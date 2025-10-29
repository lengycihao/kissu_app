import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kissu_app/services/geofence_monitoring_service.dart';
import 'package:kissu_app/network/public/geofence_api.dart';
import 'package:kissu_app/services/permission_service.dart';
import 'package:kissu_app/widgets/dialogs/self_notification_permission_dialog.dart';
import 'package:kissu_app/services/tracking_service.dart';
import 'package:kissu_app/utils/debug_util.dart';

/// 位置提醒Controller
class LocationReminderController extends GetxController {
  static const String _storageKey = 'location_reminders';
  
  // 位置提醒列表
  final RxList<LocationReminder> reminders = <LocationReminder>[].obs;
  
  // API实例
  final _geofenceApi = GeofenceApi();
  
  // 加载状态
  final RxBool isLoading = false.obs;
  
  // 页面埋点相关
  DateTime? _pageEnterTime; // 页面进入时间
  int _scrollCount = 0; // 页面滑动次数
  
  @override
  void onInit() {
    super.onInit();
    // 记录页面进入时间
    _pageEnterTime = DateTime.now();
    // 从服务端加载位置提醒
    loadRemindersFromServer();
    // 启动围栏监测
    _startGeofenceMonitoring();
    // 检查通知权限
    _checkNotificationPermission();
  }
  
  /// 检查通知权限
  Future<void> _checkNotificationPermission() async {
    try {
      final permissionService = PermissionService();
      final hasPermission = await permissionService.isNotificationPermissionGranted();
      
      if (!hasPermission) {
        // 延迟一下，等待页面完全显示
        await Future.delayed(const Duration(milliseconds: 500));
        
        // 显示通知权限弹窗
        await SelfNotificationPermissionDialogUtil.show(
          onKnow: () {
            debugPrint('用户点击了知道了');
          },
          onGoSettings: () async {
            debugPrint('用户点击去开启通知权限');
            // 跳转到系统设置
            await permissionService.openNotificationSettings();
          },
        );
      }
    } catch (e) {
      debugPrint('❌ 检查通知权限失败: $e');
    }
  }
  
  @override
  void onClose() {
    // 上报页面浏览埋点
    _trackPageView();
    // 停止围栏监测
    _stopGeofenceMonitoring();
    super.onClose();
  }
  
  /// 增加滑动次数计数
  void incrementScrollCount() {
    _scrollCount++;
  }
  
  /// 上报页面浏览埋点
  Future<void> _trackPageView() async {
    if (_pageEnterTime == null) return;
    
    try {
      // 计算停留时长
      final duration = DateTime.now().difference(_pageEnterTime!);
      final seconds = duration.inSeconds;
      final stayDuration = '${seconds}s';
      
      // 上报埋点
      await TrackingService.trackLocationKnockListPageView(
        stayDuration: stayDuration,
        scrollTimes: _scrollCount,
      );
      
      DebugUtil.info('✅ 位置提醒列表页面浏览埋点上报成功');
    } catch (e) {
      DebugUtil.error('❌ 位置提醒列表页面浏览埋点上报失败: $e');
    }
  }
  
  /// 启动围栏监测
  void _startGeofenceMonitoring() {
    try {
      final service = Get.find<GeofenceMonitoringService>();
      service.startMonitoring();
      debugPrint('✅ 围栏监测已启动');
    } catch (e) {
      debugPrint('❌ 启动围栏监测失败: $e');
    }
  }
  
  /// 停止围栏监测
  void _stopGeofenceMonitoring() {
    try {
      final service = Get.find<GeofenceMonitoringService>();
      service.stopMonitoring();
      debugPrint('⏹️ 围栏监测已停止');
    } catch (e) {
      debugPrint('❌ 停止围栏监测失败: $e');
    }
  }
  
