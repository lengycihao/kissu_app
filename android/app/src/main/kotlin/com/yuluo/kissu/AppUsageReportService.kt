package com.yuluo.kissu

import android.Manifest
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.SharedPreferences
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.BatteryManager
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.Log
import kotlinx.coroutines.*
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.*
import kotlin.collections.ArrayList
import java.security.MessageDigest

/**
 * 原生App使用记录上报服务
 * 
 * 功能：
 * 1. 在应用被杀后仍能继续上报App使用记录到服务器
 * 2. 使用 HTTP 原生请求，不依赖 Flutter
 * 3. 支持批量上报和定时上报
 * 4. 使用 SharedPreferences 存储 token 和配置
 * 5. 自动采集所有有使用记录的应用数据
 */
class AppUsageReportService(private val context: Context) {
    
    companion object {
        private const val TAG = "AppUsageReportService"
        private const val NATIVE_LOG_TAG = "NativeAppUsage"
        private const val PREF_NAME = "kissu_preferences"
        private const val KEY_USER_TOKEN = "user_token"
        private const val KEY_USER_ID = "user_id"
        private const val KEY_BASE_URL = "base_api_url"
        private const val KEY_LAST_REPORT_TIME = "last_app_usage_report_time"
        private const val KEY_LAST_REPORT_DATE = "last_app_usage_report_date"
        private const val KEY_NATIVE_REPORTING = "native_app_usage_reporting" // 原生层上报标记
        
        // 上报策略参数
        private const val REPORT_INTERVAL_SECONDS = 120 // 2分钟上报间隔，与Flutter层保持一致
        private const val MAX_BUFFER_SIZE = 50 // 最大缓冲区大小
    }
    
    private val sharedPreferences: SharedPreferences = 
        context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
    
    private val coroutineScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val logoCacheManager = AppLogoCacheManager(context)
    
    // 上报缓冲区，按日期分组，避免跨天数据被错误日期上报
    private val reportBufferByDate = mutableMapOf<Int, MutableList<JSONObject>>()
    private var reportTimer: Timer? = null
    private var isReportTimerRunning = false

    /**
     * 获取当天日期（yyyyMMdd）
     */
    private fun getTodayDateInt(): Int {
        val calendar = java.util.Calendar.getInstance()
        return calendar.get(java.util.Calendar.YEAR) * 10000 +
                (calendar.get(java.util.Calendar.MONTH) + 1) * 100 +
                calendar.get(java.util.Calendar.DAY_OF_MONTH)
    }
    
    /**
     * 检查是否有使用情况访问权限
     */
    private fun hasUsagePermission(): Boolean {
        return try {
            val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as android.app.AppOpsManager
            val mode = appOps.checkOpNoThrow(
                "android:get_usage_stats",
                android.os.Process.myUid(),
                context.packageName
            )
            mode == android.app.AppOpsManager.MODE_ALLOWED
        } catch (e: Exception) {
            logError("检查使用情况权限失败", mapOf("error" to (e.message ?: "unknown")))
            false
        }
    }
    
