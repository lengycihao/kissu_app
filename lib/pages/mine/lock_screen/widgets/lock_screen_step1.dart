import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../lock_screen_controller.dart';
import 'lock_screen_preview_dialog.dart';

class LockScreenStep1 extends StatelessWidget {
  const LockScreenStep1({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LockScreenController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // #1 锁屏界面展示文案
          _buildSectionTitle('#1', '锁屏界面展示文案'),
          const SizedBox(height: 12),
          _buildTextInput(controller),
          const SizedBox(height: 24),
          // #1 设置锁屏界面
          _buildSectionTitle('#1', '设置锁屏界面'),
          const SizedBox(height: 12),
          _buildImageSelector(controller),
          const SizedBox(height: 16),
          // 预览按钮
          _buildPreviewButton(context, controller),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String number, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6,vertical: 1 ),
          decoration: BoxDecoration(
            color: const Color(0xFFFF7ECE) ,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xff333333),
          ),
        ),
        const Text(
          '*',
          style: TextStyle(fontSize: 16, color: Colors.red),
        ),
      ],
    );
  }

  Widget _buildTextInput(LockScreenController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16 ),
      decoration: BoxDecoration(
        color: const Color(0xffF7F7F7),
        borderRadius: BorderRadius.circular(15),
        // border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.lockTextController,
              maxLength: 20,
              cursorColor: const Color(0xFFFF7ECE),
              decoration: const InputDecoration(
                hintText: '请输入锁屏展示文案',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                border: InputBorder.none,
                counterText: '',
              ),
              style: const TextStyle(fontSize: 12, color: Color(0xff333333)),
            ),
          ),
          Obx(() => Text(
                '${controller.lockText.value.length}/20',
                style: TextStyle(fontSize: 12, color: Color(0xffaaaaaa)),
              )),
        ],
      ),
    );
  }

  Widget _buildImageSelector(LockScreenController controller) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 4, // 3张预设 + 1个自定义
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          if (index < 3) {
            return Obx(() => _buildImageItem(
                  controller,
                  index: index,
                  isSelected: controller.selectedImageIndex.value == index,
                  child: Image.asset(
                    controller.presetImages[index],
                    width: 80,
                    height: 146,
                    fit: BoxFit.fitWidth,
                  ),
                ));
          } else {
            return Obx(() => _buildCustomImageItem(controller));
          }
        },
      ),
    );
  }

  Widget _buildImageItem(
    LockScreenController controller, {
    required int index,
    required bool isSelected,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: () => controller.selectImage(index),
      child: Container(
        width: 80,
        height: 146,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF7ECE) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: child,
        ),
      ),
    );
  }

  Widget _buildCustomImageItem(LockScreenController controller) {
    final hasCustomImage = controller.customImagePath.value.isNotEmpty;
    final isSelected = controller.selectedImageIndex.value == 3;

    return GestureDetector(
      onTap: () => controller.pickCustomImage(),
      child: Container(
        width: 80,
        height: 146,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          
          color: Color(0xffF2F2F2),
        ),
        child: hasCustomImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(controller.customImagePath.value),
                  width: 80,
                  height: 146,
                  fit: BoxFit.cover,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 28, color: Color(0xffc8c8c8)),
                ],
              ),
      ),
    );
  }

  Widget _buildPreviewButton(
      BuildContext context, LockScreenController controller) {
    return Center(
      child: Obx(() {
        final canPreview = controller.selectedImageIndex.value >= 0;
        return GestureDetector(
          onTap: canPreview
              ? () => showLockScreenPreview(context, controller)
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.remove_red_eye_outlined,
                size: 18,
                color: canPreview
                    ? const Color(0xFF009BFE)
                    : Colors.grey[400],
              ),
              const SizedBox(width: 4),
              Text(
                '预览Ta被锁屏界面',
                style: TextStyle(
                  fontSize: 12,
                  color: canPreview
                      ? const Color(0xFF009BFE)
                      : Colors.grey[400],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
