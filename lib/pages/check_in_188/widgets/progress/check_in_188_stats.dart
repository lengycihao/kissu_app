import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/check_in_188/widgets/check_in_188_makeup_bottom_sheet.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import '../../check_in_188_progress_controller.dart';

/// 188打卡进行中页面 - 打卡数据统计模块
class CheckIn188Stats extends StatelessWidget {
  final CheckIn188ProgressController controller;

  const CheckIn188Stats({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(15, 16, 15, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          _buildTitleRow(),
          const SizedBox(height: 16),
          // 未打卡天数和补卡按钮
          _buildMissedDaysRow(),
          const SizedBox(height: 16),
          // 统计数据行
          _buildStatsRow(),
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
          '打卡数据',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  /// 构建未打卡天数行
  Widget _buildMissedDaysRow() {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE9EBFF),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 未打卡天数
            Column(
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${controller.missedDays.value}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'AlimamaShuHeiTi',
                          color: Color(0xFF333333),
                        ),
                      ),
                      TextSpan(
                        text: '天',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF333333),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),
                const Text(
                  '未打卡天数',
                  style: TextStyle(fontSize: 12, color: Color(0xFF777777)),
                ),
              ],
            ),

            const SizedBox(width: 12),
            // 补卡按钮
            Column(
              children: [
                // 去补卡按钮
                GestureDetector(
                  onTap: () {
                    // 显示补卡弹窗
                    Get.bottomSheet(
                      CheckIn188MakeupBottomSheet(
                        missedDates: controller.missedDatesList,
                        totalDays: controller.totalDays.value,
                        checkedDays: controller.checkedDays.value,
                        recoveryCardCount: controller.recoveryCardCount.value,
                      ),
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9DA7), Color(0xFFFF9DA7)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '去补卡',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Get.toNamed(KissuRoutePath.checkIn188RecoveryCard);
                  },
                  child: const Text(
                    '获取补签卡>',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B75FF)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建统计数据行
  Widget _buildStatsRow() {
    return Obx(
      () => Row(
        children: [
          // 活动进度
          Expanded(
            child: _buildStatItem(
              value: '${controller.activityProgress.value}%',
              label: '活动进度',
            ),
          ),
          // 已打卡天数
          Expanded(
            child: _buildStatItem(
              value: '${controller.checkedInDays.value}天',
              label: '已打卡天数',
            ),
          ),
          // 剩余打卡天数
          Expanded(
            child: _buildStatItem(
              value: '${controller.remainingDays.value}天',
              label: '剩余打卡天数',
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单个统计项
  Widget _buildStatItem({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EBFF),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF777777)),
          ),
        ],
      ),
    );
  }
}
