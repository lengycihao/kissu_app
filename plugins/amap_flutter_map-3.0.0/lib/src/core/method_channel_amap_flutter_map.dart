import 'dart:async';
import 'dart:typed_data';

import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/src/core/amap_flutter_platform.dart';
import 'package:amap_flutter_map/src/types/types.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:stream_transform/stream_transform.dart';

import 'map_event.dart';

const VIEW_TYPE = 'com.amap.flutter.map';

/// 使用[MethodChannel]与Native代码通信的[AMapFlutterPlatform]的实现。
class MethodChannelAMapFlutterMap implements AMapFlutterPlatform {
  final Map<int, MethodChannel> _channels = {};

  MethodChannel channel(int mapId) {
    final channel = _channels[mapId];
    if (channel == null) {
      throw StateError('地图Channel未初始化，mapId: $mapId');
    }
    return channel;
  }

  @override
  Future<void> init(int mapId) {
    MethodChannel? channel = _channels[mapId];
    if (channel == null) {
      channel = MethodChannel('amap_flutter_map_$mapId');
      channel.setMethodCallHandler((call) => _handleMethodCall(call, mapId));
      _channels[mapId] = channel;
    }
    return channel.invokeMethod<void>('map#waitForMap');
  }

  ///更新地图参数
  Future<void> updateMapOptions(
    Map<String, dynamic> newOptions, {
    required int mapId,
  }) {
    return channel(mapId).invokeMethod<void>(
      'map#update',
      <String, dynamic>{
        'options': newOptions,
      },
    );
  }

  /// 更新Marker的数据
  Future<void> updateMarkers(
    MarkerUpdates markerUpdates, {
    required int mapId,
  }) {
    return channel(mapId).invokeMethod<void>(
      'markers#update',
      markerUpdates.toMap(),
    );
  }

  /// 更新polyline的数据
  Future<void> updatePolylines(
    PolylineUpdates polylineUpdates, {
    required int mapId,
  }) {
    return channel(mapId).invokeMethod<void>(
      'polylines#update',
      polylineUpdates.toMap(),
    );
  }

  /// 更新polygon的数据
  Future<void> updatePolygons(
    PolygonUpdates polygonUpdates, {
    required int mapId,
  }) {
    return channel(mapId).invokeMethod<void>(
      'polygons#update',
      polygonUpdates.toMap(),
    );
  }

  /// 更新circle的数据
  Future<void> updateCircles(
    CircleUpdates circleUpdates, {
    required int mapId,
  }) {
    return channel(mapId).invokeMethod<void>(
      'circles#update',
      circleUpdates.toMap(),
    );
  }

  /// 更新单个标记
  Future<void> updateMarker(
    Marker marker, {
    required int mapId,
  }) {
    return channel(mapId).invokeMethod<void>(
      'marker#update',
      marker.toMap(),
    );
  }

  /// 启动Marker呼吸动画（iOS原版实现）
  Future<bool> startMarkerBreathAnimation({
    required int mapId,
    required String markerId,
    int duration = 400,
  }) async {
    try {
      final result = await channel(mapId).invokeMethod<bool>(
        'marker#startBreathAnimation',
        {
          'markerId': markerId,
          'duration': duration,
        },
      );
      return result ?? false;
    } catch (e) {
      debugPrint('启动Marker呼吸动画失败: $e');
      return false;
    }
  }

  /// 停止Marker呼吸动画
  Future<bool> stopMarkerBreathAnimation({
    required int mapId,
    required String markerId,
  }) async {
    try {
      final result = await channel(mapId).invokeMethod<bool>(
        'marker#stopBreathAnimation',
        {
          'markerId': markerId,
        },
      );
      return result ?? false;
    } catch (e) {
      debugPrint('停止Marker呼吸动画失败: $e');
      return false;
    }
  }

  /// 启动Marker波纹动画（扩散+透明度渐变）
  /// 
  /// 🌊 波纹效果：
  /// - 从 1.0 扩大到 1.5倍
  /// - 透明度从 0.6 渐变到 0.0
  /// - 循环播放，产生持续扩散效果
  /// - 在原生层执行，60fps流畅运行
  /// 
  /// [markerId] Marker的ID（必须是已存在的Marker）
  /// [duration] 动画周期（毫秒，默认2000ms）
  Future<bool> startMarkerRippleAnimation({
    required int mapId,
    required String markerId,
    int duration = 2000,
  }) async {
    try {
      final result = await channel(mapId).invokeMethod<bool>(
        'marker#startRippleAnimation',
        {
          'markerId': markerId,
          'duration': duration,
        },
      );
      return result ?? false;
    } catch (e) {
      debugPrint('启动Marker波纹动画失败: $e');
      return false;
    }
  }

