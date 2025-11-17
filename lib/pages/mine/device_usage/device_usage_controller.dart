import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kissu_app/network/public/usage_record_api.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'device_usage_page.dart';

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

  final _usageRecordApi = UsageRecordApi();

  @override
  void onInit() {
    super.onInit();
    // 初始化绑定状态和会员状态
    _updateBindStatus();
    _loadData(); // 加载真实数据
  }

  @override
  void onReady() {
    super.onReady();
    // 页面准备就绪时，刷新状态（处理从其他页面返回的情况）
    _refreshStatusAndData();
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
  
  /// 切换调试模式
  void toggleDebugMode() {
    isDebugEmptyMode.value = !isDebugEmptyMode.value;
    
    if (isDebugEmptyMode.value) {
      // 进入空数据模式
      _resetData();
    } else {
      // 恢复真实数据
      _loadData();
    }
  }
  
  /// 获取今天当前时间的分钟数（用于圆环图进度计算）
  int getTodayCurrentMinutes() {
    final now = DateTime.now();
    return now.hour * 60 + now.minute;
  }
  
  /// 获取圆环图进度（使用时长分钟数 / 今天当前时间的分钟数）
  double getCircularProgress() {
    final currentMinutes = getTodayCurrentMinutes();
    if (currentMinutes <= 0) return 0.0;
    final progress = screenUsageTotalMinutes.value / currentMinutes;
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

      // 获取用机记录统计数据
      final result = await _usageRecordApi.getMobileUsageRecordSta(date: dateStr);
      
      if (result.isSuccess && result.data != null) {
        final data = result.data!;
        
        // 处理手机使用数据 (mobile字段)
        final mobile = data.mobile;
        
        // 解析屏幕使用时长（从"2小时1分钟"格式中提取）
        final (hours, minutes) = mobile.totalUseDuration.parseHoursAndMinutes();
        screenUsageHours.value = hours;
        screenUsageMinutes.value = minutes;
        screenUsageTotalMinutes.value = mobile.totalUseDuration.minute;
        
        // 最近使用时长
        recentUsageMinutes.value = mobile.lastUseDuration.minute;
        
        // 解锁次数
        unlockCount.value = mobile.totalUnlock.count;

        // 处理App使用数据 (otherApp字段)
        final otherApp = data.otherApp;
        
        // 最长使用App
        if (otherApp.longestApp != null) {
          final longestApp = otherApp.longestApp!;
          longestAppName.value = longestApp.appName;
          longestAppLogo.value = longestApp.appLogo;
          final (longestHours, longestMinutes) = longestApp.parseHoursAndMinutes();
          longestAppHours.value = longestHours;
          longestAppMinutes.value = longestMinutes;
        } else {
          longestAppName.value = "";
          longestAppLogo.value = "";
          longestAppHours.value = 0;
          longestAppMinutes.value = 0;
        }
        
        // 打开次数最多的App
        if (otherApp.openMostApp != null) {
          final openMostApp = otherApp.openMostApp!;
          openMostAppName.value = openMostApp.appName;
          openMostAppLogo.value = openMostApp.appLogo;
          openMostAppCount.value = openMostApp.count ?? 0;
        } else {
          openMostAppName.value = "";
          openMostAppLogo.value = "";
          openMostAppCount.value = 0;
        }
        
        // 最近使用的App
        if (otherApp.lastUseApp != null) {
          final lastUseApp = otherApp.lastUseApp!;
          lastUseAppName.value = lastUseApp.appName;
          lastUseAppLogo.value = lastUseApp.appLogo;
          lastUseAppTime.value = lastUseApp.time;
        } else {
          lastUseAppName.value = "";
          lastUseAppLogo.value = "";
          lastUseAppTime.value = "";
        }

        // 敏感操作记录暂时不处理
        sensitiveRecords.value = [];

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
  }

  /// 刷新数据（供外部调用）
  Future<void> refreshData() async {
    await _loadData();
  }
  
  /// 设置日期并重新加载数据
  Future<void> setDate(DateTime date) async {
    selectedDate.value = date;
    await _loadData();
  }
}

