/// 位置上报数据模型
class LocationReportModel {
  final String longitude;  // 经度
  final String latitude;   // 纬度
  final String locationTime; // 定位时间（时间戳）
  final String speed;      // 时速
  final String altitude;   // 海拔
  final String locationName; // 地点
  final String accuracy;   // 精度

  LocationReportModel({
    required this.longitude,
    required this.latitude,
    required this.locationTime,
    required this.speed,
    required this.altitude,
    required this.locationName,
    required this.accuracy,
  });

  factory LocationReportModel.fromJson(Map<String, dynamic> json) {
    return LocationReportModel(
      longitude: json['longitude']?.toString() ?? '0.0',
      latitude: json['latitude']?.toString() ?? '0.0',
      locationTime: json['location_time']?.toString() ?? '0',
      speed: json['speed']?.toString() ?? '0.0',
      altitude: json['altitude']?.toString() ?? '0.0',
      locationName: json['location_name']?.toString() ?? '',
      accuracy: json['accuracy']?.toString() ?? '0.0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'longitude': longitude.toString(),      // 🎯 确保输出字符串
      'latitude': latitude.toString(),        // 🎯 确保输出字符串
      'location_time': locationTime.toString(), // 🎯 确保输出字符串
      'speed': speed.toString(),              // 🎯 确保输出字符串
      'altitude': altitude.toString(),        // 🎯 确保输出字符串
      'location_name': locationName.toString(), // 🎯 确保输出字符串
      // 🔧 修复：移除accuracy字段，与iOS原生版本和服务器API保持一致
      'accuracy': accuracy.toString(),     // ❌ 服务器不需要此字段
    };
  }

  @override
  String toString() {
    return 'LocationReportModel(longitude: $longitude, latitude: $latitude, locationTime: $locationTime, speed: $speed, altitude: $altitude, locationName: $locationName, accuracy: $accuracy)';
  }

  /// ✅ 数据验证：检查位置数据是否有效
  bool get isValid {
    try {
      // 检查经纬度是否为空
      if (latitude.isEmpty || longitude.isEmpty) {
        return false;
      }
      
      // 尝试解析为数字
      final lat = double.tryParse(latitude);
      final lng = double.tryParse(longitude);
      
      if (lat == null || lng == null) {
        return false;
      }
      
      // 检查经纬度范围
      // 纬度范围：-90 到 90
      // 经度范围：-180 到 180
      if (lat.abs() > 90 || lng.abs() > 180) {
        return false;
      }
      
      // 检查是否为0,0（无效坐标）
      if (lat == 0.0 && lng == 0.0) {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// ✅ 精度检查：是否为高质量定位
  bool get hasGoodAccuracy {
    try {
      final acc = double.tryParse(accuracy);
      return acc != null && acc > 0 && acc <= 100.0;
    } catch (e) {
      return false;
    }
  }

  /// ✅ 精度检查：是否为高精度定位（20米内）
  bool get hasHighAccuracy {
    try {
      final acc = double.tryParse(accuracy);
      return acc != null && acc > 0 && acc <= 20.0;
    } catch (e) {
      return false;
    }
  }

  /// ✅ 速度检查：是否在合理范围内（< 200 km/h）
  bool get hasReasonableSpeed {
    try {
      final spd = double.tryParse(speed);
      if (spd == null) return true; // 速度为空时不过滤
      // 速度单位是m/s，200km/h ≈ 55.6m/s
      return spd >= 0 && spd <= 55.6;
    } catch (e) {
      return true;
    }
  }

  /// ✅ 时间戳检查：是否为合理的时间戳
  bool get hasValidTimestamp {
    try {
      final timestamp = int.tryParse(locationTime);
      if (timestamp == null) return false;
      
      // 检查时间戳是否在合理范围内（10位秒时间戳）
      // 2020-01-01 到 2100-01-01
      final minTimestamp = 1577836800; // 2020-01-01 (10位秒)
      final maxTimestamp = 4102444800; // 2100-01-01 (10位秒)
      
      return timestamp >= minTimestamp && timestamp <= maxTimestamp;
    } catch (e) {
      return false;
    }
  }

  /// ✅ 综合验证：所有检查都通过
  bool get isFullyValid {
    return isValid && 
           hasGoodAccuracy && 
           hasReasonableSpeed && 
           hasValidTimestamp;
  }
}

/// 位置上报请求模型
class LocationReportRequest {
  final List<LocationReportModel> locations;

  LocationReportRequest({
    required this.locations,
  });

  factory LocationReportRequest.fromJson(Map<String, dynamic> json) {
    return LocationReportRequest(
      locations: json['locations'] != null
          ? (json['locations'] as List)
              .map((i) => LocationReportModel.fromJson(i))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'locations': locations.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'LocationReportRequest(locations: $locations)';
  }
}

/// 位置上报响应模型
class LocationReportResponse {
  final bool success;
  final String? message;
  final dynamic data;

  LocationReportResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory LocationReportResponse.fromJson(Map<String, dynamic> json) {
    return LocationReportResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
    };
  }
}
