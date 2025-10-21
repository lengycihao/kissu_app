import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:kissu_app/widgets/safe_amap_widget.dart';
import 'package:kissu_app/widgets/smooth_avatar_widget.dart';
import 'package:kissu_app/pages/track/track_page.dart';
import 'package:kissu_app/pages/track/track_binding.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'location_v2_controller.dart';
import 'widgets/device_info_section.dart';
import 'widgets/location_info_section.dart';
import 'widgets/cached_map_widget.dart';
import 'widgets/floating_action_buttons.dart';
import 'widgets/left_floating_buttons.dart';
import 'widgets/floating_tips_widget.dart';

class LocationV2Page extends StatelessWidget {
  LocationV2Page({super.key});

  final controller = Get.put(LocationV2Controller());

  @override
  Widget build(BuildContext context) {
    return _LocationPageContent(controller: controller);
  }
}

// 将主要内容提取为单独的StatefulWidget以优化性能
class _LocationPageContent extends StatefulWidget {
  final LocationV2Controller controller;

  const _LocationPageContent({required this.controller});

  @override
  State<_LocationPageContent> createState() => _LocationPageContentState();
}

class _LocationPageContentState extends State<_LocationPageContent>
    with WidgetsBindingObserver {
  late double screenHeight;
  late double initialHeight;
  late double minHeight;
  late double maxHeight;
  late double mapHeight;
  
  /// 下半屏拖拽控制器
  late DraggableScrollableController _draggableController;
  
  /// ScrollView控制器（由DraggableScrollableSheet提供）
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      // 应用进入后台，暂停地图更新（释放资源）
      print('📍 LocationV2Page: 应用进入后台，暂停地图更新');
    } else if (state == AppLifecycleState.resumed) {
      // 应用恢复前台，恢复地图更新
      print('📍 LocationV2Page: 应用恢复前台，恢复地图更新');
      
      // 应用恢复前台时，重新检查权限状态（用户可能在设置中修改了权限）
      widget.controller.tipsManager.onAppResumed();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在这里计算屏幕尺寸相关参数
    screenHeight = MediaQuery.of(context).size.height;
    // 起始位置：下半屏高度为190px（顶部距离屏幕底部190px）
    initialHeight = 190;
    // 最小位置：不允许往下滑，最小就是初始位置190px
    minHeight = 190;
    // 最大位置：顶部距离屏幕顶部100px
    maxHeight = screenHeight - 100;
    mapHeight = screenHeight - initialHeight + 90;

    // 初始化底部面板控制器
    _draggableController = DraggableScrollableController();
    widget.controller.setDraggableController(_draggableController);
  }

  @override
  Widget build(BuildContext context) {
    widget.controller.pageContext = context; // 保存 Scaffold 的 context
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: Color(0xFFFFF6EF)),
        child: Stack(
          children: [
            // 固定的地图模块 - 使用缓存优化
            Positioned.fill(
              child: CachedMapWidget(controller: widget.controller),
            ),


            // 全屏渐变背景 - 从中间滑到顶部时显示
            _GradientBackgroundOverlay(
              controller: widget.controller,
              screenHeight: screenHeight,
              initialHeight: initialHeight,
              maxHeight: maxHeight,
            ),


            // 右侧浮动按钮组 - 位于地图和下半屏之间
            FloatingActionButtons(
              screenHeight: screenHeight,
              controller: widget.controller,
            ),

            // 左侧浮动按钮组 - 刷新和切换地图类型
            LeftFloatingButtons(
              screenHeight: screenHeight,
              controller: widget.controller,
            ),

            // 浮动提示组件
            FloatingTipsWidget(
              controller: widget.controller,
              tipsManager: widget.controller.tipsManager,
              screenHeight: screenHeight,
            ),

            // 下半屏 DraggableScrollableSheet，扩大可拖动区域
            NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                widget.controller.sheetPercent.value = notification.extent;
                return true;
              },
              child: Builder(
                builder: (context) {
                  // 🔧 修改：只有已绑定、查看另一半头像时且非会员时才禁用拖动
                  return Obx(() {
                    final isVip = widget
                        .controller
                        .isVip
                        .value; // 🔧 使用controller的响应式isVip
                    final isViewingPartner =
                        widget.controller.isOneself.value == 0;
                    final isBindPartner = widget.controller.isBindPartner.value;
                    final shouldLimitDrag =
                        !isVip && isViewingPartner && isBindPartner;

                    // 🔧 根据绑定状态动态计算中间吸顶位置
                    // 未绑定时设备信息模块高度134px，已绑定时92px，差42px
                    // 为了让视觉上的吸顶位置一致，需要调整snapSize
                    final middleSnapSize = isBindPartner
                        ? 0.5 +
                              (21 / screenHeight) // 已绑定：屏幕中间
                        : 0.5 +
                              (57 /
                                  screenHeight); // 未绑定：稍微往上偏移42px（设备模块高度差）+ 35

                    return DraggableScrollableSheet(
                      controller: _draggableController,
                      initialChildSize: initialHeight / screenHeight,
                      minChildSize: shouldLimitDrag
                          ? initialHeight / screenHeight
                          : minHeight / screenHeight,
                      maxChildSize: shouldLimitDrag
                          ? initialHeight / screenHeight
                          : maxHeight / screenHeight,
                      snap: true, // 启用吸附效果
                      snapSizes: shouldLimitDrag
                          ? null
                          : [
                              middleSnapSize, // 🔧 动态中间位置（根据绑定状态调整）
                              (screenHeight - 100) /
                                  screenHeight, // 距离屏幕顶部100px
                            ],
                      snapAnimationDuration: const Duration(milliseconds: 200), // 🎯 优化滑动体验：缩短吸附动画时间
                      builder: (context, scrollController) {
                        // 保存scrollController以便在返回按钮点击时使用
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
                                  // boxShadow: [
                                  //   BoxShadow(
                                  //     color: Colors.black12,
                                  //     blurRadius: 10,
                                  //     offset: Offset(0, -2),
                                  //   ),
                                  // ],
                                ),
                                child: Stack(
                                  children: [
                                    NotificationListener<ScrollNotification>(
                                      onNotification: (notification) {
                                        if (notification
                                            is ScrollStartNotification) {
                                          return true;
                                        }
                                        return false;
                                      },
                                      child: CustomScrollView(
                                        controller: scrollController,
                                        slivers: [
                                          // 顶部固定区域
                                          SliverToBoxAdapter(
                                            child: Stack(
                                              children: [
                                                Column(
                                                  children: [
                                                    // 虚拟数据提示文字 - 设备信息模块上方居中显示
                                                    //以下为虚拟数据

                                                    // 虚拟提示文字 - 仅查看另一半数据且未绑定时显示
                                                    Obx(() {
                                                      // 只有查看另一半数据(isOneself=0)且未绑定时才显示虚拟数据提示
                                                      if (widget.controller.isOneself.value == 0 && 
                                                          !widget.controller.isBindPartner.value) {
                                                        return Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Center(
                                                              child: Container(
                                                                width: 125,
                                                                height: 23,
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                decoration: BoxDecoration(
                                                                  color: Colors
                                                                      .white,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        12.5,
                                                                      ),
                                                                ),
                                                                child: const Text(
                                                                  '以下为虚拟数据',
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color: Color(
                                                                      0xFF999999,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 10,
                                                            ),
                                                          ],
                                                        );
                                                      }
                                                      return const SizedBox.shrink();
                                                    }),
                                                    //离线提醒
                                                    Obx(() {
                                                      // 只有在已绑定状态下，且另一半离线时才显示
                                                      if (widget.controller.isBindPartner.value && 
                                                          widget.controller.partnerOnlineStatus.value != null &&
                                                          widget.controller.partnerOnlineStatus.value!.status == 0) {
                                                        
                                                        // 格式化离线时间
                                                        String offlineTime = '';
                                                        if (widget.controller.partnerOnlineStatus.value!.updateTime != null) {
                                                          offlineTime = widget.controller.partnerOnlineStatus.value!.updateTime!;
                                                        }
                                                        
                                                        return GestureDetector(
                                                          onTap: () {
                                                            // 点击查看原因，跳转到常见问题页面
                                                            widget.controller.navigateToQuestionPage(
                                                              widget.controller.partnerOnlineStatus.value!.problemId
                                                            );
                                                          },
                                                          child: Container(
                                                            width: double.infinity,
                                                            margin: EdgeInsets.only(
                                                              left: 14,
                                                              right: 14,
                                                              bottom: 10,
                                                            ),
                                                            padding: EdgeInsets.only(
                                                              left: 10,
                                                              right: 10,
                                                            ),
                                                            height: 28,
                                                            decoration: BoxDecoration(
                                                              color: Color(0xffFFFCE8),
                                                              borderRadius: BorderRadius.circular(12),
                                                            ),
                                                            alignment: Alignment.center,
                                                            child: Row(
                                                              children: [
                                                                Image.asset(
                                                                  'assets/phone_history/kissu3_history_yichang.webp',
                                                                  width: 16,
                                                                  height: 16,
                                                                ),
                                                                SizedBox(width: 4),
                                                                Expanded(
                                                                  child: Text(
                                                                    'Ta离线啦${offlineTime.isNotEmpty ? '，离线时间: $offlineTime' : ''}',
                                                                    style: TextStyle(
                                                                      fontSize: 12,
                                                                      color: Color(0xFF333333),
                                                                    ),
                                                                    overflow: TextOverflow.ellipsis,
                                                                  ),
                                                                ),
                                                                Row(
                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                  children: [
                                                                    Text(
                                                                      '查看原因',
                                                                      style: TextStyle(
                                                                        fontSize: 13,
                                                                        color: Color(0xFFFF9500),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(width: 4),
                                                                    Image.asset(
                                                                      'assets/phone_history/kissu3_arrow_blue.webp',
                                                                      color: Color(0xFFAD6D48),
                                                                      width: 16,
                                                                      height: 16,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                      return const SizedBox.shrink();
                                                    }),
                                                    DeviceInfoSection(controller: widget.controller),
                                                    const SizedBox(height: 10),
                                                    LocationInfoSection(controller: widget.controller),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          // 列表 + 背景色 - 使用 SliverFillRemaining 确保白色背景填充到底部
                                          SliverFillRemaining(
                                            hasScrollBody: false,
                                            child: Stack(
                                              children: [
                                                Container(
                                                  margin: EdgeInsets.only(
                                                    left: 15,
                                                    right: 15,
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
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    // border: Border.all(
                                                    //   color: Color(0xffFF88AA),
                                                    // ),
                                                  ),
                                                  child: Obx(() {
                                                    if (widget
                                                        .controller
                                                        .locationRecords
                                                        .isEmpty) {
                                                      return Container(
                                                        width: double.infinity,
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              vertical: 40,
                                                            ),
                                                        child: Column(
                                                          children: [
                                                            Image.asset(
                                                              'assets/kissu_location_empty.webp',
                                                              width: 128,
                                                              height: 128,
                                                            ),
                                                            SizedBox(
                                                              height: 16,
                                                            ),
                                                            Text(
                                                              '对方目前还没有停留点哦～',
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

                                                    return _OptimizedLocationRecordsList(
                                                      controller:
                                                          widget.controller,
                                                    );
                                                  }),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // 统一的会员限制遮罩层 - 覆盖整个滚动区域（带毛玻璃效果）
                                    // 🔧 修改：只有已绑定、查看另一半头像时且非会员时才显示蒙版
                                    Obx(() {
                                      // 先读取响应式值，避免被非响应式条件短路，导致未注册依赖
                                      final isSelfFlag =
                                          widget.controller.isOneself.value;
                                      final isBindPartner =
                                          widget.controller.isBindPartner.value;
                                      final isVip = widget
                                          .controller
                                          .isVip
                                          .value; // 🔧 使用controller的响应式isVip
                                      final shouldShowVipMask =
                                          !isVip &&
                                          isSelfFlag == 0 &&
                                          isBindPartner;
                                      if (shouldShowVipMask) {
                                        return Positioned.fill(
                                          child: ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(20),
                                                ),
                                            child: BackdropFilter(
                                              filter: ImageFilter.blur(
                                                sigmaX: 10.0,
                                                sigmaY: 10.0,
                                              ),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFFFFFFF,
                                                  ).withOpacity(0.2),
                                                  borderRadius:
                                                      const BorderRadius.vertical(
                                                        top: Radius.circular(
                                                          20,
                                                        ),
                                                      ),
                                                ),
                                                child: GestureDetector(
                                                  onTap: () {
                                                    // 点击遮罩层时跳转到VIP页面，返回后刷新数据
                                                    Get.toNamed(
                                                      KissuRoutePath.vip,
                                                    )?.then((_) {
                                                      // 从VIP页面返回后，刷新用户信息和定位数据
                                                      widget.controller
                                                          .refreshUserInfo();
                                                    });
                                                  },
                                                  child: Container(
                                                    color: Colors
                                                        .transparent, // 确保整个区域可点击
                                                    child: Center(
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          // 图片
                                                          GestureDetector(
                                                            onTap: () {
                                                              // 点击图片时跳转到VIP页面，返回后刷新数据
                                                              Get.toNamed(
                                                                KissuRoutePath
                                                                    .vip,
                                                              )?.then((_) {
                                                                // 从VIP页面返回后，刷新用户信息和定位数据
                                                                widget
                                                                    .controller
                                                                    .refreshUserInfo();
                                                              });
                                                            },
                                                            child: Image.asset(
                                                              'assets/kissu_go_bind.webp',
                                                              width: 111,
                                                              height: 34,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 12,
                                                          ),
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
                                            ),
                                          ),
                                        );
                                      } else {
                                        return const SizedBox.shrink();
                                      }
                                    }),
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
            ),

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
      ),
    );
  }


}


// 全屏渐变背景遮罩 - 从中间滑到顶部时显示（优化版）
class _GradientBackgroundOverlay extends StatefulWidget {
  final LocationV2Controller controller;
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
  State<_GradientBackgroundOverlay> createState() => _GradientBackgroundOverlayState();
}

class _GradientBackgroundOverlayState extends State<_GradientBackgroundOverlay> {
  double _opacity = 0.0;
  double _lastPercent = 0.0;
  
  @override
  void initState() {
    super.initState();
    // 使用防抖来减少更新频率
    widget.controller.sheetPercent.listen((percent) {
      // 只有当变化超过阈值时才更新
      if ((percent - _lastPercent).abs() > 0.02) {
        _lastPercent = percent;
        _updateOpacity(percent);
      }
    });
  }
  
  void _updateOpacity(double currentPercent) {
    final middlePosition = 0.5;
    final maxPosition = widget.maxHeight / widget.screenHeight;
    
    double newOpacity = 0.0;
    if (currentPercent > middlePosition) {
      final progress = (currentPercent - middlePosition) / (maxPosition - middlePosition);
      newOpacity = progress.clamp(0.0, 1.0);
    }
    
    if (mounted && newOpacity != _opacity) {
      setState(() {
        _opacity = newOpacity;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: _opacity,
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
  }
}

// 缓存的地图Widget - 避免不必要的重建
class _CachedMapWidget extends StatefulWidget {
  final LocationV2Controller controller;

  const _CachedMapWidget({required this.controller});

  @override
  State<_CachedMapWidget> createState() => _CachedMapWidgetState();
}

class _CachedMapWidgetState extends State<_CachedMapWidget> {
  Set<Marker>? _cachedMarkers;
  Set<Polyline>? _cachedPolylines;
  int _lastMarkersLength = -1;
  int _lastPolylinesLength = -1;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 使用公共getter获取集合长度，避免频繁重建
      final markersLength = widget.controller.markersLength;
      final polylinesLength = widget.controller.polylinesLength;

      // 只有当标记或连接线数量发生变化时才重新构建
      if (_lastMarkersLength != markersLength ||
          _lastPolylinesLength != polylinesLength) {
        _cachedMarkers = widget.controller.markers;
        _cachedPolylines = widget.controller.polylines;
        _lastMarkersLength = markersLength;
        _lastPolylinesLength = polylinesLength;

        print(
          '🗺️ 地图Widget重建 - 标记数量: ${markersLength}, 连接线数量: ${polylinesLength}',
        );
        if (_cachedMarkers != null && _cachedMarkers!.isNotEmpty) {
          print(
            '🗺️ 标记详情: ${_cachedMarkers!.map((m) => '标记: ${m.position}').join(', ')}',
          );
        }
      }

      // 根据控制器的mapType值转换为AMap的MapType
      final mapType = widget.controller.mapType.value == 2
          ? MapType.satellite
          : MapType.normal;

      return RepaintBoundary(
        child: SafeAMapWidget(
          initialCameraPosition: widget.controller.initialCameraPosition,
          onMapCreated: widget.controller.onMapCreated,
          markers: _cachedMarkers ?? {},
          polylines: _cachedPolylines ?? {},
          compassEnabled: true,
          scaleEnabled: true,
          zoomGesturesEnabled: true,
          scrollGesturesEnabled: true,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: true,
          mapType: mapType,
        ),
      );
    });
  }
}

// 优化的头像行Widget
class _CachedAvatarRow extends StatelessWidget {
  final LocationV2Controller controller;

  const _CachedAvatarRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 另一半的头像（左边）
        _AvatarButton(
          controller: controller,
          isMyself: false,
          onTap: () {
            if (controller.isOneself.value != 0) {
              // 直接调用onAvatarTapped，让controller内部处理状态更新和地图移动
              controller.onAvatarTapped(false);
            }
          },
        ),
        const SizedBox(width: 8.0),
        // 自己的头像（右边）
        _AvatarButton(
          controller: controller,
          isMyself: true,
          onTap: () {
            if (controller.isOneself.value != 1) {
              // 直接调用onAvatarTapped，让controller内部处理状态更新和地图移动
              controller.onAvatarTapped(true);
            }
          },
        ),
      ],
    );
  }
}

// 优化的头像按钮Widget
class _AvatarButton extends StatefulWidget {
  final LocationV2Controller controller;
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
  int? _lastIsOneselfValue; // 缓存上次的isOneself值
  bool? _lastIsSelectedValue; // 缓存上次的选中状态

  @override
  Widget build(BuildContext context) {
    final baseSize = 32.0;

    // 使用 Obx 只监听必要的响应式变量
    return Obx(() {
      final currentIsOneselfValue = widget.controller.isOneself.value;

      // 检查当前头像是否被选中
      final isSelected =
          (widget.isMyself && currentIsOneselfValue == 1) ||
          (!widget.isMyself && currentIsOneselfValue == 0);

      // 只有当选中状态真正发生变化时才打印调试信息，减少日志噪音
      if (_lastIsOneselfValue != currentIsOneselfValue ||
          _lastIsSelectedValue != isSelected) {
        print(
          '🎯 头像选中状态变化 - isMyself: ${widget.isMyself}, isOneself: $currentIsOneselfValue, isSelected: $isSelected, isAvatarLoaded: $_isAvatarLoaded',
        );
        _lastIsOneselfValue = currentIsOneselfValue;
        _lastIsSelectedValue = isSelected;
      }

      // 根据选中状态调整缩放比例，但只有在头像加载成功后才应用选中效果
      final scale = (isSelected && _isAvatarLoaded) ? 1.2 : 0.9;
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
                      color: Color(0xFF000000),
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

// 优化的定位记录列表Widget
class _OptimizedLocationRecordsList extends StatelessWidget {
  final LocationV2Controller controller;

  const _OptimizedLocationRecordsList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final records = controller.locationRecords;

      // 如果没有记录，返回空Container，使用原来的空状态显示
      if (records.isEmpty) {
        return Container();
      }

      // 使用ListView.builder优化大列表性能
      if (records.length > 10) {
        // 数据太多，不显示背景图片
        return Column(
          children: [
            Obx(() {
              final recordCount = controller.locationRecords.length;
              return Row(
                children: [
                  Text(
                    "今日停留$recordCount个地方",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF000000),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Image.asset(
                    'assets/kissu_love_yellow.webp',
                    width: 23,
                    height: 23,
                  ),
                ],
              );
            }),
            SizedBox(height: 16),
            // 停留记录列表 - 使用与轨迹页面相同的方式
            if (records.isNotEmpty) ...[
              ...records.asMap().entries.map((entry) {
                final index = entry.key;
                final record = entry.value;
                final isLast = index == records.length - 1;
                return RepaintBoundary(
                  child: _LocationRecordItem(
                    record: record,
                    index: index,
                    isLast: isLast,
                  ),
                );
              }),
            ],
          ],
        );
      } else {
        // 少量数据时使用Column，并显示背景图片
        return _LocationListWithBackground(
          controller: controller,
          records: records,
        );
      }
    });
  }
}

// 带背景图片的停留点列表（只在数据较少时使用）
class _LocationListWithBackground extends StatelessWidget {
  final LocationV2Controller controller;
  final List<LocationRecord> records;

  const _LocationListWithBackground({
    required this.controller,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight - 100; // 顶部吸顶位置
    final maxPercent = maxHeight / screenHeight;
    final imageHeight = 140.0;
    final startShowPercent =
        (maxHeight - imageHeight) / screenHeight; // 开始显示图片的位置

    return Obx(() {
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
              Row(
                children: [
                  Text(
                    "今日停留${records.length}个地方",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF000000),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Image.asset(
                    'assets/kissu_love_yellow.webp',
                    width: 23,
                    height: 23,
                  ),
                ],
              ),
              SizedBox(height: 16),
              ...records.asMap().entries.map((entry) {
                final index = entry.key;
                final record = entry.value;
                final isLast = index == records.length - 1;
                return RepaintBoundary(
                  child: _LocationRecordItem(
                    record: record,
                    index: index,
                    isLast: isLast,
                  ),
                );
              }),
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

// 定位记录项Widget
class _LocationRecordItem extends StatelessWidget {
  final LocationRecord record;
  final int index;
  final bool isLast;

  const _LocationRecordItem({
    required this.record,
    required this.index,
    required this.isLast,
  });

  // 格式化时间范围显示
  String _formatTimeRange(String? startTime, String? endTime) {
    if (startTime == null || startTime.isEmpty) {
      return '未知时间';
    }

    // 如果startTime是"当前"，则显示特殊格式
    if (startTime == '当前') {
      return '当前停留';
    }

    // 如果endTime为空或为"当前"，则只显示开始时间
    if (endTime == null || endTime.isEmpty || endTime == '当前') {
      return '$startTime~当前';
    }

    return '$startTime~$endTime';
  }

  // 获取左侧文本
  String _getLeftText(LocationRecord record) {
    if (record.status == 'staying') {
      return '停留中';
    } else if (record.status == 'ended') {
      return '停留${record.duration ?? '未知'}';
    } else {
      // 默认情况，保持原有逻辑
      return '停留${record.duration ?? '未知'}';
    }
  }

  // 获取右侧文本
  String _getRightText(LocationRecord record) {
    if (record.status == 'staying') {
      return record.duration ?? '未知';
    } else if (record.status == 'ended') {
      return _formatTimeRange(record.startTime, record.endTime);
    } else {
      // 默认情况，保持原有逻辑
      return _formatTimeRange(record.startTime, record.endTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 点击item时跳转到轨迹页面，传递坐标信息
        if (record.latitude != null && record.longitude != null) {
          Get.to(
            () => TrackPage(
              initialLatitude: record.latitude!,
              initialLongitude: record.longitude!,
              initialLocationName: record.locationName,
              initialDuration: record.duration,
              initialStartTime: record.startTime,
              initialEndTime: record.endTime,
              autoShowInfoWindow: true, // 🎯 自动显示InfoWindow
            ),
            binding: TrackBinding(),
          );
        } else {
          // 如果没有坐标信息，只跳转到轨迹页面
          Get.to(() => TrackPage(), binding: TrackBinding());
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧时间
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Image(
                image: AssetImage('assets/kissu_location_circle.webp'),
                width: 8,
                height: 8,
              ),
            ),
            const SizedBox(width: 8),
            // 右侧内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    record.locationName ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF333333),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFFFFF5EF), Color(0xFFFfffff)],
                      ),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                         record.status == 'staying' ? 'assets/kissu_track_staying.webp' : 'assets/kissu_track_location.webp',
                          width: 24,
                          height: 24,color: record.status == 'staying' ? Color(0xFFBE9DFF) : Color(0xFFFBAE84),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getLeftText(record),
                          style: const TextStyle(
                            fontSize: 12,fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        Spacer(),
                        Text(
                          _getRightText(record),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
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
}




