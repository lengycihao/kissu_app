import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../check_in_188_progress_controller.dart';

/// 188打卡进行中页面 - 今日任务模块
class CheckIn188TodayTask extends StatelessWidget {
  final CheckIn188ProgressController controller;

  const CheckIn188TodayTask({
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
        // 内容区域 - 超出背景一点点
        Transform.translate(
          offset: Offset(0, screenWidth * 486 / 375 - 140),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 15),
            padding: const EdgeInsets.all(16).copyWith(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题行
                _buildTitleRow(),
                const SizedBox(height: 12),
                // 任务描述
                _buildTaskDescription(),
                const SizedBox(height: 20),
                // 任务进度区域
                _buildTaskProgressArea(),
                const SizedBox(height: 12),
                // 底部提示
                _buildBottomTip(),
              ],
            ),
          ),
        ),
      ],
    );
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
          '今日任务',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(width: 8),
        Obx(() => Text(
          controller.todayDate.value,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF333333),
          ),
        )),
      ],
    );
  }

  /// 构建任务描述
  Widget _buildTaskDescription() {
    return Obx(() => Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EBFF),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.only(left: 15),
      alignment: Alignment.centerLeft,
      child: Text(
      controller.todayTaskDescription.value,
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xFF333333),
        fontWeight: FontWeight.w500,
        height: 1.5,
      ),
    ),
    ));
  }

  /// 构建任务进度区域
  Widget _buildTaskProgressArea() {
    return Obx(() {
      final myProgress = controller.myTaskProgress.value;
      final partnerProgress = controller.partnerTaskProgress.value;
      
      return Column(
        children: [
          // 点击发送和去完成按钮区域（独立于任务图标）
          _buildActionButtons(myProgress),
          const SizedBox(height: 4),
          // 任务图标区域（始终居中）
          Row(
            children: [
              // 左侧 - 我的任务区域（粉色）
              Expanded(
                child: _buildMyTaskArea(myProgress),
              ),
              // 中间 - 心形进度（高于左右任务元素）
              _buildCenterHeart(),
              // 右侧 - 对方任务区域（蓝色）
              Expanded(
                child: _buildPartnerTaskArea(partnerProgress),
              ),
            ],
          ),
        ],
      );
    });
  }

  /// 构建操作按钮区域（点击发送、去完成）
  Widget _buildActionButtons(int myProgress) {
    final bool showSendButton = myProgress < 1;
    final bool showDoneButton = myProgress >= 1 && myProgress < 2;
    
    return SizedBox(
       height: 30,
      child: Row(
        children: [
          // 左侧按钮区域
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 点击发送按钮
                if (showSendButton)
                  Transform.translate(offset: Offset(-9, 0),child: AnimatedBuilder(
                    animation: controller.floatAnimationController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -controller.floatAnimation.value),
                        child: GestureDetector(
                          onTap: controller.onSendLoveMessage,
                          child: Image.asset(
                            'assets/188/kissu_188_click_send.webp',
                            width: 62,
                            height: 26,
                          ),
                        ),
                      );
                    },
                  ),)
                else
                  const SizedBox(width: 62),
                // 去完成按钮
                if (showDoneButton)
                  Transform.translate(offset: const Offset(-6, 0),child: AnimatedBuilder(
                    animation: controller.floatAnimationController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -controller.floatAnimation.value),
                        child: GestureDetector(
                          onTap: controller.onCompleteTask,
                          child: Image.asset(
                            'assets/188/kissu_188_click_done.webp',
                            width: 62,
                            height: 26,
                          ),
                        ),
                      );
                    },
                  ))
                else
                  const SizedBox(width: 62),
              ],
            ),
          ),
          // 中间占位（与心形对齐）
          const SizedBox(width: 50),
          // 右侧占位（对方不显示按钮）
          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  /// 构建我的任务区域（不包含按钮，始终居中）
  Widget _buildMyTaskArea(int progress) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 我爱你任务
        _buildTaskItem(
          isDone: progress >= 1,
          doneIcon: 'assets/188/kissu_188_task_me_done.webp',
          undoneIcon: 'assets/188/kissu_188_task_me_undone.webp',
          label: '我爱你',
          labelColor: const Color(0xFF333333),
        ),
        // 箭头
        Image.asset(
          'assets/188/kissu_188_task_me_to_right.webp',
          width: 8,
          height: 8,
        ),
        // 我的任务
        _buildTaskItem(
          isDone: progress >= 2,
          doneIcon: 'assets/188/kissu_188_task_me_done.webp',
          undoneIcon: 'assets/188/kissu_188_task_me_undone.webp',
          label: '我的任务',
          labelColor: const Color(0xFF333333),
        ),
      ],
    );
  }

  /// 构建中心心形（高于左右任务元素）
  Widget _buildCenterHeart() {
    return Transform.translate(
      offset: const Offset(0, -30), // 向上偏移，高于左右任务元素
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/188/kissu_188_task_me_to_top.webp',
            width: 8,
            height: 8,
          ),
          const SizedBox(width: 10),
          // 心形图标
          Obx(() => Image.asset(
            controller.getCenterHeartIcon(),
            width: 34,
            height: 34,
          )),const SizedBox(width: 10),
          Image.asset(
            'assets/188/kissu_188_task_she_to_top.webp',
            width: 8,
            height: 8,
          ),
        ],
      ),
    );
  }

  /// 构建对方任务区域
  Widget _buildPartnerTaskArea(int progress) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 对方我爱你任务
        _buildTaskItem(
          isDone: progress >= 1,
          doneIcon: 'assets/188/kissu_188_task_she_done.webp',
          undoneIcon: 'assets/188/kissu_188_task_she_undone.webp',
          label: 'Ta的任务',
          labelColor: const Color(0xFF5C90F8),
        ),
        // 箭头
        Image.asset(
          'assets/188/kissu_188_task_she_to_left.webp',
          width: 8,
          height: 8,
        ),
        // 对方的任务
        _buildTaskItem(
          isDone: progress >= 2,
          doneIcon: 'assets/188/kissu_188_task_she_done.webp',
          undoneIcon: 'assets/188/kissu_188_task_she_undone.webp',
          label: '我爱你',
          labelColor: const Color(0xFF5C90F8),
        ),
      ],
    );
  }

  /// 构建单个任务项（通用）
  Widget _buildTaskItem({
    required bool isDone,
    required String doneIcon,
    required String undoneIcon,
    required String label,
    required Color labelColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 状态图标
        Image.asset(
          isDone ? doneIcon : undoneIcon,
          width: 30,
          height: 30,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: labelColor,
          ),
        ),
      ],
    );
  }

  /// 构建底部提示
  Widget _buildBottomTip() {
    return const Center(
      child: Text(
        '情侣双方互发我爱你+双方完成任务=今日打卡成功',
        style: TextStyle(
          fontSize: 12,
          color: Color(0xFFDA8A8A),
        ),
      ),
    );
  }
}
