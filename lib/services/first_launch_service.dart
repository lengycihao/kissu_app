import 'dart:async';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kissu_app/network/tools/logging/log_manager.dart';

/// 首次启动服务
class FirstLaunchService extends GetxService {
  static FirstLaunchService get instance => Get.find<FirstLaunchService>();
  
  // SharedPreferences 键
  static const String _hasAgreedKey = 'has_agreed_first_agreement';
  
  // 🔥 内存缓存：记录用户是否已同意隐私协议
  // 只要用户同意过一次，就永远不再显示弹窗
  bool? _cachedHasAgreed;
  
  /// 检查是否需要显示首次协议弹窗
  /// 🔑 关键修复：只检查用户是否已同意，简化逻辑避免冲突
  Future<bool> shouldShowFirstAgreement() async {
    // 🔥 优化：如果已经有缓存结果，直接返回
    if (_cachedHasAgreed != null) {
      final shouldShow = !_cachedHasAgreed!;
      logger.info('使用缓存的协议状态: hasAgreed=$_cachedHasAgreed, shouldShow=$shouldShow', tag: 'FirstLaunchService');
      return shouldShow;
    }
    
    try {
      // 🔥 修复：为 SharedPreferences 操作添加超时保护，避免阻塞
      final prefs = await SharedPreferences.getInstance()
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              logger.warning('获取SharedPreferences超时（2秒）', tag: 'FirstLaunchService');
              throw TimeoutException('获取SharedPreferences超时', const Duration(seconds: 2));
            },
          );
      
      final hasAgreed = prefs.getBool(_hasAgreedKey) ?? false;
      
      // 🔥 成功读取后缓存结果
      _cachedHasAgreed = hasAgreed;
      
      final shouldShow = !hasAgreed;
      logger.info('检查首次协议弹窗状态: hasAgreed=$hasAgreed, shouldShow=$shouldShow', tag: 'FirstLaunchService');
      return shouldShow;
    } catch (e) {
      logger.error('检查首次协议弹窗状态失败: $e', tag: 'FirstLaunchService', error: e);
      
      // 🔥 修复：如果有缓存，使用缓存；否则默认不显示（避免重复弹窗）
      if (_cachedHasAgreed != null) {
        final shouldShow = !_cachedHasAgreed!;
        logger.warning('读取失败，使用缓存: hasAgreed=$_cachedHasAgreed, shouldShow=$shouldShow', tag: 'FirstLaunchService');
        return shouldShow;
      }
      
      // 🔥 没有缓存时，默认不显示弹窗（保守策略，避免骚扰用户）
      logger.warning('读取失败且无缓存，默认不显示弹窗（避免重复弹窗）', tag: 'FirstLaunchService');
      return false;
    }
  }
  
  /// 标记已显示首次协议弹窗（已废弃，保留兼容性）
  @Deprecated('不再需要单独标记弹窗显示状态，只需标记用户同意状态')
  Future<void> markFirstAgreementShown() async {
    logger.info('markFirstAgreementShown已废弃，无需调用', tag: 'FirstLaunchService');
  }
  
  /// 标记用户已同意首次协议
  Future<void> markFirstAgreementAgreed() async {
    try {
      // 🔥 修复：为 SharedPreferences 操作添加超时保护
      final prefs = await SharedPreferences.getInstance()
          .timeout(
            const Duration(seconds: 1),
            onTimeout: () {
              logger.warning('获取SharedPreferences超时（1秒）', tag: 'FirstLaunchService');
              throw TimeoutException('获取SharedPreferences超时', const Duration(seconds: 1));
            },
          );
      await prefs.setBool(_hasAgreedKey, true)
          .timeout(
            const Duration(seconds: 1),
            onTimeout: () {
              logger.warning('保存首次协议同意状态超时（1秒）', tag: 'FirstLaunchService');
              return false; // 超时返回false，但不影响流程
            },
          );
      
      // 🔥 更新内存缓存：用户已同意，下次不再显示弹窗
      _cachedHasAgreed = true;
      
      logger.info('已标记用户同意首次协议', tag: 'FirstLaunchService');
    } catch (e) {
      logger.error('标记首次协议同意状态失败: $e', tag: 'FirstLaunchService', error: e);
    }
  }
  
  /// 退出应用
  Future<void> exitApp() async {
    try {
      // 🔥 修复：用户拒绝时不标记任何状态，下次启动仍需同意
      // 这符合隐私合规要求：必须每次启动都征得用户同意
      logger.info('用户拒绝隐私协议，退出应用', tag: 'FirstLaunchService');
      
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
