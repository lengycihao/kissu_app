import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../check_in_188_progress_controller.dart';

/// 188打卡进行中页面 - 明日任务模块
class CheckIn188TomorrowTask extends StatelessWidget {
  final CheckIn188ProgressController controller;

  const CheckIn188TomorrowTask({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 双方都完成今日任务（我爱你+我的任务都完成）才显示明日任务内容
      final bool myTaskComplete = controller.myTaskProgress.value >= 2;
      final bool partnerTaskComplete = controller.partnerTaskProgress.value >= 2;
      final bool bothComplete = myTaskComplete && partnerTaskComplete;
      
      if (!bothComplete) {
        // 未完成时显示提示
        return Container(
          margin: const EdgeInsets.fromLTRB(15, 50, 15, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleRow(),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 50,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Center(
                  child: Text(
                    '双方完成今日打卡，即可开启',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF999999),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
      
      // 双方都完成时显示明日任务内容
      return Container(
        margin: const EdgeInsets.fromLTRB(15, 50, 15, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleRow(),
            const SizedBox(height: 12),
            Text(
              controller.tomorrowTaskDescription.value.isNotEmpty
                  ? controller.tomorrowTaskDescription.value
                  : '明天早上6点至7点之间，去定位页面面，我的心情卡设置一个心情告诉他...',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    });
  }

  /// 构建标题行
  Widget _buildTitleRow() {
    return Row(
      children: [
        Image.asset(
          'assets/188/kissu_188_label_color.webp',
          width: 7,
          height: 14,
        ),
        const SizedBox(width: 8),
        const Text(
          '明日任务',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }
}
