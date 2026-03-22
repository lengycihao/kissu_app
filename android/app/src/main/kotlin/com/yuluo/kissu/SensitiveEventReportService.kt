package com.yuluo.kissu

import android.Manifest
import android.content.Context
import com.yuluo.kissu.constants.AppConstants
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import android.os.BatteryManager
import android.os.Build
import io.flutter.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import androidx.core.content.ContextCompat
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * 原生敏感事件上报服务（锁屏/解锁）
 *
 * 作用：
 * - 在 Flutter 引擎不存活时，接管手机锁屏/解锁事件的上报工作
 * - 与 Flutter 侧 SensitiveDataApi 使用同一个接口：/v4/reporting/sensitive/record
 * - 避免与 Flutter 重复上报：当 MainActivity.isFlutterEngineAlive 为 true 时不做原生上报
 */
class SensitiveEventReportService(private val context: Context) {

    companion object {
        private const val TAG = "SensitiveEventReport"
        private const val NATIVE_LOG_TAG = "NativeSensitiveEvent"

        // SharedPreferences 名称与键，与 AppUsageReportService 保持一致
        private const val PREF_NAME = "kissu_preferences"
        private const val KEY_USER_TOKEN = "user_token"
        private const val KEY_USER_ID = "user_id"
        private const val KEY_BASE_URL = "base_api_url"

        // 敏感数据上报接口路径（与 ApiRequest.sensitiveDataReport 保持一致）
        private const val SENSITIVE_API_PATH = "/v4/reporting/sensitive/record"
    }

