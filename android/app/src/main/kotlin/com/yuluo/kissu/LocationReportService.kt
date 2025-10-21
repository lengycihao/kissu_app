package com.yuluo.kissu

import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import com.amap.api.location.AMapLocation
import io.flutter.Log
import kotlinx.coroutines.*
import org.json.JSONArray
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.*
import kotlin.collections.ArrayList
import java.security.MessageDigest

/**
 * 原生定位上报服务
 * 
 * 功能：
 * 1. 在应用被杀后仍能继续上报定位数据到服务器
 * 2. 使用 HTTP 原生请求，不依赖 Flutter
 * 3. 支持批量上报和单点上报
 * 4. 使用 SharedPreferences 存储 token 和配置
 */
class LocationReportService(private val context: Context) {
    
    companion object {
        private const val TAG = "LocationReportService"
        private const val PREF_NAME = "kissu_preferences"
        private const val KEY_USER_TOKEN = "user_token"
        private const val KEY_USER_ID = "user_id"
        private const val KEY_BASE_URL = "base_api_url"
        private const val KEY_LAST_REPORT_TIME = "last_location_report_time"
        private const val KEY_LAST_REPORT_LAT = "last_report_latitude"
        private const val KEY_LAST_REPORT_LNG = "last_report_longitude"
        
        // 与Flutter层保持一致的上报策略参数
        private const val COLLECTION_DISTANCE_METERS = 50 // 50米收集距离，与Flutter层 <50m 丢弃一致
        private const val REPORT_INTERVAL_SECONDS = 60 // 1分钟上报间隔，与Flutter层_reportInterval一致
        private const val MAX_COLLECTION_BUFFER_SIZE = 12 // 1分钟最多12个点(5秒一个)，与Flutter层一致
    }
    
    private val sharedPreferences: SharedPreferences = 
        context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
    
    private val coroutineScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    
    // 收集缓冲区，与Flutter层策略保持一致
    private val collectionBuffer = mutableListOf<JSONObject>()
    private var reportTimer: Timer? = null
    private var isReportTimerRunning = false
    
    /**
     * 处理定位数据（与Flutter层策略保持一致）
     * 1. 检查是否需要收集
     * 2. 收集到缓冲区
     * 3. 启动定时上报器
     */
    fun reportLocation(location: AMapLocation) {
        coroutineScope.launch {
            try {
                // 检查是否需要收集定位
                if (!shouldCollectLocation(location)) {
                    return@launch
                }
                
                // 检查 token 是否存在
                val token = sharedPreferences.getString(KEY_USER_TOKEN, null)
                val userId = sharedPreferences.getString(KEY_USER_ID, null)
                val baseUrl = sharedPreferences.getString(KEY_BASE_URL, null)
                
                Log.d(TAG, "🔑 读取用户信息: token=${if (token.isNullOrEmpty()) "空" else "已存在(${token.take(20)}...)"}, userId=$userId, baseUrl=$baseUrl")
                
                if (token.isNullOrEmpty()) {
                    Log.w(TAG, "⚠️ 用户未登录，无法收集定位数据")
                    return@launch
                }
                
                // 构建定位数据并加入收集缓冲区
                val locationData = buildLocationData(location)
                synchronized(collectionBuffer) {
                    collectionBuffer.add(locationData)
                    Log.d(TAG, "📦 位置已收集到缓冲区 (${collectionBuffer.size}/${MAX_COLLECTION_BUFFER_SIZE}): ${location.latitude}, ${location.longitude}")
                    
                    // 如果缓冲区满了，立即上报
                    if (collectionBuffer.size >= MAX_COLLECTION_BUFFER_SIZE) {
                        Log.d(TAG, "⚠️ 缓冲区已满，触发立即上报")
                        performImmediateReport(token)
                    }
                }
                
                // 启动定时上报器
                startReportTimer(token)
                
                // 更新最后收集的位置信息
                updateLastCollectionInfo(location)
                
            } catch (e: Exception) {
                Log.e(TAG, "💥 定位处理异常", e)
            }
        }
    }
    
