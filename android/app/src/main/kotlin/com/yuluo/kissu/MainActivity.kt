package com.yuluo.kissu

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
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
import com.amap.api.maps.MapsInitializer

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
         private const val PAYMENT_CHANNEL = "kissu_payment"
        private const val APP_INFO_CHANNEL = "kissu_app/app_info"
        private const val WHITELIST_CHANNEL = "kissu_app/whitelist"
        private const val GPS_STATUS_CHANNEL = "kissu_app/gps_status"
        private const val SCREEN_LOCK_CHANNEL = "kissu_app/screen_lock"
        private const val APP_USAGE_CHANNEL = "app_usage_channel"
        private const val APP_ICON_CHANNEL = "app_icon_channel"
        private const val PUSH_BRING_FRONT_CHANNEL = "app.push/bring_to_front"
    }
    
    // 各功能处理器
    private lateinit var paymentHandler: PaymentHandler
    private lateinit var shareHandler: ShareHandler
    private lateinit var appUsageHandler: AppUsageHandler
    private lateinit var locationHandler: LocationHandler
    // private lateinit var appInfoHandler: AppInfoHandler
    private lateinit var systemHandler: SystemHandler 
    private lateinit var foregroundServiceHandler: ForegroundServiceHandler
    
    // 微信 API 实例（用于企业微信客服）
    private var wxApi: com.tencent.mm.opensdk.openapi.IWXAPI? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 🔥 禁用MainActivity的LAUNCHER能力，避免与MainActivityDefault冲突导致双图标
         
        // 🔒 高德地图隐私合规（SDK 8.1.0+ 强制要求）
        // 📝 必须在使用任何高德SDK功能之前调用
        // 🔥 修复：根据隐私政策同意状态设置，而不是直接设置为已同意
        initAmapPrivacy()
        
        // 🔥 处理OpenInstall的Intent（必须在handleNotificationIntent之前）
        handleOpenInstallIntent(intent)
        
        // 处理从通知启动的情况
        handleNotificationIntent(intent)
        
        Log.d(TAG, "MainActivity onCreate")

        // 🔥 修复：移除立即启动定位服务的代码，等待用户同意隐私政策后再启动
        // 定位服务将在用户同意隐私政策后，由 Flutter 层通过 ForegroundServiceHandler 启动
        // 这样可以避免在用户同意前获取位置信息和 ANDROID ID
    }
    
    /**
     * 处理OpenInstall的Intent
     * 用于处理通过OpenInstall链接打开应用的情况
     */
    private fun handleOpenInstallIntent(intent: Intent?) {
        intent?.let {
            // 检查是否是OpenInstall的scheme
            val data = it.data
            if (data != null && data.scheme == "eb24o3") {
                Log.d(TAG, "🔔 检测到OpenInstall Intent")
                Log.d(TAG, "  - Scheme: ${data.scheme}")
                Log.d(TAG, "  - Host: ${data.host}")
                Log.d(TAG, "  - Path: ${data.path}")
                Log.d(TAG, "  - Query: ${data.query}")
                Log.d(TAG, "  - Full URI: ${data.toString()}")
                
                // 打印所有extras
                it.extras?.let { extras ->
                    Log.d(TAG, "  - Extras:")
                    for (key in extras.keySet()) {
                        Log.d(TAG, "    - $key: ${extras.get(key)}")
                    }
                }
            }
        }
    }
    
    /**
     * 处理从通知启动的Intent
     * 用于处理小米厂商通道等离线通知点击
     * 参考极光官方文档：厂商通道使用 JMessageExtra 获取参数
     */
    private fun handleNotificationIntent(intent: Intent?) {
        intent?.let {
            var jpushExtras: String? = null
            
            // 1. 优先检查厂商通道参数（小米、vivo、OPPO、FCM、魅族、荣耀、极光通道）
            // SDK ≥ 4.6.0 版本，厂商通道使用 JMessageExtra
            val jMessageExtra = it.extras?.getString("JMessageExtra")
            if (!jMessageExtra.isNullOrEmpty()) {
                jpushExtras = jMessageExtra
                Log.d(TAG, "从通知启动（厂商通道）- JMessageExtra: $jpushExtras")
            }
            
            // 2. 检查华为通道参数（使用 getData）
            if (jpushExtras.isNullOrEmpty() && it.data != null) {
                jpushExtras = it.data.toString()
                Log.d(TAG, "从通知启动（华为通道）- getData: $jpushExtras")
            }
            
            // 3. 检查极光通道参数（自定义的 jpush_extras）
            if (jpushExtras.isNullOrEmpty()) {
                jpushExtras = it.getStringExtra("jpush_extras")
                if (!jpushExtras.isNullOrEmpty()) {
                    Log.d(TAG, "从通知启动（极光通道）- jpush_extras: $jpushExtras")
                }
            }
            
            // 4. 检查其他可能的参数
            if (jpushExtras.isNullOrEmpty()) {
                val extras = it.extras
                if (extras != null) {
                    // 尝试从 extras 中获取所有可能的极光相关参数
                    for (key in extras.keySet()) {
                        if (key.contains("jpush", ignoreCase = true) || 
                            key.contains("JPush", ignoreCase = true) ||
                            key.contains("extra", ignoreCase = true)) {
                            val value = extras.get(key)?.toString()
                            if (!value.isNullOrEmpty()) {
                                Log.d(TAG, "从通知启动 - 找到参数: $key = $value")
                                if (jpushExtras.isNullOrEmpty()) {
                                    jpushExtras = value
                                }
                            }
                        }
                    }
                }
            }
            
            if (!jpushExtras.isNullOrEmpty()) {
                Log.d(TAG, "最终获取到的通知参数: $jpushExtras")
                // 这里可以将数据传递给Flutter层处理
                // 可以通过MethodChannel或者EventChannel传递给Flutter
            } else {
                Log.d(TAG, "未找到通知参数，可能是普通启动")
            }
        }
    }
    
 
    
    /**
     * 初始化高德地图隐私合规
     * 📝 SDK 8.1.0+ 强制要求，否则地图无法正常使用
     * 🔥 修复：根据隐私政策同意状态设置，而不是直接设置为已同意
     */
    private fun initAmapPrivacy() {
        try {
            // 检查隐私政策是否已同意（从 SharedPreferences 读取 Flutter 保存的状态）
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val privacyAgreed = prefs.getBoolean("flutter.privacy_policy_agreed", false)
            
            // 设置已经显示隐私政策（true表示已向用户展示）
            MapsInitializer.updatePrivacyShow(this, true, true)
            // 🔥 修复：根据实际隐私政策同意状态设置，而不是直接设置为 true
            MapsInitializer.updatePrivacyAgree(this, privacyAgreed)
            
            if (privacyAgreed) {
                Log.d(TAG, "✅ 高德地图隐私合规初始化成功（用户已同意隐私政策）")
            } else {
                Log.d(TAG, "⚠️ 高德地图隐私合规初始化（用户未同意隐私政策，等待同意后启用）")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ 高德地图隐私合规初始化失败", e)
            // 如果读取失败，默认设置为未同意，确保合规
            try {
                MapsInitializer.updatePrivacyShow(this, true, true)
                MapsInitializer.updatePrivacyAgree(this, false)
            } catch (e2: Exception) {
                Log.e(TAG, "❌ 设置高德地图隐私默认状态失败", e2)
            }
        }
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
        // appInfoHandler = AppInfoHandler(this)
        systemHandler = SystemHandler(this) 
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
        
         
        
        // 支付通道
        MethodChannel(messenger, PAYMENT_CHANNEL).setMethodCallHandler { call, result ->
            paymentHandler.handleMethodCall(call, result)
        }
        
        // // 应用信息通道
        // MethodChannel(messenger, APP_INFO_CHANNEL).setMethodCallHandler { call, result ->
        //     appInfoHandler.handleMethodCall(call, result)
        // }
        
        // 白名单通道
        MethodChannel(messenger, WHITELIST_CHANNEL).setMethodCallHandler { call, result ->
            systemHandler.handleWhitelistCall(call, result)
        }
        
        // 应用使用统计通道
        MethodChannel(messenger, APP_USAGE_CHANNEL).setMethodCallHandler { call, result ->
            appUsageHandler.handleMethodCall(call, result)
        }
        
        // 应用图标通道（动态切换桌面图标）
        MethodChannel(messenger, APP_ICON_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCurrentIcon" -> {
                    val current = getCurrentIconId()
                    result.success(current)
                }
                "changeIcon" -> {
                    val iconId = call.argument<String>("iconId")
                    if (iconId.isNullOrEmpty()) {
                        result.error("INVALID_ARGS", "iconId is required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val ok = changeAppIcon(iconId)
                        result.success(ok)
                    } catch (e: Exception) {
                        Log.e(TAG, "切换图标失败", e)
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // 推送点击后把任务栈前置（配合 JNotifyActivity 回调）
        MethodChannel(messenger, PUSH_BRING_FRONT_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "bringToFront") {
                try {
                    // 尝试复用已有任务栈，避免总是重启显示冷启动页
                    val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
                    if (launchIntent != null) {
                        launchIntent.addCategory(Intent.CATEGORY_LAUNCHER)
                        launchIntent.flags =
                            Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_SINGLE_TOP or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP or
                            Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                        startActivity(launchIntent)
                    } else {
                        // 兜底：若获取失败，再用重启任务方式
                        val component = ComponentName(packageName, "com.yuluo.kissu.MainActivity")
                        val intent = Intent.makeRestartActivityTask(component)
                        startActivity(intent)
                    }
                    result.success(null)
                } catch (e: Exception) {
                    Log.e(TAG, "bringToFront 失败", e)
                    result.error("START_FAIL", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
    
    /**
     * Flutter 侧图标 id 与 Android activity-alias 映射
     */
    private val iconAliasMap: Map<String, String> = mapOf(
        // 页面中的 kissu_icon（默认）
        "default" to "com.yuluo.kissu.MainActivityDefault",
        // kissu_logo_2 ~ kissu_logo_10
        "logo_2" to "com.yuluo.kissu.MainActivityIcon2",
        "logo_3" to "com.yuluo.kissu.MainActivityIcon3",
        "logo_4" to "com.yuluo.kissu.MainActivityIcon4",
        "logo_5" to "com.yuluo.kissu.MainActivityIcon5",
        "logo_6" to "com.yuluo.kissu.MainActivityIcon6",
        "logo_7" to "com.yuluo.kissu.MainActivityIcon7",
        "logo_8" to "com.yuluo.kissu.MainActivityIcon8",
        "logo_9" to "com.yuluo.kissu.MainActivityIcon9",
        "logo_10" to "com.yuluo.kissu.MainActivityIcon10",
        "logo_11" to "com.yuluo.kissu.MainActivityIcon11",
        "logo_12" to "com.yuluo.kissu.MainActivityIcon12",
        "logo_13" to "com.yuluo.kissu.MainActivityIcon13",
        "logo_14" to "com.yuluo.kissu.MainActivityIcon14",
        "logo_15" to "com.yuluo.kissu.MainActivityIcon15",
        "logo_16" to "com.yuluo.kissu.MainActivityIcon16",
        "logo_17" to "com.yuluo.kissu.MainActivityIcon17",
        "logo_18" to "com.yuluo.kissu.MainActivityIcon18",
    )

    /**
     * 获取当前启用的图标 id
     */
    private fun getCurrentIconId(): String {
        val pm = packageManager
        iconAliasMap.forEach { (id, aliasName) ->
            val componentName = ComponentName(this, aliasName)
            val state = pm.getComponentEnabledSetting(componentName)
            if (state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED) {
                return id
            }
        }
        // 如果都没有显式启用，认为是默认图标
        return "default"
    }

    /**
     * 切换桌面图标：
     * - 只启用一个对应的 activity-alias
     * - 其它全部禁用，避免桌面出现多个图标
     */
    private fun changeAppIcon(iconId: String): Boolean {
        val targetAlias = iconAliasMap[iconId] ?: return false
        val pm = packageManager

        
        iconAliasMap.forEach { (id, aliasName) ->
             val componentName = ComponentName(this, aliasName)
             val newState = if (id == iconId) PackageManager.COMPONENT_ENABLED_STATE_ENABLED else PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            pm.setComponentEnabledSetting(
                componentName,
                newState,
                PackageManager.DONT_KILL_APP
            )
        }

        Log.d(TAG, "桌面图标已切换为: $iconId ($targetAlias)")
        return true
    }
    
    /**
     * 初始化友盟
     */
    private fun initUmeng() {
        // 注意：UMConfigure 已在 Application.onCreate 中初始化（KissuApplication）
        // 这里仅保留平台配置（微信/QQ），避免重复初始化
        PlatformConfig.setWeixin("wxca15128b8c388c13", "e0d2d1e8c3f4e5f6a7b8c9d0e1f2a3b4")
        PlatformConfig.setQQZone("102797447", "c5KJ2VipiMRMCpJf")
        Log.d(TAG, "友盟平台配置完成（UMeng init 在 Application 中完成）")
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
    }
    
    override fun onPause() {
        super.onPause() 
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