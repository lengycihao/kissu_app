import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import '../../check_in_188_progress_controller.dart';

/// 188打卡进行中页面 - 打卡日历模块
class CheckIn188Calendar extends StatelessWidget {
  final CheckIn188ProgressController controller;

  const CheckIn188Calendar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(15, 16, 15, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行（有左右padding）
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildTitleRow(),
          ),
          const SizedBox(height: 12),
          // 提示信息（横向铺满，无左右边距）
          _buildTipRow(),
          const SizedBox(height: 12),
          // 月份切换（有左右padding）
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildMonthSelector(),
          ),
          const SizedBox(height: 16),
          // 星期标题（有左右padding）
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildWeekdayHeader(),
          ),
          const SizedBox(height: 11),
          // 日历网格（支持左右滑动切换月份，有左右padding）
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity > 500) {
                // 向右滑动，上一个月
                controller.changeMonth(-1);
              } else if (velocity < -500) {
                // 向左滑动，下一个月
                controller.changeMonth(1);
              }
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildCalendarGrid(),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建标题行
  Widget _buildTitleRow() {
    return Row(
      children: [
        Image.asset(
          'assets/188/kissu_188_label_color.webp',
          width: 7,
          height: 14,
        ),
        const SizedBox(width: 8),
        const Text(
          '打卡日历',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF333333),
          ),
        ),
        const Spacer(),
        // 补签卡
        Transform.translate(
          offset: Offset(16, 0),
          child: Image.asset(
            'assets/188/kissu_188_check_in_card.webp',
            height: 24,
          ),
        ),
      ],
    );
  }

  /// 构建提示信息行（横向铺满）
  Widget _buildTipRow() {
    return Obx(
      () => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8EB),
             ),
            child: Row(
              children: [
                const Image(
                  image: AssetImage('assets/188/kissu_188_warning.webp'),
                  width: 14,
                  height: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '目前有${controller.missedDays.value}次未打卡，请在本阶段结束前补卡',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFDE6464),
                  ),
                ),
                const Spacer(),
                     GestureDetector(
                  onTap: () {
                    Get.toNamed(KissuRoutePath.checkIn188RecoveryCard);
                  },
                  child: const Text(
                    '去补卡>',
                    style: TextStyle(fontSize: 12, color: Color(0xFFDE6464)),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  /// 构建月份选择器
  Widget _buildMonthSelector() {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => controller.changeMonth(-1),
            child: Image(image: AssetImage('assets/188/kissu_188_calendar_left.webp'),width: 14,),
          ),
          const SizedBox(width: 26),
          Text(
            '${controller.currentYear.value}年${controller.currentMonth.value}月',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(width: 26),
          GestureDetector(
            onTap: () => controller.changeMonth(1),
            child: Image(image: AssetImage('assets/188/kissu_188_calendar_right.webp'),width: 14,),
          ),
        ],
      ),
    );
  }

  /// 构建星期标题
  Widget _buildWeekdayHeader() {
    const weekdays = ['日', '一', '二', '三', '四', '五', '六'];
    return Row(
      children: weekdays
          .map(
            (day) => Expanded(
              child: Center(
                child: Text(
                  day,
                  style: const TextStyle(
                    fontSize: 14,fontWeight: FontWeight.w500,
                    color: Color(0xFFaaaaaa),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  /// 构建日历网格
  Widget _buildCalendarGrid() {
    return Obx(() {
      final year = controller.currentYear.value;
      final month = controller.currentMonth.value;

      // 获取当月第一天是星期几
      final firstDay = DateTime(year, month, 1);
      final firstWeekday = firstDay.weekday % 7; // 0=周日

      // 获取当月天数
      final daysInMonth = DateTime(year, month + 1, 0).day;

      // 获取今天
      final today = DateTime.now();
      final isCurrentMonth = today.year == year && today.month == month;
      final todayDay = today.day;

      // 构建日历格子
      List<Widget> rows = [];
      List<Widget> currentRow = [];

      // 填充第一周的空白
      for (int i = 0; i < firstWeekday; i++) {
        currentRow.add(const Expanded(child: SizedBox()));
      }

      // 填充日期
      for (int day = 1; day <= daysInMonth; day++) {
        final dateKey = '$year-$month-$day';
        final record = controller.checkInRecords[dateKey];
        
        // 当前日期
        final currentDate = DateTime(year, month, day);
        // 是否在活动期间内
        final isInActivityPeriod = controller.isDateInActivityPeriod(currentDate);
        // 是否是未来日期（相对于今天）
        final isFutureDate = currentDate.isAfter(today);
        final isToday = isCurrentMonth && day == todayDay;

        currentRow.add(
          Expanded(
            child: _buildDayCell(
              day: day,
              record: record,
              isFuture: isFutureDate,
              isToday: isToday,
              isInActivityPeriod: isInActivityPeriod,
            ),
          ),
        );

        if (currentRow.length == 7) {
          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: currentRow),
            ),
          );
          currentRow = [];
        }
      }

      // 填充最后一周的空白
      if (currentRow.isNotEmpty) {
        while (currentRow.length < 7) {
          currentRow.add(const Expanded(child: SizedBox()));
        }
        rows.add(Row(children: currentRow));
      }

      return Column(children: rows);
    });
  }

  /// 构建单个日期格子
  /// 日历状态说明：
  /// - 不在活动期间内：无背景，只显示日期数字
  /// - 活动期间内的未来日期：kissu_188_calendar_future_bg.webp
  /// - 活动期间内一个任务都没完成：kissu_188_calendar_empty_bg（无元素）
  /// - 活动期间内完成了部分任务但未全部完成：kissu_188_calendar_empty_bg + 心形元素
  /// - 活动期间内双方都完成：kissu_188_calendar_done_bg
  /// - 活动期间内缺卡日期（一个任务都没完成的历史日期）：kissu_188_calendar_buka_bg（无元素）
  Widget _buildDayCell({
    required int day,
    Map<String, int>? record,
    required bool isFuture,
    required bool isToday,
    required bool isInActivityPeriod,
  }) {
    final myProgress = record?['me'] ?? 0;
    final partnerProgress = record?['partner'] ?? 0;
    final bothComplete = myProgress == 2 && partnerProgress == 2;
    // 缺卡：活动期间内的历史日期且一个任务都没完成
    final isMissed = isInActivityPeriod && !isFuture && !isToday && record != null && myProgress == 0 && partnerProgress == 0;
    // 部分完成：有记录但未全部完成
    final isPartialComplete = isInActivityPeriod && record != null && !bothComplete && !isMissed && (myProgress > 0 || partnerProgress > 0);

    return Container(
      height: 62, // 增加高度，日期数字放在背景下方
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 背景图片区域
          SizedBox(
            width: 36,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 背景图片（只在活动期间内显示）
                if (!isInActivityPeriod)
                  // 不在活动期间内，无背景
                  const SizedBox()
                else if (isFuture)
                  // 活动期间内的未来日期
                  Image.asset(
                    'assets/188/kissu_188_calendar_future_bg.webp',
                    width: 36,
                    height: 40,
                    fit: BoxFit.fill,
                  )
                else if (bothComplete)
                  // 双方都完成
                  Image.asset(
                    'assets/188/kissu_188_calendar_done_bg.webp',
                    width: 36,
                    height: 40,
                    fit: BoxFit.fill,
                  )
                else if (isMissed)
                  // 缺卡日期（一个任务都没完成）
                  Image.asset(
                    'assets/188/kissu_188_calendar_buka_bg.webp',
                    width: 36,
                    height: 40,
                    fit: BoxFit.fill,
                  )
                else if (isPartialComplete)
                  // 部分完成，显示空背景+心形元素
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/188/kissu_188_calendar_empty_bg.webp',
                        width: 36,
                        height: 40,
                        fit: BoxFit.fill,
                      ),
                      // 我完成的心（左下角）
                      if (myProgress == 2)
                        Positioned(
                          bottom: 2,
                          left: 2,
                          child: Image.asset(
                            'assets/188/kissu_188_calendar_me_heart.webp',
                            width: 10,
                            height: 10,
                          ),
                        ),
                      // 对方完成的心（右下角）
                      if (partnerProgress == 2)
                        Positioned(
                          bottom: 2,
                          right: 4,
                          child: Image.asset(
                            'assets/188/kissu_188_calendar_she_heart.webp',
                            width: 13,
                            height: 13,
                          ),
                        ),
                    ],
                  )
                else if (isInActivityPeriod)
                  // 活动期间内但一个任务都没完成（今天）
                  Image.asset(
                    'assets/188/kissu_188_calendar_empty_bg.webp',
                    width: 36,
                    height: 40,
                    fit: BoxFit.fill,
                  ),
                // 今天标记
                if (isToday)
                  Positioned(
                    top: 3,
                    child: const Text(
                        '今天',
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          // 日期数字（放在背景下方）
          Text(
            '$day',
            style: TextStyle(
              fontSize: 12,
              fontWeight:  FontWeight.w500 ,
              color: isToday ? const Color(0xFFaaaaaa) : const Color(0xFFaaaaaa),
            ),
          ),
        ],
      ),
    );
  }
}
