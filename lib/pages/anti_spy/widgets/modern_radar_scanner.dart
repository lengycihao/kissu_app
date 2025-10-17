import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../anti_spy_controller.dart';

// 方案1: 现代波纹雷达 - 多层波纹扩散效果
class ModernRadarScanner extends StatefulWidget {
  final double size;
  
  const ModernRadarScanner({
    super.key,
    this.size = 280,
  });

  @override
  State<ModernRadarScanner> createState() => _ModernRadarScannerState();
}

class _ModernRadarScannerState extends State<ModernRadarScanner>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _rotationController;
  late Animation<double> _waveAnimation;
  late Animation<double> _rotationAnimation;
  
  final Map<String, DevicePoint> _devicePositions = {};
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    
    // 波纹动画控制器
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeOut,
    ));
    
    // 旋转动画控制器
    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _waveController.dispose();
    _rotationController.dispose();
    super.dispose();
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
        _waveController.repeat();
        _rotationController.repeat();
      } else {
        _waveController.stop();
        _rotationController.stop();
      }
      
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 背景网格
            _buildBackgroundGrid(),
            
            // 波纹效果
            if (state == ScanState.scanning) _buildWaveEffect(controller),
            
            // 旋转扫描线
            if (state == ScanState.scanning) _buildRotatingScanLine(controller),
            
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
      painter: ModernRadarBackgroundPainter(),
    );
  }
  
  Widget _buildWaveEffect(AntiSpyController controller) {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: WaveEffectPainter(
            progress: _waveAnimation.value,
            color: _getRadarColor(controller.scanState.value),
          ),
        );
      },
    );
  }
  
  Widget _buildRotatingScanLine(AntiSpyController controller) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value * 2 * math.pi,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: ModernScanLinePainter(
              color: _getRadarColor(controller.scanState.value),
            ),
          ),
        );
      },
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
              final baseSize = isSuspicious ? 16.0 : 14.0;
              final animatedSize = baseSize * (0.7 + 0.5 * controller.pulseAnimation.value);
              final deviceColor = isSuspicious ? 
                const Color(0xFFFF4444) : const Color(0xFF4A9EFF);
              
              return Container(
                width: animatedSize,
                height: animatedSize,
                decoration: BoxDecoration(
                  color: deviceColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: deviceColor.withOpacity(0.6),
                      blurRadius: 12 * controller.pulseAnimation.value,
                      spreadRadius: 4 * controller.pulseAnimation.value,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: animatedSize * 0.6,
                    height: animatedSize * 0.6,
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
    
    // 初始状态和扫描中：不显示图标，只显示空圆圈
    if (state == ScanState.initial || state == ScanState.scanning) {
      return Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(
            color: _getRadarColor(state).withOpacity(0.4),
            width: 3,
          ),
        ),
        child: Container(
          width: 70,
          height: 70,
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: _getRadarColor(state).withOpacity(0.6),
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
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _getRadarColor(state).withOpacity(0.3),
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
    );
  }
  
  Color _getRadarColor(ScanState state) {
    switch (state) {
      case ScanState.initial:
        return const Color(0xFF5B9BD5);
      case ScanState.scanning:
        return const Color(0xFF4A9EFF);
      case ScanState.success:
        return const Color(0xFF4CAF50);
      case ScanState.suspicious:
        return const Color(0xFFFF4444);
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

class ModernRadarBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    
    final paint = Paint()
      ..color = const Color(0xFF4A9EFF).withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // 绘制同心圆
    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(center, maxRadius * i / 5, paint);
    }
    
    // 绘制放射线
    paint.strokeWidth = 1;
    paint.color = paint.color.withOpacity(0.08);
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180;
      final endX = center.dx + maxRadius * math.cos(angle);
      final endY = center.dy + maxRadius * math.sin(angle);
      canvas.drawLine(center, Offset(endX, endY), paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WaveEffectPainter extends CustomPainter {
  final double progress;
  final Color color;
  
  WaveEffectPainter({required this.progress, required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    
    // 绘制多层波纹
    for (int i = 0; i < 3; i++) {
      final waveProgress = (progress + i * 0.3) % 1.0;
      final currentRadius = maxRadius * waveProgress;
      final opacity = (1.0 - waveProgress) * 0.3;
      
      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      
      canvas.drawCircle(center, currentRadius, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! WaveEffectPainter || 
           oldDelegate.progress != progress ||
           oldDelegate.color != color;
  }
}

class ModernScanLinePainter extends CustomPainter {
  final Color color;
  
  ModernScanLinePainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // 创建更现代的渐变扫描线
    final gradient = SweepGradient(
      center: Alignment.center,
      startAngle: 0,
      endAngle: math.pi / 2,
      colors: [
        Colors.transparent,
        color.withOpacity(0.1),
        color.withOpacity(0.5),
        color.withOpacity(0.8),
        color.withOpacity(0.3),
        Colors.transparent,
      ],
      stops: const [0.0, 0.2, 0.6, 0.8, 0.9, 1.0],
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );
    
    // 绘制扇形
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi / 2,
      true,
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! ModernScanLinePainter || oldDelegate.color != color;
  }
}

