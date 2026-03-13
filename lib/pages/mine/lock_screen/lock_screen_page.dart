import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'lock_screen_controller.dart';
import 'widgets/lock_screen_header.dart';
import 'widgets/lock_screen_step1.dart';
import 'widgets/lock_screen_step2.dart';
import 'widgets/lock_screen_locked.dart';
import 'widgets/lock_screen_bottom_button.dart';
import 'widgets/lock_screen_permission_banner.dart';

class LockScreenPage extends StatefulWidget {
  const LockScreenPage({super.key});

  @override
  State<LockScreenPage> createState() => _LockScreenPageState();
}

class _LockScreenPageState extends State<LockScreenPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 当输入框获得焦点时，延迟滚动使其可见（避免被键盘遮挡）
  void _scrollToFocusedWidget(BuildContext widgetContext) {
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
      if (keyboardHeight > 0) {
        Scrollable.ensureVisible(
          widgetContext,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LockScreenController>();
    // 获取键盘高度
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Obx(() {
        if (controller.pageState.value == 'locked') {
          return const LockScreenLockedView();
        }
        return _buildSetupView(context, controller, keyboardHeight, isKeyboardVisible);
      }),
    );
  }

  Widget _buildSetupView(BuildContext context, LockScreenController controller, double keyboardHeight, bool isKeyboardVisible) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Stack(
        children: [
          // 背景图铺满顶部
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/lock/kissu_lock_bg.webp',
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
          ),
          // 主内容
          SafeArea(
            child: Column(
              children: [
                // 固定的顶部导航栏（透明，覆盖在背景图上）
                const LockScreenTopBar(),
                
                // 可滚动的内容区域（支持下拉刷新）
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => controller.refreshPermissions(),
                    color: const Color(0xFFFF7ECE),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const LockScreenHeader(),
                          Obx(() {
                            if (controller.currentStep.value == 1) {
                              return const LockScreenStep1();
                            } else {
                              return LockScreenStep2(
                                onFieldFocused: _scrollToFocusedWidget,
                              );
                            }
                          }),
                          // 键盘弹出时增加底部空间，确保输入框可滚动到可见区域
                          SizedBox(height: isKeyboardVisible ? keyboardHeight : 100),
                        ],
                      ),
                    ),
                  ),
                ),
                // 键盘弹出时隐藏底部按钮，避免遮挡
                if (!isKeyboardVisible) const LockScreenBottomButton(),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: MediaQuery.of(context).padding.top + 44,
            child: // 权限提示横幅
                const LockScreenPermissionBanners(),
          ),
        ],
      ),
    );
  }
}
