import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/widgets/safe_amap_widget.dart'; 
import 'package:kissu_app/utils/debug_util.dart';
import 'track_replay_controller.dart';

/// 轨迹播放页面
/// 全屏播放轨迹，只包含地图和底部播放条
class TrackReplayPage extends StatelessWidget {
  const TrackReplayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TrackReplayController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 全屏地图
          Positioned.fill(child: _MapWidget(controller: controller)),

          // 底部播放条
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _ReplayControlBar(controller: controller),
          ),

          // 顶部返回按钮
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 5,
            child: _BackButton(),
          ),
        ],
      ),
    );
  }
}

/// 地图组件
class _MapWidget extends StatefulWidget {
  final TrackReplayController controller;

  const _MapWidget({required this.controller});

  @override
  State<_MapWidget> createState() => _MapWidgetState();
}

// 辅助类：停留点及其在轨迹中的索引
class _StopPointWithIndex {
  final LatLng point;
  final int index;
  
  _StopPointWithIndex({required this.point, required this.index});
}

class _MapWidgetState extends State<_MapWidget> {
  Set<Polyline> _cachedPolylines = {};
  int _polylinesVersion = -1;
  BitmapDescriptor? _trackLineTextureRed; // 红色轨迹线纹理（只加载一次）
  BitmapDescriptor? _trackLineTextureBlue; // 蓝色轨迹线纹理（只加载一次）

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 🎯 检查轨迹线是否需要更新
      final currentPolylinesVersion = widget.controller.trackPoints.length;
      if (currentPolylinesVersion != _polylinesVersion) {
        // 使用 Future.microtask 避免在 build 期间调用 setState
        Future.microtask(() {
          if (mounted) {
        _updatePolylines();
        _polylinesVersion = currentPolylinesVersion;
          }
        });
      }
      
      // 🎯 直接组合所有markers（每次都重新组合以确保响应式更新）
      final allMarkers = <Marker>{};
      
      // 添加播放markers（头像和底座）
      final avatar = widget.controller.replayAvatarMarker.value;
      final pedestal = widget.controller.replayPedestalMarker.value;
      if (avatar != null) {
        allMarkers.add(avatar);
      }
      if (pedestal != null) {
        allMarkers.add(pedestal);
      }
      
      // 添加静态markers（起点、终点、停留点）
      allMarkers.addAll(widget.controller.allMarkers);

