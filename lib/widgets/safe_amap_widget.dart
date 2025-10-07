import 'dart:async';
import 'package:flutter/material.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';

/// 安全的高德地图包装器，解决mapId不匹配导致的空值错误
class SafeAMapWidget extends StatefulWidget {
  final CameraPosition initialCameraPosition;
  final void Function(AMapController)? onMapCreated;
  final Set<Marker>? markers;
  final Set<Polyline>? polylines;
  final Set<Polygon>? polygons;
  final Set<Circle>? circles;
  final MyLocationStyleOptions? myLocationStyleOptions;
  final bool compassEnabled;
  final bool scaleEnabled;
  final bool zoomGesturesEnabled;
  final bool scrollGesturesEnabled;
  final bool rotateGesturesEnabled;
  final bool tiltGesturesEnabled;
  final MapType mapType;
  final void Function(LatLng)? onTap;
  final void Function(LatLng)? onLongPress;
  final void Function(AMapLocation)? onLocationChanged;
  final void Function(CameraPosition)? onCameraMove;
  final void Function(CameraPosition)? onCameraMoveEnd;
  final void Function(AMapPoi)? onPoiTouched;

  const SafeAMapWidget({
    Key? key,
    required this.initialCameraPosition,
    this.onMapCreated,
    this.markers,
    this.polylines,
    this.polygons,
    this.circles,
    this.myLocationStyleOptions,
    this.compassEnabled = false,
    this.scaleEnabled = false,
    this.zoomGesturesEnabled = true,
    this.scrollGesturesEnabled = true,
    this.rotateGesturesEnabled = true,
    this.tiltGesturesEnabled = true,
    this.mapType = MapType.normal,
    this.onTap,
    this.onLongPress,
    this.onLocationChanged,
    this.onCameraMove,
    this.onCameraMoveEnd,
    this.onPoiTouched,
  }) : super(key: key);

  @override
  State<SafeAMapWidget> createState() => _SafeAMapWidgetState();
}

class _SafeAMapWidgetState extends State<SafeAMapWidget> {
  bool _isMapReady = false;
  final Completer<void> _mapReadyCompleter = Completer<void>();

  @override
  void initState() {
    super.initState();
    print('🗺️ SafeAMapWidget 初始化开始');
  }

  @override
  void dispose() {
    print('🗺️ SafeAMapWidget 销毁');
    super.dispose();
  }

  void _onMapCreated(AMapController controller) async {
    print('🗺️ SafeAMapWidget 地图创建成功');
    
    try {
      // 等待一小段时间确保地图完全初始化
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (mounted) {
        setState(() {
          _isMapReady = true;
        });
        
        if (!_mapReadyCompleter.isCompleted) {
          _mapReadyCompleter.complete();
        }
        
        // 调用用户的回调
        widget.onMapCreated?.call(controller);
        
        print('🗺️ SafeAMapWidget 地图就绪完成');
      }
    } catch (e) {
      print('🗺️ SafeAMapWidget 地图创建错误: $e');
      if (!_mapReadyCompleter.isCompleted) {
        _mapReadyCompleter.completeError(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _mapReadyCompleter.future,
      builder: (context, snapshot) {
        // 显示加载状态
        if (snapshot.connectionState == ConnectionState.waiting && !_isMapReady) {
          return Stack(
            children: [
              // 先创建地图
              _buildAMapWidget(),
              // 显示加载遮罩
              Container(
                color: Colors.grey.withOpacity(0.1),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('地图加载中...', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        // 地图加载错误
        if (snapshot.hasError) {
          return Container(
            color: Colors.grey[100],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('地图加载失败: ${snapshot.error}', 
                       style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        // 重新加载
                      });
                    },
                    child: const Text('重新加载'),
                  ),
                ],
              ),
            ),
          );
        }

        // 地图正常显示
        return _buildAMapWidget();
      },
    );
  }

  Widget _buildAMapWidget() {
    return AMapWidget(
      initialCameraPosition: widget.initialCameraPosition,
      onMapCreated: _onMapCreated,
      markers: widget.markers ?? <Marker>{},
      polylines: widget.polylines ?? <Polyline>{},
      polygons: widget.polygons ?? <Polygon>{},
      circles: widget.circles ?? <Circle>{},
      myLocationStyleOptions: widget.myLocationStyleOptions,
      compassEnabled: widget.compassEnabled,
      scaleEnabled: widget.scaleEnabled,
      zoomGesturesEnabled: widget.zoomGesturesEnabled,
      scrollGesturesEnabled: widget.scrollGesturesEnabled,
      rotateGesturesEnabled: widget.rotateGesturesEnabled,
      tiltGesturesEnabled: widget.tiltGesturesEnabled,
      mapType: widget.mapType,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onLocationChanged: widget.onLocationChanged,
      onCameraMove: widget.onCameraMove,
      onCameraMoveEnd: widget.onCameraMoveEnd,
      onPoiTouched: widget.onPoiTouched,
      // 必须正确设置的合规隐私声明，否则SDK不会工作，会造成地图白屏等问题
      privacyStatement: const AMapPrivacyStatement(
        hasContains: true, 
        hasShow: true, 
        hasAgree: true
      ),
    );
  }
}
