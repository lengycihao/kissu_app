package com.yuluo.kissu

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.app.ActivityManager
import android.app.usage.UsageStatsManager
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.Log
import com.amap.api.location.AMapLocation
import com.amap.api.location.AMapLocationClient
import com.amap.api.location.AMapLocationClientOption
import com.amap.api.location.AMapLocationListener

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
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "前台定位服务创建")
        // ⚡ 关键修复：onCreate 中不做任何耗时操作，避免5秒超时
        // 所有初始化将在 onStartCommand 中的 startForeground() 之后进行
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_FOREGROUND_SERVICE -> {
                // 🔥 关键修复：第一时间调用 startForeground()，避免5秒超时崩溃
                createBasicForegroundNotification(intent)
                
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
        
        // 🔥 初始化原生定位客户端
        initLocationClient()
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        return null // 不支持绑定
    }
    
    override fun onDestroy() {
        super.onDestroy()
        isServiceRunning = false
        
        // 🔥 停止定位监听
        stopLocationTracking()
        
        // 🔥 释放 WAKE_LOCK
        try {
            wakeLock?.let {
                if (it.isHeld) {
                    it.release()
                    Log.d(TAG, "WakeLock 已释放")
                }
            }
            wakeLock = null
        } catch (e: Exception) {
            Log.e(TAG, "释放 WakeLock 失败", e)
        }
        
        Log.d(TAG, "前台定位服务销毁")
    }
    
    /**
     * 🔥 立即创建基本前台通知，避免5秒超时
     * 必须在 onStartCommand 中第一时间调用
     * ⚡ 性能优化：只使用最快的操作，避免任何耗时调用
     */
    private fun createBasicForegroundNotification(intent: Intent) {
        try {
            // 提取基本参数
            channelId = intent.getStringExtra(EXTRA_CHANNEL_ID) ?: DEFAULT_CHANNEL_ID
            notificationId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, DEFAULT_NOTIFICATION_ID)
            val channelName = intent.getStringExtra(EXTRA_CHANNEL_NAME) ?: "定位服务"
            val title = intent.getStringExtra(EXTRA_TITLE) ?: "Kissu - 情侣定位"
            val content = intent.getStringExtra(EXTRA_CONTENT) ?: "正在为您提供位置定位服务"
            
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
                throw e2 // 抛出异常让系统知道失败了
            }
        }
    }
    
    /**
     * 启动前台服务（延迟执行的完整初始化）
     */
    private fun startLocationForegroundService(intent: Intent) {
        try {
            // 提取配置参数
            val channelName = intent.getStringExtra(EXTRA_CHANNEL_NAME) ?: "定位服务"
            val channelDescription = intent.getStringExtra(EXTRA_CHANNEL_DESCRIPTION) ?: "为您提供位置定位服务"
            
            val title = intent.getStringExtra(EXTRA_TITLE) ?: "Kissu - 情侣定位"
            val content = intent.getStringExtra(EXTRA_CONTENT) ?: "正在为您提供位置定位服务"
            val iconName = intent.getStringExtra(EXTRA_ICON) ?: "ic_notification"
            val priority = intent.getStringExtra(EXTRA_PRIORITY) ?: "high"
            val importance = intent.getStringExtra(EXTRA_IMPORTANCE) ?: "high"
            val ongoing = intent.getBooleanExtra(EXTRA_ONGOING, true)
            val autoCancel = intent.getBooleanExtra(EXTRA_AUTO_CANCEL, false)
            val enableVibration = intent.getBooleanExtra(EXTRA_ENABLE_VIBRATION, false)
            val enableSound = intent.getBooleanExtra(EXTRA_ENABLE_SOUND, false)
            
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
            val title = intent.getStringExtra(EXTRA_TITLE) ?: "Kissu - 情侣定位"
            val content = intent.getStringExtra(EXTRA_CONTENT) ?: "正在为您提供位置定位服务"
            val bigText = intent.getStringExtra(EXTRA_BIG_TEXT)
            
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
        
        // 🔥 检查是否应该上报位置（避免与Flutter重复上报）
        if (shouldReportLocation()) {
            Log.d(TAG, "✅ 应用在后台，执行原生位置上报")
            locationReportService?.reportLocation(location)
        } else {
            Log.d(TAG, "⏸️ 应用在前台，跳过原生位置上报（Flutter正在处理）")
        }
        
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
}
