package com.yuluo.kissu

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.util.Log

/**
 * 设备厂商白名单引导工具
 * 
 * 针对不同厂商手机，提供一键跳转到后台运行白名单设置页面
 * 解决国产手机厂商后台限制导致的APP被杀问题
 */
object DeviceWhitelistHelper {
    
    private const val TAG = "DeviceWhitelistHelper"
    
    /**
     * 设备厂商枚举
     */
    enum class Manufacturer {
        XIAOMI,      // 小米/红米
        HUAWEI,      // 华为
        HONOR,       // 荣耀
        OPPO,        // OPPO
        VIVO,        // VIVO
        REALME,      // realme
        ONEPLUS,     // 一加
        SAMSUNG,     // 三星
        MEIZU,       // 魅族
        LENOVO,      // 联想
        ASUS,        // 华硕
        ZTE,         // 中兴
        NUBIA,       // 努比亚
        COOLPAD,     // 酷派
        GIONEE,      // 金立
        UNKNOWN      // 未知厂商
    }
    
    /**
     * 获取设备厂商
     */
    fun getManufacturer(): Manufacturer {
        val brand = Build.BRAND.lowercase()
        val manufacturer = Build.MANUFACTURER.lowercase()
        
        return when {
            brand.contains("xiaomi") || brand.contains("redmi") || manufacturer.contains("xiaomi") -> Manufacturer.XIAOMI
            brand.contains("huawei") || manufacturer.contains("huawei") -> Manufacturer.HUAWEI
            brand.contains("honor") || manufacturer.contains("honor") -> Manufacturer.HONOR
            brand.contains("oppo") || manufacturer.contains("oppo") -> Manufacturer.OPPO
            brand.contains("vivo") || manufacturer.contains("vivo") -> Manufacturer.VIVO
            brand.contains("realme") || manufacturer.contains("realme") -> Manufacturer.REALME
            brand.contains("oneplus") || manufacturer.contains("oneplus") -> Manufacturer.ONEPLUS
            brand.contains("samsung") || manufacturer.contains("samsung") -> Manufacturer.SAMSUNG
            brand.contains("meizu") || manufacturer.contains("meizu") -> Manufacturer.MEIZU
            brand.contains("lenovo") || manufacturer.contains("lenovo") -> Manufacturer.LENOVO
            brand.contains("asus") || manufacturer.contains("asus") -> Manufacturer.ASUS
            brand.contains("zte") || manufacturer.contains("zte") -> Manufacturer.ZTE
            brand.contains("nubia") || manufacturer.contains("nubia") -> Manufacturer.NUBIA
            brand.contains("coolpad") || manufacturer.contains("coolpad") -> Manufacturer.COOLPAD
            brand.contains("gionee") || manufacturer.contains("gionee") -> Manufacturer.GIONEE
            else -> Manufacturer.UNKNOWN
        }
    }
    
    /**
     * 获取厂商名称（中文）
     */
    fun getManufacturerName(): String {
        return when (getManufacturer()) {
            Manufacturer.XIAOMI -> "小米"
            Manufacturer.HUAWEI -> "华为"
            Manufacturer.HONOR -> "荣耀"
            Manufacturer.OPPO -> "OPPO"
            Manufacturer.VIVO -> "VIVO"
            Manufacturer.REALME -> "realme"
            Manufacturer.ONEPLUS -> "一加"
            Manufacturer.SAMSUNG -> "三星"
            Manufacturer.MEIZU -> "魅族"
            Manufacturer.LENOVO -> "联想"
            Manufacturer.ASUS -> "华硕"
            Manufacturer.ZTE -> "中兴"
            Manufacturer.NUBIA -> "努比亚"
            Manufacturer.COOLPAD -> "酷派"
            Manufacturer.GIONEE -> "金立"
            Manufacturer.UNKNOWN -> "其他"
        }
    }
    
    /**
     * 是否需要引导用户设置白名单
     * 
     * 国产手机通常需要，三星等不需要
     */
    fun needsWhitelistGuidance(): Boolean {
        return when (getManufacturer()) {
            Manufacturer.XIAOMI,
            Manufacturer.HUAWEI,
            Manufacturer.HONOR,
            Manufacturer.OPPO,
            Manufacturer.VIVO,
            Manufacturer.REALME,
            Manufacturer.ONEPLUS,
            Manufacturer.MEIZU,
            Manufacturer.ASUS -> true
            else -> false
        }
    }
    
