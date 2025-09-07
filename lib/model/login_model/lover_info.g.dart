// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lover_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoverInfo _$LoverInfoFromJson(Map<String, dynamic> json) => LoverInfo(
  id: (json['id'] as num?)?.toInt(),
  phone: json['phone'] as String?,
  nickname: json['nickname'] as String?,
  headPortrait: json['head_portrait'] as String?,
  gender: (json['gender'] as num?)?.toInt(),
  birthday: json['birthday'] as String?,
  provinceName: json['province_name'] as String?,
  cityName: json['city_name'] as String?,
  bindTime: json['bind_time'] as String?,
  bindDate: json['bind_date'] as String?,
  loveTime: json['love_time'] as String?,
  loveDays: (json['love_days'] as num?)?.toInt(),
);

Map<String, dynamic> _$LoverInfoToJson(LoverInfo instance) => <String, dynamic>{
  'id': instance.id,
  'phone': instance.phone,
  'nickname': instance.nickname,
  'head_portrait': instance.headPortrait,
  'gender': instance.gender,
  'birthday': instance.birthday,
  'province_name': instance.provinceName,
  'city_name': instance.cityName,
  'bind_time': instance.bindTime,
  'bind_date': instance.bindDate,
  'love_time': instance.loveTime,
  'love_days': instance.loveDays,
};
