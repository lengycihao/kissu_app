import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:kissu_app/widgets/safe_amap_widget.dart';
import 'package:kissu_app/services/tracking_service.dart';
import 'package:kissu_app/utils/debug_util.dart';
import 'package:kissu_app/widgets/common_back_button.dart';
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
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
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

class _MapWidgetState extends State<_MapWidget> {
  Set<Polyline> _cachedPolylines = {};
  int _polylinesVersion = -1;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 🎯 检查轨迹线是否需要更新
      final currentPolylinesVersion = widget.controller.trackPoints.length;
      if (currentPolylinesVersion != _polylinesVersion) {
        _updatePolylines();
        _polylinesVersion = currentPolylinesVersion;
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

  void _updatePolylines() {
    final newPolylines = <Polyline>{};

    try {
      final trackPoints = widget.controller.trackPoints;

      if (trackPoints.length >= 2) {
        const int maxPointsPerSegment = 100;

        if (trackPoints.length <= maxPointsPerSegment) {
          newPolylines.add(
            Polyline(
              points: trackPoints,
              color: const Color(0xdd639DFF),
              width: 6,
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
                  color: const Color(0xdd639DFF),
                  width: 6,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      DebugUtil.error('创建轨迹线失败: $e');
    }

    _cachedPolylines = newPolylines;
  }
}

/// 返回按钮
class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CommonBackButton(
        onTap: () => Get.back(),
        assetPath: 'assets/images/kissu_mine_back.webp',
        iconSize: 24,
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
                    // 上报轨迹回放按钮埋点（仅在开始播放时）
                    try {
                      await TrackingService.trackFootMoving();
                      DebugUtil.info('✅ 足迹页面-轨迹回放按钮埋点上报成功');
                    } catch (e) {
                      DebugUtil.error('❌ 足迹页面-轨迹回放按钮埋点上报失败: $e');
                    }
                    controller.startReplay();
                  }
                },
                child: Obx(
                  () => Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(13) ,
                    color: Colors.red,
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
