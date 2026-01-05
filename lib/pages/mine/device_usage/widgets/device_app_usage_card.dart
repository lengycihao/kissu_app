import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:kissu_app/pages/mine/device_usage/device_usage_controller.dart';
import 'package:kissu_app/utils/network_image_helper.dart';

/// 首页「Ta的 App 使用记录」卡片
/// 只负责 UI，点击行为由外部通过 [onTap] 控制。
class DeviceAppUsageCard extends StatelessWidget {
  const DeviceAppUsageCard({
    super.key,
    required this.controller,
    required this.onTap,
  });

  final DeviceUsageController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ModuleTitle(title: 'Ta的App使用记录'),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 左侧：最长使用 App
                        Expanded(
                          flex: 130,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F9F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // App 图标
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: const Color(0xFFF9F9F9),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Obx(() {
                                      if (controller.longestAppLogo.value
                                          .isNotEmpty) {
                                        return NetworkImageHelper.loadImage(
                                          imageUrl:
                                              controller.longestAppLogo.value,
                                          fit: BoxFit.cover,
                                          errorWidget: Image.asset(
                                            'assets/phone_history/kissu4_phone_icon_empty.webp',
                                            fit: BoxFit.cover,
                                          ),
                                        );
                                      } else {
                                        return Image.asset(
                                          'assets/phone_history/kissu4_phone_icon_empty.webp',
                                          fit: BoxFit.cover,
                                        );
                                      }
                                    }),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '最长使用APP',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Obx(
                                  () => Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text:
                                              '${controller.longestAppHours.value}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF333333),
                                          ),
                                        ),
                                        const TextSpan(
                                          text: '小时',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xcc333333),
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              '${controller.longestAppMinutes.value}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF333333),
                                          ),
                                        ),
                                        const TextSpan(
                                          text: '分钟',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xcc333333),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // 右侧：两个 App 信息模块
                        Expanded(
                          flex: 155,
                          child: Column(
                            children: [
                              // 打开次数最多的 App
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9F9F9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Image.asset(
                                            'assets/4.0/kissu4_new_use_times_pic.webp',
                                            width: 16,
                                            height: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          const Expanded(
                                            child: Text(
                                              '打开次数最多的App',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xcc333333),
                                              ),
                                            ),
                                          ),
                                          Image.asset(
                                            'assets/4.0/kissu4_new_use_right.webp',
                                            width: 6,
                                            height: 6,
                                          ),
                                        ],
                                      ),
                                      Obx(
                                        () => Row(
                                          children: [
                                            const SizedBox(width: 20),
                                            Container(
                                              width: 26,
                                              height: 26,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: controller
                                                              .openMostAppCount
                                                              .value >
                                                          0 &&
                                                      controller
                                                          .openMostAppLogo
                                                          .value
                                                          .isNotEmpty
                                                  ? ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                      child: NetworkImageHelper
                                                          .loadImage(
                                                        imageUrl: controller
                                                            .openMostAppLogo
                                                            .value,
                                                        width: 26,
                                                        height: 26,
                                                        fit: BoxFit.cover,
                                                        errorWidget: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                          child: Image.asset(
                                                            'assets/phone_history/kissu4_phone_icon_empty.webp',
                                                            width: 26,
                                                            height: 26,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  : ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                      child: Image.asset(
                                                        'assets/phone_history/kissu4_phone_icon_empty.webp',
                                                        width: 26,
                                                        height: 26,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text.rich(
                                              TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text:
                                                        '${controller.openMostAppCount.value}',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(
                                                        0xFF333333,
                                                      ),
                                                    ),
                                                  ),
                                                  const TextSpan(
                                                    text: ' 次',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Color(0xff777777),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // 最近使用的 App
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9F9F9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Image.asset(
                                            'assets/4.0/kissu4_new_use_time_pic.webp',
                                            width: 16,
                                            height: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          const Expanded(
                                            child: Text(
                                              '最近使用的App',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xcc333333),
                                              ),
                                            ),
                                          ),
                                          Image.asset(
                                            'assets/4.0/kissu4_new_use_right.webp',
                                            width: 6,
                                            height: 6,
                                          ),
                                        ],
                                      ),
                                      Obx(
                                        () => Row(
                                          children: [
                                            const SizedBox(width: 20),
                                            Container(
                                              width: 26,
                                              height: 26,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: controller
                                                              .lastUseAppTime
                                                              .value
                                                              .isNotEmpty &&
                                                      controller
                                                          .lastUseAppLogo
                                                          .value
                                                          .isNotEmpty
                                                  ? ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                      child: NetworkImageHelper
                                                          .loadImage(
                                                        imageUrl: controller
                                                            .lastUseAppLogo
                                                            .value,
                                                        width: 26,
                                                        height: 26,
                                                        fit: BoxFit.cover,
                                                        errorWidget: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                          child: Image.asset(
                                                            'assets/phone_history/kissu4_phone_icon_empty.webp',
                                                            width: 26,
                                                            height: 26,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  : ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                      child: Image.asset(
                                                        'assets/phone_history/kissu4_phone_icon_empty.webp',
                                                        width: 26,
                                                        height: 26,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              controller.lastUseAppTime.value
                                                      .isEmpty
                                                  ? '00:00'
                                                  : controller
                                                      .lastUseAppTime.value,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF333333),
                                              ),
                                            ),
                                          ],
                                        ),
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
                  ),
                ],
              ),
            ),
            // 毛玻璃蒙版（未绑定或已绑定未开会员时显示）
            Obx(() {
              final isBound = controller.isUserBound.value;
              final isVip = controller.isUserVip.value;
              if (!isBound || (isBound && !isVip)) {
                return Positioned(
                  top: 40, // 漏出标题区域
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _FrostedGlassMask(
                    text: '实时查看Ta的App详细使用记录',
                    isVipButton: isBound && !isVip,
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }
}

class _ModuleTitle extends StatelessWidget {
  const _ModuleTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Image.asset(
              'assets/4.0/kissu4_new_use_label_bg.webp',
              height: 15,
              width: 140,
              fit: BoxFit.fitWidth,
            ),
            SizedBox(
              height: 20,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'AlimamaShuHeiTi',
                      color: Color(0xFF333333),
                    ),
                  ),
                  Image.asset(
                    'assets/4.0/kissu4_app_use_tip.webp',
                    width: 13,
                    height: 17,
                  ),
                ],
              ),
            ),
          ],
        ),
        const Spacer(),
        Image.asset(
          'assets/4.0/kissu4_next_go.webp',
          width: 16,
          height: 16,
        ),
      ],
    );
  }
}

/// 毛玻璃蒙版（未绑定或已绑定未开会员时显示）
class _FrostedGlassMask extends StatelessWidget {
  const _FrostedGlassMask({
    required this.text,
    required this.isVipButton,
  });

  final String text;
  final bool isVipButton;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFFFFFFF).withOpacity(0.2),
                const Color(0xFFFDE4FF).withOpacity(0.8),
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Image.asset(
                          'assets/images/kissu4_vip_hat.webp',
                          width: 16,
                          height: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Stack(
                        children: [
                          Positioned(
                            bottom: 2,
                            right: 0,
                            child: Image.asset(
                              'assets/images/kissu4_vip_line.webp',
                              width: 68,
                              height: 12,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Text(
                            text,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                   
                   Image.asset(
                      isVipButton
                          ? 'assets/gif/kissu_vip.gif' // 已绑定未开会员
                          : 'assets/gif/kissu_bind.gif', // 未绑定
                    width: isVipButton ? 189 : 176,
                    height: isVipButton ? 60 : 44,
                      fit: BoxFit.contain,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


