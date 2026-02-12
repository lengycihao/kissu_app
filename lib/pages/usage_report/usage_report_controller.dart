import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kissu_app/models/usage_record_api_model.dart';
import 'package:kissu_app/model/system_info_model.dart';
import 'package:kissu_app/network/public/usage_record_api.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/utils/source_page_utils.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/utils/vip_navigation_helper.dart';
import 'package:kissu_app/services/analytics/analytics_helper.dart';
import 'package:kissu_app/services/analytics/analytics_manager.dart';
import 'package:kissu_app/services/analytics/analytics_params.dart';
import 'package:kissu_app/services/analytics/analytics_events.dart'; 

class UsageReportController extends GetxController {
  final UsageRecordApi _usageRecordApi = UsageRecordApi();
  // final PhoneHistoryApi _phoneHistoryApi = PhoneHistoryApi();

  // 防抖Timer
  Timer? _debounceTimer;

  // 选中的日期索引 (6对应今天，在DateSelector的recentDates数组中)
  final selectedDateIndex = 6.obs;

  // 当前选中的日期
  final selectedDate = DateTime.now().obs;
 

    final isLoading = false.obs;

 

  // 系统设置相关
  final systemInfo = Rxn<SystemInfoModel>();
  final isSystemInfoLoading = false.obs;
  final isSystemSwitchLoading = false.obs;

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
  final selectedFilters = <String>['位置轨迹', 'Kissu', '手机状态', 'App使用统计'].obs; // 已选中的筛选项列表，默认4个都勾选
  final tempSelectedFilters = <String>[].obs; // 临时选中的筛选项列表（用于对话框）
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


