import 'package:flutter/material.dart';
import 'base_dialog.dart';

/// VIP会员弹窗
class VipDialog extends BaseDialog {
  final String title;
  final String? subtitle;
  final String? content;
  final String buttonText;
  final VoidCallback? onButtonTap;
  final bool showFireEffect;

  const VipDialog({
    Key? key,
    required this.title,
    this.subtitle,
    this.content,
    this.buttonText = '继续观看',
    this.onButtonTap,
    this.showFireEffect = true,
  }) : super(key: key);

  @override
  Widget buildContent(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none, // 允许子元素溢出
      alignment: Alignment.center,
      children: [
        DialogContainer(
          backgroundImage: 'assets/kissu_dialog_vip_bg.webp',
          width: 300,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B9D),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
              if (content != null) ...[
                const SizedBox(height: 12),
                Text(
                  content!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              // 按钮
              _VipButton(
                text: buttonText,
                onTap: () {
                  Navigator.of(context).pop();
                  onButtonTap?.call();
                },
              ),
            ],
          ),
        ),
        // 火焰效果（溢出弹窗）
        if (showFireEffect)
          Positioned(
            top: -40,
            right: -10,
            child: Image.asset(
              'assets/kissu_dialog_vip_fire.webp',
              width: 100,
              height: 100,
            ),
          ),
      ],
    );
  }

  /// 显示VIP弹窗
  static Future<void> show({
    required BuildContext context,
    required String title,
    String? subtitle,
    String? content,
    String buttonText = '继续观看',
    VoidCallback? onButtonTap,
    bool showFireEffect = true,
  }) {
    return BaseDialog.show<void>(
      context: context,
      barrierDismissible: false,
      dialog: VipDialog(
        title: title,
        subtitle: subtitle,
        content: content,
        buttonText: buttonText,
        onButtonTap: onButtonTap,
        showFireEffect: showFireEffect,
      ),
    );
  }
}

/// VIP按钮组件
class _VipButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const _VipButton({Key? key, required this.text, this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        height: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

/// 预设的VIP弹窗
class VipDialogPresets {
  /// 再看30秒得会员
  static Future<void> showWatchMoreDialog(BuildContext context) {
    return VipDialog.show(
      context: context,
      title: '再看30秒得会员',
      subtitle: '+60分钟',
      buttonText: '继续观看',
    );
  }

  /// 再看2个视频得全天免费会员
  static Future<void> showWatchVideosDialog(BuildContext context) {
    return VipDialog.show(
      context: context,
      title: '再看2个视频得',
      subtitle: '全天免费会员',
      buttonText: '继续观看',
    );
  }

  /// 恭喜你完成了今天任务获得全天免费会员
  static Future<void> showTaskCompleteDialog(BuildContext context) {
    return VipDialog.show(
      context: context,
      title: '恭喜你完成了今天任务获得',
      subtitle: '全天免费会员',
      buttonText: '关闭',
      content: '明天记得要来哦',
    );
  }

  /// 恭喜成功开通会员
  static Future<void> showVipSuccessDialog(BuildContext context) {
    return VipDialog.show(
      context: context,
      title: '恭喜成功开通会员',
      subtitle: '你还没有绑定另一半哦，快去绑定吧',
      content: '399点自动赠特',
      buttonText: '确认绑定',
    );
  }
}
