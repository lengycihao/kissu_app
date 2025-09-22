import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kissu_app/model/phone_history_model/phone_history_model.dart';
import 'package:kissu_app/model/phone_history_model/datum.dart';
import 'package:kissu_app/model/system_info_model.dart';
import 'package:kissu_app/network/public/phone_history_api.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/utils/debug_util.dart';
import 'phone_history_setting_dialog.dart';

class PhoneHistoryController extends GetxController {
  final _api = PhoneHistoryApi();
  
  // PageView相关
  late PageController pageController;
  final currentPageIndex = 6.obs; // 默认显示今天（最右边）
  
  // 是否绑定情侣 - 初始为null，表示未知状态
  final isBinding = Rxn<bool>();
  
  // 数据相关
  final phoneHistoryModel = Rxn<PhoneHistoryModel>();
  final recordList = <Datum>[].obs;
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final isLoadingMore = false.obs;
  final hasMoreData = true.obs;
  
  // 分页相关
  int _currentPage = 1;
  final int _pageSize = 10;
  
  // 选中的日期
  final selectedDate = DateTime.now().obs;
  String get formattedDate => DateFormat('yyyy-MM-dd').format(selectedDate.value);
  
  // 选中的日期索引
  final selectedDateIndex = 6.obs; // 默认选中今天（最右边）
  var tooltipText = Rxn<String>();
  OverlayEntry? _overlayEntry;
  late BuildContext pageContext;
  
  // 防抖timer
  Timer? _debounceTimer;
  
  // 加载相关状态
  final isDateLoading = false.obs;
  
  // 滑动提示相关
  final swipeHintText = ''.obs;
  Timer? _swipeHintTimer;

  // 系统设置相关
  final systemInfo = Rxn<SystemInfoModel>();
  final isSystemInfoLoading = false.obs;
  final isSystemSwitchLoading = false.obs;

  /// 最近7天日期列表（今天及之前6天）
  List<DateTime> get recentDates {
    final now = DateTime.now();
    // 反转顺序，让最左边是最早的，最右边是今天
    return List.generate(7, (index) => now.subtract(Duration(days: 6 - index)));
  }

  @override
  void onInit() {
    super.onInit();
    // 初始化PageController，默认显示今天
    pageController = PageController(initialPage: 6);
    // 初始化绑定状态（从本地用户信息获取，避免闪烁）
    _initBindingStatus();
    // 初始加载数据
    loadData();
  }

  @override
  void onReady() {
    super.onReady();
    // 页面准备就绪时，检查是否需要刷新绑定状态
    _checkAndRefreshBindingStatus();
  }


  @override
  void onClose() {
    // 清理PageController
    pageController.dispose();
    // 清理overlay
    hideTooltip();
    // 清理防抖timer
    _debounceTimer?.cancel();
    // 清理滑动提示timer
    _swipeHintTimer?.cancel();
    super.onClose();
  }

  /// PageView页面改变回调
  void onPageChanged(int index) {
    currentPageIndex.value = index;
    selectedDateIndex.value = index; // 同步日期选择器的选中状态
    final targetDate = recentDates[index];
    selectedDate.value = targetDate;
    
    // 检查是否应该请求数据
    if (_shouldLoadDataForDate(targetDate)) {
      // 加载对应日期的数据
      _currentPage = 1;
      isDateLoading.value = true;
      loadData(isRefresh: true).then((_) {
        isDateLoading.value = false;
      });
    } else {
      // 未绑定状态下选择今天之前的日期，清空数据但不请求
      recordList.clear();
      phoneHistoryModel.value = null;
    }
  }

  /// 初始化绑定状态（从本地用户信息获取，避免页面闪烁）
  void _initBindingStatus() {
    final user = UserManager.currentUser;
    if (user != null) {
      // 安全处理bindStatus的dynamic类型
      bool isBound = false;
      if (user.bindStatus != null) {
        if (user.bindStatus is int) {
          isBound = user.bindStatus == 1;
        } else if (user.bindStatus is String) {
          isBound = user.bindStatus == "1";
        }
      }
      isBinding.value = isBound;
      DebugUtil.info('📱 初始化绑定状态: $isBound (从本地用户信息获取)');
    } else {
      DebugUtil.info('📱 用户信息为空，绑定状态保持为null');
    }
  }

  /// 判断是否应该为指定日期请求数据
  bool _shouldLoadDataForDate(DateTime targetDate) {
    // 如果绑定状态未知，允许请求数据
    if (isBinding.value == null) {
      return true;
    }
    
    // 如果已绑定，总是请求数据
    if (isBinding.value == true) {
      return true;
    }
    
    // 如果未绑定，只请求今天的数据
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final targetDateOnly = DateTime(targetDate.year, targetDate.month, targetDate.day);
    
    return targetDateOnly.isAtSameMomentAs(todayDate);
  }

