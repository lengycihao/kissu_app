import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import '../../utils/debug_util.dart';

/// 标记选项数据类
class MarkerOption {
  final String name;
  final String? assetPath;
  
  const MarkerOption(this.name, this.assetPath);
}

/// 动画类型枚举
enum MarkerAnimationType {
  none('无动画', '无动画效果'),
  swing('摇摆', '左右摇摆动画');
  
  const MarkerAnimationType(this.name, this.description);
  
  final String name;
  final String description;
}

/// 轨迹播放测试页面控制器
class TrackPlayTestController extends GetxController with GetTickerProviderStateMixin {
  /// 地图控制器
  AMapController? mapController;
  
  /// 地图是否就绪
  final isMapReady = false.obs;
  
  /// 播放状态
  final isPlaying = false.obs;
  
  /// 播放进度 (0.0 - 1.0)
  final playProgress = 0.0.obs;
  
  /// 当前标记点位置
  final currentMarkerPosition = Rx<LatLng?>(null);
  
  /// 动画控制器
  AnimationController? _animationController;
  Animation<double>? _animation;
  
  /// 轨迹点列表（示例数据）
  final List<LatLng> trackPoints = <LatLng>[
    // 创建一个简单的测试轨迹 - 从天安门到故宫的路线
    const LatLng(39.90469, 116.40717), // 天安门
    const LatLng(39.90567, 116.40717), // 向北移动
    const LatLng(39.90665, 116.40717), // 继续向北
    const LatLng(39.90763, 116.40717), // 继续向北
    const LatLng(39.90861, 116.40717), // 继续向北
    const LatLng(39.90959, 116.40717), // 继续向北
    const LatLng(39.91057, 116.40717), // 继续向北
    const LatLng(39.91155, 116.40717), // 继续向北
    const LatLng(39.91253, 116.40717), // 继续向北
    const LatLng(39.91351, 116.40717), // 继续向北
    const LatLng(39.91449, 116.40717), // 继续向北
    const LatLng(39.91547, 116.40717), // 继续向北
    const LatLng(39.91645, 116.40717), // 继续向北
    const LatLng(39.91743, 116.40717), // 继续向北
    const LatLng(39.91841, 116.40717), // 继续向北
    const LatLng(39.91939, 116.40717), // 故宫南门
  ];
  
  /// 初始相机位置
  late final CameraPosition initialCameraPosition;
  
  
  /// 标记点
  final markers = <Marker>{}.obs;
  
  /// 自定义移动标记图片类型
  final selectedMarkerType = 'default'.obs;
  
  /// 预定义的标记图片选项
  final markerOptions = <String, MarkerOption>{
    'default': const MarkerOption('默认蓝色', null),
    'circle': const MarkerOption('圆圈', 'assets/kissu_track_header_girl.webp'),
    'play': const MarkerOption('播放', 'assets/kissu_location_play.webp'),
    'run': const MarkerOption('奔跑', 'assets/kissu_track_header_boy.webp'),
    'car': const MarkerOption('汽车', 'assets/kissu_vip_cat.webp'),
    'heart': const MarkerOption('爱心', 'assets/kissu3_love_avater.webp'),
  };
  
  // 注意：由于使用覆盖层实现动画，不再需要移动标记图标
  
  /// 当前选择的动画类型
  final selectedAnimationType = MarkerAnimationType.swing.obs;
  
  /// 动画控制器（用于marker动画）
  AnimationController? _markerAnimationController;
  
  /// 动画对象（用于marker动画）
  Animation<double>? _markerAnimation;
  
  
  

  /// 缓存移动标记图标，避免在每一帧动画中重复加载资源
  BitmapDescriptor? _movingMarkerIcon;

  /// 当前 marker 透明度（0.0 - 1.0），用于替代缩放类动画
  final markerAlpha = 1.0.obs;

  /// 当前 marker 旋转角度（度），用于方向与旋转动画
  final markerRotationDeg = 0.0.obs;
  
  
  /// 控制面板是否展开
  final isPanelExpanded = true.obs;
  
  @override
  void onInit() {
    super.onInit();
    
    // 设置初始相机位置（轨迹中心点）
    initialCameraPosition = CameraPosition(
      target: trackPoints.first,
      zoom: 15.0,
    );
    
    
    // 创建起点和终点标记
    _createStartEndMarkers();
    
    // 初始化移动标记点到起始位置
    currentMarkerPosition.value = trackPoints.first;
    
    // 初始化默认标记图标
    _initializeMarkerIcon();
    
    // 初始化marker动画
    _initializeMarkerAnimation();
  }
  
  @override
  void onClose() {
    _animationController?.dispose();
    _markerAnimationController?.dispose();
    super.onClose();
  }
  
  /// marker大小（像素）
  final markerSize = 60.0.obs;

