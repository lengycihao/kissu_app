import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';
import '../location_v2_controller.dart';
import 'floating_tips_widget.dart';

/// 定位页面覆盖层管理器
/// 负责管理各种覆盖层组件：渐变背景、提示信息、过渡动画等
class LocationOverlayManager {
  final LocationV2Controller controller;
  double _opacity = 0.0;
  double _lastPercent = 0.0;

  LocationOverlayManager({required this.controller}) {
    // 监听sheetPercent变化来更新渐变背景透明度
    controller.sheetPercent.listen((percent) {
      if ((percent - _lastPercent).abs() > 0.02) {
        _lastPercent = percent;
        _updateOpacity(percent);
      }
    });
  }

  

  /// 构建切换视图时的过渡动画
  Widget buildSwitchTransition() {
    return Obx(() {
      if (!controller.isSwitchingView.value) {
        return const SizedBox.shrink();
      }
      return AnimatedBuilder(
        animation: controller.switchTransitionAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: controller.switchTransitionAnimation.value,
            child: Container(
              color: const Color(0xFFFFF6EF),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B9D)),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  /// 构建渐变背景覆盖层
  Widget buildGradientBackground() {
    return Builder(
      builder: (context) => Obx(
        () => _GradientBackgroundOverlay(
          controller: controller,
          screenHeight: MediaQuery.of(context).size.height,
          initialHeight: _calculateInitialHeight(),
          maxHeight: MediaQuery.of(context).size.height - 100,
          opacity: _opacity,
        ),
      ),
    );
  }

  /// 构建浮动提示组件
  Widget buildFloatingTips() {
    return Builder(
      builder: (context) => FloatingTipsWidget(
        controller: controller,
        tipsManager: controller.tipsManager,
        screenHeight: MediaQuery.of(context).size.height,
      ),
    );
  }

  /// 构建离线提示覆盖层
  Widget buildOfflineTipOverlay() {
    return Builder(
      builder: (context) => Obx(() {
        if (!(controller.isBindPartner.value &&
            controller.partnerOnlineStatus.value != null &&
            controller.partnerOnlineStatus.value!.status == 0)) {
          return const SizedBox.shrink();
        }

        final sheetPercent = controller.sheetPercent.value;
        final isBindPartner = controller.isBindPartner.value;
        final middleSnapSize = isBindPartner
            ? 0.5 + (21 / MediaQuery.of(context).size.height)
            : 0.5 + (57 / MediaQuery.of(context).size.height);
        final maxPercent = (MediaQuery.of(context).size.height - 100) /
            MediaQuery.of(context).size.height;
        double opacity;
        if (sheetPercent <= middleSnapSize) {
          opacity = 1.0;
        } else if (sheetPercent >= maxPercent) {
          opacity = 0.0;
        } else {
          opacity =
              1.0 -
              ((sheetPercent - middleSnapSize) / (maxPercent - middleSnapSize));
        }
        opacity = opacity.clamp(0.0, 1.0);

        final bottom = (MediaQuery.of(context).size.height * sheetPercent) + 8;

        return Positioned(
          left: 0,
          right: 0,
          bottom: bottom,
          child: Opacity(
            opacity: opacity,
            child: IgnorePointer(
              ignoring: opacity == 0.0,
              child: _buildOfflineTip(
                margin: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ),
        );
      }),
    );
  }

  /// 构建底部吸底图片
  Widget buildBottomImage() {
    return Obx(() {
      final currentPercent = controller.sheetPercent.value;
      final screenHeight = MediaQuery.of(Get.context!).size.height;
      final maxPercent = (screenHeight - 100.0) / screenHeight; // 使用固定的最大偏移
      const imageHeight = 115.0; // 底部图片高度
      final startShowPercent = (screenHeight - 100.0 - imageHeight) / screenHeight;

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
            duration: const Duration(milliseconds: 200),
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
                  return Container();
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
    return Builder(
      builder: (context) => Obx(() {
        final sheetHeight = MediaQuery.of(context).size.height * controller.sheetPercent.value;

        final logoBottom = sheetHeight + 5;

        final isBindPartner = controller.isBindPartner.value;
        final middleSnapSize = isBindPartner
            ? 0.5 + (21 / MediaQuery.of(context).size.height)
            : 0.5 + (57 / MediaQuery.of(context).size.height);
        final maxPercent = (MediaQuery.of(context).size.height - 100) /
            MediaQuery.of(context).size.height;

      final sheetPercent = controller.sheetPercent.value;
      double opacity;
      if (sheetPercent <= middleSnapSize) {
        opacity = 1.0;
      } else if (sheetPercent >= maxPercent) {
        opacity = 0.0;
      } else {
        opacity =
            1.0 -
            ((sheetPercent - middleSnapSize) / (maxPercent - middleSnapSize));
      }
      opacity = opacity.clamp(0.0, 1.0);

        return Positioned(
          bottom: logoBottom,
          left: 16,
          child: Opacity(
            opacity: opacity,
            child: Image.asset(
              'assets/images/map_logo.webp',
              width: 68,
              height: 22,
            ),
          ),
        );
      }),
    );
  }

  /// 构建离线提示
  Widget _buildOfflineTip({EdgeInsets? margin}) {
    String offlineTime = '';
    if (controller.partnerOnlineStatus.value!.updateTime != null) {
      offlineTime =
          controller.partnerOnlineStatus.value!.updateTime!;
    }

    return GestureDetector(
      onTap: () {
        controller.navigateToQuestionPage(
          controller.partnerOnlineStatus.value!.problemId,
        );
      },
      child: Container(
        width: double.infinity,
        margin: margin ?? EdgeInsets.only(left: 14, right: 14, bottom: 10),
        padding: EdgeInsets.only(left: 10, right: 10),
        height: 28,
        decoration: BoxDecoration(
          color: Color(0xffFFFCE8),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Row(
          children: [
            Image.asset(
              'assets/phone_history/kissu3_history_yichang.webp',
              width: 16,
              height: 16,
            ),
            SizedBox(width: 4),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ta离线啦${offlineTime.isNotEmpty ? '，离线时间: $offlineTime' : ''}',
                  style: TextStyle(fontSize: 12, color: Color(0xFF333333)),
                  maxLines: 1,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '查看原因',
                  style: TextStyle(fontSize: 13, color: Color(0xFFFF9500)),
                ),
                const SizedBox(width: 4),
                Image.asset(
                  'assets/phone_history/kissu3_arrow_blue.webp',
                  color: Color(0xFFAD6D48),
                  width: 16,
                  height: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 计算初始高度
  double _calculateInitialHeight() {
    final isBindPartner = controller.isBindPartner.value;
    final isVip = controller.isVip.value;
    return (!isBindPartner || !isVip) ? 310 : 190;
  }

  /// 更新渐变背景透明度
  void _updateOpacity(double currentPercent) {
    // 由于我们现在使用Builder包装，这个方法可能不需要手动更新
    // UI会通过Obx自动更新
  }
}

/// 渐变背景覆盖层组件
class _GradientBackgroundOverlay extends StatelessWidget {
  final LocationV2Controller controller;
  final double screenHeight;
  final double initialHeight;
  final double maxHeight;
  final double opacity;

  const _GradientBackgroundOverlay({
    required this.controller,
    required this.screenHeight,
    required this.initialHeight,
    required this.maxHeight,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: opacity,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF6F6F6),
                  Color(0xFFFFFFFF),
                  Color(0xFFF6F6F6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
