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
        
        // 上报策略
        private const val MIN_REPORT_INTERVAL_SECONDS = 60 // 最小上报间隔60秒
        private const val MIN_REPORT_DISTANCE_METERS = 50.0 // 最小上报距离50米
    }
    
    private val sharedPreferences: SharedPreferences = 
        context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
    
    private val coroutineScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    
    /**
     * 上报单个定位数据
     */
    fun reportLocation(location: AMapLocation) {
        coroutineScope.launch {
            try {
                // 检查是否需要上报
                if (!shouldReport(location)) {
                    Log.d(TAG, "📍 定位数据不满足上报条件，跳过")
                    return@launch
                }
                
                // 检查 token 是否存在
                val token = sharedPreferences.getString(KEY_USER_TOKEN, null)
                val userId = sharedPreferences.getString(KEY_USER_ID, null)
                val baseUrl = sharedPreferences.getString(KEY_BASE_URL, null)
                
                Log.d(TAG, "🔑 读取用户信息: token=${if (token.isNullOrEmpty()) "空" else "已存在(${token.take(20)}...)"}, userId=$userId, baseUrl=$baseUrl")
                
                if (token.isNullOrEmpty()) {
                    Log.w(TAG, "⚠️ 用户未登录，无法上报定位数据")
                    return@launch
                }
                
                // 构建上报数据
                val locationData = buildLocationData(location)
                val locationArray = JSONArray().apply {
                    put(locationData)
                }
                
                // 发送 HTTP 请求
                val success = sendLocationToServer(token, locationArray)
                
                if (success) {
                    Log.d(TAG, "✅ 定位上报成功: ${location.latitude}, ${location.longitude}")
                    updateLastReportInfo(location)
                } else {
                    Log.w(TAG, "❌ 定位上报失败")
                }
            } catch (e: Exception) {
                Log.e(TAG, "💥 定位上报异常", e)
            }
        }
    }
    
    /**
     * 检查是否需要上报
     * ✅ 增强策略：
     * 1. 首次定位必报
     * 2. 精度过滤：accuracy > 100米的位置不上报
     * 3. 时间触发：距离上次上报超过60秒
     * 4. 距离触发：距离上次上报位置超过50米（且间隔≥10秒，防抖）
     * 5. 速度触发：高速移动时（>20m/s，约72km/h）提高上报频率（30秒）
     */
    private fun shouldReport(location: AMapLocation): Boolean {
        // 检查定位是否有效
        if (location.errorCode != 0) {
            Log.d(TAG, "⚠️ 定位失败，错误码: ${location.errorCode}")
            return false
        }
        
        // ✅ 1. 精度过滤
        if (location.accuracy > 100.0) {
            Log.d(TAG, "⚠️ 精度不足(${location.accuracy}m > 100m)，跳过上报")
            return false
        }
        
        val currentTime = System.currentTimeMillis()
        val lastReportTime = sharedPreferences.getLong(KEY_LAST_REPORT_TIME, 0)
        
        // ✅ 2. 首次上报
        if (lastReportTime == 0L) {
            Log.d(TAG, "🚀 首次定位，立即上报 (精度: ${location.accuracy}m)")
            return true
        }
        
        val timeDiff = (currentTime - lastReportTime) / 1000 // 转换为秒
        
        // ✅ 3. 时间间隔检查（60秒）
        if (timeDiff >= MIN_REPORT_INTERVAL_SECONDS) {
            Log.d(TAG, "⏰ 时间触发上报: 距离上次上报${timeDiff}秒 (精度: ${location.accuracy}m)")
            return true
        }
        
        // ✅ 4. 距离检查（50米 + 最小10秒间隔防抖）
        val lastLat = sharedPreferences.getString(KEY_LAST_REPORT_LAT, null)?.toDoubleOrNull()
        val lastLng = sharedPreferences.getString(KEY_LAST_REPORT_LNG, null)?.toDoubleOrNull()
        
        if (lastLat != null && lastLng != null) {
            val distance = calculateDistance(
                lastLat, lastLng,
                location.latitude, location.longitude
            )
            
            if (distance >= MIN_REPORT_DISTANCE_METERS && timeDiff >= 10) {
                Log.d(TAG, "📍 距离触发上报: 移动${distance.toInt()}米 (精度: ${location.accuracy}m)")
                return true
            }
        }
        
        // ✅ 5. 速度检查：高速移动时提高上报频率
        if (location.speed > 20.0 && timeDiff >= 30) {
            Log.d(TAG, "🚀 高速移动触发上报: 速度${location.speed}m/s ≈ ${(location.speed * 3.6).toInt()}km/h")
            return true
        }
        
        Log.d(TAG, "📍 不满足上报条件: 时间${timeDiff}秒, 精度${location.accuracy}m, 速度${location.speed}m/s")
        return false
    }
    
    /**
     * 构建定位数据 JSON
     */
    private fun buildLocationData(location: AMapLocation): JSONObject {
        val locationTime = location.time // 定位时间戳
        
        return JSONObject().apply {
            put("longitude", location.longitude.toString())
            put("latitude", location.latitude.toString())
            put("location_time", locationTime.toString())
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
                    
                    if (code == 200) {
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
     * 更新最后上报信息
     */
    private fun updateLastReportInfo(location: AMapLocation) {
        sharedPreferences.edit().apply {
            putLong(KEY_LAST_REPORT_TIME, System.currentTimeMillis())
            putString(KEY_LAST_REPORT_LAT, location.latitude.toString())
            putString(KEY_LAST_REPORT_LNG, location.longitude.toString())
            apply()
        }
    }
    
    /**
     * 计算两点之间的距离（米）
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
        sharedPreferences.edit().apply {
            remove(KEY_USER_TOKEN)
            remove(KEY_USER_ID)
            remove(KEY_LAST_REPORT_TIME)
            remove(KEY_LAST_REPORT_LAT)
            remove(KEY_LAST_REPORT_LNG)
            apply()
        }
        Log.d(TAG, "🗑️ 用户信息已清除")
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
        
        Log.d(TAG, "🔐 签名参数汇总: $allParams")
        
        // 按 key ASCII 升序排序
        val sortedKeys = allParams.keys.sorted()
        Log.d(TAG, "🔐 排序后的key: $sortedKeys")
        
        // 拼接所有 value
        val signBuilder = StringBuilder()
        sortedKeys.forEach { key ->
            val value = allParams[key]
            signBuilder.append(value)
            Log.d(TAG, "🔐 拼接参数 $key = $value")
        }
        
        // 拼接密钥
        signBuilder.append(secretKey)
        
        // 生成 MD5 并转大写
        val signString = signBuilder.toString()
        Log.d(TAG, "🔐 完整签名字符串: $signString")
        
        val signature = md5(signString).uppercase()
        Log.d(TAG, "🔐 最终签名: $signature")
        
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
        coroutineScope.cancel()
        Log.d(TAG, "LocationReportService 已销毁")
    }
}

