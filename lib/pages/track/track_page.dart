import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:kissu_app/pages/track/component/stop_list_page.dart';
import 'package:kissu_app/pages/track/component/custom_stay_point_info_window.dart';
import 'package:kissu_app/model/location_model/location_model.dart';
import 'package:kissu_app/widgets/selector/date_selector.dart';
import 'package:kissu_app/widgets/safe_amap_widget.dart';
import 'package:kissu_app/widgets/smooth_avatar_widget.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/utils/debug_util.dart';
import 'track_controller.dart';

class TrackPage extends StatelessWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialLocationName;
  final String? initialDuration;
  final String? initialStartTime;
  final String? initialEndTime;

  const TrackPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialLocationName,
    this.initialDuration,
    this.initialStartTime,
    this.initialEndTime,
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

class _TrackPageContentState extends State<_TrackPageContent> {
  late final double screenHeight;
  late final double initialHeight;
  late final double minHeight;
  late final double maxHeight;
  late final double mapHeight;
  late final DraggableScrollableController _draggableController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在这里计算屏幕尺寸相关参数
    screenHeight = MediaQuery.of(context).size.height;
    initialHeight = screenHeight * 0.4;
    minHeight = screenHeight * 0.4;
    maxHeight = screenHeight - 150;
    mapHeight = screenHeight - initialHeight + 90;
    
    // 初始化底部面板控制器
    _draggableController = DraggableScrollableController();
    widget.controller.setDraggableController(_draggableController);
    
