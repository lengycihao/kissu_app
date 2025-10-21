package com.yuluo.kissu.wxapi

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.util.Log
import com.tencent.mm.opensdk.constants.ConstantsAPI
import com.tencent.mm.opensdk.modelbase.BaseReq
import com.tencent.mm.opensdk.modelbase.BaseResp
import com.tencent.mm.opensdk.openapi.IWXAPI
import com.tencent.mm.opensdk.openapi.IWXAPIEventHandler
import com.tencent.mm.opensdk.openapi.WXAPIFactory

/**
 * 微信支付回调Activity
 * 用于处理微信支付的回调结果
 */
class WXPayEntryActivity : Activity(), IWXAPIEventHandler {
    
    companion object {
        private const val TAG = "WXPayEntryActivity"
    }
    
    private var api: IWXAPI? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "=== WXPayEntryActivity onCreate ===")
        Log.d(TAG, "Intent: ${intent?.toUri(0)}")
        Log.d(TAG, "Intent extras: ${intent?.extras?.keySet()?.joinToString()}")
        
        // 初始化微信API
        api = WXAPIFactory.createWXAPI(this, "wxca15128b8c388c13")
        val handleResult = api?.handleIntent(intent, this)
        Log.d(TAG, "handleIntent result: $handleResult")
    }
    
    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        Log.d(TAG, "=== WXPayEntryActivity onNewIntent ===")
        Log.d(TAG, "Intent: ${intent?.toUri(0)}")
        Log.d(TAG, "Intent extras: ${intent?.extras?.keySet()?.joinToString()}")
        setIntent(intent)
        val handleResult = api?.handleIntent(intent, this)
        Log.d(TAG, "handleIntent result: $handleResult")
    }
    
    override fun onReq(req: BaseReq?) {
        Log.d(TAG, "onReq: ${req?.type}")
    }
    
    override fun onResp(resp: BaseResp?) {
        Log.d(TAG, "=== onResp 被调用 ===")
        Log.d(TAG, "Response type: ${resp?.type}")
        Log.d(TAG, "Error code: ${resp?.errCode}")
        Log.d(TAG, "Error string: ${resp?.errStr}")
        Log.d(TAG, "Transaction: ${resp?.transaction}")
        Log.d(TAG, "OpenId: ${resp?.openId}")
        
        when (resp?.type) {
            ConstantsAPI.COMMAND_PAY_BY_WX -> {
                Log.d(TAG, "✅ 确认是微信支付回调")
                // 微信支付回调
                when (resp.errCode) {
                    BaseResp.ErrCode.ERR_OK -> {
                        Log.d(TAG, "✅ 微信支付成功 (errCode=0)")
                        // 通知Flutter层支付成功
                        notifyFlutterPaymentResult(true, "支付成功")
                    }
                    BaseResp.ErrCode.ERR_USER_CANCEL -> {
                        Log.d(TAG, "⚠️ 微信支付取消 (errCode=-2)")
                        // 通知Flutter层支付取消 - 增强处理
                        notifyFlutterPaymentResult(false, "用户取消支付")
                        Log.d(TAG, "📢 用户取消支付通知已发送")
                    }
                    BaseResp.ErrCode.ERR_COMM -> {
                        Log.d(TAG, "❌ 微信支付错误 (errCode=-1)")
                        // 通知Flutter层支付失败
                        notifyFlutterPaymentResult(false, "支付失败")
                    }
                    else -> {
                        Log.d(TAG, "❓ 微信支付未知错误码: ${resp.errCode}")
                        notifyFlutterPaymentResult(false, "支付失败，错误码: ${resp.errCode}")
                    }
                }
            }
            else -> {
                Log.d(TAG, "⚠️ 非微信支付回调: type=${resp?.type}")
                // 如果不是微信支付回调，但我们正在等待支付结果，可能是异常情况
                // 为了保险起见，也发送一个取消通知
                Log.d(TAG, "⚠️ 非预期的回调类型，发送取消通知以防状态卡住")
                notifyFlutterPaymentResult(false, "支付流程异常")
            }
        }
        
        Log.d(TAG, "Activity即将finish")
        finish()
    }
    
    /**
     * 通知Flutter层支付结果
     */
    private fun notifyFlutterPaymentResult(success: Boolean, message: String) {
        try {
            Log.d(TAG, "=== 开始通知Flutter支付结果 ===")
            Log.d(TAG, "Success: $success")
            Log.d(TAG, "Message: $message")
            Log.d(TAG, "Package name: $packageName")
            
            // 发送广播给MainActivity，让它通知Flutter
            val intent = android.content.Intent("kissu.payment.result").apply {
                putExtra("success", success)
                putExtra("message", message)
                putExtra("timestamp", System.currentTimeMillis()) // 添加时间戳
                setPackage(packageName)
            }
            sendBroadcast(intent)
            Log.d(TAG, "✅ 支付结果广播已发送: success=$success, message=$message")
            
            // 增强：延迟再发送一次，确保广播能被接收到
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                try {
                    Log.d(TAG, "🔄 延迟重发支付结果广播: success=$success")
                    val retryIntent = android.content.Intent("kissu.payment.result").apply {
                        putExtra("success", success)
                        putExtra("message", message)
                        putExtra("timestamp", System.currentTimeMillis())
                        putExtra("retry", true) // 标记为重试
                        setPackage(packageName)
                    }
                    sendBroadcast(retryIntent)
                    Log.d(TAG, "✅ 重试广播已发送")
                } catch (e: Exception) {
                    Log.e(TAG, "❌ 重试广播失败", e)
                }
            }, 500) // 延迟500ms
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ 发送支付结果广播失败", e)
        }
    }
}