    private val sharedPreferences =
        context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)

    private val coroutineScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    /**
     * 上报锁屏/解锁事件
     */
    fun reportScreenEvent(isUnlock: Boolean, timestampSeconds: Long) {
        // 如果 Flutter 引擎存活，交给 Flutter 层处理，避免重复上报
        if (MainActivity.isFlutterEngineAlive) {
            Log.d(TAG, "Flutter 引擎存活，跳过原生锁屏/解锁上报")
            return
        }

        val eventType = if (isUnlock) 14 else 15
        reportSensitiveEvent(
            eventType = eventType,
            extMap = mapOf("timestamp" to timestampSeconds)
        )
    }

    /**
     * 通用敏感事件上报
     *
     * @param eventType 事件类型（6、7、8、14、15、21 等）
     * @param extMap 额外字段（可选），会序列化为 JSON
     */
    fun reportSensitiveEvent(
        eventType: Int,
        extMap: Map<String, Any?> = emptyMap(),
        extraHeaders: Map<String, String> = emptyMap(),
        retryIfFailed: Boolean = true,
        forceNative: Boolean = false
    ) {
        if (!forceNative && MainActivity.isFlutterEngineAlive) {
            Log.d(TAG, "Flutter 引擎存活，eventType=$eventType 交由 Flutter 处理")
            return
        }

        coroutineScope.launch {
            try {
                val token = sharedPreferences.getString(KEY_USER_TOKEN, null)
                val baseUrl = sharedPreferences.getString(KEY_BASE_URL, null)
                val userId = sharedPreferences.getString(KEY_USER_ID, null)

                if (token.isNullOrEmpty() || baseUrl.isNullOrEmpty()) {
                    logWarning("Token 或 BaseUrl 为空，无法上报敏感事件")
                    return@launch
                }

                Log.d(TAG, "准备上报敏感事件: eventType=$eventType, ext=$extMap")

                val success = sendSensitiveEventToServer(
                    baseUrl = baseUrl,
                    token = token,
                    userId = userId,
                    eventType = eventType,
                    extMap = extMap,
                    extraHeaders = extraHeaders
                )

                if (success) {
                    logInfo("✅ 原生敏感事件上报成功", extra = mapOf("eventType" to eventType))
                } else {
                    logWarning("❌ 原生敏感事件上报失败", extra = mapOf("eventType" to eventType))
                    if (retryIfFailed) {
                        scheduleRetry(eventType, extMap, extraHeaders, forceNative)
                    }
                }
            } catch (e: Exception) {
                logError("💥 原生敏感事件上报异常", extra = mapOf("error" to (e.message ?: "unknown"), "eventType" to eventType))
                if (retryIfFailed) {
                    scheduleRetry(eventType, extMap, extraHeaders, forceNative)
                }
            }
        }
    }

    private fun scheduleRetry(
        eventType: Int,
        extMap: Map<String, Any?>,
        extraHeaders: Map<String, String>,
        forceNative: Boolean
    ) {
        coroutineScope.launch {
            try {
                Log.d(TAG, "⏳ 3秒后重试敏感事件上报: eventType=$eventType")
                delay(3000)
                reportSensitiveEvent(
                    eventType,
                    extMap,
                    extraHeaders = extraHeaders,
                    retryIfFailed = false,
                    forceNative = forceNative
                )
            } catch (e: Exception) {
                logError("重试敏感事件上报调度失败", extra = mapOf("error" to (e.message ?: "unknown")))
            }
        }
    }

    /**
     * 发送敏感事件到服务器
     */
    private suspend fun sendSensitiveEventToServer(
        baseUrl: String,
        token: String,
        userId: String?,
        eventType: Int,
        extMap: Map<String, Any?>,
        extraHeaders: Map<String, String>
    ): Boolean = withContext(Dispatchers.IO) {
        var connection: HttpURLConnection? = null
        try {
            val apiUrl = "$baseUrl$SENSITIVE_API_PATH"

            Log.d(TAG, "📡 敏感事件上报地址: $apiUrl")

            val extJson = JSONObject()
            extMap.forEach { (key, value) ->
                when (value) {
                    null -> extJson.put(key, JSONObject.NULL)
                    is Number, is Boolean, is String -> extJson.put(key, value)
                    else -> extJson.put(key, value.toString())
                }
            }

            // 构造请求体
            val body = JSONObject().apply {
                put("event_type", eventType)
                put("ext", if (extMap.isNotEmpty()) extJson.toString() else "{}")
            }

            // 构造业务 Header，与后端约定保持一致
            val headers = mutableMapOf(
                "Content-Type" to "application/json; charset=UTF-8",
                "Accept" to "application/json",
                "token" to token,
                "version" to getAppVersion(),
                "pkg" to context.packageName,
                "deviceid" to getDeviceId(),
                "channel" to (sharedPreferences.getString("app_channel", null) ?: "kissu_android"),
                "os" to "1", // 1 = Android
                "model" to Build.MODEL,
                "osversion" to Build.VERSION.RELEASE,
                "timestamp" to System.currentTimeMillis().toString(),
                "mobile-model" to "${Build.BRAND} ${Build.MODEL}",
                "brand" to Build.BRAND,
                "is-open-location" to getLocationPermissionFlag(),
                "network-name" to (extraHeaders["network-name"] ?: getCurrentNetworkHeaderValue()),
                "power" to (extraHeaders["power"] ?: getBatteryHeaderValue())
            )

            if (!userId.isNullOrEmpty()) {
                headers["userid"] = userId
            }
            
            // 尝试获取OAID（如果可用）
            val oaid = getOaid()
            if (!oaid.isNullOrEmpty()) {
                headers["oaid"] = oaid
            }

            // 生成签名（与 AppUsageReportService.generateSign 规则保持一致）
            val sign = generateSign(
                headers = headers,
                bodyParams = mapOf(
                    "event_type" to eventType.toString(),
                    "ext" to body.getString("ext")
                )
            )
            headers["sign"] = sign

            Log.d(TAG, "🔐 签名生成成功: $sign")

            val url = URL(apiUrl)
            connection = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                doInput = true
                doOutput = true
                useCaches = false
                connectTimeout = 15000
                readTimeout = 15000

                headers.forEach { (key, value) ->
                    setRequestProperty(key, value)
                }
            }

            connection.outputStream.use { os ->
                os.write(body.toString().toByteArray(Charsets.UTF_8))
                os.flush()
            }

            val code = connection.responseCode
            Log.d(TAG, "📡 敏感事件 HTTP 响应码: $code")

                val responseText = if (code == HttpURLConnection.HTTP_OK) {
                    connection.inputStream.bufferedReader().use { it.readText() }
                } else {
                    connection.errorStream?.bufferedReader()?.use { it.readText() } ?: ""
                }

            Log.d(TAG, "📡 敏感事件响应内容: $responseText")

            if (code == HttpURLConnection.HTTP_OK) {
                val json = try {
                    JSONObject(responseText)
                } catch (e: Exception) {
                    Log.w(TAG, "响应不是合法 JSON，仍视为失败", e)
                    return@withContext false
                }
                val respCode = json.optInt("code", -1)
                return@withContext respCode == 0
            }

            false
        } catch (e: Exception) {
            logError("💥 发送敏感事件请求异常", extra = mapOf("error" to (e.message ?: "unknown")))
            false
        } finally {
            connection?.disconnect()
        }
    }

    /**
     * 生成签名
     *
     * 规则与 AppUsageReportService.generateSign 保持一致：
     * 1. 收集所有参数（业务 header + 请求体参数）
     * 2. 按 key ASCII 升序排序
     * 3. 拼接所有 value（不拼接 key）
     * 4. 最后拼接密钥
     * 5. 对整个字符串做 MD5，转大写
     */
    private fun generateSign(
        headers: Map<String, String>,
        bodyParams: Map<String, String>
    ): String {
        val secretKey = AppConstants.API_SIGNATURE_SECRET_KEY

        val allParams = mutableMapOf<String, String>()

        // 业务 header（与 AppUsageReportService 保持一致）
        val businessHeaders = setOf("channel", "version", "deviceid", "pkg", "token", "userid")
        headers.forEach { (key, value) ->
            if (businessHeaders.contains(key.lowercase())) {
                allParams[key.lowercase()] = value
            }
        }

        // 请求体参数
        allParams.putAll(bodyParams)

        val sortedKeys = allParams.keys.sorted()
        val sb = StringBuilder()
        sortedKeys.forEach { key ->
            sb.append(allParams[key])
        }
        sb.append(secretKey)

        val signString = sb.toString()
        val signature = md5(signString).uppercase()

        Log.d(TAG, "签名原串: $signString")
        Log.d(TAG, "签名结果: $signature")

        return signature
    }

    private fun md5(input: String): String {
        val md = MessageDigest.getInstance("MD5")
        val digest = md.digest(input.toByteArray())
        return digest.joinToString("") { "%02x".format(it) }
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
            logWarning("检查隐私政策状态失败", extra = mapOf("error" to (e.message ?: "unknown")))
            false // 默认返回 false，确保合规
        }
    }
    
    /**
     * 获取设备 ID（Android ID）
     * 🔥 修复：在用户同意隐私政策前不获取 ANDROID ID，返回降级值
     */
    private fun getDeviceId(): String {
        // 🔥 关键修复：检查隐私政策是否已同意
        if (!isPrivacyPolicyAgreed()) {
            return "privacy_not_agreed_${System.currentTimeMillis()}"
        }
        
        return try {
            android.provider.Settings.Secure.getString(
                context.contentResolver,
                android.provider.Settings.Secure.ANDROID_ID
            ) ?: "unknown"
        } catch (e: Exception) {
            logError("获取设备ID失败", extra = mapOf("error" to (e.message ?: "unknown")))
            "unknown"
        }
    }

    private fun getCurrentNetworkHeaderValue(): String {
        return try {
            val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val activeNetwork = cm.activeNetwork
            if (activeNetwork != null) {
                val capabilities = cm.getNetworkCapabilities(activeNetwork)
                val hasInternet = capabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true
                if (hasInternet) {
                    return when {
                        capabilities!!.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> {
                            val wifiManager =
                                context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                            val info = wifiManager.connectionInfo
                            val ssid = info?.ssid?.trim('"')
                            if (!ssid.isNullOrBlank() && !ssid.equals("<unknown ssid>", true)) {
                                "wifi_$ssid"
                            } else {
                                "wifi"
                            }
                        }
                        capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "mobile"
                        capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ethernet"
                        capabilities.hasTransport(NetworkCapabilities.TRANSPORT_BLUETOOTH) -> "bluetooth"
                        else -> "other"
                    }
                }
            }

            @Suppress("DEPRECATION")
            val info = cm.activeNetworkInfo
            if (info != null && info.isConnected) {
                return when (info.type) {
                    ConnectivityManager.TYPE_WIFI -> "wifi"
                    ConnectivityManager.TYPE_MOBILE -> "mobile"
                    ConnectivityManager.TYPE_ETHERNET -> "ethernet"
                    ConnectivityManager.TYPE_BLUETOOTH -> "bluetooth"
                    else -> "other"
                }
            }
            "none"
        } catch (e: Exception) {
            logError("获取网络头部信息失败", extra = mapOf("error" to (e.message ?: "unknown")))
            "unknown"
        }
    }

    private fun getBatteryHeaderValue(): String {
        return try {
            val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            val level = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
            if (level >= 0) level.toString() else "100"
        } catch (e: Exception) {
            logError("获取电量信息失败", extra = mapOf("error" to (e.message ?: "unknown")))
            "100"
        }
    }

    private fun getLocationPermissionFlag(): String {
        return try {
            val fineGranted = ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
            val coarseGranted = ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_COARSE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
            if (fineGranted || coarseGranted) "1" else "0"
        } catch (e: Exception) {
            logError("获取定位权限状态失败", extra = mapOf("error" to (e.message ?: "unknown")))
            "0"
        }
    }
    
    /**
     * 获取OAID（Open Anonymous Device Identifier）
     * 注意：OAID获取需要异步操作，这里返回缓存的OAID或null
     * 如果需要完整的OAID支持，建议通过Flutter层获取并传递给原生层
     */
    private fun getOaid(): String? {
        // TODO: 实现OAID获取逻辑
        // 由于OAID获取需要异步回调，原生代码中实现较复杂
        // 建议通过SharedPreferences存储Flutter层获取的OAID，或通过extraHeaders传递
        return null
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
            val todayFormat = SimpleDateFormat("yyyy-MM-dd", Locale.US)
            val today = todayFormat.format(Date())
            
            // 🔥 修复：查找今天已有的日志文件，避免每次写入都创建新文件（导致大量1KB小文件）
            val existingLogFile = logDir.listFiles()?.find { 
                it.name.startsWith(today) && it.name.endsWith("_app.log") 
            }
            
            val logFile = existingLogFile ?: File(logDir, "${dateFormat.format(Date())}_app.log")
            
            val isoFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSSSS", Locale.US)
            val timestamp = isoFormat.format(Date())
            
            val logEntry = org.json.JSONObject().apply {
                put("timestamp", timestamp)
                put("level", level)
                put("tag", NATIVE_LOG_TAG)
                put("message", message)
                extra?.let {
                    val extraJson = org.json.JSONObject()
                    it.forEach { (key, value) ->
                        extraJson.put(key, value ?: org.json.JSONObject.NULL)
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