    // 设置停留点点击回调
    widget.controller.onStayPointTapped = _onStayPointTapped;
  }
  
  /// 处理停留点点击事件
  void _onStayPointTapped(TrackStopPoint stopPoint, LatLng position) {
    // 隐藏之前的信息窗口
    CustomStayPointInfoWindowManager.hideInfoWindow();
    
    // 检查地图控制器是否可用
    if (widget.controller.mapController == null) {
      DebugUtil.error('地图控制器不可用，无法显示InfoWindow');
      return;
    }
    
    // 显示自定义信息窗口（使用经纬度坐标）
    CustomStayPointInfoWindowManager.showInfoWindow(
      context: context,
      stopPointLocation: position, // 传递经纬度坐标
      mapController: widget.controller.mapController!, // 传递地图控制器
      locationName: stopPoint.locationName ?? '未知位置',
      duration: stopPoint.duration ?? '',
      startTime: stopPoint.startTime ?? '',
      endTime: stopPoint.endTime ?? '',
    );
  }

  @override
  void dispose() {
    // 清理自定义信息窗口
    CustomStayPointInfoWindowManager.hideInfoWindow();
    // 清理回调
    widget.controller.onStayPointTapped = null;
    // 确保控制器被正确清理
    DebugUtil.info('轨迹页面即将销毁，触发控制器清理...');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 固定的地图模块 - 使用缓存优化
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: mapHeight,
            child: _CachedMapWidget(controller: widget.controller),
          ),

          // 背景遮罩层优化 - 减少重建频率
          _OptimizedOverlayWidget(
            controller: widget.controller,
            mapHeight: mapHeight,
            initialHeight: initialHeight,
            screenHeight: screenHeight,
          ),

          // 播放控制器优化
          _PlayerControlWidget(
            controller: widget.controller,
            screenHeight: screenHeight,
            initialHeight: initialHeight,
          ),

          // 下半屏 DraggableScrollableSheet，扩大可拖动区域
          NotificationListener<DraggableScrollableNotification>(
                      onNotification: (notification) {
                        widget.controller.sheetPercent.value = notification.extent;
                        
                        // 只在底部面板真正持续滑动时隐藏InfoWindow
                        // 使用延迟机制避免点击触发的瞬间滑动
                        Future.delayed(Duration(milliseconds: 200), () {
                          if (notification.extent != widget.controller.sheetPercent.value) {
                            // 如果200ms后extent还在变化，说明是真正的滑动操作
                            CustomStayPointInfoWindowManager.hideInfoWindow();
                          }
                        });
                        
                        return true;
                      },
            child: DraggableScrollableSheet(
              controller: _draggableController,
              initialChildSize: initialHeight / screenHeight,
              minChildSize: minHeight / screenHeight,
              maxChildSize: maxHeight / screenHeight,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // 未绑定提示 - 放置在播放按钮和下半屏之间
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 15,
                      ),
                      child: _FloatingUnbindNotification(
                        controller: widget.controller,
                        screenHeight: screenHeight,
                        initialHeight: initialHeight,
                      ),
                    ),

                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            NotificationListener<ScrollNotification>(
                              onNotification: (notification) {
                                // 使用智能滚动检测，特别处理边界反弹
                                if (notification is ScrollUpdateNotification) {
                                  if (notification.scrollDelta != null) {
                                    CustomStayPointInfoWindowManager.onScrollDetected(notification.scrollDelta!);
                                  }
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
                                    Container(
                                      width: double.infinity,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Color(0xffFFF7D0),
                                            Colors.white,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        const SizedBox(height: 12),
                                        Container(
                                          width: 40,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        // 未绑定状态提示文字
                                        _buildUnboundHint(),
                                        _buildDateSelector(),
                                        const SizedBox(height: 16),
                                        _buildStatisticsRow(),
                                        // const SizedBox(height: 12),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // 列表 + 背景色
                              SliverToBoxAdapter(
                                child: Container(
                                  margin: EdgeInsets.only(
                                    left: 25,
                                    right: 25,
                                    top: 20,
                                    bottom: 15,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Color(0xffFFECEA),
                                    ),
                                  ),
                                  child: Obx(() {
                                    if (widget.controller.stopRecords.isEmpty) {
                                      return Container(
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
                                                color: Color(0xff666666),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    return _OptimizedStopRecordsList(
                                      controller: widget.controller,
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),
                            // VIP遮罩层 - 覆盖整个滚动区域
                            // 非会员时，只有在查看另一半时才显示会员蒙版，查看自己时不显示
                            Obx(() {
                              // 确保始终读取响应式变量，避免短路导致未注册依赖
                              final isSelf = widget.controller.isOneself.value;
                              final showMask = !UserManager.isVip && isSelf != 1;
                              return showMask
                                  ? Positioned.fill(
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          image: DecorationImage(
                                            image: AssetImage('assets/kissu_vip_unbind.webp'),
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
                                            color: Colors.transparent, // 确保整个区域可点击
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  // 图片
                                                  GestureDetector(
                                                    onTap: () {
                                                      // 点击图片时跳转到VIP页面
                                                      Get.toNamed(KissuRoutePath.vip);
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
                                                      color: Color(0xFF333333),
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
            ),
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

  // 未绑定状态提示文字
  Widget _buildUnboundHint() {
    return Obx(() {
      // 只在未绑定状态时显示
      if (widget.controller.isBindPartner.value) {
        return const SizedBox.shrink();
      }
      
      return Container(
        margin: const EdgeInsets.only(top: 1, bottom: 2),
        child: const Text(
          "以下为虚拟数据",
          style: TextStyle(
            fontFamily: 'LiuhuanKatongShoushu',
            fontSize: 14,
            color: Color(0xFFFF88AA),
          ),
          textAlign: TextAlign.center,
        ),
      );
    });
  }

  // 日期选择模块
  Widget _buildDateSelector() {
    return DateSelector(
      externalSelectedIndex: widget.controller.selectedDateIndex,
      onSelect: (date) {
        widget.controller.selectDate(date);
      },
    );
  }


  // 统计栏组件
  Widget _buildStatisticsRow() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 1, vertical: 12),
      margin: EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Color(0xffFFFCE8),
        borderRadius: BorderRadius.circular(12),
        
      ),
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
           
          Obx(() => _buildStat(
            "停留时间", 
            widget.controller.stayDuration.value.isEmpty 
              ? "0分钟" 
              : widget.controller.stayDuration.value,
            icon: Icons.access_time,
            color: Color(0xFF4ECDC4),
          )),
          
          Obx(() => _buildStat(
            "移动距离", 
            widget.controller.moveDistance.value.isEmpty 
              ? "0.0km" 
              : widget.controller.moveDistance.value,
            icon: Icons.directions_walk,
            color: Color(0xFF45B7D1),
          )),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, {IconData? icon, Color? color}) {
    return Expanded(
      child: Column(
        children: [
           
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF000000),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color:   Color(0xFF000000),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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

      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: mapHeight,
        child: IgnorePointer(
          child: Container(
            color: Colors.black.withValues(alpha: opacity.clamp(0.0, 0.4)),
          ),
        ),
      );
    });
  }
}

// 缓存的地图Widget - 避免不必要的重建
class _CachedMapWidget extends StatelessWidget {
  final TrackController controller;

  const _CachedMapWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 创建标记集合
      Set<Marker> markers = {};
      
      // 安全地添加停留点标记
      try {
        markers.addAll(controller.stayMarkers);
      } catch (e) {
        DebugUtil.error('添加停留点标记失败: $e');
      }
      
      // 安全地添加轨迹起点和终点标记
      try {
        markers.addAll(controller.trackStartEndMarkers);
      } catch (e) {
        DebugUtil.error('添加轨迹起终点标记失败: $e');
      }
      
      // 安全地添加当前回放位置标记s
      if (controller.currentPosition.value != null) {
        try {
          // 尝试使用自定义图标，如果失败则使用默认标记
           markers.add(Marker(
            position: controller.currentPosition.value!,
            icon:  BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            anchor: const Offset(0.5, 0.5), // 设置锚点为图片中心
            infoWindow: const InfoWindow(
              title: '当前位置',
              snippet: '轨迹回放中',
            ),
          ));
          DebugUtil.success('当前位置标记创建成功');
        } catch (e) {
          DebugUtil.error('添加当前位置标记失败: $e，使用简化标记');
          // 降级方案：使用最简单的标记
          try {
            markers.add(Marker(
              position: controller.currentPosition.value!,
              anchor: const Offset(0.5, 0.5), // 设置锚点为图片中心
            ));
          } catch (fallbackError) {
            DebugUtil.error('简化标记也失败: $fallbackError');
          }
        }
      }
      
      // 创建轨迹线集合
      Set<Polyline> polylines = {};
      
      // 安全创建轨迹线，防止空点集合错误
      try {
        // 双重检查确保轨迹线创建的安全性
        if (controller.hasValidTrackData.value && 
            controller.trackPoints.isNotEmpty && 
            controller.trackPoints.length >= 2) {
          // 创建轨迹点的副本，避免响应式变量在创建过程中变化
          final pointsCopy = List<LatLng>.from(controller.trackPoints);
          
          if (pointsCopy.isNotEmpty && pointsCopy.length >= 2) {
            // 主轨迹线 - 统一使用蓝色
            polylines.add(Polyline(
              points: pointsCopy,
              color: const Color(0xFF3B96FF),
              width: 5,
            ));
            DebugUtil.success('创建轨迹线，点数: ${pointsCopy.length}');
          } else {
            DebugUtil.warning('轨迹点副本检查失败，不创建轨迹线');
          }
        } else {
          DebugUtil.info('无有效轨迹数据，不创建轨迹线。状态: ${controller.hasValidTrackData.value}, 点数: ${controller.trackPoints.length}');
        }
      } catch (e) {
        DebugUtil.error('创建轨迹线时发生错误: $e');
        // 确保不创建有问题的轨迹线
      }
      
      // 创建多边形覆盖物集合（用于高亮圆圈）
      Set<Polygon> polygons = {};
      
      // 安全地添加高亮圆圈
      try {
        polygons.addAll(controller.highlightCircles);
        if (controller.highlightCircles.isNotEmpty) {
          DebugUtil.success('添加高亮圆圈，数量: ${controller.highlightCircles.length}');
        }
      } catch (e) {
        DebugUtil.error('添加高亮圆圈失败: $e');
      }
      
      return SafeAMapWidget(
        initialCameraPosition: controller.initialCameraPosition,
        onMapCreated: controller.onMapCreated,
        markers: markers,
        polylines: polylines,
        polygons: polygons,
        compassEnabled: true,
        scaleEnabled: true,
        zoomGesturesEnabled: true,
        scrollGesturesEnabled: true,
        rotateGesturesEnabled: true,
        tiltGesturesEnabled: true,
        // 添加地图移动监听
        onCameraMove: (CameraPosition position) {
          // 地图移动时更新相机位置并重新计算InfoWindow位置
          CustomStayPointInfoWindowManager.updateCameraPosition(position);
        },
        onCameraMoveEnd: (CameraPosition position) {
          // 地图移动结束时进行最终精确更新
          print('🏁 地图移动结束，进行最终位置更新');
        },
        // 添加地图点击监听，点击地图时清除高亮圆圈
        onTap: (LatLng position) {
          // 点击地图时清除高亮圆圈和InfoWindow
          controller.clearAllHighlightCircles();
          CustomStayPointInfoWindowManager.hideInfoWindow();
        },
      );
    });
  }
}

// 优化的播放控制器Widget
class _PlayerControlWidget extends StatelessWidget {
  final TrackController controller;
  final double screenHeight;
  final double initialHeight;

  const _PlayerControlWidget({
    required this.controller,
    required this.screenHeight,
    required this.initialHeight,
  });

  @override
  Widget build(BuildContext context) {
    // 隐藏播放按钮
    return const SizedBox.shrink();
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
              controller.isOneself.value = 0;
              controller.refreshCurrentUserData();
              // 添加触觉反馈
              HapticFeedback.lightImpact();
              print('🔄 切换到查看另一半的数据');
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
              controller.isOneself.value = 1;
              controller.refreshCurrentUserData();
              // 添加触觉反馈
              HapticFeedback.lightImpact();
              print('🔄 切换到查看自己的数据');
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
      final isSelected = (widget.isMyself && widget.controller.isOneself.value == 1) || 
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
                    ? Border.all(
                        color: const Color(0xFFFF88AA),
                        width: 1,
                      )
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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

// 优化的停留记录列表Widget
class _OptimizedStopRecordsList extends StatelessWidget {
  final TrackController controller;

  const _OptimizedStopRecordsList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final records = controller.stopRecords;

      // 使用ListView.builder优化大列表性能
      if (records.length > 10) {
        return SizedBox(
          height: 400, // 限制高度，启用滚动
          child: ListView.builder(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final isLast = index == records.length - 1;
              return StopListItem(
                record: record,
                index: index,
                isLast: isLast,
              );
            },
          ),
        );
      } else {
        // 少量数据时使用Column
        return Column(
          children: records.asMap().entries.map((entry) {
            final index = entry.key;
            final record = entry.value;
            final isLast = index == records.length - 1;
            return StopListItem(record: record, index: index, isLast: isLast);
          }).toList(),
        );
      }
    });
  }
}

// 浮动未绑定提示组件 - 位于播放按钮和下半屏之间
class _FloatingUnbindNotification extends StatelessWidget {
  final TrackController controller;
  final double screenHeight;
  final double initialHeight;

  const _FloatingUnbindNotification({
    required this.controller,
    required this.screenHeight,
    required this.initialHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 只在未绑定时显示
      if (controller.isBindPartner.value) {
        return const SizedBox.shrink();
      }

      // final sheetPercent = controller.sheetPercent.value;
      // final initialPosition = initialHeight / screenHeight;
      // final shouldShow = (sheetPercent <= initialPosition + 0.15);

      return Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/kissu_unbind_bg.webp'),
            fit: BoxFit.fill,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "还没有绑定另一半，快去绑定吧！",
                  style: TextStyle(fontSize: 14, color: Color(0xff333333)),
                ),
                Text(
                  "绑定关系，开启甜蜜之旅",
                  style: TextStyle(fontSize: 12, color: Color(0xff666666)),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => controller.performBindAction(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffFF88AA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "立即绑定",
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
