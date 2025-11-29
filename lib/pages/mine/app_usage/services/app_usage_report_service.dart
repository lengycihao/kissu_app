import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kissu_app/network/tools/logging/log_manager.dart';
import 'package:kissu_app/pages/mine/app_usage/models/app_usage_record.dart';
import 'package:kissu_app/pages/mine/app_usage/api/app_usage_api.dart';

/// App使用记录采集上报服务
/// 
/// 功能：
/// 1. 每天第一次打开app时全量上报当天截止到当前时间的所有数据
/// 2. 之后每2分钟增量上报新产生的数据
/// 3. 每天23:59:59增量上报并清空本地记录
/// 4. 每天第一次上报前先清除前一天的本地缓存
class AppUsageReportService {
  static const platform = MethodChannel('app_usage_channel');
  static const _tag = 'AppUsageReportService';
  
  // 定时器
  Timer? _reportTimer;
  Timer? _midnightTimer;
  
  // 是否已经完成今天的首次上报
  bool _hasReportedToday = false;
  
  // 上次上报的记录（用于增量对比）
  // key: packageName, value: 最后一条会话的打开时间
  Map<String, int> _lastReportedSessions = {};
  
  // 单例
  static final AppUsageReportService _instance = AppUsageReportService._internal();
  factory AppUsageReportService() => _instance;
  AppUsageReportService._internal();
  
  /// 初始化服务（自动采集所有有使用记录的应用）
  Future<void> initialize() async {
    stop(); // 先停止旧服务
    
    await _loadLastReportedSessions();
    await _checkAndClearOldData();
    
    // 执行首次上报
    await _performFirstReportOfDay();
    
    // 启动定时上报
    _startReportTimer();
    
    // 设置午夜上报
    _startMidnightTimer();
    
    logger.info('✅ App使用记录上报服务已启动（自动采集所有应用）', tag: _tag);
  }
  
  /// 停止服务
  void stop() {
    _reportTimer?.cancel();
    _midnightTimer?.cancel();
    logger.info('⏹️ App使用记录上报服务已停止', tag: _tag);
  }
  
  /// 检查并清除旧数据
  Future<void> _checkAndClearOldData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastReportDate = prefs.getString('last_report_date') ?? '';
      final today = _getTodayString();
      
