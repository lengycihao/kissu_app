import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'app_usage_detail_controller.dart';
import 'dart:math' as math;
import 'package:kissu_app/widgets/selector/date_selector.dart';
import 'package:intl/intl.dart';

/// App使用记录详情页面
class AppUsageDetailPage extends GetView<AppUsageDetailController> {
  const AppUsageDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Stack(
        children: [
          // 背景图片（与顶部对齐）
          Positioned.fill(
            child: Image.asset(
              "assets/4.0/kissu4_new_use_bg.webp",
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // 顶部导航栏
                _buildTopBar(),
                // 内容区域
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Obx(() {
                      if (!controller.hasTodayData) {
                        return _buildEmptyState();
                      }

                      return Column(
                        children: [
                          // 日期选择器（已有自己的margin，不需要额外padding）
                          _buildDateSelector(),
                          const SizedBox(height: 16),
                          // 标题行（使用与主页面相同的样式）
                          _buildModuleTitle("屏幕使用时间"),
                          const SizedBox(height: 12),
                          // 屏幕使用时间
                          _buildScreenUsageChart(),
                          const SizedBox(height: 16),
                          _buildModuleTitle("手机解锁次数"),
                          const SizedBox(height: 12),
                          // 手机解锁次数
                          _buildUnlockCountChart(),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 顶部导航栏
  Widget _buildTopBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 返回按钮
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                "assets/4.0/kissu4_back.webp",
                width: 24,
                height: 24,
              ),
            ),
          ),
          // 标题
          const Expanded(
            child: Center(
              child: Text(
                "Ta的手机使用记录",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  /// 日期选择器
  Widget _buildDateSelector() {
    return DateSelector(
      externalSelectedIndex: controller.selectedDateIndex,
      onSelect: (date) {
        controller.changeDate(date);
      },
    );
  }

  /// 屏幕使用时间图表
  Widget _buildScreenUsageChart() {
    return Container(
      height: 260,
      padding: const EdgeInsets.only(left: 13, right: 14, top: 14, bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日期和总时长
          Obx(() {
            final selectedDate = controller.selectedDate.value;
            final now = DateTime.now();
            final isToday = selectedDate.year == now.year &&
                selectedDate.month == now.month &&
                selectedDate.day == now.day;
            
            final dateStr = DateFormat('M月d日').format(selectedDate);
            final displayText = isToday ? '$dateStr（今天）' : dateStr;
            
            return Text(
              displayText,
              style: const TextStyle(fontSize: 11, color: Color(0xFF333333)),
            );
          }),
          const SizedBox(height: 4),
          // 总时长
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(() {
                String totalTime = controller.todayTotalScreenTime;

                // 解析时间字符串
                final match = RegExp(r'(\d+)小时(\d+)分').firstMatch(totalTime);
                String hours = match?.group(1) ?? "0";
                String minutes = match?.group(2) ?? "00";

                return Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: hours,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const TextSpan(
                        text: "小时",
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xcc333333),
                        ),
                      ),
                      TextSpan(
                        text: minutes,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const TextSpan(
                        text: "分",
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xcc333333),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              // 趋势显示（根据trend值显示）
              Obx(() {
                final trend = controller.screenTrend.value;
                final trendText = controller.screenTrendText.value;

                // trend为0时不显示
                if (trend == 0 || trendText.isEmpty) {
                  return const SizedBox.shrink();
                }

                // 根据trend显示不同的图标
                String iconPath = trend == 1
                    ? "assets/4.0/kissu4_use_down.webp"  // 下降
                    : "assets/4.0/kissu4_use_up.webp";   // 上升

                return Row(
                  children: [
                    Image.asset(
                      iconPath,
                      width: 12,
                      height: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trendText,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 15),
          // 柱状图
          Obx(() {
            List<int> data = controller.todayScreenUsage.sublist(0, 19); // 只显示0-18点
            List<String> labels = List.generate(19, (i) => "$i点");

            int maxValue = 60;

            return _buildBarChart(
              data: data,
              labels: labels,
              color: const Color(0xFFFF88CC),
              maxValue: maxValue,
              unit: "分钟",
              valueFormatter: (value) => "$value分钟",
              isToday: true,
              showAllLabels: false,
              yAxisReservedSize: 45,
              isScreenTimeChart: true, // 标识是屏幕使用时间图表
            );
          }),
        ],
      ),
    );
  }

  /// 手机解锁次数图表
  Widget _buildUnlockCountChart() {
    return Container(
      height: 260,
      padding: const EdgeInsets.only(left: 13, right: 14, top: 14, bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日期和对比
          Obx(() {
            final selectedDate = controller.selectedDate.value;
            final now = DateTime.now();
            final isToday = selectedDate.year == now.year &&
                selectedDate.month == now.month &&
                selectedDate.day == now.day;
            
            final dateStr = DateFormat('M月d日').format(selectedDate);
            final displayText = isToday ? '$dateStr（今天）' : dateStr;
            
            return Text(
              displayText,
              style: const TextStyle(fontSize: 11, color: Color(0xFF333333)),
            );
          }),
          const SizedBox(height: 4),
          // 总次数和趋势
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(() {
                int totalCount = controller.todayTotalUnlockCount;

                return Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "$totalCount",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333), 
                        ),
                      ),
                      const TextSpan(
                        text: "次",
                        style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                      ),
                    ],
                  ),
                );
              }),
              // 趋势显示（根据trend值显示）
              Obx(() {
                final trend = controller.unlockTrend.value;
                final trendText = controller.unlockTrendText.value;
                
                // trend为0时不显示
                if (trend == 0 || trendText.isEmpty) {
                  return const SizedBox.shrink();
                }
                
                // 根据trend显示不同的图标
                String iconPath = trend == 1 
                    ? "assets/4.0/kissu4_use_down.webp"  // 下降
                    : "assets/4.0/kissu4_use_up.webp";   // 上升
                
                return Row(
                  children: [
                    Image.asset(
                      iconPath,
                      width: 12,
                      height: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trendText,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 15),
          // 柱状图
          Obx(() {
            List<int> data = controller.todayUnlockCount.sublist(0, 19); // 只显示0-18点
            List<String> labels = List.generate(19, (i) => "$i点");

            // 根据数据最大值向上取整到10的倍数
            int maxValue = _calculateChartMaxValue(
              data.isEmpty ? 0 : data.reduce(math.max),
              50,
            );

            return _buildBarChart(
              data: data,
              labels: labels,
              color: const Color(0xFFFF88CC),
              maxValue: maxValue,
              unit: "次",
              valueFormatter: (value) => "$value次",
              isToday: true,
              showAllLabels: false,
              yAxisReservedSize: 40,
              isScreenTimeChart: false, // 标识是解锁次数图表
            );
          }),
        ],
      ),
    );
  }

  /// 通用柱状图组件（使用fl_chart）
  Widget _buildBarChart({
    required List<int> data,
    required List<String> labels,
    required Color color,
    required int maxValue,
    required String unit,
    required String Function(int) valueFormatter,
    required bool isToday,
    required bool showAllLabels,
    required double yAxisReservedSize,
    required bool isScreenTimeChart,
  }) {
    bool isScreenTime = unit == "分钟" && isToday;
    
    return Expanded(
      child: Obx(() {
        int touchedIndex = isScreenTimeChart 
            ? controller.touchedScreenBarIndex.value 
            : controller.touchedUnlockBarIndex.value;
        
        return BarChart(
          BarChartData(
            maxY: maxValue.toDouble(),
            minY: 0,
            barTouchData: BarTouchData(
              enabled: true,
              handleBuiltInTouches: false,
              touchCallback: (FlTouchEvent event, barTouchResponse) {
                if (event is FlTapUpEvent) {
                  // 点击松开时处理
                  if (barTouchResponse?.spot != null) {
                    int tappedIndex = barTouchResponse!.spot!.touchedBarGroupIndex;
                    // 如果点击的是当前已选中的柱子，则取消选中
                    if (touchedIndex == tappedIndex) {
                      if (isScreenTimeChart) {
                        controller.clearTouchedScreenBar();
                      } else {
                        controller.clearTouchedUnlockBar();
                      }
                    } else {
                      // 否则选中新的柱子
                      if (isScreenTimeChart) {
                        controller.setTouchedScreenBarIndex(tappedIndex);
                      } else {
                        controller.setTouchedUnlockBarIndex(tappedIndex);
                      }
                    }
                  } else {
                    // 点击空白区域，清除选中
                    if (isScreenTimeChart) {
                      controller.clearTouchedScreenBar();
                    } else {
                      controller.clearTouchedUnlockBar();
                    }
                  }
                }
              },
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => Colors.white,
                tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                tooltipMargin: 8,
                tooltipRoundedRadius: 4,
                tooltipBorder: const BorderSide(color: Color(0xFFE5E5E5), width: 1),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  if (touchedIndex != groupIndex) return null;
                  
                  int value = rod.toY.round();
                  String timeRange = _getTimeRangeText(groupIndex, labels, isToday);
                  String valueText = unit == "分钟" ? "使用了$value分钟" : "解锁了$value次";
                  
                  return BarTooltipItem(
                    '$timeRange\n$valueText',
                    const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF333333),
                      height: 1.4,
                    ),
                  );
                },
              ),
            ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            // Y轴
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: yAxisReservedSize,
                interval: isToday ? 10 : 1, // 当天每10显示，本周每1检查
                getTitlesWidget: (value, meta) {
                  if (isToday) {
                    // 当天数据：显示所有刻度（每10一个）
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Text(
                        '${value.toInt()}$unit',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF999999)),
                        textAlign: TextAlign.right,
                      ),
                    );
                  } else {
                    // 本周数据：只显示4个关键刻度点
                    int label2 = ((maxValue * 2 / 3) / 10).round() * 10;
                    int label3 = ((maxValue / 3) / 10).round() * 10;
                    
                    if ((value - maxValue).abs() < 0.5 || 
                        (value - label2).abs() < 0.5 || 
                        (value - label3).abs() < 0.5 || 
                        value == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Text(
                          '${value.toInt()}$unit',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF999999)),
                          textAlign: TextAlign.right,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }
                },
              ),
            ),
            // X轴
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < labels.length) {
                    bool shouldShow = showAllLabels || index % 4 == 0;
                    if (shouldShow) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          labels[index],
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF333333),
                          ),
                        ),
                      );
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          // 网格线（关闭默认网格）
          gridData: FlGridData(
            show: false,
          ),
          // 边框
          borderData: FlBorderData(
            show: true,
            border: const Border(
              bottom: BorderSide(color: Color(0xFFD2D2D2), width: 0.5),
              left: BorderSide.none,
              top: BorderSide.none,
              right: BorderSide.none,
            ),
          ),
          // 柱状图数据
          barGroups: List.generate(data.length, (index) {
            bool isTouched = touchedIndex == index;
            bool hasValue = data[index] > 0;
            
            Color barColor;
            if (!hasValue) {
              barColor = color.withValues(alpha: 0.1);
            } else if (touchedIndex == -1) {
              // 未点击状态：正常颜色 #FFA2DC
              barColor = const Color(0xFFFFA2DC);
            } else if (isTouched) {
              // 被点击的柱子：正常颜色 #FFA2DC
              barColor = const Color(0xFFFFA2DC);
            } else {
              // 其他柱子：变淡 #FFE9F6
              barColor = const Color(0xFFFFE9F6);
            }
            
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: data[index].toDouble(),
                  color: barColor,
                  width: isToday ? 8 : 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }),
          // 使用extraLinesData精确绘制虚线（会在柱状图下方）
          extraLinesData: ExtraLinesData(
            horizontalLines: _getHorizontalLines(maxValue, isScreenTime),
            extraLinesOnTop: false, // 虚线在柱状图下方
          ),
        ),
        );
      }),
    );
  }

  /// 获取时间范围文本
  String _getTimeRangeText(int index, List<String> labels, bool isToday) {
    if (isToday) {
      // 当天：显示"在X点~Y点之间"
      int startHour = index;
      int endHour = index + 1;
      return "在$startHour点~$endHour点之间";
    } else {
      // 本周：显示日期
      return labels[index];
    }
  }

  /// 空状态
  Widget _buildEmptyState() {
    return Container(
      height: 500,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            "assets/4.0/kissu4_use_app_empty.webp",
            width: 100,
            height: 100,
          ),
          const SizedBox(height: 16),
          const Text(
            "暂无使用数据啊",
            style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }

  /// 计算图表最大值（向上取整到10的倍数）
  int _calculateChartMaxValue(int dataMax, int suggestedMax) {
    if (dataMax == 0) return suggestedMax;
    return ((dataMax / 10).ceil()) * 10;
  }

  /// 获取水平虚线配置
  List<HorizontalLine> _getHorizontalLines(int maxValue, bool isScreenTime) {
    if (isScreenTime && maxValue == 60) {
      // 当天屏幕使用时间：在20、40、50分钟位置画虚线
      return [
        HorizontalLine(
          y: 20,
          color: const Color(0xFFE5E5E5),
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
        HorizontalLine(
          y: 40,
          color: const Color(0xFFE5E5E5),
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
        HorizontalLine(
          y: 50,
          color: const Color(0xFFE5E5E5),
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      ];
    } else {
      // 其他情况：均匀分布的虚线
      int label2 = ((maxValue * 2 / 3) / 10).round() * 10;
      int label3 = ((maxValue / 3) / 10).round() * 10;
      double mid = ((label2 + label3) / 2 / 10).round() * 10.0;
      
      return [
        HorizontalLine(
          y: label2.toDouble(),
          color: const Color(0xFFE5E5E5),
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
        HorizontalLine(
          y: mid,
          color: const Color(0xFFE5E5E5),
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
        HorizontalLine(
          y: label3.toDouble(),
          color: const Color(0xFFE5E5E5),
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      ];
    }
  }

  /// 模块标题（带背景和tip图标）
  Widget _buildModuleTitle(String title) {
    return Row(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Image.asset(
              "assets/4.0/kissu4_new_use_label_bg.webp",
              height: 12,
              width: 116,
              fit: BoxFit.fitWidth,
            ),
            SizedBox(
              height: 20,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'AlimamaShuHeiTi',
                      color: Color(0xFF333333),
                    ),
                  ),
                  Image.asset(
                    "assets/4.0/kissu4_app_use_tip.webp",
                    width: 13,
                    height: 17,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
