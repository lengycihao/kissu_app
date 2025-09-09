// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'datum.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Datum _$DatumFromJson(Map<String, dynamic> json) => Datum(
  content: json['content'] as String?,
  vipCheck: (json['vip_check'] as num?)?.toInt(),
  createTime: json['create_time'] as String?,
);

Map<String, dynamic> _$DatumToJson(Datum instance) => <String, dynamic>{
  'content': instance.content,
  'vip_check': instance.vipCheck,
  'create_time': instance.createTime,
};
