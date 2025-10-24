import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:kissu_app/pages/usage_report/widgets/map_marker_util.dart';
import 'package:kissu_app/utils/debug_util.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';

/// 轨迹页面回放管理器
/// 负责轨迹回放的所有功能，包括播放控制、进度管理、速度控制等
class TrackReplayManager extends GetxController with GetTickerProviderStateMixin {
  /// 播放控制器UI状态 - true显示完整播放器，false显示简单按钮
  final showFullPlayer = false.obs;
  
  /// 播放期间已行走的距离
  final replayDistance = "".obs;
  
  /// 播放时间
  final replayTime = "00:00:00".obs;
  
  /// 播放进度 (0.0 ~ 1.0)
  final replayProgress = 0.0.obs;
  
  /// 当前速度
  final currentSpeed = "".obs;
  
  /// 轨迹回放状态
  final currentReplayIndex = 0.obs;
  final isReplaying = false.obs;
  final replaySpeed = 1.0.obs; // 播放速度倍数
  
  /// 播放头像标记
  final Rx<Marker?> replayAvatarMarker = Rx<Marker?>(null);
  
  /// 当前位置标记
  final Rx<LatLng?> currentPosition = Rx<LatLng?>(null);
  
  /// 动画控制器 - 替代Timer的更好方案
  AnimationController? _replayAnimationController;
  Animation<double>? _replayAnimation;
  
  /// 动画进度 - 用于实时更新进度条
  final animationProgress = 0.0.obs;
  
  /// 播放相关参数
  static const Duration _minReplayDuration = Duration(seconds: 3); // 最短播放时长
  
  /// 播放时间跟踪
  DateTime? _replayStartTime;
  double _cumulativeDistance = 0.0; // 累计距离（米）
  
  /// 外部依赖回调
  Function(LatLng)? onMapMove;
  Function(LatLng)? onMapMoveSmooth;
  Function(List<LatLng>)? onFitMapToTrack; // 新增：将地图视角调整到显示完整轨迹
  String Function()? getCurrentUserAvatar;
  List<LatLng> Function()? getTrackPoints;
  List<dynamic> Function()? getStopPoints;
  
  /// 设置外部依赖
  void setDependencies({
    Function(LatLng)? onMapMove,
    Function(LatLng)? onMapMoveSmooth,
    Function(List<LatLng>)? onFitMapToTrack,
    String Function()? getCurrentUserAvatar,
    List<LatLng> Function()? getTrackPoints,
    List<dynamic> Function()? getStopPoints,
  }) {
    this.onMapMove = onMapMove;
    this.onMapMoveSmooth = onMapMoveSmooth;
    this.onFitMapToTrack = onFitMapToTrack;
    this.getCurrentUserAvatar = getCurrentUserAvatar;
    this.getTrackPoints = getTrackPoints;
    this.getStopPoints = getStopPoints;
  }
  
  /// 获取轨迹点列表
  List<LatLng> get trackPoints => getTrackPoints?.call() ?? [];
  
  /// 获取停留点列表
  List<dynamic> get stopPoints => getStopPoints?.call() ?? [];
  
  /// 重置播放状态
  void resetReplayState() {
    // 停止当前播放
    _replayAnimationController?.stop();
    _replayAnimationController?.reset();
    isReplaying.value = false;
    currentReplayIndex.value = 0;
    replaySpeed.value = 1.0;
    currentPosition.value = null;
    animationProgress.value = 0.0;
    
    // 🎭 清除播放头像标记
    if (replayAvatarMarker.value != null) {
      DebugUtil.info('🧹 清除播放头像标记');
      replayAvatarMarker.value = null;
    }
  }
  
