import 'package:flutter/material.dart';

class DashedLine extends StatelessWidget {
  final double height;      // 线条厚度
  final double dashWidth;   // 每个短横宽度
  final double dashSpace;   // 短横间距
  final Color color;

  const DashedLine({
    Key? key,
    this.height = 1,
    this.dashWidth = 4,
    this.dashSpace = 2,
    this.color = const Color(0xFFE6E2E3), // 默认 #E6E2E3
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.maxWidth;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }
}
