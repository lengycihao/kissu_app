import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:get/get.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/pages/usage_report/widgets/map_marker_util.dart';
 import 'package:kissu_app/widgets/custom_toast_widget.dart';
import 'package:kissu_app/pages/location/services/marker_builder.dart';

/// 轨迹页面回放管理器
/// 负责轨迹回放的所有功能，包括播放控制、进度管理、速度控制等
class TrackReplayManager extends GetxController {
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

  /// 🎯 相机跟随控制 - 是否在回放时跟随播放头像移动相机视角
  final enableCameraFollow = false.obs; // 默认关闭相机跟随

  /// 播放头像标记
  final Rx<Marker?> replayAvatarMarker = Rx<Marker?>(null);

  /// 🎯 播放底座标记（头像下面的旋转底座）
  final Rx<Marker?> replayPedestalMarker = Rx<Marker?>(null);

  /// 当前位置标记
  final Rx<LatLng?> currentPosition = Rx<LatLng?>(null);

  /// 🎯 底座相关
  late final MarkerBuilder _markerBuilder = MarkerBuilder();
  BitmapDescriptor? _cachedPedestalIcon; // 缓存的底座icon
  ui.Offset? _cachedAnchor; // 缓存的锚点
  bool _isCreatingPedestal = false; // 🎯 防止重复创建底座

  /// 🎯 兼容性属性 - 为了保持与现有代码的兼容性
  RxDouble get animationProgress => replayProgress;

  /// 🎯 高精度定时器替代AnimationController，确保60fps流畅播放
  Timer? _replayTimer;

  /// 播放相关参数 - 基于距离的匀速移动
  static const Duration _frameInterval = Duration(
    milliseconds: 50,
  ); // 20fps更新频率，原生动画填充中间帧实现60fps视觉效果

  /// 🎯 匀速移动参数
  DateTime? _playbackStartTime;
  Duration? _totalPlaybackDuration;
  double _uniformSpeed = 0.0; // 匀速移动速度（米/秒）
  double _totalDistance = 0.0; // 轨迹总距离（米）

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

  /// 地图控制器（用于原生动画）
  AMapController? _mapController;

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

  /// 设置地图控制器（用于原生动画）
  void setMapController(AMapController? controller) {
    _mapController = controller;
  }

  /// 地图PlatformView销毁时的清理逻辑
  void onMapDisposed() {
    logDebug('🧹 轨迹播放：地图控制器已销毁，停止回放定时器');
    _mapController = null;
    _replayTimer?.cancel();
    _replayTimer = null;
  }

  /// 获取轨迹点列表
  List<LatLng> get trackPoints => getTrackPoints?.call() ?? [];

  /// 获取停留点列表
  List<dynamic> get stopPoints => getStopPoints?.call() ?? [];

  /// 重置播放状态
  void resetReplayState() {
    // 停止当前播放
    _replayTimer?.cancel();
    _replayTimer = null;
    isReplaying.value = false;
    currentReplayIndex.value = 0;
    replaySpeed.value = 1.0;
    currentPosition.value = null;
    replayProgress.value = 0.0;

    // 🎯 重置播放状态
    _playbackStartTime = null;
    _totalPlaybackDuration = null;

    // 🎭 清除播放头像和底座标记
    if (replayAvatarMarker.value != null) {
      logDebug('🧹 清除播放头像标记');
      replayAvatarMarker.value = null;
    }
    if (replayPedestalMarker.value != null) {
      logDebug('🧹 清除播放底座标记');
      replayPedestalMarker.value = null;
    }

    // 🎯 重置底座创建标志
    _isCreatingPedestal = false;
  }

