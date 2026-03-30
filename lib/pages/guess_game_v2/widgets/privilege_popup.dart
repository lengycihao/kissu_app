import 'package:flutter/material.dart';

/// 特权弹窗V2：答题次数+1 / 跳过这道题（气泡样式，在按钮上方浮动）
class PrivilegePopupV2 extends StatelessWidget {
  final int remainingCount;
  final VoidCallback onExtraAttempt;
  final VoidCallback onSkip;
  final VoidCallback onDismiss;

  const PrivilegePopupV2({
    super.key,
    required this.remainingCount,
    required this.onExtraAttempt,
    required this.onSkip,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 120, left: 30),
            child: GestureDetector(
              onTap: () {}, // 阻止穿透
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 气泡容器
                  Container(
                    width: 80,
                    // padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF000000),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildOption(
                          label: '答题次数+1',
                          onTap: remainingCount > 0 ? onExtraAttempt : null,
                        ),
                         Container(
                          margin: EdgeInsets.symmetric(horizontal: 15),
                          height: 1,
                          color: const Color(0xFFe1e1e1),
                        ),
                         _buildOption(
                          label: '跳过这道题',
                          onTap: remainingCount > 0 ? onSkip : null,
                        ),
                      ],
                    ),
                  ),
                  // 向下的小三角
                  CustomPaint(
                    size: const Size(20, 8),
                    painter: _TrianglePainter(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required String label,
    VoidCallback? onTap,
  }) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
             color: disabled ? const Color(0xFFCCCCCC) : const Color(0xFF333333),
          ),
        ),
      ),
    );
  }
}

/// 绘制向下的小三角
class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2 - 10, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width / 2 + 10, 0)
      ..close();

    canvas.drawPath(path, paint);

    // 绘制边框
    final borderPaint = Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final borderPath = Path()
      ..moveTo(size.width / 2 - 10, 0)
      ..lineTo(size.width / 2, size.height);

    final borderPath2 = Path()
      ..moveTo(size.width / 2 + 10, 0)
      ..lineTo(size.width / 2, size.height);

    canvas.drawPath(borderPath, borderPaint);
    canvas.drawPath(borderPath2, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
