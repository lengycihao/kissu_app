/// 每小时的应用使用记录（用于统计视图）
class HourlyAppRecord {
  /// App名称
  final String appName;
  
  /// App包名
  final String appPkg;
  
  /// 小时键（字符串格式，如"18"）
  final String hourKey;
  
  /// App Logo URL
  final String appLogo;
  
  /// 总使用时长（秒）
  final int totalUseDuration;
  
  /// 使用次数
  final int useCount;
  
  /// 使用时长文本（如："小于一分钟"、"2分钟"）
  final String useAppDurationMinutes;
  
  HourlyAppRecord({
    required this.appName,
    required this.appPkg,
    required this.hourKey,
    required this.appLogo,
    required this.totalUseDuration,
    required this.useCount,
    required this.useAppDurationMinutes,
  });
  
  factory HourlyAppRecord.fromJson(Map<String, dynamic> json) {
    return HourlyAppRecord(
      appName: json['app_name'] as String? ?? '',
      appPkg: json['app_pkg'] as String? ?? '',
      hourKey: json['hour_key']?.toString() ?? '',
      appLogo: json['app_logo'] as String? ?? '',
      totalUseDuration: json['total_use_duration'] as int? ?? 0,
      useCount: json['use_count'] as int? ?? 0,
      useAppDurationMinutes: json['use_app_duration_minutes'] as String? ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'app_name': appName,
      'app_pkg': appPkg,
      'hour_key': hourKey,
      'app_logo': appLogo,
      'total_use_duration': totalUseDuration,
      'use_count': useCount,
      'use_app_duration_minutes': useAppDurationMinutes,
    };
  }
  
  HourlyAppRecord copyWith({
    String? appName,
    String? appPkg,
    String? hourKey,
    String? appLogo,
    int? totalUseDuration,
    int? useCount,
    String? useAppDurationMinutes,
  }) {
    return HourlyAppRecord(
      appName: appName ?? this.appName,
      appPkg: appPkg ?? this.appPkg,
      hourKey: hourKey ?? this.hourKey,
      appLogo: appLogo ?? this.appLogo,
      totalUseDuration: totalUseDuration ?? this.totalUseDuration,
      useCount: useCount ?? this.useCount,
      useAppDurationMinutes: useAppDurationMinutes ?? this.useAppDurationMinutes,
    );
  }
}

/// 每小时的使用记录组（用于统计视图）
class HourlyAppRecordGroup {
  /// 小时键（整数，如18、17）
  final int hourKey;
  
  /// 该小时的记录列表
  final List<HourlyAppRecord> recordList;
  
  HourlyAppRecordGroup({
    required this.hourKey,
    required this.recordList,
  });
  
  factory HourlyAppRecordGroup.fromJson(Map<String, dynamic> json) {
    // hour_key 可能是整数或字符串格式（如 "00"、"01"、"18"）
    int hourKeyValue = 0;
    final hourKey = json['hour_key'];
    if (hourKey != null) {
      if (hourKey is int) {
        hourKeyValue = hourKey;
      } else if (hourKey is String) {
        // 字符串格式，如 "00"、"01"、"18"
        hourKeyValue = int.tryParse(hourKey) ?? 0;
      } else {
        // 其他类型，尝试转换为字符串再解析
        hourKeyValue = int.tryParse(hourKey.toString()) ?? 0;
      }
    }
    
    return HourlyAppRecordGroup(
      hourKey: hourKeyValue,
      recordList: (json['record_list'] as List<dynamic>?)
          ?.map((e) => HourlyAppRecord.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'hour_key': hourKey,
      'record_list': recordList.map((e) => e.toJson()).toList(),
    };
  }
  
  /// 将hour_key转换为HH:00格式
  String get hourKeyFormatted {
    return '${hourKey.toString().padLeft(2, '0')}:00';
  }
}

/// 统计视图响应数据模型
class HourlyAppRecordResponse {
  /// 每小时的使用记录组列表
  final List<HourlyAppRecordGroup> hourlyRecords;
  
  HourlyAppRecordResponse({
    required this.hourlyRecords,
  });
  
  factory HourlyAppRecordResponse.fromJson(List<dynamic> json) {
    return HourlyAppRecordResponse(
      hourlyRecords: json
          .map((e) => HourlyAppRecordGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
  
  List<dynamic> toJson() {
    return hourlyRecords.map((e) => e.toJson()).toList();
  }
}

