package com.yuluo.kissu

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import java.security.MessageDigest
import java.security.NoSuchAlgorithmException
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import com.umeng.analytics.MobclickAgent
import com.umeng.commonsdk.UMConfigure
import com.umeng.socialize.PlatformConfig
import com.umeng.socialize.ShareAction
import com.umeng.socialize.UMShareAPI
import com.umeng.socialize.UMShareListener
import com.umeng.socialize.bean.SHARE_MEDIA
import com.umeng.socialize.media.UMImage
import com.umeng.socialize.media.UMWeb
// import com.amap.api.location.AMapLocationClient
import com.alipay.sdk.app.PayTask
import com.tencent.mm.opensdk.modelpay.PayReq
import com.tencent.mm.opensdk.openapi.WXAPIFactory
import com.tencent.mm.opensdk.openapi.IWXAPI
import com.tencent.mm.opensdk.openapi.IWXAPIEventHandler
import com.tencent.mm.opensdk.modelbase.BaseResp
import com.tencent.mm.opensdk.modelpay.PayResp
import com.tencent.mm.opensdk.constants.ConstantsAPI
import kotlinx.coroutines.*
import android.content.BroadcastReceiver
import android.content.Context
import android.content.IntentFilter

class MainActivity : FlutterActivity(), IWXAPIEventHandler {
    private val CHANNEL = "app.location/settings"
    private val WECHAT_CHANNEL = "app.wechat/launch"
    private val FOREGROUND_SERVICE_CHANNEL = "kissu_app/foreground_service"
    private val SHARE_CHANNEL = "app.share/invoke"
    private val UMSHARE_CHANNEL = "umshare"
    private val PAYMENT_CHANNEL = "kissu_payment"
    
    // 微信支付API
    private var wxApi: IWXAPI? = null
    
    // 支付结果等待器
    private var paymentResultCompleter: ((Boolean, String) -> Unit)? = null
    
