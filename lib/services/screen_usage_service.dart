import 'package:usage_stats/usage_stats.dart';
import 'dart:io';
import 'app_info_service.dart';

/// 屏幕使用时长数据模型
class ScreenUsageData {
  final String packageName;
  final String appName;
  final int totalTimeInForeground; // 毫秒
  final DateTime firstTimeStamp;
  final DateTime lastTimeStamp;
  final int lastTimeUsed; // 毫秒

  ScreenUsageData({
    required this.packageName,
    required this.appName,
    required this.totalTimeInForeground,
    required this.firstTimeStamp,
    required this.lastTimeStamp,
    required this.lastTimeUsed,
  });

  /// 获取使用时长（小时）
  double get usageHours => totalTimeInForeground / (1000 * 60 * 60);

  /// 获取使用时长（分钟）
  double get usageMinutes => totalTimeInForeground / (1000 * 60);

  /// 获取使用时长（秒）
  double get usageSeconds => totalTimeInForeground / 1000;

  /// 格式化使用时长为易读格式 (如: "2小时30分钟")
  String get formattedUsageTime {
    final hours = (totalTimeInForeground / (1000 * 60 * 60)).floor();
    final minutes = ((totalTimeInForeground % (1000 * 60 * 60)) / (1000 * 60)).floor();
    
    if (hours > 0) {
      return '${hours}小时${minutes}分钟';
    } else if (minutes > 0) {
      return '${minutes}分钟';
    } else {
      final seconds = (totalTimeInForeground / 1000).floor();
      return '${seconds}秒';
    }
  }
}

/// 屏幕解锁记录数据模型
class UnlockEventData {
  final DateTime timestamp;
  final int unlockCount;

  UnlockEventData({
    required this.timestamp,
    required this.unlockCount,
  });
}

/// 屏幕使用时长服务
/// 负责获取和处理应用使用统计数据
class ScreenUsageService {
  static final ScreenUsageService _instance = ScreenUsageService._internal();
  factory ScreenUsageService() => _instance;
  ScreenUsageService._internal();

