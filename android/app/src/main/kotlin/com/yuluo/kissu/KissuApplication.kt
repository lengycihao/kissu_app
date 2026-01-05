package com.yuluo.kissu

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
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
        private const val CHANNEL_ID = "im_message_channel"
        private const val CHANNEL_NAME = "IM消息通知"
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
            }
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "✅ 通知渠道已创建: $CHANNEL_ID")
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
                    
                    // 🔥 判断App是否在前台
                    if (!appInForeground) {
                        Log.d(TAG, "🔔 App在后台，显示本地通知")
                        showLocalNotification(title, content, ext)
                    } else {
                        Log.d(TAG, "🔔 App在前台，不显示通知")
                    }
                }
                
            })
            Log.d(TAG, "✅ 自定义推送监听器已设置")
        } catch (e: Exception) {
            Log.e(TAG, "设置推送监听器失败", e)
        }
    }
    
    private fun showLocalNotification(title: String, content: String, ext: String) {
        try {
            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("push_ext", ext)
            }
            
            val pendingIntent = PendingIntent.getActivity(
                this,
                notificationId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            val notification = NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_notification)
                .setContentTitle(title)
                .setContentText(content)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .setContentIntent(pendingIntent)
                .setDefaults(NotificationCompat.DEFAULT_ALL)
                .build()
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(notificationId++, notification)
            
            Log.d(TAG, "✅ 本地通知已显示: $title - $content")
        } catch (e: Exception) {
            Log.e(TAG, "显示本地通知失败", e)
        }
    }
}


