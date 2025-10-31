import 'dart:async';
import 'package:get/get.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:kissu_app/utils/debug_util.dart';

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

  /// 🔒 动画锁机制，防止地图变化时的滑动冲突
  bool _isAnimating = false;

  /// 地图创建完成回调
  void onMapCreated(AMapController controller, Function? hideAllInfoWindows) {
    mapController = controller;
    DebugUtil.success('轨迹页面高德地图创建成功');

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
        DebugUtil.info('🔒 地图初始化后关闭所有 InfoWindow (50ms)');
      }
    });
  }

  /// 设置地图就绪状态
  void setMapReady(bool ready) {
    isMapReady.value = ready;
    DebugUtil.info('地图就绪状态更新: $ready');
  }

  /// 🔒 设置动画锁状态
  void setAnimationLock(bool isLocked) {
    _isAnimating = isLocked;
    DebugUtil.info('🔒 地图动画锁状态: $isLocked');
  }

  /// 是否正在动画中
  bool get isAnimating => _isAnimating;

  /// 移动地图到指定位置
  void moveMapToLocation(LatLng location) {
    // 检查地图是否就绪
    if (!isMapReady.value || mapController == null) {
      DebugUtil.warning('地图未就绪或控制器为空，无法移动地图位置');
      return;
    }

    try {
      mapController!.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: location, zoom: 18.0),
        ),
      );
      DebugUtil.info('地图已移动到: ${location.latitude}, ${location.longitude}');
    } catch (e) {
      DebugUtil.error('移动地图失败: $e');
    }
  }

  /// 平滑移动地图到指定位置
  void moveMapToLocationSmooth(LatLng position) {
    try {
      mapController?.moveCamera(CameraUpdate.newLatLng(position));
    } catch (e) {
      DebugUtil.error('平滑移动地图失败: $e');
    }
  }

  /// 切换地图类型
  void switchMapType(int type) {
    if (type != 1 && type != 2) {
      DebugUtil.warning('无效的地图类型: $type');
      return;
    }

    if (mapType.value == type) {
      DebugUtil.info('地图类型未改变，无需切换');
      return;
    }

    mapType.value = type;
    DebugUtil.info('地图类型切换为: ${type == 1 ? "经典地图" : "卫星地图"}');
  }

  /// 计算适合所有轨迹点的相机位置
  CameraPosition? calculateOptimalCameraPosition(List<LatLng> trackPoints) {
    if (trackPoints.isEmpty) return null;

    // 计算边界
    double minLat = trackPoints.first.latitude;
    double maxLat = trackPoints.first.latitude;
    double minLng = trackPoints.first.longitude;
    double maxLng = trackPoints.first.longitude;

    for (final point in trackPoints) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    // 添加边距（10%的padding）
    final latPadding = (maxLat - minLat) * 0.1;
    final lngPadding = (maxLng - minLng) * 0.1;

    minLat -= latPadding;
    maxLat += latPadding;
    minLng -= lngPadding;
    maxLng += lngPadding;

    // 计算中心点
    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    // 计算合适的缩放级别
    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

    // 根据距离计算缩放级别 - 支持更大范围的轨迹
    double zoom;
    if (maxDiff < 0.001) {
      zoom = 19.0; // 非常小的区域 (< 100米)
    } else if (maxDiff < 0.01) {
      zoom = 18.0; // 小区域 (< 1公里)
    } else if (maxDiff < 0.05) {
      zoom = 16.0; // 中小区域 (< 5公里)
    } else if (maxDiff < 0.1) {
      zoom = 13.0; // 中等区域 (< 10公里)
    } else if (maxDiff < 0.2) {
      zoom = 11.0; // 中大区域 (< 20公里)
    } else if (maxDiff < 0.5) {
      zoom = 10.0; // 大区域 (< 50公里)
    } else if (maxDiff < 1.0) {
      zoom = 9.0; // 很大区域 (< 100公里)
    } else if (maxDiff < 2.0) {
      zoom = 8.0; // 超大区域 (< 200公里)
    } else if (maxDiff < 5.0) {
      zoom = 6.0; // < 500公里
    } else if (maxDiff < 10.0) {
      zoom = 4.0; // < 1000公里
    } else if (maxDiff < 20.0) {
      zoom = 3.0; // < 2000公里
    } else {
      zoom = 3.0; // 全球区域 (> 2000公里)
    }

    // 打印调试信息
    DebugUtil.info(
      '轨迹范围计算: latDiff=$latDiff, lngDiff=$lngDiff, maxDiff=$maxDiff, zoom=$zoom',
    );
    DebugUtil.info('轨迹中心点: ($centerLat, $centerLng)');

    return CameraPosition(target: LatLng(centerLat, centerLng), zoom: zoom);
  }

  /// 自动调整地图视图以显示轨迹（仅基于轨迹点）
  Future<void> fitMapToTrack(List<LatLng> trackPoints) async {
    if (!isMapReady.value || mapController == null) {
      DebugUtil.warning('地图未就绪或控制器为空，无法调整视图');
      return;
    }

    if (trackPoints.isEmpty) {
      DebugUtil.warning('轨迹点为空，无法调整视图');
      return;
    }

    // 计算最佳相机位置
    final targetPosition = calculateOptimalCameraPosition(trackPoints);
    if (targetPosition == null) {
      DebugUtil.warning('无法计算最佳相机位置');
      return;
    }

    try {
      await mapController!.moveCamera(
        CameraUpdate.newCameraPosition(targetPosition),
      );
      DebugUtil.success('地图已调整到显示完整轨迹 - 缩放级别: ${targetPosition.zoom}');
    } catch (e) {
      DebugUtil.error('调整地图视图失败: $e');
    }
  }

  /// 自动调整地图视图以显示所有轨迹点
  Future<void> fitMapToTrackPoints({
    required List<LatLng> trackPoints,
    required List<dynamic> stopPoints,
    required dynamic locationData,
  }) async {
    if (!isMapReady.value || mapController == null) {
      DebugUtil.warning('地图未就绪或控制器为空，无法调整视图');
      return;
    }

    CameraPosition? targetPosition;

    // 检查是否有轨迹数据
    final hasTrackData = trackPoints.isNotEmpty || stopPoints.isNotEmpty;

    // 如果没有任何位置信息，显示全国地图视图
    if (!hasTrackData) {
      DebugUtil.info('🗺️ 无位置信息，显示全国地图视图');
      targetPosition = CameraPosition(
        target: LatLng(35.86166, 104.195397), // 中国地理中心
        zoom: 3.0, // 可以看到全国的缩放级别 (越小范围越大)
      );
    }
    // 优先使用轨迹点计算最佳位置
    else if (trackPoints.isNotEmpty) {
      DebugUtil.info('开始自动调整地图视图，轨迹点数量: ${trackPoints.length}');
      targetPosition = calculateOptimalCameraPosition(trackPoints);
    }
    // 如果没有轨迹点，尝试使用位置数据的起点或终点
    else if (locationData != null) {
      if (locationData.trace?.startPoint.lat != 0.0 &&
          locationData.trace?.startPoint.lng != 0.0) {
        targetPosition = CameraPosition(
          target: LatLng(
            locationData.trace!.startPoint.lat,
            locationData.trace!.startPoint.lng,
          ),
          zoom: 18.0,
        );
        DebugUtil.info('使用起点作为地图中心');
      } else if (locationData.trace?.endPoint.lat != 0.0 &&
          locationData.trace?.endPoint.lng != 0.0) {
        targetPosition = CameraPosition(
          target: LatLng(
            locationData.trace!.endPoint.lat,
            locationData.trace!.endPoint.lng,
          ),
          zoom: 18.0,
        );
        DebugUtil.info('使用终点作为地图中心');
      }
    }

    // 如果没有任何有效位置，使用默认杭州坐标
    if (targetPosition == null) {
      DebugUtil.warning('没有有效位置数据，使用默认杭州坐标');
      targetPosition = const CameraPosition(
        target: LatLng(30.2741, 120.2206),
        zoom: 18.0,
      );
    }

    try {
      await mapController!.moveCamera(
        CameraUpdate.newCameraPosition(targetPosition),
      );
      DebugUtil.success('地图已自动调整到最佳视图 - 缩放级别: ${targetPosition.zoom}');
    } catch (e) {
      DebugUtil.error('调整地图视图失败: $e');
    }
  }

  /// 强制地图更新，确保UI同步
  void forceMapUpdate({
    required List<LatLng> trackPoints,
    required List<dynamic> stopPoints,
    required dynamic locationData,
  }) {
    // 检查地图是否就绪
    if (!isMapReady.value || mapController == null) {
      DebugUtil.warning('地图未就绪或控制器为空，无法强制更新');
      return;
    }

    // 使用防抖，避免频繁更新导致性能问题
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      DebugUtil.info('🔄 执行强制地图更新...');

      // 自动调整地图视图
      fitMapToTrackPoints(
        trackPoints: trackPoints,
        stopPoints: stopPoints,
        locationData: locationData,
      );
    });
  }

  /// 清理资源
  void dispose() {
    _debounceTimer?.cancel();
    mapController = null;
  }
}