      return SafeAMapWidget(
        initialCameraPosition: widget.controller.initialCameraPosition,
        onMapCreated: widget.controller.onMapCreated,
        onMapDisposed: widget.controller.onMapDisposed,
        markers: allMarkers,
        polylines: _cachedPolylines,
        mapType: widget.controller.mapTypeValue.value == 1
            ? MapType.normal
            : MapType.satellite,
        buildingsEnabled: false,
        compassEnabled: true,
        scaleEnabled: true,
        zoomGesturesEnabled: true,
        scrollGesturesEnabled: true,
        rotateGesturesEnabled: true,
        tiltGesturesEnabled: true,
      );
    });
  }

  /// 计算两点之间的距离（米）
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // 地球半径（米）
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

  /// 在轨迹点中找到距离给定坐标最近的点索引
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

  /// 从 stopPoint 中获取位置
  LatLng? _getStopPointPosition(dynamic stopPoint) {
    try {
      if (stopPoint is Map) {
        final lat = stopPoint['lat'] ?? stopPoint['latitude'];
        final lng = stopPoint['lng'] ?? stopPoint['longitude'];
        if (lat != null && lng != null) {
          return LatLng(
            double.parse(lat.toString()),
            double.parse(lng.toString()),
          );
        }
      }
      // 如果是 StayPoint 对象
      if (stopPoint.position != null) {
        return stopPoint.position;
      }
      return null;
    } catch (e) {
      logError('获取停留点位置失败: $e');
      return null;
    }
  }

  Future<void> _updatePolylines() async {
    final newPolylines = <Polyline>{};

    try {
      final trackPoints = widget.controller.trackPoints;
      final stopPoints = widget.controller.stopPoints;

      if (trackPoints.length >= 2) {
        // 加载轨迹线纹理（只加载一次）
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
        
        // 确保纹理已加载
        if (_trackLineTextureRed == null || _trackLineTextureBlue == null) {
          logError('❌ 纹理未完全加载，无法创建轨迹线');
          return;
        }

        // 如果有停留点，按停留点分段
        if (stopPoints.isNotEmpty && trackPoints.length > stopPoints.length) {
          // 构建分段点列表：起点 + 停留点 + 终点
          final allPoints = <LatLng>[];
          
          // 添加起点
          allPoints.add(trackPoints.first);
          
          // 添加所有停留点
          final stopPositions = <LatLng>[];
          for (final stopPoint in stopPoints) {
            final position = _getStopPointPosition(stopPoint);
            if (position != null) {
              stopPositions.add(position);
            }
          }
          
          // 添加终点
          allPoints.add(trackPoints.last);
          
          // 先找到每个点在轨迹点中的索引
          final pointsWithIndex = <_StopPointWithIndex>[];
          for (final point in allPoints) {
            final index = _findNearestPointIndex(trackPoints, point);
            pointsWithIndex.add(_StopPointWithIndex(point: point, index: index));
          }
          
          // 添加停留点（也找到索引）
          for (final position in stopPositions) {
            final index = _findNearestPointIndex(trackPoints, position);
            pointsWithIndex.add(_StopPointWithIndex(point: position, index: index));
          }
          
          // 按索引排序
          pointsWithIndex.sort((a, b) => a.index.compareTo(b.index));
          
          // 去重：如果多个点对应同一个轨迹点索引，只保留第一个
          final uniquePoints = <_StopPointWithIndex>[];
          int? lastIndex;
          for (final pointWithIndex in pointsWithIndex) {
            if (lastIndex == null || pointWithIndex.index != lastIndex) {
              uniquePoints.add(pointWithIndex);
              lastIndex = pointWithIndex.index;
            }
          }
          
          // 确保包含最后一个点（即使索引相同）
          if (pointsWithIndex.isNotEmpty) {
            final last = pointsWithIndex.last;
            if (uniquePoints.isEmpty || uniquePoints.last.index != last.index) {
              uniquePoints.add(last);
            }
          }
          
          logDebug('🎨 去重后有效分段点数: ${uniquePoints.length} (原始: ${allPoints.length + stopPositions.length})');

          // 根据分段点创建轨迹线
          logDebug('🎨 准备创建 ${uniquePoints.length - 1} 段轨迹线');
          for (int i = 0; i < uniquePoints.length - 1; i++) {
            final startPoint = uniquePoints[i];
            final endPoint = uniquePoints[i + 1];
            
            final startIndex = startPoint.index;
            final endIndex = endPoint.index;
            
            logDebug('🎨 分段 $i: startIndex=$startIndex, endIndex=$endIndex');
            
            // 确保索引顺序正确且有效
            if (endIndex > startIndex && endIndex < trackPoints.length) {
              final segmentTrackPoints = trackPoints.sublist(startIndex, endIndex + 1);
              
              if (segmentTrackPoints.length >= 2) {
                // 红蓝交替：偶数索引（0, 2, 4...）用红色，奇数索引（1, 3, 5...）用蓝色
                final isRed = i % 2 == 0;
                final texture = isRed ? _trackLineTextureRed! : _trackLineTextureBlue!;
                logDebug('🎨 分段 $i: 使用${isRed ? "红色" : "蓝色"}纹理, 点数=${segmentTrackPoints.length}');
                
                // 如果分段太长，需要进一步分割（每段最多100个点）
        const int maxPointsPerSegment = 100;
                if (segmentTrackPoints.length <= maxPointsPerSegment) {
                  newPolylines.add(
                    Polyline(
                      points: segmentTrackPoints,
                      width: 8,
                      visible: true,
                      customTexture: texture,
                      capType: CapType.round,
                    ),
                  );
                } else {
                  for (
                    int j = 0;
                    j < segmentTrackPoints.length - 1;
                    j += maxPointsPerSegment - 1
                  ) {
                    final subEndIndex = (j + maxPointsPerSegment).clamp(
                      0,
                      segmentTrackPoints.length,
                    );
                    final subSegmentPoints = segmentTrackPoints.sublist(j, subEndIndex);
                    
                    if (subSegmentPoints.length >= 2) {
                      newPolylines.add(
                        Polyline(
                          points: subSegmentPoints,
                          width: 8,
                          visible: true,
                          customTexture: texture,
                          capType: CapType.round,
                        ),
                      );
                    }
                  }
                }
              } else {
                logWarning('⚠️ 分段 $i: 点数不足，跳过 (${segmentTrackPoints.length})');
              }
            } else {
              logWarning('⚠️ 分段 $i: 索引无效，跳过 (startIndex=$startIndex, endIndex=$endIndex, trackPoints.length=${trackPoints.length})');
            }
          }
          
          logDebug('✅ 轨迹线分段完成，共创建 ${newPolylines.length} 条线段');
        } else {
          // 如果没有停留点，使用默认纹理（红色）
          const int maxPointsPerSegment = 100;
        if (trackPoints.length <= maxPointsPerSegment) {
          newPolylines.add(
            Polyline(
              points: trackPoints,
                width: 8,
                visible: true,
                customTexture: _trackLineTextureRed!,
                capType: CapType.round,
            ),
          );
        } else {
          for (
            int i = 0;
            i < trackPoints.length - 1;
            i += maxPointsPerSegment - 1
          ) {
            final endIndex = (i + maxPointsPerSegment).clamp(
              0,
              trackPoints.length,
            );
            final segmentPoints = trackPoints.sublist(i, endIndex);

            if (segmentPoints.length >= 2) {
              newPolylines.add(
                Polyline(
                  points: segmentPoints,
                    width: 8,
                    visible: true,
                    customTexture: _trackLineTextureRed!,
                    capType: CapType.round,
                ),
              );
              }
            }
          }
        }
      }
    } catch (e) {
      logError('创建轨迹线失败: $e');
    }

    if (mounted) {
      // 使用 WidgetsBinding 确保在 build 完成后更新状态
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
    _cachedPolylines = newPolylines;
          });
        }
      });
    }
  }
}

