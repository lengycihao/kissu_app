import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../anti_spy_controller.dart';

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

class RadarScanner extends StatefulWidget {
  final double size;
  
  const RadarScanner({
    super.key,
    this.size = 280,
  });

  @override
  State<RadarScanner> createState() => _RadarScannerState();
}

class _RadarScannerState extends State<RadarScanner> {
  final Map<String, DevicePoint> _devicePositions = {};
  final math.Random _random = math.Random();
  
  // 生成随机设备点位置
  DevicePoint _generateRandomPosition() {
    // 生成随机角度 (0 到 2π)
    final angle = _random.nextDouble() * 2 * math.pi;
    // 生成随机半径 (30% 到 80% 的雷达半径)
    final minRadius = (widget.size / 2) * 0.3;
    final maxRadius = (widget.size / 2) * 0.8;
    final radius = minRadius + _random.nextDouble() * (maxRadius - minRadius);
    
    // 计算笛卡尔坐标
    final x = radius * math.cos(angle);
    final y = radius * math.sin(angle);
    
    return DevicePoint(
      x: x,
      y: y,
      angle: angle,
      radius: radius,
    );
  }
  
  // 获取或生成设备位置
  DevicePoint _getDevicePosition(String deviceId) {
    if (!_devicePositions.containsKey(deviceId)) {
      _devicePositions[deviceId] = _generateRandomPosition();
    }
    return _devicePositions[deviceId]!;
  }
  
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AntiSpyController>();
    
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 🎯 背景圆圈 - 静态，不需要重建
          _buildBackgroundCircles(),
          
          // 🎯 扫描雷达线 - 直接使用AnimatedBuilder，避免Obx导致的重建卡顿
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: controller.radarAnimation,
              builder: (context, child) {
                // 🎯 使用Obx单独监听颜色变化，不影响动画连续性
                return Obx(() {
                  final radarColor = _getRadarColor(controller.scanState.value);
                  return Transform.rotate(
                    angle: controller.radarAnimation.value * 2 * math.pi,
                    child: CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: RadarLinePainter(
                        color: radarColor,
                      ),
                    ),
                  );
                });
              },
            ),
          ),
          
          // 🎯 扫描到的设备点 - 只在设备列表变化时重建
          Obx(() => _buildDevicePoints(controller)),
          
          // 🎯 中心图标 - 只在状态变化时重建
          Obx(() => _buildCenterIcon(controller)),
        ],
      ),
    );
  }
  
  Widget _buildBackgroundCircles() {
    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: RadarBackgroundPainter(),
    );
  }
  
  Widget _buildDevicePoints(AntiSpyController controller) {
    // 清理不存在的设备位置
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
              final baseSize = isSuspicious ? 14.0 : 12.0;
              final animatedSize = baseSize * (0.8 + 0.4 * controller.pulseAnimation.value);
              final deviceColor = isSuspicious ? Colors.red : Colors.blue;
              
              return Container(
                width: animatedSize,
                height: animatedSize,
                decoration: BoxDecoration(
                  color: deviceColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: deviceColor.withOpacity(0.6 * controller.pulseAnimation.value),
                      blurRadius: 10 * controller.pulseAnimation.value,
                      spreadRadius: 3 * controller.pulseAnimation.value,
                    ),
                  ],
                ),
                child: isSuspicious 
                  ? Icon(
                      Icons.warning,
                      size: animatedSize * 0.6,
                      color: Colors.white,
                    )
                  : null,
              );
            },
          ),
        );
      }).toList(),
    );
  }
  
  // 构建中心图标
  Widget _buildCenterIcon(AntiSpyController controller) {
    final state = controller.scanState.value;
    
    // 初始状态和扫描中：不显示图标，只显示空圆圈
    if (state == ScanState.initial || state == ScanState.scanning) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: _getRadarColor(state).withOpacity(0.3),
            width: 2,
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
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        Icons.error,
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
        return const Color(0xFF5B9BD5);
      case ScanState.success:
        return const Color(0xFF70AD47);
      case ScanState.suspicious:
        return const Color(0xFFE74C3C);
      case ScanState.failed:
        return const Color(0xFFF39C12);
    }
  }
}

class RadarBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    
    final paint = Paint()
      ..color = const Color(0xFF5B9BD5).withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // 绘制同心圆
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, maxRadius * i / 4, paint);
    }
    
    // 绘制十字线
    paint.color = paint.color.withOpacity(0.3);
    // 水平线
    canvas.drawLine(
      Offset(0, center.dy), 
      Offset(size.width, center.dy), 
      paint,
    );
    // 垂直线
    canvas.drawLine(
      Offset(center.dx, 0), 
      Offset(center.dx, size.height), 
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RadarLinePainter extends CustomPainter {
  final Color color;
  
  RadarLinePainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // 创建渐变效果
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        color.withOpacity(0.8),
        color.withOpacity(0.4),
        color.withOpacity(0.1),
        Colors.transparent,
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );
    
    // 绘制扇形（45度扇形）
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 8, // 起始角度
      math.pi / 4,  // 扇形角度
      true,
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! RadarLinePainter || oldDelegate.color != color;
  }
}
