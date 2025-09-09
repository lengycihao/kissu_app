// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginModel _$LoginModelFromJson(Map<String, dynamic> json) => LoginModel(
  id: const StringToIntConverter().fromJson(json['id']),
  phone: json['phone'] as String?,
  nickname: json['nickname'] as String?,
  headPortrait: json['head_portrait'] as String?,
  gender: const StringToIntConverter().fromJson(json['gender']),
  loverId: const StringToIntConverter().fromJson(json['lover_id']),
  birthday: json['birthday'] as String?,
  halfUid: const StringToIntConverter().fromJson(json['half_uid']),
  status: const StringToIntConverter().fromJson(json['status']),
  inviterId: const StringToIntConverter().fromJson(json['inviter_id']),
  friendCode: json['friend_code'] as String?,
  friendQrCode: json['friend_qr_code'] as String?,
  isForEverVip: const StringToIntConverter().fromJson(json['is_for_ever_vip']),
  vipEndTime: const StringToIntConverter().fromJson(json['vip_end_time']),
  channel: json['channel'] as String?,
  mobileModel: json['mobile_model'] as String?,
  deviceId: json['device_id'] as String?,
  uniqueId: json['unique_id'] as String?,
  provinceName: json['province_name'] as String?,
  cityName: json['city_name'] as String?,
  bindStatus: json['bind_status'],
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
  loginTime: const StringToIntConverter().fromJson(json['login_time']),
  vipEndDate: json['vip_end_date'] as String?,
  isVip: const StringToIntConverter().fromJson(json['is_vip']),
  token: json['token'] as String?,
  imSign: json['im_sign'] as String?,
  isPerfectInformation: const StringToIntConverter().fromJson(
    json['is_perfect_information'],
  ),
  halfUserInfo: json['half_user_info'] == null
      ? null
      : HalfUserInfo.fromJson(json['half_user_info'] as Map<String, dynamic>),
  loverInfo: json['lover_info'] == null
      ? null
      : LoverInfo.fromJson(json['lover_info'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LoginModelToJson(
  LoginModel instance,
) => <String, dynamic>{
  'id': const StringToIntConverter().toJson(instance.id),
  'phone': instance.phone,
  'nickname': instance.nickname,
  'head_portrait': instance.headPortrait,
  'gender': const StringToIntConverter().toJson(instance.gender),
  'lover_id': const StringToIntConverter().toJson(instance.loverId),
  'birthday': instance.birthday,
  'half_uid': const StringToIntConverter().toJson(instance.halfUid),
  'status': const StringToIntConverter().toJson(instance.status),
  'inviter_id': const StringToIntConverter().toJson(instance.inviterId),
  'friend_code': instance.friendCode,
  'friend_qr_code': instance.friendQrCode,
  'is_for_ever_vip': const StringToIntConverter().toJson(instance.isForEverVip),
  'vip_end_time': const StringToIntConverter().toJson(instance.vipEndTime),
  'channel': instance.channel,
  'mobile_model': instance.mobileModel,
  'device_id': instance.deviceId,
  'unique_id': instance.uniqueId,
  'province_name': instance.provinceName,
  'city_name': instance.cityName,
  'bind_status': instance.bindStatus,
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
  'login_time': const StringToIntConverter().toJson(instance.loginTime),
  'vip_end_date': instance.vipEndDate,
  'is_vip': const StringToIntConverter().toJson(instance.isVip),
  'token': instance.token,
  'im_sign': instance.imSign,
  'is_perfect_information': const StringToIntConverter().toJson(
    instance.isPerfectInformation,
  ),
  'half_user_info': instance.halfUserInfo,
  'lover_info': instance.loverInfo,
};
