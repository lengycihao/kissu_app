/// 用机记录API数据模型

/// 分页敏感记录响应模型（新版V4接口）
class SensitiveRecordPageResponse {
  final bool hasMore;
  final List<SensitiveRecordItem> list;
  final HalfUserData? halfUserData;

  SensitiveRecordPageResponse({
    required this.hasMore,
    required this.list,
    this.halfUserData,
  });

  factory SensitiveRecordPageResponse.fromJson(Map<String, dynamic> json) {
    return SensitiveRecordPageResponse(
      hasMore: json['has_more'] ?? false,
      list: (json['data'] as List?)
              ?.map((e) => SensitiveRecordItem.fromJson(e))
              .toList() ??
          [],
      halfUserData: json['half_user_data'] != null
          ? HalfUserData.fromJson(json['half_user_data'])
          : null,
    );
  }
}

/// 另一半用户设备信息
class HalfUserData {
  final String power;        // 电量（如 "75%" 或 "未知"）
  final String networkName;  // 网络名称（WiFi名称或 "未知"）
  final String mobileModel;  // 手机型号（如 "iPhone 14" 或 "未知"）
  final String isWifi;       // 是否是WiFi（"0"表示移动网络，"1"表示WiFi）
  final String distance;    // 距离（如 "100m" 或 "未知"）

  HalfUserData({
    required this.power,
    required this.networkName,
    required this.mobileModel,
    required this.isWifi,
    required this.distance,
  });

  factory HalfUserData.fromJson(Map<String, dynamic> json) {
    return HalfUserData(
      power: json['power']?.toString() ?? '未知',
      networkName: json['network_name']?.toString() ?? '未知',
      mobileModel: json['mobile_model']?.toString() ?? '未知',
      isWifi: json['is_wifi']?.toString() ?? '0',
      distance: json['distance']?.toString() ?? '未知',
    );
  }

  /// 是否连接WiFi
  bool get isConnectedToWifi => isWifi == '1';
}

/// 敏感记录单项
class SensitiveRecordItem {
  final String icon;
  final String content;
   final String createTime;
  final int eventType;
  final String jumpPage;
  final int isVip;
    final Map<String, dynamic> ext;

  SensitiveRecordItem({
    required this.icon,
    required this.content,  
     required this.createTime,
    required this.eventType,
    required this.jumpPage,
    required this.isVip,
     required this.ext,
  });

  factory SensitiveRecordItem.fromJson(Map<String, dynamic> json) {
    return SensitiveRecordItem(
      icon: json['icon'] ?? '',
      content: json['content'] ?? '',
      createTime: json['create_time'] ?? '',
      eventType: json['event_type'] ?? 0,
      jumpPage: json['jump_page'] ?? '',
      isVip: json['is_vip'] ?? 0,
      ext: json['ext'] ?? {},
    );
  }

  /// 是否有副标题（双行显示）
  bool get hasSubContent {
    return ext['sub_content'] != null && 
           ext['sub_content'].toString().isNotEmpty;
  }

  /// 获取副标题内容
  String get subContent {
    return ext['sub_content']?.toString() ?? '';
  }

  /// 是否需要VIP权限
  bool get needsVip => isVip == 1;

  /// 是否显示跳转按钮
  bool get showJumpButton => jumpPage.isNotEmpty;
}

/// API响应根模型
class UsageRecordApiResponse {
  final RecordSection allRecord;
  final RecordSection sensitiveRecord;
  final RecordSection unlockMobileRecord;
  final RecordSection locationStayAbnormalRecord;
  final ScreenUsageDurationRecord mobileScreenUsageDurationRecord;
  final HalfLocationMobileDevice halfLocationMobileDevice;

  UsageRecordApiResponse({
    required this.allRecord,
    required this.sensitiveRecord,
    required this.unlockMobileRecord,
    required this.locationStayAbnormalRecord,
    required this.mobileScreenUsageDurationRecord,
    required this.halfLocationMobileDevice,
  });

