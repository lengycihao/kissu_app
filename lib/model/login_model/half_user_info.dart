import 'package:json_annotation/json_annotation.dart';

part 'half_user_info.g.dart';

@JsonSerializable()
class HalfUserInfo {
  int? id;
  String? phone;
  String? nickname;
  @JsonKey(name: 'head_portrait')
  String? headPortrait;
  int? gender;
  String? birthday;
  @JsonKey(name: 'half_uid')
  int? halfUid;
  int? status;
  @JsonKey(name: 'lover_id')
  int? loverId;
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
  String? bindStatus;
  @JsonKey(name: 'lately_bind_time')
  String? latelyBindTime;
  @JsonKey(name: 'lately_unbind_time')
  String? latelyUnbindTime;
  @JsonKey(name: 'lately_login_time')
  String? latelyLoginTime;
  @JsonKey(name: 'lately_pay_time')
  String? latelyPayTime;
  @JsonKey(name: 'login_nums')
  String? loginNums;
  @JsonKey(name: 'open_app_nums')
  String? openAppNums;
  @JsonKey(name: 'lately_open_app_time')
  String? latelyOpenAppTime;
  @JsonKey(name: 'is_test')
  String? isTest;
  @JsonKey(name: 'is_order_vip')
  String? isOrderVip;
  @JsonKey(name: 'vip_end_date')
  String? vipEndDate;
  @JsonKey(name: 'is_vip')
  int? isVip;

  HalfUserInfo({
    this.id,
    this.phone,
    this.nickname,
    this.headPortrait,
    this.gender,
    this.birthday,
    this.halfUid,
    this.status,
    this.loverId,
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
    this.vipEndDate,
    this.isVip,
  });

  factory HalfUserInfo.fromJson(Map<String, dynamic> json) {
    return _$HalfUserInfoFromJson(json);
  }

  Map<String, dynamic> toJson() => _$HalfUserInfoToJson(this);
}
