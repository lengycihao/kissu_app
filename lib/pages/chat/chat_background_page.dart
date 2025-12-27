import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/chat/chat_background_controller.dart';

class ChatBackgroundPage extends GetView<ChatBackgroundController> {
  const ChatBackgroundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // 顶部预览区域
          Expanded(
            child: _buildPreviewArea(),
          ),
          // 底部背景选择区域
          _buildBackgroundSelector(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(44 + MediaQuery.of(Get.context!).padding.top),
      child: Container(
        height: 55 + MediaQuery.of(Get.context!).padding.top,
        color: Colors.white,
        child: Stack(
          children: [
            // 返回按钮
            Positioned(
              left: 5,
              top: MediaQuery.of(Get.context!).padding.top,
              bottom: 0,
              child: GestureDetector(
                onTap: () => Get.back(),
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
            Positioned(
              left: 0,
              right: 0,
              top: MediaQuery.of(Get.context!).padding.top,
              bottom: 0,
              child: Center(
                child: Text(
                  '聊天背景',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            // 右侧使用按钮
            Positioned(
              right: 16,
              // top: MediaQuery.of(Get.context!).padding.top,
              bottom: 10,
              child: GestureDetector(
                onTap: controller.applyBackground,
                child: Container(
                  width: 70,
                  height: 33,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xffFF90CA),
                    borderRadius: BorderRadius.circular(16.5),
                  ),
                  child: const Text(
                    '使用',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewArea() {
    return Obx(() => Container(
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: controller.getBackgroundImageProvider(controller.previewBackground.value),
              fit: BoxFit.cover,
            ),
          ),
        ));
  }

  Widget _buildBackgroundSelector() {
    return Container(
      height: 160,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
         
      ),
      child: Obx(() => ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: controller.allBackgrounds.length + 1, // +1 for add button
            itemBuilder: (context, index) {
              if (index == 0) {
                // 添加按钮
                return _buildAddButton();
              } else {
                // 背景缩略图
                final backgroundPath = controller.allBackgrounds[index - 1];
                return _buildBackgroundThumbnail(backgroundPath, index - 1);
              }
            },
          )),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: controller.addBackgroundFromGallery,
      child: Container(
        width: 80,
        height: 80,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
           
        ),
        alignment: Alignment.center,
        child: Image(image: AssetImage('assets/chat/kissu_add_picture.webp'),width: 32,height: 32,)
      ),
    );
  }

  Widget _buildBackgroundThumbnail(String backgroundPath, int index) {
    return Obx(() {
      final isSelected = controller.selectedBackground.value == backgroundPath;

      return GestureDetector(
        onTap: () => controller.selectBackground(backgroundPath),
        child: Container(
          width: 80,
          height: 80,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: const Color(0xFFFF90CA), width: 2)
                : Border.all(color: const Color(0xFFFBF0F0), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image(
              image: controller.getBackgroundImageProvider(backgroundPath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFF5F5F5),
                  child: const Icon(
                    Icons.broken_image,
                    color: Color(0xFF999999),
                  ),
                );
              },
            ),
          ),
        ),
      );
    });
  }
}

