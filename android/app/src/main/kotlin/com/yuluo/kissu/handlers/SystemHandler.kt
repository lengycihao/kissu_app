package com.yuluo.kissu.handlers

import android.app.Activity
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.provider.Settings
import android.util.Log
import com.yuluo.kissu.DeviceWhitelistHelper
import com.yuluo.kissu.ScreenLockReceiver as NativeScreenLockReceiver
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest
import java.security.NoSuchAlgorithmException

/**
 * 系统功能处理器
 * 负责处理屏幕锁定监听、设备白名单、SHA1签名等系统功能
 */
class SystemHandler(private val activity: Activity) {
    
    companion object {
        private const val TAG = "SystemHandler"
    }
    
    // 屏幕锁定事件发送器
    private var screenLockEventSink: EventChannel.EventSink? = null
    
    // 屏幕锁定监听器（使用原生增强版 ScreenLockReceiver）
    private var screenLockReceiver: NativeScreenLockReceiver? = null
    
    // 是否已注册 Receiver
    private var isReceiverRegistered = false
    
    /**
     * 初始化系统处理器
     */
    fun initialize(screenLockChannel: EventChannel) {
        // 设置屏幕锁定事件流
        screenLockChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                screenLockEventSink = events
                // 将 EventSink 传递给原生增强版 ScreenLockReceiver
                NativeScreenLockReceiver.setEventSink(events)
                // 复用已注册的 Receiver，避免重复注册
                if (!isReceiverRegistered) {
                    registerScreenLockReceiver()
                } else {
                    Log.d(TAG, "Receiver 已注册，复用现有实例，仅更新 EventSink")
                }
            }
            
            override fun onCancel(arguments: Any?) {
                // ✅ 不注销 Receiver，仅清空 EventSink
                // Receiver 继续在后台跟踪锁屏状态，下次 onListen 时恢复上报
                NativeScreenLockReceiver.setEventSink(null)
                screenLockEventSink = null
                Log.d(TAG, "EventSink 已清空，Receiver 保持活跃")
            }
        })
        
        // 打印SHA1签名
        printSHA1()
    }
    
    /**
     * 清理资源
     */
    fun cleanup() {
        unregisterScreenLockReceiver()
    }
    
    /**
     * 处理白名单方法调用
     */
    fun handleWhitelistCall(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getManufacturer" -> {
                result.success(DeviceWhitelistHelper.getManufacturerName())
            }
            "needsWhitelistGuidance" -> {
                result.success(DeviceWhitelistHelper.needsWhitelistGuidance())
            }
            "getGuidanceText" -> {
                result.success(DeviceWhitelistHelper.getGuidanceText())
            }
            "getShortGuidance" -> {
                result.success(DeviceWhitelistHelper.getShortGuidance())
            }
            "openWhitelistSettings" -> {
                val success = DeviceWhitelistHelper.openWhitelistSettings(activity)
                result.success(success)
            }
            "initBDConvert" -> {
                try {
                    com.bytedance.ads.convert.BDConvert.init(activity.applicationContext, activity)
                    Log.d(TAG, "✅ 巨量引擎SDK初始化成功（Flutter触发）")
                    result.success(true)
                } catch (e: Exception) {
                    Log.e(TAG, "❌ 巨量引擎SDK初始化失败", e)
                    result.success(false)
                }
            }
            "getAndroidId" -> {
                try {
                    // 隐私合规检查：仅在用户同意隐私政策后才返回
                    val prefs = activity.getSharedPreferences("FlutterSharedPreferences", android.content.Context.MODE_PRIVATE)
                    val agreed = prefs.getBoolean("flutter.privacy_policy_agreed", false)
                    if (!agreed) {
                        result.success(null)
                        return
                    }
                    val androidId = Settings.Secure.getString(
                        activity.contentResolver,
                        Settings.Secure.ANDROID_ID
                    )
                    result.success(androidId)
                } catch (e: Exception) {
                    Log.e(TAG, "获取Android ID失败", e)
                    result.success(null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }
    
    /**
     * 注册屏幕锁定监听器
     */
    private fun registerScreenLockReceiver() {
        if (screenLockReceiver == null) {
            screenLockReceiver = NativeScreenLockReceiver()
        }
        if (isReceiverRegistered) {
            Log.d(TAG, "Receiver 已注册，跳过")
            return
        }

        val filter = IntentFilter().apply {
            // 锁屏 / 亮屏 / 解锁相关广播
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_USER_PRESENT)
            // Android 7.0+：包含设备启动后首次解锁等场景
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                addAction(Intent.ACTION_USER_UNLOCKED)
            }
        }

        try {
            // ✅ 使用 applicationContext 注册，脱离 Activity 生命周期
            val appContext = activity.applicationContext
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                // ✅ 系统广播使用 RECEIVER_EXPORTED，确保能收到
                appContext.registerReceiver(screenLockReceiver, filter, Activity.RECEIVER_EXPORTED)
            } else {
                appContext.registerReceiver(screenLockReceiver, filter)
            }
            isReceiverRegistered = true
            Log.d(TAG, "屏幕锁定监听器已注册（applicationContext + 增强版）")
        } catch (e: Exception) {
            Log.e(TAG, "注册屏幕锁定监听器失败", e)
            isReceiverRegistered = false
        }
    }
    
    /**
     * 注销屏幕锁定监听器
     */
    private fun unregisterScreenLockReceiver() {
        screenLockReceiver?.let {
            try {
                // ✅ 使用 applicationContext 注销（和注册时保持一致）
                activity.applicationContext.unregisterReceiver(it)
                screenLockReceiver = null
                isReceiverRegistered = false
                Log.d(TAG, "屏幕锁定监听器已注销")
            } catch (e: Exception) {
                Log.e(TAG, "注销屏幕锁定监听器失败", e)
                isReceiverRegistered = false
            }
        }
    }
    
    /**
     * 打印应用SHA1签名
     */
    private fun printSHA1() {
        try {
            val packageInfo = activity.packageManager.getPackageInfo(
                activity.packageName,
                android.content.pm.PackageManager.GET_SIGNATURES
            )
            for (signature in packageInfo.signatures ?: emptyArray()) {
                val md = MessageDigest.getInstance("SHA1")
                md.update(signature.toByteArray())
                val sha1 = md.digest().joinToString(":") { "%02X".format(it) }
                Log.d(TAG, "应用SHA1签名: $sha1")
            }
        } catch (e: NoSuchAlgorithmException) {
            Log.e(TAG, "无法获取SHA1", e)
        } catch (e: Exception) {
            Log.e(TAG, "获取签名失败", e)
        }
    }
}
