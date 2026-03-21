import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/tools/logging/log_manager.dart';
import 'package:kissu_app/pages/location/location_reminder/location_reminder_controller.dart';
import 'package:kissu_app/services/simple_location_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 电子围栏监测服务
/// 
/// 功能：
/// 1. 实时监测用户位置
/// 2. 判断是否进入/离开围栏
/// 3. 触发提醒通知
class GeofenceMonitoringService extends GetxService {
  static GeofenceMonitoringService get instance => Get.find<GeofenceMonitoringService>();
  
  // 位置监听订阅
  StreamSubscription? _locationSubscription;
  
  // 围栏状态记录（记录每个围栏的进入/离开状态）
  final RxMap<String, bool> _geofenceStates = <String, bool>{}.obs;
  
  // 通知插件
  final FlutterLocalNotificationsPlugin _notificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  // 是否已初始化
  bool _isInitialized = false;
  
  @override
  void onInit() {
    super.onInit();
    _initializeNotifications();
  }
  
  @override
  void onClose() {
    stopMonitoring();
    super.onClose();
  }
  
  /// 初始化通知
  Future<void> _initializeNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      await _notificationsPlugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      _isInitialized = true;
      logger.debug('✅ 电子围栏通知初始化成功');
    } catch (e) {
      logger.error('❌ 电子围栏通知初始化失败: $e');
    }
  }
  
  /// 通知点击回调
  void _onNotificationTapped(NotificationResponse response) {
    logger.debug('📱 用户点击了围栏通知: ${response.payload}');
    // TODO: 可以跳转到位置提醒页面
  }
  
  /// 开始监测
  Future<void> startMonitoring() async {
    if (_locationSubscription != null) {
      logger.debug('⚠️ 围栏监测已在运行中');
      return;
    }
    
    try {
      // 订阅定位服务
      _locationSubscription = SimpleLocationService.instance.locationStream.listen(
        _onLocationUpdate,
        onError: (error) {
          logger.error('❌ 位置更新错误: $error');
        },
      );
      
      logger.debug('✅ 电子围栏监测已启动');
    } catch (e) {
      logger.error('❌ 启动围栏监测失败: $e');
    }
  }
  
  /// 停止监测
  void stopMonitoring() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    logger.debug('⏹️ 电子围栏监测已停止');
  }
  
  /// 位置更新回调
  void _onLocationUpdate(Map<String, Object> locationData) {
    try {
      // 从Map中提取经纬度
      final latitude = locationData['latitude'];
      final longitude = locationData['longitude'];
      
      if (latitude == null || longitude == null) {
        logger.warning('⚠️ 无效的位置数据,latitude: $latitude, longitude: $longitude');
        return;
      }
      
      final userLat = double.tryParse(latitude.toString());
      final userLng = double.tryParse(longitude.toString());
      
      if (userLat == null || userLng == null) {
        logger.warning('⚠️ 无法解析经纬度,latitude: $latitude, longitude: $longitude');
        return;
      }
      
      // 获取所有激活的围栏
      final controller = Get.find<LocationReminderController>();
      final activeReminders = controller.reminders.where((r) => r.isActive).toList();
      
      if (activeReminders.isEmpty) {
        return;
      }
      
      // 检查每个围栏
      for (final reminder in activeReminders) {
        _checkGeofence(reminder, userLat, userLng);
      }
    } catch (e) {
      logger.error('❌ 处理位置更新失败: $e');
    }
  }
  
  /// 检查单个围栏
  void _checkGeofence(LocationReminder reminder, double userLat, double userLng) {
    // 计算距离
    final distance = _calculateDistance(
      userLat,
      userLng,
      reminder.latitude,
      reminder.longitude,
    );
    
    // 判断是否在围栏内
    final isInside = distance <= reminder.radius;
    
    // 获取之前的状态
    final wasInside = _geofenceStates[reminder.id] ?? false;
    
    // 状态改变才触发
    if (isInside != wasInside) {
      _geofenceStates[reminder.id] = isInside;
      
      // 根据围栏类型和状态判断是否触发提醒
      bool shouldNotify = false;
      String notificationTitle = '';
      String notificationBody = '';
      
      if (reminder.type == ReminderType.arrive && isInside) {
        // 到达提醒：进入围栏时触发
        shouldNotify = true;
        notificationTitle = '📍 到达提醒';
        notificationBody = '你已到达 ${reminder.name}';
      } else if (reminder.type == ReminderType.leave && !isInside) {
        // 离开提醒：离开围栏时触发
        shouldNotify = true;
        notificationTitle = '🚶 离开提醒';
        notificationBody = '你已离开 ${reminder.name}';
      }
      
      if (shouldNotify) {
        _showNotification(
          reminder.id,
          notificationTitle,
          notificationBody,
          distance,
        );
        
        logger.debug('🔔 触发围栏提醒: ${reminder.name}, 类型=${reminder.type}, 距离=${distance.toStringAsFixed(1)}米');
      }
    }
  }
  
  /// 计算两点之间的距离（米）
  /// 使用 Haversine 公式
  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371000.0; // 地球半径（米）
    
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// 角度转弧度
  double _toRadians(double degree) {
    return degree * pi / 180.0;
  }
  
  /// 显示通知
  Future<void> _showNotification(
    String reminderId,
    String title,
    String body,
    double distance,
  ) async {
    if (!_isInitialized) {
      logger.warning('⚠️ 通知未初始化，跳过');
      return;
    }
    
    try {
      const androidDetails = AndroidNotificationDetails(
        'geofence_channel',
        '位置提醒',
        channelDescription: '电子围栏到达/离开提醒',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _notificationsPlugin.show(
        reminderId.hashCode, // 使用围栏ID的哈希作为通知ID
        title,
        '$body（距离: ${distance.toStringAsFixed(0)}米）',
        details,
        payload: reminderId,
      );
      
      logger.debug('✅ 通知已发送: $title - $body');
    } catch (e) {
      logger.error('❌ 发送通知失败: $e');
    }
  }
  
  /// 获取围栏状态（用于调试）
  Map<String, bool> getGeofenceStates() {
    return Map<String, bool>.from(_geofenceStates);
  }
  
  /// 重置所有围栏状态
  void resetGeofenceStates() {
    _geofenceStates.clear();
    logger.debug('🔄 围栏状态已重置');
  }
  
  /// 检查指定围栏的当前状态
  Future<Map<String, dynamic>> checkGeofenceStatus(String reminderId) async {
    try {
      final controller = Get.find<LocationReminderController>();
      final reminder = controller.reminders.firstWhere((r) => r.id == reminderId);
      
      // 获取当前位置（使用LocationReportModel）
      final locationModel = SimpleLocationService.instance.currentLocation.value;
      if (locationModel == null) {
        return {
          'success': false,
          'message': '无法获取当前位置',
        };
      }
      
      final userLat = double.parse(locationModel.latitude);
      final userLng = double.parse(locationModel.longitude);
      
      final distance = _calculateDistance(
        userLat,
        userLng,
        reminder.latitude,
        reminder.longitude,
      );
      
      final isInside = distance <= reminder.radius;
      
      return {
        'success': true,
        'reminderId': reminderId,
        'name': reminder.name,
        'distance': distance,
        'radius': reminder.radius,
        'isInside': isInside,
        'type': reminder.type.toString(),
      };
    } catch (e) {
      return {
        'success': false,
        'message': '检查围栏状态失败: $e',
      };
    }
  }
}

