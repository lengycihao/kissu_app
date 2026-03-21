import 'dart:async';
import 'package:get/get.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/utils/user_manager.dart';

class TrackMapManager {
  AMapController? mapController;

  final isMapReady = false.obs;
  final mapType = 1.obs;

  /// ✅ 是否已经自动调整过地图（核心开关）
  bool _hasFitted = false;

  /// ✅ 是否用户主动操作过地图
  bool _userInteracting = false;

  /// 防抖（仅用于用户操作）
  Timer? _debounceTimer;

  /// ===== 初始化 =====

  void onMapCreated(AMapController controller, Function? hideAllInfoWindows) {
    mapController = controller;
    setMapReady(true);

    hideAllInfoWindows?.call();

    Future.delayed(const Duration(milliseconds: 50), () {
      hideAllInfoWindows?.call();
    });
  }

  void setMapReady(bool ready) {
    isMapReady.value = ready;
  }

  /// ===== 用户行为标记（重要） =====

  void onUserGesture() {
    _userInteracting = true;
    logDebug('👆 用户开始操作地图');
  }

  void resetUserGesture() {
    _userInteracting = false;
  }

  /// ===== ✅ 核心：只执行一次的地图自适应 =====

  Future<void> fitMapOnce({
    required List<LatLng> trackPoints,
    required dynamic locationData,
  }) async {
    if (!isMapReady.value || mapController == null) return;

    /// ❗ 已执行过，不再执行（核心优化）
    if (_hasFitted) {
      logDebug('⚠️ 已经fit过地图，跳过');
      return;
    }

    /// ❗ 用户操作过，不抢控制权
    if (_userInteracting) {
      logDebug('⚠️ 用户正在操作地图，跳过自动fit');
      return;
    }

    _hasFitted = true;

    final isVip = UserManager.isVip;

    try {
      if (!isVip) {
        await mapController!.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(35.86166, 104.195397),
              zoom: 3.0,
            ),
          ),
        );
        return;
      }

      final List<LatLng> allPoints = [];

      if (locationData?.locations != null) {
        for (final loc in locationData.locations) {
          if (loc.lat != 0 && loc.lng != 0) {
            allPoints.add(LatLng(loc.lat, loc.lng));
          }
        }
      }

      if (allPoints.isEmpty) return;

      if (allPoints.length == 1) {
        await mapController!.moveCamera(
          CameraUpdate.newLatLngZoom(allPoints.first, 18),
        );
        return;
      }

      double minLat = allPoints.first.latitude;
      double maxLat = allPoints.first.latitude;
      double minLng = allPoints.first.longitude;
      double maxLng = allPoints.first.longitude;

      for (final p in allPoints) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }

      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      await mapController!.moveCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
        animated: true,
        duration: 500,
      );

      logDebug('✅ 首次地图自适应完成');
    } catch (e) {
      logError('fitMapOnce失败: $e');
    }
  }

  /// ===== ❌ 禁止自动触发地图移动 =====

  void forceMapUpdate({
    required List<LatLng> trackPoints,
    required List<dynamic> stopPoints,
    required dynamic locationData,
  }) {
    /// ❗ 只刷新UI，不动地图
    logDebug('🔄 刷新地图UI（不移动相机）');
  }

  /// ===== ✅ 用户触发地图移动（安全） =====

  void moveToPointByUser(LatLng point) {
    if (!isMapReady.value || mapController == null) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      mapController!.moveCamera(
        CameraUpdate.newLatLngZoom(point, 18),
      );
    });
  }

  /// ===== 地图类型 =====

  void switchMapType(int type) {
    if (mapType.value == type) return;
    mapType.value = type;
  }

  /// ===== 生命周期 =====

  void onMapDisposed() {
    _debounceTimer?.cancel();
    mapController = null;
    setMapReady(false);
    _hasFitted = false;
    _userInteracting = false;
  }
}