    /**
     * 启动定时上报器（与Flutter层1分钟间隔保持一致）
     */
    private fun startReportTimer(token: String) {
        if (isReportTimerRunning) {
            return
        }
        
        reportTimer?.cancel()
        reportTimer = Timer().apply {
            schedule(object : TimerTask() {
                override fun run() {
                    performScheduledReport(token)
                }
            }, REPORT_INTERVAL_SECONDS * 1000L, REPORT_INTERVAL_SECONDS * 1000L)
        }
        isReportTimerRunning = true
        Log.d(TAG, "⏰ 定时上报器已启动，间隔: ${REPORT_INTERVAL_SECONDS}秒")
    }
    
    /**
     * 执行定时上报
     */
    private fun performScheduledReport(token: String) {
        coroutineScope.launch {
            val locationsToReport: JSONArray
            val bufferSize: Int
            
            // 在synchronized块内拷贝数据，避免在同步代码块内调用挂起函数
            synchronized(collectionBuffer) {
                if (collectionBuffer.isEmpty()) {
                    Log.d(TAG, "📦 缓冲区为空，跳过定时上报")
                    return@launch
                }
                
                locationsToReport = JSONArray()
                collectionBuffer.forEach { locationData ->
                    locationsToReport.put(locationData)
                }
                bufferSize = collectionBuffer.size
            }
            
            Log.d(TAG, "⏰ 执行定时上报，位置数量: $bufferSize")
            
            // 在synchronized块外调用挂起函数
            val success = sendLocationToServer(token, locationsToReport)
            
            // 根据结果处理缓冲区
            synchronized(collectionBuffer) {
                if (success) {
                    collectionBuffer.clear()
                    Log.d(TAG, "✅ 定时上报成功，缓冲区已清空")
                } else {
                    Log.w(TAG, "❌ 定时上报失败，缓冲区保留数据")
                }
            }
        }
    }
    
    /**
     * 执行立即上报（缓冲区满时）
     */
    private fun performImmediateReport(token: String) {
        coroutineScope.launch {
            val locationsToReport: JSONArray
            val bufferSize: Int
            
            // 在synchronized块内拷贝数据，避免在同步代码块内调用挂起函数
            synchronized(collectionBuffer) {
                locationsToReport = JSONArray()
                collectionBuffer.forEach { locationData ->
                    locationsToReport.put(locationData)
                }
                bufferSize = collectionBuffer.size
            }
            
            Log.d(TAG, "⚡ 执行立即上报，位置数量: $bufferSize")
            
            // 在synchronized块外调用挂起函数
            val success = sendLocationToServer(token, locationsToReport)
            
            // 根据结果处理缓冲区
            synchronized(collectionBuffer) {
                if (success) {
                    collectionBuffer.clear()
                    Log.d(TAG, "✅ 立即上报成功，缓冲区已清空")
                } else {
                    Log.w(TAG, "❌ 立即上报失败，缓冲区保留数据")
                }
            }
        }
    }
    
    /**
     * 检查是否需要收集定位
     * 与Flutter层策略保持一致：
     * 1. 首次定位必收集
     * 2. 与上次收集位置距离>=50米时收集
     * 3. 每1分钟上报一次收集到的位置
     */
    private fun shouldCollectLocation(location: AMapLocation): Boolean {
        // 检查定位是否有效
        if (location.errorCode != 0) {
            Log.d(TAG, "⚠️ 定位失败，错误码: ${location.errorCode}")
            return false
        }
        
        val lastReportTime = sharedPreferences.getLong(KEY_LAST_REPORT_TIME, 0)
        
        // 首次定位必收集
        if (lastReportTime == 0L) {
            Log.d(TAG, "🚀 首次定位，必须收集: ${location.latitude}, ${location.longitude}, 精度: ${location.accuracy}m")
            return true
        }
        
        // 检查与上次位置的距离
        val lastLat = sharedPreferences.getString(KEY_LAST_REPORT_LAT, null)?.toDoubleOrNull()
        val lastLng = sharedPreferences.getString(KEY_LAST_REPORT_LNG, null)?.toDoubleOrNull()
        
        if (lastLat != null && lastLng != null) {
            val distance = calculateDistance(
                lastLat, lastLng,
                location.latitude, location.longitude
            )
            
            if (distance >= COLLECTION_DISTANCE_METERS) {
                Log.d(TAG, "📍 距离触发收集: 移动${distance.toInt()}米 >= ${COLLECTION_DISTANCE_METERS}米 (精度: ${location.accuracy}m)")
                return true
            } else {
                Log.d(TAG, "📍 距离不足，跳过收集: 移动${distance.toInt()}米 < ${COLLECTION_DISTANCE_METERS}米")
                return false
            }
        }
        
        return false
    }
    
