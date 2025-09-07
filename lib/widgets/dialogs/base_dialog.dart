import 'package:flutter/material.dart';

/// 弹窗基类，提供通用的弹窗样式和动画
abstract class BaseDialog extends StatelessWidget {
  const BaseDialog({Key? key}) : super(key: key);

  /// 显示弹窗
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget dialog,
    bool barrierDismissible = true,
    Color? barrierColor,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: barrierColor ?? Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return dialog;
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
  }

  /// 构建弹窗内容
  Widget buildContent(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(color: Colors.transparent, child: buildContent(context)),
    );
  }
}

/// 通用弹窗容器
class DialogContainer extends StatelessWidget {
  final String? backgroundImage;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Widget child;
  final BoxConstraints? constraints;

  const DialogContainer({
    Key? key,
    this.backgroundImage,
    this.width,
    this.height,
    this.padding,
    required this.child,
    this.constraints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 300,
      height: height,
      constraints:
          constraints ??
          BoxConstraints(
            minHeight: 0,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image:
            backgroundImage != null
                ? DecorationImage(
                  image: AssetImage(backgroundImage!),
                  fit: BoxFit.fill,
                )
                : null,
        color: backgroundImage == null ? Colors.white : null,
      ),
      child: child,
    );
  }
}

/// 弹窗按钮
class DialogButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final String? backgroundImage;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const DialogButton({
    Key? key,
    required this.text,
    this.onTap,
    this.backgroundImage,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? 120,
        height: height ?? 44,
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          // borderRadius: BorderRadius.circular(22),
          image:
              backgroundImage != null
                  ? DecorationImage(
                    image: AssetImage(backgroundImage!),
                    fit: BoxFit.fill,
                  )
                  : null,
          color:
              backgroundImage == null ? (backgroundColor ?? Colors.pink) : null,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: textColor ?? Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
