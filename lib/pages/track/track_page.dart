import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:kissu_app/pages/track/component/stop_list_page.dart';
import 'package:kissu_app/widgets/safe_amap_widget.dart';
import 'package:kissu_app/widgets/smooth_avatar_widget.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/utils/debug_util.dart';
import 'package:kissu_app/pages/track/widgets/track_date_selector.dart';
import 'package:kissu_app/pages/track/widgets/track_replay_floating_button.dart';
import 'package:shimmer/shimmer.dart';
import 'track_controller.dart';
import 'package:kissu_app/services/tracking_service.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog_controller.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';

class TrackPage extends StatelessWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialLocationName;
  final String? initialDuration;
  final String? initialStartTime;
  final String? initialEndTime;
  final bool autoShowInfoWindow; // 🎯 新增：是否自动显示InfoWindow
  final int? targetUserType; // 目标用户类型 (1: 自己, 0: 另一半)

  const TrackPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialLocationName,
    this.initialDuration,
    this.initialStartTime,
    this.initialEndTime,
    this.autoShowInfoWindow = false, // 默认不自动显示
    this.targetUserType,
  });

  @override
  Widget build(BuildContext context) {
    // 🔧 修复：使用 Get.find 而不是 Get.put，让 TrackBinding 管理控制器生命周期
    // 如果控制器不存在，则创建一个临时的（这种情况不应该发生，因为使用了 TrackBinding）
    final controller = Get.isRegistered<TrackController>() 
        ? Get.find<TrackController>() 
        : Get.put(TrackController());

    // 如果有初始坐标，设置到控制器中
    if (initialLatitude != null && initialLongitude != null) {
      controller.setInitialCoordinates(
        latitude: initialLatitude!,
        longitude: initialLongitude!,
        locationName: initialLocationName,
        duration: initialDuration,
        startTime: initialStartTime,
        endTime: initialEndTime,
        targetUserType: targetUserType,
      );
    }

    return _TrackPageContent(controller: controller);
  }
}

// 将主要内容提取为单独的StatefulWidget以优化性能
class _TrackPageContent extends StatefulWidget {
  final TrackController controller;

  const _TrackPageContent({required this.controller});

  @override
  State<_TrackPageContent> createState() => _TrackPageContentState();
}

