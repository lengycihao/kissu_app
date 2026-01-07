import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kissu_app/network/public/usage_record_api.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/services/permission_service.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/pages/mine/device_usage/models/phone_record_stat_model.dart' as api_model;
import 'package:kissu_app/pages/mine/app_usage/services/app_logo_cache_service.dart';
import 'device_usage_page.dart';
import 'package:kissu_app/services/analytics/analytics_manager.dart';
import 'package:kissu_app/services/analytics/analytics_events.dart';
import 'package:kissu_app/services/analytics/analytics_params.dart';

/// 用机记录控制器
class DeviceUsageController extends GetxController {
  // 手机使用数据
  var screenUsageHours = 0.obs; // 屏幕使用时长（小时）
  var screenUsageMinutes = 0.obs; // 屏幕使用时长（分钟）
  var screenUsageTotalMinutes = 0.obs; // 屏幕使用总时长（分钟，用于圆环图）
  var unlockCount = 0.obs; // 解锁次数
  var recentUsageMinutes = 0.obs; // 最近使用时长（分钟）

  // App使用数据
  var longestAppName = "".obs; // 最长使用App名称
  var longestAppLogo = "".obs; // 最长使用App图标
  var longestAppHours = 0.obs; // 最长使用App时长（小时）
  var longestAppMinutes = 0.obs; // 最长使用App时长（分钟）
  var openMostAppName = "".obs; // 打开次数最多App名称
  var openMostAppLogo = "".obs; // 打开次数最多App图标
  var openMostAppCount = 0.obs; // 打开次数
  var lastUseAppName = "".obs; // 最近使用App名称
  var lastUseAppLogo = "".obs; // 最近使用App图标
  var lastUseAppTime = "".obs; // 最近使用时间

  // 敏感操作记录
  var sensitiveRecords = <SensitiveRecord>[].obs;

  // 数据加载状态
  var isLoading = false.obs;
  
  // 调试模式：显示空数据状态
  var isDebugEmptyMode = false.obs;

  // 当前选择的日期
  var selectedDate = DateTime.now().obs;

  // 用户绑定状态
  var isUserBound = false.obs;
  
  // 用户会员状态
  var isUserVip = false.obs;

  // 权限状态
  var hasUsagePermission = false.obs;

  // 另一半用户设备信息
  var halfUserData = Rxn<api_model.HalfUserData>();

  // 用机记录引导图是否显示
  final RxBool showGuideOverlay = false.obs;

  final _usageRecordApi = UsageRecordApi();
  final _logoCacheService = AppLogoCacheService();
  
  // 埋点相关
  int? _pageEnterTime;
  int _exitType = ExitTypeValue.back;

  @override
  void onInit() {
    super.onInit();
    
    // 埋点：记录页面进入时间
    _pageEnterTime = DateTime.now().millisecondsSinceEpoch;
    
    // 初始化 App Logo 缓存
    _logoCacheService.initialize();
    // 初始化绑定状态和会员状态
    _updateBindStatus();
    _loadData(); // 加载真实数据
    // 检查并显示用机记录引导图（首次进入立即检查）
    _checkAndShowGuide();
    // 启动使用情况访问权限监听（轮询检测，直到授权或页面关闭）
    _startUsagePermissionMonitor();
  }
  
  /// 检查并显示用机记录引导图
  Future<void> _checkAndShowGuide() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasShownGuide =
          prefs.getBool('has_shown_device_usage_guide') ?? false;

      debugPrint('🔍 检查用机记录引导图显示状态: $hasShownGuide');

