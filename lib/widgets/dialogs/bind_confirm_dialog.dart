import 'package:flutter/material.dart';
import 'base_dialog.dart';

/// 绑定确认弹窗
class BindConfirmDialog extends BaseDialog {
  final String title;
  final String content;
  final String? subContent;
  final String confirmText;
  final VoidCallback? onConfirm;
  final String? userAvatar1;
  final String? userAvatar2;

  const BindConfirmDialog({
    Key? key,
    required this.title,
    required this.content,
    this.subContent,
    this.confirmText = '确认绑定',
    this.onConfirm,
    this.userAvatar1,
    this.userAvatar2,
  }) : super(key: key);

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            DialogContainer(
              backgroundImage: 'assets/kissu_dialog_sex_bg.webp',
              width: 300,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 为头像预留空间
                  const SizedBox(height: 40),
                  // 标题
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // 内容
                  Text(
                    content,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                    ),
                  ),
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
                  // 确认按钮
                  DialogButton(
                    text: confirmText,
                    backgroundImage: 'assets/kissu_dialop_common_sure_bg.webp',
                    width: 200,
                    onTap: () {
                      Navigator.of(context).pop(true);
                      onConfirm?.call();
                    },
                  ),
                ],
              ),
            ),
            // 溢出的头像
            Positioned(
              top: -35,
              left: 60,
              child: _buildAvatar(userAvatar1, true),
            ),
            Positioned(
              top: -35,
              right: 60,
              child: _buildAvatar(userAvatar2, false),
            ),
          ],
        ),
        // 底部关闭按钮
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(false),
          child: Container(
            width: 21,
            height: 21,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.3),
            ),
            child: const Icon(
              Icons.close,
              size: 14,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(String? avatarUrl, bool isLeft) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isLeft ? Colors.pink.shade200 : Colors.blue.shade200,
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: avatarUrl != null
          ? ClipOval(
              child: Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.person,
                    size: 35,
                    color: Colors.white.withOpacity(0.8),
                  );
                },
              ),
            )
          : Icon(
              Icons.person,
              size: 35,
              color: Colors.white.withOpacity(0.8),
            ),
    );
  }

  /// 显示绑定确认弹窗
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String content,
    String? subContent,
    String confirmText = '确认绑定',
    VoidCallback? onConfirm,
    String? userAvatar1,
    String? userAvatar2,
  }) {
    return BaseDialog.show<bool>(
      context: context,
      barrierDismissible: false,
      dialog: BindConfirmDialog(
        title: title,
        content: content,
        subContent: subContent,
        confirmText: confirmText,
        onConfirm: onConfirm,
        userAvatar1: userAvatar1,
        userAvatar2: userAvatar2,
      ),
    );
  }
}

/// 情侣绑定确认弹窗
class CoupleBindConfirmDialog {
  static Future<bool?> show(BuildContext context, {
    String? userAvatar1,
    String? userAvatar2,
  }) {
    return BindConfirmDialog.show(
      context: context,
      title: '郑进湾 请求和你绑定情侣',
      content: '绑定后你的定位、用机记录等信息权限可能会在部分场景下共享给对方',
      confirmText: '确认绑定',
      userAvatar1: userAvatar1,
      userAvatar2: userAvatar2,
    );
  }
}