      if (lastReportDate != today) {
        // 新的一天，清除旧数据
        logger.info('🆕 检测到新的一天，清除旧数据', tag: _tag);
        await prefs.remove('last_reported_sessions');
        await prefs.setString('last_report_date', today);
        _lastReportedSessions.clear();
        _hasReportedToday = false;
      } else {
        // 同一天，检查是否已完成首次上报
        _hasReportedToday = prefs.getBool('has_reported_today') ?? false;
      }
    } catch (e) {
      logger.error('检查并清除旧数据失败: $e', tag: _tag, error: e);
    }
  }
  
  /// 执行当天首次上报（全量上报）
  Future<void> _performFirstReportOfDay() async {
    if (_hasReportedToday) {
      logger.info('今天已完成首次上报，跳过', tag: _tag);
      return;
    }
    
    try {
      logger.info('📤 开始执行当天首次全量上报...', tag: _tag);
      
      final records = await _collectUsageData();
      
      if (records.isEmpty) {
        logger.info('暂无使用记录需要上报', tag: _tag);
        _hasReportedToday = true;
        await _saveReportStatus();
        return;
      }
      
      // 上报数据
      final result = await AppUsageApi.reportAppUsage(records);
      
      if (result.isSuccess) {
        logger.info('✅ 首次全量上报成功: ${records.length}个应用', tag: _tag);
        
        // 保存上报记录
        await _saveLastReportedSessions(records);
        _hasReportedToday = true;
        await _saveReportStatus();
      } else {
        logger.error('首次全量上报失败: ${result.msg}', tag: _tag);
      }
    } catch (e) {
      logger.error('执行首次上报异常: $e', tag: _tag, error: e);
    }
  }
  
  /// 启动定时上报（每2分钟）
  void _startReportTimer() {
    _reportTimer?.cancel();
    _reportTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _performIncrementalReport();
    });
    logger.info('⏰ 定时上报已启动（每2分钟）', tag: _tag);
  }
  
  /// 执行增量上报
  Future<void> _performIncrementalReport() async {
    if (!_hasReportedToday) {
      logger.info('尚未完成首次上报，跳过增量上报', tag: _tag);
      return;
    }
    
    try {
      logger.info('📤 开始执行增量上报...', tag: _tag);
      
      // 采集当天全量数据
      final allRecords = await _collectUsageData();
      
      if (allRecords.isEmpty) {
        logger.info('暂无使用记录', tag: _tag);
        return;
      }
      
      // 筛选出增量数据
      final incrementalRecords = _filterIncrementalData(allRecords);
      
      if (incrementalRecords.isEmpty) {
        logger.info('暂无新增使用记录', tag: _tag);
        return;
      }
      
      // 上报增量数据
      final result = await AppUsageApi.reportAppUsage(incrementalRecords);
      
      if (result.isSuccess) {
        logger.info('✅ 增量上报成功: ${incrementalRecords.length}个应用', tag: _tag);
        
        // 更新上报记录
        await _saveLastReportedSessions(allRecords);
      } else {
        logger.error('增量上报失败: ${result.msg}', tag: _tag);
      }
    } catch (e) {
      logger.error('执行增量上报异常: $e', tag: _tag, error: e);
    }
  }
  
  /// 启动午夜定时器（每天23:59:59）
  void _startMidnightTimer() {
    _midnightTimer?.cancel();
    
    // 计算距离今天23:59:59的时间
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day, 23, 59, 59);
    var duration = midnight.difference(now);
    
    if (duration.isNegative) {
      // 已经过了今天的23:59:59，计算明天的
      final tomorrow = now.add(const Duration(days: 1));
      final nextMidnight = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 59, 59);
      duration = nextMidnight.difference(now);
    }
    
    _midnightTimer = Timer(duration, () {
      _performMidnightReport();
      // 递归设置下一个午夜定时器
      _startMidnightTimer();
    });
    
    logger.info('🌙 午夜定时器已设置，将在 ${duration.inHours}小时${duration.inMinutes.remainder(60)}分钟后触发', tag: _tag);
  }
  
  /// 执行午夜上报并清空记录
  Future<void> _performMidnightReport() async {
    try {
      logger.info('🌙 执行午夜上报并清空记录...', tag: _tag);
      
      // 最后一次增量上报
      await _performIncrementalReport();
      
      // 清空本地记录
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_reported_sessions');
      await prefs.remove('has_reported_today');
      _lastReportedSessions.clear();
      _hasReportedToday = false;
      
      logger.info('✅ 午夜上报完成，本地记录已清空', tag: _tag);
    } catch (e) {
      logger.error('执行午夜上报异常: $e', tag: _tag, error: e);
    }
  }
  
  /// 采集使用数据（自动采集所有有使用记录的应用）
  Future<List<AppUsageRecord>> _collectUsageData() async {
    try {
      // 调用Native方法获取所有有使用记录的应用
      final List<dynamic> result = await platform.invokeMethod(
        'getAllUsageData',  // 使用新的方法名，获取所有应用的使用数据
      );
      
      final records = <AppUsageRecord>[];
      int totalApps = result.length;
      int appsWithData = 0;
      int appsWithoutData = 0;
      
      for (final data in result) {
        final map = _convertMap(data);
        final appName = map['appName'] as String;
        final packageName = map['packageName'] as String;
        
        // 只处理有使用记录的应用
        final hourlyRecords = (map['hourlyRecords'] as List<dynamic>)
            .map((e) => HourlyUsageRecord.fromJson(_convertMap(e)))
            .toList();
        
        if (hourlyRecords.isNotEmpty) {
          appsWithData++;
          records.add(AppUsageRecord(
            appName: appName,
            packageName: packageName,
            iconBase64: map['iconBase64'] as String?,
            date: map['date'] as String,
            hourlyRecords: hourlyRecords,
          ));
          logger.info('✅ $appName: ${hourlyRecords.length}个小时记录', tag: _tag);
        } else {
          appsWithoutData++;
          logger.info('⚠️ $appName: 无使用记录', tag: _tag);
        }
      }
      
      logger.info('📊 采集完成: 总共${totalApps}个应用, 有数据${appsWithData}个, 无数据${appsWithoutData}个', tag: _tag);
      return records;
    } catch (e) {
      logger.error('采集使用数据失败: $e', tag: _tag, error: e);
      return [];
    }
  }
  
  /// 筛选增量数据
  List<AppUsageRecord> _filterIncrementalData(List<AppUsageRecord> allRecords) {
    final incrementalRecords = <AppUsageRecord>[];
    
    for (final record in allRecords) {
      final packageName = record.packageName;
      final lastReportedTime = _lastReportedSessions[packageName] ?? 0;
      
      // 筛选出新增的会话
      final newSessions = record.allSessions
          .where((session) => session.openTime > lastReportedTime)
          .toList();
      
      if (newSessions.isEmpty) {
        continue;
      }
      
      // 按小时重新组织新增会话
      final hourlyMap = <int, List<AppUsageSession>>{};
      for (final session in newSessions) {
        final hour = DateTime.fromMillisecondsSinceEpoch(session.openTime).hour;
        if (!hourlyMap.containsKey(hour)) {
          hourlyMap[hour] = [];
        }
        hourlyMap[hour]!.add(session);
      }
      
      // 构建每小时记录
      final newHourlyRecords = <HourlyUsageRecord>[];
      hourlyMap.forEach((hour, sessions) {
        final totalDuration = sessions.fold<int>(0, (sum, s) => sum + s.duration);
        newHourlyRecords.add(HourlyUsageRecord(
          hour: hour,
          totalDuration: totalDuration,
          sessionCount: sessions.length,
          sessions: sessions,
        ));
      });
      
      newHourlyRecords.sort((a, b) => a.hour.compareTo(b.hour));
      
      incrementalRecords.add(AppUsageRecord(
        appName: record.appName,
        packageName: record.packageName,
        iconBase64: record.iconBase64,
        date: record.date,
        hourlyRecords: newHourlyRecords,
      ));
      
      logger.info('📈 ${record.appName}: 新增 ${newSessions.length} 条会话记录', tag: _tag);
    }
    
    return incrementalRecords;
  }
  
  /// 保存上报记录
  Future<void> _saveLastReportedSessions(List<AppUsageRecord> records) async {
    try {
      for (final record in records) {
        final sessions = record.allSessions;
        if (sessions.isNotEmpty) {
          // 保存最后一条会话的打开时间
          _lastReportedSessions[record.packageName] = sessions.last.openTime;
        }
      }
      
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_lastReportedSessions);
      await prefs.setString('last_reported_sessions', json);
      
      logger.info('💾 已保存上报记录: ${_lastReportedSessions.length}个应用', tag: _tag);
    } catch (e) {
      logger.error('保存上报记录失败: $e', tag: _tag, error: e);
    }
  }
  
  /// 加载上报记录
  Future<void> _loadLastReportedSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('last_reported_sessions');
      
      if (json != null && json.isNotEmpty) {
        final Map<String, dynamic> map = jsonDecode(json);
        _lastReportedSessions = map.map((key, value) => MapEntry(key, value as int));
        logger.info('📂 已加载上报记录: ${_lastReportedSessions.length}个应用', tag: _tag);
      }
    } catch (e) {
      logger.error('加载上报记录失败: $e', tag: _tag, error: e);
    }
  }
  
  /// 保存上报状态
  Future<void> _saveReportStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_reported_today', _hasReportedToday);
    } catch (e) {
      logger.error('保存上报状态失败: $e', tag: _tag, error: e);
    }
  }
  
  /// 获取今天的日期字符串
  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
  
  /// 递归转换Map类型
  Map<String, dynamic> _convertMap(dynamic data) {
    if (data is Map) {
      return data.map((key, value) {
        if (value is Map) {
          return MapEntry(key.toString(), _convertMap(value));
        } else if (value is List) {
          return MapEntry(key.toString(), value.map((e) {
            if (e is Map) {
              return _convertMap(e);
            }
            return e;
          }).toList());
        }
        return MapEntry(key.toString(), value);
      });
    }
    return {};
  }
  
  // ==================== 调试方法 ====================
  
  /// 手动触发全量上报（用于调试）
  Future<Map<String, dynamic>> debugFullReport() async {
    try {
      logger.info('🔧 [调试] 手动触发全量上报', tag: _tag);
      
      final records = await _collectUsageData();
      
      if (records.isEmpty) {
        return {
          'success': false,
          'message': '暂无使用记录',
          'data': <AppUsageRecord>[],
        };
      }
      
      final result = await AppUsageApi.reportAppUsage(records);
      
      if (result.isSuccess) {
        await _saveLastReportedSessions(records);
        _hasReportedToday = true;
        await _saveReportStatus();
      }
      
      return {
        'success': result.isSuccess,
        'message': result.msg ?? (result.isSuccess ? '上报成功' : '上报失败'),
        'data': records,
      };
    } catch (e) {
      logger.error('[调试] 全量上报异常: $e', tag: _tag, error: e);
      return {
        'success': false,
        'message': '上报异常: $e',
        'data': <AppUsageRecord>[],
      };
    }
  }
  
  /// 手动触发增量上报（用于调试）
  Future<Map<String, dynamic>> debugIncrementalReport() async {
    try {
      logger.info('🔧 [调试] 手动触发增量上报', tag: _tag);
      
      final allRecords = await _collectUsageData();
      
      if (allRecords.isEmpty) {
        return {
          'success': false,
          'message': '暂无使用记录',
          'data': <AppUsageRecord>[],
        };
      }
      
      final incrementalRecords = _filterIncrementalData(allRecords);
      
      if (incrementalRecords.isEmpty) {
        return {
          'success': false,
          'message': '暂无新增记录',
          'data': <AppUsageRecord>[],
        };
      }
      
      final result = await AppUsageApi.reportAppUsage(incrementalRecords);
      
      if (result.isSuccess) {
        await _saveLastReportedSessions(allRecords);
      }
      
      return {
        'success': result.isSuccess,
        'message': result.msg ?? (result.isSuccess ? '上报成功' : '上报失败'),
        'data': incrementalRecords,
      };
    } catch (e) {
      logger.error('[调试] 增量上报异常: $e', tag: _tag, error: e);
      return {
        'success': false,
        'message': '上报异常: $e',
        'data': <AppUsageRecord>[],
      };
    }
  }
  
  /// 查看待上报数据（用于调试）
  Future<Map<String, dynamic>> debugViewPendingData() async {
    try {
      logger.info('🔧 [调试] 查看待上报数据', tag: _tag);
      
      final allRecords = await _collectUsageData();
      
      if (allRecords.isEmpty) {
        return {
          'success': true,
          'message': '暂无使用记录',
          'allData': <AppUsageRecord>[],
          'incrementalData': <AppUsageRecord>[],
          'lastReportedSessions': _lastReportedSessions,
        };
      }
      
      final incrementalRecords = _filterIncrementalData(allRecords);
      
      return {
        'success': true,
        'message': '数据加载成功',
        'allData': allRecords,
        'incrementalData': incrementalRecords,
        'lastReportedSessions': _lastReportedSessions,
      };
    } catch (e) {
      logger.error('[调试] 查看待上报数据异常: $e', tag: _tag, error: e);
      return {
        'success': false,
        'message': '加载失败: $e',
        'allData': <AppUsageRecord>[],
        'incrementalData': <AppUsageRecord>[],
        'lastReportedSessions': {},
      };
    }
  }
  
  /// 清空本地记录（用于调试）
  Future<void> debugClearLocalData() async {
    try {
      logger.info('🔧 [调试] 清空本地记录', tag: _tag);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_reported_sessions');
      await prefs.remove('has_reported_today');
      await prefs.remove('last_report_date');
      
      _lastReportedSessions.clear();
      _hasReportedToday = false;
      
      logger.info('✅ 本地记录已清空', tag: _tag);
    } catch (e) {
      logger.error('[调试] 清空本地记录失败: $e', tag: _tag, error: e);
    }
  }
}