class _TrackPageContentState extends State<_TrackPageContent>
    with WidgetsBindingObserver {
  late final double screenHeight;
  late final double maxHeight;
  late final DraggableScrollableController _draggableController;
  ScrollController? _scrollController;
  
  /// 上一次的屏幕状态（小屏/中屏/大屏），用于判断状态是否改变
  String? _lastScreenState;

  // 动态计算 initialHeight 和 minHeight
  double get initialHeight {
    final isBindPartner = widget.controller.isBindPartner.value;
    final isVip = UserManager.isVip;
    // 未绑定或未开通会员时：280，已绑定且是会员时：190
    return (!isBindPartner || !isVip) ? 280 : 190;
  }

  double get minHeight {
    final isBindPartner = widget.controller.isBindPartner.value;
    final isVip = UserManager.isVip;
    // 未绑定或未开通会员时：280，已绑定且是会员时：190
    return (!isBindPartner || !isVip) ? 280 : 190;
  }

  double get mapHeight => screenHeight - initialHeight + 90;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // 移除生命周期观察者
    WidgetsBinding.instance.removeObserver(this);
    // 确保控制器被正确清理
    DebugUtil.info('轨迹页面即将销毁，触发控制器清理...');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      // 应用进入后台，暂停地图更新（释放资源）
      logDebug('🛤️ TrackPage: 应用进入后台，暂停地图更新', tag: 'TrackPage');
    } else if (state == AppLifecycleState.resumed) {
      // 应用恢复前台，恢复地图更新
      logDebug('🛤️ TrackPage: 应用恢复前台，恢复地图更新', tag: 'TrackPage');
    }
  }
  
  /// 监听滑动面板百分比变化，判断屏幕状态并上报埋点
  void _onSheetPercentChanged(double extent) {
    // 计算各个状态的阈值
    final minPercent = minHeight / screenHeight;  // 小屏（底部）
    final maxPercent = maxHeight / screenHeight;  // 大屏（顶部吸顶）
    
    // 中屏的阈值：介于小屏和大屏之间的中间位置（允许一定容差）
    // 判断逻辑：小屏和大屏各占 20% 的范围，中间 60% 的范围都算中屏
    final smallToMediumThreshold = minPercent + (maxPercent - minPercent) * 0.2;
    final mediumToLargeThreshold = minPercent + (maxPercent - minPercent) * 0.8;
    
    // 判断当前屏幕状态
    String currentState;
    if (extent <= smallToMediumThreshold) {
      currentState = '小屏';
    } else if (extent >= mediumToLargeThreshold) {
      currentState = '大屏';
    } else {
      currentState = '中屏';
    }
    
    // 只有当状态真正改变时才上报埋点（避免频繁上报）
    if (_lastScreenState != null && _lastScreenState != currentState) {
      _trackSwipeState(currentState);
    }
    
    // 更新上一次的状态
    _lastScreenState = currentState;
  }
  
  /// 上报滑动状态埋点
  Future<void> _trackSwipeState(String clickState) async {
    try {
      await TrackingService.trackFootprintPageSwipeState(
        clickState: clickState,
      );
      DebugUtil.info('✅ 足迹页面-滑动状态埋点上报成功: $clickState');
    } catch (e) {
      DebugUtil.error('❌ 足迹页面-滑动状态埋点上报失败: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在这里计算屏幕尺寸相关参数
    screenHeight = MediaQuery.of(context).size.height;
    // initialHeight 和 minHeight 将在 build 中根据状态动态计算
    maxHeight = screenHeight - 100;

    // 初始化底部面板控制器
    _draggableController = DraggableScrollableController();
    widget.controller.setDraggableController(_draggableController);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 固定的地图模块 - 全屏显示
          Positioned.fill(
            child: _CachedMapWidget(controller: widget.controller),
          ),

          // 背景遮罩层优化 - 减少重建频率
          Obx(() => _OptimizedOverlayWidget(
            controller: widget.controller,
            mapHeight: mapHeight,
            initialHeight: initialHeight,
            screenHeight: screenHeight,
          )),

          // 全屏渐变背景 - 从中间滑到顶部时显示
          Obx(() => _GradientBackgroundOverlay(
            controller: widget.controller,
            screenHeight: screenHeight,
            initialHeight: initialHeight,
            maxHeight: maxHeight,
          )),

          // 左侧浮动按钮组（刷新 + 切换地图）
          _LeftFloatingButtons(controller: widget.controller),

          // 右侧轨迹播放浮动按钮
          TrackReplayFloatingButton(
            controller: widget.controller,
            screenHeight: screenHeight,
          ),

          // 下半屏 DraggableScrollableSheet，扩大可拖动区域
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              widget.controller.sheetPercent.value = notification.extent;
              
              // 监听滑动状态变化并上报埋点
              _onSheetPercentChanged(notification.extent);
              
              return true;
            },
            child: Obx(() {
              // 🔧 使用固定的中间吸顶位置，不受切换头像影响
              // 根据实际绑定状态（而不是当前查看用户的状态）来确定位置
              final actualBindStatus = widget.controller.getActualBindStatus();
              final middleSnapSize = actualBindStatus
                  ? 0.5 +
                        (21 / screenHeight) // 已绑定：屏幕中间
                  : 0.5 + (57 / screenHeight); // 未绑定：稍微往上偏移42px（设备模块高度差）+ 35

              return DraggableScrollableSheet(
                controller: _draggableController,
                initialChildSize: initialHeight / screenHeight,
                minChildSize: minHeight / screenHeight,
                maxChildSize: maxHeight / screenHeight,
                snap: true, // 启用吸附效果
                snapSizes: [
                  minHeight / screenHeight, // 最小高度（底部位置）
                  middleSnapSize, // 🔧 动态中间位置（根据绑定状态调整）
                  (screenHeight - 100) / screenHeight, // 距离屏幕顶部100px
                ],
                snapAnimationDuration: const Duration(milliseconds: 200), // 缩短吸附动画时间
                builder: (context, scrollController) {
                  // 将scrollController保存到实例变量中，以便在返回按钮点击时使用
                  _scrollController = scrollController;
                  // 将scrollController传递给控制器，用于停留点点击时归位
                  widget.controller.setListScrollController(scrollController);
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
                              NotificationListener<ScrollNotification>(
                                onNotification: (notification) {
                                  if (notification is ScrollStartNotification) {
                                    widget.controller.setAnimationLock(false);
                                  }
                                  return false;
                                },
                                child: CustomScrollView(
                                  controller: scrollController,
                                  slivers: [
                                    // 顶部固定区域 - 前两个模块
                                    SliverToBoxAdapter(
                                      child: Column(
                                        children: [
                                          // 日期模块
                                          _buildDateModule(),
                                          const SizedBox(height: 10),
                                          // 停留次数时间模块
                                          _buildStayStatsModule(),
                                        ],
                                      ),
                                    ),

                                    // 停留点模块 + 背景色 - 使用 SliverFillRemaining 确保填充到底部
                                    SliverFillRemaining(
                                      hasScrollBody: false,
                                      child: Stack(
                                        children: [
                                          Container(
                                            margin: EdgeInsets.only(
                                              left: 14,
                                              right: 14,
                                              top: 10,
                                              bottom: 15,
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 15,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Obx(() {
                                              if (widget
                                                  .controller
                                                  .stopRecords
                                                  .isEmpty) {
                                                return Container(
                                                  width: double.infinity,
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: 40,
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Image.asset(
                                                        'assets/kissu_track_empty.webp',
                                                        width: 128,
                                                        height: 128,
                                                      ),
                                                      SizedBox(height: 16),
                                                      Text(
                                                        '对方目前还没有足迹内容哦～',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Color(
                                                            0xff666666,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }

                                              return _OptimizedStopRecordsListWithBackground(
                                                controller: widget.controller,
                                              );
                                            }),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 统一的蒙版层（未绑定 或 已绑定但未开会员）
                              _buildVipMask(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            }),
          ),

          // 地图logo - 悬浮在地图上，位置跟随下半屏移动
          _buildMapLogo(),

          // 顶部返回按钮（带旋转动画）
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: () => widget.controller.handleBackButtonTap(_scrollController),
                child: AnimatedBuilder(
                  animation: widget.controller.backButtonRotationAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: widget.controller.backButtonRotationAnimation.value * 2 * 3.14159, // 转换为弧度
                      child: Image.asset(
                        'assets/kissu_mine_back.webp',
                        width: 24,
                        height: 24,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          //顶部头像优化
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: _CachedAvatarRow(controller: widget.controller),
          ),
        ],
      ),
    );
  }

  // 统计栏组件
  Widget _buildStatisticsRow() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 1, vertical: 12),
      margin: EdgeInsets.symmetric(horizontal: 5),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx(
            () => _buildStat(
              "停留次数",
              widget.controller.stayCount.value.toString(),
              icon: Icons.location_on,
              color: Color(0xFFFF6B6B),
            ),
          ),

          Obx(
            () => _buildStat(
              "停留时间",
              widget.controller.stayDuration.value.isEmpty
                  ? "0分钟"
                  : widget.controller.stayDuration.value,
              icon: Icons.access_time,
              color: Color(0xFF4ECDC4),
            ),
          ),

          Obx(
            () => _buildStat(
              "移动距离",
              widget.controller.moveDistance.value.isEmpty
                  ? "0.0km"
                  : widget.controller.moveDistance.value,
              icon: Icons.directions_walk,
              color: Color(0xFF45B7D1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    String label,
    String value, {
    IconData? icon,
    Color? color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF333333),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF000000),
              // fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 日期选择器
  Widget _buildDateModule() {
    return Obx(() {
      // 如果已绑定，显示普通日期选择器
      if (widget.controller.isBindPartner.value) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 14),
          padding: EdgeInsets.only(bottom: 10, top: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: TrackDateSelector(
            selectedIndex: widget.controller.selectedDateIndex,
            isBind: widget.controller.isBindPartner.value,
            onSelect: (date) {
              widget.controller.selectDate(date);
            },
          ),
        );
      }

      // 未绑定时显示带背景图的绑定模块
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 14),
        height: 92,
         
        child: Stack(
          children: [
            // 日期选择器
            Positioned(
              left: 0,
              right: 0,
              // top: 49,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TrackDateSelector(
                  selectedIndex: widget.controller.selectedDateIndex,
                  isBind: widget.controller.isBindPartner.value,
                  onSelect: (date) {
                    widget.controller.selectDate(date);
                  },
                  showBorder: false,
                  selectedBackgroundColor: Color(0xFFFF74A0).withOpacity(0.8),
                  selectedTextColor: Colors.white,
                  unselectedTextColor: Color(0xff333333),
                  height: 50,
                  margin: EdgeInsets.symmetric(horizontal: 9, vertical: 10),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// 停留次数时间模块
  Widget _buildStayStatsModule() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 14),
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Color(0xffFFFAFA),
      ),
      child: _buildStatisticsRow(),
    );
  }

  /// 上报开通会员按钮埋点
  Future<void> _trackOpenMembershipButton() async {
    try {
      // 上报新版埋点：足迹-立刻开通会员
      await TrackingService.trackTrackToVip();
      DebugUtil.info('✅ 足迹页面-立刻开通会员埋点上报成功');
    } catch (e) {
      DebugUtil.error('❌ 足迹页面-立刻开通会员埋点上报失败: $e');
    }
  }

  /// 上报立即去绑定按钮埋点
  Future<void> _trackBindNowButton() async {
    try {
      // 上报新版埋点：足迹-立刻去绑定
      await TrackingService.trackTrackToBind();
      DebugUtil.info('✅ 足迹页面-立刻去绑定埋点上报成功');
    } catch (e) {
      DebugUtil.error('❌ 足迹页面-立刻去绑定埋点上报失败: $e');
    }
  }

  /// 统一的蒙版层（未绑定 或 已绑定但未开会员）
  Widget _buildVipMask() {
    return Obx(() {
      final isBindPartner = widget.controller.isBindPartner.value;
      final isVip = UserManager.isVip;
      
      // 未绑定 或 已绑定但未开会员时显示蒙版
      final shouldShowMask = !isBindPartner || (isBindPartner && !isVip);
      
      if (shouldShowMask) {
        return Positioned.fill(
          child: Column(
            children: [
              // 顶部日期组件（清晰的，不模糊）
              _buildDateModule(),
              const SizedBox(height: 10),
              // 原来的蒙版整体
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF).withOpacity(0.2),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 文字图片
                            Image.asset(
                              'assets/kissu3_go_label.webp',
                              width: 216,
                              height: 32,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 20),
                            // 按钮
                            GestureDetector(
                              onTap: () async {
                                if (!isBindPartner) {
                                  // 未绑定：显示绑定弹窗
                                  await _trackBindNowButton();
                                  if (mounted && context.mounted) {
                                    CustomBottomDialog.show(
                                      context: context,
                                      caller: BindingDialogCaller.track,
                                    ).then((_) {
                                      widget.controller.refreshCurrentUserData();
                                    });
                                  }
                                } else {
                                  // 已绑定但未开会员：跳转到VIP页面
                                  await _trackOpenMembershipButton();
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
                                    ? 'assets/kissu3_go_bind.webp'  // 未绑定
                                    : 'assets/kissu3_go_vip.webp',  // 已绑定未开会员
                                width: 150,
                                height: 48,
                                fit: BoxFit.contain,
                              ),
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
        );
      }
      return const SizedBox.shrink();
    });
  }

  // 地图logo - 悬浮在地图上，位置在右侧轨迹回放按钮下方，跟随下半屏滑动
  Widget _buildMapLogo() {
    return Obx(() {
      // 🔧 修复：跟随下半屏滑动，与定位页面保持一致
      final sheetHeight = screenHeight * widget.controller.sheetPercent.value;
      
      // 右侧轨迹回放按钮的bottom位置
      final buttonBottom = sheetHeight + 70;
      
      // logo在按钮下方，按钮高度50px
      final logoBottom = buttonBottom - 50 - 15;
      
      // 根据绑定状态动态计算中间吸顶位置
      final actualBindStatus = widget.controller.getActualBindStatus();
      final middleSnapSize = actualBindStatus
          ? 0.5 + (21 / screenHeight)
          : 0.5 + (57 / screenHeight);
      final maxPercent = (screenHeight - 100) / screenHeight;
      
      // 计算透明度（与轨迹回放按钮同步）
      final sheetPercent = widget.controller.sheetPercent.value;
      double opacity;
      if (sheetPercent <= middleSnapSize) {
        opacity = 1.0;
      } else if (sheetPercent >= maxPercent) {
        opacity = 0.0;
      } else {
        opacity = 1.0 - ((sheetPercent - middleSnapSize) / (maxPercent - middleSnapSize));
      }
      opacity = opacity.clamp(0.0, 1.0);
      
      return Positioned(
        bottom: logoBottom,
        right: 16,
        child: Opacity(
          opacity: opacity,
          child: Image.asset(
            'assets/map_logo.webp',
            width: 68,
            height: 22,
          ),
        ),
      );
    });
  }
}// 优化的遮罩层Widget - 减少重建频率
class _OptimizedOverlayWidget extends StatelessWidget {
  final TrackController controller;
  final double mapHeight;
  final double initialHeight;
  final double screenHeight;

  const _OptimizedOverlayWidget({
    required this.controller,
    required this.mapHeight,
    required this.initialHeight,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 计算遮罩透明度：从 0 到 0.4
      final opacity =
          (controller.sheetPercent.value - (initialHeight / screenHeight)) *
          0.6;

      return Positioned.fill(
        child: IgnorePointer(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 100),
            opacity: opacity.clamp(0.0, 0.4),
            child: Container(color: Colors.black.withValues(alpha: 1.0)),
          ),
        ),
      );
    });
  }
}

// 高性能地图Widget - 减少不必要的重建
class _CachedMapWidget extends StatefulWidget {
  final TrackController controller;

  const _CachedMapWidget({required this.controller});

  @override
  State<_CachedMapWidget> createState() => _CachedMapWidgetState();
}

class _CachedMapWidgetState extends State<_CachedMapWidget> {
  // 缓存地图元素，避免频繁重建
  Set<Marker> _cachedMarkers = {};
  Set<Polyline> _cachedPolylines = {};
  int _markersVersion = -1;
  int _polylinesVersion = -1;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 检查标记是否需要更新
      final currentMarkersVersion =
          widget.controller.stopMarkers.length +
          widget.controller.trackStartEndMarkers.length +
          (widget.controller.tempInfoWindowMarker != null ? 10000 : 0); // 检测临时标记变化
      if (currentMarkersVersion != _markersVersion) {
        _updateMarkers();
        _markersVersion = currentMarkersVersion;
      }

      // 检查轨迹线是否需要更新
      final currentPolylinesVersion = widget.controller.hasValidTrackData.value
          ? widget.controller.trackPoints.length
          : 0;
      if (currentPolylinesVersion != _polylinesVersion) {
        _updatePolylines();
        _polylinesVersion = currentPolylinesVersion;
      }

      return SafeAMapWidget(
        initialCameraPosition: widget.controller.initialCameraPosition,
        onMapCreated: widget.controller.onMapCreated,
        markers: _cachedMarkers,
        polylines: _cachedPolylines,
        circles: widget.controller.highlightCircles.toSet(),
        mapType: widget.controller.mapType.value == 1
            ? MapType.normal
            : MapType.satellite,
        buildingsEnabled: false, // 隐藏3D建筑物
        compassEnabled: true,
        scaleEnabled: true,
        zoomGesturesEnabled: true,
        scrollGesturesEnabled: true,
        rotateGesturesEnabled: true,
        tiltGesturesEnabled: true,
        onTap: (LatLng position) {
          widget.controller.clearMapHighlights();
        },
        onInfoWindowClose: () {
          // 上报关闭埋点
          _trackInfoWindowClose();
          widget.controller.clearAllHighlightCircles();
        },
      );
    });
  }

  /// 更新标记缓存
  void _updateMarkers() {
    final newMarkers = <Marker>{};

    try {
      newMarkers.addAll(widget.controller.stopMarkers);
      newMarkers.addAll(widget.controller.trackStartEndMarkers);
    } catch (e) {
      DebugUtil.error('添加标记失败: $e');
    }

    
    // 添加临时 InfoWindow 标记（如果存在）
    if (widget.controller.tempInfoWindowMarker != null) {
      try {
        newMarkers.add(widget.controller.tempInfoWindowMarker!);
        DebugUtil.info('✅ 已添加临时 InfoWindow 标记到地图缓存');
      } catch (e) {
        DebugUtil.error('添加临时 InfoWindow 标记失败: $e');
      }
    }

    _cachedMarkers = newMarkers;
  }
  
  /// 上报 InfoWindow 关闭埋点
  Future<void> _trackInfoWindowClose() async {
    try {
      await TrackingService.trackFootprintStayCloseButton();
      DebugUtil.info('✅ 足迹页面-停留位置关闭按钮埋点上报成功');
    } catch (e) {
      DebugUtil.error('❌ 足迹页面-停留位置关闭按钮埋点上报失败: $e');
    }
  }

  void _updatePolylines() {
    final newPolylines = <Polyline>{};

    try {
      final trackPoints = widget.controller.trackPoints.toList();
      
      if (widget.controller.hasValidTrackData.value &&
          trackPoints.length >= 2) {
        const int maxPointsPerSegment = 100;
        
        if (trackPoints.length <= maxPointsPerSegment) {
          newPolylines.add(
            Polyline(
              points: trackPoints,
              color: const Color(0xdd639DFF),
              width: 6,
            ),
          );
        } else {
          for (int i = 0; i < trackPoints.length - 1; i += maxPointsPerSegment - 1) {
            final endIndex = (i + maxPointsPerSegment).clamp(0, trackPoints.length);
            final segmentPoints = trackPoints.sublist(i, endIndex);
            
            if (segmentPoints.length >= 2) {
              newPolylines.add(
                Polyline(
                  points: segmentPoints,
                  color: const Color(0xdd639DFF),
                  width: 6,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      DebugUtil.error('创建轨迹线失败: $e');
    }

    _cachedPolylines = newPolylines;
  }
}

// 优化的头像行Widget
class _CachedAvatarRow extends StatelessWidget {
  final TrackController controller;

  const _CachedAvatarRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 未绑定时不展示任何头像
      if (!controller.isBindPartner.value) {
        return const SizedBox.shrink();
      }
      
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 显示另一半头像（左边）
          _AvatarButton(
            controller: controller,
            isMyself: false,
            onTap: () {
              if (controller.isOneself.value != 0) {
                // 直接调用onAvatarTapped，让controller内部处理状态更新和地图移动
                controller.onAvatarTapped(false);
                // 添加触觉反馈
                HapticFeedback.lightImpact();
                logDebug('🎯 头像点击：切换到查看另一半的轨迹数据', tag: 'TrackPage');
              }
            },
          ),
          const SizedBox(width: 8),
          // 显示自己的头像（右边）
          _AvatarButton(
            controller: controller,
            isMyself: true,
            onTap: () {
              if (controller.isOneself.value != 1) {
                // 直接调用onAvatarTapped，让controller内部处理状态更新和地图移动
                controller.onAvatarTapped(true);
                // 添加触觉反馈
                HapticFeedback.lightImpact();
                logDebug('🎯 头像点击：切换到查看自己的轨迹数据', tag: 'TrackPage');
              }
            },
          ),
        ],
      );
    });
  }
}

// 优化的头像按钮Widget
class _AvatarButton extends StatefulWidget {
  final TrackController controller;
  final bool isMyself;
  final VoidCallback onTap;

  const _AvatarButton({
    required this.controller,
    required this.isMyself,
    required this.onTap,
  });

  @override
  State<_AvatarButton> createState() => _AvatarButtonState();
}

class _AvatarButtonState extends State<_AvatarButton> {
  bool _isAvatarLoaded = false;

  @override
  Widget build(BuildContext context) {
    // iOS风格尺寸定义
    const selectedSize = 32.0;  // 选中时的尺寸
    const unselectedSize = 25.0;  // 未选中时的尺寸
    const selectedRadius = 12.0;  // 选中时的圆角
    const unselectedRadius = 9.0;  // 未选中时的圆角

    return Obx(() {
      final currentIsOneselfValue = widget.controller.isOneself.value;
      final isSelected = (widget.isMyself && currentIsOneselfValue == 1) ||
          (!widget.isMyself && currentIsOneselfValue == 0);

      // iOS风格：直接根据选中状态确定尺寸，而不是用scale
      final actualSize = (isSelected && _isAvatarLoaded) ? selectedSize : unselectedSize;
      final cornerRadius = (isSelected && _isAvatarLoaded) ? selectedRadius : unselectedRadius;

      final avatarUrl = widget.isMyself
          ? widget.controller.myAvatar.value
          : widget.controller.partnerAvatar.value;

      return GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // iOS风格弹簧动画：duration 300ms, Spring curve (damping 0.7)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut, // 使用 easeOut 避免产生负值
              width: actualSize,
              height: actualSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(cornerRadius),
                border: (isSelected && _isAvatarLoaded)
                    ? Border.all(color: const Color(0xFFFF88AA), width: 1)
                    : null,
                boxShadow: (isSelected && _isAvatarLoaded)
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF88AA).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: SmoothAvatarWidget(
                avatarUrl: avatarUrl.isNotEmpty ? avatarUrl : null,
                defaultAsset: '',
                width: actualSize,
                height: actualSize,
                borderRadius: BorderRadius.circular(cornerRadius - 1),
                fit: BoxFit.cover,
                onImageLoaded: () {
                  setState(() {
                    _isAvatarLoaded = true;
                  });
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}
// 带背景图片渐隐渐现效果的停留记录列表Widget
class _OptimizedStopRecordsListWithBackground extends StatelessWidget {
  final TrackController controller;

  const _OptimizedStopRecordsListWithBackground({required this.controller});

  /// 构建 Shimmer 加载占位列表
  Widget _buildShimmerLoadingList() {
    return Column(
      children: List.generate(5, (index) => _buildShimmerItem()),
    );
  }

  /// 构建单个 Shimmer 占位项（模拟 StopListItem 的布局）
  Widget _buildShimmerItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFFE0E0E0),
        highlightColor: const Color(0xFFF5F5F5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左边时间部分
            Container(
              width: 40,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // 时间轴圆点
            Container(
              width: 20,
              margin: const EdgeInsets.symmetric(horizontal: 0),
              child: Center(
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            // 内容部分
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 地点名称
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 11),
                  // 粉色渐变卡片
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 停留时长
                        Container(
                          width: 100,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // 时间范围
                        Container(
                          width: 140,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight - 100; // 顶部吸顶位置
    final maxPercent = maxHeight / screenHeight;
    final imageHeight = 140.0;
    final startShowPercent =
        (maxHeight - imageHeight) / screenHeight; // 开始显示图片的位置

    return Obx(() {
      final records = controller.stopRecords;
      final currentPercent = controller.sheetPercent.value;
      final isLoading = controller.isLoading.value;
      
      // 🐛 调试信息
      logDebug('🎨 UI 重新渲染: isLoading=$isLoading, records.length=${records.length}', tag: 'TrackPage');

      // 计算图片透明度
      // 从 startShowPercent 滑动到 maxPercent 时，透明度从 0 到 1
      double imageOpacity = 0.0;
      if (currentPercent >= startShowPercent && currentPercent <= maxPercent) {
        final progress =
            (currentPercent - startShowPercent) /
            (maxPercent - startShowPercent);
        imageOpacity = progress.clamp(0.0, 1.0);
      } else if (currentPercent > maxPercent) {
        imageOpacity = 1.0;
      }

      return Stack(
        children: [
          Column(
            children: [
              // 标题行
               
              SizedBox(height: 10),
              // 🎯 加载状态：显示占位动画
              if (isLoading) ...[
                _buildShimmerLoadingList(),
                SizedBox(height: imageHeight),
              ]
              // 停留记录列表
              else if (records.isNotEmpty) ...[
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
                // 添加底部间距，为背景图片留出空间
                SizedBox(height: imageHeight),
              ]
              // 空状态
              else ...[
                SizedBox(height: imageHeight),
              ],
            ],
          ),
          // 底部背景图片 - 根据滑动位置逐渐显现
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 100),
              opacity: imageOpacity,
              child: Center(
                child: Image.asset(
                  'assets/location/kissu3_list_bottom_bg.webp',
                  width: 284,
                  height: imageHeight,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}
// 全屏渐变背景遮罩 - 从中间滑到顶部时显示
class _GradientBackgroundOverlay extends StatelessWidget {
  final TrackController controller;
  final double screenHeight;
  final double initialHeight;
  final double maxHeight;

  const _GradientBackgroundOverlay({
    required this.controller,
    required this.screenHeight,
    required this.initialHeight,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 计算中间位置（屏幕中间）
      final middlePosition = 0.5; // 屏幕中间位置
      final maxPosition = maxHeight / screenHeight;
      final currentPercent = controller.sheetPercent.value;

      // 只在从中间位置滑到顶部时显示渐变背景
      // 当 currentPercent > middlePosition 时开始显示
      double opacity = 0.0;
      if (currentPercent > middlePosition) {
        // 从中间到顶部的进度：0 到 1
        final progress =
            (currentPercent - middlePosition) / (maxPosition - middlePosition);
        opacity = progress.clamp(0.0, 1.0);
      }

      return Positioned.fill(
        child: IgnorePointer(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: opacity,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFEF6F0), // 顶部颜色
                    Color(0xFFFFFFFF), // 中间颜色
                    Color(0xFFF6F6F6), // 底部颜色
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// 左侧浮动按钮组（刷新 + 切换地图）
class _LeftFloatingButtons extends StatelessWidget {
  final TrackController controller;

  const _LeftFloatingButtons({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 获取当前面板的滑动百分比
      final sheetPercent = controller.sheetPercent.value;

      // 计算第一个按钮的底部位置（向上移动避免被播放条遮挡）
      final screenHeight = MediaQuery.of(context).size.height;
      const deviceHeightDiff = -42.0; // 设备模块高度差
      const extraOffset = 80.0; // 额外向上移动80px，避免被播放条遮挡
      final firstButtonBottom = screenHeight / 2 - deviceHeightDiff + extraOffset;

      // 计算透明度：当面板滑到中间时开始淡出
      const middleSnapSize = 0.6;
      const maxPercent = 0.95;
      double opacity;

      if (sheetPercent <= middleSnapSize) {
        opacity = 1.0;
      } else if (sheetPercent >= maxPercent) {
        opacity = 0.0;
      } else {
        opacity = (maxPercent - sheetPercent) / (maxPercent - middleSnapSize);
      }

      opacity = opacity.clamp(0.0, 1.0);

      return Positioned(
        left: 16,
        bottom: firstButtonBottom,
        child: Opacity(
          opacity: opacity,
          child: IgnorePointer(
            ignoring: opacity == 0.0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 刷新按钮
                  GestureDetector(
                    onTap: () async {
                      await controller.refreshCurrentUserData();
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Image(
                        image: AssetImage(
                          'assets/location/kissu_refresh_map.webp',
                        ),
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),

                  // 切换地图类型按钮
                  GestureDetector(
                    onTap: () {
                      _showMapTypePicker(context);
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Image(
                        image: AssetImage(
                          'assets/location/kissu3_change_map.webp',
                        ),
                        fit: BoxFit.contain,
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  /// 显示地图类型选择弹窗
  void _showMapTypePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MapTypePickerSheet(controller: controller),
    );
  }
}

// 地图类型选择弹窗
class _MapTypePickerSheet extends StatelessWidget {
  final TrackController controller;

  const _MapTypePickerSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部拖动条
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // 地图类型选项
          Row(
            children: [
              // 经典地图
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    controller.switchMapType(1);
                    Navigator.pop(context);
                  },
                  child: Obx(
                    () => _MapTypeOption(
                      imagePath: 'assets/kissu3_map_custom.webp',
                      label: '经典地图',
                      isSelected: controller.mapType.value == 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // 卫星地图
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    controller.switchMapType(2);
                    Navigator.pop(context);
                  },
                  child: Obx(
                    () => _MapTypeOption(
                      imagePath: 'assets/kissu3_map_3d.webp',
                      label: '卫星地图',
                      isSelected: controller.mapType.value == 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// 地图类型选项组件
class _MapTypeOption extends StatelessWidget {
  final String imagePath;
  final String label;
  final bool isSelected;

  const _MapTypeOption({
    required this.imagePath,
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 地图预览图
        Container(
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFFD1E4)
                  : const Color(0xFFffffff),
              width: isSelected ? 5 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // 如果图片加载失败，显示占位符
                return Container(
                  color: const Color(0xFFF5F5F5),
                  child: const Center(
                    child: Icon(Icons.map, size: 48, color: Color(0xFFCCCCCC)),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),

        // 地图类型标签
        Stack(
          children: [
            Positioned(
              bottom: 1,
              left: 0,
              right: 0,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFFEBF3)
                      : const Color(0xFFffffff),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ],
    );
  }
}




