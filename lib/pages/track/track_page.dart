import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:kissu_app/pages/track/component/stop_list_page.dart';
import 'package:kissu_app/widgets/selector/date_selector.dart';
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
    initialHeight = screenHeight * 0.3;
    minHeight = screenHeight * 0.3;
    maxHeight = screenHeight - 150;
    mapHeight = screenHeight - initialHeight + 30;
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
                return Container(
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
                                    colors: [Color(0xffFFF7D0), Colors.white],
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
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
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
                            margin: EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 15,
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
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.location_off,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        '暂无轨迹数据',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '该日期没有位置记录',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
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
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx(() => _buildStat("保留次数", widget.controller.stayCount.value.toString())),
          Obx(() => _buildStat("停留时间", widget.controller.stayDuration.value)),
          Obx(() => _buildStat("移动距离", widget.controller.moveDistance.value)),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 12)),
      ],
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
      final opacity = (controller.sheetPercent.value - (initialHeight / screenHeight)) * 0.6;
      
      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: mapHeight,
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

// 缓存的地图Widget - 避免不必要的重建
class _CachedMapWidget extends StatelessWidget {
  final TrackController controller;

  const _CachedMapWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return RepaintBoundary(
        child: FlutterMap(
          mapController: controller.mapController,
          options: controller.mapOptions,
          children: [
            TileLayer(
              urlTemplate: 'https://webrd0{s}.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=2&style=8&x={x}&y={y}&z={z}',
              subdomains: const ['1', '2', '3', '4'],
              userAgentPackageName: 'com.example.kissu_app',
              tileProvider: NetworkTileProvider(),
              retinaMode: true,
            ),
            // 轨迹线
            if (controller.trackPoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: controller.trackPoints,
                    color: controller.isOneself.value == 1
                        ? const Color(0xFF3B96FF)
                        : const Color(0xFFFF88AA),
                    strokeWidth: 4.0,
                    strokeJoin: StrokeJoin.round,
                    strokeCap: StrokeCap.round,
                    useStrokeWidthInMeter: false,
                  ),
                ],
              ),
            // 停留点Markers
            if (controller.stayMarkers.isNotEmpty)
              MarkerLayer(markers: controller.stayMarkers),
            // 当前回放位置标记
            if (controller.currentPosition.value != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: controller.currentPosition.value!,
                    width: 76,
                    height: 76,
                    child: _CachedMovingAvatar(controller: controller),
                  ),
                ],
              ),
          ],
        ),
      );
    });
  }
}

// 优化的移动头像Widget
class _CachedMovingAvatar extends StatelessWidget {
  final TrackController controller;

  const _CachedMovingAvatar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 76x76 方向指引箭头
          Transform.rotate(
            angle: controller.getRotationAngle(),
            child: Image.asset(
              'assets/kissu_location_run.webp',
              width: 76,
              height: 76,
              fit: BoxFit.contain,
            ),
          ),
          // 头像
          Positioned(
            top: 16,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/kissu_location_header_bg.webp'),
                  fit: BoxFit.cover,
                ),
              ),
              padding: EdgeInsets.all(2),
              child: ClipOval(
                child: _buildAvatarImage(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage() {
    final isMyself = controller.isOneself.value == 1;
    final avatarUrl = isMyself ? controller.myAvatar.value : controller.partnerAvatar.value;
    final defaultAsset = isMyself ? 'assets/kissu_track_header_boy.webp' : 'assets/kissu_track_header_girl.webp';

    if (avatarUrl.isNotEmpty) {
      return Image.network(
        avatarUrl,
        width: 30,
        height: 30,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(defaultAsset, width: 30, height: 30, fit: BoxFit.cover);
        },
      );
    } else {
      return Image.asset(defaultAsset, width: 30, height: 30, fit: BoxFit.cover);
    }
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

      return AnimatedPositioned(
        duration: const Duration(milliseconds: 200),
        bottom: screenHeight * 0.3 + 20,
        left: 20,
        right: 20,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
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
              Obx(() => Text(
                controller.replayDistance.value,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              )),
                const SizedBox(width: 20),
              Obx(() => Text(
                controller.replayTime.value,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              )),
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
                final currentIndex = controller.currentReplayIndex.value.clamp(0, maxIndex);
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
                      color: controller.isReplaying.value ? Colors.orange : Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      controller.isReplaying.value ? Icons.pause : Icons.play_arrow,
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
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: progress,
                      onChanged: (value) {
                        if (controller.trackPoints.isNotEmpty) {
                          final maxIndex = controller.trackPoints.length - 1;
                          if (maxIndex > 0) {
                            final newIndex = (value * maxIndex).round().clamp(0, maxIndex);
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
              controller.loadLocationData();
            }
          },
        ),
      ];

      // 绑定状态时显示另一半头像
      if (controller.isBindPartner.value && controller.partnerAvatar.value.isNotEmpty) {
        avatars.add(const SizedBox(width: 8));
        avatars.add(
          _AvatarButton(
            controller: controller,
            isMyself: false,
            onTap: () {
              if (controller.isOneself.value != 0) {
                controller.isOneself.value = 0;
                controller.loadLocationData();
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
    final size = isMyself ? 32.0 : 26.0;
    final radius = size / 2;
    final isSelected = isMyself ? controller.isOneself.value == 1 : controller.isOneself.value == 0;
    final avatarUrl = isMyself ? controller.myAvatar.value : controller.partnerAvatar.value;
    final defaultAsset = isMyself ? 'assets/kissu_track_header_boy.webp' : 'assets/kissu_track_header_girl.webp';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          image: isSelected
              ? const DecorationImage(
                  image: AssetImage('assets/kissu_track_header_bbg.webp'),
                  fit: BoxFit.cover,
                )
              : null,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: avatarUrl.isNotEmpty
              ? Image.network(
                  avatarUrl,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(defaultAsset, width: size, height: size, fit: BoxFit.cover);
                  },
                )
              : Image.asset(defaultAsset, width: size, height: size, fit: BoxFit.cover),
        ),
      ),
    );
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
              return RepaintBoundary(
                child: StopListItem(
                  record: record,
                  index: index,
                  isLast: isLast,
                ),
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
            return RepaintBoundary(
              child: StopListItem(
                record: record,
                index: index,
                isLast: isLast,
              ),
            );
          }).toList(),
        );
      }
    });
  }
}
