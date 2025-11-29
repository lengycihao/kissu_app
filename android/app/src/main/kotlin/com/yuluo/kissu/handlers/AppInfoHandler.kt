package com.yuluo.kissu.handlers

import android.app.Activity
import android.content.ComponentName
import android.content.pm.PackageManager
import android.util.Log
import io.flutter.plugin.common.MethodChannel

/**
 * 应用信息处理器
 * 负责处理应用名称获取、应用图标切换等功能
 */
class AppInfoHandler(private val activity: Activity) {
    
    companion object {
        private const val TAG = "AppInfoHandler"
    }
    
    /**
     * 处理应用信息方法调用
     */
    fun handleMethodCall(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getAppName" -> {
                val packageName = call.argument<String>("packageName") ?: ""
                result.success(getAppName(packageName))
            }
            "getAppNames" -> {
                val packageNames = call.argument<List<String>>("packageNames") ?: emptyList()
                result.success(getAppNames(packageNames))
            }
            "changeAppIcon" -> {
                val iconType = call.argument<String>("iconType") ?: "default"
                changeAppIcon(iconType, result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }
    
    /**
     * 获取单个应用名称
     */
    private fun getAppName(packageName: String): String {
        return try {
            val pm = activity.packageManager
            val appInfo = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(appInfo).toString()
        } catch (e: Exception) {
            Log.w(TAG, "获取应用名称失败: $packageName", e)
            packageName.split(".").lastOrNull() ?: packageName
        }
    }
    
    /**
     * 批量获取应用名称
     */
    private fun getAppNames(packageNames: List<String>): Map<String, String> {
        val result = mutableMapOf<String, String>()
        val pm = activity.packageManager
        
        for (packageName in packageNames) {
            try {
                val appInfo = pm.getApplicationInfo(packageName, 0)
                val appName = pm.getApplicationLabel(appInfo).toString()
                result[packageName] = appName
            } catch (e: Exception) {
                Log.w(TAG, "获取应用名称失败: $packageName", e)
                result[packageName] = packageName.split(".").lastOrNull() ?: packageName
            }
        }
        
        return result
    }
    
    /**
     * 切换应用图标
     */
    private fun changeAppIcon(iconType: String, result: MethodChannel.Result) {
        try {
            val pm = activity.packageManager
            val packageName = activity.packageName
            
            // 定义所有可能的图标别名
            val iconAliases = mapOf(
                "default" to "$packageName.MainActivityDefault",
                "one" to "$packageName.MainActivityLogoOne"
            )
            
            // 禁用所有其他图标
            iconAliases.forEach { (type, alias) ->
                val state = if (type == iconType) {
                    PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                } else {
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED
                }
                
                pm.setComponentEnabledSetting(
                    ComponentName(packageName, alias),
                    state,
                    PackageManager.DONT_KILL_APP
                )
            }
            
            Log.d(TAG, "应用图标已切换为: $iconType")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "切换应用图标失败", e)
            result.success(false)
        }
    }
}
