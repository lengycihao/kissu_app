package com.yuluo.kissu

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import com.tencent.mm.opensdk.modelbase.BaseResp
import com.tencent.mm.opensdk.openapi.IWXAPIEventHandler
import com.umeng.analytics.MobclickAgent
import com.umeng.commonsdk.UMConfigure
import com.umeng.socialize.PlatformConfig
import com.umeng.socialize.UMShareAPI
import com.yuluo.kissu.handlers.*

class MainActivity : FlutterActivity(), IWXAPIEventHandler {
   companion object {
        private const val TAG = "MainActivity"
        
        // Flutter 引擎存活标记
        @Volatile
        var isFlutterEngineAlive = false
        
        // 通道名称
        private const val CHANNEL = "app.location/settings"
        private const val WECHAT_CHANNEL = "app.wechat/launch"
        private const val FOREGROUND_SERVICE_CHANNEL = "kissu_app/foreground_service"
        private const val SHARE_CHANNEL = "app.share/invoke"
        private const val UMSHARE_CHANNEL = "umshare"
        private const val UMENG_ANALYTICS_CHANNEL = "umeng_analytics"
        private const val PAYMENT_CHANNEL = "kissu_payment"
        private const val APP_INFO_CHANNEL = "kissu_app/app_info"
        private const val WHITELIST_CHANNEL = "kissu_app/whitelist"
        private const val GPS_STATUS_CHANNEL = "kissu_app/gps_status"
        private const val SCREEN_LOCK_CHANNEL = "kissu_app/screen_lock"
        private const val APP_USAGE_CHANNEL = "app_usage_channel"
        private const val APP_ICON_CHANNEL = "app_icon_channel"
    }
    
    // 各功能处理器
    private lateinit var paymentHandler: PaymentHandler
    private lateinit var shareHandler: ShareHandler
    private lateinit var appUsageHandler: AppUsageHandler
    private lateinit var locationHandler: LocationHandler
    private lateinit var appInfoHandler: AppInfoHandler
    private lateinit var systemHandler: SystemHandler
    private lateinit var analyticsHandler: AnalyticsHandler
    private lateinit var foregroundServiceHandler: ForegroundServiceHandler
    
    // 微信 API 实例（用于企业微信客服）
    private var wxApi: com.tencent.mm.opensdk.openapi.IWXAPI? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 初始化友盟
        initUmeng()
        
        Log.d(TAG, "MainActivity onCreate")
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        isFlutterEngineAlive = true
        Log.d(TAG, "Flutter引擎配置开始")
        
        // 初始化所有处理器
        initializeHandlers(flutterEngine)
        
        // 注册所有通道
        registerChannels(flutterEngine)
        
