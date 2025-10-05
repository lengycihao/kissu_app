import 'package:flutter/material.dart';
import 'base_dialog.dart';

/// 位置状态删除/替换确认弹窗
class LocationStateDeleteDialog extends BaseDialog {
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final String title; // 弹窗标题

  const LocationStateDeleteDialog({
    Key? key,
    this.onConfirm,
    this.onCancel,
    this.title = '确定要删除吗？', // 默认标题
  }) : super(key: key);

  @override
  Widget buildContent(BuildContext context) {
    return Container(
      width: 269,
      height: 220,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/location/kissu3_state_delete_bg.webp'),
          fit: BoxFit.fill,
        ),
      ),
      child: Stack(
        children: [
          // 标题 - Y轴位置115，加粗
          Positioned(
            top: 115,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF333333),
                  fontWeight: FontWeight.bold, // 加粗
                ),
              ),
            ),
          ),
          // 按钮区域 - 底部间距30
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 取消按钮
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop(false);
                    onCancel?.call();
                  },
                  child: Container(
                    width: 106,
                    height: 36,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/location/kissu3_state_delete_cancel.webp'),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 确认按钮
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop(true);
                    onConfirm?.call();
                  },
                  child: Container(
                    width: 106,
                    height: 36,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/location/kissu3_state_delete_sure.webp'),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 显示删除/替换确认弹窗
  static Future<bool?> show({
    required BuildContext context,
    String title = '确定要删除吗？',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) {
    return BaseDialog.show<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      dialog: LocationStateDeleteDialog(
        title: title,
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
    );
  }
}

