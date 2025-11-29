/// 通知设置响应数据模型
class NotificationSettingsResponse {
  final String classifyTitle;
  final List<NotificationStatusItem> statusList;

  NotificationSettingsResponse({
    required this.classifyTitle,
    required this.statusList,
  });

  factory NotificationSettingsResponse.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsResponse(
      classifyTitle: json['classify_title'] ?? '',
      statusList: (json['status_list'] as List<dynamic>?)
              ?.map((item) => NotificationStatusItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// 通知状态项
class NotificationStatusItem {
  final String field;
  final String title;
  final String subTitle;
  final int status;

  NotificationStatusItem({
    required this.field,
    required this.title,
    required this.subTitle,
    required this.status,
  });

  factory NotificationStatusItem.fromJson(Map<String, dynamic> json) {
    return NotificationStatusItem(
      field: json['field'] ?? '',
      title: json['title'] ?? '',
      subTitle: json['sub_title'] ?? '',
      status: json['status'] ?? 0,
    );
  }

  bool get isEnabled => status == 1;
}
