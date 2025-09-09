import 'package:json_annotation/json_annotation.dart';

part 'datum.g.dart';

@JsonSerializable()
class Datum {
  String? content;
  @JsonKey(name: 'vip_check')
  int? vipCheck;
  @JsonKey(name: 'create_time')
  String? createTime;

  Datum({this.content, this.vipCheck, this.createTime});

  factory Datum.fromJson(Map<String, dynamic> json) => _$DatumFromJson(json);

  Map<String, dynamic> toJson() => _$DatumToJson(this);
}
