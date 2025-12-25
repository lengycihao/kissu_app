import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/widgets/common_back_button.dart';
import 'package:kissu_app/pages/home/home_controller.dart';
import 'package:kissu_app/routers/kissu_route_path.dart'; 

/// 我的页面-顶部导航栏
class MineTopBar extends StatelessWidget {
  final VoidCallback onBackTap;
  final VoidCallback onSettingTap;

  const MineTopBar({
    super.key,
    required this.onBackTap,
    required this.onSettingTap,
  });

  // 点击通知按钮
  void _onNotificationTap() {
 
    
    // 跳转到消息列表页面（一级页面）
    // 注意：红点不在这里清除，而是在进入各个详情页时清除
    debugPrint('📭 点击消息中心按钮，进入消息列表');
    Get.toNamed(KissuRoutePath.messageList);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ).copyWith(bottom: 0,left: 6,right: 15),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 左侧按钮
          Align(
            alignment: Alignment.centerLeft,
            child: CommonBackButton(
              onTap: onBackTap,
              assetPath: "assets/images/kissu_mine_back.webp",
            ),
          ),
          // 居中标题
          const Text(
            "我的",
            style: TextStyle(fontSize: 18, color: Color(0xff333333),fontWeight: FontWeight.w500),
          ),
          // 右侧按钮组
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 通知图标（在设置按钮左边）
                Builder(
                  builder: (context) {
                    if (!Get.isRegistered<HomeController>()) {
                      return const SizedBox.shrink();
                    }
                    final homeController = Get.find<HomeController>();
                    return Obx(() {
                      final isRedDot = homeController.isRedDot.value;
                      return GestureDetector(
                        onTap: _onNotificationTap,
                        child: Container(
                          width: 22,
                          height: 22,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Image.asset(
                                "assets/images/kissu_home_notiicon.webp",
                                width: 22,
                                height: 22,
                              ),
                              // 红点角标
                              if (isRedDot)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: const Color(0xffFF6B6B),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    });
                  },
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onSettingTap,
                  child: Image.asset(
                    "assets/4.0/kissu4_setting.webp",
                    width: 22,
                    height: 22,
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

