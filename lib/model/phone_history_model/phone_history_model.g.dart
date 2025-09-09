// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phone_history_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PhoneHistoryModel _$PhoneHistoryModelFromJson(Map<String, dynamic> json) =>
    PhoneHistoryModel(
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => Datum.fromJson(e as Map<String, dynamic>))
          .toList(),
      user: json['user'] == null
          ? null
          : User.fromJson(json['user'] as Map<String, dynamic>),
      mobileLocationInfo: json['mobile_location_info'] == null
          ? null
          : MobileLocationInfo.fromJson(
              json['mobile_location_info'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$PhoneHistoryModelToJson(PhoneHistoryModel instance) =>
    <String, dynamic>{
      'data': instance.data,
      'user': instance.user,
      'mobile_location_info': instance.mobileLocationInfo,
    };
