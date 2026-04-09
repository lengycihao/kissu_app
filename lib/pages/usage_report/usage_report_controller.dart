import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kissu_app/models/usage_record_api_model.dart';
import 'package:kissu_app/network/public/usage_record_api.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/utils/source_page_utils.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/utils/vip_navigation_helper.dart';
import 'package:kissu_app/services/analytics/analytics_helper.dart';
import 'package:kissu_app/services/analytics/analytics_manager.dart';
import 'package:kissu_app/services/analytics/analytics_params.dart';
import 'package:kissu_app/services/analytics/analytics_events.dart';
import 'package:kissu_app/pages/usage_report/widgets/filter_bottom_sheet.dart';

class UsageReportController extends GetxController {
  final UsageRecordApi _usageRecordApi = UsageRecordApi();

  // 防抖Timer
  Timer? _debounceTimer;

  // 选中的日期索引 (6对应今天，在DateSelector的recentDates数组中)
  final selectedDateIndex = 6.obs;

  // 当前选中的日期
  final selectedDate = DateTime.now().obs;

  final isLoading = false.obs;

  // 用户绑定状态（响应式）
  final isUserBound = false.obs;

  // 用户会员状态（响应式）
  final isUserVip = false.obs;

  // 页面Context（用于Overlay）
  late BuildContext pageContext;

  // 埋点相关
  int? _pageEnterTime;
  int _exitType = ExitTypeValue.back;
  bool _hasTrackedExit = false; // 是否已上报离开埋点
  
  // 页面离开回调
  VoidCallback? onNavigateToNextPage;

  // 筛选选项（改为多选）
  final selectedFilters = <String>['位置轨迹', 'Kissu', '手机状态', 'App使用统计'].obs;
  final filterOptions = ['位置轨迹', 'Kissu', '手机状态', 'App使用统计'];

  // 分页相关
  final currentPage = 1.obs;
  final pageSize = 20; // 每页加载20条
  final hasMore = false.obs;
  final isLoadingMore = false.obs;
  final RxList<SensitiveRecordItem> sensitiveRecordList = <SensitiveRecordItem>[].obs;
  
  // 最后刷新时间
  final lastRefreshTime = Rxn<DateTime>();
  
  // 是否正在下拉刷新
  final isPullingRefresh = false.obs;
  
  // 另一半用户设备信息
  final halfUserData = Rxn<HalfUserData>();

  // 设备信息展开状态：null表示未展开，其他值表示当前展开的项类型
  final selectedDeviceInfoType = Rxn<String>(); // 'distance', 'mobileModel', 'network', 'power'

  // 设备信息悬浮提示的自动隐藏定时器
  Timer? _deviceInfoTooltipTimer;
  
  // 筛选类型映射：位置轨迹=4, Kissu=1, 手机状态=2, App使用统计=3
  // 返回逗号分隔的字符串，如 "1,2" 或 null（查询全部）
  String? get sensitiveClassify {
    if (selectedFilters.isEmpty) {
      return null; // 全部
    }
    
    // 如果所有选项都选中，等同于查询全部，返回 null
    if (selectedFilters.length == filterOptions.length && 
        selectedFilters.toSet().containsAll(filterOptions)) {
      return null; // 全部
    }
    
    final classifyList = <int>[];
    for (var filter in selectedFilters) {
      switch (filter) {
        case 'Kissu':
          classifyList.add(1);
          break;
        case '手机状态':
          classifyList.add(2);
          break;
        case 'App使用统计':
          classifyList.add(3);
          break;
        case '位置轨迹':
          classifyList.add(4);
          break;
      }
    }
    
    return classifyList.isEmpty ? null : classifyList.join(',');
  }