  /// 创建播放头像标记
  Future<void> _createReplayAvatarMarker(LatLng position) async {
    try {
      // 获取当前查看的用户头像
      final avatarUrl = getCurrentUserAvatar?.call() ?? '';

      logDebug('🎭 创建播放头像标记，头像URL: $avatarUrl');

      // 🔧 根据设备像素比计算头像尺寸，确保在所有设备上显示一致
      final dpr = ui.window.devicePixelRatio;
      final screenWidth = ui.window.physicalSize.width / dpr;
      const designWidth = 375.0;
      const designAvatarSize = 60.0; // 设计稿头像尺寸
      final screenScale = screenWidth / designWidth;
      final avatarSize = designAvatarSize * screenScale * dpr;
      logDebug('📍 回放头像marker尺寸: $avatarSize (dpr=$dpr, screenScale=$screenScale)');

      // 使用 MapMarkerUtil 创建圆形头像标记（与定位页面一致的双层边框）
      final avatarIcon = await MapMarkerUtil.createCircleAvatarMarker(
        avatarUrl,
        size: avatarSize,
      );

      final marker = Marker(
        position: position,
        icon: avatarIcon,
        infoWindow: const InfoWindow(title: '', snippet: ''),
        zIndex: 1000.0, // 🎯 确保播放头像在停留点之上显示
      );
      marker.setIdForCopy('replay_avatar_marker'); // 🎯 设置ID用于动画控制
      replayAvatarMarker.value = marker;

      logDebug('✅ 播放头像标记创建成功');

      // 🎯 延迟启动iOS原版呼吸动画（等待marker添加到地图）
      Future.delayed(const Duration(milliseconds: 300), () {
        _startReplayAvatarAnimation();
      });
    } catch (e) {
      logError('❌ 创建播放头像标记失败: $e');
      replayAvatarMarker.value = null;
    }
  }

  /// 🎯 使用原生平滑移动API更新播放头像标记位置（性能优化）
  void _updateReplayAvatarMarkerSync(LatLng position) async {
    if (replayAvatarMarker.value == null) {
      // 如果标记不存在，异步创建新标记
      _createReplayAvatarMarker(position);
      return;
    }
    
    // 🎯 关键：完全依赖原生动画，不更新任何会触发UI重建的value
    if (_mapController == null) {
      logWarning('⚠️ MapController未初始化，跳过marker更新');
      return;
    }
    
    try {
      // 🎯 使用原生平滑移动API，让原生层处理所有动画
      // 不await，避免阻塞，让原生层异步处理
      _mapController!.moveMarkerSmoothly(
        markerId: 'replay_avatar_marker',
        targetPosition: position,
        duration: _frameInterval.inMilliseconds,
      );
      
      // 🎯 关键：不更新currentPosition.value，避免触发Obx重建
      // 原生动画会自动处理marker的位置更新
      
      // 降低日志频率
      if ((currentReplayIndex.value % 100) == 0) {
        logDebug(
          '🎯 原生平滑移动头像: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
        );
      }
    } catch (e) {
      logError('❌ 原生平滑移动失败: $e');
    }
  }

  /// 🎯 创建播放底座标记
  Future<void> _createReplayPedestalMarker(LatLng position) async {
    try {
      // 创建底座icon（仅一次）
      if (_cachedPedestalIcon == null) {
        _cachedPedestalIcon = await _markerBuilder.createPedestalMarker(
          pedestalAsset: 'assets/images/kissu_location_run.webp',
          size: 800.0,
        );
        _cachedAnchor = const ui.Offset(0.5, 0.5); // 中心点为锚点
      }

      // 计算旋转角度（基于运动方向）
      final rotation = _calculateMovementRotation(position);

      final marker = Marker(
        position: position,
        icon: _cachedPedestalIcon!,
        anchor: _cachedAnchor ?? const ui.Offset(0.5, 0.5), // 中心旋转
        rotation: rotation,
        zIndex: 999.0, // 底座在头像下方
        clickable: false,
      );
      marker.setIdForCopy('replay_pedestal_marker');
      replayPedestalMarker.value = marker;

      logDebug('✅ 播放底座标记创建成功，旋转角度: $rotation');
    } catch (e) {
      logError('❌ 创建播放底座标记失败: $e');
      replayPedestalMarker.value = null;
    }
  }

  /// 🎯 使用原生API更新播放底座标记位置和旋转（同步版本）
  void _updateReplayPedestalMarkerSync(LatLng position) async {
    if (replayPedestalMarker.value == null && _cachedPedestalIcon == null) {
      // 🎯 只创建一次，防止重复异步创建
      if (!_isCreatingPedestal) {
        _isCreatingPedestal = true;
        _createReplayPedestalMarker(position).then((_) {
          _isCreatingPedestal = false;
        });
      }
      return;
    }
    
    if (_cachedPedestalIcon == null || _mapController == null) {
      return;
    }
    
    try {
      // 计算旋转角度（基于运动方向）
      final rotation = _calculateMovementRotation(position);

      // 🎯 使用原生平滑移动API，不await避免阻塞
      _mapController!.moveMarkerSmoothly(
        markerId: 'replay_pedestal_marker',
        targetPosition: position,
        duration: _frameInterval.inMilliseconds,
        rotation: rotation,
      );
      
      // 降低日志频率
      if ((currentReplayIndex.value % 100) == 0) {
        logDebug('🎯 原生平滑移动底座，旋转: ${rotation.toStringAsFixed(1)}°');
      }
    } catch (e) {
      logError('❌ 更新播放底座标记失败: $e');
    }
  }