  factory UsageRecordApiResponse.fromJson(Map<String, dynamic> json) {
    // 注意：大部分数据在 sensitive_data 里，但 half_location_mobile_device 在外层
    final sensitiveData = json['sensitive_data'] as Map<String, dynamic>? ?? {};
    
    return UsageRecordApiResponse(
      allRecord: RecordSection.fromJson(sensitiveData['all_record'] ?? {}),
      sensitiveRecord: RecordSection.fromJson(sensitiveData['sensitive_record'] ?? {}),
      unlockMobileRecord: RecordSection.fromJson(sensitiveData['unlock_mobile_record'] ?? {}),
      locationStayAbnormalRecord: RecordSection.fromJson(sensitiveData['location_stay_abnormal_record'] ?? {}),
      mobileScreenUsageDurationRecord: ScreenUsageDurationRecord.fromJson(sensitiveData['mobile_screen_usage_duration_record'] ?? {}),
      halfLocationMobileDevice: HalfLocationMobileDevice.fromJson(json['half_location_mobile_device'] ?? {}),  // 注意：这个在根层级
    );
  }
}

/// 记录区块（敏感记录、解锁记录、定位异常记录都使用这个结构）
class RecordSection {
  final int number;
  final List<RecordItem> data;

  RecordSection({
    required this.number,
    required this.data,
  });

  factory RecordSection.fromJson(Map<String, dynamic> json) {
    return RecordSection(
      number: json['number'] ?? 0,
      data: (json['data'] as List?)?.map((e) => RecordItem.fromJson(e)).toList() ?? [],
    );
  }
}

/// 单条记录项
class RecordItem {
  final String icon;
  final Map<String, dynamic> ext;
  final String createTime;
  final String content;
  final List<VarData> varData;
  final int eventType;
  final int sensitiveLevel;

  RecordItem({
    required this.icon,
    required this.ext,
    required this.createTime,
    required this.content,
    required this.varData,
    required this.eventType,
    required this.sensitiveLevel,
  });

  factory RecordItem.fromJson(Map<String, dynamic> json) {
    return RecordItem(
      icon: json['icon'] ?? '',
      ext: json['ext'] ?? {},
      createTime: json['create_time'] ?? '',
      content: json['content'] ?? '',
      varData: (json['var_data'] as List?)
              ?.map((e) => VarData.fromJson(e))
              .toList() ??
          [],
      eventType: json['event_type'] ?? 0,
      sensitiveLevel: json['sensitive_level'] ?? 0,
    );
  }
}

/// 可变文本数据（用于高亮显示）
class VarData {
  final String changeText;
  final String color;

  VarData({
    required this.changeText,
    required this.color,
  });

  factory VarData.fromJson(Map<String, dynamic> json) {
    return VarData(
      changeText: json['change_text'] ?? '',
      color: json['color'] ?? '#333333',
    );
  }
}

/// 屏幕使用时长记录
class ScreenUsageDurationRecord {
  final int number;
  final List<ScreenUsageGroup> mobileScreenUsageDurationStatistics;
  final List<ScreenUsageGroup> mobileScreenUsageDurationList;

  ScreenUsageDurationRecord({
    required this.number,
    required this.mobileScreenUsageDurationStatistics,
    required this.mobileScreenUsageDurationList,
  });

