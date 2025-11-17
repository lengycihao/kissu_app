import 'package:flutter/material.dart';
import 'base_dialog.dart';

/// VIP开通成功弹窗
class VipOpenSuccessDialog extends BaseDialog {
  final VoidCallback? onExperience; // 点击"去体验"

  const VipOpenSuccessDialog({
    Key? key,
    this.onExperience,
  }) : super(key: key);

  @override
  Widget buildContent(BuildContext context) {
    // 设计稿基准尺寸：375 * 812
    const double designWidth = 375.0;
    
    // 获取屏幕宽度
    final screenWidth = MediaQuery.of(context).size.width;
    
    // 计算缩放比例（基于宽度）
    final scale = screenWidth / designWidth;
    
    // 顶部图片尺寸：321 * 264
    final topImageWidth = 321.0 * scale;
    final topImageHeight = 264.0 * scale;
    
    // 中间图片尺寸：260 * 76
    final middleImageWidth = 260.0 * scale;
    final middleImageHeight = 76.0 * scale;
    
    // 按钮尺寸：160 * 44
    final buttonWidth = 160.0 * scale;
    final buttonHeight = 44.0 * scale;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 顶部图片
        Image.asset(
          'assets/4.0/kissu4_vip_open_success_bg.webp',
          width: topImageWidth,
          height: topImageHeight,
          fit: BoxFit.contain,
        ),
        SizedBox(height: 8 * scale), // 添加间距
        // 中间图片
        Image.asset(
          'assets/4.0/kissu4_vip_open_success_bg_tip.webp',
          width: middleImageWidth,
          height: middleImageHeight,
          fit: BoxFit.contain,
        ),
        SizedBox(height: 16 * scale), // 添加间距
        // 按钮
        GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
            onExperience?.call();
          },
          child: Container(
            width: buttonWidth,
            height: buttonHeight,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF7942),
                  Color(0xFFFF3764),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(buttonHeight / 2),
            ),
            alignment: Alignment.center,
            child: const Text(
              '去体验',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 显示VIP开通成功弹窗
  static Future<void> show({
    required BuildContext context,
    VoidCallback? onExperience,
    bool barrierDismissible = true,
  }) {
    return BaseDialog.show(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: const Color(0xD9000005), // 灰色背景 #000005 85%不透明
      dialog: VipOpenSuccessDialog(
        onExperience: onExperience,
      ),
    );
  }
}

