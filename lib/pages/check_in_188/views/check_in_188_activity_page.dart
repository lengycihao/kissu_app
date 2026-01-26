import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/check_in_188/views/check_in_188_activity_controller.dart';

/// 参与活动获得补签卡页面
class CheckIn188ActivityPage extends GetView<CheckIn188ActivityController> {
  const CheckIn188ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffffffff),
      body: Stack(
        children: [
          // 背景渐变
        // 背景图
          Positioned.fill(
            child: Image.asset(
              "assets/4.0/kissu4_new_use_bg.webp",
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),
          // 内容区域
          Column(
            children: [
              // 导航栏
              _buildNavBar(),
              // 内容列表
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollUpdateNotification) {
                      controller.updateNavBarOpacity(notification.metrics.pixels);
                    }
                    return false;
                  },
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      const SizedBox(height: 16),
                      // 标题模块
                      _buildTitleSection(),
                      const SizedBox(height: 16),
                      // 活动列表
                      Obx(() => Column(
                            children: controller.activities
                                .map((activity) => _buildActivityCard(activity))
                                .toList(),
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建导航栏
  Widget _buildNavBar() {
    return Obx(() {
      final opacity = controller.navBarOpacity.value;
      return Container(
        padding: EdgeInsets.only(top: Get.mediaQuery.padding.top),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE8EB).withOpacity(opacity),
        ),
        child: SizedBox(
          height: 44,
          child: Stack(
            children: [
              // 返回按钮
              Positioned(
                left: 0,
                child: GestureDetector(
                  onTap: controller.goBack,
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: const Icon(Icons.chevron_left, size: 28),
                  ),
                ),
              ),
              // 标题
              const Center(
                child: Text(
                  '获取补签卡',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// 构建标题模块（参考用机记录页面的标题样式）
  Widget _buildTitleSection() {
    return Row(
      children: [
        Stack(
          alignment: Alignment.bottomLeft,
          children: [
            // 彩色背景图片
            Image.asset(
              'assets/188/kissu_188_use_late_tip.webp',
              width: 70,
              height: 15,
              fit: BoxFit.fill,
            ),
            // 标题文字
            const Text(
              '参与活动获得补签卡',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'AlimamaShuHeiTi',
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
        // 小图标
        Transform.translate(
          offset: const Offset(-2, -2),
          child: Image.asset(
            'assets/4.0/kissu4_app_use_tip.webp',
            width: 13,
            height: 17,
          ),
        ),
      ],
    );
  }

  /// 构建活动卡片
  Widget _buildActivityCard(ActivityItem activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EBFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 活动标题
          Text(
            activity.title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF000000),
            ),
          ),
           // 活动描述
          Text(
            activity.description,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF000000),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          // 邀请按钮
          GestureDetector(
            onTap: () => controller.onInviteFriend(activity.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                activity.buttonText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}