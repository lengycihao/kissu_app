package com.yuluo.kissu

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import com.umeng.commonsdk.UMConfigure
import com.tencent.chat.flutter.push.tencent_cloud_chat_push.application.TencentCloudChatPushApplication
import com.tencent.qcloud.tim.push.TIMPushListener
import com.tencent.qcloud.tim.push.TIMPushManager

class KissuApplication : TencentCloudChatPushApplication() {
    companion object {
        private const val TAG = "KissuApplication"
        // 🔥 通知渠道ID必须与 timpush-configs.json 中的 notificationChannelId 保持一致
        private const val CHANNEL_ID = "im_push_channel"
        private const val CHANNEL_NAME = "IM消息推送"
        // 🔥 OPPO私信通道ID（需要在OPPO开放平台申请）
        private const val OPPO_CHANNEL_ID = "kissu_im_message"
        private const val OPPO_CHANNEL_NAME = "私信消息"
        private var notificationId = 1000
        
        /**
         * 初始化友盟SDK（在用户同意隐私政策后调用）
         * 🔥 隐私合规：此方法必须在用户明确同意隐私政策后才能调用
         */
        fun initUmengSdk(context: Context) {
            try {
                UMConfigure.init(
                    context,
                    "6879fba679267e0210b67bde",
                    "Umeng",
                    UMConfigure.DEVICE_TYPE_PHONE,
                    null
                )
                UMConfigure.setLogEnabled(true)
                Log.d(TAG, "✅ 友盟SDK已初始化（用户同意隐私政策后）")
            } catch (e: Exception) {
                Log.e(TAG, "❌ 初始化友盟SDK失败", e)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        
        // 创建通知渠道
        createNotificationChannel()
        
        // 🔥 设置自定义推送监听器，手动显示通知
        setupPushListener()

        // 🔥 隐私合规修复：添加友盟SDK的preInit调用
        // preInit不会收集敏感信息，只是预初始化SDK框架
        // 真正的init会在用户同意隐私政策后调用
        try { 
            UMConfigure.preInit(
                applicationContext,
                "6879fba679267e0210b67bde",
                "Umeng"
            )
            Log.d(TAG, "✅ 友盟SDK预初始化完成（preInit）")
        } catch (e: Exception) {
            Log.e(TAG, "❌ 友盟SDK预初始化失败", e)
        }
        
        Log.d(TAG, "Application.onCreate 完成（友盟SDK将在用户同意隐私政策后完成初始化）")
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // 默认 IM 消息通道
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "IM聊天消息通知"
                enableLights(true)
                enableVibration(true)
                setShowBadge(true)
                // 🔥 确保通知在锁屏上完整显示
                lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
                // 🔥 允许通知绕过勿扰模式（可选，根据需求决定是否启用）
                // setBypassDnd(true)
            }
            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "✅ 通知渠道已创建: $CHANNEL_ID, importance=HIGH")

            // // 🔥 OPPO 私信通道（channel_id 必须与 androidOPPOChannelID 一致）
            // // 当 App 进程被杀死时，OPPO 系统直接使用此 channel_id 创建通知
            // // 如果该 NotificationChannel 不存在，通知会被 Android 8+ 静默丢弃
            // val oppoChannel = NotificationChannel(
            //     OPPO_CHANNEL_ID,
            //     OPPO_CHANNEL_NAME,
            //     NotificationManager.IMPORTANCE_HIGH
            // ).apply {
            //     description = "OPPO私信消息推送通道"
            //     enableLights(true)
            //     enableVibration(true)
            //     setShowBadge(true)
            //     lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
            // }
            // notificationManager.createNotificationChannel(oppoChannel)
            // Log.d(TAG, "✅ OPPO私信通知渠道已创建: $OPPO_CHANNEL_ID, importance=HIGH")
        }
    }
    
    private fun setupPushListener() {
        try {
            TIMPushManager.getInstance().addPushListener(object : TIMPushListener() {
                override fun onRecvPushMessage(pushMessage: com.tencent.qcloud.tim.push.TIMPushMessage?) {
                    Log.d(TAG, "🔔 onRecvPushMessage 被调用")
                    
                    if (pushMessage == null) {
                        Log.w(TAG, "pushMessage is null")
                        return
                    }
                    
                    val title = pushMessage.title ?: "新消息"
                    val content = pushMessage.desc ?: ""
                    val ext = pushMessage.ext ?: ""
                    
                    Log.d(TAG, "🔔 收到推送: title=$title, content=$content, ext=$ext")
                    Log.d(TAG, "🔔 App状态: ${if (appInForeground) "前台" else "后台"}")

                    // 🔥 App在后台时，手动创建通知确保用户能看到
                    // SDK 的 disablePostNotificationInForeground(true) 只禁用了前台通知
                    // 后台场景需要在此回调中手动创建通知
                    if (!appInForeground) {
                        showBackgroundNotification(title, content, ext)
                    } else {
                        Log.d(TAG, "🔔 App在前台，由Flutter层处理消息展示")
                    }
                }
            })
            Log.d(TAG, "✅ 自定义推送监听器已设置")
        } catch (e: Exception) {
            Log.e(TAG, "设置推送监听器失败", e)
        }
    }

    /**
     * App在后台时手动创建系统通知
     * 确保即使SDK不自动弹出通知，用户也能收到提醒
     */
    private fun showBackgroundNotification(title: String, content: String, ext: String) {
        try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // 使用 PendingIntent 点击通知时打开App
            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            val pendingIntent = if (launchIntent != null) {
                android.app.PendingIntent.getActivity(
                    this, 0, launchIntent,
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                )
            } else null

            val notification = NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_notification)
                .setContentTitle(title)
                .setContentText(content)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setDefaults(NotificationCompat.DEFAULT_ALL)
                .apply {
                    if (pendingIntent != null) setContentIntent(pendingIntent)
                }
                .build()

            notificationManager.notify(notificationId++, notification)
            Log.d(TAG, "🔔 后台通知已创建: title=$title, content=$content")
        } catch (e: Exception) {
            Log.e(TAG, "创建后台通知失败", e)
        }
    }
}
