import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:kissu_app/pages/track/stay_point.dart';
import 'package:latlong2/latlong.dart';

class LocationController extends GetxController {
  /// 停留统计
  final stayCount = 5.obs;
  final stayDuration = "3小时55分钟".obs;
  final moveDistance = "9.63km".obs;

  /// 最近 7 天
  final recentDays =
      List.generate(7, (i) {
        final date = DateTime.now().subtract(Duration(days: i));
        return "${date.month}-${date.day}";
      }).obs;

  final selectedDayIndex = 0.obs;
  final sheetPercent = 0.4.obs;

  /// 地图
  final MapController mapController = MapController();

  /// 轨迹点（这里用停留点生成的路线，你可以替换为接口数据）
  late final List<LatLng> trackPoints =
      stayPoints.map((e) => e.position).toList();

  /// 停留点 marker 缓存
  late final List<Marker> stayMarkers = _buildStayMarkers();

  /// 地图配置缓存
  late final MapOptions mapOptions = MapOptions(
    initialCenter:
        trackPoints.isNotEmpty ? trackPoints.first : const LatLng(30.0, 120.0),
    initialZoom: 16.0,
    maxZoom: 18, // 最大缩放
    minZoom: 10, // 最小缩放
  );

  /// 轨迹回放状态
  final currentReplayIndex = 0.obs;
  final isReplaying = false.obs; // 改为响应式变量
  Timer? _replayTimer;

  /// 平滑动画相关
  final currentPosition = Rx<LatLng?>(null);
  final animationProgress = 0.0.obs;
  static const int animationSteps = 20; // 每两个点之间的插值步数
  int _currentStep = 0;

  final List<StopRecord> stopRecords = [
    StopRecord(
      time: '18:30',
      leftTime: "当前",
      location: '浙江省杭州市上城区彭埠街道云峰家园附近',
      stayDuration: '停留中 已停留 51 分钟停留中 已停留 51 分钟',
      isCurrent: true,
    ),
    StopRecord(
      time: '18:17~18:30',
      leftTime: "21:52",
      location: '浙江省杭州市上城区四季青街道杭州市上城区仁本职业培训学校中豪·湘和国际附近',
      stayDuration: '停留 13 分钟 41 秒',
    ),
    StopRecord(
      time: '17:46~18:05',
      leftTime: "21:52",
      location: '浙江省杭州市上城区彭埠街道新塘路维萨新筑附近',
      stayDuration: '停留 18 分钟 51 秒',
    ),
    StopRecord(
      time: '17:27',
      leftTime: "21:52",
      location: '浙江省杭州市上城区四季青街道五福新村（景芳路）天虹购物中心 B 座附近',
      stayDuration: '',
    ),
  ];

  List<Marker> _buildStayMarkers() {
    return stayPoints.map((point) {
      return Marker(
        point: point.position,
        width: 50,
        height: 50,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFE91E63),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '${point.index}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }).toList();
  }

  /// 获取当前所有 markers
  List<Marker> get allMarkers {
    final markers = List<Marker>.from(stayMarkers);
    if (currentPosition.value != null) {
      // 创建一个新的 marker 在当前位置
      markers.add(
        Marker(
          point: currentPosition.value!,
          width: 40,
          height: 40,
          child: Transform.rotate(
            angle: _getRotationAngle(),
            child: const Icon(
              Icons.directions_walk, // 改为行走的小人图标
              color: Colors.blue,
              size: 32,
            ),
          ),
        ),
      );
    }
    return markers;
  }

  /// 计算小人的朝向角度
  double _getRotationAngle() {
    if (currentReplayIndex.value >= trackPoints.length - 1) return 0;

    final current = trackPoints[currentReplayIndex.value];
    final next = trackPoints[currentReplayIndex.value + 1];

    final dx = next.longitude - current.longitude;
    final dy = next.latitude - current.latitude;

    return atan2(dx, dy);
  }

  /// 在两点之间进行插值
  LatLng _interpolatePosition(LatLng start, LatLng end, double t) {
    final lat = start.latitude + (end.latitude - start.latitude) * t;
    final lng = start.longitude + (end.longitude - start.longitude) * t;
    return LatLng(lat, lng);
  }

  /// 开始回放
  void startReplay() {
    if (trackPoints.isEmpty) return;
    isReplaying.value = true;
    _currentStep = 0;

    // 设置初始位置
    if (currentPosition.value == null && trackPoints.isNotEmpty) {
      currentPosition.value = trackPoints[currentReplayIndex.value];
    }

    _replayTimer?.cancel();
    // 更快的定时器，实现平滑动画
    _replayTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (currentReplayIndex.value < trackPoints.length - 1) {
        final startPoint = trackPoints[currentReplayIndex.value];
        final endPoint = trackPoints[currentReplayIndex.value + 1];

        // 计算插值进度
        final progress = _currentStep / animationSteps;

        // 更新当前位置（插值）
        currentPosition.value = _interpolatePosition(
          startPoint,
          endPoint,
          progress,
        );

        // 平滑移动地图视角
        mapController.move(currentPosition.value!, mapController.camera.zoom);

        _currentStep++;

        // 到达下一个点
        if (_currentStep >= animationSteps) {
          _currentStep = 0;
          currentReplayIndex.value++;
        }
      } else {
        // 到达终点
        currentPosition.value = trackPoints.last;
        stopReplay();
      }
    });
  }

  /// 暂停
  void pauseReplay() {
    isReplaying.value = false;
    _replayTimer?.cancel();
  }

  /// 停止并重置
  void stopReplay() {
    isReplaying.value = false;
    _replayTimer?.cancel();
    currentReplayIndex.value = 0;
    _currentStep = 0;
    // 重置位置
    if (trackPoints.isNotEmpty) {
      currentPosition.value = trackPoints.first;
      mapController.move(trackPoints.first, mapController.camera.zoom);
    }
  }

  @override
  void onClose() {
    _replayTimer?.cancel();
    mapController.dispose();
    super.onClose();
  }
}
