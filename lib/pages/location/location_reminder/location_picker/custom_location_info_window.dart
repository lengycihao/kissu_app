import 'dart:async';
import 'package:flutter/material.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'dart:math' as math;
import 'package:kissu_app/utils/debug_util.dart';

/// 自定义位置选择信息窗口
class CustomLocationInfoWindow extends StatelessWidget {
  final String address;
  final VoidCallback? onClose;

  const CustomLocationInfoWindow({
    Key? key,
    required this.address,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 250,
        minWidth: 150,
      ),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                // 地址信息
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: Color(0xFFFF88AA),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        address,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF333333),
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.none,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
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

/// 自定义位置信息窗口管理器
class CustomLocationInfoWindowManager {
  // 单例
  static OverlayEntry? _currentOverlay;
  static BuildContext? _context;
  static LatLng? _currentLocation;
  static AMapController? _mapController;
  static String? _currentAddress;
  static CameraPosition? _lastCameraPosition;
  
  // 防抖定时器
  static Timer? _updateTimer;
  static const int _updateDelay = 100; // 100ms防抖延迟
  
  // 保护机制：记录上次显示时间
  static DateTime? _lastShowTime;
  static const int _minShowInterval = 200; // 最小显示间隔200ms
  
  /// 显示自定义信息窗口
  static void showInfoWindow({
    required BuildContext context,
    required LatLng location, // 经纬度坐标
    required AMapController mapController, // 地图控制器
    required String address,
    VoidCallback? onClose,
  }) {
    // 关闭已存在的窗口
    forceHideInfoWindow();
    
    // 记录显示时间，用于保护机制
    _lastShowTime = DateTime.now();
    
    // 保存当前信息
    _context = context;
    _currentLocation = location;
    _mapController = mapController;
    _currentAddress = address;
    
    // 计算InfoWindow位置并显示
    _updateInfoWindowPosition();
  }
  
  /// 更新相机位置（由地图移动事件调用）
  static void updateCameraPosition(CameraPosition position) {
    DebugUtil.info('相机位置更新: ${position.target.latitude}, ${position.target.longitude}, zoom: ${position.zoom}');
    _lastCameraPosition = position;
    
    // 如果当前有InfoWindow显示，则使用防抖机制更新其位置
    if (_currentLocation != null) {
      DebugUtil.info('准备更新InfoWindow位置（防抖中）...');
      _debounceUpdateInfoWindow();
    } else {
      DebugUtil.warning('没有当前位置，跳过InfoWindow更新');
    }
  }
  
  /// 防抖更新InfoWindow位置
  static void _debounceUpdateInfoWindow() {
    // 取消之前的定时器
    _updateTimer?.cancel();
    
    // 设置新的定时器
    _updateTimer = Timer(Duration(milliseconds: _updateDelay), () {
      DebugUtil.info('防抖结束，开始更新InfoWindow位置...');
      _updateInfoWindowPosition();
    });
  }
  
  /// 更新InfoWindow位置（地图移动时调用）
  static void _updateInfoWindowPosition() {
    
    if (_currentLocation == null || 
        _mapController == null || 
        _context == null) {
      DebugUtil.error('缺少必要参数: location=$_currentLocation, controller=$_mapController, context=$_context');
      return;
    }
    
    DebugUtil.info('当前位置: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}');
    
    // 移除旧的overlay
    _currentOverlay?.remove();
    
    // 使用高精度坐标转换算法
    final screenPosition = _highPrecisionLatLngToScreenPoint(_currentLocation!, _context!);
    
    DebugUtil.info('屏幕坐标转换结果: ${screenPosition.dx}, ${screenPosition.dy}');
    
    // 不在这里调整位置，直接使用计算出的屏幕坐标
    // 位置调整在_PositionedInfoWindow中统一处理
    final adjustedPosition = Offset(
      screenPosition.dx, 
      screenPosition.dy, // 使用原始屏幕坐标
    );
    
    DebugUtil.success('计算出的屏幕坐标: ${adjustedPosition.dx}, ${adjustedPosition.dy}');
    
    _currentOverlay = OverlayEntry(
      builder: (context) => _PositionedInfoWindow(
        position: adjustedPosition,
        address: _currentAddress!,
        onClose: hideInfoWindow,
      ),
    );
    
    try {
      Overlay.of(_context!).insert(_currentOverlay!);
      DebugUtil.success('InfoWindow 成功插入到 Overlay');
    } catch (e) {
      DebugUtil.error('InfoWindow插入失败: $e');
    }
  }
  
  
  
