package com.yuluo.kissu.handlers

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.util.Log
import com.alipay.sdk.app.PayTask
import com.tencent.mm.opensdk.constants.ConstantsAPI
import com.tencent.mm.opensdk.modelbase.BaseResp
import com.tencent.mm.opensdk.modelpay.PayReq
import com.tencent.mm.opensdk.modelpay.PayResp
import com.tencent.mm.opensdk.openapi.IWXAPI
import com.tencent.mm.opensdk.openapi.WXAPIFactory
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import com.yuluo.kissu.constants.AppConstants

/**
 * 支付处理器
 * 负责处理微信支付和支付宝支付
 */
class PaymentHandler(private val activity: Activity) {
    
    companion object {
        private const val TAG = "PaymentHandler"
        private const val WECHAT_APP_ID = AppConstants.WECHAT_APP_ID
    }
    
    // 微信支付API
    var wxApi: IWXAPI? = null
        private set
    
    // 支付结果等待器
    private var paymentResultCompleter: ((Boolean, String) -> Unit)? = null
    
    // 支付超时定时器
    private var paymentTimeoutJob: Job? = null
    
    // 支付结果广播接收器
    private val paymentResultReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == "kissu.payment.result") {
                val success = intent.getBooleanExtra("success", false)
                val message = intent.getStringExtra("message") ?: ""
                val timestamp = intent.getLongExtra("timestamp", 0)
                val isRetry = intent.getBooleanExtra("retry", false)
                
                Log.d(TAG, "收到支付结果广播: success=$success, message=$message, timestamp=$timestamp, isRetry=$isRetry")
                
                if (paymentResultCompleter != null) {
                    Log.d(TAG, "立即通知支付结果: success=$success, message=$message")
                    paymentResultCompleter?.invoke(success, message)
                    paymentResultCompleter = null
                    paymentTimeoutJob?.cancel()
                    paymentTimeoutJob = null
                } else {
                    Log.w(TAG, "支付结果回调已被清空，忽略广播")
                }
            }
        }
    }
    
    /**
     * 初始化支付处理器
     */
    fun initialize() {
        // 初始化微信支付
        wxApi = WXAPIFactory.createWXAPI(activity, WECHAT_APP_ID, true)
        wxApi?.registerApp(WECHAT_APP_ID)
        
        // 注册支付结果广播接收器
        val filter = IntentFilter("kissu.payment.result")
        activity.registerReceiver(paymentResultReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        
        Log.d(TAG, "支付处理器初始化完成")
    }
    
    /**
     * 清理资源
     */
    fun cleanup() {
        try {
            activity.unregisterReceiver(paymentResultReceiver)
        } catch (e: Exception) {
            Log.e(TAG, "注销支付结果广播接收器失败", e)
        }
    }
    
    /**
     * 处理支付方法调用
     */
    fun handleMethodCall(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initWechat" -> {
                val appId = call.argument<String>("appId") ?: WECHAT_APP_ID
                Log.d(TAG, "初始化微信支付: appId=$appId")
                initialize()
                result.success(null)
            }
            "isWechatInstalled" -> {
                result.success(isWechatAppInstalled())
            }
            "isAlipayInstalled" -> {
                result.success(isAlipayAppInstalled())
            }
            "payWithWechat" -> {
                val appId = call.argument<String>("appId") ?: WECHAT_APP_ID
                val partnerId = call.argument<String>("partnerId") ?: ""
                val prepayId = call.argument<String>("prepayId") ?: ""
                val packageValue = call.argument<String>("packageValue") ?: ""
                val nonceStr = call.argument<String>("nonceStr") ?: ""
                val timeStamp = call.argument<String>("timeStamp") ?: ""
                val sign = call.argument<String>("sign") ?: ""
                
                payWithWechat(appId, partnerId, prepayId, packageValue, nonceStr, timeStamp, sign, result)
            }
            "payWithAlipay" -> {
                val orderInfo = call.argument<String>("orderInfo") ?: ""
                payWithAlipay(orderInfo, result)
            }
            "cancelPaymentTimeout" -> {
                cancelPaymentTimeout()
                result.success(null)
            }
            else -> {
                result.notImplemented()
            }
        }
    }
    
    /**
     * 检查微信是否安装
     */
    private fun isWechatAppInstalled(): Boolean {
        return isAppInstalled("com.tencent.mm")
    }
    
    /**
     * 检查支付宝是否安装
     */
    private fun isAlipayAppInstalled(): Boolean {
        return isAppInstalled("com.eg.android.AlipayGphone")
    }
    
    /**
     * 检查应用是否安装
     */
    private fun isAppInstalled(packageName: String): Boolean {
        return try {
            activity.packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: Exception) {
            false
        }
    }
    
    /**
     * 微信支付
     */
    private fun payWithWechat(
        appId: String,
        partnerId: String,
        prepayId: String,
        packageValue: String,
        nonceStr: String,
        timeStamp: String,
        sign: String,
        result: MethodChannel.Result
    ) {
        try {
            Log.d(TAG, "开始微信支付")
            Log.d(TAG, "appId: $appId")
            Log.d(TAG, "partnerId: $partnerId")
            Log.d(TAG, "prepayId: $prepayId")
            Log.d(TAG, "packageValue: $packageValue")
            Log.d(TAG, "nonceStr: $nonceStr")
            Log.d(TAG, "timeStamp: $timeStamp")
            Log.d(TAG, "sign: $sign")
            
            if (wxApi == null) {
                Log.e(TAG, "微信API未初始化")
                result.success(mapOf("success" to false, "message" to "微信API未初始化"))
                return
            }
            
            // 清理之前的回调状态
            if (paymentResultCompleter != null) {
                Log.w(TAG, "检测到未清理的支付回调，先清理")
                paymentResultCompleter = null
            }
            
            // 取消之前的超时定时器
            paymentTimeoutJob?.cancel()
            paymentTimeoutJob = null
            
            // 设置支付结果回调
            paymentResultCompleter = { success, message ->
                Log.d(TAG, "支付结果回调: success=$success, message=$message")
                paymentTimeoutJob?.cancel()
                paymentTimeoutJob = null
                result.success(mapOf("success" to success, "message" to message))
            }
            
            // 设置60秒超时
            paymentTimeoutJob = CoroutineScope(Dispatchers.Main).launch {
                delay(60000)
                if (paymentResultCompleter != null) {
                    Log.w(TAG, "支付超时（60秒）")
                    paymentResultCompleter?.invoke(false, "支付超时")
                    paymentResultCompleter = null
                }
            }
            
            // 构建支付请求
            val req = PayReq()
            req.appId = appId
            req.partnerId = partnerId
            req.prepayId = prepayId
            req.packageValue = packageValue
            req.nonceStr = nonceStr
            req.timeStamp = timeStamp
            req.sign = sign
            
            // 发送支付请求
            val sendResult = wxApi!!.sendReq(req)
            Log.d(TAG, "微信支付请求发送结果: $sendResult")
            
            if (!sendResult) {
                Log.e(TAG, "微信支付请求发送失败")
                paymentResultCompleter = null
                paymentTimeoutJob?.cancel()
                paymentTimeoutJob = null
                result.success(mapOf("success" to false, "message" to "微信支付请求发送失败"))
            }
        } catch (e: Exception) {
            Log.e(TAG, "微信支付异常", e)
            paymentResultCompleter = null
            paymentTimeoutJob?.cancel()
            paymentTimeoutJob = null
            result.success(mapOf("success" to false, "message" to "微信支付失败: ${e.message}"))
        }
    }
    
    /**
     * 取消支付超时定时器
     */
    private fun cancelPaymentTimeout() {
        Log.d(TAG, "取消支付超时定时器")
        paymentTimeoutJob?.cancel()
        paymentTimeoutJob = null
        Log.d(TAG, "支付超时定时器已取消")
    }
    
    /**
     * 支付宝支付
     */
    private fun payWithAlipay(orderInfo: String, result: MethodChannel.Result) {
        Log.d(TAG, "开始支付宝支付，orderInfo长度: ${orderInfo.length}")
        Log.d(TAG, "orderInfo前100字符: ${orderInfo.take(100)}...")
        
        if (orderInfo.isEmpty()) {
            Log.e(TAG, "支付宝订单信息为空")
            result.success(mapOf("success" to false, "message" to "支付宝订单信息为空"))
            return
        }
        
        CoroutineScope(Dispatchers.IO).launch {
            try {
                Log.d(TAG, "创建PayTask并调用支付")
                val payTask = PayTask(activity)
                Log.d(TAG, "PayTask创建成功，开始调用payV2")
                
                val payResult = payTask.payV2(orderInfo, true)
                Log.d(TAG, "支付宝支付完成，返回结果类型: ${payResult.javaClass.simpleName}")
                Log.d(TAG, "支付宝支付返回结果: $payResult")
                
                withContext(Dispatchers.Main) {
                    val resultStatus = parseAlipayResult(payResult)
                    Log.d(TAG, "解析后的支付结果: success=${resultStatus.success}, message=${resultStatus.message}")
                    
                    result.success(mapOf(
                        "success" to resultStatus.success,
                        "message" to resultStatus.message,
                        "result" to payResult.toString()
                    ))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    Log.e(TAG, "支付宝支付异常", e)
                    result.success(mapOf(
                        "success" to false,
                        "message" to "支付失败: ${e.message}",
                        "error" to e.javaClass.simpleName
                    ))
                }
            }
        }
    }
    
    /**
     * 解析支付宝支付结果
     */
    private data class AlipayResult(val success: Boolean, val message: String)
    
    private fun parseAlipayResult(payResult: Map<String, String>): AlipayResult {
        val resultStatus = payResult["resultStatus"]
        Log.d(TAG, "解析支付宝支付结果: resultStatus=$resultStatus")
        
        return when (resultStatus) {
            "9000" -> AlipayResult(true, "支付成功")
            "8000" -> AlipayResult(false, "支付结果确认中")
            "4000" -> AlipayResult(false, "订单支付失败")
            "5000" -> AlipayResult(false, "重复请求")
            "6001" -> AlipayResult(false, "用户中途取消")
            "6002" -> AlipayResult(false, "网络连接出错")
            "6004" -> AlipayResult(false, "支付结果未知，其它支付结果")
            else -> AlipayResult(false, "未知支付状态: $resultStatus")
        }
    }
    
    /**
     * 处理微信支付回调
     */
    fun onWechatPayResp(resp: BaseResp?) {
        when (resp?.type) {
            ConstantsAPI.COMMAND_PAY_BY_WX -> {
                val payResp = resp as PayResp
                when (payResp.errCode) {
                    BaseResp.ErrCode.ERR_OK -> {
                        Log.d(TAG, "微信支付成功")
                        paymentResultCompleter?.invoke(true, "支付成功")
                        paymentResultCompleter = null
                    }
                    BaseResp.ErrCode.ERR_USER_CANCEL -> {
                        Log.d(TAG, "微信支付取消")
                        paymentResultCompleter?.invoke(false, "用户取消支付")
                        paymentResultCompleter = null
                    }
                    BaseResp.ErrCode.ERR_COMM -> {
                        Log.e(TAG, "微信支付失败")
                        paymentResultCompleter?.invoke(false, "支付失败")
                        paymentResultCompleter = null
                    }
                    else -> {
                        Log.e(TAG, "微信支付未知错误: ${payResp.errCode}")
                        paymentResultCompleter?.invoke(false, "支付失败，错误码: ${payResp.errCode}")
                        paymentResultCompleter = null
                    }
                }
            }
        }
    }
}
