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
    
    // 🔥 尝试读取（带重试机制）
    for (int retry = 0; retry < 2; retry++) {
      try {
        // 🔥 增加超时时间到3秒，冷启动时SharedPreferences初始化可能较慢
        final prefs = await SharedPreferences.getInstance()
            .timeout(
              const Duration(seconds: 3),
              onTimeout: () {
                logger.warning('获取SharedPreferences超时（3秒），重试次数: $retry', tag: 'FirstLaunchService');
                throw TimeoutException('获取SharedPreferences超时', const Duration(seconds: 3));
              },
            );
        
        final hasAgreed = prefs.getBool(_hasAgreedKey) ?? false;
        
        // 🔥 成功读取后缓存结果
        _cachedHasAgreed = hasAgreed;
        
        final shouldShow = !hasAgreed;
        logger.info('检查首次协议弹窗状态: hasAgreed=$hasAgreed, shouldShow=$shouldShow', tag: 'FirstLaunchService');
        return shouldShow;
      } catch (e) {
        logger.error('检查首次协议弹窗状态失败（重试次数: $retry）: $e', tag: 'FirstLaunchService', error: e);
        // 短暂延迟后重试
        if (retry < 1) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
    }
    
    // 🔥 多次重试失败后，检查缓存
    if (_cachedHasAgreed != null) {
      final shouldShow = !_cachedHasAgreed!;
      logger.warning('读取失败，使用缓存: hasAgreed=$_cachedHasAgreed, shouldShow=$shouldShow', tag: 'FirstLaunchService');
      return shouldShow;
    }
    
    // 🔥 没有缓存时，默认不显示弹窗（保守策略，避免骚扰用户）
    logger.warning('读取失败且无缓存，默认不显示弹窗（避免重复弹窗）', tag: 'FirstLaunchService');
    return false;
  }
  
  /// 标记已显示首次协议弹窗（已废弃，保留兼容性）
  @Deprecated('不再需要单独标记弹窗显示状态，只需标记用户同意状态')
  Future<void> markFirstAgreementShown() async {
    logger.info('markFirstAgreementShown已废弃，无需调用', tag: 'FirstLaunchService');
  }
  
  /// 标记用户已同意首次协议
  /// 🔥 修复：确保保存成功后才更新缓存，增加重试机制
  Future<void> markFirstAgreementAgreed() async {
    // 🔥 先更新内存缓存，确保当前会话不会重复弹窗
    _cachedHasAgreed = true;
    
    // 🔥 尝试保存到磁盘（带重试机制）
    bool saved = false;
    for (int retry = 0; retry < 3 && !saved; retry++) {
      try {
        // 🔥 增加超时时间到3秒，冷启动时SharedPreferences初始化可能较慢
        final prefs = await SharedPreferences.getInstance()
            .timeout(
              const Duration(seconds: 3),
              onTimeout: () {
                logger.warning('获取SharedPreferences超时（3秒），重试次数: $retry', tag: 'FirstLaunchService');
                throw TimeoutException('获取SharedPreferences超时', const Duration(seconds: 3));
              },
            );
        
        // 🔥 保存并验证
        await prefs.setBool(_hasAgreedKey, true);
        
        // 🔥 验证保存是否成功
        final verified = prefs.getBool(_hasAgreedKey) ?? false;
        if (verified) {
          saved = true;
          logger.info('已标记用户同意首次协议（重试次数: $retry）', tag: 'FirstLaunchService');
        } else {
          logger.warning('保存首次协议同意状态验证失败，重试次数: $retry', tag: 'FirstLaunchService');
        }
      } catch (e) {
        logger.error('标记首次协议同意状态失败（重试次数: $retry）: $e', tag: 'FirstLaunchService', error: e);
        // 短暂延迟后重试
        if (retry < 2) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }
    
    if (!saved) {
      logger.error('❌ 保存首次协议同意状态最终失败，下次冷启动可能重复弹窗', tag: 'FirstLaunchService');
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