    // 支付结果广播接收器
    private val paymentResultReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == "kissu.payment.result") {
                val success = intent.getBooleanExtra("success", false)
                val message = intent.getStringExtra("message") ?: ""
                Log.d("MainActivity", "收到支付结果广播: success=$success, message=$message")
                
                // 立即处理支付结果，确保用户取消支付时能立即得到反馈
                if (paymentResultCompleter != null) {
                    Log.d("MainActivity", "立即通知支付结果: success=$success, message=$message")
                    paymentResultCompleter?.invoke(success, message)
                    paymentResultCompleter = null
                } else {
                    Log.w("MainActivity", "收到支付结果但无等待的回调: success=$success, message=$message")
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 设置高德地图隐私合规
        setupAmapPrivacyCompliance()
        
        // 打印SHA1值用于调试高德地图配置
        printSHA1()
        
        // 设置QQ权限 - 关键配置！
        try {
            val tencentClass = Class.forName("com.tencent.tauth.Tencent")
            val setIsPermissionGrantedMethod = tencentClass.getMethod("setIsPermissionGranted", Boolean::class.java)
            setIsPermissionGrantedMethod.invoke(null, true)
            Log.d("MainActivity", "QQ权限设置成功")
        } catch (e: Exception) {
            Log.e("MainActivity", "设置QQ权限失败", e)
        }
        
        // 注册支付结果广播接收器
        val filter = IntentFilter("kissu.payment.result")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Android 13+ 需要明确指定RECEIVER_NOT_EXPORTED
            registerReceiver(paymentResultReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(paymentResultReceiver, filter)
        }
        Log.d("MainActivity", "支付结果广播接收器已注册")
    }
    
    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(paymentResultReceiver)
            Log.d("MainActivity", "支付结果广播接收器已注销")
        } catch (e: Exception) {
            Log.e("MainActivity", "注销广播接收器失败", e)
        }
    }
    
    /**
     * 设置高德地图隐私合规
     * 注意：由于使用Flutter高德地图插件，隐私合规应该在Flutter层面处理
     */
    private fun setupAmapPrivacyCompliance() {
        try {
            // 注释掉原生API调用，因为使用了Flutter插件
            // AMapLocationClient.updatePrivacyShow(this, true, true)
            // AMapLocationClient.updatePrivacyAgree(this, true)
            // AMapLocationClient.setApiKey("38edb925a25f22e3aae2f86ce7f2ff3b")
            
            Log.d("MainActivity", "高德地图隐私合规设置跳过（使用Flutter插件）")
        } catch (e: Exception) {
            Log.e("MainActivity", "高德地图隐私合规设置失败: ${e.message}")
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Flutter 3.16+ 使用自动插件注册，手动注册可能导致重复注册
        // 如果遇到插件重复注册警告，可以移除此代码块
        // 保留注释以说明历史原因
        /*
        try {
            GeneratedPluginRegistrant.registerWith(flutterEngine)
        } catch (_: Throwable) {
            // Safe no-op
        }
        */


        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openNotificationSettings" -> {
                    openNotificationSettings()
                    result.success(null)
                }
                "openLocationSettings" -> {
                    openLocationSettings()
                    result.success(null)
                }
                "openBatteryOptimizationSettings" -> {
                    openBatteryOptimizationSettings()
                    result.success(null)
                }
                "openUsageAccessSettings" -> {
                    openUsageAccessSettings()
                    result.success(null)
                }
                "openAppSettings" -> {
                    openAppSettings()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WECHAT_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openWeComKf" -> {
                    val url = call.argument<String>("kfidUrl") ?: ""
                    if (url.isNotEmpty()) {
                        openWeComKf(url)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGS", "kfidUrl is empty", null)
                    }
                }
                "shareToWeChatText" -> {
                    val text = call.argument<String>("text") ?: ""
                    if (text.isBlank()) {
                        result.error("INVALID_ARGS", "text is empty", null)
                    } else {
                        val ok = shareTextToWeChat(text)
                        result.success(ok)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // 原生分享通道：用于 QQ 文本分享（通过 Intent 调起 QQ 文本分享界面）
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "shareToQQText" -> {
                    val text = call.argument<String>("text") ?: ""
                    if (text.isBlank()) {
                        result.error("INVALID_ARGS", "text is empty", null)
                        return@setMethodCallHandler
                    }
                    val ok = shareTextToQQ(text)
                    result.success(ok)
                }
                else -> result.notImplemented()
            }
        }

        // 友盟分享通道
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UMSHARE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "umInit" -> {
                    val appKey = call.argument<String>("appKey") ?: ""
                    val channel = call.argument<String>("channel") ?: "Umeng"
                    val logEnabled = call.argument<Boolean>("logEnabled") ?: false
                    initUMengSDK(appKey, channel, logEnabled)
                    result.success(null)
                }
                "platformConfig" -> {
                    val qqAppKey = call.argument<String>("qqAppKey") ?: ""
                    val qqAppSecret = call.argument<String>("qqAppSecret") ?: ""
                    val weChatAppId = call.argument<String>("weChatAppId") ?: ""
                    val weChatFileProvider = call.argument<String>("weChatFileProvider") ?: ""
                    configPlatforms(qqAppKey, qqAppSecret, weChatAppId, weChatFileProvider)
                    result.success(null)
                }
                "setPrivacyPolicy" -> {
                    val granted = call.argument<Boolean>("granted") ?: true
                    setUMengPrivacyPolicy(granted)
                    result.success(null)
                }
                "umCheckInstall" -> {
                    val platform = call.arguments as? Int ?: 0
                    val isInstalled = checkPlatformInstall(platform)
                    result.success(mapOf("isInstalled" to isInstalled))
                }
                "checkQQInstallBackup" -> {
                    val isInstalled = checkQQInstallBackup()
                    result.success(mapOf("isInstalled" to isInstalled))
                }
                "umShare" -> {
                    val title = call.argument<String>("title") ?: ""
                    val text = call.argument<String>("text") ?: ""
                    val img = call.argument<String>("img") ?: ""
                    val weburl = call.argument<String>("weburl") ?: ""
                    val sharemedia = call.argument<Int>("sharemedia") ?: 0
                    umengShare(title, text, img, weburl, sharemedia, result)
                }
                else -> result.notImplemented()
            }
        }

        // 支付通道
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PAYMENT_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initWechat" -> {
                    val appId = call.argument<String>("appId") ?: ""
                    initWechatPay(appId)
                    result.success(null)
                }
                "isWechatInstalled" -> {
                    val isInstalled = isWechatAppInstalled()
                    result.success(isInstalled)
                }
                "payWithWechat" -> {
                    val appId = call.argument<String>("appId") ?: ""
                    val partnerId = call.argument<String>("partnerId") ?: ""
                    val prepayId = call.argument<String>("prepayId") ?: ""
                    val packageValue = call.argument<String>("packageValue") ?: ""
                    val nonceStr = call.argument<String>("nonceStr") ?: ""
                    val timeStamp = call.argument<String>("timeStamp") ?: ""
                    val sign = call.argument<String>("sign") ?: ""
                    Log.d("MainActivity", "收到微信支付请求，参数: appId=$appId, partnerId=$partnerId, prepayId=$prepayId")
                    payWithWechat(appId, partnerId, prepayId, packageValue, nonceStr, timeStamp, sign, result)
                }
                "isAlipayInstalled" -> {
                    val isInstalled = isAlipayAppInstalled()
                    result.success(isInstalled)
                }
                "payWithAlipay" -> {
                    val orderInfo = call.argument<String>("orderInfo") ?: ""
                    Log.d("MainActivity", "收到支付宝支付请求，orderInfo长度: ${orderInfo.length}")
                    payWithAlipay(orderInfo, result)
                }
                else -> result.notImplemented()
            }
        }
        
        // 前台服务通道
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FOREGROUND_SERVICE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startForegroundService" -> {
                    val config = call.arguments as? Map<String, Any> ?: mapOf()
                    val success = ForegroundLocationService.startService(this, config)
                    result.success(success)
                }
                "stopForegroundService" -> {
                    val success = ForegroundLocationService.stopService(this)
                    result.success(success)
                }
                "isServiceRunning" -> {
                    val isRunning = ForegroundLocationService.isRunning()
                    result.success(isRunning)
                }
                "updateNotification" -> {
                    val config = call.arguments as? Map<String, Any> ?: mapOf()
                    // 发送更新通知的Intent
                    val intent = android.content.Intent(this, ForegroundLocationService::class.java).apply {
                        action = ForegroundLocationService.ACTION_UPDATE_NOTIFICATION
                        config.forEach { (key, value) ->
                            when (value) {
                                is String -> putExtra(key, value)
                                is Int -> putExtra(key, value)
                                is Long -> putExtra(key, value)
                                is Boolean -> putExtra(key, value)
                            }
                        }
                    }
                    startService(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun shareTextToWeChat(text: String): Boolean {
        val wechatPkg = "com.tencent.mm"
        if (!isAppInstalled(wechatPkg)) return false
        return try {
            // WeChat supports ACTION_SEND with text/plain; some ROMs require explicit package
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, text)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                `package` = wechatPkg
            }
            startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun shareTextToQQ(text: String): Boolean {
        // 优先尝试 QQ (Android 官方包名)
        val qqPackages = listOf(
            "com.tencent.mobileqq",
            "com.tencent.tim",
            "com.tencent.qqlite"
        )
        val sendIntent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, text)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        // 首选目标包
        for (pkg in qqPackages) {
            if (isAppInstalled(pkg)) {
                try {
                    val intent = Intent(sendIntent).apply { `package` = pkg }
                    startActivity(intent)
                    return true
                } catch (_: Exception) { }
            }
        }
        // 兜底：系统分享选择器（可能仍然能路由到 QQ）
        return try {
            val chooser = Intent.createChooser(sendIntent, "分享到QQ")
            chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(chooser)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun openNotificationSettings() {
        val intent: Intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Android 8.0+
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            // Android 5.0 - 7.1
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                putExtra("app_package", packageName)
                putExtra("app_uid", applicationInfo.uid)
            }
        } else {
            // Android 4.4及以下，打开应用详情页
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", packageName, null)
            }
        }
        startActivity(intent)
    }

    private fun openLocationSettings() {
        val brand = (Build.BRAND ?: "").lowercase(java.util.Locale.ROOT)
        val manufacturer = (Build.MANUFACTURER ?: "").lowercase(java.util.Locale.ROOT)
        val model = (Build.MODEL ?: "").lowercase(java.util.Locale.ROOT)
        val product = (Build.PRODUCT ?: "").lowercase(java.util.Locale.ROOT)
        val deviceSignature = "$brand|$manufacturer|$model|$product"
        // 仅检测华为设备（排除荣耀设备，因为荣耀设备定位功能正常）
        val isHuawei = (deviceSignature.contains("huawei") ||
                       deviceSignature.contains("hw")) &&
                       // 明确排除荣耀设备
                       !deviceSignature.contains("honor") &&
                       !deviceSignature.contains("hny") &&
                       !deviceSignature.contains("magic")

        // 对华为设备（非荣耀），强制直达"应用信息"页，避免任何权限页被重定向到"定位服务"
        if (isHuawei) {
            // 1) 尝试显式跳转到 AOSP 的已安装应用详情页
            try {
                val explicit = Intent().apply {
                    setClassName("com.android.settings", "com.android.settings.applications.InstalledAppDetails")
                    putExtra("app_package", packageName)
                    putExtra("package", packageName)
                    putExtra(Intent.EXTRA_PACKAGE_NAME, packageName)
                    data = Uri.fromParts("package", packageName, null)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(explicit)
                return
            } catch (_: Exception) { }

            // 2) 尝试新版设置的 AppInfoDashboard
            try {
                val dashboard = Intent().apply {
                    setClassName("com.android.settings", "com.android.settings.applications.AppInfoDashboardActivity")
                    data = Uri.fromParts("package", packageName, null)
                    putExtra(Intent.EXTRA_PACKAGE_NAME, packageName)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(dashboard)
                return
            } catch (_: Exception) { }

            // 3) 通用应用详情页
            try {
                val appDetails = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.fromParts("package", packageName, null)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(appDetails)
                return
            } catch (_: Exception) { }
        }

        // 其它设备：直接进入应用详情页（用户可手动进入"权限"->"位置信息"）
        try {
            val appDetails = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", packageName, null)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(appDetails)
            return
        } catch (_: Exception) { }

        // 最终兜底：尝试 AOSP 显式 Activity（极少数 ROM 需要）
        try {
            val explicit = Intent().apply {
                setClassName("com.android.settings", "com.android.settings.applications.InstalledAppDetails")
                putExtra("app_package", packageName)
                putExtra("package", packageName)
                putExtra(Intent.EXTRA_PACKAGE_NAME, packageName)
                data = Uri.fromParts("package", packageName, null)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(explicit)
            return
        } catch (_: Exception) { }
    }

    private fun openBatteryOptimizationSettings() {
        // 厂商适配：优先打开"自启动/后台运行"设置
        try {
            val miui = Intent().apply {
                setClassName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(miui)
            return
        } catch (_: Exception) { }

        try {
            val huawei = Intent().apply {
                setClassName("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(huawei)
            return
        } catch (_: Exception) { }

        try {
            val oppo = Intent().apply {
                setClassName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(oppo)
            return
        } catch (_: Exception) { }

        try {
            val vivo = Intent().apply {
                setClassName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(vivo)
            return
        } catch (_: Exception) { }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                // 标准：申请忽略电池优化（Doze）
                val ignoreDoze = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = Uri.parse("package:$packageName")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(ignoreDoze)
                return
            } catch (_: Exception) { }

            try {
                // 标准：忽略电池优化设置列表
                val ignoreList = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                startActivity(ignoreList)
                return
            } catch (_: Exception) { }
        }

        // 兜底：应用详情页
        val fallback = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.fromParts("package", packageName, null)
        }
        startActivity(fallback)
    }

    private fun openUsageAccessSettings() {
        // 尝试打开本应用的使用情况访问详情页
        try {
            val perApp = Intent().apply {
                setClassName("com.android.settings", "com.android.settings.Settings\$UsageAccessDetailsActivity")
                data = Uri.parse("package:$packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(perApp)
            return
        } catch (_: Exception) { }

        // 标准：使用情况访问列表
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            try {
                val list = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                startActivity(list)
                return
            } catch (_: Exception) { }
        }

        // 兜底：应用详情页
        val fallback = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.fromParts("package", packageName, null)
        }
        startActivity(fallback)
    }

    private fun openAppSettings() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.fromParts("package", packageName, null)
        }
        startActivity(intent)
    }

    // ===== WeChat/WeCom Customer Service Opening =====
    private fun isAppInstalled(targetPackage: String): Boolean {
        return try {
            packageManager.getPackageInfo(targetPackage, PackageManager.GET_ACTIVITIES)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun openUrlInPackage(url: String, targetPackage: String): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                `package` = targetPackage
            }
            startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun openWeComKf(kfidUrl: String) {
        val wechatPkg = "com.tencent.mm"
        val wecomPkg = "com.tencent.wework"

        // 优先尝试用微信打开（kfid 链接通常在微信内直达会话）
        if (isAppInstalled(wechatPkg) && openUrlInPackage(kfidUrl, wechatPkg)) {
            return
        }

        // 再尝试企业微信
        if (isAppInstalled(wecomPkg) && openUrlInPackage(kfidUrl, wecomPkg)) {
            return
        }

        // 兜底：交给系统默认浏览器
        try {
            val browser = Intent(Intent.ACTION_VIEW, Uri.parse(kfidUrl)).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(browser)
        } catch (_: Exception) { }
    }

    // ===== 友盟分享相关方法 =====
    private fun initUMengSDK(appKey: String, channel: String, logEnabled: Boolean) {
        try {
            // 友盟合规要求：预初始化，设置隐私政策
            UMConfigure.preInit(this, appKey, channel)
            // 🔒 隐私合规：不在用户同意前设置隐私授权
            // UMConfigure.submitPolicyGrantResult(this, true) // 移到用户同意后执行
            // 正式初始化
            UMConfigure.init(this, appKey, channel, UMConfigure.DEVICE_TYPE_PHONE, null)
            UMConfigure.setLogEnabled(logEnabled)
            
            // 预授权QQ权限 - 在友盟初始化后立即设置
            try {
                val tencentClass = Class.forName("com.tencent.tauth.Tencent")
                val setIsPermissionGrantedMethod = tencentClass.getMethod("setIsPermissionGranted", Boolean::class.java)
                setIsPermissionGrantedMethod.invoke(null, true)
                Log.d("MainActivity", "友盟初始化后QQ权限预授权成功")
            } catch (e: Exception) {
                Log.w("MainActivity", "友盟初始化后QQ权限预授权失败: ${e.message}")
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun setUMengPrivacyPolicy(granted: Boolean) {
        try {
            UMConfigure.submitPolicyGrantResult(this, granted)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun configPlatforms(qqAppKey: String, qqAppSecret: String, weChatAppId: String, weChatFileProvider: String) {
        try {
            // 配置QQ平台（QQ空间配置同时支持QQ好友分享）
            // 注意：友盟的setQQZone方法参数顺序是(appKey, appSecret)
            // 其中appKey是QQ应用的ID，appSecret是QQ应用的密钥
            if (qqAppKey.isNotEmpty() && qqAppSecret.isNotEmpty()) {
                // 1. 首先配置QQ平台
                PlatformConfig.setQQZone(qqAppKey, qqAppSecret)
                Log.d("MainActivity", "QQ平台配置成功: appKey=$qqAppKey, appSecret=$qqAppSecret")
                
                // 1.5. 配置后立即修复QQ权限
                fixQQPermissions()
                
                // 2. 设置QQ权限 - 多种方法尝试解决2003错误
                try {
                    // 方法1：使用Tencent类的静态方法设置权限
                    val tencentClass = Class.forName("com.tencent.tauth.Tencent")
                    val setIsPermissionGrantedMethod = tencentClass.getMethod("setIsPermissionGranted", Boolean::class.java)
                    setIsPermissionGrantedMethod.invoke(null, true)
                    Log.d("MainActivity", "QQ权限设置成功 (静态方法)")
                } catch (e: Exception) {
                    Log.w("MainActivity", "QQ静态权限设置失败: ${e.message}")
                    
                    // 方法2：尝试通过实例设置权限
                    try {
                        val tencent = com.tencent.tauth.Tencent.createInstance(qqAppKey, this, "com.yuluo.kissu.fileprovider")
                        if (tencent != null) {
                            val setPermissionMethod = tencent.javaClass.getMethod("setIsPermissionGranted", Boolean::class.java)
                            setPermissionMethod.invoke(tencent, true)
                            Log.d("MainActivity", "QQ权限设置成功 (实例方法)")
                        }
                    } catch (e2: Exception) {
                        Log.e("MainActivity", "QQ实例权限设置也失败: ${e2.message}")
                    }
                }
                
                Log.d("MainActivity", "QQ空间配置已启用，同时支持QQ好友分享")
            } else {
                Log.w("MainActivity", "QQ平台配置失败: appKey或appSecret为空")
            }
            
            // 配置微信平台
            if (weChatAppId.isNotEmpty()) {
                PlatformConfig.setWeixin(weChatAppId, "")
                // 配置FileProvider
                if (weChatFileProvider.isNotEmpty()) {
                    PlatformConfig.setWXFileProvider(weChatFileProvider)
                }
                Log.d("MainActivity", "微信平台配置成功: appId=$weChatAppId")
            } else {
                Log.w("MainActivity", "微信平台配置失败: appId为空")
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "配置平台失败", e)
            e.printStackTrace()
        }
    }

    private fun checkPlatformInstall(platform: Int): Boolean {
        return try {
            val shareMedia = when (platform) {
                0 -> SHARE_MEDIA.WEIXIN // 微信
                1 -> SHARE_MEDIA.QQ // QQ
                2 -> SHARE_MEDIA.QZONE // QQ空间
                3 -> SHARE_MEDIA.WEIXIN_CIRCLE // 微信朋友圈
                else -> SHARE_MEDIA.WEIXIN
            }
            val result = UMShareAPI.get(this).isInstall(this, shareMedia)
            Log.d("MainActivity", "友盟检测平台安装状态: platform=$platform, result=$result")
            result
        } catch (e: Exception) {
            Log.e("MainActivity", "友盟检测平台安装状态失败", e)
            false
        }
    }
    
    /**
     * 备用QQ检测方法 - 直接检查QQ应用是否安装
     */
    private fun checkQQInstallBackup(): Boolean {
        return try {
            Log.d("MainActivity", "开始备用QQ检测...")
            
            // 方法1：检查QQ应用包名
            val qqPackages = listOf(
                "com.tencent.mobileqq", // QQ主应用
                "com.tencent.mobileqqi", // QQ国际版
                "com.tencent.tim" // TIM
            )
            
            for (packageName in qqPackages) {
                try {
                    packageManager.getPackageInfo(packageName, 0)
                    Log.d("MainActivity", "找到QQ应用: $packageName")
                    return true
                } catch (e: Exception) {
                    Log.d("MainActivity", "未找到QQ应用: $packageName")
                }
            }
            
            // 方法2：检查QQ应用Intent
            val intent = packageManager.getLaunchIntentForPackage("com.tencent.mobileqq")
            if (intent != null) {
                Log.d("MainActivity", "通过Intent检测到QQ应用")
                return true
            }
            
            Log.d("MainActivity", "备用QQ检测结果: 未安装")
            false
        } catch (e: Exception) {
            Log.e("MainActivity", "备用QQ检测失败", e)
            false
        }
    }

    private fun umengShare(title: String, text: String, img: String, weburl: String, sharemedia: Int, result: MethodChannel.Result) {
        try {
            val shareMedia = when (sharemedia) {
                0 -> SHARE_MEDIA.WEIXIN // 微信好友
                1 -> SHARE_MEDIA.WEIXIN_CIRCLE // 微信朋友圈
                2 -> SHARE_MEDIA.QQ // QQ好友
                3 -> SHARE_MEDIA.QZONE // QQ空间
                else -> SHARE_MEDIA.WEIXIN
            }

            Log.d("MainActivity", "开始分享到平台: $shareMedia (code: $sharemedia)")
            Log.d("MainActivity", "分享参数: title=$title, text=$text, weburl=$weburl, img=$img")
            
            // 如果是QQ分享，先进行配置诊断
            if (sharemedia == 2 || sharemedia == 3) {
                diagnoseQQConfig()
            }
            
            // 检查平台是否安装
            val isInstalled = UMShareAPI.get(this).isInstall(this, shareMedia)
            Log.d("MainActivity", "平台是否安装: $isInstalled")
            
            if (!isInstalled) {
                val platformName = when (sharemedia) {
                    2, 3 -> "QQ"
                    0, 1 -> "微信"
                    else -> "未知平台"
                }
                result.success(mapOf("success" to false, "message" to "${platformName}未安装"))
                return
            }

            val shareAction = ShareAction(this).setPlatform(shareMedia)

            // 如果有网页链接，分享网页
            if (weburl.isNotEmpty()) {
                val web = UMWeb(weburl)
                web.title = title
                web.description = text
                if (img.isNotEmpty()) {
                    web.setThumb(UMImage(this, img))
                }
                shareAction.withMedia(web)
                Log.d("MainActivity", "分享网页内容")
            } else {
                // 分享纯文本
                shareAction.withText(text)
                Log.d("MainActivity", "分享纯文本内容")
            }

            shareAction.setCallback(object : UMShareListener {
                override fun onStart(platform: SHARE_MEDIA?) {
                    Log.d("MainActivity", "分享开始: platform=$platform")
                    
                    // 如果是QQ分享，在开始前再次确认权限设置
                    if (platform == SHARE_MEDIA.QQ || platform == SHARE_MEDIA.QZONE) {
                        try {
                            val tencentClass = Class.forName("com.tencent.tauth.Tencent")
                            val setIsPermissionGrantedMethod = tencentClass.getMethod("setIsPermissionGranted", Boolean::class.java)
                            setIsPermissionGrantedMethod.invoke(null, true)
                            Log.d("MainActivity", "QQ分享前权限确认成功")
                        } catch (e: Exception) {
                            Log.w("MainActivity", "QQ分享前权限确认失败: ${e.message}")
                        }
                    }
                }

                override fun onResult(platform: SHARE_MEDIA?) {
                    Log.d("MainActivity", "分享成功: platform=$platform")
                    result.success(mapOf("success" to true, "message" to "分享成功"))
                }

                override fun onError(platform: SHARE_MEDIA?, t: Throwable?) {
                    Log.e("MainActivity", "分享失败: platform=$platform, error=${t?.message}", t)
                    result.success(mapOf("success" to false, "message" to "分享失败: ${t?.message}"))
                }

                override fun onCancel(platform: SHARE_MEDIA?) {
                    Log.d("MainActivity", "分享取消: platform=$platform")
                    result.success(mapOf("success" to false, "message" to "分享取消"))
                }
            }).share()

        } catch (e: Exception) {
            Log.e("MainActivity", "分享异常", e)
            result.success(mapOf("success" to false, "message" to "分享异常: ${e.message}"))
        }
    }

    /**
     * QQ配置诊断方法
     * 用于检查QQ开放平台配置是否正确
     */
    private fun diagnoseQQConfig() {
        try {
            Log.d("MainActivity", "=== QQ配置诊断开始 ===")
            
            // 1. 检查应用包名
            val packageName = packageName
            Log.d("MainActivity", "应用包名: $packageName")
            
            // 2. 检查应用签名
            val packageInfo = packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
            val signatures = packageInfo.signatures
            if (signatures != null && signatures.isNotEmpty()) {
                val signature = signatures[0]
                val md = MessageDigest.getInstance("MD5")
                md.update(signature.toByteArray())
                val signatureHash = md.digest().joinToString("") { "%02x".format(it) }
                Log.d("MainActivity", "应用签名MD5: $signatureHash")
                Log.d("MainActivity", "请将此签名配置到QQ开放平台: $signatureHash")
                
                // 同时生成SHA1签名（某些平台可能需要）
                try {
                    val sha1 = MessageDigest.getInstance("SHA1")
                    sha1.update(signature.toByteArray())
                    val sha1Hash = sha1.digest().joinToString(":") { "%02x".format(it) }.uppercase()
                    Log.d("MainActivity", "应用签名SHA1: $sha1Hash")
                } catch (e: Exception) {
                    Log.w("MainActivity", "生成SHA1签名失败: ${e.message}")
                }
            }
            
            // 3. 检查QQ配置
            val qqAppId = "102797447"
            val qqAppKey = "c5KJ2VipiMRMCpJf"
            Log.d("MainActivity", "QQ AppID: $qqAppId")
            Log.d("MainActivity", "QQ AppKey: $qqAppKey")
            Log.d("MainActivity", "期望的AndroidManifest scheme: tencent$qqAppId")
            
            // 4. 检查QQ是否安装
            val qqInstalled = UMShareAPI.get(this).isInstall(this, SHARE_MEDIA.QQ)
            Log.d("MainActivity", "QQ是否安装: $qqInstalled")
            
            // 5. 检查QQ版本
            try {
                val qqPackageInfo = packageManager.getPackageInfo("com.tencent.mobileqq", 0)
                Log.d("MainActivity", "QQ版本: ${qqPackageInfo.versionName}")
            } catch (e: Exception) {
                Log.d("MainActivity", "无法获取QQ版本信息: ${e.message}")
            }
            
            Log.d("MainActivity", "如果仍然出现2003错误，请检查：")
            Log.d("MainActivity", "1. QQ开放平台应用是否已通过审核")
            Log.d("MainActivity", "2. 应用包名是否与QQ开放平台配置一致")
            Log.d("MainActivity", "3. 应用签名是否与QQ开放平台配置一致")
            Log.d("MainActivity", "4. QQ开放平台应用状态是否为'已上线'")
            Log.d("MainActivity", "5. AndroidManifest.xml中的scheme是否为 tencent$qqAppId 格式")
            
            Log.d("MainActivity", "=== QQ配置诊断完成 ===")
            
        } catch (e: Exception) {
            Log.e("MainActivity", "QQ配置诊断失败", e)
        }
    }

    /**
     * 修复QQ权限问题的综合方法
     * 针对2003错误进行多层修复
     */
    private fun fixQQPermissions() {
        try {
            Log.d("MainActivity", "开始修复QQ权限问题...")
            
            // 1. 强制设置QQ权限为已授权
            try {
                val tencentClass = Class.forName("com.tencent.tauth.Tencent")
                val setIsPermissionGrantedMethod = tencentClass.getMethod("setIsPermissionGranted", Boolean::class.java)
                setIsPermissionGrantedMethod.invoke(null, true)
                Log.d("MainActivity", "✓ QQ静态权限设置成功")
            } catch (e: Exception) {
                Log.w("MainActivity", "✗ QQ静态权限设置失败: ${e.message}")
            }
            
            // 2. 创建Tencent实例并设置权限
            try {
                val qqAppId = "102797447"
                val tencent = com.tencent.tauth.Tencent.createInstance(qqAppId, this, "com.yuluo.kissu.fileprovider")
                if (tencent != null) {
                    // 尝试通过实例方法设置权限
                    try {
                        val setPermissionMethod = tencent.javaClass.getMethod("setIsPermissionGranted", Boolean::class.java)
                        setPermissionMethod.invoke(tencent, true)
                        Log.d("MainActivity", "✓ QQ实例权限设置成功")
                    } catch (e: Exception) {
                        Log.w("MainActivity", "✗ QQ实例权限方法调用失败: ${e.message}")
                    }
                    
                    // 设置其他可能的权限标志
                    try {
                        val fields = tencent.javaClass.declaredFields
                        for (field in fields) {
                            if (field.name.contains("permission", ignoreCase = true) || 
                                field.name.contains("grant", ignoreCase = true)) {
                                field.isAccessible = true
                                if (field.type == Boolean::class.java || field.type == java.lang.Boolean::class.java) {
                                    field.set(tencent, true)
                                    Log.d("MainActivity", "✓ 设置权限字段 ${field.name} = true")
                                }
                            }
                        }
                    } catch (e: Exception) {
                        Log.w("MainActivity", "设置权限字段失败: ${e.message}")
                    }
                } else {
                    Log.w("MainActivity", "✗ 无法创建Tencent实例")
                }
            } catch (e: Exception) {
                Log.e("MainActivity", "✗ 创建Tencent实例失败: ${e.message}")
            }
            
            Log.d("MainActivity", "QQ权限修复完成")
            
        } catch (e: Exception) {
            Log.e("MainActivity", "QQ权限修复过程出错", e)
        }
    }

    // ===== 支付相关方法 =====
    private fun initWechatPay(appId: String) {
        try {
            wxApi = WXAPIFactory.createWXAPI(this, appId, true)
            wxApi?.registerApp(appId)
            Log.d("MainActivity", "微信支付初始化成功: $appId")
        } catch (e: Exception) {
            Log.e("MainActivity", "微信支付初始化失败", e)
        }
    }

    private fun isWechatAppInstalled(): Boolean {
        return try {
            wxApi?.isWXAppInstalled ?: false
        } catch (e: Exception) {
            false
        }
    }

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
        Log.d("MainActivity", "开始微信支付流程")
        Log.d("MainActivity", "wxApi是否为null: ${wxApi == null}")
        Log.d("MainActivity", "微信是否安装: ${wxApi?.isWXAppInstalled}")
        
        try {
            // 检查基本条件
            if (wxApi == null) {
                Log.e("MainActivity", "微信API未初始化")
                result.success(mapOf("success" to false, "message" to "微信API未初始化"))
                return
            }
            
            if (wxApi?.isWXAppInstalled != true) {
                Log.e("MainActivity", "微信未安装")
                result.success(mapOf("success" to false, "message" to "请先安装微信"))
                return
            }
            
            // 验证必要参数
            if (appId.isEmpty() || partnerId.isEmpty() || prepayId.isEmpty()) {
                Log.e("MainActivity", "微信支付参数不完整: appId=$appId, partnerId=$partnerId, prepayId=$prepayId")
                result.success(mapOf("success" to false, "message" to "微信支付参数不完整"))
                return
            }
            
            // 清理之前的回调状态（重要：防止状态污染）
            if (paymentResultCompleter != null) {
                Log.w("MainActivity", "检测到未清理的支付回调，先清理")
                paymentResultCompleter = null
            }
            
            // 设置支付结果回调，确保立即处理结果
            paymentResultCompleter = { success: Boolean, message: String ->
                Log.d("MainActivity", "微信支付完成: success=$success, message=$message")
                try {
                    result.success(mapOf("success" to success, "message" to message))
                } catch (e: Exception) {
                    Log.e("MainActivity", "返回支付结果失败", e)
                }
            }
            
            Log.d("MainActivity", "创建微信支付请求")
            val req = PayReq().apply {
                this.appId = appId
                this.partnerId = partnerId
                this.prepayId = prepayId
                this.packageValue = packageValue
                this.nonceStr = nonceStr
                this.timeStamp = timeStamp
                this.sign = sign
            }
            
            Log.d("MainActivity", "发送微信支付请求...")
            val sendResult = wxApi?.sendReq(req)
            Log.d("MainActivity", "微信支付请求发送结果: $sendResult")
            
            if (sendResult == true) {
                Log.d("MainActivity", "微信支付请求已发送，等待用户操作...")
                Log.d("MainActivity", "注意：此时不会立即返回支付结果，需要等待微信回调")
                // 不立即返回，等待WXPayEntryActivity的回调
                
                // 设置15秒超时，提高响应速度
                CoroutineScope(Dispatchers.Main).launch {
                    delay(15000) // 15秒超时
                    if (paymentResultCompleter != null) {
                        Log.w("MainActivity", "微信支付超时")
                        paymentResultCompleter?.invoke(false, "支付超时")
                        paymentResultCompleter = null
                    }
                }
            } else {
                Log.e("MainActivity", "微信支付请求发送失败，sendResult: $sendResult")
                paymentResultCompleter = null
                result.success(mapOf("success" to false, "message" to "微信支付请求发送失败"))
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "微信支付异常", e)
            paymentResultCompleter = null
            result.success(mapOf("success" to false, "message" to "微信支付失败: ${e.message}"))
        }
    }

    private fun isAlipayAppInstalled(): Boolean {
        return isAppInstalled("com.eg.android.AlipayGphone")
    }

    private fun payWithAlipay(orderInfo: String, result: MethodChannel.Result) {
        Log.d("MainActivity", "开始支付宝支付，orderInfo长度: ${orderInfo.length}")
        Log.d("MainActivity", "orderInfo前100字符: ${orderInfo.take(100)}...")
        
        if (orderInfo.isEmpty()) {
            Log.e("MainActivity", "支付宝订单信息为空")
            result.success(mapOf(
                "success" to false,
                "message" to "支付宝订单信息为空"
            ))
            return
        }
        
        CoroutineScope(Dispatchers.IO).launch {
            try {
                Log.d("MainActivity", "创建PayTask并调用支付")
                val payTask = PayTask(this@MainActivity)
                Log.d("MainActivity", "PayTask创建成功，开始调用payV2")
                
                val payResult = payTask.payV2(orderInfo, true)
                Log.d("MainActivity", "支付宝支付完成，返回结果类型: ${payResult.javaClass.simpleName}")
                Log.d("MainActivity", "支付宝支付返回结果: $payResult")
                
                withContext(Dispatchers.Main) {
                    // 解析支付结果
                    val resultStatus = parseAlipayResult(payResult)
                    Log.d("MainActivity", "解析后的支付结果: success=${resultStatus.success}, message=${resultStatus.message}")
                    
                    result.success(mapOf(
                        "success" to resultStatus.success,
                        "message" to resultStatus.message,
                        "result" to payResult.toString()
                    ))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    Log.e("MainActivity", "支付宝支付异常", e)
                    Log.e("MainActivity", "异常类型: ${e.javaClass.simpleName}")
                    Log.e("MainActivity", "异常消息: ${e.message}")
                    Log.e("MainActivity", "异常堆栈: ${e.stackTraceToString()}")
                    
                    result.success(mapOf(
                        "success" to false,
                        "message" to "支付失败: ${e.message}",
                        "error" to e.javaClass.simpleName
                    ))
                }
            }
        }
    }
    
    private data class AlipayResult(val success: Boolean, val message: String)
    
    private fun parseAlipayResult(payResult: Map<String, String>): AlipayResult {
        val resultStatus = payResult["resultStatus"]
        Log.d("MainActivity", "解析支付宝支付结果: resultStatus=$resultStatus, 完整结果=$payResult")
        
        return when (resultStatus) {
            "9000" -> {
                Log.d("MainActivity", "支付宝支付成功")
                AlipayResult(true, "支付成功")
            }
            "8000" -> {
                Log.d("MainActivity", "支付宝支付结果确认中")
                AlipayResult(false, "支付结果确认中")
            }
            "4000" -> {
                Log.d("MainActivity", "支付宝订单支付失败")
                AlipayResult(false, "订单支付失败")
            }
            "5000" -> {
                Log.d("MainActivity", "支付宝重复请求")
                AlipayResult(false, "重复请求")
            }
            "6001" -> {
                Log.d("MainActivity", "支付宝用户取消支付")
                AlipayResult(false, "用户中途取消")
            }
            "6002" -> {
                Log.d("MainActivity", "支付宝网络连接出错")
                AlipayResult(false, "网络连接出错")
            }
            "6004" -> {
                Log.d("MainActivity", "支付宝支付结果未知")
                AlipayResult(false, "支付结果未知，其它支付结果")
            }
            else -> {
                Log.e("MainActivity", "支付宝未知支付状态: $resultStatus")
                AlipayResult(false, "未知支付状态: $resultStatus")
            }
        }
    }

    // 微信支付回调
    override fun onReq(req: com.tencent.mm.opensdk.modelbase.BaseReq?) {
        // 通常不需要处理
    }

    override fun onResp(resp: BaseResp?) {
        when (resp?.type) {
            ConstantsAPI.COMMAND_PAY_BY_WX -> {
                val payResp = resp as PayResp
                when (payResp.errCode) {
                    BaseResp.ErrCode.ERR_OK -> {
                        Log.d("MainActivity", "微信支付成功")
                        // 通知Flutter支付成功
                        paymentResultCompleter?.invoke(true, "支付成功")
                        paymentResultCompleter = null
                    }
                    BaseResp.ErrCode.ERR_USER_CANCEL -> {
                        Log.d("MainActivity", "微信支付取消")
                        // 通知Flutter支付取消
                        paymentResultCompleter?.invoke(false, "用户取消支付")
                        paymentResultCompleter = null
                    }
                    BaseResp.ErrCode.ERR_COMM -> {
                        Log.e("MainActivity", "微信支付失败")
                        // 通知Flutter支付失败
                        paymentResultCompleter?.invoke(false, "支付失败")
                        paymentResultCompleter = null
                    }
                    else -> {
                        Log.e("MainActivity", "微信支付未知错误: ${payResp.errCode}")
                        // 通知Flutter支付失败
                        paymentResultCompleter?.invoke(false, "支付失败，错误码: ${payResp.errCode}")
                        paymentResultCompleter = null
                    }
                }
            }
        }
    }

    /**
     * 打印应用签名SHA1值，用于高德地图等服务配置
     */
    private fun printSHA1() {
        try {
            val packageInfo = packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
            for (signature in packageInfo.signatures ?: emptyArray()) {
                val md = MessageDigest.getInstance("SHA1")
                md.update(signature.toByteArray())
                val sha1 = md.digest().joinToString(":") { "%02X".format(it) }
                Log.d("MainActivity", "应用SHA1签名: $sha1")
            }
        } catch (e: NoSuchAlgorithmException) {
            Log.e("MainActivity", "无法获取SHA1", e)
        } catch (e: Exception) {
            Log.e("MainActivity", "获取签名失败", e)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        UMShareAPI.get(this).onActivityResult(requestCode, resultCode, data)
        
        // 处理微信支付回调
        if (wxApi != null) {
            wxApi!!.handleIntent(data, this)
        }
    }
}