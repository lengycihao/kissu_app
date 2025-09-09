import 'package:json_annotation/json_annotation.dart';

import 'half_user_info.dart';
import 'lover_info.dart';

part 'login_model.g.dart';

class StringToIntConverter implements JsonConverter<int?, dynamic> {
  const StringToIntConverter();

  @override
  int? fromJson(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  @override
  dynamic toJson(int? value) => value;
}

@JsonSerializable()
class LoginModel {
  @StringToIntConverter()
  int? id;
  String? phone;
  String? nickname;
  @JsonKey(name: 'head_portrait')
  String? headPortrait;
  @StringToIntConverter()
  int? gender;
  @JsonKey(name: 'lover_id')
  @StringToIntConverter()
  int? loverId;
  String? birthday;
  @JsonKey(name: 'half_uid')
  @StringToIntConverter()
  int? halfUid;
  @StringToIntConverter()
  int? status;
  @JsonKey(name: 'inviter_id')
  @StringToIntConverter()
  int? inviterId;
  @JsonKey(name: 'friend_code')
  String? friendCode;
  @JsonKey(name: 'friend_qr_code')
  String? friendQrCode;
  @JsonKey(name: 'is_for_ever_vip')
  @StringToIntConverter()
  int? isForEverVip;
  @JsonKey(name: 'vip_end_time')
  @StringToIntConverter()
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
  dynamic bindStatus;
  @JsonKey(name: 'lately_bind_time')
  @StringToIntConverter()
  int? latelyBindTime;
  @JsonKey(name: 'lately_unbind_time')
  @StringToIntConverter()
  int? latelyUnbindTime;
  @JsonKey(name: 'lately_login_time')
  @StringToIntConverter()
  int? latelyLoginTime;
  @JsonKey(name: 'lately_pay_time')
  @StringToIntConverter()
  int? latelyPayTime;
  @JsonKey(name: 'login_nums')
  @StringToIntConverter()
  int? loginNums;
  @JsonKey(name: 'open_app_nums')
  @StringToIntConverter()
  int? openAppNums;
  @JsonKey(name: 'lately_open_app_time')
  @StringToIntConverter()
  int? latelyOpenAppTime;
  @JsonKey(name: 'is_test')
  @StringToIntConverter()
  int? isTest;
  @JsonKey(name: 'is_order_vip')
  @StringToIntConverter()
  int? isOrderVip;
  @JsonKey(name: 'login_time')
  @StringToIntConverter()
  int? loginTime;
  @JsonKey(name: 'vip_end_date')
  String? vipEndDate;
  @JsonKey(name: 'is_vip')
  @StringToIntConverter()
  int? isVip;
  String? token;
  @JsonKey(name: 'im_sign')
  String? imSign;
  @JsonKey(name: 'is_perfect_information')
  @StringToIntConverter()
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
