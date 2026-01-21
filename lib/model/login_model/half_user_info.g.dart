// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'half_user_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HalfUserInfo _$HalfUserInfoFromJson(Map<String, dynamic> json) => HalfUserInfo(
  id: (json['id'] as num?)?.toInt(),
  phone: json['phone'] as String?,
  nickname: json['nickname'] as String?,
  headPortrait: json['head_portrait'] as String?,
  gender: (json['gender'] as num?)?.toInt(),
  birthday: json['birthday'] as String?,
  halfUid: (json['half_uid'] as num?)?.toInt(),
  status: (json['status'] as num?)?.toInt(),
  loverId: (json['lover_id'] as num?)?.toInt(),
  inviterId: (json['inviter_id'] as num?)?.toInt(),
  friendCode: json['friend_code'] as String?,
  friendQrCode: json['friend_qr_code'] as String?,
  isForEverVip: (json['is_for_ever_vip'] as num?)?.toInt(),
  vipEndTime: (json['vip_end_time'] as num?)?.toInt(),
  channel: json['channel'] as String?,
  mobileModel: json['mobile_model'] as String?,
  deviceId: json['device_id'] as String?,
  uniqueId: json['unique_id'] as String?,
  provinceName: json['province_name'] as String?,
  cityName: json['city_name'] as String?,
  bindStatus: const StringToIntConverter().fromJson(json['bind_status']),
  latelyBindTime: const StringToIntConverter().fromJson(
    json['lately_bind_time'],
  ),
  latelyUnbindTime: const StringToIntConverter().fromJson(
    json['lately_unbind_time'],
  ),
  latelyLoginTime: const StringToIntConverter().fromJson(
    json['lately_login_time'],
  ),
  latelyPayTime: const StringToIntConverter().fromJson(json['lately_pay_time']),
  loginNums: const StringToIntConverter().fromJson(json['login_nums']),
  openAppNums: const StringToIntConverter().fromJson(json['open_app_nums']),
  latelyOpenAppTime: const StringToIntConverter().fromJson(
    json['lately_open_app_time'],
  ),
  isTest: const StringToIntConverter().fromJson(json['is_test']),
  isOrderVip: const StringToIntConverter().fromJson(json['is_order_vip']),
  vipEndDate: json['vip_end_date'] as String?,
  isVip: (json['is_vip'] as num?)?.toInt(),
);

Map<String, dynamic> _$HalfUserInfoToJson(
  HalfUserInfo instance,
) => <String, dynamic>{
  'id': instance.id,
  'phone': instance.phone,
  'nickname': instance.nickname,
  'head_portrait': instance.headPortrait,
  'gender': instance.gender,
  'birthday': instance.birthday,
  'half_uid': instance.halfUid,
  'status': instance.status,
  'lover_id': instance.loverId,
  'inviter_id': instance.inviterId,
  'friend_code': instance.friendCode,
  'friend_qr_code': instance.friendQrCode,
  'is_for_ever_vip': instance.isForEverVip,
  'vip_end_time': instance.vipEndTime,
  'channel': instance.channel,
  'mobile_model': instance.mobileModel,
  'device_id': instance.deviceId,
  'unique_id': instance.uniqueId,
  'province_name': instance.provinceName,
  'city_name': instance.cityName,
  'bind_status': const StringToIntConverter().toJson(instance.bindStatus),
  'lately_bind_time': const StringToIntConverter().toJson(
    instance.latelyBindTime,
  ),
  'lately_unbind_time': const StringToIntConverter().toJson(
    instance.latelyUnbindTime,
  ),
  'lately_login_time': const StringToIntConverter().toJson(
    instance.latelyLoginTime,
  ),
  'lately_pay_time': const StringToIntConverter().toJson(
    instance.latelyPayTime,
  ),
  'login_nums': const StringToIntConverter().toJson(instance.loginNums),
  'open_app_nums': const StringToIntConverter().toJson(instance.openAppNums),
  'lately_open_app_time': const StringToIntConverter().toJson(
    instance.latelyOpenAppTime,
  ),
  'is_test': const StringToIntConverter().toJson(instance.isTest),
  'is_order_vip': const StringToIntConverter().toJson(instance.isOrderVip),
  'vip_end_date': instance.vipEndDate,
  'is_vip': instance.isVip,
};
