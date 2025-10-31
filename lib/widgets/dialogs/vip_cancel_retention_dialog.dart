import 'package:flutter/material.dart';
import 'base_dialog.dart';

/// 取消开通会员挽留弹窗
class VipCancelRetentionDialog extends BaseDialog {
  final VoidCallback? onUnlock; // 点击"全部解锁"
  final VoidCallback? onCancel;  // 点击"下次再说"

  const VipCancelRetentionDialog({
    Key? key,
    this.onUnlock,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget buildContent(BuildContext context) {
    // 获取屏幕宽度
    final screenWidth = MediaQuery.of(context).size.width;
    
    // 背景宽度：屏幕宽度 - 50（两边各25边距）
    final backgroundWidth = screenWidth - 50;
    
    // 背景高度：根据比例 326*380 计算
    final backgroundHeight = backgroundWidth * 380 / 326;
    
    // "全部解锁"按钮宽度：屏幕宽度 - 164
    final unlockButtonWidth = screenWidth - 164;
    
    // "全部解锁"按钮高度：根据比例 212*36 计算
    final unlockButtonHeight = unlockButtonWidth * 36 / 212;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center, // 纵向居中
      mainAxisSize: MainAxisSize.min,
      children: [
        // 背景图和"全部解锁"按钮的组合
        SizedBox(
          width: backgroundWidth,
          height: backgroundHeight + unlockButtonHeight / 2, // 背景高度 + 按钮一半高度（越界部分）
          child: Stack(
            clipBehavior: Clip.none, // 允许子组件越界显示
            children: [
              // 背景图
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  width: backgroundWidth,
                  height: backgroundHeight,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/3.0/vip_cancel_dialog.webp'),
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
              // "全部解锁"按钮 - 一半在背景上，一半越界
              Positioned(
                bottom: 0, // 对齐到Stack的底部
                left: (backgroundWidth - unlockButtonWidth) / 2, // 水平居中
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop(true); // 返回true表示用户选择解锁
                    onUnlock?.call();
                  },
                  child: Container(
                    width: unlockButtonWidth,
                    height: unlockButtonHeight,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/3.0/vip_cancel_sure.webp'),
                        fit: BoxFit.fill,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '全部解锁',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFFFFFFF),
                        fontWeight: FontWeight.bold, // 加粗
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8), // 距离全部解锁按钮8px
        // "下次再说"按钮 - 纯文字按钮
        GestureDetector(
          onTap: () {
            Navigator.of(context).pop(false); // 返回false表示用户选择下次再说
            onCancel?.call();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Text(
              '下次再说',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF999999),
                fontWeight: FontWeight.normal, // 正常字体
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 显示取消开通会员挽留弹窗
  static Future<bool?> show({
    required BuildContext context,
    VoidCallback? onUnlock,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) {
    return BaseDialog.show<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      dialog: VipCancelRetentionDialog(
        onUnlock: onUnlock,
        onCancel: onCancel,
      ),
    );
  }
}

