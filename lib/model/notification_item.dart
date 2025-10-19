/// 通知设置项模型
class NotificationItem {
  /// 字段标识
  final String field;
  
  /// 是否选中 (1: 选中, 0: 未选中)
  final int isChecked;
  
  /// 标题
  final String title;

  const NotificationItem({
    required this.field,
    required this.isChecked,
    required this.title,
  });

  /// 从JSON创建对象
  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      field: json['field'] ?? '',
      isChecked: json['is_checked'] ?? 0,
      title: json['title'] ?? '',
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'field': field,
      'is_checked': isChecked,
      'title': title,
    };
  }

  /// 复制并修改选中状态
  NotificationItem copyWith({
    String? field,
    int? isChecked,
    String? title,
  }) {
    return NotificationItem(
      field: field ?? this.field,
      isChecked: isChecked ?? this.isChecked,
      title: title ?? this.title,
    );
  }

  /// 是否选中
  bool get checked => isChecked == 1;

  @override
  String toString() {
    return 'NotificationItem(field: $field, isChecked: $isChecked, title: $title)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationItem &&
        other.field == field &&
        other.isChecked == isChecked &&
        other.title == title;
  }

  @override
  int get hashCode {
    return Object.hash(field, isChecked, title);
  }
}
