import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/mine/device_usage/device_usage_controller.dart';
import 'package:kissu_app/utils/network_image_helper.dart';

/// 首页「Ta的敏感操作记录」卡片
/// 只负责 UI，点击行为由外部通过 [onTap] 控制。
class DeviceSensitiveUsageCard extends StatelessWidget {
  const DeviceSensitiveUsageCard({
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
        constraints: const BoxConstraints(minHeight: 240),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _ModuleTitle(title: 'Ta的敏感操作记录'),
                  const SizedBox(height: 12),
                  Obx(() {
                    if (controller.sensitiveRecords.isEmpty ||
                        controller.isDebugEmptyMode.value) {
                      return const _EmptySensitiveRecords();
                    }
                    final records = controller.sensitiveRecords;
                    final maxCount = records.length > 3 ? 3 : records.length;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        maxCount,
                        (index) => _SensitiveRecordItem(
                          record: records[index],
                          showDivider: index < maxCount - 1,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            // 🎯 毛玻璃蒙版（仅未绑定时显示，已绑定后不需要蒙版）
            Obx(() {
              final isBound = controller.isUserBound.value;
              if (!isBound) {
                return Positioned(
                  top: 40,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _FrostedGlassMask(
                    text: '实时查看Ta的敏感操作记录',
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

class _EmptySensitiveRecords extends StatelessWidget {
  const _EmptySensitiveRecords();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/4.0/kissu4_use_app_empty.webp',
            width: 80,
            height: 80,
          ),
          const SizedBox(height: 8),
          const Text(
            '暂无使用数据',
            style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }
}

class _SensitiveRecordItem extends StatelessWidget {
  const _SensitiveRecordItem({
    required this.record,
    required this.showDivider,
  });

  final dynamic record; // 类型为 SensitiveRecord，但此处不强依赖具体类
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final String iconPath = record.iconPath as String;
    final String content = record.content as String;
    final String time = record.time as String;
    final String subtitle = record.subtitle as String? ?? '';

    final itemHeight = subtitle.isNotEmpty ? 68.0 : 52.0;

    return Column(
      children: [
        Container(
          height: itemHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: NetworkImageHelper.loadImage(
                  imageUrl: iconPath,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      content,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF333333),
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xcc333333),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const SizedBox(height: 10),
      ],
    );
  }
}

/// 毛玻璃蒙版（未绑定时显示）
class _FrostedGlassMask extends StatelessWidget {
  const _FrostedGlassMask({
    required this.text,
  });

  final String text;

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
                    'assets/gif/kissu_bind.gif',
                    width: 176,
                    height: 44,
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