  @override
  void onInit() {
    super.onInit();
    logDebug('📊 UsageReportController 初始化');

    // 埋点：记录页面进入时间（十位时间戳）
    _pageEnterTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // 注册页面离开回调
    onNavigateToNextPage = () {
      _trackPageExit(ExitTypeValue.nextPage);
    };

    // 初始化用户绑定状态（使用本地数据）
    _updateUserBindStatus();

    // 然后静默刷新用户信息
    _silentRefreshUserInfo();

    // 延迟加载数据，等待页面转场动画完成（350ms）
    // loadData内部会设置isLoading状态
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!isClosed) {
        loadData();
      }
    });
  }

  /// 页面重新获得焦点时的回调（从其他页面返回时会调用）
  void onPageResumed() {
    _silentRefreshUserInfo();
  }

  /// 静默刷新用户信息（不阻塞UI）
  Future<void> _silentRefreshUserInfo() async {
    try {
      final success = await UserManager.refreshUserInfo();
      if (success) {
        // 刷新成功后重新加载本地数据到UI
        _updateUserBindStatus();
      }
    } catch (e) {
      logError('❌ 用机记录页面：静默刷新用户信息失败: $e');
    }
  }

  /// 上报页面离开埋点
  void _trackPageExit(int exitType) {
    if (_hasTrackedExit || _pageEnterTime == null) return;
    _hasTrackedExit = true;
    
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final duration = currentTime - _pageEnterTime!;
    
    // 上报埋点：sensitive_page_event
    AnalyticsManager.instance.trackPageView(
      pageId: SensitiveEvents.pageId,
      eventId: SensitiveEvents.page,
      enterTime: _pageEnterTime!,
      duration: duration,
      exitType: exitType,
    );
    
    // 如果是进入下一页，立即重置状态，为从下一页返回后的埋点做准备
    if (exitType == ExitTypeValue.nextPage) {
      _pageEnterTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      _hasTrackedExit = false;
      _exitType = ExitTypeValue.back;
    }
  }
  
  /// 应用切换到后台
  void onAppPaused() {
    _exitType = ExitTypeValue.toBackground;
    _trackPageExit(ExitTypeValue.toBackground);
  }
  
  /// 应用从后台返回
  void onAppResumed() {
    // 重置状态，准备下次埋点
    _pageEnterTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _hasTrackedExit = false;
    _exitType = ExitTypeValue.back;
  }
  
  @override
  void onClose() {
    // 埋点：记录页面离开事件（返回）
    _trackPageExit(_exitType);

    _debounceTimer?.cancel();
    _deviceInfoTooltipTimer?.cancel();
    super.onClose();
  }

  /// 切换日期
  void changeDate(DateTime date) {
    // 如果选择的是相同日期，直接返回
    final newDateStr = DateFormat('yyyy-MM-dd').format(date);
    final currentDateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);

    if (newDateStr == currentDateStr) {
      return;
    }

    selectedDate.value = date;

    // 取消之前的防抖Timer
    _debounceTimer?.cancel();

    // 使用防抖加载数据，避免连续点击时多次请求
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      loadData();
    });
  }

  /// 加载数据（重置分页）
  Future<void> loadData({bool isRefresh = false}) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);

    try {
      // 只在非刷新时显示loading
      if (!isRefresh) {
        isLoading.value = true;
      }
      currentPage.value = 1;

      // 调用分页API
      final result = await _usageRecordApi.getSensitiveRecordPage(
        page: currentPage.value,
        pageSize: pageSize,
        sensitiveClassify: sensitiveClassify,
        date: dateStr,
      );

      if (result.isSuccess && result.data != null) {
        sensitiveRecordList.value = result.data!.list;
        hasMore.value = result.data!.hasMore;
        halfUserData.value = result.data!.halfUserData;
      } else {
        logError('❌ 数据加载失败: ${result.msg}');
        _showToast(result.msg ?? '数据加载失败');
      }
    } catch (e) {
      logError('💥 数据加载异常: $e');
      _showToast('数据加载异常: $e');
    } finally {
      if (!isRefresh) {
        isLoading.value = false;
      }
    }
  }


  /// 加载更多数据
  Future<void> loadMoreData() async {
    if (isLoadingMore.value || !hasMore.value) {
      logWarning('⚠️ 无法加载更多：isLoadingMore=${isLoadingMore.value}, hasMore=${hasMore.value}');
      return;
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);

    try {
      isLoadingMore.value = true;
      currentPage.value++;

      final result = await _usageRecordApi.getSensitiveRecordPage(
        page: currentPage.value,
        pageSize: pageSize,
        sensitiveClassify: sensitiveClassify,
        date: dateStr,
      );

      if (result.isSuccess && result.data != null) {
        sensitiveRecordList.addAll(result.data!.list);
        hasMore.value = result.data!.hasMore;
        if (result.data!.halfUserData != null) {
          halfUserData.value = result.data!.halfUserData;
        }
      } else {
        logError('❌ 加载更多失败: ${result.msg}');
        currentPage.value--; // 恢复页码
        _showToast(result.msg ?? '加载更多失败');
      }
    } catch (e) {
      logError('💥 加载更多异常: $e');
      currentPage.value--; // 恢复页码
      _showToast('加载更多异常: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// 下拉刷新
  Future<void> onRefresh() async {
    isPullingRefresh.value = true;
    await loadData(isRefresh: true);
    // 更新刷新时间
    lastRefreshTime.value = DateTime.now();
    isPullingRefresh.value = false;
  }

  /// 处理记录item点击
  void handleRecordItemClick(SensitiveRecordItem record) {
    if (record.needsVip) {
      // 埋点：记录敏感操作记录item上的vip按钮点击
      AnalyticsHelper.trackSensitiveItemVipBtn();
      
      _navigateToVipPageWithEvent(SensitiveEvents.itemVipBtn);
    } else if (record.showJumpButton) {
      // 有跳转按钮，处理跳转
      handleJumpPageClick(record.jumpPage);
    }
  }

  /// 处理跳转按钮点击
  void handleJumpPageClick(String jumpPage) {
    onNavigateToNextPage?.call();

    switch (jumpPage) {
      case 'appUsePage':
        Get.toNamed(KissuRoutePath.appUsage);
        break;
      case 'tracePage':
        Get.toNamed(KissuRoutePath.track);
        break;
      case 'unlockPhonePage':
        Get.toNamed(KissuRoutePath.appUsageInfo);
        break;
      case 'locationPage':
        Get.toNamed(KissuRoutePath.location);
        break;
      case 'mobileUse':
        Get.toNamed(KissuRoutePath.deviceUsage, arguments: {'source_event': SensitiveEvents.page});
        break;
      case 'locationReminder':
        Get.toNamed(KissuRoutePath.locationReminder);
        break;
      default:
        logDebug('⚠️ 未知的跳转页面类型: $jumpPage');
    }
  }

  /// 跳转到VIP页面（带来源事件参数）
  Future<void> _navigateToVipPageWithEvent(String sourceEvent) async {
    onNavigateToNextPage?.call();

    final result = await Get.toNamed(
      KissuRoutePath.vip,
      arguments: {'source_page': SourcePageUtilsCaller.usageReport, 'source_event': sourceEvent},
    );

    if (result == true) {
      await loadData();
    }
  }

  /// 显示Toast提示
  void _showToast(String message) {
    OKToastUtil.show(message);
  }

  /// 显示设置对话框
  void showSettingDialog() async {
    // 埋点：页面离开（进入下一页）
    onNavigateToNextPage?.call();
    
    // 跳转到用机设置页面
    Get.toNamed(KissuRoutePath.notificationSettings);
  }

  /// 更新用户绑定状态
  void _updateUserBindStatus() {
    final user = UserManager.currentUser;
    bool bound = false;
    if (user?.bindStatus != null) {
      if (user!.bindStatus is int) {
        bound = user.bindStatus == 1;
      } else if (user.bindStatus is String) {
        bound = user.bindStatus == "1";
      }
    }
    isUserBound.value = bound;
    isUserVip.value = UserManager.isVip;
  }

  /// 处理距离按钮点击事件
  void handleDistanceButtonClick() {
    if (isUserBound.value) {
      VipNavigationHelper.navigateToLocationWithVipCheck();
    } else {
      showBindingDialog();
    }
  }

  /// 处理开通会员按钮点击事件
  void handleVipButtonClick() async {
    await Get.toNamed(
      KissuRoutePath.vip,
      arguments: {'source_page': SourcePageUtilsCaller.usageReport, 'source_event': PhoneHistoryEvents.appUseModule},
    );

    try {
      final success = await UserManager.refreshUserInfo();
      if (success) {
        _updateUserBindStatus();
        if (isUserBound.value && isUserVip.value) {
          loadData();
        }
      }
    } catch (e) {
      logError('❌ 刷新用户信息失败: $e');
    }
  }

  /// 显示绑定弹窗
  void showBindingDialog() {
    final currentContext = Get.context;
    if (currentContext != null) {
      CustomBottomDialog.show(
        context: currentContext,
        caller: SourcePageUtilsCaller.usageReport,
        sourceEvent: PhoneHistoryEvents.pageId, // 用机记录页面统一传mobile_use_page
        onClose: () {},
      ).then((result) {
        // 绑定弹窗关闭后，更新绑定状态并检查是否需要刷新页面
        _updateUserBindStatus();
        if (isUserBound.value) {
          loadData();
        }
      });
    } else {
      logError('❌ 无法获取Context，跳过显示绑定弹窗');
    }
  }

  /// 显示筛选对话框
  void showFilterDialog() {
    FilterBottomSheet.show(
      filterOptions: filterOptions,
      currentFilters: selectedFilters,
      onConfirm: (selected) {
        selectedFilters.value = selected;
        loadData();
      },
    );
  }
  
  /// 清除设备信息提示（手动关闭 tip）
  void clearSelectedDeviceInfo() {
    _deviceInfoTooltipTimer?.cancel();
    selectedDeviceInfoType.value = null;
  }

  /// 切换设备信息展开状态（并启动 2 秒自动隐藏计时）
  void toggleDeviceInfo(String? type) {
    // 先取消之前的定时器
    _deviceInfoTooltipTimer?.cancel();

    // 如果点击的是当前已展开的项，则收起并直接返回
    if (selectedDeviceInfoType.value == type) {
      selectedDeviceInfoType.value = null;
      return;
    }

    // 切换到新的类型
    selectedDeviceInfoType.value = type;

    // 启动 2 秒自动隐藏
    if (type != null) {
      _deviceInfoTooltipTimer = Timer(const Duration(seconds: 2), () {
        // 只在当前仍然是同一个类型时才隐藏，避免抢掉后续点击
        if (selectedDeviceInfoType.value == type && !isClosed) {
          selectedDeviceInfoType.value = null;
        }
      });
    }
  }
}
