import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:kissu_app/models/screen_time_model.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';

/// 简单曲线图组件
class SimpleCurveChart extends StatelessWidget {
  final String iconPath;
  final String title;
  final String timePeriod;
  final int count;
  final List<ChartDataPoint> data;
  final Color backgroundColor;
  final Color curveColor;
  final Color gradientStartColor;
  final Color gradientEndColor;

  const SimpleCurveChart({
    super.key,
    required this.iconPath,
    required this.title,
    required this.timePeriod,
    required this.count,
    required this.data,
    this.backgroundColor = Colors.white,
    this.curveColor = const Color(0xFFFFBBAD),
    this.gradientStartColor = const Color(0x33FFBBAD),
    this.gradientEndColor = const Color(0x00FFBBAD),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 100, // 整个白色容器固定高度100
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行（图标 + 文字）
          Row(
            children: [
              Image.asset(
                iconPath,
                width: 16,
                height: 16,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF666666),
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 内容区域：左侧时间段和次数，右侧曲线图
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 左侧：时间段和次数（竖向排列）
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timePeriod,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count次',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                // 右侧：曲线图（不显示X轴标签）
                Expanded(
                  child: Builder(
                    builder: (context) {
                      // 创建一个 GlobalKey 来访问 _ChartPainter 的状态
                      final chartKey = GlobalKey<_ChartPainterState>();
                      return GestureDetector(
                        // 直接在这里处理点击，绕过内部复杂的手势处理
                        onTapUp: (details) {
                          logDebug('🎯 卡片级点击: ${details.localPosition}', tag: 'SimpleCurveChart');
                          // 调用图表的点击处理
                          chartKey.currentState?._handleTap(details.localPosition);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: _ChartPainter(
                          key: chartKey,
                          data: data,
                          curveColor: curveColor,
                          gradientStartColor: gradientStartColor,
                          gradientEndColor: gradientEndColor,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends StatefulWidget {
  final List<ChartDataPoint> data;
  final Color curveColor;
  final Color gradientStartColor;
  final Color gradientEndColor;

  const _ChartPainter({
    super.key,
    required this.data,
    required this.curveColor,
    required this.gradientStartColor,
    required this.gradientEndColor,
  });

  @override
  State<_ChartPainter> createState() => _ChartPainterState();
}

class _ChartPainterState extends State<_ChartPainter> {
  int? _selectedIndex; // 选中的点的索引

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const Center(
        child: Text(
          '暂无数据',
          style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
        ),
      );
    }

    // 简化版：只负责绘制
    return CustomPaint(
      painter: _CurvePainter(
        data: widget.data,
        curveColor: widget.curveColor,
        gradientStartColor: widget.gradientStartColor,
        gradientEndColor: widget.gradientEndColor,
        selectedIndex: _selectedIndex,
      ),
      child: Container(),
    );
  }

  void _handleTap(Offset position) {
    // 找到最近的点
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    if (widget.data.isEmpty) return;

    final maxValue = widget.data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) return;

    final chartHeight = size.height;
    final chartWidth = size.width;
    final stepX = chartWidth / (widget.data.length - 1);

    // 计算所有点的坐标
    final points = <Offset>[];
    for (var i = 0; i < widget.data.length; i++) {
      final x = i * stepX;
      final normalizedValue = widget.data[i].value / maxValue;
      final y = chartHeight * (1 - normalizedValue);
      points.add(Offset(x, y));
    }

    // 找到最近的点
    double minDistance = double.infinity;
    int closestIndex = 0;

    for (var i = 0; i < points.length; i++) {
      final distance = (points[i] - position).distance;
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    // 如果点击位置在点附近（30像素内），则选中该点
    if (minDistance < 30) {
      logDebug('📍 选中点 $closestIndex, 距离: ${minDistance.toStringAsFixed(1)}px', tag: 'SimpleCurveChart');
      setState(() {
        _selectedIndex = closestIndex;
      });
    } else {
      logDebug('❌ 点击空白区域, 最近距离: ${minDistance.toStringAsFixed(1)}px, 隐藏 Marker', tag: 'SimpleCurveChart');
      setState(() {
        _selectedIndex = null;
      });
    }
  }
}

class _CurvePainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final Color curveColor;
  final Color gradientStartColor;
  final Color gradientEndColor;
  final int? selectedIndex;

  _CurvePainter({
    required this.data,
    required this.curveColor,
    required this.gradientStartColor,
    required this.gradientEndColor,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // 找到最大值用于归一化
    final maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) return;

    final chartHeight = size.height; // 使用全部高度
    final chartWidth = size.width;
    final stepX = chartWidth / (data.length - 1);

    // 计算所有点的坐标
    final points = <Offset>[];
    for (var i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedValue = data[i].value / maxValue;
      final y = chartHeight * (1 - normalizedValue);
      points.add(Offset(x, y));
    }

    // 绘制渐变填充区域
    final gradientPath = Path();
    gradientPath.moveTo(points.first.dx, chartHeight);
    gradientPath.lineTo(points.first.dx, points.first.dy);

    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final controlPoint1 = Offset(
        current.dx + (next.dx - current.dx) / 3,
        current.dy,
      );
      final controlPoint2 = Offset(
        current.dx + (next.dx - current.dx) * 2 / 3,
        next.dy,
      );
      gradientPath.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        next.dx,
        next.dy,
      );
    }

    gradientPath.lineTo(points.last.dx, chartHeight);
    gradientPath.close();

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [gradientStartColor, gradientEndColor],
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight));

    canvas.drawPath(gradientPath, gradientPaint);

    // 绘制曲线
    final curvePath = Path();
    curvePath.moveTo(points.first.dx, points.first.dy);

    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final controlPoint1 = Offset(
        current.dx + (next.dx - current.dx) / 3,
        current.dy,
      );
      final controlPoint2 = Offset(
        current.dx + (next.dx - current.dx) * 2 / 3,
        next.dy,
      );
      curvePath.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        next.dx,
        next.dy,
      );
    }

    final curvePaint = Paint()
      ..color = curveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(curvePath, curvePaint);

    // 绘制数据点
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final isSelected = selectedIndex == i;
      
      // 普通点
      final pointPaint = Paint()
        ..color = curveColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, isSelected ? 5 : 3, pointPaint);
      
      // 如果是选中的点，绘制外圈和 Marker
      if (isSelected) {
        // 绘制白色外圈
        final outerCirclePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(point, 6, outerCirclePaint);
        
        // 绘制 Marker 标签
        _drawMarker(canvas, point, data[i], size);
      }
    }
  }

