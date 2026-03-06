import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../lock_screen_controller.dart';

class LockScreenStep2 extends StatelessWidget {
  const LockScreenStep2({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LockScreenController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // #1 设置问题
          _buildSectionTitle('#1', '设置问题'),
          const SizedBox(height: 12),
          _buildQuestionInput(controller),
          const SizedBox(height: 24),
          // #2 设置答案
          _buildAnswerSectionTitle(),
          const SizedBox(height: 12),
          _buildAnswerOptions(controller),
          const SizedBox(height: 20),
      
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String number, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: const Color(0xFFFF7ECE) ,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const Text(
          '*',
          style: TextStyle(fontSize: 16, color: Color(0xFFFF7ECE)),
        ),
      ],
    );
  }

  Widget _buildAnswerSectionTitle() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: const Color(0xFFFF7ECE),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            '#2',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          '设置答案',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const Text(
          '*',
          style: TextStyle(fontSize: 16, color: Color(0xFFFF7ECE)),
        ),
        const SizedBox(width: 8),
        Text(
          '点击左侧按钮选择正确选项',
          style: TextStyle(fontSize: 12, color: Color(0xffaaaaaa)),
        ),
      ],
    );
  }

  Widget _buildQuestionInput(LockScreenController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, ),
      decoration: BoxDecoration(
        color: Color(0xfff7f7f7),
        borderRadius: BorderRadius.circular(12),
       ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.questionController,
              maxLength: 20,
              cursorColor: const Color(0xFFFF7ECE),
              decoration: const InputDecoration(
                hintText: '请输入问题',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                border: InputBorder.none,
                counterText: '',
              ),
              style: const TextStyle(fontSize: 12, color: Colors.black),
            ),
          ),
          Obx(() => Text(
                '${controller.question.value.length}/20',
                style: TextStyle(fontSize: 12, color: Color(0xffaaaaaa)),
              )),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions(LockScreenController controller) {
    return Obx(() => Column(
          children: List.generate(4, (index) {
            final isSelected = controller.selectedAnswerIndex.value == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12,  ).copyWith(left: 4),
                decoration: BoxDecoration(
                  color: Color(0xfff7f7f7),
                  borderRadius: BorderRadius.circular(12),
                 ),
                child: Row(
                  children: [
                    // 单选框
                    GestureDetector(
                      onTap: () => controller.selectAnswer(index),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.transparent,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? const Color(0xFFFF7ECE)
                                : Color(0xffe6e6e6),
                             
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // 答案输入框
                    Expanded(
                      child: TextField(
                        controller: controller.answerControllers[index],
                        maxLength: 10,
                        cursorColor: const Color(0xFFFF7ECE),
                        decoration: const InputDecoration(
                          hintText: '',
                          hintStyle:
                              TextStyle(color: Colors.grey, fontSize: 15),
                          border: InputBorder.none,
                          counterText: '',
                        ),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black),
                      ),
                    ),
                    Obx(() => Text(
                          '${controller.answers[index].value.length}/10',
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[400]),
                        )),
                  ],
                ),
              ),
            );
          }),
        ));
  }
 
}
