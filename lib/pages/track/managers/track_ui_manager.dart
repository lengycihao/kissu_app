import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/utils/debug_util.dart';

/// 轨迹页面UI管理器
/// 负责底部面板控制、动画管理、日期选择器等UI状态管理
class TrackUIManager extends GetxController with GetTickerProviderStateMixin {
  /// 返回按钮旋转状态
  final isBackButtonRotated = false.obs;
  
  /// 返回按钮动画控制器
  late AnimationController backButtonAnimationController;
  late Animation<double> backButtonRotationAnimation;
  
  /// 日期选择器的选中索引（0-6，对应最近7天）
  final selectedDateIndex = 6.obs; // 默认选择今天（最右边）
  
  final recentDays = List.generate(7, (i) {
    final date = DateTime.now().subtract(Duration(days: i));
    return "${date.month}-${date.day}";
  }).obs;
  
  final selectedDayIndex = 0.obs;
  final sheetPercent = 0.3.obs;
  
  /// 底部面板控制器
  DraggableScrollableController? _draggableController;
  
  /// 停留点列表的ScrollController
  ScrollController? _listScrollController;
  
  @override
  void onInit() {
    super.onInit();
    // 初始化返回按钮动画控制器
    _initBackButtonAnimation();
    
    // 监听下半屏滑动位置变化
    _listenToSheetChanges();
  }
  
  /// 初始化返回按钮动画控制器
  void _initBackButtonAnimation() {
    backButtonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    backButtonRotationAnimation = Tween<double>(
      begin: 0.0,
      end: -0.25, // -90度 (逆时针旋转90度)
    ).animate(CurvedAnimation(
      parent: backButtonAnimationController,
      curve: Curves.easeInOut,
    ));
  }
  
  /// 监听下半屏滑动位置变化
  void _listenToSheetChanges() {
    sheetPercent.listen((percent) {
      // 当滑动到顶部吸顶位置时（约0.85以上），触发按钮旋转
      final topThreshold = 0.85;
      
      if (percent >= topThreshold && !isBackButtonRotated.value) {
        // 滑动到顶部，按钮逆时针旋转90度
        isBackButtonRotated.value = true;
        backButtonAnimationController.forward();
      } else if (percent < topThreshold && isBackButtonRotated.value) {
        // 滑动离开顶部，按钮顺时针旋转回原位
        isBackButtonRotated.value = false;
        backButtonAnimationController.reverse();
      }
    });
  }
  
  /// 处理旋转状态下的返回按钮点击
  void handleBackButtonTap([ScrollController? scrollController]) {
    if (isBackButtonRotated.value) {
      // 如果按钮已旋转，将下半屏回滚到底部，并重置ScrollView
      _scrollToBottom(scrollController);
    } else {
      // 正常返回
      Get.back();
    }
  }
  
  /// 将下半屏滚动到底部
  void _scrollToBottom([ScrollController? scrollController]) {
    // 先将下半屏回滚到底部
    if (_draggableController != null) {
      _draggableController!.animateTo(
        0.3, // 回到初始位置
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ).then((_) {
        // 下半屏回滚完成后，再重置ScrollView到顶部
        if (scrollController != null && scrollController.hasClients) {
          scrollController.animateTo(
            0.0, // 滚动到顶部
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }
  
  /// 设置底部面板控制器
  void setDraggableController(DraggableScrollableController controller) {
    _draggableController = controller;
  }
  
  /// 设置停留点列表的ScrollController
  void setListScrollController(ScrollController? controller) {
    _listScrollController = controller;
  }
  
  /// 获取停留点列表的ScrollController
  ScrollController? getListScrollController() {
    return _listScrollController;
  }
  
  /// 智能展开底部面板到中间位置
  void expandToMiddlePosition() {
    if (_draggableController != null) {
      try {
        _draggableController!.animateTo(
          0.5, // 展开到中间位置
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        logDebug('🎯 智能展开底部面板到中间位置');
      } catch (e) {
        logError('❌ 展开底部面板失败: $e');
      }
    }
  }
  
  /// 收起底部面板到最小位置
  void collapseToMinPosition() {
    if (_draggableController != null) {
      try {
        _draggableController!.animateTo(
          0.3, // 收起到最小位置
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        logDebug('🎯 收起底部面板到最小位置');
      } catch (e) {
        logError('❌ 收起底部面板失败: $e');
      }
    }
  }

  /// 收起底部面板到底部吸顶位置（点击停留点时使用）
  void collapseToBottomPosition() {
    if (_draggableController != null) {
      try {
        // 计算底部吸顶位置（对应 snapSizes 中的第一个位置）
        const minHeight = 190.0;
        final screenHeight = Get.context != null ? MediaQuery.of(Get.context!).size.height : 800.0;
        final bottomSnapSize = minHeight / screenHeight;
        
        _draggableController!.animateTo(
          bottomSnapSize, // 收起到底部吸顶位置
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        logDebug('🎯 收起底部面板到底部吸顶位置');
      } catch (e) {
        logError('❌ 收起底部面板到底部位置失败: $e');
      }
    }
  }
  
  /// 更新日期选择器索引
  void updateDateIndex(int index) {
    if (index >= 0 && index < 7) {
      selectedDateIndex.value = index;
      logDebug('日期选择器索引更新为: $index');
    }
  }
  
  /// 获取选中的日期
  DateTime getSelectedDate() {
    final daysAgo = 6 - selectedDateIndex.value;
    return DateTime.now().subtract(Duration(days: daysAgo));
  }
  
  @override
  void onClose() {
    backButtonAnimationController.dispose();
    super.onClose();
  }
}
