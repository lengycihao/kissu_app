import 'package:flutter/material.dart';
import 'base_dialog.dart';
import 'package:kissu_app/services/analytics/analytics_helper.dart';

/// 会员过期提醒弹窗
class VipExpireReminderDialog extends BaseDialog {
  final String desc; // 描述文本（如："你的双人月度会员已过期 10 天"）
  final int expireDays; // 过期天数
  final VoidCallback? onRenewal; // 点击"立即续费"
  final VoidCallback? onCancel; // 点击"下次再说"

  const VipExpireReminderDialog({
    Key? key,
    required this.desc,
    required this.expireDays,
    this.onRenewal,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget buildContent(BuildContext context) {
    // 弹窗宽度：300
    const dialogWidth = 300.0;

    // 弹窗高度：344
    const dialogHeight = 344.0;

    // 立即续费按钮宽度：260
    const renewalButtonWidth = 212.0;

    // 立即续费按钮高度：44
    const renewalButtonHeight = 36.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 弹窗主体
        Container(
          width: dialogWidth,
          height: dialogHeight,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/vip_expire_dialog_bg.webp'),
              fit: BoxFit.fill,
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 55), // 根据设计图调整标题位置
              // 标题文本
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildDescriptionText(),
              ),
              const Spacer(),
              // 立即续费按钮
              GestureDetector(
                onTap: () {
                  // 埋点：记录立即续费按钮点击（1=进入）
                  AnalyticsHelper.trackExpiryTipDialog(btnStatus: 1);
                  Navigator.of(context).pop(true);
                  onRenewal?.call();
                },
                child: Container(
                  width: renewalButtonWidth,
                  height: renewalButtonHeight,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF7942), Color(0xFFFF3764), Color(0xFFF753CB)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '立即续费',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // "下次再说"按钮
        GestureDetector(
          onTap: () {
            // 埋点：记录下次再说按钮点击（0=关闭）
            AnalyticsHelper.trackExpiryTipDialog(btnStatus: 0);
            Navigator.of(context).pop(false);
            onCancel?.call();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Text(
              '下次再说',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xdd999999),
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建描述文本，将过期天数高亮显示
  Widget _buildDescriptionText() {
    // 从desc中提取天数并高亮显示
    final expireDaysStr = expireDays.toString();
    
    // 查找天数在desc中的位置
    final index = desc.indexOf(expireDaysStr);
    
    if (index == -1) {
      // 如果找不到天数，直接显示整个文本
      return Text(
        desc,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF000000),
          height: 1.5,
        ),
      );
    }

    // 分割文本：前部分 + 天数 + 后部分
    final beforeDays = desc.substring(0, index);
    final afterDays = desc.substring(index + expireDaysStr.length);

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(
            text: beforeDays,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF000000),
              height: 1.5,
            ),
          ),
          TextSpan(
            text: expireDaysStr,
            style: const TextStyle(
              fontSize: 26,
              color: Color(0xFFFF2121),
              fontWeight: FontWeight.bold,
              height: 1.5,
            ),
          ),
          TextSpan(
            text: afterDays,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF000000),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 显示会员过期提醒弹窗
  static Future<bool?> show({
    required BuildContext context,
    required String desc,
    required int expireDays,
    VoidCallback? onRenewal,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) {
    return BaseDialog.show<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      dialog: VipExpireReminderDialog(
        desc: desc,
        expireDays: expireDays,
        onRenewal: onRenewal,
        onCancel: onCancel,
      ),
    );
  }
}
