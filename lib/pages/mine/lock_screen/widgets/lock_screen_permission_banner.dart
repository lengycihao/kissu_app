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
          // 横幅1：自己的锁机权限未开启（悬浮窗或app使用记录任一未开启都显示）
          if (!controller.isMyPermissionGranted)
            _buildBanner(
              text: '我的锁机权限未开启，还不支持Ta锁机哦',
              actionText: '去设置',
              onTap: () => controller.goToPermissionSettings(
                flashOverlay: !controller.isOverlayGranted.value,
                flashUsage: !controller.isUsageAccessGranted.value,
              ),
            ),
          // 横幅2：对方权限未开启（加载完成后才判断，避免加载中误显示）
          if (!controller.isLoadingPartnerPermission.value &&
              !controller.isPartnerPermissionGranted.value)
            _buildBanner(
              text: 'Ta还未开启相关权限，还不能锁机哦',
              actionText: '去提醒',
              onTap: () => controller.sendRemindDirectly(),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFffffff), width: 0.5),
      ),
      child: Row(
        children: [
          // 警告图标
          const Image(image: AssetImage('assets/lock/kissu_lock_warning.webp'),width: 16,),
          const SizedBox(width: 6),
          // 提示文字
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF333333),
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
                    color: Color(0xFFFF7ECE),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: Color(0xFFFF7ECE),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
