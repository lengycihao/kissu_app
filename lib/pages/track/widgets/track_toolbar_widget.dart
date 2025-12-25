import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../widgets/smooth_avatar_widget.dart';
import '../../../network/tools/logging/logging.dart';
import '../track_controller.dart';
import '../track_page_config.dart';
import 'track_replay_floating_button.dart';

/// 工具栏组件管理器
/// 负责管理所有悬浮按钮和工具栏组件
class TrackToolbarWidget {
  final TrackController controller;

  TrackToolbarWidget({required this.controller});

  /// 构建左侧浮动按钮组
  Widget buildLeftFloatingButtons() {
    return Obx(() {
      final sheetPercent = controller.sheetPercent.value;
      final screenHeight = MediaQuery.of(Get.context!).size.height;

      // 计算第一个按钮的底部位置
      const deviceHeightDiff = -42.0;
      const extraOffset = 80.0;
      final firstButtonBottom = screenHeight / 2 - deviceHeightDiff + extraOffset;

      // 计算透明度
      const middleSnapSize = 0.6;
      const maxPercent = 0.95;
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
        left: TrackPageConfig.defaultPadding,
        bottom: firstButtonBottom,
        child: Opacity(
          opacity: opacity,
          child: IgnorePointer(
            ignoring: opacity == 0.0,
            child: Container(
              decoration: BoxDecoration(
                color: TrackPageConfig.backgroundWhite,
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 刷新按钮
                  GestureDetector(
                    onTap: () async => await controller.refreshCurrentUserData(),
                    child: Container(
                      width: TrackPageConfig.buttonSize,
                      height: TrackPageConfig.buttonSize,
                      decoration: BoxDecoration(
                        color: TrackPageConfig.backgroundWhite,
                        borderRadius: BorderRadius.circular(TrackPageConfig.buttonBorderRadius),
                      ),
                      child: const Image(
                        image: AssetImage('assets/location/kissu_refresh_map.webp'),
                        width: TrackPageConfig.buttonSize,
                        height: TrackPageConfig.buttonSize,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // 切换地图类型按钮
                  GestureDetector(
                    onTap: () => _showMapTypePicker(Get.context!),
                    child: Container(
                      width: TrackPageConfig.buttonSize,
                      height: TrackPageConfig.buttonSize,
                      decoration: BoxDecoration(
                        color: TrackPageConfig.backgroundWhite,
                        borderRadius: BorderRadius.circular(TrackPageConfig.buttonBorderRadius),
                      ),
                      child: const Image(
                        image: AssetImage('assets/location/kissu3_change_map.webp'),
                        fit: BoxFit.contain,
                        width: TrackPageConfig.buttonSize,
                        height: TrackPageConfig.buttonSize,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  /// 构建右侧轨迹播放浮动按钮
  Widget buildRightReplayButton() {
    return TrackReplayFloatingButton(
      controller: controller,
      screenHeight: MediaQuery.of(Get.context!).size.height,
    );
  }

  /// 构建返回按钮
  Widget buildBackButton() {
    return Positioned(
      top: MediaQuery.of(Get.context!).padding.top + TrackPageConfig.defaultPadding,
      left: TrackPageConfig.defaultPadding,
      child: Container(
        decoration: BoxDecoration(
          color: TrackPageConfig.backgroundWhite.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [TrackPageConfig.backButtonShadow],
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => controller.handleBackButtonTap(null), // 这里需要传递scrollController
          child: AnimatedBuilder(
            animation: controller.backButtonRotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: controller.backButtonRotationAnimation.value * 2 * 3.14159,
                child: const Image(
                  image: AssetImage('assets/images/kissu_mine_back.webp'),
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 构建顶部头像行
  Widget buildAvatarRow() {
    return Positioned(
      top: MediaQuery.of(Get.context!).padding.top + TrackPageConfig.defaultPadding,
      left: 0,
      right: 0,
      child: _CachedAvatarRow(controller: controller),
    );
  }

  /// 显示地图类型选择弹窗
  void _showMapTypePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MapTypePickerSheet(controller: controller),
    );
  }
}

/// 优化的头像行组件
class _CachedAvatarRow extends StatelessWidget {
  final TrackController controller;

  const _CachedAvatarRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 未绑定时不展示任何头像
      if (!controller.isBindPartner.value) {
        return const SizedBox.shrink();
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 显示另一半头像（左边）
          _AvatarButton(
            controller: controller,
            isMyself: false,
            onTap: () {
              if (controller.isOneself.value != 0) {
                controller.onAvatarTapped(false);
                HapticFeedback.lightImpact();
                logDebug('🎯 头像点击：切换到查看另一半的轨迹数据', tag: 'TrackPage');
              }
            },
          ),
          const SizedBox(width: 8),
          // 显示自己的头像（右边）
          _AvatarButton(
            controller: controller,
            isMyself: true,
            onTap: () {
              if (controller.isOneself.value != 1) {
                controller.onAvatarTapped(true);
                HapticFeedback.lightImpact();
                logDebug('🎯 头像点击：切换到查看自己的轨迹数据', tag: 'TrackPage');
              }
            },
          ),
        ],
      );
    });
  }
}

/// 优化的头像按钮组件
class _AvatarButton extends StatefulWidget {
  final TrackController controller;
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

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentIsOneselfValue = widget.controller.isOneself.value;
      final isSelected = (widget.isMyself && currentIsOneselfValue == 1) ||
          (!widget.isMyself && currentIsOneselfValue == 0);

      final actualSize = (isSelected && _isAvatarLoaded)
          ? TrackPageConfig.avatarSizeSelected
          : TrackPageConfig.avatarSizeUnselected;

      final avatarUrl = widget.isMyself
          ? widget.controller.myAvatar.value
          : widget.controller.partnerAvatar.value;

      return GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: TrackPageConfig.longAnimation,
              curve: Curves.easeOut,
              width: actualSize,
              height: actualSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: (isSelected && _isAvatarLoaded)
                    ? Border.all(
                        color: TrackPageConfig.secondaryPink,
                        width: 1,
                      )
                    : null,
                boxShadow: (isSelected && _isAvatarLoaded)
                    ? [TrackPageConfig.avatarShadow]
                    : null,
              ),
              child: SmoothAvatarWidget(
                avatarUrl: avatarUrl.isNotEmpty ? avatarUrl : null,
                defaultAsset: '',
                width: actualSize,
                height: actualSize,
                borderRadius: BorderRadius.circular(actualSize / 2),
                fit: BoxFit.cover,
                onImageLoaded: () {
                  setState(() {
                    _isAvatarLoaded = true;
                  });
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// 地图类型选择弹窗
class _MapTypePickerSheet extends StatelessWidget {
  final TrackController controller;

  const _MapTypePickerSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TrackPageConfig.backgroundWhite,
        borderRadius: TrackPageConfig.panelTopBorderRadiusGeometry,
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: TrackPageConfig.defaultPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部拖动条
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: TrackPageConfig.borderGray,
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
                    () => _MapTypeOption(
                      imagePath: 'assets/images/kissu3_map_custom.webp',
                      label: '经典地图',
                      isSelected: controller.mapType.value == 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: TrackPageConfig.defaultPadding),
              // 卫星地图
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    controller.switchMapType(2);
                    Navigator.pop(context);
                  },
                  child: Obx(
                    () => _MapTypeOption(
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
class _MapTypeOption extends StatelessWidget {
  final String imagePath;
  final String label;
  final bool isSelected;

  const _MapTypeOption({
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
            borderRadius: TrackPageConfig.defaultBorderRadius,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFFD1E4)
                  : TrackPageConfig.backgroundWhite,
              width: isSelected ? 5 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: TrackPageConfig.defaultBorderRadius,
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
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
                      : TrackPageConfig.backgroundWhite,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: TrackPageConfig.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
