import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/mine/mine_controller.dart';
import 'package:kissu_app/widgets/relationship_animation_overlay.dart';
import 'package:kissu_app/network/tools/logging/log_manager.dart';
import 'package:kissu_app/pages/home/home_controller.dart';
import 'package:kissu_app/pages/location/location_v2_controller.dart';
import 'package:kissu_app/pages/track/track_controller.dart';

/// 情侣关系动画服务
/// 负责显示绑定/解绑关系时的GIF动画
class RelationshipAnimationService extends GetxService {
  static RelationshipAnimationService get instance => Get.find<RelationshipAnimationService>();

  // GIF资源路径
  static const String bindGifPath = 'assets/gif/bind_success.gif';
  static const String unbindGifPath = 'assets/gif/unbind_success.gif';

  // 当前是否正在显示动画
  bool _isShowingAnimation = false;

  /// 显示绑定成功动画（3秒）
  /// 
  /// [onComplete] 动画播放完成后的回调
  void showBindAnimation({VoidCallback? onComplete}) {
    _showAnimation(
      bindGifPath, 
      '绑定成功', 
      const Duration(seconds: 3),
      onComplete: onComplete,
    );
  }

  /// 显示解绑成功动画（2秒）
  /// 
  /// [onComplete] 动画播放完成后的回调
  void showUnbindAnimation({VoidCallback? onComplete}) {
    _showAnimation(
      unbindGifPath, 
      '解绑成功', 
      const Duration(seconds: 2),
      onComplete: onComplete,
    );
  }

  /// 显示动画叠加层
  /// 
  /// [gifPath] GIF资源路径
  /// [animationType] 动画类型描述
  /// [duration] 动画播放时长
  /// [onComplete] 动画播放完成后的额外回调
  void _showAnimation(
    String gifPath, 
    String animationType, 
    Duration duration, {
    VoidCallback? onComplete,
  }) {
    // 如果已经在显示动画，不重复显示
    if (_isShowingAnimation) {
      logger.warning('动画正在播放中，跳过本次请求', tag: 'RelationshipAnimationService');
      return;
    }

    _isShowingAnimation = true;
    logger.info('显示$animationType动画: $gifPath, 时长: ${duration.inSeconds}秒', tag: 'RelationshipAnimationService');

    // 使用Get的overlay显示动画
    Get.dialog(
      RelationshipAnimationOverlay(
        gifPath: gifPath,
        duration: duration,
        onAnimationComplete: () async {
          // 动画完成后关闭对话框
          _isShowingAnimation = false;
          logger.info('$animationType动画播放完成，准备关闭对话框', tag: 'RelationshipAnimationService');
          
          if (Get.isDialogOpen == true) {
            Get.back();
          }
          
          // 等待对话框关闭动画完成
          await Future.delayed(const Duration(milliseconds: 100));
          
          logger.info('对话框已关闭，执行完成回调', tag: 'RelationshipAnimationService');
          
          // 调用外部传入的完成回调
          onComplete?.call();
        },
      ),
      barrierDismissible: false,
      barrierColor: Colors.transparent,
    );
  }

  /// 刷新当前活动页面的数据
  /// 尝试刷新所有已注册的页面控制器
  void refreshCurrentPage() {
    logger.info('🔄 开始刷新当前页面...', tag: 'RelationshipAnimationService');
    
    try {
      // 刷新首页
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        homeController.loadUserInfo();
        logger.info('✅ 首页数据已刷新', tag: 'RelationshipAnimationService');
      }
      
      // 刷新我的页面
      if (Get.isRegistered<MineController>()) {
        final mineController = Get.find<MineController>();
        mineController.loadUserInfo();
        logger.info('✅ 我的页面数据已刷新', tag: 'RelationshipAnimationService');
      }
      
      // 刷新定位页面
      if (Get.isRegistered<LocationV2Controller>()) {
        final locationController = Get.find<LocationV2Controller>();
        locationController.refreshUserInfo();
        logger.info('✅ 定位页面数据已刷新', tag: 'RelationshipAnimationService');
      }
      
      // 刷新足迹页面
      if (Get.isRegistered<TrackController>()) {
        final trackController = Get.find<TrackController>();
        trackController.refreshCurrentUserData();
        logger.info('✅ 足迹页面数据已刷新', tag: 'RelationshipAnimationService');
      }
      
      logger.info('✅ 页面刷新完成', tag: 'RelationshipAnimationService');
    } catch (e) {
      logger.error('❌ 刷新页面失败: $e', tag: 'RelationshipAnimationService');
    }
  }
}