  /// 🎯 计算固定指向终点的角度
  double _calculateMovementRotation(LatLng position) {
    final trackPts = trackPoints;
    if (trackPts.length < 1) return 0.0;

    // 🎯 固定指向轨迹终点
    final endPoint = trackPts.last;

    final dx = endPoint.longitude - position.longitude;
    final dy = endPoint.latitude - position.latitude;

    // 计算角度（atan2(y, x) 返回的是从东方向开始逆时针的角度）
    // 参数顺序：第一个是y（纬度差），第二个是x（经度差）
    var angle = math.atan2(dy, dx) * 180.0 / math.pi;

    // atan2返回的角度：正东=0°，正北=90°，正西=180°/-180°，正南=-90°
    // 转换为地图角度：正北=0°，正东=90°，正南=180°，正西=270°
    angle = 90.0 - angle;

    // 🎯 确保角度在0-360范围内
    if (angle < 0) {
      angle += 360.0;
    }

    // 🎯 底座图片默认指向左方（西方270度），需要加90度偏移
    // 因为地图角度0是正北，而底座图片默认朝左(西方)
    angle += 90.0;
    if (angle >= 360.0) {
      angle -= 360.0;
    }

    return angle;
  }

  /// 🎯 基于插值位置计算小人的朝向角度（iOS方案）
  double _getRotationAngle() {
    if (trackPoints.length < 2) return 0;

    // 🎯 获取当前插值位置和下一个预测位置来计算朝向
    final currentProgress = replayProgress.value;
    final nextProgress = (currentProgress + 0.01).clamp(0.0, 1.0); // 向前预测一小步

    final currentPos = _calculateTimeBasedInterpolatedPosition(currentProgress);
    final nextPos = _calculateTimeBasedInterpolatedPosition(nextProgress);

    if (currentPos == null || nextPos == null) return 0;

    // 计算移动方向角度（弧度）
    final dx = nextPos.longitude - currentPos.longitude;
    final dy = nextPos.latitude - currentPos.latitude;

    if (dx == 0 && dy == 0) return 0; // 没有移动

    final angle = math.atan2(dy, dx);

    // 返回角度（顺时针旋转，初始朝向北）
    return angle + math.pi / 2;
  }

  /// 公开的获取旋转角度方法
  double getRotationAngle() {
    return _getRotationAngle();
  }

  /// 计算两点间距离（米）
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // 地球半径（米）
    final lat1Rad = point1.latitude * math.pi / 180;
    final lat2Rad = point2.latitude * math.pi / 180;
    final deltaLat = (point2.latitude - point1.latitude) * math.pi / 180;
    final deltaLng = (point2.longitude - point1.longitude) * math.pi / 180;

    final a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

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

  /// 🎯 计算匀速移动参数（基于距离的匀速播放）
  void _calculatePlaybackDuration() {
    if (trackPoints.isEmpty) {
      logDebug('⚠️ 轨迹点为空，无法计算播放时长');
      _totalDistance = 0.0;
      _uniformSpeed = 130.0;
      _totalPlaybackDuration = Duration(seconds: 10);
      return;
    }

    // 🎯 计算轨迹总距离
    _totalDistance = _calculateTotalTrackDistance();

    // 🎯 计算自适应匀速（参考iOS算法）
    _uniformSpeed = _calculateAdaptiveSpeed(_totalDistance);

    // 🎯 基于距离和匀速计算播放时长
    final calculatedSeconds = _totalDistance / _uniformSpeed;
    _totalPlaybackDuration = Duration(
      milliseconds: (calculatedSeconds * 1000).round(),
    );

    // 应用播放速度
    final actualDuration =
        _totalPlaybackDuration!.inSeconds / replaySpeed.value;

    logDebug(
      '🎬 匀速移动参数: 总距离=${(_totalDistance / 1000).toStringAsFixed(2)}km, 匀速=${_uniformSpeed.toStringAsFixed(1)}m/s, 播放时长=${actualDuration.toStringAsFixed(1)}秒',
    );
  }

