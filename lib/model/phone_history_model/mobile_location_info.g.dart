// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mobile_location_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MobileLocationInfo _$MobileLocationInfoFromJson(Map<String, dynamic> json) =>
    MobileLocationInfo(
      power: json['power'] as String?,
      networkName: json['network_name'] as String?,
      mobileModel: json['mobile_model'] as String?,
      isWifi: json['is_wifi'] as String?,
      calculateLocationTime: json['calculate_location_time'] as String?,
      distance: json['distance'] as String?,
    );

Map<String, dynamic> _$MobileLocationInfoToJson(MobileLocationInfo instance) =>
    <String, dynamic>{
      'power': instance.power,
      'network_name': instance.networkName,
      'mobile_model': instance.mobileModel,
      'is_wifi': instance.isWifi,
      'calculate_location_time': instance.calculateLocationTime,
      'distance': instance.distance,
    };