  /// 初始化标记图标（已移除，使用覆盖层实现）
  Future<void> _initializeMarkerIcon() async {
    final markerOption = markerOptions[selectedMarkerType.value];
    if (markerOption?.assetPath != null) {
      // 🎯 使用真正有效的大小控制方法
      _movingMarkerIcon = await _createResizedMarkerIcon(
        markerOption!.assetPath!,
        markerSize.value.toInt(),
        markerSize.value.toInt(),
      );
    } else {
      _movingMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
    await updateMovingMarker();
  }

  /// 🎨 创建指定大小的marker图标（真正有效的方法）
  Future<BitmapDescriptor> _createResizedMarkerIcon(
    String assetPath,
    int width,
    int height,
  ) async {
    try {
      // 加载原始图片数据
      final ByteData data = await rootBundle.load(assetPath);
      
      // 使用ui.instantiateImageCodec进行缩放
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: width,
        targetHeight: height,
      );
      
      // 获取缩放后的图片
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ByteData? resizedData = await frameInfo.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      
      if (resizedData == null) {
        DebugUtil.error('图片缩放失败，使用默认marker');
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      }
      
      // 使用fromBytes创建BitmapDescriptor
      return BitmapDescriptor.fromBytes(resizedData.buffer.asUint8List());
    } catch (e) {
      DebugUtil.error('创建缩放marker失败: $e');
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

  /// 🎛️ 改变marker大小
  Future<void> changeMarkerSize(double newSize) async {
    if (markerSize.value == newSize) return;
    
    markerSize.value = newSize;
    DebugUtil.info('正在调整marker大小到: ${newSize}px');
    await _initializeMarkerIcon();
  }
  
  /// 地图创建回调
  void onMapCreated(AMapController controller) {
    mapController = controller;
    isMapReady.value = true;
  }
  
  
  /// 创建起点和终点标记
  void _createStartEndMarkers() {
    // 起点标记（绿色）
    markers.add(
      Marker(
        position: trackPoints.first,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: '起点'),
      ),
    );
    
    // 终点标记（红色）
    markers.add(
      Marker(
        position: trackPoints.last,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: '终点'),
      ),
    );
  }
  
  /// 更新移动标记点
  Future<void> updateMovingMarker() async {
    if (currentMarkerPosition.value == null) return;
    
    // 创建或更新移动标记点
    final movingMarkerId = 'moving_marker';
    markers.removeWhere((marker) => marker.id == movingMarkerId);
    
    // 使用已缓存的图标，避免在动画过程中重复加载
    final icon = _movingMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    
    final marker = Marker(
      position: currentMarkerPosition.value!,
      icon: icon,
      alpha: markerAlpha.value,
      rotation: markerRotationDeg.value,
      visible: true,
      zIndex: 1000.0, // 确保在轨迹线之上
    );
    marker.setIdForCopy(movingMarkerId);
    markers.add(marker);
    // 强制触发标记集合刷新，确保地图端收到更新
    markers.refresh();
  }
  
