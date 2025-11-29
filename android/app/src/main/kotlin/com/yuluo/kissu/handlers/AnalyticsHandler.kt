package com.yuluo.kissu.handlers

import android.app.Activity
import android.util.Log
import com.umeng.analytics.MobclickAgent
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
