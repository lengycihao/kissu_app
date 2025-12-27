import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/chat/chat_theme_controller.dart';

class ChatThemePage extends GetView<ChatThemeController> {
  const ChatThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // 顶部预览区域
          Expanded(child: _buildPreviewArea()),
          // 底部主题选择区域
          _buildThemeSelector(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(44 + MediaQuery.of(Get.context!).padding.top),
      child: Container(
        height: 44 + MediaQuery.of(Get.context!).padding.top,
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
                  '主题设置',
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
              bottom: 5,
              child: GestureDetector(
                onTap: controller.applyTheme,
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
    return Obx(() {
      final theme = controller.previewTheme.value;

      return Container(
        width: double.infinity,
        decoration: const BoxDecoration(color: Color(0xFFffffff)),
        child: Center(
          child: Container(
            width: 220,
            // height: 500,
            margin: const EdgeInsets.symmetric(vertical: 20),

            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/chat/kissu_chat_theme$theme.webp',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // 如果主题预览图不存在，使用背景图作为后备
                  return Image.asset(
                    controller.getThemeBackgroundPath(theme),
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildThemeSelector() {
    return Container(
      height: 250,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x07000000),
            offset: Offset(0, -1),
            blurRadius: 40,
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ChatThemeController.themes.length,
        itemBuilder: (context, index) {
          final theme = ChatThemeController.themes[index];
          return _buildThemeThumbnail(theme);
        },
      ),
    );
  }

  Widget _buildThemeThumbnail(int theme) {
    return Obx(() {
      final isSelected = controller.selectedTheme.value == theme;

      return GestureDetector(
        onTap: () => controller.selectTheme(theme),
        child: Container(
          width: 110,
          // padding: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: isSelected
                ? Border.all(color: const Color(0xFFFF90CA), width: 2)
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/chat/kissu_chat_theme$theme.webp',
              fit: BoxFit.contain,
              width: 110,
              height: 170,
              errorBuilder: (context, error, stackTrace) {
                // 如果主题预览图不存在，使用背景图作为后备
                return Image.asset(
                  controller.getThemeBackgroundPath(theme),
                  fit: BoxFit.contain,
                  width: 100,
                  height: 190,
                );
              },
            ),
          ),
        ),
      );
    });
  }
}