/// 返回按钮
class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
       
      child: GestureDetector(
        onTap: () => Get.back(),
        child: Center(
          child: Image.asset(
            'assets/images/kissu_mine_back.webp',
            width: 22,
            height: 22,
          ),
        ),
      ),
    );
  }
}

/// 底部播放控制条
class _ReplayControlBar extends StatelessWidget {
  final TrackReplayController controller;

  const _ReplayControlBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 14, right: 14, bottom: 30),
      padding: const EdgeInsets.symmetric(
        horizontal: 0,
        // vertical: 12,
      ).copyWith(left: 5),
      decoration: BoxDecoration(
        color: const Color(0xffF7F7F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 播放控制行：播放按钮 + 进度条
          Row(
            children: [
              // 播放/暂停按钮
              GestureDetector(
                onTap: () async {
                  if (controller.isReplaying.value) {
                    controller.pauseReplay();
                  } else {
                    
                    controller.startReplay();
                  }
                },
                child: Obx(
                  () => Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(13) ,
                     alignment: Alignment.center,
                    child: Image(
                      image: AssetImage(
                        controller.isReplaying.value
                            ? 'assets/3.0/kissu3_pause.webp'
                            : 'assets/3.0/kissu3_play.webp',
                      ),
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              // const SizedBox(width: 8),

              // 进度条
              Expanded(
                child: Obx(() {
                  final progress = controller.replayProgress.value;
                  return SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 7,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                      activeTrackColor: const Color(0xFFFFDC73),
                      inactiveTrackColor: const Color(0xFFffffff),
                      thumbColor: const Color(0xFFFFDC73),
                      overlayColor: const Color(0xFFFFDC73),
                    ),
                    child: Slider(
                      value: progress.clamp(0.0, 1.0),
                      onChanged: (value) {
                        controller.seekReplay(value);
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
