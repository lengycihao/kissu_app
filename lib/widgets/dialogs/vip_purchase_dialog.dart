import 'package:flutter/material.dart';
import 'base_dialog.dart';

/// 开通VIP弹窗
class VipPurchaseDialog extends BaseDialog {
  final VoidCallback? onConfirm;

  const VipPurchaseDialog({Key? key, this.onConfirm}) : super(key: key);

  @override
  Widget buildContent(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width - 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFE4F1), // 左上角
            Color(0xFFFBFDFF), // 中间
            Color(0xFFFFF4DB), // 右下角
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 15,
            right: 16,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
              decoration: BoxDecoration(),
              child: Image(
                image: AssetImage('assets/3.0/kissu3_close.webp'),
                fit: BoxFit.fill,
                width: 16,
                height: 16,
              ),
            ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部标题
              _buildHeader(),

              // 中间图片
              _buildMiddleImage(),

              // 底部按钮
              _buildButton(context),

              const SizedBox(height: 24),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建顶部标题
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // VIP图标
          Image.asset('assets/3.0/kissu3_vip_icon.webp', width: 18, height: 15),
          const SizedBox(width: 6),

          // 双人会员仅需
          const Text(
            '双人会员仅需',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF333333),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),

          // 0.9
          Stack(
            children: [
              Positioned(
                left: 0,
                bottom: 2,
                child: Image(
                  image: AssetImage('assets/3.0/kissu3_price_bottom.webp'),
                  fit: BoxFit.fill,
                  width: 50,
                  height: 4,
                ),
              ),
              const Text(
                '0.9',
                style: TextStyle(
                  fontSize: 27,
                  height: 1,
                  color: Color(0xFFFF2454),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),

          // 元/天
          const Text(
            '元/天',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF333333),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建中间图片
  Widget _buildMiddleImage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/3.0/kissu3_dialog_vip.webp',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  /// 构建底部按钮
  Widget _buildButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 24, right: 24),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pop();
          onConfirm?.call();
        },
        child: Container(
          width: double.infinity,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFFF408D),
            borderRadius: BorderRadius.circular(21),
          ),
          child: const Center(
            child: Text(
              '立即查看',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 显示VIP开通弹窗（从底部弹出）
  static Future<void> show({
    required BuildContext context,
    VoidCallback? onConfirm,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Material(
              color: Colors.transparent,
              child: VipPurchaseDialog(
                onConfirm: onConfirm,
              ).buildContent(context),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: child,
        );
      },
    );
  }
}