  /// 🎯 计算自适应匀速（参考iOS算法）
  /// 算法：基于1000米为单位，基础速度130米/秒，按距离倍数线性增长
  double _calculateAdaptiveSpeed(double totalDistance) {
    if (totalDistance <= 0) return 130.0;

    // 基础速度：130米/秒
    const double baseSpeed = 130.0;

    // 最小单位：1000米
    const double unitDistance = 1000.0;

    // 计算倍数（向上取整，确保最小为1倍）
    final multiplier = math.max(1, (totalDistance / unitDistance).ceil());

    // 返回速度：130 × 倍数
    return baseSpeed * multiplier;
  }

  /// 根据轨迹长度动态计算播放时间
  Duration _calculateOptimalReplayDuration() {
    return _totalPlaybackDuration ?? const Duration(seconds: 10);
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
      replayTime.value =
          "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    }

    // 🎯 不再在这里更新播放进度，因为已经在定时器中实时更新以保持平滑
    // 只在 seekToIndex 时才需要更新进度

    // 🎯 基于实际播放速度更新速度显示（iOS方案）
    if (trackPoints.isNotEmpty && _totalPlaybackDuration != null) {
      final totalDistanceKm = _calculateTotalTrackDistance() / 1000; // 转换为公里
      final actualDurationHours =
          (_totalPlaybackDuration!.inSeconds / replaySpeed.value) /
          3600; // 考虑播放倍速

      if (actualDurationHours > 0) {
        final speedKmh = totalDistanceKm / actualDurationHours;
        currentSpeed.value = "${speedKmh.toStringAsFixed(1)}km/h";
      } else {
        currentSpeed.value = "0.0km/h";
      }
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
      _updateReplayPedestalMarkerSync(trackPoints[safeIndex]);
    }

    // 更新累计距离
    _cumulativeDistance = _calculateCumulativeDistance(0, safeIndex);

    // 手动更新进度
    replayProgress.value =
        safeIndex / (trackPoints.length - 1).clamp(1, trackPoints.length);

    // 如果正在播放，更新时间基准
    if (isReplaying.value && _replayStartTime != null) {
      // 根据当前进度调整开始时间，让时间显示更准确
      final progress = safeIndex / (trackPoints.length - 1);
      final optimalDuration = _calculateOptimalReplayDuration();
      final currentSeconds = (progress * optimalDuration.inSeconds);
      _replayStartTime = DateTime.now().subtract(
        Duration(milliseconds: (currentSeconds * 1000).round()),
      );
    }

    _updateReplayStatus();
  }

  /// 🎯 开始高精度60fps轨迹回放
  void startReplay() {
    if (trackPoints.isEmpty) {
      CustomToast.show(Get.context!, '暂无轨迹数据可回放');
      return;
    }

    logDebug('🎬 开始播放回放...');

    // 停止之前的播放
    _replayTimer?.cancel();

    // 🎯 计算播放参数（基于距离的匀速播放）
    _calculatePlaybackDuration();

    if (trackPoints.isEmpty) {
      logError('❌ 轨迹点为空，无法播放');
      return;
    }

    // 设置播放状态
    isReplaying.value = true;
    showFullPlayer.value = true;
    _playbackStartTime = DateTime.now();
    _replayStartTime = DateTime.now();
    _cumulativeDistance = 0.0;
    replayProgress.value = 0.0;

    // 🎯 调整地图视角以显示完整轨迹
    logDebug('🗺️ 调整地图视角以显示完整轨迹');
    onFitMapToTrack?.call(trackPoints);

    // 创建播放头像和底座标记
    currentPosition.value = trackPoints[0];
    _createReplayAvatarMarker(currentPosition.value!);
    _createReplayPedestalMarker(currentPosition.value!);

    _updateReplayStatus();

    // 🎯 启动播放定时器，简单直接按轨迹点播放（参考iOS方案）
    _replayTimer = Timer.periodic(_frameInterval, _onReplayTimerUpdate);

    logDebug('🎬 轨迹回放已启动');
    logDebug(
      '📊 播放参数: 总时长=${_totalPlaybackDuration!.inSeconds}秒, 轨迹点=${trackPoints.length}个, 播放速度=${replaySpeed.value}x',
    );
    logDebug(
      '📊 实际播放时长=${(_totalPlaybackDuration!.inSeconds / replaySpeed.value).toStringAsFixed(1)}秒',
    );
    logDebug(
      '📊 总距离=${(_calculateTotalTrackDistance() / 1000).toStringAsFixed(2)}公里',
    );
  }

