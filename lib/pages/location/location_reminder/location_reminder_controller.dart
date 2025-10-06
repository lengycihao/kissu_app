import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';

/// 位置提醒Controller
class LocationReminderController extends GetxController {
  // 位置提醒列表
  final RxList<LocationReminder> reminders = <LocationReminder>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    // 加载保存的位置提醒
    _loadReminders();
  }
  
  /// 加载位置提醒
  void _loadReminders() {
    // TODO: 从本地存储或后端加载位置提醒数据
    // 目前使用示例数据
    reminders.value = [
      // LocationReminder(
      //   id: '1',
      //   name: '经常去的健身房',
      //   address: '浙江省杭州市上城区远洋东街39G号中豪湘府中心·附近',
      //   icon: 'gym',
      //   note: '',
      //   latitude: 30.2741,
      //   longitude: 120.2206,
      // ),
    ];
  }
  
  /// 添加位置提醒
  void addReminder(LocationReminder reminder) {
    reminders.add(reminder);
    // TODO: 保存到本地存储或后端
    update();
  }
  
  /// 删除位置提醒
  void removeReminder(String id) {
    reminders.removeWhere((r) => r.id == id);
    // TODO: 从本地存储或后端删除
    update();
  }
  
  /// 编辑位置提醒
  void updateReminder(LocationReminder reminder) {
    final index = reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      reminders[index] = reminder;
      // TODO: 更新本地存储或后端
      update();
    }
  }
}

/// 位置提醒数据模型
class LocationReminder {
  final String id;
  final String name;
  final String address;
  final String icon; // icon类型标识
  final String note; // 备注
  final double latitude;
  final double longitude;
  final Uint8List? mapSnapshot; // 地图快照
  
  LocationReminder({
    required this.id,
    required this.name,
    required this.address,
    required this.icon,
    this.note = '',
    required this.latitude,
    required this.longitude,
    this.mapSnapshot,
  });
  
  LocationReminder copyWith({
    String? id,
    String? name,
    String? address,
    String? icon,
    String? note,
    double? latitude,
    double? longitude,
    Uint8List? mapSnapshot,
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
    );
  }
}