        Log.d(TAG, "Flutter引擎配置完成")
    }
    
    /**
     * 初始化所有处理器
     */
    private fun initializeHandlers(flutterEngine: FlutterEngine) {
        paymentHandler = PaymentHandler(this)
        shareHandler = ShareHandler(this)
        appUsageHandler = AppUsageHandler(this)
        locationHandler = LocationHandler(this)
        appInfoHandler = AppInfoHandler(this)
        systemHandler = SystemHandler(this)
        analyticsHandler = AnalyticsHandler(this)
        foregroundServiceHandler = ForegroundServiceHandler(this)
        
        // 初始化需要初始化的处理器
        paymentHandler.initialize()
        locationHandler.initialize(EventChannel(flutterEngine.dartExecutor.binaryMessenger, GPS_STATUS_CHANNEL))
        systemHandler.initialize(EventChannel(flutterEngine.dartExecutor.binaryMessenger, SCREEN_LOCK_CHANNEL))
    }
    
    /**
     * 注册所有通道
     */
    private fun registerChannels(flutterEngine: FlutterEngine) {
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        
        // 定位设置通道
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            locationHandler.handleMethodCall(call, result)
        }
        
        // 微信启动通道
        MethodChannel(messenger, WECHAT_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchWechat" -> {
                    val url = call.argument<String>("url") ?: ""
                    launchWechat(url)
                    result.success(null)
                }
                "openWeComKfWithParams" -> {
                    Log.d(TAG, "收到 openWeComKfWithParams 调用")
                    val corpId = call.argument<String>("corpId")
                    val agentId = call.argument<String>("agentId")
                    val kfId = call.argument<String>("kfId")
                    
                    Log.d(TAG, "参数: corpId=$corpId, agentId=$agentId, kfId=$kfId")
                    
                    if (corpId.isNullOrEmpty() || kfId.isNullOrEmpty()) {
                        Log.e(TAG, "参数错误")
                        result.error("INVALID_ARGS", "corpId and kfId are required", null)
                        return@setMethodCallHandler
                    }
                    
                    try {
                        Log.d(TAG, "开始调用 openWeComKfWithParams")
                        openWeComKfWithParams(corpId, agentId, kfId)
                        Log.d(TAG, "openWeComKfWithParams 调用成功")
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e(TAG, "openWeComKfWithParams 失败: ${e.message}", e)
                        result.error("OPEN_KF_FAILED", e.message, null)
                    }
                }
                "shareToWeChatText" -> {
                    val text = call.argument<String>("text") ?: ""
                    if (text.isBlank()) {
                        result.error("INVALID_ARGS", "text is empty", null)
                    } else {
                        shareHandler.shareTextToWeChat(text, result)
                    }
                }
                else -> result.notImplemented()
            }
        }
        
        // 前台服务通道
        MethodChannel(messenger, FOREGROUND_SERVICE_CHANNEL).setMethodCallHandler { call, result ->
            foregroundServiceHandler.handleMethodCall(call, result)
        }
        
        // 分享通道
        MethodChannel(messenger, SHARE_CHANNEL).setMethodCallHandler { call, result ->
            shareHandler.handleMethodCall(call, result)
        }
        
        // 友盟分享通道
        MethodChannel(messenger, UMSHARE_CHANNEL).setMethodCallHandler { call, result ->
            shareHandler.handleMethodCall(call, result)
        }
        
        // 友盟统计通道
        MethodChannel(messenger, UMENG_ANALYTICS_CHANNEL).setMethodCallHandler { call, result ->
            analyticsHandler.handleMethodCall(call, result)
        }
        
        // 支付通道
        MethodChannel(messenger, PAYMENT_CHANNEL).setMethodCallHandler { call, result ->
            paymentHandler.handleMethodCall(call, result)
        }
        
        // 应用信息通道
        MethodChannel(messenger, APP_INFO_CHANNEL).setMethodCallHandler { call, result ->
            appInfoHandler.handleMethodCall(call, result)
        }
        
        // 白名单通道
        MethodChannel(messenger, WHITELIST_CHANNEL).setMethodCallHandler { call, result ->
            systemHandler.handleWhitelistCall(call, result)
        }
        
        // 应用使用统计通道
        MethodChannel(messenger, APP_USAGE_CHANNEL).setMethodCallHandler { call, result ->
            appUsageHandler.handleMethodCall(call, result)
        }
        
        // 应用图标通道
        MethodChannel(messenger, APP_ICON_CHANNEL).setMethodCallHandler { call, result ->
            appInfoHandler.handleMethodCall(call, result)
        }
    }
    
    /**
     * 初始化友盟
     */
    private fun initUmeng() {
        // 初始化友盟SDK
        UMConfigure.init(
            this,
            "6879fba679267e0210b67bde",
            "Umeng",
            UMConfigure.DEVICE_TYPE_PHONE,
            ""
        )
        
        // 设置友盟日志加密
        UMConfigure.setLogEnabled(true)
        
        // 配置微信平台
        PlatformConfig.setWeixin("wxca15128b8c388c13", "e0d2d1e8c3f4e5f6a7b8c9d0e1f2a3b4")
        
        // 配置QQ平台
        PlatformConfig.setQQZone("102797447", "c5KJ2VipiMRMCpJf")
        
        Log.d(TAG, "友盟SDK初始化完成")
    }
    
    /**
     * 启动微信
     */
    private fun launchWechat(url: String) {
        try {
            val intent = packageManager.getLaunchIntentForPackage("com.tencent.mm")
            if (intent != null) {
                startActivity(intent)
                Log.d(TAG, "启动微信成功")
            } else {
                Log.w(TAG, "未安装微信")
            }
        } catch (e: Exception) {
            Log.e(TAG, "启动微信失败", e)
        }
    }
    
    /**
     * 打开企业微信客服（通过微信SDK）
     */
    private fun openWeComKfWithParams(corpId: String, agentId: String?, kfId: String) {
        Log.d(TAG, "📞 拉起企业微信客服 - 企业ID: $corpId, 客服ID: $kfId")

        // 初始化微信 API
        if (wxApi == null) {
            Log.d(TAG, "初始化微信 API")
            wxApi = com.tencent.mm.opensdk.openapi.WXAPIFactory.createWXAPI(this, "wxca15128b8c388c13", true)
            wxApi?.registerApp("wxca15128b8c388c13")
        }

        // 检查微信是否安装
        if (wxApi?.isWXAppInstalled != true) {
            Log.e(TAG, "❌ 微信未安装，无法拉起客服")
            throw Exception("请先安装微信")
        }

        // 检查微信版本（降低版本要求）
        val supportApi = wxApi?.wxAppSupportAPI ?: 0
        val minVersion = 0x26050250  // 微信 6.5.2.80 (企业微信客服功能最低版本)
        Log.d(TAG, "微信 API 版本: $supportApi (需要 >= $minVersion)")

        if (supportApi < minVersion) {
            Log.e(TAG, "❌ 微信版本过低 (当前: $supportApi, 需要: >= $minVersion)")
            throw Exception("请升级微信到 6.5.2 或更高版本")
        }

        // 🚀 直接使用微信 SDK 拉起客服（不走浏览器！）
        try {
            val req = com.tencent.mm.opensdk.modelbiz.WXOpenCustomerServiceChat.Req()
            req.corpId = corpId  // 企业微信ID: ww5c345e5aa1a2a697
            req.url = "https://work.weixin.qq.com/kfid/$kfId"  // 客服链接
            
            Log.d(TAG, "🚀 发送微信客服请求: corpId=$corpId, url=${req.url}")
            val success = wxApi?.sendReq(req) ?: false
            
            if (success) {
                Log.d(TAG, "✅ 成功拉起微信客服！")
            } else {
                Log.e(TAG, "❌ 微信 SDK sendReq 返回 false")
                throw Exception("拉起客服失败")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ 拉起客服异常: ${e.message}", e)
            throw e
        }
    }
    
    override fun onResume() {
        super.onResume()
        analyticsHandler.onResume()
    }
    
    override fun onPause() {
        super.onPause()
        analyticsHandler.onPause()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        
        // 清理所有处理器
        paymentHandler.cleanup()
        locationHandler.cleanup()
        systemHandler.cleanup()
        
        isFlutterEngineAlive = false
        Log.d(TAG, "MainActivity onDestroy")
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        // 处理分享回调
        shareHandler.onActivityResult(requestCode, resultCode, data)
        
        // 处理微信支付回调
        paymentHandler.wxApi?.handleIntent(data, this)
    }
    
    // ==================== 微信支付回调 ====================
    
    override fun onReq(req: com.tencent.mm.opensdk.modelbase.BaseReq?) {
        // 通常不需要处理
    }
    
    override fun onResp(resp: BaseResp?) {
        paymentHandler.onWechatPayResp(resp)
    }

}