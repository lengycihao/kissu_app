import 'package:flutter/material.dart';

/// 电视机造型的题目显示区域
/// UI参考：粉色边框电视机，倒计时在TV面板内顶部，提示词在倒计时下方
class TvDisplayWidget extends StatelessWidget {
  final String displayText;      // 显示内容（倒计时数字/答案/开始游戏）
  final bool isCountdown;        // 是否为倒计时模式（3-2-1）
  final int? questionIndex;      // 当前题号 (0-4)
  final int? totalQuestions;     // 总题数
  final int? timer;              // 剩余秒数（显示在TV面板内顶部）
  final String? hintChar;        // 提示词（显示在倒计时下方）
  final bool isCustomInput;      // 是否为自定义答案输入模式
  final VoidCallback? onRandomTap; // 随机生成按钮回调
  final List<int>? questionStatuses; // 每题状态: 0=pending, 1=correct, 2=wrong/timeout, 3=skipped

  const TvDisplayWidget({
    super.key,
    required this.displayText,
    this.isCountdown = false,
    this.questionIndex,
    this.totalQuestions,
    this.timer,
    this.hintChar,
    this.isCustomInput = false,
    this.onRandomTap,
    this.questionStatuses,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 进度显示
        if (questionIndex != null && totalQuestions != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '本轮进度  ${questionIndex! + 1}/$totalQuestions',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                // 分段彩色进度条
                _buildSegmentedProgressBar(),
              ],
            ),
          ),

        // 电视机造型
        Stack(
          clipBehavior: Clip.none,
          children: [
            // 电视机主体
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 160),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFFB6C1),
                  width: 3,
                ),
              ),
              child: _buildTvContent(),
            ),

            // 电视天线（左侧斜线 + 右侧斜线）
            Positioned(
              top: -24,
              left: MediaQuery.of(context).size.width * 0.25,
              child: Transform.rotate(
                angle: -0.4,
                child: Container(
                  width: 3,
                  height: 30,
                  color: const Color(0xFFFFB6C1),
                ),
              ),
            ),
            Positioned(
              top: -24,
              left: MediaQuery.of(context).size.width * 0.25 + 20,
              child: Transform.rotate(
                angle: 0.4,
                child: Container(
                  width: 3,
                  height: 30,
                  color: const Color(0xFFFFB6C1),
                ),
              ),
            ),

            // 右上角小熊装饰
            Positioned(
              top: -18,
              right: 16,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF0F5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pets,
                  size: 18,
                  color: Color(0xFFFF90CA),
                ),
              ),
            ),

            // 右侧装饰按钮（旋钮+小圆点）
            Positioned(
              right: -14,
              top: 40,
              child: Column(
                children: [
                  // 大旋钮
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD4E5),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFFB6C1), width: 2),
                    ),
                    child: const Center(
                      child: Icon(Icons.radio_button_checked, size: 12, color: Color(0xFFFF90CA)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 小圆点
                  _buildTvDot(const Color(0xFFFF90CA)),
                  const SizedBox(height: 6),
                  _buildTvDot(const Color(0xFFFFD4E5)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// TV面板内容
  Widget _buildTvContent() {
    // 倒计时模式（3-2-1）
    if (isCountdown) {
      return Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            displayText,
            key: ValueKey(displayText),
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
        ),
      );
    }

    // 自定义答案输入模式
    if (isCustomInput) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.edit, size: 20, color: Color(0xFF999999)),
          const SizedBox(height: 8),
          const Text(
            '自定义答案',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          if (onRandomTap != null)
            GestureDetector(
              onTap: onRandomTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shuffle, size: 14, color: Color(0xFF999999)),
                    SizedBox(width: 4),
                    Text(
                      '随机生成',
                      style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    // 正常游戏模式：倒计时 + 提示词 + 答案/???
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 倒计时（TV面板内顶部）
        if (timer != null)
          Text(
            '${timer}秒',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: timer! <= 10
                  ? const Color(0xFFFF4444)
                  : const Color(0xFFFF90CA),
            ),
          ),
        if (timer != null) const SizedBox(height: 8),

        // 提示词（倒计时下方）
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '提示词：',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF333333).withValues(alpha: 0.6),
              ),
            ),
            if (hintChar != null)
              Text(
                hintChar!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B5CF6),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // 分隔椭圆装饰
        Container(
          width: 80,
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFFE8E0FF).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 8),

        // 主显示内容（答案/???）
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            displayText,
            key: ValueKey(displayText),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
        ),
      ],
    );
  }

  /// 分段彩色进度条：每段对应一道题，不同状态不同颜色
  Widget _buildSegmentedProgressBar() {
    final total = totalQuestions ?? 5;
    final current = questionIndex ?? 0;

    // 每段颜色
    const segmentColors = [
      Color(0xFFFF90CA), // 题1 - 粉色
      Color(0xFF8B5CF6), // 题2 - 紫色
      Color(0xFF3B82F6), // 题3 - 蓝色
      Color(0xFFF59E0B), // 题4 - 黄色
      Color(0xFF10B981), // 题5 - 绿色
    ];

    return Row(
      children: List.generate(total, (i) {
        final isActive = i <= current;
        // 状态颜色：pending=灰色, 已完成按各自颜色
        Color color;
        if (questionStatuses != null && i < questionStatuses!.length) {
          switch (questionStatuses![i]) {
            case 1: // correct
              color = const Color(0xFF4CAF50);
              break;
            case 2: // wrong/timeout
              color = const Color(0xFFFF4444);
              break;
            case 3: // skipped
              color = const Color(0xFFFF9800);
              break;
            default: // pending
              color = isActive
                  ? (i < segmentColors.length ? segmentColors[i] : const Color(0xFFFF90CA))
                  : const Color(0xFFE0E0E0);
          }
        } else {
          color = isActive
              ? (i < segmentColors.length ? segmentColors[i] : const Color(0xFFFF90CA))
              : const Color(0xFFE0E0E0);
        }

        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(right: i < total - 1 ? 3 : 0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTvDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
