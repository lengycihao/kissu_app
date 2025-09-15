import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:amap_map/amap_map.dart';
import 'package:kissu_app/pages/track/component/stop_list_page.dart';
import 'package:kissu_app/widgets/selector/date_selector.dart';
import 'package:kissu_app/widgets/safe_amap_widget.dart';
import 'track_controller.dart';

class TrackPage extends StatelessWidget {
  TrackPage({super.key});

  final controller = Get.put(TrackController());

  @override
  Widget build(BuildContext context) {
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在这里计算屏幕尺寸相关参数
    screenHeight = MediaQuery.of(context).size.height;
    initialHeight = screenHeight * 0.4;
    minHeight = screenHeight * 0.4;
    maxHeight = screenHeight - 150;
    mapHeight = screenHeight - initialHeight + 30;
  }

  @override
  void dispose() {
    // 确保控制器被正确清理
    print('🚪 轨迹页面即将销毁，触发控制器清理...');
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
              return true;
            },
            child: DraggableScrollableSheet(
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
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is ScrollStartNotification) {
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
                                        // 虚拟数据提示
                                        Obx(() {
                                          if (widget
                                              .controller
                                              .isUsingMockData
                                              .value) {
                                            return Column(
                                              children: [
                                                Text(
                                                  '以下为虚拟数据',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFFFF88AA),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                              ],
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        }),
                                        _buildDateSelector(),
                                        const SizedBox(height: 16),
                                        _buildStatisticsRow(),
                                        const SizedBox(height: 12),
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

  // 日期选择模块
  Widget _buildDateSelector() {
    return DateSelector(
      onSelect: (date) {
        widget.controller.selectDate(date);
      },
    );
  }

  // 统计栏组件
  Widget _buildStatisticsRow() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      margin: EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Color(0xffFFFCE8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
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
          Container(
            width: 1,
            height: 30,
            color: Colors.grey.withValues(alpha: 0.3),
          ),
          Obx(() => _buildStat(
            "停留时间", 
            widget.controller.stayDuration.value.isEmpty 
              ? "0分钟" 
              : widget.controller.stayDuration.value,
            icon: Icons.access_time,
            color: Color(0xFF4ECDC4),
          )),
          Container(
            width: 1,
            height: 30,
            color: Colors.grey.withValues(alpha: 0.3),
          ),
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
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: color ?? Color(0xFF666666),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: color ?? Color(0xFF333333),
              fontWeight: FontWeight.bold,
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
        print('❌ 添加停留点标记失败: $e');
      }
      
      // 安全地添加当前回放位置标记s
      if (controller.currentPosition.value != null) {
        try {
          // 尝试使用自定义图标，如果失败则使用默认标记
           markers.add(Marker(
            position: controller.currentPosition.value!,
            icon:  BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: const InfoWindow(
              title: '当前位置',
              snippet: '轨迹回放中',
            ),
          ));
          print('✅ 当前位置标记创建成功');
        } catch (e) {
          print('❌ 添加当前位置标记失败: $e，使用简化标记');
          // 降级方案：使用最简单的标记
          try {
            markers.add(Marker(
              position: controller.currentPosition.value!,
            ));
          } catch (fallbackError) {
            print('❌ 简化标记也失败: $fallbackError');
          }
        }
      }
      
      // 创建轨迹线集合
      Set<Polyline> polylines = {};
      if (controller.trackPoints.isNotEmpty && controller.trackPoints.length > 1) {
        // 主轨迹线
        polylines.add(Polyline(
          points: controller.trackPoints,
          color: controller.isOneself.value == 1
              ? const Color(0xFF3B96FF)  // 男性 - 蓝色轨迹
              : const Color(0xFFFF88AA), // 女性 - 粉色轨迹
          width: 5,
        ));
        
        // 添加轨迹阴影效果（可选）
        polylines.add(Polyline(
          points: controller.trackPoints,
          color: (controller.isOneself.value == 1
              ? const Color(0xFF3B96FF)
              : const Color(0xFFFF88AA)).withValues(alpha: 0.3),
          width: 8,
        ));
      }
      
      return SafeAMapWidget(
        initialCameraPosition: controller.initialCameraPosition,
        onMapCreated: controller.onMapCreated,
        markers: markers,
        polylines: polylines,
        compassEnabled: true,
        scaleEnabled: true,
        zoomGesturesEnabled: true,
        scrollGesturesEnabled: true,
        rotateGesturesEnabled: true,
        tiltGesturesEnabled: true,
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
    return Obx(() {
      final sheetPercent = controller.sheetPercent.value;
      final initialPosition = initialHeight / screenHeight;
      final shouldShow = (sheetPercent <= initialPosition + 0.15);

      return Positioned(
        bottom: screenHeight * 0.4 + 20,
        left: 20,
        right: 20,
        child: Opacity(
          opacity: shouldShow ? 1.0 : 0.0,
          child: controller.showFullPlayer.value
              ? _FullPlayerControls(controller: controller)
              : _SimplePlayButton(controller: controller),
        ),
      );
    });
  }
}

// 简单播放按钮组件
class _SimplePlayButton extends StatelessWidget {
  final TrackController controller;

  const _SimplePlayButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => controller.startReplay(),
      child: Align(
        alignment: AlignmentGeometry.centerLeft,
        child: SizedBox(
          width: 60,
          height: 60,
          child: Image.asset(
            'assets/kissu_location_play.webp',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

// 完整播放控制器组件
class _FullPlayerControls extends StatelessWidget {
  final TrackController controller;

  const _FullPlayerControls({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 距离和时间显示
        Container(
          margin: EdgeInsets.only(bottom: 20),
          width: 170,
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Obx(
                () => Text(
                  controller.replayDistance.value,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
              const SizedBox(width: 20),
              Obx(
                () => Text(
                  controller.replayTime.value,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
        // 播放控制器
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Obx(() {
            // 安全计算进度值
            double progress = 0.0;
            if (controller.trackPoints.isNotEmpty) {
              final maxIndex = controller.trackPoints.length - 1;
              if (maxIndex > 0) {
                final currentIndex = controller.currentReplayIndex.value.clamp(
                  0,
                  maxIndex,
                );
                progress = currentIndex / maxIndex;
              } else {
                progress = 1.0;
              }
            }
            progress = progress.clamp(0.0, 1.0);

            return Row(
              children: [
                // 播放/暂停按钮
                GestureDetector(
                  onTap: controller.isReplaying.value
                      ? controller.pauseReplay
                      : controller.startReplay,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: controller.isReplaying.value
                          ? Colors.orange
                          : Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      controller.isReplaying.value
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                // 进度条
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Color(0xffFFDC73),
                      inactiveTrackColor: Color(0x33FFDC73),
                      thumbColor: Color(0xffFFDC73),
                      overlayColor: Color(0x33FFDC73),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: progress,
                      onChanged: (value) {
                        if (controller.trackPoints.isNotEmpty) {
                          final maxIndex = controller.trackPoints.length - 1;
                          if (maxIndex > 0) {
                            final newIndex = (value * maxIndex).round().clamp(
                              0,
                              maxIndex,
                            );
                            controller.seekToIndex(newIndex);
                          }
                        }
                      },
                    ),
                  ),
                ),
                // 关闭按钮
                GestureDetector(
                  onTap: controller.closePlayer,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(color: Colors.white),
                    child: Image(
                      image: AssetImage('assets/kissu_location_close.webp'),
                      width: 15,
                      height: 15,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

// 优化的头像行Widget
class _CachedAvatarRow extends StatelessWidget {
  final TrackController controller;

  const _CachedAvatarRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final List<Widget> avatars = [
        // 自己的头像
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
      ];

      // 绑定状态时显示另一半头像
      if (controller.isBindPartner.value &&
          controller.partnerAvatar.value.isNotEmpty) {
        avatars.add(const SizedBox(width: 8));
        avatars.add(
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
        );
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: avatars,
      );
    });
  }
}

// 优化的头像按钮Widget
class _AvatarButton extends StatelessWidget {
  final TrackController controller;
  final bool isMyself;
  final VoidCallback onTap;

  const _AvatarButton({
    required this.controller,
    required this.isMyself,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final baseSize = 32.0;
      
      // 检查当前头像是否被选中
      final isSelected = (isMyself && controller.isOneself.value == 1) || 
                        (!isMyself && controller.isOneself.value == 0);
      
      // 根据选中状态调整缩放比例
      final scale = isSelected ? 1.2 : 0.9;
      final actualSize = baseSize * scale;
      
      final avatarUrl = isMyself
          ? controller.myAvatar.value
          : controller.partnerAvatar.value;
      final defaultAsset = isMyself
          ? 'assets/kissu_track_header_boy.webp'
          : 'assets/kissu_track_header_girl.webp';

      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: actualSize,
          height: actualSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(actualSize / 2),
            border: isSelected 
                ? Border.all(
                    color: const Color(0xFFFF88AA),
                    width: 3,
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF88AA).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(actualSize / 2),
            child: avatarUrl.isNotEmpty
                ? Image.network(
                    avatarUrl,
                    width: actualSize,
                    height: actualSize,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        defaultAsset,
                        width: actualSize,
                        height: actualSize,
                        fit: BoxFit.cover,
                      );
                    },
                  )
                : Image.asset(
                    defaultAsset,
                    width: actualSize,
                    height: actualSize,
                    fit: BoxFit.cover,
                  ),
          ),
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
