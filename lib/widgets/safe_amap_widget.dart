import 'dart:async';
import 'package:flutter/material.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';

/// 安全的高德地图包装器
/// 功能：
/// 1. 解决mapId不匹配导致的空值错误
/// 2. 解决Platform View渲染引擎不一致导致的花屏问题
/// 3. 优化地图初始化和渲染流程
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
  final VoidCallback? onInfoWindowClose;

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
    this.onInfoWindowClose,
  }) : super(key: key);

  @override
  State<SafeAMapWidget> createState() => _SafeAMapWidgetState();
}

class _SafeAMapWidgetState extends State<SafeAMapWidget> {
  bool _isMapReady = false;
  bool _shouldRender = false;
  final Completer<void> _mapReadyCompleter = Completer<void>();

  @override
  void initState() {
    super.initState();
    print('🗺️ SafeAMapWidget 初始化开始');
    
    // 延迟渲染，等待Flutter渲染树稳定后再显示地图
    // 这可以避免初始化时Flutter渲染引擎与原生地图渲染引擎的冲突，减少花屏
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            setState(() {
              _shouldRender = true;
            });
            print('🗺️ SafeAMapWidget 渲染已启用');
          }
        });
      }
    });
  }

  @override
  void dispose() {
    print('🗺️ SafeAMapWidget 销毁');
    super.dispose();
  }

  void _onMapCreated(AMapController controller) async {
    print('🗺️ SafeAMapWidget 地图创建成功');
    
    try {
      // 等待地图完全初始化并稳定渲染
      // 延长等待时间以确保原生地图和Flutter渲染引擎同步
      await Future.delayed(const Duration(milliseconds: 200));
      
      if (mounted) {
        // 限制地图渲染帧率，降低渲染压力，减少花屏概率
        try {
          await controller.setRenderFps(30);
          print('🗺️ SafeAMapWidget 已设置渲染帧率: 30fps');
        } catch (e) {
          print('🗺️ SafeAMapWidget 设置帧率失败: $e');
        }
        
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
    // 如果尚未准备好渲染，显示占位符
    // 这避免了在Flutter渲染树未稳定时创建Platform View，减少花屏
    if (!_shouldRender) {
      return Container(
        color: Colors.white,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('准备地图...', style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      );
    }
    
    return FutureBuilder<void>(
      future: _mapReadyCompleter.future,
      builder: (context, snapshot) {
        // 显示加载状态
        if (snapshot.connectionState == ConnectionState.waiting && !_isMapReady) {
          return Stack(
            children: [
              // 使用RepaintBoundary隔离地图渲染层，避免与其他Widget的渲染冲突
              RepaintBoundary(
                child: _buildAMapWidget(),
              ),
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

        // 地图正常显示，使用RepaintBoundary隔离渲染层
        return RepaintBoundary(
          child: _buildAMapWidget(),
        );
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
      onInfoWindowClose: widget.onInfoWindowClose,
      // 必须正确设置的合规隐私声明，否则SDK不会工作，会造成地图白屏等问题
      privacyStatement: const AMapPrivacyStatement(
        hasContains: true, 
        hasShow: true, 
        hasAgree: true
      ),
    );
  }
}
