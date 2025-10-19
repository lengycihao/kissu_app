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
  final int? isOpenLocation;
  final int? isOneself;
  final String? distance;
  final List<StopPoint>? stops;
  final StayCollect? stayCollect;
  final String? headPortrait;
  final Face? face;
  final OnlineStatus? online;
  final LivesInfo? lives;

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
    this.isOpenLocation,
    this.isOneself,
    this.distance,
    this.stops,
    this.stayCollect,
    this.headPortrait,
    this.face,
    this.online,
    this.lives,
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
      isOpenLocation: json['is_open_location'],
      isOneself: json['is_oneself'],
      distance: json['distance'],
      stops: json['stops'] != null
          ? (json['stops'] as List).map((i) => StopPoint.fromJson(i)).toList()
          : null,
      stayCollect: json['stay_collect'] != null
          ? StayCollect.fromJson(json['stay_collect'])
          : null,
      headPortrait: json['head_portrait'],
      face: json['face'] != null && json['face'] is Map<String, dynamic> && (json['face'] as Map<String, dynamic>).isNotEmpty
          ? Face.fromJson(json['face'])
          : null,
      online: json['online'] != null
          ? OnlineStatus.fromJson(json['online'])
          : null,
      lives: json['lives'] != null
          ? LivesInfo.fromJson(json['lives'])
          : null,
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
      'is_open_location': isOpenLocation,
      'is_oneself': isOneself,
      'distance': distance,
      'stops': stops?.map((e) => e.toJson()).toList(),
      'stay_collect': stayCollect?.toJson(),
      'head_portrait': headPortrait,
      'face': face?.toJson(),
      'online': online?.toJson(),
      'lives': lives?.toJson(),
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

// 用户信息模型 - 匹配API响应中的user字段
class UserInfo {
  final String? headPortrait;
  final int? isVip;
  final int? isBind;
  final int? halfIsOpenLocation;
  final String? halfHeadPortrait;

  UserInfo({
    this.headPortrait,
    this.isVip,
    this.isBind,
    this.halfIsOpenLocation,
    this.halfHeadPortrait,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      headPortrait: json['head_portrait'],
      isVip: json['is_vip'],
      isBind: json['is_bind'],
      halfIsOpenLocation: json['half_is_open_location'],
      halfHeadPortrait: json['half_head_portrait'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'head_portrait': headPortrait,
      'is_vip': isVip,
      'is_bind': isBind,
      'half_is_open_location': halfIsOpenLocation,
      'half_head_portrait': halfHeadPortrait,
    };
  }
}

// TrackApi 使用的响应模型
class LocationResponse {
  final UserInfo? user;  // 用户信息
  final List<TrackLocation>? locations;  // 轨迹点列表
  final TraceData? trace;  // 轨迹数据

  LocationResponse({
    this.user,
    this.locations,
    this.trace,
  });