    /**
     * 构建定位数据 JSON
     */
    private fun buildLocationData(location: AMapLocation): JSONObject {
        // 转换为10位时间戳（秒）
        val locationTime = if (location.time > 0) {
            // 高德返回的是13位毫秒时间戳，转换为10位秒时间戳
            (location.time / 1000).toString()
        } else {
            // 如果高德时间戳无效，使用当前时间
            (System.currentTimeMillis() / 1000).toString()
        }
        
        return JSONObject().apply {
            put("longitude", location.longitude.toString())
            put("latitude", location.latitude.toString())
            put("location_time", locationTime) // 10位时间戳
            put("speed", location.speed.toString())
            put("altitude", location.altitude.toString())
            put("accuracy", location.accuracy.toString())
            put("location_name", buildLocationName(location))
        }
    }
    
    /**
     * 构建地点名称
     */
    private fun buildLocationName(location: AMapLocation): String {
        return when {
            !location.address.isNullOrEmpty() -> location.address
            !location.description.isNullOrEmpty() -> location.description
            else -> {
                val parts = mutableListOf<String>()
                if (!location.province.isNullOrEmpty()) parts.add(location.province)
                if (!location.city.isNullOrEmpty()) parts.add(location.city)
                if (!location.district.isNullOrEmpty()) parts.add(location.district)
                if (!location.street.isNullOrEmpty()) parts.add(location.street)
                if (!location.streetNum.isNullOrEmpty()) parts.add(location.streetNum + "号")
                parts.joinToString("")
            }
        }
    }
    
