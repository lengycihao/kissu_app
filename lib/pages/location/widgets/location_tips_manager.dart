import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../utils/user_manager.dart';
import '../../../utils/permission_helper.dart';
import '../location_v2_controller.dart';

/// 定位页面提示管理器
/// 管理三种提示：定位权限、另一半定位开关、会员到期
class LocationTipsManager extends GetxController {
  final LocationV2Controller locationController;
  
  /// 提示状态
  final showPermissionTip = false.obs; // 用户定位权限未开启提示
  final showPartnerLocationTip = false.obs; // 另一半定位未开启提示
  final showVipExpiryTip = false.obs; // 会员到期提示
  
  /// 会员到期信息
  final vipExpiryDays = 0.obs; // 剩余天数
  final vipExpiryHours = 0.obs; // 剩余小时数（当小于1天时使用）
  final vipExpiryText = "".obs; // 显示文本
  
  LocationTipsManager(this.locationController);
  
  @override
  void onInit() {
    super.onInit();
    _startPermissionMonitoring();
    
    // 延迟执行权限检查，确保页面完全初始化后再检查
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAllTips();
    });
  }
  
  @override
  void onClose() {
    _stopPermissionMonitoring();
    super.onClose();
  }
  
  /// 检查所有提示
  void _checkAllTips() {
    debugPrint('🔍 LocationTipsManager: 开始检查所有提示');
    _checkPermissionTip();
    _checkPartnerLocationTip();
    _checkVipExpiryTip();
    debugPrint('🔍 LocationTipsManager: 所有提示检查完成');
  }
  
  /// 1. 检查用户"始终允许"定位权限提示
  void _checkPermissionTip() async {
    try {
      debugPrint('🔍 LocationTipsManager: 开始检查始终允许定位权限');
      
      // 检查始终允许定位权限状态（后台定位权限）
      final alwaysStatus = await Permission.locationAlways.status;
      final shouldShow = !alwaysStatus.isGranted;
      
      debugPrint('🔐 始终允许定位权限状态: $alwaysStatus');
      debugPrint('🔐 是否应该显示权限提示: $shouldShow');
      debugPrint('🔐 当前提示状态: ${showPermissionTip.value}');
      
      if (showPermissionTip.value != shouldShow) {
        showPermissionTip.value = shouldShow;
        debugPrint('🔐 始终允许定位权限提示状态更新: $shouldShow (状态: $alwaysStatus)');
      } else {
        debugPrint('🔐 权限提示状态无变化，保持: ${showPermissionTip.value}');
      }
    } catch (e) {
      debugPrint('❌ 检查始终允许定位权限失败: $e');
    }
  }
  
  /// 2. 检查另一半定位开关提示
  void _checkPartnerLocationTip() {
    try {
      // 从定位数据中获取另一半的定位开关状态
      final locationData = locationController.locationData.value;
      if (locationData?.halfLocationMobileDevice?.isOpenLocation != null) {
        final isPartnerLocationOpen = locationData!.halfLocationMobileDevice!.isOpenLocation == 1;
        showPartnerLocationTip.value = !isPartnerLocationOpen;
        debugPrint('📍 另一半定位开关提示状态: ${showPartnerLocationTip.value}');
      } else {
        showPartnerLocationTip.value = false;
      }
    } catch (e) {
      debugPrint('❌ 检查另一半定位开关失败: $e');
      showPartnerLocationTip.value = false;
    }
  }
  
  /// 3. 检查会员到期提示
  void _checkVipExpiryTip() {
    try {
      final user = UserManager.currentUser;
      if (user == null) {
        showVipExpiryTip.value = false;
        return;
      }
      
      // 永久会员不显示提示
      if (user.isForEverVip == 1) {
        showVipExpiryTip.value = false;
        debugPrint('👑 永久会员，不显示到期提示');
        return;
      }
      
      // 非会员不显示提示
      if (user.isVip != 1) {
        showVipExpiryTip.value = false;
        debugPrint('👤 非会员，不显示到期提示');
        return;
      }
      
      // 会员且非永久会员，检查到期时间
      if (user.vipEndTime != null) {
        final vipEndTimestamp = user.vipEndTime! * 1000; // 转换为毫秒
        final endTime = DateTime.fromMillisecondsSinceEpoch(vipEndTimestamp);
        final now = DateTime.now();
        final difference = endTime.difference(now);
        
        if (difference.inDays <= 5 && difference.inDays >= 0) {
          // 5天内到期（且未过期）
          showVipExpiryTip.value = true;
          
          if (difference.inDays >= 1) {
            // 显示天数（1-5天）
            vipExpiryDays.value = difference.inDays;
            vipExpiryText.value = "${difference.inDays}天";
            debugPrint('⏰ 会员${difference.inDays}天后到期');
          } else if (difference.inHours > 0) {
            // 显示小时数（小于1天且大于0小时）
            vipExpiryHours.value = difference.inHours;
            vipExpiryText.value = "${difference.inHours}小时";
            debugPrint('⏰ 会员${difference.inHours}小时后到期');
          } else {
            // 已过期或即将过期（0小时内）
            vipExpiryText.value = "即将到期";
            debugPrint('⏰ 会员即将到期或已过期');
          }
        } else if (difference.inDays < 0) {
          // 已过期，仍然显示提示
          showVipExpiryTip.value = true;
          vipExpiryText.value = "已过期";
          debugPrint('⏰ 会员已过期');
        } else {
          showVipExpiryTip.value = false;
          debugPrint('✅ 会员到期时间充足（>${difference.inDays}天），不显示提示');
        }
      } else {
        showVipExpiryTip.value = false;
        debugPrint('⚠️ 会员到期时间为空');
      }
    } catch (e) {
      debugPrint('❌ 检查会员到期提示失败: $e');
      showVipExpiryTip.value = false;
    }
  }
  
  /// 开始权限监听
  void _startPermissionMonitoring() {
    // 监听定位数据更新时检查另一半定位开关
    ever(locationController.locationData, (_) {
      _checkPartnerLocationTip(); // 当定位数据更新时检查另一半定位开关
    });
  }
  
  /// 停止权限监听
  void _stopPermissionMonitoring() {
    // 清理监听器逻辑（如果需要的话）
  }
  
  /// 应用恢复前台时检查权限状态
  void onAppResumed() {
    debugPrint('📱 LocationTipsManager: 应用恢复前台，重新检查权限状态');
    _checkPermissionTip();
  }
  
  /// 点击权限提示 - 跳转到设置页面
  void onPermissionTipTap() async {
    try {
      debugPrint('🔐 点击定位权限提示，跳转到设置页面');
      await PermissionHelper.openLocationSettings();
    } catch (e) {
      debugPrint('❌ 打开定位设置失败: $e');
    }
  }
  
  /// 关闭另一半定位提示
  void onPartnerLocationTipClose() {
    showPartnerLocationTip.value = false;
    debugPrint('❌ 用户手动关闭另一半定位提示');
  }
  
  /// 点击会员到期提示 - 跳转到会员页面
  void onVipExpiryTipTap() {
    debugPrint('👑 点击会员到期提示，跳转到会员页面');
    // 使用项目路由常量保持一致性
    Get.toNamed('/kisssu_app/vip');
  }
  
  /// 获取当前应该显示的提示类型
  /// 返回优先级最高的提示类型
  String? get currentTipType {
    if (showPermissionTip.value) return 'permission';
    if (showPartnerLocationTip.value) return 'partner_location';
    if (showVipExpiryTip.value) return 'vip_expiry';
    return null;
  }
  
  /// 是否有任何提示需要显示
  bool get hasAnyTip => currentTipType != null;
  
  /// 刷新所有提示状态（供外部调用）
  void refreshTips() {
    _checkAllTips();
  }
}
