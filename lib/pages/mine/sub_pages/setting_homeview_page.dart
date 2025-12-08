import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/services/view_mode_service.dart';
import 'package:kissu_app/widgets/common_back_button.dart';

class SettingHomeController extends GetxController {
  late ViewModeService viewModeService;

  @override
  void onInit() {
    super.onInit();
    viewModeService = Get.find<ViewModeService>();
  }

  // 当前选择的模式 0 = pst, 1 = dst
  int get selectedIndex => viewModeService.currentViewMode;

  void select(int index) {
    viewModeService.setViewMode(index);
  }

  String get centerImage {
    if (selectedIndex == 0) {
      return "assets/images/kissu_setting_home_center_dst.webp";
    } else {
      return "assets/images/kissu_setting_home_center_pst.webp";
    }
  }

  String get leftButtonImage {
    return selectedIndex == 0
        ? "assets/images/kissu_setting_home_pst.webp"
        : "assets/images/kissu_setting_home_pstu.webp";
  }

  String get rightButtonImage {
    return selectedIndex == 1
        ? "assets/images/kissu_setting_home_dst.webp"
        : "assets/images/kissu_setting_home_dstu.webp";
  }

  void onBackTap() {
    Get.back();
  }
}

class SettingHomePage extends StatelessWidget {
  const SettingHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SettingHomeController());

    return Scaffold(
      body: Stack(
        children: [
          // 背景图
          Positioned.fill(
            child: Image.asset(
              "assets/images/kissu_setting_home_bg.webp",
              fit: BoxFit.cover,
            ),
          ),

          // 页面内容
          SafeArea(
            child: Column(
              children: [
                // 顶部导航
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                  child: Row(
                    children: [
                      CommonBackButton(
                        onTap: controller.onBackTap,
                        assetPath: "assets/images/kissu_mine_back.webp",
                        iconSize: 22,
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            "首页视图",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 30), // 占位保持居中
                    ],
                  ),
                ),

                // 中间图片 - 带动画
                Expanded(
                  child: Center(
                    child: Obx(
                      () => TweenAnimationBuilder<double>(
                        key: ValueKey(controller.viewModeService.selectedViewMode.value),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.scale(
                              scale: 0.9 + (0.1 * value),
                              child: child,
                            ),
                          );
                        },
                        child: Image.asset(
                          controller.viewModeService.selectedViewMode.value == 1
                              ? "assets/images/kissu_setting_home_center_dst.webp"
                              : "assets/images/kissu_setting_home_center_pst.webp",
                          width: 180,
                          height: 364,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),

                // 底部两个按钮 - 带动画
                Padding(
                  padding: const EdgeInsets.only(bottom: 50),
                  child: Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _AnimatedButton(
                          delay: 0,
                          onTap: () => controller.select(0),
                          imagePath: controller.viewModeService.selectedViewMode.value == 0
                              ? "assets/images/kissu_setting_home_pst.webp"
                              : "assets/images/kissu_setting_home_pstu.webp",
                        ),
                        const SizedBox(width: 36),
                        _AnimatedButton(
                          delay: 100,
                          onTap: () => controller.select(1),
                          imagePath: controller.viewModeService.selectedViewMode.value == 1
                              ? "assets/images/kissu_setting_home_dst.webp"
                              : "assets/images/kissu_setting_home_dstu.webp",
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final int delay;
  final VoidCallback onTap;
  final String imagePath;

  const _AnimatedButton({
    Key? key,
    required this.delay,
    required this.onTap,
    required this.imagePath,
  }) : super(key: key);

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _animation,
        child: Image.asset(
          widget.imagePath,
          width: 124,
          height: 184,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}