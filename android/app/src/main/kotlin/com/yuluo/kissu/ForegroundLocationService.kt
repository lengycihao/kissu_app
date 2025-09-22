package com.yuluo.kissu

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.Log

/**
 * 前台定位服务
 * 
 * 为应用提供持续的后台定位能力，符合Android 8.0+的后台执行限制
 */
class ForegroundLocationService : Service() {
    
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
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "前台定位服务创建")
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_FOREGROUND_SERVICE -> {
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
    
    override fun onBind(intent: Intent?): IBinder? {
        return null // 不支持绑定
    }
    
    override fun onDestroy() {
        super.onDestroy()
        isServiceRunning = false
        Log.d(TAG, "前台定位服务销毁")
    }
    
    /**
     * 启动前台服务
     */
    private fun startLocationForegroundService(intent: Intent) {
        try {
            // 提取配置参数
            channelId = intent.getStringExtra(EXTRA_CHANNEL_ID) ?: DEFAULT_CHANNEL_ID
            val channelName = intent.getStringExtra(EXTRA_CHANNEL_NAME) ?: "定位服务"
            val channelDescription = intent.getStringExtra(EXTRA_CHANNEL_DESCRIPTION) ?: "为您提供位置定位服务"
            notificationId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, DEFAULT_NOTIFICATION_ID)
            
            val title = intent.getStringExtra(EXTRA_TITLE) ?: "Kissu - 情侣定位"
            val content = intent.getStringExtra(EXTRA_CONTENT) ?: "正在为您提供位置定位服务"
            val iconName = intent.getStringExtra(EXTRA_ICON) ?: "ic_notification"
            val priority = intent.getStringExtra(EXTRA_PRIORITY) ?: "high"
            val importance = intent.getStringExtra(EXTRA_IMPORTANCE) ?: "high"
            val ongoing = intent.getBooleanExtra(EXTRA_ONGOING, true)
            val autoCancel = intent.getBooleanExtra(EXTRA_AUTO_CANCEL, false)
            val enableVibration = intent.getBooleanExtra(EXTRA_ENABLE_VIBRATION, false)
            val enableSound = intent.getBooleanExtra(EXTRA_ENABLE_SOUND, false)
            
            // 创建通知渠道
            createNotificationChannel(channelId, channelName, channelDescription, importance)
            
            // 构建通知
            val notification = buildNotification(
                title, content, iconName, priority, ongoing, autoCancel, enableVibration, enableSound
            )
            
            // 启动前台服务
            startForeground(notificationId, notification)
            isServiceRunning = true
            
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
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
        
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
            val resourceId = resources.getIdentifier(iconName, "drawable", packageName)
            if (resourceId != 0) resourceId else android.R.drawable.ic_dialog_info
        } catch (e: Exception) {
            Log.w(TAG, "无法找到图标资源: $iconName，使用默认图标")
            android.R.drawable.ic_dialog_info
        }
    }
}
