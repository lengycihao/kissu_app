package com.yuluo.kissu

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import cn.jpush.android.api.JPushInterface
import org.json.JSONObject

class JPushReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "JPushReceiver"
        private const val CHANNEL_ID = "kissu_push_channel"
        private const val CHANNEL_NAME = "Kissu推送通知"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        try {
            val bundle = intent.extras
            Log.d(TAG, "onReceive - action: ${intent.action}, extras: $bundle")
            
            when (intent.action) {
                JPushInterface.ACTION_REGISTRATION_ID -> {
                    val regId = bundle?.getString(JPushInterface.EXTRA_REGISTRATION_ID)
                    Log.d(TAG, "Registration ID: $regId")
                }
                
                JPushInterface.ACTION_MESSAGE_RECEIVED -> {
                    Log.d(TAG, "收到推送消息")
                    processCustomMessage(context, bundle)
                }
                
                JPushInterface.ACTION_NOTIFICATION_RECEIVED -> {
                    Log.d(TAG, "收到推送通知")
                    processNotificationReceived(context, bundle)
                }
                
                JPushInterface.ACTION_NOTIFICATION_OPENED -> {
                    Log.d(TAG, "用户点击了通知")
                    processNotificationOpened(context, bundle)
                }
                
                JPushInterface.ACTION_CONNECTION_CHANGE -> {
                    val connected = intent.getBooleanExtra(JPushInterface.EXTRA_CONNECTION_CHANGE, false)
                    Log.d(TAG, "JPush连接状态: $connected")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "处理JPush事件时出错", e)
        }
    }
    
    private fun processCustomMessage(context: Context, bundle: android.os.Bundle?) {
        bundle?.let { extras ->
            val title = extras.getString(JPushInterface.EXTRA_TITLE, "新消息")
            val message = extras.getString(JPushInterface.EXTRA_MESSAGE, "")
            val extrasStr = extras.getString(JPushInterface.EXTRA_EXTRA, "{}")
            
            Log.d(TAG, "自定义消息 - 标题: $title, 内容: $message, 附加: $extrasStr")
            
            // 创建自定义通知
            createCustomNotification(context, title, message, extrasStr)
        }
    }
    
    private fun processNotificationReceived(context: Context, bundle: android.os.Bundle?) {
        bundle?.let { extras ->
            val title = extras.getString(JPushInterface.EXTRA_NOTIFICATION_TITLE, "")
            val content = extras.getString(JPushInterface.EXTRA_ALERT, "")
            val extrasStr = extras.getString(JPushInterface.EXTRA_EXTRA, "{}")
            val notificationId = extras.getInt(JPushInterface.EXTRA_NOTIFICATION_ID, 0)
            val isAppInForeground = isAppInForeground(context)
            
            Log.d(TAG, "=== 收到推送通知 ===")
            Log.d(TAG, "标题: $title")
            Log.d(TAG, "内容: $content")
            Log.d(TAG, "通知ID: $notificationId")
            Log.d(TAG, "应用状态: ${if (isAppInForeground) "前台" else "后台"}")
            Log.d(TAG, "附加数据: $extrasStr")
            Log.d(TAG, "Bundle内容: $extras")
            
            // 关键修复：在后台时强制创建通知
            if (!isAppInForeground) {
                Log.d(TAG, "应用在后台，强制创建通知以确保用户能看到")
                createCustomNotification(context, title, content, extrasStr)
            } else {
                Log.d(TAG, "应用在前台，极光推送会自动处理通知")
            }
        }
    }
    
    private fun processNotificationOpened(context: Context, bundle: android.os.Bundle?) {
        // 打开应用
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        launchIntent?.let { intent ->
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            
            // 传递通知数据
            bundle?.let { extras ->
                val extrasStr = extras.getString(JPushInterface.EXTRA_EXTRA, "{}")
                intent.putExtra("jpush_extras", extrasStr)
            }
            
            context.startActivity(intent)
        }
    }
    
    private fun createCustomNotification(context: Context, title: String, content: String, extrasStr: String) {
        try {
            Log.d(TAG, "=== 开始创建通知 ===")
            Log.d(TAG, "标题: $title")
            Log.d(TAG, "内容: $content")
            Log.d(TAG, "渠道ID: $CHANNEL_ID")
            
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            // 创建通知渠道 (Android 8.0+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Kissu应用推送通知"
                    enableLights(true)
                    lightColor = android.graphics.Color.parseColor("#FF6B9D")
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 300, 300, 300)
                    setShowBadge(true)
                    lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
                    setBypassDnd(false)
                }
                notificationManager.createNotificationChannel(channel)
                Log.d(TAG, "通知渠道已创建: $CHANNEL_ID")
            }
            
            // 创建点击意图
            val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            intent?.putExtra("jpush_extras", extrasStr)
            
            val pendingIntent = PendingIntent.getActivity(
                context,
                System.currentTimeMillis().toInt(),
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            // 构建通知
            val notification = NotificationCompat.Builder(context, CHANNEL_ID)
                .setContentTitle(title)
                .setContentText(content)
                .setSmallIcon(R.drawable.ic_notification)
                .setColor(context.resources.getColor(R.color.notification_color, null))
                .setAutoCancel(true)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setDefaults(NotificationCompat.DEFAULT_ALL)
                .setContentIntent(pendingIntent)
                .setStyle(NotificationCompat.BigTextStyle().bigText(content))
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setCategory(NotificationCompat.CATEGORY_MESSAGE)
                .setFullScreenIntent(pendingIntent, false)
                .setOngoing(false)
                .setOnlyAlertOnce(false)
                .build()
            
            // 显示通知
            val notificationId = System.currentTimeMillis().toInt()
            notificationManager.notify(notificationId, notification)
            
            Log.d(TAG, "=== 通知创建成功 ===")
            Log.d(TAG, "通知ID: $notificationId")
            Log.d(TAG, "标题: $title")
            Log.d(TAG, "内容: $content")
            Log.d(TAG, "渠道: $CHANNEL_ID")
            
        } catch (e: Exception) {
            Log.e(TAG, "=== 创建通知失败 ===", e)
            Log.e(TAG, "错误详情: ${e.message}")
            e.printStackTrace()
        }
    }
    
    private fun isAppInForeground(context: Context): Boolean {
        return try {
            val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
            val appProcesses = activityManager.runningAppProcesses ?: return false
            
            appProcesses.any { processInfo ->
                processInfo.processName == context.packageName &&
                processInfo.importance == android.app.ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND
            }
        } catch (e: Exception) {
            Log.e(TAG, "检查应用前台状态失败", e)
            false
        }
    }
}
