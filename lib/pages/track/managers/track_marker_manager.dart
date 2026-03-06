import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/pages/usage_report/widgets/map_marker_util.dart';
import 'package:kissu_app/pages/track/stay_point.dart';
import 'package:kissu_app/model/location_model/location_model.dart';

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
    
    logDebug('🎯 设置初始坐标信息: $latitude, $longitude, 位置: $locationName, 目标用户: ${targetUserType == 1 ? "自己" : "另一半"}');
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
      logWarning('地图未就绪或控制器为空，无法移动地图位置');
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
    
    logDebug('🎯 [AutoShowInfoWindow] 开始执行完整流程...');
    logDebug('🎯 [AutoShowInfoWindow] 目标坐标: (${initialInfo.latitude}, ${initialInfo.longitude})');
    logDebug('🎯 [AutoShowInfoWindow] 停留点总数: ${stopPoints.length}');
    
    // 在停留点中查找匹配的点
    for (final stopPoint in stopPoints) {
      final distance = _calculateDistance(
        LatLng(initialInfo.latitude, initialInfo.longitude),
        stopPoint.position,
      );
      
      logDebug('🎯 [AutoShowInfoWindow] 检查停留点: ${stopPoint.title}, 距离: ${distance.toStringAsFixed(2)}米');
      
      // 如果距离小于50米，认为是同一个点
      if (distance < 50) {
        logDebug('✅ [AutoShowInfoWindow] 找到匹配的停留点！');
        
        // 完整流程执行
        Future.delayed(const Duration(milliseconds: 100), () {
          // 1. 先清除之前的高亮
          clearMapHighlights();
          logDebug('🎯 [AutoShowInfoWindow] 步骤1: 清除旧高亮');
          
          // 2. 移动相机到停留点
          Future.delayed(const Duration(milliseconds: 100), () {
            _moveMapToLocation(stopPoint.position);
            logDebug('🎯 [AutoShowInfoWindow] 步骤2: 移动相机到目标点');
            
            // 3. 等待相机移动完成后显示InfoWindow
            Future.delayed(const Duration(milliseconds: 500), () async {
              await _showStopPointInfo(stopPoint);
              logDebug('🎯 [AutoShowInfoWindow] 步骤3: 显示InfoWindow');
              
              // 4. InfoWindow创建完成后绘制高亮圆圈
              Future.delayed(const Duration(milliseconds: 200), () {
                drawHighlightCircle(stopPoint.position);
                logDebug('🎯 [AutoShowInfoWindow] 步骤4: 绘制高亮圆圈');
                
                // 5. 智能展开底部面板
                expandToMiddlePosition?.call();
                logDebug('🎯 [AutoShowInfoWindow] 步骤5: 展开底部面板');
                
                logDebug('✅ [AutoShowInfoWindow] 完整流程执行完成！');
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
      logDebug('🎯 显示停留点InfoWindow: ${stopPoint.title}');
      
      // 🎯 直接使用临时 Marker 方式，因为直接调用 showInfoWindow() 可能不会触发适配器
      // 临时 Marker 会在创建时自动显示 InfoWindow（如果设置了 autoShowCustomInfoWindow: true）
      await showInfoWindowForStopPoint(stopPoint);
      
      logDebug('✅ InfoWindow 已通过临时 Marker 方式显示');
    } catch (e) {
      logError('❌ 显示停留点InfoWindow失败: $e');
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
      
      logDebug('🎯 直接在坐标位置创建 InfoWindow: $locationName');
      logDebug('🎯 目标坐标: ($position)');
      
      // 在指定位置创建临时 Marker 并显示 InfoWindow
      final stopInfo = _parseStopInfo(stopPoint);
      // 修改为只显示地址信息，与位置提醒页面保持一致
      final String infoTitle = locationName.contains('\n') ? locationName.split('\n').first : locationName;
      final String infoSnippet = locationName.contains('\n') ? locationName.split('\n').skip(1).join('\n') : '';
      
      // 先清除之前的临时 InfoWindow Marker（如果有）
      _clearTempInfoWindowMarker();
      
      // 🎯 等待清除操作完成，确保地图更新生效
      await Future.delayed(const Duration(milliseconds: 50));
      
      // 创建临时 Marker，设置自动显示 InfoWindow 并支持拖拽
      // 使用与位置提醒页面相同的 marker 图标
      final markerIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/3.0/kissu3_map_marker_icon.webp',
      );

      final tempMarker = Marker(
        position: position,
        icon: markerIcon, // 🎯 显示与位置提醒页面相同的 marker 图标
        // 移除 anchor 设置，与位置提醒页面保持一致，使用默认锚点
        infoWindowEnable: true,
        autoShowCustomInfoWindow: true, // 🎯 关键：自动显示 InfoWindow
        draggable: true, // 🎯 启用拖拽功能
        // 移除 isTrackStyle，使用 Flutter 的 customInfoWindowBuilder，与位置提醒页面保持一致
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
          logDebug('🎯 InfoWindow Marker 拖拽结束，新位置: ${newPosition.latitude}, ${newPosition.longitude}');
          drawHighlightCircle(newPosition); // 这个方法会先清除现有圆圈再创建新的
        },
        onTap: (String markerId) {
          logDebug('🎯 点击临时 InfoWindow 标记');
        },
      );
      
      // 保存临时标记的引用
      _tempInfoWindowMarker = tempMarker;
      
      // 🎯 先绘制高亮圆圈（在地图更新前添加，这样只需要一次地图更新）
      drawHighlightCircle(position);
      
      // 🎯 触发地图更新以显示临时标记和圆圈（一次更新包含所有元素，性能最优）
      _forceMapUpdate();
      
      logDebug('✅ 临时 InfoWindow 和高亮圆圈已创建并触发地图更新');
      
    } catch (e) {
      logError('❌ 显示停留点 InfoWindow 失败: $e');
    }
  }
  
  /// 清除临时 InfoWindow Marker
  void _clearTempInfoWindowMarker() {
    if (_tempInfoWindowMarker != null) {
      logDebug('🧹 清除之前的临时 InfoWindow Marker 和高亮圆圈');
      _tempInfoWindowMarker = null;
      
      // 🎯 同时清除高亮圆圈
      highlightCircles.clear();
      
      // 清除后触发地图更新
      _forceMapUpdate();
      
      logDebug('✅ 临时标记和圆圈已清除');
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
    logDebug('🔄 [ForceMapUpdate] 开始强制更新地图');
    
    // 强制刷新所有响应式变量，让UI重新构建
    stopMarkers.refresh();
    trackStartEndMarkers.refresh();
    highlightCircles.refresh(); // 🎯 刷新高亮圆圈
    
    logDebug('✅ [ForceMapUpdate] 地图更新完成（包含圆圈）');
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
      if (stopPoint is TrackStopPoint) {
        // TrackStopPoint类型有startTime和endTime属性
        if (stopPoint.startTime?.isNotEmpty == true) {
          if (stopPoint.endTime?.isNotEmpty == true && stopPoint.endTime != stopPoint.startTime) {
            // 有开始和结束时间
            stayTime = '${stopPoint.startTime}~${stopPoint.endTime}';
          } else {
            // 只有开始时间
            stayTime = stopPoint.startTime!;
          }
        }
      }
      // StayPoint类型没有startTime和endTime属性，stayTime保持为空
    } catch (e) {
      logError('解析停留时间段失败: $e');
    }
    
    return {
      'locationName': locationName,
      'stayDuration': stayDuration,
      'stayTime': stayTime,
    };
  }
  
  /// 🎯 构建轨迹样式的InfoWindow（与位置提醒页面保持一致）
  /// 只显示地址信息，样式与位置提醒页面保持一致
  Widget _buildTrackInfoWindow({
    required String locationName,
    required String stayDuration,
    required String stayTime,
  }) {
    // 解析地址信息，模拟位置提醒页面的地址格式
    final address = locationName;
    final mainAddress = address.contains('\n') ? address.split('\n').first : address;
    final detailAddress = address.contains('\n') ? address.split('\n').skip(1).join('\n') : '';

    return Container(
      width: 220, // 与位置提醒页面保持一致
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mainAddress,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          if (detailAddress.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              detailAddress,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
            ),
          ],
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
        logDebug('🎯 已隐藏所有 InfoWindow');
      } catch (e) {
        logError('❌ 隐藏所有 InfoWindow 失败: $e');
      }
    }
  }
  
  /// 清除所有高亮圆圈（使用原生地图API）
  void clearAllHighlightCircles() {
    logDebug('🧹 [HighlightCircles] 清除围栏圆圈');
    
    // 清空圆圈列表
    highlightCircles.clear();
  }
  
  /// 🎯 统一清除：同时隐藏 InfoWindow 和清除圆圈
  /// 确保 InfoWindow 和圆圈在相同时机出现和消失
  void clearMapHighlights() {
    logDebug('🧹 [MapHighlights] 清除所有地图高亮（InfoWindow + 围栏圆圈）');
    hideAllInfoWindows();
    clearAllHighlightCircles();
  }
  
  /// 🎯 不会隐藏 InfoWindow，确保圆圈和 InfoWindow 同时显示
  void drawHighlightCircle(LatLng center) {
    logDebug('🎯 开始绘制高亮圆圈: ${center.latitude}, ${center.longitude}');
    
    // 先清除已有的圆圈
    highlightCircles.clear();
    
    // 创建新的高亮圆圈，与位置提醒页面保持一致
    final circle = Circle(
      center: center,
      radius: 100, // 100米半径
      strokeColor: const Color(0x55FFFFFF), // 与位置提醒页面一致：半透明白色边框
      fillColor: const Color(0x55FFD6EC), // 与位置提醒页面一致：粉色半透明填充
      strokeWidth: 5, // 与位置提醒页面一致
    );
    
    highlightCircles.add(circle);
    
    logDebug('✅ 高亮圆圈已添加，当前数量: ${highlightCircles.length}');
  }
  
  /// 创建停留点标记
  /// 🚀 性能优化：减少循环内日志输出，只在关键节点打印摘要
  Future<List<Marker>> createStopMarkers({
    required List<dynamic> stopPoints,
    required Function(dynamic) onStopPointTap,
    LatLng? startPoint,
    LatLng? endPoint,
  }) async {
    if (stopPoints.isEmpty) {
      return [];
    }
    
    final markers = <Marker>[];
    int skippedCount = 0;
    final startTime = DateTime.now();
    
    try {
      for (int i = 0; i < stopPoints.length; i++) {
        final point = stopPoints[i];
        
        try {
          // 🎯 使用停留点的 serialNumber 作为显示编号（与列表保持一致）
          final displayNumber = point.serialNumber;
          
          if (displayNumber == null || displayNumber.isEmpty) {
            skippedCount++;
            continue;
          }
          
          // 创建自定义停留点图标（粉色圆形/椭圆形，带数字）
          final customIcon = await _createCustomStopPointIcon(displayNumber);
          
          // 解析停留点信息
          final stopInfo = _parseStopInfo(point);

          final marker = Marker(
            position: point.position,
            icon: customIcon,
            onTap: (_) => onStopPointTap(point),
            infoWindowEnable: true,
            stayDuration: stopInfo['stayDuration'],
            stayTime: stopInfo['stayTime'],
            zIndex: 1.0,
            infoWindow: InfoWindow(
              title: stopInfo['locationName']!.contains('\n')
                  ? stopInfo['locationName']!.split('\n').first
                  : stopInfo['locationName']!,
              snippet: stopInfo['locationName']!.contains('\n')
                  ? stopInfo['locationName']!.split('\n').skip(1).join('\n')
                  : '',
            ), 
            customInfoWindowBuilder: (context) => _buildTrackInfoWindow(
              locationName: stopInfo['locationName']!,
              stayDuration: stopInfo['stayDuration']!,
              stayTime: stopInfo['stayTime']!,
            ),
          );
          markers.add(marker);
        } catch (e) {
          logError('创建停留点标记失败 [${i + 1}]: $e');
        }
      }
      
      stopMarkers.value = markers;
      
      // 🚀 只打印摘要日志
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      logDebug('🎯 [CreateStopMarkers] 完成: 输入=${stopPoints.length}, 成功=${markers.length}, 跳过=$skippedCount, 耗时=${duration}ms');
    } catch (e) {
      logError('创建停留点标记过程出错: $e');
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

  /// 🔧 从asset加载图片并缩放到指定尺寸，返回BitmapDescriptor
  /// 这个方法确保在所有设备上图片尺寸一致，不依赖ImageConfiguration.size
  Future<BitmapDescriptor> _createScaledAssetIcon(String assetPath, int width, int height) async {
    // 加载原始图片
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
      targetHeight: height,
    );
    final frameInfo = await codec.getNextFrame();
    final image = frameInfo.image;
    
    // 转换为字节数据
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('无法转换图片为字节数据');
    }
    
    return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
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
          // 🔧 使用手动加载和缩放图片的方式，确保在所有设备上尺寸一致
          // BitmapDescriptor.fromAssetImage 的 ImageConfiguration.size 在某些设备上不生效
          final dpr = ui.window.devicePixelRatio;
          final screenWidth = ui.window.physicalSize.width / dpr;
          const designWidth = 375.0;
          final screenScale = screenWidth / designWidth;
          // 计算物理像素尺寸（用于绘制）
          final adaptedWidth = (34.0 * screenScale * dpr).round();
          final adaptedHeight = (48.0 * screenScale * dpr).round();
          logDebug('📍 起点marker尺寸: ${adaptedWidth}x$adaptedHeight (dpr=$dpr, screenScale=$screenScale)');
          
          final startIcon = await _createScaledAssetIcon(
            'assets/images/kissu_location_start.webp',
            adaptedWidth,
            adaptedHeight,
          );
          
          markers.add(Marker(
            position: startPoint,
            icon: startIcon,
            anchor: const Offset(0.5, 1.0), // 底部中心对齐
            infoWindow: const InfoWindow(title: '', snippet: ''),
            zIndex: 2.0, // 🎯 设置较低的层级，确保播放头像marker在起点标记之上显示
            onTap: (_) {
              logDebug('点击了轨迹起点');
              _moveMapToLocation(startPoint);
            },
          ));
          logDebug('✅ 轨迹起点标记创建成功');
        } catch (e) {
          logError('❌ 创建起点标记失败: $e，使用降级方案');
          // 降级方案：使用绿色圆点（使用适配后的尺寸）
          final fallbackSize = _calculateAdaptedSize(24.0);
          final fallbackIcon = await _createColoredCircleIcon(Colors.green, fallbackSize);
          markers.add(Marker(
            position: startPoint,
            icon: fallbackIcon,
            infoWindow: const InfoWindow(title: '', snippet: ''),
            zIndex: 2.0, // 🎯 设置较低的层级，确保播放头像marker在起点标记之上显示
            onTap: (_) {
              logDebug('点击了轨迹起点');
              _moveMapToLocation(startPoint);
            },
          ));
        }
      }
      
      // 🔥 修复：终点使用图标而非头像marker
      if (endPoint != null) {
        try {
          // 使用终点图标（不使用头像）
          final dpr = ui.window.devicePixelRatio;
          final screenWidth = ui.window.physicalSize.width / dpr;
          const designWidth = 375.0;
          final screenScale = screenWidth / designWidth;
          final adaptedWidth = 44.0 * screenScale;  // 逻辑像素
          final adaptedHeight = 46.0 * screenScale; // 逻辑像素
          final endIcon = await BitmapDescriptor.fromAssetImage(
            ImageConfiguration(size: Size(adaptedWidth, adaptedHeight), devicePixelRatio: dpr),
            'assets/images/kissu_location_end.webp',
          );
          
          markers.add(Marker(
            position: endPoint,
            icon: endIcon,
            anchor: const Offset(0.59, 0.83),
            infoWindow: const InfoWindow(title: '', snippet: ''),
            zIndex: 2.0,
            onTap: (_) {
              logDebug('点击了轨迹终点');
              _moveMapToLocation(endPoint);
            },
          ));
          logDebug('✅ 轨迹终点图标创建成功');
        } catch (e) {
          logError('❌ 创建终点图标失败: $e');
          // 兜底：使用红色圆点
          final fallbackSize = _calculateAdaptedSize(24.0);
          final fallbackIcon = await _createColoredCircleIcon(Colors.red, fallbackSize);
          markers.add(Marker(
            position: endPoint,
            icon: fallbackIcon,
            infoWindow: const InfoWindow(title: '', snippet: ''),
            zIndex: 2.0,
            onTap: (_) {
              logDebug('点击了轨迹终点');
              _moveMapToLocation(endPoint);
            },
          ));
        }
      }
      
      trackStartEndMarkers.value = markers;
      logDebug('起终点标记创建完成');
    } catch (e) {
      logError('创建起终点标记失败: $e');
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
      logError('创建当前位置标记失败: $e');
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
        logDebug('✅ 已添加临时 InfoWindow 标记到地图');
      } catch (e) {
        logError('❌ 添加临时 InfoWindow 标记失败: $e');
      }
    }
    
    // 添加播放头像标记（如果存在且正在播放或暂停）
    if (replayAvatarMarker != null) {
      try {
        markers.add(replayAvatarMarker);
        logDebug('✅ 已添加播放头像标记到地图');
      } catch (e) {
        logError('❌ 添加播放头像标记失败: $e');
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
  /// 🎯 注意：现在使用 Flutter 的 customInfoWindowBuilder，与位置提醒页面保持一致
  /// 所以这里不需要手动调用 _showStopPointInfo，只需要处理其他逻辑（移动地图、绘制圆圈等）
  void handleStopPointTap(dynamic stopPoint) {
     

    logDebug('停留点被点击: ${stopPoint.title}');
    
 
    
    // 🎯 不清除 InfoWindow，因为标记会自动显示自定义 InfoWindow
    // 只清除圆圈，然后重新绘制
    clearAllHighlightCircles();
    
    // 延迟执行，避免与清除操作冲突
    Future.delayed(const Duration(milliseconds: 100), () {
      // 1. 先收起下半屏到底部吸顶位置
      collapseToBottomPosition?.call();
      logDebug('🎯 收起下半屏到底部吸顶位置');
      
      // 2. 等待面板收起动画完成后移动地图
      Future.delayed(const Duration(milliseconds: 300), () {
        _moveMapToLocation(stopPoint.position);
        
        // 3. 等待地图移动完成后绘制高亮圆圈
        // 🎯 不需要手动显示 InfoWindow，因为标记会自动显示自定义 InfoWindow
        Future.delayed(const Duration(milliseconds: 500), () {
          logDebug('🎯 地图移动完成，现在绘制高亮圆圈');
          drawHighlightCircle(stopPoint.position);
        });
      });
    });
  }

 
  
 
  
  /// 清理所有标记和高亮
  void clearAllMarkers() {
    stopMarkers.clear();
    trackStartEndMarkers.clear();
    currentPosition.value = null;
    clearAllHighlightCircles();
    logDebug('所有标记已清理');
  }
  
  /// 立即清理地图上的所有内容
  void clearMapImmediately() {
    logDebug('🧹 立即清理地图内容...');
    
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
  /// 🚀 性能优化：减少循环内日志输出
  void updateStopRecordsFromApiData(dynamic locationData) {
    if (locationData == null || locationData.trace == null || locationData.trace!.stops == null) {
      stopRecords.clear();
      return;
    }
    
    final apiStops = locationData.trace!.stops;
    
    if (apiStops.isEmpty) {
      stopRecords.clear();
      return;
    }
    
    // 处理停留记录数据转换（不打印每个点的日志）
    try {
      final processedRecords = <StopRecord>[];
      for (final stop in apiStops) {
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
      
      stopRecords.value = processedRecords;
      
      // 🚀 只打印摘要日志
      logDebug('📊 [StopRecords] 更新完成: ${processedRecords.length}条记录');
    } catch (e) {
      logError('❌ [StopRecords] 处理停留记录失败: $e');
      stopRecords.clear();
    }
  }
}
