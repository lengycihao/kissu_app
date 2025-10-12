package com.yuluo.kissu

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.location.LocationManager
import android.util.Log
import io.flutter.plugin.common.EventChannel

/**
 * GPS状态监听器
 * 
 * 监听系统GPS开关状态变化，并通过EventChannel通知Flutter层
 * 
 * 实现原理：
 * 1. 通过BroadcastReceiver监听 PROVIDERS_CHANGED_ACTION 广播
 * 2. 检测GPS Provider的启用状态
 * 3. 通过EventChannel实时推送状态变化到Flutter
 * 
 * 使用场景：
 * - 用户在系统设置中打开/关闭GPS
 * - 需要实时上报GPS状态变化
 * 
 * @author AI Assistant
 * @date 2025-10-11
 */
class GpsStatusReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "GpsStatusReceiver"
        
        /**
         * GPS状态变化监听器（单例）
         */
        var eventSink: EventChannel.EventSink? = null
    }
    
    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) {
            return
        }
        
        // 只处理 PROVIDERS_CHANGED_ACTION 广播
        if (intent.action != LocationManager.PROVIDERS_CHANGED_ACTION) {
            return
        }
        
        Log.d(TAG, "📍 收到GPS状态变化广播")
        
        try {
            // 获取LocationManager
            val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as? LocationManager
            if (locationManager == null) {
                Log.e(TAG, "❌ 无法获取LocationManager")
                return
            }
            
            // 检查GPS Provider是否启用
            val isGpsEnabled = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)
            Log.d(TAG, "🔍 GPS状态: ${if (isGpsEnabled) "开启" else "关闭"}")
            
            // 通过EventChannel通知Flutter层
            eventSink?.let { sink ->
                sink.success(isGpsEnabled)
                Log.d(TAG, "✅ 已通知Flutter: GPS ${if (isGpsEnabled) "开启" else "关闭"}")
            } ?: run {
                Log.w(TAG, "⚠️ EventSink未初始化，无法通知Flutter")
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ 处理GPS状态变化失败: ${e.message}", e)
        }
    }
    
    /**
     * 获取当前GPS状态
     */
    fun getCurrentGpsStatus(context: Context): Boolean {
        return try {
            val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as? LocationManager
            val isEnabled = locationManager?.isProviderEnabled(LocationManager.GPS_PROVIDER) ?: false
            Log.d(TAG, "📍 当前GPS状态: ${if (isEnabled) "开启" else "关闭"}")
            isEnabled
        } catch (e: Exception) {
            Log.e(TAG, "❌ 获取GPS状态失败: ${e.message}", e)
            false
        }
    }
}

