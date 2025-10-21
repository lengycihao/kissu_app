import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../anti_spy_controller.dart';

// 方案4: 发光环雷达 - 多层发光环效果
class GlowRadarScanner extends StatefulWidget {
  final double size;
  
  const GlowRadarScanner({
    super.key,
    this.size = 280,
  });

  @override
  State<GlowRadarScanner> createState() => _GlowRadarScannerState();
}

class _GlowRadarScannerState extends State<GlowRadarScanner>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _rotationController;
  late AnimationController _breatheController;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _breatheAnimation;
  
  final Map<String, DevicePoint> _devicePositions = {};
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    
    // 发光动画控制器
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    // 旋转动画控制器
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    // 呼吸动画控制器
    _breatheController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _breatheAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _breatheController,
      curve: Curves.easeInOut,
    ));
    
    // 🎯 监听扫描状态变化，控制动画启停，避免在build中重复调用
    final controller = Get.find<AntiSpyController>();
    ever(controller.scanState, (state) {
      if (!mounted) return;
      if (state == ScanState.scanning) {
        if (!_glowController.isAnimating) _glowController.repeat(reverse: true);
        if (!_rotationController.isAnimating) _rotationController.repeat();
        if (!_breatheController.isAnimating) _breatheController.repeat(reverse: true);
      } else {
        _glowController.stop();
        _rotationController.stop();
        _breatheController.stop();
      }
    });
    
    // 初始状态检查
    if (controller.scanState.value == ScanState.scanning) {
      _glowController.repeat(reverse: true);
      _rotationController.repeat();
      _breatheController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _rotationController.dispose();
    _breatheController.dispose();
    super.dispose();
  }

  // 生成随机设备点位置
  DevicePoint _generateRandomPosition() {
    final angle = _random.nextDouble() * 2 * math.pi;
    final minRadius = (widget.size / 2) * 0.3;
    final maxRadius = (widget.size / 2) * 0.8;
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
    
    // 🎯 不再使用Obx包裹整个Widget树，避免不必要的重建导致动画卡顿
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 背景光环 - 🎯 使用Obx监听状态变化
          Obx(() => _buildBackgroundGlow(controller)),
          
          // 发光圆环 - 🎯 使用Obx只监听状态变化来控制显示/隐藏
          Obx(() => controller.scanState.value == ScanState.scanning
              ? _buildGlowRings(controller)
              : const SizedBox.shrink()),
          
          // 旋转扫描光束 - 🎯 使用Obx只监听状态变化来控制显示/隐藏
          Obx(() => controller.scanState.value == ScanState.scanning
              ? _buildGlowScanBeam(controller)
              : const SizedBox.shrink()),
          
          // 设备点 - 🎯 使用Obx监听设备列表变化
          Obx(() => _buildDevicePoints(controller)),
          
          // 中心图标 - 🎯 使用Obx监听状态变化
          Obx(() => _buildCenterIcon(controller)),
        ],
      ),
    );
  }
  
  Widget _buildBackgroundGlow(AntiSpyController controller) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            _getRadarColor(controller.scanState.value).withOpacity(0.05),
            _getRadarColor(controller.scanState.value).withOpacity(0.02),
            Colors.transparent,
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
        shape: BoxShape.circle,
      ),
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: GlowRadarBackgroundPainter(
          color: _getRadarColor(controller.scanState.value),
        ),
      ),
    );
  }
  
  Widget _buildGlowRings(AntiSpyController controller) {
    // 🎯 使用RepaintBoundary隔离重绘区域
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: GlowRingsPainter(
              progress: _glowAnimation.value,
              color: _getRadarColor(controller.scanState.value),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildGlowScanBeam(AntiSpyController controller) {
    // 🎯 使用RepaintBoundary隔离重绘区域
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value * 2 * math.pi,
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: GlowScanBeamPainter(
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
              final baseSize = isSuspicious ? 22.0 : 18.0;
              final animatedSize = baseSize * (0.9 + 0.3 * controller.pulseAnimation.value);
              final deviceColor = isSuspicious ? 
                const Color(0xFFFF5722) : const Color(0xFF03DAC6);
              
              return Container(
                width: animatedSize + 10,
                height: animatedSize + 10,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      deviceColor.withOpacity(0.3),
                      deviceColor.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: animatedSize,
                    height: animatedSize,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.white,
                          deviceColor,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: deviceColor.withOpacity(0.8),
                          blurRadius: 20 * controller.pulseAnimation.value,
                          spreadRadius: 5 * controller.pulseAnimation.value,
                        ),
                      ],
                    ),
                    child: isSuspicious 
                      ? Icon(
                          Icons.warning_rounded,
                          size: animatedSize * 0.6,
                          color: Colors.white,
                        )
                      : null,
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
    
    // 初始状态和扫描中：显示发光核心
    if (state == ScanState.initial || state == ScanState.scanning) {
      return AnimatedBuilder(
        animation: state == ScanState.scanning ? _breatheAnimation : const AlwaysStoppedAnimation(0.5),
        builder: (context, child) {
          final breatheValue = state == ScanState.scanning ? _breatheAnimation.value : 0.5;
          final glowIntensity = 0.3 + 0.4 * breatheValue;
          
          return Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  _getRadarColor(state).withOpacity(glowIntensity),
                  _getRadarColor(state).withOpacity(glowIntensity * 0.5),
                  _getRadarColor(state).withOpacity(glowIntensity * 0.2),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.4, 0.7, 1.0],
              ),
              shape: BoxShape.circle,
            ),
            child: Container(
              width: 70,
              height: 70,
              margin: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getRadarColor(state).withOpacity(0.8),
                  width: 2 + breatheValue,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getRadarColor(state).withOpacity(0.6),
                    blurRadius: 20 * breatheValue,
                    spreadRadius: 5 * breatheValue,
                  ),
                ],
              ),
            ),
          );
        },
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
        width: 24,
        height: 24,
        child: Image.asset(
          assetPath,
          width: 24,
          height: 24,
          fit: BoxFit.cover,
        ),
      );
    }
    
    // 失败状态显示错误图标
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            _getRadarColor(state).withOpacity(0.4),
            _getRadarColor(state).withOpacity(0.2),
            _getRadarColor(state).withOpacity(0.1),
            Colors.transparent,
          ],
          stops: const [0.0, 0.4, 0.7, 1.0],
        ),
        shape: BoxShape.circle,
      ),
      child: Container(
        width: 85,
        height: 85,
        margin: const EdgeInsets.all(7.5),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _getRadarColor(state).withOpacity(0.5),
              blurRadius: 25,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          Icons.error_outline,
          size: 50,
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
        return const Color(0xFF03DAC6);
      case ScanState.success:
        return const Color(0xFF4CAF50);
      case ScanState.suspicious:
        return const Color(0xFFFF5722);
      case ScanState.failed:
        return const Color(0xFFFF9800);
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

class GlowRadarBackgroundPainter extends CustomPainter {
  final Color color;
  
  GlowRadarBackgroundPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    
    final paint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // 绘制发光同心圆
    for (int i = 1; i <= 5; i++) {
      final radius = maxRadius * i / 5;
      paint.strokeWidth = i == 5 ? 3 : 2;
      
      // 添加发光效果
      paint.shader = null;
      paint.color = color.withOpacity(0.08);
      paint.strokeWidth = (i == 5 ? 3 : 2) + 4;
      canvas.drawCircle(center, radius, paint);
      
      paint.color = color.withOpacity(0.15);
      paint.strokeWidth = i == 5 ? 3 : 2;
      canvas.drawCircle(center, radius, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! GlowRadarBackgroundPainter || 
           oldDelegate.color != color;
  }
}

class GlowRingsPainter extends CustomPainter {
  final double progress;
  final Color color;
  
  GlowRingsPainter({required this.progress, required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    
    // 绘制多层发光环
    for (int i = 0; i < 3; i++) {
      final ringProgress = (progress + i * 0.33) % 1.0;
      final currentRadius = maxRadius * (0.2 + ringProgress * 0.7);
      final opacity = (1.0 - ringProgress) * 0.6;
      
      final paint = Paint()
        ..color = color.withOpacity(opacity * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0;
      
      // 外层发光
      canvas.drawCircle(center, currentRadius, paint);
      
      // 内层亮光
      paint.color = color.withOpacity(opacity);
      paint.strokeWidth = 3.0;
      canvas.drawCircle(center, currentRadius, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! GlowRingsPainter || 
           oldDelegate.progress != progress ||
           oldDelegate.color != color;
  }
}

class GlowScanBeamPainter extends CustomPainter {
  final Color color;
  
  GlowScanBeamPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // 创建发光扫描光束
    final gradient = SweepGradient(
      center: Alignment.center,
      startAngle: -math.pi / 8,
      endAngle: math.pi / 8,
      colors: [
        Colors.transparent,
        color.withOpacity(0.1),
        color.withOpacity(0.4),
        color.withOpacity(0.8),
        color.withOpacity(0.4),
        color.withOpacity(0.1),
        Colors.transparent,
      ],
      stops: const [0.0, 0.1, 0.3, 0.5, 0.7, 0.9, 1.0],
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );
    
    // 绘制扇形光束
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 8,
      math.pi / 4,
      true,
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! GlowScanBeamPainter || oldDelegate.color != color;
  }
}