      if (!hasShownGuide) {
        debugPrint('📱 首次进入用机记录页面，显示引导图');

        // 立即标记已显示，防止重复显示
        await prefs.setBool('has_shown_device_usage_guide', true);

        // 直接显示覆盖层（不再延迟）
        if (!isClosed) {
          showGuideOverlay.value = true;
        }
      }
    } catch (e) {
      debugPrint('❌ 检查用机记录引导图状态失败: $e');
    }
  }

  /// 隐藏用机记录引导图
  void hideGuideOverlay() {
    showGuideOverlay.value = false;
  }
  
  /// 格式化页面进入时间为 "年-月-日 时:分:秒" 格式
  String _formatEnterTime(DateTime dateTime) {
    final year = dateTime.year;
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute:$second';
  }
  
  /// 格式化停留时长为 "分:秒" 格式
  String _formatDuration(int durationMs) {
    final totalSeconds = (durationMs / 1000).floor();
    final minutes = (totalSeconds / 60).floor();
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void onReady() {
    super.onReady();
    // 页面准备就绪时，刷新状态（处理从其他页面返回的情况）
    _refreshStatusAndData();
  }

  Timer? _usagePermissionTimer;

  /// 启动对“使用情况访问”权限的轮询检测（仅 Android 有效）
  void _startUsagePermissionMonitor() {
    // 先做一次快速检查
    _checkUsagePermissionOnce();

    // 如果已授权则不再启动定时器
    if (hasUsagePermission.value) return;

    // 每 2 秒检查一次，直到授权或控制器销毁
    _usagePermissionTimer?.cancel();
    _usagePermissionTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      await _checkUsagePermissionOnce();
      if (hasUsagePermission.value) {
        _usagePermissionTimer?.cancel();
        _usagePermissionTimer = null;
      }
    });
  }

  /// 检查使用情况访问权限一次并更新状态
  Future<void> _checkUsagePermissionOnce() async {
    try {
      final permissionService = PermissionService();
      final granted = await permissionService.isUsageAccessGranted();
      hasUsagePermission.value = granted;
    } catch (e) {
      logError('检查使用情况访问权限失败: $e', tag: 'DeviceUsage', error: e);
    }
  }

  @override
  void onClose() {
    // 埋点：记录页面离开事件
    if (_pageEnterTime != null) {
      final exitTime = DateTime.now().millisecondsSinceEpoch;
      final durationMs = exitTime - _pageEnterTime!;
      final enterTimeStr = _formatEnterTime(DateTime.fromMillisecondsSinceEpoch(_pageEnterTime!));
      final durationStr = _formatDuration(durationMs);
      
      AnalyticsManager.instance.trackPageView(
        pageId: PhoneHistoryEvents.pageId,
        eventId: PhoneHistoryEvents.page,
        enterTime: enterTimeStr,
        duration: durationStr,
        sourcePage: Get.arguments != null && Get.arguments is Map && Get.arguments.containsKey('source_page')
            ? (Get.arguments['source_page'] as int).toString()
            : null,
        exitType: _exitType,
      );
    }
    
    _usagePermissionTimer?.cancel();
    _usagePermissionTimer = null;
    super.onClose();
  }

  /// 更新绑定状态和会员状态
  void _updateBindStatus() {
    final userInfo = UserManager.getUserBasicInfo();
    isUserBound.value = userInfo['isBound'] ?? false;
    isUserVip.value = UserManager.isVip;
  }

  /// 公开方法：更新绑定状态（供外部调用）
  void updateBindStatus() {
    _updateBindStatus();
    // 如果状态发生变化，重新加载数据
    _refreshStatusAndData();
  }

  /// 刷新状态并重新加载数据
  Future<void> _refreshStatusAndData() async {
    // 先刷新用户信息
    try {
      await UserManager.refreshUserInfo();
    } catch (e) {
      logDebug('刷新用户信息失败: $e', tag: 'DeviceUsage');
    }
    
    // 更新绑定和会员状态
    final oldBound = isUserBound.value;
    final oldVip = isUserVip.value;
    _updateBindStatus();
    
    // 如果绑定状态或会员状态发生变化，重新加载数据
    if (oldBound != isUserBound.value || oldVip != isUserVip.value) {
      logDebug('绑定或会员状态发生变化，重新加载数据', tag: 'DeviceUsage');
      await _loadData();
    }
  }
  
  // /// 切换调试模式
  // void toggleDebugMode() {
  //   isDebugEmptyMode.value = !isDebugEmptyMode.value;
    
  //   if (isDebugEmptyMode.value) {
  //     // 进入空数据模式
  //     _resetData();
  //   } else {
  //     // 恢复真实数据
  //     _loadData();
  //   }
  // }
  
  /// 获取今天当前时间的分钟数（用于圆环图进度计算）
  int getTodayCurrentMinutes() {
    final now = DateTime.now();
    return now.hour * 60 + now.minute;
  }
  
  /// 获取圆环图进度（使用时长分钟数 / 24小时 = 1440分钟）
  double getCircularProgress() {
    const int totalMinutesInDay = 24 * 60; // 24小时 = 1440分钟
    if (totalMinutesInDay <= 0) return 0.0;
    final progress = screenUsageTotalMinutes.value / totalMinutesInDay;
    return progress > 1.0 ? 1.0 : progress;
  }

  /// 加载数据
  Future<void> _loadData() async {
    try {
      isLoading.value = true;

      // 检查是否已绑定
      final userInfo = UserManager.getUserBasicInfo();
      if (!userInfo['isBound']) {
        logDebug('用户未绑定，不加载数据', tag: 'DeviceUsage');
        return;
      }

      // 格式化日期参数
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);

      // 调用新API：获取用机记录统计数据
      final result = await _usageRecordApi.getPhoneRecordStat(date: dateStr);
      
      if (result.isSuccess && result.data != null) {
        final data = result.data!;
        
        // 处理手机使用记录数据
        if (data.mobileUseRecord != null) {
          final mobileRecord = data.mobileUseRecord!;
          
          // 屏幕使用时长
          screenUsageHours.value = mobileRecord.screenUseDuration.hours;
          screenUsageMinutes.value = mobileRecord.screenUseDuration.minutes;
          screenUsageTotalMinutes.value = 
              mobileRecord.screenUseDuration.hours * 60 + 
              mobileRecord.screenUseDuration.minutes;
          
          // 最近使用时长（秒转分钟）
          recentUsageMinutes.value = mobileRecord.latelyUseDuration;
          
          // 解锁次数
          unlockCount.value = mobileRecord.unlockPhoneNumbers;
        }

        // 处理App使用记录数据
        if (data.appUseRecord != null) {
          final appRecord = data.appUseRecord!;
          
          // 最长使用App
          if (appRecord.longestAppUseDurationData != null) {
            final longestApp = appRecord.longestAppUseDurationData!;
            final longestPkg = longestApp.appPkg;
            longestAppLogo.value = _getLogoForPackage(longestPkg, longestApp.appLogo);
            longestAppHours.value = longestApp.hours;
            longestAppMinutes.value = longestApp.minutes;
            // 注意：新API不提供app_name，只有logo
            longestAppName.value = "";
          } else {
            longestAppName.value = "";
            longestAppLogo.value = "";
            longestAppHours.value = 0;
            longestAppMinutes.value = 0;
          }
          
          // 打开次数最多的App
          if (appRecord.maxAppOpenNumberData != null) {
            final openMostApp = appRecord.maxAppOpenNumberData!;
            final openMostPkg = openMostApp.appPkg;
            openMostAppLogo.value = _getLogoForPackage(openMostPkg, openMostApp.appLogo);
            openMostAppCount.value = openMostApp.openAppNumber;
            // 注意：新API不提供app_name，只有logo
            openMostAppName.value = "";
          } else {
            openMostAppName.value = "";
            openMostAppLogo.value = "";
            openMostAppCount.value = 0;
          }
          
          // 最近打开的App
          if (appRecord.latelyOpenAppTimeData != null) {
            final lastUseApp = appRecord.latelyOpenAppTimeData!;
            final lastUsePkg = lastUseApp.appPkg;
            lastUseAppLogo.value = _getLogoForPackage(lastUsePkg, lastUseApp.appLogo);
            lastUseAppTime.value = lastUseApp.latelyOpenTime;
            // 注意：新API不提供app_name，只有logo
            lastUseAppName.value = "";
          } else {
            lastUseAppName.value = "";
            lastUseAppLogo.value = "";
            lastUseAppTime.value = "";
          }
        }

        // 处理敏感记录数据
        if (data.sensitiveRecord.isNotEmpty) {
          // 将新API的SensitiveRecord转换为页面使用的SensitiveRecord类型
          sensitiveRecords.value = data.sensitiveRecord.map((record) {
            return SensitiveRecord(
              iconPath: record.icon,
              content: record.content,
              time: record.createTime,
              subtitle: record.ext.subContent,
            );
          }).toList();
        } else {
          sensitiveRecords.value = [];
        }

        // 保存另一半用户设备信息
        halfUserData.value = data.halfUserData;

        logInfo('用机记录数据加载成功', tag: 'DeviceUsage');
      } else {
        logWarning('用机记录数据加载失败: ${result.msg}', tag: 'DeviceUsage');
        // 加载失败时使用空数据
        _resetData();
      }
    } catch (e, stackTrace) {
      logError('加载用机记录数据异常: $e', tag: 'DeviceUsage', error: e, stackTrace: stackTrace);
      _resetData();
    } finally {
      isLoading.value = false;
    }
  }

  /// 重置数据为空值
  void _resetData() {
    screenUsageHours.value = 0;
    screenUsageMinutes.value = 0;
    screenUsageTotalMinutes.value = 0;
    unlockCount.value = 0;
    recentUsageMinutes.value = 0;
    
    longestAppName.value = "";
    longestAppLogo.value = "";
    longestAppHours.value = 0;
    longestAppMinutes.value = 0;
    openMostAppName.value = "";
    openMostAppLogo.value = "";
    openMostAppCount.value = 0;
    lastUseAppName.value = "";
    lastUseAppLogo.value = "";
    lastUseAppTime.value = "";
    
    sensitiveRecords.value = [];
    halfUserData.value = null;
  }

  /// 刷新数据（供外部调用）
  Future<void> refreshData() async {
    await _loadData();
  }

  /// 根据包名优先从缓存获取 Logo，缓存没有再使用接口返回的 Logo
  String _getLogoForPackage(String? packageName, String currentLogo) {
    final pkg = packageName ?? '';
    if (pkg.isEmpty) {
      return currentLogo;
    }

    // 1）优先使用本地缓存里的 logo
    final cached = _logoCacheService.getCachedLogoUrl(pkg);
    if (cached != null && cached.isNotEmpty) {
      // 如果接口里的 logo 也有值且和缓存不一致，顺手用最新接口值更新缓存
      if (currentLogo.isNotEmpty && currentLogo != cached) {
        unawaited(_logoCacheService.cacheLogoUrl(pkg, currentLogo));
      }
      return cached;
    }

    // 2）缓存里没有，再用接口里的，并写入缓存
    if (currentLogo.isNotEmpty) {
      unawaited(_logoCacheService.cacheLogoUrl(pkg, currentLogo));
    }
    return currentLogo;
  }
  
  /// 设置日期并重新加载数据
  Future<void> setDate(DateTime date) async {
    selectedDate.value = date;
    await _loadData();
  }

  /// 打开使用情况访问设置
  Future<void> openUsageSettings() async {
    try {
      final permissionService = PermissionService();
      await permissionService.openUsageAccessSettings();
    } catch (e) {
      logError('打开使用情况设置失败: $e', tag: 'DeviceUsage', error: e);
    }
  }
}

