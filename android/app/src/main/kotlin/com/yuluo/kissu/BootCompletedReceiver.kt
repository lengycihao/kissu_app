package com.yuluo.kissu

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import com.yuluo.kissu.widget.KissuWidgetDaysProvider
import com.yuluo.kissu.widget.KissuWidgetProvider
import com.yuluo.kissu.widget.WidgetUpdateWorker
import io.flutter.Log
import org.json.JSONObject

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
                ensureWidgetPeriodicWorkIfNeeded(context)
                handleBootCompleted(context)
            }
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                Log.d(TAG, "应用更新完成，准备恢复定位服务...")
                ensureWidgetPeriodicWorkIfNeeded(context)
                handleBootCompleted(context)
            }
            Intent.ACTION_USER_PRESENT -> {
                Log.d(TAG, "用户解锁屏幕（部分厂商需要此事件）")
                // 仅在首次解锁时触发
                ensureWidgetPeriodicWorkIfNeeded(context)
                handleUserPresent(context)
            }
        }
    }

    private fun ensureWidgetPeriodicWorkIfNeeded(context: Context) {
        try {
            val manager = AppWidgetManager.getInstance(context)
            val largeIds = manager.getAppWidgetIds(ComponentName(context, KissuWidgetProvider::class.java))
            val daysIds = manager.getAppWidgetIds(ComponentName(context, KissuWidgetDaysProvider::class.java))
            if (largeIds.isNotEmpty() || daysIds.isNotEmpty()) {
                WidgetUpdateWorker.enqueuePeriodicWork(context)
                Log.d(TAG, "✅ 检测到桌面小组件，已恢复周期刷新任务")
            } else {
                Log.d(TAG, "ℹ️ 未检测到桌面小组件，跳过周期刷新任务恢复")
            }
        } catch (e: Exception) {
            Log.e(TAG, "恢复小组件周期任务失败", e)
        }
    }
    
    /**
     * 处理开机完成事件
     */
    private fun handleBootCompleted(context: Context, triggeredByUserUnlock: Boolean = false) {
        try {
            Log.d(TAG, "🔍 开始处理开机完成事件...")
            
            if (!triggeredByUserUnlock) {
                resetFirstUnlockFlag(context)
            }
            
            // 检查用户上次是否启用了定位服务
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val wasLocationEnabled = prefs.getBoolean(KEY_LOCATION_SERVICE_ENABLED, false)
            
            Log.d(TAG, "📊 定位服务状态检查: wasLocationEnabled=$wasLocationEnabled")
            
            if (!wasLocationEnabled) {
                Log.d(TAG, "ℹ️ 用户上次未启用定位服务，跳过自动启动")
                return
            }
            
            Log.d(TAG, "✅ 用户上次已启用定位服务，准备自动启动...")
            
            // 🔥 启动前台定位服务
            startForegroundLocationService(context)
            
            // 🔥 检查是否有未过期的锁屏，立即恢复锁屏
            checkAndRestoreLockScreen(context)
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ 处理开机启动失败", e)
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
                handleBootCompleted(context, triggeredByUserUnlock = true)
            }
        } catch (e: Exception) {
            Log.e(TAG, "处理用户解锁失败", e)
        }
    }
    
    /**
     * 🔥 检查是否有未过期的锁屏，立即恢复锁屏服务
     * 防止被锁方通过重启手机逃避锁定
     */
    private fun checkAndRestoreLockScreen(context: Context) {
        try {
            val lockPrefs = context.getSharedPreferences(
                LockScreenOverlayService.PREFS_NAME, Context.MODE_PRIVATE
            )
            val screenLockJson = lockPrefs.getString(LockScreenOverlayService.KEY_SCREEN_LOCK, null)
            
            if (screenLockJson.isNullOrEmpty()) {
                Log.d(TAG, "🔒 没有锁屏数据，跳过锁屏恢复")
                return
            }
            
            val obj = JSONObject(screenLockJson)
            val endTime = obj.optLong("endTime", 0)
            val currentTime = System.currentTimeMillis()
            
            if (currentTime >= endTime) {
                Log.d(TAG, "🔒 锁屏已过期，清除锁屏数据")
                lockPrefs.edit().remove(LockScreenOverlayService.KEY_SCREEN_LOCK).apply()
                return
            }
            
            // 检查悬浮窗权限
            if (!Settings.canDrawOverlays(context)) {
                Log.w(TAG, "🔒 缺少悬浮窗权限，无法恢复锁屏")
                return
            }
            
            Log.d(TAG, "🔒 发现未过期的锁屏，立即恢复！剩余: ${(endTime - currentTime) / 1000}秒")
            
            // 立即启动锁屏服务
            val serviceIntent = Intent(context, LockScreenOverlayService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
            
            Log.d(TAG, "🔒 锁屏服务已在开机后快速恢复")
        } catch (e: Exception) {
            Log.e(TAG, "🔒 检查锁屏恢复失败", e)
        }
    }
    
    /**
     * 启动前台定位服务
     * 🔥 修复：检查隐私政策是否已同意，避免在用户未同意时获取位置信息和 ANDROID ID
     */
    private fun startForegroundLocationService(context: Context) {
        try {
            // 🔥 关键修复：检查隐私政策是否已同意（从 SharedPreferences 读取 Flutter 保存的状态）
            val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val privacyAgreed = flutterPrefs.getBoolean("flutter.privacy_policy_agreed", false)
            
            if (!privacyAgreed) {
                Log.w(TAG, "⚠️ 用户未同意隐私政策，跳过开机自启动定位服务（隐私合规）")
                return
            }
            
            // 🔥 检查用户 Token 是否存在（用于定位上报）
            val prefs = context.getSharedPreferences("kissu_preferences", Context.MODE_PRIVATE)
            val token = prefs.getString("user_token", null)
            val userId = prefs.getString("user_id", null)
            
            if (token.isNullOrEmpty()) {
                Log.w(TAG, "⚠️ 用户Token不存在，定位服务将启动但无法上报数据（用户需要重新登录）")
            } else {
                Log.d(TAG, "✅ 用户Token存在: userId=$userId, token=${token.take(20)}...")
            }
            
            val serviceIntent = Intent(context, ForegroundLocationService::class.java).apply {
                action = ForegroundLocationService.ACTION_START_FOREGROUND_SERVICE
                
                // 使用默认通知内容
                putExtra("title", "Kissu")
                putExtra("content", "请不要关掉Kissu后台进程\n当前正在为对方共享您的信息，请勿关闭")
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
            Log.e(TAG, "❌ 启动前台定位服务失败", e)
        }
    }
}