    /**
     * 获取引导文本
     */
    fun getGuidanceText(): String {
        val manufacturerName = getManufacturerName()
        return when (getManufacturer()) {
            Manufacturer.XIAOMI -> 
                "为确保定位服务稳定运行，请在${manufacturerName}手机设置中：\n" +
                "1. 将本应用添加到【后台自启动】白名单\n" +
                "2. 关闭【省电优化】\n" +
                "3. 设置为【无限制】模式"
            
            Manufacturer.HUAWEI, Manufacturer.HONOR -> 
                "为确保定位服务稳定运行，请在${manufacturerName}手机设置中：\n" +
                "1. 将本应用添加到【应用启动管理】白名单\n" +
                "2. 开启【自动管理】或手动设置【允许】\n" +
                "3. 关闭【省电优化】"
            
            Manufacturer.OPPO, Manufacturer.REALME -> 
                "为确保定位服务稳定运行，请在${manufacturerName}手机设置中：\n" +
                "1. 将本应用添加到【自启动管理】白名单\n" +
                "2. 关闭【后台冻结】\n" +
                "3. 设置为【允许后台运行】"
            
            Manufacturer.VIVO -> 
                "为确保定位服务稳定运行，请在${manufacturerName}手机设置中：\n" +
                "1. 将本应用添加到【后台高耗电】白名单\n" +
                "2. 开启【允许自启动】\n" +
                "3. 关闭【后台冻结】"
            
            Manufacturer.ONEPLUS -> 
                "为确保定位服务稳定运行，请在${manufacturerName}手机设置中：\n" +
                "1. 关闭【电池优化】\n" +
                "2. 开启【允许后台运行】\n" +
                "3. 设置为【无限制】模式"
            
            Manufacturer.MEIZU -> 
                "为确保定位服务稳定运行，请在${manufacturerName}手机设置中：\n" +
                "1. 将本应用添加到【后台管理】白名单\n" +
                "2. 开启【待机时保持运行】\n" +
                "3. 关闭【省电优化】"
            
            else -> 
                "为确保定位服务稳定运行，建议在系统设置中：\n" +
                "1. 关闭本应用的电池优化\n" +
                "2. 允许本应用后台运行"
        }
    }
    
    /**
     * 跳转到白名单设置页面
     * 
     * @return true 成功跳转，false 跳转失败（使用通用设置页）
     */
    fun openWhitelistSettings(context: Context): Boolean {
        return try {
            when (getManufacturer()) {
                Manufacturer.XIAOMI -> openXiaomiSettings(context)
                Manufacturer.HUAWEI -> openHuaweiSettings(context)
                Manufacturer.HONOR -> openHonorSettings(context)
                Manufacturer.OPPO -> openOppoSettings(context)
                Manufacturer.VIVO -> openVivoSettings(context)
                Manufacturer.REALME -> openRealmeSettings(context)
                Manufacturer.ONEPLUS -> openOnePlusSettings(context)
                Manufacturer.MEIZU -> openMeizuSettings(context)
                Manufacturer.SAMSUNG -> openSamsungSettings(context)
                Manufacturer.ASUS -> openAsusSettings(context)
                else -> openBatteryOptimizationSettings(context)
            }
        } catch (e: Exception) {
            Log.e(TAG, "跳转白名单设置失败，尝试通用设置", e)
            openBatteryOptimizationSettings(context)
        }
    }
    
    // ==================== 各厂商跳转实现 ====================
    
    /**
     * 小米：自启动管理
     */
    private fun openXiaomiSettings(context: Context): Boolean {
        return tryStartActivity(context, Intent().apply {
            component = ComponentName(
                "com.miui.securitycenter",
                "com.miui.permcenter.autostart.AutoStartManagementActivity"
            )
        }) || openBatteryOptimizationSettings(context)
    }
    
    /**
     * 华为：应用启动管理
     */
    private fun openHuaweiSettings(context: Context): Boolean {
        return tryStartActivity(context, Intent().apply {
            component = ComponentName(
                "com.huawei.systemmanager",
                "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"
            )
        }) || tryStartActivity(context, Intent().apply {
            component = ComponentName(
                "com.huawei.systemmanager",
                "com.huawei.systemmanager.optimize.process.ProtectActivity"
            )
        }) || openBatteryOptimizationSettings(context)
    }
    