  /// 停止Marker波纹动画
  Future<bool> stopMarkerRippleAnimation({
    required int mapId,
    required String markerId,
  }) async {
    try {
      final result = await channel(mapId).invokeMethod<bool>(
        'marker#stopRippleAnimation',
        {
          'markerId': markerId,
        },
      );
      return result ?? false;
    } catch (e) {
      debugPrint('停止Marker波纹动画失败: $e');
      return false;
    }
  }

  /// 🎯 平滑移动Marker到目标位置（原生动画）
  /// 
  /// 使用高德地图原生平滑移动API，实现60fps流畅移动
  /// 
  /// [mapId] 地图ID
  /// [markerId] Marker的ID（必须是已存在的Marker）
  /// [targetPosition] 目标位置
  /// [duration] 动画时长（毫秒）
  /// [rotation] 可选的旋转角度（度数）
  Future<bool> moveMarkerSmoothly({
    required int mapId,
    required String markerId,
    required LatLng targetPosition,
    int duration = 100,
    double? rotation,
  }) async {
    try {
      final params = <String, dynamic>{
        'markerId': markerId,
        'latitude': targetPosition.latitude,
        'longitude': targetPosition.longitude,
        'duration': duration,
      };
      
      if (rotation != null) {
        params['rotation'] = rotation;
      }
      
      final result = await channel(mapId).invokeMethod<bool>(
        'marker#moveMarkerSmoothly',
        params,
      );
      return result ?? false;
    } catch (e) {
      debugPrint('平滑移动Marker失败: $e');
      return false;
    }
  }

  @override
  void dispose({required int id}) {
    if (_channels.containsKey(id)) {
      _channels.remove(id);
    }
  }

  @override
  Widget buildView(
      Map<String, dynamic> creationParams,
      Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers,
      void Function(int id) onPlatformViewCreated) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      creationParams['debugMode'] = kDebugMode;
      return AndroidView(
        viewType: VIEW_TYPE,
        onPlatformViewCreated: onPlatformViewCreated,
        gestureRecognizers: gestureRecognizers,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: VIEW_TYPE,
        onPlatformViewCreated: onPlatformViewCreated,
        gestureRecognizers: gestureRecognizers,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
    return Text('当前平台:$defaultTargetPlatform, 不支持使用高德地图插件');
  }

  // handleMethodCall的`broadcast`
  final StreamController<MapEvent> _mapEventStreamController =
      StreamController<MapEvent>.broadcast();

  // 根据mapid返回相应的event.
  Stream<MapEvent> _events(int mapId) =>
      _mapEventStreamController.stream.where((event) => event.mapId == mapId);

  //定位回调
  Stream<LocationChangedEvent> onLocationChanged({required int mapId}) {
    return _events(mapId).whereType<LocationChangedEvent>();
  }

  //Camera 移动回调
  Stream<CameraPositionMoveEvent> onCameraMove({required int mapId}) {
    return _events(mapId).whereType<CameraPositionMoveEvent>();
  }

  ///Camera 移动结束回调
  Stream<CameraPositionMoveEndEvent> onCameraMoveEnd({required int mapId}) {
    return _events(mapId).whereType<CameraPositionMoveEndEvent>();
  }

  Stream<MapTapEvent> onMapTap({required int mapId}) {
    return _events(mapId).whereType<MapTapEvent>();
  }

  Stream<MapLongPressEvent> onMapLongPress({required int mapId}) {
    return _events(mapId).whereType<MapLongPressEvent>();
  }

  Stream<MapPoiTouchEvent> onPoiTouched({required int mapId}) {
    return _events(mapId).whereType<MapPoiTouchEvent>();
  }

  Stream<MarkerTapEvent> onMarkerTap({required int mapId}) {
    return _events(mapId).whereType<MarkerTapEvent>();
  }

  Stream<MarkerDragEndEvent> onMarkerDragEnd({required int mapId}) {
    return _events(mapId).whereType<MarkerDragEndEvent>();
  }

  Stream<PolylineTapEvent> onPolylineTap({required int mapId}) {
    return _events(mapId).whereType<PolylineTapEvent>();
  }

  Stream<InfoWindowCloseEvent> onInfoWindowClose({required int mapId}) {
    return _events(mapId).whereType<InfoWindowCloseEvent>();
  }

