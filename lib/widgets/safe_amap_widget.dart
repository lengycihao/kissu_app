import 'dart:async';
import 'package:flutter/material.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import '../utils/map_style_loader.dart';

/// 安全的高德地图包装器
/// 功能：
/// 1. 解决mapId不匹配导致的空值错误
/// 2. 解决Platform View渲染引擎不一致导致的花屏问题
/// 3. 优化地图初始化和渲染流程
/// 4. 支持自定义地图样式
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
  final bool buildingsEnabled;
  // final bool labelsEnabled;
  final void Function(LatLng)? onTap;
  final void Function(LatLng)? onLongPress;
  final void Function(AMapLocation)? onLocationChanged;
  final void Function(CameraPosition)? onCameraMove;
  final void Function(CameraPosition)? onCameraMoveEnd;
  final void Function(AMapPoi)? onPoiTouched;
  final VoidCallback? onInfoWindowClose;
  /// 是否启用自定义地图样式
  final bool enableCustomStyle;

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
    this.buildingsEnabled = true,
    // this.labelsEnabled = true,
    this.onTap,
    this.onLongPress,
    this.onLocationChanged,
    this.onCameraMove,
    this.onCameraMoveEnd,
    this.onPoiTouched,
    this.onInfoWindowClose,
    this.enableCustomStyle = true, // 默认启用自定义样式
  }) : super(key: key);

  @override
  State<SafeAMapWidget> createState() => _SafeAMapWidgetState();
}

class _SafeAMapWidgetState extends State<SafeAMapWidget> {
  bool _shouldRender = false;
  final Completer<void> _mapReadyCompleter = Completer<void>();
  CustomStyleOptions? _customStyleOptions;

  @override
  void initState() {
    super.initState();
    print('🗺️ SafeAMapWidget 初始化开始');
    
    // 加载自定义地图样式
    _loadCustomMapStyle();
    
    // 延迟渲染，等待Flutter渲染树稳定后再显示地图
    // 这可以避免初始化时Flutter渲染引擎与原生地图渲染引擎的冲突，减少花屏
    // 优化：减少延迟时间从50ms到16ms（一帧的时间）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 16), () {
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

  /// 加载自定义地图样式
  Future<void> _loadCustomMapStyle() async {
    if (!widget.enableCustomStyle) {
      print('🗺️ SafeAMapWidget 自定义样式已禁用');
      return;
    }

    try {
      _customStyleOptions = await MapStyleLoader.getCustomMapStyle();
      print('🗺️ SafeAMapWidget 自定义样式加载成功');
    } catch (e) {
      print('🗺️ SafeAMapWidget 自定义样式加载失败: $e');
      _customStyleOptions = null;
    }
  }

  @override
  void dispose() {
    print('🗺️ SafeAMapWidget 销毁');
    super.dispose();
  }

  void _onMapCreated(AMapController controller) async {
    print('🗺️ SafeAMapWidget 地图创建成功');
    
    // 立即完成地图就绪状态
    if (!_mapReadyCompleter.isCompleted) {
      _mapReadyCompleter.complete();
    }
    
    // 立即调用用户的回调，让页面可以开始加载数据
    widget.onMapCreated?.call(controller);
    
    print('🗺️ SafeAMapWidget 地图就绪完成');
    
    // 后台异步设置渲染帧率，不阻塞主流程
    Future.delayed(const Duration(milliseconds: 100)).then((_) async {
      if (mounted) {
        try {
          await controller.setRenderFps(30);
          print('🗺️ SafeAMapWidget 已设置渲染帧率: 30fps');
        } catch (e) {
          print('🗺️ SafeAMapWidget 设置帧率失败: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 如果尚未准备好渲染，显示占位符（只在第一帧显示，避免闪烁）
    // 这避免了在Flutter渲染树未稳定时创建Platform View，减少花屏
    if (!_shouldRender) {
      return Container(
        color: const Color(0xFFFFF6EF), // 与页面背景色一致
      );
    }
    
    // 地图就绪后直接显示，不显示loading遮罩
    // 数据将在后台静默加载并更新到地图上
    return RepaintBoundary(
      child: _buildAMapWidget(),
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
      customStyleOptions: _customStyleOptions, // 应用自定义地图样式
      compassEnabled: widget.compassEnabled,
      scaleEnabled: widget.scaleEnabled,
      zoomGesturesEnabled: widget.zoomGesturesEnabled,
      scrollGesturesEnabled: widget.scrollGesturesEnabled,
      rotateGesturesEnabled: widget.rotateGesturesEnabled,
      tiltGesturesEnabled: widget.tiltGesturesEnabled,
      mapType: widget.mapType,
      buildingsEnabled: widget.buildingsEnabled,
      // labelsEnabled: widget.labelsEnabled,
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