    /**
     * 检查应用是否在前台
     */
    private fun isAppInForeground(): Boolean {
        return try {
            val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val runningAppProcesses = activityManager.runningAppProcesses
                for (processInfo in runningAppProcesses) {
                    if (processInfo.processName == context.packageName) {
                        val importance = processInfo.importance
                        val reasonCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            processInfo.importanceReasonCode
                        } else {
                            android.app.ActivityManager.RunningAppProcessInfo.REASON_UNKNOWN
                        }

                        // 仅当真正有前台 Activity 时才认为在前台
                        val hasRealForegroundActivity =
                            importance == android.app.ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND &&
                                (reasonCode == android.app.ActivityManager.RunningAppProcessInfo.REASON_UNKNOWN ||
                                        reasonCode == android.app.ActivityManager.RunningAppProcessInfo.REASON_SERVICE_IN_USE)

                        // 前台服务（IMPORTANCE_FOREGROUND_SERVICE）不视为前台界面，允许继续原生上报
                        val isOnlyForegroundService =
                            importance == android.app.ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND_SERVICE

                        return hasRealForegroundActivity && !isOnlyForegroundService
                    }
                }
            }
            false
        } catch (e: Exception) {
            logError("检查应用前台状态失败", mapOf("error" to (e.message ?: "unknown")))
            false
        }
    }
    
    /**
     * 设置原生层上报标记
     */
    private fun setNativeReportingFlag(isReporting: Boolean) {
        sharedPreferences.edit().apply {
            putBoolean(KEY_NATIVE_REPORTING, isReporting)
            apply()
        }
    }
    
    /**
     * 检查原生层是否正在上报
     */
    fun isNativeReporting(): Boolean {
        return sharedPreferences.getBoolean(KEY_NATIVE_REPORTING, false)
    }
    
    /**
     * 采集并上报App使用记录
     * 在应用被杀或后台时调用
     */
    fun collectAndReportUsageData() {
        coroutineScope.launch {
            try {
                // 检查权限
                if (!hasUsagePermission()) {
                    Log.w(TAG, "⚠️ 没有使用情况访问权限，无法采集数据")
                    return@launch
                }
                
                // 检查 token 是否存在
                val token = sharedPreferences.getString(KEY_USER_TOKEN, null)
                val userId = sharedPreferences.getString(KEY_USER_ID, null)
                val baseUrl = sharedPreferences.getString(KEY_BASE_URL, null)
                
                if (token.isNullOrEmpty()) {
                    Log.w(TAG, "⚠️ 用户未登录，无法上报App使用记录")
                    return@launch
                }
                
                Log.d(TAG, "📱 开始采集App使用记录...")
                
                // 设置上报标记
                setNativeReportingFlag(true)
                
                // 采集使用数据
                val usageData = collectUsageData()
                val todayDate = getTodayDateInt()
                
                if (usageData.isEmpty()) {
                    Log.d(TAG, "📱 暂无使用记录需要上报")
                    setNativeReportingFlag(false)
                    return@launch
                }
                
                Log.d(TAG, "📱 采集到 ${usageData.size} 个应用的使用记录")
                
                // 添加到缓冲区（按app_pkg去重，新数据覆盖旧数据）
                synchronized(reportBufferByDate) {
                    val bufferForDate = reportBufferByDate.getOrPut(todayDate) { mutableListOf() }
                    
                    // 按app_pkg去重：移除已存在的相同包名数据，然后添加新数据
                    for (newData in usageData) {
                        val newPkg = newData.optString("app_pkg", "")
                        if (newPkg.isNotEmpty()) {
                            bufferForDate.removeAll { it.optString("app_pkg", "") == newPkg }
                        }
                    }
                    bufferForDate.addAll(usageData)
                    
                    Log.d(TAG, "📱 缓冲区更新后: ${bufferForDate.size} 个应用")
                    
                    // 如果当日缓冲区满了，立即上报
                    if (bufferForDate.size >= MAX_BUFFER_SIZE) {
                        Log.d(TAG, "⚠️ 当日缓冲区已满，触发立即上报")
                        performImmediateReport(token)
                    }
                }
                
                // 启动定时上报器
                startReportTimer(token)
                
            } catch (e: Exception) {
                logError("💥 采集App使用记录异常", mapOf("error" to (e.message ?: "unknown")))
                setNativeReportingFlag(false)
            }
        }
    }
    
    /**
     * 采集App使用数据
     */
    private fun collectUsageData(): List<JSONObject> {
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = java.util.Calendar.getInstance()
        calendar.set(java.util.Calendar.HOUR_OF_DAY, 0)
        calendar.set(java.util.Calendar.MINUTE, 0)
        calendar.set(java.util.Calendar.SECOND, 0)
        calendar.set(java.util.Calendar.MILLISECOND, 0)
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()
        
        // 获取今天所有应用的使用统计
        val usageStats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )
        
        val result = mutableListOf<JSONObject>()
        val pm = context.packageManager
        
        // 遍历所有有使用记录的应用
        for (stats in usageStats) {
            // 只处理今天有使用记录的应用（总使用时长 > 0）
            if (stats.totalTimeInForeground > 0) {
                try {
                    val packageName = stats.packageName
                    
                    // 检查应用是否仍然安装
                    val appInfo = pm.getApplicationInfo(packageName, 0)
                    
                    // 过滤系统应用
                    val isSystemApp = (appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0
                    val isUpdatedSystemApp = (appInfo.flags and android.content.pm.ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0
                    
                    // 跳过纯系统应用
                    if (isSystemApp && !isUpdatedSystemApp) {
                        continue
                    }
                    
                    // 跳过没有启动器入口的应用
                    val launchIntent = pm.getLaunchIntentForPackage(packageName)
                    if (launchIntent == null) {
                        continue
                    }
                    
                    // 过滤常见的系统包名前缀
                    val systemPrefixes = listOf(
                        "com.android.",
                        "com.google.android.",
                        "android.",
                        "com.miui.system",
                        "com.xiaomi.system",
                        "com.huawei.system",
                        "com.oppo.system",
                        "com.vivo.system",
                        "com.samsung.android.app.system"
                    )
                    if (systemPrefixes.any { packageName.startsWith(it) }) {
                        continue
                    }
                    
                    // 获取应用信息
                    val appName = pm.getApplicationLabel(appInfo).toString()
                    
                    // 获取使用事件
                    val usageEvents = usageStatsManager.queryEvents(startTime, endTime)
                    val event = UsageEvents.Event()
                    
                    val appEvents = mutableListOf<Pair<Int, Long>>()
                    while (usageEvents.getNextEvent(event)) {
                        if (event.packageName == packageName) {
                            when (event.eventType) {
                                UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                                    appEvents.add(Pair(1, event.timeStamp))
                                }
                                UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                                    appEvents.add(Pair(0, event.timeStamp))
                                }
                            }
                        }
                    }
                    
                    appEvents.sortBy { it.second }
                    
                    // 构建会话记录（传入startTime用于处理跨天会话）
                    val sessions = buildSessions(appEvents, startTime, endTime)
                    
                    if (sessions.isEmpty()) {
                        continue
                    }
                    
                    // 构建record数组（包含operate_time和operate_type）
                    val recordList = JSONArray()
                    for (session in sessions) {
                        val openTime = session.getLong("openTime")
                        val closeTime = session.getLong("closeTime")
                        val isRunning = session.optBoolean("isRunning", false)
                        
                        // 上报openTime（operate_type = 1）
                        recordList.put(JSONObject().apply {
                            put("operate_time", openTime / 1000) // 转换为秒级时间戳
                            put("operate_type", 1)
                        })
                        
                        // 如果有关闭时间，上报closeTime（operate_type = 0）
                        if (closeTime > 0 && !isRunning) {
                            recordList.put(JSONObject().apply {
                                put("operate_time", closeTime / 1000) // 转换为秒级时间戳
                                put("operate_type", 0)
                            })
                        }
                    }
                    
                    // 获取或上传logo
                    val logoUrl = getOrUploadLogo(packageName, appInfo)
                    
                    // 构建应用使用记录数据
                    val appUsageData = JSONObject().apply {
                        put("app_name", appName)
                        put("app_pkg", packageName)
                        put("app_logo", logoUrl ?: "")
                        put("record", recordList)
                    }
                    
                    result.add(appUsageData)
                    
                } catch (e: Exception) {
                    // 应用可能已被卸载，跳过
                    Log.w(TAG, "跳过应用: ${stats.packageName}, 原因: ${e.message}")
                }
            }
        }
        
        Log.d(TAG, "📱 采集完成: ${result.size} 个应用")
        return result
    }
    
    /**
     * 构建会话记录
     *
     * 逻辑：
     * 1. 先根据前后台事件构建原始会话列表
     * 2. 🔥 处理跨天会话：如果openTime在今天0点之前，调整为今天0点
     * 3. 过滤掉时长小于3秒的会话
     * 4. 合并间隔小于10秒的会话
     * 5. 最终再过滤一次，保留时长≥5秒的会话
     * 
     * @param appEvents 应用事件列表
     * @param startTime 今天0点的时间戳，用于处理跨天会话
     * @param endTime 当前时间戳
     */
    private fun buildSessions(appEvents: List<Pair<Int, Long>>, startTime: Long, endTime: Long): List<JSONObject> {
        val sessions = mutableListOf<JSONObject>()
        var lastOpenTime: Long? = null

        // 1. 根据事件构建原始会话
        for ((eventType, timestamp) in appEvents) {
            if (eventType == 1) {
                lastOpenTime = timestamp
            } else if (eventType == 0 && lastOpenTime != null) {
                // 🔥 跨天会话处理：如果openTime在今天0点之前，调整为今天0点
                val adjustedOpenTime = if (lastOpenTime < startTime) startTime else lastOpenTime
                val duration = timestamp - adjustedOpenTime
                
                // 只添加有效时长的会话（调整后时长>0）
                if (duration > 0) {
                    sessions.add(JSONObject().apply {
                        put("openTime", adjustedOpenTime)
                        put("closeTime", timestamp)
                        put("duration", duration)
                        put("isRunning", false)
                    })
                }
                lastOpenTime = null
            }
        }

        // 如果还有未关闭的会话
        if (lastOpenTime != null) {
            // 🔥 跨天会话处理：如果openTime在今天0点之前，调整为今天0点
            val adjustedOpenTime = if (lastOpenTime < startTime) startTime else lastOpenTime
            val duration = endTime - adjustedOpenTime
            
            // 只添加有效时长的会话
            if (duration > 0) {
                sessions.add(JSONObject().apply {
                    put("openTime", adjustedOpenTime)
                    put("closeTime", -1L)
                    put("duration", duration)
                    put("isRunning", true)
                })
            }
        }

        // 2. 过滤掉时长太短的会话（小于3秒）
        val MIN_DURATION = 3000L
        val validSessions = sessions.filter { it.getLong("duration") >= MIN_DURATION }

        // 3. 合并间隔太短的会话（间隔小于10秒）
        val MERGE_THRESHOLD = 5000L
        val mergedSessions = mutableListOf<JSONObject>()
        if (validSessions.isNotEmpty()) {
            var currentSession = JSONObject(validSessions[0].toString())

            for (i in 1 until validSessions.size) {
                val nextSession = validSessions[i]
                val currentCloseTime = currentSession.getLong("closeTime")
                val nextOpenTime = nextSession.getLong("openTime")

                if (currentCloseTime == -1L) {
                    mergedSessions.add(currentSession)
                    currentSession = JSONObject(nextSession.toString())
                    continue
                }

                val gap = nextOpenTime - currentCloseTime

                if (gap <= MERGE_THRESHOLD) {
                    val nextCloseTime = nextSession.getLong("closeTime")
                    val currentOpenTime = currentSession.getLong("openTime")

                    currentSession.put("closeTime", nextCloseTime)
                    currentSession.put("duration", if (nextCloseTime == -1L) {
                        currentSession.put("isRunning", true)
                        endTime - currentOpenTime
                    } else {
                        nextCloseTime - currentOpenTime
                    })
                } else {
                    mergedSessions.add(currentSession)
                    currentSession = JSONObject(nextSession.toString())
                }
            }

            mergedSessions.add(currentSession)
        }

        // 4. 最终过滤：过滤掉时长小于5秒的会话
        val FINAL_MIN_DURATION = 5000L
        return mergedSessions.filter { it.getLong("duration") >= FINAL_MIN_DURATION }
    }
    
    /**
     * 获取或上传logo
     */
    private fun getOrUploadLogo(packageName: String, appInfo: ApplicationInfo): String? {
        val cached = logoCacheManager.getLogoUrl(packageName)
        if (!cached.isNullOrEmpty()) {
            Log.d(TAG, "🖼️ 使用缓存logo: $packageName -> $cached")
            return cached
        }
        
        val token = sharedPreferences.getString(KEY_USER_TOKEN, null)
        if (token.isNullOrEmpty()) {
            Log.w(TAG, "⚠️ 用户未登录，无法上传logo: $packageName")
            return null
        }
        
        return try {
            val pm = context.packageManager
            val drawable = pm.getApplicationIcon(appInfo)
            val bitmap = renderAppIcon(drawable) ?: return null
            
            val tempFile = File(context.cacheDir, "app_logo_${packageName}_${System.currentTimeMillis()}.png")
            try {
                FileOutputStream(tempFile).use { fos ->
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, fos)
                    fos.flush()
                }
                
                val uploaded = uploadLogoFile(token, tempFile)
                if (!uploaded.isNullOrEmpty()) {
                    logoCacheManager.cacheLogoUrl(packageName, uploaded)
                }
                uploaded
            } finally {
                if (tempFile.exists()) {
                    tempFile.delete()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "上传logo失败", e)
            logError("上传logo失败", mapOf("packageName" to packageName, "error" to (e.message ?: "unknown")))
            null
        }
    }
    
    /**
     * 将Drawable渲染为统一尺寸的Bitmap
     */
    private fun renderAppIcon(drawable: Drawable?): Bitmap? {
        if (drawable == null) return null
        val targetSize = 512
        return when (drawable) {
            is BitmapDrawable -> {
                val bmp = drawable.bitmap
                if (bmp.width == targetSize && bmp.height == targetSize) {
                    bmp
                } else {
                    Bitmap.createScaledBitmap(bmp, targetSize, targetSize, true)
                }
            }
            else -> {
                val bitmap = Bitmap.createBitmap(targetSize, targetSize, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bitmap)
                drawable.setBounds(0, 0, targetSize, targetSize)
                drawable.draw(canvas)
                bitmap
            }
        }
    }
    
    /**
     * 上传logo文件
     */
    private fun uploadLogoFile(token: String, file: File): String? {
        var connection: HttpURLConnection? = null
        val boundary = "----kissu${System.currentTimeMillis()}"
        return try {
            val baseUrl = sharedPreferences.getString(KEY_BASE_URL, "https://service-api.ikissu.cn")
            val apiUrl = "$baseUrl/file/upload"
            val userId = sharedPreferences.getString(KEY_USER_ID, "")
            
            val headers = mutableMapOf(
                "Accept" to "application/json",
                "token" to token,
                "version" to getAppVersion(),
                "pkg" to context.packageName,
                "deviceid" to getDeviceId(),
                "channel" to "kissu_android",
                "os" to "1",
                "model" to Build.MODEL,
                "osversion" to Build.VERSION.RELEASE,
                "timestamp" to System.currentTimeMillis().toString(),
                "mobile-model" to "${Build.BRAND} ${Build.MODEL}",
                "brand" to Build.BRAND,
                "network-name" to getCurrentNetworkHeaderValue(),
                "power" to getBatteryHeaderValue(),
                "is-open-location" to getLocationPermissionFlag()
            )
            
            if (!userId.isNullOrEmpty()) {
                headers["userid"] = userId
            }
            
            val sign = generateSign(headers, emptyMap())
            headers["sign"] = sign
            
            val url = URL(apiUrl)
            connection = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                doOutput = true
                doInput = true
                useCaches = false
                connectTimeout = 15000
                readTimeout = 20000
                setRequestProperty("Content-Type", "multipart/form-data; boundary=$boundary")
                headers.forEach { (key, value) ->
                    setRequestProperty(key, value)
                }
            }
            
            BufferedOutputStream(connection.outputStream).use { output ->
                val lineEnd = "\r\n"
                val twoHyphens = "--"
                output.write((twoHyphens + boundary + lineEnd).toByteArray(Charsets.UTF_8))
                output.write("Content-Disposition: form-data; name=\"file\"; filename=\"${file.name}\"\r\n".toByteArray(Charsets.UTF_8))
                output.write("Content-Type: image/png\r\n\r\n".toByteArray(Charsets.UTF_8))
                file.inputStream().use { input ->
                    input.copyTo(output)
                }
                output.write(lineEnd.toByteArray(Charsets.UTF_8))
                output.write((twoHyphens + boundary + twoHyphens + lineEnd).toByteArray(Charsets.UTF_8))
                output.flush()
            }
            
            val responseCode = connection.responseCode
            val responseText = if (responseCode == HttpURLConnection.HTTP_OK) {
                connection.inputStream.bufferedReader().use { it.readText() }
            } else {
                connection.errorStream?.bufferedReader()?.use { it.readText() } ?: ""
            }
            
            if (responseCode == HttpURLConnection.HTTP_OK) {
                val json = JSONObject(responseText)
                val code = json.optInt("code", -1)
                if (code == 0) {
                    val dataObj = json.optJSONObject("data")
                    val logoUrl = dataObj?.optString("file_url") ?: json.optString("data")
                    Log.d(TAG, "logo上传成功: $logoUrl")
                    logInfo("logo上传成功: $logoUrl", mapOf("logoUrl" to logoUrl))
                    return logoUrl
                }
            }
            
            Log.w(TAG, "logo上传失败: HTTP=$responseCode, response=$responseText")
            logWarning("logo上传失败: HTTP=$responseCode, response=$responseText", mapOf("responseCode" to responseCode, "responseText" to responseText))
            null
        } catch (e: Exception) {
            Log.e(TAG, "logo上传异常", e)
            logError("logo上传异常", mapOf("error" to (e.message ?: "unknown")))
            null
        } finally {
            connection?.disconnect()
        }
    }
    
    /**
     * 启动定时上报器（与Flutter层2分钟间隔保持一致）
     */
    private fun startReportTimer(token: String) {
        if (isReportTimerRunning) {
            return
        }
        
        reportTimer?.cancel()
        // 定时任务中每次都从SharedPreferences读取最新token，而不是使用创建时的token
        // 这样切换账号后，定时器会自动使用新token
        reportTimer = Timer().apply {
            schedule(object : TimerTask() {
                override fun run() {
                    // 每次都从SharedPreferences读取最新token，确保切换账号后使用新token
                    val currentToken = sharedPreferences.getString(KEY_USER_TOKEN, null)
                    if (currentToken.isNullOrEmpty()) {
                        Log.w(TAG, "定时上报：token为空，跳过上报")
                        logWarning("定时上报：token为空，跳过上报", mapOf("token" to currentToken))
                        return
                    }
                    performScheduledReport(currentToken)
                }
            }, REPORT_INTERVAL_SECONDS * 1000L, REPORT_INTERVAL_SECONDS * 1000L)
        }
        isReportTimerRunning = true
        Log.d(TAG, "定时上报器已启动，间隔: ${REPORT_INTERVAL_SECONDS}秒")
        logInfo("定时上报器已启动，间隔: ${REPORT_INTERVAL_SECONDS}秒", mapOf("interval" to REPORT_INTERVAL_SECONDS))
    }
    
    /**
     * 执行定时上报
     */
    private fun performScheduledReport(token: String) {
        coroutineScope.launch {
            val bufferSnapshot: Map<Int, List<JSONObject>>
            
            // 拷贝按日期分组的数据，避免在同步块内做网络请求
            synchronized(reportBufferByDate) {
                if (reportBufferByDate.isEmpty()) {
                    Log.d(TAG, "缓冲区为空，跳过定时上报")
                    logInfo("缓冲区为空，跳过定时上报", mapOf("bufferSize" to reportBufferByDate.size))
                    return@launch
                }
                bufferSnapshot = reportBufferByDate.mapValues { (_, list) -> list.toList() }
                }
                
            bufferSnapshot.forEach { (dateInt, appList) ->
                val dataToReport = JSONArray()
                appList.forEach { appData ->
                    dataToReport.put(appData)
            }
            
                Log.d(TAG, "执行定时上报，日期: $dateInt，应用数量: ${appList.size}")
                logInfo("执行定时上报，日期: $dateInt，应用数量: ${appList.size}", mapOf("date" to dateInt, "appCount" to appList.size))
            
                val success = sendUsageDataToServer(token, dataToReport, dateInt)
            
                synchronized(reportBufferByDate) {
                if (success) {
                        reportBufferByDate.remove(dateInt)
                        Log.d(TAG, "定时上报成功，日期: $dateInt 缓冲区已清空")
                        logInfo("定时上报成功，日期: $dateInt 缓冲区已清空", mapOf("date" to dateInt))
                } else {
                        Log.w(TAG, "定时上报失败，日期: $dateInt 缓冲区保留数据")
                        logWarning("定时上报失败，日期: $dateInt 缓冲区保留数据", mapOf("date" to dateInt))
                }
                
                    if (reportBufferByDate.isEmpty()) {
                    setNativeReportingFlag(false)
                    }
                }
            }
        }
    }
    
    /**
     * 执行立即上报（缓冲区满时）
     */
    private fun performImmediateReport(token: String) {
        coroutineScope.launch {
            val bufferSnapshot: Map<Int, List<JSONObject>>
            
            synchronized(reportBufferByDate) {
                if (reportBufferByDate.isEmpty()) {
                    Log.d(TAG, "缓冲区为空，跳过立即上报")
                    logInfo("缓冲区为空，跳过立即上报", mapOf("bufferSize" to reportBufferByDate.size))
                    return@launch
                }
                bufferSnapshot = reportBufferByDate.mapValues { (_, list) -> list.toList() }
            }
            
            bufferSnapshot.forEach { (dateInt, appList) ->
                val dataToReport = JSONArray()
                appList.forEach { appData ->
                    dataToReport.put(appData)
            }
            
                Log.d(TAG, "执行立即上报，日期: $dateInt，应用数量: ${appList.size}")
                logInfo("执行立即上报，日期: $dateInt，应用数量: ${appList.size}", mapOf("date" to dateInt, "appCount" to appList.size))
            
                val success = sendUsageDataToServer(token, dataToReport, dateInt)
            
                synchronized(reportBufferByDate) {
                if (success) {
                        reportBufferByDate.remove(dateInt)
                        Log.d(TAG, "立即上报成功，日期: $dateInt 缓冲区已清空")
                        logInfo("立即上报成功，日期: $dateInt 缓冲区已清空", mapOf("date" to dateInt))
                } else {
                        Log.w(TAG, "立即上报失败，日期: $dateInt 缓冲区保留数据")
                        logWarning("立即上报失败，日期: $dateInt 缓冲区保留数据", mapOf("date" to dateInt))
                }
                
                    if (reportBufferByDate.isEmpty()) {
                    setNativeReportingFlag(false)
                    }
                }
            }
        }
    }
    
    /**
     * 发送App使用数据到服务器
     */
    private suspend fun sendUsageDataToServer(
        token: String,
        appUsageArray: JSONArray,
        dateInt: Int
    ): Boolean {
        return withContext(Dispatchers.IO) {
            var connection: HttpURLConnection? = null
            try {
                // 获取基础 URL
                val baseUrl = sharedPreferences.getString(KEY_BASE_URL, "https://service-api.ikissu.cn")
                val apiUrl = "$baseUrl/v4/report/app/use/record"
                val userId = sharedPreferences.getString(KEY_USER_ID, "")
                
                Log.d(TAG, "开始上报App使用记录")
                logInfo("开始上报App使用记录", mapOf("apiUrl" to apiUrl))
                Log.d(TAG, "API地址: $apiUrl")
                Log.d(TAG, "上报数据: ${appUsageArray.length()} 个应用")
                logInfo("上报数据: ${appUsageArray.length()} 个应用", mapOf("appCount" to appUsageArray.length()))
                
                // 准备请求头
                val headers = mutableMapOf(
                    "Content-Type" to "application/json; charset=UTF-8",
                    "Accept" to "application/json",
                    "token" to token,
                    "version" to getAppVersion(),
                    "pkg" to context.packageName,
                    "deviceid" to getDeviceId(),
                    "channel" to "kissu_android",
                    "os" to "1", // 1 = Android
                    "model" to Build.MODEL,
                    "osversion" to Build.VERSION.RELEASE,
                    "timestamp" to System.currentTimeMillis().toString(),
                    "mobile-model" to "${Build.BRAND} ${Build.MODEL}",
                    "brand" to Build.BRAND,
                    "network-name" to getCurrentNetworkHeaderValue(),
                    "power" to getBatteryHeaderValue(),
                    "is-open-location" to getLocationPermissionFlag()
                )
                
                // 添加 userId（如果存在）
                if (!userId.isNullOrEmpty()) {
                    headers["userid"] = userId
                }
                
                // 准备请求体参数（用于签名）
                val bodyParams = mapOf(
                    "app_use_record_data" to appUsageArray.toString(),
                    "date" to dateInt.toString()
                )
                
                // 生成签名
                val sign = generateSign(headers, bodyParams)
                headers["sign"] = sign
                
                Log.d(TAG, "签名已生成: $sign")
                logInfo("签名已生成: $sign", mapOf("sign" to sign))
                
                // 创建 HTTP 连接
                val url = URL(apiUrl)
                connection = (url.openConnection() as HttpURLConnection).apply {
                    requestMethod = "POST"
                    doOutput = true
                    doInput = true
                    useCaches = false
                    connectTimeout = 15000
                    readTimeout = 15000
                    
                    // 设置所有请求头
                    headers.forEach { (key, value) ->
                        setRequestProperty(key, value)
                    }
                }
                
                // 构建请求体
                val requestBody = JSONObject().apply {
                    put("app_use_record_data", appUsageArray)
                    put("date", dateInt)
                }
                
                // 发送请求
                OutputStreamWriter(connection.outputStream, Charsets.UTF_8).use { writer ->
                    writer.write(requestBody.toString())
                    writer.flush()
                }
                
                // 读取响应
                val responseCode = connection.responseCode
                Log.d(TAG, "HTTP响应码: $responseCode")
                logInfo("HTTP响应码: $responseCode", mapOf("responseCode" to responseCode))
                
                if (responseCode == HttpURLConnection.HTTP_OK) {
                    val response = connection.inputStream.bufferedReader().use { it.readText() }
                    Log.d(TAG, "服务器响应: $response")
                    logInfo("服务器响应: $response", mapOf("response" to response))
                    
                    // 解析响应
                    val jsonResponse = JSONObject(response)
                    val code = jsonResponse.optInt("code", -1)
                    
                    if (code == 0) {
                        Log.d(TAG, "App使用记录上报成功")
                        logInfo("App使用记录上报成功", mapOf("code" to code))
                        return@withContext true
                    } else {
                        Log.w(TAG, "App使用记录上报失败: ${jsonResponse.optString("msg")}")
                        logWarning("App使用记录上报失败: ${jsonResponse.optString("msg")}", mapOf("code" to code, "msg" to jsonResponse.optString("msg")))
                        return@withContext false
                    }
                } else {
                    val errorResponse = connection.errorStream?.bufferedReader()?.use { it.readText() } ?: ""
                    Log.w(TAG, "HTTP请求失败: $responseCode, $errorResponse")
                    logWarning("HTTP请求失败: $responseCode, $errorResponse", mapOf("responseCode" to responseCode, "errorResponse" to errorResponse))
                    return@withContext false
                }
            } catch (e: Exception) {
                Log.e(TAG, "发送App使用数据异常", e)
                logError("发送App使用数据异常", mapOf("error" to (e.message ?: "unknown")))
                return@withContext false
            } finally {
                connection?.disconnect()
            }
        }
    }
    
    /**
     * 获取应用版本号
     */
    private fun getAppVersion(): String {
        return try {
            val packageInfo = context.packageManager.getPackageInfo(context.packageName, 0)
            packageInfo.versionName ?: "1.0.0"
        } catch (e: Exception) {
            "1.0.0"
        }
    }
    
    /**
     * 检查隐私政策是否已同意
     */
    private fun isPrivacyPolicyAgreed(): Boolean {
        return try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            prefs.getBoolean("flutter.privacy_policy_agreed", false)
        } catch (e: Exception) {
            Log.w(TAG, "检查隐私政策状态失败", e)
            false // 默认返回 false，确保合规
        }
    }
    
    /**
     * 获取设备 ID（使用 Android ID）
     * 修复：在用户同意隐私政策前不获取 ANDROID ID，返回降级值
     */
    private fun getDeviceId(): String {
        // 检查隐私政策是否已同意
        if (!isPrivacyPolicyAgreed()) {
            Log.d(TAG, "用户未同意隐私政策，返回降级设备ID")
            logInfo("用户未同意隐私政策，返回降级设备ID", mapOf("privacyPolicyAgreed" to false))
            return "privacy_not_agreed_${System.currentTimeMillis()}"
        }
        
        return try {
            android.provider.Settings.Secure.getString(
                context.contentResolver,
                android.provider.Settings.Secure.ANDROID_ID
            ) ?: "unknown"
        } catch (e: Exception) {
            logError("获取设备ID失败", mapOf("error" to (e.message ?: "unknown")))
            "unknown"
        }
    }
    
    /**
     * 获取当前网络头部信息
     */
    private fun getCurrentNetworkHeaderValue(): String {
        return try {
            val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as android.net.ConnectivityManager
            val activeNetwork = cm.activeNetwork
            if (activeNetwork != null) {
                val capabilities = cm.getNetworkCapabilities(activeNetwork)
                val hasInternet = capabilities?.hasCapability(android.net.NetworkCapabilities.NET_CAPABILITY_INTERNET) == true
                if (hasInternet) {
                    return when {
                        capabilities!!.hasTransport(android.net.NetworkCapabilities.TRANSPORT_WIFI) -> {
                            val wifiManager =
                                context.applicationContext.getSystemService(Context.WIFI_SERVICE) as android.net.wifi.WifiManager
                            val info = wifiManager.connectionInfo
                            val ssid = info?.ssid?.trim('"')
                            if (!ssid.isNullOrBlank() && !ssid.equals("<unknown ssid>", true)) {
                                "wifi_$ssid"
                            } else {
                                "wifi"
                            }
                        }
                        capabilities.hasTransport(android.net.NetworkCapabilities.TRANSPORT_CELLULAR) -> "mobile"
                        capabilities.hasTransport(android.net.NetworkCapabilities.TRANSPORT_ETHERNET) -> "ethernet"
                        capabilities.hasTransport(android.net.NetworkCapabilities.TRANSPORT_BLUETOOTH) -> "bluetooth"
                        else -> "other"
                    }
                }
            }

            @Suppress("DEPRECATION")
            val info = cm.activeNetworkInfo
            if (info != null && info.isConnected) {
                return when (info.type) {
                    android.net.ConnectivityManager.TYPE_WIFI -> "wifi"
                    android.net.ConnectivityManager.TYPE_MOBILE -> "mobile"
                    android.net.ConnectivityManager.TYPE_ETHERNET -> "ethernet"
                    android.net.ConnectivityManager.TYPE_BLUETOOTH -> "bluetooth"
                    else -> "other"
                }
            }
            "none"
        } catch (e: Exception) {
            logError("获取网络头部信息失败", mapOf("error" to (e.message ?: "unknown")))
            "unknown"
        }
    }
    
    /**
     * 获取电池电量头部信息
     */
    private fun getBatteryHeaderValue(): String {
        return try {
            val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as android.os.BatteryManager
            val level = batteryManager.getIntProperty(android.os.BatteryManager.BATTERY_PROPERTY_CAPACITY)
            if (level >= 0) level.toString() else "100"
        } catch (e: Exception) {
            logError("获取电量信息失败", mapOf("error" to (e.message ?: "unknown")))
            "100"
        }
    }
    
    /**
     * 获取定位权限状态
     */
    private fun getLocationPermissionFlag(): String {
        return try {
            val fineGranted = androidx.core.content.ContextCompat.checkSelfPermission(
                context,
                android.Manifest.permission.ACCESS_FINE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
            val coarseGranted = androidx.core.content.ContextCompat.checkSelfPermission(
                context,
                android.Manifest.permission.ACCESS_COARSE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
            if (fineGranted || coarseGranted) "1" else "0"
        } catch (e: Exception) {
            logError("获取定位权限状态失败", mapOf("error" to (e.message ?: "unknown")))
            "0"
        }
    }
    
    /**
     * 保存用户 Token（供 Flutter 调用，复用LocationReportService的逻辑）
     */
    fun saveUserToken(token: String, userId: String) {
        sharedPreferences.edit().apply {
            putString(KEY_USER_TOKEN, token)
            putString(KEY_USER_ID, userId)
            apply()
        }
        Log.d(TAG, "用户Token已保存: $userId")
        logInfo("用户Token已保存: $userId", mapOf("userId" to userId))
        
        // 关键修复：保存token后，如果定时器正在运行，强制重启定时器以使用新token
        // 这样切换账号后，定时器会立即使用新token
        if (isReportTimerRunning && reportTimer != null) {
            Log.d(TAG, "Token已更新，重启定时器以使用新token")
            logInfo("Token已更新，重启定时器以使用新token", mapOf("token" to token))
            // 取消旧定时器
            reportTimer?.cancel()
            reportTimer = null
            isReportTimerRunning = false
            // 使用新token重新启动定时器
            startReportTimer(token)
        }
    }
    
    /**
     * 保存 API 基础 URL（供 Flutter 调用，复用LocationReportService的逻辑）
     */
    fun saveBaseUrl(baseUrl: String) {
        sharedPreferences.edit().apply {
            putString(KEY_BASE_URL, baseUrl)
            apply()
        }
        Log.d(TAG, "API基础URL已保存: $baseUrl")
        logInfo("API基础URL已保存: $baseUrl", mapOf("baseUrl" to baseUrl))
    }
    
    /**
     * 清除用户信息（登出时调用）
     */
    fun clearUserInfo() {
        // 停止定时器
        reportTimer?.cancel()
        reportTimer = null
        isReportTimerRunning = false
        
        // 清空缓冲区
        synchronized(reportBufferByDate) {
            reportBufferByDate.clear()
        }
        
        // 清除SharedPreferences
        sharedPreferences.edit().apply {
            remove(KEY_USER_TOKEN)
            remove(KEY_USER_ID)
            remove(KEY_LAST_REPORT_TIME)
            remove(KEY_LAST_REPORT_DATE)
            remove(KEY_NATIVE_REPORTING)
            apply()
        }
        Log.d(TAG, "用户信息、定时器和缓冲区已清除")
        logInfo("用户信息、定时器和缓冲区已清除", mapOf("clearUserInfo" to true))
    }
    
    /**
     * 生成 API 签名
     * 
     * 签名规则：
     * 1. 收集所有参数（业务header + 请求体参数）
     * 2. 按 key 名 ASCII 升序排序
     * 3. 拼接所有 value（不拼接 key）
     * 4. 最后拼接密钥
     * 5. 对整个字符串做 MD5，转大写
     */
    private fun generateSign(
        headers: Map<String, String>,
        bodyParams: Map<String, String>
    ): String {
        val secretKey = "TYXHTRrGeP8xy095q0iY"
        
        // 合并所有参数
        val allParams = mutableMapOf<String, String>()
        
        // 添加业务 header（排除 sign、timestamp 等）
        val businessHeaders = setOf("channel", "version", "deviceid", "pkg", "token", "userid")
        headers.forEach { (key, value) ->
            if (businessHeaders.contains(key.lowercase())) {
                allParams[key.lowercase()] = value
            }
        }
        
        // 添加请求体参数
        allParams.putAll(bodyParams)
        
        // 按 key ASCII 升序排序
        val sortedKeys = allParams.keys.sorted()
        
        // 拼接所有 value
        val signBuilder = StringBuilder()
        sortedKeys.forEach { key ->
            val value = allParams[key]
            signBuilder.append(value)
        }
        
        // 拼接密钥
        signBuilder.append(secretKey)
        
        // 生成 MD5 并转大写
        val signString = signBuilder.toString()
        val signature = md5(signString).uppercase()
        
        return signature
    }
    
    /**
     * 计算 MD5 哈希值
     */
    private fun md5(input: String): String {
        val md = MessageDigest.getInstance("MD5")
        val digest = md.digest(input.toByteArray())
        return digest.joinToString("") { "%02x".format(it) }
    }
    
    /**
     * 销毁服务
     */
    fun destroy() {
        // 停止定时器
        reportTimer?.cancel()
        reportTimer = null
        isReportTimerRunning = false
        
        // 清空缓冲区
        synchronized(reportBufferByDate) {
            reportBufferByDate.clear()
        }
        
        // 取消协程
        coroutineScope.cancel()
        Log.d(TAG, "AppUsageReportService 已销毁")
    }
    
    // ================================
    // 🔥 原生层文件日志功能
    // ================================
    
    private fun writeNativeLog(
        level: String,
        message: String,
        extra: Map<String, Any?>? = null
    ) {
        try {
            // 使用与 Flutter 层相同的日志目录：filesDir/logs（对应 getApplicationSupportDirectory()/logs）
            val logDir = File(context.filesDir, "logs")
            if (!logDir.exists()) {
                logDir.mkdirs()
            }
            
            val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH-mm-ss.SSSSSS", Locale.US)
            val now = Date()
            val fileName = "${dateFormat.format(now)}_app.log"
            val logFile = File(logDir, fileName)
            
            val isoFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSSSS", Locale.US)
            val timestamp = isoFormat.format(now)
            
            val logEntry = JSONObject().apply {
                put("timestamp", timestamp)
                put("level", level)
                put("tag", NATIVE_LOG_TAG)
                put("message", message)
                extra?.let {
                    val extraJson = JSONObject()
                    it.forEach { (key, value) ->
                        extraJson.put(key, value ?: JSONObject.NULL)
                    }
                    put("extra", extraJson)
                }
            }
            
            logFile.appendText(logEntry.toString() + "\n")
        } catch (e: Exception) {
            Log.e(TAG, "写入原生日志失败", e)
        }
    }
    
    private fun logInfo(message: String, extra: Map<String, Any?>? = null) {
        Log.d(TAG, message)
        writeNativeLog("INFO", message, extra)
    }
    
    private fun logWarning(message: String, extra: Map<String, Any?>? = null) {
        Log.w(TAG, message)
        writeNativeLog("WARNING", message, extra)
    }
    
    private fun logError(message: String, extra: Map<String, Any?>? = null) {
        Log.e(TAG, message)
        writeNativeLog("ERROR", message, extra)
    }
}

/**
 * 读取Flutter共享的logo缓存（与Flutter层的AppLogoCacheService共用同一份数据）
 */
class AppLogoCacheManager(context: Context) {
    companion object {
        const val PREF_NAME = "FlutterSharedPreferences"
        const val CACHE_KEY = "flutter.app_logo_cache"
    }
    
    private val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
    private val cache = mutableMapOf<String, String>()
    private var isLoaded = false
    private val lock = Any()
    
    fun getLogoUrl(packageName: String): String? {
        synchronized(lock) {
            ensureLoaded()
            return cache[packageName]
        }
    }
    
    fun cacheLogoUrl(packageName: String, logoUrl: String) {
        if (logoUrl.isEmpty()) return
        synchronized(lock) {
            ensureLoaded()
            cache[packageName] = logoUrl
            saveCache()
        }
    }
    
    private fun ensureLoaded() {
        if (isLoaded) return
        val json = prefs.getString(CACHE_KEY, null)
        if (!json.isNullOrEmpty()) {
            try {
                val obj = JSONObject(json)
                val keys = obj.keys()
                while (keys.hasNext()) {
                    val key = keys.next()
                    val value = obj.optString(key, "")
                    if (value.isNotEmpty()) {
                        cache[key] = value
                    }
                }
                Log.d("AppLogoCacheManager", "已加载logo缓存: ${cache.size}个")
            } catch (e: Exception) {
                Log.e("AppLogoCacheManager", "加载logo缓存失败", e)
                cache.clear()
            }
        }
        isLoaded = true
    }
    
    private fun saveCache() {
        try {
            val obj = JSONObject()
            cache.forEach { (pkg, url) ->
                obj.put(pkg, url)
            }
            prefs.edit().putString(CACHE_KEY, obj.toString()).apply()
            Log.d("AppLogoCacheManager", "🖼️ logo缓存已更新: ${cache.size}个")
        } catch (e: Exception) {
            Log.e("AppLogoCacheManager", "保存logo缓存失败", e)
        }
    }
}

