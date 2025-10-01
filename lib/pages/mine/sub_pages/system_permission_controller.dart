import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/permission_service.dart';
import '../../../utils/oktoast_util.dart';

/// 系统权限页面控制器
class SystemPermissionController extends GetxController with WidgetsBindingObserver {
  final PermissionService _permissionService = PermissionService();
  
  // 权限状态响应式变量
  final RxBool isLocationGranted = false.obs;
  final RxBool isNotificationGranted = false.obs;
  final RxBool isBatteryOptimized = false.obs;
  final RxBool isUsageAccessGranted = false.obs;
  
  // 加载状态
  final RxBool isLoading = false.obs;
  
  // 权限配置数据
  final List<Map<String, dynamic>> permissionItems = [
    {
      "icon": "assets/kissu_setting_ssdw.webp",
      "title": "开启实时定位",
      "subtitle": "和ta持续分享你的位置",
      "type": PermissionType.location,
    },
    {
      "icon": "assets/kissu_setting_htyx.webp", 
      "title": "允许后台运行",
      "subtitle": "应用后台常驻，确保数据同步",
      "type": PermissionType.battery,
    },
    {
      "icon": "assets/kissu_setting_tztx.webp",
      "title": "开启通知提醒", 
      "subtitle": "收到ta的实时动态提醒",
      "type": PermissionType.notification,
    },
    {
      "icon": "assets/kissu_setting_cc.webp",
      "title": "允许获取应用使用权限",
      "subtitle": "和ta分享手机使用报告", 
      "type": PermissionType.usage,
    },
  ];

  @override
  void onInit() {
    super.onInit();
    // 添加应用生命周期监听
    WidgetsBinding.instance.addObserver(this);
    // 初始化时检查权限状态
    checkAllPermissions();
  }

  @override
  void onClose() {
    // 移除应用生命周期监听
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// 应用生命周期变化监听
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // 当应用从后台回到前台时，重新检查权限状态
    if (state == AppLifecycleState.resumed) {
      print('应用回到前台，重新检查权限状态');
      // 延迟检查，确保页面完全激活
      Future.delayed(const Duration(milliseconds: 500), () {
        checkAllPermissions();
      });
    }
  }

  /// 检查所有权限状态
  Future<void> checkAllPermissions() async {
    // 避免重复检查
    if (isLoading.value) return;
    
    isLoading.value = true;
    try {
      final permissions = await _permissionService.checkAllPermissions();
      
      // 批量更新，减少UI重建次数
      final newLocationGranted = permissions[PermissionType.location] ?? false;
      final newLocationAlwaysGranted = permissions[PermissionType.locationAlways] ?? false;
      final newNotificationGranted = permissions[PermissionType.notification] ?? false;
      final newBatteryOptimized = permissions[PermissionType.battery] ?? false;
      final newUsageAccessGranted = permissions[PermissionType.usage] ?? false;
      
      // 只在状态真正改变时才更新
      if (isLocationGranted.value != newLocationGranted) {
        isLocationGranted.value = newLocationGranted;
      }
      if (isNotificationGranted.value != newNotificationGranted) {
        isNotificationGranted.value = newNotificationGranted;
      }
      if (isBatteryOptimized.value != newBatteryOptimized) {
        isBatteryOptimized.value = newBatteryOptimized;
      }
      if (isUsageAccessGranted.value != newUsageAccessGranted) {
        isUsageAccessGranted.value = newUsageAccessGranted;
      }
      
      // 记录后台位置权限状态（用于调试）
      print('后台位置权限: $newLocationAlwaysGranted');
      
      print('权限状态检查完成:');
      print('位置权限: ${isLocationGranted.value}');
      print('通知权限: ${isNotificationGranted.value}');
      print('电池优化: ${isBatteryOptimized.value}');
      print('使用情况访问: ${isUsageAccessGranted.value}');
      
    } catch (e) {
      print('检查权限状态时发生错误: $e');
      OKToastUtil.showError('检查权限状态失败');
    } finally {
      isLoading.value = false;
    }
  }

  /// 根据权限类型获取当前状态
  bool getPermissionStatus(PermissionType type) {
    switch (type) {
      case PermissionType.location:
        return isLocationGranted.value;
      case PermissionType.locationAlways:
        return isLocationGranted.value; // 后台位置权限基于基础位置权限
      case PermissionType.notification:
        return isNotificationGranted.value;
      case PermissionType.battery:
        return isBatteryOptimized.value;
      case PermissionType.usage:
        return isUsageAccessGranted.value;
      case PermissionType.photos:
        // 相册权限状态需要通过 PermissionService 检查
        return true; // 默认返回 true，实际状态由 PermissionService 管理
      case PermissionType.camera:
        // 相机权限状态需要通过 PermissionService 检查
        return true; // 默认返回 true，实际状态由 PermissionService 管理
      case PermissionType.phone:
        // 电话状态权限状态需要通过 PermissionService 检查
        return true; // 默认返回 true，实际状态由 PermissionService 管理
    }
  }

  /// 根据权限类型获取状态描述
  String getPermissionStatusText(PermissionType type) {
    final isGranted = getPermissionStatus(type);
    return _permissionService.getPermissionStatusDescription(type, isGranted);
  }

  /// 根据权限类型获取按钮文本
  String getButtonText(PermissionType type) {
    final isGranted = getPermissionStatus(type);
    return isGranted ? "已开启" : "去设置";
  }

  /// 根据权限类型获取按钮颜色
  Color getButtonColor(PermissionType type) {
    final isGranted = getPermissionStatus(type);
    return isGranted ? const Color(0xFFCCCCCC) : const Color(0xFFFF839E);
  }

  /// 根据权限类型获取按钮是否可点击
  bool isButtonEnabled(PermissionType type) {
    return !getPermissionStatus(type);
  }

  /// 处理权限设置点击
  Future<void> onPermissionTap(PermissionType type) async {
    final isGranted = getPermissionStatus(type);
    
    if (isGranted) {
      // 权限已开启，不执行任何操作
      return;
    }

    try {
      // 跳转到对应的系统设置页面
      await _permissionService.openPermissionSettings(type);
      
    } catch (e) {
      print('跳转系统设置失败: $e');
      OKToastUtil.showError('无法打开设置页面，请手动前往系统设置');
    }
  }

}
