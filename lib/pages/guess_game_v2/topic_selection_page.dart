import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/topic_selection_controller.dart';
import 'widgets/custom_topic_dialog.dart';

/// 你说我猜V2 选题页面
class TopicSelectionPage extends GetView<TopicSelectionController> {
  const TopicSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          // image: DecorationImage(
          //   image: AssetImage('assets/say_guess/kissu_say_guess_bg.webp'),
          //   alignment: Alignment.topCenter,
          // ),
          color: Colors.white,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              const SizedBox(height: 16),
              _buildTitle(),
              const SizedBox(height: 20),
              Expanded(child: _buildTopicGrid()),
              _buildBottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 44,
      color: Colors.transparent,
      child: Stack(
        children: [
          // 返回按钮
          Positioned(
            left: 5,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: Image.asset(
                  "assets/images/kissu_mine_back.webp",
                  width: 22,
                  height: 22,
                ),
              ),
            ),
          ),
          // 标题 - 绝对居中
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Image(
                image: AssetImage(
                  'assets/say_guess/kissu_say_guess_title.webp',
                ),
                width: 102,
                height: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Obx(
      () => Column(
        children: [
          const Text(
            '选择5个作为本轮游戏的猜题答案',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '每轮第5题为自定义答案，也可使用选择的答案 (${controller.selectedCount}/5)',
            style: const TextStyle(fontSize: 12, color: Color(0xFFaaaaaa)),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicGrid() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF90CA)),
        );
      }

      final allItems = <Widget>[];

      // 候选题目
      for (int i = 0; i < controller.candidates.length; i++) {
        final topic = controller.candidates[i];
        allItems.add(
          _buildTopicChip(
            topic.answer,
            topic.isSelected,
            () => controller.toggleSelect(i),
          ),
        );
      }

      // 自定义题目
      for (int i = 0; i < controller.customTopics.length; i++) {
        final topic = controller.customTopics[i];
        allItems.add(
          _buildTopicChip(
            topic.answer,
            true,
            () => controller.removeCustomTopic(i),
            isCustom: true,
          ),
        );
      }

      // 自定义按钮
      allItems.add(_buildCustomButton());

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(spacing: 12, runSpacing: 20, children: allItems),
      );
    });
  }

  Widget _buildTopicChip(
    String text,
    bool isSelected,
    VoidCallback onTap, {
    bool isCustom = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF9AD9) : Color(0xfff5f5f5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isCustom
                      ? const Color(0xFFFF90CA)
                      : const Color(0xFF333333)),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomButton() {
    return GestureDetector(
      onTap: () => _showCustomDialog(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Color(0xffC2C2C2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: Color(0xFFffffff)),
            SizedBox(width: 4),
            Text(
              '自定义',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFFffffff),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomDialog() {
    Get.dialog(
      CustomTopicDialog(
        onConfirm: (answer, description) {
          controller.addCustomTopic(answer, description);
        },
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildBottomButton() {
    return Obx(() {
      final canProceed = controller.canProceed;
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
        child: GestureDetector(
          onTap: canProceed ? () => controller.onNextStep() : null,
          child: Container(
            width: double.infinity,
            height: 44,
            decoration: BoxDecoration(
              color: canProceed
                  ? const Color(0xFF222222)
                  : const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Center(
              child: controller.isSending.value
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      '下一步',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: canProceed
                            ? Colors.white
                            : const Color(0xFF999999),
                      ),
                    ),
            ),
          ),
        ),
      );
    });
  }
}