  /// 开始播放
  void startPlay() {
    if (isPlaying.value) return;
    
    // 停止之前的动画
    _animationController?.dispose();
    
    isPlaying.value = true;
    
    // 创建动画控制器（10秒播放完成）
    _animationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    
    // 创建动画
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.linear,
    ));
    
    // 监听动画变化
    _animation!.addListener(_onAnimationUpdate);
    
    // 监听动画完成
    _animationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onPlayCompleted();
      }
    });
    
    // 开始动画
    _animationController!.forward();
    
    // 启动marker动画（所有动画类型都使用同一个控制器）
    final animationType = selectedAnimationType.value;
    if (animationType != MarkerAnimationType.none) {
      _markerAnimationController?.repeat();
    }
    
    print('开始播放轨迹，动画类型: ${selectedAnimationType.value}');
  }
  
  /// 暂停播放
  void pausePlay() {
    if (!isPlaying.value) return;
    
    isPlaying.value = false;
    _animationController?.stop();
    _markerAnimationController?.stop();
  }
  
  /// 重置播放
  void resetPlay() {
    isPlaying.value = false;
    _animationController?.reset();
    _markerAnimationController?.stop();
    playProgress.value = 0.0;
    currentMarkerPosition.value = trackPoints.first;
    
    // 重置透明度和旋转
    markerAlpha.value = 1.0;
    markerRotationDeg.value = 0.0;
    
    updateMovingMarker();
    
    // 移动地图到起点
    moveMapToPosition(trackPoints.first);
    
    print('播放已重置');
  }
  
  /// 初始化marker动画
  void _initializeMarkerAnimation() {
    _markerAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _markerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _markerAnimationController!,
      curve: Curves.easeInOut,
    ));
    
    _markerAnimation!.addListener(_onMarkerAnimationUpdate);
    
    // 开始循环动画
    _markerAnimationController!.repeat();
  }
  
  
  /// marker动画更新回调
  void _onMarkerAnimationUpdate() {
    if (_markerAnimation == null) return;
    
    final animationType = selectedAnimationType.value;
    final progress = _markerAnimation!.value;
    
    switch (animationType) {
      case MarkerAnimationType.none:
        markerAlpha.value = 1.0;
        markerRotationDeg.value = 0.0;
        break;
      case MarkerAnimationType.swing:
        _updateSwingAnimation(progress);
        break;
    }

    // 同步到地图上的 marker
    updateMovingMarker();
  }
  
  /// 摇摆动画效果
  void _updateSwingAnimation(double progress) {
    // 左右摇摆效果（小角度旋转）
    final rotationDeg = 12.0 * math.sin(progress * 2 * math.pi);
    markerRotationDeg.value = rotationDeg;
  }
  
  
  
  /// 切换动画类型
  void changeAnimationType(MarkerAnimationType animationType) {
    if (selectedAnimationType.value == animationType) return;
    
    selectedAnimationType.value = animationType;
    
    // 停止所有动画
    _markerAnimationController?.stop();
    
    // 重置所有动画状态
    markerAlpha.value = 1.0;
    markerRotationDeg.value = 0.0;
    
    // 启动marker动画（所有动画类型都使用同一个控制器）
    if (animationType != MarkerAnimationType.none) {
      _markerAnimationController?.repeat();
    }
    
    print('切换到动画类型: ${animationType.name}');
  }
  
  /// 切换标记图片类型（已移除，使用覆盖层实现）
  Future<void> changeMarkerType(String markerType) async {
    if (selectedMarkerType.value == markerType) return;
    
    selectedMarkerType.value = markerType;
    // 重新加载并缓存图标，然后更新移动标记
    await _initializeMarkerIcon();
  }
  
  /// 动画更新回调
  void _onAnimationUpdate() {
    if (_animation == null) return;
    
    final progress = _animation!.value;
    playProgress.value = progress;
    
    // 计算当前应该在哪个轨迹点
    final totalPoints = trackPoints.length;
    final exactIndex = progress * (totalPoints - 1);
    final currentIndex = exactIndex.floor().clamp(0, totalPoints - 2);
    final nextIndex = (currentIndex + 1).clamp(0, totalPoints - 1);
    final interpolationProgress = exactIndex - currentIndex;
    
    // 插值计算当前位置
    final startPoint = trackPoints[currentIndex];
    final endPoint = trackPoints[nextIndex];
    final newPosition = _interpolatePosition(startPoint, endPoint, interpolationProgress);
    
    // 更新当前位置
    currentMarkerPosition.value = newPosition;
    
    // 获取当前动画类型
    final animationType = selectedAnimationType.value;
    
    // 只有在特定动画类型时才应用方位角，否则让动画系统控制rotation
    if (animationType == MarkerAnimationType.none) {
      // 无动画时，让marker指向运动方向
      final bearingDeg = _computeBearingDegrees(startPoint, endPoint);
      markerRotationDeg.value = bearingDeg;
    }
    // 其他动画类型的rotation由动画系统控制，不在这里覆盖
    
    updateMovingMarker();
    
    // 移动地图跟随标记点
    moveMapToPosition(newPosition);
  }
  
  /// 播放完成回调
  void _onPlayCompleted() {
    isPlaying.value = false;
    playProgress.value = 1.0;
    currentMarkerPosition.value = trackPoints.last;
    
    // 停止标记动画
    _markerAnimationController?.stop();
    
    updateMovingMarker();
    
    print('播放完成，已停止所有动画');
  }
  
  /// 位置插值
  LatLng _interpolatePosition(LatLng start, LatLng end, double progress) {
    final lat = start.latitude + (end.latitude - start.latitude) * progress;
    final lng = start.longitude + (end.longitude - start.longitude) * progress;
    return LatLng(lat, lng);
  }

  /// 计算两点之间的方位角（度，0-360，0为正北，顺时针）
  double _computeBearingDegrees(LatLng start, LatLng end) {
    final lat1 = _degToRad(start.latitude);
    final lat2 = _degToRad(end.latitude);
    final dLon = _degToRad(end.longitude - start.longitude);
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.cos(lat2) * math.cos(dLon) - math.sin(lat1) * math.sin(lat2);
    final brng = math.atan2(y, x);
    final brngDeg = (_radToDeg(brng) + 360.0) % 360.0;
    return brngDeg;
  }

  double _degToRad(double deg) => deg * math.pi / 180.0;
  double _radToDeg(double rad) => rad * 180.0 / math.pi;
  
  
  
  /// 移动地图到指定位置
  void moveMapToPosition(LatLng position) {
    if (!isMapReady.value) return;
    
    mapController?.moveCamera(
      CameraUpdate.newLatLng(position),
    );
  }
  
  /// 切换控制面板展开状态
  void togglePanel() {
    isPanelExpanded.value = !isPanelExpanded.value;
  }
}
