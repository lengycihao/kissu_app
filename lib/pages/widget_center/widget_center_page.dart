import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'widget_center_controller.dart'; 

class WidgetCenterPage extends StatelessWidget {
  const WidgetCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WidgetCenterController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/4.0/kissu4_new_use_bg.webp',
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: Column(
                    children: [
                      const SizedBox(height: 70),
                      _buildSlogan(),
                      const SizedBox(height: 90),
                      _buildCarousel(controller),
                      const SizedBox(height: 20),
                      _buildIndicator(controller),
                      const Spacer(),
                      _buildAddButton(controller),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SizedBox(
      height: 44,
      child: Stack(
        children: [
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
                  'assets/images/kissu_mine_back.webp',
                  width: 22,
                  height: 22,
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                '组件中心',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlogan() {
    return Text(
        '我们的宗旨就是，让爱遍布每一个角落。',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          color: Color(0xFFaaaaaa),
          height: 1.5,
        ),
      );
  }

  Widget _buildCarousel(WidgetCenterController controller) {
    return SizedBox(
      height: 260,
      child: PageView(
        onPageChanged: controller.onPageChanged,
        children: [
          // 4×2 大卡片: 宽矩形，居中显示
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Center(
              child: Image(image: AssetImage('assets/images/kissu_component42.webp')),
            ),
          ),
          // 2×2 方形小卡片: 居中显示
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Center(
              child: Image(image: AssetImage('assets/images/kissu_component22.webp')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(WidgetCenterController controller) {
    return Obx(() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(2, (index) {
          final isActive = controller.currentPage.value == index;
          return Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? const Color(0xFF333333) : const Color(0xFFD9D9D9),
            ),
          );
        }),
      );
    });
  }

  Widget _buildAddButton(WidgetCenterController controller) {
    return GestureDetector(
      onTap: () => _showAddWidgetDialog(),
      child: Container(
        height: 40,
        width: 110,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: const Text(
          '添加小组件',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showAddWidgetDialog() {
    Get.toNamed(KissuRoutePath.widgetAddGuide);
  }
}
