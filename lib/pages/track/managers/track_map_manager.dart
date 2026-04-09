import 'dart:async';
import 'package:get/get.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/utils/debug_util.dart';
import 'package:kissu_app/utils/user_manager.dart';  

/// 轨迹页面地图管理器
/// 负责地图的初始化、相机控制、地图类型切换等功能
class TrackMapManager {
  /// 地图控制器
  AMapController? mapController;

  /// 地图就绪状态
  final isMapReady = false.obs;

  /// 地图类型 (1: 经典地图, 2: 卫星地图)
  final mapType = 1.obs;

  /// 防抖定时器
  Timer? _debounceTimer;

  /// ✅ [api.md] 是否已自动调整过地图视图（防止同一份数据多次 moveCamera）
  bool _hasFitted = false;

  /// ✅ [api.md] 用户是否主动操作过地图（操作期间跳过自动 fit）
  bool _userInteracting = false;

  /// 🔒 动画锁机制，防止地图变化时的滑动冲突
  bool _isAnimating = false;

  /// 地图创建完成回调
  void onMapCreated(AMapController controller, Function? hideAllInfoWindows) {
    mapController = controller;
    // logDebug('轨迹页面高德地图创建成功');

    // 设置地图就绪状态
    setMapReady(true);

    // 🎯 立即隐藏 InfoWindow（第一次）
    if (hideAllInfoWindows != null) {
      hideAllInfoWindows();
    }

    // 🎯 延迟后再次隐藏（第二次），确保 Marker 创建后的 InfoWindow 也被隐藏
    Future.delayed(const Duration(milliseconds: 50), () {
      if (hideAllInfoWindows != null) {
        hideAllInfoWindows();
        // logDebug('🔒 地图初始化后关闭所有 InfoWindow (50ms)');
      }
    });
  }

  /// 设置地图就绪状态
  void setMapReady(bool ready) {
    isMapReady.value = ready;
    // logDebug('地图就绪状态更新: $ready');
  }

  /// 🔒 设置动画锁状态
  void setAnimationLock(bool isLocked) {
    _isAnimating = isLocked;
    // logDebug('🔒 地图动画锁状态: $isLocked');
  }

  /// 是否正在动画中
  bool get isAnimating => _isAnimating;

  /// 重置 fit 标志（加载新数据或切换用户前调用）
  void resetFit() {
    _hasFitted = false;
    _userInteracting = false;
  }

  /// 标记用户开始手动操作地图（后续自动 fit 将跳过，避免抢夺控制权）
  void onUserGesture() {
    _userInteracting = true;
    // logDebug('👆 用户开始操作地图，暂停自动fit');
  }

  /// 恢复自动 fit 权限
  void resetUserGesture() {
    _userInteracting = false;
  }

