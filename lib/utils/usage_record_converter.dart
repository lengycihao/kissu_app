import 'package:kissu_app/models/screen_time_model.dart';
import 'package:kissu_app/models/unlock_record_model.dart';
import 'package:kissu_app/models/usage_record_api_model.dart';

/// 用机记录数据转换工具类
/// 将API数据转换为UI模型
class UsageRecordConverter {
  /// 将API数据转换为屏幕使用时长数据
  static ScreenTimeDetailModel convertToScreenTimeModel(
    ScreenUsageDurationRecord apiData,
    DateTime targetDate,
  ) {
    // 1. 转换24小时柱状图数据
    final hourlyData = <ChartDataPoint>[];
    for (int hour = 0; hour < 24; hour++) {
      // 从statistics中查找该小时的数据
      int totalMinutes = 0;
      for (var group in apiData.mobileScreenUsageDurationStatistics) {
        for (var detail in group.detail) {
          if (int.tryParse(detail.hour) == hour) {
            totalMinutes += detail.durationMinutes;
          }
        }
      }
      hourlyData.add(ChartDataPoint(
        label: hour.toString(),
        value: totalMinutes.toDouble(),
      ));
    }

    // 2. 转换记录列表（从list中筛选有时长的记录）
    final records = <ScreenTimeRecordItem>[];
    for (var group in apiData.mobileScreenUsageDurationList) {
      if (group.groupDurationMinutes > 0) {
        // 解析时间范围，例如 "08-10" 表示8点到10点
        final timeParts = group.groupLabel.split('-');
        if (timeParts.length == 2) {
          final startHour = int.tryParse(timeParts[0]) ?? 0;
          final endHour = int.tryParse(timeParts[1]) ?? 0;
          
          records.add(ScreenTimeRecordItem(
            startTime: DateTime(targetDate.year, targetDate.month, targetDate.day, startHour, 0),
            endTime: DateTime(targetDate.year, targetDate.month, targetDate.day, endHour, 0),
            durationMinutes: group.groupDurationMinutes,
          ));
        }
      }
    }

    // 计算总时长
    final totalMinutes = apiData.mobileScreenUsageDurationList
        .fold<int>(0, (sum, group) => sum + group.groupDurationMinutes);

    return ScreenTimeDetailModel(
      totalMinutes: totalMinutes,
      hourlyData: hourlyData,
      longestPeriodData: [], // 曲线图暂不使用
      abnormalPeriodData: [], // 曲线图暂不使用
      records: records,
    );
  }

  /// 将API数据转换为解锁记录数据
  static UnlockRecordDetailModel convertToUnlockRecordModel(
    RecordSection apiData,
    DateTime targetDate,
  ) {
    final records = <UnlockRecordItem>[];

    for (var item in apiData.data) {
      // 解析创建时间
      final time = _parseTime(item.createTime, targetDate);

      // event_type 14: 解锁手机（单个）
      // event_type 15: 锁定手机（单个）
      // event_type 19: 解锁->锁定时段记录
      if (item.eventType == 14) {
        // 解锁手机
        records.add(UnlockRecordItem(
          time: time,
          action: UnlockActionType.unlock,
          icon: item.icon,
        ));
      } else if (item.eventType == 15) {
        // 锁定手机
        records.add(UnlockRecordItem(
          time: time,
          action: UnlockActionType.lock,
          icon: item.icon,
        ));
      } else if (item.eventType == 19) {
        // 时段记录：解锁->锁定
        final unlockTimeStr = item.ext['unlock_time'] as String?;
        final lockTimeStr = item.ext['lock_time'] as String?;
        final moveDistanceStr = item.ext['move_distance'] as String?;
        final stayNumberStr = item.ext['stay_number'] as String?;

        final unlockTime = unlockTimeStr != null ? _parseTime(unlockTimeStr, targetDate) : time;
        final lockTime = lockTimeStr != null ? _parseTime(lockTimeStr, targetDate) : null;
        
        // 解析移动距离（去除单位"m"或"米"）
        double? moveDistance;
        if (moveDistanceStr != null) {
          final distanceNum = moveDistanceStr.replaceAll(RegExp(r'[^\d.]'), '');
          moveDistance = double.tryParse(distanceNum);
        }

        // 解析停留点数量
        final stayNumber = stayNumberStr != null ? int.tryParse(stayNumberStr) : null;

        records.add(UnlockRecordItem(
          time: unlockTime,
          action: UnlockActionType.unlock,
          endTime: lockTime,
          movementDistance: moveDistance,
          stayPointCount: stayNumber,
          icon: item.icon,
        ));
      }
    }

    return UnlockRecordDetailModel(
      unlockCount: apiData.number, // 使用API返回的总数
      hourlyData: [], // 折线图数据暂时为空（接口还没做好）
      weeklyData: [], // 折线图数据暂时为空（接口还没做好）
      records: records,
    );
  }

