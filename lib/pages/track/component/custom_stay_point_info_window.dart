import 'dart:async';
import 'package:flutter/material.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'dart:math' as math;

/// 自定义停留点信息窗口
class CustomStayPointInfoWindow extends StatelessWidget {
  final String locationName;
  final String duration;
  final String startTime;
  final String endTime;
  final VoidCallback? onClose;

  const CustomStayPointInfoWindow({
    Key? key,
    required this.locationName,
    required this.duration,
    required this.startTime,
    required this.endTime,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 213,
      height: 106,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/kissu_marker_bg.png'),
          fit: BoxFit.fill,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 9, 30, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 第一行：位置名称
                Text(
                  locationName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // 第二行：图标 + 停留时长
                Row(
                  children: [
                    Image.asset(
                      'assets/kissu_track_location.webp',
                      width: 18,
                      height: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      duration,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF333333),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
                
                // 第三行：时间范围
                Text(
                  '$startTime~$endTime',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF999999),
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
           // 关闭按钮
            Positioned(
              top: 3,
              right: 5,
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(
                    'assets/kissu_marker_close.png',
                    width: 14,
                    height: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
/// 自定义停留点信息窗口管理器
class CustomStayPointInfoWindowManager {
  static OverlayEntry? _currentOverlay;
  static LatLng? _currentStopPointLocation; // 当前停留点位置
  static AMapController? _mapController; // 地图控制器
  static BuildContext? _context; // 上下文引用
  static String? _currentLocationName;
  static String? _currentDuration;
  static String? _currentStartTime;
  static String? _currentEndTime;
  static CameraPosition? _lastCameraPosition; // 存储最新的相机位置
  
  // 防抖和性能优化
  static Timer? _updateTimer;
  static const int _updateDelay = 16; // 60fps，防止过度频繁更新
  
  // 点击保护机制
  static DateTime? _lastShowTime; // 最后一次显示InfoWindow的时间
  static const Duration _protectionDuration = Duration(milliseconds: 500); // 保护期500ms
  
  // 地图移动保护机制：防止地图移动时被滚动事件隐藏
  static bool _isMapMoving = false;
  static DateTime? _mapMoveStartTime;
  static const Duration _mapMoveProtectionDuration = Duration(milliseconds: 2000);
  
  // 智能滚动检测：特别处理边界滚动和连续滚动
  static DateTime? _lastScrollTime;
  static Timer? _scrollDebounceTimer;
  static int _consecutiveScrollCount = 0;
  
  /// 显示自定义信息窗口
  static void showInfoWindow({
    required BuildContext context,
    required LatLng stopPointLocation, // 经纬度坐标
    required AMapController mapController, // 地图控制器
    required String locationName,
    required String duration,
    required String startTime,
    required String endTime,
    VoidCallback? onClose,
  }) {
    // 关闭已存在的窗口
    forceHideInfoWindow();
    
    // 记录显示时间，用于保护机制
    _lastShowTime = DateTime.now();
    
    // 保存当前信息
    _context = context;
    _currentStopPointLocation = stopPointLocation;
    _mapController = mapController;
    _currentLocationName = locationName;
    _currentDuration = duration;
    _currentStartTime = startTime;
    _currentEndTime = endTime;
    
    // 计算InfoWindow位置并显示
    _updateInfoWindowPosition();
  }
  
  /// 更新相机位置（由地图移动事件调用）
  static void updateCameraPosition(CameraPosition position) {
    print('📍 相机位置更新: ${position.target.latitude}, ${position.target.longitude}, zoom: ${position.zoom}');
    _lastCameraPosition = position;
    
    // 如果当前有InfoWindow显示，则使用防抖机制更新其位置
    if (_currentStopPointLocation != null) {
      print('🔄 准备更新InfoWindow位置（防抖中）...');
      _debounceUpdateInfoWindow();
    } else {
      print('⚠️  没有当前停留点，跳过InfoWindow更新');
    }
  }
  
  /// 防抖更新InfoWindow位置
  static void _debounceUpdateInfoWindow() {
    // 取消之前的定时器
    _updateTimer?.cancel();
    
    // 设置新的定时器
    _updateTimer = Timer(Duration(milliseconds: _updateDelay), () {
      print('🔄 防抖结束，开始更新InfoWindow位置...');
      _updateInfoWindowPosition();
    });
  }
  
  /// 更新InfoWindow位置（地图移动时调用）
  static void _updateInfoWindowPosition() {
    print('🎯 _updateInfoWindowPosition 被调用');
    if (_currentStopPointLocation == null || 
        _mapController == null || 
        _context == null) {
      print('❌ 缺少必要参数: stopPoint=${_currentStopPointLocation}, controller=${_mapController}, context=${_context}');
      return;
    }
    
    print('📍 当前停留点位置: ${_currentStopPointLocation!.latitude}, ${_currentStopPointLocation!.longitude}');
    
    // 移除旧的overlay
    _currentOverlay?.remove();
    
    // 使用高精度坐标转换算法
    final screenPosition = _highPrecisionLatLngToScreenPoint(_currentStopPointLocation!, _context!);
    
    print('🖥️ 屏幕坐标转换结果: ${screenPosition.dx}, ${screenPosition.dy}');
    
    // 不在这里调整位置，直接使用计算出的屏幕坐标
    // 位置调整在_PositionedInfoWindow中统一处理
    final adjustedPosition = Offset(
      screenPosition.dx, 
      screenPosition.dy, // 使用原始屏幕坐标
    );
    
    print('✅ 计算出的屏幕坐标: ${adjustedPosition.dx}, ${adjustedPosition.dy}');
    
    _currentOverlay = OverlayEntry(
      builder: (context) => _PositionedInfoWindow(
        position: adjustedPosition,
        locationName: _currentLocationName!,
        duration: _currentDuration!,
        startTime: _currentStartTime!,
        endTime: _currentEndTime!,
        onClose: hideInfoWindow,
      ),
    );
    
    try {
      Overlay.of(_context!).insert(_currentOverlay!);
      print('✅ InfoWindow 成功插入到 Overlay');
    } catch (e) {
      print('❌ InfoWindow插入失败: $e');
    }
  }
  
  
  
  /// 高精度的经纬度转屏幕坐标算法
  /// 使用优化的计算方法减少误差
  static Offset _highPrecisionLatLngToScreenPoint(LatLng location, BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final mapHeight = screenSize.height * 0.6; // 地图区域高度
    
    print('📱 屏幕尺寸: ${screenSize.width} x ${screenSize.height}, 地图高度: $mapHeight');
    
    // 如果没有相机位置信息，使用屏幕中心
    if (_lastCameraPosition == null) {
      print('⚠️  没有相机位置信息，使用屏幕中心');
      return Offset(screenSize.width / 2, mapHeight / 2);
    }
    
    final camera = _lastCameraPosition!;
    final cameraTarget = camera.target;
    final zoom = camera.zoom;
    
    print('📷 相机信息: 中心(${cameraTarget.latitude}, ${cameraTarget.longitude}), 缩放: $zoom');
    
    // 使用更高精度的计算
    // 基于Web墨卡托投影，但针对小范围区域优化
    final double zoomFactor = math.pow(2, zoom).toDouble();
    final double scale = 256.0 * zoomFactor / 360.0; // 每度对应的像素数
    
    // 计算经纬度差异
    final double deltaLng = location.longitude - cameraTarget.longitude;
    final double deltaLat = location.latitude - cameraTarget.latitude;
    
    // 转换为屏幕坐标偏移
    final double screenDeltaX = deltaLng * scale;
    
    // 纬度转换需要考虑墨卡托投影的非线性
    final double lat1Rad = cameraTarget.latitude * math.pi / 180.0;
    final double lat2Rad = location.latitude * math.pi / 180.0;
    final double y1 = math.log(math.tan(math.pi / 4.0 + lat1Rad / 2.0));
    final double y2 = math.log(math.tan(math.pi / 4.0 + lat2Rad / 2.0));
    final double screenDeltaY = (y1 - y2) * scale * 180.0 / math.pi;
    
    // 计算最终屏幕坐标
    double screenX = (screenSize.width / 2) + screenDeltaX;
    double screenY = (mapHeight / 2) + screenDeltaY;
    
    print('🌐 坐标差异: deltaLng=$deltaLng, deltaLat=$deltaLat');
    print('📏 屏幕偏移: deltaX=$screenDeltaX, deltaY=$screenDeltaY');
    print('🎯 最终屏幕坐标: ($screenX, $screenY)');
    
    return Offset(screenX, screenY);
  }
  
  
  
  /// 地图移动时调用此方法更新位置
  static void onMapMove() {
    if (_currentStopPointLocation != null) {
      _updateInfoWindowPosition();
    }
  }
  
  /// 隐藏信息窗口
  static void hideInfoWindow() {
    // 检查是否在点击保护期内
    if (_lastShowTime != null) {
      final timeSinceShow = DateTime.now().difference(_lastShowTime!);
      if (timeSinceShow < _protectionDuration) {
        // 在保护期内，不隐藏InfoWindow
        return;
      }
    }
    
    // 检查是否在地图移动保护期内
    if (_isMapMoving || _mapMoveStartTime != null) {
      final timeSinceMove = _mapMoveStartTime != null 
        ? DateTime.now().difference(_mapMoveStartTime!)
        : Duration.zero;
      if (_isMapMoving || timeSinceMove < _mapMoveProtectionDuration) {
        // 地图正在移动或在移动保护期内，不隐藏InfoWindow
        print('🛡️ 地图移动保护期内，不隐藏InfoWindow');
        return;
      }
    }
    
    // 取消防抖定时器
    _updateTimer?.cancel();
    _updateTimer = null;
    
    _currentOverlay?.remove();
    _currentOverlay = null;
    _currentStopPointLocation = null;
    _mapController = null;
    _context = null;
    _currentLocationName = null;
    _currentDuration = null;
    _currentStartTime = null;
    _currentEndTime = null;
    _lastCameraPosition = null;
    _lastShowTime = null; // 清除保护时间
  }
  
  /// 智能滚动检测：防止边界反弹误触发
  static void onScrollDetected(double scrollDelta) {
    final now = DateTime.now();
    
    // 如果在保护期内，直接忽略
    if (_isInProtectionPeriod() || _isMapMoving) {
      return;
    }
    
    // 记录滚动时间和累计计数
    if (_lastScrollTime == null || now.difference(_lastScrollTime!) > Duration(milliseconds: 100)) {
      _consecutiveScrollCount = 1;
    } else {
      _consecutiveScrollCount++;
    }
    _lastScrollTime = now;
    
    // 取消之前的防抖定时器
    _scrollDebounceTimer?.cancel();
    
    // 大幅滚动：立即隐藏
    if (scrollDelta.abs() > 25) {
      hideInfoWindow();
      return;
    }
    
    // 中等滚动：检查是否为连续滚动
    if (scrollDelta.abs() > 15) {
      if (_consecutiveScrollCount >= 2) {
        hideInfoWindow();
        return;
      }
    }
    
    // 小幅滚动：延迟检查，可能是边界反弹
    if (scrollDelta.abs() > 10) {
      _scrollDebounceTimer = Timer(Duration(milliseconds: 200), () {
        if (_consecutiveScrollCount >= 3) {
          hideInfoWindow();
        }
      });
    }
  }
  
  /// 检查是否在保护期内
  static bool _isInProtectionPeriod() {
    if (_lastShowTime == null) return false;
    final timeSinceShow = DateTime.now().difference(_lastShowTime!);
    return timeSinceShow < _protectionDuration;
  }
  
  /// 强制隐藏信息窗口（忽略保护期）
  static void forceHideInfoWindow() {
    // 取消防抖定时器
    _updateTimer?.cancel();
    _updateTimer = null;
    _scrollDebounceTimer?.cancel();
    _scrollDebounceTimer = null;
    
    _currentOverlay?.remove();
    _currentOverlay = null;
    _currentStopPointLocation = null;
    _mapController = null;
    _context = null;
    _currentLocationName = null;
    _currentDuration = null;
    _currentStartTime = null;
    _currentEndTime = null;
    _lastCameraPosition = null;
    _lastShowTime = null; // 清除保护时间
    _isMapMoving = false; // 清除移动状态
    _mapMoveStartTime = null; // 清除移动时间
    _lastScrollTime = null;
    _consecutiveScrollCount = 0;
  }
  
  /// 标记地图开始移动
  static void startMapMoving() {
    _isMapMoving = true;
    _mapMoveStartTime = DateTime.now();
    print('🗺️ 地图开始移动，启动保护机制');
  }
  
  /// 标记地图移动结束
  static void stopMapMoving() {
    // 延迟结束保护，确保动画完全结束
    Future.delayed(Duration(milliseconds: 800), () {
      _isMapMoving = false;
      _mapMoveStartTime = null;
      print('🗺️ 地图移动结束，关闭保护机制');
    });
  }
}

/// 定位的信息窗口
class _PositionedInfoWindow extends StatelessWidget {
  final Offset position;
  final String locationName;
  final String duration;
  final String startTime;
  final String endTime;
  final VoidCallback onClose;

  const _PositionedInfoWindow({
    Key? key,
    required this.position,
    required this.locationName,
    required this.duration,
    required this.startTime,
    required this.endTime,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // InfoWindow的尺寸：宽213, 高106
    const double infoWindowWidth = 213.0;
    const double infoWindowHeight = 106.0;
    
    // 精确的位置计算：
    // - 水平居中：position.dx是停留点的中心，需要减去InfoWindow宽度的一半
    // - 垂直位置：position.dy是停留点的中心，InfoWindow应该显示在上方
    //   考虑到InfoWindow有尖角指向下方，所以要减去InfoWindow的高度加上一些间距
    final double finalLeft = position.dx - (infoWindowWidth / 2);
    final double finalTop = position.dy - infoWindowHeight - 20;
    
    print('📋 InfoWindow最终位置计算:');
    print('   原始坐标: (${position.dx}, ${position.dy})');
    print('   InfoWindow尺寸: ${infoWindowWidth}x$infoWindowHeight');
    print('   最终位置: left=$finalLeft, top=$finalTop');
    
    return Positioned(
      left: finalLeft, // 水平居中
      top: finalTop, // 在停留点上方，留20像素间距
      child: CustomStayPointInfoWindow(
        locationName: locationName,
        duration: duration,
        startTime: startTime,
        endTime: endTime,
        onClose: onClose,
      ),
    );
  }
}