    // // 检查并请求屏幕使用时长权限
    // _checkAndRequestPermission();
  }

  @override
  void onReady() {
    super.onReady();
    // 页面准备就绪时，确保已经静默刷新
  }

  /// 页面重新获得焦点时的回调（从其他页面返回时会调用）
  void onPageResumed() {
    logDebug('📊 用机记录页面重新获得焦点，静默刷新用户信息');
  
    // 然后静默刷新用户信息
    _silentRefreshUserInfo();
  }

  /// 静默刷新用户信息（不阻塞UI）
  Future<void> _silentRefreshUserInfo() async {
    try {
      logDebug('🔄 用机记录页面：静默刷新用户信息');
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
    
    logDebug(
      '✅ 敏感操作记录页面离开埋点: 停留时长=${duration}s, exitType=$exitType',
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
    logDebug('📊 UsageReportController 销毁');
    super.onClose();
  }

  /// 切换日期
  void changeDate(DateTime date) {
    // 如果选择的是相同日期，直接返回
    final newDateStr = DateFormat('yyyy-MM-dd').format(date);
    final currentDateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);

    if (newDateStr == currentDateStr) {
      logDebug('📊 相同日期，跳过切换: $newDateStr');
      return;
    }

    selectedDate.value = date;

    // 取消之前的防抖Timer
    _debounceTimer?.cancel();

    // 使用防抖加载数据，避免连续点击时多次请求
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      logDebug('📊 防抖Timer触发，开始加载数据');
      loadData();
    });
  }

  /// 加载数据（重置分页）
  Future<void> loadData({bool isRefresh = false}) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);
    logDebug('📊 加载数据: $dateStr, isRefresh: $isRefresh');

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
        logDebug('✅ 数据加载成功，共${result.data!.list.length}条记录');
        // 刷新时直接替换数据，不清空再添加
        sensitiveRecordList.value = result.data!.list;
        hasMore.value = result.data!.hasMore;
        // 保存设备信息
        halfUserData.value = result.data!.halfUserData;
        logDebug('📄 是否有更多数据: ${hasMore.value}');
        logDebug('📱 设备信息: ${result.data!.halfUserData?.mobileModel ?? "未知"}');
      } else {
        logError('❌ 数据加载失败: ${result.msg}');
        _showToastSafely(result.msg ?? '数据加载失败');
      }
    } catch (e) {
      logError('💥 数据加载异常: $e');
      _showToastSafely('数据加载异常: $e');
    } finally {
      if (!isRefresh) {
        isLoading.value = false;
      }
    }
  }


  /// 加载更多数据
  Future<void> loadMoreData() async {
    if (isLoadingMore.value || !hasMore.value) {
      logDebug('⚠️ 无法加载更多：isLoadingMore=${isLoadingMore.value}, hasMore=${hasMore.value}');
      return;
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);
    logDebug('📊 加载更多数据，当前页: ${currentPage.value}');

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
        logDebug('✅ 加载更多成功，新增${result.data!.list.length}条记录');
        sensitiveRecordList.addAll(result.data!.list);
        hasMore.value = result.data!.hasMore;
        // 更新设备信息（加载更多时也可能更新）
        if (result.data!.halfUserData != null) {
          halfUserData.value = result.data!.halfUserData;
        }
        logDebug('📄 是否还有更多数据: ${hasMore.value}');
      } else {
        logError('❌ 加载更多失败: ${result.msg}');
        currentPage.value--; // 恢复页码
        _showToastSafely(result.msg ?? '加载更多失败');
      }
    } catch (e) {
      logError('💥 加载更多异常: $e');
      currentPage.value--; // 恢复页码
      _showToastSafely('加载更多异常: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// 切换筛选类型（已废弃，改用多选）
  @Deprecated('使用多选筛选，直接在showFilterDialog中处理')
  void changeFilter(String filter) {
    logDebug('🔄 切换筛选类型: $filter');
    // 已改为多选，此方法不再使用
  }

  /// 下拉刷新
  Future<void> onRefresh() async {
    logDebug('🔄 下拉刷新');
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
      
      // 需要VIP权限，跳转到VIP页面
      logDebug('🔒 需要VIP权限，跳转到VIP页面');
      _navigateToVipPageWithEvent(SensitiveEvents.itemVipBtn);
    } else if (record.showJumpButton) {
      // 有跳转按钮，处理跳转
      handleJumpPageClick(record.jumpPage);
    }
  }

  /// 处理跳转按钮点击
  void handleJumpPageClick(String jumpPage) {
    logDebug('🔗 跳转页面: $jumpPage');
    
    // 埋点：页面离开（进入下一页）
    onNavigateToNextPage?.call();
    
    switch (jumpPage) {
      case 'appUsePage':
        // 跳转到app使用统计页面
        logDebug('📱 跳转到App使用统计页面');
        Get.toNamed(KissuRoutePath.appUsage);
        break;
      case 'tracePage':
        // 跳转到足迹页面
        logDebug('👣 跳转到足迹页面');
        Get.toNamed(KissuRoutePath.track);
        break;
      case 'unlockPhonePage':
        // 跳转到设备使用记录页面（包含解锁记录）
        logDebug('📲 跳转到设备使用记录页面');
        Get.toNamed(KissuRoutePath.appUsageInfo);
        break;
      case 'locationPage':
        // 跳转到定位页面
        logDebug('📍 跳转到定位页面');
        Get.toNamed(KissuRoutePath.location);
        break;
      case 'mobileUse':
        // 跳转到设备使用页面
        logDebug('📱 跳转到设备使用页面');
        Get.toNamed(KissuRoutePath.deviceUsage, arguments: {'source_event': SensitiveEvents.page});
        break;
      case 'locationReminder':
        // 跳转到定位提醒页面
        logDebug('🔔 跳转到定位提醒页面');
        Get.toNamed(KissuRoutePath.locationReminder);
        break;
      default:
        logDebug('⚠️ 未知的跳转页面类型: $jumpPage');
    }
  }

  /// 跳转到VIP页面（带来源事件参数）
  Future<void> _navigateToVipPageWithEvent(String sourceEvent) async {
    logDebug('💎 跳转到VIP页面, sourceEvent: $sourceEvent');
    
    // 埋点：页面离开（进入下一页）
    onNavigateToNextPage?.call();
    
    // 跳转到VIP页面
    final result = await Get.toNamed(KissuRoutePath.vip, arguments: {'source_page': SourcePageUtilsCaller.usageReport, 'source_event': sourceEvent});
    
    // 如果开通成功，刷新数据
    if (result == true) {
      logDebug('✅ VIP开通成功，刷新数据');
      await loadData();
    }
  }

  /// 安全地显示Toast
  void _showToastSafely(String message) {
    try {
      // 优先使用pageContext（已在页面中保存）
      CustomToast.show(pageContext, message);
    } catch (e) {
      logInfo('⚠️ 使用pageContext显示Toast失败，尝试其他方式: $e');
      // fallback到Get.context
      try {
        if (Get.context != null) {
          CustomToast.show(Get.context!, message);
        } else {
          // 最终fallback：使用OKToastUtil
          OKToastUtil.show(message);
        }
      } catch (e2) {
        logError('⚠️ 所有Toast显示方式都失败: $e2');
        // 最后使用print输出
       }
    }
  }

  /// 显示设置对话框
  void showSettingDialog() async {
    // 埋点：页面离开（进入下一页）
    onNavigateToNextPage?.call();
    
    // 跳转到用机设置页面
    Get.toNamed(KissuRoutePath.notificationSettings);
  }

  /// 获取系统信息设置
  // Future<void> loadSystemInfo() async {
  //   isSystemInfoLoading.value = true;
  //   try {
  //     final result = await _phoneHistoryApi.getSystemInfo();
  //     if (result.isSuccess && result.data != null) {
  //       systemInfo.value = result.data!;
  //     } else {
  //       OKToastUtil.show('获取系统设置失败: ${result.msg}');
  //     }
  //   } catch (e) {
  //     OKToastUtil.show('获取系统设置异常: $e');
  //   } finally {
  //     isSystemInfoLoading.value = false;
  //   }
  // }

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
    isUserVip.value = UserManager.isVip; // 同时更新会员状态
    logDebug('📊 用户绑定状态更新: $bound, 会员状态: ${isUserVip.value}');
  }

  /// 检查用户是否已绑定（保持向后兼容）
  bool isUserBoundSync() {
    return isUserBound.value;
  }

  /// 处理距离按钮点击事件
  void handleDistanceButtonClick() {
    if (isUserBound.value) {
      // 已绑定，跳转到定位页面（添加会员检查）
      logDebug('📍 用户已绑定，跳转到定位页面（检查会员状态）');
      VipNavigationHelper.navigateToLocationWithVipCheck();
    } else {
      // 未绑定，显示绑定弹窗
      logDebug('💑 用户未绑定，显示绑定弹窗');
      showBindingDialog();
    }
  }

  /// 处理绑定按钮点击事件
  void handleBindButtonClick() async {
    logDebug('💑 立即绑定按钮被点击');

 

    showBindingDialog();
  }

  /// 处理开通会员按钮点击事件
  void handleVipButtonClick() async {
    logDebug('💎 开通会员按钮被点击');

    

    // 跳转到VIP页面
    await Get.toNamed(
      KissuRoutePath.vip,
     arguments: {'source_page': SourcePageUtilsCaller.usageReport, 'source_event': PhoneHistoryEvents.appUseModule},
    );

    // 从VIP页面返回后，刷新用户信息
    logDebug('📊 从VIP页面返回，刷新用户信息');
    try {
      final success = await UserManager.refreshUserInfo();
      if (success) {
        _updateUserBindStatus(); // 更新绑定状态和会员状态
        if (isUserBound.value && isUserVip.value) {
          // 如果已绑定且已开通会员，刷新数据
          logDebug('💎 用户已开通会员，刷新页面数据');
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
        onClose: () {
          logDebug('💑 绑定弹窗已关闭');
        },
      ).then((result) {
        // 绑定弹窗关闭后，更新绑定状态并检查是否需要刷新页面
        _updateUserBindStatus();
        if (isUserBound.value) {
          logDebug('💑 用户已绑定，刷新页面数据');
          loadData();
        }
      });
    } else {
      logError('❌ 无法获取Context，跳过显示绑定弹窗');
    }
  }
 

  
  /// 显示筛选对话框
  void showFilterDialog() {
    // 初始化临时选中项为当前选中项
    tempSelectedFilters.value = List.from(selectedFilters);
    
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '事件筛选',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),

            // 筛选选项列表
            ...filterOptions.map((option) {
              return Obx(() {
                final isSelected = tempSelectedFilters.contains(option);
                return InkWell(
                  onTap: () {
                    // 多选逻辑：点击切换选中状态
                    if (isSelected) {
                      tempSelectedFilters.remove(option);
                    } else {
                      tempSelectedFilters.add(option);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    margin: EdgeInsets.symmetric(horizontal: 36),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(width: 1, color: Color(0xffF6F6F6)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                        Image(
                          image: AssetImage(
                            isSelected
                                ? 'assets/phone_history/kissu3_history_seting_sel.webp'
                                : 'assets/phone_history/kissu3_history_seting_unsel.webp',
                          ),
                          width: 16,
                        ),
                      ],
                    ),
                  ),
                );
              });
            }) ,
            SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Get.back();
                // 应用筛选条件，重新加载数据
                selectedFilters.value = List.from(tempSelectedFilters);
                loadData();
              },
              child: Container(
                height: 42,
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 36),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(21),
                ),
                alignment: Alignment.center,
                child: Text(
                  "确定",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
      isScrollControlled: true,
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