  /// 🎯 基于时间的平滑插值播放定时器回调（真正的iOS方案）
  void _onReplayTimerUpdate(Timer timer) {
    if (!isReplaying.value) {
      timer.cancel();
      return;
    }

    if (trackPoints.isEmpty || _playbackStartTime == null) {
      timer.cancel();
      return;
    }

    final now = DateTime.now();
    final elapsed = now.difference(_playbackStartTime!);

    // 🎯 考虑播放速度的实际播放时长
    final actualDuration = Duration(
      milliseconds: (_totalPlaybackDuration!.inMilliseconds / replaySpeed.value)
          .round(),
    );

    // 计算播放进度（0-1）
    final progress = (elapsed.inMilliseconds / actualDuration.inMilliseconds)
        .clamp(0.0, 1.0);

    // 检查播放完成
    if (progress >= 1.0) {
      timer.cancel();
      _onPlaybackComplete();
      return;
    }

    // 🎯 基于时间的平滑插值计算当前位置
    final interpolatedPosition = _calculateTimeBasedInterpolatedPosition(
      progress,
    );
    if (interpolatedPosition == null) {
      return;
    }

    // 更新当前位置为插值计算的平滑位置
    currentPosition.value = interpolatedPosition;

    // 🎯 更新播放头像和底座位置
    _updateReplayAvatarMarkerSync(interpolatedPosition);
    _updateReplayPedestalMarkerSync(interpolatedPosition);

    // 🎯 根据设置决定是否移动地图视角
    if (enableCameraFollow.value) {
      onMapMoveSmooth?.call(interpolatedPosition);
    }

    // 更新进度条
    replayProgress.value = progress;

    // 🎯 计算当前轨迹点索引用于停留点检查
    final currentIndex = _calculateCurrentTrackPointIndex(progress);
    if (currentIndex != currentReplayIndex.value) {
      currentReplayIndex.value = currentIndex;
      _checkPassingStopPoint(currentIndex);
    }

    // 更新累计距离
    _cumulativeDistance = _calculateCumulativeDistance(0, currentIndex);

    // 更新状态显示（降低频率避免过于频繁）
    if ((elapsed.inMilliseconds / 100) % 3 == 0) {
      // 每300ms更新一次状态
      _updateReplayStatus();
    }
  }

  /// 🎯 基于距离权重的平滑插值位置计算（真正的iOS方案）
  LatLng? _calculateTimeBasedInterpolatedPosition(double progress) {
    if (trackPoints.isEmpty) return null;
    if (progress <= 0.0) return trackPoints.first;
    if (progress >= 1.0) return trackPoints.last;

    // 🎯 iOS方案：基于累计距离而不是轨迹点数量进行插值
    final totalDistance = _calculateTotalTrackDistance();
    if (totalDistance <= 0) return trackPoints.first;

    final targetDistance = progress * totalDistance;

    // 找到目标距离所在的轨迹段
    double cumulativeDistance = 0.0;
    for (int i = 0; i < trackPoints.length - 1; i++) {
      final segmentDistance = _calculateDistance(
        trackPoints[i],
        trackPoints[i + 1],
      );

      if (cumulativeDistance + segmentDistance >= targetDistance) {
        // 找到了目标段，计算段内插值
        final remainingDistance = targetDistance - cumulativeDistance;
        final segmentProgress = segmentDistance > 0
            ? remainingDistance / segmentDistance
            : 0.0;

        // 在两个轨迹点之间进行线性插值
        final startPoint = trackPoints[i];
        final endPoint = trackPoints[i + 1];

        final interpolatedLat =
            startPoint.latitude +
            (endPoint.latitude - startPoint.latitude) * segmentProgress;
        final interpolatedLng =
            startPoint.longitude +
            (endPoint.longitude - startPoint.longitude) * segmentProgress;

        return LatLng(interpolatedLat, interpolatedLng);
      }

      cumulativeDistance += segmentDistance;
    }

    // 如果没找到（理论上不应该发生），返回最后一个点
    return trackPoints.last;
  }

