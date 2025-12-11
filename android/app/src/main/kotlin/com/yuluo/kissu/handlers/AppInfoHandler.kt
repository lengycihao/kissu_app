// package com.yuluo.kissu.handlers

// import android.app.Activity
// import android.content.pm.PackageManager
// import android.util.Log
// import io.flutter.plugin.common.MethodChannel

// /**
//  * 应用信息处理器
//  * 负责处理应用名称获取等功能
//  */
// class AppInfoHandler(private val activity: Activity) {
    
//     companion object {
//         private const val TAG = "AppInfoHandler"
//     }
    
//     /**
//      * 处理应用信息方法调用
//      */
//     fun handleMethodCall(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
//         when (call.method) {
//             "getAppName" -> {
//                 val packageName = call.argument<String>("packageName") ?: ""
//                 result.success(getAppName(packageName))
//             }
//             "getAppNames" -> {
//                 val packageNames = call.argument<List<String>>("packageNames") ?: emptyList()
//                 result.success(getAppNames(packageNames))
//             }
//             "changeIcon", "changeAppIcon" -> {
//                 // 🚫 动态切换logo功能已删除
//                 Log.w(TAG, "动态切换logo功能已删除，拒绝切换请求")
//                 result.success(false)
//             }
//             "getCurrentIcon" -> {
//                 // 🚫 动态切换logo功能已删除，始终返回默认图标
//                 result.success("default")
//             }
//             else -> {
//                 result.notImplemented()
//             }
//         }
//     }
    
//     /**
//      * 获取单个应用名称
//      */
//     private fun getAppName(packageName: String): String {
//         return try {
//             val pm = activity.packageManager
//             val appInfo = pm.getApplicationInfo(packageName, 0)
//             pm.getApplicationLabel(appInfo).toString()
//         } catch (e: Exception) {
//             Log.w(TAG, "获取应用名称失败: $packageName", e)
//             packageName.split(".").lastOrNull() ?: packageName
//         }
//     }
    
//     /**
//      * 批量获取应用名称
//      */
//     private fun getAppNames(packageNames: List<String>): Map<String, String> {
//         val result = mutableMapOf<String, String>()
//         val pm = activity.packageManager
        
//         for (packageName in packageNames) {
//             try {
//                 val appInfo = pm.getApplicationInfo(packageName, 0)
//                 val appName = pm.getApplicationLabel(appInfo).toString()
//                 result[packageName] = appName
//             } catch (e: Exception) {
//                 Log.w(TAG, "获取应用名称失败: $packageName", e)
//                 result[packageName] = packageName.split(".").lastOrNull() ?: packageName
//             }
//         }
        
//         return result
//     }
    
// }
