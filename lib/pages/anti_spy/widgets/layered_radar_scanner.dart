import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../anti_spy_controller.dart';
import 'radar_animation_layer.dart';
import 'device_points_layer.dart';

/// 🎯 分层雷达扫描器 - 性能优化版
/// 
/// 架构设计：
/// 1. 底层：RadarAnimationLayer - 纯动画层，独立运行，不受数据影响
/// 2. 顶层：DevicePointsLayer - 透明蒙版层，只在设备数据变化时更新
/// 
/// 优势：
/// - 雷达动画永远不会因为设备列表变化而重建
/// - 设备点更新不会影响雷达动画的流畅度
/// - 各层独立渲染，使用RepaintBoundary优化性能
class LayeredRadarScanner extends StatelessWidget {
  final double size;
  final RadarStyle style;
  
  const LayeredRadarScanner({
    super.key,
    this.size = 280,
    this.style = RadarStyle.classic,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AntiSpyController>();
    
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 🎯 底层：雷达动画层 - 只监听扫描状态，持续旋转
          Obx(() => RadarAnimationLayer(
            size: size,
            style: style,
            isScanning: controller.scanState.value == ScanState.scanning,
          )),
          
          // 🎯 顶层：设备点蒙版层 - 只监听设备列表和状态变化
          Obx(() => DevicePointsLayer(
            size: size,
            devices: controller.discoveredDevices,
            scanState: controller.scanState.value,
          )),
        ],
      ),
    );
  }
}