  void _drawMarker(Canvas canvas, Offset point, ChartDataPoint dataPoint, Size size) {
    // 格式化时间显示，例如 "2点"
    final timeStr = '${dataPoint.label}点';
    final valueStr = '${dataPoint.value.toInt()}次';
    
    // 创建文本画笔
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    // 绘制时间
    textPainter.text = TextSpan(
      text: timeStr,
      style: const TextStyle(
        color: Color(0xFF666666),
        fontSize: 10,
        fontWeight: FontWeight.w400,
      ),
    );
    textPainter.layout();
    
    // 绘制次数
    final valuePainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    valuePainter.text = TextSpan(
      text: valueStr,
      style: const TextStyle(
        color: Color(0xFF333333),
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
    valuePainter.layout();
    
    // 计算标签背景的宽度和高度
    final padding = 6.0;
    final spacing = 2.0;
    final labelWidth = [textPainter.width, valuePainter.width].reduce((a, b) => a > b ? a : b) + padding * 2;
    final labelHeight = textPainter.height + valuePainter.height + spacing + padding * 2;
    
    // 计算标签位置（在点的上方，避免超出边界）
    var labelLeft = point.dx - labelWidth / 2;
    var labelTop = point.dy - labelHeight - 12; // 12 是箭头高度
    
    // 边界检测
    if (labelLeft < 0) labelLeft = 0;
    if (labelLeft + labelWidth > size.width) labelLeft = size.width - labelWidth;
    if (labelTop < 0) labelTop = point.dy + 12; // 如果上方放不下，就放下方
    
    // 绘制标签背景（带圆角）
    final labelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(labelLeft, labelTop, labelWidth, labelHeight),
      const Radius.circular(4),
    );
    
    final labelPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(labelRect, labelPaint);
    
    // 绘制阴影边框
    final borderPaint = Paint()
      ..color = const Color(0x1A000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(labelRect, borderPaint);
    
    // 绘制小三角箭头（指向点）
    final arrowPath = Path();
    final arrowCenterX = point.dx.clamp(labelLeft + 6, labelLeft + labelWidth - 6);
    
    if (labelTop < point.dy) {
      // 箭头在下方（标签在上方）
      arrowPath.moveTo(arrowCenterX, labelTop + labelHeight);
      arrowPath.lineTo(arrowCenterX - 4, labelTop + labelHeight);
      arrowPath.lineTo(arrowCenterX, labelTop + labelHeight + 6);
      arrowPath.lineTo(arrowCenterX + 4, labelTop + labelHeight);
    } else {
      // 箭头在上方（标签在下方）
      arrowPath.moveTo(arrowCenterX, labelTop);
      arrowPath.lineTo(arrowCenterX - 4, labelTop);
      arrowPath.lineTo(arrowCenterX, labelTop - 6);
      arrowPath.lineTo(arrowCenterX + 4, labelTop);
    }
    arrowPath.close();
    canvas.drawPath(arrowPath, labelPaint);
    
    // 绘制文本内容
    final textX = labelLeft + padding;
    var textY = labelTop + padding;
    
    textPainter.paint(canvas, Offset(textX, textY));
    textY += textPainter.height + spacing;
    valuePainter.paint(canvas, Offset(textX, textY));
  }

  @override
  bool shouldRepaint(covariant _CurvePainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.selectedIndex != selectedIndex;
  }
}

