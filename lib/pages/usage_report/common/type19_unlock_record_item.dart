import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/unlock_record_model.dart';
import '../../../services/tracking_service.dart';
import '../../../utils/user_manager.dart';
import '../../../routers/kissu_route_path.dart';

/// 类型19解锁记录专用组件
/// 包含额外信息（移动距离和停留点）和毛玻璃效果
class Type19UnlockRecordItemWidget extends StatelessWidget {
  final UnlockRecordItem record;
  final bool showTimeLabel;
  final VoidCallback? onTap;
  final VoidCallback? onVipStatusChanged; // VIP状态变化回调

  const Type19UnlockRecordItemWidget({
    Key? key,
    required this.record,
    this.showTimeLabel = false,
    this.onTap,
    this.onVipStatusChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 时间标签
        if (showTimeLabel) ...[
          _buildTimeLabel(),
          const SizedBox(height: 8),
        ],
        // 检查是否需要显示毛玻璃效果（敏感记录且非会员）
        if (_shouldShowBlurOverlay())
          _buildBlurOverlay()
        else
          _buildNormalContent(),
      ],
    );
  }

  /// 判断是否需要显示毛玻璃效果
  bool _shouldShowBlurOverlay() {
    // 类型19的解锁记录在非会员状态下显示毛玻璃效果
    return !UserManager.isVip;
  }

  /// 构建正常内容（会员状态）
  Widget _buildNormalContent() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 根据是否为时段记录显示不同样式
            if (record.isPeriodRecord)
              _buildPeriodRecordRow(record)
            else
              _buildSingleActionRow(record),
            // 额外信息（移动距离和停留点）
            if (record.hasExtraInfo) ...[
              const SizedBox(height: 12),
              _buildExtraInfo(record),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建毛玻璃遮罩效果（非会员状态的敏感记录）
  Widget _buildBlurOverlay() {
    return GestureDetector(
      onTap: () async {
        // 上报会员可见按钮埋点
        try {
          await TrackingService.trackMembershipOnly();
          print('✅ 会员可见按钮埋点上报成功');
        } catch (e) {
          print('❌ 会员可见按钮埋点上报失败: $e');
        }
        
        // 跳转到VIP页面
        await Get.toNamed(
          KissuRoutePath.vip,
          arguments: {
            'previousPageName': '用机记录页面',
            'previousPageId': 'device_usage_record_page',
          },
        );
        // VIP页面返回后刷新用户信息
        await UserManager.refreshUserInfo();
        // 通知父组件刷新UI
        onVipStatusChanged?.call();
      },
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          children: [
            // 原始内容（隐藏在毛玻璃下）
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 根据是否为时段记录显示不同样式
                if (record.isPeriodRecord)
                  _buildPeriodRecordRow(record)
                else
                  _buildSingleActionRow(record),
                // 额外信息（移动距离和停留点）
                if (record.hasExtraInfo) ...[
                  const SizedBox(height: 12),
                  _buildExtraInfo(record),
                ],
              ],
            ),
            // 毛玻璃遮罩层
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 敏感记录专用文字
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 13, color: Colors.black),
                          children: [
                            const TextSpan(text: '对方'),
                            TextSpan(
                              text: '手机产生了一条敏感记录',
                              style: TextStyle(color: Color(0xFFB66CF2)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 会员可查看按钮
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '会员可查看',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFFF9500),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Image.asset(
                            'assets/phone_history/kissu3_vip_go.webp',
                            width: 6,
                            height: 6,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
      return Image.network(
        iconUrl,
        width: 16,
        height: 16,
        errorBuilder: (context, error, stackTrace) {
          // 网络图标加载失败，使用本地图标
          return _buildLocalIcon(action);
        },
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