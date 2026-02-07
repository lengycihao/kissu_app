import 'package:flutter/material.dart';
import 'package:kissu_app/services/analytics/analytics_helper.dart';

/// 开通VIP弹窗
class VipPurchaseDialog extends StatefulWidget {
  final VoidCallback? onConfirm;
  final VoidCallback? onCloseTracked;

  const VipPurchaseDialog({Key? key, this.onConfirm, this.onCloseTracked}) : super(key: key);

  @override
  State<VipPurchaseDialog> createState() => _VipPurchaseDialogState();

  /// 显示VIP开通弹窗
  static Future<void> show({
    required BuildContext context,
    VoidCallback? onConfirm,
    bool barrierDismissible = false, // 默认不允许点击背景关闭
  }) async {
    // 埋点：VIP充值弹窗曝光（在show方法中调用，确保只触发一次）
    AnalyticsHelper.trackVipRechargeDialogExposure(
      pageEnterTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    
    // 标记是否已经上报过埋点（避免重复上报）
    bool hasTrackedClose = false;
    
    await showGeneralDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      // 背景色：#000000 70% 
      barrierColor: const Color(0xb3000000),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              // 阻止点击弹窗内容区域时关闭
              onTap: () {},
              child: VipPurchaseDialog(
                onConfirm: onConfirm,
                onCloseTracked: () {
                  hasTrackedClose = true;
                },
              ),
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

    // 弹窗关闭后，如果没有上报过关闭埋点（说明是点击背景关闭的），则上报
    if (!hasTrackedClose) {
      AnalyticsHelper.trackVipRechargeDialog(btnStatus: 0); // 0=关闭
    }
  }
}

class _VipPurchaseDialogState extends State<VipPurchaseDialog> {
 

  /// 处理开通会员按钮点击
  void _handleConfirm() {
    // 埋点：充值弹窗确认按钮点击
    AnalyticsHelper.trackVipRechargeDialog(btnStatus: 1); // 1=进入
    
    // 标记已上报埋点（确认按钮也算已处理，不需要再上报关闭）
    widget.onCloseTracked?.call();
    
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
                onTap: _handleConfirm,
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
              SizedBox(height: 25 * scale), // 按钮距离协议6px
              
            ],
          ),
        ),
        // 关闭按钮（在背景下方5px处）
        Positioned(
          bottom: -(closeButtonSize + 5 * scale), // 背景下方5px
          child: GestureDetector(
            onTap: () async {
              // 埋点：充值弹窗关闭按钮点击
              AnalyticsHelper.trackVipRechargeDialog(btnStatus: 0); // 0=关闭
              
              // 标记已上报埋点
              widget.onCloseTracked?.call();
              
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

 }
