import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../anti_spy_controller.dart';

// 方案2: 脉冲扫描雷达 - 脉冲式扫描线效果
class PulseRadarScanner extends StatefulWidget {
  final double size;
  
  const PulseRadarScanner({
    super.key,
    this.size = 280,
  });

  @override
  State<PulseRadarScanner> createState() => _PulseRadarScannerState();
}

class _PulseRadarScannerState extends State<PulseRadarScanner>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scanController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scanAnimation;
  
  final Map<String, DevicePoint> _devicePositions = {};
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    
    // 脉冲动画控制器
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    ));
    
    // 扫描动画控制器
    _scanController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );
    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanController,
      curve: Curves.linear,
    ));
    
    // 🎯 监听扫描状态变化，控制动画启停，避免在build中重复调用
    final controller = Get.find<AntiSpyController>();
    ever(controller.scanState, (state) {
      if (!mounted) return;
      if (state == ScanState.scanning) {
        if (!_pulseController.isAnimating) _pulseController.repeat();
        if (!_scanController.isAnimating) _scanController.repeat();
      } else {
        _pulseController.stop();
        _scanController.stop();
      }
    });
    
    // 初始状态检查
    if (controller.scanState.value == ScanState.scanning) {
      _pulseController.repeat();
      _scanController.repeat();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  // 生成随机设备点位置
  DevicePoint _generateRandomPosition() {
    final angle = _random.nextDouble() * 2 * math.pi;
    final minRadius = (widget.size / 2) * 0.2;
    final maxRadius = (widget.size / 2) * 0.9;
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
          // 背景圆圈 - 静态
          _buildBackgroundCircles(),
          
          // 脉冲扫描效果 - 🎯 使用Obx只监听状态变化来控制显示/隐藏
          Obx(() => controller.scanState.value == ScanState.scanning
              ? _buildPulseScan(controller)
              : const SizedBox.shrink()),
          
          // 设备点 - 🎯 使用Obx监听设备列表变化
          Obx(() => _buildDevicePoints(controller)),
          
          // 中心图标 - 🎯 使用Obx监听状态变化
          Obx(() => _buildCenterIcon(controller)),
        ],
      ),
    );
  }
  
  Widget _buildBackgroundCircles() {
    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: PulseRadarBackgroundPainter(),
    );
  }
  
  Widget _buildPulseScan(AntiSpyController controller) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 旋转扫描线 - 🎯 使用RepaintBoundary隔离重绘
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _scanAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _scanAnimation.value * 2 * math.pi,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: PulseScanLinePainter(
                    color: _getRadarColor(controller.scanState.value),
                  ),
                ),
              );
            },
          ),
        ),
        
        // 脉冲圆环 - 🎯 使用RepaintBoundary隔离重绘
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: PulseRingPainter(
                  progress: _pulseAnimation.value,
                  color: _getRadarColor(controller.scanState.value),
                ),
              );
            },
          ),
        ),
      ],
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
              final baseSize = isSuspicious ? 18.0 : 15.0;
              final animatedSize = baseSize * (0.8 + 0.4 * controller.pulseAnimation.value);
              final deviceColor = isSuspicious ? 
                const Color(0xFFE53E3E) : const Color(0xFF3182CE);
              
              return Container(
                width: animatedSize,
                height: animatedSize,
                decoration: BoxDecoration(
                  color: deviceColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: deviceColor.withOpacity(0.5),
                      blurRadius: 8 * controller.pulseAnimation.value,
                      spreadRadius: 2 * controller.pulseAnimation.value,
                    ),
                  ],
                ),
                child: isSuspicious 
                  ? Icon(
                      Icons.warning_rounded,
                      size: animatedSize * 0.7,
                      color: Colors.white,
                    )
                  : Icon(
                      Icons.circle,
                      size: animatedSize * 0.5,
                      color: Colors.white,
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
    
    // 初始状态和扫描中：显示脉冲圆圈
    if (state == ScanState.initial || state == ScanState.scanning) {
      return AnimatedBuilder(
        animation: state == ScanState.scanning ? _pulseController : const AlwaysStoppedAnimation(0.0),
        builder: (context, child) {
          final pulseValue = state == ScanState.scanning ? _pulseAnimation.value : 0.0;
          return Container(
            width: 80 + (20 * pulseValue),
            height: 80 + (20 * pulseValue),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: _getRadarColor(state).withOpacity(0.6 - 0.3 * pulseValue),
                width: 3 + pulseValue,
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
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _getRadarColor(state).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        Icons.error_outline,
        size: 40,
        color: _getRadarColor(state),
      ),
    );
  }
  
  Color _getRadarColor(ScanState state) {
    switch (state) {
      case ScanState.initial:
        return const Color(0xFF5B9BD5);
      case ScanState.scanning:
        return const Color(0xFF3182CE);
      case ScanState.success:
        return const Color(0xFF38A169);
      case ScanState.suspicious:
        return const Color(0xFFE53E3E);
      case ScanState.failed:
        return const Color(0xFFDD6B20);
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

class PulseRadarBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    
    final paint = Paint()
      ..color = const Color(0xFF3182CE).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // 绘制同心圆
    for (int i = 1; i <= 4; i++) {
      paint.strokeWidth = i == 4 ? 3 : 2;
      canvas.drawCircle(center, maxRadius * i / 4, paint);
    }
    
    // 绘制刻度线
    paint.strokeWidth = 1;
    paint.color = paint.color.withOpacity(0.2);
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * math.pi / 180;
      final startRadius = maxRadius * 0.9;
      final endRadius = maxRadius;
      final startX = center.dx + startRadius * math.cos(angle);
      final startY = center.dy + startRadius * math.sin(angle);
      final endX = center.dx + endRadius * math.cos(angle);
      final endY = center.dy + endRadius * math.sin(angle);
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PulseScanLinePainter extends CustomPainter {
  final Color color;
  
  PulseScanLinePainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // 创建扫描线渐变
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        color.withOpacity(0.9),
        color.withOpacity(0.6),
        color.withOpacity(0.3),
        color.withOpacity(0.1),
        Colors.transparent,
      ],
      stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );
    
    // 绘制扇形扫描线
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 6,
      math.pi / 3,
      true,
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! PulseScanLinePainter || oldDelegate.color != color;
  }
}

class PulseRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  
  PulseRingPainter({required this.progress, required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    
    // 绘制脉冲环
    for (int i = 0; i < 2; i++) {
      final ringProgress = (progress + i * 0.5) % 1.0;
      final currentRadius = maxRadius * ringProgress * 0.8;
      final opacity = (1.0 - ringProgress) * 0.4;
      
      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;
      
      canvas.drawCircle(center, currentRadius, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! PulseRingPainter || 
           oldDelegate.progress != progress ||
           oldDelegate.color != color;
  }
}

