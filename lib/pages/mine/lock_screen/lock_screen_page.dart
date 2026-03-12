import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'lock_screen_controller.dart';
import 'widgets/lock_screen_header.dart';
import 'widgets/lock_screen_step1.dart';
import 'widgets/lock_screen_step2.dart';
import 'widgets/lock_screen_locked.dart';
import 'widgets/lock_screen_bottom_button.dart';
import 'widgets/lock_screen_permission_banner.dart';

class LockScreenPage extends StatelessWidget {
  const LockScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LockScreenController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        if (controller.pageState.value == 'locked') {
          return const LockScreenLockedView();
        }
        return _buildSetupView(context, controller);
      }),
    );
  }

  Widget _buildSetupView(BuildContext context, LockScreenController controller) {
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
                              return const LockScreenStep2();
                            }
                          }),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
                const LockScreenBottomButton(),
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
