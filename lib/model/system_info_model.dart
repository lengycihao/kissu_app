/// 系统信息数据模型
class SystemInfoModel {
  final int? id;
  final int? userId;
  final int isPushKissuMsg; // 是否打开kissu消息推送 1是 0否
  final int isPushSystemMsg; // 是否打开消息推送 1是 0否
  final int isPushPhoneStatusMsg; // 是否打开手机状态推送 1是 0否
  final int isPushLocationMsg; // 是否打开手机位置推送 1是 0否

  SystemInfoModel({
    this.id,
    this.userId,
    required this.isPushKissuMsg,
    required this.isPushSystemMsg,
    required this.isPushPhoneStatusMsg,
    required this.isPushLocationMsg,
  });

  factory SystemInfoModel.fromJson(Map<String, dynamic> json) {
    return SystemInfoModel(
      id: json['id'],
      userId: json['user_id'],
      isPushKissuMsg: json['is_push_kissu_msg'] ?? 0,
      isPushSystemMsg: json['is_push_system_msg'] ?? 0,
      isPushPhoneStatusMsg: json['is_push_phone_status_msg'] ?? 0,
      isPushLocationMsg: json['is_push_location_msg'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'is_push_kissu_msg': isPushKissuMsg,
      'is_push_system_msg': isPushSystemMsg,
      'is_push_phone_status_msg': isPushPhoneStatusMsg,
      'is_push_location_msg': isPushLocationMsg,
    };
  }

  /// 转换为设置接口需要的参数格式（字符串类型）
  Map<String, String> toSwitchParams() {
    return {
      'is_push_kissu_msg': isPushKissuMsg.toString(),
      'is_push_system_msg': isPushSystemMsg.toString(),
      'is_push_phone_status_msg': isPushPhoneStatusMsg.toString(),
      'is_push_location_msg': isPushLocationMsg.toString(),
    };
  }

  /// 创建副本并更新指定字段
  SystemInfoModel copyWith({
    int? id,
    int? userId,
    int? isPushKissuMsg,
    int? isPushSystemMsg,
    int? isPushPhoneStatusMsg,
    int? isPushLocationMsg,
  }) {
    return SystemInfoModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      isPushKissuMsg: isPushKissuMsg ?? this.isPushKissuMsg,
      isPushSystemMsg: isPushSystemMsg ?? this.isPushSystemMsg,
      isPushPhoneStatusMsg: isPushPhoneStatusMsg ?? this.isPushPhoneStatusMsg,
      isPushLocationMsg: isPushLocationMsg ?? this.isPushLocationMsg,
    );
  }
}
