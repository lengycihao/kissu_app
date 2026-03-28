import 'package:flutter/material.dart';

/// 提示字选择器（出题者收到提示请求后，选择答案中的一个字发送给猜题者）
class HintCharSelector extends StatelessWidget {
  final List<String> chars;
  final ValueChanged<int> onCharSelected;

  const HintCharSelector({
    super.key,
    required this.chars,
    required this.onCharSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 拆字显示
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(chars.length, (index) {
            return GestureDetector(
              onTap: () => onCharSelected(index),
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E0FF),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF8B5CF6),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    chars[index],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        const Text(
          '选择提示字给对方',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }
}
