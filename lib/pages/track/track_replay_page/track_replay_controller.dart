import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:kissu_app/pages/track/managers/track_replay_manager.dart';
import 'package:kissu_app/pages/track/managers/track_map_manager.dart';
import 'package:kissu_app/utils/debug_util.dart';
import 'dart:ui' as ui;
import 'dart:math';

/// 轨迹播放页面控制器
/// 专门用于全屏播放轨迹，只包含地图和播放控制器
class TrackReplayController extends GetxController with GetTickerProviderStateMixin {
  /// 管理器实例
  late final TrackMapManager _mapManager;
  late final TrackReplayManager _replayManager;
  
  /// 从轨迹页面传递过来的数据
  final List<LatLng> trackPoints;
  final List<dynamic> stopPoints;
  final String currentUserAvatar;
  final int mapType;
  
  TrackReplayController({
    required this.trackPoints,
    required this.stopPoints,
    required this.currentUserAvatar,
    this.mapType = 1,
  }) {
    // DebugUtil.info('🎬 轨迹播放控制器初始化');
    // DebugUtil.info('📍 轨迹点数量: ${trackPoints.length}');
    // DebugUtil.info('🛑 停留点数量: ${stopPoints.length}');
    // DebugUtil.info('🛑 停留点数据: $stopPoints');
  }
  
  /// 对外暴露的属性
  RxBool get isMapReady => _mapManager.isMapReady;
  RxInt get mapTypeValue => _mapManager.mapType;
  AMapController? get mapController => _mapManager.mapController;
  
  /// 播放相关属性
  RxBool get showFullPlayer => _replayManager.showFullPlayer;
  RxString get replayDistance => _replayManager.replayDistance;
  RxString get replayTime => _replayManager.replayTime;
  RxDouble get replayProgress => _replayManager.replayProgress;
  RxString get currentSpeed => _replayManager.currentSpeed;
  RxInt get currentReplayIndex => _replayManager.currentReplayIndex;
  RxBool get isReplaying => _replayManager.isReplaying;
  RxDouble get replaySpeed => _replayManager.replaySpeed;
  Rx<Marker?> get replayAvatarMarker => _replayManager.replayAvatarMarker;
  Rx<LatLng?> get currentPosition => _replayManager.currentPosition;
  RxDouble get animationProgress => _replayManager.animationProgress;
  
  @override
  void onInit() {
    super.onInit();
    
    // 初始化管理器
    _mapManager = TrackMapManager();
    _replayManager = TrackReplayManager();
    
    // 设置地图类型
    _mapManager.mapType.value = mapType;
    
    // 手动调用 onInit
    _replayManager.onInit();
    
    // 设置依赖关系
    _setupManagerDependencies();
    
    DebugUtil.info('🎬 轨迹播放页面初始化完成');
  }
  
  /// 设置管理器之间的依赖关系
  void _setupManagerDependencies() {
    _replayManager.setDependencies(
      onMapMove: _mapManager.moveMapToLocation,
      onMapMoveSmooth: _mapManager.moveMapToLocationSmooth,
      onFitMapToTrack: _mapManager.fitMapToTrack,
      getCurrentUserAvatar: () => currentUserAvatar,
      getTrackPoints: () => trackPoints,
      getStopPoints: () => stopPoints,
    );
  }
  
  /// 地图初始相机位置
  CameraPosition get initialCameraPosition {
    if (trackPoints.isNotEmpty) {
      final optimalPosition = _mapManager.calculateOptimalCameraPosition(trackPoints);
      if (optimalPosition != null) {
        return optimalPosition;
      }
    }
    
    // 默认位置（杭州）
    return const CameraPosition(
      target: LatLng(30.2741, 120.2206),
      zoom: 18.0,
    );
  }
  
  /// 地图创建完成回调
  void onMapCreated(AMapController controller) {
    _mapManager.onMapCreated(controller, () {});
    
    // 延迟执行，等待地图准备完成
    Future.delayed(const Duration(milliseconds: 500), () {
      // 自动调整地图视角以显示完整轨迹
      if (trackPoints.isNotEmpty) {
        _mapManager.fitMapToTrack(trackPoints);
      }
    });
  }
  
  /// 设置地图就绪状态
  void setMapReady(bool ready) {
    _mapManager.setMapReady(ready);
  }
  
