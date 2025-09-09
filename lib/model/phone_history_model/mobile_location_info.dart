import 'package:json_annotation/json_annotation.dart';

part 'mobile_location_info.g.dart';

@JsonSerializable()
class MobileLocationInfo {
  String? power;
  @JsonKey(name: 'network_name')
  String? networkName;
  @JsonKey(name: 'mobile_model')
  String? mobileModel;
  @JsonKey(name: 'is_wifi')
  String? isWifi;
  @JsonKey(name: 'calculate_location_time')
  String? calculateLocationTime;
  String? distance;

  MobileLocationInfo({
    this.power,
    this.networkName,
    this.mobileModel,
    this.isWifi,
    this.calculateLocationTime,
    this.distance,
  });

  factory MobileLocationInfo.fromJson(Map<String, dynamic> json) {
    return _$MobileLocationInfoFromJson(json);
  }

  Map<String, dynamic> toJson() => _$MobileLocationInfoToJson(this);
}
