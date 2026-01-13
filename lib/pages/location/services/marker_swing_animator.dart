import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';

/// 地图标记摆动动画管理器
/// 
/// 负责管理地图标记的摆动动画效果
class MarkerSwingAnimator {
  Timer? _swingTimer;
  final swingAngle = 0.0.obs;
  
  AMapController? _mapController;
  BitmapDescriptor? _myIcon;
  BitmapDescriptor? _partnerIcon;
  Rx<LatLng?>? _myLocation;
  Rx<LatLng?>? _partnerLocation;

  /// 初始化动画器
  void init({
    required AMapController? mapController,
    required BitmapDescriptor? myIcon,
    required BitmapDescriptor? partnerIcon,
    required Rx<LatLng?> myLocation,
    required Rx<LatLng?> partnerLocation,
  }) {
    _mapController = mapController;
    _myIcon = myIcon;
    _partnerIcon = partnerIcon;
    _myLocation = myLocation;
    _partnerLocation = partnerLocation;
  }

  /// 更新图标
  void updateIcons({
    BitmapDescriptor? myIcon,
    BitmapDescriptor? partnerIcon,
  }) {
    if (myIcon != null) _myIcon = myIcon;
    if (partnerIcon != null) _partnerIcon = partnerIcon;
  }

  /// 开始摆动动画
  void start() {
    stop();

    // 🚀 修复：检查地图控制器是否已初始化，避免Channel未初始化错误
    if (_mapController == null) {
      logDebug('⚠️ MapController未初始化，跳过摆动动画');
      return;
    }

    if (_myIcon == null && _partnerIcon == null) {
      return;
    }

    int timeStep = 0;
    _swingTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      final time = timeStep * 0.08;
      final period = 2 * math.pi;
      final normalizedTime = (time % period) / period;
      final angle = (normalizedTime < 0.5)
          ? (-12.0 + normalizedTime * 48.0)
          : (36.0 - normalizedTime * 48.0);

      swingAngle.value = angle;
      Future.microtask(() => _updateMarkersRotation());
      timeStep++;
    });
  }

  /// 停止摆动动画
  void stop() {
    if (_swingTimer == null) return;

    _swingTimer?.cancel();
    _swingTimer = null;

    // 🚀 修复：只有在地图控制器已初始化时才执行停止动画，避免Channel未初始化错误
    if (_mapController == null) {
      swingAngle.value = 0.0;
      return;
    }

    final currentAngle = swingAngle.value;
    if (currentAngle.abs() > 0.5) {
      int steps = 0;
      const maxSteps = 8;
      Timer.periodic(const Duration(milliseconds: 30), (timer) {
        steps++;
        final progress = steps / maxSteps;
        final easeOut = 1 - math.pow(1 - progress, 3);
        swingAngle.value = currentAngle * (1 - easeOut);

        Future.microtask(() => _updateMarkersRotation());

        if (steps >= maxSteps) {
          timer.cancel();
          swingAngle.value = 0.0;
          _updateMarkersRotation();
        }
      });
    } else {
      swingAngle.value = 0.0;
      _updateMarkersRotation();
    }
  }

  /// 更新标记旋转角度
  void _updateMarkersRotation() async {
    if (_mapController == null) return;

    try {
      if (_myLocation?.value != null && _myIcon != null) {
        final myMarker = Marker(
          position: _myLocation!.value!,
          rotation: swingAngle.value,
          icon: _myIcon!,
          anchor: const Offset(0.5, 1.0),
        );
        myMarker.setIdForCopy('my_marker');
        await _mapController!.updateMarker(myMarker);
      }

      if (_partnerLocation?.value != null && _partnerIcon != null) {
        final partnerMarker = Marker(
          position: _partnerLocation!.value!,
          rotation: -swingAngle.value,
          icon: _partnerIcon!,
          anchor: const Offset(0.5, 1.0),
        );
        partnerMarker.setIdForCopy('partner_marker');
        await _mapController!.updateMarker(partnerMarker);
      }
    } catch (e) {
      // 🚀 修复：静默处理Channel未初始化错误（地图初始化期间的预期状态）
      final errorMsg = e.toString();
      if (errorMsg.contains('Channel未初始化') || errorMsg.contains('Bad state')) {
        // 静默处理，这是地图初始化期间的正常状态
        return;
      }
      // 其他错误才输出日志
      logError('Update marker rotation error: $e');
    }
  }

  /// 清理资源
  void dispose() {
    stop();
    _swingTimer?.cancel();
    _swingTimer = null;
  }
}

