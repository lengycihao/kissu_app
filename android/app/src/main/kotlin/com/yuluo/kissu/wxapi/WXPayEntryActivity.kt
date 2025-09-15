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
                        // 支付成功，可以通知Flutter层
                    }
                    BaseResp.ErrCode.ERR_USER_CANCEL -> {
                        Log.d(TAG, "微信支付取消")
                        // 用户取消支付
                    }
                    BaseResp.ErrCode.ERR_COMM -> {
                        Log.d(TAG, "微信支付错误")
                        // 支付错误
                    }
                }
            }
        }
        
        finish()
    }
}
