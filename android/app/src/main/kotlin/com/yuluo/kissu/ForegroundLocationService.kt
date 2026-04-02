package com.yuluo.kissu

import android.Manifest
import android.app.*
import android.content.BroadcastReceiver
import com.yuluo.kissu.constants.AppConstants
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.app.PendingIntent
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import android.os.SystemClock
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.PowerManager
import android.app.ActivityManager
import android.app.usage.UsageStatsManager
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.OutOfQuotaPolicy
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import io.flutter.Log
import com.amap.api.location.AMapLocation
import com.amap.api.location.AMapLocationClient
import com.amap.api.location.AMapLocationClientOption
import com.amap.api.location.AMapLocationListener
import java.util.Timer
import java.util.TimerTask
import java.util.concurrent.TimeUnit
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import org.json.JSONArray
import org.json.JSONObject
import android.provider.Settings
import com.tencent.imsdk.v2.V2TIMManager
import com.tencent.imsdk.v2.V2TIMAdvancedMsgListener
import com.tencent.imsdk.v2.V2TIMMessage
import com.tencent.imsdk.v2.V2TIMSDKConfig
import com.tencent.imsdk.v2.V2TIMCallback
import com.tencent.imsdk.v2.V2TIMSDKListener
import com.tencent.imsdk.v2.V2TIMSendCallback

/**
 * 前台定位服务
 * 
 * 为应用提供持续的后台定位能力，符合Android 8.0+的后台执行限制
 * 增加 WAKE_LOCK 支持，确保息屏时定位仍然活跃
 * 🔥 新增：原生定位监听器，APP被杀后仍能持续定位上报
 */
class ForegroundLocationService : Service(), AMapLocationListener {
    
    companion object {
        private const val TAG = "ForegroundLocationService"
        private const val NATIVE_LOG_TAG = "NativeKeepAlive"
        private const val DEFAULT_NOTIFICATION_ID = 1001
        private const val DEFAULT_CHANNEL_ID = "kissu_location_service"
        
        // 服务动作
        const val ACTION_START_FOREGROUND_SERVICE = "START_FOREGROUND_SERVICE"
        const val ACTION_STOP_FOREGROUND_SERVICE = "STOP_FOREGROUND_SERVICE"
        const val ACTION_UPDATE_NOTIFICATION = "UPDATE_NOTIFICATION"
        
        // Intent额外数据键
        const val EXTRA_CHANNEL_ID = "channel_id"
        const val EXTRA_CHANNEL_NAME = "channel_name"
        const val EXTRA_CHANNEL_DESCRIPTION = "channel_description"
        const val EXTRA_NOTIFICATION_ID = "notification_id"
        const val EXTRA_TITLE = "title"
        const val EXTRA_CONTENT = "content"
        const val EXTRA_BIG_TEXT = "big_text"
        const val EXTRA_ICON = "icon"
        const val EXTRA_PRIORITY = "priority"
        const val EXTRA_IMPORTANCE = "importance"
        const val EXTRA_ONGOING = "ongoing"
        const val EXTRA_AUTO_CANCEL = "auto_cancel"
        const val EXTRA_ENABLE_VIBRATION = "enable_vibration"
        const val EXTRA_ENABLE_SOUND = "enable_sound"
        
        // 🔥 广播事件防抖间隔（毫秒）
        private const val BROADCAST_DEBOUNCE_MS = 1000L // 1秒内相同广播只处理一次
        
        // 🔥 IM SDK AppID（与Flutter侧TencentIMService.sdkAppID一致）
        private const val IM_SDK_APP_ID = AppConstants.TENCENT_IM_SDK_APP_ID
        
        @Volatile
        private var isServiceRunning = false
        
        fun isRunning(): Boolean = isServiceRunning
        
        /**
         * 启动前台服务
         */
        fun startService(context: Context, config: Map<String, Any>): Boolean {
            return try {
                val intent = Intent(context, ForegroundLocationService::class.java).apply {
                    action = ACTION_START_FOREGROUND_SERVICE
                    config.forEach { (key, value) ->
                        when (value) {
                            is String -> putExtra(key, value)
                            is Int -> putExtra(key, value)
                            is Boolean -> putExtra(key, value)
                        }
                    }
                }
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
                true
            } catch (e: Exception) {
                Log.e(TAG, "启动前台服务失败", e)
                false
            }
        }
        
        /**
         * 停止前台服务
         */
        fun stopService(context: Context): Boolean {
            return try {
                val intent = Intent(context, ForegroundLocationService::class.java).apply {
                    action = ACTION_STOP_FOREGROUND_SERVICE
                }
                context.stopService(intent)
                true
            } catch (e: Exception) {
                Log.e(TAG, "停止前台服务失败", e)
                false
            }
        }
    }
    
    private var notificationId = DEFAULT_NOTIFICATION_ID
    private var channelId = DEFAULT_CHANNEL_ID
    private var notificationBuilder: NotificationCompat.Builder? = null
    private var wakeLock: PowerManager.WakeLock? = null
    
    // 🔥 原生定位相关
    private var locationClient: AMapLocationClient? = null
    private var locationReportService: LocationReportService? = null
    private var healthCheckTimer: Timer? = null
    private var heartbeatIntent: PendingIntent? = null
    private var screenOffKeepAliveTimer: Timer? = null // 息屏时的额外保活定时器
    private var screenOffHeartbeatIntent: PendingIntent? = null // 息屏时的额外心跳闹钟
    
    // 🔥 防止并发创建 Binder 对象的锁
    private val locationClientLock = Any()
    
    // 🔥 原生App使用记录上报相关
    private var appUsageReportService: AppUsageReportService? = null
    private var appUsageReportTimer: Timer? = null

    // 🔥 原生锁屏/解锁事件上报相关
    private var sensitiveEventReportService: SensitiveEventReportService? = null
    private var screenEventReceiver: BroadcastReceiver? = null
    private var networkReceiver: BroadcastReceiver? = null
    private var chargingReceiver: BroadcastReceiver? = null

    private var lastNetworkState: NetworkState = NetworkState.NONE
    private var lastWifiName: String? = null
    private var lastChargingState: Boolean? = null
    
    // 🔥 广播事件防抖：防止短时间内重复处理相同广播
    private var lastScreenOffTime: Long = 0L
    private var lastScreenOnTime: Long = 0L
    private var lastUnlockTime: Long = 0L
    
