import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';

/// 截屏反馈浮动按钮控制器
class ScreenshotFeedbackButtonController extends GetxController 
    with GetSingleTickerProviderStateMixin {
  
  // 是否显示按钮
  var isVisible = false.obs;
  
  // 当前截图路径
  String? currentScreenshotPath;
  
  // 动画控制器
  late AnimationController animationController;
  late Animation<Offset> slideAnimation;
  
  // 自动隐藏定时器
  Timer? _autoHideTimer;
  
  // 自动隐藏延迟时间（秒）
  static const int autoHideDelay = 5;
  
  @override
  void onInit() {
    super.onInit();
    print('🔧 ScreenshotFeedbackButtonController.onInit() 被调用');
    
    // 初始化动画控制器
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // 从左侧滑入的动画
    slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    ));
  }
  
  /// 显示按钮
  void show(String screenshotPath) {
    print('🔧 ScreenshotFeedbackButtonController.show() 被调用');
    print('   截图路径: $screenshotPath');
    
    // 取消之前的自动隐藏定时器
    _autoHideTimer?.cancel();
    
    currentScreenshotPath = screenshotPath;
    isVisible.value = true;
    animationController.forward();
    
    // 设置自动隐藏定时器
    _autoHideTimer = Timer(const Duration(seconds: autoHideDelay), () {
      print('⏰ 截屏反馈按钮: 自动隐藏倒计时结束');
      hide();
    });
    
    print('✅ 截屏反馈按钮: 显示按钮 path=$screenshotPath (${autoHideDelay}秒后自动隐藏)');
  }
  
  /// 【测试方法】手动触发显示（用于调试）
  void testShow() {
    show('/test/screenshot.png');
    print('🧪 测试: 手动显示截屏反馈按钮');
  }
  
  /// 隐藏按钮
  void hide() {
    // 取消自动隐藏定时器
    _autoHideTimer?.cancel();
    
    animationController.reverse().then((_) {
      isVisible.value = false;
      currentScreenshotPath = null;
    });
    
    print('✅ 截屏反馈按钮: 隐藏按钮');
  }
  
  @override
  void onClose() {
    _autoHideTimer?.cancel();
    animationController.dispose();
    super.onClose();
  }
}

/// 截屏反馈浮动按钮组件
class ScreenshotFeedbackButton extends StatelessWidget {
  final VoidCallback? onTap;
  
  const ScreenshotFeedbackButton({
    Key? key,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ScreenshotFeedbackButtonController>();
    
    return Obx(() {
      if (!controller.isVisible.value) {
        return const SizedBox.shrink();
      }
      
      return Positioned(
        left: 0,
        top: MediaQuery.of(context).size.height / 2 - 70, // 垂直居中
        child: SlideTransition(
          position: controller.slideAnimation,
          child: GestureDetector(
            onTap: () {
              if (onTap != null) {
                onTap!();
              } else {
                _handleFeedbackTap(controller);
              }
            },
            child: Image(image: AssetImage("assets/3.0/kissu3_feedback.webp"),width: 76,height: 28,),
          ),
        ),
      );
    });
  }
  
  /// 处理反馈按钮点击
  void _handleFeedbackTap(ScreenshotFeedbackButtonController controller) {
    // 隐藏按钮
    controller.hide();
    
    // 跳转到意见反馈页面，不再传递截图路径
    Get.toNamed(KissuRoutePath.feedback);
    
    print('✅ 截屏反馈按钮: 跳转到意见反馈页面（不传递截图）');
  }
}

