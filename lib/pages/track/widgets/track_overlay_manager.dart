import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../track_controller.dart';
import '../track_page_config.dart';

/// 遮罩效果管理器
/// 负责管理所有覆盖在地图上的遮罩效果
class TrackOverlayManager {
  final TrackController controller;

  TrackOverlayManager({required this.controller});

  /// 构建背景遮罩层
  Widget buildBackgroundOverlay() {
    return Obx(() {
      final opacity = (controller.sheetPercent.value - (TrackPageConfig.bindPartnerPanelHeight / MediaQuery.of(Get.context!).size.height)) * 0.6;
      return Positioned.fill(
        child: IgnorePointer(
          child: AnimatedOpacity(
            duration: TrackPageConfig.shortAnimation,
            opacity: opacity.clamp(0.0, TrackPageConfig.maxOverlayOpacity),
            child: Container(color: TrackPageConfig.overlayBlack.withValues(alpha: 1.0)),
          ),
        ),
      );
    });
  }

  /// 构建全屏渐变背景
  Widget buildGradientBackground() {
    return Obx(() {
      final screenHeight = MediaQuery.of(Get.context!).size.height;
      final initialHeight = TrackPageConfig.getInitialHeight(
        isBindPartner: controller.isBindPartner.value,
        isVip: false, // 这里需要从控制器获取
      );
      final maxHeight = screenHeight - TrackPageConfig.maxPanelOffset;

      return _GradientBackgroundOverlay(
        controller: controller,
        screenHeight: screenHeight,
        initialHeight: initialHeight,
        maxHeight: maxHeight,
      );
    });
  }

  /// 构建底部吸底图片
  Widget buildBottomImage() {
    return Obx(() {
      final currentPercent = controller.sheetPercent.value;
      final screenHeight = MediaQuery.of(Get.context!).size.height;
      final maxPercent = (screenHeight - TrackPageConfig.maxPanelOffset) / screenHeight;
      const imageHeight = TrackPageConfig.bottomImageHeight;
      final startShowPercent = (screenHeight - TrackPageConfig.maxPanelOffset - imageHeight) / screenHeight;

      double imageOpacity = 0.0;
      if (currentPercent >= startShowPercent && currentPercent <= maxPercent) {
        final progress = (currentPercent - startShowPercent) / (maxPercent - startShowPercent);
        imageOpacity = progress.clamp(0.0, 1.0);
      } else if (currentPercent > maxPercent) {
        imageOpacity = 1.0;
      }

      return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: IgnorePointer(
          ignoring: true,
          child: AnimatedOpacity(
            duration: TrackPageConfig.normalAnimation,
            opacity: imageOpacity,
            child: SizedBox(
              height: imageHeight,
              width: double.infinity,
              child: Image.asset(
                'assets/location/kissu3_track_bottom_bg.webp',
                width: MediaQuery.of(Get.context!).size.width,
                height: imageHeight,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('底部背景图片加载失败: $error');
                  return Container(
                    height: imageHeight,
                    color: const Color(0xFFE0E0E0),
                  );
                },
              ),
            ),
          ),
        ),
      );
    });
  }

  /// 构建地图logo
  Widget buildMapLogo() {
    return Obx(() {
      final screenHeight = MediaQuery.of(Get.context!).size.height;
      final sheetHeight = screenHeight * controller.sheetPercent.value;

      // 右侧轨迹回放按钮的bottom位置
      final buttonBottom = sheetHeight + 70;

      // logo在按钮下方，按钮高度50px，logo距离按钮15px
      final logoBottom = buttonBottom - 50 - 15;

      // 根据绑定状态动态计算中间吸顶位置
      final actualBindStatus = controller.getActualBindStatus();
      final middleSnapSize = actualBindStatus
          ? 0.5 + (21 / screenHeight)
          : 0.5 + (57 / screenHeight);
      final maxPercent = (screenHeight - TrackPageConfig.maxPanelOffset) / screenHeight;

      // 计算透明度
      final sheetPercent = controller.sheetPercent.value;
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
        left: TrackPageConfig.defaultPadding,
        child: Opacity(
          opacity: opacity,
          child: Image.asset(
            'assets/images/map_logo.webp',
            width: TrackPageConfig.mapLogoWidth,
            height: TrackPageConfig.mapLogoHeight,
          ),
        ),
      );
    });
  }
}

/// 全屏渐变背景遮罩组件
class _GradientBackgroundOverlay extends StatefulWidget {
  final TrackController controller;
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

  @override
  void initState() {
    super.initState();
    widget.controller.sheetPercent.listen((percent) {
      if ((percent - 0.0).abs() > 0.02) {
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
      newOpacity = (progress.clamp(0.0, 1.0)) * TrackPageConfig.maxGradientOpacity;
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
          duration: TrackPageConfig.normalAnimation,
          opacity: _opacity,
          child: Container(
            decoration: BoxDecoration(
              gradient: TrackPageConfig.panelGradient,
            ),
          ),
        ),
      ),
    );
  }
}
