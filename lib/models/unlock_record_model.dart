import 'package:kissu_app/models/screen_time_model.dart';

/// 解锁记录类型枚举
enum UnlockRecordType {
  mostFrequentTime, // 解锁次数最多时段
  abnormalTime, // 23点后异常时段
}

/// 解锁操作类型枚举
enum UnlockActionType {
  lock, // 锁定手机
  unlock, // 解锁手机
}

/// 解锁记录详情模型
class UnlockRecordDetailModel {
  final int unlockCount; // 解锁次数
  final List<ChartDataPoint> hourlyData; // 按小时统计的数据
  final List<ChartDataPoint> weeklyData; // 按星期统计的数据
  final List<UnlockRecordItem> records; // 解锁记录列表

  UnlockRecordDetailModel({
    required this.unlockCount,
    required this.hourlyData,
    required this.weeklyData,
    required this.records,
  });
}

/// 单条解锁记录
class UnlockRecordItem {
  final UnlockRecordType? type; // 记录类型（最多时段/异常时段）
  final DateTime time; // 时间
  final UnlockActionType action; // 操作类型（锁定/解锁）
  final DateTime? endTime; // 结束时间（如果是时段记录）
  final double? movementDistance; // 期间定位移动距离（米）
  final int? stayPointCount; // 期间停留点数量
  final String icon; // 图标URL
  final int? eventType; // 原始事件类型（用于区分类型19等特殊记录）

  UnlockRecordItem({
    this.type,
    required this.time,
    required this.action,
    this.endTime,
    this.movementDistance,
    this.stayPointCount,
    this.icon = '',
    this.eventType,
  });

  /// 是否为时段记录（有开始和结束时间）
  bool get isPeriodRecord => endTime != null;

  /// 是否有额外信息（移动距离或停留点）
  bool get hasExtraInfo => movementDistance != null || stayPointCount != null;

  /// 格式化时间显示
  String get timeDisplay {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// 格式化结束时间显示
  String get endTimeDisplay {
    if (endTime == null) return '';
    final hour = endTime!.hour.toString().padLeft(2, '0');
    final minute = endTime!.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// 格式化距离显示
  String? get distanceDisplay {
    if (movementDistance == null) return null;
    if (movementDistance! < 1000) {
      return '${movementDistance!.toStringAsFixed(0)}米';
    } else {
      return '${(movementDistance! / 1000).toStringAsFixed(1)}公里';
    }
  }
}

