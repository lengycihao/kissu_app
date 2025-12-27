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
 
  /// 构建右侧轨迹播放浮动按钮
  Widget buildRightReplayButton() {
    return TrackReplayFloatingButton(
      controller: controller,
      screenHeight: MediaQuery.of(Get.context!).size.height,
    );
  }

  /// 构建返回按钮
  Widget buildBackButton(BuildContext context, ScrollController? scrollController) {
    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: 5,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => controller.handleBackButtonTap(scrollController),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Image.asset(
            'assets/images/kissu_mine_back.webp',
            width: 22,
            height: 22,
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
