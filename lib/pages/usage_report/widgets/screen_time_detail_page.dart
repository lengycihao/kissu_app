import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/models/screen_time_model.dart';
import 'package:kissu_app/pages/usage_report/usage_report_controller.dart';
import '../common/screen_time_item.dart';

/// 屏幕使用时长详情页面
class ScreenTimeDetailPage extends StatefulWidget {
  const ScreenTimeDetailPage({super.key});

  @override
  State<ScreenTimeDetailPage> createState() => _ScreenTimeDetailPageState();
}

class _ScreenTimeDetailPageState extends State<ScreenTimeDetailPage> {
  final ScrollController _scrollController = ScrollController();
  final UsageReportController _controller = Get.find<UsageReportController>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Obx(() {
            final data = _controller.screenTimeData.value;
            
            // 如果没有数据，显示空状态
            if (data == null || data.records.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.hourglass_empty, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      '暂无屏幕使用记录',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }
            
            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                // 柱状图（包含标题）
                SliverToBoxAdapter(child: _buildBarChart(data)),
                // 曲线图部分（暂不使用）
                // SliverToBoxAdapter(child: _buildChartsSection()),
                // 记录列表
                SliverPadding(
                  padding: const EdgeInsets.only(top: 12, bottom: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildRecordItem(data.records[index]);
                      },
                      childCount: data.records.length,
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  /// 构建柱状图
  Widget _buildBarChart(ScreenTimeDetailModel data) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12).copyWith(top: 20),
      padding: const EdgeInsets.all(16),
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 25,
            left: 16,
            right: 16,
            bottom: 0,
            child: _InteractiveBarChart(data: data.hourlyData),
          ),
          // 标题在柱状图背景上
          Positioned(
            top: 0,
            left: 0,
            child: Row(
              children: [
                Image.asset(
                  'assets/phone_history/kissu3_history_time_more.webp',
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  '屏幕使用时长',
                  style: TextStyle(fontSize: 14, color: Color(0xFF333333)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建记录项（使用公共组件）
  Widget _buildRecordItem(ScreenTimeRecordItem record) {
    return ScreenTimeItemWidget(record: record);
  }
}

/// 交互式柱状图组件
class _InteractiveBarChart extends StatefulWidget {
  final List<ChartDataPoint> data;

  const _InteractiveBarChart({required this.data});

  @override
  State<_InteractiveBarChart> createState() => _InteractiveBarChartState();
}

class _InteractiveBarChartState extends State<_InteractiveBarChart> {
  int? _selectedIndex; // 选中的柱子索引

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (details) {
        _handleTap(details.localPosition);
      },
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        painter: _BarChartPainter(
          data: widget.data,
          selectedIndex: _selectedIndex,
        ),
        child: Container(),
      ),
    );
  }

  void _handleTap(Offset position) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    if (widget.data.isEmpty) return;

    final maxValue = widget.data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) return;

    // 计算柱子位置
    final barCount = widget.data.length;
    final barWidth = 5.0;
    final totalBarWidth = barCount * barWidth;
    final totalSpacing = size.width - totalBarWidth;
    final spacing = barCount > 1 ? totalSpacing / (barCount - 1) : 0;

    // 找到点击的柱子
    int closestIndex = -1;
    double minDistance = double.infinity;

    for (int i = 0; i < widget.data.length; i++) {
      final barX = i * (barWidth + spacing);
      final barCenterX = barX + barWidth / 2;
      final distance = (position.dx - barCenterX).abs();

      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    // 如果点击在柱子附近（30像素内），则选中
    if (minDistance < 30 && closestIndex >= 0) {
      setState(() {
        _selectedIndex = closestIndex;
      });
    } else {
      setState(() {
        _selectedIndex = null;
      });
    }
  }
}

/// 柱状图绘制器
class _BarChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final int? selectedIndex;

  _BarChartPainter({
    required this.data,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // 找到最大值用于归一化
    final maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) return;

    // 计算每个柱子的宽度和间距
    final barCount = data.length;
    final barWidth = 5.0; // 固定柱子宽度5px
    final totalBarWidth = barCount * barWidth; // 所有柱子总宽度
    final totalSpacing = size.width - totalBarWidth; // 剩余空间作为间距
    final spacing = barCount > 1 ? totalSpacing / (barCount - 1) : 0; // 间距

    // 绘制柱子
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final normalizedHeight = (point.value / maxValue) * size.height;
      final x = i * (barWidth + spacing);
      final y = size.height - normalizedHeight;

      // 使用渐变色（参考曲线图的颜色）
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFFBBAD),
          const Color(0x80FFBBAD), // 0.5 opacity
        ],
      );

      final rect = Rect.fromLTWH(x, y, barWidth, normalizedHeight);
      paint.shader = gradient.createShader(rect);

      // 绘制圆角矩形
      final rRect = RRect.fromRectAndRadius(
        rect,
        const Radius.circular(2.5), // 5px宽度的一半作为圆角半径
      );
      canvas.drawRRect(rRect, paint);

      // 如果是选中的柱子，绘制marker
      if (selectedIndex == i) {
        final barCenterX = x + barWidth / 2;
        final barTop = y;
        _drawMarker(canvas, Offset(barCenterX, barTop), point, size);
      }
    }
  }

  void _drawMarker(Canvas canvas, Offset point, ChartDataPoint dataPoint, Size size) {
    // 格式化时间显示，例如 "8点"
    final timeStr = '${dataPoint.label}点';
    final valueStr = '${dataPoint.value.toInt()}min';
    
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
    
    // 绘制时长
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
    
    // 计算标签位置（在柱子上方，避免超出边界）
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
    
    // 绘制小三角箭头（指向柱子顶部）
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
  bool shouldRepaint(_BarChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.selectedIndex != selectedIndex;
  }
}
