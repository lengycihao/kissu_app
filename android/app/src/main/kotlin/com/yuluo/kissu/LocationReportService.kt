package com.yuluo.kissu

import android.Manifest
import android.content.Context
import com.yuluo.kissu.constants.AppConstants
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import android.os.BatteryManager
import android.os.Build
import android.app.NotificationChannel
import android.app.NotificationManager
import androidx.core.content.ContextCompat
import androidx.core.app.NotificationCompat
import com.amap.api.location.AMapLocation
import io.flutter.Log
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.ForegroundInfo
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import kotlinx.coroutines.*
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
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
        const val COLLECTION_DISTANCE_METERS = 50 // 50米收集距离，与Flutter层 <50m 丢弃一致
        const val REPORT_INTERVAL_SECONDS = 60 // 1分钟上报间隔
        const val FORCE_COLLECT_INTERVAL_SECONDS = 60 // 🔥 强制收集间隔：即使距离不足，超过此时间也必须收集
        const val MAX_COLLECTION_BUFFER_SIZE = 12 // 1分钟最多12个点(5秒一个)
        const val MAX_CACHE_POOL_SIZE = 200 // 防御性上限，避免失败时无限增长
        const val WORK_UNIQUE_NAME = "location_report_restart"
        // 与 ForegroundLocationService 保持一致的通知渠道与文案
        const val WORKER_CHANNEL_ID = "kissu_location_service"
        const val WORKER_CHANNEL_NAME = "定位服务"
        
        // 🔥 关键修复：将定时器和缓冲区改为静态变量，避免多实例导致多个定时器同时运行
        // 收集缓冲区，与Flutter层策略保持一致
        private val collectionBuffer = mutableListOf<JSONObject>()
        // 序列化上报，避免并发重复发送
        private val isReporting = AtomicBoolean(false)
        // 定时器相关 - 静态确保全局唯一
        private var reportTimer: Timer? = null
        private var isReportTimerRunning = false
        @Volatile
        private var lastTimerFireTime: Long = 0L
        // 保存最后收到的位置信息（无论是否收集到缓冲区）
        @Volatile
        private var lastReceivedLocation: AMapLocation? = null
        @Volatile
        private var lastReceivedLocationTime: Long = 0
        // 协程作用域 - 静态确保全局唯一
        private val coroutineScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

        // === WiFi 静止锚点：连WiFi且真实未移动时，锁定上报初始位置，避免室内GPS漂移 ===
        // 判断移动的速度阈值 (m/s)，超过此值认为用户在移动（含热点驾车场景）
        // 1.5 m/s ≈ 5.4 km/h，低速步行触发需结合位置偏差双重确认
        private const val WIFI_MOVING_SPEED_MS = 1.5f
        // 距锚点超过此距离(米)时，认为用户真实移动，重置锚点
        private const val WIFI_STATIONARY_DISTANCE_M = 80.0
        // 需要连续这么多次低速+近锚点才确认静止，防止启动瞬间误判
        private const val WIFI_STATIONARY_CONFIRM_COUNT = 3
        // WiFi 静止锚点位置
        @Volatile private var wifiAnchorLocation: AMapLocation? = null
        // 连续静止确认计数
        @Volatile private var wifiStationaryCount: Int = 0

        // === WiFi 学习机制：记住每个 WiFi 是室内固定还是移动WiFi ===
        private const val WIFI_TYPE_UNKNOWN = 0      // 未知，需要学习
        private const val WIFI_TYPE_STATIONARY = 1   // 室内固定WiFi → 走锚点逻辑
        private const val WIFI_TYPE_MOBILE = 2       // 移动WiFi（车载/便携）→ 走正常上报
        private const val KEY_WIFI_CLASSIFICATIONS = "wifi_classifications"
        private const val WIFI_MAX_STORED = 50       // 最多记录50个WiFi，防止无限增长
        // 连续检测到移动多少次才标记为移动WiFi
        private const val WIFI_LEARN_MOVING_THRESHOLD = 3
        // 已标记为室内的WiFi，连续多少次高速移动后降级为UNKNOWN重新学习（纠错机制）
        private const val WIFI_RECLASSIFY_THRESHOLD = 5
        // 当前正在观察的 WiFi BSSID
        @Volatile private var currentLearningBssid: String? = null
        // 连续移动观察计数（用于学习未知WiFi + 纠错已知WiFi）
        @Volatile private var wifiLearnMovingCount: Int = 0

        // === 室内WiFi省电暂停：确认室内WiFi后停止定位收集和上报，节省资源 ===
        @Volatile private var isStationaryWifiPaused: Boolean = false
        @Volatile private var pausedWifiBssid: String? = null
    }
    
    private val sharedPreferences: SharedPreferences = 
        context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
    
    // 避免老数据循环：超过此时间窗口的旧点会在收集/上报前被清理
    private val staleDurationMs = TimeUnit.HOURS.toMillis(1)
    
    /**
     * 处理定位数据（与Flutter层策略保持一致）
     * 1. 检查是否需要收集
     * 2. 收集到缓冲区
     * 3. 启动定时上报器
     */
    fun reportLocation(location: AMapLocation) {
        coroutineScope.launch {
            try {
                // === 室内WiFi省电暂停检查 ===
                if (isStationaryWifiPaused) {
                    val currentBssid = getConnectedWifiBssid()
                    val stillOnSameWifi = isWifiConnected() && currentBssid != null && currentBssid == pausedWifiBssid
                    if (stillOnSameWifi) {
                        // 仍在同一个室内WiFi，跳过所有定位处理（省电）
                        return@launch
                    }
                    // WiFi已变化或断开，恢复定位
                    resumeFromStationaryWifi("WiFi变化: $pausedWifiBssid → $currentBssid")
                }

                // 🔥 关键修复：无论是否收集到缓冲区，都保存最后收到的位置
                // 这样定时上报时即使缓冲区为空，也能上报当前位置
                if (location.errorCode == 0) {
                    lastReceivedLocation = location
                    lastReceivedLocationTime = System.currentTimeMillis()
                }

                // WiFi+静止锚点：当连接WiFi且用户真实未移动时，用锚点替换漂移的GPS位置
                val effectiveLocation = if (location.errorCode == 0) resolveReportLocation(location) else location
                
                // 🔥 关键检查：resolveReportLocation 内部可能刚触发了室内WiFi暂停，此时必须跳过后续收集和上报
                if (isStationaryWifiPaused) {
                    Log.w(TAG, "⏸️ 室内WiFi暂停已激活，跳过收集和上报")
                    return@launch
                }
                
                // 检查网络状态（仅用于日志和控制是否尝试立即上报，不再阻断收集）
                val networkAvailable = isNetworkAvailable()
                if (!networkAvailable) {
                    Log.d(TAG, "📡 当前无网络，继续收集定位数据到缓冲区，等待网络恢复后上报")
                }

                // 检查是否需要收集定位
                if (!shouldCollectLocation(effectiveLocation)) {
                    return@launch
                }
                
                // 检查 token 是否存在
                val token = sharedPreferences.getString(KEY_USER_TOKEN, null)
                val userId = sharedPreferences.getString(KEY_USER_ID, null)
                val baseUrl = sharedPreferences.getString(KEY_BASE_URL, null)
                
                val tokenInfo = if (token.isNullOrEmpty()) "空" else "已存在(${token.take(20)}...)"
                Log.d(TAG, "🔑 读取用户信息: token=$tokenInfo, userId=$userId, baseUrl=$baseUrl")
                
                if (token.isNullOrEmpty()) {
                    Log.w(TAG, "⚠️ 用户未登录，无法收集定位数据")
                    return@launch
                }
                
                // 构建定位数据并加入收集缓冲区
                val locationData = buildLocationData(effectiveLocation)
                synchronized(collectionBuffer) {
                    pruneStaleLocationsLocked()
                    // 防御性上限：超过容量时丢弃最旧，防止无限增长
                    if (collectionBuffer.size >= MAX_CACHE_POOL_SIZE) {
                        collectionBuffer.removeAt(0)
                        Log.w(TAG, "🧹 缓冲池超上限(${collectionBuffer.size + 1}/$MAX_CACHE_POOL_SIZE)，已丢弃最旧一个点")
                    }
                    collectionBuffer.add(locationData)
                    Log.d(TAG, "📦 位置已收集到缓冲区 (${collectionBuffer.size}/${MAX_COLLECTION_BUFFER_SIZE}): ${location.latitude}, ${location.longitude}")
                    
                    // 如果缓冲区满了且有网络，立即上报；无网络时跳过（数据保留在缓冲区，等网络恢复）
                    if (collectionBuffer.size >= MAX_COLLECTION_BUFFER_SIZE && networkAvailable) {
                        Log.d(TAG, "⚠️ 缓冲区已满，触发立即上报")
                        performImmediateReport(token)
                    }
                }
                
                // 有网络时启动/维持定时上报器；无网络时跳过（下次有网络的 reportLocation 调用会启动）
                if (networkAvailable) {
                    startReportTimer(token)
                }
                
                // 更新最后收集的位置信息
                updateLastCollectionInfo(effectiveLocation)
                
            } catch (e: Exception) {
                Log.e(TAG, "💥 定位处理异常", e)
            }
        }
    }
    
    /**
     * 启动定时上报器（与Flutter�?分钟间隔保持一致）
     */
    private fun startReportTimer(token: String) {
        // 已运行则不重复重启，避免频繁 cancel/recreate
        if (reportTimer != null && isReportTimerRunning) {
            return
        }
        // 防御：若 timer 引用存在但标记为 false，先清理
        if (reportTimer != null && !isReportTimerRunning) {
            reportTimer?.cancel()
            reportTimer = null
        }
        
        // 创建新的定时器
        // 🔥 关键修复：定时任务中每次都从SharedPreferences读取最新token，而不是使用创建时的token
        // 这样切换账号后，定时器会自动使用新token
        // 🔥 捕获当前实例引用，确保定时器回调中能正确访问实例方法
        val serviceInstance = this
        reportTimer = Timer().apply {
            schedule(object : TimerTask() {
                override fun run() {
                    lastTimerFireTime = System.currentTimeMillis()
                    // 每次都从SharedPreferences读取最新token，确保切换账号后使用新token
                    val currentToken = serviceInstance.sharedPreferences.getString(KEY_USER_TOKEN, null)
                    if (currentToken.isNullOrEmpty()) {
                        Log.w(TAG, "⚠️ 定时上报：token为空，跳过上报")
                        return
                    }
                    serviceInstance.performScheduledReport(currentToken)
                }
            }, REPORT_INTERVAL_SECONDS * 1000L, REPORT_INTERVAL_SECONDS * 1000L)
        }
        isReportTimerRunning = true
        Log.d(TAG, "⏰ 定时上报器已启动，间隔: ${REPORT_INTERVAL_SECONDS}秒")

        // 启动 WorkManager 兜底：若定时器被杀，尝试重启服务与定时器
        scheduleOneTimeRestartWork()
    }
    
    /**
     * 确保定时上报器在运行（供健康检查调用）
     * 如果定时器未运行且有 token，则重新启动定时器
     */
    fun ensureReportTimerRunning() {
        // 室内WiFi暂停中，不需要定时器
        if (isStationaryWifiPaused) {
            Log.d(TAG, "🔍 保活检查：室内WiFi暂停中，跳过定时器检查")
            return
        }
        val token = sharedPreferences.getString(KEY_USER_TOKEN, null)
        if (token.isNullOrEmpty()) {
            Log.d(TAG, "🔍 保活检查：无 token，跳过定时器检查")
            return
        }
        
        // 检查定时器是否真的在运行
        val timerRunning = reportTimer != null && isReportTimerRunning
        
        // 🔥 关键修复：即使定时器标记为运行中，也检查是否真的在正常触发
        // Android Doze 模式下 java.util.Timer 线程可能被系统冻结，导致定时器停滞
        val timerStale = timerRunning && lastTimerFireTime > 0 && 
            (System.currentTimeMillis() - lastTimerFireTime) > REPORT_INTERVAL_SECONDS * 2 * 1000L
        
        if (!timerRunning || timerStale) {
            Log.w(TAG, "⚠️ 保活检查：定时器${if (timerStale) "已停滞（可能被Doze冻结）" else "未运行"}，重新启动")
            // 强制重启定时器
            reportTimer?.cancel()
            reportTimer = null
            isReportTimerRunning = false
            startReportTimer(token)
            scheduleOneTimeRestartWork()
            
            // 🔥 定时器重启后立即尝试上报，避免数据长时间滞留在缓冲区
            performScheduledReport(token)
        } else {
            Log.d(TAG, "✅ 保活检查：定时器运行正常")
        }
    }

    /**
     * 使用 WorkManager 单次兜底，延迟短时间后尝试重启服务/定时器。
     * 避免系统将周期 WorkManager 拉高到15分钟。
     */
    private fun scheduleOneTimeRestartWork() {
        try {
            val workRequest = OneTimeWorkRequestBuilder<LocationReportWorker>()
                .setInitialDelay(2, TimeUnit.MINUTES) // 兜底延迟，避免与常规60s定时冲突
                .build()

            WorkManager.getInstance(context).enqueueUniqueWork(
                WORK_UNIQUE_NAME,
                ExistingWorkPolicy.REPLACE,
                workRequest
            )
            Log.d(TAG, "🛠️ 已调度 WorkManager 单次兜底任务（2分钟后尝试重启服务/定时器）")
        } catch (e: Exception) {
            Log.e(TAG, "调度 WorkManager 单次兜底失败", e)
        }
    }
    
    /**
     * 执行定时上报
     */
    private fun performScheduledReport(token: String) {
        coroutineScope.launch {
            // 🔥 室内WiFi暂停中，跳过定时上报
            if (isStationaryWifiPaused) {
                Log.d(TAG, "⏰ 定时上报跳过：室内WiFi暂停中")
                return@launch
            }
            // 避免并发重复发送
            if (!isReporting.compareAndSet(false, true)) {
                Log.w(TAG, "⏰ 定时上报跳过：已有上报进行中")
                return@launch
            }
            try {
                val locationsToReport: JSONArray
                val bufferSize: Int
                var usedLastReceivedLocation = false
                
                // 在synchronized块内拷贝数据，避免在同步代码块内调用挂起函数
                synchronized(collectionBuffer) {
                    pruneStaleLocationsLocked()
                    
                    // 🔥 关键修复：缓冲区为空时，使用最后收到的位置进行上报
                    // 确保即使用户静止不动，也能定期上报当前位置
                    if (collectionBuffer.isEmpty()) {
                        val lastLocation = lastReceivedLocation
                        val lastLocationAge = System.currentTimeMillis() - lastReceivedLocationTime
                        
                        // 检查最后位置是否有效（5分钟内收到的位置）
                        if (lastLocation != null && lastLocation.errorCode == 0 && lastLocationAge < 5 * 60 * 1000L) {
                            Log.d(TAG, "📦 缓冲区为空，使用最后收到的位置上报: ${lastLocation.latitude}, ${lastLocation.longitude}")
                            locationsToReport = JSONArray()
                            locationsToReport.put(buildLocationData(lastLocation))
                            bufferSize = 1
                            usedLastReceivedLocation = true
                        } else {
                            Log.d(TAG, "📦 缓冲区为空且无有效的最后位置（age=${lastLocationAge/1000}秒），跳过定时上报")
                            return@launch
                        }
                    } else {
                        locationsToReport = JSONArray()
                        collectionBuffer.forEach { locationData ->
                            locationsToReport.put(locationData)
                        }
                        bufferSize = collectionBuffer.size
                    }
                }
                
                Log.d(TAG, "⏰ 执行定时上报，位置数量: $bufferSize${if (usedLastReceivedLocation) "（使用最后位置）" else ""}")
                
                // 在synchronized块外调用挂起函数
                val success = sendLocationToServer(token, locationsToReport)
                
                // 根据结果处理缓冲区
                synchronized(collectionBuffer) {
                    if (success) {
                        if (!usedLastReceivedLocation) {
                            collectionBuffer.clear()
                        }
                        Log.d(TAG, "✅ 定时上报成功，缓冲区已清空")
                    } else {
                        Log.w(TAG, "❌ 定时上报失败，缓冲区保留数据")
                    }
                }
                
                // 🔥 上报成功时写入文件日志（附带上报的点位信息）
                if (success) {
                    logReportSuccess(locationsToReport, usedLastReceivedLocation)
                    // 🔥 上报成功后刷新桌面小组件数据
                    triggerWidgetUpdate()
                }
            } finally {
                isReporting.set(false)
            }
        }
    }
    
    /**
     * 执行立即上报（缓冲区满时�?
     */
    private fun performImmediateReport(token: String) {
        coroutineScope.launch {
            // 避免并发重复发送
            if (!isReporting.compareAndSet(false, true)) {
                Log.w(TAG, "⚡ 立即上报跳过：已有上报进行中")
                return@launch
            }
            try {
                val locationsToReport: JSONArray
                val bufferSize: Int
                
                // 在synchronized块内拷贝数据，避免在同步代码块内调用挂起函数
                synchronized(collectionBuffer) {
                    pruneStaleLocationsLocked()
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
                
                // 🔥 上报成功时写入文件日志（附带上报的点位信息）
                if (success) {
                    logReportSuccess(locationsToReport, false)
                    // 🔥 上报成功后刷新桌面小组件数据
                    triggerWidgetUpdate()
                }
            } finally {
                isReporting.set(false)
            }
        }
    }
    
    /**
     * 解析实际应上报的位置
     *
     * WiFi+静止场景：室内 GPS 受多径干扰容易漂移，导致轨迹乱跳。
     * 当检测到用户连接 WiFi 且真实未移动时，锁定到最初的锚点位置上报，
     * 而非持续漂移的 GPS 坐标。
     *
     * 移动判断双重保险：
     * 1. GPS 速度 > WIFI_MOVING_SPEED_MS（覆盖手机热点+驾车场景）
     * 2. 累积位移 > WIFI_STATIONARY_DISTANCE_M（兜底慢速移动）
     * 只要任意一项超出阈值，立即释放锚点，切回真实位置上报。
     */
    private fun resolveReportLocation(location: AMapLocation): AMapLocation {
        if (!isWifiConnected()) {
            if (wifiAnchorLocation != null) {
                Log.d(TAG, "📶 WiFi 已断开，清除静止锚点")
                wifiAnchorLocation = null
                wifiStationaryCount = 0
            }
            currentLearningBssid = null
            wifiLearnMovingCount = 0
            return location
        }

        // 获取当前 WiFi BSSID，用于学习机制
        val bssid = getConnectedWifiBssid()
        resetWifiLearningState(bssid) // WiFi 切换时重置学习计数

        // ====== 已学习的 WiFi：直接走对应逻辑，跳过学习阶段 ======
        if (bssid != null) {
            val classification = getWifiClassification(bssid)

            // 已知移动WiFi → 跳过锚点，走正常定位上报
            if (classification == WIFI_TYPE_MOBILE) {
                if (wifiAnchorLocation != null) {
                    Log.d(TAG, "📶 已知移动WiFi[$bssid]，清除锚点，走正常上报")
                    wifiAnchorLocation = null
                    wifiStationaryCount = 0
                }
                return location
            }

            // 已知室内WiFi → 但仍需先检查速度（纠错：防止误标记的热点被永远当室内处理）
            if (classification == WIFI_TYPE_STATIONARY) {
                val speed = location.speed
                if (speed > WIFI_MOVING_SPEED_MS) {
                    // 已知"室内"WiFi 却在高速移动 → 可能是误判，累积纠错计数
                    wifiLearnMovingCount++
                    if (wifiLearnMovingCount >= WIFI_RECLASSIFY_THRESHOLD) {
                        // 连续多次高速移动 → 降级为UNKNOWN，重新学习
                        setWifiClassification(bssid, WIFI_TYPE_UNKNOWN)
                        wifiLearnMovingCount = 0
                        Log.d(TAG, "🔄 室内WiFi[$bssid]连续${WIFI_RECLASSIFY_THRESHOLD}次高速移动，降级为未知重新学习")
                    } else {
                        Log.d(TAG, "⚠️ 室内WiFi但速度${speed}m/s，纠错观察($wifiLearnMovingCount/$WIFI_RECLASSIFY_THRESHOLD)")
                    }
                    wifiAnchorLocation = null
                    wifiStationaryCount = 0
                    return location // 高速移动时始终上报真实位置
                }
                wifiLearnMovingCount = 0 // 低速时重置纠错计数
                return resolveStationaryWifi(location, skipConfirm = true, pauseBssid = bssid)
            }
        }

        // ====== 未知WiFi：边上报边学习 ======
        val speed = location.speed
        if (speed > WIFI_MOVING_SPEED_MS) {
            // 正在移动 → 累积移动计数
            wifiLearnMovingCount++
            if (bssid != null && wifiLearnMovingCount >= WIFI_LEARN_MOVING_THRESHOLD) {
                setWifiClassification(bssid, WIFI_TYPE_MOBILE)
            }
            Log.d(TAG, "🚗 WiFi+移动(${speed}m/s)，学习中($wifiLearnMovingCount/$WIFI_LEARN_MOVING_THRESHOLD)")
            wifiAnchorLocation = null
            wifiStationaryCount = 0
            return location
        }

        // 低速 → 走锚点逻辑（含学习）
        wifiLearnMovingCount = 0 // 低速时重置移动计数
        return resolveStationaryWifi(location, skipConfirm = false, learnBssid = bssid, pauseBssid = bssid)
    }

    /**
     * 处理 WiFi 静止锚点逻辑
     * @param skipConfirm 已知室内WiFi时跳过确认阶段，直接锁定锚点
     * @param learnBssid 非null时，确认静止后将该WiFi标记为室内固定
     */
    private fun resolveStationaryWifi(
        location: AMapLocation,
        skipConfirm: Boolean,
        learnBssid: String? = null,
        pauseBssid: String? = null
    ): AMapLocation {
        val anchor = wifiAnchorLocation
        if (anchor == null) {
            wifiAnchorLocation = location
            wifiStationaryCount = 1
            Log.d(TAG, "📍 WiFi+低速，建立初始锚点: ${location.latitude}, ${location.longitude}")
            // 已知室内WiFi且是首次建锚点，直接返回该位置（不需等确认）
            return location
        }

        val distFromAnchor = calculateDistance(
            anchor.latitude, anchor.longitude,
            location.latitude, location.longitude
        )

        return if (distFromAnchor < WIFI_STATIONARY_DISTANCE_M) {
            wifiStationaryCount++
            val confirmNeeded = if (skipConfirm) 1 else WIFI_STATIONARY_CONFIRM_COUNT
            if (wifiStationaryCount >= confirmNeeded) {
                // 确认静止 → 学习该WiFi为室内固定
                if (learnBssid != null && wifiStationaryCount == confirmNeeded) {
                    setWifiClassification(learnBssid, WIFI_TYPE_STATIONARY)
                }
                // 确认静止 → 进入省电暂停模式（停止后续定位收集和上报）
                if (!isStationaryWifiPaused && pauseBssid != null && wifiStationaryCount > confirmNeeded) {
                    enterStationaryWifiPause(pauseBssid)
                }
                Log.d(TAG, "🔒 WiFi+静止锁定(${wifiStationaryCount}次)，上报锚点 " +
                    "[${anchor.latitude},${anchor.longitude}]，GPS 实际偏差 ${distFromAnchor.toInt()}m")
                anchor
            } else {
                Log.d(TAG, "📍 WiFi+静止待确认(${wifiStationaryCount}/${confirmNeeded})")
                location
            }
        } else {
            // 距锚点超阈值：用户真实移动，重置锚点
            Log.d(TAG, "🚶 WiFi 下位移 ${distFromAnchor.toInt()}m >= ${WIFI_STATIONARY_DISTANCE_M.toInt()}m，重置锚点")
            wifiAnchorLocation = location
            wifiStationaryCount = 1
            location
        }
    }

    /**
     * 检查当前是否连接固定 WiFi（排除手机热点）
     * 手机热点虽然走 TRANSPORT_WIFI，但通常是计费网络（metered）
     * 只有非计费的固定 WiFi（家庭/办公）才启用静止锚点防漂移
     */
    private fun isWifiConnected(): Boolean {
        return try {
            val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val network = cm.activeNetwork ?: return false
            val caps = cm.getNetworkCapabilities(network) ?: return false
            if (!caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) return false
            // 排除手机热点：热点通常是计费网络（metered），固定WiFi通常非计费
            if (!caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED)) {
                Log.d(TAG, "📶 检测到计费WiFi（可能是手机热点），跳过静止锚点")
                return false
            }
            true
        } catch (e: Exception) {
            false
        }
    }

    /**
     * 获取当前连接的 WiFi BSSID（MAC地址，唯一标识一个WiFi接入点）
     */
    @Suppress("deprecation")
    private fun getConnectedWifiBssid(): String? {
        return try {
            val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            val info = wifiManager.connectionInfo
            val bssid = info?.bssid
            if (bssid != null && bssid != "02:00:00:00:00:00") bssid else null
        } catch (e: Exception) {
            null
        }
    }

    /**
     * 查询 WiFi BSSID 的已学习分类
     * @return WIFI_TYPE_UNKNOWN / WIFI_TYPE_STATIONARY / WIFI_TYPE_MOBILE
     */
    private fun getWifiClassification(bssid: String): Int {
        return try {
            val json = sharedPreferences.getString(KEY_WIFI_CLASSIFICATIONS, null) ?: return WIFI_TYPE_UNKNOWN
            val map = JSONObject(json)
            map.optInt(bssid, WIFI_TYPE_UNKNOWN)
        } catch (e: Exception) {
            WIFI_TYPE_UNKNOWN
        }
    }

    /**
     * 保存 WiFi BSSID 的分类（持久化到 SharedPreferences）
     * 超过 WIFI_MAX_STORED 条时淘汰最早的记录
     */
    private fun setWifiClassification(bssid: String, type: Int) {
        try {
            val json = sharedPreferences.getString(KEY_WIFI_CLASSIFICATIONS, null)
            val map = if (json != null) JSONObject(json) else JSONObject()
            map.put(bssid, type)
            // 超过上限时，删除最前面的 key（简单 FIFO 淘汰）
            if (map.length() > WIFI_MAX_STORED) {
                val firstKey = map.keys().next()
                map.remove(firstKey)
            }
            sharedPreferences.edit().putString(KEY_WIFI_CLASSIFICATIONS, map.toString()).apply()
            val typeName = when (type) {
                WIFI_TYPE_STATIONARY -> "室内固定"
                WIFI_TYPE_MOBILE -> "移动"
                else -> "未知"
            }
            Log.d(TAG, "🧠 WiFi学习完成: $bssid → $typeName")
        } catch (e: Exception) {
            Log.e(TAG, "保存WiFi分类失败: ${e.message}")
        }
    }

    /**
     * 当WiFi切换时重置学习状态
     */
    private fun resetWifiLearningState(newBssid: String?) {
        if (newBssid != currentLearningBssid) {
            currentLearningBssid = newBssid
            wifiLearnMovingCount = 0
        }
    }

    // === 室内WiFi省电暂停相关方法 ===

    /**
     * 进入室内WiFi省电暂停模式
     * 停止定位收集、上报定时器，等待网络变化后恢复
     */
    private fun enterStationaryWifiPause(bssid: String) {
        isStationaryWifiPaused = true
        pausedWifiBssid = bssid
        // 停止上报定时器
        reportTimer?.cancel()
        reportTimer = null
        isReportTimerRunning = false
        Log.w(TAG, "⏸️ 室内WiFi确认[$bssid]，进入省电暂停模式（停止定位收集和上报）")
    }

    /**
     * 从室内WiFi暂停中恢复（WiFi断开或切换时调用）
     */
    fun resumeFromStationaryWifi(reason: String = "") {
        if (!isStationaryWifiPaused) return
        isStationaryWifiPaused = false
        pausedWifiBssid = null
        wifiAnchorLocation = null
        wifiStationaryCount = 0
        wifiLearnMovingCount = 0
        Log.w(TAG, "▶️ 室内WiFi暂停已解除${if (reason.isNotEmpty()) "（$reason）" else ""}，恢复定位和上报")
    }

    /**
     * 查询当前是否处于室内WiFi省电暂停状态
     */
    fun isLocationPausedForStationaryWifi(): Boolean = isStationaryWifiPaused

    /**
     * 检查是否需要收集定位
     * 策略：
     * 1. 首次定位必收集
     * 2. 收集池为空时直接放入
     * 3. 收集池不为空时，距离>=50米时收集，否则丢弃
     * 4. 每1分钟上报一次收集到的位置
     */
    private fun shouldCollectLocation(location: AMapLocation): Boolean {
        // 检查定位是否有效
        if (location.errorCode != 0) {
            Log.w(TAG, "⚠️ 定位失败，错误码: ${location.errorCode}")
            return false
        }
        
        // 🔥 修复：检查收集池是否为空，为空时直接放入（与Flutter层策略一致）
        val isBufferEmpty: Boolean
        synchronized(collectionBuffer) {
            isBufferEmpty = collectionBuffer.isEmpty()
        }
        if (isBufferEmpty) {
            Log.d(TAG, "📦 收集池为空，直接放入: ${location.latitude}, ${location.longitude}, 精度: ${location.accuracy}m")
            return true
        }
        
        val lastReportTime = sharedPreferences.getLong(KEY_LAST_REPORT_TIME, 0)
        
        // 首次定位必收集
        if (lastReportTime == 0L) {
            Log.d(TAG, "🚀 首次定位，必须收集: ${location.latitude}, ${location.longitude}, 精度: ${location.accuracy}m")
            return true
        }
        
        // 🔥 关键修复：即使距离不足，超过强制收集间隔也必须收集
        // 解决用户静止不动时位置不更新的问题
        val timeSinceLastCollection = System.currentTimeMillis() - lastReportTime
        val forceCollectDue = timeSinceLastCollection >= FORCE_COLLECT_INTERVAL_SECONDS * 1000L
        
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
            } else if (forceCollectDue) {
                // 🔥 关键修复：距离不足但时间已到，强制收集
                Log.d(TAG, "⏰ 时间触发强制收集: 距离${distance.toInt()}米 < ${COLLECTION_DISTANCE_METERS}米，但已超过${FORCE_COLLECT_INTERVAL_SECONDS}秒 (精度: ${location.accuracy}m)")
                return true
            } else {
                Log.d(TAG, "📍 距离不足且时间未到，跳过收集: 移动${distance.toInt()}米 < ${COLLECTION_DISTANCE_METERS}米，距上次收集${timeSinceLastCollection/1000}秒")
                return false
            }
        }
        
        // 🔥 如果没有上次位置记录但时间已到，也应该收集
        if (forceCollectDue) {
            Log.d(TAG, "⏰ 无上次位置记录，时间触发强制收集")
            return true
        }
        
        return false
    }

    /**
     * 清理过期的定位点（持有锁时调用）
     */
    private fun pruneStaleLocationsLocked() {
        if (collectionBuffer.isEmpty()) return
        val nowSec = System.currentTimeMillis() / 1000
        val iterator = collectionBuffer.iterator()
        var removed = 0
        while (iterator.hasNext()) {
            val item = iterator.next()
            val ts = item.optString("location_time").toLongOrNull()
            if (ts != null && (nowSec - ts * 1L) * 1000 > staleDurationMs) {
                iterator.remove()
                removed++
            }
        }
        if (removed > 0) {
            Log.w(TAG, "🗑️ 已移除过期定位点: $removed 条")
        }
    }
    
    /**
     * 构建定位数据 JSON
     */
    private fun buildLocationData(location: AMapLocation): JSONObject {
        // 转换为10位时间戳（秒）
        // 为避免缓存定位返回的旧时间戳，这里统一使用当前上报时间
        val locationTime = (System.currentTimeMillis() / 1000).toString()
        
        return JSONObject().apply {
            put("longitude", location.longitude.toString())
            put("latitude", location.latitude.toString())
            put("location_time", locationTime) // 10位时间戳
            put("speed", location.speed.toString())
            put("altitude", location.altitude.toString())
            put("accuracy", location.accuracy.toString())
            // put("location_name", buildLocationName(location))
            put("location_name", "")
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
                    "channel" to (sharedPreferences.getString("app_channel", null) ?: "kissu_android"), // 渠道标识（优先从Flutter同步的配置读取）
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
                
                // 添加 Android ID（隐私合规后才添加）
                val androidId = getAndroidId()
                if (!androidId.isNullOrEmpty()) {
                    headers["androidid"] = androidId
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
     * 🔥 修复：在用户同意隐私政策前不获取 ANDROID ID，返回降级值
     */
    private fun getDeviceId(): String {
        // 🔥 关键修复：检查隐私政策是否已同意
        if (!isPrivacyPolicyAgreed()) {
            Log.d(TAG, "用户未同意隐私政策，返回降级设备ID")
            return "privacy_not_agreed_${System.currentTimeMillis()}"
        }
        
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
     * 获取 Android ID（仅在隐私政策同意后返回）
     */
    private fun getAndroidId(): String? {
        if (!isPrivacyPolicyAgreed()) return null
        return try {
            android.provider.Settings.Secure.getString(
                context.contentResolver,
                android.provider.Settings.Secure.ANDROID_ID
            )
        } catch (e: Exception) {
            Log.e(TAG, "获取Android ID失败", e)
            null
        }
    }

    /**
     * 获取当前网络头部信息
     */
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
                                context.applicationContext.getSystemService(Context.WIFI_SERVICE) as android.net.wifi.WifiManager
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
            Log.e(TAG, "获取网络头部信息失败: ${e.message}", e)
            "unknown"
        }
    }

    /**
     * 判定当前是否有可用网络
     */
    private fun isNetworkAvailable(): Boolean {
        return try {
            val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val network = cm.activeNetwork ?: return false
            val caps = cm.getNetworkCapabilities(network) ?: return false
            caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
                (caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ||
                    caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) ||
                    caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) ||
                    caps.hasTransport(NetworkCapabilities.TRANSPORT_BLUETOOTH))
        } catch (_: Exception) {
            false
        }
    }
    
    /**
     * 获取电池电量头部信息
     */
    private fun getBatteryHeaderValue(): String {
        return try {
            val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            val level = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
            if (level >= 0) level.toString() else "100"
        } catch (e: Exception) {
            Log.e(TAG, "获取电量信息失败: ${e.message}", e)
            "100"
        }
    }
    
    /**
     * 获取定位权限状态
     */
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
            Log.e(TAG, "获取定位权限状态失败: ${e.message}", e)
            "0"
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
        
        // 🔥 关键修复：保存token后，如果定时器正在运行，强制重启定时器以使用新token
        // 这样切换账号后，定时器会立即使用新token
        if (isReportTimerRunning && reportTimer != null) {
            Log.d(TAG, "🔄 Token已更新，重启定时器以使用新token")
            // 取消旧定时器
            reportTimer?.cancel()
            reportTimer = null
            isReportTimerRunning = false
            // 使用新token重新启动定时器
            startReportTimer(token)
        }
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
        val secretKey = AppConstants.API_SIGNATURE_SECRET_KEY
        
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
     * 定位上报成功后触发桌面小组件数据刷新
     * 使用节流：每5分钟最多触发一次，避免频繁刷新
     */
    private var lastWidgetTriggerTime = 0L
    private fun triggerWidgetUpdate() {
        try {
            val now = System.currentTimeMillis()
            if (now - lastWidgetTriggerTime < 5 * 60 * 1000) {
                return // 5分钟内不重复触发
            }
            lastWidgetTriggerTime = now
            com.yuluo.kissu.widget.WidgetUpdateWorker.enqueueOneTimeWork(context)
            Log.d(TAG, "📱 已触发小组件数据刷新")
        } catch (e: Exception) {
            Log.w(TAG, "触发小组件刷新失败: ${e.message}")
        }
    }

    /**
     * 上报成功后写入文件日志（附带上报的点位信息）
     */
    private fun logReportSuccess(locationsToReport: JSONArray, usedLastLocation: Boolean) {
        try {
            val locationsSummary = StringBuilder()
            for (i in 0 until locationsToReport.length()) {
                val loc = locationsToReport.getJSONObject(i)
                if (i > 0) locationsSummary.append("; ")
                locationsSummary.append("${loc.optString("latitude")},${loc.optString("longitude")},精度:${loc.optString("accuracy")}")
            }
            // writeNativeLog("INFO", "📤 定位上报成功", "LocationReport", mapOf(
            //     "count" to locationsToReport.length(),
            //     "usedLastLocation" to usedLastLocation,
            //     "locations" to locationsSummary.toString()
            // ))
        } catch (e: Exception) {
            Log.e(TAG, "记录上报成功日志失败", e)
        }
    }
    
    /**
     * 写入原生层日志到文件（与 Flutter 层日志目录一致）
     */
    private fun writeNativeLog(level: String, message: String, tag: String = TAG, extra: Map<String, Any>? = null) {
        try {
            val logDir = File(context.filesDir, "logs")
            if (!logDir.exists()) {
                logDir.mkdirs()
            }
            
            val todayFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
            val today = todayFormat.format(Date())
            
            val existingLogFile = logDir.listFiles()?.find { 
                it.name.startsWith(today) && it.name.endsWith("_app.log") 
            }
            
            val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH-mm-ss.SSSSSS", Locale.getDefault())
            val logFile = existingLogFile ?: File(logDir, "${dateFormat.format(Date())}_app.log")
            
            val timestamp = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSSSS", Locale.getDefault()).format(Date())
            val logJson = JSONObject().apply {
                put("level", level)
                put("message", message)
                put("tag", tag)
                put("timestamp", timestamp)
                put("error", JSONObject.NULL)
                put("stackTrace", JSONObject.NULL)
                if (extra != null) {
                    put("extra", JSONObject(extra))
                } else {
                    put("extra", JSONObject.NULL)
                }
            }
            
            logFile.appendText(logJson.toString() + "\n")
            
        } catch (e: Exception) {
            Log.e(TAG, "写入日志文件失败", e)
        }
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

/**
 * WorkManager 单次兜底：重启服务/定时器，避免长时间停摆
 */
class LocationReportWorker(appContext: Context, params: androidx.work.WorkerParameters) :
    androidx.work.CoroutineWorker(appContext, params) {

    override suspend fun doWork(): Result {
        return try {
            setForeground(createForegroundInfo())

            // 重启定时器（60秒主频），内部会自行检查 token 与运行状态
            val service = LocationReportService(applicationContext)
            service.ensureReportTimerRunning()
            Log.d("LocationReportWorker", "兜底重启定时器/服务完成")
            Result.success()
        } catch (e: Exception) {
            Log.e("LocationReportWorker", "兜底重启失败", e)
            Result.retry()
        }
    }

    private fun createForegroundInfo(): ForegroundInfo {
        val channelId = LocationReportService.WORKER_CHANNEL_ID
        val channelName = LocationReportService.WORKER_CHANNEL_NAME
        val nm = applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                channelName,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                enableVibration(false)
                enableLights(false)
                setSound(null, null)
                setShowBadge(false)
            }
            nm.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(applicationContext, channelId)
            .setContentTitle("Kissu")
            .setContentText("请不要关掉Kissu后台进程\n当前正在为对方共享您的信息，请勿关闭")
            .setSmallIcon(
                applicationContext.resources.getIdentifier(
                    "ic_launcher",
                    "mipmap",
                    applicationContext.packageName
                ).takeIf { it != 0 } ?: android.R.drawable.ic_dialog_info
            )
            .setOngoing(true)
            .setSound(null)
            .setVibrate(null)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        // 使用与前台服务相同的通知 ID，避免生成额外通知
        // Android 14+ 需要显式声明前台服务类型，否则会抛 InvalidForegroundServiceTypeException
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val serviceType =
                ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION or ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
            ForegroundInfo(1001, notification, serviceType)
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Android 10+ 支持 location 类型
            ForegroundInfo(1001, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)
        } else {
            // 旧版 API 没有类型参数
            ForegroundInfo(1001, notification)
        }
    }
}
