package com.yuluo.kissu.handlers

import android.app.Activity
import android.util.Log
import com.umeng.analytics.MobclickAgent
import com.umeng.commonsdk.UMConfigure
import io.flutter.plugin.common.MethodChannel

/**
 * 友盟统计处理器
 * 负责处理友盟统计事件上报
 */
class AnalyticsHandler(private val activity: Activity) {
    
    companion object {
        private const val TAG = "AnalyticsHandler"
    }
    
    /**
     * 处理友盟统计方法调用
     */
    fun handleMethodCall(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            // 友盟初始化（由 Flutter 侧在用户同意隐私政策后调用）
            "umeng_init" -> {
                val appKey = call.argument<String>("appKey") ?: "6879fba679267e0210b67bde"
                val channel = call.argument<String>("channel") ?: "Umeng"
                val logEnabled = call.argument<Boolean>("logEnabled") ?: false

                try {
                    UMConfigure.init(
                        activity.applicationContext,
                        appKey,
                        channel,
                        UMConfigure.DEVICE_TYPE_PHONE,
                        null
                    )
                    UMConfigure.setLogEnabled(logEnabled)
                    Log.d(TAG, "友盟初始化完成: appKey=$appKey, channel=$channel, logEnabled=$logEnabled")
                } catch (e: Exception) {
                    Log.e(TAG, "友盟初始化失败", e)
                }
                result.success(null)
            }

            // 提交隐私政策授权结果（由 Flutter 侧在用户同意/拒绝后调用）
            "umeng_submitPolicyGrantResult" -> {
                val granted = call.argument<Boolean>("granted") ?: false
                try {
                    // 仅在 SDK 支持的情况下调用提交授权结果接口
                    UMConfigure.submitPolicyGrantResult(activity.applicationContext, granted)
                    Log.d(TAG, "友盟隐私授权结果已提交: granted=$granted")
                } catch (e: Exception) {
                    Log.e(TAG, "提交友盟隐私授权结果失败", e)
                }
                result.success(null)
            }

            "onEvent" -> {
                val eventId = call.argument<String>("eventId") ?: ""
                val eventLabel = call.argument<String>("eventLabel")
                
                if (eventLabel != null) {
                    MobclickAgent.onEvent(activity, eventId, eventLabel)
                } else {
                    MobclickAgent.onEvent(activity, eventId)
                }
                
                Log.d(TAG, "友盟事件上报: $eventId, label: $eventLabel")
                result.success(null)
            }
            "onEventWithMap" -> {
                val eventId = call.argument<String>("eventId") ?: ""
                @Suppress("UNCHECKED_CAST")
                val map = call.argument<Map<String, String>>("map") ?: emptyMap()
                
                MobclickAgent.onEvent(activity, eventId, map)
                Log.d(TAG, "友盟事件上报(带参数): $eventId, params: $map")
                result.success(null)
            }
            "onPageStart" -> {
                val pageName = call.argument<String>("pageName") ?: ""
                MobclickAgent.onPageStart(pageName)
                Log.d(TAG, "友盟页面开始: $pageName")
                result.success(null)
            }
            "onPageEnd" -> {
                val pageName = call.argument<String>("pageName") ?: ""
                MobclickAgent.onPageEnd(pageName)
                Log.d(TAG, "友盟页面结束: $pageName")
                result.success(null)
            }
            "setUserProfile" -> {
                val userId = call.argument<String>("userId") ?: ""
                if (userId.isNotEmpty()) {
                    MobclickAgent.onProfileSignIn(userId)
                    Log.d(TAG, "友盟用户登录: $userId")
                }
                result.success(null)
            }
            else -> {
                result.notImplemented()
            }
        }
    }
    
    /**
     * Activity Resume时调用
     */
    fun onResume() {
        MobclickAgent.onResume(activity)
    }
    
    /**
     * Activity Pause时调用
     */
    fun onPause() {
        MobclickAgent.onPause(activity)
    }
}
