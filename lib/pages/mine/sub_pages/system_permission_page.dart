import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'system_permission_controller.dart';
import '../../../services/permission_service.dart';

class SystemPermissionPage extends GetView<SystemPermissionController> {
  const SystemPermissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景图
          Positioned.fill(
            child: Image.asset("assets/kissu_mine_bg.webp", fit: BoxFit.cover),
          ),
          Column(
            children: [
              const SizedBox(height: 40),
              // 顶部导航栏
              _buildTopBar(),
              // 权限列表
              Expanded(
                child: _buildPermissionList(),
              ),
            ],
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
              "assets/kissu_mine_back.webp",
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
        ],
      ),
    );
  }

  /// 构建权限列表
  Widget _buildPermissionList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF6D4128),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: controller.permissionItems.map((item) {
            final type = item["type"] as PermissionType;
            return _buildPermissionItem(item, type);
          }).toList(),
        ),
      );
    });
  }

  /// 构建单个权限项
  Widget _buildPermissionItem(Map<String, dynamic> item, PermissionType type) {
    return Obx(() {
      final isGranted = controller.getPermissionStatus(type);
      final buttonText = controller.getButtonText(type);
      final buttonColor = controller.getButtonColor(type);
      final isEnabled = controller.isButtonEnabled(type);

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 14),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF6D4128)),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.1),
        ),
        child: Row(
          children: [
            // 权限图标
            Image.asset(item["icon"], width: 44, height: 44),
            const SizedBox(width: 12),
            // 权限信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item["title"],
                    style: const TextStyle(
                      color: Color(0xff333333),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item["subtitle"],
                    style: const TextStyle(
                      color: Color(0xff666666),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 权限状态显示
                  Text(
                    controller.getPermissionStatusText(type),
                    style: TextStyle(
                      color: isGranted ? const Color(0xFF4CAF50) : const Color(0xFFFF5722),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // 设置按钮
            GestureDetector(
              onTap: isEnabled ? () => controller.onPermissionTap(type) : null,
              child: Container(
                width: 60,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: buttonColor,
                ),
                alignment: Alignment.center,
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
