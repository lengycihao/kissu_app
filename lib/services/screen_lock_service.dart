import 'dart:async';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kissu_app/services/sensitive_data_service.dart';
import 'package:kissu_app/utils/debug_util.dart';

/// 锁屏/解锁事件监听服务
/// 
/// 负责监听Android原生层的锁屏和解锁事件，并触发敏感数据上报
/// 
/// 功能特点：
/// 1. 通过EventChannel接收Android原生锁屏/解锁事件
/// 2. 自动触发敏感数据上报服务
/// 3. 提供完整的生命周期管理
/// 4. 支持隐私合规检查
/// 
/// 使用场景：
/// - 用户锁屏/解锁手机时自动上报
/// - 配合敏感数据上报服务使用
/// 
/// @author AI Assistant
/// @date 2025-10-15
class ScreenLockService extends GetxService {
  static ScreenLockService get instance => Get.find<ScreenLockService>();
  
  // EventChannel 用于接收Android原生锁屏/解锁事件
  static const EventChannel _eventChannel = EventChannel('kissu_app/screen_lock');
  
  // 事件流订阅
  StreamSubscription<dynamic>? _eventSubscription;
  
  // 是否已初始化
  bool _isInitialized = false;

  // 轻量本地去重：记录上一次上报的事件类型与时间戳（秒）
  String? _lastEventType;
  int? _lastEventTimestampSeconds;
  
  @override
  void onInit() {
    super.onInit();
    DebugUtil.info('ScreenLockService 初始化');
  }
  
  @override
  void onClose() {
    stopListening();
    super.onClose();
  }
  
