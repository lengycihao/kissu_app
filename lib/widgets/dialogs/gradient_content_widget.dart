import 'package:flutter/material.dart';

/// 渐变背景的内容组件
class GradientContentWidget extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? height;

  const GradientContentWidget({
    Key? key,
    required this.child,
    this.padding,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/dialog/kissu_bind_dialog.webp'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Container(
        padding: padding ?? const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}
