import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'love_info_controller.dart';
import 'love_info_widgets.dart';

class LoveInfoPage extends StatelessWidget {
  const LoveInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoveInfoController());

    return Obx(
      () => Stack(
        children: [
          // 背景图层
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/kissu_mine_bg.webp"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Column(
                children: [
                  // 自定义标题栏
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(
                              'assets/kissu_mine_back.webp',
                              width: 24,
                              height: 24,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: const Text(
                              '恋爱信息',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        // 占位符保持标题居中
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  // 页面内容
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              // 头像部分
                              const SizedBox(height: 60),

                              // 在一起天数卡片
                              TogetherCard(controller: controller),
                              const SizedBox(height: 20),

                              // 相恋时间
                              LoveTimeSection(controller: controller),
                              const SizedBox(height: 20),

                              // 我的信息
                              MyInfoSection(controller: controller),
                              const SizedBox(height: 20),

                              // TA的信息（仅在绑定状态显示）
                              if (controller.isBindPartner.value) ...[
                                PartnerInfoSection(controller: controller),
                                const SizedBox(height: 20),
                              ],
                            ],
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: AvatarSection(controller: controller),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
