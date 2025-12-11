/// 用机记录统计数据模型
/// 对应新接口 /use/phone/record/stat
class PhoneRecordStatModel {
  final MobileUseRecord? mobileUseRecord;
  final AppUseRecord? appUseRecord;
  final List<SensitiveRecord> sensitiveRecord;
  final HalfUserData? halfUserData;

  PhoneRecordStatModel({
    this.mobileUseRecord,
    this.appUseRecord,
    this.sensitiveRecord = const [],
    this.halfUserData,
  });

  factory PhoneRecordStatModel.fromJson(Map<String, dynamic> json) {
    return PhoneRecordStatModel(
      mobileUseRecord: json['mobile_use_record'] != null
          ? MobileUseRecord.fromJson(json['mobile_use_record'])
          : null,
      appUseRecord: json['app_use_record'] != null
          ? AppUseRecord.fromJson(json['app_use_record'])
          : null,
      sensitiveRecord: (json['sensitive_record'] as List<dynamic>?)
              ?.map((e) => SensitiveRecord.fromJson(e))
              .toList() ??
          [],
      halfUserData: json['half_user_data'] != null
          ? HalfUserData.fromJson(json['half_user_data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mobile_use_record': mobileUseRecord?.toJson(),
      'app_use_record': appUseRecord?.toJson(),
      'sensitive_record': sensitiveRecord.map((e) => e.toJson()).toList(),
      'half_user_data': halfUserData?.toJson(),
    };
  }
}

/// 另一半用户设备信息
class HalfUserData {
  final int os; // 1=苹果，2=安卓

  HalfUserData({
    required this.os,
  });

  factory HalfUserData.fromJson(Map<String, dynamic> json) {
    return HalfUserData(
      os: json['os'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'os': os,
    };
  }

  /// 是否是苹果手机
  bool get isIOS => os == 1;

  /// 是否是安卓手机
  bool get isAndroid => os == 2;
}

/// 手机使用记录
class MobileUseRecord {
  final ScreenUseDuration screenUseDuration;
  final int latelyUseDuration; // 最近使用时长（秒）
  final int unlockPhoneNumbers; // 解锁次数

  MobileUseRecord({
    required this.screenUseDuration,
    required this.latelyUseDuration,
    required this.unlockPhoneNumbers,
  });

  factory MobileUseRecord.fromJson(Map<String, dynamic> json) {
    return MobileUseRecord(
      screenUseDuration: ScreenUseDuration.fromJson(
          json['screen_use_duration'] ?? {}),
      latelyUseDuration: json['lately_use_duration'] ?? 0,
      unlockPhoneNumbers: json['unlock_phone_numbers'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'screen_use_duration': screenUseDuration.toJson(),
      'lately_use_duration': latelyUseDuration,
      'unlock_phone_numbers': unlockPhoneNumbers,
    };
  }
}

/// 屏幕使用时长
class ScreenUseDuration {
  final int hours;
  final int minutes;

  ScreenUseDuration({
    required this.hours,
    required this.minutes,
  });

  factory ScreenUseDuration.fromJson(Map<String, dynamic> json) {
    return ScreenUseDuration(
      hours: json['hours'] ?? 0,
      minutes: json['minutes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hours': hours,
      'minutes': minutes,
    };
  }
}

/// App使用记录
class AppUseRecord {
  final LongestAppUseDurationData? longestAppUseDurationData;
  final MaxAppOpenNumberData? maxAppOpenNumberData;
  final LatelyOpenAppTimeData? latelyOpenAppTimeData;

  AppUseRecord({
    this.longestAppUseDurationData,
    this.maxAppOpenNumberData,
    this.latelyOpenAppTimeData,
  });

  factory AppUseRecord.fromJson(Map<String, dynamic> json) {
    return AppUseRecord(
      longestAppUseDurationData:
          json['longest_app_use_duration_data'] != null
              ? LongestAppUseDurationData.fromJson(
                  json['longest_app_use_duration_data'])
              : null,
      maxAppOpenNumberData: json['max_app_open_number_data'] != null
          ? MaxAppOpenNumberData.fromJson(json['max_app_open_number_data'])
          : null,
      latelyOpenAppTimeData: json['lately_open_app_time_data'] != null
          ? LatelyOpenAppTimeData.fromJson(json['lately_open_app_time_data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'longest_app_use_duration_data': longestAppUseDurationData?.toJson(),
      'max_app_open_number_data': maxAppOpenNumberData?.toJson(),
      'lately_open_app_time_data': latelyOpenAppTimeData?.toJson(),
    };
  }
}

/// 使用时长最长的App数据
class LongestAppUseDurationData {
  final String appLogo;
  final String appPkg;
  final int hours;
  final int minutes;

  LongestAppUseDurationData({
    required this.appLogo,
    required this.appPkg,
    required this.hours,
    required this.minutes,
  });

  factory LongestAppUseDurationData.fromJson(Map<String, dynamic> json) {
    return LongestAppUseDurationData(
      appLogo: json['app_logo'] ?? '',
      appPkg: json['app_pkg'] ?? '',
      hours: json['hours'] ?? 0,
      minutes: json['minutes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'app_logo': appLogo,
      'app_pkg': appPkg,
      'hours': hours,
      'minutes': minutes,
    };
  }
}

/// 打开次数最多的App数据
class MaxAppOpenNumberData {
  final String appLogo;
  final String appPkg;
  final int openAppNumber;

  MaxAppOpenNumberData({
    required this.appLogo,
    required this.appPkg,
    required this.openAppNumber,
  });

  factory MaxAppOpenNumberData.fromJson(Map<String, dynamic> json) {
    return MaxAppOpenNumberData(
      appLogo: json['app_logo'] ?? '',
      appPkg: json['app_pkg'] ?? '',
      openAppNumber: json['open_app_number'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'app_logo': appLogo,
      'app_pkg': appPkg,
      'open_app_number': openAppNumber,
    };
  }
}

/// 最近打开的App数据
class LatelyOpenAppTimeData {
  final String appLogo;
  final String appPkg;
  final String latelyOpenTime;

  LatelyOpenAppTimeData({
    required this.appLogo,
    required this.appPkg,
    required this.latelyOpenTime,
  });

  factory LatelyOpenAppTimeData.fromJson(Map<String, dynamic> json) {
    return LatelyOpenAppTimeData(
      appLogo: json['app_logo'] ?? '',
      appPkg: json['app_pkg'] ?? '',
      latelyOpenTime: json['lately_open_time'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'app_logo': appLogo,
      'app_pkg': appPkg,
      'lately_open_time': latelyOpenTime,
    };
  }
}

/// 敏感记录
class SensitiveRecord {
  final String icon;
  final SensitiveRecordExt ext;
  final String createTime;
  final int isVip;
  final String content;
  final String jumpPage;
  final int eventType;

  SensitiveRecord({
    required this.icon,
    required this.ext,
    required this.createTime,
    required this.isVip,
    required this.content,
    required this.jumpPage,
    required this.eventType,
  });

  factory SensitiveRecord.fromJson(Map<String, dynamic> json) {
    return SensitiveRecord(
      icon: json['icon'] ?? '',
      ext: SensitiveRecordExt.fromJson(json['ext'] ?? {}),
      createTime: json['create_time'] ?? '',
      isVip: json['is_vip'] ?? 0,
      content: json['content'] ?? '',
      jumpPage: json['jump_page'] ?? '',
      eventType: json['event_type'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'icon': icon,
      'ext': ext.toJson(),
      'create_time': createTime,
      'is_vip': isVip,
      'content': content,
      'jump_page': jumpPage,
      'event_type': eventType,
    };
  }
}

/// 敏感记录扩展信息
class SensitiveRecordExt {
  final String subContent;

  SensitiveRecordExt({
    required this.subContent,
  });

  factory SensitiveRecordExt.fromJson(Map<String, dynamic> json) {
    return SensitiveRecordExt(
      subContent: json['sub_content'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sub_content': subContent,
    };
  }
}
