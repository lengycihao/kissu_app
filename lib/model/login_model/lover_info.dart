import 'package:json_annotation/json_annotation.dart';

part 'lover_info.g.dart';

@JsonSerializable()
class LoverInfo {
  int? id;
  String? phone;
  String? nickname;
  @JsonKey(name: 'head_portrait')
  String? headPortrait;
  int? gender;
  String? birthday;
  @JsonKey(name: 'province_name')
  String? provinceName;
  @JsonKey(name: 'city_name')
  String? cityName;
  
  // 绑定关系相关字段
  @JsonKey(name: 'bind_time')
  String? bindTime;
  @JsonKey(name: 'bind_date')
  String? bindDate;
  @JsonKey(name: 'love_time')
  String? loveTime;
  @JsonKey(name: 'love_days')
  int? loveDays;
  
  LoverInfo({
    this.id,
    this.phone,
    this.nickname,
    this.headPortrait,
    this.gender,
    this.birthday,
    this.provinceName,
    this.cityName,
    this.bindTime,
    this.bindDate,
    this.loveTime,
    this.loveDays,
  });

  factory LoverInfo.fromJson(Map<String, dynamic> json) {
    return _$LoverInfoFromJson(json);
  }

  Map<String, dynamic> toJson() => _$LoverInfoToJson(this);
}
