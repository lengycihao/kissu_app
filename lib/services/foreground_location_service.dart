import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/tools/logging/log_manager.dart';

/// 前台定位服务管理器
/// 
/// 提供Android前台服务支持，确保应用在后台时能够持续进行定位
/// 符合Android 8.0+的后台执行限制要求
class ForegroundLocationService extends GetxService {
  static ForegroundLocationService get instance => Get.find<ForegroundLocationService>();
  
  // 服务状态
  final RxBool _isServiceRunning = false.obs;
  final RxString _serviceStatus = '未启动'.obs;
  final Rxn<DateTime> _serviceStartTime = Rxn<DateTime>();
  
  // 前台服务配置
  static const String _channelId = 'kissu_location_service';
  static const String _channelName = 'Kissu';
  static const String _channelDescription = '请不要关掉Kissu后台进程\n当前正在为对方共享您的信息，请勿关闭';
  static const int _notificationId = 1001;
  
  // 平台通道
  static const MethodChannel _methodChannel = MethodChannel('kissu_app/foreground_service');
  
  @override
  void onInit() {
    super.onInit();
    _setupMethodChannel();
  }
  
  @override
  void onClose() {
    stopForegroundService();
    super.onClose();
  }
  
  /// 设置方法通道
  void _setupMethodChannel() {
    _methodChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onServiceStarted':
          _handleServiceStarted();
          break;
        case 'onServiceStopped':
          _handleServiceStopped();
          break;
        case 'onServiceError':
          _handleServiceError(call.arguments);
          break;
        default:
          debugPrint('⚠️ 未知的方法调用: ${call.method}');
      }
    });
  }
  
  /// 启动前台服务
  Future<bool> startForegroundService() async {
    if (!Platform.isAndroid) {
      // logger.debug('ℹ️ 前台服务仅支持Android平台');
      return false;
    }
    
    if (_isServiceRunning.value) {
      // logger.debug('ℹ️ 前台服务已在运行');
      return true;
    }
    
    try {
      // logger.debug('🚀 启动前台定位服务...');
      
      final result = await _methodChannel.invokeMethod('startForegroundService', {
        'channelId': _channelId,
        'channelName': _channelName,
        'channelDescription': _channelDescription,
        'notificationId': _notificationId,
        'title': 'Kissu',
        'content': '请不要关掉Kissu后台进程\n当前正在为对方共享您的信息，请勿关闭', // 静默通知，不显示内容
        'icon': 'ic_launcher',
        'enableVibration': false,
        'enableSound': false,
        'priority': 'min', // 🔧 最低优先级，通知栏不可见
        'importance': 'min', // 🔧 最低重要性
        'ongoing': true,
        'autoCancel': false,
      });
      
      if (result == true) {
        _isServiceRunning.value = true;
        _serviceStatus.value = '运行中';
        _serviceStartTime.value = DateTime.now();
        // logger.debug('✅ 前台定位服务启动成功');
        return true;
      } else {
        logger.error('❌ 前台定位服务启动失败');
        return false;
      }
    } catch (e) {
      logger.error('❌ 启动前台服务异常: $e');
      _serviceStatus.value = '启动失败';
      return false;
    }
  }
  
  /// 停止前台服务
  Future<bool> stopForegroundService() async {
    if (!Platform.isAndroid) {
      return false;
    }
    
    if (!_isServiceRunning.value) {
      // logger.debug('ℹ️ 前台服务未运行，无需停止');
      return true;
    }
    
    try {
      // logger.debug('🛑 停止前台定位服务...');
      
      final result = await _methodChannel.invokeMethod('stopForegroundService');
      
      if (result == true) {
        _isServiceRunning.value = false;
        _serviceStatus.value = '已停止';
        _serviceStartTime.value = null;
        // logger.debug('✅ 前台定位服务停止成功');
        return true;
      } else {
        logger.error('❌ 前台定位服务停止失败');
        return false;
      }
    } catch (e) {
      logger.error('❌ 停止前台服务异常: $e');
      return false;
    }
  }
  
  /// 更新前台服务通知
  Future<bool> updateForegroundServiceNotification({
    String? title,
    String? content,
    String? bigText,
  }) async {
    if (!Platform.isAndroid || !_isServiceRunning.value) {
      return false;
    }
    
    try {
      final result = await _methodChannel.invokeMethod('updateNotification', {
        'notificationId': _notificationId,
        'title': title ?? 'Kissu - 情侣定位',
        'content': content ?? '正在为您提供位置定位服务',
        'bigText': bigText,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      return result == true;
    } catch (e) {
      logger.error('❌ 更新前台服务通知失败: $e');
      return false;
    }
  }
  
  /// 检查前台服务是否正在运行
  Future<bool> isForegroundServiceRunning() async {
    if (!Platform.isAndroid) {
      return false;
    }
    
    try {
      final result = await _methodChannel.invokeMethod('isServiceRunning');
      final isRunning = result == true;
      
      // 同步状态
      if (isRunning != _isServiceRunning.value) {
        _isServiceRunning.value = isRunning;
        _serviceStatus.value = isRunning ? '运行中' : '已停止';
        
        if (!isRunning) {
          _serviceStartTime.value = null;
        }
      }
      
      return isRunning;
    } catch (e) {
      logger.error('❌ 检查前台服务状态失败: $e');
      return false;
    }
  }
  
  /// 处理服务启动回调
  void _handleServiceStarted() {
    _isServiceRunning.value = true;
    _serviceStatus.value = '运行中';
    _serviceStartTime.value = DateTime.now();
    // logger.debug('📢 前台服务启动回调');
  }
  
  /// 处理服务停止回调
  void _handleServiceStopped() {
    _isServiceRunning.value = false;
    _serviceStatus.value = '已停止';
    _serviceStartTime.value = null;
    // logger.debug('📢 前台服务停止回调');
  }
  
  /// 处理服务错误回调
  void _handleServiceError(dynamic error) {
    _serviceStatus.value = '错误: $error';
    logger.error('📢 前台服务错误回调: $error');
  }
  
  /// 获取服务运行时长
  Duration? get serviceRunningDuration {
    if (_serviceStartTime.value == null) {
      return null;
    }
    return DateTime.now().difference(_serviceStartTime.value!);
  }
  
  /// 获取服务状态信息
  Map<String, dynamic> get serviceInfo {
    return {
      'isRunning': _isServiceRunning.value,
      'status': _serviceStatus.value,
      'startTime': _serviceStartTime.value?.toIso8601String(),
      'runningDuration': serviceRunningDuration?.inSeconds,
      'platform': Platform.operatingSystem,
      'supported': Platform.isAndroid,
    };
  }
  
  // Getter方法
  bool get isServiceRunning => _isServiceRunning.value;
  String get serviceStatus => _serviceStatus.value;
  DateTime? get serviceStartTime => _serviceStartTime.value;
  
  /// 打印服务状态
  void printServiceStatus() {
    final info = serviceInfo;
    logger.debug('📊 前台定位服务状态:');
    logger.debug('   运行状态: ${info['isRunning']}');
    logger.debug('   服务状态: ${info['status']}');
    logger.debug('   启动时间: ${info['startTime'] ?? '未启动'}');
    logger.debug('   运行时长: ${info['runningDuration'] ?? 0}秒');
    logger.debug('   平台支持: ${info['supported']}');
  }
}

/// 前台服务增强扩展
/// 
/// 为SimpleLocationService提供前台服务支持
extension ForegroundServiceExtension on Object {
  
  /// 启用前台服务模式
  Future<bool> enableForegroundServiceMode() async {
    try {
      final foregroundService = ForegroundLocationService.instance;
      return await foregroundService.startForegroundService();
    } catch (e) {
      logger.error('❌ 启用前台服务模式失败: $e');
      return false;
    }
  }
  
  /// 禁用前台服务模式
  Future<bool> disableForegroundServiceMode() async {
    try {
      final foregroundService = ForegroundLocationService.instance;
      return await foregroundService.stopForegroundService();
    } catch (e) {
      logger.error('❌ 禁用前台服务模式失败: $e');
      return false;
    }
  }
  
  /// 更新前台服务状态
  Future<void> updateForegroundServiceStatus(String status, {String? details}) async {
    try {
      final foregroundService = ForegroundLocationService.instance;
      if (foregroundService.isServiceRunning) {
        await foregroundService.updateForegroundServiceNotification(
          content: status,
          bigText: details,
        );
      }
    } catch (e) {
      logger.error('❌ 更新前台服务状态失败: $e');
    }
  }
}

/// 前台服务工具类
class ForegroundServiceUtils {
  
  /// 检查是否需要前台服务
  /// 
  /// Android 8.0+ 在后台运行定位服务时需要前台服务
  static bool shouldUseForegroundService() {
    if (!Platform.isAndroid) {
      return false;
    }
    
    // Android API 26 (8.0) 及以上版本需要前台服务
    // 这里简化判断，实际项目中可以通过platform_channel获取API级别
    return true;
  }
  
  /// 获取推荐的前台服务配置
  static Map<String, dynamic> getRecommendedConfig() {
    return {
      'useHighPriorityNotification': true,
      'enableLocationUpdates': true,
      'enableBatteryOptimization': false,
      'enableAutoRestart': true,
      'updateInterval': 60, // 60秒更新一次通知
    };
  }
  
  /// 检查前台服务权限
  static Future<bool> checkForegroundServicePermission() async {
    if (!Platform.isAndroid) {
      return true;
    }
    
    try {
      // 这里可以添加权限检查逻辑
      // 例如检查 FOREGROUND_SERVICE 权限
      return true;
    } catch (e) {
      logger.error('❌ 检查前台服务权限失败: $e');
      return false;
    }
  }
}
