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
      'longitude': longitude,
      'latitude': latitude,
      'location_time': locationTime,
      'speed': speed,
      'altitude': altitude,
      'location_name': locationName,
      'accuracy': accuracy,
    };
  }

  @override
  String toString() {
    return 'LocationReportModel(longitude: $longitude, latitude: $latitude, locationTime: $locationTime, speed: $speed, altitude: $altitude, locationName: $locationName, accuracy: $accuracy)';
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
