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
        Log.d(TAG, "QQEntryActivity onCreate - 处理QQ分享回调")
        
        // 处理QQ回调 - 不要立即finish，让友盟处理完回调
        try {
            UMShareAPI.get(this).onActivityResult(0, RESULT_OK, intent)
            Log.d(TAG, "QQ分享回调处理完成")
        } catch (e: Exception) {
            Log.e(TAG, "QQ分享回调处理失败", e)
        } finally {
            finish()
        }
    }
    
    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        Log.d(TAG, "onNewIntent - 处理新的QQ分享回调")
        setIntent(intent)
        
        try {
            UMShareAPI.get(this).onActivityResult(0, RESULT_OK, intent)
            Log.d(TAG, "QQ分享新Intent回调处理完成")
        } catch (e: Exception) {
            Log.e(TAG, "QQ分享新Intent回调处理失败", e)
        } finally {
            finish()
        }
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        Log.d(TAG, "onActivityResult: requestCode=$requestCode, resultCode=$resultCode")
        
        // 处理QQ回调结果
        try {
            UMShareAPI.get(this).onActivityResult(requestCode, resultCode, data)
            Log.d(TAG, "QQ分享onActivityResult回调处理完成")
        } catch (e: Exception) {
            Log.e(TAG, "QQ分享onActivityResult回调处理失败", e)
        } finally {
            finish()
        }
    }
}
