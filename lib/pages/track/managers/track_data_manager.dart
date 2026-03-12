import 'package:get/get.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:kissu_app/model/location_model/location_model.dart';
import 'package:kissu_app/network/public/ltrack_api.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/pages/track/stay_point.dart';
import 'package:kissu_app/pages/track/utils/track_point_filter.dart';
 import 'package:intl/intl.dart';

/// 轨迹页面数据管理器
/// 负责数据加载、缓存管理、数据处理等功能
class TrackDataManager {
  /// 自己的位置数据
  final Rx<LocationResponse?> myselfData = Rx<LocationResponse?>(null);
  
  /// 另一半的位置数据
  final Rx<LocationResponse?> partnerData = Rx<LocationResponse?>(null);
  
  /// 当前显示的是哪个用户（1=自己，0=另一半）
  /// 🎯 默认显示自己的数据（未绑定时只看自己，已绑定时再切换到另一半）
  final currentUserType = 1.obs;
  
  /// 当前显示的数据
  LocationResponse? get currentData => 
      currentUserType.value == 1 ? myselfData.value : partnerData.value;
  
  /// 轨迹点缓存池 - 用于避免重复计算
  final Map<String, List<LatLng>> _trackPointsCache = {};
  
  /// 停留点缓存池 - 用于避免重复计算
  final Map<String, List<StayPoint>> _stopPointsCache = {};
  
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
      // 先过滤零值点
      final validLocations = currentData!.locations!
          .where((loc) => loc.lat != 0.0 && loc.lng != 0.0)
          .toList();
      // 飘点过滤：基于速度和尖刺模式检测，过滤掉GPS漂移点
      final filteredLocations = TrackPointFilter.filterLocations(validLocations);
      for (final location in filteredLocations) {
        points.add(LatLng(location.lat, location.lng));
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
    
    // 🔥 修复：同步更新轨迹线状态，避免异步更新导致的时序问题
    // 之前使用 Future.microtask() 会导致 hasValidTrackData 状态更新滞后，
    // 在头像切换时 UI 可能在状态更新前就读取了旧值，导致 marker 显示不稳定
    final hasData = points.isNotEmpty;
    if (hasValidTrackData.value != hasData) {
      hasValidTrackData.value = hasData;
    }
    logDebug('轨迹点数量: ${points.length}, hasValidTrackData: $hasData');
    
    return points;
  }
  
  /// 停留点列表（从当前数据实时计算，带缓存）
  /// 🎯 只返回 trace.stops 中 point_type="stop" 的数据，序号使用 serial_number
  /// 🚀 性能优化：添加缓存机制，避免重复计算
  List<StayPoint> get stopPoints {
    if (currentData == null || currentData!.trace?.stops == null) {
      return [];
    }
    
    // 根据当前查看的用户和日期生成缓存键
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);
    final cacheKey = 'stopPoints_user${currentUserType.value}_$dateStr';
    
    // 检查缓存
    if (_stopPointsCache.containsKey(cacheKey)) {
      return _stopPointsCache[cacheKey]!;
    }
    
    final allStops = currentData!.trace!.stops;
    
    // 🎯 只筛选 point_type="stop" 的停留点（不打印每个点的日志）
    final stopTypeStops = allStops.where((stop) {
      final isValid = stop.lat != 0.0 && stop.lng != 0.0;
      final isStopType = stop.pointType == "stop";
      return isValid && isStopType;
    }).toList();
    
    int index = 0;
    final result = stopTypeStops.map((stop) {
      return StayPoint(
        position: LatLng(stop.lat, stop.lng),
        title: stop.locationName ?? '未知位置',
        duration: stop.duration ?? '',
        index: index++,
        serialNumber: stop.serialNumber ?? '',
      );
    }).toList();
    
    // 缓存结果
    _stopPointsCache[cacheKey] = result;
    
