import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'track_controller.dart'; 
import 'widgets/track_page_layout.dart';

/// 轨迹页面主入口
/// 简化的入口类，负责参数传递和布局管理
class TrackPage extends StatelessWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialLocationName;
  final String? initialDuration;
  final String? initialStartTime;
  final String? initialEndTime;
  final bool autoShowInfoWindow;
  final int? targetUserType;

  const TrackPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialLocationName,
    this.initialDuration,
    this.initialStartTime,
    this.initialEndTime,
    this.autoShowInfoWindow = false,
    this.targetUserType,
  });

  @override
  Widget build(BuildContext context) {
    // 获取或创建控制器
    final controller = Get.isRegistered<TrackController>()
        ? Get.find<TrackController>()
        : Get.put(TrackController());

    // 设置初始坐标（如果提供）
    if (initialLatitude != null && initialLongitude != null) {
      controller.setInitialCoordinates(
        latitude: initialLatitude!,
        longitude: initialLongitude!,
        locationName: initialLocationName,
        duration: initialDuration,
        startTime: initialStartTime,
        endTime: initialEndTime,
        targetUserType: targetUserType,
      );
    }

    // 返回简化的布局组件
    return TrackPageLayout(controller: controller);
  }
}