  Future<dynamic> _handleMethodCall(MethodCall call, int mapId) async {
    switch (call.method) {
      case 'location#changed':
        try {
          _mapEventStreamController.add(LocationChangedEvent(
              mapId, AMapLocation.fromMap(call.arguments['location'])!));
        } catch (e) {
          print("location#changed error=======>" + e.toString());
        }
        break;

      case 'camera#onMove':
        try {
          _mapEventStreamController.add(CameraPositionMoveEvent(
              mapId, CameraPosition.fromMap(call.arguments['position'])!));
        } catch (e) {
          print("camera#onMove error===>" + e.toString());
        }
        break;
      case 'camera#onMoveEnd':
        try {
          _mapEventStreamController.add(CameraPositionMoveEndEvent(
              mapId, CameraPosition.fromMap(call.arguments['position'])!));
        } catch (e) {
          print("camera#onMoveEnd error===>" + e.toString());
        }
        break;
      case 'map#onTap':
        _mapEventStreamController
            .add(MapTapEvent(mapId, LatLng.fromJson(call.arguments['latLng'])!));
        break;
      case 'map#onLongPress':
        _mapEventStreamController.add(MapLongPressEvent(
            mapId, LatLng.fromJson(call.arguments['latLng'])!));
        break;

      case 'marker#onTap':
        _mapEventStreamController.add(MarkerTapEvent(
          mapId,
          call.arguments['markerId'],
        ));
        break;
      case 'marker#onDragEnd':
        _mapEventStreamController.add(MarkerDragEndEvent(
            mapId,
            LatLng.fromJson(call.arguments['position'])!,
            call.arguments['markerId']));
        break;
      case 'polyline#onTap':
        _mapEventStreamController
            .add(PolylineTapEvent(mapId, call.arguments['polylineId']));
        break;
      case 'onInfoWindowClose':
        _mapEventStreamController.add(InfoWindowCloseEvent(mapId));
        break;
      case 'map#onPoiTouched':
        try {
          _mapEventStreamController.add(
              MapPoiTouchEvent(mapId, AMapPoi.fromJson(call.arguments['poi'])!));
        } catch (e) {
          print('map#onPoiTouched error===>' + e.toString());
        }
        break;
    }
  }

  ///移动镜头到一个新的位置
  Future<void> moveCamera(
    CameraUpdate cameraUpdate, {
    required int mapId,
    bool animated = true,
    int duration = 0,
  }) async {
    try {
      final mapChannel = channel(mapId);
      await mapChannel.invokeMethod<void>('camera#move', <String, dynamic>{
        'cameraUpdate': cameraUpdate.toJson(),
        'animated': animated,
        'duration': duration
      });
    } catch (e) {
      print('🚨 移动相机失败: $e, mapId: $mapId');
      rethrow;
    }
  }

  ///设置地图每秒渲染的帧数
  Future<void> setRenderFps(int fps, {required int mapId}) {
    return channel(mapId)
        .invokeMethod<void>('map#setRenderFps', <String, dynamic>{
      'fps': fps,
    });
  }

  ///截屏
  Future<Uint8List?> takeSnapshot({
    required int mapId,
  }) {
    return channel(mapId).invokeMethod<Uint8List>('map#takeSnapshot');
  }

  //获取地图审图号（普通地图）
  Future<String?> getMapContentApprovalNumber({
    required int mapId,
  }) {
    return channel(mapId).invokeMethod<String>('map#contentApprovalNumber');
  }

  //获取地图审图号（卫星地图）
  Future<String?> getSatelliteImageApprovalNumber({
    required int mapId,
  }) {
    return channel(mapId)
        .invokeMethod<String>('map#satelliteImageApprovalNumber');
  }

  Future<void> clearDisk({
    required int mapId,
  }) {
    return channel(mapId).invokeMethod<void>('map#clearDisk');
  }

  /// 隐藏所有 InfoWindow
  Future<void> hideAllInfoWindows({
    required int mapId,
  }) {
    return channel(mapId).invokeMethod<void>('map#hideAllInfoWindows');
  }

  /// 隐藏指定 Marker 的 InfoWindow
  Future<void> hideInfoWindow(String markerId, {
    required int mapId,
  }) {
    return channel(mapId).invokeMethod<void>('map#hideInfoWindow', <String, dynamic>{
      'markerId': markerId,
    });
  }

  /// 显示指定 Marker 的 InfoWindow
  Future<void> showInfoWindow(String markerId, {
    required int mapId,
  }) {
    return channel(mapId).invokeMethod<void>('map#showInfoWindow', <String, dynamic>{
      'markerId': markerId,
    });
  }

