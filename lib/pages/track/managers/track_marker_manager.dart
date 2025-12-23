import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:kissu_app/pages/usage_report/widgets/map_marker_util.dart';
import 'package:kissu_app/utils/debug_util.dart';
import 'package:kissu_app/pages/track/stay_point.dart';
import 'package:kissu_app/services/tracking_service.dart'; 
import 'package:kissu_app/pages/location/services/marker_builder.dart';

/// 初始坐标信息类
class InitialCoordinateInfo {
  final double latitude;
  final double longitude;
  final String? locationName;
  final String? duration;
  final String? startTime;
  final String? endTime;
  final int? targetUserType; // 目标用户类型 (1: 自己, 0: 另一半)

  InitialCoordinateInfo({
    required this.latitude,
    required this.longitude,
    this.locationName,
    this.duration,
    this.startTime,
    this.endTime,
    this.targetUserType,
  });
}

/// 轨迹页面标记管理器
/// 负责地图标记、InfoWindow、圆圈等元素的管理
class TrackMarkerManager {
  /// 停留点标记列表
  final RxList<Marker> stopMarkers = <Marker>[].obs;
  
  /// 轨迹起终点标记
  final RxList<Marker> trackStartEndMarkers = <Marker>[].obs;
  
  /// 当前位置标记
  final Rx<LatLng?> currentPosition = Rx<LatLng?>(null);
  
  
  /// 停留记录列表（从API数据转换而来）
  final RxList<StopRecord> stopRecords = <StopRecord>[].obs;
  
  /// 高亮圆圈列表（使用原生地图API）
  final RxList<Circle> highlightCircles = <Circle>[].obs;
  
  /// 临时 InfoWindow 标记（用于显示停留点详情）
  Marker? _tempInfoWindowMarker;
  
  /// 获取临时 InfoWindow 标记
  Marker? get tempInfoWindowMarker => _tempInfoWindowMarker;
  
  // 🚀 防抖机制：避免频繁更新地图，减少卡顿
  Timer? _mapUpdateTimer;
  bool _pendingMapUpdate = false;
  
  /// 初始坐标信息（从定位页面传递）
  final Rx<InitialCoordinateInfo?> initialCoordinateInfo = Rx<InitialCoordinateInfo?>(null);
  
  /// 🎯 是否需要自动显示InfoWindow（从定位页面跳转时）
  bool _shouldAutoShowInfoWindow = false;
  
  /// 外部依赖
  AMapController? Function()? getMapController;
  bool Function()? isMapReady;
  String Function()? getCurrentUserAvatar;
  Function(LatLng)? onMapMove;
  Function()? expandToMiddlePosition;
  Function()? collapseToMinPosition;
  Function()? collapseToBottomPosition;
  
  /// 设置外部依赖
  void setDependencies({
    AMapController? Function()? getMapController,
    bool Function()? isMapReady,
    String Function()? getCurrentUserAvatar,
    Function(LatLng)? onMapMove,
    Function()? expandToMiddlePosition,
    Function()? collapseToMinPosition,
    Function()? collapseToBottomPosition,
  }) {
    this.getMapController = getMapController;
    this.isMapReady = isMapReady;
    this.getCurrentUserAvatar = getCurrentUserAvatar;
    this.onMapMove = onMapMove;
    this.expandToMiddlePosition = expandToMiddlePosition;
    this.collapseToMinPosition = collapseToMinPosition;
    this.collapseToBottomPosition = collapseToBottomPosition;
  }
  
  /// 设置初始坐标信息（从定位页面传递）
  void setInitialCoordinates({
    required double latitude,
    required double longitude,
    String? locationName,
    String? duration,
    String? startTime,
    String? endTime,
    int? targetUserType,
  }) {
    initialCoordinateInfo.value = InitialCoordinateInfo(
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      duration: duration,
      startTime: startTime,
      endTime: endTime,
      targetUserType: targetUserType,
    );
    
    // 设置标记，表示需要自动显示InfoWindow
    _shouldAutoShowInfoWindow = true;
    
    DebugUtil.info('🎯 设置初始坐标信息: $latitude, $longitude, 位置: $locationName, 目标用户: ${targetUserType == 1 ? "自己" : "另一半"}');
  }
  
  /// 获取初始坐标信息
  InitialCoordinateInfo? getInitialCoordinateInfo() {
    return initialCoordinateInfo.value;
  }
  
  /// 处理初始坐标高亮显示
  void handleInitialCoordinates() {
    final initialInfo = initialCoordinateInfo.value;
    if (initialInfo == null) return;
    
    // 绘制高亮圆圈
    drawHighlightCircle(LatLng(initialInfo.latitude, initialInfo.longitude));
    
    // 移动地图到初始位置
    _moveMapToLocation(LatLng(initialInfo.latitude, initialInfo.longitude));
    
    // 清除初始坐标信息，避免重复处理
    initialCoordinateInfo.value = null;
  }
  