  /// 加载数据
  Future<void> loadData({bool isRefresh = false}) async {
    if (isRefresh) {
      isRefreshing.value = true;
      _currentPage = 1;
      hasMoreData.value = true;
    } else {
      isLoading.value = true;
    }

    try {
      final result = await _api.getSensitiveRecord(
        page: _currentPage,
        pageSize: _pageSize,
        date: formattedDate,
      );

      if (result.isSuccess && result.data != null) {
        phoneHistoryModel.value = result.data!;
        
        // 更新绑定状态 - 修正：1=未绑定，2=绑定
        isBinding.value = result.data!.user?.isBind == 1;
        
        if (isRefresh || _currentPage == 1) {
          recordList.clear();
        }
        
        if (result.data!.data != null && result.data!.data!.isNotEmpty) {
          recordList.addAll(result.data!.data!);
        }
        
        // 检查是否还有更多数据
        hasMoreData.value = result.data!.data != null && 
                           result.data!.data!.length >= _pageSize;
      } else {
        if (_currentPage == 1) {
          recordList.clear();
        }
        // 可以在这里显示错误信息
        DebugUtil.error('加载失败: ${result.msg}');
      }
    } catch (e) {
      DebugUtil.error('加载数据异常: $e');
      if (_currentPage == 1) {
        recordList.clear();
      }
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  /// 下拉刷新
  Future<void> onRefresh() async {
    await loadData(isRefresh: true);
  }

  /// 上拉加载更多
  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMoreData.value) return;
    
    isLoadingMore.value = true;
    _currentPage++;
    
    try {
      final result = await _api.getSensitiveRecord(
        page: _currentPage,
        pageSize: _pageSize,
        date: formattedDate,
      );

      if (result.isSuccess && result.data != null) {
        if (result.data!.data != null && result.data!.data!.isNotEmpty) {
          recordList.addAll(result.data!.data!);
          hasMoreData.value = result.data!.data!.length >= _pageSize;
        } else {
          hasMoreData.value = false;
        }
      } else {
        _currentPage--; // 回滚页码
        DebugUtil.error('加载更多失败: ${result.msg}');
      }
    } catch (e) {
      _currentPage--; // 回滚页码
      DebugUtil.error('加载更多异常: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// 切换日期（带防抖和加载状态）- 添加PageView动画
  void changeDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final currentDateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);
    
    // 如果是同一天，不需要重新请求
    if (dateStr == currentDateStr) return;
    
    // 找到对应的页面索引
    final targetIndex = recentDates.indexWhere((d) => 
      DateFormat('yyyy-MM-dd').format(d) == dateStr
    );
    
    if (targetIndex != -1) {
      // 使用PageView动画切换到对应页面
      pageController.animateToPage(
        targetIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 根据设备组件类型生成简化信息
  String _getDeviceSimpleInfo(String componentText) {
    // 根据当前显示的文本判断是哪个组件
    if (componentText == deviceModel) {
      // 手机设备组件
      return "设备型号：$deviceModel";
    } else if (componentText == batteryLevel) {
      // 电量组件
      return "当前电量：$batteryLevel";
    } else if (componentText == networkName) {
      // 网络组件
      return "网络名称：$networkName";
    }
    
    // 默认返回原文本
    return componentText;
  }

  void showTooltip(String text, Offset position) {
    hideTooltip(); // 先移除旧的

    // 获取简化信息
    final simpleText = _getDeviceSimpleInfo(text);

    final screenSize = MediaQuery.of(pageContext).size;
    const padding = 12.0;

    // 先预估提示框的大小
    final maxWidth = screenSize.width * 0.6;
    final estimatedHeight = 40.0;

    double left = position.dx;
    double top = position.dy;

    // 避免溢出右边
    if (left + maxWidth + padding > screenSize.width) {
      left = screenSize.width - maxWidth - padding;
    }

    // 避免溢出下边
    if (top + estimatedHeight + padding > screenSize.height) {
      top = screenSize.height - estimatedHeight - padding;
    }

    _overlayEntry = OverlayEntry(
      builder: (_) {
        return Stack(
          children: [
            // ✅ 全屏透明点击区域
            Positioned.fill(
              child: GestureDetector(
                onTap: hideTooltip,
                behavior: HitTestBehavior.translucent, // 即使透明也能点到
                child: Container(color: Colors.transparent),
              ),
            ),
            // 提示框
            Positioned(
              left: left,
              top: top,
              child: Material(
                color: Colors.transparent,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        simpleText,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                    // 关闭按钮
                    Positioned(
                      top: -8,
                      right: -8,
                      child: GestureDetector(
                        onTap: hideTooltip,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.grey,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(pageContext, rootOverlay: true).insert(_overlayEntry!);
  }

  void hideTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // 显示设置弹窗
  void showSettingDialog() async {
    // 先加载系统信息
    await loadSystemInfo();
    // 然后显示弹窗
    PhoneHistorySettingDialog.show(
      systemInfo: systemInfo.value,
      onConfirm: _updateSystemSettings,
    );
  }

  /// 获取系统信息设置
  Future<void> loadSystemInfo() async {
    isSystemInfoLoading.value = true;
    try {
      final result = await _api.getSystemInfo();
      if (result.isSuccess && result.data != null) {
        systemInfo.value = result.data!;
      } else {
        OKToastUtil.show('获取系统设置失败: ${result.msg}');
      }
    } catch (e) {
      OKToastUtil.show('获取系统设置异常: $e');
    } finally {
      isSystemInfoLoading.value = false;
    }
  }

  /// 更新系统设置
  Future<void> _updateSystemSettings(SystemInfoModel newSystemInfo) async {
    isSystemSwitchLoading.value = true;
    try {
      final result = await _api.setSystemSwitch(
        isPushKissuMsg: newSystemInfo.isPushKissuMsg.toString(),
        isPushSystemMsg: newSystemInfo.isPushSystemMsg.toString(),
        isPushPhoneStatusMsg: newSystemInfo.isPushPhoneStatusMsg.toString(),
        isPushLocationMsg: newSystemInfo.isPushLocationMsg.toString(),
      );

      if (result.isSuccess) {
        systemInfo.value = newSystemInfo;
        OKToastUtil.show('设置成功');
      } else {
        OKToastUtil.show('设置失败: ${result.msg}');
      }
    } catch (e) {
      OKToastUtil.showError('设置异常: $e');
    } finally {
      isSystemSwitchLoading.value = false;
    }
  }

  /// 显示绑定弹窗 - 直接跳转到分享页面
  void showBindingDialog() {
    // 直接跳转到分享页面，不再显示弹窗
    Get.toNamed(KissuRoutePath.share);
  }

  /// 检查并刷新绑定状态
  Future<void> _checkAndRefreshBindingStatus() async {
    try {
      // 从本地用户信息获取绑定状态
      final localUser = UserManager.currentUser;
      bool localIsBound = false;
      if (localUser?.bindStatus != null) {
        if (localUser!.bindStatus is int) {
          localIsBound = localUser.bindStatus == 1;
        } else if (localUser.bindStatus is String) {
          localIsBound = localUser.bindStatus == "1";
        }
      }
      
      print('📱 检查绑定状态 - 本地状态: $localIsBound, 页面状态: ${isBinding.value}');
      
      // 如果本地状态与页面状态不一致，则刷新数据
      if (localIsBound != isBinding.value) {
        print('📱 绑定状态不一致，刷新数据');
        await loadData(isRefresh: true);
        print('📱 绑定状态已刷新: ${isBinding.value}');
      } else {
        print('📱 绑定状态一致，无需刷新');
      }
    } catch (e) {
      print('📱 刷新绑定状态失败: $e');
    }
  }

  /// 外部调用的刷新方法（用于其他页面通知更新）
  Future<void> refreshBindingStatus() async {
    try {
      print('📱 收到绑定状态刷新通知');
      await loadData(isRefresh: true);
      print('📱 绑定状态已更新: ${isBinding.value}');
    } catch (e) {
      print('📱 刷新绑定状态失败: $e');
    }
  }

  /// 左滑切换到后一天
  void swipeToNextDay() {
    final nextDate = selectedDate.value.add(const Duration(days: 1));
    final today = DateTime.now();
    
    // 不能超过今天
    if (nextDate.isAfter(DateTime(today.year, today.month, today.day))) {
      _showSwipeHint('已经是最新日期');
      return;
    }
    
    _showSwipeHint(DateFormat('yyyy-MM-dd').format(nextDate));
    changeDate(nextDate);
  }

  /// 右滑切换到前一天  
  void swipeToPreviousDay() {
    final prevDate = selectedDate.value.subtract(const Duration(days: 1));
    _showSwipeHint(DateFormat('yyyy-MM-dd').format(prevDate));
    changeDate(prevDate);
  }
  
  /// 显示滑动提示
  void _showSwipeHint(String text) {
    swipeHintText.value = text;
    _swipeHintTimer?.cancel();
    _swipeHintTimer = Timer(const Duration(seconds: 1), () {
      swipeHintText.value = '';
    });
  }

  // 获取用机记录数据
  List<PhoneUsageRecord> getUsageRecords() {
    if (isBinding.value != true || recordList.isEmpty) return [];

    return recordList.map((datum) => PhoneUsageRecord(
      time: datum.createTime ?? '',
      action: datum.content ?? '',
      isPartner: true,
    )).toList();
  }

  // 获取设备信息
  String get deviceModel => phoneHistoryModel.value?.mobileLocationInfo?.mobileModel ?? '未知';
  String get batteryLevel => phoneHistoryModel.value?.mobileLocationInfo?.power ?? '未知';
  String get networkName => phoneHistoryModel.value?.mobileLocationInfo?.networkName ?? '未知';
  String get distance => phoneHistoryModel.value?.mobileLocationInfo?.distance ?? '';
  String get updateTime => phoneHistoryModel.value?.mobileLocationInfo?.calculateLocationTime ?? '';

}

// 用机记录数据模型
class PhoneUsageRecord {
  final String time;
  final String action;
  final bool isPartner;

  PhoneUsageRecord({
    required this.time,
    required this.action,
    required this.isPartner,
  });
}
