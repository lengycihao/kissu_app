/// 小时详细数据
class HourDetail {
  /// 小时（如："0", "1"）
  final String hour;
  
  /// 时长（秒数字符串，如："180", "537"）
  final String duration;
  
  HourDetail({
    required this.hour,
    required this.duration,
  });
  
  /// 从JSON创建
  factory HourDetail.fromJson(Map<String, dynamic> json) {
    return HourDetail(
      hour: json['hour']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '0',
    );
  }
  
  /// 获取时长（分钟）
  int get durationMinutes {
    final seconds = int.tryParse(duration) ?? 0;
    return (seconds / 60).round();
  }
}

/// 图表数据点
class ChartDataPoint {
  /// 标签（如：小时数 "8"、"9"）
  final String label;
  
  /// 值（如：使用时长分钟数）
  final double value;
  
  /// 详细信息（用于tooltip显示）
  final String? detail;
  
  /// 小时详细数据列表
  final List<HourDetail>? hourDetails;
  
  ChartDataPoint({
    required this.label,
    required this.value,
    this.detail,
    this.hourDetails,
  });
}

/// 屏幕使用时长详情数据模型
class ScreenTimeDetailModel {
  /// 总使用时长（分钟）
  final int totalMinutes;

  /// 24小时数据（柱状图）
  final List<ChartDataPoint> hourlyData;

  /// 使用时长最长时段曲线数据
  final List<ChartDataPoint> longestPeriodData;

  /// 23点后异常时段曲线数据
  final List<ChartDataPoint> abnormalPeriodData;

  /// 使用记录列表
  final List<ScreenTimeRecordItem> records;

  ScreenTimeDetailModel({
    required this.totalMinutes,
    required this.hourlyData,
    required this.longestPeriodData,
    required this.abnormalPeriodData,
    required this.records,
  });

  /// 格式化总时长显示（如：1h10min）
  String get totalTimeDisplay {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) {
      return '${hours}h${minutes}min';
    }
    return '${minutes}min';
  }
}

/// 屏幕使用时长记录项
class ScreenTimeRecordItem {
  /// 开始时间
  final DateTime startTime;

  /// 结束时间
  final DateTime endTime;

  /// 使用时长（分钟）
  final int durationMinutes;

  /// 是否为隐私消息
  // final bool isPrivacyMessage;
  
  /// 应用名称（可选）
  final String? appName;
  
  /// 应用包名（可选）
  final String? packageName;

  ScreenTimeRecordItem({
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    // this.isPrivacyMessage = false,
    this.appName,
    this.packageName,
  });

  /// 时间段显示（如：9-11点）
  String get timePeriodDisplay {
    final startHour = startTime.hour;
    final endHour = endTime.hour;
    return '$startHour-$endHour点';
  }

  /// 时长显示（如：1h10min）
  String get durationDisplay {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours > 0) {
      return '${hours}h${minutes}min';
    }
    return '${minutes}min';
  }
}

