import 'dart:async';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/tools/logging/log_manager.dart';
import 'package:kissu_app/pages/mine/app_usage/services/app_usage_report_service.dart';

/// App使用记录自动上报服务
/// 
/// 功能：
/// 1. 在首页进入时检查权限，如果有权限则启动自动上报
/// 2. 监听权限变化，如果权限从无到有，重新启动服务
/// 3. 退出登录时停止服务
/// 4. 重新登录时重启服务
class AppUsageAutoReportService extends GetxService {
  static const platform = MethodChannel('app_usage_channel');
  static const _tag = 'AppUsageAutoReportService';
  
  // 上报服务实例
  final _reportService = AppUsageReportService();
  
  // 权限检查定时器（用于监听权限变化）
  Timer? _permissionCheckTimer;
  
  // 上次权限状态
  bool _lastPermissionStatus = false;
  
  // 是否已启动服务
  bool _isServiceStarted = false;
  
  // 是否正在检查权限
  bool _isCheckingPermission = false;
  
  @override
  void onInit() {
    super.onInit();
    logger.info('App使用记录自动上报服务已初始化', tag: _tag);
  }
  
  @override
  void onClose() {
    stop();
    super.onClose();
  }
  
  /// 启动自动上报服务
  /// 在首页进入时调用
  Future<void> start() async {
    if (_isServiceStarted) {
      logger.info('服务已启动，跳过重复启动', tag: _tag);
      return;
    }
    
    logger.info('🚀 开始启动App使用记录自动上报服务', tag: _tag);
    
    // 检查权限
    final hasPermission = await _checkUsagePermission();
    _lastPermissionStatus = hasPermission;
    
    if (hasPermission) {
      // 有权限，启动上报服务（首次启动时增加延迟，让系统有时间准备数据）
      await _startReportService(delayMs: 3000);
    } else {
      logger.info('暂无App使用记录权限，等待权限开启', tag: _tag);
    }
    
    // 启动权限监听（每10秒检查一次）
    _startPermissionListener();
    
    _isServiceStarted = true;
    logger.info('✅ App使用记录自动上报服务已启动', tag: _tag);
  }
  
  /// 停止自动上报服务
  /// 在退出登录时调用
  void stop() {
    if (!_isServiceStarted) {
      return;
    }
    
    logger.info('⏹️ 停止App使用记录自动上报服务', tag: _tag);
    
    // 停止上报服务
    _reportService.stop();
    
    // 停止权限监听
    _permissionCheckTimer?.cancel();
    _permissionCheckTimer = null;
    
    _isServiceStarted = false;
    _lastPermissionStatus = false;
    
    logger.info('✅ App使用记录自动上报服务已停止', tag: _tag);
  }
  
  /// 重启服务
  /// 在重新登录时调用
  /// [forceFullReport] 是否强制全量上报（换账号时需要）
  Future<void> restart({bool forceFullReport = false}) async {
    logger.info('🔄 重启App使用记录自动上报服务${forceFullReport ? "（强制全量上报）" : ""}', tag: _tag);
    stop();
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 检查权限
    final hasPermission = await _checkUsagePermission();
    _lastPermissionStatus = hasPermission;
    
    if (hasPermission) {
      // 有权限，启动上报服务（换账号时强制全量上报）
      await _startReportService(delayMs: 3000, forceFullReport: forceFullReport);
    } else {
      logger.info('暂无App使用记录权限，等待权限开启', tag: _tag);
    }
    
    // 启动权限监听（每10秒检查一次）
    _startPermissionListener();
    
    _isServiceStarted = true;
    logger.info('✅ App使用记录自动上报服务已重启', tag: _tag);
  }
  
  /// 检查App使用记录权限
  Future<bool> _checkUsagePermission() async {
    try {
      // 尝试获取一个简单的使用数据来检测权限
      await platform.invokeMethod('getAppUsageTime', {'packageName': 'com.android.settings'});
      return true;
    } on PlatformException catch (e) {
      if (e.code == 'NO_PERMISSION') {
        return false;
      }
      // 其他错误认为有权限
      return true;
    } catch (e) {
      logger.warning('检查权限异常: $e', tag: _tag);
      return false;
    }
  }
  
  /// 启动上报服务
  /// [delayMs] 延迟时间（毫秒），用于权限刚开启时等待系统生效
  /// [forceFullReport] 是否强制全量上报（用于换账号等情况）
  Future<void> _startReportService({int delayMs = 0, bool forceFullReport = false}) async {
    try {
      if (delayMs > 0) {
        logger.info('⏳ 等待 ${delayMs}ms 后启动上报服务（确保权限已生效，系统数据已准备好）', tag: _tag);
        await Future.delayed(Duration(milliseconds: delayMs));
      }
      
      logger.info('📤 启动App使用记录上报服务（全量+定时增量）', tag: _tag);
      await _reportService.initialize(forceFullReport: forceFullReport);
      logger.info('✅ App使用记录上报服务启动成功', tag: _tag);
    } catch (e) {
      logger.error('启动上报服务失败: $e', tag: _tag, error: e);
    }
  }
  
  /// 启动权限监听
  void _startPermissionListener() {
    _permissionCheckTimer?.cancel();
    
    // 每10秒检查一次权限状态
    _permissionCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (_isCheckingPermission) {
        return; // 避免重复检查
      }
      
      _isCheckingPermission = true;
      try {
        final currentPermission = await _checkUsagePermission();
        
        // 如果权限从无到有，重新启动服务（延迟5秒，确保权限已生效且系统数据已准备好）
        if (!_lastPermissionStatus && currentPermission) {
          logger.info('🔓 检测到App使用记录权限已开启，延迟5秒后重新启动上报服务（让系统有时间准备数据）', tag: _tag);
          await _startReportService(delayMs: 5000);
        }
        
        // 如果权限从有到无，停止上报服务
        if (_lastPermissionStatus && !currentPermission) {
          logger.warning('🔒 检测到App使用记录权限已关闭，停止上报服务', tag: _tag);
          _reportService.stop();
        }
        
        _lastPermissionStatus = currentPermission;
      } catch (e) {
        logger.error('权限检查异常: $e', tag: _tag, error: e);
      } finally {
        _isCheckingPermission = false;
      }
    });
    
    logger.info('👂 权限监听已启动（每10秒检查一次）', tag: _tag);
  }
  
  /// 手动触发权限检查（用于从设置页面返回时立即检查）
  Future<void> checkPermissionAndRestartIfNeeded() async {
    if (_isCheckingPermission) {
      return;
    }
    
    _isCheckingPermission = true;
    try {
      final currentPermission = await _checkUsagePermission();
      
      // 如果权限从无到有，重新启动服务（延迟5秒，确保权限已生效且系统数据已准备好）
      if (!_lastPermissionStatus && currentPermission) {
        logger.info('🔓 手动检查：App使用记录权限已开启，延迟5秒后重新启动上报服务（让系统有时间准备数据）', tag: _tag);
        await _startReportService(delayMs: 5000);
      }
      
      // 如果权限从有到无，停止上报服务
      if (_lastPermissionStatus && !currentPermission) {
        logger.warning('🔒 手动检查：App使用记录权限已关闭，停止上报服务', tag: _tag);
        _reportService.stop();
      }
      
      _lastPermissionStatus = currentPermission;
    } catch (e) {
      logger.error('手动权限检查异常: $e', tag: _tag, error: e);
    } finally {
      _isCheckingPermission = false;
    }
  }
}

