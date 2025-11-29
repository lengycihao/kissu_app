package com.yuluo.kissu.handlers

import android.app.Activity
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.drawable.BitmapDrawable
import android.provider.Settings
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.io.ByteArrayOutputStream

/**
 * 应用使用统计处理器
 * 负责处理应用列表获取、使用时长统计等功能
 */
class AppUsageHandler(private val activity: Activity) {
    
    companion object {
        private const val TAG = "AppUsageHandler"
    }
    
    /**
     * 处理应用使用统计方法调用
     */
    fun handleMethodCall(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getInstalledApps" -> {
                // 在后台线程获取应用列表，避免阻塞主线程
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val apps = getInstalledApps()
                        withContext(Dispatchers.Main) {
                            result.success(apps)
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("ERROR", "获取应用列表失败: ${e.message}", null)
                        }
                    }
                }
            }
            "getAppUsageTime" -> {
                val packageName = call.argument<String>("packageName") ?: ""
                if (!hasUsagePermission()) {
                    result.error("NO_PERMISSION", "没有使用情况访问权限", null)
                } else {
                    result.success(getUsageTime(packageName))
                }
            }
            "getDetailedUsageData" -> {
                val packageName = call.argument<String>("packageName") ?: ""
                if (!hasUsagePermission()) {
                    result.error("NO_PERMISSION", "没有使用情况访问权限", null)
                } else {
                    result.success(getDetailedUsageData(packageName))
                }
            }
            "getBatchDetailedUsageData" -> {
                val packageNames = call.argument<List<String>>("packageNames") ?: emptyList()
                if (!hasUsagePermission()) {
                    result.error("NO_PERMISSION", "没有使用情况访问权限", null)
                } else {
                    result.success(getBatchDetailedUsageData(packageNames))
                }
            }
            "getAllUsageData" -> {
                // 获取所有有使用记录的应用数据
                if (!hasUsagePermission()) {
                    result.error("NO_PERMISSION", "没有使用情况访问权限", null)
                } else {
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val data = getAllUsageData()
                            withContext(Dispatchers.Main) {
                                result.success(data)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("ERROR", "获取使用数据失败: ${e.message}", null)
                            }
                        }
                    }
                }
            }
            "openUsageSettings" -> {
                openUsageSettings()
                result.success(null)
            }
            else -> {
                result.notImplemented()
            }
        }
    }
    
    /**
     * 获取所有已安装应用列表
     */
    private fun getInstalledApps(): List<Map<String, Any>> {
        val pm = activity.packageManager
        val apps = pm.getInstalledApplications(PackageManager.GET_META_DATA)
        val result = mutableListOf<Map<String, Any>>()
        
        for (app in apps) {
            try {
                val packageName = app.packageName
                
                // 🔧 过滤系统应用：只显示用户安装的应用
                val isSystemApp = (app.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0
                val isUpdatedSystemApp = (app.flags and android.content.pm.ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0
                
                // 跳过纯系统应用
                if (isSystemApp && !isUpdatedSystemApp) {
                    continue
                }
                
                // 🔧 额外过滤：跳过系统组件和服务
                // 1. 没有启动器入口的应用（用户无法直接打开）
                val launchIntent = pm.getLaunchIntentForPackage(packageName)
                if (launchIntent == null) {
                    continue
                }
                
                // 2. 过滤常见的系统包名前缀
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
                
                val appName = pm.getApplicationLabel(app).toString()
                val iconDrawable = pm.getApplicationIcon(app)
                
                // 兼容各种图标类型（BitmapDrawable、VectorDrawable、AdaptiveIconDrawable等）
                val bitmap = when (iconDrawable) {
                    is BitmapDrawable -> iconDrawable.bitmap
                    else -> {
                        val width = if (iconDrawable.intrinsicWidth > 0) iconDrawable.intrinsicWidth else 192
                        val height = if (iconDrawable.intrinsicHeight > 0) iconDrawable.intrinsicHeight else 192
                        val bmp = android.graphics.Bitmap.createBitmap(width, height, android.graphics.Bitmap.Config.ARGB_8888)
                        val canvas = android.graphics.Canvas(bmp)
                        iconDrawable.setBounds(0, 0, canvas.width, canvas.height)
                        iconDrawable.draw(canvas)
                        bmp
                    }
                }
                
                val stream = ByteArrayOutputStream()
                bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, stream)
                val byteArray = stream.toByteArray()
                
                result.add(
                    mapOf(
                        "appName" to appName,
                        "packageName" to packageName,
                        "icon" to byteArray
                    )
                )
            } catch (e: Exception) {
                Log.w(TAG, "无法获取应用信息: ${app.packageName}, ${e.message}")
            }
        }
        
        Log.i(TAG, "共获取到 ${result.size} 个用户应用（已过滤系统应用）")
        return result.sortedBy { (it["appName"] as String).lowercase() }
    }
    
    /**
     * 检查是否有使用情况访问权限
     */
    private fun hasUsagePermission(): Boolean {
        return try {
            val appOps = activity.getSystemService(Context.APP_OPS_SERVICE) as android.app.AppOpsManager
            val mode = appOps.checkOpNoThrow(
                "android:get_usage_stats",
                android.os.Process.myUid(),
                activity.packageName
            )
            mode == android.app.AppOpsManager.MODE_ALLOWED
        } catch (e: Exception) {
            Log.e(TAG, "检查使用情况权限失败", e)
            false
        }
    }
    
    /**
     * 获取指定应用的使用时长（过去24小时）
     */
    private fun getUsageTime(packageName: String): Int {
        val usageStatsManager = activity.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val endTime = System.currentTimeMillis()
        val startTime = endTime - 24 * 60 * 60 * 1000
        
        val statsList: List<UsageStats> =
            usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
        
        var totalTime = 0L
        for (stats in statsList) {
            if (stats.packageName == packageName) {
                totalTime += stats.totalTimeInForeground
            }
        }
        
        return totalTime.toInt()
    }
    
    /**
     * 获取指定应用的详细使用数据
     */
    private fun getDetailedUsageData(packageName: String): Map<String, Any> {
        val usageStatsManager = activity.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        
        val calendar = java.util.Calendar.getInstance()
        calendar.set(java.util.Calendar.HOUR_OF_DAY, 0)
        calendar.set(java.util.Calendar.MINUTE, 0)
        calendar.set(java.util.Calendar.SECOND, 0)
        calendar.set(java.util.Calendar.MILLISECOND, 0)
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()
        
        // 获取应用信息
        val pm = activity.packageManager
        var appName = packageName
        var iconBase64 = ""
        try {
            val appInfo = pm.getApplicationInfo(packageName, 0)
            appName = pm.getApplicationLabel(appInfo).toString()
            
            val iconDrawable = pm.getApplicationIcon(appInfo)
            val bitmap = when (iconDrawable) {
                is BitmapDrawable -> iconDrawable.bitmap
                else -> {
                    val width = if (iconDrawable.intrinsicWidth > 0) iconDrawable.intrinsicWidth else 192
                    val height = if (iconDrawable.intrinsicHeight > 0) iconDrawable.intrinsicHeight else 192
                    val bmp = android.graphics.Bitmap.createBitmap(width, height, android.graphics.Bitmap.Config.ARGB_8888)
                    val canvas = android.graphics.Canvas(bmp)
                    iconDrawable.setBounds(0, 0, canvas.width, canvas.height)
                    iconDrawable.draw(canvas)
                    bmp
                }
            }
            val stream = ByteArrayOutputStream()
            bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, stream)
            val byteArray = stream.toByteArray()
            iconBase64 = android.util.Base64.encodeToString(byteArray, android.util.Base64.NO_WRAP)
        } catch (e: Exception) {
            Log.w(TAG, "获取应用信息失败: $packageName", e)
        }
        
        // 获取使用事件
        val usageEvents = usageStatsManager.queryEvents(startTime, endTime)
        val event = android.app.usage.UsageEvents.Event()
        
        val appEvents = mutableListOf<Pair<Int, Long>>()
        while (usageEvents.getNextEvent(event)) {
            if (event.packageName == packageName) {
                when (event.eventType) {
                    android.app.usage.UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                        appEvents.add(Pair(1, event.timeStamp))
                    }
                    android.app.usage.UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                        appEvents.add(Pair(0, event.timeStamp))
                    }
                }
            }
        }
        
        appEvents.sortBy { it.second }
        
        // 构建会话记录
        val rawSessions = mutableListOf<Map<String, Any>>()
        var lastOpenTime: Long? = null
        
        for ((eventType, timestamp) in appEvents) {
            if (eventType == 1) {
                lastOpenTime = timestamp
            } else if (eventType == 0 && lastOpenTime != null) {
                rawSessions.add(mapOf(
                    "openTime" to lastOpenTime,
                    "closeTime" to timestamp,
                    "duration" to (timestamp - lastOpenTime)
                ))
                lastOpenTime = null
            }
        }
        
        if (lastOpenTime != null) {
            rawSessions.add(mapOf(
                "openTime" to lastOpenTime,
                "closeTime" to -1L,
                "duration" to (endTime - lastOpenTime),
                "isRunning" to true
            ))
        }
        
        val sessions = cleanupSessions(rawSessions)
        
        // 按小时分组统计
        val hourlyRecords = buildHourlyRecords(sessions, endTime)
        
        val dateFormat = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.getDefault())
        val date = dateFormat.format(java.util.Date(startTime))
        
        return mapOf(
            "appName" to appName,
            "packageName" to packageName,
            "iconBase64" to iconBase64,
            "date" to date,
            "totalSessions" to sessions.size,
            "hourlyRecords" to hourlyRecords
        )
    }
    
    /**
     * 批量获取详细使用数据
     */
    private fun getBatchDetailedUsageData(packageNames: List<String>): List<Map<String, Any>> {
        return packageNames.map { getDetailedUsageData(it) }
    }
    
    /**
     * 获取所有有使用记录的应用数据
     * 自动获取当天所有有使用记录的应用，不需要传入包名列表
     */
    private fun getAllUsageData(): List<Map<String, Any>> {
        val usageStatsManager = activity.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
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
        
        val result = mutableListOf<Map<String, Any>>()
        val pm = activity.packageManager
        
        // 遍历所有有使用记录的应用
        for (stats in usageStats) {
            // 只处理今天有使用记录的应用（总使用时长 > 0）
            if (stats.totalTimeInForeground > 0) {
                try {
                    val packageName = stats.packageName
                    
                    // 检查应用是否仍然安装
                    val appInfo = pm.getApplicationInfo(packageName, 0)
                    
                    // 🔧 过滤系统应用
                    val isSystemApp = (appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0
                    val isUpdatedSystemApp = (appInfo.flags and android.content.pm.ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0
                    
                    // 跳过纯系统应用
                    if (isSystemApp && !isUpdatedSystemApp) {
                        continue
                    }
                    
                    // 🔧 额外过滤：跳过系统组件和服务
                    // 1. 没有启动器入口的应用（用户无法直接打开）
                    val launchIntent = pm.getLaunchIntentForPackage(packageName)
                    if (launchIntent == null) {
                        continue
                    }
                    
                    // 2. 过滤常见的系统包名前缀
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
                    
                    // 获取详细使用数据
                    val detailedData = getDetailedUsageData(packageName)
                    
                    // 只添加有hourlyRecords的应用
                    val hourlyRecords = detailedData["hourlyRecords"] as? List<*>
                    if (hourlyRecords != null && hourlyRecords.isNotEmpty()) {
                        result.add(detailedData)
                    }
                } catch (e: Exception) {
                    // 应用可能已被卸载，跳过
                    Log.w(TAG, "跳过应用: ${stats.packageName}, 原因: ${e.message}")
                }
            }
        }
        
        Log.d(TAG, "获取到 ${result.size} 个有使用记录的应用")
        return result
    }
    
    /**
     * 清理会话数据
     */
    private fun cleanupSessions(rawSessions: List<Map<String, Any>>): List<Map<String, Any>> {
        if (rawSessions.isEmpty()) return emptyList()
        
        val MIN_DURATION = 3000L
        val validSessions = rawSessions.filter { (it["duration"] as Long) >= MIN_DURATION }
        
        if (validSessions.isEmpty()) return emptyList()
        
        val MERGE_THRESHOLD = 10000L
        val mergedSessions = mutableListOf<MutableMap<String, Any>>()
        var currentSession = validSessions[0].toMutableMap()
        
        for (i in 1 until validSessions.size) {
            val nextSession = validSessions[i]
            val currentCloseTime = currentSession["closeTime"] as Long
            val nextOpenTime = nextSession["openTime"] as Long
            
            if (currentCloseTime == -1L) {
                mergedSessions.add(currentSession)
                currentSession = nextSession.toMutableMap()
                continue
            }
            
            val gap = nextOpenTime - currentCloseTime
            
            if (gap <= MERGE_THRESHOLD) {
                val nextCloseTime = nextSession["closeTime"] as Long
                val currentOpenTime = currentSession["openTime"] as Long
                
                currentSession["closeTime"] = nextCloseTime
                currentSession["duration"] = if (nextCloseTime == -1L) {
                    currentSession["isRunning"] = true
                    System.currentTimeMillis() - currentOpenTime
                } else {
                    nextCloseTime - currentOpenTime
                }
            } else {
                mergedSessions.add(currentSession)
                currentSession = nextSession.toMutableMap()
            }
        }
        
        mergedSessions.add(currentSession)
        
        val FINAL_MIN_DURATION = 5000L
        return mergedSessions.filter { (it["duration"] as Long) >= FINAL_MIN_DURATION }
    }
    
    /**
     * 构建每小时记录
     */
    private fun buildHourlyRecords(sessions: List<Map<String, Any>>, endTime: Long): List<Map<String, Any>> {
        val hourlyRecords = mutableListOf<Map<String, Any>>()
        val hourMap = mutableMapOf<Int, MutableMap<String, Any>>()
        
        for (session in sessions) {
            val openTime = session["openTime"] as Long
            val closeTime = session["closeTime"] as Long
            val actualCloseTime = if (closeTime == -1L) endTime else closeTime
            
            val openCal = java.util.Calendar.getInstance().apply { timeInMillis = openTime }
            val startHour = openCal.get(java.util.Calendar.HOUR_OF_DAY)
            
            val hourData = hourMap.getOrPut(startHour) {
                mutableMapOf(
                    "totalDuration" to 0L,
                    "sessions" to mutableListOf<Map<String, Any>>()
                )
            }
            
            val closeCal = java.util.Calendar.getInstance().apply { timeInMillis = actualCloseTime }
            val endHour = closeCal.get(java.util.Calendar.HOUR_OF_DAY)
            
            val contributedDuration = if (startHour == endHour) {
                actualCloseTime - openTime
            } else {
                val hourEndCal = java.util.Calendar.getInstance().apply {
                    timeInMillis = openTime
                    set(java.util.Calendar.HOUR_OF_DAY, startHour)
                    set(java.util.Calendar.MINUTE, 59)
                    set(java.util.Calendar.SECOND, 59)
                    set(java.util.Calendar.MILLISECOND, 999)
                }
                minOf(actualCloseTime, hourEndCal.timeInMillis) - openTime
            }
            
            hourData["totalDuration"] = (hourData["totalDuration"] as Long) + contributedDuration
            
            @Suppress("UNCHECKED_CAST")
            (hourData["sessions"] as MutableList<Map<String, Any>>).add(session)
        }
        
        for ((hour, hourData) in hourMap.entries.sortedBy { it.key }) {
            val sessionsList = hourData["sessions"] as List<*>
            hourlyRecords.add(mapOf(
                "hour" to hour,
                "totalDuration" to (hourData["totalDuration"] as Long),
                "sessionCount" to sessionsList.size,
                "sessions" to sessionsList
            ))
        }
        
        return hourlyRecords
    }
    
    /**
     * 打开使用情况访问设置
     */
    private fun openUsageSettings() {
        try {
            val intent = android.content.Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            activity.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "打开使用情况设置失败", e)
        }
    }
}
