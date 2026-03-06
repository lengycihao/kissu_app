import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../lock_screen_controller.dart';

/// 锁机页面顶部权限提示横幅
class LockScreenPermissionBanners extends StatelessWidget {
  const LockScreenPermissionBanners({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LockScreenController>();

    return Obx(() {
      return Column(
        children: [
          // 横幅1：自己的锁机权限未开启
          if (!controller.isOverlayGranted.value)
            _buildBanner(
              text: '我的锁机权限未开启，还不支持Ta锁机哦',
              actionText: '去设置',
              onTap: () => controller.goToPermissionSettings(),
            ),
          // 横幅2：对方权限未开启
          if (!controller.isPartnerPermissionGranted.value)
            _buildBanner(
              text: 'Ta还未开启相关权限，还不能锁机哦',
              actionText: '去提醒',
              onTap: () => controller.showRemindDialog(context),
            ),
        ],
      );
    });
  }

  Widget _buildBanner({
    required String text,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFD6E8), width: 0.5),
      ),
      child: Row(
        children: [
          // 警告图标
          const Icon(
            Icons.error_outline,
            size: 16,
            color: Color(0xFFFF6B9D),
          ),
          const SizedBox(width: 6),
          // 提示文字
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFFF6B9D),
              ),
            ),
          ),
          // 操作按钮
          GestureDetector(
            onTap: onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFFF6B9D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: Color(0xFFFF6B9D),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
