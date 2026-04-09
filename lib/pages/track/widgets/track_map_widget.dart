import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/services/analytics/analytics_events.dart';
import 'package:kissu_app/services/analytics/analytics_helper.dart';
import 'package:kissu_app/utils/source_page_utils.dart';
import '../../../widgets/safe_amap_widget.dart';
import '../../../utils/user_manager.dart';
import '../../../widgets/dialogs/custom_bottom_dialog.dart';
import '../track_controller.dart';
import '../track_page_config.dart';

/// 轨迹地图组件
/// 封装所有地图相关逻辑，包括标记、轨迹线、手势控制等
class TrackMapWidget extends StatefulWidget {
  final TrackController controller;

  const TrackMapWidget({
    super.key,
    required this.controller,
  });

  @override
  State<TrackMapWidget> createState() => _TrackMapWidgetState();
}

class _TrackMapWidgetState extends State<TrackMapWidget> {
  // 缓存地图元素，避免频繁重建
  Set<Marker> _cachedMarkers = {};
  Set<Polyline> _cachedPolylines = {};
  int _markersVersion = -1;
  int _polylinesVersion = -1;
  int _stopRecordsVersion = -1;

  // 轨迹线纹理缓存
  BitmapDescriptor? _trackLineTextureRed;
  BitmapDescriptor? _trackLineTextureBlue;

  // 更新状态标志
  bool _isUpdatingPolylines = false;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 检查标记是否需要更新
      final currentMarkersVersion = widget.controller.stopMarkers.length +
          widget.controller.trackStartEndMarkers.length +
          (widget.controller.tempInfoWindowMarker != null ? 10000 : 0);

      if (currentMarkersVersion != _markersVersion) {
        // 延迟更新标记，避免在build过程中调用setState
        Future.microtask(() {
          if (mounted) {
            _updateMarkers();
            _markersVersion = currentMarkersVersion;
          }
        });
      }

      // 检查轨迹线是否需要更新
      // 🔥 修复：先访问 trackPoints 触发 hasValidTrackData 的同步更新，再读取状态
      // 之前的顺序会导致 hasValidTrackData 读取到旧值，造成 marker 显示不稳定
      final currentTrackPoints = widget.controller.trackPoints;
      final hasValidData = widget.controller.hasValidTrackData.value && currentTrackPoints.length >= 2;
      final currentPolylinesVersion = hasValidData ? currentTrackPoints.length : 0;
      final currentStopRecordsVersion = widget.controller.stopRecords.length;

      if (currentPolylinesVersion != _polylinesVersion ||
          currentStopRecordsVersion != _stopRecordsVersion) {
        logDebug('🎨 检测到轨迹线需要更新 - 旧版本: $_polylinesVersion, 新版本: $currentPolylinesVersion, 停留点: $currentStopRecordsVersion');
        // 立即更新版本号，避免重复触发
        _polylinesVersion = currentPolylinesVersion;
        _stopRecordsVersion = currentStopRecordsVersion;

        Future.microtask(() {
          if (mounted) {
            _updatePolylines();
          }
        });
      }

      // 根据下半屏展开程度控制地图手势
      final sheetPercent = widget.controller.sheetPercent.value;
      final isBindPartner = widget.controller.isBindPartner.value;
      final isVip = UserManager.isVip;
      
      // 🔥 未绑定或非会员时：禁用地图缩放和滚动手势
      // - 未绑定：点击地图弹绑定弹窗
      // - 已绑定但非会员：点击地图跳转VIP页面
      // - 会员：根据面板展开程度控制手势
      final bool enableMapGestures;
      final bool needInterceptGestures = !isBindPartner || !isVip;
      
      if (needInterceptGestures) {
        // 未绑定或非会员：禁用地图手势
        enableMapGestures = false;
      } else {
        // 会员且已绑定：根据面板展开程度控制
        enableMapGestures = sheetPercent <= TrackPageConfig.mapEnableThreshold;
      }

