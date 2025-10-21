import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../anti_spy_controller.dart';

/// 🎯 设备点蒙版层 - 透明叠加层，只在检测到设备时更新
/// 完全独立于雷达动画，只负责绘制设备点和中心图标
class DevicePointsLayer extends StatefulWidget {
  final double size;
  final List<DeviceInfo> devices;
  final ScanState scanState;
  
  const DevicePointsLayer({
    super.key,
    required this.size,
    required this.devices,
    required this.scanState,
  });

  @override
  State<DevicePointsLayer> createState() => _DevicePointsLayerState();
}

class _DevicePointsLayerState extends State<DevicePointsLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _breatheController;
  late Animation<double> _breatheAnimation;
  
  final Map<String, DevicePoint> _devicePositions = {};
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    
    // 呼吸动画控制器（用于设备点呼吸效果）
    _breatheController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _breatheAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _breatheController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _breatheController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DevicePointsLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 🎯 只有当设备列表真正变化时才触发重建
    if (oldWidget.devices.length != widget.devices.length ||
        !_devicesEqual(oldWidget.devices, widget.devices)) {
      setState(() {
        // 清理已消失的设备
        _cleanupOldDevices();
      });
    }
  }

  bool _devicesEqual(List<DeviceInfo> list1, List<DeviceInfo> list2) {
    if (list1.length != list2.length) return false;
    final ips1 = list1.map((d) => d.ip).toSet();
    final ips2 = list2.map((d) => d.ip).toSet();
    return ips1.difference(ips2).isEmpty && ips2.difference(ips1).isEmpty;
  }

  void _cleanupOldDevices() {
    final currentIps = widget.devices.map((d) => d.ip).toSet();
    _devicePositions.removeWhere((ip, _) => !currentIps.contains(ip));
  }

  // 生成随机设备点位置（只在设备首次出现时调用一次）
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
  
  DevicePoint _getDevicePosition(String deviceIp) {
    if (!_devicePositions.containsKey(deviceIp)) {
      _devicePositions[deviceIp] = _generateRandomPosition();
    }
    return _devicePositions[deviceIp]!;
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 透明蒙版，叠加在雷达动画层之上
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 设备点（使用AnimatedBuilder实现呼吸效果）
            if (widget.devices.isNotEmpty)
              AnimatedBuilder(
                animation: _breatheAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: DevicePointsPainter(
                      devices: widget.devices,
                      getDevicePosition: _getDevicePosition,
                      breatheScale: _breatheAnimation.value,
                    ),
                  );
                },
              ),
            
            // 中心图标
            _buildCenterIcon(),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterIcon() {
    IconData iconData;
    Color iconColor;
    
    switch (widget.scanState) {
      case ScanState.initial:
        iconData = Icons.shield_outlined;
        iconColor = Colors.grey;
        break;
      case ScanState.scanning:
        iconData = Icons.radar;
        iconColor = const Color(0xFF00D9FF);
        break;
      case ScanState.suspicious:
        iconData = Icons.warning_amber_rounded;
        iconColor = Colors.orange;
        break;
      case ScanState.success:
        iconData = Icons.verified_user;
        iconColor = Colors.green;
        break;
      case ScanState.failed:
        iconData = Icons.error_outline;
        iconColor = Colors.red;
        break;
    }
    
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
        border: Border.all(
          color: iconColor.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 28,
      ),
    );
  }
}

/// 设备点绘制器
class DevicePointsPainter extends CustomPainter {
  final List<DeviceInfo> devices;
  final DevicePoint Function(String) getDevicePosition;
  final double breatheScale;
  
  DevicePointsPainter({
    required this.devices,
    required this.getDevicePosition,
    required this.breatheScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    for (final device in devices) {
      final position = getDevicePosition(device.ip);
      final devicePoint = Offset(
        center.dx + position.x,
        center.dy + position.y,
      );
      
      _drawDevicePoint(canvas, devicePoint, device);
    }
  }

  void _drawDevicePoint(Canvas canvas, Offset point, DeviceInfo device) {
    final color = _getDeviceColor(device.type);
    final baseRadius = 6.0;
    final animatedRadius = baseRadius * breatheScale;
    
    // 外圈光晕
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3 * breatheScale)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(point, animatedRadius * 2, glowPaint);
    
    // 设备点
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(point, animatedRadius, pointPaint);
    
    // 内圈高光
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.8);
    canvas.drawCircle(point, animatedRadius * 0.4, highlightPaint);
  }

  Color _getDeviceColor(DeviceType type) {
    switch (type) {
      case DeviceType.camera:
        return const Color(0xFFFF4757); // 红色 - 摄像头
      case DeviceType.phone:
        return const Color(0xFF00D9FF); // 青色 - 手机
      case DeviceType.tablet:
        return const Color(0xFF1E90FF); // 蓝色 - 平板
      case DeviceType.laptop:
      case DeviceType.desktop:
      case DeviceType.computer:
        return const Color(0xFF5F9EA0); // 青灰 - 电脑
      case DeviceType.router:
        return const Color(0xFFFF6348); // 橙红色 - 路由器
      case DeviceType.printer:
        return const Color(0xFF9370DB); // 紫色 - 打印机
      case DeviceType.tv:
        return const Color(0xFF20B2AA); // 浅海蓝 - 电视
      case DeviceType.speaker:
        return const Color(0xFFFFAB00); // 橙色 - 音箱
      case DeviceType.iot:
        return const Color(0xFF32CD32); // 绿色 - 物联网
      case DeviceType.server:
        return const Color(0xFFDC143C); // 深红 - 服务器
      case DeviceType.unknown:
        return const Color(0xFFCCCCCC); // 灰色 - 未知
    }
  }

  @override
  bool shouldRepaint(DevicePointsPainter oldDelegate) {
    return breatheScale != oldDelegate.breatheScale ||
           devices.length != oldDelegate.devices.length;
  }
}

/// 设备点位置数据类
class DevicePoint {
  final double x;
  final double y;
  final double angle;
  final double radius;
  
  const DevicePoint({
    required this.x,
    required this.y,
    required this.angle,
    required this.radius,
  });
}

