package com.yuluo.kissu

 
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import cn.jpush.android.api.JPushInterface

class JPushService : Service() {
    
    companion object {
        private const val TAG = "JPushService"
        private const val CHANNEL_ID = "kissu_push_service"
        private const val CHANNEL_NAME = "Kissu推送保活"
        private const val NOTIFICATION_ID = 4001
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "JPushService created")
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // 关键：立刻启动为前台服务，避免被系统当作空后台服务清理
        ensureForeground()

        Log.d(TAG, "JPushService started")
        
        // 确保JPush服务在后台运行
        try {
            JPushInterface.resumePush(applicationContext)
            Log.d(TAG, "JPush服务已恢复")
        } catch (e: Exception) {
            Log.e(TAG, "恢复JPush服务失败", e)
        }
        
        // 返回START_STICKY确保服务被系统杀死后能重启
        return START_STICKY
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "JPushService destroyed")
    }

    /**
     * 将服务提升为前台优先级，减少被系统回收的概率
     */
    private fun ensureForeground() {
        try {
            createNotificationChannelIfNeeded()

            // 点击通知回到应用
            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            val pendingIntent = PendingIntent.getActivity(
                this,
                0,
                launchIntent,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
            )

            val notification = NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("Kissu 推送服务")
                .setContentText("保持推送连接中")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setOngoing(true)
                .setAutoCancel(false)
                // 提升优先级，避免被系统降级为后台空进程
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setCategory(NotificationCompat.CATEGORY_SERVICE)
                .setContentIntent(pendingIntent)
                .build()

            startForeground(NOTIFICATION_ID, notification)
        } catch (e: SecurityException) {
            // Android 13+ 通知权限被关时，前台服务可能抛异常，降级为普通服务以避免直接崩溃
            Log.e(TAG, "启动前台推送服务失败（权限问题），降级为普通服务运行", e)
        } catch (e: Exception) {
            Log.e(TAG, "启动前台推送服务失败", e)
        }
    }

    private fun createNotificationChannelIfNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                // 使用默认重要性，避免被系统静默降权
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                setShowBadge(false)
                enableLights(false)
                enableVibration(false)
                setSound(null, null)
                description = "用于保持极光推送连接的前台服务"
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }
}
