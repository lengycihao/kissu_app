import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/services/permission_service.dart';
import 'package:kissu_app/utils/permission_helper.dart';
import 'package:kissu_app/pages/home/home_controller.dart';

class MessageListController extends GetxController {
  // 通知权限状态
  var hasNotificationPermission = false.obs;
  
  // 是否有新的系统消息
  var hasNewSystemMessage = false.obs;
  
  // 是否有新的互动消息
  var hasNewInteractionMessage = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkNotificationPermission();
    _syncRedDotFromHome();
  }

  /// 从首页同步红点状态
  void _syncRedDotFromHome() {
    try {
      // 尝试获取 HomeController
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        // 同步红点状态
        hasNewSystemMessage.value = homeController.systemNoticeRedDot.value > 0;
        hasNewInteractionMessage.value = homeController.interactionNoticeRedDot.value > 0;
        
        debugPrint('📊 同步红点状态: 系统消息=${hasNewSystemMessage.value}, 互动消息=${hasNewInteractionMessage.value}');
      } else {
        debugPrint('⚠️ HomeController 未注册，无法同步红点状态');
      }
    } catch (e) {
      debugPrint('❌ 同步红点状态失败: $e');
    }
  }

  /// 检查通知权限
  Future<void> _checkNotificationPermission() async {
    try {
      final permissionService = PermissionService();
      final isGranted = await permissionService.isNotificationPermissionGranted();
      hasNotificationPermission.value = isGranted;
      debugPrint('通知权限状态: $isGranted');
    } catch (e) {
      debugPrint('检查通知权限失败: $e');
      hasNotificationPermission.value = false;
    }
  }

  /// 打开通知设置
  Future<void> openNotificationSettings() async {
    try {
      await PermissionHelper.openNotificationSettings();
      // 延迟检查权限状态
      Future.delayed(const Duration(milliseconds: 500), () {
        _checkNotificationPermission();
      });
    } catch (e) {
      debugPrint('打开通知设置失败: $e');
    }
  }

  /// 返回上一页
  void onBackTap() {
    Get.back();
  }

  /// 清空未读消息
  void clearUnreadMessages() {
    // TODO: 实现清空未读消息的逻辑
    debugPrint('清空未读消息');
  }

  /// 进入系统消息详情
  void goToSystemMessage() {
    // 清除本地红点显示
    hasNewSystemMessage.value = false;
    
    // 清除 HomeController 中的红点
    try {
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        homeController.systemNoticeRedDot.value = 0;
        // 清除主红点显示
        homeController.isRedDot.value = false;
        debugPrint('✅ 已清除系统消息红点');
      }
    } catch (e) {
      debugPrint('❌ 清除系统消息红点失败: $e');
    }
    
    Get.toNamed('/kisssu_app/message_detail', arguments: {'type': 'system'});
  }

  /// 进入互动消息详情
  void goToInteractionMessage() {
    // 清除本地红点显示
    hasNewInteractionMessage.value = false;
    
    // 清除 HomeController 中的红点
    try {
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        homeController.interactionNoticeRedDot.value = 0;
        // 清除主红点显示
        homeController.isRedDot.value = false;
        debugPrint('✅ 已清除互动消息红点');
      }
    } catch (e) {
      debugPrint('❌ 清除互动消息红点失败: $e');
    }
    
    Get.toNamed('/kisssu_app/interaction_message');
  }

  /// 页面恢复时重新检查通知权限
  void onResume() {
    _checkNotificationPermission();
  }
}

