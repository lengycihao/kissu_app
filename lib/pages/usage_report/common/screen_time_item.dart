import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kissu_app/models/screen_time_model.dart';

/// 屏幕使用时长记录列表项组件（公共组件，可在多个页面复用）
class ScreenTimeItemWidget extends StatelessWidget {
  final ScreenTimeRecordItem record;
  final VoidCallback? onTap;
  final bool showTimeLabel; // 是否显示时间标签（用于全部记录页面）

  const ScreenTimeItemWidget({
    super.key,
    required this.record,
    this.onTap,
    this.showTimeLabel = false, // 默认不显示
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 时间标签（仅在全部记录页面显示）
        if (showTimeLabel ) ...[
          const SizedBox(height: 8),
          _buildTimeLabel(),
          const SizedBox(height: 8),
        ],
        _buildNormalRecord(),
        // if (record.isPrivacyMessage) ...[
        //   // 隐私消息格式
        //   _buildPrivacyMessage(),
        // ] else ...[
        //   // 正常使用记录格式
        //   _buildNormalRecord(),
        // ],
      ],
    );
  }

  /// 构建时间标签
  Widget _buildTimeLabel() {
    final timeStr = DateFormat('HH:mm').format(record.startTime);
    return Center(
      child: Text(
        timeStr,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF999999),
        ),
      ),
    );
  }

  /// 构建正常记录
  Widget _buildNormalRecord() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          // mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 图标
            Image.asset(
              'assets/phone_history/kissu3_history_time_more.webp',
              width: 16,
              height: 16,
            ),
            const SizedBox(width: 4),
            // 时间段
            Text(
              record.timePeriodDisplay,
              style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFBF8FF),
                borderRadius: BorderRadius.circular(1000),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              child: Row(
                children: [
                  // 文字
                  const Text(
                    '使用屏幕时长',
                    style: TextStyle(fontSize: 13, color: Color(0xFF333333)),
                  ),
                  const SizedBox(width: 8),
                  // 时长（粉色）
                  Text(
                    record.durationDisplay,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFFF21AA),
                      fontWeight: FontWeight.w600,
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

