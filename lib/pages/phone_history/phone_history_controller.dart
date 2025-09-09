import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kissu_app/model/phone_history_model/phone_history_model.dart';
import 'package:kissu_app/model/phone_history_model/datum.dart';
import 'package:kissu_app/network/public/phone_history_api.dart';
import 'package:kissu_app/widgets/dialogs/binding_input_dialog.dart';
import 'package:kissu_app/pages/mine/mine_controller.dart';
import 'phone_history_setting_dialog.dart';

class PhoneHistoryController extends GetxController {
  final _api = PhoneHistoryApi();
  
  // PageView相关
  late PageController pageController;
  final currentPageIndex = 6.obs; // 默认显示今天（最右边）
  
  // 是否绑定情侣
  final isBinding = true.obs;
  
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
    // 初始加载数据
    loadData();
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
    
    // 加载对应日期的数据
    _currentPage = 1;
    isDateLoading.value = true;
    loadData(isRefresh: true).then((_) {
      isDateLoading.value = false;
    });
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
        
        // 更新绑定状态
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
        print('加载失败: ${result.msg}');
      }
    } catch (e) {
      print('加载数据异常: $e');
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
        print('加载更多失败: ${result.msg}');
      }
    } catch (e) {
      _currentPage--; // 回滚页码
      print('加载更多异常: $e');
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

  void showTooltip(String text, Offset position) {
    hideTooltip(); // 先移除旧的

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
                        text,
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
  void showSettingDialog() {
    PhoneHistorySettingDialog.show();
  }

  /// 显示绑定弹窗
  void showBindingDialog() async {
    final result = await BindingInputDialog.show(context: pageContext);
    if (result == true) {
      // 绑定成功后刷新当前页面数据
      await loadData(isRefresh: true);
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
    if (!isBinding.value || recordList.isEmpty) return [];

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
