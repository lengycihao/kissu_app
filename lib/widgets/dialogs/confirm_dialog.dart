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
                fontSize: 14,
                height: 1.7,
                color: Color(0xFF333333),
              ),
            ),
          ],
          if (subContent != null) ...[
            const SizedBox(height: 8),
            Text(
              subContent!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
            ),
          ],
          const SizedBox(height: 25),
          // 按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (showCancel) ...[
                DialogButton(
                  text: cancelText ?? '取消',
                  width: 110,
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
                width: 110,
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
    return BaseDialog.show<bool>(
      context: context,
      dialog: _LogoutConfirmDialogContent(),
    );
  }
}

/// 退出登录弹窗内容（自定义按钮布局）
class _LogoutConfirmDialogContent extends BaseDialog {
  const _LogoutConfirmDialogContent({Key? key}) : super(key: key);

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
          const Text(
            '提示',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            '确定要退出登录吗？',
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 14,
              height: 1.7,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 25),
          // 按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 左边：确认按钮（执行退出操作）
              DialogButton(
                text: '确认',
                width: 110,
                backgroundImage:
                    'assets/kissu_dialop_common_sure_bg.webp', // 使用确认背景
                onTap: () {
                  Navigator.of(context).pop(true); // 返回 true 表示确认退出
                },
              ),
              // 右边：我再想想按钮（取消操作）
              DialogButton(
                text: '我再想想',
                width: 110,
                backgroundImage:
                    'assets/kissu_dialop_common_cancel_bg.webp', // 使用取消背景
                onTap: () {
                  Navigator.of(context).pop(false); // 返回 false 表示取消
                },
              ),
            ],
          ),
        ],
      ),
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

  const _PhoneChangeDialog({Key? key, required this.phoneNumber})
    : super(key: key);

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
            style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 8),
          Text(
            phoneNumber,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
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

/// 注销账户确认弹窗
class CancellationConfirmDialog {
  static Future<bool?> show(BuildContext context) {
    return BaseDialog.show<bool>(
      context: context,
      dialog: _CancellationConfirmDialogContent(),
    );
  }
}

/// 注销账户弹窗内容（与退出登录弹窗保持一致的UI）
class _CancellationConfirmDialogContent extends BaseDialog {
  const _CancellationConfirmDialogContent({Key? key}) : super(key: key);

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
          const Text(
            '确认注销',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            '注销账户后，您的所有数据将被永久删除，无法恢复。确定要注销吗？',
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 14,
              height: 1.7,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 25),
          // 按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 左边：确认按钮（执行注销操作）
              DialogButton(
                text: '确认',
                width: 110,
                backgroundImage:
                    'assets/kissu_dialop_common_cancel_bg.webp', // 使用取消背景（红色）
                onTap: () {
                  Navigator.of(context).pop(true); // 返回 true 表示确认注销
                },
              ),
              // 右边：我再想想按钮（取消操作）
              DialogButton(
                text: '我再想想',
                width: 110,
                backgroundImage:
                    'assets/kissu_dialop_common_sure_bg.webp', // 使用确认背景（绿色）
                onTap: () {
                  Navigator.of(context).pop(false); // 返回 false 表示取消
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
