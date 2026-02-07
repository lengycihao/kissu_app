package com.yuluo.kissu

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import android.content.ComponentName
import androidx.core.app.NotificationCompat
import cn.jpush.android.api.JPushInterface
import org.json.JSONObject
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class JPushReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "JPushReceiver"
        private const val NATIVE_LOG_TAG = "NativeJPush"
        private const val CHANNEL_ID = "kissu_push_channel"
        private const val CHANNEL_NAME = "Kissu推送通知"
        
        // ================================
        // 🔥 原生层文件日志功能
        // ================================
        
        private fun writeNativeLog(
            context: Context,
            level: String,
            message: String,
            extra: Map<String, Any?>? = null
        ) {
            try {
                // 使用与 Flutter 层相同的日志目录：filesDir/logs（对应 getApplicationSupportDirectory()/logs）
                val logDir = File(context.filesDir, "logs")
                if (!logDir.exists()) {
                    logDir.mkdirs()
                }
                
                val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH-mm-ss.SSSSSS", Locale.US)
                val todayFormat = SimpleDateFormat("yyyy-MM-dd", Locale.US)
                val today = todayFormat.format(Date())
                
                // 查找今天的日志文件，如果不存在则创建新的
                val existingLogFile = logDir.listFiles()?.find { 
                    it.name.startsWith(today) && it.name.endsWith("_app.log") 
                }
                
                val logFile = existingLogFile ?: File(logDir, "${dateFormat.format(Date())}_app.log")
                
                val isoFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSSSS", Locale.US)
                val timestamp = isoFormat.format(Date())
                
                val logEntry = JSONObject().apply {
                    put("timestamp", timestamp)
                    put("level", level)
                    put("tag", NATIVE_LOG_TAG)
                    put("message", message)
                    extra?.let {
                        val extraJson = JSONObject()
                        it.forEach { (key, value) ->
                            extraJson.put(key, value ?: JSONObject.NULL)
                        }
                        put("extra", extraJson)
                    }
                }
                
                logFile.appendText(logEntry.toString() + "\n")
            } catch (e: Exception) {
                Log.e(TAG, "写入原生日志失败", e)
            }
        }
        
        fun logInfo(context: Context, message: String, extra: Map<String, Any?>? = null) {
            Log.d(TAG, message)
            writeNativeLog(context, "INFO", message, extra)
        }
        
        fun logWarning(context: Context, message: String, extra: Map<String, Any?>? = null) {
            Log.w(TAG, message)
            writeNativeLog(context, "WARNING", message, extra)
        }
        
        fun logError(context: Context, message: String, extra: Map<String, Any?>? = null) {
            Log.e(TAG, message)
            writeNativeLog(context, "ERROR", message, extra)
        }
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        try {
            val bundle = intent.extras
            Log.d(TAG, "onReceive - action: ${intent.action}, extras: $bundle")
            
            when (intent.action) {
                // 兼容老的 *_ACTION 广播写法
                "cn.jpush.android.intent.REGISTRATION" -> {
                    val regId = bundle?.getString(JPushInterface.EXTRA_REGISTRATION_ID)
                    Log.d(TAG, "Registration ID (legacy): $regId")
                }
                "cn.jpush.android.intent.NOTIFICATION_OPENED_ACTION",
                "cn.jpush.android.intent.NOTIFICATION_OPENED",
                "cn.jpush.android.intent.NOTIFICATION_OPENED_PROXY" -> {
                    Log.d(TAG, "用户点击了通知（legacy/opened）")
                    processNotificationOpened(context, bundle)
                }
                "cn.jpush.android.intent.NOTIFICATION_RECEIVED_ACTION",
                "cn.jpush.android.intent.NOTIFICATION_RECEIVED",
                "cn.jpush.android.intent.NOTIFICATION_RECEIVED_PROXY" -> {
                    Log.d(TAG, "收到推送通知（legacy/received）")
                    processNotificationReceived(context, bundle)
                }
                "cn.jpush.android.intent.MESSAGE_RECEIVED_ACTION",
                "cn.jpush.android.intent.MESSAGE_RECEIVED",
                "cn.jpush.android.intent.MESSAGE_RECEIVED_PROXY" -> {
                    Log.d(TAG, "收到推送消息（legacy/message）")
                    processCustomMessage(context, bundle)
                }

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
            logError(context, "处理JPush事件时出错", mapOf("error" to (e.message ?: "unknown")))
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
            
            // 检查是否走厂商通道（更准确的检测方式）
            // 厂商通道的通知通常会有特定的key或者通过其他方式标识
            val channelType = extras.getString("cn.jpush.android.CHANNEL_TYPE", "")
            val vendorId = extras.getString("cn.jpush.android.VENDOR_ID", "")
            val isFromVendor = channelType.isNotEmpty() || vendorId.isNotEmpty() ||
                             extras.keySet().any { it.contains("vendor", ignoreCase = true) || 
                                                   it.contains("xiaomi", ignoreCase = true) ||
                                                   it.contains("oppo", ignoreCase = true) ||
                                                   it.contains("vivo", ignoreCase = true) ||
                                                   it.contains("meizu", ignoreCase = true) }
            
            Log.d(TAG, "=== 收到推送通知 ===")
            Log.d(TAG, "标题: $title")
            Log.d(TAG, "内容: $content")
            Log.d(TAG, "通知ID: $notificationId")
            Log.d(TAG, "应用状态: ${if (isAppInForeground) "前台" else "后台"}")
            Log.d(TAG, "通道类型: $channelType")
            Log.d(TAG, "厂商ID: $vendorId")
            Log.d(TAG, "是否厂商通道: $isFromVendor")
            Log.d(TAG, "附加数据: $extrasStr")
            Log.d(TAG, "Bundle所有Key: ${extras.keySet().joinToString()}")
            
            // 🔥 关键修复：在后台时总是创建通知作为兜底
            // 即使走厂商通道，也创建通知确保用户能看到（厂商通道可能因为权限等问题未生效）
            // 如果厂商通道生效，可能会有两个通知，但总比没有通知好
            if (!isAppInForeground) {
                Log.d(TAG, "应用在后台，创建自定义通知以确保用户能看到")
                if (isFromVendor) {
                    Log.d(TAG, "注意：检测到可能是厂商通道，但仍创建通知作为兜底")
                }
                createCustomNotification(context, title, content, extrasStr)
            } else {
                Log.d(TAG, "应用在前台，极光推送会自动处理通知")
                // 前台时不需要创建通知，极光推送会自动处理
            }
        }
    }
    
    private fun processNotificationOpened(context: Context, bundle: android.os.Bundle?) {
        Log.d(TAG, "=== processNotificationOpened: 尝试拉起应用界面 ===")
        Log.d(TAG, "包名: ${context.packageName}")
        Log.d(TAG, "Bundle: $bundle")

        try {
            // 获取附加数据
            val extrasStr = bundle?.getString(JPushInterface.EXTRA_EXTRA, "{}") ?: "{}"
            
            // 🔥 关键修复：使用 activity-alias (MainActivityDefault) 来启动
            // 因为 MainActivity 本身没有 MAIN/LAUNCHER intent-filter
            val component = ComponentName(context.packageName, "com.yuluo.kissu.MainActivityDefault")
            
            // 直接使用普通Intent，确保能够冷启动
            // makeRestartActivityTask 在某些情况下可能无法冷启动
            val targetIntent = Intent().apply {
                setComponent(component)
                action = Intent.ACTION_MAIN
                addCategory(Intent.CATEGORY_LAUNCHER)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED
                putExtra("jpush_extras", extrasStr)
            }

            try {
                context.startActivity(targetIntent)
                Log.d(TAG, "processNotificationOpened: startActivity 已调用（使用MainActivityDefault）")
            } catch (e: Exception) {
                Log.e(TAG, "启动MainActivityDefault失败，尝试使用MainActivity", e)
                // 兜底方案：如果 activity-alias 失败，尝试直接启动 MainActivity
                val fallbackComponent = ComponentName(context.packageName, "com.yuluo.kissu.MainActivity")
                val fallbackIntent = Intent().apply {
                    setComponent(fallbackComponent)
                    action = Intent.ACTION_MAIN
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                            Intent.FLAG_ACTIVITY_CLEAR_TOP or
                            Intent.FLAG_ACTIVITY_SINGLE_TOP
                    putExtra("jpush_extras", extrasStr)
                }
                try {
                    context.startActivity(fallbackIntent)
                    Log.d(TAG, "processNotificationOpened: 使用MainActivity启动成功")
                } catch (e2: Exception) {
                    Log.e(TAG, "processNotificationOpened: 所有启动方式都失败", e2)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "processNotificationOpened: 启动Activity失败", e)
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
            
            // 创建点击意图 - 修复冷启动问题
            // 🔥 关键修复：使用 activity-alias 来启动，因为 MainActivity 本身没有 MAIN/LAUNCHER
            // 使用 MainActivityDefault (activity-alias) 确保能够冷启动
            val component = ComponentName(context.packageName, "com.yuluo.kissu.MainActivityDefault")
            val intent = Intent().apply {
                setComponent(component)
                action = Intent.ACTION_MAIN
                addCategory(Intent.CATEGORY_LAUNCHER)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED
                putExtra("jpush_extras", extrasStr)
            }
            
            // 使用FLAG_IMMUTABLE确保在Android 12+正常工作
            // 使用固定ID确保每次都能更新同一个PendingIntent
            val pendingIntentRequestCode = 1001
            val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            
            val pendingIntent = PendingIntent.getActivity(
                context,
                pendingIntentRequestCode,
                intent,
                pendingIntentFlags
            )
            
            Log.d(TAG, "PendingIntent创建成功 - Component: ${intent.component}, Flags: ${intent.flags}")
            
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
            logError(context, "创建通知失败", mapOf("error" to (e.message ?: "unknown")))
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
            logError(context, "检查应用前台状态失败", mapOf("error" to (e.message ?: "unknown")))
            false
        }
    }
}