    // 🔥 原生IM消息监听器（用于保活状态下接收锁屏指令）
    private var imMsgListener: V2TIMAdvancedMsgListener? = null
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "前台定位服务创建")
        logInfo("🚀 原生前台定位服务创建")
        // ⚡ 关键修复：onCreate 中不做任何耗时操作，避免5秒超时
        // 所有初始化将在 onStartCommand 中的 startForeground() 之后进行
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_FOREGROUND_SERVICE -> {
                // 🔥 关键修复：必须先调用 startForeground()，避免5秒超时崩溃
                // 即使权限不足，也必须先调用 startForeground()，然后再停止服务
                createBasicForegroundNotification(intent)
                
                // 检查权限，有权限才能启动前台定位服务
                if (!hasLocationPermissions()) {
                    Log.w(TAG, "缺少前台定位或位置权限，无法启动前台服务")
                    // 标记服务期望保持运行，等待用户授权后由健康检查拉起
                    markServiceEnabled(true)
                    // 延迟停止服务，避免立即崩溃（此时已调用 startForeground，不会超时）
                    Handler(android.os.Looper.getMainLooper()).postDelayed({
                        stopForeground(true)
                        stopSelf()
                        isServiceRunning = false
                    }, 100)
                    return START_NOT_STICKY
                }
                
                // 标记服务期望保持运行，用于被系统杀死后的自恢复
                markServiceEnabled(true)
                
                // ✅ 在 startForeground() 之后才进行其他初始化
                initializeServiceComponents()
                
                // 异步执行完整的通知更新和定位启动
                startLocationForegroundService(intent)
            }
            ACTION_STOP_FOREGROUND_SERVICE -> {
                stopForegroundService()
            }
            ACTION_UPDATE_NOTIFICATION -> {
                updateNotification(intent)
            }
            else -> {
                // 处理其他情况（如系统重启后恢复服务）
                // 🔥 关键修复：必须先调用 startForeground()，避免5秒超时崩溃
                // 即使权限不足，也必须先调用 startForeground()，然后再停止服务
                if (intent != null) {
                    createBasicForegroundNotification(intent)
                } else {
                    // 如果没有 intent，创建一个基本的通知
                    val basicIntent = Intent().apply {
                        action = ACTION_START_FOREGROUND_SERVICE
                    }
                    createBasicForegroundNotification(basicIntent)
                }
                
                // 检查权限，有权限才能启动前台定位服务
                if (!hasLocationPermissions()) {
                    Log.w(TAG, "缺少前台定位或位置权限，无法启动前台服务（else分支）")
                    markServiceEnabled(true)
                    // 延迟停止服务，避免立即崩溃（此时已调用 startForeground，不会超时）
                    Handler(android.os.Looper.getMainLooper()).postDelayed({
                        stopForeground(true)
                        stopSelf()
                        isServiceRunning = false
                    }, 100)
                    return START_NOT_STICKY
                }
                
                markServiceEnabled(true)
                initializeServiceComponents()
                
                // 🔥 关键修复：else分支也需要启动定位和上报服务
                // 因为系统重启恢复服务时，只初始化了组件但没有启动定位
                startLocationTracking()
                startAppUsageReporting()
                
                Log.d(TAG, "前台定位服务已恢复（else分支）")
                logInfo("🔄 原生前台定位服务已恢复（系统重启/被杀后恢复）")
            }
        }
        
        // 返回START_STICKY确保服务被系统杀死后会重启
        return START_STICKY
    }
    
    /**
     * 初始化服务组件（在 startForeground() 之后调用）
     */
    private fun initializeServiceComponents() {
        // 🔥 修复：即使 locationClient 已存在，也要确保其他组件（如上报服务）已初始化
        // 因为服务可能被系统回收后恢复，某些组件可能丢失
        var needInit = locationClient == null
        
        if (!needInit) {
            // 检查其他关键组件是否也存在
            if (locationReportService == null || appUsageReportService == null) {
                Log.w(TAG, "服务组件部分丢失，需要重新初始化")
                needInit = true
            }
        }
        
        if (!needInit) {
            Log.d(TAG, "服务组件已完整初始化，跳过")
            return
        }
        
        // 🔥 获取 WAKE_LOCK，确保息屏时定位仍然活跃
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "Kissu::LocationWakeLock"
            ).apply {
                // 设置为非引用计数模式，避免重复 acquire/release 导致问题
                setReferenceCounted(false)
            }
            Log.d(TAG, "WakeLock 创建成功")
            
            // 🔥 立即获取 WakeLock，确保服务启动时就开始保活
            try {
                if (!wakeLock!!.isHeld) {
                    wakeLock!!.acquire()
                    Log.d(TAG, "WakeLock 已立即获取（服务启动时）")
                }
            } catch (e: Exception) {
                logError("立即获取 WakeLock 失败", extra = mapOf("error" to (e.message ?: "unknown")))
            }
        } catch (e: Exception) {
            logError("创建 WakeLock 失败", extra = mapOf("error" to (e.message ?: "unknown")))
        }
        
        // 🔥 初始化定位上报服务（先释放旧的，防止 Binder 泄漏）
        try {
            locationReportService?.let { oldService ->
                // 旧服务已存在，先清理（如果有清理方法）
                Log.d(TAG, "释放旧的定位上报服务")
            }
            locationReportService = LocationReportService(this)
            Log.d(TAG, "定位上报服务初始化成功")
        } catch (e: Exception) {
            Log.e(TAG, "初始化定位上报服务失败", e)
        }
        
        // 🔥 初始化App使用记录上报服务（先释放旧的，防止 Binder 泄漏）
        try {
            appUsageReportService?.let { oldService ->
                // 旧服务已存在，先清理（如果有清理方法）
                Log.d(TAG, "释放旧的App使用记录上报服务")
            }
            appUsageReportService = AppUsageReportService(this)
            Log.d(TAG, "App使用记录上报服务初始化成功")
        } catch (e: Exception) {
            logError("初始化App使用记录上报服务失败", extra = mapOf("error" to (e.message ?: "unknown")))
        }

        // 🔥 初始化敏感事件上报服务（锁屏/解锁）（先释放旧的，防止 Binder 泄漏）
        try {
            sensitiveEventReportService?.let { oldService ->
                // 先注销旧的接收器
                try {
                    unregisterScreenEventReceiver()
                    unregisterNetworkReceiver()
                    unregisterChargingReceiver()
                    Log.d(TAG, "已注销旧的敏感事件上报服务接收器")
                } catch (e: Exception) {
                    Log.e(TAG, "注销旧接收器失败", e)
                }
            }
            sensitiveEventReportService = SensitiveEventReportService(this)
            registerScreenEventReceiver()
            registerNetworkReceiver()
            registerChargingReceiver()
            Log.d(TAG, "敏感事件上报服务初始化成功")
        } catch (e: Exception) {
            logError("初始化敏感事件上报服务失败", extra = mapOf("error" to (e.message ?: "unknown")))
        }
        
        // 🔥 初始化原生定位客户端
        synchronized(locationClientLock) {
            initLocationClient()
        }

        // 🔥 启动原生保活健康检查（确保定位/上报组件存活）
        startHealthCheck()
        
        // 🔥 检查屏幕状态，如果息屏则启动息屏保活机制
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            if (!powerManager.isInteractive) {
                Log.d(TAG, "服务启动时屏幕已关闭，启动息屏保活机制")
                startScreenOffKeepAlive()
            }
        } catch (e: Exception) {
            logError("检查屏幕状态失败", extra = mapOf("error" to (e.message ?: "unknown")))
        }
        
        // 🔥 注册原生IM消息监听器（保活状态下接收锁屏指令）
        registerImMessageListener()
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        return null // 不支持绑定
    }
    
    override fun onDestroy() {
        super.onDestroy()
        
         logWarning("⚠️ 原生前台定位服务被销毁，尝试自恢复")
        
        // 🔥 移除原生IM消息监听器
        unregisterImMessageListener()
        
        // 🔥 停止定位监听（会释放 locationClient）
        stopLocationTracking()
        
        // 🔥 释放上报服务，防止 Binder 泄漏
        try {
            locationReportService = null
            appUsageReportService = null
            sensitiveEventReportService = null
            Log.d(TAG, "已释放所有上报服务")
        } catch (e: Exception) {
            logWarning("释放上报服务失败", extra = mapOf("error" to (e.message ?: "unknown")))
        }
        
        // 🔥 停止健康检查
        healthCheckTimer?.cancel()
        healthCheckTimer = null

        // 🔥 停止心跳闹钟
        stopHeartbeatAlarm()
        
        // 🔥 停止息屏保活机制
        stopScreenOffKeepAlive()

        // 🔥 停止App使用记录上报
        stopAppUsageReporting()

        // 🔥 注销锁屏/解锁广播接收器
        unregisterScreenEventReceiver()
        unregisterNetworkReceiver()
        unregisterChargingReceiver()
        
        // 🔥 释放 WAKE_LOCK（但不要设置为 null，因为可能需要重启）
        try {
            wakeLock?.let {
                if (it.isHeld) {
                    it.release()
                    Log.d(TAG, "WakeLock 已释放")
                }
            }
            // 注意：不设置为 null，因为重启时可能需要重新获取
        } catch (e: Exception) {
            logError("释放 WakeLock 失败", extra = mapOf("error" to (e.message ?: "unknown")))
        }
        
        // 无论是否打算重启，先同步运行状态，避免 Flutter 层误判
        isServiceRunning = false

        // 🔥 无条件安排一次重启，防止厂商 ROM 杀死后不再拉起
        scheduleRestart(reason = "onDestroy")
        scheduleWorkRestart(reason = "onDestroy")
        
        Log.d(TAG, "前台定位服务销毁")
    }
    
    /**
     * 当任务被移除时（用户从最近任务中移除应用）
     * 某些系统会杀死服务，这里尝试重启
     */
    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
         logWarning("⚠️ 应用任务被移除（用户上滑清理），尝试重启服务")
        
        scheduleRestart(reason = "onTaskRemoved")
        scheduleWorkRestart(reason = "onTaskRemoved")
    }
    
    // ==================== 🔥 原生IM消息监听（保活锁屏） ====================
    
    /**
     * 注册原生V2TIM消息监听器
     * 当前台服务保活进程时，通过IM长连接实时接收锁屏指令
     * 无需用户操作，收到消息立即锁屏
     * 
     * 🔥 关键：app杀死后前台服务重启时，IM SDK未初始化，
     * 需要先原生初始化SDK并登录，才能接收消息
     */
    private fun registerImMessageListener() {
        try {
            // 检查IM SDK是否已登录
            val loginUser = V2TIMManager.getInstance().loginUser
            if (!loginUser.isNullOrEmpty()) {
                Log.d(TAG, "🔒 IM SDK已登录: $loginUser，直接注册消息监听器")
                addImMsgListenerIfNeeded()
                return
            }
            
            // IM SDK未登录，需要原生初始化并登录
            Log.d(TAG, "🔒 IM SDK未登录，尝试原生初始化并登录...")
            initNativeIMAndLogin()
        } catch (e: Exception) {
            Log.e(TAG, "🔒 注册原生IM消息监听器失败", e)
        }
    }
    
    /**
     * 原生初始化V2TIM SDK并登录
     * 从SharedPreferences读取缓存的IM凭证进行登录
     */
    private fun initNativeIMAndLogin() {
        try {
            // 读取IM凭证
            val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val imUserId = flutterPrefs.getString("flutter.im_user_id", null)
            val imUserSig = flutterPrefs.getString("flutter.im_user_sig", null)
            
            if (imUserId.isNullOrEmpty() || imUserSig.isNullOrEmpty()) {
                Log.w(TAG, "🔒 IM凭证未找到(userId=${imUserId != null}, userSig=${imUserSig != null})，无法原生登录IM")
                return
            }
            
            Log.d(TAG, "🔒 找到IM凭证: userId=$imUserId，开始原生初始化SDK...")
            
            // 初始化V2TIM SDK
            val config = V2TIMSDKConfig()
            config.logLevel = V2TIMSDKConfig.V2TIM_LOG_WARN
            val initResult = V2TIMManager.getInstance().initSDK(applicationContext, IM_SDK_APP_ID, config, object : V2TIMSDKListener() {
                override fun onConnecting() {
                    Log.d(TAG, "🔒 [原生IM] 正在连接...")
                }
                override fun onConnectSuccess() {
                    Log.d(TAG, "🔒 [原生IM] 连接成功")
                }
                override fun onConnectFailed(code: Int, error: String?) {
                    Log.e(TAG, "🔒 [原生IM] 连接失败: code=$code, error=$error")
                }
                override fun onKickedOffline() {
                    Log.w(TAG, "🔒 [原生IM] 被踢下线")
                }
                override fun onUserSigExpired() {
                    Log.w(TAG, "🔒 [原生IM] UserSig过期")
                }
            })
            
            if (!initResult) {
                Log.e(TAG, "🔒 V2TIM SDK原生初始化失败")
                return
            }
            
            Log.d(TAG, "🔒 V2TIM SDK原生初始化成功，开始登录...")
            
            // 登录
            V2TIMManager.getInstance().login(imUserId, imUserSig, object : V2TIMCallback {
                override fun onSuccess() {
                    Log.d(TAG, "🔒 V2TIM原生登录成功: $imUserId")
                    // 登录成功后注册消息监听器
                    addImMsgListenerIfNeeded()
                    // 🔥 重启后检查锁屏状态，快速恢复锁屏
                    checkAndRestoreLockScreen()
                }
                
                override fun onError(code: Int, desc: String?) {
                    Log.e(TAG, "🔒 V2TIM原生登录失败: code=$code, desc=$desc")
                }
            })
        } catch (e: Exception) {
            Log.e(TAG, "🔒 初始化原生IM SDK失败", e)
        }
    }
    
    /**
     * 添加IM消息监听器（如果尚未添加）
     */
    private fun addImMsgListenerIfNeeded() {
        if (imMsgListener != null) {
            Log.d(TAG, "🔒 IM消息监听器已存在，跳过注册")
            return
        }
        
        imMsgListener = object : V2TIMAdvancedMsgListener() {
            override fun onRecvNewMessage(msg: V2TIMMessage?) {
                if (msg == null) return
                
                // 只处理非自己发送的消息
                if (msg.isSelf) return
                
                // 只处理自定义消息
                val customElem = msg.customElem ?: return
                val data = customElem.data ?: return
                
                try {
                    val dataStr = String(data)
                    val json = JSONObject(dataStr)
                    val type = json.optString("type", "")
                    
                    when (type) {
                        "lock_screen_command" -> {
                            Log.d(TAG, "🔒 [原生IM监听] 收到锁屏指令，立即启动锁屏！")
                            // 存储发送者ID（用于答题解锁后发送unlock_phone_receive）
                            val senderId = msg.sender
                            if (!senderId.isNullOrEmpty()) {
                                val flPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                                flPrefs.edit().putString("flutter.lock_sender_id", senderId).apply()
                                Log.d(TAG, "🔒 已存储锁机发送者ID: $senderId")
                            }
                            handleNativeLockScreenCommand(json)
                        }
                        "unlock_phone_send" -> {
                            Log.d(TAG, "🔓 [原生IM监听] 收到解锁指令，立即解锁！")
                            handleNativeUnlockCommand()
                        }
                    }
                } catch (e: Exception) {
                    // 非JSON格式的自定义消息，忽略
                }
            }
        }
        
        V2TIMManager.getMessageManager().addAdvancedMsgListener(imMsgListener)
        Log.d(TAG, "🔒 原生IM消息监听器注册成功，可接收锁屏指令")
    }
    
    /**
     * 移除原生IM消息监听器
     */
    private fun unregisterImMessageListener() {
        try {
            imMsgListener?.let {
                V2TIMManager.getMessageManager().removeAdvancedMsgListener(it)
                Log.d(TAG, "🔒 原生IM消息监听器已移除")
            }
            imMsgListener = null
        } catch (e: Exception) {
            Log.e(TAG, "🔒 移除原生IM消息监听器失败", e)
        }
    }
    
    /**
     * 处理锁屏指令（原生层直接处理，不依赖Flutter）
     */
    private fun handleNativeLockScreenCommand(json: JSONObject) {
        try {
            // 用户未登录时不处理锁机指令
            val kissuPrefs = getSharedPreferences("kissu_preferences", Context.MODE_PRIVATE)
            val userToken = kissuPrefs.getString("user_token", null)
            if (userToken.isNullOrEmpty()) {
                Log.w(TAG, "🔒 用户未登录（无token），忽略锁机指令")
                return
            }

            // 检查悬浮窗权限
            if (!Settings.canDrawOverlays(this)) {
                Log.w(TAG, "🔒 缺少悬浮窗权限，无法启动锁屏")
                return
            }
            
            // 解析锁屏数据（IM消息字段: question, answers, lock_prompt, lock_bg_image, default_bg_image_index）
            val question = json.optString("question", "什么马不能骑？")
            val minutes = json.optInt("minutes", 2000)
            val lockText = json.optString("lock_prompt", json.optString("lockText", ""))
            val bgImageUrl = json.optString("lock_bg_image", "")
            
            // 解析 default_bg_image_index（"kissu_lock_1"/"kissu_lock_2"/"kissu_lock_3" → 0/1/2）
            val defaultBgImageIndexStr = json.optString("default_bg_image_index", "")
            val bgImageIndex = when (defaultBgImageIndexStr) {
                "kissu_lock_2" -> 1
                "kissu_lock_3" -> 2
                else -> 0
            }
            
            // 解析 answers 字段（含 is_answer 字段的JSON数组），提取答案文本和正确答案索引
            val answers = mutableListOf<String>()
            var correctIndex = -1
            try {
                val answersRaw = json.opt("answers")
                val answerArray: JSONArray? = when (answersRaw) {
                    is String -> JSONArray(answersRaw)
                    is JSONArray -> answersRaw
                    else -> null
                }
                if (answerArray != null) {
                    for (i in 0 until answerArray.length()) {
                        val item = answerArray.opt(i)
                        if (item is JSONObject) {
                            answers.add(item.optString("answer", ""))
                            if (item.optInt("is_answer", 0) == 1 && correctIndex < 0) {
                                correctIndex = i
                            }
                        } else {
                            answers.add(item.toString())
                        }
                    }
                }
            } catch (e: Exception) {
                Log.w(TAG, "🔒 解析answers失败: ${e.message}")
            }
            if (answers.isEmpty()) {
                answers.addAll(listOf("海马", "河马", "斑马", "木马"))
            }
            if (correctIndex < 0) correctIndex = 0
            
            Log.d(TAG, "🔒 解析IM锁屏数据: question=$question, answers=$answers, correctIndex=$correctIndex, bgImageIndex=$bgImageIndex, defaultBgImageIndex=$defaultBgImageIndexStr")
            
            // 存储问题数据到SharedPreferences供答题页面使用
            val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            flutterPrefs.edit().apply {
                putString("flutter.lock_question", question)
                putString("flutter.lock_answers", JSONArray(answers).toString())
                putLong("flutter.lock_correct_index", correctIndex.toLong())
                putString("flutter.lock_text", lockText)
                putLong("flutter.lock_bg_image_index", bgImageIndex.toLong())
                putString("flutter.lock_default_bg_image_index", defaultBgImageIndexStr)
                if (bgImageUrl.isNotEmpty()) {
                    putString("flutter.lock_bg_image_url", bgImageUrl)
                    // 自定义图片时清除预设索引
                    putString("flutter.lock_bg_image_local_path", "") // 原生端会异步下载
                } else {
                    // 预设图片时清除自定义图片路径，防止残留
                    putString("flutter.lock_bg_image_url", "")
                    putString("flutter.lock_bg_image_local_path", "")
                }
                apply()
            }
            
            Log.d(TAG, "🔒 锁屏数据已存储: question=$question, correctIndex=$correctIndex, minutes=$minutes, lockText=$lockText")
            
            // 存储锁屏状态
            val lockPrefs = getSharedPreferences(LockScreenOverlayService.PREFS_NAME, Context.MODE_PRIVATE)
            val endTime = System.currentTimeMillis() + minutes * 60 * 1000L
            val lockInfo = JSONObject().apply {
                put("endTime", endTime)
                put("minutes", minutes)
            }
            lockPrefs.edit().putString(LockScreenOverlayService.KEY_SCREEN_LOCK, lockInfo.toString()).apply()
            
            // 启动锁屏服务，传递lockText和bgImageUrl通过Intent extras
            val serviceIntent = Intent(this, LockScreenOverlayService::class.java)
            if (lockText.isNotEmpty()) {
                serviceIntent.putExtra("lock_text", lockText)
            }
            if (bgImageUrl.isNotEmpty()) {
                serviceIntent.putExtra("bg_image_path", bgImageUrl)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent)
            } else {
                startService(serviceIntent)
            }
            
            Log.d(TAG, "🔒 锁屏服务已从前台服务中启动: ${minutes}分钟, lockText=$lockText")
            
        } catch (e: Exception) {
            Log.e(TAG, "🔒 处理锁屏指令失败", e)
        }
    }
    
    /**
     * 🔥 重启后检查锁屏状态，快速恢复锁屏
     * 防止被锁方通过重启手机逃避锁定
     */
    private fun checkAndRestoreLockScreen() {
        try {
            val lockPrefs = getSharedPreferences(LockScreenOverlayService.PREFS_NAME, Context.MODE_PRIVATE)
            val screenLockJson = lockPrefs.getString(LockScreenOverlayService.KEY_SCREEN_LOCK, null)
            
            if (screenLockJson.isNullOrEmpty()) {
                Log.d(TAG, "🔒 没有锁屏数据，跳过锁屏恢复")
                return
            }
            
            val obj = JSONObject(screenLockJson)
            val endTime = obj.optLong("endTime", 0)
            val currentTime = System.currentTimeMillis()
            
            if (currentTime >= endTime) {
                Log.d(TAG, "🔒 锁屏已过期，清除数据并发送解锁通知给锁机方")
                lockPrefs.edit().remove(LockScreenOverlayService.KEY_SCREEN_LOCK).apply()
                // 锁屏过期，发送解锁通知给A
                sendExpiredUnlockNotification()
                return
            }
            
            // 检查悬浮窗权限
            if (!Settings.canDrawOverlays(this)) {
                Log.w(TAG, "🔒 缺少悬浮窗权限，无法恢复锁屏")
                return
            }
            
            Log.d(TAG, "🔒 发现未过期的锁屏，立即恢复！剩余: ${(endTime - currentTime) / 1000}秒")
            
            // 立即启动锁屏服务
            val serviceIntent = Intent(this, LockScreenOverlayService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent)
            } else {
                startService(serviceIntent)
            }
            
            Log.d(TAG, "🔒 锁屏服务已快速恢复")
        } catch (e: Exception) {
            Log.e(TAG, "🔒 检查锁屏恢复失败", e)
        }
    }
    
    /**
     * � 锁屏时间过期后发送解锁通知给锁机方
     */
    private fun sendExpiredUnlockNotification() {
        try {
            val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val senderId = flutterPrefs.getString("flutter.lock_sender_id", null)
            
            if (senderId.isNullOrEmpty()) {
                Log.w(TAG, "🔓 未找到锁机发送者ID，无法发送过期解锁通知")
                return
            }
            
            // 读取保存的答题次数
            val lockPrefs = getSharedPreferences(LockScreenOverlayService.PREFS_NAME, Context.MODE_PRIVATE)
            val attempts = lockPrefs.getInt("lock_answer_attempts", 0)
            
            val msgData = JSONObject().apply {
                put("type", "unlock_phone_receive")
                put("attempts", attempts)
            }
            val msgBytes = msgData.toString().toByteArray()
            
            val msg = V2TIMManager.getMessageManager().createCustomMessage(msgBytes)
            V2TIMManager.getMessageManager().sendMessage(
                msg, senderId, null,
                V2TIMMessage.V2TIM_PRIORITY_HIGH,
                false, null,
                object : V2TIMSendCallback<V2TIMMessage> {
                    override fun onSuccess(message: V2TIMMessage?) {
                        Log.d(TAG, "🔓 过期解锁通知已发送: sender=$senderId, attempts=$attempts")
                        // 清理
                        flutterPrefs.edit().remove("flutter.lock_sender_id").apply()
                        lockPrefs.edit().remove("lock_answer_attempts").apply()
                    }
                    override fun onError(code: Int, desc: String?) {
                        Log.e(TAG, "🔓 发送过期解锁通知失败: code=$code, desc=$desc")
                    }
                    override fun onProgress(progress: Int) {}
                }
            )
        } catch (e: Exception) {
            Log.e(TAG, "🔓 发送过期解锁通知失败", e)
        }
    }
    
    /**
     * �� 处理解锁指令（原生层直接处理，不依赖Flutter）
     */
    private fun handleNativeUnlockCommand() {
        try {
            // 清除锁屏状态
            val lockPrefs = getSharedPreferences(LockScreenOverlayService.PREFS_NAME, Context.MODE_PRIVATE)
            lockPrefs.edit().remove(LockScreenOverlayService.KEY_SCREEN_LOCK).apply()
            
            // 清除发送者ID
            val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            flutterPrefs.edit().remove("flutter.lock_sender_id").apply()
            
            // 停止锁屏服务
            val serviceIntent = Intent(this, LockScreenOverlayService::class.java).apply {
                action = "STOP_SERVICE"
            }
            startService(serviceIntent)
            
            Log.d(TAG, "🔓 已执行原生解锁操作")
        } catch (e: Exception) {
            Log.e(TAG, "🔓 处理解锁指令失败", e)
        }
    }
    
    /**
     * 🔥 立即创建基本前台通知，避免5秒超时
     * 必须在 onStartCommand 中第一时间调用
     * ⚡ 性能优化：只使用最快的操作，避免任何耗时调用
     */
    private fun createBasicForegroundNotification(intent: Intent) {
        try {
            // 提取基本参数
            channelId = intent.getStringExtraCompat(EXTRA_CHANNEL_ID, "channelId") ?: DEFAULT_CHANNEL_ID
            notificationId = intent.getIntExtraCompat(EXTRA_NOTIFICATION_ID, "notificationId", defaultValue = DEFAULT_NOTIFICATION_ID)
            val channelName = intent.getStringExtraCompat(EXTRA_CHANNEL_NAME, "channelName") ?: "定位服务"
            val title = intent.getStringExtraCompat(EXTRA_TITLE, "title") ?: "Kissu - 情侣定位"
            val content = intent.getStringExtraCompat(EXTRA_CONTENT, "content") ?: "正在为您提供位置定位服务"
            
            // 快速创建通知渠道（如果不存在）
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    channelId,
                    channelName,
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    enableLights(false)
                    enableVibration(false)
                    setShowBadge(false)
                    setSound(null, null)
                }
                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.createNotificationChannel(channel)
            }
            
            // ⚡ 快速构建基本通知 - 直接使用系统图标，避免资源查找耗时
            val notification = NotificationCompat.Builder(this, channelId)
                .setContentTitle(title)
                .setContentText(content)
                .setSmallIcon(android.R.drawable.ic_dialog_info) // 直接使用系统图标
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setOngoing(true)
                .setAutoCancel(false)
                .setShowWhen(false)
                .setSound(null)
                .setVibrate(null)
                .setVisibility(NotificationCompat.VISIBILITY_SECRET)
                .build()
            
            // 🔥 关键：立即启动前台服务（必须在5秒内）
            // Android 14+ (API 34+) 需要指定前台服务类型
            // 如果权限不足，使用 DATA_SYNC 类型避免崩溃（临时方案）
            if (Build.VERSION.SDK_INT >= 34) {
                val hasLocationPerms = hasLocationPermissions()
                val serviceType = if (hasLocationPerms) {
                    android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
                } else {
                    // 权限不足时使用 DATA_SYNC 类型避免崩溃（AndroidManifest 中已声明此权限）
                    Log.w(TAG, "⚠️ 定位权限不足，使用 DATA_SYNC 类型启动前台服务（临时方案）")
                    android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
                }
                startForeground(notificationId, notification, serviceType)
            } else {
                startForeground(notificationId, notification)
            }
            isServiceRunning = true
            
            Log.d(TAG, "⚡ 前台服务已立即启动（避免5秒超时）")
            
        } catch (e: Exception) {
            Log.e(TAG, "创建基本前台通知失败", e)
            // 即使失败也尝试用最简单的通知启动
            try {
                // 使用最基本的通知配置
                val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    // 创建默认渠道
                    val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    val defaultChannel = NotificationChannel(
                        DEFAULT_CHANNEL_ID,
                        "定位服务",
                        NotificationManager.IMPORTANCE_LOW
                    )
                    nm.createNotificationChannel(defaultChannel)
                    NotificationCompat.Builder(this, DEFAULT_CHANNEL_ID)
                } else {
                    NotificationCompat.Builder(this)
                }
                
                val defaultNotification = builder
                    .setContentTitle("定位服务")
                    .setContentText("运行中")
                    .setSmallIcon(android.R.drawable.ic_dialog_info)
                    .build()
                    
                if (Build.VERSION.SDK_INT >= 34) {
                    val hasLocationPerms = hasLocationPermissions()
                    val serviceType = if (hasLocationPerms) {
                        android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
                    } else {
                        logWarning("⚠️ 定位权限不足，使用 DATA_SYNC 类型启动前台服务（默认通知）")
                        android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
                    }
                    startForeground(DEFAULT_NOTIFICATION_ID, defaultNotification, serviceType)
                } else {
                    startForeground(DEFAULT_NOTIFICATION_ID, defaultNotification)
                }
                isServiceRunning = true
                Log.d(TAG, "⚡ 使用默认通知启动前台服务")
            } catch (e2: Exception) {
                logError("创建默认前台通知也失败", extra = mapOf("error" to (e2.message ?: "unknown")))
                // 🔥 最后兜底：即使所有通知创建都失败，也必须调用 startForeground() 避免崩溃
                try {
                    val emergencyNotification = NotificationCompat.Builder(this, DEFAULT_CHANNEL_ID)
                        .setContentTitle("服务运行中")
                        .setContentText("")
                        .setSmallIcon(android.R.drawable.ic_menu_info_details)
                        .setPriority(NotificationCompat.PRIORITY_MIN)
                        .build()
                    if (Build.VERSION.SDK_INT >= 34) {
                        val hasLocationPerms = hasLocationPermissions()
                        val serviceType = if (hasLocationPerms) {
                            android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
                        } else {
                            logWarning("⚠️ 定位权限不足，使用 DATA_SYNC 类型启动前台服务（紧急通知）")
                            android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
                        }
                        startForeground(DEFAULT_NOTIFICATION_ID, emergencyNotification, serviceType)
                    } else {
                        startForeground(DEFAULT_NOTIFICATION_ID, emergencyNotification)
                    }
                    isServiceRunning = true
                    Log.d(TAG, "⚡ 使用紧急通知启动前台服务（避免崩溃）")
                } catch (e3: Exception) {
                    logError("紧急通知也失败，服务可能崩溃", extra = mapOf("error" to (e3.message ?: "unknown")))
                    // 如果连紧急通知都失败，只能抛出异常
                    throw e3
                }
            }
        }
    }
    
    /**
     * 启动前台服务（延迟执行的完整初始化）
     */
    private fun startLocationForegroundService(intent: Intent) {
        try {
            // 提取配置参数
            val channelName = intent.getStringExtraCompat(EXTRA_CHANNEL_NAME, "channelName") ?: "定位服务"
            val channelDescription = intent.getStringExtraCompat(EXTRA_CHANNEL_DESCRIPTION, "channelDescription") ?: "为您提供位置定位服务"
            
            val title = intent.getStringExtraCompat(EXTRA_TITLE, "title") ?: "Kissu - 情侣定位"
            val content = intent.getStringExtraCompat(EXTRA_CONTENT, "content") ?: "正在为您提供位置定位服务"
            val iconName = intent.getStringExtraCompat(EXTRA_ICON, "icon", "iconName") ?: "ic_notification"
            val priority = intent.getStringExtraCompat(EXTRA_PRIORITY, "priority") ?: "high"
            val importance = intent.getStringExtraCompat(EXTRA_IMPORTANCE, "importance") ?: "high"
            val ongoing = intent.getBooleanExtraCompat(EXTRA_ONGOING, "ongoing", defaultValue = true)
            val autoCancel = intent.getBooleanExtraCompat(EXTRA_AUTO_CANCEL, "autoCancel", defaultValue = false)
            val enableVibration = intent.getBooleanExtraCompat(EXTRA_ENABLE_VIBRATION, "enableVibration", defaultValue = false)
            val enableSound = intent.getBooleanExtraCompat(EXTRA_ENABLE_SOUND, "enableSound", defaultValue = false)
            
            // 完整创建通知渠道
            createNotificationChannel(channelId, channelName, channelDescription, importance)
            
            // 构建完整通知
            val notification = buildNotification(
                title, content, iconName, priority, ongoing, autoCancel, enableVibration, enableSound
            )
            
            // 更新前台服务通知（不是第一次启动）
            val notificationManager = NotificationManagerCompat.from(this)
            notificationManager.notify(notificationId, notification)
            
            // 🔥 获取 WAKE_LOCK，确保息屏时仍能定位
            try {
                wakeLock?.let {
                    if (!it.isHeld) {
                        it.acquire()
                        Log.d(TAG, "WakeLock 已获取，息屏时将保持定位活跃")
                    }
                }
            } catch (e: Exception) {
                logError("获取 WakeLock 失败", extra = mapOf("error" to (e.message ?: "unknown")))
            }
            
            // 🔥 确保组件已初始化（防止服务已存在但组件丢失的情况）
            if (locationClient == null || locationReportService == null) {
                logWarning("检测到组件丢失，重新初始化")
                initializeServiceComponents()
            }
            
            // 🔥 启动定位监听（确保总是尝试启动，即使组件已存在）
            startLocationTracking()
            
            // 🔥 确保上报定时器在运行（防止定时器被系统回收）
            locationReportService?.ensureReportTimerRunning()
            
            // 🔥 启动App使用记录上报
            startAppUsageReporting()
            
             logInfo("✅ 原生前台定位服务启动成功")
            
        } catch (e: Exception) {
             logError("❌ 启动前台服务失败", extra = mapOf("error" to (e.message ?: "unknown")))
        }
    }
    
    /**
     * 停止前台服务
     */
    private fun stopForegroundService() {
        try {
            // 🔥 释放 WAKE_LOCK
            wakeLock?.let {
                if (it.isHeld) {
                    it.release()
                    Log.d(TAG, "WakeLock 已释放（停止服务）")
                }
            }
            
            stopForeground(true)
            stopSelf()
            isServiceRunning = false
            // 标记服务不再需要保持运行
            markServiceEnabled(false)
             logInfo("⏹️ 原生前台定位服务停止成功")
        } catch (e: Exception) {
             logError("❌ 停止前台服务失败", extra = mapOf("error" to (e.message ?: "unknown")))
        }
    }
    
    /**
     * 更新通知
     */
    private fun updateNotification(intent: Intent) {
        try {
            notificationId = intent.getIntExtraCompat(EXTRA_NOTIFICATION_ID, "notificationId", defaultValue = notificationId)
            val title = intent.getStringExtraCompat(EXTRA_TITLE, "title") ?: "Kissu - 情侣定位"
            val content = intent.getStringExtraCompat(EXTRA_CONTENT, "content") ?: "正在为您提供位置定位服务"
            val bigText = intent.getStringExtraCompat(EXTRA_BIG_TEXT, "bigText")
            
            notificationBuilder?.let { builder ->
                builder.setContentTitle(title)
                    .setContentText(content)
                    .setWhen(System.currentTimeMillis())
                
                // 如果有大文本，使用BigTextStyle
                if (!bigText.isNullOrEmpty()) {
                    builder.setStyle(
                        NotificationCompat.BigTextStyle()
                            .bigText(bigText)
                            .setBigContentTitle(title)
                    )
                }
                
                val notificationManager = NotificationManagerCompat.from(this)
                notificationManager.notify(notificationId, builder.build())
                
                 logInfo("通知更新成功: $title - $content")
            }
        } catch (e: Exception) {
             logError("更新通知失败", extra = mapOf("error" to (e.message ?: "unknown")))
        }
    }
    
    /**
     * 创建通知渠道 (Android 8.0+)
     */
    private fun createNotificationChannel(
        channelId: String,
        channelName: String,
        channelDescription: String,
        importance: String
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val importanceLevel = when (importance.lowercase()) {
                "high" -> NotificationManager.IMPORTANCE_HIGH
                "default" -> NotificationManager.IMPORTANCE_DEFAULT
                "low" -> NotificationManager.IMPORTANCE_LOW
                "min" -> NotificationManager.IMPORTANCE_MIN
                else -> NotificationManager.IMPORTANCE_DEFAULT
            }
            
            val channel = NotificationChannel(channelId, channelName, importanceLevel).apply {
                description = channelDescription
                enableLights(false)
                enableVibration(false)
                setShowBadge(false)
                setSound(null, null)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
            
            Log.d(TAG, "通知渠道创建成功: $channelId")
        }
    }
    
    /**
     * 构建通知
     */
    private fun buildNotification(
        title: String,
        content: String,
        iconName: String,
        priority: String,
        ongoing: Boolean,
        autoCancel: Boolean,
        enableVibration: Boolean,
        enableSound: Boolean
    ): Notification {
        
        // 获取图标资源ID
        val iconResId = getIconResourceId(iconName)
        
        // 创建点击Intent（点击通知打开应用）
        val clickIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, clickIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
        )
        
        // 设置通知优先级
        val notificationPriority = when (priority.lowercase()) {
            "high" -> NotificationCompat.PRIORITY_HIGH
            "default" -> NotificationCompat.PRIORITY_DEFAULT
            "low" -> NotificationCompat.PRIORITY_LOW
            "min" -> NotificationCompat.PRIORITY_MIN
            else -> NotificationCompat.PRIORITY_DEFAULT
        }
        
        notificationBuilder = NotificationCompat.Builder(this, channelId)
            .setContentTitle(title)
            .setContentText(content)
            .setSmallIcon(iconResId)
            .setContentIntent(pendingIntent)
            .setPriority(notificationPriority)
            .setOngoing(ongoing)
            .setAutoCancel(autoCancel)
            .setShowWhen(true)
            .setWhen(System.currentTimeMillis())
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_SECRET) // 🔧 最低可见性，锁屏不显示
        
        // 设置震动和声音
        if (!enableVibration) {
            notificationBuilder?.setVibrate(null)
        }
        if (!enableSound) {
            notificationBuilder?.setSound(null)
        }
        
        return notificationBuilder!!.build()
    }

    /**
     * 检查前台定位服务所需权限是否齐全
     */
    private fun hasLocationPermissions(): Boolean {
        // Android 10-13: FOREGROUND_SERVICE_LOCATION 权限在 Manifest 中声明后自动授予，无需检查
        // Android 14+ (API 34+): 需要检查权限
        val fgOk = if (Build.VERSION.SDK_INT >= 34) {
            // Android 14+ 需要检查
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.FOREGROUND_SERVICE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            // Android 10-13: 只要在 Manifest 中声明就认为有权限
            true
        }

        val coarseOk = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        val fineOk = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        if (!fgOk || (!coarseOk && !fineOk)) {
            logError("定位权限不足", extra = mapOf("fg" to fgOk, "coarse" to coarseOk, "fine" to fineOk))
        }
        return fgOk && (coarseOk || fineOk)
    }

    /**
     * 在设备被上滑清理或服务被销毁时，使用 AlarmManager 安排一次延迟重启，
     * 避免部分 ROM 忽略 START_STICKY / Handler 延迟。
     */
    private fun scheduleRestart(delayMs: Long = 1200L, reason: String) {
        try {
            val intent = Intent(this, ForegroundLocationService::class.java).apply {
                action = ACTION_START_FOREGROUND_SERVICE
                // 使用默认配置
                putExtra("title", "Kissu")
                putExtra("content", "请不要关掉Kissu后台进程\n当前正在为对方共享您的信息，请勿关闭")
                putExtra("channelId", "kissu_location_service")
                putExtra("notificationId", 1001)
                putExtra("iconName", "ic_launcher")
                putExtra("priority", 2)
                putExtra("ongoing", true)
                putExtra("autoCancel", false)
                putExtra("enableVibration", false)
                putExtra("enableSound", false)
            }

            val pendingIntent = PendingIntent.getService(
                this,
                2002,
                intent,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
            )

            val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val triggerAt = SystemClock.elapsedRealtime() + delayMs
            am.setExactAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP, triggerAt, pendingIntent)
            logInfo("🔄 已安排重启（$reason），delay=${delayMs}ms")
        } catch (e: Exception) {
            logError("安排重启失败（$reason）", extra = mapOf("error" to (e.message ?: "unknown")))
        }
    }

    /**
     * 使用 WorkManager 兜底重启，防止 exact alarm 被省电策略拦截
     * 
     * 🔥 修复：Expedited jobs 不能设置 delay，需要二选一：
     * - 需要立即执行：使用 setExpedited()，不设置 delay
     * - 需要延迟执行：使用 setInitialDelay()，不设置 expedited
     */
    private fun scheduleWorkRestart(reason: String) {
        try {
            // 🔥 修复：不再同时使用 setExpedited 和 setInitialDelay
            // 对于重启任务，延迟执行更重要（避免立即重启导致的循环）
            val request = OneTimeWorkRequestBuilder<LocationServiceRestartWorker>()
                .setInitialDelay(2, TimeUnit.SECONDS)
                // 移除 setExpedited，因为 Expedited jobs cannot be delayed
                .build()

            WorkManager.getInstance(applicationContext).enqueueUniqueWork(
                "foreground_location_restart",
                ExistingWorkPolicy.REPLACE,
                request
            )
            logInfo("🛠️ WorkManager 兜底重启已安排（$reason）")
        } catch (e: Exception) {
            logError("安排 WorkManager 重启失败（$reason）", extra = mapOf("error" to (e.message ?: "unknown")))
        }
    }

    /**
     * 记录服务期望状态，便于被系统杀死后自恢复
     */
    private fun markServiceEnabled(enabled: Boolean) {
        try {
            val prefs = getSharedPreferences("kissu_location_prefs", Context.MODE_PRIVATE)
            prefs.edit().putBoolean("location_service_enabled", enabled).apply()
            logInfo("服务期望状态已更新: $enabled")
        } catch (e: Exception) {
            logError("更新服务期望状态失败", extra = mapOf("error" to (e.message ?: "unknown")))
        }
    }

    /**
     * Intent 兼容读取工具：同时支持下划线和驼峰写法
     */
    private fun Intent.getStringExtraCompat(vararg keys: String): String? {
        keys.forEach { key ->
            if (hasExtra(key)) {
                return getStringExtra(key)
            }
        }
        return null
    }

    private fun Intent.getIntExtraCompat(vararg keys: String, defaultValue: Int): Int {
        keys.forEach { key ->
            if (hasExtra(key)) {
                return getIntExtra(key, defaultValue)
            }
        }
        return defaultValue
    }

    private fun Intent.getBooleanExtraCompat(vararg keys: String, defaultValue: Boolean): Boolean {
        keys.forEach { key ->
            if (hasExtra(key)) {
                return getBooleanExtra(key, defaultValue)
            }
        }
        return defaultValue
    }
    
    /**
     * 获取图标资源ID
     */
    private fun getIconResourceId(iconName: String): Int {
        return try {
            // 先在 drawable 中查找
            var resourceId = resources.getIdentifier(iconName, "drawable", packageName)
            
            // 如果 drawable 中找不到，再在 mipmap 中查找（适用于 ic_launcher）
            if (resourceId == 0) {
                resourceId = resources.getIdentifier(iconName, "mipmap", packageName)
            }
            
            if (resourceId != 0) resourceId else android.R.drawable.ic_dialog_info
        } catch (e: Exception) {
            logWarning("无法找到图标资源: $iconName，使用默认图标")
            android.R.drawable.ic_dialog_info
        }
    }
    
    // ================================
    // 🔥 原生定位监听相关方法
    // ================================
    
    /**
     * 初始化定位客户端
     */
    private fun initLocationClient() {
        synchronized(locationClientLock) {
            try {
                // 🔥 修复 Binder 泄漏：先释放旧的实例，再创建新的
                locationClient?.let { oldClient ->
                    try {
                        if (oldClient.isStarted) {
                            oldClient.stopLocation()
                        }
                        oldClient.onDestroy()
                        Log.d(TAG, "已释放旧的定位客户端")
                    } catch (e: Exception) {
                        Log.e(TAG, "释放旧定位客户端失败", e)
                    }
                }
                
                // 创建新实例
                locationClient = AMapLocationClient(applicationContext)
                locationClient?.setLocationListener(this)
                
                // 配置定位参数
                val locationOption = AMapLocationClientOption().apply {
                    locationMode = AMapLocationClientOption.AMapLocationMode.Hight_Accuracy
                    isGpsFirst = true
                    httpTimeOut = 30000
                    // ✅ 关键修复：与Flutter层统一为5秒，避免APP被杀后定位频率骤降
                    interval = 5000 // 5秒定位一次（与Flutter层保持一致）
                    isNeedAddress = false
                    isOnceLocation = false
                    isOnceLocationLatest = false
                    isSensorEnable = false
                    isWifiScan = true
                    isLocationCacheEnable = true
                    geoLanguage = AMapLocationClientOption.GeoLanguage.DEFAULT
                }
                
                locationClient?.setLocationOption(locationOption)
                Log.d(TAG, "原生定位客户端初始化成功")
                
            } catch (e: Exception) {
                logError("初始化定位客户端失败", extra = mapOf("error" to (e.message ?: "unknown")))
                locationClient = null
            }
        }
    }
    
    /**
     * 启动定位监听
     */
    private fun startLocationTracking() {
        try {
            locationClient?.let { client ->
                if (!hasLocationPermissions()) {
                    logWarning("缺少定位权限，暂不启动定位监听，等待后续授权")
                    return
                }
                if (!client.isStarted) {
                    client.startLocation()
                     logInfo("🚀 原生定位监听已启动")
                } else {
                    Log.d(TAG, "原生定位监听已在运行中")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "启动定位监听失败", e)
        }
    }
    
    /**
     * 停止定位监听
     */
    private fun stopLocationTracking() {
        try {
            locationClient?.let { client ->
                if (client.isStarted) {
                    client.stopLocation()
                     logInfo("⏹️ 原生定位监听已停止")
                }
                client.onDestroy()
            }
            locationClient = null
            locationReportService = null
        } catch (e: Exception) {
             logError("❌ 停止定位监听失败", extra = mapOf("error" to (e.message ?: "unknown")))
        }
    }

    /**
     * 原生保活健康检查：降频到 60 秒，减少高频唤醒
     */
    private fun startHealthCheck() {
        healthCheckTimer?.cancel()
        healthCheckTimer = Timer().apply {
            schedule(object : TimerTask() {
                override fun run() {
                    try {
                        // 🔥 每次健康检查都输出日志，确认保活在运行
                        val clientStatus = locationClient?.isStarted ?: false
                        val reportServiceStatus = locationReportService != null
                        val wakeLockStatus = wakeLock?.isHeld ?: false
                        logInfo("💓 保活心跳", extra = mapOf(
                            "locationClient" to clientStatus,
                            "reportService" to reportServiceStatus,
                            "wakeLock" to wakeLockStatus
                        ))
                        
                        // 定位客户端存活且在运行
                        synchronized(locationClientLock) {
                            if (locationClient == null) {
                                initLocationClient()
                            }
                        }
                        locationClient?.let { client ->
                            if (!client.isStarted) {
                                if (!hasLocationPermissions()) {
                                     logWarning("💡 保活检查：缺少定位权限，等待授权")
                                    return
                                }
                                client.startLocation()
                                 logInfo("💡 保活检查：重新启动定位客户端")
                            }
                        }

                        // 上报服务存活
                        if (locationReportService == null) {
                            // 🔥 修复 Binder 泄漏：确保旧实例已释放（虽然应该已经是 null）
                            locationReportService?.let { oldService ->
                                try {
                                    // LocationReportService 如果有清理方法，在这里调用
                                    Log.d(TAG, "释放旧的上报服务")
                                } catch (e: Exception) {
                                    Log.e(TAG, "释放旧上报服务失败", e)
                                }
                            }
                            locationReportService = LocationReportService(this@ForegroundLocationService)
                             logInfo("💡 保活检查：重新创建上报服务")
                        }
                        
                        // 🔥 确保上报定时器在运行（可能被系统回收）
                        locationReportService?.ensureReportTimerRunning()

                        // 确保心跳闹钟已设置
                        ensureHeartbeatAlarm()
                        
                        // � 检查锁屏状态，如果有锁屏数据且锁屏服务未运行，则启动锁屏服务
                        checkAndStartLockScreenService()
                        
                        // � 息屏时确保 WAKE_LOCK 持续持有（防止被系统回收）
                        try {
                            wakeLock?.let {
                                if (!it.isHeld) {
                                    it.acquire()
                                    Log.d(TAG, "💪 保活：重新获取 WAKE_LOCK（可能被系统回收）")
                                }
                            }
                        } catch (e: Exception) {
                            logError("保活时获取 WAKE_LOCK 失败", extra = mapOf("error" to (e.message ?: "unknown")))
                        }
                    } catch (e: Exception) {
                        logError("保活健康检查异常", extra = mapOf("error" to (e.message ?: "unknown")))
                    }
                }
            }, 60_000L, 60_000L) // 60秒检查一次，降低被判高频唤醒风险
        }
        logInfo("🚑 原生保活健康检查已启动（60秒）")
    }

    /**
     * 心跳闹钟：每 3 分钟唤醒一次，降低高频唤醒风险
     */
    private fun ensureHeartbeatAlarm() {
        try {
            val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(this, ForegroundLocationService::class.java).apply {
                action = ACTION_START_FOREGROUND_SERVICE
                // 使用统一的通知配置（与 BootCompletedReceiver 保持一致）
                putExtra("title", "Kissu")
                putExtra("content", "请不要关掉Kissu后台进程\n当前正在为对方共享您的信息，请勿关闭")
                putExtra("channelId", "kissu_location_service")
                putExtra("notificationId", 1001)
                putExtra("iconName", "ic_launcher")
                putExtra("priority", 2) // PRIORITY_HIGH
                putExtra("ongoing", true)
                putExtra("autoCancel", false)
                putExtra("enableVibration", false)
                putExtra("enableSound", false)
            }
            heartbeatIntent = PendingIntent.getService(
                this,
                2003,
                intent,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
            )

            val triggerAt = SystemClock.elapsedRealtime() + 180 * 1000L // 3分钟，降低高频唤醒风险
            heartbeatIntent?.let { pi ->
                am.setExactAndAllowWhileIdle(
                    AlarmManager.ELAPSED_REALTIME_WAKEUP,
                    triggerAt,
                    pi
                )
            }
            // logInfo("❤️ 心跳闹钟已设置，3分钟后触发")
        } catch (e: Exception) {
            logError("设置心跳闹钟失败", extra = mapOf("error" to (e.message ?: "unknown")))
        }
    }

    /**
     * 停止心跳闹钟
     */
    private fun stopHeartbeatAlarm() {
        try {
            val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            heartbeatIntent?.let { am.cancel(it) }
            heartbeatIntent = null
            logInfo("❤️ 心跳闹钟已停止")
        } catch (e: Exception) {
            logError("停止心跳闹钟失败", extra = mapOf("error" to (e.message ?: "unknown")))
        }
    }
    
    /**
     * 息屏时的额外保活机制：更频繁的检查和唤醒
     */
    private fun startScreenOffKeepAlive() {
        try {
            // 1. 启动保活定时器（每60秒检查一次，降低高频唤醒风险）
            screenOffKeepAliveTimer?.cancel()
            screenOffKeepAliveTimer = Timer().apply {
                schedule(object : TimerTask() {
                    override fun run() {
                        try {
                            // 确保 WAKE_LOCK 持续持有
                            wakeLock?.let {
                                if (!it.isHeld) {
                                    it.acquire()
                                    Log.d(TAG, "🌙 息屏保活：重新获取 WAKE_LOCK")
                                }
                            }
                            
                            // 检查定位客户端是否存活
                            locationClient?.let { client ->
                                if (!client.isStarted) {
                                    if (hasLocationPermissions()) {
                                        client.startLocation()
                                        Log.d(TAG, "🌙 息屏保活：重新启动定位客户端")
                                    }
                                }
                            }
                            
                            // 检查上报服务是否存活
                            if (locationReportService == null) {
                                locationReportService = LocationReportService(this@ForegroundLocationService)
                                Log.d(TAG, "🌙 息屏保活：重新创建上报服务")
                            }
                            
                            // 🔥 确保上报定时器在运行（可能被系统回收）
                            locationReportService?.ensureReportTimerRunning()
                            
                            // 确保心跳闹钟已设置
                            ensureHeartbeatAlarm()
                            ensureScreenOffHeartbeatAlarm()
                            
                            Log.d(TAG, "🌙 息屏保活检查完成")
                        } catch (e: Exception) {
                            logError("息屏保活检查异常", extra = mapOf("error" to (e.message ?: "unknown")))
                        }
                    }
                }, 60_000L, 60_000L) // 每60秒检查一次
            }
            
            // 2. 设置息屏心跳闹钟（每120秒唤醒一次，平衡保活与耗电）
            ensureScreenOffHeartbeatAlarm()
            
            // logInfo("🌙 息屏保活机制已启动（60秒检查 + 120秒心跳）")
        } catch (e: Exception) {
            logError("启动息屏保活机制失败", extra = mapOf("error" to (e.message ?: "unknown")))
        }
    }
    
    /**
     * 停止息屏保活机制
     */
    private fun stopScreenOffKeepAlive() {
        try {
            // 停止保活定时器
            screenOffKeepAliveTimer?.cancel()
            screenOffKeepAliveTimer = null
            
            // 停止息屏心跳闹钟
            stopScreenOffHeartbeatAlarm()
            
            Log.d(TAG, "🌙 息屏保活机制已停止")
        } catch (e: Exception) {
            logError("停止息屏保活机制失败", extra = mapOf("error" to (e.message ?: "unknown")))
        }
    }
    
    /**
     * 息屏时的额外心跳闹钟：每120秒唤醒一次
     */
    private fun ensureScreenOffHeartbeatAlarm() {
        try {
            val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(this, ForegroundLocationService::class.java).apply {
                action = ACTION_START_FOREGROUND_SERVICE
                // 使用统一的通知配置
                putExtra("title", "Kissu")
                putExtra("content", "请不要关掉Kissu后台进程\n当前正在为对方共享您的信息，请勿关闭")
                putExtra("channelId", "kissu_location_service")
                putExtra("notificationId", 1001)
                putExtra("iconName", "ic_launcher")
                putExtra("priority", 2)
                putExtra("ongoing", true)
                putExtra("autoCancel", false)
                putExtra("enableVibration", false)
                putExtra("enableSound", false)
            }
            screenOffHeartbeatIntent = PendingIntent.getService(
                this,
                2004, // 不同的requestCode，避免与普通心跳冲突
                intent,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
            )

            val triggerAt = SystemClock.elapsedRealtime() + 120 * 1000L // 120秒后触发
            screenOffHeartbeatIntent?.let { pi ->
                // 使用 setExactAndAllowWhileIdle 确保在 Doze 模式下也能触发
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    am.setExactAndAllowWhileIdle(
                        AlarmManager.ELAPSED_REALTIME_WAKEUP,
                        triggerAt,
                        pi
                    )
                } else {
                    am.setExact(
                        AlarmManager.ELAPSED_REALTIME_WAKEUP,
                        triggerAt,
                        pi
                    )
                }
            }
            Log.d(TAG, "🌙 息屏心跳闹钟已设置，120秒后触发")
        } catch (e: Exception) {
            logError("设置息屏心跳闹钟失败", extra = mapOf("error" to (e.message ?: "unknown")))
        }
    }
    
    /**
     * 停止息屏心跳闹钟
     */
    private fun stopScreenOffHeartbeatAlarm() {
        try {
            val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            screenOffHeartbeatIntent?.let { am.cancel(it) }
            screenOffHeartbeatIntent = null
            Log.d(TAG, "🌙 息屏心跳闹钟已停止")
        } catch (e: Exception) {
            logError("停止息屏心跳闹钟失败", extra = mapOf("error" to (e.message ?: "unknown")))
        }
    }
    
    /**
     * 定位监听回调
     */
    override fun onLocationChanged(location: AMapLocation?) {
        if (location == null) {
             logWarning("⚠️ 原生定位回调：位置为空")
            return
        }
        
        Log.d(TAG, "📍 原生定位成功: ${location.latitude}, ${location.longitude}, 精度: ${location.accuracy}m")
        
        // 统一走原生上报通道（前台/后台/被杀）
        locationReportService?.reportLocation(location)
        
        // 更新通知内容
        updateLocationNotification(location)
    }
    
    /**
     * 检查是否应该上报位置
     * 避免与Flutter应用前台时的位置上报重复
     */
    private fun shouldReportLocation(): Boolean {
        return try {
            // 使用更现代的方法检测应用是否在前台
            val isAppInForeground = isAppInForeground()
            
            if (isAppInForeground) {
                Log.d(TAG, "检测到应用在前台，跳过原生位置上报")
                return false
            }
            
            // 应用在后台，允许上报
            Log.d(TAG, "应用在后台，允许原生位置上报")
            true
            
        } catch (e: Exception) {
            logError("检查应用状态失败，默认允许上报", extra = mapOf("error" to (e.message ?: "unknown")))
            // 如果检查失败，为了保险起见，允许上报
            true
        }
    }
    
    /**
     * 检测应用是否在前台运行
     * 使用多种方法确保兼容性
     */
    private fun isAppInForeground(): Boolean {
        return try {
            // 方法1: 使用 ActivityManager (适用于较新版本)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                val runningAppProcesses = activityManager.runningAppProcesses
                
                for (processInfo in runningAppProcesses) {
                    if (processInfo.processName == packageName) {
                        val isForeground = processInfo.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND
                        Log.d(TAG, "使用RunningAppProcesses检测: 应用${if (isForeground) "在前台" else "在后台"}")
                        return isForeground
                    }
                }
            }
            
            // 方法2: 使用 UsageStatsManager (需要权限，但更准确)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                try {
                    val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
                    val time = System.currentTimeMillis()
                    val usageStats = usageStatsManager.queryUsageStats(
                        UsageStatsManager.INTERVAL_DAILY,
                        time - 1000 * 60, // 1分钟前
                        time
                    )
                    
                    for (usageStat in usageStats) {
                        if (usageStat.packageName == packageName) {
                            val isForeground = usageStat.lastTimeUsed > time - 1000 * 10 // 10秒内有使用
                            Log.d(TAG, "使用UsageStats检测: 应用${if (isForeground) "在前台" else "在后台"}")
                            return isForeground
                        }
                    }
                } catch (e: Exception) {
                    logError("UsageStats检测失败，可能缺少权限", extra = mapOf("error" to (e.message ?: "unknown")))
                }
            }
            
            // 方法3: 使用传统的getRunningTasks (作为后备方案)
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                val runningTasks = activityManager.getRunningTasks(1)
                
                if (runningTasks.isNotEmpty()) {
                    val topActivity = runningTasks[0].topActivity
                    val isForeground = topActivity?.packageName == packageName
                    Log.d(TAG, "使用getRunningTasks检测: 应用${if (isForeground) "在前台" else "在后台"}")
                    return isForeground
                }
            }
            
            // 如果所有方法都失败，默认认为应用在后台
            logWarning("无法检测应用状态，默认认为在后台")
            false
            
        } catch (e: Exception) {
            logError("检测应用前台状态失败", extra = mapOf("error" to (e.message ?: "unknown")))
            false
        }
    }
    
    /**
     * 更新定位通知内容
     * 🔧 已禁用：保持静默，不更新通知
     */
    private fun updateLocationNotification(location: AMapLocation) {
        // 🔧 移除通知更新，保持静默
        // 不在定位成功后更新通知内容，避免频繁弹出通知
        // Log.d(TAG, "定位成功，静默模式（不更新通知）")
    }
    
    // ================================
    // 🔥 App使用记录上报相关方法
    // ================================
    
    /**
     * 启动App使用记录上报
     * 在应用被杀或后台时，定期采集并上报App使用记录
     */
    private fun startAppUsageReporting() {
        try {
            appUsageReportService?.let { service ->
                // 立即执行一次采集和上报
                service.collectAndReportUsageData()
                
                // 启动定时器，每2分钟采集一次（与Flutter层保持一致）
                appUsageReportTimer?.cancel()
                appUsageReportTimer = Timer().apply {
                    schedule(object : TimerTask() {
                        override fun run() {
                            // Flutter 上报已禁用，前台也由原生采集上报
                            Log.d(TAG, "📱 执行App使用记录采集和上报（前台/后台统一原生）")
                            service.collectAndReportUsageData()
                        }
                    }, 120000L, 120000L) // 2分钟间隔
                }
                Log.d(TAG, "🚀 App使用记录上报已启动（每2分钟采集一次，前台/后台统一原生）")
            }
        } catch (e: Exception) {
            logError("启动App使用记录上报失败", extra = mapOf("error" to (e.message ?: "unknown")))
        }
    }
    
    /**
     * 停止App使用记录上报
     */
    private fun stopAppUsageReporting() {
        try {
            appUsageReportTimer?.cancel()
            appUsageReportTimer = null
            appUsageReportService?.destroy()
            appUsageReportService = null
            Log.d(TAG, "App使用记录上报已停止")
        } catch (e: Exception) {
            Log.e(TAG, "停止App使用记录上报失败", e)
        }
    }

    // ================================
    // 🔥 锁屏/解锁敏感事件上报相关方法
    // ================================

    /**
     * 注册锁屏/解锁广播接收器
     *
     * 注意：
     * - 只有在 Flutter 引擎不存活时才执行原生上报，避免与 Flutter 重复
     * - 利用前台服务保活能力，在 APP 被杀但服务仍在时继续上报
     */
    private fun registerScreenEventReceiver() {
        if (screenEventReceiver != null) {
            Log.d(TAG, "锁屏/解锁广播接收器已注册，跳过")
            return
        }

        if (sensitiveEventReportService == null) {
            logWarning(TAG, "敏感事件上报服务未初始化，无法注册锁屏广播接收器")
            return
        }

        screenEventReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (context == null || intent == null) return

                val action = intent.action ?: return
                val nowMillis = System.currentTimeMillis()
                val timestampSeconds = nowMillis / 1000

                try {
                    when (action) {
                        Intent.ACTION_SCREEN_OFF -> {
                            // 🔥 防抖：1秒内重复的锁屏广播只处理一次
                            if (nowMillis - lastScreenOffTime < BROADCAST_DEBOUNCE_MS) {
                                Log.d(TAG, "⚠️ 锁屏广播防抖：${nowMillis - lastScreenOffTime}ms 内重复，跳过")
                                return
                            }
                            lastScreenOffTime = nowMillis
                            
                            logInfo("🌙 收到锁屏广播")
                            
                            // 🔥 息屏时加强保活：确保 WAKE_LOCK 持续持有
                            try {
                                wakeLock?.let {
                                    if (!it.isHeld) {
                                        it.acquire()
                                        Log.d(TAG, "💪 息屏保活：重新获取 WAKE_LOCK")
                                    }
                                }
                            } catch (e: Exception) {
                                logError("息屏时获取 WAKE_LOCK 失败", extra = mapOf("error" to (e.message ?: "unknown")))
                            }
                            
                            // 🔥 息屏时立即设置心跳闹钟，确保1分钟后唤醒
                            ensureHeartbeatAlarm()
                            
                            // 🔥 息屏时启动额外的保活机制：更频繁的检查和唤醒
                            startScreenOffKeepAlive()
                            
                            // Flutter 存活时交给 Flutter 处理
                            if (MainActivity.isFlutterEngineAlive) {
                                Log.d(TAG, "Flutter 引擎存活，锁屏事件交由 Flutter 处理")
                                return
                            }
                            sensitiveEventReportService?.reportScreenEvent(
                                isUnlock = false,
                                timestampSeconds = timestampSeconds
                            )
                        }
                        Intent.ACTION_USER_PRESENT, Intent.ACTION_USER_UNLOCKED -> {
                            // 🔥 防抖：1秒内重复的解锁广播只处理一次
                            if (nowMillis - lastUnlockTime < BROADCAST_DEBOUNCE_MS) {
                                Log.d(TAG, "⚠️ 解锁广播防抖：${nowMillis - lastUnlockTime}ms 内重复，跳过")
                                return
                            }
                            lastUnlockTime = nowMillis
                            
                            Log.d(TAG, "🔓 [Service] 收到解锁广播 $action")
                            logInfo("🔓 收到解锁广播", extra = mapOf("action" to action))
                            if (MainActivity.isFlutterEngineAlive) {
                                Log.d(TAG, "Flutter 引擎存活，解锁事件交由 Flutter 处理")
                                return
                            }
                            sensitiveEventReportService?.reportScreenEvent(
                                isUnlock = true,
                                timestampSeconds = timestampSeconds
                            )
                        }
                        Intent.ACTION_SCREEN_ON -> {
                            // 🔥 防抖：1秒内重复的亮屏广播只处理一次
                            if (nowMillis - lastScreenOnTime < BROADCAST_DEBOUNCE_MS) {
                                Log.d(TAG, "⚠️ 亮屏广播防抖：${nowMillis - lastScreenOnTime}ms 内重复，跳过")
                                return
                            }
                            lastScreenOnTime = nowMillis
                            
                            logInfo("💡 收到亮屏广播")
                            
                            // 🔥 亮屏时停止息屏保活机制（节省资源）
                            stopScreenOffKeepAlive()

                            // 🔥 若服务标记为未运行（被系统回收），立刻自拉起
                            if (!isServiceRunning) {
                                try {
                                    val restartIntent = Intent(
                                        this@ForegroundLocationService,
                                        ForegroundLocationService::class.java
                                    ).apply {
                                        setAction(ACTION_START_FOREGROUND_SERVICE)
                                    }
                                    ContextCompat.startForegroundService(
                                        this@ForegroundLocationService,
                                        restartIntent
                                    )
                                    Log.d(TAG, "💡 亮屏自拉起前台服务")
                                } catch (e: Exception) {
                                    logError("亮屏自拉起前台服务失败", extra = mapOf("error" to (e.message ?: "unknown")))
                                }
                            }
                            
                            // 🔥 亮屏时检查服务状态并恢复
                            try {
                                // 检查定位客户端是否存活
                                if (locationClient == null || !locationClient!!.isStarted) {
                                    Log.w(TAG, "💡 亮屏检查：定位客户端异常，尝试恢复")
                                    if (hasLocationPermissions()) {
                                        synchronized(locationClientLock) {
                                            initLocationClient()
                                            startLocationTracking()
                                        }
                                    }
                                }
                                
                                // 检查上报服务是否存活
                                if (locationReportService == null) {
                                    Log.w(TAG, "💡 亮屏检查：上报服务异常，尝试恢复")
                                    locationReportService = LocationReportService(this@ForegroundLocationService)
                                }
                                
                                // 🔥 确保上报定时器在运行（防止定时器被系统回收）
                                locationReportService?.ensureReportTimerRunning()
                                
                                // 确保健康检查在运行
                                if (healthCheckTimer == null) {
                                    Log.w(TAG, "💡 亮屏检查：健康检查异常，尝试恢复")
                                    startHealthCheck()
                                }
                                
                                // 确保心跳闹钟已设置
                                ensureHeartbeatAlarm()
                                
                                Log.d(TAG, "💡 亮屏检查完成，服务状态已恢复")
                            } catch (e: Exception) {
                                logError("亮屏时恢复服务失败", extra = mapOf("error" to (e.message ?: "unknown")))
                            }
                        }
                    }
                } catch (e: Exception) {
                    logError("处理锁屏/解锁广播时异常", extra = mapOf("error" to (e.message ?: "unknown")))
                }
            }
        }

        try {
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_SCREEN_OFF)
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_USER_PRESENT)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    addAction(Intent.ACTION_USER_UNLOCKED)
                }
            }
            registerReceiver(screenEventReceiver, filter)
            Log.d(TAG, "锁屏/解锁广播接收器已注册（服务级）")
        } catch (e: Exception) {
            logError("注册锁屏/解锁广播接收器失败", extra = mapOf("error" to (e.message ?: "unknown")))
            screenEventReceiver = null
        }
    }

    /**
     * 注销锁屏/解锁广播接收器
     */
    private fun unregisterScreenEventReceiver() {
        screenEventReceiver?.let {
            try {
                unregisterReceiver(it)
                Log.d(TAG, "锁屏/解锁广播接收器已注销")
            } catch (e: Exception) {
                logError("注销锁屏/解锁广播接收器失败", extra = mapOf("error" to (e.message ?: "unknown")))
            }
        }
        screenEventReceiver = null
        sensitiveEventReportService = null
    }

    private fun registerNetworkReceiver() {
        if (networkReceiver != null) return
        if (sensitiveEventReportService == null) return

        networkReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                context ?: return
                handleNetworkChange(context)
            }
        }

        try {
            val (state, wifiName) = getCurrentNetworkInfo(this)
            lastNetworkState = state
            lastWifiName = wifiName

            val filter = IntentFilter().apply {
                addAction(ConnectivityManager.CONNECTIVITY_ACTION)
                addAction(WifiManager.NETWORK_STATE_CHANGED_ACTION)
            }
            registerReceiver(networkReceiver, filter)
            Log.d(TAG, "网络状态广播接收器已注册")
        } catch (e: Exception) {
            logError("注册网络状态广播接收器失败", extra = mapOf("error" to (e.message ?: "unknown")))
            networkReceiver = null
        }
    }

    private fun unregisterNetworkReceiver() {
        networkReceiver?.let {
            try {
                unregisterReceiver(it)
                Log.d(TAG, "网络状态广播接收器已注销")
            } catch (e: Exception) {
                logError("注销网络状态广播接收器失败", extra = mapOf("error" to (e.message ?: "unknown")))
            }
        }
        networkReceiver = null
        lastNetworkState = NetworkState.NONE
        lastWifiName = null
    }

    private fun registerChargingReceiver() {
        if (chargingReceiver != null) return
        if (sensitiveEventReportService == null) return

        chargingReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                context ?: return
                when (intent?.action) {
                    Intent.ACTION_POWER_CONNECTED -> handleChargingStateChange(true)
                    Intent.ACTION_POWER_DISCONNECTED -> handleChargingStateChange(false)
                }
            }
        }

        try {
            lastChargingState = getCurrentChargingState()

            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_POWER_CONNECTED)
                addAction(Intent.ACTION_POWER_DISCONNECTED)
            }
            registerReceiver(chargingReceiver, filter)
            Log.d(TAG, "充电状态广播接收器已注册")
        } catch (e: Exception) {
            logError("注册充电状态广播接收器失败", extra = mapOf("error" to (e.message ?: "unknown")))
            chargingReceiver = null
        }
    }

    private fun unregisterChargingReceiver() {
        chargingReceiver?.let {
            try {
                unregisterReceiver(it)
                Log.d(TAG, "充电状态广播接收器已注销")
            } catch (e: Exception) {
                logError("注销充电状态广播接收器失败", extra = mapOf("error" to (e.message ?: "unknown")))
            }
        }
        chargingReceiver = null
        lastChargingState = null
    }

    private fun handleNetworkChange(context: Context) {
        val (newState, wifiName) = getCurrentNetworkInfo(context)
        processNetworkChange(newState, wifiName)
    }

    private fun getCurrentNetworkInfo(context: Context): Pair<NetworkState, String?> {
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        var newState = NetworkState.NONE
        var currentWifiName: String? = null

        val activeNetwork = cm.activeNetwork
        if (activeNetwork != null) {
            val capabilities = cm.getNetworkCapabilities(activeNetwork)
            val hasInternet = capabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true
            if (hasInternet) {
                when {
                    capabilities!!.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> {
                        newState = NetworkState.WIFI
                        val wifiManager =
                            applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                        val info = wifiManager.connectionInfo
                        currentWifiName = info?.ssid?.trim('"')
                    }
                    capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> {
                        newState = NetworkState.MOBILE
                    }
                    else -> newState = NetworkState.OTHER
                }
            }
        } else {
            @Suppress("DEPRECATION")
            val activeInfo = cm.activeNetworkInfo
            if (activeInfo != null && activeInfo.isConnected) {
                when (activeInfo.type) {
                    ConnectivityManager.TYPE_WIFI -> {
                        newState = NetworkState.WIFI
                        val wifiManager =
                            applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                        val info = wifiManager.connectionInfo
                        currentWifiName = info?.ssid?.trim('"')
                    }
                    ConnectivityManager.TYPE_MOBILE -> newState = NetworkState.MOBILE
                    else -> newState = NetworkState.OTHER
                }
            }
        }

        return Pair(newState, currentWifiName)
    }

    private fun processNetworkChange(newState: NetworkState, currentWifiName: String?) {
        if (newState == NetworkState.WIFI) {
            val sanitizedName = currentWifiName
                ?.takeIf { it.isNotBlank() && !it.equals("<unknown ssid>", ignoreCase = true) }

            if (sanitizedName == null) {
                Log.d(TAG, "Wi-Fi SSID 尚未获取，等待稳定后再上报")
                return
            }

            if (lastNetworkState != NetworkState.WIFI || sanitizedName != lastWifiName) {
                logInfo("📡 网络变化：切换到WiFi", extra = mapOf("wifiName" to sanitizedName))
                sensitiveEventReportService?.reportSensitiveEvent(
                    eventType = 6,
                    extMap = mapOf("network_name" to sanitizedName),
                    extraHeaders = mapOf("network-name" to sanitizedName),
                    forceNative = true
                )
                lastWifiName = sanitizedName
            }

            lastNetworkState = NetworkState.WIFI
            return
        }

        if (newState == NetworkState.MOBILE) {
            if (lastNetworkState != NetworkState.MOBILE) {
                logInfo("📡 网络变化：切换到移动网络")
                sensitiveEventReportService?.reportSensitiveEvent(
                    eventType = 21,
                    extraHeaders = mapOf("network-name" to "mobile"),
                    forceNative = true
                )
                lastWifiName = null
            }
            lastNetworkState = NetworkState.MOBILE
            return
        }

        // 其他网络或无网络
        if (newState != lastNetworkState) {
            lastWifiName = null
        }
        lastNetworkState = newState
    }

    private fun handleChargingStateChange(isCharging: Boolean) {
        if (lastChargingState != null && lastChargingState == isCharging) {
            return
        }
        lastChargingState = isCharging

        val batteryLevel = getBatteryLevel()
        val eventType = if (isCharging) 7 else 8
        logInfo("🔋 充电状态变化", extra = mapOf(
            "isCharging" to isCharging,
            "batteryLevel" to batteryLevel
        ))
        sensitiveEventReportService?.reportSensitiveEvent(
            eventType = eventType,
            extMap = mapOf("power" to batteryLevel.toString()),
            extraHeaders = mapOf("power" to batteryLevel.toString()),
            forceNative = true
        )
    }

    private fun getBatteryLevel(): Int {
        return try {
            val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            val level = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
            if (level >= 0) level else fetchBatteryLevelFromIntent()
        } catch (e: Exception) {
            fetchBatteryLevelFromIntent()
        }
    }

    private fun getCurrentChargingState(): Boolean? {
        val intent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED)) ?: return null
        val status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
        return when (status) {
            BatteryManager.BATTERY_STATUS_CHARGING,
            BatteryManager.BATTERY_STATUS_FULL -> true
            BatteryManager.BATTERY_STATUS_DISCHARGING,
            BatteryManager.BATTERY_STATUS_NOT_CHARGING -> false
            else -> null
        }
    }

    private fun fetchBatteryLevelFromIntent(): Int {
        val intent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        return intent?.let {
            val level = it.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
            val scale = it.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
            if (level >= 0 && scale > 0) (level * 100) / scale else -1
        } ?: -1
    }

    private enum class NetworkState {
        NONE, WIFI, MOBILE, OTHER
    }

    // ================================
    // 🔥 原生层文件日志功能
    // ================================
    
    /**
     * 写入原生层日志到文件（与 Flutter 层日志目录一致）
     * 日志格式与 Flutter 层保持一致，便于统一分析
     */
    private fun writeNativeLog(level: String, message: String, tag: String = NATIVE_LOG_TAG, extra: Map<String, Any>? = null) {
        try {
            // 使用与 Flutter 层相同的日志目录：filesDir/logs（对应 getApplicationSupportDirectory()/logs）
            val logDir = File(applicationContext.filesDir, "logs")
            if (!logDir.exists()) {
                logDir.mkdirs()
            }
            
            // 使用与 Flutter 层相同的文件命名格式
            val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH-mm-ss.SSSSSS", Locale.getDefault())
            val todayFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
            val today = todayFormat.format(Date())
            
            // 查找今天的定位日志文件，如果不存在则创建新的
            val existingLogFile = logDir.listFiles()?.find { 
                it.name.startsWith(today) && it.name.endsWith("_location.log") 
            }
            
            val logFile = existingLogFile ?: File(logDir, "${dateFormat.format(Date())}_location.log")
            
            // 构建与 Flutter 层格式一致的 JSON 日志
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
            Log.e(TAG, "写入原生日志文件失败", e)
        }
    }
    
    /**
     * 记录 INFO 级别日志
     */
    private fun logInfo(message: String, tag: String = NATIVE_LOG_TAG, extra: Map<String, Any>? = null) {
        Log.d(TAG, "[$tag] $message")
        writeNativeLog("INFO", message, tag, extra)
    }
    
    /**
     * 记录 WARNING 级别日志
     */
    private fun logWarning(message: String, tag: String = NATIVE_LOG_TAG, extra: Map<String, Any>? = null) {
        Log.w(TAG, "[$tag] $message")
        writeNativeLog("WARNING", message, tag, extra)
    }
    
    /**
     * 记录 ERROR 级别日志
     */
    private fun logError(message: String, tag: String = NATIVE_LOG_TAG, extra: Map<String, Any>? = null) {
        Log.e(TAG, "[$tag] $message")
        writeNativeLog("ERROR", message, tag, extra)
    }
    
    /**
     * 🔒 检查锁屏状态，如果有锁屏数据且锁屏服务未运行，则启动锁屏服务
     * 用于 app 被杀后，保活服务恢复时检查是否需要显示锁屏
     */
    private fun checkAndStartLockScreenService() {
        try {
            val lockPrefs = getSharedPreferences(LockScreenOverlayService.PREFS_NAME, Context.MODE_PRIVATE)
            val screenLockJson = lockPrefs.getString(LockScreenOverlayService.KEY_SCREEN_LOCK, null)
            
            if (screenLockJson != null) {
                // 检查锁屏是否过期
                val obj = org.json.JSONObject(screenLockJson)
                val endTime = obj.optLong("endTime", 0)
                
                if (endTime > System.currentTimeMillis()) {
                    // 锁屏未过期，检查锁屏服务是否在运行
                    if (!isLockScreenServiceRunning()) {
                        logInfo("🔒 保活检查：检测到锁屏数据，启动锁屏服务")
                        startLockScreenService()
                    }
                } else {
                    // 锁屏已过期，清除数据
                    lockPrefs.edit().remove(LockScreenOverlayService.KEY_SCREEN_LOCK).apply()
                    logInfo("🔓 保活检查：锁屏已过期，清除锁屏数据")
                }
            }
        } catch (e: Exception) {
            logError("检查锁屏状态失败", extra = mapOf("error" to (e.message ?: "unknown")))
        }
    }
    
    /**
     * 检查锁屏服务是否在运行
     */
    private fun isLockScreenServiceRunning(): Boolean {
        try {
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            @Suppress("DEPRECATION")
            for (service in activityManager.getRunningServices(Int.MAX_VALUE)) {
                if (LockScreenOverlayService::class.java.name == service.service.className) {
                    return true
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "检查锁屏服务状态失败", e)
        }
        return false
    }
    
    /**
     * 启动锁屏服务
     */
    private fun startLockScreenService() {
        try {
            val intent = Intent(this, LockScreenOverlayService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            Log.d(TAG, "🔒 锁屏服务已启动")
        } catch (e: Exception) {
            logError("启动锁屏服务失败", extra = mapOf("error" to (e.message ?: "unknown")))
        }
    }
}

/**
 * 使用 WorkManager 兜底重启前台定位服务
 */
class LocationServiceRestartWorker(
    appContext: Context,
    params: WorkerParameters
) : Worker(appContext, params) {

    override fun doWork(): Result {
        return try {
            val intent = Intent(applicationContext, ForegroundLocationService::class.java).apply {
                action = ForegroundLocationService.ACTION_START_FOREGROUND_SERVICE
                putExtra("title", "Kissu")
                putExtra("content", "请不要关掉Kissu后台进程\n当前正在为对方共享您的信息，请勿关闭")
                putExtra("channelId", "kissu_location_service")
                putExtra("notificationId", 1001)
                putExtra("iconName", "ic_launcher")
                putExtra("priority", 2)
                putExtra("ongoing", true)
                putExtra("autoCancel", false)
                putExtra("enableVibration", false)
                putExtra("enableSound", false)
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                applicationContext.startForegroundService(intent)
            } else {
                applicationContext.startService(intent)
            }
            Log.d("LocationServiceRestartWorker", "已通过 WorkManager 触发前台服务重启")
            Result.success()
        } catch (e: Exception) {
            Log.e("LocationServiceRestartWorker", "WorkManager 重启失败", e)
            Result.retry()
        }
    }
}
