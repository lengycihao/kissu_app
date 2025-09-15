package com.yuluo.kissu

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.util.Log
import cn.jpush.android.api.JPushInterface

class JPushService : Service() {
    
    companion object {
        private const val TAG = "JPushService"
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "JPushService created")
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
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
}
