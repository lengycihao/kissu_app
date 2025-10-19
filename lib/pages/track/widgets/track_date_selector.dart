import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 轨迹页面专用的日期选择器组件
/// 提供最近7天的日期选择功能
class TrackDateSelector extends StatelessWidget {
  /// 当前选中索引
  final RxInt? selectedIndex;

  /// 点击日期回调，返回选中的 DateTime
  final void Function(DateTime date)? onSelect;

  /// 是否显示边框
  final bool showBorder;

  /// 选中项背景色
  final Color? selectedBackgroundColor;

  /// 选中项文字颜色
  final Color? selectedTextColor;

  /// 未选中项边框颜色
  final Color? unselectedBorderColor;

  /// 未选中项文字颜色
  final Color? unselectedTextColor;

  /// 组件高度
  final double height;

  /// 外边距
  final EdgeInsetsGeometry? margin;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 圆角半径
  final double borderRadius;

  const TrackDateSelector({
    Key? key,
    this.selectedIndex,
    this.onSelect,
    this.showBorder = true,
    this.selectedBackgroundColor,
    this.selectedTextColor,
    this.unselectedBorderColor,
    this.unselectedTextColor,
    this.height = 50,
    this.margin,
    this.padding,
    this.borderRadius = 8,
  }) : super(key: key);

  /// 最近7天日期列表（今天及之前6天）
  List<DateTime> get recentDates {
    final now = DateTime.now();
    // 反转顺序，让最左边是最早的，最右边是今天
    return List.generate(7, (index) => now.subtract(Duration(days: 6 - index)));
  }

  /// 日期显示文本（今天/昨天/周几）
  String getDateText(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return '今天';
    if (difference == 1) return '昨天';

    const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return weekdays[date.weekday % 7];
  }

  /// 日期数字
  String getDateNumber(DateTime date) => date.day.toString();

  @override
  Widget build(BuildContext context) {
    final dates = recentDates;
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - 14*3 - 48) / 7; // 平分屏幕宽度
    
    // 使用外部传入的selectedIndex或者创建本地的
    final currentSelectedIndex = selectedIndex ?? 6.obs;

    // 默认颜色
    final defaultSelectedBgColor = selectedBackgroundColor ?? const Color(0xFFFF74A0);
    final defaultSelectedTextColor = selectedTextColor ?? Colors.white;
    final defaultUnselectedBorderColor = unselectedBorderColor ??   Colors.transparent;
    final defaultUnselectedTextColor = unselectedTextColor ?? const Color(0xFF333333);

    return Container(
      height: height,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
      padding: padding,
      child: Row(
        children: List.generate(dates.length, (index) {
          final date = dates[index];

          return Obx(
            () => GestureDetector(
              onTap: () {
                currentSelectedIndex.value = index;
                print('📅 选择日期: ${date.toString().split(' ')[0]}');
                if (onSelect != null) {
                  onSelect!(date);
                }
              },
              child: Container(
                width: itemWidth,
                height: height,
                margin: EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: currentSelectedIndex.value == index
                      ? defaultSelectedBgColor
                      : Colors.transparent,
                  border: showBorder ? Border.all(
                    color: currentSelectedIndex.value == index
                        ? Colors.transparent
                        : defaultUnselectedBorderColor,
                    width: 1,
                  ) : null,
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      getDateText(date),
                      style: TextStyle(
                        fontSize: 13,
                        color: currentSelectedIndex.value == index
                            ? defaultSelectedTextColor
                            : defaultUnselectedTextColor,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      getDateNumber(date),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: currentSelectedIndex.value == index
                            ? defaultSelectedTextColor
                            : const Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
