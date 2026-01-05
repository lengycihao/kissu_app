/// 敏感操作记录数据类
class SensitiveRecord {
  final String iconPath;
  final String content;
  final String time;
  final String subtitle;

  SensitiveRecord({
    required this.iconPath,
    required this.content,
    required this.time,
    this.subtitle = "",
  });
}
