import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/services/analytics/analytics_events.dart';
import 'package:kissu_app/utils/source_page_utils.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';
import '../track_controller.dart';
import '../track_replay_page/track_replay_controller.dart';
import '../track_replay_page/track_replay_page.dart';
import 'package:kissu_app/services/analytics/analytics_helper.dart';

/// 轨迹播放浮动按钮
/// 参考定位页面的右侧浮动按钮实现，跟随下半屏滑动渐变
class TrackReplayFloatingButton extends StatelessWidget {
  final TrackController controller;
  final double screenHeight;

  const TrackReplayFloatingButton({
    super.key,
    required this.controller,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 获取当前滑动进度
      final sheetPercent = controller.sheetPercent.value;
      
      // 🔧 修复：跟随下半屏滑动，与定位页面保持一致
      final sheetHeight = screenHeight * sheetPercent;
      
      // 右侧按钮的bottom位置（在下半屏顶部上方30px）
      final buttonBottom = sheetHeight + 30;

      // 根据绑定状态动态计算中间吸顶位置（与DraggableScrollableSheet的snapSize保持一致）
      final actualBindStatus = controller.getActualBindStatus();
      final middleSnapSize = actualBindStatus
          ? 0.5 + (21 / screenHeight) // 已绑定：屏幕中间 + 21px偏移
          : 0.5 + (57 / screenHeight); // 未绑定：屏幕中间 + 57px偏移

      // 计算顶部吸顶位置的百分比
      final maxPercent = (screenHeight - 100) / screenHeight;

      // 计算透明度：从中间吸顶位置向顶部吸顶位置移动时，逐渐消失
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
            child: GestureDetector(
              onTap: () => _onPlayButtonTap(context),
              child: Container(
                width: 50,
                height: 50,
                child: Image.asset(
                  'assets/3.0/kissu3_track_play_icon.webp',
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  /// 播放按钮点击事件
  void _onPlayButtonTap(BuildContext context) {
    // 埋点：轨迹回放按钮点击
    AnalyticsHelper.trackTrackHistoryReplay();
    
    // 🔥 非会员点击轨迹回放按钮时跳转VIP页面
    final isVip = UserManager.isVip;
    if (!isVip) {
      // 埋点：页面离开（进入下一页）
      controller.onNavigateToNextPage?.call();
      
      Get.toNamed(
        KissuRoutePath.vip,
        arguments: {
          'source_page': SourcePageUtilsCaller.track,
          'source_event': TrackEvents.page,
        },
      );
      return;
    }
    
    // 检查是否有有效的轨迹数据
    if (controller.trackPoints.length < 3) {
      CustomToast.show(context, '暂无足够的轨迹数据可回放');
      return;
    }

    // 创建播放页面控制器
    final replayController = TrackReplayController(
      trackPoints: controller.trackPoints.toList(),
      stopPoints: controller.stopPoints.toList(),
      currentUserAvatar: _getCurrentUserAvatar(),
      // mapType: controller.mapType.value,
    );

    // 注册控制器
    Get.put(replayController);

    // 埋点：页面离开（进入下一页）
    controller.onNavigateToNextPage?.call();

    // 跳转到播放页面
    Get.to(
      () => const TrackReplayPage(),
      transition: Transition.rightToLeft,
    )?.then((_) {
      // 返回时删除控制器
      Get.delete<TrackReplayController>();
    });
  }

  /// 获取当前用户头像
  String _getCurrentUserAvatar() {
    if (controller.isOneself.value == 1) {
      return controller.myAvatar.value;
    } else {
      return controller.partnerAvatar.value;
    }
  }
}

