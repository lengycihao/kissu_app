import 'dart:io';
import 'package:flutter/material.dart';
import '../lock_screen_controller.dart';

void showLockScreenPreview(
    BuildContext context, LockScreenController controller) {
  showDialog(
    context: context,
    barrierColor: Colors.white,
    builder: (context) {
      return GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  // 预览图
                  _buildPreviewImage(controller),
                  // // 锁屏文案叠加
                  // Positioned(
                  //   top: 60,
                  //   left: 0,
                  //   right: 0,
                  //   child: Center(
                  //     child: Container(
                  //       padding: const EdgeInsets.symmetric(
                  //           horizontal: 16, vertical: 8),
                  //       decoration: BoxDecoration(
                  //         color: Colors.black.withOpacity(0.5),
                  //         borderRadius: BorderRadius.circular(20),
                  //       ),
                  //       child: Text(
                  //         controller.lockText.value.isNotEmpty
                  //             ? controller.lockText.value
                  //             : '锁屏文案预览',
                  //         style: const TextStyle(
                  //           fontSize: 16,
                  //           color: Colors.white,
                  //           fontWeight: FontWeight.w500,
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  // 关闭按钮
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.3),
                        ),
                        child: const Icon(Icons.close,
                            size: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildPreviewImage(LockScreenController controller) {
  final index = controller.selectedImageIndex.value;
  if (index >= 0 && index < 3) {
    return Image.asset(
      controller.previewImages[index],
      fit: BoxFit.cover,
    );
  } else if (index == 3 && controller.customImagePath.value.isNotEmpty) {
    return Stack(
  children: [
    Positioned.fill(
       
       child: ClipRRect(
        borderRadius: BorderRadius.circular(0), // 圆角大小
        child: Image.file(
          File(controller.customImagePath.value),
          fit: BoxFit.cover,
        ),
      ),
    ),
    Positioned.fill(
      // left: 5,
      // right: 5,
       child: ClipRRect(
        borderRadius: BorderRadius.circular(0), // 圆角大小
        child: Image.asset(
          'assets/lock/kissu_lock_gray_comment.webp',
          fit: BoxFit.fill,
        ),
      ),
    ),
  ],
);
  }
  return Image.asset(
    controller.previewImages[0],
    fit: BoxFit.contain,
  );
}
