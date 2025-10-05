/// 敏感记录类型枚举
enum SensitiveRecordType {
  location, // 定位类型
  track, // 轨迹类型
  wifi, // WiFi类型
  battery, // 电量类型
  device, // 手机类型
}

/// WiFi操作类型枚举
enum WifiActionType {
  changed, // 更换wifi
  opened, // 开启权限
  closed, // 关闭权限
}

/// 敏感记录数据模型
class SensitiveRecordModel {
  final SensitiveRecordType type;
  final DateTime time;
  final String? locationDuration; // 定位：停留时长（如"2小时"）
  final int? trackPointCount; // 轨迹：停留点数量
  final WifiActionType? wifiActionType; // WiFi：操作类型
  final String? wifiName; // WiFi：WiFi名称
  final int? batteryLevel; // 电量：当前电量百分比
  final bool? isCharging; // 电量：是否充电中
  final String? deviceModel; // 设备：设备型号

  SensitiveRecordModel({
    required this.type,
    required this.time,
    this.locationDuration,
    this.trackPointCount,
    this.wifiActionType,
    this.wifiName,
    this.batteryLevel,
    this.isCharging,
    this.deviceModel,
  });

  /// 创建定位类型记录
  factory SensitiveRecordModel.location({
    required DateTime time,
    required String duration,
  }) {
    return SensitiveRecordModel(
      type: SensitiveRecordType.location,
      time: time,
      locationDuration: duration,
    );
  }

  /// 创建轨迹类型记录
  factory SensitiveRecordModel.track({
    required DateTime time,
    required int pointCount,
  }) {
    return SensitiveRecordModel(
      type: SensitiveRecordType.track,
      time: time,
      trackPointCount: pointCount,
    );
  }

  /// 创建WiFi类型记录
  factory SensitiveRecordModel.wifi({
    required DateTime time,
    required WifiActionType actionType,
    String? wifiName,
  }) {
    return SensitiveRecordModel(
      type: SensitiveRecordType.wifi,
      time: time,
      wifiActionType: actionType,
      wifiName: wifiName,
    );
  }

  /// 创建电量类型记录
  factory SensitiveRecordModel.battery({
    required DateTime time,
    required int batteryLevel,
    required bool isCharging,
  }) {
    return SensitiveRecordModel(
      type: SensitiveRecordType.battery,
      time: time,
      batteryLevel: batteryLevel,
      isCharging: isCharging,
    );
  }

  /// 创建设备类型记录
  factory SensitiveRecordModel.device({
    required DateTime time,
    required String deviceModel,
  }) {
    return SensitiveRecordModel(
      type: SensitiveRecordType.device,
      time: time,
      deviceModel: deviceModel,
    );
  }
}

