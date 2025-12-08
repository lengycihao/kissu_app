package com.yuluo.kissu

import android.Manifest
import android.app.*
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
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
import io.flutter.Log
import com.amap.api.location.AMapLocation
import com.amap.api.location.AMapLocationClient
import com.amap.api.location.AMapLocationClientOption
import com.amap.api.location.AMapLocationListener
import java.util.Timer
import java.util.TimerTask

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
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "前台定位服务创建")
        // ⚡ 关键修复：onCreate 中不做任何耗时操作，避免5秒超时
        // 所有初始化将在 onStartCommand 中的 startForeground() 之后进行
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_FOREGROUND_SERVICE -> {
                // 🔥 关键修复：必须先调用 startForeground()，避免5秒超时崩溃
                // 即使权限不足，也要先调用 startForeground()，否则会崩溃
                createBasicForegroundNotification(intent)
                // 标记服务期望保持运行，用于被系统杀死后的自恢复
                markServiceEnabled(true)
                
                // Android 14+ 对前台定位服务校验严格；缺权限时停止服务
                if (!hasLocationPermissions()) {
                    Log.e(TAG, "缺少前台定位或位置权限，停止启动前台服务")
                    // 延迟停止，确保 startForeground() 已生效
                    Handler(android.os.Looper.getMainLooper()).postDelayed({
                        stopSelf()
                        isServiceRunning = false
                    }, 100)
                    return START_NOT_STICKY
                }
                
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
                // 也必须先调用 startForeground()
                if (intent != null) {
                    createBasicForegroundNotification(intent)
                } else {
                    // 如果没有 intent，创建一个基本的通知
                    val basicIntent = Intent().apply {
                        action = ACTION_START_FOREGROUND_SERVICE
                    }
                    createBasicForegroundNotification(basicIntent)
                }
            }
        }
        
        // 返回START_STICKY确保服务被系统杀死后会重启
        return START_STICKY
    }
    
    /**
     * 初始化服务组件（在 startForeground() 之后调用）
     */
    private fun initializeServiceComponents() {
        // 如果已经初始化过，跳过
        if (locationClient != null) {
            Log.d(TAG, "服务组件已初始化，跳过")
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
                Log.e(TAG, "立即获取 WakeLock 失败", e)
            }
        } catch (e: Exception) {
            Log.e(TAG, "创建 WakeLock 失败", e)
        }
        
        // 🔥 初始化定位上报服务
        try {
            locationReportService = LocationReportService(this)
            Log.d(TAG, "定位上报服务初始化成功")
        } catch (e: Exception) {
            Log.e(TAG, "初始化定位上报服务失败", e)
        }
        
        // 🔥 初始化App使用记录上报服务
        try {
            appUsageReportService = AppUsageReportService(this)
            Log.d(TAG, "App使用记录上报服务初始化成功")
        } catch (e: Exception) {
            Log.e(TAG, "初始化App使用记录上报服务失败", e)
        }

        // 🔥 初始化敏感事件上报服务（锁屏/解锁）
        try {
            sensitiveEventReportService = SensitiveEventReportService(this)
            registerScreenEventReceiver()
            registerNetworkReceiver()
            registerChargingReceiver()
            Log.d(TAG, "敏感事件上报服务初始化成功")
        } catch (e: Exception) {
            Log.e(TAG, "初始化敏感事件上报服务失败", e)
        }
        
        // 🔥 初始化原生定位客户端
        initLocationClient()
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        return null // 不支持绑定
    }
    
    override fun onDestroy() {
        super.onDestroy()
        
        Log.w(TAG, "⚠️ 前台定位服务被销毁，尝试自恢复")
        
        // 🔥 停止定位监听
        stopLocationTracking()
        
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
            Log.e(TAG, "释放 WakeLock 失败", e)
        }
        
        // 无论是否打算重启，先同步运行状态，避免 Flutter 层误判
        isServiceRunning = false

        // 🔥 无条件安排一次重启，防止厂商 ROM 杀死后不再拉起
        scheduleRestart(reason = "onDestroy")
        
        Log.d(TAG, "前台定位服务销毁")
    }
    
    /**
     * 当任务被移除时（用户从最近任务中移除应用）
     * 某些系统会杀死服务，这里尝试重启
     */
    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        Log.w(TAG, "⚠️ 应用任务被移除，尝试重启服务")
        
        scheduleRestart(reason = "onTaskRemoved")
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
            startForeground(notificationId, notification)
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
                    
                startForeground(DEFAULT_NOTIFICATION_ID, defaultNotification)
                isServiceRunning = true
                Log.d(TAG, "⚡ 使用默认通知启动前台服务")
            } catch (e2: Exception) {
                Log.e(TAG, "创建默认前台通知也失败", e2)
                // 🔥 最后兜底：即使所有通知创建都失败，也必须调用 startForeground() 避免崩溃
                try {
                    val emergencyNotification = NotificationCompat.Builder(this, DEFAULT_CHANNEL_ID)
                        .setContentTitle("服务运行中")
                        .setContentText("")
                        .setSmallIcon(android.R.drawable.ic_menu_info_details)
                        .setPriority(NotificationCompat.PRIORITY_MIN)
                        .build()
                    startForeground(DEFAULT_NOTIFICATION_ID, emergencyNotification)
                    isServiceRunning = true
                    Log.d(TAG, "⚡ 使用紧急通知启动前台服务（避免崩溃）")
                } catch (e3: Exception) {
                    Log.e(TAG, "紧急通知也失败，服务可能崩溃", e3)
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
                Log.e(TAG, "获取 WakeLock 失败", e)
            }
            
            // 🔥 启动定位监听
            startLocationTracking()
            
            // 🔥 启动App使用记录上报
            startAppUsageReporting()
            
            Log.d(TAG, "前台定位服务启动成功")
            
        } catch (e: Exception) {
            Log.e(TAG, "启动前台服务失败", e)
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
            Log.d(TAG, "前台定位服务停止成功")
        } catch (e: Exception) {
            Log.e(TAG, "停止前台服务失败", e)
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
                
                Log.d(TAG, "通知更新成功: $title - $content")
            }
        } catch (e: Exception) {
            Log.e(TAG, "更新通知失败", e)
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
            Log.e(TAG, "定位权限不足：fg=$fgOk, coarse=$coarseOk, fine=$fineOk")
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
                putExtra("content", "请不要关掉Kisssu后台进程\n当前正在为对方共享您的信息，请勿关闭")
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
            Log.d(TAG, "🔄 已安排重启（$reason），delay=${delayMs}ms")
        } catch (e: Exception) {
            Log.e(TAG, "安排重启失败（$reason）", e)
        }
    }

    /**
     * 记录服务期望状态，便于被系统杀死后自恢复
     */
    private fun markServiceEnabled(enabled: Boolean) {
        try {
            val prefs = getSharedPreferences("kissu_location_prefs", Context.MODE_PRIVATE)
            prefs.edit().putBoolean("location_service_enabled", enabled).apply()
            Log.d(TAG, "服务期望状态已更新: $enabled")
        } catch (e: Exception) {
            Log.e(TAG, "更新服务期望状态失败", e)
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
            Log.w(TAG, "无法找到图标资源: $iconName，使用默认图标")
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
        try {
            locationClient = AMapLocationClient(applicationContext)
            locationClient?.setLocationListener(this)
            
            // 配置定位参数
            val locationOption = AMapLocationClientOption().apply {
                locationMode = AMapLocationClientOption.AMapLocationMode.Hight_Accuracy
                isGpsFirst = true
                httpTimeOut = 30000
                // ✅ 关键修复：与Flutter层统一为5秒，避免APP被杀后定位频率骤降
                interval = 5000 // 5秒定位一次（与Flutter层保持一致）
                isNeedAddress = true
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
            Log.e(TAG, "初始化定位客户端失败", e)
        }
    }
    
    /**
     * 启动定位监听
     */
    private fun startLocationTracking() {
        try {
            locationClient?.let { client ->
                if (!client.isStarted) {
                    client.startLocation()
                    Log.d(TAG, "🚀 原生定位监听已启动（APP被杀后仍可工作）")
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
                    Log.d(TAG, "原生定位监听已停止")
                }
                client.onDestroy()
            }
            locationClient = null
            locationReportService = null
        } catch (e: Exception) {
            Log.e(TAG, "停止定位监听失败", e)
        }
    }
    
    /**
     * 定位监听回调
     */
    override fun onLocationChanged(location: AMapLocation?) {
        if (location == null) {
            Log.w(TAG, "⚠️ 原生定位回调：位置为空")
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
            Log.e(TAG, "检查应用状态失败，默认允许上报", e)
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
                    Log.w(TAG, "UsageStats检测失败，可能缺少权限", e)
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
            Log.w(TAG, "无法检测应用状态，默认认为在后台")
            false
            
        } catch (e: Exception) {
            Log.e(TAG, "检测应用前台状态失败", e)
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
        Log.d(TAG, "定位成功，静默模式（不更新通知）")
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
                            // 检查应用是否在后台或被杀死
                            if (!isAppInForeground()) {
                                Log.d(TAG, "📱 应用在后台，执行App使用记录采集和上报")
                                service.collectAndReportUsageData()
                            } else {
                                Log.d(TAG, "⏸️ 应用在前台，跳过原生App使用记录上报（Flutter正在处理）")
                            }
                        }
                    }, 120000L, 120000L) // 2分钟间隔
                }
                Log.d(TAG, "🚀 App使用记录上报已启动（每2分钟采集一次）")
            }
        } catch (e: Exception) {
            Log.e(TAG, "启动App使用记录上报失败", e)
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
            Log.w(TAG, "敏感事件上报服务未初始化，无法注册锁屏广播接收器")
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
                            Log.d(TAG, "🌙 [Service] 收到锁屏广播 ACTION_SCREEN_OFF")
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
                            Log.d(TAG, "🔓 [Service] 收到解锁广播 $action")
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
                            // 亮屏本身不直接上报，仅作为调试日志
                            Log.d(TAG, "💡 [Service] 收到亮屏广播 ACTION_SCREEN_ON")
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "处理锁屏/解锁广播时异常", e)
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
            Log.e(TAG, "注册锁屏/解锁广播接收器失败", e)
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
                Log.e(TAG, "注销锁屏/解锁广播接收器失败", e)
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
            Log.e(TAG, "注册网络状态广播接收器失败", e)
            networkReceiver = null
        }
    }

    private fun unregisterNetworkReceiver() {
        networkReceiver?.let {
            try {
                unregisterReceiver(it)
                Log.d(TAG, "网络状态广播接收器已注销")
            } catch (e: Exception) {
                Log.e(TAG, "注销网络状态广播接收器失败", e)
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
            Log.e(TAG, "注册充电状态广播接收器失败", e)
            chargingReceiver = null
        }
    }

    private fun unregisterChargingReceiver() {
        chargingReceiver?.let {
            try {
                unregisterReceiver(it)
                Log.d(TAG, "充电状态广播接收器已注销")
            } catch (e: Exception) {
                Log.e(TAG, "注销充电状态广播接收器失败", e)
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
}
