import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import '../../../widgets/safe_amap_widget.dart';
import '../location_v2_controller.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';

/// 缓存的地图Widget - 避免不必要的重建
class CachedMapWidget extends StatefulWidget {
  final LocationV2Controller controller;

  const CachedMapWidget({
    super.key,
    required this.controller,
  });

  @override
  State<CachedMapWidget> createState() => _CachedMapWidgetState();
}

class _CachedMapWidgetState extends State<CachedMapWidget> {
  Set<Marker>? _cachedMarkers;
  Set<Polyline>? _cachedPolylines;
  int _lastMarkersLength = -1;
  int _lastPolylinesLength = -1;

  @override
  Widget build(BuildContext context) {
    // 使用GetBuilder替代Obx，实现精准更新（API文档推荐）
    // 只监听markers和polylines的变化，不监听其他状态
    return GetBuilder<LocationV2Controller>(
      id: LocationV2Controller.markersUpdateId,
      builder: (controller) {
        // 使用公共getter获取集合长度，避免频繁重建
        final markersLength = controller.markersLength;
        final polylinesLength = controller.polylinesLength;

        // 只有当标记或连接线数量发生变化时才重新构建
        if (_lastMarkersLength != markersLength ||
            _lastPolylinesLength != polylinesLength) {
          _cachedMarkers = controller.markers;
          _cachedPolylines = controller.polylines;
          _lastMarkersLength = markersLength;
          _lastPolylinesLength = polylinesLength;

          logDebug(
            '🗺️ 地图Widget重建 - 标记数量: ${markersLength}, 连接线数量: ${polylinesLength}',
            tag: 'CachedMapWidget',
          );
          if (_cachedMarkers != null && _cachedMarkers!.isNotEmpty) {
            logDebug(
              '🗺️ 标记详情: ${_cachedMarkers!.map((m) => '标记: ${m.position}').join(', ')}',
              tag: 'CachedMapWidget',
            );
          }
        }

        // mapType使用Obx单独监听，避免影响地图主体
        return Obx(() {
          final mapType = controller.mapType.value == 2
              ? MapType.satellite
              : MapType.normal;

          // 直接返回地图Widget，避免RepaintBoundary与硬件加速冲突
          return SafeAMapWidget(
            initialCameraPosition: controller.initialCameraPosition,
            onMapCreated: controller.onMapCreated,
            markers: _cachedMarkers ?? const {},
            polylines: _cachedPolylines ?? const {},
            compassEnabled: true,
            scaleEnabled: true,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            mapType: mapType,
            buildingsEnabled: false, // 隐藏3D建筑物提升性能
            // labelsEnabled: false, // 隐藏底图文字标注
          );
        });
      },
    );
  }
}
