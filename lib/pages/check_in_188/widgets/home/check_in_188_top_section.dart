import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../check_in_188_controller.dart';

/// 188打卡页面 - 顶部区域组件
class CheckIn188TopSection extends StatelessWidget {
  final CheckIn188Controller controller;

  const CheckIn188TopSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = Get.width;
    return Stack(
      children: [
        // 顶部背景图
        Image.asset(
          'assets/188/kissu_188_top_bg.webp',
          width: screenWidth,
          height: screenWidth * 486 / 375,
          fit: BoxFit.cover,
        ),
        // 内容
        Transform.translate(
          offset: Offset(0, screenWidth * 486 / 375 - 110),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                // 520元恋爱基金标题图片
                Align(
                  alignment: AlignmentGeometry.topLeft,
                  child: Image.asset(
                    'assets/188/kissu_188_top_title.webp',
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                ),
                // 统计数据
                _buildStatisticsRow(),
                // 重叠头像
                _buildOverlappingAvatars(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建统计数据行
  Widget _buildStatisticsRow() {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        child: Row(
          children: [
            // 当前累计参与人数
            Expanded(
              child: Column(
                children: [
                  const Text(
                    '当前累计参与人数',
                    style: TextStyle(fontSize: 12, color: Color(0xFF333333)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${controller.participantCount.value}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF1A76),
                    ),
                  ),
                ],
              ),
            ),
            // 累计被领取奖金金额
            Expanded(
              child: Column(
                children: [
                  const Text(
                    '累计被领取奖金金额(元)',
                    style: TextStyle(fontSize: 12, color: Color(0xFF333333)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '￥${controller.totalPrize.value}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF1A76),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建重叠头像
  Widget _buildOverlappingAvatars() {
    return Obx(() {
      final avatars = controller.participantAvatars;
      if (avatars.isEmpty) return const SizedBox.shrink();

      const avatarSize = 25.0;
      const overlap = 7.0;

      return SizedBox(
        height: avatarSize,
        child: Stack(
          children: [
            for (int i = 0; i < avatars.length && i < 5; i++)
              Positioned(
                left: 18 + i * (avatarSize - overlap),
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    image: DecorationImage(
                      image: AssetImage(avatars[i]),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
