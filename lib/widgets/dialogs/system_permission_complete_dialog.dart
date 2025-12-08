import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 系统权限指引完成确认弹窗
class SystemPermissionCompleteDialog extends StatelessWidget {
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const SystemPermissionCompleteDialog({
    super.key,
    this.onConfirm,
    this.onCancel,
  });

  void _handleCancel() {
    Get.back(result: false);
    onCancel?.call();
  }

  void _handleConfirm() {
    Get.back(result: true);
    onConfirm?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/dialog/kissu4_dialog_small_bg.webp'),
            fit: BoxFit.fill,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 36, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '确认完成?',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF333333),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '未按指引设置相关权限，可能导致定位和使用数据的更新不及时',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF333333),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _handleCancel,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFfffff),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF999999),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '点错了',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _handleConfirm,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF83C4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '确定',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<bool?> show({
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) {
    return Get.dialog<bool>(
      SystemPermissionCompleteDialog(onConfirm: onConfirm, onCancel: onCancel),
      barrierDismissible: barrierDismissible,
    );
  }
}
