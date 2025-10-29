import 'package:get/get.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:kissu_app/model/location_model/location_model.dart';
import 'package:kissu_app/network/public/ltrack_api.dart';
import 'package:kissu_app/pages/track/stay_point.dart';
import 'package:kissu_app/utils/debug_util.dart';
import 'package:intl/intl.dart';

/// 轨迹页面数据管理器
/// 负责数据加载、缓存管理、数据处理等功能
class TrackDataManager {
  /// 自己的位置数据
  final Rx<LocationResponse?> myselfData = Rx<LocationResponse?>(null);
  
  /// 另一半的位置数据
  final Rx<LocationResponse?> partnerData = Rx<LocationResponse?>(null);
  
  /// 当前显示的是哪个用户（1=自己，0=另一半）
  /// 🎯 默认显示另一半的数据
  final currentUserType = 0.obs;
  
  /// 当前显示的数据
  LocationResponse? get currentData => 
      currentUserType.value == 1 ? myselfData.value : partnerData.value;
  
  /// 轨迹点缓存池 - 用于避免重复计算
  final Map<String, List<LatLng>> _trackPointsCache = {};
  
  /// 轨迹线状态管理 - 用于解决高德地图轨迹线更新问题
  final RxBool hasValidTrackData = false.obs;
  
  /// 当前选择的日期
  final selectedDate = DateTime.now().obs;
  
  /// 停留统计 (从当前显示的数据实时计算)
  final stayCount = 0.obs;
  final stayDuration = "".obs;
  final moveDistance = "".obs;
  
  /// 加载状态
  final isLoading = false.obs;
  
  /// 轨迹点列表（从当前数据实时计算）
  List<LatLng> get trackPoints {
    if (currentData == null) return [];
    
    // 根据当前查看的用户和日期生成缓存键
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);
    final cacheKey = 'user${currentUserType.value}_$dateStr';
    
    // 检查缓存
    if (_trackPointsCache.containsKey(cacheKey)) {
      return _trackPointsCache[cacheKey]!;
    }
    
    // 计算轨迹点
    final points = <LatLng>[];
    // 优先使用 locations 数组
    if (currentData!.locations?.isNotEmpty == true) {
      for (final location in currentData!.locations!) {
        if (location.lat != 0.0 && location.lng != 0.0) {
          points.add(LatLng(location.lat, location.lng));
        }
      }
    } else if (currentData!.trace?.stops.isNotEmpty == true) {
      // 如果没有locations，从stops生成轨迹点
      for (final stop in currentData!.trace!.stops) {
        if (stop.lat != 0.0 && stop.lng != 0.0) {
          points.add(LatLng(stop.lat, stop.lng));
        }
      }
    }
    
    // 缓存结果
    _trackPointsCache[cacheKey] = points;
    
    // 更新轨迹线状态
    hasValidTrackData.value = points.isNotEmpty;
    DebugUtil.info('轨迹点数量: ${points.length}, hasValidTrackData: ${hasValidTrackData.value}');
    
