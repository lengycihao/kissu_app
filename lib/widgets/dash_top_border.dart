import 'package:flutter/material.dart';

class DashedTopBorderContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final Color borderColor;
  final double dashWidth;
  final double dashSpace;

  const DashedTopBorderContainer({
    Key? key,
    required this.child,
    this.borderRadius = 10.0,
    this.borderWidth = 2.0,
    this.borderColor = Colors.black,
    this.dashWidth = 6.0,
    this.dashSpace = 4.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedTopBorderPainter(
        borderRadius: borderRadius,
        borderWidth: borderWidth,
        borderColor: borderColor,
        dashWidth: dashWidth,
        dashSpace: dashSpace,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );
  }
}

class _DashedTopBorderPainter extends CustomPainter {
  final double borderRadius;
  final double borderWidth;
  final Color borderColor;
  final double dashWidth;
  final double dashSpace;

  _DashedTopBorderPainter({
    required this.borderRadius,
    required this.borderWidth,
    required this.borderColor,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final half = borderWidth / 2.0;
    final left = half;
    final right = size.width - half;
    final top = half;
    final bottom = size.height - half;
    final r = borderRadius;

    final path = Path();

    // 左边
    path.moveTo(left, top + r - 4);
    path.lineTo(left, bottom - r);
    path.arcToPoint(
      Offset(left + r, bottom),
      radius: Radius.circular(r),
      clockwise: false,
    );

    // 下边
    path.lineTo(right - r, bottom);
    path.arcToPoint(
      Offset(right, bottom - r),
      radius: Radius.circular(r),
      clockwise: false,
    );

    // 右边
    path.lineTo(right, top + r);
    path.arcToPoint(
      Offset(right - r + 9, top),
      radius: Radius.circular(r),
      clockwise: false,
    );

    // 画左 / 下 / 右三边（实线）
    canvas.drawPath(path, paint);

    // 画虚线的上边
    double startX = left + r;
    final endX = right - r;
    final y = top;

    while (startX < endX) {
      final dashEnd = (startX + dashWidth).clamp(startX, endX);
      canvas.drawLine(Offset(startX, y), Offset(dashEnd, y), paint);
      startX = dashEnd + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedTopBorderPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace;
  }
}
