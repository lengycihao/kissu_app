import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../check_in_188_progress_controller.dart';

/// 188打卡进行中页面 - 导航栏组件
class CheckIn188ProgressNavBar extends StatelessWidget {
  final CheckIn188ProgressController controller;

  const CheckIn188ProgressNavBar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final opacity = controller.navBarOpacity.value;
      return Container(
        padding: EdgeInsets.only(top: Get.mediaQuery.padding.top),
        decoration: BoxDecoration(color: Colors.white.withOpacity(opacity)),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              // 返回按钮
              GestureDetector(
                onTap: controller.goBack,
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/188/kissu_188_back.webp',
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
              const Spacer(),
              // 标题
              const Text(
                '188心动打卡挑战',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'AlimamaShuHeiTi',
                  color: Color(0xFF9C1818),
                ),
              ),
              const Spacer(),
              // 活动详情按钮（文字颜色随导航栏透明度渐变）
              GestureDetector(
                onTap: () {
                  // TODO: 跳转活动详情
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '活动详情',
                    style: TextStyle(
                      fontSize: 14,
                      // 从白色(0xccffffff)渐变到深灰色(0xFF333333)
                      color: Color.lerp(
                        const Color(0xccffffff),
                        const Color(0xFF333333),
                        opacity,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
