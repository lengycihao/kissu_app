package com.yuluo.kissu

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.Log

/**
 * 开机自启动广播接收器
 * 
 * 在设备重启后自动恢复定位服务，确保用户无需手动重启APP
 * 
 * 触发场景：
 * - 系统启动完成（BOOT_COMPLETED）
 * - 应用更新完成（MY_PACKAGE_REPLACED）
 * - 用户解锁屏幕（USER_PRESENT）- 部分厂商需要
 */
class BootCompletedReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "BootCompletedReceiver"
        private const val PREFS_NAME = "kissu_location_prefs"
        private const val KEY_LOCATION_SERVICE_ENABLED = "location_service_enabled"
        
        /**
         * 保存定位服务状态（由 MainActivity 调用）
         * 
         * 在 Flutter 层启动/停止定位时调用此方法，保存状态
         */
        fun saveLocationServiceState(context: Context, enabled: Boolean) {
            try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                prefs.edit().putBoolean(KEY_LOCATION_SERVICE_ENABLED, enabled).apply()
                Log.d(TAG, "定位服务状态已保存: enabled=$enabled")
            } catch (e: Exception) {
                Log.e(TAG, "保存定位服务状态失败", e)
            }
        }
        
        /**
         * 重置首次解锁标志（在开机时重置）
         */
        fun resetFirstUnlockFlag(context: Context) {
            try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                prefs.edit().putBoolean("first_unlock_after_boot", true).apply()
            } catch (e: Exception) {
                Log.e(TAG, "重置首次解锁标志失败", e)
            }
        }
    }
    
    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) {
            Log.w(TAG, "Context 或 Intent 为空，忽略广播")
            return
        }
        
        val action = intent.action ?: return
        Log.d(TAG, "收到系统广播: $action")
        
        when (action) {
            Intent.ACTION_BOOT_COMPLETED -> {
                Log.d(TAG, "设备启动完成，准备恢复定位服务...")
                handleBootCompleted(context)
            }
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                Log.d(TAG, "应用更新完成，准备恢复定位服务...")
                handleBootCompleted(context)
            }
            Intent.ACTION_USER_PRESENT -> {
                Log.d(TAG, "用户解锁屏幕（部分厂商需要此事件）")
                // 仅在首次解锁时触发
                handleUserPresent(context)
            }
        }
    }
    
    /**
     * 处理开机完成事件
     */
    private fun handleBootCompleted(context: Context) {
        try {
            // 检查用户上次是否启用了定位服务
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val wasLocationEnabled = prefs.getBoolean(KEY_LOCATION_SERVICE_ENABLED, false)
            
            if (!wasLocationEnabled) {
                Log.d(TAG, "用户上次未启用定位服务，跳过自动启动")
                return
            }
            
            Log.d(TAG, "用户上次已启用定位服务，准备自动启动...")
            
            // 🔥 启动前台定位服务
            startForegroundLocationService(context)
            
        } catch (e: Exception) {
            Log.e(TAG, "处理开机启动失败", e)
        }
    }
    
    /**
     * 处理用户解锁事件（部分厂商如小米、华为需要）
     */
    private fun handleUserPresent(context: Context) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val isFirstUnlock = prefs.getBoolean("first_unlock_after_boot", true)
            
            if (isFirstUnlock) {
                Log.d(TAG, "首次解锁，尝试启动定位服务（厂商兼容）")
                prefs.edit().putBoolean("first_unlock_after_boot", false).apply()
                handleBootCompleted(context)
            }
        } catch (e: Exception) {
            Log.e(TAG, "处理用户解锁失败", e)
        }
    }
    
    /**
     * 启动前台定位服务
     */
    private fun startForegroundLocationService(context: Context) {
        try {
            val serviceIntent = Intent(context, ForegroundLocationService::class.java).apply {
                action = ForegroundLocationService.ACTION_START_FOREGROUND_SERVICE
                
                // 使用默认通知内容
                putExtra("title", "Kissu定位服务")
                putExtra("content", "正在为您提供位置服务...")
                putExtra("channelId", "kissu_location_service")
                putExtra("notificationId", 1001)
                putExtra("iconName", "ic_launcher")
                putExtra("priority", 2) // PRIORITY_HIGH
                putExtra("ongoing", true)
                putExtra("autoCancel", false)
                putExtra("enableVibration", false)
                putExtra("enableSound", false)
            }
            
            // Android 8.0+ 使用 startForegroundService
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
                Log.d(TAG, "✅ 前台定位服务启动成功（开机自启动）")
            } else {
                context.startService(serviceIntent)
                Log.d(TAG, "✅ 定位服务启动成功（开机自启动）")
            }
            
            // 🔥 同时启动 Flutter Engine（如果需要）
            // 注意：这里不启动完整的 MainActivity，只启动后台服务
            // Flutter 的定位逻辑会通过 MethodChannel 与原生层通信
            
        } catch (e: Exception) {
            Log.e(TAG, "启动前台定位服务失败", e)
        }
    }
}

