import 'package:flutter/material.dart';

/// 188打卡页面 - 活动简介组件
class CheckIn188ActivityIntro extends StatelessWidget {
  const CheckIn188ActivityIntro({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('活动简介'),
              const SizedBox(height: 8),
              _buildIntroItem('1.每日在 188 心动打卡挑战页发送"我爱你"，完成系统指定任务，即算当日打卡。'),
              _buildIntroRichItem('2.连续打卡', '天，可解锁', '元现金奖励', ' 188 ', ' 520 '),
              _buildIntroItem('3.挑战完成后，奖金将于7个工作日内发放至账户。'),
            ],
          ),
          // 右下角红包图标
          Positioned(
            right: 0,
            bottom: 0,
            child: Image.asset(
              'assets/188/kissu_188_red_packet_close.webp',
              width: 56,
              height: 56,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建模块标题
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Image.asset(
          'assets/188/kissu_188_label_color.webp',
          width: 7,
          height: 14,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  /// 构建活动简介条目
  Widget _buildIntroItem(String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        content,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF333333),
          height: 1.5,
        ),
      ),
    );
  }

  /// 构建富文本简介条目
  Widget _buildIntroRichItem(
    String content1,
    String content2,
    String content3,
    String number1,
    String number2,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: content1,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF333333),
                height: 1.5,
              ),
            ),
            TextSpan(
              text: number1,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFFF4949),
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            TextSpan(
              text: content2,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF333333),
                height: 1.5,
              ),
            ),
            TextSpan(
              text: number2,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFFFF4949),
                height: 1.5,
              ),
            ),
            TextSpan(
              text: content3,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF333333),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
