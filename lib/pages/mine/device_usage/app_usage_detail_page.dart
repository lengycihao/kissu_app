import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_usage_detail_controller.dart';
import 'dart:math' as math;
import 'package:kissu_app/widgets/selector/date_selector.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

/// App使用记录详情页面
class AppUsageDetailPage extends StatefulWidget {
  const AppUsageDetailPage({super.key});

  @override
  State<AppUsageDetailPage> createState() => _AppUsageDetailPageState();
}

class _AppUsageDetailPageState extends State<AppUsageDetailPage> with WidgetsBindingObserver {
  late AppUsageDetailController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AppUsageDetailController>();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      controller.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      controller.onAppResumed();
    }
  }

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
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await controller.loadData();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Column(
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
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 引导图覆盖层
          Obx(() => _buildGuideOverlay()),
        ],
      ),
    );
  }

  /// 顶部导航栏
  Widget _buildTopBar() {
    return SizedBox(
      height: 44,
      child: Stack(
        children: [
          // 返回按钮
          Positioned(
            left: 5,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: Image.asset(
                  "assets/images/kissu_mine_back.webp",
                  width: 22,
                  height: 22,
                ),
              ),
            ),
          ),
          // 标题 - 绝对居中
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                "Ta的手机使用记录",
                style: TextStyle(
                  fontSize: 16, // 用户特别要求改为16
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),
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
      height: 280,
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
            final isToday =
                selectedDate.year == now.year &&
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
                    ? "assets/4.0/kissu4_use_down.webp" // 下降
                    : "assets/4.0/kissu4_use_up.webp"; // 上升

                return Row(
                  children: [
                    Image.asset(iconPath, width: 12, height: 12),
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
          // 柱状图或空状态
          Obx(() {
            // 原始 24 小时数据（索引 0-23 对应 0-23 点）
            final fullData = controller.todayScreenUsage;

            // 只保留有数据的小时，X 轴只展示这些点
            final nonZeroHours = <int>[];
            for (int hour = 0; hour < fullData.length; hour++) {
              if (fullData[hour] > 0) {
                nonZeroHours.add(hour);
              }
            }

            // 如果没有数据，显示空状态
            if (nonZeroHours.isEmpty) {
              return _buildEmptyState();
            }

            // 有数据时，只显示有数据的小时
            final data = nonZeroHours.map((h) => fullData[h]).toList();
            final labels = nonZeroHours.map((h) => "$h点").toList();

            int maxValue = 60;

            return _buildBarChart(
              data: data,
              labels: labels,
              hours: nonZeroHours, // 传递真实的小时值列表
              color: const Color(0xFFFF88CC),
              maxValue: maxValue,
              unit: "分钟",
              valueFormatter: (value) => "$value分钟",
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
      height: 280,
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
            final isToday =
                selectedDate.year == now.year &&
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
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
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
                    ? "assets/4.0/kissu4_use_down.webp" // 下降
                    : "assets/4.0/kissu4_use_up.webp"; // 上升

                return Row(
                  children: [
                    Image.asset(iconPath, width: 12, height: 12),
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
          // 柱状图或空状态
          Obx(() {
            // 原始 24 小时数据（索引 0-23 对应 0-23 点）
            final fullData = controller.todayUnlockCount;

            // 只保留有数据的小时，X 轴只展示这些点
            final nonZeroHours = <int>[];
            for (int hour = 0; hour < fullData.length; hour++) {
              if (fullData[hour] > 0) {
                nonZeroHours.add(hour);
              }
            }

            // 如果没有数据，显示空状态
            if (nonZeroHours.isEmpty) {
              return _buildEmptyState();
            }

            // 有数据时，只显示有数据的小时
            final data = nonZeroHours.map((h) => fullData[h]).toList();
            final labels = nonZeroHours.map((h) => "$h点").toList();

            // 根据数据最大值向上取整到10的倍数
            int maxValue = _calculateChartMaxValue(
              data.reduce(math.max),
              50,
            );

            return _buildBarChart(
              data: data,
              labels: labels,
              hours: nonZeroHours, // 传递真实的小时值列表
              color: const Color(0xFFFF88CC),
              maxValue: maxValue,
              unit: "次",
              valueFormatter: (value) => "$value次",
              showAllLabels: false,
              yAxisReservedSize: 40,
              isScreenTimeChart: false, // 标识是解锁次数图表
            );
          }),
        ],
      ),
    );
  }

  /// 通用柱状图组件（使用自定义 CustomPaint 实现）
  Widget _buildBarChart({
    required List<int> data,
    required List<String> labels,
    required List<int> hours, // 真实的小时值列表（如[18, 20]）
    required Color color,
    required int maxValue,
    required String unit,
    required String Function(int) valueFormatter,
    required bool showAllLabels,
    required double yAxisReservedSize,
    required bool isScreenTimeChart,
  }) {
    bool isScreenTime = unit == "分钟";

    return Expanded(
      child: Obx(() {
        int touchedIndex = isScreenTimeChart
            ? controller.touchedScreenBarIndex.value
            : controller.touchedUnlockBarIndex.value;

        // 动态计算宽度，每根柱子宽度 + groupSpace
        // 左右两侧各添加12px的padding，让第一根和最后一根柱子不贴着边缘
        const double sidePadding = 12.0;
        double barWidth = 8;
        double groupSpace = 12;
        double chartWidth = sidePadding + data.length * (barWidth + groupSpace) + sidePadding;
        
        // 生成所有Y轴标签
        List<int> yAxisLabels = [];
        if (isScreenTimeChart) {
          for (int i = 0; i <= maxValue; i += 10) {
            yAxisLabels.add(i);
          }
        } else {
          if (maxValue <= 0) {
            yAxisLabels.add(0);
          } else if (maxValue <= 6) {
            for (int i = 0; i <= maxValue; i++) {
              yAxisLabels.add(i);
            }
          } else {
            // 正常情况：均分 6 份
            double rawInterval = maxValue / 6;
            // 把 interval 调整为最接近的 5 的倍数
            int niceInterval = (rawInterval / 5).ceil() * 5;
            // 根据新的 interval 再算 niceMax
            int niceMax = niceInterval * 6;
            // 生成 Y 轴标签
            for (int i = 0; i <= niceMax; i += niceInterval) {
              yAxisLabels.add(i);
            }
          }
        }

        // 获取水平虚线配置
        List<double> horizontalLineValues = [];
        if (isScreenTime && maxValue == 60) {
          // 屏幕使用时间：虚线应该和Y轴的20、40、60刻度对齐
          horizontalLineValues = [20, 40, 60];
        } else {
          horizontalLineValues = [
            maxValue / 3,
            maxValue * 2 / 3,
            maxValue.toDouble(),
          ];
        }

        // 统一的绘制高度（与图表绘制器保持一致）
        final double chartDrawHeight = isScreenTimeChart ? 160.0 : 150.0;
        const double bottomTitleHeight = 18.0;
        // Y轴标签区域和图表绘制区域的实际可用高度
        // 由于Container高度280，减去padding和顶部内容后，实际图表区域约252
        // 但为了对齐，我们使用固定的绘制高度chartDrawHeight
        // Y轴标签区域高度280，图表绘制区域高度300（CustomPaint的size）
        // 对齐规则：两个区域的底部(0值)和顶部(maxValue)应该对齐
        
        return Row(
          children: [
            // 固定的Y轴标签区域（高度280，与Container高度一致）
            SizedBox(
              width: yAxisReservedSize,
              height: 280,
              child: Stack(
                children: yAxisLabels.map((value) {
                  bool isLastLabel = value == yAxisLabels.last;
                  // 计算标签位置（从底部开始，与图表绘制器对齐）
                  // 图表绘制器：底部在y=282（距离顶部282px），顶部在y=282-chartDrawHeight
                  // Y轴标签区域高度280，使用bottom属性
                  // 对齐规则：
                  // - 图表底部y=282对应Y轴标签bottom=18（距离底部18px）
                  // - 图表顶部y=282-chartDrawHeight对应Y轴标签bottom=18+chartDrawHeight
                  // 由于Y轴标签区域280，图表区域300，需要调整：
                  // - Y轴标签底部应该在bottom=18位置（对应图表y=282）
                  // - Y轴标签顶部应该在bottom=18+chartDrawHeight位置（对应图表y=282-chartDrawHeight）
                  double ratio = value / maxValue;
                  // Y轴标签底部(0值)应该在bottom=bottomTitleHeight位置（18px）
                  // Y轴标签顶部(maxValue)应该在bottom=bottomTitleHeight+chartDrawHeight位置
                  double bottomOffset = bottomTitleHeight + (ratio * chartDrawHeight);

                  return Positioned(
                    bottom: bottomOffset,
                    right: 5,
                    child: Transform.translate(
                      offset: isLastLabel
                          ? const Offset(0, 8)
                          : const Offset(0, 5),
                      child: Text(
                        '$value$unit',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF333333),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            // 可滚动的图表区域
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: chartWidth < Get.width - 16 * 2 - 70
                      ? Get.width - 16 * 2 - 70
                      : chartWidth,
                  height: 300,
                  child: Stack(
                    children: [
                      // 自定义柱状图
                      GestureDetector(
                        onTapDown: (details) {
                          final localPosition = details.localPosition;
                          const double sidePadding = 12.0;
                          double totalBarWidth = barWidth + groupSpace;
                          // 考虑左侧padding，调整触摸位置计算
                          double adjustedX = localPosition.dx - sidePadding;
                          if (adjustedX < 0) {
                            adjustedX = 0;
                          }
                          int tappedIndex = (adjustedX / totalBarWidth).floor();

                          if (tappedIndex >= 0 && tappedIndex < data.length) {
                            if (touchedIndex == tappedIndex) {
                              // 再次点击同一个柱子，清除选中
                              if (isScreenTimeChart) {
                                controller.clearTouchedScreenBar();
                              } else {
                                controller.clearTouchedUnlockBar();
                              }
                            } else {
                              // 点击新的柱子，设置选中
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
                        },
                        child: CustomPaint(
                          size: Size(
                            chartWidth < Get.width - 16 * 2 - 70
                                ? Get.width - 16 * 2 - 70
                                : chartWidth,
                            300,
                          ),
                          painter: _BarChartPainter(
                            data: data,
                            hours: hours,
                            maxValue: maxValue,
                            barWidth: barWidth,
                            groupSpace: groupSpace,
                            touchedIndex: touchedIndex,
                            horizontalLineValues: horizontalLineValues,
                            isScreenTimeChart: isScreenTimeChart,
                            showAllLabels: showAllLabels,
                          ),
                        ),
                      ),
                      // 自定义 Tooltip
                      if (touchedIndex >= 0 && touchedIndex < data.length)
                        Builder(
                          builder: (tooltipContext) {
                            final availableWidth = Get.width - 16 * 2 - yAxisReservedSize;
                            final actualContainerWidth = chartWidth < availableWidth
                                ? availableWidth
                                : chartWidth;
                            final chartLeftOffset = chartWidth < availableWidth
                                ? (actualContainerWidth - chartWidth) / 2
                                : 0.0;
                            
                            // 计算tooltip位置（需要考虑左右padding）
                            const double sidePadding = 12.0;
                            double leftPosition =
                                sidePadding + touchedIndex * (barWidth + groupSpace) + chartLeftOffset;

                            // 根据图表类型使用不同的绘制区域高度（与图表绘制器对齐）
                            const double bottomTitleHeight = 18.0;
                            double chartDrawHeight = isScreenTimeChart ? 160.0 : 150.0;
                            double barHeight =
                                (data[touchedIndex] / maxValue) * chartDrawHeight;

                            Widget tooltipContent = GestureDetector(
                              onTap: () {
                                if (isScreenTimeChart) {
                                  controller.clearTouchedScreenBar();
                                } else {
                                  controller.clearTouchedUnlockBar();
                                }
                              },
                              child: Container(
                                width: 120,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _getTimeRangeText(touchedIndex, hours) +
                                        '\n' +
                                        (unit == "分钟"
                                            ? "使用了${data[touchedIndex]}分钟"
                                            : "解锁了${data[touchedIndex]}次"),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF000000),
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            );

                            const double tooltipWidth = 120.0;
                            const double tooltipHeight = 40.0;
                            
                            // 计算柱子的中心位置
                            double barCenterX = leftPosition + barWidth / 2;
                            
                            // 计算图表右边缘
                            double chartRightEdge = chartWidth + chartLeftOffset;
                            
                            // 判断tooltip应该放在柱子的左边还是右边
                            bool placeOnRight = true;
                            
                            if (barCenterX + tooltipWidth / 2 + 8 > chartRightEdge) {
                              placeOnRight = false;
                            }
                            
                            if (barCenterX - tooltipWidth / 2 - 8 < chartLeftOffset) {
                              placeOnRight = true;
                            }
                            
                            // 计算tooltip的水平位置
                            double tooltipLeft;
                            if (placeOnRight) {
                              tooltipLeft = leftPosition + barWidth + 8;
                            } else {
                              tooltipLeft = leftPosition - tooltipWidth - 8;
                            }
                            
                            // 确保tooltip不超出图表区域
                            if (tooltipLeft < chartLeftOffset) {
                              tooltipLeft = chartLeftOffset + 8;
                            }
                            if (tooltipLeft + tooltipWidth > chartRightEdge) {
                              tooltipLeft = chartRightEdge - tooltipWidth - 8;
                            }
                            
                            // 计算tooltip的垂直位置（贴在柱子顶部）
                            // 图表绘制器坐标系：从顶部(0)到底部(300)
                            // chartBottom = 300 - 18 = 282
                            // barTop = chartBottom - barHeight = 282 - barHeight
                            // Positioned的bottom属性：从Stack底部向上的距离
                            // 转换：Positioned bottom = 300 - 图表y坐标
                            
                            // 计算柱子在图表中的位置
                            const double stackHeight = 300.0;
                            double chartBottom = stackHeight - bottomTitleHeight; // 282
                            double barTop = chartBottom - barHeight; // 柱子顶部在图表中的y坐标
                            
                            // tooltip应该贴在柱子顶部，距离柱子顶部8px
                            // tooltip的底部应该在 barTop - 8 的位置
                            // Positioned bottom = 300 - (barTop - 8) = 300 - barTop + 8
                            double tooltipBottom = stackHeight - barTop + 8;
                            
                            // 如果tooltip会超出图表顶部，则调整位置
                            // 图表顶部y坐标 = chartBottom - chartDrawHeight = 282 - 160 = 122
                            double chartTop = chartBottom - chartDrawHeight;
                            double tooltipTop = stackHeight - tooltipBottom - tooltipHeight; // tooltip顶部在图表中的y坐标
                            
                            if (tooltipTop < chartTop) {
                              // tooltip超出顶部，放在柱子中间位置
                              double barCenter = barTop + barHeight / 2;
                              tooltipBottom = stackHeight - barCenter + tooltipHeight / 2;
                            }
                            
                            // 确保tooltip不会太低（至少距离底部18px，为X轴标签留空间）
                            if (tooltipBottom < bottomTitleHeight + tooltipHeight) {
                              tooltipBottom = bottomTitleHeight + tooltipHeight + 8;
                            }
                            
                            return Positioned(
                              left: tooltipLeft,
                              bottom: tooltipBottom,
                              child: tooltipContent,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  /// 获取时间范围文本
  String _getTimeRangeText(int index, List<int> hours) {
    // 使用真实的小时值列表
    if (index < 0 || index >= hours.length) {
      return "";
    }

    final startHour = hours[index];
    final endHour = startHour + 1;

    return "在${startHour}点~${endHour}点之间";
  }

  /// 空状态
  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/4.0/kissu4_use_app_empty.webp",
              width: 80,
              height: 80,
            ),
            const SizedBox(height: 12),
            const Text(
              "暂无使用数据",
              style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
            ),
          ],
        ),
      ),
    );
  }

  /// 计算图表最大值（向上取整到10的倍数）
  int _calculateChartMaxValue(int dataMax, int suggestedMax) {
    if (dataMax == 0) return suggestedMax;
    if (dataMax < 10) {
      return dataMax + 2;
    } else if (dataMax < 50) {
      return ((dataMax / 5).ceil()) * 5;
    } else {
      return ((dataMax / 10).ceil()) * 10;
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

  /// 构建引导图覆盖层
  Widget _buildGuideOverlay() {
    if (!controller.showGuideOverlay.value) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.black.withOpacity(0.7),
      child: SafeArea(
        child: Stack(
          children: [
            // 引导图图片 - 覆盖屏幕使用时间模块
            Positioned(
              top: 175, // 顶部导航栏44 + 日期选择器约80 + 标题16
              left: 16,
              right: 16,
              child: Column(
                children: [
                  Image.asset(
                    'assets/phone_history/kissu4_phone_history_guide.webp',
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/phone_history/kissu4_phone_history_guide_bottom.webp',
                        fit: BoxFit.contain,
                        width: 48,
                        height: 38,
                      ),
                      SizedBox(width: 56),
                      Image.asset(
                        'assets/phone_history/kissu4_phone_history_guide_right.webp',
                        fit: BoxFit.contain,
                        width: 32,
                        height: 10,
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image(
                        image: AssetImage(
                          'assets/phone_history/kissu4_phone_history_guide_title_left.webp',
                        ),
                        width: 14,
                        height: 14,
                      ),
                      SizedBox(width: 2),
                      Text(
                        '支持滑动查看更多内容~',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFFffffff),
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                          fontFamily: 'AlimamaShuHeiTi',
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      controller.hideGuideOverlay();
                    },
                    child: Container(
                      width: 90,
                      height: 30,
                      margin: EdgeInsets.only(top: 20),
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(
                            'assets/phone_history/kissu4_phone_history_guide_title.webp',
                          ),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 自定义柱状图绘制器
class _BarChartPainter extends CustomPainter {
  final List<int> data;
  final List<int> hours;
  final int maxValue;
  final double barWidth;
  final double groupSpace;
  final int touchedIndex;
  final List<double> horizontalLineValues;
  final bool isScreenTimeChart;
  final bool showAllLabels;

  _BarChartPainter({
    required this.data,
    required this.hours,
    required this.maxValue,
    required this.barWidth,
    required this.groupSpace,
    required this.touchedIndex,
    required this.horizontalLineValues,
    required this.isScreenTimeChart,
    required this.showAllLabels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // 与Y轴标签对齐：图表区域高度300，底部标签高度18
    // 图表底部应该在y=300-bottomTitleHeight的位置
    const double bottomTitleHeight = 18.0;
    final double chartDrawHeight = isScreenTimeChart ? 160.0 : 150.0;
    // 图表底部位置：从顶部向下300-bottomTitleHeight=282
    // 图表顶部位置：282-chartDrawHeight
    final double chartBottom = size.height - bottomTitleHeight; // 300 - 18 = 282
    // 左右两侧各添加12px的padding，让第一根和最后一根柱子不贴着边缘
    const double sidePadding = 12.0;
    final double chartLeft = sidePadding;

    // 绘制水平虚线
    final dashPaint = Paint()
      ..color = const Color(0xFFE5E5E5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (double value in horizontalLineValues) {
      double ratio = value / maxValue;
      double y = chartBottom - (ratio * chartDrawHeight);
      
      // 绘制虚线
      const dashWidth = 4.0;
      const dashSpace = 4.0;
      double currentX = chartLeft;
      while (currentX < size.width) {
        canvas.drawLine(
          Offset(currentX, y),
          Offset(currentX + dashWidth, y),
          dashPaint,
        );
        currentX += dashWidth + dashSpace;
      }
    }

    // 绘制底部边框
    final borderPaint = Paint()
      ..color = const Color(0xFFD2D2D2)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(chartLeft, chartBottom),
      Offset(size.width, chartBottom),
      borderPaint,
    );

    // 绘制柱状图
    for (int index = 0; index < data.length; index++) {
      // 添加左侧padding，让第一根柱子不贴着边缘
      double leftPosition = sidePadding + index * (barWidth + groupSpace);
      double barLeft = leftPosition;
      double barRight = barLeft + barWidth;
      
      bool hasValue = data[index] > 0;
      bool isTouched = touchedIndex == index;
      
      Color barColor;
      if (!hasValue) {
        barColor = const Color(0xFFFF88CC).withOpacity(0.1);
      } else if (touchedIndex == -1) {
        barColor = const Color(0xFFFFA2DC);
      } else if (isTouched) {
        barColor = const Color(0xFFFFA2DC);
      } else {
        barColor = const Color(0xFFFFE9F6);
      }

      if (hasValue) {
        double ratio = data[index] / maxValue;
        double barHeight = ratio * chartDrawHeight;
        double barTop = chartBottom - barHeight;

        // 绘制圆角矩形（柱子）
        final barPaint = Paint()
          ..color = barColor
          ..style = PaintingStyle.fill;

        final barRect = RRect.fromRectAndCorners(
          Rect.fromLTRB(barLeft, barTop, barRight, chartBottom),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        );

        canvas.drawRRect(barRect, barPaint);
      } else {
        // 绘制空值柱子（半透明）
        final barPaint = Paint()
          ..color = barColor
          ..style = PaintingStyle.fill;

        final barRect = RRect.fromRectAndCorners(
          Rect.fromLTRB(barLeft, chartBottom - 1, barRight, chartBottom),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        );

        canvas.drawRRect(barRect, barPaint);
      }

      // 绘制底部标签
      // X轴最多显示12个刻度，只显示奇数索引（index % 2 == 1）
      if (index < hours.length) {
        bool shouldShow = false;
        if (showAllLabels) {
          shouldShow = true;
        } else {
          // 只显示奇数索引（index % 2 == 1）
          if (index % 2 == 1) {
            // 计算当前索引之前有多少个奇数索引（包括当前）
            int oddIndexCount = 0;
            for (int i = 0; i <= index; i++) {
              if (i % 2 == 1) {
                oddIndexCount++;
              }
            }
            // 最多显示12个奇数索引
            shouldShow = oddIndexCount <= 12;
          } else {
            shouldShow = false;
          }
        }

        if (shouldShow) {
          final hour = hours[index];
          final textPainter = TextPainter(
            text: TextSpan(
              text: "$hour点",
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF333333),
              ),
            ),
            textDirection: ui.TextDirection.ltr,
            textAlign: TextAlign.center,
          );
          textPainter.layout();
          
          double labelX = barLeft + barWidth / 2 - textPainter.width / 2;
          double labelY = chartBottom + 3;
          
          textPainter.paint(canvas, Offset(labelX, labelY));
        }
      }
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.touchedIndex != touchedIndex ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.hours != hours;
  }
}
