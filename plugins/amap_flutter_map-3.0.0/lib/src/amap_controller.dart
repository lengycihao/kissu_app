part of amap_flutter_map;

final MethodChannelAMapFlutterMap _methodChannel = AMapFlutterPlatform.instance as MethodChannelAMapFlutterMap;

/// 地图通信中心
class AMapController {
  final int mapId;
  final _MapState _mapState;

  AMapController._(CameraPosition initCameraPosition, this._mapState, {required this.mapId}) {
    _connectStreams(mapId);
  }

  ///根据传入的id初始化[AMapController]
  /// 主要用于在[AMapWidget]初始化时在[AMapWidget.onMapCreated]中初始化controller
  static Future<AMapController> init(
    int id,
    CameraPosition initialCameration,
    _MapState mapState,
  ) async {
    await _methodChannel.init(id);
    return AMapController._(
      initialCameration,
      mapState,
      mapId: id,
    );
  }

  ///只用于测试
  ///用于与native的通信
  @visibleForTesting
  MethodChannel get channel {
    return _methodChannel.channel(mapId);
  }

  void _connectStreams(int mapId) {
    if (_mapState.widget.onLocationChanged != null) {
      _methodChannel
          .onLocationChanged(mapId: mapId)
          .listen((LocationChangedEvent e) => _mapState.widget.onLocationChanged!(e.value));
    }

    if (_mapState.widget.onCameraMove != null) {
      _methodChannel
          .onCameraMove(mapId: mapId)
          .listen((CameraPositionMoveEvent e) => _mapState.widget.onCameraMove!(e.value));
    }
    if (_mapState.widget.onCameraMoveEnd != null) {
      _methodChannel
          .onCameraMoveEnd(mapId: mapId)
          .listen((CameraPositionMoveEndEvent e) => _mapState.widget.onCameraMoveEnd!(e.value));
    }
    if (_mapState.widget.onTap != null) {
      _methodChannel.onMapTap(mapId: mapId).listen(((MapTapEvent e) => _mapState.widget.onTap!(e.value)));
    }
    if (_mapState.widget.onLongPress != null) {
      _methodChannel
          .onMapLongPress(mapId: mapId)
          .listen(((MapLongPressEvent e) => _mapState.widget.onLongPress!(e.value)));
    }

    if (_mapState.widget.onPoiTouched != null) {
      _methodChannel
          .onPoiTouched(mapId: mapId)
          .listen(((MapPoiTouchEvent e) => _mapState.widget.onPoiTouched!(e.value)));
    }

    _methodChannel.onMarkerTap(mapId: mapId).listen((MarkerTapEvent e) => _mapState.onMarkerTap(e.value));

    _methodChannel
        .onMarkerDragEnd(mapId: mapId)
        .listen((MarkerDragEndEvent e) => _mapState.onMarkerDragEnd(e.value, e.position));

    _methodChannel.onPolylineTap(mapId: mapId).listen((PolylineTapEvent e) => _mapState.onPolylineTap(e.value));

    _methodChannel.onInfoWindowClose(mapId: mapId).listen((InfoWindowCloseEvent e) => _mapState.onInfoWindowClose());
  }

  void disponse() {
    _methodChannel.dispose(id: mapId);
  }

  Future<void> _updateMapOptions(Map<String, dynamic> optionsUpdate) {
    return _methodChannel.updateMapOptions(optionsUpdate, mapId: mapId);
  }

  Future<void> _updateMarkers(MarkerUpdates markerUpdates) {
    return _methodChannel.updateMarkers(markerUpdates, mapId: mapId);
  }

  Future<void> _updatePolylines(PolylineUpdates polylineUpdates) {
    return _methodChannel.updatePolylines(polylineUpdates, mapId: mapId);
  }

  Future<void> _updatePolygons(PolygonUpdates polygonUpdates) {
    return _methodChannel.updatePolygons(polygonUpdates, mapId: mapId);
  }

  Future<void> _updateCircles(CircleUpdates circleUpdates) {
    return _methodChannel.updateCircles(circleUpdates, mapId: mapId);
  }

  /// 更新单个标记
  /// 
  /// 用于更新已存在的标记属性，如位置、旋转角度等
  /// [marker] 要更新的标记对象，必须包含markerId
  Future<void> updateMarker(Marker marker) {
    return _methodChannel.updateMarker(marker, mapId: mapId);
  }

  /// 启动Marker呼吸动画（iOS原版实现）
  /// 
  /// 🎯 iOS原版效果：
  /// - 横向拉伸：X=1.03, Y=0.98（横向拉伸，纵向压缩）
  /// - 纵向拉伸：X=0.98, Y=1.03（横向压缩，纵向拉伸）
  /// - 两种状态交替变换，产生自然的"呼吸"效果
  /// 
  /// 🚀 性能优势：
  /// - 使用原生ScaleAnimation（GPU加速）
  /// - 60fps流畅运行
  /// - 零跨平台通信开销（只调用一次）
  /// 
  /// [markerId] Marker的ID（必须是已存在的Marker）
  /// [duration] 动画时长（毫秒，默认400ms，与iOS原版一致）
  Future<bool> startMarkerBreathAnimation({
    required String markerId,
    int duration = 400,
  }) {
    return _methodChannel.startMarkerBreathAnimation(
      mapId: mapId,
      markerId: markerId,
      duration: duration,
    );
  }

