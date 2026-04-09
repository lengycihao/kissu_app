import 'package:flutter/material.dart';

/// 188打卡页面 - 常见问题组件
class CheckIn188FaqSection extends StatelessWidget {
  const CheckIn188FaqSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('常见问题'),
          const SizedBox(height: 16),
          _buildFAQItem(
            'Q1:如何完成每日打卡？',
            '答：在188心动打卡页面中互发"我爱你"，同时解锁当日任务进度完成后才算打卡成功，即可完成当日打卡。',
          ),
          _buildFAQItem(
            'Q2:系统下发的任务有哪些？',
            '答：每日打卡任务均可实现任务，且Kissu语音发送无任何要求仅需情侣双方可完成的打卡任务。',
          ),
          _buildFAQItem(
            'Q3:参与心动打卡有哪些限制？',
            '答：目前打卡计划仅支持情侣组队配对用户参加，且参与当日双方需要完成打卡任务。',
          ),
          _buildFAQItem(
            'Q4:打卡挑战成功后，如何获取奖金？',
            '答：情侣双方完成打卡任务后进行身份认证，平台将于7个工作日内完成打款。',
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

  /// 构建FAQ条目
  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF333333),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
