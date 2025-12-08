/// App使用统计数据模型（用于"最近使用App"模块）
class AppUsageStatData {
  /// App ID
  final String id;
  
  /// App名称
  final String appName;
  
  /// App包名（用于logo缓存）
  final String appPkg;
  
  /// App Logo URL
  final String appLogo;
  
  /// 打开次数
  final int openAppNumber;
  
  /// 使用时长（秒）
  final int useAppDuration;
  
  /// 使用分钟数
  final int minutes;
  
  AppUsageStatData({
    required this.id,
    required this.appName,
    required this.appPkg,
    required this.appLogo,
    required this.openAppNumber,
    required this.useAppDuration,
    required this.minutes,
  });
  
  factory AppUsageStatData.fromJson(Map<String, dynamic> json) {
    return AppUsageStatData(
      id: json['_id'] as String? ?? '',
      appName: json['app_name'] as String? ?? '',
      appPkg: json['app_pkg'] as String? ?? '',
      appLogo: json['app_logo'] as String? ?? '',
      openAppNumber: json['open_app_number'] as int? ?? 0,
      useAppDuration: json['use_app_duration'] as int? ?? 0,
      minutes: json['minutes'] as int? ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'app_name': appName,
      'app_pkg': appPkg,
      'app_logo': appLogo,
      'open_app_number': openAppNumber,
      'use_app_duration': useAppDuration,
      'minutes': minutes,
    };
  }
  
  AppUsageStatData copyWith({
    String? id,
    String? appName,
    String? appPkg,
    String? appLogo,
    int? openAppNumber,
    int? useAppDuration,
    int? minutes,
  }) {
    return AppUsageStatData(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      appPkg: appPkg ?? this.appPkg,
      appLogo: appLogo ?? this.appLogo,
      openAppNumber: openAppNumber ?? this.openAppNumber,
      useAppDuration: useAppDuration ?? this.useAppDuration,
      minutes: minutes ?? this.minutes,
    );
  }
}

/// App使用统计响应数据模型
class AppUsageStatResponse {
  /// App使用统计数据列表
  final List<AppUsageStatData> appUseStatData;
  
  /// 总打开次数
  final int totalOpenAppNumber;
  
  /// 总使用时长（秒）
  final int totalUseAppDuration;
  
  AppUsageStatResponse({
    required this.appUseStatData,
    required this.totalOpenAppNumber,
    required this.totalUseAppDuration,
  });
  
  factory AppUsageStatResponse.fromJson(Map<String, dynamic> json) {
    return AppUsageStatResponse(
      appUseStatData: (json['app_use_stat_data'] as List<dynamic>?)
          ?.map((e) => AppUsageStatData.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      totalOpenAppNumber: json['total_open_app_number'] as int? ?? 0,
      totalUseAppDuration: json['total_use_app_duration'] as int? ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'app_use_stat_data': appUseStatData.map((e) => e.toJson()).toList(),
      'total_open_app_number': totalOpenAppNumber,
      'total_use_app_duration': totalUseAppDuration,
    };
  }
}

