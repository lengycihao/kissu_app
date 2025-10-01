import 'package:json_annotation/json_annotation.dart';

part 'share_config.g.dart';

@JsonSerializable()
class ShareConfig {
  @JsonKey(name: 'share_title')
  String? shareTitle;
  
  @JsonKey(name: 'share_introduction')
  String? shareIntroduction;
  
  @JsonKey(name: 'share_cover')
  String? shareCover;
  
  @JsonKey(name: 'share_page')
  String? sharePage;

  ShareConfig({
    this.shareTitle,
    this.shareIntroduction,
    this.shareCover,
    this.sharePage,
  });

  factory ShareConfig.fromJson(Map<String, dynamic> json) {
    return _$ShareConfigFromJson(json);
  }

  Map<String, dynamic> toJson() => _$ShareConfigToJson(this);
}

