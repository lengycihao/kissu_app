import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';

/// 地图缩放级别计算工具类
/// 基于轨迹页面的缩放逻辑，提供统一的地图缩放计算方法
class MapZoomCalculator {
  
  /// 根据两个位置点计算最佳的地图缩放级别和中心点
  /// 
  /// [point1] 第一个位置点
  /// [point2] 第二个位置点（可选）
  /// [defaultZoom] 当只有一个点或计算失败时使用的默认缩放级别
  /// 
  /// 返回包含目标位置和缩放级别的CameraPosition
  static CameraPosition calculateOptimalCameraPosition({
    required LatLng point1,
    LatLng? point2,
    double defaultZoom = 16.0,
  }) {
    // 如果只有一个点，使用默认缩放级别
    if (point2 == null) {
      return CameraPosition(
        target: point1,
        zoom: defaultZoom,
      );
    }
    
    // 计算边界
    double minLat = point1.latitude < point2.latitude ? point1.latitude : point2.latitude;
    double maxLat = point1.latitude > point2.latitude ? point1.latitude : point2.latitude;
    double minLng = point1.longitude < point2.longitude ? point1.longitude : point2.longitude;
    double maxLng = point1.longitude > point2.longitude ? point1.longitude : point2.longitude;
    
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
    
    // 根据距离计算缩放级别 - 与轨迹页面保持一致
    double zoom;
    if (maxDiff < 0.001) {
      zoom = 18.0; // 非常小的区域 (< 100米)
    } else if (maxDiff < 0.01) {
      zoom = 16.0; // 小区域 (< 1公里)
    } else if (maxDiff < 0.05) {
      zoom = 14.0; // 中小区域 (< 5公里)
    } else if (maxDiff < 0.1) {
      zoom = 13.0; // 中等区域 (< 10公里)
    } else if (maxDiff < 0.2) {
      zoom = 12.0; // 中大区域 (< 20公里)
    } else if (maxDiff < 0.5) {
      zoom = 11.0; // 大区域 (< 50公里)
    } else if (maxDiff < 1.0) {
      zoom = 10.0; // 很大区域 (< 100公里)
    } else if (maxDiff < 2.0) {
      zoom = 9.0; // 超大区域 (< 200公里)
    } else {
      zoom = 8.0; // 极大区域 (> 200公里)
    }
    
    print('🗺️ MapZoomCalculator - 计算结果: latDiff=$latDiff, lngDiff=$lngDiff, maxDiff=$maxDiff, zoom=$zoom');
    print('🗺️ MapZoomCalculator - 中心点: ($centerLat, $centerLng)');
    
    return CameraPosition(
      target: LatLng(centerLat, centerLng),
      zoom: zoom,
    );
  }
  
  /// 根据多个位置点计算最佳的地图缩放级别和中心点
  /// 
  /// [points] 位置点列表
  /// [defaultZoom] 当点列表为空或计算失败时使用的默认缩放级别
  /// [defaultCenter] 当点列表为空时使用的默认中心点
  /// 
  /// 返回包含目标位置和缩放级别的CameraPosition
  static CameraPosition calculateOptimalCameraPositionForMultiplePoints({
    required List<LatLng> points,
    double defaultZoom = 16.0,
    LatLng defaultCenter = const LatLng(30.2741, 120.2206), // 杭州默认坐标
  }) {
    if (points.isEmpty) {
      return CameraPosition(
        target: defaultCenter,
        zoom: defaultZoom,
      );
    }
    
    if (points.length == 1) {
      return CameraPosition(
        target: points.first,
        zoom: defaultZoom,
      );
    }
    
    // 计算边界
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    
    for (final point in points) {
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
    
    // 根据距离计算缩放级别 - 与轨迹页面保持一致
    double zoom;
    if (maxDiff < 0.001) {
      zoom = 18.0; // 非常小的区域 (< 100米)
    } else if (maxDiff < 0.01) {
      zoom = 16.0; // 小区域 (< 1公里)
    } else if (maxDiff < 0.05) {
      zoom = 14.0; // 中小区域 (< 5公里)
    } else if (maxDiff < 0.1) {
      zoom = 13.0; // 中等区域 (< 10公里)
    } else if (maxDiff < 0.2) {
      zoom = 12.0; // 中大区域 (< 20公里)
    } else if (maxDiff < 0.5) {
      zoom = 11.0; // 大区域 (< 50公里)
    } else if (maxDiff < 1.0) {
      zoom = 10.0; // 很大区域 (< 100公里)
    } else if (maxDiff < 2.0) {
      zoom = 9.0; // 超大区域 (< 200公里)
    } else {
      zoom = 8.0; // 极大区域 (> 200公里)
    }
    
    print('🗺️ MapZoomCalculator - 多点计算结果: 点数=${points.length}, latDiff=$latDiff, lngDiff=$lngDiff, maxDiff=$maxDiff, zoom=$zoom');
    print('🗺️ MapZoomCalculator - 中心点: ($centerLat, $centerLng)');
    
    return CameraPosition(
      target: LatLng(centerLat, centerLng),
      zoom: zoom,
    );
  }
  
  /// 计算两点的拉远缩放级别（用于初始显示）
  /// 这个方法返回比最佳缩放级别更拉远的级别，用于页面初始显示
  static CameraPosition calculateFarCameraPosition({
    required LatLng point1,
    LatLng? point2,
    double defaultFarZoom = 12.0,
  }) {
    // 如果只有一个点，使用较低缩放级别
    if (point2 == null) {
      return CameraPosition(
        target: point1,
        zoom: defaultFarZoom,
      );
    }
    
    // 计算中心点
    final centerLat = (point1.latitude + point2.latitude) / 2;
    final centerLng = (point1.longitude + point2.longitude) / 2;
    final center = LatLng(centerLat, centerLng);
    
    // 计算两点之间的差值（近似距离）
    final latDiff = (point1.latitude - point2.latitude).abs();
    final lngDiff = (point1.longitude - point2.longitude).abs();
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
    
    // 拉远缩放级别：比最佳级别低2-4级
    double farZoom;
    if (maxDiff < 0.001) {
      farZoom = 16.0; // 非常近的距离也要显示较远视角
    } else if (maxDiff < 0.01) {
      farZoom = 13.0; // 近距离显示中等视角
    } else if (maxDiff < 0.05) {
      farZoom = 10.0; // 中近距离显示远视角  
    } else if (maxDiff < 0.1) {
      farZoom = 9.0; // 中距离显示很远视角
    } else if (maxDiff < 0.2) {
      farZoom = 8.0; // 中远距离
    } else if (maxDiff < 0.5) {
      farZoom = 7.0; // 远距离
    } else if (maxDiff < 1.0) {
      farZoom = 6.0; // 很远距离
    } else if (maxDiff < 2.0) {
      farZoom = 5.0; // 超远距离
    } else {
      farZoom = 4.0; // 极远距离
    }
    
    print('🌍 MapZoomCalculator - 拉远级别计算: maxDiff=$maxDiff, farZoom=$farZoom');
    print('🌍 MapZoomCalculator - 拉远中心点: ($centerLat, $centerLng)');
    
    return CameraPosition(
      target: center,
      zoom: farZoom,
    );
  }
}