  /// 移动地图到指定位置
  void _moveMapToLocation(LatLng location) {
    // 检查地图是否就绪
    if (!(isMapReady?.call() ?? false) || getMapController?.call() == null) {
      DebugUtil.warning('地图未就绪或控制器为空，无法移动地图位置');
      return;
    }
    
    onMapMove?.call(location);
  }
  
  /// 🎯 检查是否需要自动显示InfoWindow（从定位页面跳转时）
  /// 完整流程：
  /// 1. 在停留点中查找匹配的点（距离<50米）
  /// 2. 移动相机到该点
  /// 3. 显示InfoWindow
  /// 4. 绘制高亮圆圈
  /// 5. 展开底部面板
  void checkAutoShowInfoWindow(List<dynamic> stopPoints) {
    if (!_shouldAutoShowInfoWindow) return;
    
    final initialInfo = initialCoordinateInfo.value;
    if (initialInfo == null) return;
    
    DebugUtil.info('🎯 [AutoShowInfoWindow] 开始执行完整流程...');
    DebugUtil.info('🎯 [AutoShowInfoWindow] 目标坐标: (${initialInfo.latitude}, ${initialInfo.longitude})');
    DebugUtil.info('🎯 [AutoShowInfoWindow] 停留点总数: ${stopPoints.length}');
    
    // 在停留点中查找匹配的点
    for (final stopPoint in stopPoints) {
      final distance = _calculateDistance(
        LatLng(initialInfo.latitude, initialInfo.longitude),
        stopPoint.position,
      );
      
      DebugUtil.info('🎯 [AutoShowInfoWindow] 检查停留点: ${stopPoint.title}, 距离: ${distance.toStringAsFixed(2)}米');
      
      // 如果距离小于50米，认为是同一个点
      if (distance < 50) {
        DebugUtil.success('✅ [AutoShowInfoWindow] 找到匹配的停留点！');
        
        // 完整流程执行
        Future.delayed(const Duration(milliseconds: 100), () {
          // 1. 先清除之前的高亮
          clearMapHighlights();
          DebugUtil.info('🎯 [AutoShowInfoWindow] 步骤1: 清除旧高亮');
          
          // 2. 移动相机到停留点
          Future.delayed(const Duration(milliseconds: 100), () {
            _moveMapToLocation(stopPoint.position);
            DebugUtil.info('🎯 [AutoShowInfoWindow] 步骤2: 移动相机到目标点');
            
            // 3. 等待相机移动完成后显示InfoWindow
            Future.delayed(const Duration(milliseconds: 500), () async {
              await _showStopPointInfo(stopPoint);
              DebugUtil.info('🎯 [AutoShowInfoWindow] 步骤3: 显示InfoWindow');
              
              // 4. InfoWindow创建完成后绘制高亮圆圈
              Future.delayed(const Duration(milliseconds: 200), () {
                drawHighlightCircle(stopPoint.position);
                DebugUtil.info('🎯 [AutoShowInfoWindow] 步骤4: 绘制高亮圆圈');
                
                // 5. 智能展开底部面板
                expandToMiddlePosition?.call();
                DebugUtil.info('🎯 [AutoShowInfoWindow] 步骤5: 展开底部面板');
                
                DebugUtil.success('✅ [AutoShowInfoWindow] 完整流程执行完成！');
              });
            });
          });
        });
        
        break;
      }
    }
    
    // 重置标记，避免重复处理
    _shouldAutoShowInfoWindow = false;
    
    // 清除初始坐标信息
    initialCoordinateInfo.value = null;
  }
  
  /// 显示停留点信息
  /// 🎯 直接使用标记的 showInfoWindow 方法，这样会使用标记已设置的自定义 InfoWindow
  /// 🎯 注意：高德地图 SDK 的 showInfoWindow() 可能不会触发适配器，所以使用临时 Marker 方式
  Future<void> _showStopPointInfo(dynamic stopPoint) async {
    try {
      DebugUtil.info('🎯 显示停留点InfoWindow: ${stopPoint.title}');
      
      // 🎯 直接使用临时 Marker 方式，因为直接调用 showInfoWindow() 可能不会触发适配器
      // 临时 Marker 会在创建时自动显示 InfoWindow（如果设置了 autoShowCustomInfoWindow: true）
      await showInfoWindowForStopPoint(stopPoint);
      
      DebugUtil.success('✅ InfoWindow 已通过临时 Marker 方式显示');
    } catch (e) {
      DebugUtil.error('❌ 显示停留点InfoWindow失败: $e');
    }
  }
  