  /// 停止Marker呼吸动画
  /// 
  /// [markerId] Marker的ID
  Future<bool> stopMarkerBreathAnimation({
    required String markerId,
  }) {
    return _methodChannel.stopMarkerBreathAnimation(
      mapId: mapId,
      markerId: markerId,
    );
  }

  ///改变地图视角
  ///
  ///通过[CameraUpdate]对象设置新的中心点、缩放比例、放大缩小、显示区域等内容
  ///
  ///（注意：iOS端设置显示区域时，不支持duration参数，动画时长使用iOS地图默认值350毫秒）
  ///
  ///可选属性[animated]用于控制是否执行动画移动
  ///
  ///可选属性[duration]用于控制执行动画的时长,默认250毫秒,单位:毫秒
  Future<void> moveCamera(CameraUpdate cameraUpdate, {bool animated = true, int duration = 250}) {
    return _methodChannel.moveCamera(cameraUpdate, mapId: mapId, animated: animated, duration: duration);
  }

  ///设置地图每秒渲染的帧数
  Future<void> setRenderFps(int fps) {
    return _methodChannel.setRenderFps(fps, mapId: mapId);
  }

  ///地图截屏
  Future<Uint8List?> takeSnapshot() {
    return _methodChannel.takeSnapshot(mapId: mapId);
  }

  /// 获取地图审图号（普通地图）
  ///
  /// 任何使用高德地图API调用地图服务的应用必须在其应用中对外透出审图号
  ///
  /// 如高德地图在"关于"中体现
  Future<String?> getMapContentApprovalNumber() {
    return _methodChannel.getMapContentApprovalNumber(mapId: mapId);
  }

  /// 获取地图审图号（卫星地图)
  ///
  /// 任何使用高德地图API调用地图服务的应用必须在其应用中对外透出审图号
  ///
  /// 如高德地图在"关于"中体现
  Future<String?> getSatelliteImageApprovalNumber() {
    return _methodChannel.getSatelliteImageApprovalNumber(mapId: mapId);
  }

  /// 清空缓存
  Future<void> clearDisk() {
    return _methodChannel.clearDisk(mapId: mapId);
  }

  /// 隐藏所有 InfoWindow
  /// 
  /// 调用此方法将关闭地图上所有正在显示的 InfoWindow
  Future<void> hideAllInfoWindows() {
    return _methodChannel.hideAllInfoWindows(mapId: mapId);
  }

  /// 隐藏指定 Marker 的 InfoWindow
  /// 
  /// [markerId] Marker 的 ID
  /// 调用此方法将关闭指定 Marker 的 InfoWindow
  Future<void> hideInfoWindow(String markerId) {
    return _methodChannel.hideInfoWindow(markerId, mapId: mapId);
  }

  /// 显示指定 Marker 的 InfoWindow
  /// 
  /// [markerId] Marker 的 ID
  /// 调用此方法将显示指定 Marker 的 InfoWindow
  Future<void> showInfoWindow(String markerId) {
    return _methodChannel.showInfoWindow(markerId, mapId: mapId);
  }

  /// 显示围栏圆圈
  /// 
  /// [latitude] 纬度
  /// [longitude] 经度
  /// [radius] 半径（米），默认100米
  /// [strokeColor] 边框颜色，默认白色
  /// [fillColor] 填充颜色，默认粉色半透明
  /// [strokeWidth] 边框宽度，默认3
  /// 
  /// 调用此方法将在指定位置显示一个围栏圆圈（会先清除之前的圆圈）
  Future<void> showGeofenceCircle({
    required double latitude,
    required double longitude,
    double radius = 100.0,
    String strokeColor = '#FFFFFF',
    String fillColor = '#61FFE3EB', // #61 = 38% 不透明度
    double strokeWidth = 3.0,
  }) {
    return _methodChannel.showGeofenceCircle(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
      strokeColor: strokeColor,
      fillColor: fillColor,
      strokeWidth: strokeWidth,
      mapId: mapId,
    );
  }

  /// 隐藏围栏圆圈
  /// 
  /// 调用此方法将隐藏当前显示的围栏圆圈（但不删除，可以重新显示）
  Future<void> hideGeofenceCircle() {
    return _methodChannel.hideGeofenceCircle(mapId: mapId);
  }

  /// 清除围栏圆圈
  /// 
  /// 调用此方法将完全清除围栏圆圈（删除，需要重新创建）
  Future<void> clearGeofenceCircle() {
    return _methodChannel.clearGeofenceCircle(mapId: mapId);
  }

  /// 获取当前相机位置
  /// 
  /// 返回当前地图的相机位置信息，包括中心点坐标、缩放级别、倾斜角度和旋转角度
  Future<CameraPosition?> getCameraPosition() {
    return _methodChannel.getCameraPosition(mapId: mapId);
  }
}
