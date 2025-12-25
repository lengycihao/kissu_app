package com.yuluo.kissu

import android.app.Application
import android.util.Log
import com.umeng.commonsdk.UMConfigure

class KissuApplication : Application() {
    companion object {
        private const val TAG = "KissuApplication"
    }

    override fun onCreate() {
        super.onCreate()

        try {
            // 在 Application.onCreate 中初始化友盟，确保原生层在任何分享/支付调用前已就绪
            UMConfigure.init(
                applicationContext,
                "6879fba679267e0210b67bde",
                "Umeng",
                UMConfigure.DEVICE_TYPE_PHONE,
                null
            )
            UMConfigure.setLogEnabled(true)
            Log.d(TAG, "友盟 SDK 已在 Application.onCreate 中初始化")
        } catch (e: Exception) {
            Log.e(TAG, "初始化友盟 SDK 失败", e)
        }
    }
}


