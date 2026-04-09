import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../check_in_188_controller.dart';

/// 188打卡页面 - 导航栏组件
class CheckIn188NavBar extends StatelessWidget {
  final CheckIn188Controller controller;

  const CheckIn188NavBar({
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
              // 标题（滚动后显示）
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
              const SizedBox(width: 44),
            ],
          ),
        ),
      );
    });
  }
}
