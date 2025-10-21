import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 🎯 纯动画雷达层 - 完全独立，不依赖任何业务数据
/// 只负责绘制雷达的扫描动画效果，永远不会因为数据变化而重建
class RadarAnimationLayer extends StatefulWidget {
  final double size;
  final RadarStyle style;
  final bool isScanning; // 控制动画启停
  
  const RadarAnimationLayer({
    super.key,
    required this.size,
    required this.style,
    required this.isScanning,
  });

  @override
  State<RadarAnimationLayer> createState() => _RadarAnimationLayerState();
}

class _RadarAnimationLayerState extends State<RadarAnimationLayer>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _updateAnimationState();
  }

  void _initAnimations() {
    // 旋转动画（用于扫描线和粒子旋转）
    _rotationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );
    
    // 脉冲动画（用于脉冲波纹效果）
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    
    // 发光动画（用于光晕呼吸效果）
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(RadarAnimationLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isScanning != widget.isScanning) {
      _updateAnimationState();
    }
  }

  void _updateAnimationState() {
    if (widget.isScanning) {
      _startAnimations();
    } else {
      _stopAnimations();
    }
  }

  void _startAnimations() {
    if (!_rotationController.isAnimating) {
      _rotationController.repeat();
    }
    if (!_pulseController.isAnimating && widget.style == RadarStyle.pulse) {
      _pulseController.repeat();
    }
    if (!_glowController.isAnimating && widget.style == RadarStyle.glow) {
      _glowController.repeat(reverse: true);
    }
  }

  void _stopAnimations() {
    _rotationController.stop();
    _pulseController.stop();
    _glowController.stop();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 使用RepaintBoundary隔离重绘区域
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: _buildRadarByStyle(),
      ),
    );
  }

  Widget _buildRadarByStyle() {
    switch (widget.style) {
      case RadarStyle.classic:
        return _buildClassicRadar();
      case RadarStyle.pulse:
        return _buildPulseRadar();
      case RadarStyle.glow:
        return _buildGlowRadar();
      case RadarStyle.particle:
        return _buildParticleRadar();
    }
  }

  // 方案1: 经典雷达扫描线
  Widget _buildClassicRadar() {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: ClassicRadarPainter(
            rotation: _rotationAnimation.value,
          ),
        );
      },
    );
  }

  // 方案2: 脉冲扫描雷达
  Widget _buildPulseRadar() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _rotationAnimation]),
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: PulseRadarPainter(
            pulse: _pulseAnimation.value,
            rotation: _rotationAnimation.value,
          ),
        );
      },
    );
  }

  // 方案3: 发光扫描雷达
  Widget _buildGlowRadar() {
    return AnimatedBuilder(
      animation: Listenable.merge([_glowAnimation, _rotationAnimation]),
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: GlowRadarPainter(
            glow: _glowAnimation.value,
            rotation: _rotationAnimation.value,
          ),
        );
      },
    );
  }

  // 方案4: 粒子流动雷达
  Widget _buildParticleRadar() {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: ParticleRadarPainter(
            rotation: _rotationAnimation.value,
          ),
        );
      },
    );
  }
}

/// 雷达样式枚举
enum RadarStyle {
  classic,  // 经典扫描线
  pulse,    // 脉冲波纹
  glow,     // 发光光束
  particle, // 粒子流动
}

// ============== 以下是各种雷达的纯绘制类 ==============

/// 经典雷达绘制器
class ClassicRadarPainter extends CustomPainter {
  final double rotation;
  
  ClassicRadarPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 绘制背景圆圈
    _drawBackgroundCircles(canvas, center, radius);
    