  /// 🎯 计算当前轨迹点索引（用于停留点检查）
  int _calculateCurrentTrackPointIndex(double progress) {
    if (trackPoints.isEmpty) return 0;
    if (progress <= 0.0) return 0;
    if (progress >= 1.0) return trackPoints.length - 1;

    final totalSegments = trackPoints.length - 1;
    final exactPosition = progress * totalSegments;
    return exactPosition.round().clamp(0, trackPoints.length - 1);
  }

  /// 🎯 播放完成处理
  void _onPlaybackComplete() {
    logDebug('🎯 轨迹回放完成');
    isReplaying.value = false;
    _replayTimer?.cancel();
    _replayTimer = null;

    // 确保进度为100%
    replayProgress.value = 1.0;
    currentReplayIndex.value = trackPoints.length - 1;

    // 确保最后位置正确
    if (trackPoints.isNotEmpty) {
      currentPosition.value = trackPoints.last;
      _updateReplayAvatarMarkerSync(trackPoints.last);
      _updateReplayPedestalMarkerSync(trackPoints.last);
    }

    _updateReplayStatus();
    _showReplayCompleteMessage();
  }

  /// 检查是否经过停留点
  void _checkPassingStopPoint(int currentIndex) {
    if (currentIndex >= trackPoints.length || stopPoints.isEmpty) return;

    final currentPoint = trackPoints[currentIndex];

    // 检查是否接近任何停留点
    for (final stopPoint in stopPoints) {
      try {
        LatLng? stopPointPosition;
        String? stopPointName;

        // 🎯 兼容不同类型的停留点对象
        if (stopPoint is Map<String, dynamic>) {
          // JSON格式的停留点
          final lat = double.tryParse(stopPoint['lat']?.toString() ?? '0');
          final lng = double.tryParse(stopPoint['lng']?.toString() ?? '0');
          if (lat != null && lng != null) {
            stopPointPosition = LatLng(lat, lng);
            stopPointName =
                stopPoint['address']?.toString() ??
                stopPoint['locationName']?.toString() ??
                '未知位置';
          }
        } else if (stopPoint.runtimeType.toString().contains('StayPoint')) {
          // StayPoint类型 - 使用position属性
          final position = stopPoint.position;
          if (position != null) {
            stopPointPosition = position;
            stopPointName = stopPoint.title ?? '未知位置';
          }
        } else {
          // TrackStopPoint类型 - 使用lat/lng属性
          try {
            final lat = (stopPoint as dynamic).lat;
            final lng = (stopPoint as dynamic).lng;
            if (lat != null && lng != null) {
              stopPointPosition = LatLng(lat.toDouble(), lng.toDouble());
              stopPointName = (stopPoint as dynamic).locationName ?? '未知位置';
            }
          } catch (e) {
            logWarning('⚠️ 无法解析停留点坐标: $e');
            continue;
          }
        }

        if (stopPointPosition != null) {
          final distance = _calculateDistance(currentPoint, stopPointPosition);

          // 如果距离小于50米，认为经过了停留点
          if (distance < 50) {
            logDebug(
              '🎯 经过停留点: $stopPointName (距离: ${distance.toStringAsFixed(1)}m)',
            );
            break;
          }
        }
      } catch (e) {
        logWarning('⚠️ 检查停留点时发生错误: $e');
        continue;
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
    _replayTimer?.cancel();
    _replayTimer = null;
    logDebug('轨迹回放已暂停');
  }

  /// 停止并重置
  void stopReplay() {
    isReplaying.value = false;
    _replayTimer?.cancel();
    _replayTimer = null;

    // 停止播放头像动画
    _stopReplayAvatarAnimation();

    // 重置到起点
    currentReplayIndex.value = 0;
    replayProgress.value = 0.0;
    _cumulativeDistance = 0.0;
    replayTime.value = "00:00:00";
    replayDistance.value = "0米";
    currentSpeed.value = "0.0km/h";

    if (trackPoints.isNotEmpty) {
      currentPosition.value = trackPoints.first;
      onMapMove?.call(trackPoints.first);

      // 更新播放头像和底座位置
      if (replayAvatarMarker.value != null) {
        _updateReplayAvatarMarkerSync(trackPoints.first);
        _updateReplayPedestalMarkerSync(trackPoints.first);
      }
    }

    _replayStartTime = null;
    _playbackStartTime = null;
    logDebug('轨迹回放已停止并重置');
  }

  /// 关闭播放器并重置动画
  void closePlayer() {
    stopReplay(); // 停止当前播放
    showFullPlayer.value = false; // 隐藏播放器UI

    // 清除播放头像标记
    if (replayAvatarMarker.value != null) {
      logDebug('🧹 关闭播放器时清除播放头像标记');
      replayAvatarMarker.value = null;
    }

    // 恢复显示当前位置标记
    currentPosition.value = null;

    logDebug('播放器已关闭');
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

    // 🎯 如果正在播放，重新开始播放以应用新的速度
    if (isReplaying.value) {
      final currentProgress = replayProgress.value;
      stopReplay();

      // 重新预计算路径（应用新速度）
      _calculatePlaybackDuration();

      // 从当前进度继续播放
      startReplay();
      seekReplay(currentProgress);
    }

    logDebug('播放速度切换为: ${replaySpeed.value}x');
  }

  /// 根据进度跳转（用于进度条拖动）
  void seekReplay(double progress) {
    if (trackPoints.isEmpty) return;

    final safeProgress = progress.clamp(0.0, 1.0);

    // 🎯 直接跳转到对应轨迹点位置
    final targetIndex = (safeProgress * (trackPoints.length - 1)).round();
    final currentIndex = targetIndex.clamp(0, trackPoints.length - 1);

    currentPosition.value = trackPoints[currentIndex];
    if (replayAvatarMarker.value != null) {
      _updateReplayAvatarMarkerSync(currentPosition.value!);
      _updateReplayPedestalMarkerSync(currentPosition.value!);
    }

    // 更新原始索引
    currentReplayIndex.value = currentIndex;

    // 更新进度
    replayProgress.value = safeProgress;

    // 🎯 如果正在播放，调整播放开始时间以匹配新进度
    if (isReplaying.value &&
        _playbackStartTime != null &&
        _totalPlaybackDuration != null) {
      final elapsedTime = Duration(
        milliseconds: (safeProgress * _totalPlaybackDuration!.inMilliseconds)
            .round(),
      );
      _playbackStartTime = DateTime.now().subtract(elapsedTime);
    }

    // 更新累计距离和状态
    _cumulativeDistance = _calculateCumulativeDistance(
      0,
      currentReplayIndex.value,
    );
    _updateReplayStatus();
  }

  /// 🎯 切换相机跟随模式（已禁用）
  void toggleCameraFollow() {
    // 相机跟随功能已禁用，不执行任何操作（保留方法签名以兼容未来扩展）
    logDebug('🎯 相机跟随功能已禁用');
  }

  /// 🎯 设置相机跟随模式（已禁用）
  void setCameraFollow(bool enabled) {
    // 相机跟随功能已禁用，强制保持关闭状态（保留方法签名以兼容未来扩展）
    enableCameraFollow.value = false;
    logDebug('🎯 相机跟随功能已禁用，忽略设置请求');
  }

  /// 🎯 启动播放头像的原生呼吸动画（iOS原版效果）
  ///
  /// 🎨 iOS原版效果：
  /// - 横向拉伸：X=1.03, Y=0.98（横向拉伸3%，纵向压缩2%）
  /// - 纵向拉伸：X=0.98, Y=1.03（横向压缩2%，纵向拉伸3%）
  /// - 两种状态交替变换，产生自然的"呼吸"效果
  /// - 动画时长：0.4秒（与iOS原版完全一致）
  void _startReplayAvatarAnimation() async {
    if (_mapController == null) {
      logWarning('⚠️ MapController未初始化，跳过启动动画');
      return;
    }

    try {
      final success = await _mapController!.startMarkerBreathAnimation(
        markerId: 'replay_avatar_marker',
        duration: 400, // iOS原版：0.4秒
      );

      if (success) {
        logDebug('✅ 播放头像呼吸动画已启动(iOS原版效果)');
      } else {
        logWarning('⚠️ 播放头像呼吸动画启动失败');
      }
    } catch (e) {
      logError('❌ 启动播放头像动画失败: $e');
    }
  }

  /// 🎯 停止播放头像的原生呼吸动画
  void _stopReplayAvatarAnimation() async {
    if (_mapController == null) return;

    try {
      await _mapController!.stopMarkerBreathAnimation(
        markerId: 'replay_avatar_marker',
      );
      logDebug('✅ 播放头像呼吸动画已停止');
    } catch (e) {
      logError('❌ 停止播放头像动画失败: $e');
    }
  }

  @override
  void onClose() {
    _replayTimer?.cancel();
    // 停止播放头像动画
    _stopReplayAvatarAnimation();
    super.onClose();
  }
}
