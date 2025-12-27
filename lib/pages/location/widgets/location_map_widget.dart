import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import '../../../widgets/safe_amap_widget.dart';
import '../location_v2_controller.dart';

/// 定位页面地图组件
/// 负责地图的显示和地图相关逻辑的管理
class LocationMapWidget extends StatefulWidget {
  final LocationV2Controller controller;

  const LocationMapWidget({
    super.key,
    required this.controller,
  });

  @override
  State<LocationMapWidget> createState() => _LocationMapWidgetState();
}

class _LocationMapWidgetState extends State<LocationMapWidget> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 🎯 修复：直接使用markers和polylines，但用RepaintBoundary优化性能
      // 连线位置已修复为使用actualMyLocation，与marker保持一致
      final markers = widget.controller.markers;
      final polylines = widget.controller.polylines;

      final mapType = widget.controller.mapType.value == 2
          ? MapType.satellite
          : MapType.normal;

      return RepaintBoundary(
        child: SafeAMapWidget(
          initialCameraPosition: widget.controller.initialCameraPosition,
          onMapCreated: widget.controller.onMapCreated,
          markers: markers,
          polylines: polylines,
          compassEnabled: true,
          scaleEnabled: true,
          zoomGesturesEnabled: true,
          scrollGesturesEnabled: true,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: true,
          mapType: mapType,
        ),
      );
    });
  }
}