  /// 公共方法：显示指定停留点的InfoWindow
  Future<void> showInfoWindowForStopPoint(dynamic stopPoint) async {
    try {
      // 🎯 兼容 StayPoint 和 TrackStopPoint 两种类型
      final LatLng position;
      final String locationName;
      
      if (stopPoint is StayPoint) {
        position = stopPoint.position;
        locationName = stopPoint.title;
      } else {
        // TrackStopPoint 类型
        position = LatLng(stopPoint.lat, stopPoint.lng);
        locationName = stopPoint.locationName ?? '未知位置';
      }
      
      DebugUtil.info('🎯 直接在坐标位置创建 InfoWindow: $locationName');
      DebugUtil.info('🎯 目标坐标: ($position)');
      
      // 在指定位置创建临时 Marker 并显示 InfoWindow
      final stopInfo = _parseStopInfo(stopPoint);
      final String infoTitle = stopInfo['locationName']!;
      final String infoSnippet = '${stopPoint.startTime ?? ''} ${stopPoint.duration?.isNotEmpty == true ? '停留${stopPoint.duration}' : ''}';
      
      // 先清除之前的临时 InfoWindow Marker（如果有）
      _clearTempInfoWindowMarker();
      
      // 🎯 等待清除操作完成，确保地图更新生效
      await Future.delayed(const Duration(milliseconds: 50));
      
      // 创建临时 Marker，设置自动显示 InfoWindow 并支持拖拽
      final tempMarker = Marker(
        position: position,
        alpha: 0.0, // 🎯 完全透明，不显示系统marker
        anchor: const Offset(0.5, 0.5), // 🎯 设置锚点为中心，使InfoWindow相对坐标点居中
        infoWindowEnable: true,
        autoShowCustomInfoWindow: true, // 🎯 关键：自动显示 InfoWindow
        draggable: true, // 🎯 启用拖拽功能
        isTrackStyle: true, // 🎯 使用轨迹样式 InfoWindow
        stayDuration: stopInfo['stayDuration'], // 🎯 停留时长
        stayTime: stopInfo['stayTime'], // 🎯 停留时间
        infoWindow: InfoWindow(
          title: infoTitle,
          snippet: infoSnippet,
        ),
        customInfoWindowBuilder: (context) => _buildTrackInfoWindow(
          locationName: stopInfo['locationName']!,
          stayDuration: stopInfo['stayDuration']!,
          stayTime: stopInfo['stayTime']!,
        ),
        onDragEnd: (String markerId, LatLng newPosition) {
          // 🎯 拖拽结束时清除现有圆圈并重新创建
          DebugUtil.info('🎯 InfoWindow Marker 拖拽结束，新位置: ${newPosition.latitude}, ${newPosition.longitude}');
          drawHighlightCircle(newPosition); // 这个方法会先清除现有圆圈再创建新的
        },
        onTap: (String markerId) {
          DebugUtil.info('🎯 点击临时 InfoWindow 标记');
        },
      );
      
      // 保存临时标记的引用
      _tempInfoWindowMarker = tempMarker;
      
      // 🎯 先绘制高亮圆圈（在地图更新前添加，这样只需要一次地图更新）
      drawHighlightCircle(position);
      
      // 🎯 触发地图更新以显示临时标记和圆圈（一次更新包含所有元素，性能最优）
      _forceMapUpdate();
      
      DebugUtil.success('✅ 临时 InfoWindow 和高亮圆圈已创建并触发地图更新');
      
    } catch (e) {
      DebugUtil.error('❌ 显示停留点 InfoWindow 失败: $e');
    }
  }
  
  /// 清除临时 InfoWindow Marker
  void _clearTempInfoWindowMarker() {
    if (_tempInfoWindowMarker != null) {
      DebugUtil.info('🧹 清除之前的临时 InfoWindow Marker 和高亮圆圈');
      _tempInfoWindowMarker = null;
      
      // 🎯 同时清除高亮圆圈
      highlightCircles.clear();
      
      // 清除后触发地图更新
      _forceMapUpdate();
      
      DebugUtil.info('✅ 临时标记和圆圈已清除');
    }
  }
  
  /// 强制地图更新，确保UI同步
  /// 🚀 防抖版本的地图更新，避免频繁更新导致卡顿
  void _forceMapUpdate() {
    // 如果已经有待处理的更新，标记需要更新但不立即执行
    if (_mapUpdateTimer != null && _mapUpdateTimer!.isActive) {
      _pendingMapUpdate = true;
      return;
    }

    // 立即执行一次更新，然后设置防抖定时器
    _pendingMapUpdate = false;
    _mapUpdateTimer?.cancel();
    _mapUpdateTimer = Timer(const Duration(milliseconds: 150), () {
      // 如果防抖期间有新的更新请求，执行最后一次更新
      if (_pendingMapUpdate) {
        _pendingMapUpdate = false;
        _performMapUpdate();
      }
      _mapUpdateTimer = null;
    });

    // 立即执行更新
    _performMapUpdate();
  }

  /// 执行实际的地图更新操作
  void _performMapUpdate() {
    DebugUtil.info('🔄 [ForceMapUpdate] 开始强制更新地图');
    
    // 强制刷新所有响应式变量，让UI重新构建
    stopMarkers.refresh();
    trackStartEndMarkers.refresh();
    highlightCircles.refresh(); // 🎯 刷新高亮圆圈
    
    DebugUtil.success('✅ [ForceMapUpdate] 地图更新完成（包含圆圈）');
  }
  