    /**
     * 荣耀：应用启动管理
     */
    private fun openHonorSettings(context: Context): Boolean {
        return openHuaweiSettings(context) // 荣耀使用类似华为的设置
    }
    
    /**
     * OPPO：自启动管理
     */
    private fun openOppoSettings(context: Context): Boolean {
        return tryStartActivity(context, Intent().apply {
            component = ComponentName(
                "com.coloros.safecenter",
                "com.coloros.safecenter.permission.startup.StartupAppListActivity"
            )
        }) || tryStartActivity(context, Intent().apply {
            component = ComponentName(
                "com.oppo.safe",
                "com.oppo.safe.permission.startup.StartupAppListActivity"
            )
        }) || openBatteryOptimizationSettings(context)
    }
    
    /**
     * VIVO：后台高耗电
     */
    private fun openVivoSettings(context: Context): Boolean {
        return tryStartActivity(context, Intent().apply {
            component = ComponentName(
                "com.iqoo.secure",
                "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager"
            )
        }) || tryStartActivity(context, Intent().apply {
            component = ComponentName(
                "com.vivo.permissionmanager",
                "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"
            )
        }) || openBatteryOptimizationSettings(context)
    }
    
    /**
     * Realme：自启动管理
     */
    private fun openRealmeSettings(context: Context): Boolean {
        return openOppoSettings(context) // Realme 基于 ColorOS
    }
    
    /**
     * 一加：电池优化
     */
    private fun openOnePlusSettings(context: Context): Boolean {
        return openBatteryOptimizationSettings(context)
    }
    
    /**
     * 魅族：后台管理
     */
    private fun openMeizuSettings(context: Context): Boolean {
        return tryStartActivity(context, Intent("com.meizu.safe.security.SHOW_APPSEC").apply {
            putExtra("packageName", context.packageName)
        }) || openBatteryOptimizationSettings(context)
    }
    
    /**
     * 三星：电池优化
     */
    private fun openSamsungSettings(context: Context): Boolean {
        return openBatteryOptimizationSettings(context)
    }
    
    /**
     * 华硕：自启动管理
     */
    private fun openAsusSettings(context: Context): Boolean {
        return tryStartActivity(context, Intent().apply {
            component = ComponentName(
                "com.asus.mobilemanager",
                "com.asus.mobilemanager.powersaver.PowerSaverSettings"
            )
        }) || openBatteryOptimizationSettings(context)
    }
    
    /**
     * 通用：电池优化设置（忽略电池优化）
     */
    private fun openBatteryOptimizationSettings(context: Context): Boolean {
        return try {
            val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            Log.e(TAG, "打开电池优化设置失败", e)
            // 最后尝试打开应用设置页面
            try {
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = android.net.Uri.fromParts("package", context.packageName, null)
                }
                context.startActivity(intent)
                true
            } catch (e2: Exception) {
                Log.e(TAG, "打开应用设置页面失败", e2)
                false
            }
        }
    }
    
    /**
     * 尝试启动 Activity
     */
    private fun tryStartActivity(context: Context, intent: Intent): Boolean {
        return try {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            Log.d(TAG, "成功跳转到厂商设置页面: ${intent.component?.className}")
            true
        } catch (e: Exception) {
            Log.d(TAG, "跳转失败: ${intent.component?.className}, ${e.message}")
            false
        }
    }
    
    /**
     * 获取简短的引导步骤（用于弹窗）
     */
    fun getShortGuidance(): String {
        return when (getManufacturer()) {
            Manufacturer.XIAOMI -> "请将本应用添加到【后台自启动】白名单"
            Manufacturer.HUAWEI, Manufacturer.HONOR -> "请在【应用启动管理】中允许本应用自启动"
            Manufacturer.OPPO, Manufacturer.REALME -> "请将本应用添加到【自启动管理】白名单"
            Manufacturer.VIVO -> "请将本应用添加到【后台高耗电】白名单"
            Manufacturer.ONEPLUS -> "请关闭本应用的【电池优化】"
            Manufacturer.MEIZU -> "请开启【待机时保持运行】"
            else -> "请关闭本应用的电池优化"
        }
    }
}



