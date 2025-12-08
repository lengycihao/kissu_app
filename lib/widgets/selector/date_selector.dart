import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DateSelector extends StatelessWidget {
  /// 当前选中索引 - 现在从外部传入
  final RxInt? externalSelectedIndex;

  /// 点击日期回调，返回选中的 DateTime
  final void Function(DateTime date)? onSelect;

  DateSelector({Key? key, this.onSelect, this.externalSelectedIndex})
      : super(key: key);

  /// 最近7天日期列表（从6天前到今天），不包含未来日期
  /// 今天始终在最右边
  List<DateTime> get recentDates {
    final now = DateTime.now();
    // 生成最近7天：最左边是6天前，最右边是今天
    return List.generate(7, (index) => now.subtract(Duration(days: 6 - index)));
  }

  /// 日期显示文本：显示周几（周一、周二...周日）
  String getDateText(DateTime date) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    // weekday: 1-7 映射到 0-6
    return weekdays[date.weekday - 1];
  }

  /// 日期数字：今天显示“今”，其他显示具体日期数字
  String getDateNumber(DateTime date) {
    final now = DateTime.now();
    final bool isToday =
        now.year == date.year && now.month == date.month && now.day == date.day;
    if (isToday) return '今';
    return date.day.toString();
  }

  @override
  Widget build(BuildContext context) {
    final dates = recentDates;
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - 12*6 - 52) / 7; // 平分屏幕宽度
    
    // 使用外部传入的selectedIndex或者创建本地的
    final selectedIndex = externalSelectedIndex ?? 6.obs;

    return Container(
      height: 65,
      
      // margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                height: 45,
                margin: EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: selectedIndex.value == index
                      ? const Color(0xFFFF9AD8)
                      : Colors.transparent,
                  border: Border.all(
                    color: selectedIndex.value == index
                        ? Colors.transparent
                        : const Color(0xffDCDCDC),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      getDateText(date),
                      style: TextStyle(
                        fontSize: 10,
                        color: selectedIndex.value == index
                            ? Colors.white
                            : const Color(0x99000000),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      getDateNumber(date),
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'AlimamaShuHeiTi',
                        fontWeight: FontWeight.w500,
                        color: selectedIndex.value == index
                            ? Colors.white
                            : const Color(0x80333333),
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
