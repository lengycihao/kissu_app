import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kissu_app/network/tools/logging/log_manager.dart';
import 'package:kissu_app/pages/mine/app_usage/models/app_usage_record.dart';
import 'package:kissu_app/pages/mine/app_usage/api/app_usage_api.dart';
import 'package:kissu_app/pages/mine/app_usage/services/app_logo_cache_service.dart';
import 'package:kissu_app/network/public/file_upload_api.dart';

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
  // key: packageName, value: Map<openTime, closeTimeReported>
  // closeTimeReported: true表示该会话的closeTime已上报，false表示只上报了openTime
  Map<String, Map<int, bool>> _lastReportedSessions = {};
  
  // 单例
  static final AppUsageReportService _instance = AppUsageReportService._internal();
  factory AppUsageReportService() => _instance;
  AppUsageReportService._internal();
  
  // Logo缓存服务
  final _logoCacheService = AppLogoCacheService();
  
  /// 初始化服务（自动采集所有有使用记录的应用）
  Future<void> initialize({bool forceFullReport = false}) async {
    stop(); // 先停止旧服务
    
    // 初始化logo缓存服务
    await _logoCacheService.initialize();
    
    // 如果强制全量上报（换账号等情况），清除上报状态
    if (forceFullReport) {
      // logDebug('🔄 强制全量上报：清除之前的上报状态', tag: _tag);
      await _clearReportStatus();
    } else {
      await _loadLastReportedSessions();
      await _checkAndClearOldData();
    }
    
    // 执行首次上报
    await _performFirstReportOfDay();
    
    // 启动定时上报
    _startReportTimer();
    
    // 设置午夜上报
    _startMidnightTimer();
    
    logInfo('✅ App使用记录上报服务已启动（自动采集所有应用，每2分钟自动上报）', tag: _tag);
  }
  
  /// 停止服务
  void stop() {
    _reportTimer?.cancel();
    _midnightTimer?.cancel();
    logInfo('⏹️ App使用记录上报服务已停止', tag: _tag);
  }
  
  /// 清除上报状态（用于换账号等情况）
  Future<void> _clearReportStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_reported_sessions');
      await prefs.remove('has_reported_today');
      await prefs.remove('last_report_date');
      _lastReportedSessions.clear();
      _hasReportedToday = false;
      // logDebug('✅ 上报状态已清除', tag: _tag);
    } catch (e) {
      logError('清除上报状态失败: $e', tag: _tag, error: e);
    }
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
      logError('检查并清除旧数据失败: $e', tag: _tag, error: e);
    }
  }
  
  /// 执行当天首次上报（全量上报）
  Future<void> _performFirstReportOfDay() async {
    if (_hasReportedToday) {
      // logDebug('今天已完成首次上报，跳过', tag: _tag);
      return;
    }
    
    try {
      // logDebug('📤 开始执行当天首次全量上报...', tag: _tag);
      
      // 首次上报时传入 isFirstReport=true，增加延迟和重试
      final records = await _collectUsageData(isFirstReport: true);
      
      if (records.isEmpty) {
        // logDebug('暂无使用记录需要上报', tag: _tag);
        _hasReportedToday = true;
        await _saveReportStatus();
        return;
      }
      
      // 自动上报数据
      await _reportUsageData(records);
      
      // 保存上报记录
      await _saveLastReportedSessions(records);
      _hasReportedToday = true;
      await _saveReportStatus();
    } catch (e) {
      logger.error('执行首次上报异常: $e', tag: _tag, error: e);
    }
  }
  
  /// 启动定时上报（每2分钟）
  void _startReportTimer() {
    _reportTimer?.cancel();
    _reportTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      // 🔥 修复：每次定时上报前检查是否跨天
      _checkAndHandleDayChange();
      _performIncrementalReport();
    });
    // logDebug('⏰ 定时上报已启动（每2分钟）', tag: _tag);
  }
  
  /// 🔥 新增：检查并处理跨天情况
  Future<void> _checkAndHandleDayChange() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastReportDate = prefs.getString('last_report_date') ?? '';
      final today = _getTodayString();
      
      if (lastReportDate.isNotEmpty && lastReportDate != today) {
        // 检测到跨天，需要清除旧数据并触发新一天的首次上报
        logInfo('🆕 定时检查检测到跨天：$lastReportDate -> $today，触发新一天首次上报', tag: _tag);
        
        // 清除旧数据
        await prefs.remove('last_reported_sessions');
        await prefs.setString('last_report_date', today);
        _lastReportedSessions.clear();
        _hasReportedToday = false;
        
        // 执行新一天的首次上报
        await _performFirstReportOfDay();
      }
    } catch (e) {
      logError('检查跨天失败: $e', tag: _tag, error: e);
    }
  }
  
  /// 执行增量上报
  Future<void> _performIncrementalReport() async {
    if (!_hasReportedToday) {
      // logDebug('尚未完成首次上报，跳过增量上报', tag: _tag);
      return;
    }
    
    try {
      // logDebug('📤 开始执行增量上报...', tag: _tag);
      
      // 采集当天全量数据
      final allRecords = await _collectUsageData();
      
      if (allRecords.isEmpty) {
        // logDebug('暂无使用记录', tag: _tag);
        return;
      }
      
      // 筛选出增量数据
      final incrementalRecords = _filterIncrementalData(allRecords);
      
      if (incrementalRecords.isEmpty) {
        // logDebug('暂无新增使用记录', tag: _tag);
        return;
      }
      
      // 自动上报增量数据
      await _reportUsageData(incrementalRecords);
      
      // 更新上报记录
      await _saveLastReportedSessions(allRecords);
    } catch (e) {
      logError('执行增量上报异常: $e', tag: _tag, error: e);
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
    
    // logDebug('🌙 午夜定时器已设置，将在 ${duration.inHours}小时${duration.inMinutes.remainder(60)}分钟后触发', tag: _tag);
  }
  
  /// 执行午夜上报并清空记录
  Future<void> _performMidnightReport() async {
    try {
      // logDebug('🌙 执行午夜上报并清空记录...', tag: _tag);
      
      // 最后一次增量上报
      await _performIncrementalReport();
      
      // 清空本地记录（注意：不清空logo缓存，因为logo不会改变，保留缓存可以避免重复上传）
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_reported_sessions');
      await prefs.remove('has_reported_today');
      _lastReportedSessions.clear();
      _hasReportedToday = false;
      
      // 🔥 修复：更新last_report_date为新的一天
      final tomorrow = DateTime.now().add(const Duration(seconds: 2)); // 加2秒确保已经过了午夜
      final newDateStr = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
      await prefs.setString('last_report_date', newDateStr);
      
      // logDebug('✅ 午夜上报完成，本地记录已清空（logo缓存保留）', tag: _tag);
      
      // 🔥 修复：延迟几秒后触发新一天的首次上报
      // 确保已经过了午夜12点，系统数据已更新
      Future.delayed(const Duration(seconds: 5), () {
        _performFirstReportOfNewDay();
      });
    } catch (e) {
      logError('执行午夜上报异常: $e', tag: _tag, error: e);
    }
  }
  
  /// 🔥 新增：执行新一天的首次上报（午夜后自动触发）
  Future<void> _performFirstReportOfNewDay() async {
    try {
      // logDebug('🌅 开始执行新一天的首次上报...', tag: _tag);
      
      // 等待系统数据准备好
      await Future.delayed(const Duration(seconds: 3));
      
      final records = await _collectUsageData(isFirstReport: true);
      
      if (records.isEmpty) {
        // logDebug('新一天暂无使用记录需要上报', tag: _tag);
        _hasReportedToday = true;
        await _saveReportStatus();
        return;
      }
      
      // 上报数据
      await _reportUsageData(records);
      
      // 保存上报记录
      await _saveLastReportedSessions(records);
      _hasReportedToday = true;
      await _saveReportStatus();
      
      // logDebug('✅ 新一天首次上报完成', tag: _tag);
    } catch (e) {
      logError('新一天首次上报异常: $e', tag: _tag, error: e);
    }
  }
  
  /// 采集使用数据（自动采集所有有使用记录的应用）
  /// [retryCount] 重试次数，用于权限刚开启时重试获取数据
  /// [isFirstReport] 是否是首次上报，用于决定是否需要额外延迟和重试
  Future<List<AppUsageRecord>> _collectUsageData({int retryCount = 0, bool isFirstReport = false}) async {
    try {
      // 如果是首次上报且是第一次尝试，增加延迟让系统有时间准备数据
      if (isFirstReport && retryCount == 0) {
        // logDebug('⏳ 首次上报：等待3秒让系统准备数据...', tag: _tag);
        await Future.delayed(const Duration(seconds: 3));
      }
      
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
          // logDebug('✅ $appName: ${hourlyRecords.length}个小时记录', tag: _tag);
        } else {
          appsWithoutData++;
          // logDebug('⚠️ $appName: 无使用记录', tag: _tag);
        }
      }
      
      logInfo('📊 采集完成: 总共$totalApps个应用, 有数据$appsWithData个, 无数据$appsWithoutData个', tag: _tag);
      
      // 如果第一次采集没有数据，且是首次上报，增加延迟后重试（最多重试2次）
      if (records.isEmpty && isFirstReport && retryCount < 2) {
        final delaySeconds = (retryCount + 1) * 3; // 第1次重试延迟3秒，第2次延迟6秒
        // logDebug('⚠️ 首次采集无数据（重试${retryCount + 1}/2），可能是权限刚开启或系统数据未准备好，等待${delaySeconds}秒后重试...', tag: _tag);
        await Future.delayed(Duration(seconds: delaySeconds));
        return await _collectUsageData(retryCount: retryCount + 1, isFirstReport: isFirstReport);
      }
      
      return records;
    } catch (e) {
      logError('采集使用数据失败: $e', tag: _tag, error: e);
      
      // 如果是首次上报且重试次数未达上限，增加延迟后重试
      if (isFirstReport && retryCount < 2) {
        final delaySeconds = (retryCount + 1) * 3; // 第1次重试延迟3秒，第2次延迟6秒
        logWarning('⚠️ 采集数据异常（重试${retryCount + 1}/2），等待${delaySeconds}秒后重试...', tag: _tag);
        await Future.delayed(Duration(seconds: delaySeconds));
        return await _collectUsageData(retryCount: retryCount + 1, isFirstReport: isFirstReport);
      }
      
      return [];
    }
  }
  
  /// 筛选增量数据
  /// 逻辑：
  /// 1. 如果会话的openTime已上报，但closeTime未上报，则只上报closeTime
  /// 2. 如果会话的openTime未上报，则上报openTime和closeTime（如果有）
  List<AppUsageRecord> _filterIncrementalData(List<AppUsageRecord> allRecords) {
    final incrementalRecords = <AppUsageRecord>[];
    
    for (final record in allRecords) {
      final packageName = record.packageName;
      final reportedSessions = _lastReportedSessions[packageName] ?? <int, bool>{};
      
      // 筛选出需要上报的会话
      final sessionsToReport = <AppUsageSession>[];
      for (final session in record.allSessions) {
        final openTimeReported = reportedSessions.containsKey(session.openTime);
        final closeTimeReported = reportedSessions[session.openTime] ?? false;
        
        if (openTimeReported) {
          // openTime已上报，检查closeTime是否需要上报
          if (session.closeTime > 0 && !session.isRunning && !closeTimeReported) {
            // 只上报closeTime，创建一个只包含closeTime的会话对象
            // 注意：这里我们需要特殊处理，因为AppUsageSession需要openTime
            // 但上报时我们只会上报closeTime（operate_type=0）
            // 所以我们需要标记这个会话只上报closeTime
            sessionsToReport.add(session);
            // logDebug('📈 ${record.appName}: 会话 ${session.openTime} 的closeTime需要上报', tag: _tag);
          }
        } else {
          // openTime未上报，上报整个会话（包括openTime和closeTime）
          sessionsToReport.add(session);
          // logDebug('📈 ${record.appName}: 新会话 ${session.openTime} 需要上报', tag: _tag);
        }
      }
      
      if (sessionsToReport.isEmpty) {
        continue;
      }
      
      // 按小时重新组织需要上报的会话
      final hourlyMap = <int, List<AppUsageSession>>{};
      for (final session in sessionsToReport) {
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
      
      // logDebug('📈 ${record.appName}: 需要上报 ${sessionsToReport.length} 条会话记录', tag: _tag);
    }
    
    return incrementalRecords;
  }
  
  /// 保存上报记录
  /// 更新每个会话的上报状态（openTime和closeTime）
  Future<void> _saveLastReportedSessions(List<AppUsageRecord> records) async {
    try {
      for (final record in records) {
        final packageName = record.packageName;
        final sessions = record.allSessions;
        
        // 初始化该应用的上报记录
        if (!_lastReportedSessions.containsKey(packageName)) {
          _lastReportedSessions[packageName] = <int, bool>{};
        }
        
        // 更新每个会话的上报状态
        for (final session in sessions) {
          final openTimeReported = _lastReportedSessions[packageName]!.containsKey(session.openTime);
          
          // 如果openTime未上报，标记为已上报（closeTime未上报）
          if (!openTimeReported) {
            _lastReportedSessions[packageName]![session.openTime] = false; // closeTime未上报
          }
          
          // 如果closeTime已上报，更新状态
          if (session.closeTime > 0 && !session.isRunning) {
            _lastReportedSessions[packageName]![session.openTime] = true; // closeTime已上报
          }
        }
      }
      
      final prefs = await SharedPreferences.getInstance();
      // 将Map转换为可序列化的格式
      final serializableMap = <String, Map<String, bool>>{};
      _lastReportedSessions.forEach((packageName, sessions) {
        serializableMap[packageName] = sessions.map((key, value) => MapEntry(key.toString(), value));
      });
      final json = jsonEncode(serializableMap);
      await prefs.setString('last_reported_sessions', json);
      
      // logDebug('💾 已保存上报记录: ${_lastReportedSessions.length}个应用', tag: _tag);
    } catch (e) {
      logError('保存上报记录失败: $e', tag: _tag, error: e);
    }
  }
  
  /// 加载上报记录
  Future<void> _loadLastReportedSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('last_reported_sessions');
      
      if (json != null && json.isNotEmpty) {
        final Map<String, dynamic> map = jsonDecode(json);
        _lastReportedSessions = <String, Map<int, bool>>{};
        
        // 解析新的格式：Map<String, Map<String, bool>>
        map.forEach((packageName, sessions) {
          if (sessions is Map) {
            final sessionMap = <int, bool>{};
            sessions.forEach((openTimeStr, closeTimeReported) {
              final openTime = int.tryParse(openTimeStr.toString());
              if (openTime != null) {
                sessionMap[openTime] = closeTimeReported as bool? ?? false;
              }
            });
            _lastReportedSessions[packageName] = sessionMap;
          }
        });
        
        // logDebug('📂 已加载上报记录: ${_lastReportedSessions.length}个应用', tag: _tag);
      }
    } catch (e) {
      logError('加载上报记录失败: $e', tag: _tag, error: e);
      // 如果解析失败，尝试兼容旧格式（Map<String, int>）
      try {
        final prefs = await SharedPreferences.getInstance();
        final json = prefs.getString('last_reported_sessions');
        if (json != null && json.isNotEmpty) {
          final Map<String, dynamic> map = jsonDecode(json);
          // 兼容旧格式：将旧格式转换为新格式
          _lastReportedSessions = <String, Map<int, bool>>{};
          map.forEach((packageName, lastOpenTime) {
            if (lastOpenTime is int) {
              _lastReportedSessions[packageName] = {lastOpenTime: false}; // closeTime未上报
            }
          });
          // logDebug('📂 已从旧格式加载上报记录: ${_lastReportedSessions.length}个应用', tag: _tag);
        }
      } catch (e2) {
        logError('兼容旧格式加载失败: $e2', tag: _tag, error: e2);
      }
    }
  }
  
  /// 保存上报状态
  Future<void> _saveReportStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_reported_today', _hasReportedToday);
    } catch (e) {
      logError('保存上报状态失败: $e', tag: _tag, error: e);
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
      
      // 注意：上报功能已移至调试页面，这里只返回采集的数据
      // 调用者需要在controller中处理数据转换和logo上传后再上报
      return {
        'success': true,
        'message': '数据采集成功，请在调试页面手动上报',
        'data': records,
      };
    } catch (e) {
      logError('[调试] 全量上报异常: $e', tag: _tag, error: e);
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
      logDebug('🔧 [调试] 手动触发增量上报', tag: _tag);
      
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
      
      // 注意：上报功能已移至调试页面，这里只返回采集的数据
      // 调用者需要在controller中处理数据转换和logo上传后再上报
      return {
        'success': true,
        'message': '数据采集成功，请在调试页面手动上报',
        'data': incrementalRecords,
      };
    } catch (e) {
      logError('[调试] 增量上报异常: $e', tag: _tag, error: e);
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
      logDebug('🔧 [调试] 查看待上报数据', tag: _tag);
      
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
      logError('[调试] 查看待上报数据异常: $e', tag: _tag, error: e);
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
      logDebug('🔧 [调试] 清空本地记录', tag: _tag);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_reported_sessions');
      await prefs.remove('has_reported_today');
      await prefs.remove('last_report_date');
      
      _lastReportedSessions.clear();
      _hasReportedToday = false;
      
      logDebug('✅ 本地记录已清空', tag: _tag);
    } catch (e) {
      logError('[调试] 清空本地记录失败: $e', tag: _tag, error: e);
    }
  }
  
  /// 将AppUsageRecord转换为上报格式
  /// [record] 应用使用记录
  /// [logoUrl] logo的URL
  /// 返回转换后的数据格式
  /// 注意：只上报未上报的operate_type，避免重复上报
  Map<String, dynamic> _convertRecordToReportFormat(AppUsageRecord record, String? logoUrl) {
    // 获取所有会话并按时间排序
    final sessions = record.allSessions;
    final packageName = record.packageName;
    final reportedSessions = _lastReportedSessions[packageName] ?? <int, bool>{};
    
    // 构建record数组（包含operate_time和operate_type）
    final recordList = <Map<String, dynamic>>[];
    
    for (final session in sessions) {
      final openTimeReported = reportedSessions.containsKey(session.openTime);
      final closeTimeReported = reportedSessions[session.openTime] ?? false;
      
      if (!openTimeReported) {
        // openTime未上报，上报openTime（operate_type = 1）
        recordList.add({
          'operate_time': session.openTime ~/ 1000, // 转换为秒级时间戳
          'operate_type': 1,
        });
      }
      
      // 关闭app（operate_type = 0），如果有关闭时间且未上报
      if (session.closeTime > 0 && !session.isRunning && !closeTimeReported) {
        recordList.add({
          'operate_time': session.closeTime ~/ 1000, // 转换为秒级时间戳
          'operate_type': 0,
        });
      }
    }
    
    return {
      'app_logo': logoUrl ?? '',
      'app_name': record.appName,
      'app_pkg': record.packageName,
      'record': recordList,
    };
  }
  
  /// 检查原生层是否正在上报
  Future<bool> _isNativeReporting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('native_app_usage_reporting') ?? false;
    } catch (e) {
      logError('检查原生层上报状态失败: $e', tag: _tag, error: e);
      return false;
    }
  }
  
  /// 上报使用数据（自动上报）
  Future<void> _reportUsageData(List<AppUsageRecord> records) async {
    if (records.isEmpty) {
      // logDebug('没有可上报的数据', tag: _tag);
      return;
    }
    
    // 🔥 检查原生层是否正在上报，如果是则跳过Flutter层上报
    if (await _isNativeReporting()) {
      // logDebug('⏸️ 原生层正在上报，跳过Flutter层上报', tag: _tag);
      return;
    }
    
    try {
      // logDebug('📤 开始自动上报: ${records.length}个应用', tag: _tag);
      
      // 记录每个应用的详细信息
      for (final record in records) {
        final totalMin = record.totalDuration ~/ 1000 ~/ 60;
        final totalSec = (record.totalDuration ~/ 1000) % 60;
        logInfo('📱 ${record.appName} (${record.packageName}): ${record.sessionCount}个会话, 使用${totalMin}分${totalSec}秒', tag: _tag);
      }
      
      // 处理每个应用的数据转换
      final appUseRecordData = <Map<String, dynamic>>[];
      int? dateInt;
      
      for (final record in records) {
        // 获取或上传logo URL
        String? logoUrl = _logoCacheService.getCachedLogoUrl(record.packageName);
        
        if (logoUrl != null && logoUrl.isNotEmpty) {
          // logDebug('✅ ${record.appName}: 使用缓存的logo', tag: _tag);
        } else {
          // 缓存中没有，尝试上传
          if (record.iconBase64 != null && record.iconBase64!.isNotEmpty) {
            // logDebug('📤 ${record.appName}: 缓存中没有logo，尝试上传', tag: _tag);
            logoUrl = await _uploadLogoFromBase64(record.packageName, record.iconBase64!);
            if (logoUrl != null && logoUrl.isNotEmpty) {
              // logDebug('✅ ${record.appName}: logo上传成功', tag: _tag);
            } else {
              logWarning('⚠️ ${record.appName}: logo上传失败', tag: _tag);
            }
          } else {
            logWarning('⚠️ ${record.appName}: 缓存中没有logo且iconBase64为空，无法上传logo', tag: _tag);
          }
        }
        
        // 转换数据格式（如果没有logo，使用空字符串）
        final convertedData = _convertRecordToReportFormat(record, logoUrl ?? '');
        appUseRecordData.add(convertedData);
        
        // 获取日期（使用第一个记录的日期）
        if (dateInt == null) {
          final dateParts = record.date.split('-');
          dateInt = int.parse('${dateParts[0]}${dateParts[1].padLeft(2, '0')}${dateParts[2].padLeft(2, '0')}');
        }
      }
      
      if (appUseRecordData.isEmpty) {
        logWarning('转换后的数据为空，跳过上报', tag: _tag);
        return;
      }
      
      // 上报数据
      final result = await AppUsageApi.reportAppUsage(appUseRecordData, dateInt!);
      
      if (result.isSuccess) {
        // logDebug('✅ 自动上报成功: ${records.length}个应用', tag: _tag);
      } else {
        logError('自动上报失败: ${result.msg}', tag: _tag);
      }
    } catch (e) {
      logError('自动上报异常: $e', tag: _tag, error: e);
    }
  }
  
  /// 从base64上传logo
  Future<String?> _uploadLogoFromBase64(String packageName, String iconBase64) async {
    try {
      // 解码base64
      final iconBytes = base64Decode(iconBase64);
      
      if (iconBytes.isEmpty) {
        logWarning('logo数据为空: $packageName', tag: _tag);
        return null;
      }
      
      // 创建临时文件
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('${tempDir.path}/app_logo_${packageName}_$timestamp.png');
      
      try {
        // 将字节数据写入临时文件
        await tempFile.writeAsBytes(iconBytes);
        
        // 上传文件
        final fileUploadApi = FileUploadApi();
        final result = await fileUploadApi.uploadFile(tempFile);
        
        // 删除临时文件
        try {
          await tempFile.delete();
        } catch (e) {
          logWarning('删除临时文件失败: $e', tag: _tag);
        }
        
        if (result.isSuccess && result.data != null) {
          final logoUrl = result.data!;
          // 缓存URL
          await _logoCacheService.cacheLogoUrl(packageName, logoUrl);
          // logDebug('✅ logo上传成功: $packageName -> $logoUrl', tag: _tag);
          return logoUrl;
        } else {
          logError('logo上传失败: ${result.msg}', tag: _tag);
          return null;
        }
      } catch (e) {
        // 确保临时文件被删除
        try {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        } catch (_) {}
        rethrow;
      }
    } catch (e) {
      logError('上传logo失败: $packageName, $e', tag: _tag, error: e);
      return null;
    }
  }
}
