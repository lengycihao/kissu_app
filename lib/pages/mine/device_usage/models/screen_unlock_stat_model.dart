/// 屏幕使用和解锁统计数据模型
class ScreenUnlockStatModel {
  final ScreenUseData? screenUseData;
  final UnlockPhoneData? unlockPhoneData;

  ScreenUnlockStatModel({
    this.screenUseData,
    this.unlockPhoneData,
  });

  factory ScreenUnlockStatModel.fromJson(Map<String, dynamic> json) {
    return ScreenUnlockStatModel(
      screenUseData: json['screen_use_data'] != null
          ? ScreenUseData.fromJson(json['screen_use_data'])
          : null,
      unlockPhoneData: json['unlock_phone_data'] != null
          ? UnlockPhoneData.fromJson(json['unlock_phone_data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'screen_use_data': screenUseData?.toJson(),
      'unlock_phone_data': unlockPhoneData?.toJson(),
    };
  }
}

/// 屏幕使用数据
class ScreenUseData {
  final int hours;
  final int minutes;
  final int trend; // 0持平 1下降 2上升
  final String trendText;
  final List<HourlyUsageStat> hourlyUsageStat;

  ScreenUseData({
    required this.hours,
    required this.minutes,
    required this.trend,
    required this.trendText,
    required this.hourlyUsageStat,
  });

  factory ScreenUseData.fromJson(Map<String, dynamic> json) {
    return ScreenUseData(
      hours: json['hours'] ?? 0,
      minutes: json['minutes'] ?? 0,
      trend: json['trend'] ?? 0,
      trendText: json['trend_text'] ?? '',
      hourlyUsageStat: (json['hourly_usage_stat'] as List<dynamic>?)
              ?.map((e) => HourlyUsageStat.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hours': hours,
      'minutes': minutes,
      'trend': trend,
      'trend_text': trendText,
      'hourly_usage_stat': hourlyUsageStat.map((e) => e.toJson()).toList(),
    };
  }
}

/// 每小时使用统计
class HourlyUsageStat {
  final int hour;
  final int duration;
  final int minutes;
  final List<int> hourLabel;

  HourlyUsageStat({
    required this.hour,
    required this.duration,
    required this.minutes,
    required this.hourLabel,
  });

  factory HourlyUsageStat.fromJson(Map<String, dynamic> json) {
    return HourlyUsageStat(
      hour: json['hour'] ?? 0,
      duration: json['duration'] ?? 0,
      minutes: json['minutes'] ?? 0,
      hourLabel: (json['hour_label'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'duration': duration,
      'minutes': minutes,
      'hour_label': hourLabel,
    };
  }
}

/// 手机解锁数据
class UnlockPhoneData {
  final int unlockNumber;
  final int trend; // 0持平 1下降 2上升
  final String trendText;
  final List<UnlockPhoneStat> unlockPhoneStat;

  UnlockPhoneData({
    required this.unlockNumber,
    required this.trend,
    required this.trendText,
    required this.unlockPhoneStat,
  });

  factory UnlockPhoneData.fromJson(Map<String, dynamic> json) {
    return UnlockPhoneData(
      unlockNumber: json['unlock_number'] ?? 0,
      trend: json['trend'] ?? 0,
      trendText: json['trend_text'] ?? '',
      unlockPhoneStat: (json['unlock_phone_stat'] as List<dynamic>?)
              ?.map((e) => UnlockPhoneStat.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unlock_number': unlockNumber,
      'trend': trend,
      'trend_text': trendText,
      'unlock_phone_stat': unlockPhoneStat.map((e) => e.toJson()).toList(),
    };
  }
}

/// 每小时解锁统计
class UnlockPhoneStat {
  final int hour;
  final int unlockNumber;
  final List<int> hourLabel;

  UnlockPhoneStat({
    required this.hour,
    required this.unlockNumber,
    required this.hourLabel,
  });

  factory UnlockPhoneStat.fromJson(Map<String, dynamic> json) {
    return UnlockPhoneStat(
      hour: json['hour'] ?? 0,
      unlockNumber: json['unlock_number'] ?? 0,
      hourLabel: (json['hour_label'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'unlock_number': unlockNumber,
      'hour_label': hourLabel,
    };
  }
}
