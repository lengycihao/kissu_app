import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/mine/device_usage/device_usage_controller.dart';

/// 首页「Ta的手机使用记录」卡片
/// 只负责 UI，点击行为由外部通过 [onTap] 控制。
class DevicePhoneUsageCard extends StatelessWidget {
  const DevicePhoneUsageCard({
    super.key,
    required this.controller,
    required this.onTap,
  });

  final DeviceUsageController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 模块标题
                  _ModuleTitle(title: 'Ta的手机使用记录'),
                  const SizedBox(height: 12),
                  // 圆环图和统计数据
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 左侧圆环模块
                        Expanded(
                          flex: 174,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F9F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Obx(() {
                                // 已绑定但未开会员时显示星号
                                if (controller.isUserBound.value &&
                                    !controller.isUserVip.value) {
                                  return const _CircularProgressWithStars();
                                }
                                return _CircularProgress(
                                  hours: controller.screenUsageHours.value,
                                  minutes: controller.screenUsageMinutes.value,
                                  progress:
                                      controller.getCircularProgress(),
                                );
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // 右侧统计数据
                        Expanded(
                          flex: 131,
                          child: Column(
                            children: [
                              // 解锁次数
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9F9F9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  child: Obx(() {
                                    final value =
                                        (controller.isUserBound.value &&
                                                !controller.isUserVip.value)
                                            ? '*'
                                            : '${controller.unlockCount.value}';
                                    return _StatItem(
                                      iconPath:
                                          'assets/4.0/kissu4_new_use_times_pic.webp',
                                      label: '解锁手机次数',
                                      value: value,
                                      unit: '次',
                                    );
                                  }),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // 最近使用时长
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9F9F9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  child: Obx(() {
                                    final value =
                                        (controller.isUserBound.value &&
                                                !controller.isUserVip.value)
                                            ? '*'
                                            : '${controller.recentUsageMinutes.value}';
                                    return _StatItem(
                                      iconPath:
                                          'assets/4.0/kissu4_new_use_time_pic.webp',
                                      label: '最近使用时长',
                                      value: value,
                                      unit: '分钟',
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 毛玻璃蒙版（未绑定或已绑定未开会员时显示）
            Obx(() {
              final isBound = controller.isUserBound.value;
              final isVip = controller.isUserVip.value;
              if (!isBound || (isBound && !isVip)) {
                return Positioned(
                  top: 40,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _FrostedGlassMask(
                    text: '实时查看Ta的手机使用报告',
                    isVipButton: isBound && !isVip,
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }
}

class _ModuleTitle extends StatelessWidget {
  const _ModuleTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Image.asset(
              'assets/4.0/kissu4_new_use_label_bg.webp',
              height: 15,
              width: 140,
              fit: BoxFit.fitWidth,
            ),
            SizedBox(
              height: 20,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'AlimamaShuHeiTi',
                      color: Color(0xFF333333),
                    ),
                  ),
                  Image.asset(
                    'assets/4.0/kissu4_app_use_tip.webp',
                    width: 13,
                    height: 17,
                  ),
                ],
              ),
            ),
          ],
        ),
        const Spacer(),
        Image.asset(
          'assets/4.0/kissu4_next_go.webp',
          width: 16,
          height: 16,
        ),
      ],
    );
  }
}

class _CircularProgress extends StatelessWidget {
  const _CircularProgress({
    required this.hours,
    required this.minutes,
    required this.progress,
  });

  final int hours;
  final int minutes;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: const Size(92, 92),
          painter: DashedCirclePainter(
            color: const Color(0xFFFFE2F4),
            strokeWidth: 2,
          ),
        ),
        SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(
            painter: GradientCircularProgressPainter(
              progress: progress,
              strokeWidth: 9,
              backgroundColor: const Color(0xFFFFE2F4),
              gradientColors: const [Color(0xFFFFA4DC), Color(0xFFFFA0DB)],
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$hours',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const Text(
                  '小时',
                  style: TextStyle(fontSize: 11, color: Color(0xcc333333)),
                ),
                Text(
                  '$minutes',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const Text(
                  '分',
                  style: TextStyle(fontSize: 11, color: Color(0xcc333333)),
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              '屏幕使用时长',
              style: TextStyle(fontSize: 11, color: Color(0xcc333333)),
            ),
          ],
        ),
      ],
    );
  }
}

