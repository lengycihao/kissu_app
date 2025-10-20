import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routers/kissu_route_path.dart';
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
      // 🔧 根据绑定状态动态计算按钮底部位置
      // 未绑定时设备信息模块高42px，需要向下偏移42px以对齐吸顶位置
      final isBindPartner = controller.isBindPartner.value;
      final deviceHeightDiff = -42.0; // 设备模块高度差
      final firstButtonBottom = isBindPartner
          ? screenHeight / 2 - deviceHeightDiff // 已绑定：屏幕中间
          : screenHeight / 2 - deviceHeightDiff; // 未绑定：向下偏移42px

      // 获取当前滑动进度
      final sheetPercent = controller.sheetPercent.value;

      // 🔧 动态计算中间吸顶位置（与DraggableScrollableSheet的snapSize保持一致）
      final middleSnapSize = isBindPartner
          ? 0.5 + (21 / screenHeight) // 已绑定：屏幕中间 + 21px偏移
          : 0.5 + (57 / screenHeight); // 未绑定：屏幕中间 + 57px偏移

      // 计算顶部吸顶位置的百分比
      final maxPercent = (screenHeight - 100) / screenHeight;

      // 🔧 计算透明度
      double opacity = _calculateOpacity(
        sheetPercent,
        middleSnapSize,
        maxPercent,
        screenHeight,
      );

      return Positioned(
        right: 16,
        bottom: firstButtonBottom,
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
                  onTap: () => Get.toNamed(KissuRoutePath.locationState),
                ),
                const SizedBox(height: 5),

                // 轨迹按钮
                FloatingButton(
                  assetPath: 'assets/location/kissu3_location_track_an.webp',
                  onTap: () => Get.toNamed(KissuRoutePath.track),
                ),
                const SizedBox(height: 5),

                // 位置提醒按钮
                FloatingButton(
                  assetPath: 'assets/location/kissu3_location_knock_an.webp',
                  onTap: () => Get.toNamed(KissuRoutePath.locationReminder),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// 计算透明度
  double _calculateOpacity(
    double sheetPercent,
    double middleSnapSize,
    double maxPercent,
    double screenHeight,
  ) {
    if (sheetPercent <= middleSnapSize) {
      return 1.0;
    } else if (sheetPercent >= maxPercent) {
      return 0.0;
    } else {
      // 线性插值：从middleSnapSize到maxPercent之间，透明度从1降到0
      return ((maxPercent - sheetPercent) /
              (maxPercent - middleSnapSize - 20 / screenHeight))
          .clamp(0.0, 1.0);
    }
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
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
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
