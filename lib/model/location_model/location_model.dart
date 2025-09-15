class LocationResponseModel {
  final UserLocationMobileDevice? userLocationMobileDevice;
  final UserLocationMobileDevice? halfLocationMobileDevice;

  LocationResponseModel({
    this.userLocationMobileDevice,
    this.halfLocationMobileDevice,
  });

  factory LocationResponseModel.fromJson(Map<String, dynamic> json) {
    return LocationResponseModel(
      userLocationMobileDevice: json['user_location_mobile_device'] != null
          ? UserLocationMobileDevice.fromJson(json['user_location_mobile_device'])
          : null,
      halfLocationMobileDevice: json['half_location_mobile_device'] != null
          ? UserLocationMobileDevice.fromJson(json['half_location_mobile_device'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_location_mobile_device': userLocationMobileDevice?.toJson(),
      'half_location_mobile_device': halfLocationMobileDevice?.toJson(),
    };
  }
}

class UserLocationMobileDevice {
  final String? power;
  final String? networkName;
  final String? mobileModel;
  final String? isWifi;
  final String? longitude;
  final String? latitude;
  final String? location;
  final String? locationTime;
  final String? speed;
  final String? calculateLocationTime;
  final int? isOneself;
  final String? distance;
  final List<StopPoint>? stops;
  final StayCollect? stayCollect;
  final String? headPortrait;

  UserLocationMobileDevice({
    this.power,
    this.networkName,
    this.mobileModel,
    this.isWifi,
    this.longitude,
    this.latitude,
    this.location,
    this.locationTime,
    this.speed,
    this.calculateLocationTime,
    this.isOneself,
    this.distance,
    this.stops,
    this.stayCollect,
    this.headPortrait,
  });

  factory UserLocationMobileDevice.fromJson(Map<String, dynamic> json) {
    return UserLocationMobileDevice(
      power: json['power'],
      networkName: json['network_name'],
      mobileModel: json['mobile_model'],
      isWifi: json['is_wifi'],
      longitude: json['longitude'],
      latitude: json['latitude'],
      location: json['location'],
      locationTime: json['location_time'],
      speed: json['speed'],
      calculateLocationTime: json['calculate_location_time'],
      isOneself: json['is_oneself'],
      distance: json['distance'],
      stops: json['stops'] != null
          ? (json['stops'] as List).map((i) => StopPoint.fromJson(i)).toList()
          : null,
      stayCollect: json['stay_collect'] != null
          ? StayCollect.fromJson(json['stay_collect'])
          : null,
      headPortrait: json['head_portrait'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'power': power,
      'network_name': networkName,
      'mobile_model': mobileModel,
      'is_wifi': isWifi,
      'longitude': longitude,
      'latitude': latitude,
      'location': location,
      'location_time': locationTime,
      'speed': speed,
      'calculate_location_time': calculateLocationTime,
      'is_oneself': isOneself,
      'distance': distance,
      'stops': stops?.map((e) => e.toJson()).toList(),
      'stay_collect': stayCollect?.toJson(),
      'head_portrait': headPortrait,
    };
  }
}

class StopPoint {
  final String? latitude;
  final String? longitude;
  final String? locationName;
  final String? startTime;
  final String? endTime;
  final String? duration;
  final String? status;
  final String? pointType;
  final String? serialNumber;

  StopPoint({
    this.latitude,
    this.longitude,
    this.locationName,
    this.startTime,
    this.endTime,
    this.duration,
    this.status,
    this.pointType,
    this.serialNumber,
  });

  factory StopPoint.fromJson(Map<String, dynamic> json) {
    return StopPoint(
      latitude: json['latitude'],
      longitude: json['longitude'],
      locationName: json['location_name'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      duration: json['duration'],
      status: json['status'],
      pointType: json['point_type'],
      serialNumber: json['serial_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'start_time': startTime,
      'end_time': endTime,
      'duration': duration,
      'status': status,
      'point_type': pointType,
      'serial_number': serialNumber,
    };
  }
}

class StayCollect {
  final int? stayCount;
  final String? stayTime;
  final String? moveDistance;

  StayCollect({
    this.stayCount,
    this.stayTime,
    this.moveDistance,
  });

  factory StayCollect.fromJson(Map<String, dynamic> json) {
    return StayCollect(
      stayCount: json['stay_count'],
      stayTime: json['stay_time'],
      moveDistance: json['move_distance'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stay_count': stayCount,
      'stay_time': stayTime,
      'move_distance': moveDistance,
    };
  }
}

// TrackApi 使用的响应模型
class LocationResponse {
  final UserLocationMobileDevice? userLocationMobileDevice;
  final UserLocationMobileDevice? halfLocationMobileDevice;
  final List<TrackLocation>? locations;  // 轨迹点列表
  final TraceData? trace;  // 轨迹数据

  LocationResponse({
    this.userLocationMobileDevice,
    this.halfLocationMobileDevice,
    this.locations,
    this.trace,
  });

  factory LocationResponse.fromJson(Map<String, dynamic> json) {
    print('🔍 LocationResponse 解析JSON: ${json.keys.toList()}');
    
    return LocationResponse(
      // 优先检查标准字段名，如果不存在则尝试其他可能的字段名
      userLocationMobileDevice: json['user_location_mobile_device'] != null
          ? UserLocationMobileDevice.fromJson(json['user_location_mobile_device'])
          : json['user'] != null
              ? _createUserLocationFromUserData(json['user'], 1) // isOneself = 1
              : null,
      halfLocationMobileDevice: json['half_location_mobile_device'] != null
          ? UserLocationMobileDevice.fromJson(json['half_location_mobile_device'])
          : json['user'] != null
              ? _createUserLocationFromUserData(json['user'], 0) // isOneself = 0
              : null,
      locations: json['locations'] != null
          ? (json['locations'] as List)
              .map((i) => TrackLocation.fromJson(i))
              .toList()
          : null,
      trace: json['trace'] != null ? TraceData.fromJson(json['trace']) : null,
    );
  }

  /// 从user数据和trace数据创建UserLocationMobileDevice
  static UserLocationMobileDevice? _createUserLocationFromUserData(
    Map<String, dynamic> userData, 
    int isOneself
  ) {
    try {
      print('🔄 从user数据创建UserLocationMobileDevice, isOneself=$isOneself');
      
      return UserLocationMobileDevice(
        isOneself: isOneself,
        headPortrait: isOneself == 1 
            ? userData['head_portrait'] 
            : userData['half_head_portrait'],
        // 其他字段暂时为空，主要数据从trace中获取
        power: null,
        networkName: null,
        mobileModel: null,
        isWifi: null,
        longitude: null,
        latitude: null,
        location: null,
        locationTime: null,
        speed: null,
        calculateLocationTime: null,
        distance: null,
        stops: null, // stops数据从trace中获取
        stayCollect: null, // stayCollect数据从trace中获取
      );
    } catch (e) {
      print('❌ 创建UserLocationMobileDevice失败: $e');
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'user_location_mobile_device': userLocationMobileDevice?.toJson(),
      'half_location_mobile_device': halfLocationMobileDevice?.toJson(),
      'locations': locations?.map((e) => e.toJson()).toList(),
      'trace': trace?.toJson(),
    };
  }
}

// 轨迹位置点
class TrackLocation {
  final double lat;
  final double lng;
  final String? time;

  TrackLocation({
    required this.lat,
    required this.lng,
    this.time,
  });

  factory TrackLocation.fromJson(Map<String, dynamic> json) {
    return TrackLocation(
      lat: _parseDouble(json['lat'] ?? json['latitude']),
      lng: _parseDouble(json['lng'] ?? json['longitude']),
      time: json['time'],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': lat,
      'longitude': lng,
      'time': time,
    };
  }
}

// 轨迹数据
class TraceData {
  final List<TrackStopPoint> stops;
  final TrackPoint startPoint;
  final TrackPoint endPoint;
  final StayCollect? stayCollect;  // 🎯 添加统计数据字段

  TraceData({
    required this.stops,
    required this.startPoint,
    required this.endPoint,
    this.stayCollect,
  });

  factory TraceData.fromJson(Map<String, dynamic> json) {
    return TraceData(
      stops: json['stops'] != null
          ? (json['stops'] as List)
              .map((i) => TrackStopPoint.fromJson(i))
              .toList()
          : <TrackStopPoint>[],
      startPoint: json['start_point'] != null
          ? TrackPoint.fromJson(json['start_point'])
          : TrackPoint(lat: 0.0, lng: 0.0),
      endPoint: json['end_point'] != null
          ? TrackPoint.fromJson(json['end_point'])
          : TrackPoint(lat: 0.0, lng: 0.0),
      stayCollect: json['stay_collect'] != null  // 🎯 解析统计数据
          ? StayCollect.fromJson(json['stay_collect'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stops': stops.map((e) => e.toJson()).toList(),
      'start_point': startPoint.toJson(),
      'end_point': endPoint.toJson(),
      'stay_collect': stayCollect?.toJson(),  // 🎯 序列化统计数据
    };
  }
}

// 轨迹停留点
class TrackStopPoint {
  final double lat;
  final double lng;
  final String? locationName;
  final String? startTime;
  final String? endTime;
  final String? duration;
  final String? status;
  final String? pointType;
  final String? serialNumber;

  TrackStopPoint({
    required this.lat,
    required this.lng,
    this.locationName,
    this.startTime,
    this.endTime,
    this.duration,
    this.status,
    this.pointType,
    this.serialNumber,
  });

  factory TrackStopPoint.fromJson(Map<String, dynamic> json) {
    return TrackStopPoint(
      lat: _parseDoubleForStopPoint(json['lat'] ?? json['latitude']),
      lng: _parseDoubleForStopPoint(json['lng'] ?? json['longitude']),
      locationName: json['location_name'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      duration: json['duration'],
      status: json['status'],
      pointType: json['point_type'],
      serialNumber: json['serial_number'],
    );
  }

  static double _parseDoubleForStopPoint(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': lat,
      'longitude': lng,
      'location_name': locationName,
      'start_time': startTime,
      'end_time': endTime,
      'duration': duration,
      'status': status,
      'point_type': pointType,
      'serial_number': serialNumber,
    };
  }
}

// 轨迹点
class TrackPoint {
  final double lat;
  final double lng;

  TrackPoint({
    required this.lat,
    required this.lng,
  });

  factory TrackPoint.fromJson(Map<String, dynamic> json) {
    return TrackPoint(
      lat: _parseDoubleForTrackPoint(json['lat'] ?? json['latitude']),
      lng: _parseDoubleForTrackPoint(json['lng'] ?? json['longitude']),
    );
  }

  static double _parseDoubleForTrackPoint(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': lat,
      'longitude': lng,
    };
  }
}