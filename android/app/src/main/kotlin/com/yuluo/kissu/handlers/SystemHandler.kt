package com.yuluo.kissu.handlers

import android.app.Activity
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
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
                registerScreenLockReceiver()
            }
            
            override fun onCancel(arguments: Any?) {
                unregisterScreenLockReceiver()
                // 清理原生增强版 ScreenLockReceiver 的 EventSink
                NativeScreenLockReceiver.setEventSink(null)
                screenLockEventSink = null
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
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    activity.registerReceiver(screenLockReceiver, filter, Activity.RECEIVER_NOT_EXPORTED)
                } else {
                    activity.registerReceiver(screenLockReceiver, filter)
                }
                Log.d(TAG, "屏幕锁定监听器已注册（增强版）")
            } catch (e: Exception) {
                Log.e(TAG, "注册屏幕锁定监听器失败", e)
            }
        }
    }
    
    /**
     * 注销屏幕锁定监听器
     */
    private fun unregisterScreenLockReceiver() {
        screenLockReceiver?.let {
            try {
                activity.unregisterReceiver(it)
                screenLockReceiver = null
                Log.d(TAG, "屏幕锁定监听器已注销")
            } catch (e: Exception) {
                Log.e(TAG, "注销屏幕锁定监听器失败", e)
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