      // 未绑定或非会员时使用GestureDetector包裹地图，拦截所有手势
      if (needInterceptGestures) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _handleMapInteraction(),
          onScaleStart: (_) => _handleMapInteraction(),
          child: AbsorbPointer(
            absorbing: true, // 非会员时完全吸收地图手势
            child: SafeAMapWidget(
              initialCameraPosition: widget.controller.initialCameraPosition,
              onMapCreated: widget.controller.onMapCreated,
              onMapDisposed: widget.controller.onMapDisposed,
              markers: _cachedMarkers,
              polylines: _cachedPolylines,
              circles: widget.controller.highlightCircles.toSet(),
              mapType: widget.controller.mapType.value == 1
                  ? MapType.normal
                  : MapType.satellite,
              buildingsEnabled: false,
              compassEnabled: false,
              scaleEnabled: false,
              zoomGesturesEnabled: false,
              scrollGesturesEnabled: false,
              rotateGesturesEnabled: false,
              onTap: null,
              onInfoWindowClose: null,
            ),
          ),
        );
      }

      // 会员时使用原有逻辑
      return AbsorbPointer(
        absorbing: !enableMapGestures,
        child: SafeAMapWidget(
          initialCameraPosition: widget.controller.initialCameraPosition,
          onMapCreated: widget.controller.onMapCreated,
          onMapDisposed: widget.controller.onMapDisposed,
          markers: _cachedMarkers,
          polylines: _cachedPolylines,
          circles: widget.controller.highlightCircles.toSet(),
          mapType: widget.controller.mapType.value == 1
              ? MapType.normal
              : MapType.satellite,
          buildingsEnabled: false,
          compassEnabled: enableMapGestures,
          scaleEnabled: enableMapGestures,
          zoomGesturesEnabled: enableMapGestures,
          scrollGesturesEnabled: enableMapGestures,
          rotateGesturesEnabled: enableMapGestures,
          onTap: enableMapGestures ? (LatLng position) {
            widget.controller.clearMapHighlights();
          } : null,
          onInfoWindowClose: enableMapGestures ? () {
            widget.controller.clearAllHighlightCircles();
          } : null,
        ),
      );
    });
  }

  /// 处理地图交互（未绑定弹绑定弹窗，已绑定但非会员跳转VIP页面）
  void _handleMapInteraction() {
    final isBindPartner = widget.controller.isBindPartner.value;
    final isVip = UserManager.isVip;
    
    // 埋点：点击地图
    AnalyticsHelper.trackTrackMapClick();
    
    if (!isBindPartner) {
      // 未绑定：弹绑定弹窗
      _showBindingDialog();
    } else if (!isVip) {
      // 已绑定但非会员：跳转VIP页面
      widget.controller.onNavigateToNextPage?.call();
      Get.toNamed(
        KissuRoutePath.vip,
        arguments: {
          'source_page': SourcePageUtilsCaller.track,
          'source_event': TrackEvents.mapClick,
        },
      );
    }
  }
  
  /// 显示绑定弹窗
  void _showBindingDialog() {
    final currentContext = Get.context;
    if (currentContext == null) return;
    
    CustomBottomDialog.show(
      context: currentContext,
      caller: SourcePageUtilsCaller.track,
      sourceEvent: TrackEvents.mapClick,
    );
  }

  /// 更新标记缓存
  void _updateMarkers() {
    final newMarkers = <Marker>{};

    try {
      newMarkers.addAll(widget.controller.stopMarkers);
      newMarkers.addAll(widget.controller.trackStartEndMarkers);
    } catch (e) {
      logError('添加标记失败: $e');
    }

    // 添加临时 InfoWindow 标记
    if (widget.controller.tempInfoWindowMarker != null) {
      try {
        newMarkers.add(widget.controller.tempInfoWindowMarker!);
        logDebug('✅ 已添加临时 InfoWindow 标记到地图缓存');
      } catch (e) {
        logError('添加临时 InfoWindow 标记失败: $e');
      }
    }

    _cachedMarkers = newMarkers;
  }

  /// 更新轨迹线
  Future<void> _updatePolylines() async {
    // 防止重复更新
    if (_isUpdatingPolylines) {
      logDebug('🎨 轨迹线正在更新中，跳过此次更新');
      return;
    }

    _isUpdatingPolylines = true;

    final newPolylines = <Polyline>{};

    try {
      final trackPoints = widget.controller.trackPoints.toList();
      final stopRecords = widget.controller.stopRecords.toList();

      logDebug('🎯 更新轨迹线 - hasValidTrackData: ${widget.controller.hasValidTrackData.value}, trackPoints: ${trackPoints.length}, stopRecords: ${stopRecords.length}');

      if (widget.controller.hasValidTrackData.value && trackPoints.length >= 2) {
        logDebug('🎨 轨迹数据有效，开始创建轨迹线');
        logDebug('🎨 开始创建轨迹线，轨迹点数量: ${trackPoints.length}');

        // 加载轨迹线纹理
        await _loadTexturesIfNeeded();

        // 确保纹理已加载
        if (_trackLineTextureRed == null || _trackLineTextureBlue == null) {
          logError('❌ 纹理未完全加载，无法创建轨迹线');
          logError('❌ 红色纹理: ${_trackLineTextureRed != null}, 蓝色纹理: ${_trackLineTextureBlue != null}');
          return;
        }

        logDebug('✅ 纹理加载完成，开始创建轨迹线');

        if (stopRecords.isNotEmpty) {
          // 有停留点时按停留点分段
          final segments = _createSegmentedPolylines(trackPoints, stopRecords);
          newPolylines.addAll(segments);
        } else {
          // 无停留点时使用默认纹理
          final defaultPolylines = await _createDefaultPolylines(trackPoints);
          newPolylines.addAll(defaultPolylines);
        }
      } else {
        logDebug('🎨 无有效轨迹数据，清空轨迹线');
        // 没有有效数据时，清空轨迹线
        newPolylines.clear();
      }
    } catch (e) {
      logError('创建轨迹线失败: $e');
      _isUpdatingPolylines = false;
      return;
    }

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _cachedPolylines = newPolylines;
          });
          logDebug('✅ 轨迹线更新完成，共 ${newPolylines.length} 条线段');
        }
        // 重置更新标志
        _isUpdatingPolylines = false;
      });
    } else {
      // 如果组件已经卸载，直接重置标志
      _isUpdatingPolylines = false;
    }
  }

  /// 加载纹理（只加载一次）
  Future<void> _loadTexturesIfNeeded() async {
    if (_trackLineTextureRed == null) {
      try {
        _trackLineTextureRed = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(),
          'assets/texture/kissu4_track_line_red.png',
        );
        logDebug('✅ 红色纹理加载成功');
      } catch (e) {
        logError('❌ 红色纹理加载失败: $e');
      }
    }

    if (_trackLineTextureBlue == null) {
      try {
        _trackLineTextureBlue = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(),
          'assets/texture/kissu4_track_line_blue.png',
        );
        logDebug('✅ 蓝色纹理加载成功');
      } catch (e) {
        logError('❌ 蓝色纹理加载失败: $e');
      }
    }
  }

  /// 创建分段轨迹线
  List<Polyline> _createSegmentedPolylines(List<LatLng> trackPoints, List stopRecords) {
    final polylines = <Polyline>[];
    final sortedStops = _prepareSortedStops(trackPoints, stopRecords);
    final validStops = _createValidStops(trackPoints, sortedStops);

    logDebug('🎨 准备创建 ${validStops.length - 1} 段轨迹线');

    for (int i = 0; i < validStops.length - 1; i++) {
      final startStop = validStops[i];
      final endStop = validStops[i + 1];

      final startIndex = startStop.index;
      final endIndex = endStop.index;

      if (endIndex > startIndex && endIndex < trackPoints.length) {
        final segmentPoints = trackPoints.sublist(startIndex, endIndex + 1);

        if (segmentPoints.length >= 2) {
          final isRed = i % 2 == 0;
          final texture = isRed ? _trackLineTextureRed! : _trackLineTextureBlue!;

          logDebug(
            '🎨 分段 $i: 使用${isRed ? "红色" : "蓝色"}纹理, 点数=${segmentPoints.length}',
          );

          polylines.addAll(_createPolylineSegments(segmentPoints, texture));
        }
      }
    }

    logDebug('✅ 轨迹线分段完成，共创建 ${polylines.length} 条线段');
    return polylines;
  }

  /// 准备排序的停留点
  /// 参考轨迹回放页面的逻辑：起点 + 所有停留点 + 终点
  List _prepareSortedStops(List<LatLng> trackPoints, List stopRecords) {
    final allPoints = <dynamic>[];
    
    // 1. 添加轨迹起点
    if (trackPoints.isNotEmpty) {
      allPoints.add(_createStartPointFromTrackPoint(trackPoints.first));
    }
    
    // 2. 添加所有停留点（不过滤pointType，直接使用所有记录）
    allPoints.addAll(stopRecords);
    
    // 3. 添加轨迹终点
    if (trackPoints.isNotEmpty) {
      allPoints.add(_createEndPointFromTrackPoint(trackPoints.last));
    }
    
    logDebug('🔍 准备停留点: 起点1 + 停留点${stopRecords.length} + 终点1 = ${allPoints.length}');
    
    return allPoints;
  }

  /// 创建有效的停留点（带索引）
  List<_StopWithIndex> _createValidStops(List<LatLng> trackPoints, List sortedStops) {
    final validStops = <_StopWithIndex>[];
    for (final stop in sortedStops) {
      final index = _findNearestPointIndex(trackPoints, LatLng(stop.latitude, stop.longitude));
      validStops.add(_StopWithIndex(stop: stop, index: index));
    }

    // 按索引排序并去重
    validStops.sort((a, b) => a.index.compareTo(b.index));
    return _deduplicateStops(validStops);
  }

  /// 去重停留点
  List<_StopWithIndex> _deduplicateStops(List<_StopWithIndex> stops) {
    final uniqueStops = <_StopWithIndex>[];
    int? lastIndex;
    List<_StopWithIndex>? currentGroup;

    for (final stopWithIndex in stops) {
      if (lastIndex == null || stopWithIndex.index != lastIndex) {
        // 处理上一组
        if (currentGroup != null) {
          uniqueStops.add(currentGroup.length > 1 ? currentGroup.last : currentGroup.first);
        }
        // 开始新组
        currentGroup = [stopWithIndex];
        lastIndex = stopWithIndex.index;
      } else {
        currentGroup!.add(stopWithIndex);
      }
    }

    // 处理最后一组
    if (currentGroup != null) {
      uniqueStops.add(currentGroup.length > 1 ? currentGroup.last : currentGroup.first);
    }

    return uniqueStops;
  }

  /// 创建默认轨迹线（无停留点时）
  /// 按固定点数分段，红蓝交替显示
  Future<List<Polyline>> _createDefaultPolylines(List<LatLng> trackPoints) async {
    // 确保纹理已加载
    await _loadTexturesIfNeeded();
    
    if (_trackLineTextureRed == null || _trackLineTextureBlue == null) {
      logError('❌ 纹理未完全加载，无法创建默认轨迹线');
      return [];
    }

    // 每段的点数（用于红蓝交替）
    const int pointsPerColorSegment = 50;
    // 每条Polyline的最大点数（性能限制）
    const int maxPointsPerPolyline = 100;
    final polylines = <Polyline>[];

    // 按颜色分段
    int colorSegmentIndex = 0;
    for (int i = 0; i < trackPoints.length - 1; i += pointsPerColorSegment - 1) {
      final segmentEndIndex = (i + pointsPerColorSegment).clamp(0, trackPoints.length);
      final segmentPoints = trackPoints.sublist(i, segmentEndIndex);

      if (segmentPoints.length >= 2) {
        // 红蓝交替
        final isRed = colorSegmentIndex % 2 == 0;
        final texture = isRed ? _trackLineTextureRed! : _trackLineTextureBlue!;

        logDebug(
          '🎨 默认分段 $colorSegmentIndex: 使用${isRed ? "红色" : "蓝色"}纹理, 点数=${segmentPoints.length}',
        );

        // 如果分段太长，需要进一步分割
        if (segmentPoints.length <= maxPointsPerPolyline) {
          polylines.add(Polyline(
            points: segmentPoints,
            width: 8,
            visible: true,
            customTexture: texture,
            capType: CapType.round,
          ));
        } else {
          // 分割成更小的段，但保持相同颜色
          for (int j = 0; j < segmentPoints.length - 1; j += maxPointsPerPolyline - 1) {
            final subEndIndex = (j + maxPointsPerPolyline).clamp(0, segmentPoints.length);
            final subSegmentPoints = segmentPoints.sublist(j, subEndIndex);

            if (subSegmentPoints.length >= 2) {
              polylines.add(Polyline(
                points: subSegmentPoints,
                width: 8,
                visible: true,
                customTexture: texture,
                capType: CapType.round,
              ));
            }
          }
        }

        colorSegmentIndex++;
      }
    }

    logDebug('✅ 默认轨迹线创建完成，共 ${polylines.length} 条线段，${colorSegmentIndex} 个颜色分段');
    return polylines;
  }

  /// 创建折线段
  List<Polyline> _createPolylineSegments(List<LatLng> points, BitmapDescriptor texture) {
    const int maxPointsPerSegment = 100;
    final polylines = <Polyline>[];

    if (points.length <= maxPointsPerSegment) {
      polylines.add(Polyline(
        points: points,
        width: 8,
        visible: true,
        customTexture: texture,
        capType: CapType.round,
      ));
    } else {
      for (int j = 0; j < points.length - 1; j += maxPointsPerSegment - 1) {
        final subEndIndex = (j + maxPointsPerSegment).clamp(0, points.length);
        final subSegmentPoints = points.sublist(j, subEndIndex);

        if (subSegmentPoints.length >= 2) {
          polylines.add(Polyline(
            points: subSegmentPoints,
            width: 8,
            visible: true,
            customTexture: texture,
            capType: CapType.round,
          ));
        }
      }
    }

    return polylines;
  }

  /// 查找最近的轨迹点索引
  int _findNearestPointIndex(List<LatLng> trackPoints, LatLng target) {
    if (trackPoints.isEmpty) return 0;

    int nearestIndex = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < trackPoints.length; i++) {
      final distance = _calculateDistance(trackPoints[i], target);
      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }

    return nearestIndex;
  }

  /// 计算两点距离
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000;
    final double lat1Rad = point1.latitude * math.pi / 180;
    final double lat2Rad = point2.latitude * math.pi / 180;
    final double deltaLatRad = (point2.latitude - point1.latitude) * math.pi / 180;
    final double deltaLngRad = (point2.longitude - point1.longitude) * math.pi / 180;

    final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// 从轨迹点创建起点记录
  dynamic _createStartPointFromTrackPoint(LatLng point) {
    return _MockStopRecord(
      latitude: point.latitude,
      longitude: point.longitude,
      locationName: '起点',
      pointType: 'start',
      serialNumber: '起',
    );
  }

  /// 从轨迹点创建终点记录
  dynamic _createEndPointFromTrackPoint(LatLng point) {
    return _MockStopRecord(
      latitude: point.latitude,
      longitude: point.longitude,
      locationName: '终点',
      pointType: 'end',
      serialNumber: '终',
    );
  }
}

/// 辅助类：停留点及其在轨迹中的索引
class _StopWithIndex {
  final dynamic stop;
  final int index;

  _StopWithIndex({required this.stop, required this.index});
}

/// 模拟停留点记录类（用于创建终点）
class _MockStopRecord {
  final double latitude;
  final double longitude;
  final String locationName;
  final String pointType;
  final String serialNumber;

  _MockStopRecord({
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.pointType,
    required this.serialNumber,
  });
}
