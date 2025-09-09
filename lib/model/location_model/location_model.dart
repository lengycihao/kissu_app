class LocationResponse {
  final List<Location> locations;
  final TraceData trace;
  final UserData user;

  LocationResponse({
    required this.locations,
    required this.trace,
    required this.user,
  });

  factory LocationResponse.fromJson(Map<String, dynamic> json) {
    return LocationResponse(
      locations: (json['locations'] as List<dynamic>? ?? [])
          .map((e) => Location.fromJson(e))
          .toList(),
      trace: TraceData.fromJson(json['trace'] ?? {}),
      user: UserData.fromJson(json['user'] ?? {}),
    );
  }
}

/// 位置数据点
class Location {
  final String longitude;
  final String latitude;

  Location({
    required this.longitude,
    required this.latitude,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      longitude: json['longitude'] ?? '',
      latitude: json['latitude'] ?? '',
    );
  }

  // 获取纬度的double值
  double get lat => double.tryParse(latitude) ?? 0.0;

  // 获取经度的double值
  double get lng => double.tryParse(longitude) ?? 0.0;
}

/// 轨迹数据
class TraceData {
  final StartPoint startPoint;
  final List<StopPoint> stops;
  final EndPoint endPoint;
  final StayCollect stayCollect;

  TraceData({
    required this.startPoint,
    required this.stops,
    required this.endPoint,
    required this.stayCollect,
  });

  factory TraceData.fromJson(Map<String, dynamic> json) {
    return TraceData(
      startPoint: StartPoint.fromJson(json['start_point'] ?? {}),
      stops: (json['stops'] as List<dynamic>? ?? [])
          .map((e) => StopPoint.fromJson(e))
          .toList(),
      endPoint: EndPoint.fromJson(json['end_point'] ?? {}),
      stayCollect: StayCollect.fromJson(json['stay_collect'] ?? {}),
    );
  }
}

/// 起点数据
class StartPoint {
  final String longitude;
  final String latitude;
  final String locationTime;
  final String locationName;

  StartPoint({
    required this.longitude,
    required this.latitude,
    required this.locationTime,
    required this.locationName,
  });

  factory StartPoint.fromJson(Map<String, dynamic> json) {
    return StartPoint(
      longitude: json['longitude'] ?? '',
      latitude: json['latitude'] ?? '',
      locationTime: json['location_time'] ?? '',
      locationName: json['location_name'] ?? '',
    );
  }

  // 获取纬度的double值
  double get lat => double.tryParse(latitude) ?? 0.0;

  // 获取经度的double值
  double get lng => double.tryParse(longitude) ?? 0.0;
}

/// 终点数据
class EndPoint {
  final String longitude;
  final String latitude;
  final int locationTime;
  final String locationName;

  EndPoint({
    required this.longitude,
    required this.latitude,
    required this.locationTime,
    required this.locationName,
  });

  factory EndPoint.fromJson(Map<String, dynamic> json) {
    return EndPoint(
      longitude: json['longitude'] ?? '',
      latitude: json['latitude'] ?? '',
      locationTime: _parseLocationTime(json['location_time']),
      locationName: json['location_name'] ?? '',
    );
  }
  
  static int _parseLocationTime(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // 获取纬度的double值
  double get lat => double.tryParse(latitude) ?? 0.0;

  // 获取经度的double值
  double get lng => double.tryParse(longitude) ?? 0.0;
}

/// 用户数据
class UserData {
  final String headPortrait;
  final int isVip;
  final int isBind;
  final String halfHeadPortrait;

  UserData({
    required this.headPortrait,
    required this.isVip,
    required this.isBind,
    required this.halfHeadPortrait,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      headPortrait: json['head_portrait'] ?? '',
      isVip: _parseInt(json['is_vip']),
      isBind: _parseInt(json['is_bind']),
      halfHeadPortrait: json['half_head_portrait'] ?? '',
    );
  }
  
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

/// 停留点数据
class StopPoint {
  final String latitude;
  final String longitude;
  final String locationName;
  final String startTime;
  final String endTime;
  final String duration;
  final String status; // staying 停留中, ended 已结束
  final String pointType; // start 起点, stop 停留点, end 终点
  final String serialNumber;

  StopPoint({
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.status,
    required this.pointType,
    required this.serialNumber,
  });

  factory StopPoint.fromJson(Map<String, dynamic> json) {
    return StopPoint(
      latitude: json['latitude'] ?? '',
      longitude: json['longitude'] ?? '',
      locationName: json['location_name'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      duration: json['duration'] ?? '',
      status: json['status'] ?? '',
      pointType: json['point_type'] ?? '',
      serialNumber: json['serial_number'] ?? '',
    );
  }

  // 获取纬度的double值
  double get lat => double.tryParse(latitude) ?? 0.0;

  // 获取经度的double值
  double get lng => double.tryParse(longitude) ?? 0.0;

  // 是否正在停留中
  bool get isStaying => status == 'staying';

  // 是否已结束
  bool get isEnded => status == 'ended';

  // 是否是起点
  bool get isStartPoint => pointType == 'start';

  // 是否是终点
  bool get isEndPoint => pointType == 'end';

  // 是否是停留点
  bool get isStopPoint => pointType == 'stop';

  // 获取时间范围显示文本（用于已结束状态）
  String get timeRangeText {
    if (isEnded && startTime.isNotEmpty && endTime.isNotEmpty) {
      return '$startTime ~ $endTime';
    }
    return '';
  }
}

class StayCollect {
  final int stayCount;
  final String stayTime;
  final String moveDistance;

  StayCollect({
    required this.stayCount,
    required this.stayTime,
    required this.moveDistance,
  });

  factory StayCollect.fromJson(Map<String, dynamic> json) {
    return StayCollect(
      stayCount: _parseInt(json['stay_count']),
      stayTime: json['stay_time'] ?? '',
      moveDistance: json['move_distance'] ?? '',
    );
  }
  
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
