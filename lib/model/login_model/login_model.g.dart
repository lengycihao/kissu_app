// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginModel _$LoginModelFromJson(Map<String, dynamic> json) => LoginModel(
  id: (json['id'] as num?)?.toInt(),
  phone: json['phone'] as String?,
  nickname: json['nickname'] as String?,
  headPortrait: json['head_portrait'] as String?,
  gender: (json['gender'] as num?)?.toInt(),
  loverId: (json['lover_id'] as num?)?.toInt(),
  birthday: json['birthday'] as String?,
  halfUid: (json['half_uid'] as num?)?.toInt(),
  status: (json['status'] as num?)?.toInt(),
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
  bindStatus: (json['bind_status'] as num?)?.toInt(),
  latelyBindTime: (json['lately_bind_time'] as num?)?.toInt(),
  latelyUnbindTime: (json['lately_unbind_time'] as num?)?.toInt(),
  latelyLoginTime: (json['lately_login_time'] as num?)?.toInt(),
  latelyPayTime: (json['lately_pay_time'] as num?)?.toInt(),
  loginNums: (json['login_nums'] as num?)?.toInt(),
  openAppNums: (json['open_app_nums'] as num?)?.toInt(),
  latelyOpenAppTime: (json['lately_open_app_time'] as num?)?.toInt(),
  isTest: (json['is_test'] as num?)?.toInt(),
  isOrderVip: (json['is_order_vip'] as num?)?.toInt(),
  loginTime: (json['login_time'] as num?)?.toInt(),
  vipEndDate: json['vip_end_date'] as String?,
  isVip: (json['is_vip'] as num?)?.toInt(),
  token: json['token'] as String?,
  imSign: json['im_sign'] as String?,
  isPerfectInformation: (json['is_perfect_information'] as num?)?.toInt(),
  halfUserInfo: json['half_user_info'] == null
      ? null
      : HalfUserInfo.fromJson(json['half_user_info'] as Map<String, dynamic>),
  loverInfo: json['lover_info'] == null
      ? null
      : LoverInfo.fromJson(json['lover_info'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LoginModelToJson(LoginModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'phone': instance.phone,
      'nickname': instance.nickname,
      'head_portrait': instance.headPortrait,
      'gender': instance.gender,
      'lover_id': instance.loverId,
      'birthday': instance.birthday,
      'half_uid': instance.halfUid,
      'status': instance.status,
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
      'bind_status': instance.bindStatus,
      'lately_bind_time': instance.latelyBindTime,
      'lately_unbind_time': instance.latelyUnbindTime,
      'lately_login_time': instance.latelyLoginTime,
      'lately_pay_time': instance.latelyPayTime,
      'login_nums': instance.loginNums,
      'open_app_nums': instance.openAppNums,
      'lately_open_app_time': instance.latelyOpenAppTime,
      'is_test': instance.isTest,
      'is_order_vip': instance.isOrderVip,
      'login_time': instance.loginTime,
      'vip_end_date': instance.vipEndDate,
      'is_vip': instance.isVip,
      'token': instance.token,
      'im_sign': instance.imSign,
      'is_perfect_information': instance.isPerfectInformation,
      'half_user_info': instance.halfUserInfo,
      'lover_info': instance.loverInfo,
    };
