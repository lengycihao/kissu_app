import 'dart:async';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kissu_app/network/public/usage_record_api.dart';
import 'package:kissu_app/utils/debug_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kissu_app/services/analytics/analytics_manager.dart';
import 'package:kissu_app/services/analytics/analytics_events.dart';
import 'package:kissu_app/services/analytics/analytics_params.dart';

/// App使用记录详情控制器
class AppUsageDetailController extends GetxController {
  // API实例
  final _usageRecordApi = UsageRecordApi();
  
  // 防抖Timer
  Timer? _debounceTimer;

  // 日期选择相关
  var selectedDateIndex = 6.obs; // 选中的日期索引（6表示今天，0表示6天前）
  var selectedDate = DateTime.now().obs; // 当前选中的日期

  // 当天数据（按小时，0-23点）
  var todayScreenUsage = <int>[].obs; // 屏幕使用时间（分钟）
  var todayUnlockCount = <int>[].obs; // 解锁次数

  // 趋势数据
  var screenTrend = 0.obs; // 0持平 1下降 2上升
  var screenTrendText = ''.obs;
  var unlockTrend = 0.obs; // 0持平 1下降 2上升
  var unlockTrendText = ''.obs;

  // 加载状态
  var isLoading = false.obs;

  // 触摸交互相关
  var touchedScreenBarIndex = (-1).obs; // 屏幕使用时间被触摸的柱状图索引
  var touchedUnlockBarIndex = (-1).obs; // 解锁次数被触摸的柱状图索引

  // 引导图显示状态
  var showGuideOverlay = false.obs;
  
  // 埋点相关
  int? _pageEnterTime;
  int _exitType = ExitTypeValue.back;

  @override
  void onInit() {
    super.onInit();
    
    // 埋点：记录页面进入时间
    _pageEnterTime = DateTime.now().millisecondsSinceEpoch;
    
    // 加载今天的数据
    loadData();
    // 检查并显示引导图
    _checkAndShowGuide();
  }

  /// 切换日期
  void changeDate(DateTime date) {
    // 如果选择的是相同日期，直接返回
    final newDateStr = DateFormat('yyyy-MM-dd').format(date);
    final currentDateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);
    
    if (newDateStr == currentDateStr) {
      DebugUtil.info('📊 相同日期，跳过切换: $newDateStr');
      return;
    }
    
    selectedDate.value = date;
    touchedScreenBarIndex.value = -1; // 切换日期时清除触摸状态
    touchedUnlockBarIndex.value = -1;
    
    // 取消之前的防抖Timer
    _debounceTimer?.cancel();
    
