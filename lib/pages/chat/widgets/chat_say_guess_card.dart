import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import '../models/chat_message.dart';

/// 你说我猜邀请卡片消息组件
/// 卡片样式：粉色放射背景 + 可爱角色 + "你说我猜" + 邀请文案
class ChatSayGuessCard extends StatelessWidget {
  final ChatMessage message;

  const ChatSayGuessCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    // 自己发的邀请卡片不可点击，只有对方可以点击加入
    return GestureDetector(
      onTap: message.isSent ? null : () => _onCardTap(),
      child: Container(
        width: 230,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0f000000),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 上半部分：粉色放射背景 + 角色图 + "你说我猜"
            _buildTopArea(),
            // 分割线
            Container(height: 1, color: const Color(0xFFE8E8E8)),
            // 下半部分：邀请文案
            _buildBottomArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopArea() {
    return Container(
      height: 120,
      width: double.infinity,
      child: CustomPaint(
        painter: _RadialStripePainter(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 可爱角色（暂无切图，用图标+emoji代替）
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x20000000),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '🤔',
                  style: TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // "你说我猜" 标签
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '你说我猜',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF69B4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        message.isSent
            ? '已向对方发起你说我猜挑战，等待对方加入~'
            : '向你发起你说我猜挑战，快来提高我们的默契排名吧~点击加入',
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF666666),
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _onCardTap() {
    final groupId = message.groupId;
    if (groupId == null || groupId.isEmpty) return;

    // 邀请卡片点击 → 直接进入V2游戏页面（接收方）
    Get.toNamed(
      KissuRoutePath.guessGameV2Play,
      arguments: {
        'groupId': groupId,
        'isInitiator': false,
      },
    );
  }
}

/// 粉色放射条纹背景画笔
class _RadialStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = sqrt(size.width * size.width + size.height * size.height) / 2;

    // 背景底色
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFFFC0CB),
    );

    // 放射条纹
    const stripeCount = 16;
    final stripeAngle = 2 * pi / stripeCount;
    final stripePaint = Paint()
      ..color = const Color(0xFFFFD6E0)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < stripeCount; i += 2) {
      final startAngle = i * stripeAngle;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + maxRadius * cos(startAngle),
          center.dy + maxRadius * sin(startAngle),
        )
        ..lineTo(
          center.dx + maxRadius * cos(startAngle + stripeAngle),
          center.dy + maxRadius * sin(startAngle + stripeAngle),
        )
        ..close();
      canvas.drawPath(path, stripePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
