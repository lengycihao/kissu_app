import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/public/file_upload_api.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kissu_app/pages/mine/app_usage/models/app_usage_record.dart';
import 'package:kissu_app/pages/mine/app_usage/models/app_usage_stat_data.dart';
import 'package:kissu_app/pages/mine/app_usage/models/app_open_record_detail_data.dart';
import 'package:kissu_app/pages/mine/app_usage/models/hourly_app_record_data.dart';
import 'package:kissu_app/pages/mine/app_usage/models/half_auth_app.dart';
import 'package:kissu_app/pages/mine/app_usage/api/app_usage_api.dart';
import 'package:kissu_app/pages/mine/app_usage/services/app_usage_report_service.dart';
import 'package:kissu_app/pages/mine/app_usage/services/app_logo_cache_service.dart';
import 'package:kissu_app/services/app_usage_auto_report_service.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/services/analytics/analytics_manager.dart';
import 'package:kissu_app/services/analytics/analytics_events.dart';
import 'package:kissu_app/services/analytics/analytics_params.dart';

/// App使用时长控制器
class AppUsageController extends GetxController with WidgetsBindingObserver {
  static const platform = MethodChannel('app_usage_channel');
  
  // 已安装应用列表
  var apps = <AppInfo>[].obs;
  
  // 筛选的应用包名列表（用于采集数据的应用）
  var selectedApps = <String>{}.obs;
  
  // 加载状态
  var isLoading = true.obs;
  
  // 上报状态
  var isReporting = false.obs;
  
  // 搜索关键词
  var searchKeyword = ''.obs;
  
  // 权限状态
  var hasUsagePermission = false.obs;
  
  // 选中的日期
  var selectedDate = DateTime.now().obs;
  
  // 日期选择器索引（0表示今天）
  var selectedDateIndex = 6.obs; // 默认选中最后一个（今天）
  
  // 是否显示日期选择器
  var showDatePicker = false.obs;
  
  // 使用记录数据
  var usageRecords = <AppUsageRecord>[].obs;
  
  // App使用统计数据（用于"最近使用App"模块）
  var appUsageStatData = <AppUsageStatData>[].obs;
  
  // 总打开次数（用于计算进度条）
  var totalOpenAppNumber = 0.obs;
  
  // 总使用时长（秒，用于计算进度条）
  var totalUseAppDuration = 0.obs;
  
  // 是否显示次数（true）还是分钟数（false）
  var showUsageCount = true.obs;
  
  // 是否显示时间轴视图（false: 统计视图, true: 时间轴视图）
  var showTimeline = false.obs;
  
  // 时间轴视图中选中的App
  var selectedAppForTimeline = ''.obs;
  
  // 是否显示全部最近使用的App
  var showAllRecentApps = false.obs;
  
  // 时间轴视图数据：最近使用的App列表（横向滚动）
  var latelyUseAppData = <LatelyUseAppData>[].obs;
  
  // 时间轴视图数据：App打开记录详情列表
  var appOpenRecordDetail = <AppOpenRecordDetail>[].obs;

  // 埋点相关
  int? _pageEnterTime;
  int _exitType = ExitTypeValue.back;

  // Ta当前授权过的App列表
  var halfAuthorizedApps = <HalfAuthApp>[].obs;
  
  // 时间轴数据加载状态
  var isLoadingTimelineData = false.obs;
  
  // 统计视图数据：每小时的使用记录
  var hourlyAppRecords = <HourlyAppRecordGroup>[].obs;
  
  // 统计视图数据加载状态
  var isLoadingStatisticsData = false.obs;
  
  // 上报服务
  final _reportService = AppUsageReportService();
  
  // Logo缓存服务
  final _logoCacheService = AppLogoCacheService();
  
  // 防抖Timer（用于日期选择和标签切换）
  Timer? _debounceTimer;
  
  // 最近使用的App列表（使用统计数据）
  // 按照接口返回的顺序显示，不排序
  List<AppUsageStatData> get recentlyUsedApps {
    return appUsageStatData.toList();
  }
  
  // 最大使用次数（用于进度条计算，使用总打开次数）
  int get maxSessionCount {
    return totalOpenAppNumber.value;
  }
  
  // 最大使用时长（秒，用于进度条计算，使用总使用时长）
  int get maxDuration {
    return totalUseAppDuration.value;
  }
  
  // 过滤后的应用列表
  List<AppInfo> get filteredApps {
    if (searchKeyword.value.isEmpty) {
      return apps;
    }
    return apps.where((app) {
      return app.appName.toLowerCase().contains(searchKeyword.value.toLowerCase()) ||
             app.packageName.toLowerCase().contains(searchKeyword.value.toLowerCase());
    }).toList();
  }
  
  @override
  void onInit() {
    super.onInit();
    
    // 埋点：记录页面进入时间（十位时间戳）
    _pageEnterTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // 监听应用生命周期，用于从系统设置返回后自动刷新权限与数据
    WidgetsBinding.instance.addObserver(this);
    _logoCacheService.initialize(); // 初始化logo缓存
    _loadData();
    _checkPermission();
    _loadUsageData();
    loadHalfAuthorizedApps();
    
    // 进入页面后立即加载时间轴数据和统计数据（提前准备数据）
    loadTimelineData();
    loadStatisticsData();
    
    // 监听视图切换，自动加载数据（备用方案）
    ever(showTimeline, (bool isTimeline) {
      if (isTimeline) {
        // 切换到时间轴视图时，如果数据为空则重新加载
        if (latelyUseAppData.isEmpty && appOpenRecordDetail.isEmpty) {
          logger.info('时间轴视图切换监听器触发，数据为空，重新加载数据', tag: 'AppUsage');
          loadTimelineData();
        }
      } else {
        // 切换到统计视图时，如果数据为空则重新加载
        if (hourlyAppRecords.isEmpty) {
          logger.info('统计视图切换监听器触发，数据为空，重新加载数据', tag: 'AppUsage');
          loadStatisticsData();
        }
      }
    });
    
    // 监听权限变化，通知自动上报服务
    ever(hasUsagePermission, (bool hasPermission) async {
      if (hasPermission) {
        // 权限已开启，通知自动上报服务检查并启动
        try {
          if (Get.isRegistered<AppUsageAutoReportService>()) {
            final service = Get.find<AppUsageAutoReportService>();
            await service.checkPermissionAndRestartIfNeeded();
          }
        } catch (e) {
          logger.warning('通知自动上报服务检查权限失败: $e', tag: 'AppUsage');
        }
      }
    });
  }
  
  @override
  void onClose() {
    // 埋点：记录页面离开事件
    if (_pageEnterTime != null) {
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final duration = currentTime - _pageEnterTime!;
      
      AnalyticsManager.instance.trackPageView(
        pageId: AppUseEvents.pageId,
        eventId: AppUseEvents.page,
        enterTime: _pageEnterTime!,
        duration: duration,
        exitType: _exitType,
      );
    }
    
    // 移除生命周期监听，避免内存泄漏
    WidgetsBinding.instance.removeObserver(this);
    // 取消防抖Timer
    _debounceTimer?.cancel();
    super.onClose();
  }