    // 绘制扫描线
    _drawScanLine(canvas, center, radius);
  }

  void _drawBackgroundCircles(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = const Color(0xFF00D9FF).withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 绘制多个同心圆
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * i / 3, paint);
    }
    
    // 绘制十字线
    paint.strokeWidth = 0.5;
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      paint,
    );
  }

  void _drawScanLine(Canvas canvas, Offset center, double radius) {
    final angle = rotation * 2 * math.pi;
    
    // 扫描线渐变
    final gradient = SweepGradient(
      startAngle: angle,
      endAngle: angle + math.pi / 2,
      colors: [
        const Color(0xFF00D9FF).withOpacity(0.8),
        const Color(0xFF00D9FF).withOpacity(0.0),
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(radius, 0)
      ..arcTo(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        0,
        math.pi / 2,
        false,
      )
      ..close();
    
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(ClassicRadarPainter oldDelegate) {
    return rotation != oldDelegate.rotation;
  }
}

/// 脉冲雷达绘制器
class PulseRadarPainter extends CustomPainter {
  final double pulse;
  final double rotation;
  
  PulseRadarPainter({required this.pulse, required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 绘制背景
    _drawBackgroundCircles(canvas, center, radius);
    
    // 绘制脉冲波纹
    _drawPulseWaves(canvas, center, radius);
    
    // 绘制扫描线
    _drawScanLine(canvas, center, radius);
  }

  void _drawBackgroundCircles(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = const Color(0xFF00D9FF).withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * i / 3, paint);
    }
  }

  void _drawPulseWaves(Canvas canvas, Offset center, double radius) {
    for (int i = 0; i < 3; i++) {
      final waveProgress = (pulse + i * 0.33) % 1.0;
      final waveRadius = radius * waveProgress;
      final opacity = (1.0 - waveProgress) * 0.5;
      
      final paint = Paint()
        ..color = const Color(0xFF00D9FF).withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      
      canvas.drawCircle(center, waveRadius, paint);
    }
  }

  void _drawScanLine(Canvas canvas, Offset center, double radius) {
    final angle = rotation * 2 * math.pi;
    final endX = center.dx + radius * math.cos(angle);
    final endY = center.dy + radius * math.sin(angle);
    
    final paint = Paint()
      ..color = const Color(0xFF00D9FF).withOpacity(0.6)
      ..strokeWidth = 2.0;
    
    canvas.drawLine(center, Offset(endX, endY), paint);
  }

  @override
  bool shouldRepaint(PulseRadarPainter oldDelegate) {
    return pulse != oldDelegate.pulse || rotation != oldDelegate.rotation;
  }
}

/// 发光雷达绘制器
class GlowRadarPainter extends CustomPainter {
  final double glow;
  final double rotation;
  
  GlowRadarPainter({required this.glow, required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 绘制背景光环
    _drawGlowRings(canvas, center, radius);
    
    // 绘制旋转光束
    _drawGlowBeam(canvas, center, radius);
  }

  void _drawGlowRings(Canvas canvas, Offset center, double radius) {
    for (int i = 1; i <= 3; i++) {
      final ringRadius = radius * i / 3;
      final glowOpacity = 0.1 + glow * 0.2;
      
      final paint = Paint()
        ..color = const Color(0xFF00D9FF).withOpacity(glowOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      
      canvas.drawCircle(center, ringRadius, paint);
    }
  }

  void _drawGlowBeam(Canvas canvas, Offset center, double radius) {
    final angle = rotation * 2 * math.pi;
    
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    
    final gradient = RadialGradient(
      colors: [
        const Color(0xFF00D9FF).withOpacity(0.6),
        const Color(0xFF00D9FF).withOpacity(0.0),
      ],
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, -20, radius, 40),
      );
    
    canvas.drawRect(Rect.fromLTWH(0, -20, radius, 40), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(GlowRadarPainter oldDelegate) {
    return glow != oldDelegate.glow || rotation != oldDelegate.rotation;
  }
}

/// 粒子雷达绘制器
class ParticleRadarPainter extends CustomPainter {
  final double rotation;
  
  ParticleRadarPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 绘制背景圆圈
    _drawBackgroundCircles(canvas, center, radius);
    
    // 绘制流动粒子
    _drawParticles(canvas, center, radius);
  }

  void _drawBackgroundCircles(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = const Color(0xFF00D9FF).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * i / 3, paint);
    }
  }

  void _drawParticles(Canvas canvas, Offset center, double radius) {
    final random = math.Random(rotation.hashCode);
    final particleCount = 20;
    
    for (int i = 0; i < particleCount; i++) {
      final angle = (rotation + i / particleCount) * 2 * math.pi;
      final distance = radius * (0.3 + random.nextDouble() * 0.6);
      
      final x = center.dx + distance * math.cos(angle);
      final y = center.dy + distance * math.sin(angle);
      
      final opacity = 0.3 + random.nextDouble() * 0.5;
      final particleRadius = 2.0 + random.nextDouble() * 2.0;
      
      final paint = Paint()
        ..color = const Color(0xFF00D9FF).withOpacity(opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      
      canvas.drawCircle(Offset(x, y), particleRadius, paint);
    }
  }

  @override
  bool shouldRepaint(ParticleRadarPainter oldDelegate) {
    return rotation != oldDelegate.rotation;
  }
}