  /// 移动地图到指定位置
  void moveMapToLocation(LatLng location) {
    // 检查地图是否就绪
    if (!isMapReady.value || mapController == null) {
      logWarning('地图未就绪或控制器为空，无法移动地图位置');
      return;
    }

    try {
      mapController!.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: location, zoom: 18.0),
        ),
      );
      // logDebug('地图已移动到: ${location.latitude}, ${location.longitude}');
    } catch (e) {
      logError('移动地图失败: $e');
    }
  }

  /// 平滑移动地图到指定位置
  void moveMapToLocationSmooth(LatLng position) {
    try {
      mapController?.moveCamera(CameraUpdate.newLatLng(position));
    } catch (e) {
      logError('平滑移动地图失败: $e');
    }
  }

  /// 切换地图类型
  void switchMapType(int type) {
    if (type != 1 && type != 2) {
      // logDebug('无效的地图类型: $type');
      return;
    }

    if (mapType.value == type) {
      // logDebug('地图类型未改变，无需切换');
      return;
    }

    mapType.value = type;
    // logDebug('地图类型切换为: ${type == 1 ? "经典地图" : "卫星地图"}');
  }

  /// 🚀 简化：计算适合所有轨迹点的相机位置（仅用于初始化，具体缩放由 newLatLngBounds 控制）
  CameraPosition? calculateOptimalCameraPosition(List<LatLng> trackPoints) {
    if (trackPoints.isEmpty) return null;

    // 计算中心点
    double centerLat = 0;
    double centerLng = 0;

    for (final point in trackPoints) {
      centerLat += point.latitude;
      centerLng += point.longitude;
    }

    centerLat /= trackPoints.length;
    centerLng /= trackPoints.length;

    // logDebug('轨迹中心点: ($centerLat, $centerLng)');

    // 初始使用较低缩放级别，具体缩放由 fitMapToTrackPoints 中的 newLatLngBounds 精确控制
    return CameraPosition(target: LatLng(centerLat, centerLng), zoom: 10.0);
  }

  /// 🚀 优化：自动调整地图视图以显示轨迹（使用原生 newLatLngBounds）
  Future<void> fitMapToTrack(List<LatLng> trackPoints) async {
    if (!isMapReady.value || mapController == null) {
      logInfo('地图未就绪或控制器为空，无法调整视图');
      return;
    }

     
    if (trackPoints.isEmpty) {
      logWarning('轨迹点为空，无法调整视图');
      return;
    }

    // 如果只有一个点，直接定位到该点
    if (trackPoints.length == 1) {
      try {
        await mapController!.moveCamera(
          CameraUpdate.newLatLngZoom(trackPoints.first, 18.0),
        );
        logInfo('只有一个轨迹点，直接定位');
      } catch (e) {
        logError('移动到单点位置失败: $e');
      }
      return;
    }

    try {
      // 🚀 使用原生 newLatLngBounds 自动计算缩放层级
      // 计算边界
      double minLat = trackPoints.first.latitude;
      double maxLat = trackPoints.first.latitude;
      double minLng = trackPoints.first.longitude;
      double maxLng = trackPoints.first.longitude;

      for (final point in trackPoints) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }

      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      await mapController!.moveCamera(
        CameraUpdate.newLatLngBounds(bounds, 100), // 100像素边距
        animated: true,
        duration: 500,
      );

      // logDebug('✅ 使用原生LatLngBounds调整地图到显示完整轨迹');
    } catch (e) {
      logError('调整地图视图失败: $e');
    }
  }

  /// 🚀 优化：使用原生 newLatLngBounds 自动调整地图视图
  /// 非会员时固定缩放等级为3，会员时自动计算最佳缩放等级
  Future<void> fitMapToTrackPoints({
    required List<LatLng> trackPoints,
    required List<dynamic> stopPoints,
    required dynamic locationData,
  }) async {
    if (!isMapReady.value || mapController == null) {
      logInfo('地图未就绪或控制器为空，无法调整视图');
      return;
    }

    // ✅ [api.md] 已 fit 过则跳过，避免同一份数据触发多次 moveCamera
    if (_hasFitted) {
      logDebug('⚠️ 已fit过地图，跳过（调用 resetFit() 可重新触发）');
      return;
    }

    // ✅ [api.md] 用户正在操作地图，不抢夺控制权
    if (_userInteracting) {
      logDebug('⚠️ 用户正在操作地图，跳过自动fit');
      return;
    }

    _hasFitted = true;

    // 🔥 非会员时：固定缩放等级为3，只显示中国地图概览
    final isVip = UserManager.isVip;
    if (!isVip) {
      // logDebug('� 非会员：固定地图缩放等级为3');
      try {
        await mapController!.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(35.86166, 104.195397), // 中国地理中心
              zoom: 3.0,
            ),
          ),
        );
      } catch (e) {
        logError('非会员设置地图缩放等级失败: $e');
      }
      return;
    }

    // 🚀 会员时：收集所有需要显示的点，自动计算最佳缩放等级
    final List<LatLng> allPoints = [];

    // 1. 从 locations 列表中添加所有轨迹点
    if (locationData?.locations != null && locationData.locations.isNotEmpty) {
      for (final location in locationData.locations) {
        if (location.lat != 0.0 && location.lng != 0.0) {
          allPoints.add(LatLng(location.lat, location.lng));
        }
      }
      // logDebug('从 locations 添加轨迹点数量: ${locationData.locations.length}');
    }

    // 2. 添加 trace 中的起点
    if (locationData?.trace?.startPoint != null) {
      final startPoint = locationData.trace!.startPoint;
      if (startPoint.lat != 0.0 && startPoint.lng != 0.0) {
        allPoints.add(LatLng(startPoint.lat, startPoint.lng));
      //  logDebug('添加起点: (${startPoint.lat}, ${startPoint.lng})');
      }
    }

    // 3. 添加 trace 中的终点
    if (locationData?.trace?.endPoint != null) {
      final endPoint = locationData.trace!.endPoint;
      if (endPoint.lat != 0.0 && endPoint.lng != 0.0) {
        allPoints.add(LatLng(endPoint.lat, endPoint.lng));
      //  logDebug('添加终点: (${endPoint.lat}, ${endPoint.lng})');
      }
    }

    // 4. 添加 trace 中的所有停留点
    if (locationData?.trace?.stops != null) {
      for (final stop in locationData.trace!.stops) {
        if (stop.lat != 0.0 && stop.lng != 0.0) {
          allPoints.add(LatLng(stop.lat, stop.lng));
        }
      }
      // logDebug('添加停留点数量: ${locationData.trace!.stops.length}');
    }

    // logDebug('🗺️ 总点数: ${allPoints.length}');

    // 如果没有任何点，显示默认位置
    if (allPoints.isEmpty) {
      // logDebug('没有有效位置数据，显示全国地图视图');
      try {
        await mapController!.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(35.86166, 104.195397), // 中国地理中心
              zoom: 3.0,
            ),
          ),
        );
      } catch (e) {
        logError('移动到默认位置失败: $e');
      }
      return;
    }

    // 如果只有一个点，直接定位到该点
    if (allPoints.length == 1) {
      try {
        await mapController!.moveCamera(
          CameraUpdate.newLatLngZoom(allPoints.first, 18.0),
        );
        // logDebug('只有一个点，直接定位');
      } catch (e) {
        logError('移动到单点位置失败: $e');
      }
      return;
    }

    // 🚀 使用原生 newLatLngBounds 自动计算最佳缩放层级
    try {
      // 计算边界：找出最小和最大的经纬度
      double minLat = allPoints.first.latitude;
      double maxLat = allPoints.first.latitude;
      double minLng = allPoints.first.longitude;
      double maxLng = allPoints.first.longitude;

      for (final point in allPoints) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }

      // 构建 LatLngBounds
      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      // logDebug(
      //   '📍 bounds: southwest($minLat, $minLng), northeast($maxLat, $maxLng)',
      // );

      // 使用原生方法自动计算缩放层级
      await mapController!.moveCamera(
        CameraUpdate.newLatLngBounds(bounds, 100), // 100像素边距
        animated: true,
        duration: 500,
      );

      // logDebug('✅ 使用原生LatLngBounds自动调整地图视图');
    } catch (e) {
      logError('调整地图视图失败: $e');
    }
  }

  /// 强制地图更新（仅取消待执行的防抖任务，不移动相机）
  /// 注意：Marker/Polyline 由 Flutter 层响应式驱动，无需主动调用 moveCamera
  void forceMapUpdate({
    required List<LatLng> trackPoints,
    required List<dynamic> stopPoints,
    required dynamic locationData,
  }) {
    _debounceTimer?.cancel();
    // logDebug('🔄 forceMapUpdate: 取消旧防抖任务，UI由响应式驱动更新');
  }

  /// 清理资源
  void dispose() {
    _debounceTimer?.cancel();
    mapController = null;
  }

  /// PlatformView销毁时清理状态，避免持有失效的Controller引用
  void onMapDisposed() {
    DebugUtil.warning('🧹 地图PlatformView已销毁，重置地图控制器状态');
    _debounceTimer?.cancel();
    mapController = null;
    setMapReady(false);
    _hasFitted = false;
    _userInteracting = false;
  }
}
