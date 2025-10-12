/// 用机记录API数据模型

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

