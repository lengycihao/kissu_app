import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/utils/oktoast_util.dart';

/// 188补卡底部弹窗组件
class CheckIn188MakeupBottomSheet extends StatefulWidget {
  final List<String> missedDates; // 未打卡日期列表
  final int totalDays; // 总天数
  final int checkedDays; // 已打卡天数
  final int recoveryCardCount; // 补签卡数量

  const CheckIn188MakeupBottomSheet({
    super.key,
    required this.missedDates,
    required this.totalDays,
    required this.checkedDays,
    required this.recoveryCardCount,
  });

  @override
  State<CheckIn188MakeupBottomSheet> createState() =>
      _CheckIn188MakeupBottomSheetState();
}

class _CheckIn188MakeupBottomSheetState
    extends State<CheckIn188MakeupBottomSheet> {
  // 选中的日期集合
  final Set<String> selectedDates = {};

  /// 显示补卡弹窗
  static void show(
    BuildContext context, {
    required List<String> missedDates,
    required int totalDays,
    required int checkedDays,
    required int recoveryCardCount,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CheckIn188MakeupBottomSheet(
        missedDates: missedDates,
        totalDays: totalDays,
        checkedDays: checkedDays,
        recoveryCardCount: recoveryCardCount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 30),
              const Text(
                '补卡',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(
                  Icons.close,
                  size: 24,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 未打卡天数标题
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '未打卡天数',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
              Text(
                '共需要12张补签卡',
                style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 未打卡日期列表（最多显示3行，超过可滚动）
          _buildMissedDatesList(),

          const SizedBox(height: 20),

          // 188打卡奖励标题
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '188打卡奖励',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
          ),
          // const SizedBox(height: 12),

          // 进度条和红包图标
          _buildProgressBar(),

          const SizedBox(height: 16),

          // 补签卡数量和获取链接
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                '我的补签卡：${widget.recoveryCardCount}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
              ),
              GestureDetector(
                onTap: _onGetRecoveryCard,
                child: const Row(
                  children: [
                    Text(
                      '获取补签卡',
                      style: TextStyle(fontSize: 12, color: Color(0xFFFF6060)),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Color(0xFFFF6060),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 立即补卡按钮
          GestureDetector(
            onTap: selectedDates.isEmpty ? null : () => _onMakeupNow(context),
            child: Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                color: selectedDates.isEmpty
                    ? const Color(0xFFCCCCCC)
                    : Colors.black,
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: Text(
                selectedDates.isEmpty ? '补签卡不足' : '立即补卡',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 底部安全区域
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  /// 构建未打卡日期列表
  Widget _buildMissedDatesList() {
    // 计算列表高度：最多显示3行
    const double itemHeight = 36.0; // 每个日期项的高度
    const double spacing = 8.0; // 间距
    const int maxVisibleRows = 3;

    // 每行3个
    final int totalRows = (widget.missedDates.length / 3).ceil();
    final double maxHeight =
        maxVisibleRows * itemHeight + (maxVisibleRows - 1) * spacing;
    final double actualHeight =
        totalRows * itemHeight + (totalRows - 1) * spacing;

    return Container(
      constraints: BoxConstraints(
        maxHeight: actualHeight > maxHeight ? maxHeight : actualHeight,
      ),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.missedDates
              .map((date) => _buildDateItem(date))
              .toList(),
        ),
      ),
    );
  }

  /// 构建日期项
  Widget _buildDateItem(String date) {
    final isSelected = selectedDates.contains(date);

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedDates.remove(date);
              } else {
                selectedDates.add(date);
              }
            });
          },
          child: Container(
            width: (MediaQuery.of(context).size.width - 64) / 3,
            height: 36,
            decoration: BoxDecoration(
              
              color: isSelected ? Color(0xFFFF9AD9) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Text(
              date,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF333333),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建进度条
  Widget _buildProgressBar() {
    final double progress = widget.checkedDays / widget.totalDays;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // 进度文字
              Container(
                height: 20,
                padding: EdgeInsets.only(right: 10),
                 alignment: Alignment.centerRight,
                child: Text(
                  '补卡后，剩余${widget.totalDays - widget.checkedDays}天领取',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xff999999),
                  ),
                ),
              ),
              SizedBox(height: 10,),
              Stack(
                children: [
                  // 背景进度条
                  Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E5E5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  // 进度条
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF78CC), Color(0xFFFF2950)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // 红包图标
        Image.asset(
          'assets/188/kissu_188_red packet.webp',
          width: 58,
          height: 58,
        ),
      ],
    );
  }

  /// 获取补签卡
  void _onGetRecoveryCard() {
    Get.toNamed(KissuRoutePath.checkIn188RecoveryCard);
  }

  /// 立即补卡
  void _onMakeupNow(BuildContext context) {
    Navigator.of(context).pop();
    // TODO: 执行补卡逻辑
    OKToastUtil.showInfo('补卡功能开发中');
  }
}
