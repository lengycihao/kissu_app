import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:kissu_app/widgets/safe_amap_widget.dart';
import 'package:kissu_app/widgets/smooth_avatar_widget.dart';
import 'package:kissu_app/pages/track/track_page.dart';
import 'package:kissu_app/pages/track/track_binding.dart';
import 'package:kissu_app/services/tracking_service.dart';
import 'location_v2_controller.dart';
import 'services/location_data_helper.dart';
import 'widgets/device_info_section.dart';
import 'widgets/location_info_section.dart';
import 'widgets/cached_map_widget.dart';
import 'widgets/floating_action_buttons.dart';
import 'widgets/left_floating_buttons.dart';
import 'widgets/floating_tips_widget.dart';

class LocationV2Page extends StatelessWidget {
  LocationV2Page({super.key});

  @override
  Widget build(BuildContext context) {
    // 🚀 修复：使用安全的方式获取Controller，避免重复创建导致监听器重复注册
    final controller = Get.isRegistered<LocationV2Controller>() 
        ? Get.find<LocationV2Controller>() 
        : Get.put(LocationV2Controller());
    
    return _LocationPageContent(controller: controller);
  }
}

class _LocationPageContent extends StatefulWidget {
  final LocationV2Controller controller;

  const _LocationPageContent({required this.controller});

  @override
  State<_LocationPageContent> createState() => _LocationPageContentState();
}

