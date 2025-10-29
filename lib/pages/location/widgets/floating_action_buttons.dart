import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routers/kissu_route_path.dart';
import '../../../services/tracking_service.dart';
import '../location_v2_controller.dart';

/// 右侧浮动按钮组
/// 包含位置提醒、轨迹、状态等功能按钮
class FloatingActionButtons extends StatelessWidget {
  final double screenHeight;
  final LocationV2Controller controller;

  const FloatingActionButtons({
    super.key,
    required this.screenHeight,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 获取当前滑动进度
      final sheetPercent = controller.sheetPercent.value;
      
      // 计算下半屏当前的顶部位置（从屏幕底部算起）
      final sheetHeight = screenHeight * sheetPercent;
      
      // 按钮固定在下半屏上方100px处
      final buttonBottom = sheetHeight + 70;

      // 🔧 根据绑定状态动态计算中间吸顶位置（与DraggableScrollableSheet的snapSize保持一致）
      final isBindPartner = controller.isBindPartner.value;
      final middleSnapSize = isBindPartner
          ? 0.5 + (21 / screenHeight) // 已绑定：屏幕中间 + 21px偏移
          : 0.5 + (57 / screenHeight); // 未绑定：屏幕中间 + 57px偏移

      // 计算顶部吸顶位置的百分比
      final maxPercent = (screenHeight - 100) / screenHeight;

      // 🔧 计算透明度：从中间吸顶位置向顶部吸顶位置移动时，逐渐消失
      double opacity;
      if (sheetPercent <= middleSnapSize) {
        // 在中间吸顶位置以下，完全显示
        opacity = 1.0;
      } else if (sheetPercent >= maxPercent) {
        // 到达顶部吸顶位置，完全消失
        opacity = 0.0;
      } else {
        // 在中间和顶部之间，线性渐变
        opacity = 1.0 - ((sheetPercent - middleSnapSize) / (maxPercent - middleSnapSize));
      }
      
      opacity = opacity.clamp(0.0, 1.0);

      return Positioned(
        right: 16,
        bottom: buttonBottom,
        child: Opacity(
          opacity: opacity,
          child: IgnorePointer(
            ignoring: opacity == 0.0, // 透明度为0时忽略点击
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 状态按钮
                FloatingButton(
                  assetPath: 'assets/location/kissu3_location_state_an.webp',
                  onTap: () {
                    // 埋点：当前状态按钮点击
                    TrackingService.trackCurrentStateButton();
                    Get.toNamed(KissuRoutePath.locationState);
                  },
                ),
                const SizedBox(height: 5),

                // 轨迹按钮（Ta的足迹）
                FloatingButton(
                  assetPath: 'assets/location/kissu3_location_track_an.webp',
                  onTap: () {
                    // 埋点：Ta的足迹按钮点击
                    TrackingService.trackHerTrackButton();
                    Get.toNamed(KissuRoutePath.track);
                  },
                ),
                const SizedBox(height: 5),

                // 位置提醒按钮
                FloatingButton(
                  assetPath: 'assets/location/kissu3_location_knock_an.webp',
                  onTap: () {
                    // 埋点：位置提醒按钮点击
                    TrackingService.trackLocationReminderButton();
                    Get.toNamed(KissuRoutePath.locationReminder);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

}

/// 单个浮动按钮
class FloatingButton extends StatelessWidget {
  final String assetPath;
  final VoidCallback onTap;

  const FloatingButton({
    super.key,
    required this.assetPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        // decoration: BoxDecoration(
        //   boxShadow: [
        //     BoxShadow(
        //       color: Colors.black.withOpacity(0.1),
        //       blurRadius: 8,
        //       offset: const Offset(0, 2),
        //     ),
        //   ],
        // ),
        child: Image.asset(
          assetPath,
          width: 50,
          height: 50,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
