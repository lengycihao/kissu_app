import 'package:flutter/material.dart';

/// 188打卡页面 - 任务案例区域组件
class CheckIn188TaskSection extends StatelessWidget {
  const CheckIn188TaskSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 50, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('任务案例'),
          const SizedBox(height: 16),
          // 任务案例图片
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/188/kissu_188_task_info.webp',
              width: double.infinity,
              fit: BoxFit.fitWidth,
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
}
