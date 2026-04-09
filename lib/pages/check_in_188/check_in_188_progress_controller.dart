import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/oktoast_util.dart';

/// 188打卡进行中页面控制器
class CheckIn188ProgressController extends GetxController with GetTickerProviderStateMixin {
  /// 滚动控制器
  late ScrollController scrollController;
  
  /// 导航栏透明度 (0.0 - 1.0)
  final RxDouble navBarOpacity = 0.0.obs;
  
  /// 浮动动画控制器
  late AnimationController floatAnimationController;
  late Animation<double> floatAnimation;
  
  // ==================== 任务状态 ====================
  
  /// 我的任务完成状态 (0: 未完成, 1: 完成第一个, 2: 完成两个)
  final RxInt myTaskProgress = 0.obs;
  
  /// 对方的任务完成状态 (0: 未完成, 1: 完成第一个, 2: 完成两个)
  final RxInt partnerTaskProgress = 0.obs;
  
  /// 今日任务描述
  final RxString todayTaskDescription = '在"心动相册"上传一张你手机里最酷酷的Ta的照片'.obs;
  
  /// 今日日期
  final RxString todayDate = '2025-10-9'.obs;
  
  /// 明日任务描述
  final RxString tomorrowTaskDescription = ''.obs;
  
  // ==================== 打卡日历数据 ====================
  
  /// 当前显示的年月
  final RxInt currentYear = DateTime.now().year.obs;
  final RxInt currentMonth = DateTime.now().month.obs;
  
  /// 活动开始日期（参加活动的日期）
  late DateTime activityStartDate;
  
  /// 活动结束日期（开始日期 + 188天）
  late DateTime activityEndDate;
  
  /// 补签卡数量
  final RxInt recoveryCardCount = 3.obs;
  
  /// 打卡记录 Map<日期字符串, 打卡状态>
  /// 状态: {'me': 0/1/2, 'partner': 0/1/2}
  final RxMap<String, Map<String, int>> checkInRecords = <String, Map<String, int>>{}.obs;
  
  /// 未打卡日期列表
  final RxList<String> missedDatesList = <String>[].obs;
  
  /// 总天数
  final RxInt totalDays = 188.obs;
  
  /// 已打卡天数（用于进度条）
  final RxInt checkedDays = 72.obs;
  
  // ==================== 打卡数据统计 ====================
  
  /// 未打卡天数
  final RxInt missedDays = 3.obs;
  
  /// 活动进度百分比
  final RxDouble activityProgress = 36.71.obs;
  
  /// 已打卡天数
  final RxInt checkedInDays = 76.obs;
  
  /// 剩余打卡天数
  final RxInt remainingDays = 101.obs;
  
  @override
  void onInit() {
    super.onInit();
    scrollController = ScrollController();
    scrollController.addListener(_onScroll);
    
    // 初始化浮动动画
    floatAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    floatAnimation = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(
        parent: floatAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // 初始化模拟数据
    _initMockData();
  }
  
  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    floatAnimationController.dispose();
    super.onClose();
  }
  
  /// 滚动监听 - 控制导航栏透明度
  void _onScroll() {
    final offset = scrollController.offset;
    final opacity = (offset / 100).clamp(0.0, 1.0);
    navBarOpacity.value = opacity;
  }
  
  /// 初始化模拟数据
  void _initMockData() {
    final now = DateTime.now();
    
    // 模拟活动开始日期（假设从今天往前推10天开始）
    activityStartDate = now.subtract(const Duration(days: 10));
    // 活动结束日期 = 开始日期 + 188天
    activityEndDate = activityStartDate.add(const Duration(days: 188));
    
    // 模拟打卡记录（使用当前月份）
    final year = now.year;
    final month = now.month;
    checkInRecords.value = {
      '$year-$month-${now.day - 9}': {'me': 2, 'partner': 2},
      '$year-$month-${now.day - 8}': {'me': 2, 'partner': 2},
      '$year-$month-${now.day - 7}': {'me': 2, 'partner': 2},
      '$year-$month-${now.day - 6}': {'me': 2, 'partner': 2},
      '$year-$month-${now.day - 5}': {'me': 2, 'partner': 2},
      '$year-$month-${now.day - 4}': {'me': 0, 'partner': 0}, // 缺卡
      '$year-$month-${now.day - 3}': {'me': 2, 'partner': 2},
      '$year-$month-${now.day - 2}': {'me': 1, 'partner': 2}, // 我完成1个，对方完成2个
      '$year-$month-${now.day - 1}': {'me': 0, 'partner': 0}, // 昨天缺卡
      '$year-$month-${now.day}': {'me': 0, 'partner': 0}, // 今天，都未完成
    };
    
    // 模拟明日任务（只有任一方完成今日任务才显示）
    _updateTomorrowTask();
    
    // 初始化未打卡日期列表
    missedDatesList.value = [
      '2025-08-09',
      '2025-08-18',
      '2025-09-09',
      '2025-09-19',
      '2025-09-26',
      '2025-10-09',
      '2025-09-19',
    ];
  }
  
