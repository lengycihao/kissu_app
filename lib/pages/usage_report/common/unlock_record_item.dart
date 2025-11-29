import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kissu_app/utils/network_image_helper.dart';
import 'package:kissu_app/models/unlock_record_model.dart';
import 'package:kissu_app/utils/user_manager.dart';

/// 解锁记录列表项组件（公共组件，可在多个页面复用）
class UnlockRecordItemWidget extends StatelessWidget {
  final UnlockRecordItem record;
  final VoidCallback? onTap;
  final bool showTimeLabel; // 是否显示时间标签（用于全部记录页面）

  const UnlockRecordItemWidget({
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
        if (showTimeLabel) ...[
          const SizedBox(height: 8),
          _buildTimeLabel(),
          const SizedBox(height: 8),
        ],
        GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(left: 17, right: 17, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildSingleActionRow(record),
                // // 根据是否为时段记录显示不同样式
                // if (record.isPeriodRecord)
                //   _buildPeriodRecordRow(record)
                // else
                //   _buildSingleActionRow(record),
                // // 额外信息（移动距离和停留点）
                // if (record.hasExtraInfo) ...[
                //   const SizedBox(height: 12),
                //   _buildExtraInfo(record),
                // ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建时间标签
  Widget _buildTimeLabel() {
    final timeStr = DateFormat('HH:mm').format(record.time);
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

  /// 构建单个操作行（样式1：单行显示）
  Widget _buildSingleActionRow(UnlockRecordItem record) {
    return Row(
      // mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 操作图标（优先使用网络图标）
        _buildIcon(record.icon, record.action),
        const SizedBox(width: 4),
        // 时间和文字
        Text(
          '对方在${record.timeDisplay}',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(width: 4),
        // 操作文字
        Text(
          record.action == UnlockActionType.lock ? '锁定手机' : '解锁手机',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  /// 构建时段记录行（样式2：解锁->锁定，带虚线）
  Widget _buildPeriodRecordRow(UnlockRecordItem record) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 左侧：解锁图标（使用本地图标，因为type 19没有专门的解锁/锁定图标）
        _buildLocalIcon(UnlockActionType.unlock),
        const SizedBox(width: 4),
        // 解锁手机文字
        const Text(
          '解锁手机',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(width: 4),
        // 解锁时间
        Text(
          record.timeDisplay,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF999999),
          ),
        ),
        const SizedBox(width: 20),
        // 中间：虚线（固定宽度）
        SizedBox(
          width: 56,
          child: CustomPaint(
            size: const Size(60, 1),
            painter: _DashedLinePainter(),
          ),
        ),
        const SizedBox(width: 20),
        // 右侧：锁定图标（使用本地图标）
        _buildLocalIcon(UnlockActionType.lock),
        const SizedBox(width: 4),
        // 锁定手机文字
        const Text(
          '锁定手机',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(width: 4),
        // 锁定时间
        Text(
          record.endTimeDisplay,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }

  /// 构建图标（优先使用网络图标，否则使用本地图标）
  Widget _buildIcon(String iconUrl, UnlockActionType action) {
    if (iconUrl.isNotEmpty) {
      // 使用网络图标
      return NetworkImageHelper.loadImage(
        imageUrl: iconUrl,
        width: 16,
        height: 16,
        errorWidget: _buildLocalIcon(action),
      );
    } else {
      // 没有网络图标，使用本地图标
      return _buildLocalIcon(action);
    }
  }

  /// 构建本地图标（兜底方案）
  Widget _buildLocalIcon(UnlockActionType action) {
    final icon = action == UnlockActionType.lock
        ? 'assets/phone_history/kissu3_history_lock.webp'
        : 'assets/phone_history/kissu3_history_unlock.webp';
    return Image.asset(icon, width: 16, height: 16);
  }

  /// 构建额外信息（移动距离和停留点）
  Widget _buildExtraInfo(UnlockRecordItem record) {
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        // 移动距离
        if (record.movementDistance != null)
          _buildInfoItem(
            icon: 'assets/phone_history/kissu3_history_location.webp',
            label: '期间定位移动',
            value: record.distanceDisplay!,
          ),
        // 停留点
        if (record.stayPointCount != null)
          _buildInfoItem(
            icon: 'assets/phone_history/kissu3_history_stay.webp',
            label: '期间停留点产生',
            value: '${record.stayPointCount}个',
          ),
      ],
    );
  }

  /// 构建信息项
  Widget _buildInfoItem({
    required String icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(icon, width: 12, height: 12),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFFF21AA),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// 虚线绘制器
class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE9CFFF)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 3.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

