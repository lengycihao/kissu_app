import 'dart:typed_data';

/// 应用使用会话记录（每次打开和关闭的完整记录）
/// 注意：打开时间和关闭时间是原始时间，不会被拆分
class AppUsageSession {
  /// 打开时间（进入前台的时间戳，毫秒）
  final int openTime;
  
  /// 关闭时间（离开前台的时间戳，毫秒）
  /// 包括：进入后台、应用被杀死等所有离开前台的情况
  final int closeTime;
  
  /// 使用时长（毫秒）
  int get duration => closeTime - openTime;
  
  AppUsageSession({
    required this.openTime,
    required this.closeTime,
  });
  
  factory AppUsageSession.fromJson(Map<String, dynamic> json) {
    return AppUsageSession(
      openTime: json['openTime'] as int,
      closeTime: json['closeTime'] as int,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'openTime': openTime,
      'closeTime': closeTime,
      'duration': duration,
    };
  }
  
  /// 格式化打开时间
  String get openTimeFormatted {
    final date = DateTime.fromMillisecondsSinceEpoch(openTime);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }
  
  /// 格式化关闭时间
  String get closeTimeFormatted {
    final date = DateTime.fromMillisecondsSinceEpoch(closeTime);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }
}

/// 每小时的使用记录
/// 说明：
/// - 会话列表包含该小时**开始**的所有会话（完整的打开/关闭时间）
/// - 如果会话跨小时（如14:50打开，15:10关闭），会话归属于14点
/// - 但totalDuration只计算该小时内的实际使用时长
class HourlyUsageRecord {
  /// 小时（0-23）
  final int hour;
  
  /// 该小时的总使用时长（毫秒）
  /// 注意：如果会话跨小时，只计算该小时内的部分
  final int totalDuration;
  
  /// 该小时开始的会话数（打开次数）
  final int sessionCount;
  
  /// 该小时开始的所有会话列表（完整的打开/关闭时间）
  final List<AppUsageSession> sessions;
  
  HourlyUsageRecord({
    required this.hour,
    required this.totalDuration,
    required this.sessionCount,
    required this.sessions,
  });
  
  factory HourlyUsageRecord.fromJson(Map<String, dynamic> json) {
    return HourlyUsageRecord(
      hour: json['hour'] as int,
      totalDuration: json['totalDuration'] as int,
      sessionCount: json['sessionCount'] as int? ?? 0,
      sessions: (json['sessions'] as List<dynamic>)
          .map((e) => AppUsageSession.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'totalDuration': totalDuration,
      'sessionCount': sessionCount,
      'sessions': sessions.map((e) => e.toJson()).toList(),
    };
  }
}

/// 应用使用记录（完整记录）
class AppUsageRecord {
  /// 应用名称
  final String appName;
  
  /// 包名
  final String packageName;
  
  /// 应用图标（用于显示，不上报）
  final Uint8List? icon;
  
  /// 应用图标的base64编码（用于上报）
  final String? iconBase64;
  
  /// 日期（yyyy-MM-dd）
  final String date;
  
  /// 每小时的使用记录（只包含有使用的小时）
  final List<HourlyUsageRecord> hourlyRecords;
  
  /// 当天总打开次数（原始会话总数，从Native直接获取）
  final int? totalSessions;
  
  /// 当天总使用时长（毫秒）
  int get totalDuration => hourlyRecords.fold(0, (sum, record) => sum + record.totalDuration);
  
  /// 当天总打开次数（优先使用Native返回的totalSessions，否则累加每小时的sessionCount）
  int get sessionCount => totalSessions ?? hourlyRecords.fold(0, (sum, record) => sum + record.sessionCount);
  
  /// 所有会话列表（按时间排序）
  List<AppUsageSession> get allSessions {
    final sessions = <AppUsageSession>[];
    for (final hourRecord in hourlyRecords) {
      sessions.addAll(hourRecord.sessions);
    }
    sessions.sort((a, b) => a.openTime.compareTo(b.openTime));
    return sessions;
  }
  
  AppUsageRecord({
    required this.appName,
    required this.packageName,
    this.icon,
    this.iconBase64,
    required this.date,
    required this.hourlyRecords,
    this.totalSessions,
  });
  
  factory AppUsageRecord.fromJson(Map<String, dynamic> json) {
    return AppUsageRecord(
      appName: json['appName'] as String,
      packageName: json['packageName'] as String,
      iconBase64: json['iconBase64'] as String?,
      date: json['date'] as String,
      totalSessions: json['totalSessions'] as int?,
      hourlyRecords: (json['hourlyRecords'] as List<dynamic>)
          .map((e) => HourlyUsageRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
  
  /// 转换为上报用的JSON（不包含icon字段）
  Map<String, dynamic> toUploadJson() {
    return {
      'appName': appName,
      'packageName': packageName,
      'iconBase64': iconBase64,
      'date': date,
      'totalDuration': totalDuration,
      'totalSessions': sessionCount,
      'hourlyRecords': hourlyRecords.map((e) => e.toJson()).toList(),
    };
  }
  
  /// 转换为完整JSON（包含所有字段）
  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'packageName': packageName,
      'iconBase64': iconBase64,
      'date': date,
      'totalSessions': totalSessions,
      'hourlyRecords': hourlyRecords.map((e) => e.toJson()).toList(),
    };
  }
}

/// 批量上报数据模型
class AppUsageBatchReport {
  /// 上报日期
  final String reportDate;
  
  /// 应用使用记录列表
  final List<AppUsageRecord> records;
  
  AppUsageBatchReport({
    required this.reportDate,
    required this.records,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'reportDate': reportDate,
      'records': records.map((e) => e.toUploadJson()).toList(),
    };
  }
}