  factory LocationResponse.fromJson(Map<String, dynamic> json) {
    print('🔍 LocationResponse 解析JSON: ${json.keys.toList()}');
    
    return LocationResponse(
      user: json['user'] != null ? UserInfo.fromJson(json['user']) : null,
      locations: json['locations'] != null
          ? (json['locations'] as List)
              .map((i) => TrackLocation.fromJson(i))
              .toList()
          : null,
      trace: json['trace'] != null ? TraceData.fromJson(json['trace']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user?.toJson(),
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

// 在线状态模型
class OnlineStatus {
  final int? status;
  final String? updateTime;
  final int? problemId;

  OnlineStatus({
    this.status,
    this.updateTime,
    this.problemId,
  });

  factory OnlineStatus.fromJson(Map<String, dynamic> json) {
    return OnlineStatus(
      status: json['status'],
      updateTime: json['update_time'],
      problemId: json['problem_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'update_time': updateTime,
      'problem_id': problemId,
    };
  }
}

// 天气/生活信息模型
class LivesInfo {
  final List<BaseWeather>? base;
  final List<AllWeather>? all;

  LivesInfo({
    this.base,
    this.all,
  });

  factory LivesInfo.fromJson(Map<String, dynamic> json) {
    return LivesInfo(
      base: json['base'] != null
          ? (json['base'] as List).map((i) => BaseWeather.fromJson(i)).toList()
          : null,
      all: json['all'] != null
          ? (json['all'] as List).map((i) => AllWeather.fromJson(i)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'base': base?.map((e) => e.toJson()).toList(),
      'all': all?.map((e) => e.toJson()).toList(),
    };
  }
}

// 基础天气信息
class BaseWeather {
  final String? province;
  final String? city;
  final String? adcode;
  final String? weather;
  final String? temperature;
  final String? winddirection;
  final String? windpower;
  final String? humidity;
  final String? reporttime;
  final String? temperatureFloat;
  final String? humidityFloat;
  final String? weatherIcon;

  BaseWeather({
    this.province,
    this.city,
    this.adcode,
    this.weather,
    this.temperature,
    this.winddirection,
    this.windpower,
    this.humidity,
    this.reporttime,
    this.temperatureFloat,
    this.humidityFloat,
    this.weatherIcon,
  });

  factory BaseWeather.fromJson(Map<String, dynamic> json) {
    return BaseWeather(
      province: json['province'],
      city: json['city'],
      adcode: json['adcode'],
      weather: json['weather'],
      temperature: json['temperature'],
      winddirection: json['winddirection'],
      windpower: json['windpower'],
      humidity: json['humidity'],
      reporttime: json['reporttime'],
      temperatureFloat: json['temperature_float'],
      humidityFloat: json['humidity_float'],
      weatherIcon: json['weather_icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'province': province,
      'city': city,
      'adcode': adcode,
      'weather': weather,
      'temperature': temperature,
      'winddirection': winddirection,
      'windpower': windpower,
      'humidity': humidity,
      'reporttime': reporttime,
      'temperature_float': temperatureFloat,
      'humidity_float': humidityFloat,
      'weather_icon': weatherIcon,
    };
  }
}

// 完整天气预报信息
class AllWeather {
  final String? city;
  final String? adcode;
  final String? province;
  final String? reporttime;
  final List<WeatherCast>? casts;

  AllWeather({
    this.city,
    this.adcode,
    this.province,
    this.reporttime,
    this.casts,
  });

  factory AllWeather.fromJson(Map<String, dynamic> json) {
    return AllWeather(
      city: json['city'],
      adcode: json['adcode'],
      province: json['province'],
      reporttime: json['reporttime'],
      casts: json['casts'] != null
          ? (json['casts'] as List).map((i) => WeatherCast.fromJson(i)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'adcode': adcode,
      'province': province,
      'reporttime': reporttime,
      'casts': casts?.map((e) => e.toJson()).toList(),
    };
  }
}

// 天气预报详情
class WeatherCast {
  final String? date;
  final String? week;
  final String? dayweather;
  final String? nightweather;
  final String? daytemp;
  final String? nighttemp;
  final String? daywind;
  final String? nightwind;
  final String? daypower;
  final String? nightpower;
  final String? daytempFloat;
  final String? nighttempFloat;

  WeatherCast({
    this.date,
    this.week,
    this.dayweather,
    this.nightweather,
    this.daytemp,
    this.nighttemp,
    this.daywind,
    this.nightwind,
    this.daypower,
    this.nightpower,
    this.daytempFloat,
    this.nighttempFloat,
  });

  factory WeatherCast.fromJson(Map<String, dynamic> json) {
    return WeatherCast(
      date: json['date'],
      week: json['week'],
      dayweather: json['dayweather'],
      nightweather: json['nightweather'],
      daytemp: json['daytemp'],
      nighttemp: json['nighttemp'],
      daywind: json['daywind'],
      nightwind: json['nightwind'],
      daypower: json['daypower'],
      nightpower: json['nightpower'],
      daytempFloat: json['daytemp_float'],
      nighttempFloat: json['nighttemp_float'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'week': week,
      'dayweather': dayweather,
      'nightweather': nightweather,
      'daytemp': daytemp,
      'nighttemp': nighttemp,
      'daywind': daywind,
      'nightwind': nightwind,
      'daypower': daypower,
      'nightpower': nightpower,
      'daytemp_float': daytempFloat,
      'nighttemp_float': nighttempFloat,
    };
  }
}

// Face表情模型
class Face {
  final String? classId;
  final String? faceExpire;
  final String? id;
  final String? faceUrl;
  final String? className;
  final String? faceText;
  final String? createTime;

  Face({
    this.classId,
    this.faceExpire,
    this.id,
    this.faceUrl,
    this.className,
    this.faceText,
    this.createTime,
  });

  factory Face.fromJson(Map<String, dynamic> json) {
    return Face(
      classId: json['class_id'],
      faceExpire: json['face_expire'],
      id: json['id'],
      faceUrl: json['face_url'],
      className: json['class_name'],
      faceText: json['face_text'],
      createTime: json['create_time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'class_id': classId,
      'face_expire': faceExpire,
      'id': id,
      'face_url': faceUrl,
      'class_name': className,
      'face_text': faceText,
      'create_time': createTime,
    };
  }

  // 检查face数据是否有效
  bool get isValid => faceUrl != null && faceUrl!.isNotEmpty && faceText != null && faceText!.isNotEmpty;
}