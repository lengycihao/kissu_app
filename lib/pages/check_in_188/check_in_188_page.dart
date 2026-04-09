import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'check_in_188_controller.dart';
import 'widgets/home/check_in_188_nav_bar.dart';
import 'widgets/home/check_in_188_top_section.dart';
import 'widgets/home/check_in_188_task_section.dart';
import 'widgets/home/check_in_188_success_cases.dart';
import 'widgets/home/check_in_188_activity_intro.dart';
import 'widgets/home/check_in_188_faq_section.dart';
import 'widgets/home/check_in_188_bottom_button.dart';

/// 188打卡页面
class CheckIn188Page extends GetView<CheckIn188Controller> {
  const CheckIn188Page({super.key});

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
              // 顶部背景和内容
              SliverToBoxAdapter(child: CheckIn188TopSection(controller: controller)),
              // 任务案例
              const SliverToBoxAdapter(child: CheckIn188TaskSection()),
              // 提现成功案例
              SliverToBoxAdapter(child: CheckIn188SuccessCases(controller: controller)),
              // 活动简介
              const SliverToBoxAdapter(child: CheckIn188ActivityIntro()),
              // 常见问题
              const SliverToBoxAdapter(child: CheckIn188FaqSection()),
              // 底部按钮
              SliverToBoxAdapter(child: CheckIn188BottomButton(controller: controller)),
            ],
          ),
          // 导航栏
          CheckIn188NavBar(controller: controller),
        ],
      ),
    );
  }
}

// 所有UI组件已拆分到widgets文件夹中，便于维护和复用：
// - CheckIn188NavBar: 导航栏
// - CheckIn188TopSection: 顶部区域（背景、标题、统计数据、头像）
// - CheckIn188TaskSection: 任务案例
// - CheckIn188SuccessCases: 提现成功案例轮播
// - CheckIn188ActivityIntro: 活动简介
// - CheckIn188FaqSection: 常见问题
// - CheckIn188BottomButton: 底部按钮和协议
