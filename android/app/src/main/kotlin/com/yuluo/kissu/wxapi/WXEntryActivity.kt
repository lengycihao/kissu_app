package com.yuluo.kissu.wxapi

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.util.Log
import com.umeng.socialize.weixin.view.WXCallbackActivity

/**
 * 友盟微信分享/登录回调Activity
 * 这个Activity继承自友盟的WXCallbackActivity，用于处理微信分享和登录的回调
 */
class WXEntryActivity : WXCallbackActivity() {
    
    companion object {
        private const val TAG = "WXEntryActivity"
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "WXEntryActivity onCreate")
    }
    
    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        Log.d(TAG, "WXEntryActivity onNewIntent")
        setIntent(intent)
    }
}