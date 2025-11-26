import 'package:flutter/material.dart';

import 'base_dialog.dart';

class BindRequestDialog extends BaseDialog {
  final ImageProvider avatarImage;
  final String nickname;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const BindRequestDialog({
    Key? key,
    required this.avatarImage,
    required this.nickname,
    this.onAccept,
    this.onReject,
  }) : super(key: key);

  @override
  Widget buildContent(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth - 100; // 左右各 50px 外边距

    return DialogContainer(
      backgroundImage: 'assets/dialog/kissu4_bind_sure.webp',
      width: dialogWidth,
      height: 269,
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(33),
                child: SizedBox(
                  width: 66,
                  height: 66,
                  child: Image(
                    image: avatarImage,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Image.asset(
                'assets/4.0/kissu4_bind_sure_hello.webp',
                height: 63,
                fit: BoxFit.contain,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            nickname,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000000),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '申请与你绑定',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000000),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '绑定后你的定位、用机记录等信息权限可能会在部分场景下共享给对方',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFFcccccc),
              height: 1.5,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildRejectButton(context),
              const SizedBox(width: 20),
              Expanded(child: _buildAcceptButton(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRejectButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop(false);
        onReject?.call();
      },
      child: Container(
        width: 88,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF999999),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: const Text(
          '拒绝',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF999999),
          ),
        ),
      ),
    );
  }

  Widget _buildAcceptButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop(true);
        onAccept?.call();
      },
      child: Container(
        width: 88,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFFF9AD9),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: const Text(
          '同意',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  static Future<bool?> show({
    required BuildContext context,
    required ImageProvider avatarImage,
    required String nickname,
    VoidCallback? onAccept,
    VoidCallback? onReject,
    bool barrierDismissible = true,
  }) {
    return BaseDialog.show<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      dialog: BindRequestDialog(
        avatarImage: avatarImage,
        nickname: nickname,
        onAccept: onAccept,
        onReject: onReject,
      ),
    );
  }
}
