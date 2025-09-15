package com.yuluo.kissu.wxapi

import android.content.Intent
import android.os.Bundle
import android.util.Log
import com.umeng.socialize.weixin.view.WXCallbackActivity

/**
 * 友盟微信分享回调Activity
 * 专门用于处理友盟微信分享的回调
 */
class UMWXEntryActivity : WXCallbackActivity() {
    
    companion object {
        private const val TAG = "UMWXEntryActivity"
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "UMWXEntryActivity onCreate")
    }
    
    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        Log.d(TAG, "UMWXEntryActivity onNewIntent")
        setIntent(intent)
    }
}
