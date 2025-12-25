import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog_controller.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import '../track_controller.dart';
import '../component/stop_list_page.dart';
import '../widgets/track_date_selector.dart';
import '../track_page_config.dart';

/// 滑动面板管理器
/// 负责管理轨迹页面的滑动面板逻辑和内容
class TrackSheetManager {
  final TrackController controller;
  late double screenHeight = 0;
  late double maxHeight = 0;
  late final DraggableScrollableController draggableController;

  TrackSheetManager({
    required this.controller,
  }) {
    _initializeDimensions();
    draggableController = DraggableScrollableController();
    controller.setDraggableController(draggableController);
  }

  void _initializeDimensions() {
    // 这里会在didChangeDependencies中初始化
    screenHeight = 0;
    maxHeight = 0;
  }

  void updateDimensions(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    maxHeight = screenHeight - TrackPageConfig.maxPanelOffset;

    // 初始化sheetPercent
    controller.sheetPercent.value = getInitialHeight() / screenHeight;
  }

  /// 获取面板初始高度
  double getInitialHeight() {
    return TrackPageConfig.getInitialHeight(
      isBindPartner: controller.isBindPartner.value,
      isVip: UserManager.isVip,
    );
  }

  /// 获取面板最小高度
  double getMinHeight() {
    return TrackPageConfig.getMinHeight(
      isBindPartner: controller.isBindPartner.value,
      isVip: UserManager.isVip,
    );
  }

  /// 获取中间吸顶位置
  double getMiddleSnapSize() {
    return TrackPageConfig.getMiddleSnapSize(
      isBindPartner: controller.isBindPartner.value,
      screenHeight: screenHeight,
    );
  }

  /// 监听面板滑动百分比变化
  void onSheetPercentChanged(double extent) {
    // 这里可以添加埋点逻辑
    logDebug('面板滑动百分比: $extent', tag: 'TrackSheetManager');
  }

