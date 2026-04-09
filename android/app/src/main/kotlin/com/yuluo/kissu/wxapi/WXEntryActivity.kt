package com.yuluo.kissu.wxapi

import android.content.Intent
import android.os.Bundle
import android.util.Log
import com.umeng.socialize.weixin.view.WXCallbackActivity

/**
 * 友盟微信分享/登录回调Activity
 * 
 * 重要：这个Activity必须继承自友盟的WXCallbackActivity
 * 父类会自动处理微信的回调并通知到UMShareListener
 * 
 * 注意：不要在这里手动调用UMShareAPI.onActivityResult()，
 * 父类WXCallbackActivity已经处理了回调逻辑
 */
class WXEntryActivity : WXCallbackActivity() {
    
    companion object {
        private const val TAG = "WXEntryActivity"
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        Log.d(TAG, "WXEntryActivity onCreate - 微信分享回调")
        Log.d(TAG, "Intent data: ${intent?.data}")
        Log.d(TAG, "Intent action: ${intent?.action}")
        Log.d(TAG, "Intent extras: ${intent?.extras}")
        
        // 必须调用super.onCreate()，父类会处理微信回调
        super.onCreate(savedInstanceState)
        
        Log.d(TAG, "WXEntryActivity onCreate 完成，父类已处理回调")
    }
    
    override fun onNewIntent(intent: Intent?) {
        Log.d(TAG, "WXEntryActivity onNewIntent - 新的微信分享回调")
        setIntent(intent)
        
        // 必须调用super.onNewIntent()，父类会处理微信回调
        super.onNewIntent(intent)
        
        Log.d(TAG, "WXEntryActivity onNewIntent 完成")
    }
}