import 'package:flutter/material.dart';
import 'base_dialog.dart';

/// 华为渠道VIP推广弹窗
/// 首次注册登录时显示，点击图片后弹窗消失
class HuaweiVipPromoDialog extends BaseDialog {
  const HuaweiVipPromoDialog({Key? key}) : super(key: key);

  @override
  Widget buildContent(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 点击图片后关闭弹窗
        Navigator.of(context).pop();
      },
      child: Container(
        width: 270,
        height: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: const DecorationImage(
            image: AssetImage('assets/kissu_vip_oneday.webp'),
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }

  /// 显示华为VIP推广弹窗
  static Future<void> show(BuildContext context) {
    return BaseDialog.show<void>(
      context: context,
      dialog: const HuaweiVipPromoDialog(),
      barrierDismissible: true, // 允许点击外部关闭
    );
  }
}