  /// 应用生命周期变化监听
  ///
  /// 当用户从系统的「使用情况访问」设置页返回到 App 时，
  /// 会触发 [AppLifecycleState.resumed]，此时重新检查权限并刷新数据，
  /// 这样顶部的“去开启”权限横幅就能自动消失。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // 稍微延迟，确保系统权限状态已更新
      Future.delayed(const Duration(milliseconds: 500), () async {
        await _checkPermission();
        await _loadUsageData();

        if (showTimeline.value) {
          await loadTimelineData(
            appPkg: selectedAppForTimeline.value.isEmpty
                ? null
                : selectedAppForTimeline.value,
          );
        } else {
          await loadStatisticsData();
        }
      });
    }
  }
  
  @override
  void onReady() {
    super.onReady();
    // 页面准备好后，检查权限并触发自动上报服务检查
    _checkPermissionAndNotifyAutoReport();
  }
  
  /// 检查权限并通知自动上报服务
  Future<void> _checkPermissionAndNotifyAutoReport() async {
    // 重新检查权限
    await _checkPermission();
    
    // 通知自动上报服务检查权限（如果权限从无到有，会重新启动服务）
    try {
      if (Get.isRegistered<AppUsageAutoReportService>()) {
        final service = Get.find<AppUsageAutoReportService>();
        await service.checkPermissionAndRestartIfNeeded();
      }
    } catch (e) {
      logger.warning('通知自动上报服务检查权限失败: $e', tag: 'AppUsage');
    }
  }
  
  /// 检查权限
  Future<void> _checkPermission() async {
    hasUsagePermission.value = await _hasUsagePermission();
  }
  
  /// 加载使用数据
  Future<void> _loadUsageData() async {
    try {
      await _logoCacheService.initialize();
      
      // 格式化日期为 yyyy-MM-dd
      final dateStr = '${selectedDate.value.year}-${selectedDate.value.month.toString().padLeft(2, '0')}-${selectedDate.value.day.toString().padLeft(2, '0')}';
      
      // 调用API获取统计数据
      final result = await AppUsageApi.getAppUsageStat(date: dateStr);
      
      if (result.isSuccess && result.data != null) {
        final statResponse = result.data!;
        
        // 更新统计数据并同步logo缓存
        appUsageStatData.value = _applyLogoCacheToStatData(statResponse.appUseStatData);
        totalOpenAppNumber.value = statResponse.totalOpenAppNumber;
        totalUseAppDuration.value = statResponse.totalUseAppDuration;
        
        logDebug('加载App使用统计数据成功: ${appUsageStatData.length}个App', tag: 'AppUsage');
      } else {
        logError('加载App使用统计数据失败: ${result.msg}', tag: 'AppUsage');
        // 失败时清空数据
        appUsageStatData.value = [];
        totalOpenAppNumber.value = 0;
        totalUseAppDuration.value = 0;
      }
      
      // usageRecords 用于统计视图，目前统计视图还没有对接接口
      // 暂时保持为空列表，避免统计视图显示错误
      usageRecords.value = [];
    } catch (e) {
      logError('加载使用数据失败: $e', tag: 'AppUsage');
      // 异常时清空数据
      appUsageStatData.value = [];
      totalOpenAppNumber.value = 0;
      totalUseAppDuration.value = 0;
      usageRecords.value = [];
    }
  }
  
  /// 生成模拟数据（用于UI展示）
  // ignore: unused_element
  List<AppUsageRecord> _generateMockData() {
    final now = DateTime.now();
    final targetDate = selectedDate.value;
    final dayDiff = now.difference(targetDate).inDays;
    
    // 倒数第二天（今天往前数第二天）：显示空数据
    if (dayDiff == 1) {
      return [];
    }
    
    // 倒数第三天：只显示3个App（少于5个）
    if (dayDiff == 2) {
      return _generateMockDataForApps(3, targetDate);
    }
    
    // 其他日期：显示7个App
    return _generateMockDataForApps(7, targetDate);
  }
  
  /// 为指定数量的App生成模拟数据
  List<AppUsageRecord> _generateMockDataForApps(int appCount, DateTime date) {
    final mockApps = [
      {'name': '微信', 'package': 'com.tencent.mm'},
      {'name': '王者荣耀', 'package': 'com.tencent.tmgp.sgame'},
      {'name': '抖音', 'package': 'com.ss.android.ugc.aweme'},
      {'name': 'Bilibili', 'package': 'tv.danmaku.bili'},
      {'name': '支付宝', 'package': 'com.eg.android.AlipayGphone'},
      {'name': '淘宝', 'package': 'com.taobao.taobao'},
      {'name': 'QQ', 'package': 'com.tencent.mobileqq'},
    ];
    
    final records = <AppUsageRecord>[];
    final selectedApps = mockApps.take(appCount).toList();
    final isToday = _isSameDay(date, DateTime.now());
    
    // 确定最大小时：今天显示到当前小时，历史日期显示完整24小时
    final maxHour = isToday ? DateTime.now().hour : 23;
    
    for (int i = 0; i < selectedApps.length; i++) {
      final app = selectedApps[i];
      final sessions = <AppUsageSession>[];
      final hourlyMap = <int, List<AppUsageSession>>{};
      
      // 根据日期和App生成不同的使用时间段
      final baseHour = 7 + (date.day % 3);  // 7-9点开始
      // 历史日期生成更多会话记录
      final sessionCount = isToday ? (5 + (i * 2)) : (8 + (i * 3) + (date.day % 5));
      
      for (int j = 0; j < sessionCount; j++) {
        // 更分散的时间分布
        int hour;
        if (isToday) {
          // 今天：从早上到现在
          hour = (baseHour + (j * 2)) % (maxHour + 1);
        } else {
          // 历史日期：分布在全天
          hour = (baseHour + (j * 2) + (date.day % 2)) % 24;
        }
        
        final minute = (j * 13 + date.day * 7 + i * 5) % 60;
        final openTime = DateTime(date.year, date.month, date.day, hour, minute);
        final duration = ((10 + (j * 5) + date.day * 2 + i * 3) % 50 + 5) * 60 * 1000; // 5-55分钟
        final closeTime = openTime.add(Duration(milliseconds: duration));
        
        final session = AppUsageSession(
          openTime: openTime.millisecondsSinceEpoch,
          closeTime: closeTime.millisecondsSinceEpoch,
        );
        sessions.add(session);
        
        if (!hourlyMap.containsKey(hour)) {
          hourlyMap[hour] = [];
        }
        hourlyMap[hour]!.add(session);
      }
      
      // 构建每小时记录
      final hourlyRecords = <HourlyUsageRecord>[];
      hourlyMap.forEach((hour, sessions) {
        final totalDuration = sessions.fold<int>(0, (sum, s) => sum + s.duration);
        hourlyRecords.add(HourlyUsageRecord(
          hour: hour,
          totalDuration: totalDuration,
          sessionCount: sessions.length,
          sessions: sessions,
        ));
      });
      
      hourlyRecords.sort((a, b) => a.hour.compareTo(b.hour));
      
      records.add(AppUsageRecord(
        appName: app['name']!,
        packageName: app['package']!,
        date: '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        hourlyRecords: hourlyRecords,
        totalSessions: sessionCount,
      ));
    }
    
    return records;
  }
  
  /// 判断是否是同一天
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }
  
  /// 切换日期选择器显示/隐藏
  void toggleDatePicker() {
    showDatePicker.value = !showDatePicker.value;
  }
  
  /// 选择日期
  void selectDate(DateTime date) {
    // 如果选择的是相同日期，直接返回
    final newDateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final currentDateStr = '${selectedDate.value.year}-${selectedDate.value.month.toString().padLeft(2, '0')}-${selectedDate.value.day.toString().padLeft(2, '0')}';
    
    if (newDateStr == currentDateStr) {
      logDebug('相同日期，跳过切换: $newDateStr', tag: 'AppUsage');
      return;
    }
    
    selectedDate.value = date;
    showDatePicker.value = false;
    
    // 取消之前的防抖Timer
    _debounceTimer?.cancel();
    
    // 使用防抖加载数据，避免连续点击时多次请求
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      logDebug('防抖Timer触发，开始加载数据: $newDateStr', tag: 'AppUsage');
      _loadUsageData();  // 重新加载数据
      
      // 如果当前显示的是时间轴视图，也需要重新加载时间轴数据
      if (showTimeline.value) {
        loadTimelineData(appPkg: selectedAppForTimeline.value.isEmpty ? null : selectedAppForTimeline.value);
      } else {
        // 如果当前显示的是统计视图，也需要重新加载统计数据
        loadStatisticsData();
      }
    });
  }
  
  /// 加载统计数据（公开方法，供外部调用）
  Future<void> loadStatisticsData() async {
    logDebug('开始加载统计数据: date=${selectedDate.value}', tag: 'AppUsage');
    await _loadStatisticsData();
  }
  
  /// 加载统计数据（内部方法）
  Future<void> _loadStatisticsData() async {
    try {
      isLoadingStatisticsData.value = true;
      await _logoCacheService.initialize();
      
      // 格式化日期为 yyyy-MM-dd
      final dateStr = '${selectedDate.value.year}-${selectedDate.value.month.toString().padLeft(2, '0')}-${selectedDate.value.day.toString().padLeft(2, '0')}';
      
      logDebug('调用API获取统计数据: date=$dateStr', tag: 'AppUsage');
      
      // 调用API获取统计数据
      final result = await AppUsageApi.getAppRecordStat(date: dateStr);
      
      if (result.isSuccess && result.data != null) {
        final statResponse = result.data!;
        
        // 更新数据并同步logo缓存
        hourlyAppRecords.value = _applyLogoCacheToHourlyRecords(statResponse.hourlyRecords);
        
        logDebug(
          '✅ 加载统计数据成功: ${hourlyAppRecords.length}个小时的记录',
          tag: 'AppUsage',
        );
      } else {
        logError('❌ 加载统计数据失败: ${result.msg}', tag: 'AppUsage');
        // 失败时清空数据
        hourlyAppRecords.value = [];
      }
    } catch (e) {
      logError('❌ 加载统计数据异常: $e', tag: 'AppUsage');
      // 异常时清空数据
      hourlyAppRecords.value = [];
    } finally {
      isLoadingStatisticsData.value = false;
    }
  }
  
  /// 切换显示/隐藏全部最近使用的App
  void toggleShowAllRecentApps() {
    showAllRecentApps.value = !showAllRecentApps.value;
  }
  
  /// 重置时间轴视图的选中状态（切换到时间轴视图时调用）
  void resetTimelineSelection() {
    selectedAppForTimeline.value = '';
  }
  
  /// 选择时间轴视图中的App
  void selectAppForTimeline(String packageName) {
    if (selectedAppForTimeline.value == packageName) {
      selectedAppForTimeline.value = '';
      // 取消选中时，加载默认数据（不传appPkg）
      loadTimelineData();
    } else {
      selectedAppForTimeline.value = packageName;
      // 选中App时，加载该App的详细记录
      loadTimelineData(appPkg: packageName);
    }
  }
  
  /// 加载时间轴数据（公开方法，供外部调用）
  Future<void> loadTimelineData({String? appPkg}) async {
    logDebug('开始加载时间轴数据: date=${selectedDate.value}, appPkg=$appPkg', tag: 'AppUsage');
    await _loadTimelineData(appPkg: appPkg);
  }
  
  /// 加载时间轴数据（内部方法）
  Future<void> _loadTimelineData({String? appPkg}) async {
    try {
      isLoadingTimelineData.value = true;
      await _logoCacheService.initialize();
      
      // 格式化日期为 yyyy-MM-dd
      final dateStr = '${selectedDate.value.year}-${selectedDate.value.month.toString().padLeft(2, '0')}-${selectedDate.value.day.toString().padLeft(2, '0')}';
      
      logDebug('调用API获取时间轴数据: date=$dateStr, appPkg=$appPkg', tag: 'AppUsage');
      
      // 调用API获取时间轴数据
      final result = await AppUsageApi.getAppOpenRecordDetail(
        date: dateStr,
        appPkg: appPkg,
      );
      
      if (result.isSuccess && result.data != null) {
        final detailResponse = result.data!;
        
        // 更新数据并同步logo缓存
        final processedLately = _applyLogoCacheToLatelyApps(detailResponse.latelyUseAppData);
        final processedDetails = _applyLogoCacheToRecordDetails(detailResponse.appOpenRecordDetail);
        latelyUseAppData.value = processedLately;
        appOpenRecordDetail.value = processedDetails;
        
        logDebug(
          '✅ 加载时间轴数据成功: ${latelyUseAppData.length}个App, ${appOpenRecordDetail.length}条记录',
          tag: 'AppUsage',
        );
        
        // 打印详细数据用于调试
        if (latelyUseAppData.isNotEmpty) {
          logDebug('最近使用的App列表: ${latelyUseAppData.map((e) => e.appName).join(", ")}', tag: 'AppUsage');
        }
        if (appOpenRecordDetail.isNotEmpty) {
          logDebug('记录详情数量: ${appOpenRecordDetail.length}', tag: 'AppUsage');
        }
        
        // 如果有数据且当前没有选中任何app，自动选中第一个app
        if (processedLately.isNotEmpty && selectedAppForTimeline.value.isEmpty) {
          final firstApp = processedLately.first;
          logDebug('自动选中第一个App: ${firstApp.appName} (${firstApp.appPkg})', tag: 'AppUsage');
          selectedAppForTimeline.value = firstApp.appPkg;
          // 加载第一个app的详细记录
          await _loadTimelineData(appPkg: firstApp.appPkg);
        }
      } else {
        logger.error('❌ 加载时间轴数据失败: ${result.msg}', tag: 'AppUsage');
        // 失败时清空数据
        latelyUseAppData.clear();
        appOpenRecordDetail.clear();
      }
    } catch (e) {
      logger.error('❌ 加载时间轴数据异常: $e', tag: 'AppUsage', error: e);
      // 异常时清空数据
      latelyUseAppData.value = [];
      appOpenRecordDetail.value = [];
    } finally {
      isLoadingTimelineData.value = false;
    }
  }

  List<AppUsageStatData> _applyLogoCacheToStatData(List<AppUsageStatData> list) {
    return list.map((item) {
      final packageName = _resolvePackageName(
        appPkg: item.appPkg,
        fallbackId: item.id,
        appName: item.appName,
      );
      final logo = _getLogoForPackage(packageName, item.appLogo);
      return item.copyWith(appPkg: packageName, appLogo: logo);
    }).toList();
  }
  
  List<LatelyUseAppData> _applyLogoCacheToLatelyApps(List<LatelyUseAppData> list) {
    return list.map((item) {
      final packageName = _resolvePackageName(
        appPkg: item.appPkg,
        fallbackId: item.id,
        appName: item.appName,
      );
      final logo = _getLogoForPackage(packageName, item.appLogo);
      return item.copyWith(appPkg: packageName, appLogo: logo);
    }).toList();
  }
  
  List<AppOpenRecordDetail> _applyLogoCacheToRecordDetails(List<AppOpenRecordDetail> list) {
    return list.map((item) {
      final packageName = _resolvePackageName(
        appPkg: item.appPkg,
        appName: item.appName,
      );
      final logo = _getLogoForPackage(packageName, item.appLogo);
      return item.copyWith(appPkg: packageName, appLogo: logo);
    }).toList();
  }
  
  List<HourlyAppRecordGroup> _applyLogoCacheToHourlyRecords(List<HourlyAppRecordGroup> groups) {
    return groups.map((group) {
      final updatedRecords = group.recordList.map((record) {
        final packageName = _resolvePackageName(
          appPkg: record.appPkg,
          appName: record.appName,
        );
        final logo = _getLogoForPackage(packageName, record.appLogo);
        return record.copyWith(appPkg: packageName, appLogo: logo);
      }).toList();
      return HourlyAppRecordGroup(
        hourKey: group.hourKey,
        recordList: updatedRecords,
      );
    }).toList();
  }
  
  String _getLogoForPackage(String packageName, String currentLogo) {
    if (packageName.isEmpty) {
      return currentLogo;
    }

    // 1）优先使用本地缓存里的 logo（可能比接口里的更新）
    final cached = _logoCacheService.getCachedLogoUrl(packageName);
    if (cached != null && cached.isNotEmpty) {
      // 如果接口里的 logo 也有值且和缓存不一致，顺便用最新的接口值更新一下缓存
      if (currentLogo.isNotEmpty && currentLogo != cached) {
        unawaited(_logoCacheService.cacheLogoUrl(packageName, currentLogo));
      }
      return cached;
    }

    // 2）缓存里没有，再使用接口里的，并写入缓存，后面其他地方可以直接命中
    if (currentLogo.isNotEmpty) {
      unawaited(_logoCacheService.cacheLogoUrl(packageName, currentLogo));
    }
    return currentLogo;
  }
  
  String _resolvePackageName({
    String? appPkg,
    String? fallbackId,
    String? appName,
  }) {
    if (appPkg != null && appPkg.isNotEmpty) {
      return appPkg;
    }
    if (fallbackId != null && fallbackId.isNotEmpty && fallbackId.contains('.')) {
      return fallbackId;
    }
    if (appName != null && appName.isNotEmpty) {
      try {
        final match = apps.firstWhere(
          (app) => app.appName.toLowerCase() == appName.toLowerCase(),
        );
        return match.packageName;
      } catch (_) {
        return '';
      }
    }
    return '';
  }
  
  /// 加载数据
  Future<void> _loadData() async {
    isLoading.value = true;
    try {
      await _loadSelectedApps();
      await _loadInstalledApps();
      
      // 初始化上报服务（不需要传入筛选应用，自动采集所有应用）
      await initializeReportService();
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 加载已筛选的应用包名
  Future<void> _loadSelectedApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('selected_apps_for_usage') ?? [];
      selectedApps.clear();
      selectedApps.addAll(list);
      logDebug('已加载筛选应用列表: ${selectedApps.length}个', tag: 'AppUsage');
    } catch (e) {
      logError('加载筛选应用列表失败: $e', tag: 'AppUsage', error: e);
    }
  }
  
  /// 加载已安装应用列表
  Future<void> _loadInstalledApps() async {
    try {
      logDebug('开始获取已安装应用列表（后台线程）', tag: 'AppUsage');
      
      // 🔧 添加超时保护（30秒超时）
      final List<dynamic> result = await platform
          .invokeMethod('getInstalledApps')
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              logger.error('获取应用列表超时', tag: 'AppUsage');
              throw TimeoutException('获取应用列表超时，请重试');
            },
          );
      
      apps.value = result.map((e) {
        final map = Map<String, dynamic>.from(e);
        return AppInfo(
          appName: map['appName'] as String,
          packageName: map['packageName'] as String,
          icon: map['icon'] as Uint8List,
        );
      }).toList();
      
      logDebug('✅ 已获取 ${apps.length} 个用户应用', tag: 'AppUsage');
    } on TimeoutException catch (e) {
      logError('获取应用列表超时: $e', tag: 'AppUsage', error: e);
      OKToastUtil.show('获取应用列表超时，请稍后重试');
    } on PlatformException catch (e) {
      logError('获取应用列表失败: ${e.message}', tag: 'AppUsage', error: e);
      OKToastUtil.showError('获取应用列表失败: ${e.message}');
    } catch (e) {
      logError('获取应用列表异常: $e', tag: 'AppUsage', error: e);
      OKToastUtil.showError('获取应用列表失败');
    }
  }
  
  /// 切换筛选状态
  Future<void> toggleSelection(String packageName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (selectedApps.contains(packageName)) {
        selectedApps.remove(packageName);
        logDebug('取消筛选应用: $packageName', tag: 'AppUsage');
      } else {
        selectedApps.add(packageName);
        logDebug('筛选应用: $packageName', tag: 'AppUsage');
      }
      
      await prefs.setStringList('selected_apps_for_usage', selectedApps.toList());
      
      // 注意：上报服务不依赖筛选列表，这里的筛选只是用于调试页面显示
    } catch (e) {
      logError('保存筛选状态失败: $e', tag: 'AppUsage', error: e);
      OKToastUtil.showError('保存失败');
    }
  }
  
  /// 显示应用使用时长
  Future<void> showUsageTime(String packageName, String appName) async {
    try {
      logDebug('获取应用使用时长: $packageName', tag: 'AppUsage');
      final int millis = await platform.invokeMethod('getAppUsageTime', {'packageName': packageName});
      final duration = Duration(milliseconds: millis);
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      
      Get.dialog(
        _buildUsageDialog(appName, hours, minutes),
        barrierDismissible: true,
      );
    } on PlatformException catch (e) {
      if (e.code == 'NO_PERMISSION') {
        _showPermissionDialog();
      } else {
        logError('获取使用时长失败: ${e.message}', tag: 'AppUsage', error: e);
        OKToastUtil.showError('获取使用时长失败: ${e.message}');
      }
    } catch (e) {
      logError('获取使用时长异常: $e', tag: 'AppUsage', error: e);
      OKToastUtil.showError('获取使用时长失败');
    }
  }
  
  /// 采集并上报使用数据
  Future<void> collectAndReportUsageData() async {
    if (selectedApps.isEmpty) {
      OKToastUtil.show('请先筛选需要采集的应用');
      return;
    }
    
    if (!await _hasUsagePermission()) {
      _showPermissionDialog();
      return;
    }
    
    isReporting.value = true;
    try {
      logDebug('开始采集 ${selectedApps.length} 个应用的使用数据', tag: 'AppUsage');
      
      // 批量获取详细使用数据
      final List<dynamic> result = await platform.invokeMethod(
        'getBatchDetailedUsageData',
        {'packageNames': selectedApps.toList()},
      );
      
      // 转换为AppUsageRecord列表
      final records = <AppUsageRecord>[];
      for (final data in result) {
        final map = _convertMap(data);
        
        // 只上报有使用记录的应用
        final hourlyRecords = (map['hourlyRecords'] as List<dynamic>)
            .map((e) => HourlyUsageRecord.fromJson(_convertMap(e)))
            .toList();
        
        if (hourlyRecords.isNotEmpty) {
          records.add(AppUsageRecord(
            appName: map['appName'] as String,
            packageName: map['packageName'] as String,
            iconBase64: map['iconBase64'] as String?,
            date: map['date'] as String,
            hourlyRecords: hourlyRecords,
          ));
        }
      }
      
      if (records.isEmpty) {
        logDebug('没有需要上报的使用记录', tag: 'AppUsage');
        OKToastUtil.show('暂无使用记录需要上报');
        return;
      }
      
      logDebug('准备上报 ${records.length} 个应用的使用记录', tag: 'AppUsage');
      
      // 处理每个应用的logo上传和数据转换
      final appUseRecordData = <Map<String, dynamic>>[];
      int? dateInt;
      
      for (final record in records) {
        // 获取应用的icon（从apps列表中查找）
        Uint8List? iconBytes;
        try {
          final appInfo = apps.firstWhere((app) => app.packageName == record.packageName);
          iconBytes = appInfo.icon;
        } catch (e) {
          // 如果找不到应用，iconBytes保持为null
          logWarning('未找到应用图标: ${record.packageName}', tag: 'AppUsage');
        }
        
        // 获取或上传logo
        String? logoUrl;
        if (iconBytes != null && iconBytes.isNotEmpty) {
          logoUrl = await _getOrUploadLogo(record.packageName, iconBytes);
        }
        
        // 转换数据格式
        final convertedData = _convertRecordToReportFormat(record, logoUrl);
        appUseRecordData.add(convertedData);
        
        // 获取日期（使用第一个记录的日期）
        if (dateInt == null) {
          final dateParts = record.date.split('-');
          dateInt = int.parse('${dateParts[0]}${dateParts[1].padLeft(2, '0')}${dateParts[2].padLeft(2, '0')}');
        }
      }
      
      if (appUseRecordData.isEmpty) {
        OKToastUtil.show('没有可上报的数据');
        return;
      }
      
      // 上报数据
      final apiResult = await AppUsageApi.reportAppUsage(appUseRecordData, dateInt!);
      
      if (apiResult.isSuccess) {
        OKToastUtil.showSuccess('已成功上报 ${records.length} 个应用的使用记录');
        logDebug('使用记录上报成功: ${records.length}个应用', tag: 'AppUsage');
      } else {
        OKToastUtil.showError(apiResult.msg ?? '上报失败');
        logError('使用记录上报失败: ${apiResult.msg}', tag: 'AppUsage');
      }
    } on PlatformException catch (e) {
      logError('采集使用数据失败: ${e.message}', tag: 'AppUsage', error: e);
      OKToastUtil.showError('采集使用数据失败: ${e.message}');
    } catch (e) {
      logError('采集并上报使用数据异常: $e', tag: 'AppUsage', error: e);
      OKToastUtil.showError('操作失败: $e');
    } finally {
      isReporting.value = false;
    }
  }
  
  /// 获取单个应用的详细使用数据（用于查看）
  Future<AppUsageRecord?> getDetailedUsageData(String packageName) async {
    try {
      if (!await _hasUsagePermission()) {
        _showPermissionDialog();
        return null;
      }
      
      final Map<dynamic, dynamic> result = await platform.invokeMethod(
        'getDetailedUsageData',
        {'packageName': packageName},
      );
      
      final map = _convertMap(result);
      final hourlyRecords = (map['hourlyRecords'] as List<dynamic>)
          .map((e) => HourlyUsageRecord.fromJson(_convertMap(e)))
          .toList();
      
      return AppUsageRecord(
        appName: map['appName'] as String,
        packageName: map['packageName'] as String,
        iconBase64: map['iconBase64'] as String?,
        date: map['date'] as String,
        hourlyRecords: hourlyRecords,
      );
    } on PlatformException catch (e) {
      logError('获取详细使用数据失败: ${e.message}', tag: 'AppUsage', error: e);
      OKToastUtil.showError('获取使用数据失败: ${e.message}');
      return null;
    } catch (e) {
      logError('获取详细使用数据异常: $e', tag: 'AppUsage', error: e);
      OKToastUtil.showError('获取使用数据失败');
      return null;
    }
  }
  
  /// 递归转换Map类型（处理嵌套的Map和List）
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
  
  /// 检查是否有使用权限
  Future<bool> _hasUsagePermission() async {
    try {
      // 尝试获取一个简单的使用数据来检测权限
      await platform.invokeMethod('getAppUsageTime', {'packageName': 'com.android.settings'});
      return true;
    } on PlatformException catch (e) {
      if (e.code == 'NO_PERMISSION') {
        return false;
      }
      return true; // 其他错误认为有权限
    } catch (e) {
      return true;
    }
  }
  
  /// 显示权限对话框
  void _showPermissionDialog() {
    Get.dialog(
      _buildPermissionDialog(),
      barrierDismissible: false,
    );
  }
  
  /// 打开使用情况访问设置
  Future<void> openUsageSettings() async {
    try {
      await platform.invokeMethod('openUsageSettings');
    } catch (e) {
      logError('打开使用情况设置失败: $e', tag: 'AppUsage', error: e);
    }
  }
  
  /// 构建使用时长对话框
  Widget _buildUsageDialog(String appName, int hours, int minutes) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: Text(
        '$appName 使用时长',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '过去24小时使用时长',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF999999),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$hours 小时 $minutes 分钟',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF839E),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text(
            '确定',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFFFF839E),
            ),
          ),
        ),
      ],
    );
  }
  
  /// 构建权限对话框
  Widget _buildPermissionDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: const Text(
        '需要授权',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: const Text(
        '查看应用使用时长需要开启"使用情况访问"权限\n\n请在设置页面找到 Kissu 并开启权限',
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text(
            '取消',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF999999),
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            Get.back();
            openUsageSettings();
          },
          child: const Text(
            '去授权',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFFFF839E),
            ),
          ),
        ),
      ],
    );
  }
  
  /// 刷新数据
  Future<void> onRefresh() async {
    // 重新检查权限
    await _checkPermission();
    
    // 重新加载使用统计数据
    await _loadUsageData();
    await loadHalfAuthorizedApps();
    
    // 根据当前视图加载对应数据
    if (showTimeline.value) {
      // 如果当前显示的是时间轴视图，重新加载时间轴数据
      await loadTimelineData(
        appPkg: selectedAppForTimeline.value.isEmpty 
            ? null 
            : selectedAppForTimeline.value,
      );
    } else {
      // 如果当前显示的是统计视图，重新加载统计数据
      await loadStatisticsData();
    }
  }

  /// 获取Ta当前授权过的App列表
  Future<void> loadHalfAuthorizedApps() async {
    try {
      final result = await AppUsageApi.getHalfAuthorizedApps();
      if (result.isSuccess && result.data != null) {
        halfAuthorizedApps.value = result.data!;
        logDebug('加载半授权App成功: ${halfAuthorizedApps.length}', tag: 'AppUsage');
      } else {
        halfAuthorizedApps.value = [];
        logError('加载半授权App失败: ${result.msg}', tag: 'AppUsage');
      }
    } catch (e) {
      halfAuthorizedApps.value = [];
      logError('加载半授权App异常: $e', tag: 'AppUsage', error: e);
    }
  }
  
  // ==================== 调试方法 ====================
  
  
  /// 初始化上报服务（自动采集所有应用）
  Future<void> initializeReportService() async {
    try {
      await _reportService.initialize();
      logDebug('上报服务已初始化（自动采集所有应用）', tag: 'AppUsage');
    } catch (e) {
      logError('初始化上报服务失败: $e', tag: 'AppUsage', error: e);
    }
  }
  
  // /// 停止上报服务
  // void stopReportService() {
  //   _reportService.stop();
  // }
  
  // /// 查看待上报数据
  // Future<void> debugViewPendingData() async {
  //   try {
  //     final result = await _reportService.debugViewPendingData();
      
  //     if (!result['success']) {
  //       OKToastUtil.show(result['message']);
  //       return;
  //     }
      
  //     final allData = result['allData'] as List<AppUsageRecord>;
  //     final incrementalData = result['incrementalData'] as List<AppUsageRecord>;
  //     final lastReported = result['lastReportedSessions'] as Map<String, int>;
      
  //     // 显示对话框
  //     Get.dialog(
  //       _buildDebugDataDialog(allData, incrementalData, lastReported),
  //       barrierDismissible: true,
  //     );
  //   } catch (e) {
  //     logger.error('查看待上报数据失败: $e', tag: 'AppUsage', error: e);
  //     OKToastUtil.showError('查看失败: $e');
  //   }
  // }
  
  /// 获取或上传app logo URL
  /// [packageName] 应用包名
  /// [iconBytes] 应用图标字节数据
  /// 返回logo的URL
  Future<String?> _getOrUploadLogo(String packageName, Uint8List iconBytes) async {
    try {
      // 先检查缓存
      final cachedUrl = _logoCacheService.getCachedLogoUrl(packageName);
      if (cachedUrl != null && cachedUrl.isNotEmpty) {
        logDebug('✅ 使用缓存的logo: $packageName -> $cachedUrl', tag: 'AppUsage');
        return cachedUrl;
      }
      
      // 缓存中没有，需要上传
      logDebug('📤 缓存中没有logo，开始上传: $packageName', tag: 'AppUsage');
      
      if (iconBytes.isEmpty) {
        logWarning('⚠️ logo数据为空，无法上传: $packageName', tag: 'AppUsage');
        return null;
      }
      
      // 创建临时文件
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('${tempDir.path}/app_logo_${packageName}_$timestamp.png');
      
      try {
        // 将Uint8List写入临时文件
        await tempFile.writeAsBytes(iconBytes);
        
        // 上传文件
        final fileUploadApi = FileUploadApi();
        final result = await fileUploadApi.uploadFile(tempFile);
        
        // 删除临时文件
        try {
          await tempFile.delete();
        } catch (e) {
          logWarning('删除临时文件失败: $e', tag: 'AppUsage');
        }
        
        if (result.isSuccess && result.data != null) {
          final logoUrl = result.data!;
          // 缓存URL
          await _logoCacheService.cacheLogoUrl(packageName, logoUrl);
          logDebug('✅ logo上传成功: $packageName -> $logoUrl', tag: 'AppUsage');
          return logoUrl;
        } else {
          logError('logo上传失败: ${result.msg}', tag: 'AppUsage');
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
      logError('获取或上传logo失败: $packageName, $e', tag: 'AppUsage', error: e);
      return null;
    }
  }
  
  /// 将AppUsageRecord转换为上报格式
  /// [record] 应用使用记录
  /// [logoUrl] logo的URL
  /// 返回转换后的数据格式
  Map<String, dynamic> _convertRecordToReportFormat(AppUsageRecord record, String? logoUrl) {
    // 获取所有会话并按时间排序
    final sessions = record.allSessions;
    
    // 构建record数组（包含operate_time和operate_type）
    final recordList = <Map<String, dynamic>>[];
    
    for (final session in sessions) {
      // 打开app（operate_type = 1）
      recordList.add({
        'operate_time': session.openTime ~/ 1000, // 转换为秒级时间戳
        'operate_type': 1,
      });
      
      // 关闭app（operate_type = 0），如果有关闭时间
      if (session.closeTime > 0 && !session.isRunning) {
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
  
  // /// 全量上报
  // Future<void> debugFullReport() async {
  //   try {
  //     isReporting.value = true;
      
  //     // 获取全量数据
  //     final result = await _reportService.debugFullReport();
      
  //     if (!result['success']) {
  //       OKToastUtil.show(result['message']);
  //       return;
  //     }
      
  //     final records = result['data'] as List<AppUsageRecord>;
      
  //     if (records.isEmpty) {
  //       OKToastUtil.show('暂无使用记录需要上报');
  //       return;
  //     }
      
  //     logger.info('开始全量上报: ${records.length}个应用', tag: 'AppUsage');
      
  //     // 处理每个应用的logo上传和数据转换
  //     final appUseRecordData = <Map<String, dynamic>>[];
  //     int? dateInt;
      
  //     for (final record in records) {
  //       // 获取应用的icon（从apps列表中查找）
  //       Uint8List? iconBytes;
  //       try {
  //         final appInfo = apps.firstWhere((app) => app.packageName == record.packageName);
  //         iconBytes = appInfo.icon;
  //       } catch (e) {
  //         // 如果找不到应用，iconBytes保持为null
  //         logger.warning('未找到应用图标: ${record.packageName}', tag: 'AppUsage');
  //       }
        
  //       // 获取或上传logo
  //       String? logoUrl;
  //       if (iconBytes != null && iconBytes.isNotEmpty) {
  //         logoUrl = await _getOrUploadLogo(record.packageName, iconBytes);
  //       }
        
  //       // 转换数据格式
  //       final convertedData = _convertRecordToReportFormat(record, logoUrl);
  //       appUseRecordData.add(convertedData);
        
  //       // 获取日期（使用第一个记录的日期）
  //       if (dateInt == null) {
  //         final dateParts = record.date.split('-');
  //         dateInt = int.parse('${dateParts[0]}${dateParts[1].padLeft(2, '0')}${dateParts[2].padLeft(2, '0')}');
  //       }
  //     }
      
  //     if (appUseRecordData.isEmpty) {
  //       _safeShowSnackbar('提示', '没有可上报的数据');
  //       return;
  //     }
      
  //     // 上报数据
  //     final reportResult = await AppUsageApi.reportAppUsage(appUseRecordData, dateInt!);
      
  //     if (reportResult.isSuccess) {
  //       _safeShowSnackbar(
  //         '成功',
  //         '全量上报成功: ${records.length}个应用',
  //         backgroundColor: Colors.green.withValues(alpha: 0.8),
  //         colorText: Colors.white,
  //       );
  //       logger.info('✅ 全量上报成功: ${records.length}个应用', tag: 'AppUsage');
  //     } else {
  //       _safeShowSnackbar('错误', reportResult.msg ?? '上报失败');
  //       logger.error('全量上报失败: ${reportResult.msg}', tag: 'AppUsage');
  //     }
  //   } catch (e) {
  //     logger.error('全量上报失败: $e', tag: 'AppUsage', error: e);
  //     _safeShowSnackbar('错误', '上报失败: $e');
  //   } finally {
  //     isReporting.value = false;
  //   }
  // }
  
  // /// 增量上报
  // Future<void> debugIncrementalReport() async {
  //   try {
  //     isReporting.value = true;
      
  //     // 获取增量数据
  //     final result = await _reportService.debugIncrementalReport();
      
  //     if (!result['success']) {
  //       _safeShowSnackbar('提示', result['message']);
  //       return;
  //     }
      
  //     final records = result['data'] as List<AppUsageRecord>;
      
  //     if (records.isEmpty) {
  //       _safeShowSnackbar('提示', '暂无新增使用记录需要上报');
  //       return;
  //     }
      
  //     logger.info('开始增量上报: ${records.length}个应用', tag: 'AppUsage');
      
  //     // 处理每个应用的logo上传和数据转换
  //     final appUseRecordData = <Map<String, dynamic>>[];
  //     int? dateInt;
      
  //     for (final record in records) {
  //       // 获取应用的icon（从apps列表中查找）
  //       Uint8List? iconBytes;
  //       try {
  //         final appInfo = apps.firstWhere((app) => app.packageName == record.packageName);
  //         iconBytes = appInfo.icon;
  //       } catch (e) {
  //         // 如果找不到应用，iconBytes保持为null
  //         logger.warning('未找到应用图标: ${record.packageName}', tag: 'AppUsage');
  //       }
        
  //       // 获取或上传logo
  //       String? logoUrl;
  //       if (iconBytes != null && iconBytes.isNotEmpty) {
  //         logoUrl = await _getOrUploadLogo(record.packageName, iconBytes);
  //       }
        
  //       // 转换数据格式
  //       final convertedData = _convertRecordToReportFormat(record, logoUrl);
  //       appUseRecordData.add(convertedData);
        
  //       // 获取日期（使用第一个记录的日期）
  //       if (dateInt == null) {
  //         final dateParts = record.date.split('-');
  //         dateInt = int.parse('${dateParts[0]}${dateParts[1].padLeft(2, '0')}${dateParts[2].padLeft(2, '0')}');
  //       }
  //     }
      
  //     if (appUseRecordData.isEmpty) {
  //       _safeShowSnackbar('提示', '没有可上报的数据');
  //       return;
  //     }
      
  //     // 上报数据
  //     final reportResult = await AppUsageApi.reportAppUsage(appUseRecordData, dateInt!);
      
  //     if (reportResult.isSuccess) {
  //       _safeShowSnackbar(
  //         '成功',
  //         '增量上报成功: ${records.length}个应用',
  //         backgroundColor: Colors.green.withValues(alpha: 0.8),
  //         colorText: Colors.white,
  //       );
  //       logger.info('✅ 增量上报成功: ${records.length}个应用', tag: 'AppUsage');
  //     } else {
  //       _safeShowSnackbar('错误', reportResult.msg ?? '上报失败');
  //       logger.error('增量上报失败: ${reportResult.msg}', tag: 'AppUsage');
  //     }
  //   } catch (e) {
  //     logger.error('增量上报失败: $e', tag: 'AppUsage', error: e);
  //     _safeShowSnackbar('错误', '上报失败: $e');
  //   } finally {
  //     isReporting.value = false;
  //   }
  // }

  // /// 上传图片（测试上传手机app logo）
  // /// 从已安装应用列表中获取第一个应用的logo，转换为文件格式后上传
  // Future<void> debugUploadImage() async {
  //   try {
  //     // 检查是否有已安装的应用
  //     if (apps.isEmpty) {
  //       OKToastUtil.show('暂无已安装应用，请先加载应用列表');
  //       logger.warning('应用列表为空，无法上传logo', tag: 'AppUsage');
  //       return;
  //     }
      
  //     // 选择第一个应用进行测试
  //     final testApp = apps.first;
  //     logger.info('开始上传应用logo: ${testApp.appName} (${testApp.packageName})', tag: 'AppUsage');
      
  //     // 检查icon数据是否有效
  //     if (testApp.icon.isEmpty) {
  //       OKToastUtil.showError('应用logo数据为空');
  //       logger.error('应用logo数据为空: ${testApp.appName}', tag: 'AppUsage');
  //       return;
  //     }
      
  //     // 创建临时文件
  //     final tempDir = Directory.systemTemp;
  //     final timestamp = DateTime.now().millisecondsSinceEpoch;
  //     // 根据icon数据判断文件格式（Android应用图标通常是PNG格式）
  //     final tempFile = File('${tempDir.path}/app_logo_${testApp.packageName}_$timestamp.png');
      
  //     try {
  //       // 将Uint8List写入临时文件
  //       await tempFile.writeAsBytes(testApp.icon);
  //       logger.info('临时文件创建成功: ${tempFile.path}, 大小: ${testApp.icon.length} bytes', tag: 'AppUsage');
        
  //       // 上传文件
  //       final fileUploadApi = FileUploadApi();
  //       final result = await fileUploadApi.uploadFile(tempFile);
        
  //       // 删除临时文件
  //       try {
  //         await tempFile.delete();
  //         logger.info('临时文件已删除: ${tempFile.path}', tag: 'AppUsage');
  //       } catch (e) {
  //         logger.warning('删除临时文件失败: $e', tag: 'AppUsage');
  //       }
        
  //       // 处理上传结果
  //       if (result.isSuccess && result.data != null) {
           
  //       } else {
           
  //         logger.error('应用logo上传失败: ${result.msg}', tag: 'AppUsage');
  //       }
  //     } catch (e) {
  //       // 确保临时文件被删除
  //       try {
  //         if (await tempFile.exists()) {
  //           await tempFile.delete();
  //         }
  //       } catch (_) {}
        
  //       rethrow;
  //     }
  //   } catch (e) {
  //     logger.error('上传图片失败: $e', tag: 'AppUsage', error: e);
  //     OKToastUtil.showError('上传失败: $e');
  //   }
  // }
  
  // /// 清空本地记录
  // Future<void> debugClearLocalData() async {
  //   try {
  //     await _reportService.debugClearLocalData();
  //     OKToastUtil.showSuccess('本地记录已清空');
  //   } catch (e) {
  //     logger.error('清空本地记录失败: $e', tag: 'AppUsage', error: e);
  //     OKToastUtil.showError('清空失败: $e');
  //   }
  // }
  
  // /// 构建调试数据对话框
  // Widget _buildDebugDataDialog(
  //   List<AppUsageRecord> allData,
  //   List<AppUsageRecord> incrementalData,
  //   Map<String, int> lastReported,
  // ) {
  //   return Dialog(
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //     child: Container(
  //       width: double.maxFinite,
  //       constraints: const BoxConstraints(maxHeight: 600),
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           // 标题
  //           Container(
  //             padding: const EdgeInsets.all(20),
  //             decoration: const BoxDecoration(
  //               color: Color(0xFFFF839E),
  //               borderRadius: BorderRadius.only(
  //                 topLeft: Radius.circular(16),
  //                 topRight: Radius.circular(16),
  //               ),
  //             ),
  //             child: Row(
  //               children: [
  //                 const Expanded(
  //                   child: Text(
  //                     '待上报数据',
  //                     style: TextStyle(
  //                       fontSize: 18,
  //                       fontWeight: FontWeight.w600,
  //                       color: Colors.white,
  //                     ),
  //                   ),
  //                 ),
  //                 IconButton(
  //                   icon: const Icon(Icons.close, color: Colors.white),
  //                   onPressed: () => Get.back(),
  //                 ),
  //               ],
  //             ),
  //           ),
            
  //           // 统计信息
  //           Container(
  //             padding: const EdgeInsets.all(16),
  //             color: const Color(0xFFFFF5F7),
  //             child: Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceAround,
  //               children: [
  //                 _buildDebugStatCard('全量数据', '${allData.length}个'),
  //                 Container(width: 1, height: 40, color: const Color(0xFFFFD4DF)),
  //                 _buildDebugStatCard('增量数据', '${incrementalData.length}个'),
  //                 Container(width: 1, height: 40, color: const Color(0xFFFFD4DF)),
  //                 _buildDebugStatCard('已上报', '${lastReported.length}个'),
  //               ],
  //             ),
  //           ),
            
  //           // 数据列表
  //           Expanded(
  //             child: DefaultTabController(
  //               length: 2,
  //               child: Column(
  //                 mainAxisSize: MainAxisSize.min,
  //                 children: [
  //                   const TabBar(
  //                     labelColor: Color(0xFFFF839E),
  //                     unselectedLabelColor: Color(0xFF999999),
  //                     indicatorColor: Color(0xFFFF839E),
  //                     tabs: [
  //                       Tab(text: '全量数据'),
  //                       Tab(text: '增量数据'),
  //                     ],
  //                   ),
  //                   Flexible(
  //                     child: TabBarView(
  //                       children: [
  //                         _buildDebugDataList(allData),
  //                         _buildDebugDataList(incrementalData),
  //                       ],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
            
  //           // 底部按钮
  //           Container(
  //             padding: const EdgeInsets.all(16),
  //             decoration: const BoxDecoration(
  //               border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
  //             ),
  //             child: Row(
  //               mainAxisAlignment: MainAxisAlignment.end,
  //               children: [
  //                 TextButton(
  //                   onPressed: () => Get.back(),
  //                   child: const Text(
  //                     '关闭',
  //                     style: TextStyle(fontSize: 16, color: Color(0xFFFF839E)),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  
  // Widget _buildDebugStatCard(String label, String value) {
  //   return Column(
  //     children: [
  //       Text(
  //         value,
  //         style: const TextStyle(
  //           fontSize: 20,
  //           fontWeight: FontWeight.bold,
  //           color: Color(0xFFFF839E),
  //         ),
  //       ),
  //       const SizedBox(height: 4),
  //       Text(
  //         label,
  //         style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
  //       ),
  //     ],
  //   );
  // }
  
  // Widget _buildDebugDataList(List<AppUsageRecord> records) {
  //   if (records.isEmpty) {
  //     return const Center(
  //       child: Text(
  //         '暂无数据',
  //         style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
  //       ),
  //     );
  //   }
    
  //   return ListView.separated(
  //     padding: const EdgeInsets.all(16),
  //     itemCount: records.length,
  //     separatorBuilder: (context, index) => const Divider(height: 16),
  //     itemBuilder: (context, index) {
  //       final record = records[index];
  //       return Container(
  //         padding: const EdgeInsets.all(12),
  //         decoration: BoxDecoration(
  //           color: const Color(0xFFF5F5F5),
  //           borderRadius: BorderRadius.circular(8),
  //         ),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               record.appName,
  //               style: const TextStyle(
  //                 fontSize: 14,
  //                 fontWeight: FontWeight.w600,
  //                 color: Color(0xFF333333),
  //               ),
  //             ),
  //             const SizedBox(height: 4),
  //             Text(
  //               record.packageName,
  //               style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
  //             ),
  //             const SizedBox(height: 8),
  //             Row(
  //               children: [
  //                 const Icon(Icons.access_time, size: 14, color: Color(0xFF999999)),
  //                 const SizedBox(width: 4),
  //                 Text(
  //                   '${(record.totalDuration / 60000).toStringAsFixed(1)}分钟',
  //                   style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
  //                 ),
  //                 const SizedBox(width: 12),
  //                 const Icon(Icons.touch_app, size: 14, color: Color(0xFF999999)),
  //                 const SizedBox(width: 4),
  //                 Text(
  //                   '${record.sessionCount}次',
  //                   style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

}

/// 应用信息模型
class AppInfo {
  final String appName;
  final String packageName;
  final Uint8List icon;
  
  AppInfo({
    required this.appName,
    required this.packageName,
    required this.icon,
  });
}
