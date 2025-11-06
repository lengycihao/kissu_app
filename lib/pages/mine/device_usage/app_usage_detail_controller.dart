import 'package:get/get.dart';

/// App使用记录详情控制器
class AppUsageDetailController extends GetxController {
  // tab选择：0-当天，1-本周
  var selectedTab = 1.obs;

  // 当天数据（按小时，0-23点）
  var todayScreenUsage = <int>[].obs; // 屏幕使用时间（分钟）
  var todayUnlockCount = <int>[].obs; // 解锁次数

  // 本周数据（周日-周六）
  var weekScreenUsage = <int>[].obs; // 屏幕使用时间（分钟）
  var weekUnlockCount = <int>[].obs; // 解锁次数

  // 触摸交互相关
  var touchedScreenBarIndex = (-1).obs; // 屏幕使用时间被触摸的柱状图索引
  var touchedUnlockBarIndex = (-1).obs; // 解锁次数被触摸的柱状图索引

  @override
  void onInit() {
    super.onInit();
    _loadMockData();
  }

  /// 切换tab
  void switchTab(int index) {
    selectedTab.value = index;
    touchedScreenBarIndex.value = -1; // 切换tab时清除触摸状态
    touchedUnlockBarIndex.value = -1;
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

  bool get hasWeekData {
    return weekScreenUsage.any((element) => element > 0) ||
        weekUnlockCount.any((element) => element > 0);
  }

  /// 获取当天屏幕使用总时长（小时和分钟）
  String get todayTotalScreenTime {
    int totalMinutes = todayScreenUsage.fold(0, (sum, item) => sum + item);
    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    return "$hours小时${minutes.toString().padLeft(2, '0')}分";
  }

  /// 获取本周屏幕使用总时长（小时和分钟）
  String get weekTotalScreenTime {
    int totalMinutes = weekScreenUsage.fold(0, (sum, item) => sum + item);
    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    return "$hours小时${minutes.toString().padLeft(2, '0')}分";
  }

  /// 获取当天解锁总次数
  int get todayTotalUnlockCount {
    return todayUnlockCount.fold(0, (sum, item) => sum + item);
  }

  /// 获取本周解锁总次数
  int get weekTotalUnlockCount {
    return weekUnlockCount.fold(0, (sum, item) => sum + item);
  }

  /// 加载模拟数据
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

    // 本周数据（周日-周六）
    weekScreenUsage.value = [
      60, // 周日
      350, // 周一
      50, // 周二
      220, // 周三
      60, // 周四
      280, // 周五
      80, // 周六
    ];

    weekUnlockCount.value = [
      30, // 周日
      95, // 周一
      30, // 周二
      60, // 周三
      30, // 周四
      55, // 周五
      20, // 周六
    ];
  }

  /// 切换到空数据模式（用于测试）
  void switchToEmptyMode() {
    todayScreenUsage.value = List.filled(24, 0);
    todayUnlockCount.value = List.filled(24, 0);
    weekScreenUsage.value = List.filled(7, 0);
    weekUnlockCount.value = List.filled(7, 0);
  }

  /// 恢复模拟数据
  void restoreMockData() {
    _loadMockData();
  }
}

