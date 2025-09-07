import 'package:json_annotation/json_annotation.dart';

import 'half_user_info.dart';
import 'lover_info.dart';

part 'login_model.g.dart';

@JsonSerializable()
class LoginModel {
  int? id;
  String? phone;
  String? nickname;
  @JsonKey(name: 'head_portrait')
  String? headPortrait;
  int? gender;
  @JsonKey(name: 'lover_id')
  int? loverId;
  String? birthday;
  @JsonKey(name: 'half_uid')
  int? halfUid;
  int? status;
  @JsonKey(name: 'inviter_id')
  int? inviterId;
  @JsonKey(name: 'friend_code')
  String? friendCode;
  @JsonKey(name: 'friend_qr_code')
  String? friendQrCode;
  @JsonKey(name: 'is_for_ever_vip')
  int? isForEverVip;
  @JsonKey(name: 'vip_end_time')
  int? vipEndTime;
  String? channel;
  @JsonKey(name: 'mobile_model')
  String? mobileModel;
  @JsonKey(name: 'device_id')
  String? deviceId;
  @JsonKey(name: 'unique_id')
  String? uniqueId;
  @JsonKey(name: 'province_name')
  String? provinceName;
  @JsonKey(name: 'city_name')
  String? cityName;
  @JsonKey(name: 'bind_status')
  int? bindStatus;
  @JsonKey(name: 'lately_bind_time')
  int? latelyBindTime;
  @JsonKey(name: 'lately_unbind_time')
  int? latelyUnbindTime;
  @JsonKey(name: 'lately_login_time')
  int? latelyLoginTime;
  @JsonKey(name: 'lately_pay_time')
  int? latelyPayTime;
  @JsonKey(name: 'login_nums')
  int? loginNums;
  @JsonKey(name: 'open_app_nums')
  int? openAppNums;
  @JsonKey(name: 'lately_open_app_time')
  int? latelyOpenAppTime;
  @JsonKey(name: 'is_test')
  int? isTest;
  @JsonKey(name: 'is_order_vip')
  int? isOrderVip;
  @JsonKey(name: 'login_time')
  int? loginTime;
  @JsonKey(name: 'vip_end_date')
  String? vipEndDate;
  @JsonKey(name: 'is_vip')
  int? isVip;
  String? token;
  @JsonKey(name: 'im_sign')
  String? imSign;
  @JsonKey(name: 'is_perfect_information')
  int? isPerfectInformation;
  @JsonKey(name: 'half_user_info')
  HalfUserInfo? halfUserInfo;
  @JsonKey(name: 'lover_info')
  LoverInfo? loverInfo;

  LoginModel({
    this.id,
    this.phone,
    this.nickname,
    this.headPortrait,
    this.gender,
    this.loverId,
    this.birthday,
    this.halfUid,
    this.status,
    this.inviterId,
    this.friendCode,
    this.friendQrCode,
    this.isForEverVip,
    this.vipEndTime,
    this.channel,
    this.mobileModel,
    this.deviceId,
    this.uniqueId,
    this.provinceName,
    this.cityName,
    this.bindStatus,
    this.latelyBindTime,
    this.latelyUnbindTime,
    this.latelyLoginTime,
    this.latelyPayTime,
    this.loginNums,
    this.openAppNums,
    this.latelyOpenAppTime,
    this.isTest,
    this.isOrderVip,
    this.loginTime,
    this.vipEndDate,
    this.isVip,
    this.token,
    this.imSign,
    this.isPerfectInformation,
    this.halfUserInfo,
    this.loverInfo,
  });

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return _$LoginModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$LoginModelToJson(this);
}
