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
    final screenHeight = MediaQuery.of(context).size.height;
    final double initialHeight = screenHeight * 0.3;
    final double minHeight = screenHeight * 0.3; // 最小高度设置为初始高度，防止滑得太低
    final double maxHeight = screenHeight - 150; // 最高只能到距离顶部150px
    final double mapHeight =
        screenHeight - initialHeight + 30; // 地图高度多30px，让地图和列表重叠

    return Scaffold(
      backgroundColor: Colors.white, // 改为白色背景
      body: Stack(
        children: [
          // 固定的地图模块
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: mapHeight,
            child: _buildMap(),
          ),

          // 背景遮罩层，随着下半屏上滑渐变
          Obx(() {
            // 计算遮罩透明度：从 0 到 0.4
            final opacity =
                (controller.sheetPercent.value -
                    (initialHeight / screenHeight)) *
                0.6;
            return Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: mapHeight,
              child: IgnorePointer(
                // 让遮罩不拦截触摸事件
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 100),
                  opacity: opacity.clamp(0.0, 0.4),
                  child: Container(color: Colors.black),
                ),
              ),
            );
          }),

          // 播放控制器 - 根据列表位置显示/隐藏
          Obx(() {
            final sheetPercent = controller.sheetPercent.value;
            final initialPosition = initialHeight / screenHeight;

            // 当sheet在初始位置附近时显示播放控制器
            // 扩大显示范围，确保进入页面时就能看到
            final opacity =
                (sheetPercent <= initialPosition + 0.15) ? 1.0 : 0.0;

            return AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              bottom: screenHeight * 0.3 + 20, // 放在列表上方
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: opacity,
                child: _buildPlayerControls(),
              ),
            );
          }),

          // 下半屏 DraggableScrollableSheet，扩大可拖动区域
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              controller.sheetPercent.value = notification.extent;
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
                    ), // 恢复圆角
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
                      // 阻止顶部区域的滚动通知冒泡，让拖动生效
                      if (notification is ScrollStartNotification) {
                        return true; // 阻止冒泡
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
                              color: Colors.white, // 列表背景色
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Color(0xffFFECEA),
                              ), // 添加边框
                            ),
                            child: Column(
                              children:
                                  controller.stopRecords.asMap().entries.map((
                                    entry,
                                  ) {
                                    final index = entry.key;
                                    final record = entry.value;
                                    final isLast =
                                        index ==
                                        controller.stopRecords.length - 1;
                                    return StopListItem(
                                      record: record,
                                      index: index,
                                      isLast: isLast,
                                    );
                                  }).toList(),
                            ),
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
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
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
          //顶部头像
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: _buildClickableImageRow(),
          ),
        ],
      ),
    );
  }

  //顶部头像
  Widget _buildClickableImageRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center, // 可选，控制 Row 内容对齐
      children: [
        // 第一个图片，32px
        GestureDetector(
          onTap: () {
            // 处理点击事件
            print('Image 1 clicked');
          },
          child: Container(
            padding: EdgeInsets.all(1), // 内边距，增加点击区域
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/kissu_track_header_bbg.webp'),
              ),
            ),
            child: Image.asset(
              'assets/kissu_track_header_boy.webp', // 替换为你的图片路径
              width: 32, // 设置图片宽度
              height: 32, // 设置图片高度
            ),
          ),
        ),
        SizedBox(width: 8), // 图片之间的间距
        // 第二个图片，26px
        GestureDetector(
          onTap: () {
            // 处理点击事件
            print('Image 2 clicked');
          },
          child: Container(
            padding: EdgeInsets.all(1), // 内边距，增加点击区域
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/kissu_track_header_bgirl.webp'),
              ),
            ),
            child: Image.asset(
              'assets/kissu_track_header_girl.webp', // 替换为你的图片路径
              width: 26, // 设置图片宽度
              height: 26, // 设置图片高度
            ),
          ),
        ),
      ],
    );
  }

  // 播放控制器组件 - 简化版
  Widget _buildPlayerControls() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Obx(() {
        final progress =
            controller.trackPoints.isEmpty
                ? 0.0
                : controller.currentReplayIndex.value /
                    (controller.trackPoints.length - 1);
        final isReplaying = controller.isReplaying.value;

        return Row(
          children: [
            // 播放/暂停按钮
            GestureDetector(
              onTap:
                  isReplaying ? controller.pauseReplay : controller.startReplay,
              child: Container(
                decoration: BoxDecoration(
                  color: isReplaying ? Colors.orange : Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isReplaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 时间和进度条
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // // 时间显示
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     Text(
                  //       currentTime,
                  //       style: const TextStyle(
                  //         fontSize: 12,
                  //         color: Colors.grey,
                  //       ),
                  //     ),
                  //     Text(
                  //       totalTime,
                  //       style: const TextStyle(
                  //         fontSize: 12,
                  //         color: Colors.grey,
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  // const SizedBox(height: 4),
                  // 进度条
                  SliderTheme(
                    data: SliderTheme.of(Get.context!).copyWith(
                      activeTrackColor: Colors.blue,
                      inactiveTrackColor: Colors.grey[300],
                      thumbColor: Colors.blue,
                      overlayColor: Colors.blue.withOpacity(0.2),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 5,
                      ),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: progress,
                      onChanged: (value) {
                        if (controller.trackPoints.isNotEmpty) {
                          final newIndex =
                              (value * (controller.trackPoints.length - 1))
                                  .round();
                          controller.currentReplayIndex.value = newIndex;
                          controller.mapController.move(
                            controller.trackPoints[newIndex],
                            controller.mapController.camera.zoom,
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  // 抽取地图组件
  Widget _buildMap() {
    return GetBuilder<TrackController>(
      id: 'map',
      builder: (controller) {
        return FlutterMap(
          mapController: controller.mapController,
          options: controller.mapOptions,
          children: [
            TileLayer(
              urlTemplate:
                  'https://webrd0{s}.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=2&style=8&x={x}&y={y}&z={z}',
              subdomains: const ['1', '2', '3', '4'],
              userAgentPackageName: 'com.example.kissu_app',
              tileProvider: NetworkTileProvider(),
              retinaMode: true, // 启用高清模式
            ),
            // 轨迹线
            if (controller.trackPoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: controller.trackPoints,
                    color: Colors.blue,
                    strokeWidth: 6.0,
                  ),
                ],
              ),
            // Markers
            Obx(() {
              final currentIndex = controller.currentReplayIndex.value;

              final markers = List<Marker>.from(controller.stayMarkers);

              // 添加当前位置标记
              if (controller.trackPoints.isNotEmpty) {
                markers.add(
                  Marker(
                    point: controller.trackPoints[currentIndex],
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.run_circle_outlined,
                      color: Color(0xff3B96FF),
                      size: 32,
                    ),
                  ),
                );
              }

              return MarkerLayer(markers: markers);
            }),
          ],
        );
      },
    );
  }

  // 日期选择模块
  Widget _buildDateSelector() {
    return DateSelector(
      onSelect: (date) {
        print("选择了日期: $date");
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
          Obx(() => _buildStat("保留次数", controller.stayCount.value.toString())),
          Obx(() => _buildStat("停留时间", controller.stayDuration.value)),
          Obx(() => _buildStat("移动距离", controller.moveDistance.value)),
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
