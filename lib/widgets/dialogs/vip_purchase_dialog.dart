import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../services/tracking_service.dart';
import '../../utils/agreement_utils.dart';

/// 开通VIP弹窗
class VipPurchaseDialog extends StatefulWidget {
  final VoidCallback? onConfirm;

  const VipPurchaseDialog({Key? key, this.onConfirm}) : super(key: key);

  @override
  State<VipPurchaseDialog> createState() => _VipPurchaseDialogState();

  /// 显示VIP开通弹窗
  static Future<void> show({
    required BuildContext context,
    VoidCallback? onConfirm,
    bool barrierDismissible = false, // 默认不允许点击背景关闭
  }) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      // 背景色：#000000 50% 再 86% 不透明度 = 0.5 * 0.86 = 0.43 = 43% 不透明度
      // alpha = 0.43 * 255 = 109.65 ≈ 110 = 0x6E
      barrierColor: const Color(0x6E000000),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              // 阻止点击弹窗内容区域时关闭
              onTap: () {},
              child: VipPurchaseDialog(onConfirm: onConfirm),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );

    // 埋点说明：
    // 1. 点击关闭按钮会触发 trackVipAlertClose
    // 2. 点击立即查看按钮会触发 trackVipAlertOpen
    // 3. 点击屏幕背景会触发 trackVipAlertClose（如果barrierDismissible为true）
  }
}

class _VipPurchaseDialogState extends State<VipPurchaseDialog> {
  // 协议是否已同意
  bool _agreementChecked = false;

  /// 切换协议同意状态
  void _toggleAgreement() {
    setState(() {
      _agreementChecked = !_agreementChecked;
    });
  }

  /// 处理开通会员按钮点击
  void _handleConfirm() {
    if (!_agreementChecked) {
      // 如果未同意协议，可以显示提示或直接返回
      return;
    }
    // 埋点：立即查看按钮点击
    TrackingService.trackVipAlertOpen();
    Navigator.of(context).pop();
    widget.onConfirm?.call();
  }

  @override
  Widget build(BuildContext context) {
    // 设计稿基准尺寸：375 * 812
    const double designWidth = 375.0;

    // 获取屏幕宽度
    final screenWidth = MediaQuery.of(context).size.width;

    // 计算缩放比例（基于宽度）
    final scale = screenWidth / designWidth;

    // 弹窗背景图尺寸：300 * 336
    final bgWidth = 300.0 * scale;
    final bgHeight = 336.0 * scale;

    // 按钮尺寸：213 * 78
    final buttonWidth = 213.0 * scale;
    final buttonHeight = 78.0 * scale;

    // 关闭按钮尺寸：17 * 17
    final closeButtonSize = 17.0 * scale;

    return Stack(
      clipBehavior: Clip.none, // 允许子组件越界显示
      alignment: Alignment.center,
      children: [
        // 弹窗背景图
        Container(
          width: bgWidth,
          height: bgHeight,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/4.0/kissu4_home_vip_per_bg.webp'),
              fit: BoxFit.fill,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // 开通会员按钮（距离协议6px，在协议上方）
              GestureDetector(
                onTap: _agreementChecked ? _handleConfirm : null,
                child: Opacity(
                  opacity: 1.0,
                  child: Image.asset(
                    'assets/4.0/kissu4_home_vip_per_bt.webp',
                    width: buttonWidth,
                    height: buttonHeight,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(height: 6 * scale), // 按钮距离协议6px
              // 协议模块（距离底部21px）
              Padding(
                padding: EdgeInsets.only(bottom: 21 * scale),
                child: _buildAgreementRow(scale),
              ),
            ],
          ),
        ),
        // 关闭按钮（在背景下方5px处）
        Positioned(
          bottom: -(closeButtonSize + 5 * scale), // 背景下方5px
          child: GestureDetector(
            onTap: () async {
              // 埋点：关闭按钮点击
              await TrackingService.trackVipAlertClose();
              Navigator.of(context).pop();
            },
            child: Image.asset(
              'assets/4.0/kissu4_home_vip_per_close.webp',
              width: closeButtonSize,
              height: closeButtonSize,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建协议行（单选框 + 富文本）
  Widget _buildAgreementRow(double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * scale),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 单选框
          GestureDetector(
            onTap: _toggleAgreement,
            child: Image.asset(
              _agreementChecked
                  ? 'assets/4.0/kissu4_home_vip_per_sel.webp'
                  : 'assets/4.0/kissu4_home_vip_per_unsel.webp',
              width: 13 * scale,
              height: 13 * scale,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(width: 8 * scale),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 12 * scale,
                color: const Color(0xFF666666),
              ),
              children: [
                const TextSpan(
                  text: '我已阅读并同意 ',
                  style: TextStyle(fontSize: 9, color: Color(0xdd000000)),
                ),
                TextSpan(
                  text: '《会员服务协议》',
                  style: TextStyle(
                    fontSize: 9 * scale,
                    color: const Color(0xFF00232C),
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      // 上报服务协议点击埋点
                      await TrackingService.trackMembershipServiceAgreement();
                      AgreementUtils.toVipAgreement();
                    },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
