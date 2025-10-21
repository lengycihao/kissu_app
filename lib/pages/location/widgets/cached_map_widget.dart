import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import '../../../widgets/safe_amap_widget.dart';
import '../location_v2_controller.dart';

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
    return Obx(() {
      // 使用公共getter获取集合长度，避免频繁重建
      final markersLength = widget.controller.markersLength;
      final polylinesLength = widget.controller.polylinesLength;

      // 只有当标记或连接线数量发生变化时才重新构建
      if (_lastMarkersLength != markersLength ||
          _lastPolylinesLength != polylinesLength) {
        _cachedMarkers = widget.controller.markers;
        _cachedPolylines = widget.controller.polylines;
        _lastMarkersLength = markersLength;
        _lastPolylinesLength = polylinesLength;

        print(
          '🗺️ 地图Widget重建 - 标记数量: ${markersLength}, 连接线数量: ${polylinesLength}',
        );
        if (_cachedMarkers != null && _cachedMarkers!.isNotEmpty) {
          print(
            '🗺️ 标记详情: ${_cachedMarkers!.map((m) => '标记: ${m.position}').join(', ')}',
          );
        }
      }

      // 根据控制器的mapType值转换为AMap的MapType
      final mapType = widget.controller.mapType.value == 2
          ? MapType.satellite
          : MapType.normal;

      return RepaintBoundary(
        child: SafeAMapWidget(
          initialCameraPosition: widget.controller.initialCameraPosition,
          onMapCreated: widget.controller.onMapCreated,
          markers: _cachedMarkers ?? {},
          polylines: _cachedPolylines ?? {},
          compassEnabled: true,
          scaleEnabled: true,
          zoomGesturesEnabled: true,
          scrollGesturesEnabled: true,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: true,
          mapType: mapType,
          buildingsEnabled: false, // 隐藏3D建筑物
          // labelsEnabled: false, // 隐藏底图文字标注
        ),
      );
    });
  }
}
