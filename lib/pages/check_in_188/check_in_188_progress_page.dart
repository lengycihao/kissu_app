import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'check_in_188_progress_controller.dart';
import 'widgets/progress/check_in_188_progress_nav_bar.dart';
import 'widgets/progress/check_in_188_today_task.dart';
import 'widgets/progress/check_in_188_tomorrow_task.dart';
import 'widgets/progress/check_in_188_calendar.dart';
import 'widgets/progress/check_in_188_stats.dart';

/// 188打卡进行中页面
class CheckIn188ProgressPage extends GetView<CheckIn188ProgressController> {
  const CheckIn188ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F0F0),
      body: Stack(
        children: [
          // 主内容区域
          CustomScrollView(
            controller: controller.scrollController,
            slivers: [
              // 今日任务（包含顶部背景）
              SliverToBoxAdapter(child: CheckIn188TodayTask(controller: controller)),
              const SliverToBoxAdapter(child: SizedBox(height: 85)),
              // 明日任务
              SliverToBoxAdapter(child: CheckIn188TomorrowTask(controller: controller)),
              // 打卡日历
              SliverToBoxAdapter(child: CheckIn188Calendar(controller: controller)),
              // 打卡数据统计
              SliverToBoxAdapter(child: CheckIn188Stats(controller: controller)),
              // 底部安全区域
              SliverToBoxAdapter(
                child: SizedBox(height: Get.mediaQuery.padding.bottom + 16),
              ),
            ],
          ),
          // 导航栏
          CheckIn188ProgressNavBar(controller: controller),
        ],
      ),
    );
  }
}
