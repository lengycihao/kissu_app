package com.yuluo.kissu.wxapi

import android.content.Intent
import android.os.Bundle
import android.util.Log
import com.jarvan.fluwx.handler.FluwxWXEntryActivity
import com.tencent.mm.opensdk.constants.ConstantsAPI
import com.tencent.mm.opensdk.modelbase.BaseReq
import com.tencent.mm.opensdk.modelbase.BaseResp

/**
 * 微信支付回调Activity
 * 继承 fluwx 的基类，自动处理回调
 */
class WXPayEntryActivity : FluwxWXEntryActivity() {
    
    companion object {
        private const val TAG = "WXPayEntryActivity"
    }
    
    // fluwx 会自动处理回调，我们只需要记录日志
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "=== WXPayEntryActivity onCreate (fluwx) ===")
    }
}
