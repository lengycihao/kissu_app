package com.yuluo.kissu.qqapi

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.util.Log
import com.umeng.socialize.UMShareAPI
import com.tencent.tauth.Tencent

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
        Log.d(TAG, "Intent data: ${intent.data}")
        Log.d(TAG, "Intent action: ${intent.action}")
        
        // 处理QQ回调 - 使用友盟SDK处理
        try {
            val result = UMShareAPI.get(this).onActivityResult(0, RESULT_OK, intent)
            Log.d(TAG, "友盟QQ分享回调处理结果: $result")
        } catch (e: Exception) {
            Log.e(TAG, "友盟QQ分享回调处理失败", e)
            
            // 如果友盟处理失败，尝试腾讯官方SDK处理
            try {
                Tencent.onActivityResultData(0, RESULT_OK, intent, null)
                Log.d(TAG, "腾讯官方QQ回调处理完成")
            } catch (e2: Exception) {
                Log.e(TAG, "腾讯官方QQ回调处理也失败", e2)
            }
        } finally {
            // 延迟finish，确保回调处理完成
            finish()
        }
    }
    
    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        Log.d(TAG, "onNewIntent - 处理新的QQ分享回调")
        setIntent(intent)
        
        try {
            val result = UMShareAPI.get(this).onActivityResult(0, RESULT_OK, intent)
            Log.d(TAG, "友盟QQ分享新Intent回调处理结果: $result")
        } catch (e: Exception) {
            Log.e(TAG, "友盟QQ分享新Intent回调处理失败", e)
            
            // 备用处理
            try {
                Tencent.onActivityResultData(0, RESULT_OK, intent, null)
                Log.d(TAG, "腾讯官方QQ新Intent回调处理完成")
            } catch (e2: Exception) {
                Log.e(TAG, "腾讯官方QQ新Intent回调处理也失败", e2)
            }
        } finally {
            finish()
        }
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        Log.d(TAG, "onActivityResult: requestCode=$requestCode, resultCode=$resultCode")
        
        // 处理QQ回调结果
        try {
            val result = UMShareAPI.get(this).onActivityResult(requestCode, resultCode, data)
            Log.d(TAG, "友盟QQ分享onActivityResult回调处理结果: $result")
        } catch (e: Exception) {
            Log.e(TAG, "友盟QQ分享onActivityResult回调处理失败", e)
            
            // 备用处理
            try {
                Tencent.onActivityResultData(requestCode, resultCode, data, null)
                Log.d(TAG, "腾讯官方QQ onActivityResult回调处理完成")
            } catch (e2: Exception) {
                Log.e(TAG, "腾讯官方QQ onActivityResult回调处理也失败", e2)
            }
        } finally {
            finish()
        }
    }
}
