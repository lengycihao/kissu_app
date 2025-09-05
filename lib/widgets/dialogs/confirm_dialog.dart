import 'package:flutter/material.dart';
import 'base_dialog.dart';

/// 通用确认弹窗
class ConfirmDialog extends BaseDialog {
  final String title;
  final String? content;
  final String? subContent;
  final String confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool showCancel;

  const ConfirmDialog({
    Key? key,
    required this.title,
    this.content,
    this.subContent,
    this.confirmText = '确定',
    this.cancelText = '取消',
    this.onConfirm,
    this.onCancel,
    this.showCancel = true,
  }) : super(key: key);

  @override
  Widget buildContent(BuildContext context) {
    return DialogContainer(
      backgroundImage: 'assets/kissu_dialog_sex_bg.webp',
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF333333),
            ),
          ),
          if (content != null) ...[
            const SizedBox(height: 15),
            Text(
              content!,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 14,height: 1.7,
                color: Color(0xFF333333),
              ),
            ),
          ],
          if (subContent != null) ...[
            const SizedBox(height: 8),
            Text(
              subContent!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF999999),
              ),
            ),
          ],
          const SizedBox(height: 25),
          // 按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (showCancel) ...[
                DialogButton(
                  text: cancelText ?? '取消',width: 100,
                  backgroundImage: 'assets/kissu_dialop_common_cancel_bg.webp',
                  onTap: () {
                    Navigator.of(context).pop(false);
                    onCancel?.call();
                  },
                ),
                // const SizedBox(width: 20),
              ],
              DialogButton(
                text: confirmText,
                width: 100,
                backgroundImage: 'assets/kissu_dialop_common_sure_bg.webp',
                onTap: () {
                  Navigator.of(context).pop(true);
                  onConfirm?.call();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 显示确认弹窗
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    String? content,
    String? subContent,
    String confirmText = '确定',
    String? cancelText = '取消',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool showCancel = true,
    bool barrierDismissible = true,
  }) {
    return BaseDialog.show<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      dialog: ConfirmDialog(
        title: title,
        content: content,
        subContent: subContent,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        showCancel: showCancel,
      ),
    );
  }
}

/// 退出登录确认弹窗
class LogoutConfirmDialog {
  static Future<bool?> show(BuildContext context) {
    return ConfirmDialog.show(
      context: context,
      title: '提示',
      content: '确定要退出登录吗？',
      cancelText: '取消',
      confirmText: '我再想想',
    );
  }
}

/// 手机号更改确认弹窗
class PhoneChangeConfirmDialog {
  static Future<bool?> show(BuildContext context, String phoneNumber) {
    return BaseDialog.show<bool>(
      context: context,
      dialog: _PhoneChangeDialog(phoneNumber: phoneNumber),
    );
  }
}

/// 手机号更改弹窗内容（按钮上下排列）
class _PhoneChangeDialog extends BaseDialog {
  final String phoneNumber;

  const _PhoneChangeDialog({
    Key? key,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  Widget buildContent(BuildContext context) {
    return DialogContainer(
      backgroundImage: 'assets/kissu_dialog_sex_bg.webp',
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题
          const Text(
            '要更改绑定的手机号吗？',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            '当前的手机号为',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            phoneNumber,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF999999),
            ),
          ),
          const SizedBox(height: 25),
          // 按钮（上下排列）
          Column(
            children: [
              DialogButton(
                text: '确定',
                backgroundImage: 'assets/kissu_dialop_common_sure_bg.webp',
                width: 200,
                onTap: () {
                  Navigator.of(context).pop(true);
                },
              ),
              const SizedBox(height: 12),
              DialogButton(
                text: '取消',
                backgroundImage: 'assets/kissu_dialop_common_cancel_bg.webp',
                width: 200,
                onTap: () {
                  Navigator.of(context).pop(false);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 解除关系确认弹窗
class UnbindConfirmDialog {
  static Future<bool?> show(BuildContext context) {
    return ConfirmDialog.show(
      context: context,
      title: '解除关系',
      content: '解除关系意味着你将清空以上数据，此操作无法撤回，是否确认解除关系？',
      cancelText: '确认解除',
      confirmText: '再想想',
    );
  }
}