  /// 从服务端加载位置提醒列表
  Future<void> loadRemindersFromServer() async {
    try {
      isLoading.value = true;
      debugPrint('🌐 开始从服务端加载位置提醒...');
      
      final result = await _geofenceApi.getGeofencingList();
      
      if (result.isSuccess && result.data != null) {
        // 将服务端数据转换为LocationReminder对象
        final list = result.data!
            .map((json) => LocationReminder.fromServerJson(json))
            .toList();
        
        reminders.value = list;
        debugPrint('✅ 从服务端加载了 ${list.length} 个位置提醒');
        
        // 同步到本地存储（可选）
        await _saveRemindersToLocal();
      } else {
        debugPrint('⚠️ 服务端返回空数据或失败: ${result.msg}');
        // 如果服务端加载失败，尝试从本地加载
        await _loadRemindersFromLocal();
      }
    } catch (e) {
      debugPrint('❌ 从服务端加载位置提醒失败: $e');
      // 加载失败时尝试从本地加载
      await _loadRemindersFromLocal();
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 从本地加载位置提醒（作为备用）
  Future<void> _loadRemindersFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(jsonString);
        reminders.value = jsonList
            .map((json) => LocationReminder.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('✅ 从本地加载了 ${reminders.length} 个位置提醒');
      } else {
        reminders.value = [];
        debugPrint('📍 本地暂无保存的位置提醒');
      }
    } catch (e) {
      debugPrint('❌ 从本地加载位置提醒失败: $e');
      reminders.value = [];
    }
  }
  