  /// 创建播放头像标记
  Future<void> _createReplayAvatarMarker(LatLng position) async {
    try {
      // 获取当前查看的用户头像
      final avatarUrl = getCurrentUserAvatar?.call() ?? '';
      
      DebugUtil.info('🎭 创建播放头像标记，头像URL: $avatarUrl');
      
      // 使用 MapMarkerUtil 创建圆形头像标记
      final avatarIcon = await MapMarkerUtil.createCircleAvatarMarker(
        avatarUrl,
        size: 180.0, // 🎯 放大三倍（原80.0 → 240.0）
      );
      
      replayAvatarMarker.value = Marker(
        position: position,
        icon: avatarIcon,
        infoWindow: const InfoWindow(title: '', snippet: ''),
      );
      
      DebugUtil.success('✅ 播放头像标记创建成功');
    } catch (e) {
      DebugUtil.error('❌ 创建播放头像标记失败: $e');
      replayAvatarMarker.value = null;
    }
  }
  
  /// 更新播放头像标记位置 - 同步版本（性能优化）
  void _updateReplayAvatarMarkerSync(LatLng position) {
    if (replayAvatarMarker.value == null) {
      // 如果标记不存在，异步创建新标记
      _createReplayAvatarMarker(position);
    } else {
      try {
        // 同步更新现有标记的位置
        final currentMarker = replayAvatarMarker.value!;
        replayAvatarMarker.value = Marker(
          position: position,
          icon: currentMarker.icon,
          infoWindow: currentMarker.infoWindow,
        );
        // 添加调试信息，但降低频率避免日志过多
        if ((currentReplayIndex.value % 20) == 0) {
          DebugUtil.info('🎯 平滑更新头像位置: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}');
        }
      } catch (e) {
        DebugUtil.error('❌ 更新播放头像标记位置失败: $e');
      }
    }
  }
  
  /// 平滑标记更新方法 - 无阈值检查，每帧都更新
  void _updateReplayAvatarMarkerSmooth(LatLng position) {
    if (replayAvatarMarker.value == null) {
      // 如果标记不存在，创建新标记
      _createReplayAvatarMarker(position);
      return;
    }

    try {
      final currentMarker = replayAvatarMarker.value!;
      
      // 计算旋转角度（如果需要方向指示）
      final rotation = _getRotationAngle();
      
      // 使用原有图标，只更新位置和旋转
      replayAvatarMarker.value = Marker(
        position: position,
        icon: currentMarker.icon,
        infoWindow: currentMarker.infoWindow,
        rotation: rotation,
      );
      
      // 降低日志频率（每100帧记录一次）
      if ((currentReplayIndex.value % 100) == 0) {
        DebugUtil.info('🎯 平滑更新头像: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}, 角度: ${(rotation * 180 / pi).toStringAsFixed(1)}°');
      }
    } catch (e) {
      DebugUtil.error('❌ 平滑标记更新失败: $e');
      // 降级到基础更新方法
      _updateReplayAvatarMarkerSync(position);
    }
  }
  
  /// 计算小人的朝向角度
  double _getRotationAngle() {
    if (trackPoints.length < 2 || currentReplayIndex.value >= trackPoints.length - 1) return 0;

    // 确保索引在有效范围内
    final currentIndex = currentReplayIndex.value.clamp(0, trackPoints.length - 2);
    final current = trackPoints[currentIndex];
    final next = trackPoints[currentIndex + 1];

    // 计算角度（弧度）
    final dx = next.longitude - current.longitude;
    final dy = next.latitude - current.latitude;
    final angle = atan2(dy, dx);

    // 返回角度（顺时针旋转，初始朝向北）
    return angle + pi / 2;
  }
  
  /// 公开的获取旋转角度方法
  double getRotationAngle() {
    return _getRotationAngle();
  }
  
