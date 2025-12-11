package com.yuluo.kissu.handlers

import android.app.Activity
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.content.pm.PackageManager
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import com.yuluo.kissu.BootCompletedReceiver
import com.yuluo.kissu.ForegroundLocationService
import com.yuluo.kissu.LocationReportService
import com.yuluo.kissu.AppUsageReportService
import io.flutter.plugin.common.MethodChannel

/**
 * 前台服务处理器
 * 负责处理前台定位服务的启动和停止
 */
class ForegroundServiceHandler(private val activity: Activity) {
    
    companion object {
        private const val TAG = "ForegroundServiceHandler"
    }
    
    /**
     * 处理前台服务方法调用
     */
    fun handleMethodCall(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startForegroundService" -> {
                val config = call.arguments as? Map<String, Any> ?: mapOf()
                val success = ForegroundLocationService.startService(activity, config)
                
                // 🔥 保存定位服务状态，用于开机自启动
                if (success) {
                    BootCompletedReceiver.saveLocationServiceState(activity, true)
                    BootCompletedReceiver.resetFirstUnlockFlag(activity)
                    Log.d(TAG, "定位服务已启动，状态已保存用于开机自启动")
                }
                
                result.success(success)
            }
            "saveUserToken" -> {
                // 🔥 保存用户 Token 和 API 配置（供 Native 定位上报使用）
                Log.d(TAG, "📥 收到 saveUserToken 请求")
                
                val token = call.argument<String>("token") ?: ""
                val userId = call.argument<String>("userId") ?: ""
                val baseUrl = call.argument<String>("baseUrl") ?: "https://service-api.ikissu.cn"
                
                Log.d(TAG, "📝 Token参数: token=${token.take(20)}..., userId=$userId, baseUrl=$baseUrl")
                
                if (token.isEmpty()) {
                    Log.w(TAG, "❌ Token为空，无法保存")
                    result.success(mapOf("success" to false, "message" to "token is empty"))
                    return
                }
                
                try {
                    // 保存到定位上报服务
                    val locationReportService = LocationReportService(activity)
                    locationReportService.saveUserToken(token, userId)
                    locationReportService.saveBaseUrl(baseUrl)
                    
                    // 保存到App使用记录上报服务
                    val appUsageReportService = AppUsageReportService(activity)
                    appUsageReportService.saveUserToken(token, userId)
                    appUsageReportService.saveBaseUrl(baseUrl)
                    
                    Log.d(TAG, "✅ 用户Token和API配置已保存: userId=$userId, baseUrl=$baseUrl")
                    result.success(mapOf("success" to true, "message" to "Token saved successfully"))
                } catch (e: Exception) {
                    Log.e(TAG, "❌ 保存Token失败", e)
                    result.success(mapOf("success" to false, "message" to e.message))
                }
            }
            "clearUserToken" -> {
                // 🔥 清除用户 Token（登出时调用）
                try {
                    // 清除定位上报服务的用户信息
                    val locationReportService = LocationReportService(activity)
                    locationReportService.clearUserInfo()
                    
                    // 清除App使用记录上报服务的用户信息
                    val appUsageReportService = AppUsageReportService(activity)
                    appUsageReportService.clearUserInfo()
                    
                    Log.d(TAG, "用户Token已清除")
                    result.success(mapOf("success" to true, "message" to "Token cleared successfully"))
                } catch (e: Exception) {
                    Log.e(TAG, "清除Token失败", e)
                    result.success(mapOf("success" to false, "message" to e.message))
                }
            }
            "stopForegroundService" -> {
                val success = ForegroundLocationService.stopService(activity)
                
                // 🔥 保存定位服务状态（已停止）
                if (success) {
                    BootCompletedReceiver.saveLocationServiceState(activity, false)
                    Log.d(TAG, "定位服务已停止，开机将不会自动启动")
                }
                
                result.success(success)
            }
            "isServiceRunning" -> {
                val isRunning = ForegroundLocationService.isRunning()
                result.success(isRunning)
            }
            "updateNotification" -> {
                val config = call.arguments as? Map<String, Any> ?: mapOf()
                // 发送更新通知的Intent
                val intent = Intent(activity, ForegroundLocationService::class.java).apply {
                    action = ForegroundLocationService.ACTION_UPDATE_NOTIFICATION
                    config.forEach { (key, value) ->
                        when (value) {
                            is String -> putExtra(key, value)
                            is Int -> putExtra(key, value)
                            is Long -> putExtra(key, value)
                            is Boolean -> putExtra(key, value)
                        }
                    }
                }
                activity.startService(intent)
                result.success(true)
            }
            "checkNotificationPermission" -> {
                // 🔥 检查通知权限
                val notificationManager = activity.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                var isEnabled = true
                var message = "通知权限正常"
                
                // Android 13+ 需要运行时通知权限
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    if (activity.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) 
                        != PackageManager.PERMISSION_GRANTED) {
                        isEnabled = false
                        message = "需要 POST_NOTIFICATIONS 权限 (Android 13+)"
                    }
                }
                
                // 检查通知是否被用户关闭
                if (isEnabled && !notificationManager.areNotificationsEnabled()) {
                    isEnabled = false
                    message = "通知已被用户关闭"
                }
                
                result.success(mapOf(
                    "isEnabled" to isEnabled,
                    "message" to message
                ))
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    /**
     * 引导用户将应用加入电池优化白名单，避免 Doze 杀死前台服务
     * 每24小时最多提示一次
     */
    private fun maybeRequestBatteryOptimizationWhitelist() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return
        }

        val powerManager = activity.getSystemService(Context.POWER_SERVICE) as? PowerManager ?: return
        if (powerManager.isIgnoringBatteryOptimizations(activity.packageName)) {
            Log.d(TAG, "电池优化白名单已授权，跳过提示")
            return
        }

        val prefs = activity.getSharedPreferences("kissu_location_prefs", Context.MODE_PRIVATE)
        val lastPromptTime = prefs.getLong("battery_opt_prompt_time", 0L)
        val now = System.currentTimeMillis()
        val oneDayMillis = 24 * 60 * 60 * 1000L

        if (now - lastPromptTime < oneDayMillis) {
            Log.d(TAG, "24小时内已提示过电池优化，跳过")
            return
        }

        prefs.edit().putLong("battery_opt_prompt_time", now).apply()

        try {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:${activity.packageName}")
            }
            activity.startActivity(intent)
            Log.d(TAG, "已请求忽略电池优化授权")
        } catch (e: Exception) {
            Log.e(TAG, "请求忽略电池优化授权失败", e)
        }
    }
}