  factory ScreenUsageDurationRecord.fromJson(Map<String, dynamic> json) {
    return ScreenUsageDurationRecord(
      number: json['number'] ?? 0,
      mobileScreenUsageDurationStatistics: (json['mobile_screen_usage_duration_statistics'] as List?)
              ?.map((e) => ScreenUsageGroup.fromJson(e))
              .toList() ??
          [],
      mobileScreenUsageDurationList: (json['mobile_screen_usage_duration_list'] as List?)
              ?.map((e) => ScreenUsageGroup.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// 屏幕使用时长分组数据
class ScreenUsageGroup {
  final String groupLabel;
  final List<String> coverHours;
  final String groupDuration;
  final List<ScreenUsageDetail> detail;
  final String icon;

  ScreenUsageGroup({
    required this.groupLabel,
    required this.coverHours,
    required this.groupDuration,
    required this.detail,
    required this.icon,
  });

  factory ScreenUsageGroup.fromJson(Map<String, dynamic> json) {
    return ScreenUsageGroup(
      groupLabel: json['group_label'] ?? '',
      coverHours: (json['cover_hours'] as List?)?.map((e) => e.toString()).toList() ?? [],
      groupDuration: json['group_duration'] ?? '0',
      detail: (json['detail'] as List?)?.map((e) => ScreenUsageDetail.fromJson(e)).toList() ?? [],
      icon: json['icon'] ?? '',
    );
  }

  /// 获取分组时长（分钟）
  int get groupDurationMinutes => int.tryParse(groupDuration) ?? 0;
}

/// 屏幕使用时长详细数据
class ScreenUsageDetail {
  final String hour;
  final String duration;

  ScreenUsageDetail({
    required this.hour,
    required this.duration,
  });

  factory ScreenUsageDetail.fromJson(Map<String, dynamic> json) {
    return ScreenUsageDetail(
      hour: json['hour'] ?? '0',
      duration: json['duration'] ?? '0',
    );
  }

  /// 获取时长（分钟）
  int get durationMinutes {
    final seconds = int.tryParse(duration) ?? 0;
    return (seconds / 60).ceil();
  }
}

/// 半屏定位设备信息
class HalfLocationMobileDevice {
  final String power;        // 电量（如 "75%"）
  final String networkName;  // 网络名称（WiFi名称或空字符串）
  final String mobileModel;  // 手机型号
  final String isWifi;       // 是否是WiFi（"0"表示移动网络，"1"表示WiFi）

  HalfLocationMobileDevice({
    required this.power,
    required this.networkName,
    required this.mobileModel,
    required this.isWifi,
  });

  factory HalfLocationMobileDevice.fromJson(Map<String, dynamic> json) {
    return HalfLocationMobileDevice(
      power: json['power'] ?? '',
      networkName: json['network_name'] ?? '',
      mobileModel: json['mobile_model'] ?? '',
      isWifi: json['is_wifi'] ?? '0',
    );
  }

  /// 是否连接WiFi
  bool get isConnectedToWifi => isWifi == '1';
}

/// recordSta 接口响应数据模型
class MobileUsageRecordStaResponse {
  final MobileUsageData mobile;
  final OtherAppData otherApp;
  final Map<String, dynamic> sensitiveRecords; // 暂时不处理

  MobileUsageRecordStaResponse({
    required this.mobile,
    required this.otherApp,
    required this.sensitiveRecords,
  });

  factory MobileUsageRecordStaResponse.fromJson(Map<String, dynamic> json) {
    return MobileUsageRecordStaResponse(
      mobile: MobileUsageData.fromJson(json['mobile'] ?? {}),
      otherApp: OtherAppData.fromJson(json['otherApp'] ?? {}),
      sensitiveRecords: json['sensitiveRecords'] ?? {},
    );
  }
}

/// 手机使用数据
class MobileUsageData {
  final TotalUseDuration totalUseDuration;
  final LastUseDuration lastUseDuration;
  final TotalUnlock totalUnlock;

  MobileUsageData({
    required this.totalUseDuration,
    required this.lastUseDuration,
    required this.totalUnlock,
  });

  factory MobileUsageData.fromJson(Map<String, dynamic> json) {
    return MobileUsageData(
      totalUseDuration: TotalUseDuration.fromJson(json['totalUseDuration'] ?? {}),
      lastUseDuration: LastUseDuration.fromJson(json['lastUseDuration'] ?? {}),
      totalUnlock: TotalUnlock.fromJson(json['totalUnlock'] ?? {}),
    );
  }
}

/// 总使用时长
class TotalUseDuration {
  final int minute;
  final String hour; // "2小时1分钟" 格式
  final String desc;

  TotalUseDuration({
    required this.minute,
    required this.hour,
    required this.desc,
  });

  factory TotalUseDuration.fromJson(Map<String, dynamic> json) {
    return TotalUseDuration(
      minute: json['minute'] ?? 0,
      hour: json['hour'] ?? '',
      desc: json['desc'] ?? '',
    );
  }

  /// 解析小时和分钟数字
  /// 返回 (hours, minutes)
  (int, int) parseHoursAndMinutes() {
    // 解析 "2小时1分钟" 格式
    final hourMatch = RegExp(r'(\d+)小时').firstMatch(hour);
    final minuteMatch = RegExp(r'(\d+)分钟').firstMatch(hour);
    
    final hours = hourMatch != null ? int.tryParse(hourMatch.group(1) ?? '0') ?? 0 : 0;
    final minutes = minuteMatch != null ? int.tryParse(minuteMatch.group(1) ?? '0') ?? 0 : 0;
    
    return (hours, minutes);
  }
}

/// 最近使用时长
class LastUseDuration {
  final int minute;
  final String unit;

  LastUseDuration({
    required this.minute,
    required this.unit,
  });

  factory LastUseDuration.fromJson(Map<String, dynamic> json) {
    return LastUseDuration(
      minute: json['minute'] ?? 0,
      unit: json['unit'] ?? '',
    );
  }
}

/// 总解锁次数
class TotalUnlock {
  final int count;
  final String unit;

  TotalUnlock({
    required this.count,
    required this.unit,
  });

  factory TotalUnlock.fromJson(Map<String, dynamic> json) {
    return TotalUnlock(
      count: json['count'] ?? 0,
      unit: json['unit'] ?? '',
    );
  }
}

/// App使用数据
class OtherAppData {
  final AppInfo? longestApp;
  final AppInfo? openMostApp;
  final LastUseApp? lastUseApp;

  OtherAppData({
    this.longestApp,
    this.openMostApp,
    this.lastUseApp,
  });

  factory OtherAppData.fromJson(Map<String, dynamic> json) {
    return OtherAppData(
      longestApp: json['longestApp'] != null 
          ? AppInfo.fromJson(json['longestApp']) 
          : null,
      openMostApp: json['openMostApp'] != null 
          ? AppInfo.fromJson(json['openMostApp']) 
          : null,
      lastUseApp: json['lastUseApp'] != null 
          ? LastUseApp.fromJson(json['lastUseApp']) 
          : null,
    );
  }
}

/// App信息（最长使用、打开次数最多）
class AppInfo {
  final String appName;
  final String appLogo;
  final int? minute;
  final String? hour; // "1小时2分钟" 格式
  final int? count;
  final String? unit;
  final String? desc;

  AppInfo({
    required this.appName,
    required this.appLogo,
    this.minute,
    this.hour,
    this.count,
    this.unit,
    this.desc,
  });

  factory AppInfo.fromJson(Map<String, dynamic> json) {
    return AppInfo(
      appName: json['app_name'] ?? '',
      appLogo: json['app_logo'] ?? '',
      minute: json['minute'],
      hour: json['hour'],
      count: json['count'],
      unit: json['unit'],
      desc: json['desc'],
    );
  }

  /// 解析小时和分钟数字（用于 longestApp）
  /// 返回 (hours, minutes)
  (int, int) parseHoursAndMinutes() {
    if (hour == null || hour!.isEmpty) {
      return (0, 0);
    }
    
    // 解析 "1小时2分钟" 格式
    final hourMatch = RegExp(r'(\d+)小时').firstMatch(hour!);
    final minuteMatch = RegExp(r'(\d+)分钟').firstMatch(hour!);
    
    final hours = hourMatch != null ? int.tryParse(hourMatch.group(1) ?? '0') ?? 0 : 0;
    final minutes = minuteMatch != null ? int.tryParse(minuteMatch.group(1) ?? '0') ?? 0 : 0;
    
    return (hours, minutes);
  }
}

/// 最近使用的App
class LastUseApp {
  final String appName;
  final String appLogo;
  final String time; // "11:19" 格式

  LastUseApp({
    required this.appName,
    required this.appLogo,
    required this.time,
  });

  factory LastUseApp.fromJson(Map<String, dynamic> json) {
    return LastUseApp(
      appName: json['app_name'] ?? '',
      appLogo: json['app_logo'] ?? '',
      time: json['time'] ?? '',
    );
  }
}

