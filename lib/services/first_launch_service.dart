import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kissu_app/network/tools/logging/log_manager.dart';

/// 首次启动服务
/// 简化逻辑：只检查本地标志位，同意后保存，下次不再弹窗
class FirstLaunchService extends GetxService {
  static FirstLaunchService get instance => Get.find<FirstLaunchService>();
  
  static const String _hasAgreedKey = 'has_agreed_first_agreement';
  
  // 预加载的SharedPreferences实例（在服务初始化时获取）
  SharedPreferences? _prefs;
  
  @override
  void onInit() {
    super.onInit();
    _initPrefs();
  }
  
  /// 预加载SharedPreferences，避免后续读取时的初始化延迟
  Future<void> _initPrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      logger.debug('SharedPreferences预加载完成', tag: 'FirstLaunchService');
    } catch (e) {
      logger.error('SharedPreferences预加载失败: $e', tag: 'FirstLaunchService');
    }
  }
  
  /// 检查是否需要显示首次协议弹窗
  /// 简单逻辑：读取本地标志位，true=已同意不弹窗，false/null=需要弹窗
  Future<bool> shouldShowFirstAgreement() async {
    try {
      // 如果预加载的实例不可用，重新获取
      _prefs ??= await SharedPreferences.getInstance();
      
      final hasAgreed = _prefs!.getBool(_hasAgreedKey) ?? false;
      final shouldShow = !hasAgreed;
      
      logger.debug('检查隐私协议状态: hasAgreed=$hasAgreed, shouldShow=$shouldShow', tag: 'FirstLaunchService');
      return shouldShow;
    } catch (e) {
      logger.error('读取隐私协议状态失败: $e，默认显示弹窗', tag: 'FirstLaunchService');
      // 读取失败时默认显示弹窗（合规要求）
      return true;
    }
  }
  
  /// 标记用户已同意首次协议
  /// 简单逻辑：保存标志位到本地
  Future<void> markFirstAgreementAgreed() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setBool(_hasAgreedKey, true);
      logger.debug('已保存用户同意隐私协议', tag: 'FirstLaunchService');
    } catch (e) {
      logger.error('保存隐私协议同意状态失败: $e', tag: 'FirstLaunchService');
    }
  }
  
  /// 退出应用
  Future<void> exitApp() async {
    try {
      // 🔥 修复：用户拒绝时不标记任何状态，下次启动仍需同意
      // 这符合隐私合规要求：必须每次启动都征得用户同意
      logger.debug('用户拒绝隐私协议，退出应用', tag: 'FirstLaunchService');
      
      // 退出应用
      await SystemNavigator.pop();
    } catch (e) {
      logger.error('退出应用失败: $e', tag: 'FirstLaunchService', error: e);
    }
  }
  
  // /// 重置首次协议状态（用于测试或重新显示弹窗）
  // Future<void> resetFirstAgreementStatus() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     await prefs.remove(_hasAgreedKey);
      
  //     // 清除内存缓存
  //     _cachedHasAgreed = null;
      
  //     logger.info('首次协议状态已重置', tag: 'FirstLaunchService');
  //   } catch (e) {
  //     logger.error('重置首次协议状态失败: $e', tag: 'FirstLaunchService', error: e);
  //   }
  // }
}