  /// 构建可拖动面板
  Widget buildDraggableSheet() {
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        controller.sheetPercent.value = notification.extent;
        onSheetPercentChanged(notification.extent);
        return true;
      },
      child: Builder(
        builder: (context) {
          return Obx(() {
            final middleSnapSize = getMiddleSnapSize();
            final isVip = UserManager.isVip;
            final isBindPartner = controller.isBindPartner.value;
            final isViewingPartner = controller.isOneself.value == 0;
            final shouldLimitDrag = !isVip && isViewingPartner && isBindPartner;

            return DraggableScrollableSheet(
              controller: draggableController,
              initialChildSize: getInitialHeight() / screenHeight,
              minChildSize: shouldLimitDrag
                  ? getInitialHeight() / screenHeight
                  : getMinHeight() / screenHeight,
              maxChildSize: shouldLimitDrag
                  ? getInitialHeight() / screenHeight
                  : maxHeight / screenHeight,
              snap: true,
              snapSizes: shouldLimitDrag
                  ? null
                  : [middleSnapSize, maxHeight / screenHeight],
              snapAnimationDuration: TrackPageConfig.sheetSnapAnimation,
              builder: (context, scrollController) {
                controller.setListScrollController(scrollController);
                return _buildSheetContent(scrollController);
              },
            );
          });
        },
      ),
    );
  }

  /// 构建面板内容
  Widget _buildSheetContent(ScrollController scrollController) {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: TrackPageConfig.backgroundWhite,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(TrackPageConfig.panelTopBorderRadiusValue),
              ),
            ),
            child: Stack(
              children: [
                // 主要内容
                _buildMainContent(scrollController),
                // VIP蒙版层
                _buildVipMask(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建主要内容
  Widget _buildMainContent(ScrollController scrollController) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: TrackPageConfig.panelTopBorderRadiusGeometry,
        gradient: TrackPageConfig.panelGradient,
      ),
      padding: const EdgeInsets.only(top: TrackPageConfig.tinyPadding),
      child: Column(
        children: [
          // 指示条
          _buildIndicator(),
          const SizedBox(height: TrackPageConfig.tinyPadding),
          // 内容区域
          Expanded(
            child: CustomScrollView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              cacheExtent: 500,
              slivers: [
                // 顶部固定区域
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // 日期模块
                      _buildDateModule(),
                      const SizedBox(height: 10),
                      // 停留统计模块
                      _buildStayStatsModule(),
                    ],
                  ),
                ),
                // 停留点列表
                _buildStopRecordsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建指示条
  Widget _buildIndicator() {
    return Container(
      width: TrackPageConfig.indicatorWidth,
      height: TrackPageConfig.indicatorHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TrackPageConfig.indicatorBorderRadius),
        color: TrackPageConfig.borderGray,
      ),
    );
  }

  /// 构建日期模块
  Widget _buildDateModule() {
    return Obx(() {
      if (controller.isBindPartner.value) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: TrackPageConfig.horizontalMargin),
          decoration: BoxDecoration(
            borderRadius: TrackPageConfig.defaultBorderRadius,
            color: TrackPageConfig.backgroundWhite,
          ),
          child: TrackDateSelector(
            selectedIndex: controller.selectedDateIndex,
            isBind: controller.isBindPartner.value,
            onSelect: (date) => controller.selectDate(date),
            showBorder: true,
            unselectedBorderColor: TrackPageConfig.borderGray,
            selectedBackgroundColor: TrackPageConfig.primaryPink,
            selectedTextColor: TrackPageConfig.backgroundWhite,
            unselectedTextColor: const Color(0x99333333),
            height: 65,
            borderRadius: TrackPageConfig.panelBorderRadius,
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
        );
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 65,
        child: Container(
          decoration: BoxDecoration(
            color: TrackPageConfig.backgroundWhite,
            borderRadius: TrackPageConfig.defaultBorderRadius,
          ),
          child: TrackDateSelector(
            selectedIndex: controller.selectedDateIndex,
            isBind: controller.isBindPartner.value,
            onSelect: (date) => controller.selectDate(date),
            showBorder: true,
            unselectedBorderColor: TrackPageConfig.borderGray,
            selectedBackgroundColor: TrackPageConfig.primaryPink,
            selectedTextColor: TrackPageConfig.backgroundWhite,
            unselectedTextColor: const Color(0x99333333),
            height: 65,
            borderRadius: TrackPageConfig.panelBorderRadius,
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
      );
    });
  }

  /// 构建停留统计模块
  Widget _buildStayStatsModule() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: TrackPageConfig.horizontalMargin),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: TrackPageConfig.defaultBorderRadius,
        color: TrackPageConfig.backgroundWhite,
      ),
      child: _buildStatisticsRow(),
    );
  }

  /// 构建统计栏
  Widget _buildStatisticsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 20,
        children: [
          Obx(() => _buildStat(
                "停留次数",
                controller.stayCount.value.toString(),
                "次",
                icon: Icons.location_on,
                color: const Color(0xFFFF6B6B),
              )),
          Container(
            width: 1,
            height: 27,
            color: const Color(0x4d000000),
          ),
          Obx(() => _buildStat(
                "停留时长",
                controller.stayDuration.value.isEmpty
                    ? "0分钟"
                    : controller.stayDuration.value,
                "",
                icon: Icons.access_time,
                color: const Color(0xFF4ECDC4),
              )),
          Container(
            width: 1,
            height: 27,
            color: const Color(0x4d000000),
          ),
          Obx(() => _buildStat(
                "移动距离",
                controller.moveDistance.value.isEmpty
                    ? "0.0km"
                    : controller.moveDistance.value,
                "米",
                icon: Icons.directions_walk,
                color: const Color(0xFF45B7D1),
              )),
        ],
      ),
    );
  }

  /// 构建单个统计项
  Widget _buildStat(String label, String value, String unit,
      {IconData? icon, Color? color}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: TrackPageConfig.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  color: TrackPageConfig.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                unit,
                style: const TextStyle(fontSize: 13, color: TrackPageConfig.textPrimary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建停留点列表
  Widget _buildStopRecordsList() {
    return Obx(() {
      if (controller.stopRecords.isEmpty) {
        return SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.only(
              left: TrackPageConfig.horizontalMargin,
              right: TrackPageConfig.horizontalMargin,
              top: 10,
              bottom: 15,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: TrackPageConfig.defaultPadding,
              vertical: 15,
            ),
            decoration: BoxDecoration(
              color: TrackPageConfig.backgroundWhite,
              borderRadius: TrackPageConfig.defaultBorderRadius,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/kissu_track_empty.webp',
                    width: 133,
                    height: 96,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '目前还没有足迹哦～',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xff777777),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        return SliverFillRemaining(
          child: Container(
            margin: const EdgeInsets.only(
              left: TrackPageConfig.horizontalMargin,
              right: TrackPageConfig.horizontalMargin,
              top: 10,
              bottom: 15,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: TrackPageConfig.defaultPadding,
              vertical: 15,
            ),
            decoration: BoxDecoration(
              color: TrackPageConfig.backgroundWhite,
              borderRadius: TrackPageConfig.defaultBorderRadius,
            ),
            child: _OptimizedStopRecordsListWithBackground(controller: controller),
          ),
        );
      }
    });
  }

  /// 构建VIP蒙版层
  Widget _buildVipMask() {
    return Obx(() {
      final isBindPartner = controller.isBindPartner.value;
      final isVip = UserManager.isVip;
      final shouldShowMask = !isBindPartner || (isBindPartner && !isVip);

      if (!shouldShowMask) return const SizedBox.shrink();

      return Positioned.fill(
        child: Stack(
          children: [
            // 蒙版内容层
            AbsorbPointer(
              child: Column(
                children: [
                  const SizedBox(height: TrackPageConfig.tinyPadding),
                  _buildIndicator(),
                  const SizedBox(height: TrackPageConfig.tinyPadding),
                  _buildDateModule(),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: TrackPageConfig.panelTopBorderRadiusGeometry,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF).withValues(alpha: 0.2),
                            borderRadius: TrackPageConfig.panelTopBorderRadiusGeometry,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 130),
                                SizedBox(
                                  width: 175,
                                  height: 44,
                                  child: Text('按钮占位'),
                                ),
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
            // 按钮层
            Positioned.fill(
              child: IgnorePointer(
                ignoring: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 130),
                      GestureDetector(
                        onTap: () async {
                          if (!isBindPartner) {
                            if (Get.context!.mounted) {
                              CustomBottomDialog.show(
                                context: Get.context!,
                                caller: BindingDialogCaller.track,
                              ).then((_) {
                                controller.refreshCurrentUserData();
                              });
                            }
                          } else {
                            Get.toNamed(
                              KissuRoutePath.vip,
                              arguments: {
                                'previousPageName': '足迹页面',
                                'previousPageId': 'footprint_page',
                              },
                            );
                          }
                        },
                        child: Image.asset(
                          !isBindPartner
                              ? 'assets/images/kissu3_go_bind.webp'
                              : 'assets/images/kissu3_go_vip.webp',
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
    });
  }
}

/// 优化的停留记录列表组件（复用原有逻辑）
class _OptimizedStopRecordsListWithBackground extends StatelessWidget {
  final TrackController controller;

  const _OptimizedStopRecordsListWithBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final records = controller.stopRecords;
      final isLoading = controller.isLoading.value;

      return SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            if (isLoading) ...[
              // 骨架屏逻辑（保持原有实现）
            ] else if (records.isNotEmpty) ...[
              ...records.asMap().entries.map((entry) {
                final index = entry.key;
                final record = entry.value;
                final isLast = index == records.length - 1;
                return RepaintBoundary(
                  child: StopListItem(
                    record: record,
                    index: index,
                    isLast: isLast,
                  ),
                );
              }),
            ] else ...[
              // 空状态
            ],
          ],
        ),
      );
    });
  }
}