class _CircularProgressWithStars extends StatelessWidget {
  const _CircularProgressWithStars();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: const Size(92, 92),
          painter: DashedCirclePainter(
            color: const Color(0xFFFFE2F4),
            strokeWidth: 2,
          ),
        ),
        SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(
            painter: GradientCircularProgressPainter(
              progress: 0,
              strokeWidth: 9,
              backgroundColor: const Color(0xFFFFE2F4),
              gradientColors: const [Color(0xFFFFA4DC), Color(0xFFFFA0DB)],
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '*',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                Text(
                  '小时',
                  style: TextStyle(fontSize: 11, color: Color(0xcc333333)),
                ),
                Text(
                  '*',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                Text(
                  '分',
                  style: TextStyle(fontSize: 11, color: Color(0xcc333333)),
                ),
              ],
            ),
            SizedBox(height: 2),
            Text(
              '屏幕使用时长',
              style: TextStyle(fontSize: 11, color: Color(0xcc333333)),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.iconPath,
    required this.label,
    required this.value,
    required this.unit,
  });

  final String iconPath;
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Image.asset(iconPath, width: 16, height: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xcc333333),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Image.asset(
              'assets/4.0/kissu4_new_use_right.webp',
              width: 6,
              height: 6,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            Text(
              unit,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 毛玻璃蒙版（未绑定时显示）
class _FrostedGlassMask extends StatelessWidget {
  const _FrostedGlassMask({
    required this.text,
    required this.isVipButton,
  });

  final String text;
  final bool isVipButton;

  @override
  Widget build(BuildContext context) {
    // 这里只复用样式，不处理点击；实际点击逻辑在 page 中已有全局处理
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFFFFFFF).withOpacity(0.2),
                const Color(0xFFFDE4FF).withOpacity(0.8),
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Image.asset(
                          'assets/images/kissu4_vip_hat.webp',
                          width: 16,
                          height: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Stack(
                        children: [
                          Positioned(
                            bottom: 2,
                            right: 0,
                            child: Image.asset(
                              'assets/images/kissu4_vip_line.webp',
                              width: 68,
                              height: 12,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Text(
                            text,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Image.asset(
                    isVipButton
                        ? 'assets/images/kissu3_go_vip.webp'
                        : 'assets/images/kissu3_go_bind.webp',
                    width: isVipButton ? 179 : 176,
                    height:isVipButton?60: 44,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 虚线圆环绘制器（复制自 DeviceUsagePage，保持视觉一致）
class DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedCirclePainter({
    required this.color,
    this.strokeWidth = 2,
    this.dashWidth = 6,
    this.dashSpace = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    double startAngle = -math.pi / 2;
    final totalDashSpace = dashWidth + dashSpace;
    final circumference = 2 * math.pi * radius;
    final dashCount = (circumference / totalDashSpace).floor();

    for (int i = 0; i < dashCount; i++) {
      final sweepAngle = dashWidth / radius;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += totalDashSpace / radius;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 渐变圆形进度条绘制器（带白色终点圆）
class GradientCircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final List<Color> gradientColors;

  GradientCircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    if (progress <= 0) return;

    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + 2 * math.pi * progress,
      colors: gradientColors,
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );

    final endAngle = -math.pi / 2 + 2 * math.pi * progress;
    final endOffset = Offset(
      center.dx + radius * math.cos(endAngle),
      center.dy + radius * math.sin(endAngle),
    );

    final endCirclePaint = Paint()..color = Colors.white;
    canvas.drawCircle(endOffset, strokeWidth / 2.2, endCirclePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


