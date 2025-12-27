import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';
import '../location_v2_controller.dart';
import 'device_info_section.dart';
import 'location_info_section.dart';
import 'mask_device_info_widget.dart';
import 'location_records_list_widget.dart';

/// 定位页面下半屏管理器
/// 负责管理可拖拽面板及其内容
class LocationSheetManager {
  final LocationV2Controller controller;
  late double screenHeight;
  late double maxHeight;
  late double topBarHeight;
  late DraggableScrollableController _draggableController;
  ScrollController? _scrollController;

  /// 获取当前的ScrollController，用于返回按钮
  ScrollController? get scrollController => _scrollController;

  LocationSheetManager({required this.controller});

  /// 更新屏幕尺寸参数
  void updateDimensions(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    topBarHeight = MediaQuery.of(context).padding.top + 35;
    maxHeight = screenHeight - topBarHeight;
    _draggableController = DraggableScrollableController();
    controller.setDraggableController(_draggableController);

    // 初始化sheetPercent为正确的初始值
    controller.sheetPercent.value = _calculateInitialHeight() / screenHeight;
  }

  /// 计算初始高度
  double _calculateInitialHeight() {
    final isBindPartner = controller.isBindPartner.value;
    final isVip = controller.isVip.value;
    return (!isBindPartner || !isVip) ? 310 : 190;
  }

  /// 计算最小高度
  double _calculateMinHeight() {
    final isBindPartner = controller.isBindPartner.value;
    final isVip = controller.isVip.value;
    return (!isBindPartner || !isVip) ? 310 : 190;
  }

  /// 计算渐变透明度 (从底部吸顶到顶部吸顶时透明度从1.0变为0.0)
  double get _gradientOpacity {
    final currentPercent = controller.sheetPercent.value;
    final minPercent = _calculateMinHeight() / screenHeight;
    final maxPercent = maxHeight / screenHeight;

    if (currentPercent <= minPercent) {
      return 1.0; // 底部吸顶位置，完全不透明
    } else if (currentPercent >= maxPercent) {
      return 0.0; // 顶部吸顶位置，完全透明
    } else {
      // 在中间位置时线性插值
      return 1.0 - ((currentPercent - minPercent) / (maxPercent - minPercent));
    }
  }

  /// 构建可拖拽面板
  Widget buildDraggableSheet() {
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        controller.sheetPercent.value = notification.extent;
        return true;
      },
      child: Builder(
        builder: (context) {
          return Obx(() {
            final isVip = controller.isVip.value;
            final isViewingPartner = controller.isOneself.value == 0;
            final isBindPartner = controller.isBindPartner.value;
            final shouldLimitDrag = !isVip && isViewingPartner && isBindPartner;
            final middleSnapSize = isBindPartner
                ? 0.5 + (21 / screenHeight)
                : 0.5 + (57 / screenHeight);

            return DraggableScrollableSheet(
              controller: _draggableController,
              initialChildSize: _calculateInitialHeight() / screenHeight,
              minChildSize: shouldLimitDrag
                  ? _calculateInitialHeight() / screenHeight
                  : _calculateMinHeight() / screenHeight,
              maxChildSize: shouldLimitDrag
                  ? _calculateInitialHeight() / screenHeight
                  : maxHeight / screenHeight,
              snap: true,
              snapSizes: shouldLimitDrag
                  ? null
                  : [middleSnapSize, (screenHeight - topBarHeight) / screenHeight],
              snapAnimationDuration: const Duration(milliseconds: 200),
              builder: (context, scrollController) {
                _scrollController = scrollController;
                return Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: Stack(
                          children: [
                            _buildScrollView(scrollController),
                            _buildVipMask(),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          });
        },
      ),
    );
  }

  /// 构建滚动视图
  Widget _buildScrollView(ScrollController scrollController) {
    return Obx(() {
      // 计算渐变起始颜色的透明度
      final gradientStartColor = Color(0xFFFFF1FD).withValues(alpha: _gradientOpacity);
      // 计算指示条的透明度
      final indicatorOpacity = _gradientOpacity;

      return NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification) {
            return true;
          }
          return false;
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
            ),
            gradient: LinearGradient(
              colors: [gradientStartColor, Color(0xFFF6F6F6), Color(0xFFF6F6F6)],
              stops: [0,0.1,1],
              begin: AlignmentGeometry.topCenter,
              end: AlignmentGeometry.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            children: [
              Opacity(
                opacity: indicatorOpacity,
                child: Container(
                  width: 46,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: const Color(0xFFffffff),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Expanded(
                child: CustomScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  cacheExtent: 500,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              DeviceInfoSection(controller: controller),
                              const SizedBox(height: 10),
                              LocationInfoSection(controller: controller),
                            ],
                          ),
                        ],
                      ),
                    ),
                    LocationRecordsListWidget(controller: controller),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// 构建VIP蒙版
  Widget _buildVipMask() {
    return Obx(() {
      final isBindPartner = controller.isBindPartner.value;
      final isVip = controller.isVip.value;

      // 未绑定 或 已绑定但未开会员时显示蒙版
      final shouldShowMask = !isBindPartner || (isBindPartner && !isVip);

      if (shouldShowMask) {
        return Positioned.fill(
          child: Stack(
            children: [
              // 蒙版内容层：使用 AbsorbPointer 阻止触摸事件穿透
              AbsorbPointer(
                child: Column(
                  children: [
                    // 顶部占位：与指示条高度对齐
                    const SizedBox(height: 17),
                    // 设备信息模块（白色背景，显示设备型号、电量、网络）
                    MaskDeviceInfoWidget(controller: controller),
                    const SizedBox(height: 10),
                    // 蒙版整体
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF).withValues(alpha: 0.2),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 40),
                                  // 文字图片
                                  Image.asset(
                                    'assets/images/kissu3_go_label.webp',
                                    width: 187,
                                    height: 32,
                                    fit: BoxFit.contain,
                                  ),
                                   // 按钮占位
                                  // SizedBox(width: 175, height: 44),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 按钮层：允许点击
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (controller.isBindPartner.value &&
                            controller.partnerOnlineStatus.value !=
                                null &&
                            controller
                                    .partnerOnlineStatus
                                    .value!
                                    .status ==
                                0)
                          const SizedBox(height: 175)
                        else
                          const SizedBox(height: 140),
                        GestureDetector(
                          onTap: () async {
                            if (!isBindPartner) {
                              // 未绑定：显示绑定弹窗
                              controller.performBindAction();
                            } else {
                              // 已绑定但未开会员：跳转到VIP页面
                              controller.onOpenMembershipButtonTap();
                            }
                          },
                          child: Image.asset(
                            !isBindPartner
                                ? 'assets/images/kissu3_go_bind.webp' // 未绑定
                                : 'assets/images/kissu3_go_vip.webp', // 已绑定未开会员
                            width: !isBindPartner ? 175 : 189,
                            height: !isBindPartner ? 44 : 60,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }
}
