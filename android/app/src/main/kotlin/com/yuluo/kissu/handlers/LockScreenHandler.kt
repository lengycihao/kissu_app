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
                    val lockText = call.argument<String>("lockText") ?: ""
                    val bgImagePath = call.argument<String>("bgImagePath") ?: ""
                    lockScreen(minutes, lockText, bgImagePath)
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
            "ensureLockServiceRunning" -> {
                ensureLockServiceRunning()
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

    private var pendingLockText: String = ""
    private var pendingBgImagePath: String = ""

    private fun lockScreen(minutes: Int, lockText: String = "", bgImagePath: String = "") {
        val prefs = activity.getSharedPreferences(LockScreenOverlayService.PREFS_NAME, Context.MODE_PRIVATE)
        val endTime = System.currentTimeMillis() + minutes * 60 * 1000L

        val lockInfo = JSONObject().apply {
            put("endTime", endTime)
            put("minutes", minutes)
        }

        prefs.edit().putString(LockScreenOverlayService.KEY_SCREEN_LOCK, lockInfo.toString()).apply()
        pendingLockText = lockText
        pendingBgImagePath = bgImagePath
        startLockService()
        Log.d(TAG, "锁屏已启动: ${minutes}分钟, endTime=$endTime, lockText=$lockText, bgImagePath=$bgImagePath")
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
        // 传递lockText和bgImagePath通过Intent extras，避免SharedPreferences缓存问题
        if (pendingLockText.isNotEmpty()) {
            intent.putExtra("lock_text", pendingLockText)
        }
        if (pendingBgImagePath.isNotEmpty()) {
            intent.putExtra("bg_image_path", pendingBgImagePath)
        }
        Log.d(TAG, "启动锁屏服务: lockText=${pendingLockText}, bgImagePath=${pendingBgImagePath}")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            activity.startForegroundService(intent)
        } else {
            activity.startService(intent)
        }
        pendingLockText = ""
        pendingBgImagePath = ""
    }

    private fun stopLockService() {
        val intent = Intent(activity, LockScreenOverlayService::class.java).apply {
            action = "STOP_SERVICE"
        }
        activity.startService(intent)
    }

    /**
     * 🔥 确保锁屏服务正在运行（app打开时调用，重启后快速恢复锁屏）
     */
    private fun ensureLockServiceRunning() {
        val prefs = activity.getSharedPreferences(LockScreenOverlayService.PREFS_NAME, Context.MODE_PRIVATE)
        val screenLockJson = prefs.getString(LockScreenOverlayService.KEY_SCREEN_LOCK, null)
        
        if (screenLockJson.isNullOrEmpty()) return
        
        try {
            val obj = JSONObject(screenLockJson)
            val endTime = obj.optLong("endTime", 0)
            if (System.currentTimeMillis() >= endTime) {
                // 已过期，清除
                prefs.edit().remove(LockScreenOverlayService.KEY_SCREEN_LOCK).apply()
                return
            }
            
            if (!Settings.canDrawOverlays(activity)) {
                Log.w(TAG, "🔒 缺少悬浮窗权限，无法恢复锁屏")
                return
            }
            
            Log.d(TAG, "🔒 确保锁屏服务运行中，剩余: ${(endTime - System.currentTimeMillis()) / 1000}秒")
            startLockService()
        } catch (e: Exception) {
            Log.e(TAG, "🔒 检查锁屏服务失败", e)
        }
    }
}