  /// 高精度的经纬度转屏幕坐标算法
  /// 使用优化的计算方法减少误差
  static Offset _highPrecisionLatLngToScreenPoint(LatLng location, BuildContext context) {
    
    if (_mapController == null || _lastCameraPosition == null) {
      DebugUtil.error('地图控制器或相机位置为空');
      return Offset.zero;
    }
    
    // 获取屏幕尺寸
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // 获取当前相机位置和缩放级别
    final centerLat = _lastCameraPosition!.target.latitude;
    final centerLng = _lastCameraPosition!.target.longitude;
    final zoom = _lastCameraPosition!.zoom;
    
    DebugUtil.info('📐 坐标转换参数:');
    DebugUtil.info('   屏幕尺寸: ${screenWidth}x$screenHeight');
    DebugUtil.info('   地图中心: ($centerLat, $centerLng)');
    DebugUtil.info('   缩放级别: $zoom');
    DebugUtil.info('   目标位置: (${location.latitude}, ${location.longitude})');
    
    // Web墨卡托投影计算
    // 1. 计算像素比例（每度对应的像素数）
    final scale = 256 * math.pow(2, zoom) / 360.0;
    
    // 2. 计算经度差对应的像素偏移
    final deltaLng = location.longitude - centerLng;
    final pixelOffsetX = deltaLng * scale;
    
    // 3. 计算纬度的墨卡托投影
    double latToY(double lat) {
      final latRad = lat * math.pi / 180.0;
      return math.log(math.tan(math.pi / 4 + latRad / 2));
    }
    
    final centerY = latToY(centerLat);
    final targetY = latToY(location.latitude);
    final deltaY = targetY - centerY;
    final pixelOffsetY = -deltaY * scale; // Y轴向下为正
    
    DebugUtil.info('📏 投影计算结果:');
    DebugUtil.info('   缩放比例: $scale');
    DebugUtil.info('   经度偏移: $deltaLng° = ${pixelOffsetX}px');
    DebugUtil.info('   纬度偏移: ${deltaY}rad = ${pixelOffsetY}px');
    
    // 4. 计算最终屏幕坐标
    final screenX = screenWidth / 2 + pixelOffsetX;
    final screenY = screenHeight / 2 + pixelOffsetY;
    
    DebugUtil.success('✅ 最终屏幕坐标: ($screenX, $screenY)');
    
    return Offset(screenX, screenY);
  }
  
  /// 隐藏信息窗口（带保护机制）
  static void hideInfoWindow() {
    // 保护机制：如果距离上次显示时间过短，则延迟隐藏
    if (_lastShowTime != null) {
      final elapsed = DateTime.now().difference(_lastShowTime!).inMilliseconds;
      if (elapsed < _minShowInterval) {
        DebugUtil.warning('⚠️ 距离上次显示时间过短($elapsed ms)，延迟隐藏');
        Future.delayed(Duration(milliseconds: _minShowInterval - elapsed), () {
          _doHideInfoWindow();
        });
        return;
      }
    }
    
    _doHideInfoWindow();
  }
  
  /// 执行隐藏操作
  static void _doHideInfoWindow() {
    DebugUtil.info('📴 隐藏 InfoWindow');
    
    // 取消防抖定时器
    _updateTimer?.cancel();
    _updateTimer = null;
    
    // 移除Overlay
    _currentOverlay?.remove();
    _currentOverlay = null;
    
    // 清理状态
    _currentLocation = null;
    _currentAddress = null;
    _lastShowTime = null;
  }
  
  /// 强制隐藏（不带保护机制）
  static void forceHideInfoWindow() {
    DebugUtil.info('🚫 强制隐藏 InfoWindow');
    
    // 取消防抖定时器
    _updateTimer?.cancel();
    _updateTimer = null;
    
    // 移除Overlay
    _currentOverlay?.remove();
    _currentOverlay = null;
    
    // 清理状态
    _currentLocation = null;
    _currentAddress = null;
    _lastShowTime = null;
  }
  
  /// 清理所有资源
  static void dispose() {
    DebugUtil.info('🗑️ 清理 InfoWindow 资源');
    forceHideInfoWindow();
    _context = null;
    _mapController = null;
    _lastCameraPosition = null;
  }
}

/// 定位的信息窗口
class _PositionedInfoWindow extends StatelessWidget {
  final Offset position;
  final String address;
  final VoidCallback onClose;

  const _PositionedInfoWindow({
    Key? key,
    required this.position,
    required this.address,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // InfoWindow的尺寸：宽度动态，高度60
    const double minInfoWindowWidth = 150.0;
    const double maxInfoWindowWidth = 250.0;
    const double infoWindowHeight = 60.0;
    
    // 计算实际宽度（根据地址长度）
    final textPainter = TextPainter(
      text: TextSpan(
        text: address,
        style: const TextStyle(fontSize: 12),
      ),
      maxLines: 3,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxInfoWindowWidth - 50); // 减去padding和图标宽度
    
    final calculatedWidth = (textPainter.width + 60).clamp(minInfoWindowWidth, maxInfoWindowWidth);
    
    // 精确的位置计算：
    // - 水平居中：position.dx是标记点的中心，需要减去InfoWindow宽度的一半
    // - 垂直位置：position.dy是标记点的中心，InfoWindow应该显示在上方
    //   考虑到InfoWindow有尖角指向下方，所以要减去InfoWindow的高度加上一些间距
    final double finalLeft = position.dx - (calculatedWidth / 2);
    final double finalTop = position.dy - infoWindowHeight - 20;
    
    DebugUtil.info('📋 InfoWindow最终位置计算:');
    DebugUtil.info('   原始坐标: (${position.dx}, ${position.dy})');
    DebugUtil.info('   InfoWindow尺寸: ${calculatedWidth}x$infoWindowHeight');
    DebugUtil.info('   最终位置: left=$finalLeft, top=$finalTop');
    
    return Positioned(
      left: finalLeft, // 水平居中
      top: finalTop, // 在标记点上方，留20像素间距
      child: CustomLocationInfoWindow(
        address: address,
        onClose: onClose,
      ),
    );
  }
}

