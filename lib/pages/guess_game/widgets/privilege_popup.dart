import 'package:flutter/material.dart';

/// 特权弹窗（贴着按钮的tip抽屉）
class PrivilegePopup extends StatelessWidget {
  final VoidCallback onAddTime;
  final VoidCallback onSkip;
  final VoidCallback onDismiss;
  final int remainingCount;

  const PrivilegePopup({
    super.key,
    required this.onAddTime,
    required this.onSkip,
    required this.onDismiss,
    required this.remainingCount,
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
            padding: const EdgeInsets.only(left: 16, bottom: 80),
            child: GestureDetector(
              onTap: () {}, // 阻止穿透
              child: Container(
                width: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 标题
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF0F5),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      width: double.infinity,
                      child: Text(
                        '使用特权（剩余${remainingCount}次）',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ),
                    // +30秒
                    InkWell(
                      onTap: remainingCount > 0 ? onAddTime : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Row(
                          children: [
                            const Icon(Icons.timer, size: 18, color: Color(0xFFFF90CA)),
                            const SizedBox(width: 8),
                            Text(
                              '+30秒',
                              style: TextStyle(
                                fontSize: 14,
                                color: remainingCount > 0
                                    ? const Color(0xFF333333)
                                    : const Color(0xFFCCCCCC),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    // 跳过这道题
                    InkWell(
                      onTap: remainingCount > 0 ? onSkip : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Row(
                          children: [
                            const Icon(Icons.skip_next, size: 18, color: Color(0xFFFF90CA)),
                            const SizedBox(width: 8),
                            Text(
                              '跳过这道题',
                              style: TextStyle(
                                fontSize: 14,
                                color: remainingCount > 0
                                    ? const Color(0xFF333333)
                                    : const Color(0xFFCCCCCC),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
