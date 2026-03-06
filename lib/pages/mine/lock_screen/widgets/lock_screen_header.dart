import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../lock_screen_controller.dart';

/// 固定顶部导航栏（不随内容滚动）
class LockScreenTopBar extends StatelessWidget {
  const LockScreenTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        children: [
          // 返回按钮
          Positioned(
            left: 5,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                width: 44, // 触摸区域宽度48px（16px图标 + 16px左边距 + 16px额外触摸区域）
                height: 44,
                 alignment: Alignment.center,
                child: Image.asset(
                  "assets/images/kissu_mine_back.webp",
                  width: 22, // 图标16*16
                  height: 22,
                 ),
              ),
            ),
          ),
          // 标题 - 绝对居中
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                '一键锁机',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          // 右侧说明按钮
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        padding: EdgeInsets.all(20),
                        width: double.infinity,
                        child: Column(
                          children: [
                            const Text(
                              'iPhone手机功能说明',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xff333333),
                              ),
                            ),
                            SizedBox(height: 20),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '如何锁定iPhone手机\n',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xff333333),
                                      fontWeight: FontWeight.w500,
                                      height: 2.5,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        '由于系统特性，iPhone手机不支持直接锁定手机，只能锁定Ta的App，点击被锁定的App会展示锁定界面。\n\n',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xff777777),
                                      fontWeight: FontWeight.w400,
                                      height: 1.5,
                                    ),
                                  ),

                                  TextSpan(
                                    text: '可以锁定哪些App\n',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xff333333),
                                      fontWeight: FontWeight.w500,
                                      height: 2.5,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '仅支持Ta在Kissu App内预先关联的App\n\n',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xff777777),
                                      fontWeight: FontWeight.w400,
                                      height: 1.5,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '如何让设置关联App\n',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xff333333),
                                      fontWeight: FontWeight.w500,
                                      height: 2.5,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        '需要Ta在自己的手机中操作:打开 Kissu→我的→权限设置 → 关联 App\n\n',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xff777777),
                                      fontWeight: FontWeight.w400,
                                      height: 1.5,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '如何自定义锁屏界面图片\n',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xff333333),
                                      fontWeight: FontWeight.w500,
                                      height: 2.5,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        'iPhone 锁定时仅显示系统默认界面，不支持自定义图片;仅 Android 设备支持该功能。后续苹果官方开放支持后，我们会第一时间更新。\n\n',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xff777777),
                                      fontWeight: FontWeight.w400,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            color: Colors.white,
                            padding: EdgeInsets.all(6),
                            child: Image.asset(
                              'assets/lock/kissu_lock_close.webp',
                              width: 16,
                              height: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: const Center(
                child: Text(
                  '说明',
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 可滚动的头部内容（步骤指示器，背景图已在页面层级用Stack铺设）
class LockScreenHeader extends StatelessWidget {
  const LockScreenHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LockScreenController>();

    // 获取背景图的高度（用于占位，让内容从背景图下方开始）
    // 背景图宽高比约为 375:200，根据屏幕宽度计算高度
    final screenWidth = MediaQuery.of(context).size.width;
    final bgImageHeight = screenWidth * (230 / 375); // 根据实际图片比例调整

    return Column(
      children: [
        // 占位：让内容从背景图下方开始（减去导航栏高度44）
        SizedBox(height: 44),
        Image(
          image: AssetImage('assets/lock/kissu_lock_bg_top.webp'),
          height: 130,
        ),
        // 步骤指示器（独立组件，不在背景图上）
        const SizedBox(height: 12),
        Obx(() => _buildStepIndicator(controller)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildStepIndicator(LockScreenController controller) {
    final step = controller.currentStep.value;
    return Column(
      children: [
        Image(
          image: AssetImage(
            step == 1
                ? 'assets/lock/kissu_lock_bg_step1.webp'
                : 'assets/lock/kissu_lock_bg_step2.webp',
          ),
          height: 20,
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStepCircle(1, '设置锁屏信息', step >= 1),
            SizedBox(width: 30),
            _buildStepCircle(2, '设置锁屏问题', step >= 2),
          ],
        ),
      ],
    );
  }

  Widget _buildStepCircle(int stepNum, String label, bool isActive) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        color: Color(0xffaaaaaa),
      ),
    );
  }
}
