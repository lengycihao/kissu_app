import 'package:flutter/material.dart';

/// 定位/足迹异常记录模型
class LocationAnomalyModel {
  final String id;
  final String locationName; // 位置名称
  final double latitude; // 纬度
  final double longitude; // 经度
  final String timeRange; // 时间范围，如 "14:30-17:12"
  final LocationAnomalyType type; // 异常类型
  final ExceptionSubType? exceptionSubType; // 异常子类型（仅当type为exception时有效）
  final String? avatarUrl; // 头像URL（用于地图标记）

  LocationAnomalyModel({
    required this.id,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.timeRange,
    required this.type,
    this.exceptionSubType,
    this.avatarUrl,
  });
}

/// 定位/足迹异常类型
enum LocationAnomalyType {
  stay, // 停留点
  move, // 移动
  location, // 定位
  exception, // 疑似异常点
  // yishi, // 疑似更改手机定位
}

/// 异常子类型（当LocationAnomalyType为exception时）
enum ExceptionSubType {
  speed, // 速度异常
  stayDuration, // 停留时长异常
}

/// 扩展方法，用于获取异常类型的显示信息
extension LocationAnomalyTypeExtension on LocationAnomalyType {
  /// 获取类型图标路径
  String get iconPath {
    switch (this) {
      case LocationAnomalyType.stay:
        return 'assets/phone_history/kissu3_history_stay.webp';
      case LocationAnomalyType.move:
        return 'assets/phone_history/kissu3_history_info_go.webp';
      case LocationAnomalyType.location:
        return 'assets/phone_history/kissu3_history_location.webp';
      case LocationAnomalyType.exception:
        return 'assets/phone_history/kissu3_history_yichang.webp'; 
    }
  }

  /// 获取类型标题
  String get title {
    switch (this) {
      case LocationAnomalyType.stay:
        return '停留';
      case LocationAnomalyType.move:
        return '移动';
      case LocationAnomalyType.location:
        return '定位';
      case LocationAnomalyType.exception:
        return '异常';
      // case LocationAnomalyType.yishi:
      //   return '疑似更改手机定位';
    }
  }

  /// 获取地图圆形颜色配置
  MapCircleConfig get circleConfig {
    switch (this) {
      case LocationAnomalyType.stay:
        return MapCircleConfig(
          fillColor: const Color(0x663B96FF), // 40% opacity
          strokeColor: const Color(0x66B9DAFF), // 40% opacity
          radius: 30.0,
          strokeWidth: 6.0,
        );
      case LocationAnomalyType.exception:
        return MapCircleConfig(
          fillColor: const Color(0x66FF9694), // 40% opacity
          strokeColor: const Color(0x66FFD5D5), // 40% opacity
          radius: 30.0,
          strokeWidth: 6.0,
        );
      default:
        // 其他类型不显示圆形
        return MapCircleConfig(
          fillColor: const Color(0x00000000),
          strokeColor: const Color(0x00000000),
          radius: 0.0,
          strokeWidth: 0.0,
        );
    }
  }
}

/// 地图圆形配置
class MapCircleConfig {
  final Color fillColor;
  final Color strokeColor;
  final double radius;
  final double strokeWidth;

  const MapCircleConfig({
    required this.fillColor,
    required this.strokeColor,
    required this.radius,
    required this.strokeWidth,
  });
}