    // 使用防抖加载数据，避免连续点击时多次请求
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      DebugUtil.info('📊 防抖Timer触发，开始加载数据: $newDateStr');
      loadData();
    });
  }

  /// 加载数据
  Future<void> loadData() async {
    try {
      isLoading.value = true;
      
      // 格式化日期
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);
      DebugUtil.info('📊 加载屏幕解锁统计数据: $dateStr');
      
      // 调用API
      final result = await _usageRecordApi.getScreenUnlockStat(date: dateStr);
      
      if (result.isSuccess && result.data != null) {
        final data = result.data!;
        
        // 处理屏幕使用数据
        if (data.screenUseData != null) {
          final screenData = data.screenUseData!;
          
          // 初始化24小时数据（索引0-23对应0-23点）
          final screenUsageList = List<int>.filled(24, 0);
          
          // 按hour字段填充每小时数据，确保索引与真实小时对齐
          for (var stat in screenData.hourlyUsageStat) {
            if (stat.hour >= 0 && stat.hour < 24) {
              screenUsageList[stat.hour] = stat.minutes;
            }
          }
          
          todayScreenUsage.value = screenUsageList;
          screenTrend.value = screenData.trend;
          screenTrendText.value = screenData.trendText;
          
          DebugUtil.success('✅ 屏幕使用数据加载成功: ${screenData.hours}小时${screenData.minutes}分');
        }
        
        // 处理解锁数据
        if (data.unlockPhoneData != null) {
          final unlockData = data.unlockPhoneData!;
          
          // 初始化24小时数据（索引0-23对应0-23点）
          final unlockCountList = List<int>.filled(24, 0);
          
          // 按hour字段填充每小时数据，确保索引与真实小时对齐
          for (var stat in unlockData.unlockPhoneStat) {
            if (stat.hour >= 0 && stat.hour < 24) {
              unlockCountList[stat.hour] = stat.unlockNumber;
            }
          }
          
          todayUnlockCount.value = unlockCountList;
          unlockTrend.value = unlockData.trend;
          unlockTrendText.value = unlockData.trendText;
          
          DebugUtil.success('✅ 解锁数据加载成功: ${unlockData.unlockNumber}次');
        }
      } else {
        DebugUtil.warning('❌ 数据加载失败: ${result.msg}');
        // 加载失败时使用空数据
        todayScreenUsage.value = List.filled(24, 0);
        todayUnlockCount.value = List.filled(24, 0);
        screenTrend.value = 0;
        screenTrendText.value = '';
        unlockTrend.value = 0;
        unlockTrendText.value = '';
      }
    } catch (e) {
      DebugUtil.error('💥 数据加载异常: $e');
      // 异常时使用空数据
      todayScreenUsage.value = List.filled(24, 0);
      todayUnlockCount.value = List.filled(24, 0);
      screenTrend.value = 0;
      screenTrendText.value = '';
      unlockTrend.value = 0;
      unlockTrendText.value = '';
    } finally {
      isLoading.value = false;
    }
  }

  /// 设置屏幕使用时间触摸的柱状图索引
  void setTouchedScreenBarIndex(int index) {
    touchedScreenBarIndex.value = index;
  }

  /// 设置解锁次数触摸的柱状图索引
  void setTouchedUnlockBarIndex(int index) {
    touchedUnlockBarIndex.value = index;
  }

  /// 清除屏幕使用时间触摸状态
  void clearTouchedScreenBar() {
    touchedScreenBarIndex.value = -1;
  }

  /// 清除解锁次数触摸状态
  void clearTouchedUnlockBar() {
    touchedUnlockBarIndex.value = -1;
  }

  /// 判断是否有数据
  bool get hasTodayData {
    return todayScreenUsage.any((element) => element > 0) ||
        todayUnlockCount.any((element) => element > 0);
  }

  /// 获取当天屏幕使用总时长（小时和分钟）
  String get todayTotalScreenTime {
    int totalMinutes = todayScreenUsage.fold(0, (sum, item) => sum + item);
    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    return "$hours小时${minutes.toString().padLeft(2, '0')}分";
  }

  /// 获取当天解锁总次数
  int get todayTotalUnlockCount {
    return todayUnlockCount.fold(0, (sum, item) => sum + item);
  }

  /// 加载模拟数据（用于测试）
  void _loadMockData() {
    // 当天数据（24小时）
    todayScreenUsage.value = [
      15, 0, 0, 0, 0, 0, // 0-5点
      25, 15, 10, 0, // 6-9点
      45, 10, // 10-11点
      60, 50, // 12-13点
      35, 0, 0, 0, // 14-17点
      10, 5, 0, 0, 0, 0, // 18-23点
    ];

    todayUnlockCount.value = [
      0, 0, 0, 0, 0, 0, // 0-5点
      25, 25, 25, 5, // 6-9点
      30, 10, // 10-11点
      40, 15, // 12-13点
      25, 0, 0, 0, // 14-17点
      15, 20, 15, 0, 0, 0, // 18-23点
    ];
    
    screenTrend.value = 2;
    screenTrendText.value = '比昨天多3小时43分';
    unlockTrend.value = 1;
    unlockTrendText.value = '比昨天少5次';
  }

  /// 切换到空数据模式（用于测试）
  void switchToEmptyMode() {
    todayScreenUsage.value = List.filled(24, 0);
    todayUnlockCount.value = List.filled(24, 0);
  }

  /// 恢复模拟数据
  void restoreMockData() {
    _loadMockData();
  }

  /// 检查并显示引导图
  Future<void> _checkAndShowGuide() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasShownGuide = prefs.getBool('has_shown_phone_history_guide') ?? false;
      
      DebugUtil.info('🔍 检查用机记录引导图显示状态: $hasShownGuide');
      
      if (!hasShownGuide) {
        DebugUtil.info('📱 首次进入用机记录页面，显示引导图');
        
        // 立即标记已显示，防止重复显示
        await prefs.setBool('has_shown_phone_history_guide', true);
        
        // 延迟显示引导图，确保页面完全加载
        Future.delayed(const Duration(milliseconds: 800), () {
          showGuideOverlay.value = true;
        });
      } else {
        DebugUtil.info('ℹ️ 引导图已显示过');
      }
    } catch (e) {
      DebugUtil.error('❌ 检查引导图状态失败: $e');
    }
  }

  /// 隐藏引导图
  void hideGuideOverlay() {
    showGuideOverlay.value = false;
    DebugUtil.info('📱 隐藏引导图');
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
  void onClose() {
    // 埋点：记录页面离开事件
    if (_pageEnterTime != null) {
      final exitTime = DateTime.now().millisecondsSinceEpoch;
      final durationMs = exitTime - _pageEnterTime!;
      final enterTimeStr = _formatEnterTime(DateTime.fromMillisecondsSinceEpoch(_pageEnterTime!));
      final durationStr = _formatDuration(durationMs);
      
      AnalyticsManager.instance.trackPageView(
        pageId: PhoneUseEvents.pageId,
        eventId: PhoneUseEvents.page,
        enterTime: enterTimeStr,
        duration: durationStr,
        sourcePage: Get.arguments != null && Get.arguments is Map && Get.arguments.containsKey('source_page')
            ? (Get.arguments['source_page'] as int).toString()
            : null,
        exitType: _exitType,
      );
    }
    
    // 取消防抖Timer
    _debounceTimer?.cancel();
    super.onClose();
  }
}

