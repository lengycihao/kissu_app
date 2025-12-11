package com.yuluo.kissu.handlers

import android.app.Activity
import android.content.Intent
import android.util.Log
import com.umeng.commonsdk.UMConfigure
import com.umeng.socialize.PlatformConfig
import com.umeng.socialize.ShareAction
import com.umeng.socialize.UMShareAPI
import com.umeng.socialize.UMShareListener
import com.umeng.socialize.bean.SHARE_MEDIA
import com.umeng.socialize.media.UMImage
import com.umeng.socialize.media.UMWeb
import io.flutter.plugin.common.MethodChannel
import java.net.URLEncoder

/**
 * 分享处理器
 * 负责处理友盟分享功能
 */
class ShareHandler(private val activity: Activity) {
    
    companion object {
        private const val TAG = "ShareHandler"
    }
    
    /**
     * 处理分享方法调用
     */
    fun handleMethodCall(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            // 友盟分享 SDK 初始化（Flutter 侧在用户同意隐私之后调用）
            // 目前主要依赖统计侧的 UMConfigure.init，这里不重复初始化，只做日志标记
            "umInit" -> {
                Log.d(TAG, "收到 umInit 调用（初始化在 AnalyticsHandler 中统一处理）")
                result.success(null)
            }

            // 配置微信 / QQ 平台
            // 为了不影响现有功能，这里仍然使用原来在 MainActivity.initUmeng 中的固定配置
            "platformConfig" -> {
                try {
                    // 微信配置
                    PlatformConfig.setWeixin(
                        "wxca15128b8c388c13",
                        "e0d2d1e8c3f4e5f6a7b8c9d0e1f2a3b4"
                    )

                    // QQ / QQ 空间配置
                    PlatformConfig.setQQZone(
                        "102797447",
                        "c5KJ2VipiMRMCpJf"
                    )

                    Log.d(TAG, "友盟分享平台配置完成（WeChat / QQ）")
                } catch (e: Exception) {
                    Log.e(TAG, "配置友盟分享平台失败", e)
                }
                result.success(null)
            }

            // 设置隐私政策授权状态（目前授权结果主要在 AnalyticsHandler 中提交，这里仅做日志）
            "setPrivacyPolicy" -> {
                val granted = call.argument<Boolean>("granted") ?: false
                try {
                    UMConfigure.submitPolicyGrantResult(activity.applicationContext, granted)
                    Log.d(TAG, "友盟分享隐私授权状态已设置: granted=$granted")
                } catch (e: Exception) {
                    Log.e(TAG, "设置友盟分享隐私授权状态失败", e)
                }
                result.success(null)
            }

            "umCheckInstall" -> {
                // 检查平台是否安装
                val platform = call.argument<Int>("platform") ?: 0
                val isInstalled = checkPlatformInstall(platform)
                Log.d(TAG, "检查平台安装: platform=$platform, isInstalled=$isInstalled")
                result.success(mapOf("isInstalled" to isInstalled))
            }
            "checkQQInstallBackup" -> {
                // 备用QQ检测方法
                val isInstalled = checkQQInstallBackup()
                Log.d(TAG, "备用QQ检测: isInstalled=$isInstalled")
                result.success(mapOf("isInstalled" to isInstalled))
            }
            "umShare" -> {
                // 友盟分享统一入口
                val title = call.argument<String>("title") ?: ""
                val description = call.argument<String>("text") ?: ""
                val imageUrl = call.argument<String>("img") ?: ""
                val webUrl = call.argument<String>("weburl") ?: ""
                val shareMedia = call.argument<Int>("sharemedia") ?: 0
                
                Log.d(TAG, "umShare调用: sharemedia=$shareMedia, title=$title")
                
                when (shareMedia) {
                    0 -> shareToWechat(title, description, imageUrl, webUrl, 0, result) // 微信好友
                    1 -> shareToWechat(title, description, imageUrl, webUrl, 1, result) // 微信朋友圈
                    2 -> shareToQQ(title, description, imageUrl, webUrl, result) // QQ好友
                    3 -> shareToQQZone(title, description, imageUrl, webUrl, result) // QQ空间
                    else -> {
                        Log.e(TAG, "未知的分享平台: $shareMedia")
                        result.success(mapOf("success" to false, "message" to "未知的分享平台"))
                    }
                }
            }
            "shareToWechat" -> {
                val title = call.argument<String>("title") ?: ""
                val description = call.argument<String>("description") ?: ""
                val imageUrl = call.argument<String>("imageUrl") ?: ""
                val webUrl = call.argument<String>("webUrl") ?: ""
                val scene = call.argument<Int>("scene") ?: 0
                
                shareToWechat(title, description, imageUrl, webUrl, scene, result)
            }
            "shareToQQ" -> {
                val title = call.argument<String>("title") ?: ""
                val description = call.argument<String>("description") ?: ""
                val imageUrl = call.argument<String>("imageUrl") ?: ""
                val webUrl = call.argument<String>("webUrl") ?: ""
                
                shareToQQ(title, description, imageUrl, webUrl, result)
            }
            "shareToQQZone" -> {
                val title = call.argument<String>("title") ?: ""
                val description = call.argument<String>("description") ?: ""
                val imageUrl = call.argument<String>("imageUrl") ?: ""
                val webUrl = call.argument<String>("webUrl") ?: ""
                
                shareToQQZone(title, description, imageUrl, webUrl, result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }
    
    /**
     * 分享到微信
     */
    private fun shareToWechat(
        title: String,
        description: String,
        imageUrl: String,
        webUrl: String,
        scene: Int,
        result: MethodChannel.Result
    ) {
        try {
            Log.d(TAG, "分享到微信: title=$title, scene=$scene")
            
            val web = UMWeb(webUrl)
            web.title = title
            web.description = description
            web.setThumb(UMImage(activity, imageUrl))
            
            val platform = if (scene == 0) SHARE_MEDIA.WEIXIN else SHARE_MEDIA.WEIXIN_CIRCLE
            
            ShareAction(activity)
                .setPlatform(platform)
                .withMedia(web)
                .setCallback(object : UMShareListener {
                    override fun onStart(platform: SHARE_MEDIA?) {
                        Log.d(TAG, "分享开始: $platform")
                    }
                    
                    override fun onResult(platform: SHARE_MEDIA?) {
                        Log.d(TAG, "分享成功: $platform")
                        result.success(mapOf("success" to true, "message" to "分享成功"))
                    }
                    
                    override fun onError(platform: SHARE_MEDIA?, t: Throwable?) {
                        Log.e(TAG, "分享失败: $platform", t)
                        result.success(mapOf("success" to false, "message" to "分享失败: ${t?.message}"))
                    }
                    
                    override fun onCancel(platform: SHARE_MEDIA?) {
                        Log.d(TAG, "分享取消: $platform")
                        result.success(mapOf("success" to false, "message" to "用户取消分享"))
                    }
                })
                .share()
        } catch (e: Exception) {
            Log.e(TAG, "分享到微信异常", e)
            result.success(mapOf("success" to false, "message" to "分享失败: ${e.message}"))
        }
    }
    
    /**
     * 分享到QQ
     */
    private fun shareToQQ(
        title: String,
        description: String,
        imageUrl: String,
        webUrl: String,
        result: MethodChannel.Result
    ) {
        try {
            Log.d(TAG, "分享到QQ: title=$title")
            
            // 🔥 关键修复：在分享前设置QQ权限（解决2003错误）
            try {
                val tencentClass = Class.forName("com.tencent.tauth.Tencent")
                val setIsPermissionGrantedMethod = tencentClass.getMethod("setIsPermissionGranted", Boolean::class.java)
                setIsPermissionGrantedMethod.invoke(null, true)
                Log.d(TAG, "✅ QQ分享权限预设置成功")
            } catch (e: Exception) {
                Log.w(TAG, "⚠️ QQ分享权限预设置失败: ${e.message}")
            }
            
            val web = UMWeb(webUrl)
            web.title = title
            web.description = description
            web.setThumb(UMImage(activity, imageUrl))
            
            ShareAction(activity)
                .setPlatform(SHARE_MEDIA.QQ)
                .withMedia(web)
                .setCallback(object : UMShareListener {
                    override fun onStart(platform: SHARE_MEDIA?) {
                        Log.d(TAG, "分享开始: $platform")
                        
                        // 🔥 关键修复：如果是QQ分享，在开始前设置权限（解决2003错误）
                        if (platform == SHARE_MEDIA.QQ || platform == SHARE_MEDIA.QZONE) {
                            try {
                                val tencentClass = Class.forName("com.tencent.tauth.Tencent")
                                val setIsPermissionGrantedMethod = tencentClass.getMethod("setIsPermissionGranted", Boolean::class.java)
                                setIsPermissionGrantedMethod.invoke(null, true)
                                Log.d(TAG, "✅ QQ分享前权限设置成功")
                            } catch (e: Exception) {
                                Log.w(TAG, "⚠️ QQ分享前权限设置失败: ${e.message}")
                            }
                        }
                    }
                    
                    override fun onResult(platform: SHARE_MEDIA?) {
                        Log.d(TAG, "分享成功: $platform")
                        result.success(mapOf("success" to true, "message" to "分享成功"))
                    }
                    
                    override fun onError(platform: SHARE_MEDIA?, t: Throwable?) {
                        Log.e(TAG, "分享失败: $platform", t)
                        result.success(mapOf("success" to false, "message" to "分享失败: ${t?.message}"))
                    }
                    
                    override fun onCancel(platform: SHARE_MEDIA?) {
                        Log.d(TAG, "分享取消: $platform")
                        result.success(mapOf("success" to false, "message" to "用户取消分享"))
                    }
                })
                .share()
        } catch (e: Exception) {
            Log.e(TAG, "分享到QQ异常", e)
            result.success(mapOf("success" to false, "message" to "分享失败: ${e.message}"))
        }
    }
    
    /**
     * 分享到QQ空间
     */
    private fun shareToQQZone(
        title: String,
        description: String,
        imageUrl: String,
        webUrl: String,
        result: MethodChannel.Result
    ) {
        try {
            Log.d(TAG, "分享到QQ空间: title=$title")
            
            // 🔥 关键修复：在分享前设置QQ权限（解决2003错误）
            try {
                val tencentClass = Class.forName("com.tencent.tauth.Tencent")
                val setIsPermissionGrantedMethod = tencentClass.getMethod("setIsPermissionGranted", Boolean::class.java)
                setIsPermissionGrantedMethod.invoke(null, true)
                Log.d(TAG, "✅ QQ空间分享权限预设置成功")
            } catch (e: Exception) {
                Log.w(TAG, "⚠️ QQ空间分享权限预设置失败: ${e.message}")
            }
            
            val web = UMWeb(webUrl)
            web.title = title
            web.description = description
            web.setThumb(UMImage(activity, imageUrl))
            
            ShareAction(activity)
                .setPlatform(SHARE_MEDIA.QZONE)
                .withMedia(web)
                .setCallback(object : UMShareListener {
                    override fun onStart(platform: SHARE_MEDIA?) {
                        Log.d(TAG, "分享开始: $platform")
                        
                        // 🔥 关键修复：如果是QQ分享，在开始前设置权限（解决2003错误）
                        if (platform == SHARE_MEDIA.QQ || platform == SHARE_MEDIA.QZONE) {
                            try {
                                val tencentClass = Class.forName("com.tencent.tauth.Tencent")
                                val setIsPermissionGrantedMethod = tencentClass.getMethod("setIsPermissionGranted", Boolean::class.java)
                                setIsPermissionGrantedMethod.invoke(null, true)
                                Log.d(TAG, "✅ QQ空间分享前权限设置成功")
                            } catch (e: Exception) {
                                Log.w(TAG, "⚠️ QQ空间分享前权限设置失败: ${e.message}")
                            }
                        }
                    }
                    
                    override fun onResult(platform: SHARE_MEDIA?) {
                        Log.d(TAG, "分享成功: $platform")
                        result.success(mapOf("success" to true, "message" to "分享成功"))
                    }
                    
                    override fun onError(platform: SHARE_MEDIA?, t: Throwable?) {
                        Log.e(TAG, "分享失败: $platform", t)
                        result.success(mapOf("success" to false, "message" to "分享失败: ${t?.message}"))
                    }
                    
                    override fun onCancel(platform: SHARE_MEDIA?) {
                        Log.d(TAG, "分享取消: $platform")
                        result.success(mapOf("success" to false, "message" to "用户取消分享"))
                    }
                })
                .share()
        } catch (e: Exception) {
            Log.e(TAG, "分享到QQ空间异常", e)
            result.success(mapOf("success" to false, "message" to "分享失败: ${e.message}"))
        }
    }
    
    /**
     * 检查平台是否安装
     */
    private fun checkPlatformInstall(platform: Int): Boolean {
        return try {
            val shareMedia = when (platform) {
                0 -> SHARE_MEDIA.WEIXIN // 微信
                1 -> SHARE_MEDIA.QQ // QQ
                2 -> SHARE_MEDIA.QZONE // QQ空间
                3 -> SHARE_MEDIA.WEIXIN_CIRCLE // 微信朋友圈
                else -> SHARE_MEDIA.WEIXIN
            }
            val result = UMShareAPI.get(activity).isInstall(activity, shareMedia)
            Log.d(TAG, "友盟检测平台安装状态: platform=$platform, result=$result")
            result
        } catch (e: Exception) {
            Log.e(TAG, "友盟检测平台安装状态失败", e)
            false
        }
    }
    
    /**
     * 备用QQ检测方法 - 直接检查QQ应用是否安装
     */
    private fun checkQQInstallBackup(): Boolean {
        return try {
            Log.d(TAG, "开始备用QQ检测...")
            
            // 方法1：检查QQ应用包名
            val qqPackages = listOf(
                "com.tencent.mobileqq", // QQ主应用
                "com.tencent.mobileqqi", // QQ国际版
                "com.tencent.tim" // TIM
            )
            
            for (packageName in qqPackages) {
                try {
                    activity.packageManager.getPackageInfo(packageName, 0)
                    Log.d(TAG, "找到QQ应用: $packageName")
                    return true
                } catch (e: Exception) {
                    Log.d(TAG, "未找到QQ应用: $packageName")
                }
            }
            
            // 方法2：检查QQ应用Intent
            val intent = activity.packageManager.getLaunchIntentForPackage("com.tencent.mobileqq")
            if (intent != null) {
                Log.d(TAG, "通过Intent检测到QQ应用")
                return true
            }
            
            Log.d(TAG, "备用QQ检测结果: 未安装")
            false
        } catch (e: Exception) {
            Log.e(TAG, "备用QQ检测失败", e)
            false
        }
    }
    
    /**
     * 分享文本到微信（直接调用微信）
     */
    fun shareTextToWeChat(text: String, result: MethodChannel.Result) {
        val wechatPkg = "com.tencent.mm"
        if (!isAppInstalled(wechatPkg)) {
            result.success(false)
            return
        }
        
        try {
            // WeChat supports ACTION_SEND with text/plain
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, text)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                `package` = wechatPkg
            }
            activity.startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "分享文本到微信失败", e)
            result.success(false)
        }
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
     * 处理Activity结果
     */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?) {
        UMShareAPI.get(activity).onActivityResult(requestCode, resultCode, data)
    }
}