  /// 清理资源
  void dispose() {
    _mapUpdateTimer?.cancel();
    _mapUpdateTimer = null;
  }
  
  /// 🎯 解析停留点信息，提取位置名称、停留时长和停留时间
  Map<String, String> _parseStopInfo(dynamic stopPoint) {
    // 🎯 兼容 StayPoint 和 TrackStopPoint 两种类型
    final String locationName;
    final String stayDuration;
    
    if (stopPoint is StayPoint) {
      locationName = stopPoint.title;
      stayDuration = stopPoint.duration;
    } else {
      // TrackStopPoint 类型
      locationName = stopPoint.locationName ?? '未知位置';
      stayDuration = stopPoint.duration ?? '';
    }
    
    // 解析停留时间段（如果stopPoint有startTime和endTime属性）
    String stayTime = '';
    try {
      if (stopPoint.startTime?.isNotEmpty == true) {
        if (stopPoint.endTime?.isNotEmpty == true && stopPoint.endTime != stopPoint.startTime) {
          // 有开始和结束时间
          stayTime = '${stopPoint.startTime}~${stopPoint.endTime}';
        } else {
          // 只有开始时间
          stayTime = stopPoint.startTime!;
        }
      }
    } catch (e) {
      DebugUtil.info('解析停留时间段失败: $e');
    }
    
    return {
      'locationName': locationName,
      'stayDuration': stayDuration,
      'stayTime': stayTime,
    };
  }
  
