import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DateSelector extends StatelessWidget {
  /// 当前选中索引 - 现在从外部传入
  final RxInt? externalSelectedIndex;

  /// 点击日期回调，返回选中的 DateTime
  final void Function(DateTime date)? onSelect;

  DateSelector({Key? key, this.onSelect, this.externalSelectedIndex})
      : super(key: key);

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
    final itemWidth = (screenWidth - 40) / 7; // 平分屏幕宽度
    
    // 使用外部传入的selectedIndex或者创建本地的
    final selectedIndex = externalSelectedIndex ?? 6.obs;

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(dates.length, (index) {
          final date = dates[index];

          return Obx(
            () => GestureDetector(
              onTap: () {
                selectedIndex.value = index;
                print('📅 选择日期: ${date.toString().split(' ')[0]}');
                if (onSelect != null) {
                  onSelect!(date);
                }
              },
              child: Container(
                width: itemWidth,
                height: 50,
                decoration: BoxDecoration(
                  color: selectedIndex.value == index
                      ? const Color(0xFFFF6B9D)
                      : Colors.transparent,

                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      getDateText(date),
                      style: TextStyle(
                        fontSize: 13,
                        color: selectedIndex.value == index
                            ? Colors.white
                            : const Color(0xFF666666),
                      ),
                    ),
                    Text(
                      getDateNumber(date),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: selectedIndex.value == index
                            ? Colors.white
                            : const Color(0xFF333333),
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
