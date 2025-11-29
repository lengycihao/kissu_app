import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'system_permission_controller.dart';
import '../../../services/permission_service.dart';

class SystemPermissionPage extends GetView<SystemPermissionController> {
  const SystemPermissionPage({super.key});

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
                _buildTopBar(),
                const SizedBox(height: 20),
                // 权限列表
                Expanded(
                  child: _buildPermissionList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建顶部导航栏
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 16,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Image.asset(
              "assets/images/kissu_mine_back.webp",
              width: 22,
              height: 22,
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                "系统权限",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 22),
        ],
      ),
    );
  }

  /// 构建权限列表
  Widget _buildPermissionList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFEA39C)),
              ),
              const SizedBox(height: 16),
              const Text(
                '加载中...',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        physics: const BouncingScrollPhysics(),
        itemCount: controller.permissionItems.length,
        itemBuilder: (context, index) {
          final item = controller.permissionItems[index];
          final type = item["type"] as PermissionType;
          return _PermissionItemCard(
            item: item,
            type: type,
            index: index,
            controller: controller,
          );
        },
      );
    });
  }

}

/// 权限项卡片组件 - 带动画效果
class _PermissionItemCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final PermissionType type;
  final int index;
  final SystemPermissionController controller;

  const _PermissionItemCard({
    required this.item,
    required this.type,
    required this.index,
    required this.controller,
  });

  @override
  State<_PermissionItemCard> createState() => _PermissionItemCardState();
}

class _PermissionItemCardState extends State<_PermissionItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 400 + (widget.index * 80)),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Obx(() {
          final isGranted = widget.controller.getPermissionStatus(widget.type);
          final buttonText = widget.controller.getButtonText(widget.type);
          final buttonColor = widget.controller.getButtonColor(widget.type);
          final isEnabled = widget.controller.isButtonEnabled(widget.type);

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isGranted
                    ? const Color(0xFFFEA39C).withOpacity(0.3)
                    : const Color(0xFFE0E0E0),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // 权限图标
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEA39C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Image.asset(
                      widget.item["icon"],
                      width: 32,
                      height: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 权限信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item["title"],
                        style: const TextStyle(
                          color: Color(0xff333333),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.item["subtitle"],
                        style: const TextStyle(
                          color: Color(0xff999999),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 设置按钮
                GestureDetector(
                  onTap: isEnabled
                      ? () => widget.controller.onPermissionTap(widget.type)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: buttonColor,
                      boxShadow: isEnabled
                          ? [
                              BoxShadow(
                                color: buttonColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
