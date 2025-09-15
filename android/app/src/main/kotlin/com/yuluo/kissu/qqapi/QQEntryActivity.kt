package com.yuluo.kissu.qqapi

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.util.Log
import com.umeng.socialize.UMShareAPI

/**
 * QQ登录和分享回调Activity
 * 用于处理QQ登录和分享的回调
 */
class QQEntryActivity : Activity() {
    
    companion object {
        private const val TAG = "QQEntryActivity"
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "QQEntryActivity onCreate")
        
        // 处理QQ回调
        finish()
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        Log.d(TAG, "onActivityResult: requestCode=$requestCode, resultCode=$resultCode")
        
        // 处理QQ回调结果
        UMShareAPI.get(this).onActivityResult(requestCode, resultCode, data)
        finish()
    }
}
