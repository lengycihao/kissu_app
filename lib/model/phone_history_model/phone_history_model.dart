import 'package:json_annotation/json_annotation.dart';

import 'datum.dart';
import 'mobile_location_info.dart';
import 'user.dart';

part 'phone_history_model.g.dart';

@JsonSerializable()
class PhoneHistoryModel {
  List<Datum>? data;
  User? user;
  @JsonKey(name: 'mobile_location_info')
  MobileLocationInfo? mobileLocationInfo;

  PhoneHistoryModel({this.data, this.user, this.mobileLocationInfo});

  factory PhoneHistoryModel.fromJson(Map<String, dynamic> json) {
    return _$PhoneHistoryModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$PhoneHistoryModelToJson(this);
}
