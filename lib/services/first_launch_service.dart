import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kissu_app/network/tools/logging/log_manager.dart';

/// 首次启动服务
class FirstLaunchService extends GetxService {
  static FirstLaunchService get instance => Get.find<FirstLaunchService>();
  
  // SharedPreferences 键
  static const String _hasShownAgreementKey = 'has_shown_first_agreement';
  static const String _hasAgreedKey = 'has_agreed_first_agreement';
  
  /// 检查是否需要显示首次协议弹窗
  Future<bool> shouldShowFirstAgreement() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasShown = prefs.getBool(_hasShownAgreementKey) ?? false;
      final hasAgreed = prefs.getBool(_hasAgreedKey) ?? false;
      
      // 如果从未显示过弹窗，或者显示过但用户没有同意，则需要显示
      return !hasShown || !hasAgreed;
    } catch (e) {
      logger.error('检查首次协议弹窗状态失败: $e', tag: 'FirstLaunchService', error: e);
      return true; // 默认需要显示
    }
  }
  
  /// 标记已显示首次协议弹窗
  Future<void> markFirstAgreementShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasShownAgreementKey, true);
      logger.info('已标记首次协议弹窗已显示', tag: 'FirstLaunchService');
    } catch (e) {
      logger.error('标记首次协议弹窗状态失败: $e', tag: 'FirstLaunchService', error: e);
    }
  }
  
  /// 标记用户已同意首次协议
  Future<void> markFirstAgreementAgreed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasAgreedKey, true);
      logger.info('已标记用户同意首次协议', tag: 'FirstLaunchService');
    } catch (e) {
      logger.error('标记首次协议同意状态失败: $e', tag: 'FirstLaunchService', error: e);
    }
  }
  
  /// 退出应用
  Future<void> exitApp() async {
    try {
      // 标记已显示弹窗（避免下次启动时再次显示）
      await markFirstAgreementShown();
      
      // 退出应用
      await SystemNavigator.pop();
    } catch (e) {
      logger.error('退出应用失败: $e', tag: 'FirstLaunchService', error: e);
    }
  }
  
  /// 重置首次协议状态（用于测试或重新显示弹窗）
  Future<void> resetFirstAgreementStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_hasShownAgreementKey);
      await prefs.remove(_hasAgreedKey);
      logger.info('首次协议状态已重置', tag: 'FirstLaunchService');
    } catch (e) {
      logger.error('重置首次协议状态失败: $e', tag: 'FirstLaunchService', error: e);
    }
  }
}