  /// 计算两点间距离（米）
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // 地球半径（米）
    final lat1Rad = point1.latitude * pi / 180;
    final lat2Rad = point2.latitude * pi / 180;
    final deltaLat = (point2.latitude - point1.latitude) * pi / 180;
    final deltaLng = (point2.longitude - point1.longitude) * pi / 180;

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLng / 2) * sin(deltaLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }
  
  /// 计算累计距离（从startIndex到endIndex）
  double _calculateCumulativeDistance(int startIndex, int endIndex) {
    if (trackPoints.isEmpty || startIndex >= endIndex) return 0.0;
    
    double distance = 0.0;
    for (int i = startIndex; i < endIndex && i < trackPoints.length - 1; i++) {
      distance += _calculateDistance(trackPoints[i], trackPoints[i + 1]);
    }
    return distance;
  }
  
  /// 计算轨迹总距离（米）
  double _calculateTotalTrackDistance() {
    if (trackPoints.length < 2) return 0.0;
    return _calculateCumulativeDistance(0, trackPoints.length - 1);
  }
  
  /// 根据轨迹长度动态计算播放时间
  Duration _calculateOptimalReplayDuration() {
    if (trackPoints.isEmpty) return _minReplayDuration;
    
    // 计算轨迹总距离（公里）
    final totalDistanceKm = _calculateTotalTrackDistance() / 1000.0;
    
    // 🎯 优化播放时长计算，确保有足够的时间进行平滑插值
    // 根据轨迹点数量和距离综合计算
    final pointCount = trackPoints.length;
    
    // 基础时长：确保每个点至少有40ms的时间进行插值
    final baseSeconds = pointCount * 0.04;
    
    // 距离因子：每公里增加1秒
    final distanceSeconds = totalDistanceKm * 1.0;
    
    // 综合计算，取较大值确保平滑
    final totalSeconds = baseSeconds > distanceSeconds ? baseSeconds : distanceSeconds;
    
    // 限制在合理范围内：最短3秒，最长60秒
    final clampedSeconds = totalSeconds.clamp(3.0, 60.0);
    
    // 应用播放速度倍数
    final adjustedSeconds = clampedSeconds / replaySpeed.value;
    
    DebugUtil.info('📏 播放时长计算: 点数=$pointCount, 距离=${totalDistanceKm.toStringAsFixed(2)}km, '
        '基础时长=${baseSeconds.toStringAsFixed(1)}s, 最终时长=${adjustedSeconds.toStringAsFixed(1)}s');
    
    return Duration(milliseconds: (adjustedSeconds * 1000).round());
  }
  
  /// 更新播放状态（距离、时间、速度，但不更新进度因为已实时更新）
  void _updateReplayStatus() {
    // 更新距离显示
    final distanceKm = _cumulativeDistance / 1000;
    replayDistance.value = distanceKm >= 1 
        ? "${distanceKm.toStringAsFixed(1)}公里" 
        : "${_cumulativeDistance.toInt()}米";
    
    // 更新时间显示
    if (_replayStartTime != null) {
      final duration = DateTime.now().difference(_replayStartTime!);
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      final seconds = duration.inSeconds % 60;
      replayTime.value = "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    }
    
    // 🎯 不再在这里更新播放进度，因为已经在定时器中实时更新以保持平滑
    // 只在 seekToIndex 时才需要更新进度
    
    // 更新当前速度（计算最近两个点之间的速度）
    if (trackPoints.length > 1 && currentReplayIndex.value > 0 && currentReplayIndex.value < trackPoints.length) {
      final prevPoint = trackPoints[currentReplayIndex.value - 1];
      final currentPoint = trackPoints[currentReplayIndex.value];
      final distance = _calculateDistance(prevPoint, currentPoint);
      // 假设每个点之间的时间间隔约为1秒
      final speedKmh = (distance / 1000) * 3600; // 转换为公里/小时
      currentSpeed.value = "${speedKmh.toStringAsFixed(1)}km/h";
    }
  }
  
  /// 跳转到指定索引（用于进度条拖动）
  void seekToIndex(int newIndex) {
    if (trackPoints.isEmpty) return;
    
    final safeIndex = newIndex.clamp(0, trackPoints.length - 1);
    currentReplayIndex.value = safeIndex;
    
    // 更新当前位置
    currentPosition.value = trackPoints[safeIndex];
    onMapMove?.call(trackPoints[safeIndex]);
    
    // 如果存在播放头像标记，更新其位置
    if (replayAvatarMarker.value != null) {
      _updateReplayAvatarMarkerSync(trackPoints[safeIndex]);
    }
    
    // 更新累计距离
    _cumulativeDistance = _calculateCumulativeDistance(0, safeIndex);
    
    // 手动更新进度
    replayProgress.value = safeIndex / (trackPoints.length - 1).clamp(1, trackPoints.length);
    
    // 如果正在播放，更新时间基准
    if (isReplaying.value && _replayStartTime != null) {
      // 根据当前进度调整开始时间，让时间显示更准确
      final progress = safeIndex / (trackPoints.length - 1);
      final optimalDuration = _calculateOptimalReplayDuration();
      final currentSeconds = (progress * optimalDuration.inSeconds);
      _replayStartTime = DateTime.now().subtract(Duration(milliseconds: (currentSeconds * 1000).round()));
    }
    
    _updateReplayStatus();
  }
  
  /// 开始回放
  void startReplay() {
    if (trackPoints.isEmpty) {
      CustomToast.show(Get.context!, '暂无轨迹数据可回放');
      return;
    }

    // 如果当前已经播放完成，重置到开始
    if (currentReplayIndex.value >= trackPoints.length - 1) {
      currentReplayIndex.value = 0;
      _cumulativeDistance = 0.0;
      replayProgress.value = 0.0;
      animationProgress.value = 0.0;
    }
    
    print('🎬 开始播放回放...');
    
    // 停止之前的动画
    _replayAnimationController?.dispose();
    
    isReplaying.value = true;
    showFullPlayer.value = true; // 显示完整播放器
    print('🎬 showFullPlayer = ${showFullPlayer.value}');

    // 确保currentReplayIndex在有效范围内
    currentReplayIndex.value = currentReplayIndex.value.clamp(0, trackPoints.length - 1);

    // 🎯 新增：调整地图视角以显示完整轨迹
    DebugUtil.info('🗺️ 调整地图视角以显示完整轨迹');
    onFitMapToTrack?.call(trackPoints);

    // 设置初始位置
    if (currentPosition.value == null && trackPoints.isNotEmpty) {
      currentPosition.value = trackPoints[currentReplayIndex.value];
    }
    
    // 创建播放头像标记
    if (currentPosition.value != null) {
      _createReplayAvatarMarker(currentPosition.value!);
    }
    
    // 初始化播放时间跟踪
    _replayStartTime = DateTime.now();
    _cumulativeDistance = _calculateCumulativeDistance(0, currentReplayIndex.value);
    _updateReplayStatus();

    // 🎯 创建动画控制器，根据轨迹长度动态计算播放时间
    final optimalDuration = _calculateOptimalReplayDuration();
    _replayAnimationController = AnimationController(
      duration: optimalDuration,
      vsync: this,
    );

    // 创建动画，从当前进度到1.0
    final startProgress = currentReplayIndex.value / (trackPoints.length - 1).clamp(1, trackPoints.length);
    _replayAnimation = Tween<double>(
      begin: startProgress,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _replayAnimationController!,
      curve: Curves.linear, // 保持线性播放，平滑处理在插值函数中进行
    ));

    // 初始化动画进度
    animationProgress.value = startProgress;
    DebugUtil.info('🎯 动画初始进度: ${animationProgress.value}');

    // 监听动画值变化
    _replayAnimation!.addListener(_onReplayAnimationUpdate);
    
    // 监听动画完成
    _replayAnimation!.addStatusListener(_onReplayAnimationStatus);

    // 开始动画
    _replayAnimationController!.forward();
    DebugUtil.success('🎬 轨迹回放已启动，总时长: ${optimalDuration.inSeconds}秒');
  }
  
  /// 动画更新回调
  void _onReplayAnimationUpdate() {
    if (_replayAnimation == null || trackPoints.isEmpty) return;
    
    // 获取当前动画进度（0-1）
    final rawProgress = _replayAnimation!.value;
    
    // 🎯 应用多级平滑处理
    final smoothProgress = _applyMultiLevelSmoothing(rawProgress);
    
    // 更新实时进度（用于进度条显示）
    animationProgress.value = smoothProgress;
    replayProgress.value = smoothProgress;
    
    // 计算当前应该在哪个点（支持小数索引）
    final floatIndex = smoothProgress * (trackPoints.length - 1);
    final currentIdx = floatIndex.floor();
    final nextIdx = (currentIdx + 1).clamp(0, trackPoints.length - 1);
    
    // 更新整数索引（用于停留点检测等）
    if (currentIdx != currentReplayIndex.value) {
      currentReplayIndex.value = currentIdx;
      _checkPassingStopPoint(currentIdx);
    }
    
    // 🎯 插值计算平滑位置
    if (currentIdx < trackPoints.length - 1) {
      final t = floatIndex - currentIdx; // 插值参数（0-1）
      final currentPoint = trackPoints[currentIdx];
      final nextPoint = trackPoints[nextIdx];
      
      // 使用线性插值计算中间位置
      final interpolatedLat = currentPoint.latitude + (nextPoint.latitude - currentPoint.latitude) * t;
      final interpolatedLng = currentPoint.longitude + (nextPoint.longitude - currentPoint.longitude) * t;
      final interpolatedPosition = LatLng(interpolatedLat, interpolatedLng);
      
      // 更新当前位置
      currentPosition.value = interpolatedPosition;
      
      // 🎯 移除相机跟随，保持固定视角显示完整轨迹
      // onMapMoveSmooth?.call(interpolatedPosition); // 已禁用
      
      // 🎯 平滑更新播放头像位置
      _updateReplayAvatarMarkerSmooth(interpolatedPosition);
    } else {
      // 最后一个点
      currentPosition.value = trackPoints.last;
      // onMapMove?.call(trackPoints.last); // 已禁用
      _updateReplayAvatarMarkerSync(trackPoints.last);
    }
    
    // 更新累计距离（基于实际索引）
    _cumulativeDistance = _calculateCumulativeDistance(0, currentIdx) +
        (currentIdx < trackPoints.length - 1 
            ? _calculateDistance(trackPoints[currentIdx], currentPosition.value!) * (floatIndex - currentIdx)
            : 0);
    
    // 更新状态显示
    _updateReplayStatus();
  }
  
  /// 动画状态监听
  void _onReplayAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // 播放完成
      DebugUtil.info('🎯 轨迹回放完成');
      isReplaying.value = false;
      _showReplayCompleteMessage();
      
      // 确保进度为100%
      replayProgress.value = 1.0;
      animationProgress.value = 1.0;
      currentReplayIndex.value = trackPoints.length - 1;
      
      // 确保最后位置正确
      if (trackPoints.isNotEmpty) {
        currentPosition.value = trackPoints.last;
        _updateReplayAvatarMarkerSync(trackPoints.last);
      }
      
      _updateReplayStatus();
    }
  }
  
  /// 应用高级平滑处理，减少闪现效果
  double _applyAdvancedSmoothing(double t) {
    // 使用五次Hermite插值，提供更平滑的过渡
    final t2 = t * t;
    final t3 = t2 * t;
    return 6 * t3 * t2 - 15 * t2 * t2 + 10 * t3;
  }
  
  /// 应用贝塞尔曲线平滑处理
  double _applyCubicBezierSmoothing(double t) {
    // 使用三次贝塞尔曲线 (0.25, 0.1, 0.25, 1.0) 提供自然的缓动效果
    if (t <= 0) return 0;
    if (t >= 1) return 1;
    
    // 简化的三次贝塞尔计算
    final p0 = 0.0;
    final p1 = 0.25;
    final p2 = 0.75;
    final p3 = 1.0;
    
    final t2 = t * t;
    final t3 = t2 * t;
    final mt = 1 - t;
    final mt2 = mt * mt;
    final mt3 = mt2 * mt;
    
    return mt3 * p0 + 3 * mt2 * t * p1 + 3 * mt * t2 * p2 + t3 * p3;
  }
  
  /// 多级平滑处理 - 结合多种算法
  double _applyMultiLevelSmoothing(double t) {
    // 第一级：五次Hermite插值
    final smooth1 = _applyAdvancedSmoothing(t);
    // 第二级：贝塞尔曲线
    final smooth2 = _applyCubicBezierSmoothing(smooth1);
    // 混合原始值和平滑值，保持一定的响应性
    return t * 0.3 + smooth2 * 0.7;
  }
  
  /// 检查是否经过停留点
  void _checkPassingStopPoint(int currentIndex) {
    if (currentIndex >= trackPoints.length || stopPoints.isEmpty) return;
    
    final currentPoint = trackPoints[currentIndex];
    
    // 检查是否接近任何停留点
    for (final stopPoint in stopPoints) {
      final distance = _calculateDistance(
        currentPoint,
        LatLng(stopPoint.lat, stopPoint.lng),
      );
      
      // 如果距离小于50米，认为经过了停留点
      if (distance < 50) {
        // 可以在这里添加经过停留点的效果
        DebugUtil.info('经过停留点: ${stopPoint.address}');
        break;
      }
    }
  }
  
  /// 显示回放完成消息
  void _showReplayCompleteMessage() {
    // CustomToast.show(
    //   Get.context!,
    //   '轨迹回放完成',
    // );
  }
  
  /// 暂停
  void pauseReplay() {
    isReplaying.value = false;
    _replayAnimationController?.stop();
    DebugUtil.info('轨迹回放已暂停');
  }
  
  /// 停止并重置
  void stopReplay() {
    isReplaying.value = false;
    _replayAnimationController?.stop();
    _replayAnimationController?.reset();
    
    // 重置到起点
    currentReplayIndex.value = 0;
    replayProgress.value = 0.0;
    animationProgress.value = 0.0;
    _cumulativeDistance = 0.0;
    replayTime.value = "00:00:00";
    replayDistance.value = "0米";
    currentSpeed.value = "0.0km/h";
    
    if (trackPoints.isNotEmpty) {
      currentPosition.value = trackPoints.first;
      onMapMove?.call(trackPoints.first);
      
      // 更新播放头像位置
      if (replayAvatarMarker.value != null) {
        _updateReplayAvatarMarkerSync(trackPoints.first);
      }
    }
    
    _replayStartTime = null;
    DebugUtil.info('轨迹回放已停止并重置');
  }
  
  /// 关闭播放器并重置动画
  void closePlayer() {
    stopReplay(); // 停止当前播放
    showFullPlayer.value = false; // 隐藏播放器UI
    
    // 清除播放头像标记
    if (replayAvatarMarker.value != null) {
      DebugUtil.info('🧹 关闭播放器时清除播放头像标记');
      replayAvatarMarker.value = null;
    }
    
    // 恢复显示当前位置标记
    currentPosition.value = null;
    
    DebugUtil.info('播放器已关闭');
  }
  
  /// 切换播放速度（快进）
  void toggleSpeed() {
    if (replaySpeed.value == 1.0) {
      replaySpeed.value = 2.0;
    } else if (replaySpeed.value == 2.0) {
      replaySpeed.value = 4.0;
    } else {
      replaySpeed.value = 1.0;
    }
    
    // 如果正在播放，重新计算动画时长
    if (isReplaying.value && _replayAnimationController != null) {
      final remainingProgress = 1.0 - animationProgress.value;
      final optimalDuration = _calculateOptimalReplayDuration();
      final remainingDuration = Duration(
        milliseconds: (optimalDuration.inMilliseconds * remainingProgress).round(),
      );
      
      // 更新动画控制器的时长
      _replayAnimationController!.duration = remainingDuration;
    }
    
    DebugUtil.info('播放速度切换为: ${replaySpeed.value}x');
  }
  
  /// 根据进度跳转（用于进度条拖动）
  void seekReplay(double progress) {
    if (trackPoints.isEmpty) return;
    
    final targetIndex = (progress * (trackPoints.length - 1)).round();
    seekToIndex(targetIndex);
    
    // 如果正在播放，更新动画
    if (isReplaying.value && _replayAnimationController != null) {
      _replayAnimationController!.value = progress;
    }
  }
  
  @override
  void onClose() {
    _replayAnimationController?.dispose();
    super.onClose();
  }
}
