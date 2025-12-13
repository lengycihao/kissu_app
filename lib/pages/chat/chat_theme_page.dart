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
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        onPressed: () => Get.back(),
      ),
      title: const Text(
        '主题设置',
        style: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: ElevatedButton(
            onPressed: controller.applyTheme,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffBA92FD),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            child: const Text(
              '使用',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
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
          padding: EdgeInsets.only(right: 10),
          // height: 170,

          // margin: const EdgeInsets.only(right: 12),
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
      );
    });
  }
}