  /// 获取所有轨迹线
  Set<Polyline> get polylines {
    if (trackPoints.isEmpty) {
      return {};
    }
    
    try {
      return {
        Polyline(
          points: trackPoints,
          color: const Color(0xFF4285F4),
          width: 6,
          geodesic: true,
          joinType: JoinType.round,
          capType: CapType.round,
        ),
      };
    } catch (e) {
      DebugUtil.error('创建轨迹线失败: $e');
      return {};
    }
  }
  
  /// 获取所有标记
  Future<Set<Marker>> getMarkers() async {
    final markers = <Marker>[];
    
    try {
      // 添加播放头像标记
      if (replayAvatarMarker.value != null) {
        markers.add(replayAvatarMarker.value!);
      }
      
      // 添加起点终点标记
      await _addStartEndMarkers(markers);
      
      // 添加停留点标记
      await _addStopPointMarkers(markers);
      
      DebugUtil.info('标记总数: ${markers.length}');
    } catch (e) {
      DebugUtil.error('获取标记失败: $e');
    }
    
    return markers.toSet();
  }
  
  /// 添加起点终点标记（与轨迹页面完全一致）
  Future<void> _addStartEndMarkers(List<Marker> markers) async {
    if (trackPoints.isEmpty) return;
    
    final startPoint = trackPoints.first;
    final endPoint = trackPoints.last;
    
    try {
      // 创建起点标记
      try {
        final startIcon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(44, 46)),
          'assets/kissu_location_start.webp',
        );
        
        markers.add(Marker(
          position: startPoint,
          icon: startIcon,
          anchor: const Offset(0.41, 0.83), // 设置锚点为图片的 (18, 38) 位置
          infoWindow: const InfoWindow(title: '', snippet: ''),
          onTap: (_) {
            DebugUtil.info('点击了轨迹起点');
          },
        ));
        DebugUtil.success('✅ 轨迹起点标记创建成功');
      } catch (e) {
        DebugUtil.error('❌ 创建起点标记失败: $e，使用降级方案');
        // 降级方案：使用绿色圆点
        final fallbackIcon = await _createColoredCircleIcon(Colors.green, 24);
        markers.add(Marker(
          position: startPoint,
          icon: fallbackIcon,
          infoWindow: const InfoWindow(title: '', snippet: ''),
          onTap: (_) {
            DebugUtil.info('点击了轨迹起点');
          },
        ));
      }
      