    return points;
  }
  
  /// 停留点列表（从当前数据实时计算）
  List<StayPoint> get stopPoints {
    
    if (currentData == null || currentData!.trace?.stops == null) return [];
    
    int index = 0;
    return currentData!.trace!.stops
        .where((stop) => stop.lat != 0.0 && stop.lng != 0.0)
        .map((stop) => StayPoint(
              position: LatLng(stop.lat, stop.lng),
              title: stop.locationName ?? '未知位置',
              duration: stop.duration ?? '',
              index: index++,
              serialNumber: stop.serialNumber ?? '', // 🎯 从API获取序列号
            ))
        .toList();
  }
  
  /// 加载两个用户的位置数据
  Future<void> loadBothUsersData({required DateTime date}) async {
    try {
      isLoading.value = true;
      DebugUtil.info('📍 开始加载两个用户的轨迹数据 - 日期: ${DateFormat('yyyy-MM-dd').format(date)}');
      
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      // 并行加载两个用户的数据
      final results = await Future.wait([
        TrackApi.getTrack(date: dateStr, isOneself: 1), // 自己
        TrackApi.getTrack(date: dateStr, isOneself: 0), // 另一半
      ]);
      
      // 处理自己的数据
      if (results[0].isSuccess && results[0].data != null) {
        myselfData.value = results[0].data;
        DebugUtil.success('✅ 自己的轨迹数据加载成功');
      } else {
        myselfData.value = null;
        DebugUtil.warning('⚠️ 自己的轨迹数据加载失败: ${results[0].msg}');
      }
      
      // 处理另一半的数据
      if (results[1].isSuccess && results[1].data != null) {
        partnerData.value = results[1].data;
        DebugUtil.success('✅ 另一半的轨迹数据加载成功');
      } else {
        partnerData.value = null;
        DebugUtil.warning('⚠️ 另一半的轨迹数据加载失败: ${results[1].msg}');
      }
      
      // 更新统计数据（基于当前显示的用户）
      updateStatistics();
      
    } catch (e) {
      DebugUtil.error('❌ 加载轨迹数据异常: $e');
      myselfData.value = null;
      partnerData.value = null;
      _clearStatistics();
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 切换用户
  void switchUser(int userType) {
    if (currentUserType.value == userType) return;
    
    DebugUtil.info('🔄 切换用户: ${userType == 1 ? "自己" : "另一半"}');
    currentUserType.value = userType;
    
    // 清空缓存，强制重新计算轨迹点
    _trackPointsCache.clear();
    
    // 更新统计数据
    updateStatistics();
  }
  
  /// 更新统计数据（基于当前显示的用户）
  void updateStatistics() {
    if (currentData == null) {
      _clearStatistics();
      return;
    }
    
    _updateStatistics(currentData!);
  }
  
  /// 更新统计数据
  void _updateStatistics(LocationResponse data) {
    // 停留次数（根据实际停留点数量计算）
    final actualStopPoints = stopPoints;
    stayCount.value = actualStopPoints.length;
    
    // 停留时长 - 从trace.stayCollect中获取
    if (data.trace?.stayCollect?.stayTime != null) {
      stayDuration.value = data.trace!.stayCollect!.stayTime!;
    } else {
      stayDuration.value = "0分钟";
    }
    
    // 移动距离 - 从trace.stayCollect中获取
    if (data.trace?.stayCollect?.moveDistance != null) {
      moveDistance.value = data.trace!.stayCollect!.moveDistance!;
    } else {
      moveDistance.value = "0米";
    }
    
    DebugUtil.info('统计数据更新 - 停留: ${stayCount.value}次, 时长: ${stayDuration.value}, 距离: ${moveDistance.value}');
  }
  
  /// 清空统计数据
  void _clearStatistics() {
    stayCount.value = 0;
    stayDuration.value = "0分钟";
    moveDistance.value = "0米";
  }
  
  /// 清空所有数据
  void clearAllData() {
    DebugUtil.info('🧹 清空所有轨迹数据...');
    myselfData.value = null;
    partnerData.value = null;
    _trackPointsCache.clear();
    hasValidTrackData.value = false;
    _clearStatistics();
  }
  
  /// 清空缓存
  void clearCache() {
    _trackPointsCache.clear();
    DebugUtil.info('轨迹点缓存已清空');
  }
  
  /// 获取起点坐标
  LatLng? getStartPoint() {
    if (currentData?.trace?.startPoint == null) return null;
    final start = currentData!.trace!.startPoint;
    if (start.lat != 0.0 && start.lng != 0.0) {
      return LatLng(start.lat, start.lng);
    }
    return null;
  }
  
  /// 获取终点坐标
  LatLng? getEndPoint() {
    if (currentData?.trace?.endPoint == null) return null;
    final end = currentData!.trace!.endPoint;
    if (end.lat != 0.0 && end.lng != 0.0) {
      return LatLng(end.lat, end.lng);
    }
    return null;
  }
  
  /// 检查是否有有效的轨迹数据
  bool hasTrackData() {
    return trackPoints.isNotEmpty || stopPoints.isNotEmpty;
  }
  
  /// 获取默认相机位置
  CameraPosition getDefaultCameraPosition() {
    // 如果有起点，使用起点
    final startPoint = getStartPoint();
    if (startPoint != null) {
      return CameraPosition(target: startPoint, zoom: 18.0);
    }
    
    // 如果有终点，使用终点
    final endPoint = getEndPoint();
    if (endPoint != null) {
      return CameraPosition(target: endPoint, zoom: 18.0);
    }
    
    // 默认杭州坐标
    return const CameraPosition(
      target: LatLng(30.2741, 120.2206),
      zoom: 18.0,
    );
  }
}