  /// 解析时间字符串（格式：HH:mm）
  static DateTime _parseTime(String timeStr, DateTime date) {
    try {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        return DateTime(date.year, date.month, date.day, hour, minute);
      }
    } catch (e) {
      print('解析时间失败: $timeStr, 错误: $e');
    }
    return date;
  }

  // 已废弃：现在使用 API 返回的 content 和 var_data 字段来显示文本
  // /// 获取event_type对应的文案（根据会员状态）
  // static String getEventTypeText(int eventType, Map<String, dynamic> ext, bool isVip) {
  //   // 从ext中提取变量
  //   final mobileModel = ext['mobile_model'] as String?;
  //   final networkName = ext['network_name'] as String?;
  //   final power = ext['power'] as String?;
  //   final locationName = ext['location_name'] as String?;
  //   final stayNumber = ext['stay_number'] as String?;
  //
  //   // 根据event_type和会员状态返回不同文案
  //   switch (eventType) {
  //     case 1:
  //       return '对方退出账号';
  //     case 2:
  //       return '对方打开App';
  //     case 3:
  //       if (mobileModel != null && mobileModel.isNotEmpty) {
  //         return '对方更换了手机（$mobileModel）进行了登录';
  //       }
  //       return '对方更换了手机进行了登录';
  //     case 4:
  //       return isVip ? '对方开启了定位' : '对方操作了一条中敏感记录';
  //     case 5:
  //       return isVip ? '对方关闭了定位' : '对方操作了一条中敏感记录';
  //     case 6:
  //       if (isVip && networkName != null && networkName.isNotEmpty) {
  //         return '对方更换了网络$networkName';
  //       }
  //       return '对方操作了一条中敏感记录';
  //     case 7:
  //       if (isVip && power != null) {
  //         return '对方手机正在充电，当前电量$power%';
  //       }
  //       return '对方手机产生了一条敏感记录';
  //     case 8:
  //       if (isVip && power != null) {
  //         return '对方手机结束了充电，当前电量$power%';
  //       }
  //       return '对方手机产生了一条敏感记录';
  //     case 9:
  //       if (isVip && locationName != null && locationName.isNotEmpty) {
  //         return '对方在$locationName停留时间超过2小时';
  //       }
  //       return '对方在****停留时间超过2小时';
  //     case 10:
  //       return isVip ? '对方今日停留位置超过2个' : '对方今日停留位置超过****个';
  //     case 11:
  //       return isVip ? '对方位置异常' : '对方位置异常';
  //     case 12:
  //       return isVip ? '对方开启了消息通知' : '对方手机产生了一条敏感记录';
  //     case 13:
  //       return isVip ? '对方关闭了消息通知' : '对方手机产生了一条敏感记录';
  //     case 14:
  //       return isVip ? '对方解锁了手机' : '对方操作了一条中敏感记录';
  //     case 15:
  //       return isVip ? '对方锁定了手机' : '对方操作了一条敏感记录';
  //     case 16:
  //       if (isVip && stayNumber != null) {
  //         return '对方产生了$stayNumber个停留点';
  //       }
  //       return '对方产生了****个停留点';
  //     case 17:
  //       if (isVip && locationName != null && locationName.isNotEmpty) {
  //         return '对方离开了$locationName在你标记的位置区域';
  //       }
  //       return '对方位置产生一条你标记的高敏感记录';
  //     case 18:
  //       if (isVip && locationName != null && locationName.isNotEmpty) {
  //         return '对方到了$locationName在你标记的位置区域';
  //       }
  //       return '对方位置产生一条你标记的高敏感记录';
  //     case 19:
  //       return isVip ? '参考UI' : '对方操作了一条高敏感记录并产生了足迹';
  //     case 20:
  //       return isVip ? '对方当前定位速度异常' : '对方当前位置状态高敏感异常';
  //     case 21:
  //       return isVip ? '对方切换成了移动网络' : '对方操作了一条敏感记录';
  //     default:
  //       return '未知记录类型';
  //   }
  // }

  /// 获取敏感等级文本
  static String getSensitiveLevelText(int level) {
    switch (level) {
      case 1:
        return '高敏感';
      case 2:
        return '中敏感';
      case 3:
        return '低敏感';
      default:
        return '';
    }
  }

  /// 获取敏感等级颜色
  static int getSensitiveLevelColor(int level) {
    switch (level) {
      case 1:
        return 0xFFFF3B30; // 高敏感-红色
      case 2:
        return 0xFFFF9500; // 中敏感-橙色
      case 3:
        return 0xFF34C759; // 低敏感-绿色
      default:
        return 0xFF999999;
    }
  }
}