      // 创建终点标记（只有当起点和终点不是同一个点时）
      if (trackPoints.length > 1) {
        final distance = _calculateDistance(startPoint, endPoint);
        
        // 只有当起点和终点距离超过50米时才显示终点标记
        if (distance > 50) {
          try {
            final endIcon = await BitmapDescriptor.fromAssetImage(
              const ImageConfiguration(size: Size(44, 46)),
              'assets/kissu_location_end.webp',
            );
            
            markers.add(Marker(
              position: endPoint,
              icon: endIcon,
              anchor: const Offset(0.59, 0.83), // 设置锚点为图片的 (26, 38) 位置
              infoWindow: const InfoWindow(title: '', snippet: ''),
              onTap: (_) {
                DebugUtil.info('点击了轨迹终点');
              },
            ));
            DebugUtil.success('✅ 轨迹终点标记创建成功');
          } catch (e) {
            DebugUtil.error('❌ 创建终点标记失败: $e，使用降级方案');
            // 降级方案：使用红色圆点
            final fallbackIcon = await _createColoredCircleIcon(Colors.red, 24);
            markers.add(Marker(
              position: endPoint,
              icon: fallbackIcon,
              infoWindow: const InfoWindow(title: '', snippet: ''),
              onTap: (_) {
                DebugUtil.info('点击了轨迹终点');
              },
            ));
          }
        }
      }
    } catch (e) {
      DebugUtil.error('❌ 添加起点终点标记失败: $e');
    }
  }

  /// 添加停留点标记
  Future<void> _addStopPointMarkers(List<Marker> markers) async {
     if (stopPoints.isEmpty) {
       return;
    }
    
    // 获取起点和终点位置，用于过滤重复的停留点
    LatLng? startPoint;
    LatLng? endPoint;
    if (trackPoints.isNotEmpty) {
      startPoint = trackPoints.first;
      if (trackPoints.length > 1) {
        endPoint = trackPoints.last;
      }
    }
    
    try {
      for (int i = 0; i < stopPoints.length; i++) {
        final stopPoint = stopPoints[i];
         if (stopPoint == null) {
           continue;
        }
        
        // 获取停留点的位置信息
        final lat = _getStopPointLatitude(stopPoint);
        final lng = _getStopPointLongitude(stopPoint);
        final locationName = _getStopPointLocationName(stopPoint);
        final stayDuration = _getStopPointStayDuration(stopPoint);
        
        if (lat != null && lng != null) {
          final position = LatLng(lat, lng);
          
          // 检查是否与起点或终点重复（距离小于30米则认为重复）
          bool isNearStartPoint = false;
          bool isNearEndPoint = false;
          
          if (startPoint != null) {
            final distanceToStart = _calculateDistance(position, startPoint);
            isNearStartPoint = distanceToStart < 30;
          }
          
          if (endPoint != null) {
            final distanceToEnd = _calculateDistance(position, endPoint);
            isNearEndPoint = distanceToEnd < 30;
          }
          
          // 如果停留点与起点或终点过近，则跳过创建停留点标记
          if (isNearStartPoint || isNearEndPoint) {
            DebugUtil.info('🚫 跳过停留点 $i：与起点/终点距离过近 (起点距离: ${isNearStartPoint ? _calculateDistance(position, startPoint!).toStringAsFixed(1) : "无"}, 终点距离: ${isNearEndPoint ? _calculateDistance(position, endPoint!).toStringAsFixed(1) : "无"})');
            continue;
          }
           
          // 获取停留点编号（优先使用serialNumber，否则使用索引+1）
          String displayNumber;
          if (stopPoint is Map && stopPoint['serialNumber'] != null) {
            displayNumber = stopPoint['serialNumber'].toString();
          } else if (stopPoint.serialNumber != null && stopPoint.serialNumber.isNotEmpty) {
            // 如果是 StayPoint 对象，使用其 serialNumber
            displayNumber = stopPoint.serialNumber;
          } else {
            displayNumber = (i + 1).toString();
          }
           
          // 创建自定义停留点图标
          BitmapDescriptor customIcon;
          try {
            customIcon = await _createCustomStopPointIcon(displayNumber);
            DebugUtil.info('✅ 停留点 $i 自定义图标创建成功');
          } catch (e) {
            DebugUtil.warning('创建自定义停留点图标失败，使用默认图标: $e');
            customIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
          }
          
          final marker = Marker(
            position: position,
            icon: customIcon,
            anchor: const Offset(0.5, 0.5),
            infoWindow: InfoWindow(
              title: locationName ?? '停留点 $displayNumber',
              snippet: stayDuration != null ? '停留时长: $stayDuration' : null,
            ),
          );
          markers.add(marker);
         } else {
         }
      }
      
      DebugUtil.info('✅ 停留点标记处理完成，实际添加: ${markers.where((m) => m.icon != BitmapDescriptor.defaultMarker).length} 个');
    } catch (e) {
      DebugUtil.error('❌ 添加停留点标记失败: $e');
    }
  }
  
  /// 获取停留点纬度
  double? _getStopPointLatitude(dynamic stopPoint) {
    try {
      if (stopPoint is Map) {
        return stopPoint['latitude']?.toDouble() ?? 
               stopPoint['lat']?.toDouble();
      }
      // 如果是 StayPoint 对象
      if (stopPoint.position != null) {
        return stopPoint.position.latitude;
      }
      return stopPoint.latitude?.toDouble();
    } catch (e) {
      DebugUtil.error('获取停留点纬度失败: $e');
      return null;
    }
  }
  
  /// 获取停留点经度
  double? _getStopPointLongitude(dynamic stopPoint) {
    try {
      if (stopPoint is Map) {
        return stopPoint['longitude']?.toDouble() ?? 
               stopPoint['lng']?.toDouble();
      }
      // 如果是 StayPoint 对象
      if (stopPoint.position != null) {
        return stopPoint.position.longitude;
      }
      return stopPoint.longitude?.toDouble();
    } catch (e) {
      DebugUtil.error('获取停留点经度失败: $e');
      return null;
    }
  }
  
  /// 获取停留点位置名称
  String? _getStopPointLocationName(dynamic stopPoint) {
    try {
      if (stopPoint is Map) {
        return stopPoint['locationName']?.toString() ?? 
               stopPoint['location_name']?.toString() ??
               stopPoint['address']?.toString();
      }
      // 如果是 StayPoint 对象
      if (stopPoint.title != null) {
        return stopPoint.title;
      }
      return stopPoint.locationName?.toString();
    } catch (e) {
      DebugUtil.error('获取停留点位置名称失败: $e');
      return null;
    }
  }
  
  /// 获取停留点停留时长
  String? _getStopPointStayDuration(dynamic stopPoint) {
    try {
      if (stopPoint is Map) {
        return stopPoint['stayDuration']?.toString() ?? 
               stopPoint['stay_duration']?.toString() ??
               stopPoint['duration']?.toString();
      }
      // 如果是 StayPoint 对象
      if (stopPoint.duration != null) {
        return stopPoint.duration;
      }
      return stopPoint.stayDuration?.toString();
    } catch (e) {
      DebugUtil.error('获取停留点停留时长失败: $e');
      return null;
    }
  }
  
  /// 播放控制方法
  void startReplay() {
    _replayManager.startReplay();
  }
  
  void pauseReplay() {
    _replayManager.pauseReplay();
  }
  
  void stopReplay() {
    _replayManager.stopReplay();
  }
  
  void toggleSpeed() {
    _replayManager.toggleSpeed();
  }
  
  void seekReplay(double progress) {
    _replayManager.seekReplay(progress);
  }
  
  void seekToIndex(int newIndex) {
    _replayManager.seekToIndex(newIndex);
  }
  
  double getRotationAngle() {
    return _replayManager.getRotationAngle();
  }
  
  @override
  void onClose() {
    DebugUtil.info('🧹 轨迹播放页面资源清理...');
    
    // 清理管理器资源
    _mapManager.dispose();
    _replayManager.onClose();
    
    DebugUtil.success('✅ 轨迹播放页面资源清理完成');
    super.onClose();
  }

  /// 创建自定义停留点图标（粉色圆形/椭圆形，带数字）
  /// 参数: number - 显示的数字
  /// 根据数字位数自适应宽度：个位数为圆形，多位数为椭圆形
  Future<BitmapDescriptor> _createCustomStopPointIcon(String number) async {
    const double borderWidth = 2.0; // 白色边框宽度
    const double minRadius = 30.0; // 最小半径（圆形）
    const double fontSize = 32.0; // 字体大小
    
    // 先测量文本尺寸
    final textPainter = TextPainter(
      text: TextSpan(
        text: number,
        style: const TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    
    // 根据文本宽度计算图标尺寸
    final textWidth = textPainter.width;
    final textHeight = textPainter.height;
    
    // 计算所需的宽度和高度（刚好包裹数字+少量空间）
    final requiredWidth = textWidth + 6; // 文本宽度 + 左右边距
    final requiredHeight = textHeight + 4; // 文本高度 + 上下边距
    
    // 确定最终的宽度和高度（至少为圆形的直径）
    final width = max(requiredWidth, minRadius * 2);
    final height = max(requiredHeight, minRadius * 2);
    
    // 创建画布
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    final centerX = width / 2;
    final centerY = height / 2;
    
    // 绘制白色边框椭圆/圆形
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: width,
        height: height,
      ),
      borderPaint,
    );
    
    // 绘制粉色内部椭圆/圆形
    final fillPaint = Paint()
      ..color = const Color(0xFFFF88AA)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: width - borderWidth * 2,
        height: height - borderWidth * 2,
      ),
      fillPaint,
    );
    
    // 计算文本居中位置
    final textOffset = Offset(
      centerX - textPainter.width / 2,
      centerY - textPainter.height / 2,
    );
    
    textPainter.paint(canvas, textOffset);
    
    // 转换为图片
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.ceil(), height.ceil());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final uint8List = byteData!.buffer.asUint8List();
    
    return BitmapDescriptor.fromBytes(uint8List);
  }

  /// 计算两点之间的距离（米）
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // 地球半径（米）
    
    final double lat1Rad = point1.latitude * (pi / 180);
    final double lat2Rad = point2.latitude * (pi / 180);
    final double deltaLatRad = (point2.latitude - point1.latitude) * (pi / 180);
    final double deltaLngRad = (point2.longitude - point1.longitude) * (pi / 180);
    
    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// 创建彩色圆形图标（降级方案）
  Future<BitmapDescriptor> _createColoredCircleIcon(Color color, double size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    // 绘制白色边框
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, borderPaint);
    
    // 绘制彩色圆形
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 2, paint);
    
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.ceil(), size.ceil());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final uint8List = byteData!.buffer.asUint8List();
    
    return BitmapDescriptor.fromBytes(uint8List);
  }
}