  /// 获取今日屏幕使用总时长（毫秒）
  Future<int> getTodayScreenTime() async {
    if (!Platform.isAndroid) {
      return 0;
    }

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
      
      final usageStats = await queryUsageStats(startOfDay, now);
      
      int totalTime = 0;
      for (var stat in usageStats) {
        totalTime += stat.totalTimeInForeground;
      }
      
      return totalTime;
    } catch (e) {
      print('获取今日屏幕使用时长失败: $e');
      return 0;
    }
  }

  /// 获取指定日期范围的屏幕使用时长
  /// [startDate] 开始日期
  /// [endDate] 结束日期
  Future<int> getScreenTimeByDateRange(DateTime startDate, DateTime endDate) async {
    if (!Platform.isAndroid) {
      return 0;
    }

    try {
      final usageStats = await queryUsageStats(startDate, endDate);
      
      int totalTime = 0;
      for (var stat in usageStats) {
        totalTime += stat.totalTimeInForeground;
      }
      
      return totalTime;
    } catch (e) {
      print('获取指定日期范围屏幕使用时长失败: $e');
      return 0;
    }
  }

  /// 获取今日应用使用详情（按使用时长排序）
  Future<List<ScreenUsageData>> getTodayAppUsageStats({int? limit}) async {
    if (!Platform.isAndroid) {
      return [];
    }

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
      
      final usageStats = await queryUsageStats(startOfDay, now);
      
      // 过滤掉使用时长为0的应用，并按使用时长排序
      final validStats = usageStats
          .where((stat) => stat.totalTimeInForeground > 0)
          .toList()
        ..sort((a, b) => b.totalTimeInForeground.compareTo(a.totalTimeInForeground));
      
      // 如果指定了limit，只返回前N个
      final limitedStats = limit != null && limit < validStats.length
          ? validStats.sublist(0, limit)
          : validStats;
      
      return limitedStats;
    } catch (e) {
      print('获取今日应用使用详情失败: $e');
      return [];
    }
  }

  /// 获取指定日期范围的应用使用详情
  Future<List<ScreenUsageData>> getAppUsageStatsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int? limit,
  }) async {
    if (!Platform.isAndroid) {
      return [];
    }

    try {
      final usageStats = await queryUsageStats(startDate, endDate);
      
      // 过滤掉使用时长为0的应用，并按使用时长排序
      final validStats = usageStats
          .where((stat) => stat.totalTimeInForeground > 0)
          .toList()
        ..sort((a, b) => b.totalTimeInForeground.compareTo(a.totalTimeInForeground));
      
      // 如果指定了limit，只返回前N个
      final limitedStats = limit != null && limit < validStats.length
          ? validStats.sublist(0, limit)
          : validStats;
      
      return limitedStats;
    } catch (e) {
      print('获取应用使用详情失败: $e');
      return [];
    }
  }

  /// 获取过去N天的每日屏幕使用时长
  /// 返回一个Map，key为日期字符串（yyyy-MM-dd），value为使用时长（毫秒）
  Future<Map<String, int>> getScreenTimeByDays(int days) async {
    if (!Platform.isAndroid) {
      return {};
    }

    try {
      final now = DateTime.now();
      final result = <String, int>{};

      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
        final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
        
        final totalTime = await getScreenTimeByDateRange(startOfDay, endOfDay);
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        result[dateKey] = totalTime;
      }

      return result;
    } catch (e) {
      print('获取过去${days}天屏幕使用时长失败: $e');
      return {};
    }
  }

  /// 获取今日解锁次数
  /// 
  /// 统计真正的解锁次数
  Future<int> getTodayUnlockCount() async {
    if (!Platform.isAndroid) {
      return 0;
    }

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
      
      // 获取事件统计
      final events = await queryEvents(startOfDay, now);
      
      // 统计各种事件类型，用于调试
      final eventTypeCounts = <String, int>{};
      for (var event in events) {
        final eventType = event['eventType'] ?? 'unknown';
        eventTypeCounts[eventType] = (eventTypeCounts[eventType] ?? 0) + 1;
      }
      
      print('📊 事件类型统计: $eventTypeCounts');
      
      // Android UsageEvents 事件类型：
      // 1 = SCREEN_INTERACTIVE (屏幕交互/亮起)
      // 2 = SCREEN_NON_INTERACTIVE (屏幕关闭)
      // 5 = KEYGUARD_SHOWN (锁屏界面显示)
      // 6 = KEYGUARD_HIDDEN (锁屏界面隐藏 - 真正的解锁)
      // 18 = USER_UNLOCKED (用户解锁完成 - Android 7.0+)
      
      int unlockCount = 0;
      int keyguardHiddenCount = 0;
      int userUnlockedCount = 0;
      int screenInteractiveCount = 0;
      
      for (var event in events) {
        final eventType = event['eventType'] ?? '';
        if (eventType == '18') { 
          // 18 = USER_UNLOCKED (Android 7.0+ 最准确的解锁事件)
          userUnlockedCount++;
        } else if (eventType == '6') { 
          // 6 = KEYGUARD_HIDDEN (锁屏界面隐藏)
          keyguardHiddenCount++;
        } else if (eventType == '1') {
          // 1 = SCREEN_INTERACTIVE (屏幕亮起)
          screenInteractiveCount++;
        }
      }
      
      print('📊 USER_UNLOCKED(18): $userUnlockedCount, KEYGUARD_HIDDEN(6): $keyguardHiddenCount, SCREEN_INTERACTIVE(1): $screenInteractiveCount');
      
      // 优先使用 USER_UNLOCKED 事件（最准确）
      if (userUnlockedCount > 0) {
        unlockCount = userUnlockedCount;
        print('✅ 使用 USER_UNLOCKED 事件统计解锁次数');
      } 
      // 其次使用 KEYGUARD_HIDDEN 事件
      else if (keyguardHiddenCount > 0) {
        unlockCount = keyguardHiddenCount;
        print('✅ 使用 KEYGUARD_HIDDEN 事件统计解锁次数');
      }
      // 兜底：使用智能过滤算法
      else if (screenInteractiveCount > 0) {
        print('⚠️ 设备不支持 USER_UNLOCKED 和 KEYGUARD_HIDDEN 事件，使用智能过滤');
        unlockCount = _filterScreenInteractiveEvents(events);
      }
      
      print('📊 今日解锁次数: $unlockCount');
      return unlockCount;
    } catch (e) {
      print('获取今日解锁次数失败: $e');
      return 0;
    }
  }
  
  /// 智能过滤屏幕唤醒事件，估算真实解锁次数
  /// 
  /// 逻辑：
  /// 1. 配对 SCREEN_INTERACTIVE 和 SCREEN_NON_INTERACTIVE 事件
  /// 2. 只统计持续时间超过阈值的屏幕唤醒（过滤短暂的通知查看）
  /// 3. 合并时间间隔过短的事件（避免重复统计）
  int _filterScreenInteractiveEvents(List<Map<String, dynamic>> events) {
    // 提取屏幕交互事件和屏幕关闭事件
    final List<MapEntry<DateTime, String>> allEvents = [];
    
    for (var event in events) {
      try {
        final eventType = event['eventType'] ?? '';
        final timestamp = DateTime.fromMillisecondsSinceEpoch(
          int.parse(event['timeStamp'] ?? '0'),
        );
        
        if (eventType == '1') {
          allEvents.add(MapEntry(timestamp, 'INTERACTIVE'));
        } else if (eventType == '2') {
          allEvents.add(MapEntry(timestamp, 'NON_INTERACTIVE'));
        }
      } catch (e) {
        // 忽略解析失败的事件
      }
    }
    
    // 按时间排序
    allEvents.sort((a, b) => a.key.compareTo(b.key));
    
    // 分析屏幕使用模式
    int unlockCount = 0;
    DateTime? lastUnlockTime;
    DateTime? currentInteractiveTime;
    
    for (var event in allEvents) {
      final eventTime = event.key;
      final eventType = event.value;
      
      if (eventType == 'INTERACTIVE') {
        // 屏幕亮起
        if (currentInteractiveTime == null) {
          currentInteractiveTime = eventTime;
        }
      } else if (eventType == 'NON_INTERACTIVE') {
        // 屏幕关闭
        if (currentInteractiveTime != null) {
          // 计算本次屏幕使用时长
          final duration = eventTime.difference(currentInteractiveTime);
          
          // 只统计持续时间超过 3 秒的使用（过滤短暂的通知查看）
          if (duration.inSeconds >= 3) {
            // 检查距离上次解锁是否超过 2 分钟（避免短时间内重复统计）
            if (lastUnlockTime == null || 
                currentInteractiveTime.difference(lastUnlockTime).inMinutes >= 2) {
              unlockCount++;
              lastUnlockTime = currentInteractiveTime;
              print('🔓 解锁时间: ${currentInteractiveTime.hour}:${currentInteractiveTime.minute}, 使用时长: ${duration.inSeconds}秒');
            } else {
              print('⏭️ 跳过：距离上次解锁不到2分钟 (${currentInteractiveTime.hour}:${currentInteractiveTime.minute})');
            }
          } else {
            print('⏭️ 跳过：使用时长不足3秒 (${duration.inSeconds}秒)');
          }
          
          currentInteractiveTime = null;
        }
      }
    }
    
    // 如果最后一次屏幕亮起后没有关闭事件（当前屏幕仍然亮着）
    if (currentInteractiveTime != null) {
      final now = DateTime.now();
      final duration = now.difference(currentInteractiveTime);
      
      if (duration.inSeconds >= 3) {
        if (lastUnlockTime == null || 
            currentInteractiveTime.difference(lastUnlockTime).inMinutes >= 2) {
          unlockCount++;
          print('🔓 解锁时间: ${currentInteractiveTime.hour}:${currentInteractiveTime.minute}, 使用中... (${duration.inSeconds}秒)');
        }
      }
    }
    
    return unlockCount;
  }

  /// 查询使用统计（内部方法）
  Future<List<ScreenUsageData>> queryUsageStats(DateTime startDate, DateTime endDate) async {
    try {
      // 使用静态方法查询
      final stats = await UsageStats.queryUsageStats(startDate, endDate);

      if (stats.isEmpty) {
        return [];
      }

      // 提取所有包名
      final packageNames = stats
          .map((stat) => stat.packageName ?? '')
          .where((pkg) => pkg.isNotEmpty)
          .toList();

      // 批量获取应用名称
      final appInfoService = AppInfoService();
      final appNamesMap = await appInfoService.getAppNames(packageNames);

      // 构建结果列表
      return stats.map((stat) {
        final packageName = stat.packageName ?? '';
        final appName = appNamesMap[packageName] ?? packageName;
        
        return ScreenUsageData(
          packageName: packageName,
          appName: appName,
          totalTimeInForeground: int.parse(stat.totalTimeInForeground ?? '0'),
          firstTimeStamp: DateTime.fromMillisecondsSinceEpoch(
            int.parse(stat.firstTimeStamp ?? '0'),
          ),
          lastTimeStamp: DateTime.fromMillisecondsSinceEpoch(
            int.parse(stat.lastTimeStamp ?? '0'),
          ),
          lastTimeUsed: int.parse(stat.lastTimeUsed ?? '0'),
        );
      }).toList();
    } catch (e) {
      print('查询使用统计失败: $e');
      return [];
    }
  }

  /// 查询事件统计（内部方法）
  Future<List<Map<String, dynamic>>> queryEvents(DateTime startDate, DateTime endDate) async {
    try {
      // 使用静态方法查询事件
      final events = await UsageStats.queryEvents(startDate, endDate);

      // 将 UsageInfo 对象转换为 Map
      return events.map((event) {
        return {
          'eventType': event.eventType ?? '',
          'timeStamp': event.timeStamp ?? '',
          'packageName': event.packageName ?? '',
        };
      }).toList();
    } catch (e) {
      print('查询事件统计失败: $e');
      return [];
    }
  }

  /// 检查是否有权限
  Future<bool> hasPermission() async {
    if (!Platform.isAndroid) {
      return false;
    }
    
    try {
      return await UsageStats.checkUsagePermission() ?? false;
    } catch (e) {
      print('检查使用统计权限失败: $e');
      return false;
    }
  }

  /// 请求权限（跳转到系统设置）
  Future<void> requestPermission() async {
    if (!Platform.isAndroid) {
      return;
    }
    
    try {
      await UsageStats.grantUsagePermission();
    } catch (e) {
      print('请求使用统计权限失败: $e');
    }
  }
}