  /// 🎯 构建轨迹样式的InfoWindow（占位符方法，实际使用Android原生实现）
  /// 这个方法不会被实际调用，因为我们使用了Android原生的InfoWindow实现
  /// 但为了避免编译错误，需要保留这个方法定义
  Widget _buildTrackInfoWindow({
    required String locationName,
    required String stayDuration,
    required String stayTime,
  }) {
    return Container(
      width: 280,
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            locationName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          if (stayTime.isNotEmpty)
            Text(
              stayTime,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
            ),
          if (stayDuration.isNotEmpty)
            Text(
              '停留 $stayDuration',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF999999),
              ),
            ),
        ],
      ),
    );
  }
  
  
  /// 计算两点间距离（米）
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // 地球半径（米）
    final lat1Rad = point1.latitude * 3.14159265359 / 180;
    final lat2Rad = point2.latitude * 3.14159265359 / 180;
    final deltaLat = (point2.latitude - point1.latitude) * 3.14159265359 / 180;
    final deltaLng = (point2.longitude - point1.longitude) * 3.14159265359 / 180;

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLng / 2) * sin(deltaLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }
  
  /// 隐藏所有 InfoWindow
  void hideAllInfoWindows() {
    final mapController = getMapController?.call();
    if (mapController != null) {
      try {
        mapController.hideAllInfoWindows();
        DebugUtil.info('🎯 已隐藏所有 InfoWindow');
      } catch (e) {
        DebugUtil.error('❌ 隐藏所有 InfoWindow 失败: $e');
      }
    }
  }
  
  /// 清除所有高亮圆圈（使用原生地图API）
  void clearAllHighlightCircles() {
    DebugUtil.info('🧹 [HighlightCircles] 清除围栏圆圈');
    
    // 清空圆圈列表
    highlightCircles.clear();
  }
  
  /// 🎯 统一清除：同时隐藏 InfoWindow 和清除圆圈
  /// 确保 InfoWindow 和圆圈在相同时机出现和消失
  void clearMapHighlights() {
    DebugUtil.info('🧹 [MapHighlights] 清除所有地图高亮（InfoWindow + 围栏圆圈）');
    hideAllInfoWindows();
    clearAllHighlightCircles();
  }
  
  /// 🎯 不会隐藏 InfoWindow，确保圆圈和 InfoWindow 同时显示
  void drawHighlightCircle(LatLng center) {
    DebugUtil.info('🎯 开始绘制高亮圆圈: ${center.latitude}, ${center.longitude}');
    
    // 先清除已有的圆圈
    highlightCircles.clear();
    
    // 创建新的高亮圆圈
    final circle = Circle(
      center: center,
      radius: 100, // 100米半径
      strokeColor: const Color(0xFF4285F4).withValues(alpha: 0.8), // Google蓝色
      fillColor: const Color(0xFF4285F4).withValues(alpha: 0.15), // 半透明填充
      strokeWidth: 3,
    );
    
    highlightCircles.add(circle);
    
    DebugUtil.success('✅ 高亮圆圈已添加，当前数量: ${highlightCircles.length}');
  }
  
  /// 创建停留点标记
  Future<List<Marker>> createStopMarkers({
    required List<dynamic> stopPoints,
    required Function(dynamic) onStopPointTap,
    LatLng? startPoint,
    LatLng? endPoint,
  }) async {
    DebugUtil.info('🎯 [CreateStopMarkers] 开始创建停留点标记，输入数量: ${stopPoints.length}');
    DebugUtil.info('🎯 [CreateStopMarkers] 起点: $startPoint, 终点: $endPoint');
    
    if (stopPoints.isEmpty) {
      DebugUtil.warning('⚠️ [CreateStopMarkers] stopPoints为空，不创建标记');
      return [];
    }
    
    final markers = <Marker>[];
    
    try {
      for (int i = 0; i < stopPoints.length; i++) {
        final point = stopPoints[i];
        
        DebugUtil.info('🎯 [CreateStopMarkers] 处理停留点[$i]: position=${point.position}, serialNumber=${point.serialNumber}');
        
        try {
          // 🎯 移除距离过滤逻辑，所有 point_type="stop" 的点都应该显示
          
          // 🎯 使用停留点的 serialNumber 作为显示编号（与列表保持一致）
          final displayNumber = point.serialNumber;
          
          if (displayNumber == null || displayNumber.isEmpty) {
            DebugUtil.warning('⚠️ [CreateStopMarkers] 停留点[$i]的serialNumber为空，跳过创建');
            continue;
          }
          
          DebugUtil.info('🎯 [CreateStopMarkers] 停留点[$i] serialNumber=$displayNumber，开始创建marker');
          
          // 创建自定义停留点图标（粉色圆形/椭圆形，带数字）
          final customIcon = await _createCustomStopPointIcon(displayNumber);
          
          // 解析停留点信息
          final stopInfo = _parseStopInfo(point);

           
          final marker = Marker(
            position: point.position, // StayPoint 的 position 字段已经是 LatLng 类型
            icon: customIcon,
            onTap: (_) => onStopPointTap(point),
            // 设置InfoWindow数据（点击时自动显示自定义 InfoWindow）
            infoWindowEnable: true,
            isTrackStyle: true, 
            stayDuration:  stopInfo['stayDuration'] , // 停留时长
            stayTime:  stopInfo['stayTime'] , // 停留时间
            zIndex: 1.0, // 🎯 设置较低的层级，确保播放头像marker在停留点之上显示
            infoWindow: InfoWindow(
                    title: stopInfo['locationName']!,
                    snippet: stopInfo['stayDuration']!,
                  ) , 
            customInfoWindowBuilder:  (context) => _buildTrackInfoWindow(
                      locationName: stopInfo['locationName']!,
                      stayDuration: stopInfo['stayDuration']!,
                      stayTime: stopInfo['stayTime']!,
                    ) ,
          );
          markers.add(marker);
          
          DebugUtil.info('创建停留点标记 [$displayNumber]: ${point.position.latitude}, ${point.position.longitude}');
        } catch (e) {
          DebugUtil.error('创建停留点标记失败 [${i + 1}]: $e');
        }
      }
      
      stopMarkers.value = markers;
      DebugUtil.success('停留点标记创建完成，成功数量: ${markers.length}');
    } catch (e) {
      DebugUtil.error('创建停留点标记过程出错: $e');
    }
    
    return markers;
  }
  
  /// 🔧 计算适配后的尺寸（参考定位页面的DPI和屏幕缩放处理）
  /// 基于375px设计稿的比例计算，确保在不同设备上按比例缩放
  double _calculateAdaptedSize(double designSize) {
    final dpr = ui.window.devicePixelRatio;
    final screenWidth = ui.window.physicalSize.width / dpr; // 逻辑像素宽度
    const designWidth = 375.0;
    final screenScale = screenWidth / designWidth;
    // 先按屏幕比例缩放，再乘以DPI
    return designSize * screenScale * dpr;
  }

  /// 创建自定义停留点图标（黑色圆形/椭圆形，带数字）
  /// 参数: number - 显示的数字
  /// 根据数字位数自适应宽度：个位数为圆形，多位数为椭圆形
  Future<BitmapDescriptor> _createCustomStopPointIcon(String number) async {
    // 🔧 使用适配后的尺寸（设计稿：边框1.5px，最小半径10px，字体11px）
    // 停留点应该明显比起点终点(44x46)小，所以直径约20px，半径10px
    final borderWidth = _calculateAdaptedSize(1.5); // 边框宽度
    final minRadius = _calculateAdaptedSize(10.0); // 最小半径（圆形），直径20px
    final fontSize = _calculateAdaptedSize(11.0); // 字体大小（大一号）
    
    // 先测量文本尺寸
    final textPainter = TextPainter(
      text: TextSpan(
        text: number,
        style: TextStyle(
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
    
    // 🔧 使用适配后的边距（按比例缩小）
    final horizontalPadding = _calculateAdaptedSize(2.5); // 左右边距
    final verticalPadding = _calculateAdaptedSize(1.5); // 上下边距
    
    // 计算所需的宽度和高度（刚好包裹数字+少量空间）
    final requiredWidth = textWidth + horizontalPadding; // 文本宽度 + 左右边距
    final requiredHeight = textHeight + verticalPadding; // 文本高度 + 上下边距
    
    // 确定最终的宽度和高度（至少为圆形的直径）
    final width = max(requiredWidth, minRadius * 2);
    final height = max(requiredHeight, minRadius * 2);
    
    // 创建画布
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    final centerX = width / 2;
    final centerY = height / 2;
    
    // 绘制边框椭圆/圆形（颜色：#9FF5FF）
    final borderPaint = Paint()
      ..color = const Color(0xFF9FF5FF)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: width,
        height: height,
      ),
      borderPaint,
    );
    
    // 绘制黑色内部椭圆/圆形
    final fillPaint = Paint()
      ..color = Colors.black
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
  
  /// 创建轨迹起终点标记
  Future<List<Marker>> createTrackStartEndMarkers({
    required LatLng? startPoint,
    required LatLng? endPoint,
  }) async {
    final markers = <Marker>[];
    
    try {
      // 创建起点标记
      if (startPoint != null) {
        try {
          // 🔧 使用适配后的尺寸（设计稿：34x48），锚点在底部中心
          final adaptedWidth = _calculateAdaptedSize(34.0);
          final adaptedHeight = _calculateAdaptedSize(48.0);
          final startIcon = await BitmapDescriptor.fromAssetImage(
            ImageConfiguration(size: Size(adaptedWidth, adaptedHeight)),
            'assets/images/kissu_location_start.webp',
          );
          
          markers.add(Marker(
            position: startPoint,
            icon: startIcon,
            anchor: const Offset(0.5, 1.0), // 底部中心对齐
            infoWindow: const InfoWindow(title: '', snippet: ''),
            zIndex: 2.0, // 🎯 设置较低的层级，确保播放头像marker在起点标记之上显示
            onTap: (_) {
              DebugUtil.info('点击了轨迹起点');
              _moveMapToLocation(startPoint);
            },
          ));
          DebugUtil.success('✅ 轨迹起点标记创建成功');
        } catch (e) {
          DebugUtil.error('❌ 创建起点标记失败: $e，使用降级方案');
          // 降级方案：使用绿色圆点（使用适配后的尺寸）
          final fallbackSize = _calculateAdaptedSize(24.0);
          final fallbackIcon = await _createColoredCircleIcon(Colors.green, fallbackSize);
          markers.add(Marker(
            position: startPoint,
            icon: fallbackIcon,
            infoWindow: const InfoWindow(title: '', snippet: ''),
            zIndex: 2.0, // 🎯 设置较低的层级，确保播放头像marker在起点标记之上显示
            onTap: (_) {
              DebugUtil.info('点击了轨迹起点');
              _moveMapToLocation(startPoint);
            },
          ));
        }
      }
      
      // 创建终点标记（只要endPoint不为null就显示，locations字段里只要数据大于1就肯定有起点和终点）
      if (endPoint != null) {
        // 🎯 移除距离限制，只要locations数量大于1就显示终点
        try {
          // 终点使用头像标记（无动画），参考定位页头像样式
          final avatarUrl = getCurrentUserAvatar?.call() ?? '';
          final dpr = ui.window.devicePixelRatio;
          final screenWidth = ui.window.physicalSize.width / dpr;
          const designWidth = 375.0;
          const designAvatarSize = 50.0;
          final screenScale = screenWidth / designWidth;
          final avatarSize = designAvatarSize * screenScale * dpr;

          final avatarIcon = await MapMarkerUtil.createCircleAvatarMarker(
            avatarUrl,
            size: avatarSize,
          );

          // 添加伴侣底座（参考定位页面：使用伴侣底座样式）
          try {
            final markerBuilder = MarkerBuilder();
            // 计算设计稿级的底座尺寸，基于头像设计稿尺寸按比例缩放
            const designSmallPedestal = 21.0;
            const designAvatarSizeBase = 60.0;
            final designPedestalSize = designSmallPedestal * (designAvatarSizeBase / designAvatarSizeBase);
            final partnerPedestalIcon = await markerBuilder.createPedestalMarker(
              pedestalAsset: 'assets/3.0/kissu3_location_she.webp',
              designSize: designPedestalSize,
            );
            markers.add(Marker(
              position: endPoint,
              icon: partnerPedestalIcon,
              anchor: const Offset(0.5, 0.5),
              rotation: 0.0,
              zIndex: 1.0,
              clickable: false,
            ));
          } catch (pedestalError) {
            DebugUtil.warning('创建伴侣底座失败: $pedestalError');
          }

          markers.add(Marker(
            position: endPoint,
            icon: avatarIcon,
            anchor: const Offset(0.5, 1.0), // 底部中心对齐
            infoWindow: const InfoWindow(title: '', snippet: ''),
            zIndex: 2.0,
            onTap: (_) {
              DebugUtil.info('点击了轨迹终点');
              _moveMapToLocation(endPoint);
            },
          ));
          DebugUtil.success('✅ 轨迹终点头像标记创建成功');
        } catch (e) {
          DebugUtil.error('❌ 创建终点头像标记失败: $e，使用降级方案');
          // 降级方案：使用原有终点图标
          try {
            final adaptedWidth = _calculateAdaptedSize(44.0);
            final adaptedHeight = _calculateAdaptedSize(46.0);
            final endIcon = await BitmapDescriptor.fromAssetImage(
              ImageConfiguration(size: Size(adaptedWidth, adaptedHeight)),
              'assets/images/kissu_location_end.webp',
            );
            
            markers.add(Marker(
              position: endPoint,
              icon: endIcon,
              anchor: const Offset(0.59, 0.83),
              infoWindow: const InfoWindow(title: '', snippet: ''),
              zIndex: 2.0,
              onTap: (_) {
                DebugUtil.info('点击了轨迹终点');
                _moveMapToLocation(endPoint);
              },
            ));
            DebugUtil.success('✅ 终点降级标记创建成功');
          } catch (_) {
            // 再兜底：使用红色圆点
            final fallbackSize = _calculateAdaptedSize(24.0);
            final fallbackIcon = await _createColoredCircleIcon(Colors.red, fallbackSize);
            markers.add(Marker(
              position: endPoint,
              icon: fallbackIcon,
              infoWindow: const InfoWindow(title: '', snippet: ''),
              zIndex: 2.0,
              onTap: (_) {
                DebugUtil.info('点击了轨迹终点');
                _moveMapToLocation(endPoint);
              },
            ));
          }
        }
      }
      
      trackStartEndMarkers.value = markers;
      DebugUtil.info('起终点标记创建完成');
    } catch (e) {
      DebugUtil.error('创建起终点标记失败: $e');
    }
    
    return markers;
  }
  
  /// 创建彩色圆点图标
  Future<BitmapDescriptor> _createColoredCircleIcon(Color color, double size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    // 绘制圆点
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2,
      paint,
    );
    
    // 添加白色边框
    paint
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 1.5,
      paint,
    );
    
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }
  
  /// 创建当前位置标记
  Future<Marker?> createCurrentPositionMarker() async {
    if (currentPosition.value == null) return null;
    
    try {
      final avatarUrl = getCurrentUserAvatar?.call() ?? '';
      
      // 使用 MapMarkerUtil 创建圆形头像标记
      final avatarIcon = await MapMarkerUtil.createCircleAvatarMarker(
        avatarUrl,
        size: 80.0,
      );
      
      return Marker(
        position: currentPosition.value!,
        icon: avatarIcon,
        infoWindow: const InfoWindow(title: '当前位置', snippet: ''),
        zIndex: 100.0, // 🎯 设置中等层级，高于停留点但低于播放头像
      );
    } catch (e) {
      DebugUtil.error('创建当前位置标记失败: $e');
      return null;
    }
  }
  
  /// 获取所有标记
  List<Marker> getAllMarkers({
    Marker? replayAvatarMarker,
  }) {
    final markers = <Marker>[];
    
    // 添加停留点标记
    markers.addAll(stopMarkers);
    
    // 添加轨迹起终点标记
    markers.addAll(trackStartEndMarkers);
    
    // 🎯 添加临时 InfoWindow 标记（如果存在）
    if (_tempInfoWindowMarker != null) {
      try {
        markers.add(_tempInfoWindowMarker!);
        DebugUtil.info('✅ 已添加临时 InfoWindow 标记到地图');
      } catch (e) {
        DebugUtil.error('❌ 添加临时 InfoWindow 标记失败: $e');
      }
    }
    
    // 添加播放头像标记（如果存在且正在播放或暂停）
    if (replayAvatarMarker != null) {
      try {
        markers.add(replayAvatarMarker);
        DebugUtil.info('✅ 已添加播放头像标记到地图');
      } catch (e) {
        DebugUtil.error('❌ 添加播放头像标记失败: $e');
      }
      // 如果有播放头像标记，就不添加普通的当前位置标记
      return markers;
    }
    
    // 只有在没有播放头像标记时才显示普通的当前位置标记
    if (currentPosition.value != null) {
      createCurrentPositionMarker().then((marker) {
        if (marker != null) {
          markers.add(marker);
        }
      });
    }
    
    return markers;
  }
  
  /// 处理停留点点击
  /// 🎯 注意：当点击标记时，Android 原生代码会自动显示自定义 InfoWindow（因为标记已设置 isTrackStyle: true）
  /// 所以这里不需要手动调用 _showStopPointInfo，只需要处理其他逻辑（移动地图、绘制圆圈等）
  void handleStopPointTap(dynamic stopPoint) {
     

    DebugUtil.info('停留点被点击: ${stopPoint.title}');
    
    // 上报停留点点击埋点
    _trackStopPointClick();
    
    // 🎯 不清除 InfoWindow，因为标记会自动显示自定义 InfoWindow
    // 只清除圆圈，然后重新绘制
    clearAllHighlightCircles();
    
    // 延迟执行，避免与清除操作冲突
    Future.delayed(const Duration(milliseconds: 100), () {
      // 1. 先收起下半屏到底部吸顶位置
      collapseToBottomPosition?.call();
      DebugUtil.info('🎯 收起下半屏到底部吸顶位置');
      
      // 2. 等待面板收起动画完成后移动地图
      Future.delayed(const Duration(milliseconds: 300), () {
        _moveMapToLocation(stopPoint.position);
        
        // 3. 等待地图移动完成后绘制高亮圆圈
        // 🎯 不需要手动显示 InfoWindow，因为标记会自动显示自定义 InfoWindow
        Future.delayed(const Duration(milliseconds: 500), () {
          DebugUtil.info('🎯 地图移动完成，现在绘制高亮圆圈');
          drawHighlightCircle(stopPoint.position);
        });
      });
    });
  }

 
  
  /// 上报停留点点击埋点
  Future<void> _trackStopPointClick() async {
    try {
      await TrackingService.trackFootprintStayButton();
      DebugUtil.info('✅ 足迹页面-停留点点击埋点上报成功');
    } catch (e) {
      DebugUtil.error('❌ 足迹页面-停留点点击埋点上报失败: $e');
    }
  }
  
  /// 清理所有标记和高亮
  void clearAllMarkers() {
    stopMarkers.clear();
    trackStartEndMarkers.clear();
    currentPosition.value = null;
    clearAllHighlightCircles();
    DebugUtil.info('所有标记已清理');
  }
  
  /// 立即清理地图上的所有内容
  void clearMapImmediately() {
    DebugUtil.info('🧹 立即清理地图内容...');
    
    // 清除所有标记
    stopMarkers.clear();
    trackStartEndMarkers.clear();
    currentPosition.value = null;
    stopRecords.clear();
    
    // 清除高亮
    clearMapHighlights();
    
    // 隐藏所有InfoWindow
    hideAllInfoWindows();
  }
  
  /// 更新停留记录列表（从原始API数据创建）
  void updateStopRecordsFromApiData(dynamic locationData) {
    DebugUtil.info('🔍 [StopRecords] 开始更新停留记录列表');
    DebugUtil.info('🔍 [StopRecords] locationData类型: ${locationData?.runtimeType}');
    
    if (locationData == null) {
      DebugUtil.warning('⚠️ [StopRecords] locationData为null，清空stopRecords');
      stopRecords.clear();
      return;
    }
    
    if (locationData.trace == null) {
      DebugUtil.warning('⚠️ [StopRecords] trace为null，清空stopRecords');
      stopRecords.clear();
      return;
    }
    
    if (locationData.trace!.stops == null) {
      DebugUtil.warning('⚠️ [StopRecords] stops为null，清空stopRecords');
      stopRecords.clear();
      return;
    }
    
    final apiStops = locationData.trace!.stops;
    DebugUtil.info('📊 [StopRecords] stops数量: ${apiStops.length}');
    
    if (apiStops.isEmpty) {
      DebugUtil.warning('⚠️ [StopRecords] stops为空列表，清空stopRecords');
      stopRecords.clear();
      return;
    }
    
    // 处理停留记录数据转换
    try {
      final processedRecords = <StopRecord>[];
      for (final stop in apiStops) {
        DebugUtil.info('📍 [StopRecords] 处理stop: ${stop.locationName}, lat=${stop.lat}, lng=${stop.lng}');
        processedRecords.add(StopRecord(
          latitude: stop.lat,
          longitude: stop.lng,
          locationName: stop.locationName ?? '',
          startTime: stop.startTime ?? '',
          endTime: stop.endTime?.isNotEmpty == true ? stop.endTime! : (stop.startTime ?? ''),
          duration: stop.duration ?? '',
          status: stop.status ?? '',
          pointType: stop.pointType ?? '',
          serialNumber: stop.serialNumber ?? '',
        ));
      }
      
      DebugUtil.info('📝 [StopRecords] 处理完成，准备更新stopRecords，当前stopRecords.length=${stopRecords.length}');
      stopRecords.value = processedRecords;
      DebugUtil.success('✅ [StopRecords] 停留记录更新完成，新stopRecords.length=${stopRecords.length}');
      
      // 再次确认数据
      if (stopRecords.isEmpty) {
        DebugUtil.error('❌ [StopRecords] 更新后stopRecords仍为空！');
      }
    } catch (e, stackTrace) {
      DebugUtil.error('❌ [StopRecords] 处理停留记录失败: $e');
      DebugUtil.error('❌ [StopRecords] 堆栈: $stackTrace');
      stopRecords.clear();
    }
  }
}
