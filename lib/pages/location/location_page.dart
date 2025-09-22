import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:kissu_app/widgets/device_info_item.dart';
import 'package:kissu_app/widgets/safe_amap_widget.dart';
import 'package:kissu_app/widgets/smooth_avatar_widget.dart';
import 'package:kissu_app/pages/track/track_page.dart';
import 'package:kissu_app/pages/track/track_binding.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
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
    mapHeight = screenHeight - initialHeight + 90;
  }

  @override
  Widget build(BuildContext context) {
    widget.controller.pageContext = context; // 保存 Scaffold 的 context
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
            child: Builder(
              builder: (context) {
                // 非会员时禁用拖动
                final isVip = UserManager.isVip;
                return DraggableScrollableSheet(
                initialChildSize: initialHeight / screenHeight,
                minChildSize: isVip ? minHeight / screenHeight : initialHeight / screenHeight,
                maxChildSize: isVip ? maxHeight / screenHeight : initialHeight / screenHeight,
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
                        child: Stack(
                          children: [
                            NotificationListener<ScrollNotification>(
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
                                        // 虚拟数据提示文字 - 设备信息模块上方居中显示
                                        Obx(() {
                                          if (!widget.controller.isBindPartner.value) {
                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 2),
                                              alignment: Alignment.center,
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
                                child: Stack(
                                  children: [
                                    Container(
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
                          
                                        return _OptimizedLocationRecordsList(
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
                            // 统一的会员限制遮罩层 - 覆盖整个滚动区域
                            if (!UserManager.isVip)
                              Positioned.fill(
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
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
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
class _CachedMapWidget extends StatefulWidget {
  final LocationController controller;

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
      if (_lastMarkersLength != markersLength || _lastPolylinesLength != polylinesLength) {
        _cachedMarkers = widget.controller.markers;
        _cachedPolylines = widget.controller.polylines;
        _lastMarkersLength = markersLength;
        _lastPolylinesLength = polylinesLength;
        
        print('🗺️ 地图Widget重建 - 标记数量: ${markersLength}, 连接线数量: ${polylinesLength}');
        if (_cachedMarkers != null && _cachedMarkers!.isNotEmpty) {
          print('🗺️ 标记详情: ${_cachedMarkers!.map((m) => '标记: ${m.position}').join(', ')}');
        }
      }
      
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
  final LocationController controller;
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
      final isSelected = (widget.isMyself && currentIsOneselfValue == 1) || 
                        (!widget.isMyself && currentIsOneselfValue == 0);
      
      // 只有当选中状态真正发生变化时才打印调试信息，减少日志噪音
      if (_lastIsOneselfValue != currentIsOneselfValue || _lastIsSelectedValue != isSelected) {
        print('🎯 头像选中状态变化 - isMyself: ${widget.isMyself}, isOneself: $currentIsOneselfValue, isSelected: $isSelected, isAvatarLoaded: $_isAvatarLoaded');
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
  final LocationController controller;

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
        return SizedBox(
          height: 400, // 限制高度，启用滚动
          child: Column(
            children: [
              Obx(() {
                final recordCount = controller.locationRecords.length;
                return Row(
                  children: [
                    Text(
                      "今日TA停留$recordCount个地方",
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
                    "今日TA停留$recordCount个地方",
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
            }),
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
          Get.to(() => TrackPage(
            initialLatitude: record.latitude!,
            initialLongitude: record.longitude!,
            initialLocationName: record.locationName,
            initialDuration: record.duration,
            initialStartTime: record.startTime,
            initialEndTime: record.endTime,
          ), binding: TrackBinding());
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
                          _getLeftText(record),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFFF4177),
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

