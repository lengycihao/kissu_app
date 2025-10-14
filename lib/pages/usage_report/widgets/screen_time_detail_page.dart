import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/models/screen_time_model.dart';
import 'package:kissu_app/pages/usage_report/usage_report_controller.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
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
            final controller = Get.find<UsageReportController>();
            
            // 检查是否所有敏感度筛选都未选中
            final hasNoSensitiveLevelSelected = !controller.filterHighSensitive.value && 
                                               !controller.filterMediumSensitive.value && 
                                               !controller.filterLowSensitive.value;
            
            if (hasNoSensitiveLevelSelected) {
              return _buildNoSensitiveLevelSelectedState();
            }
            
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
      padding: const EdgeInsets.all(16).copyWith(left: 0,top: 14,bottom: 14),
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 25,
            left: 0,
            right: 16,
            bottom: 0,
            child: _InteractiveBarChart(data: data.hourlyData),
          ),
          // 标题在柱状图背景上
          Positioned(
            top: 0,
            left: 16,
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
          // 毛玻璃遮罩层 - 只在非会员时显示，只覆盖柱状图区域，不盖住标题
          if (!UserManager.isVip)
            Positioned(
              top: 25, // 从标题下方开始
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () async {
                  // 跳转到VIP页面
                  await Get.toNamed(KissuRoutePath.vip);
                  // VIP页面返回后刷新用户信息
                  await UserManager.refreshUserInfo();
                  // 刷新数据
                  _controller.loadData();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 第一行：会员图标 + 开通会员 + 箭头图标
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/phone_history/kissu3_vip_logo.webp',
                              width: 16,
                              height: 16,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '开通会员',
                              style: TextStyle(fontSize: 13, color: Color(0xFFFF9500)),
                            ),
                            const SizedBox(width: 4),
                            Image.asset(
                              'assets/phone_history/kissu3_vip_go.webp',
                              width: 6,
                              height: 6,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // 第二行：解锁对方屏幕使用报告
                        const Text(
                          '解锁对方屏幕使用报告',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Color(0xFF333333)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建记录项（使用公共组件）
  Widget _buildRecordItem(ScreenTimeRecordItem record) {
    return ScreenTimeItemWidget(
      record: record,
      onVipStatusChanged: () => _controller.loadData(), // VIP状态变化时刷新数据
    );
  }

  /// 构建未选择敏感度筛选的状态
  Widget _buildNoSensitiveLevelSelectedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/phone_history/kissu_phone_list_empty.webp', width: 128, height: 128),
          const SizedBox(height: 16),
          const Text(
            '请选择敏感度筛选条件',
            style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 8),
          const Text(
            '在右上角筛选中选择高敏感、中敏感或低敏感',
            style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC)),
          ),
        ],
      ),
    );
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
  Timer? _hideTimer; // 自动隐藏定时器

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  /// 计算合适的Y轴最大值，使其为整齐的数字
  double _calculateNiceMaxValue(double rawMaxValue) {
    if (rawMaxValue <= 0) return 0;
    
    // 定义合适的刻度值
    final niceValues = [
      5, 10, 15, 20, 25, 30, 40, 50, 60, 70, 80, 90, 100, 120
    ];
    
    // 找到第一个大于等于原始最大值的合适值
    for (final value in niceValues) {
      if (value >= rawMaxValue) {
        return value.toDouble();
      }
    }
    
    // 如果都不满足，返回原始值向上取整到10的倍数
    return ((rawMaxValue / 10).ceil() * 10).toDouble();
  }

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

    final rawMaxValue = widget.data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final adjustedMaxValue = rawMaxValue > 120 ? 120.0 : rawMaxValue;
    final maxValue = _calculateNiceMaxValue(adjustedMaxValue);
    if (maxValue == 0) return;

    // 计算柱子位置
    final barCount = widget.data.length;
    final barWidth = 8.0; // 与绘制器中的宽度保持一致
    final totalBarWidth = barCount * barWidth;
    final totalSpacing = size.width - 40 - totalBarWidth; // 为y轴留出40px空间
    final spacing = barCount > 1 ? totalSpacing / (barCount - 1) : 0;

    // 找到点击的柱子
    int closestIndex = -1;
    double minDistance = double.infinity;

    for (int i = 0; i < widget.data.length; i++) {
      final barX = 40 + i * (barWidth + spacing); // 为y轴留出40px空间
      final barCenterX = barX + barWidth / 2;
      final distance = (position.dx - barCenterX).abs();

      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    // 如果点击在柱子附近（30像素内）且柱子值不为0，则选中
    if (minDistance < 30 && closestIndex >= 0 && widget.data[closestIndex].value > 0) {
      setState(() {
        _selectedIndex = closestIndex;
      });
      
      // 取消之前的定时器
      _hideTimer?.cancel();
      
      // 设置2秒后自动隐藏tooltip
      _hideTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _selectedIndex = null;
          });
        }
      });
    } else {
      setState(() {
        _selectedIndex = null;
      });
      _hideTimer?.cancel();
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

  /// 计算合适的Y轴最大值，使其为整齐的数字
  double _calculateNiceMaxValue(double rawMaxValue) {
    if (rawMaxValue <= 0) return 0;
    
    // 定义合适的刻度值
    final niceValues = [
      5, 10, 15, 20, 25, 30, 40, 50, 60, 70, 80, 90, 100, 120
    ];
    
    // 找到第一个大于等于原始最大值的合适值
    for (final value in niceValues) {
      if (value >= rawMaxValue) {
        return value.toDouble();
      }
    }
    
    // 如果都不满足，返回原始值向上取整到10的倍数
    return ((rawMaxValue / 10).ceil() * 10).toDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // 找到最大值用于归一化，但不超过120分钟
    final rawMaxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final adjustedMaxValue = rawMaxValue > 120 ? 120.0 : rawMaxValue;
    final maxValue = _calculateNiceMaxValue(adjustedMaxValue);
    if (maxValue == 0) return;

    // 绘制y轴
    _drawYAxis(canvas, size, maxValue);
    
    // 绘制x轴
    _drawXAxis(canvas, size);
    
    // 计算每个柱子的宽度和间距
    final barCount = data.length;
    final barWidth = 8.0; // 增加柱子宽度到8px，因为现在只有12个柱子
    final totalBarWidth = barCount * barWidth; // 所有柱子总宽度
    final totalSpacing = size.width - 40 - totalBarWidth; // 为y轴留出40px空间
    final spacing = barCount > 1 ? totalSpacing / (barCount - 1) : 0; // 间距

    // 绘制柱子
    final paint = Paint()..style = PaintingStyle.fill;
    final backgroundPaint = Paint()
      ..color = const Color(0xFFFFF0ED)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final x = 40 + i * (barWidth + spacing); // 为y轴留出40px空间
      
      // 绘制背景柱子（撑满y轴高度）
      final backgroundHeight = size.height - 20; // 减少底部空间
      final backgroundY = 10.0; // 顶部空间
      final backgroundRect = Rect.fromLTWH(x, backgroundY, barWidth, backgroundHeight);
      final backgroundRRect = RRect.fromRectAndRadius(
        backgroundRect,
        const Radius.circular(4.0),
      );
      canvas.drawRRect(backgroundRRect, backgroundPaint);
      
      // 绘制数据柱子（只有值大于0时才绘制）
      if (point.value > 0) {
        final normalizedHeight = (point.value / maxValue) * (size.height - 20); // 减少底部空间
        final y = size.height - 10 - normalizedHeight; // 减少底部空间

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
          const Radius.circular(4.0), // 增加圆角半径
        );
        canvas.drawRRect(rRect, paint);
      }

      // 如果是选中的柱子，绘制marker
      if (selectedIndex == i && point.value > 0) {
        final normalizedHeight = (point.value / maxValue) * (size.height - 20);
        final y = size.height - 10 - normalizedHeight;
        final barCenterX = x + barWidth / 2;
        final barTop = y;
        _drawMarker(canvas, Offset(barCenterX, barTop), point, size);
      }
    }
  }

  /// 绘制y轴
  void _drawYAxis(Canvas canvas, Size size, double maxValue) {
    // 只绘制y轴标签，不绘制横线
    for (int i = 0; i <= 4; i++) {
      final y = 10 + (size.height - 20) * i / 4; // 减少底部空间
      
      // 绘制y轴标签
      final value = maxValue * (4 - i) / 4;
      _drawYAxisLabel(canvas, Offset(0, y), '${value.toInt()}');
    }
  }

  /// 绘制x轴
  void _drawXAxis(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFF0ED)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // 绘制x轴线
    final xAxisY = size.height - 10; // x轴位置
    final startX = 40.0; // 从y轴标签后开始
    final endX = size.width;
    
    canvas.drawLine(
      Offset(startX, xAxisY),
      Offset(endX, xAxisY),
      paint,
    );
  }
  
  /// 绘制y轴标签
  void _drawYAxisLabel(Canvas canvas, Offset position, String label) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Color(0xFF999999),
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    // 右对齐绘制标签
    final textX = position.dx + 30 - textPainter.width; // 距离y轴5px
    final textY = position.dy - textPainter.height / 2;
    textPainter.paint(canvas, Offset(textX, textY));
  }


  void _drawMarker(Canvas canvas, Offset point, ChartDataPoint dataPoint, Size size) {
    // 格式化显示文本
    String displayText;
    
    if (dataPoint.hourDetails != null && dataPoint.hourDetails!.isNotEmpty) {
      // 使用hourDetails数组格式化文本
      final lines = dataPoint.hourDetails!.map((detail) {
        return '${detail.hour}点：${detail.durationMinutes}min';
      }).toList();
      displayText = lines.join('\n');
    } else if (dataPoint.detail != null) {
      // 使用detail字符串
      displayText = dataPoint.detail!;
    } else {
      // 使用默认格式
      displayText = '${dataPoint.label}点：${dataPoint.value.toInt()}min';
    }
    
    // 创建文本画笔，支持多行显示
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      maxLines: null, // 支持多行
    );
    
    // 绘制详细信息
    textPainter.text = TextSpan(
      text: displayText,
      style: const TextStyle(
        color: Color(0xFF333333),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.2, // 行高
      ),
    );
    textPainter.layout(maxWidth: 200); // 设置最大宽度
    
    // 计算标签背景的宽度和高度
    final padding = 8.0; // 增加padding以适应多行文本
    final labelWidth = textPainter.width + padding * 2;
    final labelHeight = textPainter.height + padding * 2;
    
    // 智能计算标签位置，避免被右边柱子遮挡
    var labelLeft = point.dx - labelWidth / 2;
    var labelTop = point.dy - labelHeight - 12; // 12 是箭头高度
    
    // 优化水平位置：如果tooltip会超出右边界或者柱子在右半部分，则向左偏移
    final chartCenterX = size.width / 2;
    if (point.dx > chartCenterX || labelLeft + labelWidth > size.width - 20) {
      // 柱子在右半部分或tooltip会超出边界，将tooltip放在柱子左侧
      labelLeft = point.dx - labelWidth - 8; // 距离柱子8px
      if (labelLeft < 0) {
        // 如果左侧也放不下，则尽量居中但确保不超出边界
        labelLeft = (size.width - labelWidth).clamp(0, size.width - labelWidth);
      }
    } else {
      // 柱子在左半部分，正常居中显示
      if (labelLeft < 0) labelLeft = 0;
      if (labelLeft + labelWidth > size.width) labelLeft = size.width - labelWidth;
    }
    
    // 垂直位置检测
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
      ..color = const Color(0xFFFFBBAD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(labelRect, borderPaint);
    
    // 绘制小三角箭头（指向柱子顶部）
    final arrowPath = Path();
    
    // 判断tooltip相对于柱子的位置来决定箭头方向
    final tooltipCenterX = labelLeft + labelWidth / 2;
    final isTooltipOnLeft = tooltipCenterX < point.dx - 10; // tooltip在柱子左侧
    final isTooltipOnRight = tooltipCenterX > point.dx + 10; // tooltip在柱子右侧
    
    if (isTooltipOnLeft) {
      // tooltip在柱子左侧，箭头从右边指向柱子
      final arrowY = labelTop + labelHeight / 2;
      arrowPath.moveTo(labelLeft + labelWidth, arrowY);
      arrowPath.lineTo(labelLeft + labelWidth, arrowY - 4);
      arrowPath.lineTo(labelLeft + labelWidth + 6, arrowY);
      arrowPath.lineTo(labelLeft + labelWidth, arrowY + 4);
    } else if (isTooltipOnRight) {
      // tooltip在柱子右侧，箭头从左边指向柱子
      final arrowY = labelTop + labelHeight / 2;
      arrowPath.moveTo(labelLeft, arrowY);
      arrowPath.lineTo(labelLeft, arrowY - 4);
      arrowPath.lineTo(labelLeft - 6, arrowY);
      arrowPath.lineTo(labelLeft, arrowY + 4);
    } else {
      // tooltip在柱子上方或下方，使用原来的垂直箭头
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
    }
    arrowPath.close();
    
    // 绘制箭头填充
    canvas.drawPath(arrowPath, labelPaint);
    
    // 绘制箭头边框
    final arrowBorderPaint = Paint()
      ..color = const Color(0xFFFFBBAD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(arrowPath, arrowBorderPaint);
    
    // 绘制文本内容
    final textX = labelLeft + padding;
    final textY = labelTop + padding;
    
    textPainter.paint(canvas, Offset(textX, textY));
  }

  @override
  bool shouldRepaint(_BarChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.selectedIndex != selectedIndex;
  }
}
