// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShareConfig _$ShareConfigFromJson(Map<String, dynamic> json) => ShareConfig(
  shareTitle: json['share_title'] as String?,
  shareIntroduction: json['share_introduction'] as String?,
  shareCover: json['share_cover'] as String?,
  sharePage: json['share_page'] as String?,
);

Map<String, dynamic> _$ShareConfigToJson(ShareConfig instance) =>
    <String, dynamic>{
      'share_title': instance.shareTitle,
      'share_introduction': instance.shareIntroduction,
      'share_cover': instance.shareCover,
      'share_page': instance.sharePage,
    };