  /// 开始监听锁屏/解锁事件
  /// 
  /// 注意：需要在隐私政策同意后调用
  void startListening() {
    if (_isInitialized) {
      DebugUtil.warning('锁屏监听服务已经启动，跳过重复初始化');
      return;
    }
    
    try {
      DebugUtil.info('开始启动锁屏监听服务...');
      
      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
        _handleScreenEvent,
        onError: _handleError,
        onDone: _handleDone,
      );
      
      _isInitialized = true;
      DebugUtil.success('锁屏监听服务启动成功');
    } catch (e) {
      DebugUtil.error('启动锁屏监听服务失败: $e');
    }
  }
  
  /// 停止监听锁屏/解锁事件
  void stopListening() {
    if (!_isInitialized) {
      return;
    }
    
    try {
      _eventSubscription?.cancel();
      _eventSubscription = null;
      _isInitialized = false;
      DebugUtil.info('锁屏监听服务已停止');
    } catch (e) {
      DebugUtil.error('停止锁屏监听服务失败: $e');
    }
  }
  
  /// 处理锁屏/解锁事件
  void _handleScreenEvent(dynamic event) {
  try {
    DebugUtil.info('🔍 原始锁屏事件数据: $event');
    DebugUtil.info('🔍 数据类型: ${event.runtimeType}');
    
    // ✅ 统一转换 Map 类型，确保类型安全
    if (event is Map) {
      final eventMap = Map<String, dynamic>.from(event);
      DebugUtil.info('✅ 数据类型验证通过: Map<String, dynamic>');
      
      // 打印所有键值对
      eventMap.forEach((key, value) {
        DebugUtil.info('🔍 键值对: $key => $value (${value.runtimeType})');
      });
      
      // 尝试提取字段（原生传入的事件类型与时间戳，时间戳为毫秒）
      dynamic rawEventType = eventMap['event_type'];
      dynamic rawTimestamp = eventMap['timestamp'];
      
      DebugUtil.info('🔍 原始event_type: $rawEventType (${rawEventType.runtimeType})');
      DebugUtil.info('🔍 原始timestamp: $rawTimestamp (${rawTimestamp.runtimeType})');
      
      // 安全类型转换
      String? eventType;
      int? timestampMillis;
      
      try {
        eventType = rawEventType as String?;
        DebugUtil.info('✅ event_type转换成功: $eventType');
      } catch (e) {
        DebugUtil.error('❌ event_type转换失败: $e');
      }
      
      try {
        // 注意 timestamp 可能是 double 或 num，这里统一转为毫秒整数
        timestampMillis = (rawTimestamp is num) ? rawTimestamp.toInt() : null;
        DebugUtil.info('✅ timestamp转换成功(毫秒): $timestampMillis');
      } catch (e) {
        DebugUtil.error('❌ timestamp转换失败: $e');
      }
      
      // 验证必要字段
      if (eventType == null || timestampMillis == null) {
        DebugUtil.warning('❌ 锁屏事件数据缺少必要字段 - eventType: $eventType, timestampMillis: $timestampMillis');
        return;
      }
      
      // 将毫秒时间戳转换为秒级时间戳，便于后端对齐
      final timestampSeconds = timestampMillis ~/ 1000;
      
      DebugUtil.success('✅ 收到有效锁屏事件: $eventType, 时间戳(秒): $timestampSeconds');

      // 轻量去重：同一类型事件在1秒内重复到达则丢弃，兜底部分ROM重复广播
      if (_lastEventType != null &&
          _lastEventTimestampSeconds != null &&
          _lastEventType == eventType) {
        final diff = (timestampSeconds - _lastEventTimestampSeconds!).abs();
        if (diff <= 1) {
          DebugUtil.warning(
              '⚠️ 1秒内收到重复锁屏事件($eventType)，已忽略，本次: $timestampSeconds, 上次: ${_lastEventTimestampSeconds!}');
          return;
        }
      }

      // 更新本地事件缓存
      _lastEventType = eventType;
      _lastEventTimestampSeconds = timestampSeconds;
      
      // 根据事件类型触发相应的上报
      switch (eventType) {
        case 'unlock':
          DebugUtil.info('🔓 处理解锁事件');
        _handleUnlockEvent(timestampSeconds);
          break;
        case 'lock':
          DebugUtil.info('🔒 处理锁屏事件');
        _handleLockEvent(timestampSeconds);
          break;
        default:
          DebugUtil.warning('❌ 未知的锁屏事件类型: $eventType');
      }
    } else {
      DebugUtil.warning('❌ 收到无效的锁屏事件数据类型: ${event.runtimeType}, 数据: $event');
    }
  } catch (e, stackTrace) {
    DebugUtil.error('❌ 处理锁屏事件时发生异常: $e');
    DebugUtil.error('❌ 异常堆栈: $stackTrace');
  }
}

  
  /// 处理解锁事件
  void _handleUnlockEvent([int? timestampSeconds]) {
    try {
      DebugUtil.info('处理手机解锁事件');
      
      // 检查敏感数据服务是否可用
      if (Get.isRegistered<SensitiveDataService>()) {
        final sensitiveDataService = SensitiveDataService.instance;
        sensitiveDataService.reportScreenUnlock(timestampSeconds: timestampSeconds);
      } else {
        DebugUtil.warning('敏感数据服务未注册，无法上报解锁事件');
      }
    } catch (e) {
      DebugUtil.error('处理解锁事件失败: $e');
    }
  }
  
  /// 处理锁屏事件
  void _handleLockEvent([int? timestampSeconds]) {
    try {
      DebugUtil.info('处理手机锁屏事件');
      
      // 检查敏感数据服务是否可用
      if (Get.isRegistered<SensitiveDataService>()) {
        final sensitiveDataService = SensitiveDataService.instance;
        sensitiveDataService.reportScreenLock(timestampSeconds: timestampSeconds);
      } else {
        DebugUtil.warning('敏感数据服务未注册，无法上报锁屏事件');
      }
    } catch (e) {
      DebugUtil.error('处理锁屏事件失败: $e');
    }
  }
  
  /// 处理事件流错误
  void _handleError(dynamic error) {
    DebugUtil.error('锁屏监听事件流发生错误: $error');
    
    // 尝试重新启动监听（延迟重试）
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isInitialized) {
        DebugUtil.info('尝试重新启动锁屏监听服务...');
        startListening();
      }
    });
  }
  
  /// 处理事件流结束
  void _handleDone() {
    DebugUtil.warning('锁屏监听事件流已结束');
    _isInitialized = false;
  }
  
  /// 获取服务状态信息
  Map<String, dynamic> getServiceStatus() {
    return {
      'isInitialized': _isInitialized,
      'hasSubscription': _eventSubscription != null,
      'serviceName': 'ScreenLockService',
    };
  }
  
  /// 手动触发解锁事件（用于测试）
  void triggerUnlockEvent() {
    DebugUtil.info('手动触发解锁事件（测试用）');
    _handleUnlockEvent();
  }
  
  /// 手动触发锁屏事件（用于测试）
  void triggerLockEvent() {
    DebugUtil.info('手动触发锁屏事件（测试用）');
    _handleLockEvent();
  }
  
  /// 处理测试事件（用于调试）
  void handleTestEvent(dynamic event) {
    DebugUtil.info('🧪 处理测试事件: $event');
    _handleScreenEvent(event);
  }
}