  /// 更新明日任务显示
  void _updateTomorrowTask() {
    if (myTaskProgress.value > 0 || partnerTaskProgress.value > 0) {
      tomorrowTaskDescription.value = '明天早上6点至7点之间，去定位页面面，我的心情卡设置一个心情告诉他...';
    } else {
      tomorrowTaskDescription.value = '';
    }
  }
  
  /// 点击发送"我爱你"
  void onSendLoveMessage() {
    if (myTaskProgress.value >= 1) {
      OKToastUtil.showInfo('今日已发送过"我爱你"');
      return;
    }
    
    // TODO: 调用发送消息接口，给对方发送"我爱你"
    // 这里预留接口对接位置
    
    // 本地更新状态
    myTaskProgress.value = 1;
    _updateTomorrowTask();
    _updateTodayCheckInRecord();
    
    OKToastUtil.showSuccess('已向Ta发送"我爱你"');
  }
  
  /// 点击去完成任务
  void onCompleteTask() {
    if (myTaskProgress.value < 1) {
      OKToastUtil.showInfo('请先完成第一个任务');
      return;
    }
    
    if (myTaskProgress.value >= 2) {
      OKToastUtil.showInfo('今日任务已全部完成');
      return;
    }
    
    // TODO: 跳转到任务完成页面或执行任务
    // 这里预留接口对接位置
    
    // 本地更新状态
    myTaskProgress.value = 2;
    _updateTomorrowTask();
    _updateTodayCheckInRecord();
    
    OKToastUtil.showSuccess('任务完成！');
  }
  
  /// 更新今日打卡记录
  void _updateTodayCheckInRecord() {
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    final currentRecord = checkInRecords[today] ?? {'me': 0, 'partner': 0};
    currentRecord['me'] = myTaskProgress.value;
    checkInRecords[today] = currentRecord;
    checkInRecords.refresh();
  }
  
  /// 获取中心心形图标路径
  String getCenterHeartIcon() {
    final me = myTaskProgress.value;
    final partner = partnerTaskProgress.value;
    
    if (me == 0 && partner == 0) {
      return 'assets/188/kissu_188_task_undone.webp';
    } else if (me == 2 && partner == 2) {
      return 'assets/188/kissu_188_task_done.webp';
    } else if (me == 1 && partner == 0) {
      return 'assets/188/kissu_188_task_done_me1_she0.webp';
    } else if (me == 2 && partner == 0) {
      return 'assets/188/kissu_188_task_done_me2_she0.webp';
    } else if (me == 0 && partner == 1) {
      return 'assets/188/kissu_188_task_done_me0_she1.webp';
    } else if (me == 0 && partner == 2) {
      return 'assets/188/kissu_188_task_done_me0_she2.webp';
    } else if (me == 1 && partner == 1) {
      return 'assets/188/kissu_188_task_done_me1_she1.webp';
    } else if (me == 1 && partner == 2) {
      return 'assets/188/kissu_188_task_done_me1_she2.webp';
    } else if (me == 2 && partner == 1) {
      return 'assets/188/kissu_188_task_done_me2_she1.webp';
    }
    return 'assets/188/kissu_188_task_undone.webp';
  }
  
  /// 切换月份
  void changeMonth(int delta) {
    int newMonth = currentMonth.value + delta;
    int newYear = currentYear.value;
    
    if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    } else if (newMonth < 1) {
      newMonth = 12;
      newYear--;
    }
    
    currentMonth.value = newMonth;
    currentYear.value = newYear;
  }
  
  /// 点击补签
  void onRecoveryCheckIn(String date) {
    if (recoveryCardCount.value <= 0) {
      OKToastUtil.showError('补签卡不足');
      return;
    }
    
    // TODO: 调用补签接口
    // 这里预留接口对接位置
    
    OKToastUtil.showInfo('补签功能开发中');
  }
  
  /// 返回上一页
  void goBack() {
    Get.back();
  }
  
  /// 判断日期是否在活动期间内（开始日期到结束日期之间）
  bool isDateInActivityPeriod(DateTime date) {
    // 只比较日期，不比较时间
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(activityStartDate.year, activityStartDate.month, activityStartDate.day);
    final endOnly = DateTime(activityEndDate.year, activityEndDate.month, activityEndDate.day);
    
    return !dateOnly.isBefore(startOnly) && !dateOnly.isAfter(endOnly);
  }
  
  /// 获取活动开始日期
  DateTime getActivityStartDate() => activityStartDate;
  
  /// 获取活动结束日期
  DateTime getActivityEndDate() => activityEndDate;
}
