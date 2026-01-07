import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_icon_selector_controller.dart';

/// App图标选择页面
class AppIconSelectorPage extends GetView<AppIconSelectorController> {
  const AppIconSelectorPage({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Stack(
        children: [
          // 背景图
          Positioned.fill(
            child: Image.asset(
              "assets/4.0/kissu4_new_use_bg.webp",
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // 顶部导航栏
                _buildAppBar(),
                // 图标列表
                Expanded(
                  child: Obx(() => GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // 一行3个
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75, // 宽高比，为文字预留空间
                    ),
                    itemCount: controller.iconItems.length,
                    itemBuilder: (context, index) {
                      final item = controller.iconItems[index];
                      final isSelected = controller.currentIcon.value == item.id;
                      return _buildIconItem(item, isSelected);
                    },
                  )),
                ),
              ],
            ),
          ),
          // 加载遮罩
          Obx(() => controller.isLoading.value
              ? Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9DC4)),
                    ),
                  ),
                )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  /// 构建顶部导航栏
  Widget _buildAppBar() {
    return SizedBox(
      height: 44,
      child: Stack(
        children: [
          // 返回按钮
          Positioned(
            left: 5,
            top: 0,
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
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                "更换APP图标",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xff333333),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建图标项
  Widget _buildIconItem(AppIconItem item, bool isSelected) {
    return GestureDetector(
      onTap: () => controller.changeIcon(item.id, item.logoName),
      child: Column(
        children: [
          // 图标图片（带边框）- 正方形
          AspectRatio(
            aspectRatio: 1.0, // 1:1 正方形
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFFFFA1DB) : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.asset(
                      item.previewPath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  // 选中指示器
                  if (isSelected)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFA1DB),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(2),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 图标名称（在边框外）
          Text(
            item.name,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF333333),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
