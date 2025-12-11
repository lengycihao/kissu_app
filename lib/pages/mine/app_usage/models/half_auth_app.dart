/// Ta当前授权过的App数据模型
class HalfAuthApp {
  /// App ID
  final String id;

  /// App名称
  final String appName;

  /// App包名
  final String appPkg;

  /// App Logo URL
  final String appLogo;

  HalfAuthApp({
    required this.id,
    required this.appName,
    required this.appPkg,
    required this.appLogo,
  });

  factory HalfAuthApp.fromJson(Map<String, dynamic> json) {
    return HalfAuthApp(
      id: json['_id'] as String? ?? '',
      appName: json['app_name'] as String? ?? '',
      appPkg: json['app_pkg'] as String? ?? '',
      appLogo: json['app_logo'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'app_name': appName,
      'app_pkg': appPkg,
      'app_logo': appLogo,
    };
  }
}

