import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amap_map/amap_map.dart';
import 'package:kissu_app/widgets/device_info_item.dart';
import 'location_controller.dart';

class LocationPage extends StatelessWidget {
  LocationPage({super.key});

  final controller = Get.put(LocationController());

  @override
  Widget build(BuildContext context) {
    return _LocationPageContent(controller: controller);
  }
}

// 将主要内容提取为单独的StatefulWidget以优化性能
class _LocationPageContent extends StatefulWidget {
  final LocationController controller;

  const _LocationPageContent({required this.controller});

  @override
  State<_LocationPageContent> createState() => _LocationPageContentState();
}

class _LocationPageContentState extends State<_LocationPageContent> {
  late double screenHeight;
  late double initialHeight;
  late double minHeight;
  late double maxHeight;
  late double mapHeight;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在这里计算屏幕尺寸相关参数
    screenHeight = MediaQuery.of(context).size.height;
    initialHeight = screenHeight * 0.45;
    minHeight = screenHeight * 0.45;
    maxHeight = screenHeight - 150;
    mapHeight = screenHeight - initialHeight + 30;
  }

  @override
  Widget build(BuildContext context) {
    widget.controller.pageContext = context; // 保存 Scaffold 的 context
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 测试单次定位
          widget.controller.testSingleLocation();
        },
        backgroundColor: const Color(0xFFFF4177),
        child: const Icon(
          Icons.gps_fixed,
          color: Colors.white,
        ),
      ),
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

          // 未绑定提示 - 放置在下半屏上方
          // Positioned(
          //   bottom: screenHeight * 0.3 + 20,
          //   left: 20,
          //   right: 20,
          //   child: _FloatingUnbindNotification(
          //     controller: widget.controller,
          //     screenHeight: screenHeight,
          //     initialHeight: initialHeight,
          //   ),
          // ),
          
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
                  children: [ // 未绑定提示 - 放置在播放按钮和下半屏之间
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
                                        // 虚拟数据提示
                                        Obx(() {
                                          if (widget.controller.isUsingMockData.value) {
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
                                        _buildDeviceInfoSection(),
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
                                    left: 15,
                                    right: 15,
                                    top: 20,
                                    bottom: 15,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 15,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Color(0xffFF88AA)),
                                  ),
                                  child: Obx(() {
                                    if (widget.controller.locationRecords.isEmpty) {
                                      return Container(
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
                      
                                    return _OptimizedLocationRecordsList(
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

  // 设备信息模块
  Widget _buildDeviceInfoSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      margin: EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/kissu_location_device_bg.webp'),
          fit: BoxFit.fill,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 距离和更新时间
          Row(
            children: [
              const Text(
                '我们距离',
                style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
              ),
              const SizedBox(width: 8),
              Obx(
                () => Text(
                  widget.controller.distance.value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000000),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Image(
                image: AssetImage('assets/kissu_location_time_logo.webp'),
                width: 16,
                height: 16,
              ),
              Obx(
                () => Text(
                  widget.controller.speed.value,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF333333)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE8A4),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "位置",
                  style: TextStyle(fontSize: 14, color: Color(0xFF000000)),
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Obx(() {
                  return Text(
                    widget.controller.currentLocationText.value,
                    style: TextStyle(fontSize: 12, color: Color(0xFF333333)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 设备信息行
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Obx(
                    () => DeviceInfoItem(
                      text: widget.controller.myDeviceModel.value,
                      iconPath: 'assets/phone_history/kissu_phone_type.webp',
                      isDevice: true,
                      onLongPress: widget.controller.showTooltip,
                    ),
                  ),
                ),
                Expanded(
                  child: Obx(
                    () => DeviceInfoItem(
                      text: widget.controller.myBatteryLevel.value,
                      iconPath: 'assets/phone_history/kissu_phone_barry.webp',
                      isDevice: false,
                      onLongPress: widget.controller.showTooltip,
                    ),
                  ),
                ),
                Expanded(
                  child: Obx(
                    () => DeviceInfoItem(
                      text: widget.controller.myNetworkName.value,
                      iconPath: 'assets/phone_history/kissu_phone_wifi.webp',
                      isDevice: false,
                      onLongPress: widget.controller.showTooltip,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 优化的遮罩层Widget - 减少重建频率
class _OptimizedOverlayWidget extends StatelessWidget {
  final LocationController controller;
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
  final LocationController controller;

  const _CachedMapWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 创建标记集合
      Set<Marker> markers = {};
      
      // 添加我的位置标记
      if (controller.myLocation.value != null) {
        markers.add(Marker(
          position: controller.myLocation.value!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ));
      }
      
      // 添加另一半位置标记
      if (controller.partnerLocation.value != null) {
        markers.add(Marker(
          position: controller.partnerLocation.value!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
        ));
      }
      
      // 创建连接线集合
      Set<Polyline> polylines = {};
      if (controller.myLocation.value != null &&
          controller.partnerLocation.value != null) {
        polylines.add(Polyline(
          points: [
            controller.myLocation.value!,
            controller.partnerLocation.value!,
          ],
          color: const Color(0xFFFF6B9D),
          width: 3,
        ));
      }
      
      return RepaintBoundary(
        child: AMapWidget(
          initialCameraPosition: controller.initialCameraPosition,
          onMapCreated: controller.onMapCreated,
          mapType: MapType.normal,
          markers: markers,
          polylines: polylines,
          zoomGesturesEnabled: true,
          scrollGesturesEnabled: true,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: true,
          compassEnabled: false,
          scaleEnabled: false,
        ),
      );
    });
  }
}


// 优化的头像行Widget
class _CachedAvatarRow extends StatelessWidget {
  final LocationController controller;

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
  final LocationController controller;
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
    final isSelected = isMyself
        ? controller.isOneself.value == 1
        : controller.isOneself.value == 0;
    final avatarUrl = isMyself
        ? controller.myAvatar.value
        : controller.partnerAvatar.value;
    final defaultAsset = isMyself
        ? 'assets/kissu_track_header_boy.webp'
        : 'assets/kissu_track_header_girl.webp';

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
                    return Image.asset(
                      defaultAsset,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                    );
                  },
                )
              : Image.asset(
                  defaultAsset,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                ),
        ),
      ),
    );
  }
}

// 优化的定位记录列表Widget
class _OptimizedLocationRecordsList extends StatelessWidget {
  final LocationController controller;

  const _OptimizedLocationRecordsList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final records = controller.locationRecords;

      // 使用ListView.builder优化大列表性能
      if (records.length > 10) {
        return SizedBox(
          height: 400, // 限制高度，启用滚动
          child: Column(
            children: [
              Obx(() {
                final recordCount = controller.locationRecords.length;
                return Row(
                  children: [
                    Text(
                      "今日TA停留${recordCount}个地方",
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
              SizedBox(height: 16,),
              ListView.builder(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  final isLast = index == records.length - 1;
                  return RepaintBoundary(
                    child: _LocationRecordItem(
                      record: record,
                      index: index,
                      isLast: isLast,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      } else {
        // 少量数据时使用Column
        return Column(
          children: [
            Obx(() {
              final recordCount = controller.locationRecords.length;
              return Row(
                children: [
                  Text(
                    "今日TA停留${recordCount}个地方",
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
              SizedBox(height: 16,),
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
            }).toList(),
          ],
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧时间
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Image(image: AssetImage('assets/kissu_location_circle.webp'),width: 8,height: 8,),
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
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFFFFEDF2), Color(0xFFFFF5F8)],
                    ),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/kissu_track_location.webp',
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "停留${record.duration ?? '未知'}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFFF4177),
                        ),
                      ),
                      Spacer(),
                      Text(
                        _formatTimeRange(record.startTime, record.endTime),
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
    );
  }
}

// 浮动未绑定提示组件 - 位于播放按钮和下半屏之间
class _FloatingUnbindNotification extends StatelessWidget {
  final LocationController controller;
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
