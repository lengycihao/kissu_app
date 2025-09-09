import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  @JsonKey(name: 'head_portrait')
  String? headPortrait;
  @JsonKey(name: 'is_vip')
  int? isVip;
  @JsonKey(name: 'is_bind')
  int? isBind;
  @JsonKey(name: 'half_head_portrait')
  String? halfHeadPortrait;

  User({this.headPortrait, this.isVip, this.isBind, this.halfHeadPortrait});

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
