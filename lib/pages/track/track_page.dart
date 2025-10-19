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
import 'track_controller.dart';

class TrackPage extends StatelessWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialLocationName;
  final String? initialDuration;
  final String? initialStartTime;
  final String? initialEndTime;
  final bool autoShowInfoWindow; // 🎯 新增：是否自动显示InfoWindow

  const TrackPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialLocationName,
    this.initialDuration,
    this.initialStartTime,
    this.initialEndTime,
    this.autoShowInfoWindow = false, // 默认不自动显示
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TrackController());

    // 如果有初始坐标，设置到控制器中
    if (initialLatitude != null && initialLongitude != null) {
      controller.setInitialCoordinates(
        latitude: initialLatitude!,
        longitude: initialLongitude!,
        locationName: initialLocationName,
        duration: initialDuration,
        startTime: initialStartTime,
        endTime: initialEndTime,
        autoShowInfoWindow: autoShowInfoWindow, // 🎯 传递自动显示InfoWindow参数
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
  late final double initialHeight;
  late final double minHeight;
  late final double maxHeight;
  late final double mapHeight;
  late final DraggableScrollableController _draggableController;

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
      print('🛤️ TrackPage: 应用进入后台，暂停地图更新');
    } else if (state == AppLifecycleState.resumed) {
      // 应用恢复前台，恢复地图更新
      print('🛤️ TrackPage: 应用恢复前台，恢复地图更新');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在这里计算屏幕尺寸相关参数
    screenHeight = MediaQuery.of(context).size.height;
    initialHeight = 190; // 与定位页面保持一致：固定190px
    minHeight = 190; // 与定位页面保持一致
    maxHeight = screenHeight - 100; // 与定位页面保持一致
    mapHeight = screenHeight - initialHeight + 90;

    // 初始化底部面板控制器
    _draggableController = DraggableScrollableController();
    widget.controller.setDraggableController(_draggableController);

    // InfoWindow现在通过标记的customInfoWindowBuilder自动显示，无需设置回调
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
          _OptimizedOverlayWidget(
            controller: widget.controller,
            mapHeight: mapHeight,
            initialHeight: initialHeight,
            screenHeight: screenHeight,
          ),

          // 全屏渐变背景 - 从中间滑到顶部时显示
          _GradientBackgroundOverlay(
            controller: widget.controller,
            screenHeight: screenHeight,
            initialHeight: initialHeight,
            maxHeight: maxHeight,
          ),

          // 左侧浮动按钮组（刷新 + 切换地图）
          _LeftFloatingButtons(controller: widget.controller),

          // 右侧浮动按钮组已移除，播放条会自动显示

          // 下半屏 DraggableScrollableSheet，扩大可拖动区域
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              widget.controller.sheetPercent.value = notification.extent;

              // InfoWindow现在通过Marker的customInfoWindowBuilder自动管理，无需手动隐藏

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
                                  // 🔓 用户开始滑动时释放动画锁，防止自动展开与用户操作冲突
                                  if (notification is ScrollStartNotification) {
                                    widget.controller.setAnimationLock(false);
                                  }
                                  
                                  // 使用智能滚动检测，特别处理边界反弹
                                  if (notification
                                      is ScrollUpdateNotification) {
                                    // InfoWindow现在通过Marker的customInfoWindowBuilder自动管理
                                    return true;
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
                                          // 播放进度条 / 虚拟数据提示切换显示
                                          Obx(() {
                                            // 当轨迹点 >= 3 时显示播放进度条
                                            if (widget.controller.trackPoints.length >= 3) {
                                              return _ReplayProgressBar(
                                                controller: widget.controller,
                                              );
                                            }

                                            // 否则，只有查看另一半数据(isOneself=0)且未绑定时才显示虚拟数据提示
                                            if (widget
                                                        .controller
                                                        .isOneself
                                                        .value ==
                                                    0 &&
                                                !widget
                                                    .controller
                                                    .isBindPartner
                                                    .value) {
                                              return Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Center(
                                                    child: Container(
                                                      width: 125,
                                                      height: 23,
                                                      alignment:
                                                          Alignment.center,
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12.5,
                                                            ),
                                                      ),
                                                      child: const Text(
                                                        '以下为虚拟数据',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Color(
                                                            0xFF999999,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                ],
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          }),
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
                              // VIP遮罩层 - 覆盖整个滚动区域
                              // 非会员时，只有在查看另一半时才显示会员蒙版，查看自己时不显示
                              Obx(() {
                                // 确保始终读取响应式变量，避免短路导致未注册依赖
                                final isSelf =
                                    widget.controller.isOneself.value;
                                final showMask =
                                    !UserManager.isVip && isSelf != 1;
                                return showMask
                                    ? Positioned.fill(
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            image: DecorationImage(
                                              image: AssetImage(
                                                'assets/kissu_vip_unbind.webp',
                                              ),
                                              fit: BoxFit.fill,
                                            ),
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(20),
                                            ),
                                          ),
                                          child: GestureDetector(
                                            onTap: () {
                                              // 点击遮罩层时跳转到VIP页面
                                              Get.toNamed(KissuRoutePath.vip);
                                            },
                                            child: Container(
                                              color: Colors
                                                  .transparent, // 确保整个区域可点击
                                              child: Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    // 图片
                                                    GestureDetector(
                                                      onTap: () {
                                                        // 点击图片时跳转到VIP页面
                                                        Get.toNamed(
                                                          KissuRoutePath.vip,
                                                        );
                                                      },
                                                      child: Image.asset(
                                                        'assets/kissu_go_bind.webp',
                                                        width: 111,
                                                        height: 34,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    // 文字
                                                    const Text(
                                                      '实时查看"另一半"的位置和行程轨迹',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Color(
                                                          0xFF333333,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink();
                              }),
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

          // 顶部返回按钮
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
                onTap: () => Get.back(),
                child: Image.asset(
                  'assets/kissu_mine_back.webp',
                  width: 24,
                  height: 24,
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
            onSelect: (date) {
              widget.controller.selectDate(date);
            },
          ),
        );
      }

      // 未绑定时显示带背景图的绑定模块
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 14),
        height: 125, // 增加高度
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: AssetImage('assets/3.0/kissu3_track__bind_bg.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // 日期选择器
            Positioned(
              left: 0,
              right: 0,
              top: 49,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TrackDateSelector(
                  selectedIndex: widget.controller.selectedDateIndex,
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
            // 绑定按钮 - 右上角
            Positioned(
              right: 14,
              top: 8,
              child: GestureDetector(
                onTap: () => widget.controller.performBindAction(),
                child: Container(
                  width: 65,
                  height: 24,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.transparent),
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
}

// 优化的遮罩层Widget - 减少重建频率
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
  Set<Circle> _cachedCircles = {};

  // 数据变化检测，只在数据真正变化时更新
  int _markersVersion = -1;
  int _polylinesVersion = -1;
  int _circlesVersion = -1;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      bool needsUpdate = false;

      // 检查标记是否需要更新
      final currentMarkersVersion =
          widget.controller.stayMarkers.length +
          widget.controller.trackStartEndMarkers.length +
          (widget.controller.replayAvatarMarker.value != null ? 
            1000 + widget.controller.currentReplayIndex.value : 0) + // 播放头像标记 + 位置变化
          (widget.controller.replayAvatarMarker.value == null && 
           widget.controller.currentPosition.value != null && 
           !widget.controller.isReplaying.value ? 1 : 0) + // 橙色标记（仅非播放时）
          (widget.controller.tempInfoWindowMarker != null ? 10000 : 0); // 检测临时标记变化
      if (currentMarkersVersion != _markersVersion) {
        _updateMarkers();
        _markersVersion = currentMarkersVersion;
        needsUpdate = true;
      }

      // 检查轨迹线是否需要更新
      final currentPolylinesVersion = widget.controller.hasValidTrackData.value
          ? widget.controller.trackPoints.length
          : 0;
      if (currentPolylinesVersion != _polylinesVersion) {
        _updatePolylines();
        _polylinesVersion = currentPolylinesVersion;
        needsUpdate = true;
      }

      // 检查圆圈是否需要更新（使用版本号，避免仅位置变化时不刷新）
      final currentCirclesVersion = widget.controller.circlesVersion.value;
      if (currentCirclesVersion != _circlesVersion) {
        _updateCircles();
        _circlesVersion = currentCirclesVersion;
        needsUpdate = true;
      }

      // 只有在数据真正变化时才记录日志
      if (needsUpdate) {
        DebugUtil.info('地图数据变化，更新缓存');
      }

      return SafeAMapWidget(
        initialCameraPosition: widget.controller.initialCameraPosition,
        onMapCreated: widget.controller.onMapCreated,
        markers: _cachedMarkers,
        polylines: _cachedPolylines,
        circles: _cachedCircles,
        mapType: widget.controller.mapType.value == 1
            ? MapType.normal
            : MapType.satellite,
        compassEnabled: true,
        scaleEnabled: true,
        zoomGesturesEnabled: true,
        scrollGesturesEnabled: true,
        rotateGesturesEnabled: true,
        tiltGesturesEnabled: true,
        // 添加地图点击监听，点击地图时清除高亮圆圈
        onTap: (LatLng position) {
          // 点击地图时清除高亮圆圈
          widget.controller.clearAllHighlightCircles();
        },
        // 添加InfoWindow关闭事件监听
        onInfoWindowClose: () {
          // InfoWindow关闭时清除高亮圆圈
          widget.controller.clearAllHighlightCircles();
        },
      );
    });
  }

  /// 更新标记缓存
  void _updateMarkers() {
    final newMarkers = <Marker>{};

    // 安全地添加停留点标记
    try {
      newMarkers.addAll(widget.controller.stayMarkers);
    } catch (e) {
      DebugUtil.error('添加停留点标记失败: $e');
    }

    // 安全地添加轨迹起点和终点标记（始终显示）
    try {
      newMarkers.addAll(widget.controller.trackStartEndMarkers);
    } catch (e) {
      DebugUtil.error('添加轨迹起终点标记失败: $e');
    }

    // 添加播放头像标记（如果存在）
    if (widget.controller.replayAvatarMarker.value != null) {
      try {
        final marker = widget.controller.replayAvatarMarker.value!;
        newMarkers.add(marker);
        DebugUtil.info('✅ 已添加播放头像标记到地图缓存，位置: ${marker.position.latitude.toStringAsFixed(6)}, ${marker.position.longitude.toStringAsFixed(6)}');
      } catch (e) {
        DebugUtil.error('添加播放头像标记失败: $e');
      }
    }

    // 只在非播放状态且没有头像标记时，添加橙色当前位置标记
    if (widget.controller.replayAvatarMarker.value == null && 
        widget.controller.currentPosition.value != null && 
        !widget.controller.isReplaying.value) {
      try {
        newMarkers.add(
          Marker(
            position: widget.controller.currentPosition.value!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange,
            ),
            anchor: const Offset(0.5, 0.5),
            infoWindow: const InfoWindow(title: '当前位置', snippet: '轨迹回放中'),
          ),
        );
      } catch (e) {
        DebugUtil.error('添加当前位置标记失败: $e');
      }
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

  /// 更新轨迹线缓存
  void _updatePolylines() {
    final newPolylines = <Polyline>{};

    try {
      // 创建轨迹点的本地副本以避免竞态条件
      final trackPoints = widget.controller.trackPoints.toList();
      
      // ⚠️ 严格检查：必须至少有2个点才能画线
      if (widget.controller.hasValidTrackData.value &&
          trackPoints.isNotEmpty &&
          trackPoints.length >= 2) {
        
        DebugUtil.info('📈 [Polyline] 创建轨迹线，点数=${trackPoints.length}');
        
        newPolylines.add(
          Polyline(
            points: trackPoints,
            color: const Color(0xdd639DFF),
            width: 6,
          ),
        );
        
        DebugUtil.success('✅ [Polyline] 轨迹线创建成功');
      } else {
        DebugUtil.info('⏭️ [Polyline] 跳过创建轨迹线: hasValidData=${widget.controller.hasValidTrackData.value}, points=${trackPoints.length}');
      }
    } catch (e, stackTrace) {
      DebugUtil.error('❌ [Polyline] 创建轨迹线失败: $e');
      DebugUtil.error('Stack trace: $stackTrace');
      // 出错时确保返回空集合，避免使用旧的缓存
    }

    _cachedPolylines = newPolylines;
  }

  /// 更新圆圈缓存
  void _updateCircles() {
    final newCircles = <Circle>{};

    try {
      final controllerCircles = widget.controller.highlightCircles.toList();
      DebugUtil.info('🔄 [CircleCache] 更新圆圈缓存: 控制器中有 ${controllerCircles.length} 个圆圈');
      
      newCircles.addAll(controllerCircles);
      
      DebugUtil.info('✅ [CircleCache] 圆圈缓存更新完成: ${newCircles.length} 个圆圈');
    } catch (e) {
      DebugUtil.error('❌ [CircleCache] 添加高亮圆圈缓存失败: $e');
    }

    _cachedCircles = newCircles;
  }
}

// 优化的头像行Widget
class _CachedAvatarRow extends StatelessWidget {
  final TrackController controller;

  const _CachedAvatarRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 无论绑定状态如何，都显示另一半头像（左边，默认选中）
        _AvatarButton(
          controller: controller,
          isMyself: false,
          onTap: () {
            if (controller.isOneself.value != 0) {
              // 直接调用onAvatarTapped，让controller内部处理状态更新和地图移动
              controller.onAvatarTapped(false);
              // 添加触觉反馈
              HapticFeedback.lightImpact();
              print('🎯 头像点击：切换到查看另一半的轨迹数据');
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
              print('🎯 头像点击：切换到查看自己的轨迹数据');
            }
          },
        ),
      ],
    );
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
    return Obx(() {
      final baseSize = 32.0;

      // 检查当前头像是否被选中
      final isSelected =
          (widget.isMyself && widget.controller.isOneself.value == 1) ||
          (!widget.isMyself && widget.controller.isOneself.value == 0);

      // 根据选中状态调整缩放比例
      final scale = isSelected ? 1.2 : 0.9;
      final actualSize = baseSize * scale;

      final avatarUrl = widget.isMyself
          ? widget.controller.myAvatar.value
          : widget.controller.partnerAvatar.value;

      return GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: actualSize,
              height: actualSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
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
                borderRadius: BorderRadius.circular(9),
                fit: BoxFit.cover,
                onImageLoaded: () {
                  setState(() {
                    _isAvatarLoaded = true;
                  });
                },
              ),
            ),
            // 虚拟TA标签（只在未绑定且为另一半头像时显示）
            if (!widget.isMyself && !widget.controller.isBindPartner.value)
              Positioned(
                top: -18,
                left: actualSize / 2 - 23, // 居中显示
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: const Color(0xFFFF88AA),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    "虚拟TA",
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFFFF88AA),
                      fontWeight: FontWeight.w500,
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

// 带背景图片渐隐渐现效果的停留记录列表Widget
class _OptimizedStopRecordsListWithBackground extends StatelessWidget {
  final TrackController controller;

  const _OptimizedStopRecordsListWithBackground({required this.controller});

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
              // 停留记录列表
              if (records.isNotEmpty) ...[
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
              ],
              // 添加底部间距，为背景图片留出空间
              SizedBox(height: imageHeight),
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


/// 轨迹回放进度条组件 - 替换"以下为虚拟数据"提示
class _ReplayProgressBar extends StatelessWidget {
  final TrackController controller;

  const _ReplayProgressBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: 12,
      ).copyWith(left: 20),
      decoration: BoxDecoration(
        color: Color(0xffF7F7F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 播放控制行：播放按钮 + 进度条
          Row(
            children: [
              // 播放/暂停按钮
              GestureDetector(
                onTap: () {
                  if (controller.isReplaying.value) {
                    controller.pauseReplay();
                  } else {
                    controller.startReplay();
                  }
                },
                child: Obx(
                  () => Container(
                    width: 20,
                    height: 20,
                    padding: const EdgeInsets.all(4),

                    child: Image(
                      image: AssetImage(
                        controller.isReplaying.value
                            ? 'assets/3.0/kissu3_pause.webp'
                            : 'assets/3.0/kissu3_play.webp',
                      ),
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 进度条
              Expanded(
                child: Obx(() {
                  final progress = controller.replayProgress.value;
                  return SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 7,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                      activeTrackColor: const Color(0xFFFFDC73),
                      inactiveTrackColor: const Color(0xFFffffff),
                      thumbColor: const Color(0xFFFFDC73),
                      overlayColor: const Color(0xFFFFDC73),
                    ),
                    child: Slider(
                      value: progress.clamp(0.0, 1.0),
                      onChanged: (value) {
                        controller.seekReplay(value);
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
