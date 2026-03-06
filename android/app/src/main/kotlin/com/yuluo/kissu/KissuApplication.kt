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
        private const val OPPO_CHANNEL_ID = "push_oplus_category_service"
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
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "✅ 通知渠道已创建: $CHANNEL_ID, importance=HIGH")
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
                    
                    // 🔥 修复：App在后台时，腾讯IM SDK会自动显示系统通知
                    // 不需要在这里手动创建通知，否则会导致重复通知
                    // Flutter层的TencentIMService也会处理消息，但只在前台显示Banner
                    Log.d(TAG, "🔔 App状态: ${if (appInForeground) "前台" else "后台"}")
                    Log.d(TAG, "🔔 腾讯IM SDK会自动处理后台通知，无需手动创建")
                }
            })
            Log.d(TAG, "✅ 自定义推送监听器已设置")
        } catch (e: Exception) {
            Log.e(TAG, "设置推送监听器失败", e)
        }
    }
}
