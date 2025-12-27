import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../location_v2_controller.dart';
import '../map_gif_test_page.dart';

/// 左侧浮动按钮组
/// 包含刷新和切换地图类型功能
class LeftFloatingButtons extends StatelessWidget {
  final double screenHeight;
  final LocationV2Controller controller;

  const LeftFloatingButtons({
    super.key,
    required this.screenHeight,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 🔧 根据绑定状态动态计算按钮底部位置（与右侧按钮对齐）
      final isBindPartner = controller.isBindPartner.value;
      final deviceHeightDiff = -42.0; // 设备模块高度差
      final firstButtonBottom = isBindPartner
          ? screenHeight / 2 - deviceHeightDiff // 已绑定：屏幕中间
          : screenHeight / 2 - deviceHeightDiff; // 未绑定：向下偏移42px

      // 使用与右侧按钮相同的透明度计算逻辑
      final sheetPercent = controller.sheetPercent.value;

      // 🔧 动态计算中间吸顶位置（与DraggableScrollableSheet的snapSize保持一致）
      final middleSnapSize = isBindPartner
          ? 0.5
          : 0.5 + (deviceHeightDiff / screenHeight);

      final maxPercent = (screenHeight - 100) / screenHeight;

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
              
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                      child: Image(
                        image: AssetImage(
                          'assets/location/kissu3_change_map.webp',
                        ),
                        fit: BoxFit.contain,
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ), const SizedBox(height: 12),
                  // 刷新按钮
                  GestureDetector(
                    onTap: () async {
                      await controller.refreshLocationData();
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Image(
                        image: AssetImage(
                          'assets/location/kissu_refresh_map.webp',
                        ),
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 切换视图按钮
                  GestureDetector(
                    onTap: () {
                      controller.cycleMapView();
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Image(
                        image: AssetImage(
                          'assets/location/kissu_exchange_avair.webp',
                        ),
                        fit: BoxFit.contain,
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // // GIF测试入口按钮
                  // GestureDetector(
                  //   onTap: () {
                  //     Get.to(() => const MapGifTestPage());
                  //   },
                  //   child: Container(
                  //     width: 24,
                  //     height: 24,
                  //     decoration: BoxDecoration(
                  //       color: Colors.pink,
                  //       borderRadius: BorderRadius.circular(22),
                  //     ),
                  //     child: const Center(
                  //       child: Text(
                  //         'GIF',
                  //         style: TextStyle(
                  //           color: Colors.white,
                  //           fontSize: 8,
                  //           fontWeight: FontWeight.bold,
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
               
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
      builder: (context) => MapTypePickerSheet(controller: controller),
    );
  }
}

/// 地图类型选择弹窗
class MapTypePickerSheet extends StatelessWidget {
  final LocationV2Controller controller;

  const MapTypePickerSheet({
    super.key,
    required this.controller,
  });

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
                    () => MapTypeOption(
                      imagePath: 'assets/images/kissu3_map_custom.webp',
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
                    () => MapTypeOption(
                      imagePath: 'assets/images/kissu3_map_3d.webp',
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

/// 地图类型选项组件
class MapTypeOption extends StatelessWidget {
  final String imagePath;
  final String label;
  final bool isSelected;

  const MapTypeOption({
    super.key,
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
