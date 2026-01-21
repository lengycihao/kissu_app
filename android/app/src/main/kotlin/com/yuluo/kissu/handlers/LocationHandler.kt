package com.yuluo.kissu.handlers

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.location.LocationManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * 定位和GPS处理器
 * 负责处理GPS状态监听、定位设置等功能
 */
class LocationHandler(private val activity: Activity) {
    
    companion object {
        private const val TAG = "LocationHandler"
    }
    
    // GPS状态事件发送器
    private var gpsStatusEventSink: EventChannel.EventSink? = null
    
    // GPS状态监听器
    private var gpsStatusReceiver: GpsStatusReceiver? = null
    
    /**
     * 初始化定位处理器
     */
    fun initialize(gpsStatusChannel: EventChannel) {
        // 设置GPS状态事件流
        gpsStatusChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                gpsStatusEventSink = events
                registerGpsStatusReceiver()
                
                // 立即发送当前GPS状态（直接发送bool值，不是Map）
                val isEnabled = isGpsEnabled()
                gpsStatusEventSink?.success(isEnabled)
            }
            
            override fun onCancel(arguments: Any?) {
                unregisterGpsStatusReceiver()
                gpsStatusEventSink = null
            }
        })
    }
    
    /**
     * 清理资源
     */
    fun cleanup() {
        unregisterGpsStatusReceiver()
    }
    
    /**
     * 处理定位方法调用
     */
    fun handleMethodCall(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "openLocationSettings" -> {
                openLocationSettings()
                result.success(null)
            }
            "openNotificationSettings" -> {
                openNotificationSettings()
                result.success(null)
            }
            "openBatteryOptimizationSettings" -> {
                openBatteryOptimizationSettings()
                result.success(null)
            }
            "openUsageAccessSettings" -> {
                openUsageAccessSettings()
                result.success(null)
            }
            "openAppSettings" -> {
                openAppSettings()
                result.success(null)
            }
            "openSystemSettings" -> {
                openSystemSettings()
                result.success(null)
            }
            "openWifiSettings" -> {
                openWifiSettings()
                result.success(null)
            }
            "isGpsEnabled" -> {
                result.success(isGpsEnabled())
            }
            else -> {
                result.notImplemented()
            }
        }
    }
    
    /**
     * 打开定位设置页面（跳转到App应用详情页，用户可在此管理定位权限）
     */
    private fun openLocationSettings() {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", activity.packageName, null)
            }
            activity.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "打开定位设置失败", e)
        }
    }
    
    /**
     * 打开通知设置页面
     */
    private fun openNotificationSettings() {
        try {
            val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                    putExtra(Settings.EXTRA_APP_PACKAGE, activity.packageName)
                }
            } else {
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.fromParts("package", activity.packageName, null)
                }
            }
            activity.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "打开通知设置失败", e)
        }
    }
    
    /**
     * 打开电池优化设置页面
     */
    private fun openBatteryOptimizationSettings() {
        try {
            val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
            activity.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "打开电池优化设置失败", e)
        }
    }
    
    /**
     * 打开使用情况访问设置页面
     */
    private fun openUsageAccessSettings() {
        try {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            activity.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "打开使用情况访问设置失败", e)
        }
    }
    
    /**
     * 打开应用设置页面（单个 App 详情）
     */
    private fun openAppSettings() {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", activity.packageName, null)
            }
            activity.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "打开应用设置失败", e)
        }
    }

    /**
     * 打开手机系统设置主页
     */
    private fun openSystemSettings() {
        try {
            val intent = Intent(Settings.ACTION_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            activity.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "打开系统设置失败", e)
        }
    }
    
    /**
     * 打开WiFi设置页面
     */
    private fun openWifiSettings() {
        try {
            val intent = Intent(Settings.ACTION_WIFI_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            activity.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "打开WiFi设置失败", e)
        }
    }
    
    /**
     * 检查GPS是否开启
     */
    private fun isGpsEnabled(): Boolean {
        return try {
            val locationManager = activity.getSystemService(Context.LOCATION_SERVICE) as LocationManager
            locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)
        } catch (e: Exception) {
            Log.e(TAG, "检查GPS状态失败", e)
            false
        }
    }
    
    /**
     * 注册GPS状态监听器
     */
    private fun registerGpsStatusReceiver() {
        if (gpsStatusReceiver == null) {
            gpsStatusReceiver = GpsStatusReceiver()
            val filter = IntentFilter(LocationManager.PROVIDERS_CHANGED_ACTION)
            activity.registerReceiver(gpsStatusReceiver, filter)
            Log.d(TAG, "GPS状态监听器已注册")
        }
    }
    
    /**
     * 注销GPS状态监听器
     */
    private fun unregisterGpsStatusReceiver() {
        gpsStatusReceiver?.let {
            try {
                activity.unregisterReceiver(it)
                gpsStatusReceiver = null
                Log.d(TAG, "GPS状态监听器已注销")
            } catch (e: Exception) {
                Log.e(TAG, "注销GPS状态监听器失败", e)
            }
        }
    }
    
    /**
     * GPS状态广播接收器
     */
    private inner class GpsStatusReceiver : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == LocationManager.PROVIDERS_CHANGED_ACTION) {
                val isEnabled = isGpsEnabled()
                Log.d(TAG, "GPS状态变化: $isEnabled")
                // 直接发送bool值，不是Map（与Dart端期望的类型一致）
                gpsStatusEventSink?.success(isEnabled)
            }
        }
    }
}
