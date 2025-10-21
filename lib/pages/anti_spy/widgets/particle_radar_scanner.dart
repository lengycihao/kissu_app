import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../anti_spy_controller.dart';

// 粒子信息
class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double life;
  final double maxLife;
  final Color color;
  
  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.maxLife,
    required this.color,
  }) : life = maxLife;
  
  void update() {
    x += vx;
    y += vy;
    life -= 0.02;
    
    // 添加一些随机性
    vx += (math.Random().nextDouble() - 0.5) * 0.1;
    vy += (math.Random().nextDouble() - 0.5) * 0.1;
  }
  
  bool get isDead => life <= 0;
  
  double get opacity => (life / maxLife).clamp(0.0, 1.0);
}

// 方案3: 粒子雷达 - 带粒子效果的扫描
class ParticleRadarScanner extends StatefulWidget {
  final double size;
  
  const ParticleRadarScanner({
    super.key,
    this.size = 200,
  });

  @override
  State<ParticleRadarScanner> createState() => _ParticleRadarScannerState();
}

class _ParticleRadarScannerState extends State<ParticleRadarScanner>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _particleController;
  late Animation<double> _rotationAnimation;
  
  final Map<String, DevicePoint> _devicePositions = {};
  final List<Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    
    // 旋转动画控制器
    _rotationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    // 粒子更新控制器
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    );
    
    _particleController.addListener(_updateParticles);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _particleController.dispose();
    super.dispose();
  }
  
  void _updateParticles() {
    if (!mounted) return; // 安全检查
    
    setState(() {
      // 更新现有粒子
      for (var particle in _particles) {
        particle.update();
      }
      
      // 移除死亡的粒子
      _particles.removeWhere((particle) => particle.isDead);
      
      // 🎯 添加新粒子（在动画运行时），不依赖controller状态
      // 只要动画控制器在运行，就生成粒子，让动画更流畅独立
      if (_rotationController.isAnimating && _particles.length < 50) {
        _addNewParticles();
      }
    });
  }
  
  void _addNewParticles() {
    final center = Offset(widget.size / 2, widget.size / 2);
    final maxRadius = widget.size / 2;
    
    // 根据扫描线位置生成粒子
    final scanAngle = _rotationAnimation.value * 2 * math.pi;
    
    for (int i = 0; i < 3; i++) {
      final radius = maxRadius * (0.3 + _random.nextDouble() * 0.6);
      final angle = scanAngle + (_random.nextDouble() - 0.5) * 0.5;
      
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      
      final particle = Particle(
        x: x,
        y: y,
        vx: (_random.nextDouble() - 0.5) * 2,
        vy: (_random.nextDouble() - 0.5) * 2,
        maxLife: 1.0 + _random.nextDouble(),
        color: const Color(0xFF4FACFE),
      );
      
      _particles.add(particle);
    }
  }

  // 生成随机设备点位置
  DevicePoint _generateRandomPosition() {
    final angle = _random.nextDouble() * 2 * math.pi;
    final minRadius = (widget.size / 2) * 0.25;
    final maxRadius = (widget.size / 2) * 0.85;
    final radius = minRadius + _random.nextDouble() * (maxRadius - minRadius);
    
    final x = radius * math.cos(angle);
    final y = radius * math.sin(angle);
    
    return DevicePoint(
      x: x,
      y: y,
      angle: angle,
      radius: radius,
    );
  }
  
  DevicePoint _getDevicePosition(String deviceId) {
    if (!_devicePositions.containsKey(deviceId)) {
      _devicePositions[deviceId] = _generateRandomPosition();
    }
    return _devicePositions[deviceId]!;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AntiSpyController>();
    
    return Obx(() {
      final state = controller.scanState.value;
      
      // 根据状态控制动画
      if (state == ScanState.scanning) {
        _rotationController.repeat();
        _particleController.repeat();
      } else {
        _rotationController.stop();
        _particleController.stop();
        _particles.clear();
      }
      
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 背景网格
            _buildBackgroundGrid(),
            
            // 粒子效果
            if (state == ScanState.scanning) _buildParticles(),
            
            // 扫描线
            if (state == ScanState.scanning) _buildScanLine(controller),
            
            // 设备点
            _buildDevicePoints(controller),
            
            // 中心图标
            _buildCenterIcon(controller),
          ],
        ),
      );
    });
  }
  
  Widget _buildBackgroundGrid() {
    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: ParticleRadarBackgroundPainter(),
    );
  }
  
  Widget _buildParticles() {
    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: ParticlesPainter(particles: _particles),
    );
  }
  
  Widget _buildScanLine(AntiSpyController controller) {
    // 🎯 使用RepaintBoundary隔离重绘区域
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value * 2 * math.pi,
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: ParticleScanLinePainter(
                color: _getRadarColor(controller.scanState.value),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildDevicePoints(AntiSpyController controller) {
    final currentDeviceIds = controller.discoveredDevices.map((d) => d.ip).toSet();
    _devicePositions.removeWhere((key, value) => !currentDeviceIds.contains(key));
    
    return Stack(
      alignment: Alignment.center,
      children: controller.discoveredDevices.map((device) {
        final isSuspicious = controller.suspiciousDevices.contains(device);
        final devicePosition = _getDevicePosition(device.ip);
        
        return Transform.translate(
          offset: Offset(devicePosition.x, devicePosition.y),
          child: AnimatedBuilder(
            animation: controller.pulseAnimation,
            builder: (context, child) {
              final baseSize = isSuspicious ? 12.0 : 10.0;
              final animatedSize = baseSize * (0.9 + 0.3 * controller.pulseAnimation.value);
              final deviceColor = isSuspicious ? 
                const Color(0xFFFF6B6B) : const Color(0xFF4FACFE);
              
              return Container(
                width: animatedSize,
                height: animatedSize,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      deviceColor,
                      deviceColor.withOpacity(0.6),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: deviceColor.withOpacity(0.6),
                      blurRadius: 15 * controller.pulseAnimation.value,
                      spreadRadius: 3 * controller.pulseAnimation.value,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: animatedSize * 0.3,
                    height: animatedSize * 0.3,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildCenterIcon(AntiSpyController controller) {
    final state = controller.scanState.value;
    
    // 初始状态和扫描中：显示能量核心
    if (state == ScanState.initial || state == ScanState.scanning) {
      return Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              _getRadarColor(state).withOpacity(0.2),
              _getRadarColor(state).withOpacity(0.05),
              Colors.transparent,
            ],
          ),
          shape: BoxShape.circle,
        ),
        child: Container(
          width: 60,
          height: 60,
          margin: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: _getRadarColor(state).withOpacity(0.5),
              width: 2,
            ),
          ),
        ),
      );
    }
    
    // 根据结果显示不同图标
    String? assetPath;
    if (state == ScanState.success) {
      assetPath = 'assets/3.0/kissu3_leida_success.webp';
    } else if (state == ScanState.suspicious) {
      assetPath = 'assets/3.0/kissu3_leida_warning.webp';
    }
    
    if (assetPath != null) {
      return SizedBox(
        width: 20,
        height: 20,
        child: Image.asset(
          assetPath,
          width: 20,
          height: 20,
          fit: BoxFit.fill,
        ),
      );
    }
    
    // 失败状态显示错误图标
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            _getRadarColor(state).withOpacity(0.3),
            _getRadarColor(state).withOpacity(0.1),
            Colors.transparent,
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Container(
        width: 80,
        height: 80,
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _getRadarColor(state).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.error_outline,
          size: 45,
          color: _getRadarColor(state),
        ),
      ),
    );
  }
  
  Color _getRadarColor(ScanState state) {
    switch (state) {
      case ScanState.initial:
        return const Color(0xFF5B9BD5);
      case ScanState.scanning:
        return const Color(0xFF4FACFE);
      case ScanState.success:
        return const Color(0xFF51CF66);
      case ScanState.suspicious:
        return const Color(0xFFFF6B6B);
      case ScanState.failed:
        return const Color(0xFFFFB347);
    }
  }
}

// 设备点位置信息
class DevicePoint {
  final double x;
  final double y;
  final double angle;
  final double radius;
  
  DevicePoint({
    required this.x,
    required this.y,
    required this.angle,
    required this.radius,
  });
}

class ParticleRadarBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    
    final paint = Paint()
      ..color = const Color(0xFF4FACFE).withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // 绘制同心圆
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, maxRadius * i / 4, paint);
    }
    
    // 绘制网格线
    paint.color = paint.color.withOpacity(0.06);
    for (int i = 0; i < 16; i++) {
      final angle = (i * 22.5) * math.pi / 180;
      final endX = center.dx + maxRadius * math.cos(angle);
      final endY = center.dy + maxRadius * math.sin(angle);
      canvas.drawLine(center, Offset(endX, endY), paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ParticlesPainter extends CustomPainter {
  final List<Particle> particles;
  
  ParticlesPainter({required this.particles});
  
  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        2.0 * particle.opacity,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // 粒子动画需要持续重绘
  }
}

class ParticleScanLinePainter extends CustomPainter {
  final Color color;
  
  ParticleScanLinePainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // 创建扫描线渐变
    final gradient = SweepGradient(
      center: Alignment.center,
      startAngle: 0,
      endAngle: math.pi / 3,
      colors: [
        Colors.transparent,
        color.withOpacity(0.2),
        color.withOpacity(0.8),
        color.withOpacity(0.4),
        Colors.transparent,
      ],
      stops: const [0.0, 0.3, 0.7, 0.9, 1.0],
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );
    
    // 绘制扇形扫描线
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi / 3,
      true,
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! ParticleScanLinePainter || oldDelegate.color != color;
  }
}