    /**
     * 发送定位数据到服务器
     */
    private suspend fun sendLocationToServer(token: String, locationArray: JSONArray): Boolean {
        return withContext(Dispatchers.IO) {
            var connection: HttpURLConnection? = null
            try {
                // 获取基础 URL
                val baseUrl = sharedPreferences.getString(KEY_BASE_URL, "https://service-api.ikissu.cn")
                val apiUrl = "$baseUrl/location/report"
                val userId = sharedPreferences.getString(KEY_USER_ID, "")
                
                Log.d(TAG, "🚀 开始上报定位数据")
                Log.d(TAG, "📡 API地址: $apiUrl")
                Log.d(TAG, "📦 上报数据: ${locationArray.toString()}")
                
                // 准备请求头
                val headers = mutableMapOf(
                    "Content-Type" to "application/json; charset=UTF-8",
                    "Accept" to "application/json",
                    "token" to token,
                    "version" to getAppVersion(),
                    "pkg" to context.packageName,
                    "deviceid" to getDeviceId(),
                    "channel" to "kissu_android", // 渠道标识
                    "os" to "1", // 1 = Android
                    "model" to Build.MODEL,
                    "osversion" to Build.VERSION.RELEASE,
                    "timestamp" to System.currentTimeMillis().toString()
                )
                
                // 添加 userId（如果存在）
                if (!userId.isNullOrEmpty()) {
                    headers["userid"] = userId
                }
                
                // 准备请求体参数（用于签名）
                val bodyParams = mapOf(
                    "locations" to locationArray.toString()
                )
                
                // 生成签名
                val sign = generateSign(headers, bodyParams)
                headers["sign"] = sign
                
                Log.d(TAG, "🔐 签名已生成: $sign")
                
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
                    put("locations", locationArray.toString())
                }
                
                // 发送请求
                OutputStreamWriter(connection.outputStream, Charsets.UTF_8).use { writer ->
                    writer.write(requestBody.toString())
                    writer.flush()
                }
                
                // 读取响应
                val responseCode = connection.responseCode
                Log.d(TAG, "📡 HTTP响应码: $responseCode")
                
                if (responseCode == HttpURLConnection.HTTP_OK) {
                    val response = connection.inputStream.bufferedReader().use { it.readText() }
                    Log.d(TAG, "📡 服务器响应: $response")
                    
                    // 解析响应
                    val jsonResponse = JSONObject(response)
                    val code = jsonResponse.optInt("code", -1)
                    
                    if (code == 0) {
                        Log.d(TAG, "✅ 定位上报成功")
                        return@withContext true
                    } else {
                        Log.w(TAG, "❌ 定位上报失败: ${jsonResponse.optString("msg")}")
                        return@withContext false
                    }
                } else {
                    val errorResponse = connection.errorStream?.bufferedReader()?.use { it.readText() } ?: ""
                    Log.w(TAG, "❌ HTTP请求失败: $responseCode, $errorResponse")
                    return@withContext false
                }
            } catch (e: Exception) {
                Log.e(TAG, "💥 发送定位数据异常", e)
                return@withContext false
            } finally {
                connection?.disconnect()
            }
        }
    }
    
    /**
     * 更新最后收集信息
     */
    private fun updateLastCollectionInfo(location: AMapLocation) {
        sharedPreferences.edit().apply {
            putLong(KEY_LAST_REPORT_TIME, System.currentTimeMillis())
            putString(KEY_LAST_REPORT_LAT, location.latitude.toString())
            putString(KEY_LAST_REPORT_LNG, location.longitude.toString())
            apply()
        }
        Log.d(TAG, "📍 最后收集位置已更新: ${location.latitude}, ${location.longitude}")
    }
    
    /**
     * 计算两点之间的距离（米）
     * 与Flutter层的距离计算保持一致
     */
    private fun calculateDistance(lat1: Double, lng1: Double, lat2: Double, lng2: Double): Double {
        val earthRadius = 6371000.0 // 地球半径，单位：米
        
        val dLat = Math.toRadians(lat2 - lat1)
        val dLng = Math.toRadians(lng2 - lng1)
        
        val a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) *
                Math.sin(dLng / 2) * Math.sin(dLng / 2)
        
        val c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
        
        return earthRadius * c
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
     * 获取设备 ID（使用 Android ID）
     */
    private fun getDeviceId(): String {
        return try {
            android.provider.Settings.Secure.getString(
                context.contentResolver,
                android.provider.Settings.Secure.ANDROID_ID
            ) ?: "unknown"
        } catch (e: Exception) {
            Log.e(TAG, "获取设备ID失败", e)
            "unknown"
        }
    }
    
    /**
     * 保存用户 Token（供 Flutter 调用）
     */
    fun saveUserToken(token: String, userId: String) {
        sharedPreferences.edit().apply {
            putString(KEY_USER_TOKEN, token)
            putString(KEY_USER_ID, userId)
            apply()
        }
        Log.d(TAG, "✅ 用户Token已保存: $userId")
    }
    
    /**
     * 保存 API 基础 URL（供 Flutter 调用）
     */
    fun saveBaseUrl(baseUrl: String) {
        sharedPreferences.edit().apply {
            putString(KEY_BASE_URL, baseUrl)
            apply()
        }
        Log.d(TAG, "✅ API基础URL已保存: $baseUrl")
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
        synchronized(collectionBuffer) {
            collectionBuffer.clear()
        }
        
        // 清除SharedPreferences
        sharedPreferences.edit().apply {
            remove(KEY_USER_TOKEN)
            remove(KEY_USER_ID)
            remove(KEY_LAST_REPORT_TIME)
            remove(KEY_LAST_REPORT_LAT)
            remove(KEY_LAST_REPORT_LNG)
            apply()
        }
        Log.d(TAG, "🗑️ 用户信息、定时器和缓冲区已清除")
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
        
        // Log.d(TAG, "🔐 签名参数汇总: $allParams")
        
        // 按 key ASCII 升序排序
        val sortedKeys = allParams.keys.sorted()
        // Log.d(TAG, "🔐 排序后的key: $sortedKeys")
        
        // 拼接所有 value
        val signBuilder = StringBuilder()
        sortedKeys.forEach { key ->
            val value = allParams[key]
            signBuilder.append(value)
            // Log.d(TAG, "🔐 拼接参数 $key = $value")
        }
        
        // 拼接密钥
        signBuilder.append(secretKey)
        
        // 生成 MD5 并转大写
        val signString = signBuilder.toString()
        // Log.d(TAG, "🔐 完整签名字符串: $signString")
        
        val signature = md5(signString).uppercase()
        // Log.d(TAG, "🔐 最终签名: $signature")
        
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
        synchronized(collectionBuffer) {
            collectionBuffer.clear()
        }
        
        // 取消协程
        coroutineScope.cancel()
        Log.d(TAG, "LocationReportService 已销毁")
    }
}