    // 🚀 只打印摘要日志
    logDebug('📍 [StopPoints] 计算完成: 总数=${allStops.length}, 有效停留点=${result.length} (已缓存)');
    return result;
  }
  
  /// 加载两个用户的位置数据
  Future<void> loadBothUsersData({required DateTime date}) async {
    try {
      isLoading.value = true;
      logDebug('📍 开始加载两个用户的轨迹数据 - 日期: ${DateFormat('yyyy-MM-dd').format(date)}');
      
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      // 并行加载两个用户的数据
      final results = await Future.wait([
        TrackApi.getTrack(date: dateStr, isOneself: 1), // 自己
        TrackApi.getTrack(date: dateStr, isOneself: 0), // 另一半
      ]);
      
      // 处理自己的数据
      if (results[0].isSuccess && results[0].data != null) {
        myselfData.value = results[0].data;
        logDebug('✅ 自己的轨迹数据加载成功');
      } else {
        myselfData.value = null;
        logWarning('⚠️ 自己的轨迹数据加载失败: ${results[0].msg}');
      }
      
      // 处理另一半的数据
      if (results[1].isSuccess && results[1].data != null) {
        partnerData.value = results[1].data;
        logDebug('✅ 另一半的轨迹数据加载成功');
      } else {
        partnerData.value = null;
        logWarning('⚠️ 另一半的轨迹数据加载失败: ${results[1].msg}');
      }
      
      // 更新统计数据（基于当前显示的用户）
      updateStatistics();
      
    } catch (e) {
      logError('❌ 加载轨迹数据异常: $e');
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
    
    logDebug('🔄 切换用户: ${userType == 1 ? "自己" : "另一半"}');
    currentUserType.value = userType;
    
    // 清空缓存，强制重新计算轨迹点和停留点
    _trackPointsCache.clear();
    _stopPointsCache.clear();
    
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
    
    logDebug('统计数据更新 - 停留: ${stayCount.value}次, 时长: ${stayDuration.value}, 距离: ${moveDistance.value}');
  }
  
  /// 清空统计数据
  void _clearStatistics() {
    stayCount.value = 0;
    stayDuration.value = "0分钟";
    moveDistance.value = "0米";
  }
  
  /// 清空所有数据
  void clearAllData() {
    logDebug('🧹 清空所有轨迹数据...');
    myselfData.value = null;
    partnerData.value = null;
    _trackPointsCache.clear();
    _stopPointsCache.clear();
    hasValidTrackData.value = false;
    _clearStatistics();
  }
  
  /// 清空缓存
  void clearCache() {
    _trackPointsCache.clear();
    _stopPointsCache.clear();
    logDebug('轨迹点和停留点缓存已清空');
  }
  
  /// 获取起点坐标
  /// 🎯 从 locations 字段的第一个数据获取
  LatLng? getStartPoint() {
    if (currentData == null) return null;

    // 1）优先从 locations 列表的第一个点取（老逻辑）
    if (currentData!.locations != null && currentData!.locations!.isNotEmpty) {
      final firstLocation = currentData!.locations!.first;
      if (firstLocation.lat != 0.0 && firstLocation.lng != 0.0) {
        return LatLng(firstLocation.lat, firstLocation.lng);
      }
    }

    // 2）locations 为空时，尝试从 trace.startPoint 取
    if (currentData!.trace?.startPoint != null) {
      final sp = currentData!.trace!.startPoint;
      if (sp.lat != 0.0 && sp.lng != 0.0) {
        return LatLng(sp.lat, sp.lng);
      }
    }

    // 3）再兜底：如果 trace.stops 里有 pointType = 'start' 的记录，用它作为起点
    if (currentData!.trace?.stops != null &&
        currentData!.trace!.stops.isNotEmpty) {
      try {
        final startStop = currentData!.trace!.stops.firstWhere(
          (s) => (s.pointType == 'start') &&
              s.lat != 0.0 &&
              s.lng != 0.0,
          orElse: () => currentData!.trace!.stops.first,
        );
        if (startStop.lat != 0.0 && startStop.lng != 0.0) {
          return LatLng(startStop.lat, startStop.lng);
        }
      } catch (_) {
        // 忽略兜底失败
      }
    }

    return null;
  }
  
  /// 获取终点坐标
  /// 🎯 从 locations 字段的最后一个数据获取
  /// 🎯 当 locations 只有一个点时，不显示终点（只显示起点）
  LatLng? getEndPoint() {
    if (currentData == null) return null;

    // 1）优先从 locations 列表的最后一个点取（老逻辑）
    if (currentData!.locations != null && currentData!.locations!.isNotEmpty) {
      // 🎯 当只有一个点时，不显示终点（只显示起点）
      if (currentData!.locations!.length <= 1) {
        return null;
      }
      final lastLocation = currentData!.locations!.last;
      if (lastLocation.lat != 0.0 && lastLocation.lng != 0.0) {
        return LatLng(lastLocation.lat, lastLocation.lng);
      }
    }

    // 2）locations 为空时，尝试从 trace.endPoint 取
    if (currentData!.trace?.endPoint != null) {
      final ep = currentData!.trace!.endPoint;
      if (ep.lat != 0.0 && ep.lng != 0.0) {
        return LatLng(ep.lat, ep.lng);
      }
    }

    // 3）兜底：如果 trace.stops 里有 pointType = 'end' 且数据多于1个，可以取它作为终点
    if (currentData!.trace?.stops != null &&
        currentData!.trace!.stops.length > 1) {
      try {
        final endStop = currentData!.trace!.stops.lastWhere(
          (s) => (s.pointType == 'end') &&
              s.lat != 0.0 &&
              s.lng != 0.0,
          orElse: () => currentData!.trace!.stops.last,
        );
        if (endStop.lat != 0.0 && endStop.lng != 0.0) {
          return LatLng(endStop.lat, endStop.lng);
        }
      } catch (_) {
        // 忽略兜底失败
      }
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
