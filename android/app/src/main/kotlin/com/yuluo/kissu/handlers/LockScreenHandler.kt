package com.yuluo.kissu.handlers

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import com.yuluo.kissu.LockScreenOverlayService
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

/**
 * 锁机功能处理器
 * 负责处理悬浮窗权限检查、锁屏启动/解锁等功能
 */
class LockScreenHandler(private val activity: Activity) {

    companion object {
        private const val TAG = "LockScreenHandler"
        private const val OVERLAY_PERMISSION_REQUEST = 3001
    }

    private var pendingResult: MethodChannel.Result? = null

    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkOverlayPermission" -> {
                result.success(Settings.canDrawOverlays(activity))
            }
            "requestOverlayPermission" -> {
                pendingResult = result
                requestOverlayPermission()
            }
            "lockScreen" -> {
                val minutes = call.argument<Int>("minutes")
                if (minutes != null) {
                    lockScreen(minutes)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGS", "缺少minutes参数", null)
                }
            }
            "unlockScreen" -> {
                unlockScreen()
                result.success(true)
            }
            "getScreenLock" -> {
                result.success(getScreenLock())
            }
            "stopService" -> {
                stopLockService()
                result.success(true)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == OVERLAY_PERMISSION_REQUEST) {
            pendingResult?.success(Settings.canDrawOverlays(activity))
            pendingResult = null
            return true
        }
        return false
    }

    private fun requestOverlayPermission() {
        val intent = Intent(
            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
            Uri.parse("package:${activity.packageName}")
        )
        activity.startActivityForResult(intent, OVERLAY_PERMISSION_REQUEST)
    }

    private fun lockScreen(minutes: Int) {
        val prefs = activity.getSharedPreferences(LockScreenOverlayService.PREFS_NAME, Context.MODE_PRIVATE)
        val endTime = System.currentTimeMillis() + minutes * 60 * 1000L

        val lockInfo = JSONObject().apply {
            put("endTime", endTime)
            put("minutes", minutes)
        }

        prefs.edit().putString(LockScreenOverlayService.KEY_SCREEN_LOCK, lockInfo.toString()).apply()
        startLockService()
        Log.d(TAG, "锁屏已启动: ${minutes}分钟, endTime=$endTime")
    }

    private fun unlockScreen() {
        val prefs = activity.getSharedPreferences(LockScreenOverlayService.PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().remove(LockScreenOverlayService.KEY_SCREEN_LOCK).apply()
        Log.d(TAG, "锁屏已解除")
    }

    private fun getScreenLock(): String {
        val prefs = activity.getSharedPreferences(LockScreenOverlayService.PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString(LockScreenOverlayService.KEY_SCREEN_LOCK, "") ?: ""
    }

    private fun startLockService() {
        val intent = Intent(activity, LockScreenOverlayService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            activity.startForegroundService(intent)
        } else {
            activity.startService(intent)
        }
    }

    private fun stopLockService() {
        val intent = Intent(activity, LockScreenOverlayService::class.java).apply {
            action = "STOP_SERVICE"
        }
        activity.startService(intent)
    }
}
