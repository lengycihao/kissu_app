package com.yuluo.kissu

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class LockServiceRestartReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == LockScreenOverlayService.RESTART_INTENT) {
            val prefs = context.getSharedPreferences(LockScreenOverlayService.PREFS_NAME, Context.MODE_PRIVATE)
            val screenLock = prefs.getString(LockScreenOverlayService.KEY_SCREEN_LOCK, null)

            if (screenLock != null) {
                val serviceIntent = Intent(context, LockScreenOverlayService::class.java)
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        context.startForegroundService(serviceIntent)
                    } else {
                        context.startService(serviceIntent)
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
    }
}