  /// 显示围栏圆圈
  Future<void> showGeofenceCircle({
    required double latitude,
    required double longitude,
    required double radius,
    required String strokeColor,
    required String fillColor,
    required double strokeWidth,
    required int mapId,
  }) {
    return channel(mapId).invokeMethod<void>('map#showGeofenceCircle', <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'strokeColor': strokeColor,
      'fillColor': fillColor,
      'strokeWidth': strokeWidth,
    });
  }

  /// 隐藏围栏圆圈
  Future<void> hideGeofenceCircle({
    required int mapId,
  }) {
    return channel(mapId).invokeMethod<void>('map#hideGeofenceCircle');
  }

  /// 清除围栏圆圈
  Future<void> clearGeofenceCircle({
    required int mapId,
  }) {
    return channel(mapId).invokeMethod<void>('map#clearGeofenceCircle');
  }

  /// 获取当前相机位置
  Future<CameraPosition?> getCameraPosition({
    required int mapId,
  }) async {
    final result = await channel(mapId).invokeMethod<Map<dynamic, dynamic>>('map#getCameraPosition');
    if (result == null) return null;
    return CameraPosition.fromMap(result);
  }

  /// 启动GIF动画Marker
  /// 
  /// 从Flutter assets加载GIF文件并在Marker上播放帧动画
  /// 
  /// [mapId] 地图ID
  /// [markerId] Marker的ID（必须是已存在的Marker）
  /// [assetPath] GIF文件的asset路径（如: assets/gif/ceshi.gif）
  /// [width] 可选，GIF显示宽度（像素）
  /// [height] 可选，GIF显示高度（像素）
  Future<bool> startGifAnimation({
    required int mapId,
    required String markerId,
    required String assetPath,
    int? width,
    int? height,
  }) async {
    try {
      final params = <String, dynamic>{
        'markerId': markerId,
        'assetPath': assetPath,
      };
      if (width != null && height != null) {
        params['width'] = width;
        params['height'] = height;
      }
      final result = await channel(mapId).invokeMethod<bool>(
        'marker#startGifAnimation',
        params,
      );
      return result ?? false;
    } catch (e) {
      debugPrint('启动GIF动画失败: $e');
      return false;
    }
  }

  /// 停止GIF动画Marker
  /// 
  /// [mapId] 地图ID
  /// [markerId] Marker的ID
  Future<bool> stopGifAnimation({
    required int mapId,
    required String markerId,
  }) async {
    try {
      final result = await channel(mapId).invokeMethod<bool>(
        'marker#stopGifAnimation',
        {
          'markerId': markerId,
        },
      );
      return result ?? false;
    } catch (e) {
      debugPrint('停止GIF动画失败: $e');
      return false;
    }
  }

  /// 预加载GIF到缓存
  /// 
  /// 在首页等位置提前调用，预加载GIF帧数据到内存缓存
  /// 后续使用时可以直接从缓存读取，无需重新解码
  /// 
  /// [mapId] 地图ID
  /// [assetPath] GIF文件的asset路径（如: assets/gif/ceshi.gif）
  /// [width] GIF显示宽度（像素）
  /// [height] GIF显示高度（像素）
  Future<bool> preloadGif({
    required int mapId,
    required String assetPath,
    required int width,
    required int height,
  }) async {
    try {
      final result = await channel(mapId).invokeMethod<bool>(
        'marker#preloadGif',
        {
          'assetPath': assetPath,
          'width': width,
          'height': height,
        },
      );
      return result ?? false;
    } catch (e) {
      debugPrint('预加载GIF失败: $e');
      return false;
    }
  }

  /// 🔄 启动Marker摆动动画（雨刷器效果）
  /// 
  /// 以Marker的锚点（尖尖）为圆心，左右摆动
  /// 效果类似雨刷器，两个头像先靠拢再分开
  /// 
  /// [mapId] 地图ID
  /// [markerId] Marker的ID
  /// [fromAngle] 起始角度（度数）
  /// [toAngle] 目标角度（度数）
  /// [duration] 单次摆动时长（毫秒，默认800ms）
  Future<bool> startSwingAnimation({
    required int mapId,
    required String markerId,
    required double fromAngle,
    required double toAngle,
    int duration = 800,
  }) async {
    try {
      final result = await channel(mapId).invokeMethod<bool>(
        'marker#startSwingAnimation',
        {
          'markerId': markerId,
          'fromAngle': fromAngle,
          'toAngle': toAngle,
          'duration': duration,
        },
      );
      return result ?? false;
    } catch (e) {
      debugPrint('启动摆动动画失败: $e');
      return false;
    }
  }

  /// 停止Marker摆动动画
  /// 
  /// [mapId] 地图ID
  /// [markerId] Marker的ID
  Future<bool> stopSwingAnimation({
    required int mapId,
    required String markerId,
  }) async {
    try {
      final result = await channel(mapId).invokeMethod<bool>(
        'marker#stopSwingAnimation',
        {
          'markerId': markerId,
        },
      );
      return result ?? false;
    } catch (e) {
      debugPrint('停止摆动动画失败: $e');
      return false;
    }
  }
}
