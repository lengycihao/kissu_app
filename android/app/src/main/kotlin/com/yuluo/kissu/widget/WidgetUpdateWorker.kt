package com.yuluo.kissu.widget

import android.Manifest
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.pm.PackageManager
import android.location.LocationManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.BatteryManager
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import androidx.work.*
import com.yuluo.kissu.constants.AppConstants
import org.json.JSONArray
import org.json.JSONObject
import android.content.pm.ApplicationInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import java.io.BufferedOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.TimeUnit

/**
 * 小组件后台数据刷新 + 数据上报 Worker
 * 使用 WorkManager / 系统 onUpdate 触发
 * 功能：
 * 1. 获取定位数据并更新小组件 UI
 * 2. 上报当前位置到服务器（保证 App 被杀后仍能上报）
 * 3. 上报 App 使用记录到服务器
 * 即使 App 被杀死也能由系统 onUpdate 触发执行
 */
class WidgetUpdateWorker(
    private val context: Context,
    workerParams: WorkerParameters
) : Worker(context, workerParams) {

    companion object {
        private const val TAG = "WidgetUpdateWorker"
        private const val UNIQUE_WORK_NAME = "kissu_widget_update"
        private const val PREF_NAME = "kissu_preferences"
        private const val KEY_USER_TOKEN = "user_token"
        private const val KEY_USER_ID = "user_id"
        private const val KEY_BASE_URL = "base_api_url"
        private const val FLUTTER_PREF_NAME = "FlutterSharedPreferences"
        private const val LOGO_CACHE_KEY = "flutter.app_logo_cache"

        /**
         * 注册周期性小组件刷新任务（每 15 分钟）
         */
        fun enqueuePeriodicWork(context: Context) {
            val workRequest = PeriodicWorkRequestBuilder<WidgetUpdateWorker>(
                15, TimeUnit.MINUTES
            )
                .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 5, TimeUnit.MINUTES)
                .build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                UNIQUE_WORK_NAME,
                ExistingPeriodicWorkPolicy.UPDATE,
                workRequest
            )
            Log.d(TAG, "✅ 小组件周期刷新任务已注册（每15分钟）")
        }

        /**
         * 立即执行一次性数据刷新（由系统 onUpdate / 定位上报触发）
         * 比周期性任务更可靠，因为由系统事件驱动
         */
        fun enqueueOneTimeWork(context: Context) {
            val workRequest = OneTimeWorkRequestBuilder<WidgetUpdateWorker>()
                .setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
                .build()

            WorkManager.getInstance(context).enqueueUniqueWork(
                "${UNIQUE_WORK_NAME}_once",
                ExistingWorkPolicy.REPLACE,
                workRequest
            )
            Log.d(TAG, "⚡ 一次性小组件刷新任务已入队")
        }

        /**
         * 取消周期性任务（登出时调用）
         */
        fun cancelPeriodicWork(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(UNIQUE_WORK_NAME)
            Log.d(TAG, "🗑️ 小组件周期刷新任务已取消")
        }
    }

    override fun doWork(): Result {
        Log.d(TAG, "🔄 开始执行小组件数据刷新...")

        // 无论后续网络/接口是否成功，都先落一个“刷新时间”，用于验证 Worker 是否被系统调度。
        // 这里不依赖接口返回数据，避免用户误以为 Worker 未执行。
        touchWidgetRefreshTime()
        KissuWidgetProvider.updateAllWidgets(context)
        KissuWidgetDaysProvider.updateAllWidgets(context)

        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        val token = prefs.getString(KEY_USER_TOKEN, null)
        val baseUrl = prefs.getString(KEY_BASE_URL, null) ?: AppConstants.DEFAULT_BASE_URL
        val userId = prefs.getString(KEY_USER_ID, null)

        if (token.isNullOrEmpty()) {
            Log.w(TAG, "⚠️ 用户未登录（无token），跳过刷新")
            return Result.success()
        }

        return try {
            val hasNetwork = isNetworkAvailable()

            if (!hasNetwork) {
                Log.w(TAG, "⚠️ 当前无网络，跳过拉取/上报（Worker 仍会按周期被调度）")
                return Result.success()
            }

            // 任务 1：获取定位数据并更新小组件 UI
            try {
                val data = fetchLocationData(token, baseUrl, userId)
                if (data != null) {
                    updateWidgetPrefs(data)
                    KissuWidgetProvider.updateAllWidgets(context)
                    KissuWidgetDaysProvider.updateAllWidgets(context)
                    Log.d(TAG, "✅ 小组件数据刷新成功")
                } else {
                    Log.w(TAG, "⚠️ 获取定位数据返回空")
                    // 仍然更新一次刷新时间（worker 已运行但接口无数据）
                    touchWidgetRefreshTime()
                    KissuWidgetProvider.updateAllWidgets(context)
                    KissuWidgetDaysProvider.updateAllWidgets(context)
                }
            } catch (e: Exception) {
                Log.e(TAG, "💥 小组件数据刷新失败", e)
            }

            // 任务 2：上报当前位置到服务器
            try {
                reportLocationToServer(token, baseUrl, userId)
            } catch (e: Exception) {
                Log.e(TAG, "💥 位置上报失败", e)
            }

            // 任务 3：上报 App 使用记录
            try {
                collectAndReportAppUsage(token, baseUrl, userId)
            } catch (e: Exception) {
                Log.e(TAG, "💥 App使用记录上报失败", e)
            }

            Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "💥 Worker 执行异常", e)
            Result.retry()
        }
    }

    private fun isNetworkAvailable(): Boolean {
        return try {
            val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val activeNetwork = cm.activeNetwork ?: return false
            val capabilities = cm.getNetworkCapabilities(activeNetwork) ?: return false
            capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
        } catch (e: Exception) {
            false
        }
    }

    private fun touchWidgetRefreshTime() {
        try {
            val widgetPrefs = context.getSharedPreferences(
                KissuWidgetProvider.PREFS_NAME, Context.MODE_PRIVATE
            )
            val sdf = SimpleDateFormat("HH:mm:ss", Locale.getDefault())
            widgetPrefs.edit().putString(
                KissuWidgetProvider.KEY_LAST_REFRESH,
                sdf.format(Date())
            ).apply()
        } catch (_: Exception) {
        }
    }

    /**
     * 从服务器获取定位数据
     */
    private fun fetchLocationData(token: String, baseUrl: String, userId: String?): JSONObject? {
        var connection: HttpURLConnection? = null
        try {
            val apiUrl = "$baseUrl/get/location"

            // 构建请求头（复用通用方法，与 POST 请求保持一致）
            val headers = buildHeaders(token, userId)

            // 生成签名（GET 请求无 body 参数）
            val sign = generateSign(headers, emptyMap())
            headers["sign"] = sign

            // 发起 GET 请求
            val url = URL(apiUrl)
            connection = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "GET"
                doInput = true
                useCaches = false
                connectTimeout = 15000
                readTimeout = 15000
                headers.forEach { (key, value) ->
                    setRequestProperty(key, value)
                }
            }

            val responseCode = connection.responseCode
            if (responseCode == HttpURLConnection.HTTP_OK) {
                val response = connection.inputStream.bufferedReader().use { it.readText() }
                val jsonResponse = JSONObject(response)
                val code = jsonResponse.optInt("code", -1)
                if (code == 0) {
                    return jsonResponse.optJSONObject("data")
                } else {
                    Log.w(TAG, "❌ API返回错误: code=$code, msg=${jsonResponse.optString("msg")}")
                }
            } else {
                Log.w(TAG, "❌ HTTP请求失败: $responseCode")
            }
        } catch (e: Exception) {
            Log.e(TAG, "💥 请求定位数据异常", e)
        } finally {
            connection?.disconnect()
        }
        return null
    }

    /**
     * 将获取到的数据写入小组件 SharedPreferences
     */
    private fun updateWidgetPrefs(data: JSONObject) {
        val widgetPrefs = context.getSharedPreferences(
            KissuWidgetProvider.PREFS_NAME, Context.MODE_PRIVATE
        )

        val userDevice = data.optJSONObject("user_location_mobile_device")
        val halfDevice = data.optJSONObject("half_location_mobile_device")

        widgetPrefs.edit().apply {
            // 自己的数据
            if (userDevice != null) {
                val power = userDevice.optString("power", "")
                putString(KissuWidgetProvider.KEY_SELF_BATTERY, power)
                putString(KissuWidgetProvider.KEY_SELF_LOCATION, userDevice.optString("location", ""))
                putString(KissuWidgetProvider.KEY_SELF_AVATAR, userDevice.optString("head_portrait", ""))

                // 距离
                val distance = userDevice.optString("distance", "")
                if (distance.isNotEmpty()) {
                    putString(KissuWidgetProvider.KEY_DISTANCE, distance)
                }
            }

            // 另一半的数据
            if (halfDevice != null) {
                val power = halfDevice.optString("power", "")
                putString(KissuWidgetProvider.KEY_PARTNER_BATTERY, power)
                putString(KissuWidgetProvider.KEY_PARTNER_LOCATION, halfDevice.optString("location", ""))
                putString(KissuWidgetProvider.KEY_PARTNER_AVATAR, halfDevice.optString("head_portrait", ""))

                // 距离（备用）
                val distance = halfDevice.optString("distance", "")
                if (distance.isNotEmpty() && !widgetPrefs.contains(KissuWidgetProvider.KEY_DISTANCE)) {
                    putString(KissuWidgetProvider.KEY_DISTANCE, distance)
                }
            }

            // 保存最后刷新时间
            val sdf = SimpleDateFormat("HH:mm:ss", Locale.getDefault())
            putString(KissuWidgetProvider.KEY_LAST_REFRESH, sdf.format(Date()))

            apply()
        }

        Log.d(TAG, "✅ 小组件 SharedPreferences 已更新")
    }

    // ==================== 位置上报 ====================

    /**
     * 获取最后已知位置并上报到服务器
     * 使用 LocationManager.getLastKnownLocation()，无需启动 GPS 定位
     */
    private fun reportLocationToServer(token: String, baseUrl: String, userId: String?) {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        val maxAge = 30 * 60 * 1000L // 30分钟

        // ===== 策略 1：优先读取 LocationReportService 缓存的高德坐标（已经是 GCJ-02） =====
        val cachedLat = prefs.getString("last_report_latitude", null)?.toDoubleOrNull()
        val cachedLng = prefs.getString("last_report_longitude", null)?.toDoubleOrNull()
        val cachedTime = prefs.getLong("last_location_report_time", 0L)
        val cachedAge = System.currentTimeMillis() - cachedTime

        if (cachedLat != null && cachedLng != null && cachedTime > 0 && cachedAge <= maxAge) {
            Log.d(TAG, "📍 使用高德缓存坐标(GCJ-02): $cachedLat, $cachedLng, ${cachedAge / 1000}秒前")
            sendLocationReport(token, baseUrl, userId, cachedLat, cachedLng, 0.0, 0.0, 0f)
            return
        }

        // ===== 策略 2：兜底 — 系统 GPS + WGS-84→GCJ-02 坐标转换 =====
        val hasFine = ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        val hasCoarse = ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
        if (!hasFine && !hasCoarse) {
            Log.w(TAG, "⚠️ 无定位权限且无缓存坐标，跳过位置上报")
            return
        }

        val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        var lastLocation: android.location.Location? = null
        try {
            if (hasFine) {
                lastLocation = locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER)
            }
            if (lastLocation == null) {
                lastLocation = locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
            }
            if (lastLocation == null) {
                lastLocation = locationManager.getLastKnownLocation(LocationManager.PASSIVE_PROVIDER)
            }
        } catch (e: SecurityException) {
            Log.e(TAG, "获取位置权限异常", e)
            return
        }

        if (lastLocation == null) {
            Log.w(TAG, "⚠️ 无最后已知位置，跳过上报")
            return
        }

        val locationAge = System.currentTimeMillis() - lastLocation.time
        if (locationAge > maxAge) {
            Log.w(TAG, "⚠️ 位置过期(${locationAge / 1000}秒前)，跳过上报")
            return
        }

        // WGS-84 → GCJ-02 坐标转换
        val gcj02 = CoordinateConverter.wgs84ToGcj02(lastLocation.latitude, lastLocation.longitude)
        val gcjLat = gcj02[0]
        val gcjLng = gcj02[1]
        Log.d(TAG, "📍 系统GPS坐标转换: WGS(${lastLocation.latitude}, ${lastLocation.longitude}) → GCJ($gcjLat, $gcjLng)")

        sendLocationReport(token, baseUrl, userId, gcjLat, gcjLng,
            lastLocation.altitude, lastLocation.speed.toDouble(), lastLocation.accuracy)
    }

    /**
     * 发送位置上报请求（坐标已经是 GCJ-02）
     */
    private fun sendLocationReport(
        token: String, baseUrl: String, userId: String?,
        latitude: Double, longitude: Double,
        altitude: Double, speed: Double, accuracy: Float
    ) {
        val locationTime = (System.currentTimeMillis() / 1000).toString()
        val locationData = JSONObject().apply {
            put("longitude", longitude.toString())
            put("latitude", latitude.toString())
            put("location_time", locationTime)
            put("speed", speed.toString())
            put("altitude", altitude.toString())
            put("accuracy", accuracy.toString())
            put("location_name", "")
        }
        val locationArray = JSONArray().apply { put(locationData) }

        val headers = buildHeaders(token, userId)
        val bodyParams = mapOf("locations" to locationArray.toString())
        val sign = generateSign(headers, bodyParams)
        headers["sign"] = sign

        val requestBody = JSONObject().apply {
            put("locations", locationArray.toString())
        }

        val success = sendPostRequest("$baseUrl/location/report", headers, requestBody)
        if (success) {
            Log.d(TAG, "✅ 位置上报成功(原生Worker): $latitude, $longitude")
        } else {
            Log.w(TAG, "❌ 位置上报失败(原生Worker)")
        }
    }

    // ==================== App 使用记录上报 ====================

    /**
     * 采集并上报 App 使用记录
     */
    private fun collectAndReportAppUsage(token: String, baseUrl: String, userId: String?) {
        // 检查使用情况访问权限
        if (!hasUsageStatsPermission()) {
            Log.w(TAG, "⚠️ 无使用情况访问权限，跳过 App 使用记录上报")
            return
        }

        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()
        val todayDate = calendar.get(Calendar.YEAR) * 10000 +
                (calendar.get(Calendar.MONTH) + 1) * 100 +
                calendar.get(Calendar.DAY_OF_MONTH)

        // 一次性查询所有事件，按包名分组（避免 N 次 queryEvents）
        val eventsByPkg = mutableMapOf<String, MutableList<Pair<Int, Long>>>()
        try {
            val allEvents = usageStatsManager.queryEvents(startTime, endTime)
            val event = UsageEvents.Event()
            while (allEvents.getNextEvent(event)) {
                when (event.eventType) {
                    UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                        eventsByPkg.getOrPut(event.packageName) { mutableListOf() }
                            .add(Pair(1, event.timeStamp))
                    }
                    UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                        eventsByPkg.getOrPut(event.packageName) { mutableListOf() }
                            .add(Pair(0, event.timeStamp))
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "查询使用事件失败", e)
            return
        }

        // 获取今天所有应用的使用统计
        val usageStats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, startTime, endTime
        )

        val pm = context.packageManager
        val appUsageArray = JSONArray()
        val systemPrefixes = listOf("com.android.", "com.google.android.", "android.",
            "com.miui.system", "com.xiaomi.system", "com.huawei.system",
            "com.oppo.system", "com.vivo.system", "com.samsung.android.app.system")

        for (stats in usageStats) {
            if (stats.totalTimeInForeground <= 0) continue
            try {
                val packageName = stats.packageName
                val appInfo = pm.getApplicationInfo(packageName, 0)

                // 过滤系统应用
                val isSystemApp = (appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0
                val isUpdatedSystemApp = (appInfo.flags and android.content.pm.ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0
                if (isSystemApp && !isUpdatedSystemApp) continue

                // 跳过没有启动器入口的应用
                if (pm.getLaunchIntentForPackage(packageName) == null) continue

                // 过滤系统包名前缀
                if (systemPrefixes.any { packageName.startsWith(it) }) continue

                // 从预先分组的事件中获取该 app 的记录
                val appEvents = eventsByPkg[packageName] ?: continue
                val recordList = JSONArray()
                for ((eventType, timestamp) in appEvents) {
                    recordList.put(JSONObject().apply {
                        put("operate_time", timestamp / 1000)
                        put("operate_type", eventType)
                    })
                }

                if (recordList.length() == 0) continue

                val appName = pm.getApplicationLabel(appInfo).toString()
                val logoUrl = getOrUploadLogo(token, baseUrl, userId, packageName, appInfo)
                appUsageArray.put(JSONObject().apply {
                    put("app_name", appName)
                    put("app_pkg", packageName)
                    put("app_logo", logoUrl ?: "")
                    put("record", recordList)
                })
            } catch (e: Exception) {
                // 应用可能已卸载，跳过
            }
        }

        if (appUsageArray.length() == 0) {
            Log.d(TAG, "📱 暂无 App 使用记录需要上报")
            return
        }

        // 构建请求
        val headers = buildHeaders(token, userId)
        val bodyParams = mapOf(
            "app_use_record_data" to appUsageArray.toString(),
            "date" to todayDate.toString()
        )
        val sign = generateSign(headers, bodyParams)
        headers["sign"] = sign

        val requestBody = JSONObject().apply {
            put("app_use_record_data", appUsageArray)
            put("date", todayDate)
        }

        val success = sendPostRequest("$baseUrl/v4/report/app/use/record", headers, requestBody)
        if (success) {
            Log.d(TAG, "✅ App使用记录上报成功: ${appUsageArray.length()} 个应用")
        } else {
            Log.w(TAG, "❌ App使用记录上报失败")
        }
    }

    /**
     * 检查是否有使用情况访问权限
     */
    private fun hasUsageStatsPermission(): Boolean {
        return try {
            val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as android.app.AppOpsManager
            val mode = appOps.checkOpNoThrow(
                "android:get_usage_stats",
                android.os.Process.myUid(),
                context.packageName
            )
            mode == android.app.AppOpsManager.MODE_ALLOWED
        } catch (e: Exception) { false }
    }

    // ==================== Logo 处理 ====================

    /**
     * 获取或上传 App Logo（与 AppUsageReportService 共用 Flutter 缓存）
     */
    private fun getOrUploadLogo(
        token: String, baseUrl: String, userId: String?,
        packageName: String, appInfo: ApplicationInfo
    ): String? {
        // 1. 先从 Flutter SharedPreferences 读取缓存
        val cached = readLogoCache(packageName)
        if (!cached.isNullOrEmpty()) {
            return cached
        }

        // 2. 缓存没有，渲染 icon 并上传
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

                val uploaded = uploadLogoFile(token, baseUrl, userId, tempFile)
                if (!uploaded.isNullOrEmpty()) {
                    saveLogoCache(packageName, uploaded)
                    Log.d(TAG, "\uD83D\uDDBC\uFE0F logo上传成功: $packageName -> $uploaded")
                }
                uploaded
            } finally {
                if (tempFile.exists()) tempFile.delete()
            }
        } catch (e: Exception) {
            Log.e(TAG, "logo处理失败: $packageName", e)
            null
        }
    }

    /**
     * 从 Flutter SharedPreferences 读取缓存的 logo URL
     */
    private fun readLogoCache(packageName: String): String? {
        return try {
            val prefs = context.getSharedPreferences(FLUTTER_PREF_NAME, Context.MODE_PRIVATE)
            val json = prefs.getString(LOGO_CACHE_KEY, null) ?: return null
            val obj = JSONObject(json)
            val url = obj.optString(packageName, "")
            if (url.isNotEmpty()) url else null
        } catch (e: Exception) { null }
    }

    /**
     * 写入 logo URL 到 Flutter SharedPreferences 缓存
     */
    private fun saveLogoCache(packageName: String, logoUrl: String) {
        try {
            val prefs = context.getSharedPreferences(FLUTTER_PREF_NAME, Context.MODE_PRIVATE)
            val json = prefs.getString(LOGO_CACHE_KEY, null)
            val obj = if (!json.isNullOrEmpty()) JSONObject(json) else JSONObject()
            obj.put(packageName, logoUrl)
            prefs.edit().putString(LOGO_CACHE_KEY, obj.toString()).apply()
        } catch (e: Exception) {
            Log.e(TAG, "保存logo缓存失败", e)
        }
    }

    /**
     * 将 Drawable 渲染为 512x512 Bitmap
     */
    private fun renderAppIcon(drawable: Drawable?): Bitmap? {
        if (drawable == null) return null
        val targetSize = 512
        return when (drawable) {
            is BitmapDrawable -> {
                val bmp = drawable.bitmap
                if (bmp.width == targetSize && bmp.height == targetSize) bmp
                else Bitmap.createScaledBitmap(bmp, targetSize, targetSize, true)
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
     * 上传 logo 文件到 /file/upload（multipart/form-data）
     */
    private fun uploadLogoFile(token: String, baseUrl: String, userId: String?, file: File): String? {
        var connection: HttpURLConnection? = null
        val boundary = "----kissu${System.currentTimeMillis()}"
        return try {
            val apiUrl = "$baseUrl/file/upload"
            val headers = buildHeaders(token, userId)
            // multipart 不能用 application/json
            headers.remove("Content-Type")
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
                headers.forEach { (key, value) -> setRequestProperty(key, value) }
            }

            BufferedOutputStream(connection.outputStream).use { output ->
                val lineEnd = "\r\n"
                val twoHyphens = "--"
                output.write((twoHyphens + boundary + lineEnd).toByteArray(Charsets.UTF_8))
                output.write("Content-Disposition: form-data; name=\"file\"; filename=\"${file.name}\"\r\n".toByteArray(Charsets.UTF_8))
                output.write("Content-Type: image/png\r\n\r\n".toByteArray(Charsets.UTF_8))
                file.inputStream().use { input -> input.copyTo(output) }
                output.write(lineEnd.toByteArray(Charsets.UTF_8))
                output.write((twoHyphens + boundary + twoHyphens + lineEnd).toByteArray(Charsets.UTF_8))
                output.flush()
            }

            val responseCode = connection.responseCode
            if (responseCode == HttpURLConnection.HTTP_OK) {
                val response = connection.inputStream.bufferedReader().use { it.readText() }
                val json = JSONObject(response)
                if (json.optInt("code", -1) == 0) {
                    val dataObj = json.optJSONObject("data")
                    return dataObj?.optString("file_url") ?: json.optString("data")
                }
            }
            Log.w(TAG, "logo上传失败: HTTP=$responseCode")
            null
        } catch (e: Exception) {
            Log.e(TAG, "logo上传异常", e)
            null
        } finally {
            connection?.disconnect()
        }
    }

    // ==================== 通用网络方法 ====================

    /**
     * 构建通用请求头（位置上报 & App 使用记录共用）
     */
    private fun buildHeaders(token: String, userId: String?): MutableMap<String, String> {
        val headers = mutableMapOf(
            "Content-Type" to "application/json; charset=UTF-8",
            "Accept" to "application/json",
            "token" to token,
            "version" to getAppVersion(),
            "pkg" to context.packageName,
            "deviceid" to getDeviceId(),
            "channel" to (context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
                .getString("app_channel", null) ?: "kissu_android"),
            "os" to "1",
            "model" to Build.MODEL,
            "osversion" to Build.VERSION.RELEASE,
            "timestamp" to System.currentTimeMillis().toString(),
            "mobile-model" to "${Build.BRAND} ${Build.MODEL}",
            "brand" to Build.BRAND,
            "network-name" to getCurrentNetworkHeaderValue(),
            "power" to getBatteryLevel(),
            "is-open-location" to getLocationPermissionFlag()
        )
        if (!userId.isNullOrEmpty()) {
            headers["userid"] = userId
        }
        val androidId = getAndroidId()
        if (!androidId.isNullOrEmpty()) {
            headers["androidid"] = androidId
        }
        return headers
    }

    /**
     * 发送 POST 请求（通用）
     */
    private fun sendPostRequest(apiUrl: String, headers: Map<String, String>, body: JSONObject): Boolean {
        var connection: HttpURLConnection? = null
        try {
            val url = URL(apiUrl)
            connection = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                doOutput = true
                doInput = true
                useCaches = false
                connectTimeout = 15000
                readTimeout = 15000
                headers.forEach { (key, value) -> setRequestProperty(key, value) }
            }

            OutputStreamWriter(connection.outputStream, Charsets.UTF_8).use { writer ->
                writer.write(body.toString())
                writer.flush()
            }

            val responseCode = connection.responseCode
            if (responseCode == HttpURLConnection.HTTP_OK) {
                val response = connection.inputStream.bufferedReader().use { it.readText() }
                val jsonResponse = JSONObject(response)
                return jsonResponse.optInt("code", -1) == 0
            }
            Log.w(TAG, "❌ POST $apiUrl 失败: $responseCode")
        } catch (e: Exception) {
            Log.e(TAG, "💥 POST $apiUrl 异常", e)
        } finally {
            connection?.disconnect()
        }
        return false
    }

    // ==================== 工具方法 ====================

    private fun generateSign(headers: Map<String, String>, bodyParams: Map<String, String>): String {
        val secretKey = AppConstants.API_SIGNATURE_SECRET_KEY
        val allParams = mutableMapOf<String, String>()
        val businessHeaders = setOf("channel", "version", "deviceid", "pkg", "token", "userid")
        headers.forEach { (key, value) ->
            if (businessHeaders.contains(key.lowercase())) {
                allParams[key.lowercase()] = value
            }
        }
        allParams.putAll(bodyParams)
        val sortedKeys = allParams.keys.sorted()
        val signBuilder = StringBuilder()
        sortedKeys.forEach { key ->
            signBuilder.append(allParams[key])
        }
        signBuilder.append(secretKey)
        return md5(signBuilder.toString()).uppercase()
    }

    private fun md5(input: String): String {
        val md = MessageDigest.getInstance("MD5")
        val digest = md.digest(input.toByteArray())
        return digest.joinToString("") { "%02x".format(it) }
    }

    private fun getAppVersion(): String {
        return try {
            val packageInfo = context.packageManager.getPackageInfo(context.packageName, 0)
            packageInfo.versionName ?: "1.0.0"
        } catch (e: Exception) { "1.0.0" }
    }

    private fun getDeviceId(): String {
        return try {
            android.provider.Settings.Secure.getString(
                context.contentResolver,
                android.provider.Settings.Secure.ANDROID_ID
            ) ?: "unknown"
        } catch (e: Exception) { "unknown" }
    }

    private fun getBatteryLevel(): String {
        return try {
            val bm = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            val level = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
            if (level >= 0) level.toString() else "100"
        } catch (e: Exception) { "100" }
    }

    private fun getCurrentNetworkHeaderValue(): String {
        return try {
            val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val activeNetwork = cm.activeNetwork
            if (activeNetwork != null) {
                val capabilities = cm.getNetworkCapabilities(activeNetwork)
                if (capabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true) {
                    return when {
                        capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
                        capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "mobile"
                        capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ethernet"
                        else -> "other"
                    }
                }
            }
            "none"
        } catch (e: Exception) { "unknown" }
    }

    private fun getLocationPermissionFlag(): String {
        val hasFine = ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        return if (hasFine) "1" else "0"
    }

    private fun getAndroidId(): String? {
        return try {
            android.provider.Settings.Secure.getString(
                context.contentResolver,
                android.provider.Settings.Secure.ANDROID_ID
            )
        } catch (e: Exception) { null }
    }
}
