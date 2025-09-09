// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  headPortrait: json['head_portrait'] as String?,
  isVip: (json['is_vip'] as num?)?.toInt(),
  isBind: (json['is_bind'] as num?)?.toInt(),
  halfHeadPortrait: json['half_head_portrait'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'head_portrait': instance.headPortrait,
  'is_vip': instance.isVip,
  'is_bind': instance.isBind,
  'half_head_portrait': instance.halfHeadPortrait,
};