class _LocationPageContentState extends State<_LocationPageContent>
    with WidgetsBindingObserver {
  late double screenHeight;
  late double maxHeight;
  late DraggableScrollableController _draggableController;
  ScrollController? _scrollController;

  // 动态计算 initialHeight 和 minHeight
  double get initialHeight {
    final isBindPartner = widget.controller.isBindPartner.value;
    final isVip = widget.controller.isVip.value;
    // 未绑定或未开通会员时：280，已绑定且是会员时：190
    return (!isBindPartner || !isVip) ? 280 : 190;
  }

  double get minHeight {
    final isBindPartner = widget.controller.isBindPartner.value;
    final isVip = widget.controller.isVip.value;
    // 未绑定或未开通会员时：280，已绑定且是会员时：190
    return (!isBindPartner || !isVip) ? 280 : 190;
  }

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
    if (state == AppLifecycleState.resumed) {
      widget.controller.tipsManager.onAppResumed();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    screenHeight = MediaQuery.of(context).size.height;
    // initialHeight 和 minHeight 将在 build 中根据状态动态计算
    maxHeight = screenHeight - 100;
    _draggableController = DraggableScrollableController();
    widget.controller.setDraggableController(_draggableController);
    
    // 🔧 修复：初始化sheetPercent为正确的初始值，避免第一次滑动时按钮位置跳变
    widget.controller.sheetPercent.value = initialHeight / screenHeight;
  }

  @override
  Widget build(BuildContext context) {
    widget.controller.pageContext = context;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: Color(0xFFFFF6EF)),
        child: Stack(
          children: [
            Positioned.fill(
              child: CachedMapWidget(controller: widget.controller),
            ),
            _buildSwitchTransition(),
            Obx(() => _GradientBackgroundOverlay(
              controller: widget.controller,
              screenHeight: screenHeight,
              initialHeight: initialHeight,
              maxHeight: maxHeight,
            )),
            FloatingActionButtons(
              screenHeight: screenHeight,
              controller: widget.controller,
            ),
            LeftFloatingButtons(
              screenHeight: screenHeight,
              controller: widget.controller,
            ),
            FloatingTipsWidget(
              controller: widget.controller,
              tipsManager: widget.controller.tipsManager,
              screenHeight: screenHeight,
            ),
            _buildDraggableSheet(),
            // 地图logo - 悬浮在地图上，位置跟随下半屏移动
            _buildMapLogo(),
            _buildBackButton(context),
            _buildAvatarRow(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTransition() {
    return Obx(() {
      if (!widget.controller.isSwitchingView.value) {
        return const SizedBox.shrink();
      }
      return AnimatedBuilder(
        animation: widget.controller.switchTransitionAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: widget.controller.switchTransitionAnimation.value,
            child: Container(
              color: const Color(0xFFFFF6EF),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B9D)),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildDraggableSheet() {
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        widget.controller.sheetPercent.value = notification.extent;
        return true;
      },
      child: Builder(
        builder: (context) {
          return Obx(() {
            final isVip = widget.controller.isVip.value;
            final isViewingPartner = widget.controller.isOneself.value == 0;
            final isBindPartner = widget.controller.isBindPartner.value;
            final shouldLimitDrag = !isVip && isViewingPartner && isBindPartner;
            final middleSnapSize = isBindPartner
                ? 0.5 + (21 / screenHeight)
                : 0.5 + (57 / screenHeight);

            return DraggableScrollableSheet(
              controller: _draggableController,
              initialChildSize: initialHeight / screenHeight,
              minChildSize: shouldLimitDrag
                  ? initialHeight / screenHeight
                  : minHeight / screenHeight,
              maxChildSize: shouldLimitDrag
                  ? initialHeight / screenHeight
                  : maxHeight / screenHeight,
              snap: true,
              snapSizes: shouldLimitDrag
                  ? null
                  : [
                      middleSnapSize,
                      (screenHeight - 100) / screenHeight,
                    ],
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

  Widget _buildScrollView(ScrollController scrollController) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification) {
          return true;
        }
        return false;
      },
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildVirtualDataTip(),
                    _buildOfflineTip(),
                    DeviceInfoSection(controller: widget.controller),
                    const SizedBox(height: 10),
                    LocationInfoSection(controller: widget.controller),
                  ],
                ),
              ],
            ),
          ),
          _buildLocationRecordsList(),
        ],
      ),
    );
  }

  Widget _buildVirtualDataTip() {
    // 移除"以下为虚拟数据"提示
    return const SizedBox.shrink();
  }

  Widget _buildOfflineTip() {
    return Obx(() {
      if (widget.controller.isBindPartner.value &&
          widget.controller.partnerOnlineStatus.value != null &&
          widget.controller.partnerOnlineStatus.value!.status == 0) {
        String offlineTime = '';
        if (widget.controller.partnerOnlineStatus.value!.updateTime != null) {
          offlineTime =
              widget.controller.partnerOnlineStatus.value!.updateTime!;
        }

        return GestureDetector(
          onTap: () {
            widget.controller.navigateToQuestionPage(
                widget.controller.partnerOnlineStatus.value!.problemId);
          },
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.only(left: 14, right: 14, bottom: 10),
            padding: EdgeInsets.only(left: 10, right: 10),
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
    });
  }

  Widget _buildLocationRecordsList() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Stack(
        children: [
          Container(
            margin: EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 15),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Obx(() {
              if (widget.controller.locationRecords.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/kissu_location_empty.webp',
                        width: 128,
                        height: 128,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '对方目前还没有停留点哦～',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xff666666),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return _OptimizedLocationRecordsList(controller: widget.controller);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildVipMask() {
    return Obx(() {
      final isBindPartner = widget.controller.isBindPartner.value;
      final isVip = widget.controller.isVip.value;
      
      // 未绑定 或 已绑定但未开会员时显示蒙版
      final shouldShowMask = !isBindPartner || (isBindPartner && !isVip);
      
      if (shouldShowMask) {
        return Positioned.fill(
          child: Column(
            children: [
              // 顶部离线提示（清晰的，不模糊）
              _buildOfflineTip(),
              // 顶部距离信息模块（清晰的，不模糊）
              DeviceInfoSection(controller: widget.controller),
              const SizedBox(height: 10),
              // 蒙版整体
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
                                  // 上报埋点：定位-立刻去绑定
                                  await TrackingService.trackLocationToBind();
                                  widget.controller.performBindAction();
                                } else {
                                  // 已绑定但未开会员：跳转到VIP页面
                                  // 上报埋点：定位-立刻开通会员
                                  await TrackingService.trackLocationToVip();
                                  widget.controller.onOpenMembershipButtonTap();
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

  Widget _buildBackButton(BuildContext context) {
    return Positioned(
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
                angle: widget.controller.backButtonRotationAnimation.value * 2 * 3.14159,
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
    );
  }

  Widget _buildAvatarRow(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 0,
      right: 0,
      child: _CachedAvatarRow(controller: widget.controller),
    );
  }

  // 地图logo - 悬浮在地图上，位置在右侧位置提醒按钮下方60px处
  Widget _buildMapLogo() {
    return Obx(() {
      final sheetHeight = screenHeight * widget.controller.sheetPercent.value;
      
      // 右侧按钮的bottom位置
      final buttonBottom = sheetHeight + 70;
      
      // logo在按钮下方60px，按钮高度50px，所以logo的bottom = buttonBottom - 50 - 60
      final logoBottom = buttonBottom - 50 -15;
      
      // 根据绑定状态动态计算中间吸顶位置
      final isBindPartner = widget.controller.isBindPartner.value;
      final middleSnapSize = isBindPartner
          ? 0.5 + (21 / screenHeight)
          : 0.5 + (57 / screenHeight);
      final maxPercent = (screenHeight - 100) / screenHeight;
      
      // 计算透明度（与右侧按钮同步）
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
}

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
    widget.controller.sheetPercent.listen((percent) {
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
                  Color(0xFFFEF6F0),
                  Color(0xFFFFFFFF),
                  Color(0xFFF6F6F6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
      final markersLength = widget.controller.markersLength;
      final polylinesLength = widget.controller.polylinesLength;

      if (_lastMarkersLength != markersLength || _lastPolylinesLength != polylinesLength) {
        _cachedMarkers = widget.controller.markers;
        _cachedPolylines = widget.controller.polylines;
        _lastMarkersLength = markersLength;
        _lastPolylinesLength = polylinesLength;
      }

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

class _CachedAvatarRow extends StatelessWidget {
  final LocationV2Controller controller;

  const _CachedAvatarRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isBindPartner = controller.isBindPartner.value;
      
      // 未绑定时不显示任何头像
      if (!isBindPartner) {
        return const SizedBox.shrink();
      }
      
      // 已绑定时显示两个头像
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _AvatarButton(
            controller: controller,
            isMyself: false,
            onTap: () {
              if (controller.isOneself.value != 0) {
                controller.onAvatarTapped(false);
              }
            },
          ),
          const SizedBox(width: 8.0),
          _AvatarButton(
            controller: controller,
            isMyself: true,
            onTap: () {
              if (controller.isOneself.value != 1) {
                controller.onAvatarTapped(true);
              }
            },
          ),
        ],
      );
    });
  }
}

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
            if (!widget.isMyself && !widget.controller.isBindPartner.value)
              Positioned(
                top: -18,
                left: actualSize / 2 - 23,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: const Color(0xFFFF88AA), width: 1),
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

class _OptimizedLocationRecordsList extends StatelessWidget {
  final LocationV2Controller controller;

  const _OptimizedLocationRecordsList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final records = controller.locationRecords;
      if (records.isEmpty) return Container();

      if (records.length > 10) {
        return _buildLargeList(records);
      } else {
        return _LocationListWithBackground(controller: controller, records: records);
      }
    });
  }

  Widget _buildLargeList(List<LocationRecord> records) {
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
        if (records.isNotEmpty)
          ...records.asMap().entries.map((entry) {
            final index = entry.key;
            final record = entry.value;
            final isLast = index == records.length - 1;
            return RepaintBoundary(
              child: _LocationRecordItem(
                record: record,
                index: index,
                isLast: isLast,
                controller: controller,
              ),
            );
          }),
      ],
    );
  }
}

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
    final maxHeight = screenHeight - 100;
    final maxPercent = maxHeight / screenHeight;
    final imageHeight = 140.0;
    final startShowPercent = (maxHeight - imageHeight) / screenHeight;

    return Obx(() {
      final currentPercent = controller.sheetPercent.value;
      double imageOpacity = 0.0;
      
      if (currentPercent >= startShowPercent && currentPercent <= maxPercent) {
        final progress = (currentPercent - startShowPercent) / (maxPercent - startShowPercent);
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
                    controller: controller,
                  ),
                );
              }),
              SizedBox(height: imageHeight),
            ],
          ),
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

class _LocationRecordItem extends StatelessWidget {
  final LocationRecord record;
  final int index;
  final bool isLast;
  final LocationV2Controller controller;

  const _LocationRecordItem({
    required this.record,
    required this.index,
    required this.isLast,
    required this.controller,
  });

  String _formatTimeRange(String? startTime, String? endTime) {
    if (startTime == null || startTime.isEmpty) return '未知时间';
    if (startTime == '当前') return '当前停留';
    if (endTime == null || endTime.isEmpty || endTime == '当前') {
      return '$startTime~当前';
    }
    return '$startTime~$endTime';
  }

  String _getLeftText(LocationRecord record) {
    if (record.status == 'staying') {
      return '停留中';
    } else if (record.status == 'ended') {
      return '停留${record.duration ?? '未知'}';
    } else {
      return '停留${record.duration ?? '未知'}';
    }
  }

  String _getRightText(LocationRecord record) {
    if (record.status == 'staying') {
      return record.duration ?? '未知';
    } else if (record.status == 'ended') {
      return _formatTimeRange(record.startTime, record.endTime);
    } else {
      return _formatTimeRange(record.startTime, record.endTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (record.latitude != null && record.longitude != null) {
          Get.to(
            () => TrackPage(
              initialLatitude: record.latitude!,
              initialLongitude: record.longitude!,
              initialLocationName: record.locationName,
              initialDuration: record.duration,
              initialStartTime: record.startTime,
              initialEndTime: record.endTime,
              autoShowInfoWindow: true,
              targetUserType: controller.isOneself.value,
            ),
            binding: TrackBinding(),
            transition: Transition.rightToLeft,
          );
        } else {
          Get.to(
            () => TrackPage(),
            binding: TrackBinding(),
            transition: Transition.rightToLeft,
          );
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Image(
                image: AssetImage('assets/kissu_location_circle.webp'),
                width: 8,
                height: 8,
              ),
            ),
            const SizedBox(width: 8),
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
                          record.status == 'staying'
                              ? 'assets/kissu_track_staying.webp'
                              : 'assets/kissu_track_location.webp',
                          width: 24,
                          height: 24,
                          color: record.status == 'staying'
                              ? Color(0xFFBE9DFF)
                              : Color(0xFFFBAE84),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getLeftText(record),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
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