  /// 保存位置提醒到本地（用于缓存）
  Future<void> _saveRemindersToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = reminders.map((r) => r.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await prefs.setString(_storageKey, jsonString);
      debugPrint('✅ 保存了 ${reminders.length} 个位置提醒到本地');
    } catch (e) {
      debugPrint('❌ 保存位置提醒到本地失败: $e');
    }
  }
  
  /// 保存位置提醒到本地
  // Future<void> _saveReminders() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final jsonList = reminders.map((r) => r.toJson()).toList();
  //     final jsonString = json.encode(jsonList);
  //     await prefs.setString(_storageKey, jsonString);
  //     debugPrint('✅ 保存了 ${reminders.length} 个位置提醒');
  //   } catch (e) {
  //     debugPrint('❌ 保存位置提醒失败: $e');
  //   }
  // }
  
  /// 添加位置提醒（调用服务端API）
  Future<bool> addReminder(LocationReminder reminder) async {
    try {
      debugPrint('🌐 开始保存位置提醒到服务端...');
      
      // 调用服务端API保存
      final result = await _geofenceApi.saveGeofencing(
        geoIcon: reminder.icon,
        geoAction: reminder.type == ReminderType.leave ? 1 : 2,
        longitude: reminder.longitude,
        latitude: reminder.latitude,
        geoRadius: reminder.radius.toInt(),
        remark: reminder.note.isNotEmpty ? reminder.note : null,
      );
      
      if (result.isSuccess) {
        debugPrint('✅ 位置提醒保存成功');
        // 保存成功后重新从服务端加载列表
        await loadRemindersFromServer();
        return true;
      } else {
        debugPrint('❌ 位置提醒保存失败: ${result.msg}');
        Get.snackbar(
          '保存失败',
          result.msg ?? '未知错误',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ 保存位置提醒异常: $e');
      Get.snackbar(
        '保存失败',
        '网络错误，请重试',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }
  
  /// 删除位置提醒（调用服务端API）
  Future<bool> removeReminder(String id) async {
    try {
      debugPrint('🌐 开始删除位置提醒: $id');
      
      // 调用服务端API删除
      final result = await _geofenceApi.deleteGeofencing(
        geofencingId: id,
      );
      
      if (result.isSuccess) {
        debugPrint('✅ 位置提醒删除成功');
        // 删除成功后重新从服务端加载列表
        await loadRemindersFromServer();
        return true;
      } else {
        debugPrint('❌ 位置提醒删除失败: ${result.msg}');
        Get.snackbar(
          '删除失败',
          result.msg ?? '未知错误',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ 删除位置提醒异常: $e');
      Get.snackbar(
        '删除失败',
        '网络错误，请重试',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }
  
  /// 编辑位置提醒（调用服务端API）
  Future<bool> updateReminder(LocationReminder reminder) async {
    try {
      debugPrint('🌐 开始更新位置提醒: ${reminder.id}');
      
      // 调用服务端API更新
      final result = await _geofenceApi.updateGeofencing(
        geofencingId: reminder.id,
        geoIcon: reminder.icon,
        geoAction: reminder.type == ReminderType.leave ? 1 : 2,
        longitude: reminder.longitude,
        latitude: reminder.latitude,
        geoRadius: reminder.radius.toInt(),
        remark: reminder.note.isNotEmpty ? reminder.note : null,
      );
      
      if (result.isSuccess) {
        debugPrint('✅ 位置提醒更新成功');
        // 更新成功后重新从服务端加载列表
        await loadRemindersFromServer();
        return true;
      } else {
        debugPrint('❌ 位置提醒更新失败: ${result.msg}');
        Get.snackbar(
          '更新失败',
          result.msg ?? '未知错误',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ 更新位置提醒异常: $e');
      Get.snackbar(
        '更新失败',
        '网络错误，请重试',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }
  
  // /// 切换提醒激活状态
  // Future<void> toggleReminderActive(String id) async {
  //   final index = reminders.indexWhere((r) => r.id == id);
  //   if (index != -1) {
  //     reminders[index] = reminders[index].copyWith(
  //       isActive: !reminders[index].isActive,
  //     );
  //     // await _saveReminders();
  //     update();
  //   }
  // }
}

/// 位置提醒类型
enum ReminderType {
  arrive, // 到达提醒
  leave,  // 离开提醒
}

/// 位置提醒数据模型
class LocationReminder {
  final String id;
  final String name;
  final String address;
  final int icon; // icon类型标识 (1-5)
  final String note; // 备注
  final double latitude;
  final double longitude;
  final Uint8List? mapSnapshot; // 地图快照
  final double radius; // 围栏半径（米）
  final ReminderType type; // 提醒类型（到达/离开）
  final bool isActive; // 是否激活
  final int mapType; // 地图类型 (1-经典地图, 2-卫星地图)
  
  LocationReminder({
    required this.id,
    required this.name,
    required this.address,
    required this.icon,
    this.note = '',
    required this.latitude,
    required this.longitude,
    this.mapSnapshot,
    this.radius = 100.0, // 默认100米
    this.type = ReminderType.arrive, // 默认到达提醒
    this.isActive = true, // 默认激活
    this.mapType = 1, // 默认经典地图
  });
  
  LocationReminder copyWith({
    String? id,
    String? name,
    String? address,
    int? icon,
    String? note,
    double? latitude,
    double? longitude,
    Uint8List? mapSnapshot,
    double? radius,
    ReminderType? type,
    bool? isActive,
    int? mapType,
  }) {
    return LocationReminder(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      icon: icon ?? this.icon,
      note: note ?? this.note,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      mapSnapshot: mapSnapshot ?? this.mapSnapshot,
      radius: radius ?? this.radius,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      mapType: mapType ?? this.mapType,
    );
  }
  
  /// 转换为JSON（用于本地存储）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'icon': icon,
      'note': note,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'type': type.index,
      'isActive': isActive,
      'mapType': mapType,
    };
  }
  
  /// 从JSON创建（本地存储格式）
  factory LocationReminder.fromJson(Map<String, dynamic> json) {
    return LocationReminder(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      icon: json['icon'] as int,
      note: json['note'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radius: (json['radius'] as num?)?.toDouble() ?? 100.0,
      type: ReminderType.values[json['type'] as int? ?? 0],
      isActive: json['isActive'] as bool? ?? true,
      mapType: json['mapType'] as int? ?? 1,
    );
  }
  
  /// 从服务端JSON创建
  /// 服务端字段映射:
  /// - _id -> id
  /// - geo_icon -> icon (1-5)
  /// - geo_action -> type (1=离开, 2=到达)
  /// - longitude -> longitude
  /// - latitude -> latitude
  /// - geo_radius -> radius
  /// - remark -> note
  /// - location -> address
  /// - map_type -> mapType (1=经典, 2=卫星)
  factory LocationReminder.fromServerJson(Map<String, dynamic> json) {
    // geo_action: 1=离开, 2=到达
    final geoAction = json['geo_action'] as int? ?? 2;
    final reminderType = geoAction == 1 ? ReminderType.leave : ReminderType.arrive;
    
    return LocationReminder(
      id: json['_id'] as String? ?? '',
      name: json['remark'] as String? ?? '位置提醒',
      address: json['location'] as String? ?? '',
      icon: json['geo_icon'] as int? ?? 1,
      note: json['remark'] as String? ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      radius: double.tryParse(json['geo_radius']?.toString() ?? '100') ?? 100.0,
      type: reminderType,
      isActive: true,
      mapSnapshot: null, // 服务端不返回地图快照
      mapType: json['map_type'] as int? ?? 1, // 默认经典地图
    );
  }
  
  /// 转换为服务端参数格式
  Map<String, dynamic> toServerParams() {
    return {
      'geo_icon': icon,
      'geo_action': type == ReminderType.leave ? 1 : 2, // 1=离开, 2=到达
      'longitude': longitude.toString(),
      'latitude': latitude.toString(),
      'geo_radius': radius.toInt().toString(),
      'map_type': mapType.toString(), // 地图类型 (1=经典, 2=卫星)
      if (note.isNotEmpty) 'remark': note,
    };
  }
}

