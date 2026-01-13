import 'package:flutter/material.dart';
import 'base_dialog.dart';
import 'package:kissu_app/services/analytics/analytics_helper.dart';

/// VIP到期弹窗
class VipOuttimeDialog extends BaseDialog {
  final int expireDays; // 到期天数，用于选择对应的图片
  final VoidCallback? onRenew; // 点击"立即续费"
  final VoidCallback? onLater; // 点击"下次再说"

  const VipOuttimeDialog({
    Key? key,
    required this.expireDays,
    this.onRenew,
    this.onLater,
  }) : super(key: key);

  @override
  Widget buildContent(BuildContext context) {
    // 获取屏幕宽度
    final screenWidth = MediaQuery.of(context).size.width;

    // 背景宽度：屏幕宽度 - 50（两边各25边距）
    final backgroundWidth = screenWidth - 50;

    // 背景高度：根据比例 338*405 计算
    final backgroundHeight = backgroundWidth * 405 / 338;

    // "立即续费"按钮宽度：屏幕宽度 - 164
    final renewButtonWidth = screenWidth - 164;

    // "立即续费"按钮高度：根据比例 212*36 计算
    final renewButtonHeight = renewButtonWidth * 36 / 212;

    // 计算数字位置（基于 338*405 的设计尺寸）
    // 设计尺寸中位置是 (105, 124)，需要按比例缩放
    final numberX = 105 * (backgroundWidth / 338);
    final numberY = 120 * (backgroundHeight / 405);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center, // 纵向居中
      mainAxisSize: MainAxisSize.min,
      children: [
        // 背景图和"立即续费"按钮的组合
        SizedBox(
          width: backgroundWidth,
          height:
              backgroundHeight + renewButtonHeight / 2, // 背景高度 + 按钮一半高度（越界部分）
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
                      image: AssetImage('assets/4.0/vip_outtime_dialog.webp'),
                      fit: BoxFit.fill,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // 数字图片（根据 expireDays 选择对应的图片）
                      Positioned(
                        left: numberX,
                        top: numberY,
                        child: Image(
                          image: AssetImage(_getVipImagePath(expireDays)),
                          width: 25 * (backgroundWidth / 338),
                          height: 50 * (backgroundHeight / 405),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // "立即续费"按钮 - 一半在背景上，一半越界
              Positioned(
                bottom: 0, // 对齐到Stack的底部
                left: (backgroundWidth - renewButtonWidth) / 2, // 水平居中
                child: GestureDetector(
                  onTap: () {
                    // 埋点：续费弹窗立即续费按钮点击
                    AnalyticsHelper.trackRenewalReminderDialog(btnStatus: 1); // 1=进入
                    
                    Navigator.of(context).pop(true); // 返回true表示用户选择续费
                    onRenew?.call();
                  },
                  child: Container(
                    width: renewButtonWidth,
                    height: renewButtonHeight,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/3.0/vip_cancel_sure.webp'),
                        fit: BoxFit.fill,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '立即续费',
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
        const SizedBox(height: 8), // 距离立即续费按钮8px
        // "下次再说"按钮 - 纯文字按钮
        GestureDetector(
          onTap: () {
            // 埋点：续费弹窗下次再说按钮点击
            AnalyticsHelper.trackRenewalReminderDialog(btnStatus: 0); // 0=关闭
            
            Navigator.of(context).pop(false); // 返回false表示用户选择下次再说
            onLater?.call();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Text(
              '下次再说',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xccffffff),
                fontWeight: FontWeight.normal, // 正常字体
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 根据到期天数获取对应的图片路径
  String _getVipImagePath(int days) {
    switch (days) {
      case 1:
        return 'assets/4.0/kissu4_vip_1.webp';
      case 3:
        return 'assets/4.0/kissu4_vip_3.webp';
      case 7:
        return 'assets/4.0/kissu4_vip_7.webp';
      default:
        return 'assets/4.0/kissu4_vip_7.webp'; // 默认使用7
    }
  }

  /// 显示VIP到期弹窗
  static Future<bool?> show({
    required BuildContext context,
    required int expireDays,
    VoidCallback? onRenew,
    VoidCallback? onLater,
    bool barrierDismissible = true,
  }) {
    return BaseDialog.show<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      dialog: VipOuttimeDialog(
        expireDays: expireDays,
        onRenew: onRenew,
        onLater: onLater,
      ),
    );
  }
}
