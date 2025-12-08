/// 最近使用的App数据（用于时间轴视图的横向滚动列表）
class LatelyUseAppData {
  /// App ID
  final String id;
  
  /// App名称
  final String appName;
  
  /// App包名
  final String appPkg;
  
  /// App Logo URL
  final String appLogo;
  
  LatelyUseAppData({
    required this.id,
    required this.appName,
    required this.appPkg,
    required this.appLogo,
  });
  
  factory LatelyUseAppData.fromJson(Map<String, dynamic> json) {
    return LatelyUseAppData(
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
  
  LatelyUseAppData copyWith({
    String? id,
    String? appName,
    String? appPkg,
    String? appLogo,
  }) {
    return LatelyUseAppData(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      appPkg: appPkg ?? this.appPkg,
      appLogo: appLogo ?? this.appLogo,
    );
  }
}

/// App打开记录详情（用于时间轴视图的详细记录列表）
class AppOpenRecordDetail {
  /// App包名（可选，用于logo缓存）
  final String appPkg;
  
  /// App Logo URL
  final String appLogo;
  
  /// App名称
  final String appName;
  
  /// 打开时间（格式：HH:mm）
  final String openTime;
  
  /// 使用时长文本（如："小于一分钟"）
  final String useDurationText;
  
  AppOpenRecordDetail({
    required this.appPkg,
    required this.appLogo,
    required this.appName,
    required this.openTime,
    required this.useDurationText,
  });
  
  factory AppOpenRecordDetail.fromJson(Map<String, dynamic> json) {
    return AppOpenRecordDetail(
      appPkg: json['app_pkg'] as String? ?? '',
      appLogo: json['app_logo'] as String? ?? '',
      appName: json['app_name'] as String? ?? '',
      openTime: json['open_time'] as String? ?? '',
      useDurationText: json['use_duration_text'] as String? ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'app_pkg': appPkg,
      'app_logo': appLogo,
      'app_name': appName,
      'open_time': openTime,
      'use_duration_text': useDurationText,
    };
  }
  
  AppOpenRecordDetail copyWith({
    String? appPkg,
    String? appLogo,
    String? appName,
    String? openTime,
    String? useDurationText,
  }) {
    return AppOpenRecordDetail(
      appPkg: appPkg ?? this.appPkg,
      appLogo: appLogo ?? this.appLogo,
      appName: appName ?? this.appName,
      openTime: openTime ?? this.openTime,
      useDurationText: useDurationText ?? this.useDurationText,
    );
  }
}

/// App打开记录详情响应数据模型
class AppOpenRecordDetailResponse {
  /// 最近使用的App列表（横向滚动）
  final List<LatelyUseAppData> latelyUseAppData;
  
  /// App打开记录详情列表
  final List<AppOpenRecordDetail> appOpenRecordDetail;
  
  AppOpenRecordDetailResponse({
    required this.latelyUseAppData,
    required this.appOpenRecordDetail,
  });
  
  factory AppOpenRecordDetailResponse.fromJson(Map<String, dynamic> json) {
    return AppOpenRecordDetailResponse(
      latelyUseAppData: (json['lately_use_app_data'] as List<dynamic>?)
          ?.map((e) => LatelyUseAppData.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      appOpenRecordDetail: (json['app_open_record_detail'] as List<dynamic>?)
          ?.map((e) => AppOpenRecordDetail.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'lately_use_app_data': latelyUseAppData.map((e) => e.toJson()).toList(),
      'app_open_record_detail': appOpenRecordDetail.map((e) => e.toJson()).toList(),
    };
  }
}

