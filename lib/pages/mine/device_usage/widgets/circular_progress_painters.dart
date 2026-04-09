import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 虚线圆环绘制器
class DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedCirclePainter({
    required this.color,
    this.strokeWidth = 2,
    this.dashWidth = 6,
    this.dashSpace = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    double startAngle = -math.pi / 2;
    final totalDashSpace = dashWidth + dashSpace;
    final circumference = 2 * math.pi * radius;
    final dashCount = (circumference / totalDashSpace).floor();

    for (int i = 0; i < dashCount; i++) {
      final sweepAngle = dashWidth / radius;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += totalDashSpace / radius;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 渐变圆形进度条绘制器（带白色终点圆）
class GradientCircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final List<Color> gradientColors;

  GradientCircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 绘制背景圆环
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 绘制渐变进度
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final sweepAngle = 2 * math.pi * progress;

      final gradient = SweepGradient(
        colors: gradientColors,
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + sweepAngle,
        transform: const GradientRotation(0),
      );

      final progressPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, progressPaint);

      // 绘制终点白色圆
      final endAngle = -math.pi / 2 + sweepAngle;
      final endX = center.dx + radius * math.cos(endAngle);
      final endY = center.dy + radius * math.sin(endAngle);
      final endPoint = Offset(endX, endY);

      final dotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(endPoint, strokeWidth / 2 - 1, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
