import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:kissu_app/model/location_model/location_model.dart';

/// 位置数据更新助手
/// 
/// 提供统一的方法来更新位置相关的数据
class LocationDataHelper {
  /// 更新头像数据
  static void updateAvatarData({
    required UserLocationMobileDevice userData,
    required RxString avatarUrl,
    required Rx<Face?> face,
    Rx<OnlineStatus?>? onlineStatus,
  }) {
    if (userData.headPortrait != null && userData.headPortrait!.isNotEmpty) {
      avatarUrl.value = userData.headPortrait!;
    }
    face.value = userData.face;
    if (onlineStatus != null) {
      onlineStatus.value = userData.online;
    }
  }

  /// 更新位置坐标数据
  static void updateLocationData({
    required UserLocationMobileDevice userData,
    required Rx<LatLng?> location,
  }) {
    // 🔥 调试：打印原始经纬度值
    debugPrint('📍 [LocationDataHelper] 更新位置 - latitude: "${userData.latitude}", longitude: "${userData.longitude}"');
    
    if (userData.latitude != null && userData.longitude != null) {
      // 检查是否为空字符串
      final latStr = userData.latitude!.trim();
      final lngStr = userData.longitude!.trim();
      
      if (latStr.isNotEmpty && lngStr.isNotEmpty) {
        final lat = double.tryParse(latStr);
        final lng = double.tryParse(lngStr);
        if (lat != null && lng != null) {
          debugPrint('📍 [LocationDataHelper] 解析成功 - LatLng($lat, $lng)');
          location.value = LatLng(lat, lng);
          return;
        } else {
          debugPrint('📍 [LocationDataHelper] 解析失败 - lat: $lat, lng: $lng');
        }
      } else {
        debugPrint('📍 [LocationDataHelper] 经纬度为空字符串');
      }
    } else {
      debugPrint('📍 [LocationDataHelper] 经纬度为null');
    }
    // 🚀 修复：如果经纬度为空或解析失败，清空位置数据
    location.value = null;
  }

  /// 更新当前用户的详细数据
  static void updateCurrentUserData({
    required UserLocationMobileDevice userData,
    required Rx<LatLng?> myLocation,
    required RxString deviceModel,
    required RxString batteryLevel,
    required RxString networkName,
    required RxString speed,
    required RxString isWifi,
    required RxString locationTime,
    required RxString distance,
    required RxString updateTime,
    required RxString weatherIcon,
    required RxString weather,
    required RxString currentLocationText,
  }) {
    // 更新位置
    updateLocationData(userData: userData, location: myLocation);

    // 更新设备信息
    deviceModel.value = (userData.mobileModel?.isEmpty ?? true) ? "未知" : userData.mobileModel!;
    batteryLevel.value = (userData.power?.isEmpty ?? true) ? "未知" : userData.power!;
    networkName.value = (userData.networkName?.isEmpty ?? true) ? "未知" : userData.networkName!;
    speed.value = (userData.speed?.isEmpty ?? true) ? "0m/s" : userData.speed!;
    isWifi.value = userData.isWifi ?? "0";
    locationTime.value = userData.locationTime ?? "";
    distance.value = userData.distance ?? "未知";
    updateTime.value = userData.calculateLocationTime ?? "未知";

    // 更新天气信息
    if (userData.lives?.base != null && userData.lives!.base!.isNotEmpty) {
      final baseWeather = userData.lives!.base!.first;
      weatherIcon.value = baseWeather.weatherIcon ?? "";
      weather.value = baseWeather.weather ?? "";
    } else {
      weatherIcon.value = "";
      weather.value = "";
    }

    // 更新位置文本
    currentLocationText.value = userData.location ?? "位置信息不可用";
  }

  /// 格式化时间范围
  static String formatTimeRange(String? startTime, String? endTime) {
    if (startTime == null) return '未知时间';

    try {
      if (startTime.contains(':')) {
        if (endTime != null && endTime.contains(':')) {
          return '$startTime - $endTime';
        } else {
          return startTime;
        }
      }
      return startTime;
    } catch (e) {
      return startTime;
    }
  }

  /// 从停留点创建位置记录
  static LocationRecord createLocationRecord(StopPoint stop) {
    return LocationRecord(
      time: formatTimeRange(stop.startTime, stop.endTime),
      locationName: stop.locationName ?? '未知位置',
      distance: '0km',
      duration: stop.duration ?? '未知',
      startTime: stop.startTime,
      endTime: stop.endTime,
      status: stop.status,
      latitude: stop.latitude != null ? double.tryParse(stop.latitude!) : null,
      longitude: stop.longitude != null ? double.tryParse(stop.longitude!) : null,
    );
  }
}

/// 位置记录数据类
class LocationRecord {
  final String? time;
  final String? locationName;
  final String? distance;
  final String? duration;
  final String? startTime;
  final String? endTime;
  final String? status;
  final double? latitude;
  final double? longitude;

  LocationRecord({
    this.time,
    this.locationName,
    this.distance,
    this.duration,
    this.startTime,
    this.endTime,
    this.status,
    this.latitude,
    this.longitude,
  });
}

