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
        Log.d(TAG, "WXPayEntryActivity onCreate")
        
        // 初始化微信API
        api = WXAPIFactory.createWXAPI(this, "wxca15128b8c388c13")
        api?.handleIntent(intent, this)
    }
    
    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        Log.d(TAG, "WXPayEntryActivity onNewIntent")
        setIntent(intent)
        api?.handleIntent(intent, this)
    }
    
    override fun onReq(req: BaseReq?) {
        Log.d(TAG, "onReq: ${req?.type}")
    }
    
    override fun onResp(resp: BaseResp?) {
        Log.d(TAG, "onResp: ${resp?.type}, errCode: ${resp?.errCode}")
        
        when (resp?.type) {
            ConstantsAPI.COMMAND_PAY_BY_WX -> {
                // 微信支付回调
                when (resp.errCode) {
                    BaseResp.ErrCode.ERR_OK -> {
                        Log.d(TAG, "微信支付成功")
                        // 通知Flutter层支付成功
                        notifyFlutterPaymentResult(true, "支付成功")
                    }
                    BaseResp.ErrCode.ERR_USER_CANCEL -> {
                        Log.d(TAG, "微信支付取消")
                        // 通知Flutter层支付取消
                        notifyFlutterPaymentResult(false, "用户取消支付")
                    }
                    BaseResp.ErrCode.ERR_COMM -> {
                        Log.d(TAG, "微信支付错误")
                        // 通知Flutter层支付失败
                        notifyFlutterPaymentResult(false, "支付失败")
                    }
                    else -> {
                        Log.d(TAG, "微信支付未知错误: ${resp.errCode}")
                        notifyFlutterPaymentResult(false, "支付失败")
                    }
                }
            }
        }
        
        finish()
    }
    
    /**
     * 通知Flutter层支付结果
     */
    private fun notifyFlutterPaymentResult(success: Boolean, message: String) {
        try {
            // 发送广播给MainActivity，让它通知Flutter
            val intent = android.content.Intent("kissu.payment.result").apply {
                putExtra("success", success)
                putExtra("message", message)
                setPackage(packageName)
            }
            sendBroadcast(intent)
            Log.d(TAG, "已发送支付结果广播: success=$success, message=$message")
        } catch (e: Exception) {
            Log.e(TAG, "发送支付结果广播失败", e)
        }
    }
}
