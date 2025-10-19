import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:kissu_app/model/location_model/location_model.dart';
import 'package:kissu_app/network/public/ltrack_api.dart';
import 'package:kissu_app/pages/track/stay_point.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:intl/intl.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:kissu_app/utils/debug_util.dart';
import 'package:kissu_app/widgets/dialogs/permission_request_dialog.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog.dart';
import 'package:kissu_app/pages/usage_report/widgets/map_marker_util.dart';

/// 初始坐标信息类
class InitialCoordinateInfo {
  final double latitude;
  final double longitude;
  final String? locationName;
  final String? duration;
  final String? startTime;
  final String? endTime;

  InitialCoordinateInfo({
    required this.latitude,
    required this.longitude,
    this.locationName,
    this.duration,
    this.startTime,
    this.endTime,
  });
}

class TrackController extends GetxController with GetTickerProviderStateMixin {
  /// 当前查看的用户类型 (1: 自己, 0: 另一半)
  final isOneself = 0.obs; // 默认选择另一半
  
  /// 地图就绪状态
  final isMapReady = false.obs;
  
  /// 轨迹线状态管理 - 用于解决高德地图轨迹线更新问题
  final RxBool hasValidTrackData = false.obs;

  /// 🔒 动画锁机制，防止地图变化时的滑动冲突
  bool _isAnimating = false;
  Timer? _animationTimer;
  
  /// 移除了自定义图标，直接使用彩色默认标记
  
  /// 用户信息
  final myAvatar = "".obs;
  final partnerAvatar = "".obs;
  final isBindPartner = false.obs;
  
  /// 缓存两个用户的轨迹数据
  final Rx<LocationResponse?> mySelfData = Rx<LocationResponse?>(null);
  final Rx<LocationResponse?> partnerData = Rx<LocationResponse?>(null);
  
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
  
  /// 当前选择的日期
  final selectedDate = DateTime.now().obs;
  
  /// 日期选择器的选中索引（0-6，对应最近7天）
  final selectedDateIndex = 6.obs; // 默认选择今天（最右边）
  
  /// 地图类型 (1: 经典地图, 2: 卫星地图)
  final mapType = 1.obs;
  
  /// 位置数据
  final Rx<LocationResponse?> locationData = Rx<LocationResponse?>(null);
  
  
  /// 初始坐标信息（从定位页面传递）
  final Rx<InitialCoordinateInfo?> initialCoordinateInfo = Rx<InitialCoordinateInfo?>(null);
  
  /// 停留统计 (从API数据获取)
  final stayCount = 0.obs;
  final stayDuration = "".obs;
  final moveDistance = "".obs;

  /// 最近 7 天
  final recentDays = List.generate(7, (i) {
    final date = DateTime.now().subtract(Duration(days: i));
    return "${date.month}-${date.day}";
  }).obs;

  final selectedDayIndex = 0.obs;
  final sheetPercent = 0.3.obs; // 修正为与页面一致的初始值
  
  /// 底部面板控制器
  DraggableScrollableController? _draggableController;
  
  /// 加载状态
  final isLoading = false.obs;
  
  /// 🎯 是否需要自动显示InfoWindow（从定位页面跳转时）
  bool _shouldAutoShowInfoWindow = false;

  /// 地图控制器 - 延迟初始化
  AMapController? mapController;
  
  /// 防抖定时器
  Timer? _debounceTimer;
  
  // 每次都从API获取最新数据，不使用缓存

  /// 移除了自定义图标加载功能，直接使用彩色默认标记
  
  /// 移除了图标加载函数
  
  
  @override
  void onInit() {
    super.onInit();
    // 初始化地图控制器
    // 地图控制器将在地图创建时初始化
    // 确保初始状态下播放控制器可见
    sheetPercent.value = 0.3;
    
    // 重置地图就绪状态
    isMapReady.value = false;
    
    // 初始化日期选择器索引（默认选择今天，索引为6）
    selectedDateIndex.value = 6;
    
    // 加载用户信息
    _loadUserInfo();
    // 请求定位权限并加载初始数据
    _requestLocationPermissionAndLoadData();
    
  }

  
  /// 请求定位权限并加载数据（每次打开都检查）
  Future<void> _requestLocationPermissionAndLoadData() async {
    try {
      DebugUtil.check('轨迹页面检查权限状态...');
      
      // 检查定位权限状态
      final status = await Permission.location.status;
      DebugUtil.info('轨迹页面权限状态: $status');
      
      if (status.isGranted) {
        DebugUtil.success('轨迹页面权限已授予，加载数据');
        Future.microtask(() => _loadDataAsync());
      } else {
        DebugUtil.error('轨迹页面权限未授予，请求权限');
        // 显示自定义权限申请弹窗
        await _showLocationPermissionDialog();
      }
    } catch (e) {
      DebugUtil.error('轨迹页面权限请求失败: $e');
      CustomToast.show(
        Get.context!,
        '定位权限请求失败',
      );
    }
  }

  /// 显示定位权限申请弹窗
  Future<void> _showLocationPermissionDialog() async {
    await Get.dialog<bool>(
      PermissionRequestDialog(
        title: '定位权限申请',
        content: '需要获取您的位置信息来显示轨迹数据，这将帮助我们为您提供更准确的轨迹分析。',
        onContinue: () async {
          Get.back(result: true);
          // 请求系统定位权限
          final result = await Permission.location.request();
          if (result.isGranted) {
            DebugUtil.success('轨迹页面权限获取成功，加载数据');
            Future.microtask(() => _loadDataAsync());
          } else {
            DebugUtil.error('轨迹页面权限被拒绝');
            // 权限被拒绝时，静默处理，不显示额外提示
          }
        },
        onCancel: () {
          Get.back(result: false);
          DebugUtil.error('用户拒绝了轨迹页面定位权限');
        },
      ),
      barrierDismissible: false,
    );
  }

  /// 加载用户信息（初始化头像为用户信息中的头像）
  void _loadUserInfo() {
    final user = UserManager.currentUser;
    if (user != null) {
      // 设置我的头像（初始值，会被API数据覆盖）
      myAvatar.value = user.headPortrait ?? '';
      
      // 检查绑定状态 (0从未绑定，1绑定中，2已解绑)
      // bindStatus是dynamic类型，需要安全处理
      bool isBound = false;
      if (user.bindStatus != null) {
        DebugUtil.info('bindStatus原始值: ${user.bindStatus} (类型: ${user.bindStatus.runtimeType})');
        if (user.bindStatus is int) {
          isBound = user.bindStatus == 1;
        } else if (user.bindStatus is String) {
          isBound = user.bindStatus == "1";
        }
        DebugUtil.info('解析后的绑定状态: $isBound');
      } else {
        DebugUtil.warning('bindStatus为null，默认为未绑定');
      }
      isBindPartner.value = isBound;
      
      // 设置伴侣头像（初始值，会被API数据覆盖）
      if (isBindPartner.value) {
        if (user.loverInfo?.headPortrait?.isNotEmpty == true) {
          partnerAvatar.value = user.loverInfo!.headPortrait!;
        } else if (user.halfUserInfo?.headPortrait?.isNotEmpty == true) {
          partnerAvatar.value = user.halfUserInfo!.headPortrait!;
        }
      }
      // 注意：无论绑定状态如何，都会显示两个头像，实际头像将从API数据中获取
    }
  }

  /// 从API数据中更新头像信息
  void _updateAvatarsFromApiData(LocationResponse data) {
    DebugUtil.info('从API数据更新头像信息');
    
    // 从user字段中获取头像和绑定状态
    if (data.user != null) {
      final userInfo = data.user!;
      
      // 更新我的头像
      if (userInfo.headPortrait?.isNotEmpty == true) {
        myAvatar.value = userInfo.headPortrait!;
        DebugUtil.info('更新我的头像: ${myAvatar.value}');
      }
      
      // 更新伴侣头像
      if (userInfo.halfHeadPortrait?.isNotEmpty == true) {
        partnerAvatar.value = userInfo.halfHeadPortrait!;
        DebugUtil.info('更新伴侣头像: ${partnerAvatar.value}');
      }
      
      // 更新绑定状态
      isBindPartner.value = userInfo.isBind == 1;
      DebugUtil.info('更新绑定状态: ${isBindPartner.value}');
    }
    
    DebugUtil.success('头像更新完成 - 我的头像: ${myAvatar.value}, 伴侣头像: ${partnerAvatar.value}');
  }

  /// 地图初始相机位置
  CameraPosition get initialCameraPosition => CameraPosition(
    target: trackPoints.isNotEmpty
        ? trackPoints.first
        : const LatLng(30.2741, 120.2206), // 杭州默认坐标
    zoom: 16.0,
  );

  /// 计算适合所有轨迹点的相机位置
  CameraPosition? _calculateOptimalCameraPosition() {
    if (trackPoints.isEmpty) return null;
    
    // 计算边界
    double minLat = trackPoints.first.latitude;
    double maxLat = trackPoints.first.latitude;
    double minLng = trackPoints.first.longitude;
    double maxLng = trackPoints.first.longitude;
    
    for (final point in trackPoints) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }
    
    // 添加边距（10%的padding）
    final latPadding = (maxLat - minLat) * 0.1;
    final lngPadding = (maxLng - minLng) * 0.1;
    
    minLat -= latPadding;
    maxLat += latPadding;
    minLng -= lngPadding;
    maxLng += lngPadding;
    
    // 计算中心点
    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    
    // 计算合适的缩放级别
    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
    
    // 根据距离计算缩放级别 - 支持更大范围的轨迹
    double zoom;
    if (maxDiff < 0.001) {
      zoom = 18.0; // 非常小的区域 (< 100米)
    } else if (maxDiff < 0.01) {
      zoom = 16.0; // 小区域 (< 1公里)
    } else if (maxDiff < 0.05) {
      zoom = 14.0; // 中小区域 (< 5公里)
    } else if (maxDiff < 0.1) {
      zoom = 13.0; // 中等区域 (< 10公里)
    } else if (maxDiff < 0.2) {
      zoom = 12.0; // 中大区域 (< 20公里)
    } else if (maxDiff < 0.5) {
      zoom = 11.0; // 大区域 (< 50公里)
    } else if (maxDiff < 1.0) {
      zoom = 10.0; // 很大区域 (< 100公里)
    } else if (maxDiff < 2.0) {
      zoom = 9.0; // 超大区域 (< 200公里)
    } else {
      zoom = 8.0; // 极大区域 (> 200公里)
    }
    
    // 打印调试信息
    DebugUtil.info('轨迹范围计算: latDiff=$latDiff, lngDiff=$lngDiff, maxDiff=$maxDiff, zoom=$zoom');
    DebugUtil.info('轨迹中心点: ($centerLat, $centerLng)');
    
    return CameraPosition(
      target: LatLng(centerLat, centerLng),
      zoom: zoom,
    );
  }

  /// 自动调整地图视图以显示所有轨迹点
  Future<void> _fitMapToTrackPoints() async {
    if (!isMapReady.value || mapController == null) {
      DebugUtil.warning('地图未就绪或控制器为空，无法调整视图');
      return;
    }
    
    if (trackPoints.isEmpty) {
      DebugUtil.warning('轨迹点为空，无法调整视图');
      return;
    }
    
    DebugUtil.info('开始自动调整地图视图，轨迹点数量: ${trackPoints.length}');
    
    final optimalPosition = _calculateOptimalCameraPosition();
    if (optimalPosition == null) {
      DebugUtil.error('无法计算最佳视图位置');
      return;
    }
    
    try {
      await mapController!.moveCamera(
        CameraUpdate.newCameraPosition(optimalPosition),
      );
      DebugUtil.success('地图已自动调整到最佳视图 - 缩放级别: ${optimalPosition.zoom}');
    } catch (e) {
      DebugUtil.error('调整地图视图失败: $e');
    }
  }

  /// 地图创建完成回调
  void onMapCreated(AMapController controller) {
    mapController = controller;
    DebugUtil.success('轨迹页面高德地图创建成功');
    
    // 设置地图就绪状态
    setMapReady(true);
    
    // 立即关闭所有可能自动显示的 InfoWindow（缩短延迟）
    Future.delayed(const Duration(milliseconds: 100), () {
      _closeAllInfoWindows();
      DebugUtil.info('🔒 地图初始化后关闭所有 InfoWindow');
    });
    
    // 检查是否有初始坐标需要高亮显示
    _handleInitialCoordinates();
  }
  
  /// 处理初始坐标高亮显示
  void _handleInitialCoordinates() {
    final initialInfo = initialCoordinateInfo.value;
    if (initialInfo != null) {
      DebugUtil.info('处理初始坐标高亮显示: ${initialInfo.latitude}, ${initialInfo.longitude}');
      
      // 延迟执行，确保地图完全加载
      Future.delayed(const Duration(milliseconds: 500), () async {
        // 创建停留点对象
        final stopPoint = TrackStopPoint(
          lat: initialInfo.latitude,
          lng: initialInfo.longitude,
          locationName: initialInfo.locationName,
          duration: initialInfo.duration,
          startTime: initialInfo.startTime,
          endTime: initialInfo.endTime,
          serialNumber: "1",
        );
        
        // 使用内部方法：移动地图、绘制高亮圆圈（无InfoWindow）
        await _moveToStopPointWithHighlightInternal(
          initialInfo.latitude,
          initialInfo.longitude,
          stopPoint: stopPoint,
        );
        
        // 清除初始坐标信息，避免重复处理
        initialCoordinateInfo.value = null;
      });
    }
  }


  /// 移动地图到指定位置
  void _moveMapToLocation(LatLng location) {
    // 检查地图是否就绪
    if (!isMapReady.value || mapController == null) {
      DebugUtil.warning('地图未就绪或控制器为空，跳过移动地图');
      return;
    }
    
    try {
      mapController?.moveCamera(CameraUpdate.newLatLng(location));
    } catch (e) {
      DebugUtil.error('移动地图失败: $e');
    }
  }
  
  /// 移动地图到停留点（公共方法，用于列表点击）
  void moveToStopPoint(double latitude, double longitude) {
    // 检查地图是否就绪
    if (!isMapReady.value || mapController == null) {
      DebugUtil.warning('地图未就绪或控制器为空，无法移动到停留点');
      return;
    }
    
    final targetLocation = LatLng(latitude, longitude);
    
    try {
      // 移动地图并调整缩放级别以更好地显示该点
      mapController?.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: targetLocation,
            zoom: 17.0, // 使用较高的缩放级别以便更清楚地看到该位置
          ),
        ),
      );
      
      DebugUtil.info('地图移动到停留点: $latitude, $longitude');
    } catch (e) {
      DebugUtil.error('移动地图到停留点失败: $e');
    }
  }

  /// 清除所有高亮圆圈
  void clearAllHighlightCircles() {
    if (highlightCircles.isNotEmpty) {
      DebugUtil.info('🧹 [HighlightCircles] 清除 ${highlightCircles.length} 个高亮圆圈');
      highlightCircles.clear();
      highlightCircles.refresh();
      circlesVersion.value++;
      DebugUtil.success('✅ [HighlightCircles] 所有高亮圆圈已清除');
    } else {
      DebugUtil.info('📋 [HighlightCircles] 没有高亮圆圈需要清除');
    }
  }

  /// 绘制高亮圆圈（使用Circle实现）
  void drawHighlightCircle(LatLng center) {
    DebugUtil.info('🎯 开始绘制高亮圆圈: ${center.latitude}, ${center.longitude}');
    
    // 先清除之前的高亮圆圈
    clearAllHighlightCircles();
    
    try {
      final circle = Circle(
        center: center,
        radius: 100.0, // 100米半径
        strokeWidth: 3,
        strokeColor: const Color(0xFFFFFFFF), // 白色边框
        fillColor: const Color(0xFFFFE3EB).withOpacity(0.38), // 背景色 #FFE3EB，不透明度38%
        visible: true,
      );
      
      highlightCircles.add(circle);
      highlightCircles.refresh();
      circlesVersion.value++;
      DebugUtil.success('✅ 高亮圆圈已添加，总数: ${highlightCircles.length}');
      
      // 🎯 强制触发地图更新，确保圆圈立即显示
      Future.microtask(() {
        DebugUtil.info('🔄 强制刷新地图以显示新圆圈');
        update();
      });
      
    } catch (e) {
      DebugUtil.error('❌ 绘制高亮圆圈失败: $e');
    }
  }


  /// 设置底部面板控制器
  void setDraggableController(DraggableScrollableController controller) {
    _draggableController = controller;
  }
  
  /// 设置初始坐标信息（从定位页面传递）
  void setInitialCoordinates({
    required double latitude,
    required double longitude,
    String? locationName,
    String? duration,
    String? startTime,
    String? endTime,
    bool autoShowInfoWindow = false, // 🎯 新增：是否自动显示InfoWindow
  }) {
    initialCoordinateInfo.value = InitialCoordinateInfo(
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      duration: duration,
      startTime: startTime,
      endTime: endTime,
    );
    DebugUtil.info('设置初始坐标: $latitude, $longitude, 位置: $locationName, 自动显示InfoWindow: $autoShowInfoWindow');
    
    // 🎯 如果需要自动显示InfoWindow，设置标记
    if (autoShowInfoWindow) {
      _shouldAutoShowInfoWindow = true;
    }
  }
  
  /// 收起底部面板到最小高度
  void collapseBottomSheet() {
    if (_draggableController != null) {
      // 计算最小高度比例，避免与中间吸顶位置重合
      const minHeight = 190.0;
      final screenHeight = Get.context != null ? MediaQuery.of(Get.context!).size.height : 800.0;
      final minHeightRatio = minHeight / screenHeight;
      
      _draggableController!.animateTo(
        minHeightRatio, // 使用计算出的最小高度比例，确保不会卡在中间吸顶位置
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 智能展开底部面板到中间位置（用于点击停留点时）
  void expandToMiddlePosition() {
    if (_draggableController != null) {
      final screenHeight = Get.context != null ? MediaQuery.of(Get.context!).size.height : 800.0;
      final actualBindStatus = getActualBindStatus();
      final middleSnapSize = actualBindStatus
          ? 0.5 + (21 / screenHeight) // 已绑定：屏幕中间
          : 0.5 + (57 / screenHeight); // 未绑定：稍微往上偏移
      
      _draggableController!.animateTo(
        middleSnapSize,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 展开底部面板到底部吸顶位置（用于点击停留点时）
  void expandToBottomPosition() {
    if (_draggableController != null) {
      const minHeight = 190.0;
      final screenHeight = Get.context != null ? MediaQuery.of(Get.context!).size.height : 800.0;
      final bottomSnapSize = minHeight / screenHeight;
      
      _draggableController!.animateTo(
        bottomSnapSize,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 移动地图到停留点并高亮显示（增强版方法，供外部调用）
  Future<void> moveToStopPointWithHighlight(BuildContext context, double latitude, double longitude, {TrackStopPoint? stopPoint}) async {
    await _moveToStopPointWithHighlightInternal(latitude, longitude, stopPoint: stopPoint, context: context);
  }
  
  /// 移动地图到停留点并高亮显示（内部方法）
  Future<void> _moveToStopPointWithHighlightInternal(double latitude, double longitude, {TrackStopPoint? stopPoint, BuildContext? context}) async {
    final targetLocation = LatLng(latitude, longitude);
    
    DebugUtil.info('🎯 开始移动到停留点: ($latitude, $longitude)');
    DebugUtil.info('🎯 stopPoint传入的坐标: (${stopPoint?.lat}, ${stopPoint?.lng})');
    DebugUtil.info('🎯 停留点数据: ${stopPoint?.locationName ?? "无"}');
    
    // 🔒 设置动画锁，防止用户在地图变化时滑动面板造成冲突
    setAnimationLock(true);
    
    // 🔍 查找对应的Marker坐标
    final matchingMarker = stayMarkers.firstWhereOrNull((marker) {
      final distance = _calculateDistanceBetweenPointsStatic(
        marker.position, 
        LatLng(stopPoint?.lat ?? latitude, stopPoint?.lng ?? longitude)
      );
      return distance < 10; // 10米范围内
    });
    
    if (matchingMarker != null) {
      DebugUtil.info('🎯 找到匹配的Marker坐标: (${matchingMarker.position.latitude}, ${matchingMarker.position.longitude})');
      DebugUtil.info('🎯 传入参数坐标: ($latitude, $longitude)');
      
      // 计算坐标差异
      final distance = _calculateDistanceBetweenPointsStatic(matchingMarker.position, targetLocation);
      DebugUtil.warning('⚠️ 坐标差异: ${distance.toStringAsFixed(2)}米');
      
      if (distance > 5) {
        DebugUtil.error('❌ 围栏圆圈将使用不同的坐标！Marker在(${matchingMarker.position.latitude}, ${matchingMarker.position.longitude})，围栏在($latitude, $longitude)');
      }
    }
    
    DebugUtil.info('🎯 地图控制器状态: ${mapController != null ? "已就绪" : "未就绪"}');
    DebugUtil.info('🎯 地图就绪状态: ${isMapReady.value}');
    
    // 0. 关闭所有 InfoWindow（通过强制更新 Markers 列表）
    _closeAllInfoWindows();
    
    // 1. 移动地图到停留点
    moveToStopPoint(latitude, longitude);
    
    // 2. 先收起底部面板到最小高度，让用户看到地图变化
    collapseBottomSheet();
    
    // 3. 延迟后展开到底部位置，给用户更好的视觉体验
    Future.delayed(const Duration(milliseconds: 600), () {
      // 检查动画锁状态，如果用户正在滑动则不执行自动展开
      if (_isAnimating) {
        expandToBottomPosition();
      } else {
        DebugUtil.info('🔒 用户正在操作面板，跳过自动展开');
      }
    });
    
    // 4. 🎯 显示对应停留点的 InfoWindow（如果有stopPoint数据）
    if (stopPoint != null) {
      // 延迟一小段时间，确保地图移动完成
      // 同时确保 _closeAllInfoWindows() 的影响已经稳定
      Future.delayed(const Duration(milliseconds: 500), () async {
        await _showInfoWindowForStopPoint(stopPoint);
        
        // 5. ✨ InfoWindow创建完成后再绘制高亮圆圈
        Future.delayed(const Duration(milliseconds: 200), () {
          DebugUtil.info('🎯 InfoWindow创建完成，现在绘制高亮圆圈');
          drawHighlightCircle(targetLocation);
        });
      });
    } else {
      // 如果没有stopPoint数据，直接绘制圆圈
      Future.delayed(const Duration(milliseconds: 300), () {
        drawHighlightCircle(targetLocation);
      });
    }
    
    // 🔓 1.5秒后释放动画锁
    Future.delayed(const Duration(milliseconds: 1500), () {
      setAnimationLock(false);
      DebugUtil.success('✅ 移动到停留点并高亮显示完成，动画锁已释放');
    });
  }

  /// 🔒 设置动画锁状态
  void setAnimationLock(bool isLocked) {
    _isAnimating = isLocked;
    
    // 清除之前的定时器
    _animationTimer?.cancel();
    
    if (isLocked) {
      DebugUtil.info('🔒 设置动画锁，防止滑动冲突');
      // 设置最大锁定时间为3秒，防止意外情况下锁定过久
      _animationTimer = Timer(const Duration(seconds: 3), () {
        _isAnimating = false;
        DebugUtil.warning('⏰ 动画锁超时自动释放');
      });
    } else {
      DebugUtil.info('🔓 释放动画锁');
    }
  }
  
  /// 关闭所有 InfoWindow
  void _closeAllInfoWindows() {
    // 通过触发 Markers 列表更新来关闭所有 InfoWindow
    // 这是因为高德地图没有直接的 API 来关闭 InfoWindow
    // 所以我们创建一个新的列表引用，触发 Obx 更新
    stayMarkers.refresh();
    trackStartEndMarkers.refresh();
    DebugUtil.info('🔒 已关闭所有 InfoWindow');
  }
  
  /// 🎯 检查是否需要自动显示InfoWindow（从定位页面跳转时）
  void _checkAutoShowInfoWindow() {
    if (!_shouldAutoShowInfoWindow) return;
    
    final initialInfo = initialCoordinateInfo.value;
    if (initialInfo == null) return;
    
    DebugUtil.info('🎯 检查自动显示InfoWindow: 初始坐标(${initialInfo.latitude}, ${initialInfo.longitude})');
    
    // 延迟执行，确保地图和标记都已加载完成
    Future.delayed(const Duration(milliseconds: 1000), () async {
      // 查找匹配的停留点
      final matchingStopPoint = stopPoints.firstWhereOrNull((stop) {
        final distance = _calculateDistance(
          LatLng(initialInfo.latitude, initialInfo.longitude),
          LatLng(stop.lat, stop.lng),
        );
        return distance < 100; // 100米内认为是同一个停留点
      });
      
      if (matchingStopPoint != null) {
        DebugUtil.success('✅ 找到匹配的停留点，自动显示InfoWindow: ${matchingStopPoint.locationName}');
        await _showInfoWindowForStopPoint(matchingStopPoint);
        
        // 重置标记，避免重复显示
        _shouldAutoShowInfoWindow = false;
        } else {
        DebugUtil.warning('⚠️ 未找到匹配的停留点，无法自动显示InfoWindow');
      }
    });
  }
  
  /// 显示指定停留点的 InfoWindow
  Future<void> _showInfoWindowForStopPoint(TrackStopPoint stopPoint) async {
    try {
      DebugUtil.info('🎯 直接在坐标位置创建 InfoWindow: ${stopPoint.locationName}');
      DebugUtil.info('🎯 目标坐标: (${stopPoint.lat}, ${stopPoint.lng})');
      
      // 在指定位置创建临时 Marker 并显示 InfoWindow
      final stopInfo = _parseStopInfo(stopPoint);
      final String infoTitle = stopInfo['locationName']!;
      final String infoSnippet = '${stopPoint.startTime ?? ''} ${stopPoint.duration?.isNotEmpty == true ? '停留${stopPoint.duration}' : ''}';
      
      // 先清除之前的临时 InfoWindow Marker（如果有）
      _clearTempInfoWindowMarker();
      
      // 创建临时 Marker，设置自动显示 InfoWindow 并支持拖拽
      final tempMarker = Marker(
        position: LatLng(stopPoint.lat, stopPoint.lng),
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
          stopInfo['locationName']!,
          stopInfo['stayDuration']!,
          stopInfo['stayTime']!,
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
      
      // 调用地图刷新方法，确保临时标记立即显示
      await refreshCurrentUserData();
      
      DebugUtil.success('✅ 临时 InfoWindow 已创建并刷新地图');
      
    } catch (e) {
      DebugUtil.error('❌ 显示停留点 InfoWindow 失败: $e');
    }
  }

  /// 清除临时 InfoWindow Marker
  void _clearTempInfoWindowMarker() {
    if (_tempInfoWindowMarker != null) {
      DebugUtil.info('🧹 清除之前的临时 InfoWindow Marker');
      _tempInfoWindowMarker = null;
      
      // 清除后触发地图更新
      _forceMapUpdate();
      
      DebugUtil.info('✅ 临时标记已清除');
    }
  }

  /// 🎯 解析停留点信息，提取位置名称、停留时长和停留时间
  /// [stop] 停留点数据
  /// 返回 Map，包含 locationName、stayDuration、stayTime
  Map<String, String> _parseStopInfo(TrackStopPoint stop) {
    final locationName = stop.locationName ?? '未知位置';
    final stayDuration = stop.duration ?? '';
    
    // 解析停留时间段
    String stayTime = '';
    if (stop.startTime?.isNotEmpty == true) {
      if (stop.endTime?.isNotEmpty == true && stop.endTime != stop.startTime) {
        // 有开始和结束时间
        stayTime = '${stop.startTime}~${stop.endTime}';
      } else {
        // 只有开始时间
        stayTime = stop.startTime!;
      }
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
  Widget _buildTrackInfoWindow(String locationName, String stayDuration, String stayTime) {
    return Container(
      width: 280,
      height: 120,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locationName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          SizedBox(height: 8),
          Text(
            stayDuration,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          SizedBox(height: 4),
          Text(
            stayTime,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  /// 轨迹点（从API数据获取）
  final RxList<LatLng> trackPoints = <LatLng>[].obs;

  /// 停留点列表（从API数据获取）
  final RxList<TrackStopPoint> stopPoints = <TrackStopPoint>[].obs;

  /// 停留点 marker 列表
  final RxList<Marker> stayMarkers = <Marker>[].obs;

  /// 轨迹起点和终点 marker 列表
  final RxList<Marker> trackStartEndMarkers = <Marker>[].obs;

  /// 播放头像标记
  final Rx<Marker?> replayAvatarMarker = Rx<Marker?>(null);

  /// 临时 InfoWindow 标记（用于显示停留点详情）
  Marker? _tempInfoWindowMarker;
  
  /// 获取临时 InfoWindow 标记
  Marker? get tempInfoWindowMarker => _tempInfoWindowMarker;

  /// 高亮圆圈覆盖物列表（使用Circle实现）
  final RxSet<Circle> highlightCircles = <Circle>{}.obs;
  /// 高亮圆圈版本号（用于触发UI更新，即使数量未变化）
  final RxInt circlesVersion = 0.obs;

  /// 轨迹回放状态
  final currentReplayIndex = 0.obs;
  final isReplaying = false.obs; // 改为响应式变量
  final replaySpeed = 1.0.obs; // 播放速度倍数
  
  /// 动画控制器 - 替代Timer的更好方案
  AnimationController? _replayAnimationController;
  Animation<double>? _replayAnimation;
  
  /// 平滑动画相关
  final currentPosition = Rx<LatLng?>(null);
  final animationProgress = 0.0.obs;
  
  /// 播放相关参数
  static const Duration _minReplayDuration = Duration(seconds: 3); // 最短播放时长
  static const Duration _maxReplayDuration = Duration(seconds: 15); // 最长播放时长
  static const double _baseSpeedKmh = 30.0; // 基础播放速度 30km/h
  
  /// 播放时间跟踪
  DateTime? _replayStartTime;
  double _cumulativeDistance = 0.0; // 累计距离（米）

  /// 停留记录列表（从API数据转换而来）
  final RxList<StopRecord> stopRecords = <StopRecord>[].obs;
  
  /// 已移除虚拟数据逻辑，所有情况都使用真实API数据
  
  /// 数据版本号，用于确保数据一致性
  int _dataVersion = 0;

  /// 缓存状态指示器

  /// 加载位置数据 - 添加防抖优化
  Future<void> loadLocationData() async {
    // 防抖处理，避免频繁请求
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      await _performLoadLocationData();
    });
  }
  
  /// 已废弃：现在使用 _switchToCurrentUserData() 从缓存切换数据
  
  /// 直接执行数据加载 - 跳过防抖，并发请求两个用户数据
  Future<void> _performLoadLocationDataDirect() async {
    // 只有今天的数据才显示loading动画
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final selectedDateString = DateFormat('yyyy-MM-dd').format(selectedDate.value);
    final isToday = selectedDateString == today;
    
    if (isToday) {
      isLoading.value = true;
    }
    _resetReplayState();
    
    // 增加数据版本号，确保数据一致性
    final currentVersion = ++_dataVersion;
    
    // 立即清空旧数据，给用户即时反馈
    _clearDataInstantly();
    
    final dateString = DateFormat('yyyy-MM-dd').format(selectedDate.value);
    
    try {
      DebugUtil.info('🚀 并发请求两个用户的轨迹数据: $dateString');
      
      // 🚀 并发请求两个用户的数据
      final results = await Future.wait([
        TrackApi.getTrack(date: dateString, isOneself: 1, useCache: true), // 自己
        TrackApi.getTrack(date: dateString, isOneself: 0, useCache: true), // 另一半
      ]);
      
      // 检查数据版本是否还有效
      if (currentVersion != _dataVersion) {
        DebugUtil.warning('数据版本已过期，放弃数据处理');
        return;
      }
      
      final myselfResult = results[0];
      final partnerResult = results[1];
      
      // 缓存两个用户的数据
      if (myselfResult.isSuccess && myselfResult.data != null) {
        mySelfData.value = myselfResult.data;
        DebugUtil.success('✅ 自己的轨迹数据加载成功');
      } else {
        mySelfData.value = null;
        DebugUtil.warning('⚠️ 自己的轨迹数据加载失败: ${myselfResult.msg}');
      }
      
      if (partnerResult.isSuccess && partnerResult.data != null) {
        partnerData.value = partnerResult.data;
        DebugUtil.success('✅ 另一半的轨迹数据加载成功');
      } else {
        partnerData.value = null;
        DebugUtil.warning('⚠️ 另一半的轨迹数据加载失败: ${partnerResult.msg}');
      }
      
      // 根据当前选择显示对应的数据
      final currentData = isOneself.value == 1 ? mySelfData.value : partnerData.value;
      
      if (currentData == null) {
        DebugUtil.warning('⚠️ 当前用户数据为空');
        CustomToast.show(Get.context!, '获取数据失败');
        _clearData();
        return;
      }
      
      // 更新当前显示的数据
      locationData.value = currentData;
      
      // 从API数据中更新头像信息
      _updateAvatarsFromApiData(currentData);
      
      DebugUtil.success('获取到最新数据');
      
      // 使用渐进式数据更新，避免长时间阻塞UI
      await _progressiveDataUpdate();
      
    } catch (e, stackTrace) {
      DebugUtil.error('Track Controller loadLocationData error: $e');
      DebugUtil.error('请求参数: date=$dateString');
      DebugUtil.error('Stack trace: $stackTrace');
      
      String errorMessage;
      if (e.toString().contains('FormatException')) {
        errorMessage = 'JSON数据格式错误，请检查服务器返回的数据格式';
        DebugUtil.warning('建议检查API返回的JSON格式是否正确');
      } else if (e.toString().contains('is not a subtype')) {
        errorMessage = '数据类型不匹配，请稍后重试';
      } else if (e.toString().contains('Unterminated string')) {
        errorMessage = 'JSON字符串格式错误，可能存在未转义的特殊字符';
        DebugUtil.warning('建议检查JSON中是否有未正确转义的引号或换行符');
      } else {
        errorMessage = '加载数据失败: ${e.toString().length > 100 ? '${e.toString().substring(0, 100)}...' : e.toString()}';
      }
      
      CustomToast.show(
        Get.context!,
        errorMessage,
      );
      _clearData();
    } finally {
      isLoading.value = false;
    }
  }

  /// 实际执行数据加载 - 支持缓存的智能加载（带防抖）
  /// 并发请求两个用户的数据，避免切换时重新请求
  Future<void> _performLoadLocationData() async {
    // 只有今天的数据才显示loading动画
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final selectedDateString = DateFormat('yyyy-MM-dd').format(selectedDate.value);
    final isToday = selectedDateString == today;
    
    if (isToday) {
      isLoading.value = true;
    }
    _resetReplayState();
    
    // 增加数据版本号，确保数据一致性
    final currentVersion = ++_dataVersion;
    
    // 立即清空旧数据，给用户即时反馈
    _clearDataInstantly();
    
    final dateString = DateFormat('yyyy-MM-dd').format(selectedDate.value);
    
    try {
      DebugUtil.info('🚀 并发请求两个用户的轨迹数据: $dateString');
      
      // 🚀 并发请求两个用户的数据
      final results = await Future.wait([
        TrackApi.getTrack(date: dateString, isOneself: 1, useCache: true), // 自己
        TrackApi.getTrack(date: dateString, isOneself: 0, useCache: true), // 另一半
      ]);
      
      // 检查数据版本是否还有效
      if (currentVersion != _dataVersion) {
        DebugUtil.warning('数据版本已过期，放弃数据处理');
        return;
      }
      
      final myselfResult = results[0];
      final partnerResult = results[1];
      
      // 缓存两个用户的数据
      if (myselfResult.isSuccess && myselfResult.data != null) {
        mySelfData.value = myselfResult.data;
        DebugUtil.success('✅ 自己的轨迹数据加载成功');
      } else {
        mySelfData.value = null;
        DebugUtil.warning('⚠️ 自己的轨迹数据加载失败: ${myselfResult.msg}');
      }
      
      if (partnerResult.isSuccess && partnerResult.data != null) {
        partnerData.value = partnerResult.data;
        DebugUtil.success('✅ 另一半的轨迹数据加载成功');
      } else {
        partnerData.value = null;
        DebugUtil.warning('⚠️ 另一半的轨迹数据加载失败: ${partnerResult.msg}');
      }
      
      // 根据当前选择显示对应的数据
      _switchToCurrentUserData();
      
    } catch (e, stackTrace) {
      DebugUtil.error('Track Controller loadLocationData error: $e');
      DebugUtil.error('请求参数: date=$dateString');
      DebugUtil.error('Stack trace: $stackTrace');
      
      String errorMessage;
      if (e.toString().contains('FormatException')) {
        errorMessage = 'JSON数据格式错误，请检查服务器返回的数据格式';
        DebugUtil.warning('建议检查API返回的JSON格式是否正确');
      } else if (e.toString().contains('is not a subtype')) {
        errorMessage = '数据类型不匹配，请稍后重试';
      } else if (e.toString().contains('Unterminated string')) {
        errorMessage = 'JSON字符串格式错误，可能存在未转义的特殊字符';
        DebugUtil.warning('建议检查JSON中是否有未正确转义的引号或换行符');
      } else {
        errorMessage = '加载数据失败: ${e.toString().length > 100 ? '${e.toString().substring(0, 100)}...' : e.toString()}';
      }
      
      CustomToast.show(
        Get.context!,
        errorMessage,
      );
      _clearData();
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 切换到当前用户的数据（从缓存中）
  void _switchToCurrentUserData() {
    final currentData = isOneself.value == 1 ? mySelfData.value : partnerData.value;
    
    if (currentData == null) {
      DebugUtil.warning('⚠️ 当前用户数据为空');
      _clearData();
      return;
    }
    
    // 更新当前显示的数据
    locationData.value = currentData;
    
    // 从API数据中更新头像信息
    _updateAvatarsFromApiData(currentData);
    
    DebugUtil.success('✅ 切换到 ${isOneself.value == 1 ? "自己" : "另一半"} 的数据');
    
    // ⚠️ 注意顺序：先更新轨迹数据（调整stopPoints），再更新停留记录（使用调整后的stopPoints）
    _updateTrackDataAsync().then((_) {
      DebugUtil.success('🔄 轨迹数据更新完成，开始更新停留记录...');
      // 轨迹数据更新完成后，再更新停留记录
      return _updateStopRecords();
    }).then((_) {
      DebugUtil.success('🔄 停留记录更新完成，开始更新统计数据...');
      // 统计数据可以同步更新，因为很快
      _updateStatistics();
      DebugUtil.success('✅ 所有数据更新完成！');
    }).catchError((e, stackTrace) {
      DebugUtil.error('❌ 数据更新失败: $e');
      DebugUtil.error('Stack trace: $stackTrace');
      // 即使出错也尝试更新统计数据
      _updateStatistics();
    });
  }
  
  /// 获取实际的绑定状态（不受当前查看用户影响）
  bool getActualBindStatus() {
    // 优先使用自己的数据来判断绑定状态
    if (mySelfData.value?.user?.isBind != null) {
      return mySelfData.value!.user!.isBind == 1;
    }
    
    // 如果自己的数据不可用，使用另一半的数据
    if (partnerData.value?.user?.isBind != null) {
      return partnerData.value!.user!.isBind == 1;
    }
    
    // 最后使用当前的isBindPartner状态
    return isBindPartner.value;
  }

  /// 重置播放状态
  void _resetReplayState() {
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
  
  /// 立即清空数据，给用户即时反馈 - 非阻塞版本
  void _clearDataInstantly() {
    DebugUtil.info('🧹 [ClearInstantly] 开始立即清空数据（日期切换）...');
    
    // 🎯 保存当前的高亮圆圈，避免在数据刷新时被清除
    final savedHighlightCircles = Set<Circle>.from(highlightCircles);
    
    // ⚠️ 必须先设置无效状态，防止在清空过程中触发Polyline创建
    hasValidTrackData.value = false;
    
    // 清空轨迹相关数据
    trackPoints.clear();
    stopPoints.clear();
    stayMarkers.clear();
    trackStartEndMarkers.clear();
    stopRecords.clear();
    
    // 重置统计数据为加载状态
    stayCount.value = 0;
    stayDuration.value = "加载中...";
    moveDistance.value = "加载中...";
    
    // 🎯 恢复高亮圆圈
    if (savedHighlightCircles.isNotEmpty) {
      highlightCircles.assignAll(savedHighlightCircles);
      DebugUtil.info('🎯 [ClearInstantly] 已保持高亮圆圈: ${savedHighlightCircles.length}个');
      circlesVersion.value++;
    }
    
    // 异步触发地图更新，避免阻塞UI
    Future.microtask(() => _forceMapUpdate());
    
    DebugUtil.success('✅ [ClearInstantly] 数据已清空，显示加载状态');
  }
  
  /// 智能清空数据 - 头像切换专用，提供更好的用户反馈
  void _clearDataForAvatarSwitch() {
    DebugUtil.info('🧹 [ClearAvatar] 开始清空数据（头像切换）...');
    
    // 🎯 保存当前的高亮圆圈，避免在头像切换时被清除
    final savedHighlightCircles = Set<Circle>.from(highlightCircles);
    
    // ⚠️ 必须先设置无效状态，防止在清空过程中触发Polyline创建
    hasValidTrackData.value = false;
    
    // 立即清空可视数据
    trackPoints.clear();
    stopPoints.clear();
    stayMarkers.clear();
    trackStartEndMarkers.clear();
    stopRecords.clear();
    
    // 显示切换状态，而不是加载状态
    stayCount.value = 0;
    stayDuration.value = "切换中...";
    moveDistance.value = "切换中...";
    
    // 🎯 恢复高亮圆圈
    if (savedHighlightCircles.isNotEmpty) {
      highlightCircles.assignAll(savedHighlightCircles);
      DebugUtil.info('🎯 [ClearAvatar] 已保持高亮圆圈: ${savedHighlightCircles.length}个');
      circlesVersion.value++;
    }
    
    // 异步触发地图更新
    Future.microtask(() => _forceMapUpdate());
    
    DebugUtil.success('✅ [ClearAvatar] 数据已清空，显示切换状态');
  }
  
  /// 强制地图更新，确保UI同步
  void _forceMapUpdate() {
    // 检查地图是否就绪
    if (!isMapReady.value) {
      DebugUtil.warning('地图未就绪，跳过强制更新');
      return;
    }
    
    DebugUtil.info('🔄 [ForceMapUpdate] 开始强制更新地图，当前圆圈数量: ${highlightCircles.length}');
    
    // 强制刷新所有响应式变量，让UI重新构建
    trackPoints.refresh();
    stopPoints.refresh();
    stayMarkers.refresh();
    trackStartEndMarkers.refresh();
    highlightCircles.refresh(); // 🎯 确保高亮圆圈也被刷新
    
    // 🎯 触发地图页面的缓存更新（通过更新任意响应式变量）
    // 这会让地图页面重新计算版本并更新缓存
    update();
    
    DebugUtil.info('✅ [ForceMapUpdate] 地图强制更新完成，圆圈数量: ${highlightCircles.length}');
  }
  
  /// 设置地图就绪状态
  void setMapReady(bool ready) {
    isMapReady.value = ready;
    DebugUtil.info('地图就绪状态更新: $ready');
    
    // 如果地图刚就绪且有待更新的数据，恢复所有地图元素
    if (ready && (trackPoints.isNotEmpty || stopPoints.isNotEmpty || 
                  stayMarkers.isNotEmpty || trackStartEndMarkers.isNotEmpty)) {
      DebugUtil.info('地图就绪，恢复所有轨迹数据到地图');
      
      // 延迟一帧确保地图完全就绪
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _forceMapUpdate();
        
        // 如果有轨迹点，调整地图视图
        if (trackPoints.isNotEmpty) {
          _fitMapToTrackPoints();
        }
      });
    }
  }
  
  /// 强制刷新当前日期数据（不使用缓存）
  Future<void> forceRefresh() async {
    final dateString = DateFormat('yyyy-MM-dd').format(selectedDate.value);
    final isOneSelfValue = isOneself.value == 1;
    
    DebugUtil.info('强制刷新数据: $dateString');
    
    try {
      final result = await TrackApi.forceRefresh(
        date: dateString,
        isOneself: isOneSelfValue ? 1 : 0,
      );
      
      if (result.isSuccess && result.data != null) {
        locationData.value = result.data;
        
        // ⚠️ 注意顺序：先更新轨迹数据（调整stopPoints），再更新停留记录（使用调整后的stopPoints）
    await _updateTrackDataAsync();
    await _updateStopRecords();
    _updateStatistics();
    
        CustomToast.show(Get.context!, '数据刷新成功');
      } else {
        CustomToast.show(Get.context!, result.msg ?? '刷新失败');
      }
    } catch (e) {
      CustomToast.show(Get.context!, '刷新失败: $e');
    }
  }
  
  /// 获取缓存统计信息
  Future<Map<String, dynamic>> getCacheStats() async {
    return await TrackApi.getCacheStats();
  }
  
  /// 清除所有缓存
  Future<void> clearAllCache() async {
    await TrackApi.clearAllCache();
    CustomToast.show(Get.context!, '缓存已清除');
  }

  /// 清空数据
  void _clearData() {
    DebugUtil.info('🧹 [ClearData] 开始清空所有数据...');
    
    // ⚠️ 必须先设置无效状态，防止在清空过程中触发Polyline创建
    hasValidTrackData.value = false;
    
    // 然后清空所有数据
    trackPoints.clear();
    stopPoints.clear();
    stayMarkers.clear();
    trackStartEndMarkers.clear();
    stopRecords.clear();
    stayCount.value = 0;
    stayDuration.value = "";
    moveDistance.value = "";
    
    // 清空圆圈并提升版本
    if (highlightCircles.isNotEmpty) {
      highlightCircles.clear();
      highlightCircles.refresh();
      circlesVersion.value++;
    }
    
    DebugUtil.info('✅ [ClearData] 数据已清空，准备触发地图更新');
    
    // 强制触发地图更新，确保轨迹线被清空
    // 由于hasValidTrackData已经设为false，_updatePolylines会跳过创建Polyline
    _forceMapUpdate();
    
    DebugUtil.success('✅ [ClearData] 数据清空完成');
  }

  /// 新的API结构不需要设备数据，直接使用trace数据

  /// 异步更新轨迹数据 - 优化性能版本
  Future<void> _updateTrackDataAsync() async {
    DebugUtil.info('🔄 [TrackData] 开始更新轨迹数据...');
    
    if (locationData.value == null) {
      DebugUtil.error('❌ [TrackData] 位置数据为空，无法更新轨迹');
      return;
    }
    
    final data = locationData.value!;
    
    // 🎯 优先使用 locations 数组，如果为空则从 trace.stops 生成轨迹点
    List<LatLng> rawPoints;
    
    if (data.locations != null && data.locations!.isNotEmpty) {
      // 使用 locations 数组（旧版API）
      DebugUtil.info('📊 [TrackData] 使用locations数据源，位置点=${data.locations!.length}个');
      rawPoints = await compute(_processLocationData, data.locations!);
    } else if (data.trace?.stops != null && data.trace!.stops.isNotEmpty) {
      // 使用 trace.stops 生成轨迹点（新版API）
      DebugUtil.info('📊 [TrackData] 使用trace.stops数据源，停留点=${data.trace!.stops.length}个');
      rawPoints = await compute(_processStopsAsTrackData, data.trace!.stops);
    } else {
      DebugUtil.warning('⚠️ [TrackData] locations和trace.stops都为空，无轨迹数据');
      rawPoints = [];
    }
    
    // 先检查数据有效性，再进行原子更新
    // 🎯 判断是否有效轨迹：至少2个点 + 不是所有点都在同一位置
    bool isValidData = false;
    if (rawPoints.isNotEmpty && rawPoints.length >= 2) {
      // 检查是否所有点都是同一个坐标（误差范围内）
      final firstPoint = rawPoints.first;
      const double epsilon = 0.00001; // 约1米的误差范围
      
      bool allSameLocation = rawPoints.every((point) {
        return (point.latitude - firstPoint.latitude).abs() < epsilon &&
               (point.longitude - firstPoint.longitude).abs() < epsilon;
      });
      
      isValidData = !allSameLocation; // 只有当不是所有点都在同一位置时，才是有效轨迹
      
      if (allSameLocation) {
        DebugUtil.info('📍 [TrackData] 所有轨迹点在同一位置，不绘制轨迹线');
      }
    }
    
    // 原子更新：先更新状态，再更新数据
    hasValidTrackData.value = isValidData;
    trackPoints.value = rawPoints;
    DebugUtil.info('✅ [TrackData] 轨迹点数量: ${trackPoints.length}');
    
    // 立即触发地图更新，确保轨迹线显示
    _forceMapUpdate();
    
    // ⚠️ 必须await，确保stopPoints更新完成后再返回
    // 否则_updateStopRecords会在stopPoints更新之前被调用，导致stopRecords为空！
    DebugUtil.info('🔄 [TrackData] 开始处理停留点数据...');
    await _processStopPointsAsync(data);
    DebugUtil.success('✅ [TrackData] 停留点数据处理完成，stopPoints=${stopPoints.length}');
    
    // 异步更新标记，避免阻塞UI（可以不await）
    _updateMarkersAsync();
    
    DebugUtil.success('✅ [TrackData] 轨迹数据更新完成！');
  }
  
  /// 异步处理停留点数据
  Future<void> _processStopPointsAsync(LocationResponse data) async {
    try {
      DebugUtil.info('📍 [StopPoints] 开始处理停留点数据...');
      
      // 过滤停留点并调整到轨迹线上
      final rawStopPoints = data.trace?.stops
          .where((stop) => stop.lat != 0.0 && stop.lng != 0.0)
          .toList() ?? [];
      DebugUtil.info('📊 [StopPoints] 原始停留点数量: ${rawStopPoints.length}');
      
      if (rawStopPoints.isEmpty) {
        DebugUtil.warning('⚠️ [StopPoints] 没有有效的停留点数据');
        stopPoints.clear();
        return;
      }
      
      // 🎯 关键修复：如果没有有效轨迹线，直接使用原始停留点（不调整位置）
      // 这种情况常见于：用户整天都在停留，没有移动轨迹
      // 也包括多个点但都在同一位置的情况（没有实际移动）
      if (trackPoints.isEmpty || trackPoints.length < 2 || !hasValidTrackData.value) {
        DebugUtil.warning('⚠️ [StopPoints] 没有有效轨迹线（trackPoints=${trackPoints.length}, hasValidTrackData=${hasValidTrackData.value}），直接使用原始停留点坐标');
        stopPoints.value = rawStopPoints;
        DebugUtil.success('✅ [StopPoints] 使用原始停留点，数量: ${stopPoints.length}');
        
        // 🎯 检查是否需要自动显示InfoWindow
        _checkAutoShowInfoWindow();
        return;
      }
      
      // 在后台线程处理停留点调整（将停留点调整到轨迹线上）
      DebugUtil.info('🔄 [StopPoints] 开始调整停留点到轨迹线上...');
      final adjustedStopPoints = await compute(_adjustStopPointsToTrackLineStatic, {
        'rawStopPoints': rawStopPoints,
        'trackPoints': trackPoints.toList(),
      });
      stopPoints.value = adjustedStopPoints;
      DebugUtil.success('✅ [StopPoints] 调整后停留点数量: ${stopPoints.length}');
      
      // 🎯 检查是否需要自动显示InfoWindow
      _checkAutoShowInfoWindow();
      
    } catch (e) {
      DebugUtil.error('❌ [StopPoints] 处理停留点数据失败: $e');
      stopPoints.clear();
    }
  }
  
  /// 异步更新标记
  Future<void> _updateMarkersAsync() async {
    try {
      // 并行更新停留点标记和起终点标记
      await Future.wait([
        _safeUpdateStayMarkers(),
        _updateTrackStartEndMarkers(),
      ]);
    } catch (e) {
      DebugUtil.error('更新标记失败: $e');
    }
  }
  
  /// 在后台线程处理位置数据（旧版API - locations数组）
  static List<LatLng> _processLocationData(List<TrackLocation> locations) {
    return locations
        .map((location) => LatLng(location.lat, location.lng))
        .where((point) => point.latitude != 0.0 && point.longitude != 0.0)
        .toList();
  }
  
  /// 在后台线程从stops生成轨迹数据（新版API - trace.stops）
  static List<LatLng> _processStopsAsTrackData(List<TrackStopPoint> stops) {
    // 从stops中提取所有有效的位置点作为轨迹点
    return stops
        .map((stop) => LatLng(stop.lat, stop.lng))
        .where((point) => point.latitude != 0.0 && point.longitude != 0.0)
        .toList();
  }
  
  /// 静态版本的停留点调整方法，用于后台线程
  static List<TrackStopPoint> _adjustStopPointsToTrackLineStatic(Map<String, dynamic> params) {
    final rawStopPoints = params['rawStopPoints'] as List<TrackStopPoint>;
    final trackPoints = params['trackPoints'] as List<LatLng>;
    
    if (rawStopPoints.isEmpty || trackPoints.isEmpty) {
      return rawStopPoints;
    }
    
    final adjustedStopPoints = <TrackStopPoint>[];
    
    for (final stopPoint in rawStopPoints) {
      final stopLatLng = LatLng(stopPoint.lat, stopPoint.lng);
      
      // 找到停留点到轨迹线的最近距离和最近点
      final nearestPoint = _findNearestPointOnTrackLineStatic(stopLatLng, trackPoints);
      final distanceToTrack = _calculateDistanceBetweenPointsStatic(stopLatLng, nearestPoint.point);
      
      // 如果距离超过阈值，将停留点移动到轨迹线上
      const double maxDistanceThreshold = 100.0; // 100米阈值
      
      if (distanceToTrack > maxDistanceThreshold) {
        // 创建调整后的停留点
        final adjustedStopPoint = TrackStopPoint(
          lat: nearestPoint.point.latitude,
          lng: nearestPoint.point.longitude,
          startTime: stopPoint.startTime,
          endTime: stopPoint.endTime,
          locationName: stopPoint.locationName,
          duration: stopPoint.duration,
          status: stopPoint.status,
          pointType: stopPoint.pointType,
          serialNumber: stopPoint.serialNumber,
        );
        adjustedStopPoints.add(adjustedStopPoint);
      } else {
        // 距离在阈值内，保持原位置
        adjustedStopPoints.add(stopPoint);
      }
    }
    
    return adjustedStopPoints;
  }
  
  /// 静态版本的最近点查找方法
  static ({LatLng point, int segmentIndex, double ratio}) _findNearestPointOnTrackLineStatic(LatLng targetPoint, List<LatLng> trackPoints) {
    if (trackPoints.isEmpty) {
      return (point: targetPoint, segmentIndex: 0, ratio: 0.0);
    }
    
    if (trackPoints.length == 1) {
      return (point: trackPoints.first, segmentIndex: 0, ratio: 0.0);
    }
    
    double minDistance = double.infinity;
    LatLng nearestPoint = trackPoints.first;
    int nearestSegmentIndex = 0;
    double nearestRatio = 0.0;
    
    // 遍历所有线段，找到最近的投影点
    for (int i = 0; i < trackPoints.length - 1; i++) {
      final segmentStart = trackPoints[i];
      final segmentEnd = trackPoints[i + 1];
      
      // 计算目标点到当前线段的最近点
      final projectionResult = _calculateProjectionOnSegmentStatic(targetPoint, segmentStart, segmentEnd);
      final distance = _calculateDistanceBetweenPointsStatic(targetPoint, projectionResult.point);
      
      if (distance < minDistance) {
        minDistance = distance;
        nearestPoint = projectionResult.point;
        nearestSegmentIndex = i;
        nearestRatio = projectionResult.ratio;
      }
    }
    
    return (point: nearestPoint, segmentIndex: nearestSegmentIndex, ratio: nearestRatio);
  }
  
  /// 静态版本的投影计算方法
  static ({LatLng point, double ratio}) _calculateProjectionOnSegmentStatic(LatLng targetPoint, LatLng segmentStart, LatLng segmentEnd) {
    // 将经纬度转换为平面坐标进行计算（近似处理）
    final double ax = segmentStart.longitude * 111320 * cos(segmentStart.latitude * pi / 180);
    final double ay = segmentStart.latitude * 111320;
    final double bx = segmentEnd.longitude * 111320 * cos(segmentEnd.latitude * pi / 180);
    final double by = segmentEnd.latitude * 111320;
    final double px = targetPoint.longitude * 111320 * cos(targetPoint.latitude * pi / 180);
    final double py = targetPoint.latitude * 111320;
    
    // 计算向量
    final double abx = bx - ax;
    final double aby = by - ay;
    final double apx = px - ax;
    final double apy = py - ay;
    
    // 计算投影比例
    final double abSquared = abx * abx + aby * aby;
    if (abSquared == 0) {
      // 线段退化为点
      return (point: segmentStart, ratio: 0.0);
    }
    
    double t = (apx * abx + apy * aby) / abSquared;
    
    // 限制投影点在线段范围内
    t = max(0.0, min(1.0, t));
    
    // 计算投影点的经纬度
    final double projX = ax + t * abx;
    final double projY = ay + t * aby;
    
    // 转换回经纬度
    final double projLat = projY / 111320;
    final double projLng = projX / (111320 * cos(projLat * pi / 180));
    
    return (point: LatLng(projLat, projLng), ratio: t);
  }
  
  /// 静态版本的距离计算方法
  static double _calculateDistanceBetweenPointsStatic(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // 地球半径（米）
    
    final double lat1Rad = point1.latitude * pi / 180;
    final double lat2Rad = point2.latitude * pi / 180;
    final double deltaLat = (point2.latitude - point1.latitude) * pi / 180;
    final double deltaLng = (point2.longitude - point1.longitude) * pi / 180;
    
    final double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLng / 2) * sin(deltaLng / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// 更新统计数据
  void _updateStatistics() {
    if (locationData.value == null) {
      DebugUtil.error(' locationData为空，无法更新统计数据');
      return;
    }
    
    DebugUtil.info('🔍 开始更新统计数据');
    
    // 🎯 优先从 trace.stay_collect 获取统计数据（根据实际JSON结构）
    final traceStayCollect = locationData.value!.trace?.stayCollect;
    if (traceStayCollect != null) {
      DebugUtil.success(' 使用trace.stay_collect的统计数据 (主要数据源)');
      stayCount.value = traceStayCollect.stayCount ?? 0;
      stayDuration.value = traceStayCollect.stayTime ?? '';
      moveDistance.value = traceStayCollect.moveDistance ?? '';
      DebugUtil.info('📊 统计数据: 停留次数=${stayCount.value}, 停留时间=${stayDuration.value}, 移动距离=${moveDistance.value}');
      return;
    }
    
    DebugUtil.warning(' trace.stay_collect为空，设置默认统计数据');
    stayCount.value = 0;
    stayDuration.value = '';
    moveDistance.value = '';
  }

  /// 更新停留记录列表 - 异步优化版本
  Future<void> _updateStopRecords() async {
    DebugUtil.info('🔍 [StopRecords] 开始更新停留记录列表');
    
    if (locationData.value == null) {
      DebugUtil.error('❌ [StopRecords] locationData为空，无法更新停留记录');
      stopRecords.clear();
      return;
    }
    
    DebugUtil.info('✅ [StopRecords] locationData存在，trace=${locationData.value!.trace != null}');
    
    // ⚠️ 使用调整后的 stopPoints 而不是原始的 trace.stops
    // 这样可以确保列表项和Marker使用相同的坐标（调整到轨迹线上的坐标）
    if (stopPoints.isEmpty) {
      DebugUtil.warning('⚠️ [StopRecords] stopPoints为空，清空stopRecords');
      
      // 调试：检查原始数据
      final rawStops = locationData.value?.trace?.stops ?? [];
      DebugUtil.warning('⚠️ [StopRecords] 但原始trace.stops有 ${rawStops.length} 条数据');
      
      stopRecords.clear();
      return;
    }
    
    DebugUtil.info('📊 [StopRecords] stopPoints数量: ${stopPoints.length}');
    
    // 在后台线程处理停留记录数据转换
    try {
      final processedRecords = await compute(_processStopRecords, stopPoints.toList());
      stopRecords.value = processedRecords;
      DebugUtil.success('✅ [StopRecords] 停留记录更新完成，总数量: ${stopRecords.length}');
      DebugUtil.success('✅ [StopRecords] stopRecords使用调整后的stopPoints坐标，与Marker坐标一致');
    } catch (e) {
      DebugUtil.error('❌ [StopRecords] 处理停留记录失败: $e');
      stopRecords.clear();
    }
  }
  
  /// 在后台线程处理停留记录数据
  static List<StopRecord> _processStopRecords(List<TrackStopPoint> adjustedStopPoints) {
    return adjustedStopPoints.map((stop) {
      return StopRecord(
        latitude: stop.lat,   // 使用调整后的坐标
        longitude: stop.lng,  // 使用调整后的坐标
        locationName: stop.locationName ?? '',
        startTime: stop.startTime ?? '',
        endTime: stop.endTime?.isNotEmpty == true ? stop.endTime! : (stop.startTime ?? ''),
        duration: stop.duration ?? '',
        status: stop.status ?? '',
        pointType: stop.pointType ?? '',
        serialNumber: stop.serialNumber ?? '',
      );
    }).toList();
  }

  /// 当没有有效轨迹点时，尝试移动到起点或终点
  void _moveToValidPoint() {
    if (locationData.value == null) return;
    
    final data = locationData.value!;
    
    // 尝试使用起点
    if (data.trace?.startPoint.lat != 0.0 && data.trace?.startPoint.lng != 0.0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _moveMapToLocation(LatLng(data.trace!.startPoint.lat, data.trace!.startPoint.lng));
      });
      return;
    }
    
    // 尝试使用终点
    if (data.trace?.endPoint.lat != 0.0 && data.trace?.endPoint.lng != 0.0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _moveMapToLocation(LatLng(data.trace!.endPoint.lat, data.trace!.endPoint.lng));
      });
      return;
    }
    
    // 如果都没有有效坐标，保持默认杭州坐标（在mapOptions中已设置）
  }

  /// 切换查看用户（自己/另一半）
  void switchUser() {
    isOneself.value = isOneself.value == 1 ? 0 : 1;
    
    // 🎯 注释掉清除高亮圆圈，让圆圈在切换用户时保持显示
    // clearAllHighlightCircles();
    
    // 切换用户时，立即清空数据并异步加载，避免卡顿
    _clearDataForAvatarSwitch();
    Future.microtask(() => _loadDataAsync());
  }
  
  /// 头像点击时切换用户视角（不重新请求API，直接从缓存切换）
  void onAvatarTapped(bool isMyself) {
    DebugUtil.info('🎯 头像点击开始 - isMyself: $isMyself');
    
    // 🎯 注释掉清除高亮圆圈，让圆圈在切换用户时保持显示
    // clearAllHighlightCircles();
    
    // 🎬 切换头像时重置轨迹播放状态
    if (isReplaying.value) {
      DebugUtil.info('🛑 检测到正在播放轨迹，切换头像时重置播放状态');
      _resetReplayState();
    }
    
    // 更新状态
    if (isMyself) {
      // 点击自己头像，切换到自己的视角
      isOneself.value = 1;
      DebugUtil.info('🔄 切换到自己的视角');
    } else {
      // 点击另一半头像，切换到另一半的视角
      isOneself.value = 0;
      DebugUtil.info('🔄 切换到另一半的视角');
    }
    
    // 🚀 直接从缓存切换数据，不重新请求API
    DebugUtil.info('⚡ 从缓存切换数据，避免重新请求API');
    
    // 使用微任务确保不阻塞UI
    scheduleMicrotask(() {
      _switchToCurrentUserData();
      
      // 延迟一帧，确保数据已更新
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final targetUser = isOneself.value == 1;
        DebugUtil.info('📡 数据切换完成，准备移动地图...');
        _moveToTargetUserTrackLocation(targetUser);
      });
    });
  }
  
  /// 移动地图到目标用户的轨迹位置
  void _moveToTargetUserTrackLocation(bool isMyself) {
    if (!isMapReady.value || mapController == null) {
      DebugUtil.error('🚫 地图未就绪或控制器不存在，无法移动地图');
      return;
    }
    
    LatLng? targetLocation;
    String userName;
    
    if (isMyself) {
      userName = "我的轨迹";
    } else {
      userName = "另一半的轨迹";
    }
    
    DebugUtil.info('🎯 尝试移动到$userName，当前isOneself=${isOneself.value}');
    
    // 直接从最新的API数据中获取轨迹位置（避免依赖可能未更新的trackPoints）
    if (locationData.value?.trace != null) {
      final trace = locationData.value!.trace!;
      DebugUtil.info('📊 API轨迹数据 - 起点: (${trace.startPoint.lat}, ${trace.startPoint.lng}), 终点: (${trace.endPoint.lat}, ${trace.endPoint.lng})');
      
      // 优先使用起点坐标
      if (trace.startPoint.lat != 0.0 && trace.startPoint.lng != 0.0) {
        targetLocation = LatLng(trace.startPoint.lat, trace.startPoint.lng);
        DebugUtil.info('✅ 使用API起点作为目标位置: $targetLocation');
      } else if (trace.endPoint.lat != 0.0 && trace.endPoint.lng != 0.0) {
        targetLocation = LatLng(trace.endPoint.lat, trace.endPoint.lng);
        DebugUtil.info('✅ 使用API终点作为目标位置: $targetLocation');
      }
    } else {
      DebugUtil.warning('⚠️ 没有API轨迹数据可用');
    }
    
    // 如果API数据中没有轨迹信息，再尝试使用已处理的轨迹点
    if (targetLocation == null && trackPoints.isNotEmpty) {
      targetLocation = trackPoints.first;
      DebugUtil.info('✅ 使用处理后的轨迹起点作为目标位置: $targetLocation');
    }
    
    DebugUtil.info('📍 目标位置信息：$userName = $targetLocation');
    
    if (targetLocation == null) {
      DebugUtil.error('❌ 无法移动到$userName：位置信息不存在');
      return;
    }
    
    // 移动到目标位置并放大（轨迹页面使用适中的缩放级别）
    final targetZoomPosition = CameraPosition(
      target: targetLocation,
      zoom: 16.0, // 适合查看轨迹的缩放级别
    );
    
    DebugUtil.info('🎯 头像点击：移动地图到$userName并调整缩放级别(16.0)');
    
    try {
      // 异步执行地图动画，避免阻塞主线程
      unawaited(mapController!.moveCamera(
        CameraUpdate.newCameraPosition(targetZoomPosition),
        animated: true,
        duration: 800, // 800ms平滑动画
      ));
      DebugUtil.success('✅ 地图移动命令已发送');
      
      // 如果有完整轨迹数据，延迟后自动适配到完整轨迹视图
      if (trackPoints.length > 1) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          _fitMapToTrackPoints();
        });
      }
    } catch (e) {
      DebugUtil.error('❌ 地图移动失败: $e');
    }
  }

  /// 刷新当前用户数据（用于外部调用，如绑定伴侣后刷新）
  /// 会重新加载当前日期的轨迹数据
  Future<void> refreshCurrentUserData() async {
    DebugUtil.info('🔄 外部刷新请求: 重新加载当前日期的轨迹数据');
    
    try {
      // 调用标准的数据加载方法，会并发请求两个用户的数据
      await loadLocationData();
      DebugUtil.success('✅ 轨迹数据刷新完成');
    } catch (e) {
      DebugUtil.error('❌ 轨迹数据刷新失败: $e');
    }
  }

  /// 切换地图类型
  void switchMapType(int type) {
    if (type != 1 && type != 2) {
      DebugUtil.warning('⚠️ 无效的地图类型: $type，应该是 1（经典）或 2（卫星）');
      return;
    }
    mapType.value = type;
    DebugUtil.info('🗺️ 地图类型已切换为: ${type == 1 ? "经典地图" : "卫星地图"}');
  }
  
  /// 异步加载数据，完全非阻塞版本
  Future<void> _loadDataAsync() async {
    try {
      // 显示加载状态（仅对今天的数据）
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final selectedDateString = DateFormat('yyyy-MM-dd').format(selectedDate.value);
      final isToday = selectedDateString == today;
      
      if (isToday) {
        isLoading.value = true;
      }
      
      // 异步调用数据加载，避免阻塞UI
      await _performLoadLocationDataDirect();
      
      // 数据加载完成后，异步调整地图视图
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          // 异步调整地图视图，避免阻塞
          await Future.delayed(const Duration(milliseconds: 100));
          await _fitMapToTrackPoints();
          
          // 移动地图到合适位置
          if (trackPoints.isNotEmpty) {
            _moveMapToLocation(trackPoints.first);
          } else {
            _moveToValidPoint();
          }
        } catch (e) {
          DebugUtil.error('地图视图调整失败: $e');
        }
      });
      
    } catch (e) {
      DebugUtil.error('异步加载数据失败: $e');
      isLoading.value = false;
    }
  }
  
  /// 已废弃：现在使用 _switchToCurrentUserData() 中的数据更新逻辑
  
  /// 渐进式数据更新 - 分步骤更新，避免长时间阻塞
  Future<void> _progressiveDataUpdate() async {
    try {
      // 第一步：更新统计数据（最快）
      Future.microtask(() => _updateStatistics());
      
      // 第二步：更新轨迹数据（最耗时，会调整stopPoints）
      await _updateTrackDataAsync();
      
      // ⚠️ 第三步：更新停留记录（必须在stopPoints调整之后，才能使用调整后的坐标）
      await _updateStopRecords();
      
      DebugUtil.success('渐进式数据更新完成');
    } catch (e) {
      DebugUtil.error('渐进式数据更新失败: $e');
    }
  }
  
  // 移除所有缓存相关方法

  /// 执行绑定操作 - 显示绑定弹窗
  void performBindAction() {
    if (Get.context != null) {
      CustomBottomDialog.show(context: Get.context!);
    }
  }

  /// 选择日期
  void selectDate(DateTime date) {
    DebugUtil.info('📅 TrackController.selectDate 被调用: ${DateFormat('yyyy-MM-dd').format(date)}');
    
    selectedDate.value = date;
    
    // 计算选中的日期对应的索引（0-6，最近7天）
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    final index = 6 - difference; // 6是今天，5是昨天，以此类推
    selectedDateIndex.value = index.clamp(0, 6);
    
    DebugUtil.info('🔄 选择日期: ${DateFormat('yyyy-MM-dd').format(date)}, 索引: ${selectedDateIndex.value}, 开始加载数据...');
    
    // 只有今天的数据才显示loading动画
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final selectedDateString = DateFormat('yyyy-MM-dd').format(date);
    final isToday = selectedDateString == today;
    
    if (isToday) {
    isLoading.value = true;
    }
    
    // 清空当前数据，给用户即时反馈
    _clearDataForNewDate();
    
    // 异步加载新日期数据，避免卡顿
    Future.microtask(() => _loadDataAsync());
    
    // 移除预加载功能，改为按需加载避免卡顿
    // _preloadAdjacentDates(date);
  }
  
  /// 切换日期时清空数据，给用户即时反馈
  void _clearDataForNewDate() {
    // 保持加载状态，只清空可视数据
    trackPoints.clear();
    stopPoints.clear();
    stayMarkers.clear();
    trackStartEndMarkers.clear();
    stopRecords.clear();
    stayCount.value = 0;
    stayDuration.value = "加载中...";
    moveDistance.value = "加载中...";
    
    // 异步触发地图更新，避免阻塞UI
    Future.microtask(() => _forceMapUpdate());
  }
  

  // 已移除缓存相关方法，不再需要清除缓存

  /// 创建自定义停留点图标
  /// 参数: number - 显示的数字
  /// 根据数字位数自适应宽度：个位数为圆形，多位数为椭圆形
  Future<BitmapDescriptor> _createCustomStayPointIcon(String number) async {
    const double borderWidth = 2.0; // 白色边框宽度（稍微减小）
    const double minRadius = 30.0; // 最小半径（圆形，减小尺寸）
    const double fontSize = 32.0; // 字体大小（减小到20）
    
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
    final requiredWidth = textWidth + 6; // 文本宽度 + 左右边距（增大到10px每边）
    final requiredHeight = textHeight + 4; // 文本高度 + 上下边距（增大到8px每边）
    
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

  /// 安全地更新停留点 markers - 高性能优化版本
  Future<void> _safeUpdateStayMarkers() async {
    DebugUtil.info('🔄 更新停留点 markers...');
    
    // 如果没有停留点，直接清空并返回
    if (stopPoints.isEmpty) {
      stayMarkers.clear();
      return;
    }
    
    // 异步执行，避免阻塞UI
    Future.microtask(() async {
      try {
        // 优先使用简单标记，提升响应速度
        await _createSimpleStayMarkers();
        
        // 在后台异步创建自定义图标，完成后替换
        _createCustomMarkersInBackground();
        
      } catch (e) {
        DebugUtil.error('更新停留点标记失败: $e');
        // 失败时使用最简单的默认标记
        await _createFallbackMarkers();
      }
    });
  }
  
  /// 在后台创建自定义标记
  Future<void> _createCustomMarkersInBackground() async {
    try {
      await _updateStayMarkersWithIcons();
      DebugUtil.success('自定义标记创建完成');
    } catch (e) {
      DebugUtil.warning('自定义标记创建失败，保持简单标记: $e');
    }
  }
  
  /// 创建降级标记
  Future<void> _createFallbackMarkers() async {
    stayMarkers.clear();
    
    if (stopPoints.isEmpty) return;
    
    DebugUtil.info('🚀 创建降级标记: ${stopPoints.length}个');
    
    for (int i = 0; i < stopPoints.length; i++) {
      final stop = stopPoints[i];
      
      if (stop.lat == 0.0 || stop.lng == 0.0) continue;
      
      // 跳过终点和起点
      bool isEndPoint = stop.pointType == 'end' || stop.serialNumber == '终';
      bool isStartPoint = stop.pointType == 'start' || stop.serialNumber == '起';
      if (isEndPoint || isStartPoint) continue;
      
      // 使用最简单的默认标记
      final stopInfo = _parseStopInfo(stop);
      final String markerTitle = stopInfo['locationName']!;
      final String markerSnippet = '${stop.startTime ?? ''} ${stop.duration?.isNotEmpty == true ? '停留${stop.duration}' : ''}';
      
      final marker = Marker(
        position: LatLng(stop.lat, stop.lng),
         alpha: 0.0, // 🎯 完全透明，不显示系统marker
         anchor: const Offset(0.5, 0.5), // 🎯 设置锚点为中心，使InfoWindow相对坐标点居中
         infoWindowEnable: true, // 允许点击时显示 InfoWindow
         autoShowCustomInfoWindow: false, // 默认不自动显示
         draggable: true, // 🎯 启用拖拽功能
         isTrackStyle: true, // 🎯 使用轨迹样式 InfoWindow
         stayDuration: stopInfo['stayDuration'], // 🎯 停留时长
         stayTime: stopInfo['stayTime'], // 🎯 停留时间
        infoWindow: InfoWindow(
          title: markerTitle,
          snippet: markerSnippet,
        ),
        customInfoWindowBuilder: (context) => _buildTrackInfoWindow(
          stopInfo['locationName']!,
          stopInfo['stayDuration']!,
          stopInfo['stayTime']!,
        ),
        onDragEnd: (String markerId, LatLng newPosition) {
          // 🎯 拖拽结束时清除现有圆圈并重新创建
          DebugUtil.info('🎯 停留点 Marker 拖拽结束，新位置: ${newPosition.latitude}, ${newPosition.longitude}');
          drawHighlightCircle(newPosition); // 这个方法会先清除现有圆圈再创建新的
        },
        onTap: (String markerId) {
          DebugUtil.info('🎯 点击地图上的停留点: ${stop.locationName}');
          // InfoWindow 会自动显示（因为 infoWindowEnable 为 true）
            _moveMapToLocation(LatLng(stop.lat, stop.lng));
        },
      );
      
      stayMarkers.add(marker);
    }
    
    DebugUtil.success('降级标记创建完成: ${stayMarkers.length}个');
  }

  /// 更新停留点 markers（使用自定义粉色圆形图标显示数字）
  Future<void> _updateStayMarkersWithIcons() async {
    stayMarkers.clear();
    
    if (stopPoints.isEmpty) {
      DebugUtil.info('📍 没有停留点数据');
      return;
    }
    
    DebugUtil.info('📍 创建停留点标记: ${stopPoints.length}个点');
    
    try {
      final List<Marker> tempMarkers = [];
      // 使用停留点的实际serialNumber，不再使用倒序编号
      
      for (int i = 0; i < stopPoints.length; i++) {
        final stop = stopPoints[i];
        
        // 根据 pointType 和 serialNumber 判断点的类型
        bool isEndPoint = stop.pointType == 'end' || stop.serialNumber == '终';
        bool isStartPoint = stop.pointType == 'start' || stop.serialNumber == '起';
        
        // 跳过终点和起点，只显示中间停留点
        if (isEndPoint || isStartPoint) {
          continue;
        }
        
        // 使用停留点的实际serialNumber作为显示编号（在try块外定义）
        String displayNumber = stop.serialNumber ?? (i + 1).toString();
        
        try {
          String title = '停留点 ${displayNumber}';
          BitmapDescriptor? icon;
          
          // 创建自定义停留点图标
          try {
            icon = await _createCustomStayPointIcon(displayNumber);
            DebugUtil.success(' 停留点 ${displayNumber} 自定义图标创建成功');
          } catch (iconError) {
            DebugUtil.warning(' 停留点 ${displayNumber} 自定义图标创建失败，使用默认标记: $iconError');
            // 降级方案：使用粉色默认标记
            try {
              icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
            } catch (fallbackError) {
              DebugUtil.warning(' 默认标记也创建失败: $fallbackError');
            icon = null; // 使用系统默认标记
            }
          }
          
          // 创建标记，根据icon是否可用决定是否设置
          final stopInfo = _parseStopInfo(stop);
          final String infoTitle = stopInfo['locationName']!;
          final String infoSnippet = '${stop.startTime ?? ''} ${stop.duration?.isNotEmpty == true ? '停留${stop.duration}' : ''}';
          
          final marker = icon != null 
            ? Marker(
                position: LatLng(stop.lat, stop.lng),
                icon: icon,
                anchor: const Offset(0.5, 0.5), // 设置锚点为图片中心
                infoWindowEnable: true, // 允许点击时显示 InfoWindow
                autoShowCustomInfoWindow: false, // 默认不自动显示
                draggable: true, // 🎯 启用拖拽功能
                isTrackStyle: true, // 🎯 使用轨迹样式 InfoWindow
                stayDuration: stopInfo['stayDuration'], // 🎯 停留时长
                stayTime: stopInfo['stayTime'], // 🎯 停留时间
                infoWindow: InfoWindow(
                  title: infoTitle,
                  snippet: infoSnippet,
                ),
                customInfoWindowBuilder: (context) => _buildTrackInfoWindow(
                  stopInfo['locationName']!,
                  stopInfo['stayDuration']!,
                  stopInfo['stayTime']!,
                ),
                onDragEnd: (String markerId, LatLng newPosition) {
                  // 🎯 拖拽结束时清除现有圆圈并重新创建
                  DebugUtil.info('🎯 停留点标记（有图标）拖拽结束，新位置: ${newPosition.latitude}, ${newPosition.longitude}');
                  drawHighlightCircle(newPosition); // 这个方法会先清除现有圆圈再创建新的
                },
                onTap: (String markerId) {
                  DebugUtil.info('🎯 点击地图上的停留点标记: $title - ${stop.locationName}');
                  // InfoWindow 会自动显示（因为 infoWindowEnable 为 true）
                  // 移动地图、绘制高亮圆圈
                  unawaited(_moveToStopPointWithHighlightInternal(
                    stop.lat, 
                    stop.lng, 
                    stopPoint: stop,
                  ));
                },
              )
            : Marker(
                position: LatLng(stop.lat, stop.lng),
                 alpha: 0.0, // 🎯 完全透明，不显示系统marker
                anchor: const Offset(0.5, 0.5), // 🎯 设置锚点为中心，使InfoWindow相对坐标点居中
                 infoWindowEnable: true, // 允许点击时显示 InfoWindow
                 autoShowCustomInfoWindow: false, // 默认不自动显示
                 draggable: true, // 🎯 启用拖拽功能
                 isTrackStyle: true, // 🎯 使用轨迹样式 InfoWindow
                 stayDuration: stopInfo['stayDuration'], // 🎯 停留时长
                 stayTime: stopInfo['stayTime'], // 🎯 停留时间
                infoWindow: InfoWindow(
                  title: infoTitle,
                  snippet: infoSnippet,
                ),
                customInfoWindowBuilder: (context) => _buildTrackInfoWindow(
                  stopInfo['locationName']!,
                  stopInfo['stayDuration']!,
                  stopInfo['stayTime']!,
                ),
                onDragEnd: (String markerId, LatLng newPosition) {
                  // 🎯 拖拽结束时清除现有圆圈并重新创建
                  DebugUtil.info('🎯 停留点标记（无图标）拖拽结束，新位置: ${newPosition.latitude}, ${newPosition.longitude}');
                  drawHighlightCircle(newPosition); // 这个方法会先清除现有圆圈再创建新的
                },
                onTap: (String markerId) {
                  DebugUtil.info('🎯 点击地图上的停留点标记: $title - ${stop.locationName}');
                  // InfoWindow 会自动显示（因为 infoWindowEnable 为 true）
                  // 移动地图、绘制高亮圆圈
                  unawaited(_moveToStopPointWithHighlightInternal(
                    stop.lat, 
                    stop.lng, 
                    stopPoint: stop,
                  ));
                },
              );
          
          tempMarkers.add(marker);
          DebugUtil.success(' 停留点 ${displayNumber} ($title) 标记创建成功');
        } catch (e) {
          DebugUtil.error(' 停留点 ${displayNumber} 标记创建失败: $e，尝试降级方案');
          // 降级方案：使用最基本的标记（完全不设置图标）
          try {
            String fallbackTitle = '停留点 ${displayNumber}';
            final stopInfo = _parseStopInfo(stop);
            final String fallbackInfoTitle = stopInfo['locationName']!;
            final String fallbackInfoSnippet = '${stop.startTime ?? ''} ${stop.duration?.isNotEmpty == true ? '停留${stop.duration}' : ''}';
            
            final fallbackMarker = Marker(
              position: LatLng(stop.lat, stop.lng),
               alpha: 0.0, // 🎯 完全透明，不显示系统marker
               anchor: const Offset(0.5, 0.5), // 🎯 设置锚点为中心，使InfoWindow相对坐标点居中
               infoWindowEnable: true, // 允许点击时显示 InfoWindow
               draggable: true, // 🎯 启用拖拽功能
               isTrackStyle: true, // 🎯 使用轨迹样式 InfoWindow
               stayDuration: stopInfo['stayDuration'], // 🎯 停留时长
               stayTime: stopInfo['stayTime'], // 🎯 停留时间
              infoWindow: InfoWindow(
                title: fallbackInfoTitle,
                snippet: fallbackInfoSnippet,
              ),
              customInfoWindowBuilder: (context) => _buildTrackInfoWindow(
                stopInfo['locationName']!,
                stopInfo['stayDuration']!,
                stopInfo['stayTime']!,
              ),
              onDragEnd: (String markerId, LatLng newPosition) {
                // 🎯 拖拽结束时清除现有圆圈并重新创建
                DebugUtil.info('🎯 降级停留点标记拖拽结束，新位置: ${newPosition.latitude}, ${newPosition.longitude}');
                drawHighlightCircle(newPosition); // 这个方法会先清除现有圆圈再创建新的
              },
              onTap: (String markerId) {
                DebugUtil.info('🎯 点击地图上的停留点: $fallbackTitle - ${stop.locationName}');
                // InfoWindow 会自动显示（因为 infoWindowEnable 为 true）
                  _moveMapToLocation(LatLng(stop.lat, stop.lng));
              },
            );
            
            tempMarkers.add(fallbackMarker);
            DebugUtil.success(' 停留点 ${displayNumber} ($fallbackTitle) 降级标记创建成功');
          } catch (fallbackError) {
            DebugUtil.error(' 停留点 ${displayNumber} 降级方案也失败: $fallbackError，跳过此点');
            continue;
          }
        }
      }
      
      // 如果至少有一个标记创建成功，就更新列表
      if (tempMarkers.isNotEmpty) {
        stayMarkers.addAll(tempMarkers);
        DebugUtil.success(' 更新停留点标记成功: ${stayMarkers.length}个');
        
        // 强制触发地图更新，确保标记显示同步
        _forceMapUpdate();
        
        // ✅ 在标记创建后立即关闭所有 InfoWindow，防止自动显示
        Future.delayed(const Duration(milliseconds: 50), () {
          _closeAllInfoWindows();
          DebugUtil.info('🔒 停留点标记创建后关闭所有 InfoWindow');
        });
      } else {
        DebugUtil.error(' 没有成功创建任何停留点标记');
      }
    } catch (e) {
      DebugUtil.error(' 停留点标记更新过程失败: $e');
      
      // 最后的降级方案：创建一个基础彩色标记
      try {
        if (stopPoints.isNotEmpty) {
          final String emergencyTitle = '位置点';
          final String emergencySnippet = stopPoints.first.locationName ?? '未知位置';
          
          stayMarkers.add(Marker(
            position: LatLng(stopPoints.first.lat, stopPoints.first.lng),
            // 使用彩色默认图标
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindowEnable: true, // 允许点击时显示 InfoWindow
            infoWindow: InfoWindow(
              title: emergencyTitle,
              snippet: emergencySnippet,
            ),
            customInfoWindowBuilder: (context) => _buildTrackInfoWindow(
              emergencyTitle, 
              emergencySnippet.isNotEmpty ? emergencySnippet : "紧急位置", 
              ""
            ),
            onTap: (String markerId) {
              DebugUtil.info('🎯 点击地图上的紧急标记');
              // InfoWindow 会自动显示（因为 infoWindowEnable 为 true）
            },
          ));
          DebugUtil.success(' 降级方案：成功创建彩色标记');
        }
      } catch (fallbackError) {
        DebugUtil.error(' 降级方案也失败: $fallbackError');
        // 完全放弃添加标记点，避免崩溃
      }
    }
  }
  
  /// 更新轨迹起点和终点标记
  Future<void> _updateTrackStartEndMarkers() async {
    DebugUtil.info('🔄 更新轨迹起点和终点标记...');
    
    // 清空现有标记
    trackStartEndMarkers.clear();
    
    // 如果没有轨迹点，直接返回
    if (trackPoints.isEmpty) {
      DebugUtil.info('📍 没有轨迹点数据，无法创建起终点标记');
      return;
    }
    
    try {
      final List<Marker> tempMarkers = [];
      
      // 创建起点标记
      final startPoint = trackPoints.first;
      try {
        final startIcon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(44, 46)),
          'assets/kissu_location_start.webp',
        );
        
            final startMarker = Marker(
              position: startPoint,
              icon: startIcon,
              anchor: const Offset(0.41, 0.83), // 设置锚点为图片的 (18, 38) 位置
              infoWindow: InfoWindow.noText,
              onTap: (String markerId) {
                DebugUtil.info('点击了轨迹起点');
                _moveMapToLocation(startPoint);
              },
            );
        
        tempMarkers.add(startMarker);
        DebugUtil.success(' 轨迹起点标记创建成功');
      } catch (e) {
        DebugUtil.error(' 创建起点标记失败: $e，使用默认标记');
        // 降级方案：使用绿色默认标记
        try {
          final fallbackStartMarker = Marker(
            position: startPoint,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow.noText,
            onTap: (String markerId) {
              DebugUtil.info('点击了轨迹起点');
              _moveMapToLocation(startPoint);
            },
          );
          tempMarkers.add(fallbackStartMarker);
          DebugUtil.success(' 轨迹起点降级标记创建成功');
        } catch (fallbackError) {
          DebugUtil.error(' 起点降级标记也失败: $fallbackError');
        }
      }
      
      // 创建终点标记（只有当起点和终点不是同一个点时）
      if (trackPoints.length > 1) {
        final endPoint = trackPoints.last;
        final distance = _calculateDistance(startPoint, endPoint);
        
        // 只有当起点和终点距离超过50米时才显示终点标记
        if (distance > 50) {
          try {
            final endIcon = await BitmapDescriptor.fromAssetImage(
              const ImageConfiguration(size: Size(44, 46)),
              'assets/kissu_location_end.webp',
            );
            
            final endMarker = Marker(
              position: endPoint,
              icon: endIcon,
              anchor: const Offset(0.59, 0.83), // 设置锚点为图片的 (26, 38) 位置
              infoWindow: InfoWindow.noText,
              onTap: (String markerId) {
                DebugUtil.info('点击了轨迹终点');
                _moveMapToLocation(endPoint);
              },
            );
            
            tempMarkers.add(endMarker);
            DebugUtil.success(' 轨迹终点标记创建成功');
          } catch (e) {
            DebugUtil.error(' 创建终点标记失败: $e，使用默认标记');
            // 降级方案：使用红色默认标记
            try {
              final fallbackEndMarker = Marker(
                position: endPoint,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                infoWindow: InfoWindow.noText,
                onTap: (String markerId) {
                  DebugUtil.info('点击了轨迹终点');
                  _moveMapToLocation(endPoint);
                },
              );
              tempMarkers.add(fallbackEndMarker);
              DebugUtil.success(' 轨迹终点降级标记创建成功');
            } catch (fallbackError) {
              DebugUtil.error(' 终点降级标记也失败: $fallbackError');
            }
          }
        } else {
          DebugUtil.info('📍 起点和终点距离过近($distance米)，不显示终点标记');
        }
      }
      
      // 更新标记列表
      if (tempMarkers.isNotEmpty) {
        trackStartEndMarkers.addAll(tempMarkers);
        DebugUtil.success(' 轨迹起终点标记更新成功: ${trackStartEndMarkers.length}个');
        
        // 强制触发地图更新，确保标记显示同步
        _forceMapUpdate();
        
        // ✅ 在标记创建后立即关闭所有 InfoWindow，防止自动显示
        Future.delayed(const Duration(milliseconds: 50), () {
          _closeAllInfoWindows();
          DebugUtil.info('🔒 起终点标记创建后关闭所有 InfoWindow');
        });
      } else {
        DebugUtil.error(' 没有成功创建任何轨迹起终点标记');
      }
    } catch (e) {
      DebugUtil.error(' 轨迹起终点标记更新过程失败: $e');
    }
  }
  
  /// 创建简单的停留点标记（用于快速显示）
  Future<void> _createSimpleStayMarkers() async {
    stayMarkers.clear();
    
    if (stopPoints.isEmpty) {
      return;
    }
    
    DebugUtil.info('🚀 创建简单停留点标记: ${stopPoints.length}个');
    
    // 使用停留点的实际serialNumber，不再使用倒序编号
    
    for (int i = 0; i < stopPoints.length; i++) {
      final stop = stopPoints[i];
      
      if (stop.lat == 0.0 || stop.lng == 0.0) continue;
      
      // 根据 pointType 和 serialNumber 判断点的类型
      bool isEndPoint = stop.pointType == 'end' || stop.serialNumber == '终';
      bool isStartPoint = stop.pointType == 'start' || stop.serialNumber == '起';
      
      // 跳过终点和起点，只显示中间停留点
      if (isEndPoint || isStartPoint) {
        continue;
      }
      
      // 使用停留点的实际serialNumber作为显示编号
      String displayNumber = stop.serialNumber ?? (i + 1).toString();
      String title = '停留点 ${displayNumber}';
      
      // 使用最简单的默认标记
      final stopInfo = _parseStopInfo(stop);
      final String simpleMarkerTitle = stopInfo['locationName']!;
      final String simpleMarkerSnippet = '${stop.startTime ?? ''} ${stop.duration?.isNotEmpty == true ? '停留${stop.duration}' : ''}';
      
      final marker = Marker(
        position: LatLng(stop.lat, stop.lng),
         alpha: 0.0, // 🎯 完全透明，不显示系统marker
         anchor: const Offset(0.5, 0.5), // 🎯 设置锚点为中心，使InfoWindow相对坐标点居中
         infoWindowEnable: true, // 允许点击时显示 InfoWindow
         draggable: true, // 🎯 启用拖拽功能
         isTrackStyle: true, // 🎯 使用轨迹样式 InfoWindow
         stayDuration: stopInfo['stayDuration'], // 🎯 停留时长
         stayTime: stopInfo['stayTime'], // 🎯 停留时间
        infoWindow: InfoWindow(
          title: simpleMarkerTitle,
          snippet: simpleMarkerSnippet,
        ),
        customInfoWindowBuilder: (context) => _buildTrackInfoWindow(
          stopInfo['locationName']!,
          stopInfo['stayDuration']!,
          stopInfo['stayTime']!,
        ),
        onDragEnd: (String markerId, LatLng newPosition) {
          // 🎯 拖拽结束时清除现有圆圈并重新创建
          DebugUtil.info('🎯 简单停留点 Marker 拖拽结束，新位置: ${newPosition.latitude}, ${newPosition.longitude}');
          drawHighlightCircle(newPosition); // 这个方法会先清除现有圆圈再创建新的
        },
        onTap: (String markerId) {
          DebugUtil.info('🎯 点击地图上的简单停留点标记: $title - ${stop.locationName}');
          // InfoWindow 会自动显示（因为 infoWindowEnable 为 true）
          // 移动地图、绘制高亮圆圈
          _moveToStopPointWithHighlightInternal(
            stop.lat, 
            stop.lng, 
            stopPoint: stop,
          );
        },
      );
      
      stayMarkers.add(marker);
    }
    
    DebugUtil.success(' 简单停留点标记创建完成: ${stayMarkers.length}个');
  }

  /// 获取当前所有 markers
  Future<List<Marker>> get allMarkers async {
    final markers = <Marker>[];
    
    // 安全地添加停留点标记
    try {
      markers.addAll(stayMarkers);
    } catch (e) {
      DebugUtil.error(' 获取停留点标记失败: $e');
    }
    
    // 添加临时 InfoWindow 标记（如果存在）
    if (_tempInfoWindowMarker != null) {
      try {
        markers.add(_tempInfoWindowMarker!);
        DebugUtil.info('✅ 已添加临时 InfoWindow 标记到地图');
      } catch (e) {
        DebugUtil.error(' 添加临时 InfoWindow 标记失败: $e');
      }
    }
    
    // 添加播放头像标记（如果存在且正在播放或暂停）
    // 当播放头像存在时，不显示旧的当前位置标记
    if (replayAvatarMarker.value != null) {
      try {
        markers.add(replayAvatarMarker.value!);
        DebugUtil.info('✅ 已添加播放头像标记到地图');
      } catch (e) {
        DebugUtil.error(' 添加播放头像标记失败: $e');
      }
      // 如果有播放头像标记，就不添加普通的当前位置标记，直接返回
      return markers;
    }
    
    // 只有在没有播放头像标记时才显示普通的当前位置标记
    if (currentPosition.value != null) {
      try {
        // 安全创建当前位置标记
        BitmapDescriptor? icon;
        try {
          // 尝试创建彩色标记
          icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
        } catch (iconError) {
          DebugUtil.warning(' 当前位置标记图标创建失败，使用默认标记: $iconError');
          icon = null; // 使用系统默认标记
        }
        
        // 根据icon是否可用决定如何创建标记
        final String currentTitle = '当前位置';
        final String currentSnippet = '轨迹回放当前位置';
        
        final currentMarker = icon != null
          ? Marker(
              position: currentPosition.value!,
              icon: icon,
              anchor: const Offset(0.5, 0.5), // 设置锚点为图片中心
              infoWindowEnable: true, // 允许点击时显示 InfoWindow
              infoWindow: InfoWindow(
                title: currentTitle,
                snippet: currentSnippet,
              ),
              customInfoWindowBuilder: (context) => _buildTrackInfoWindow(
                currentTitle, 
                currentSnippet.isNotEmpty ? currentSnippet : "当前位置", 
                ""
              ),
              onTap: (String markerId) {
                DebugUtil.info('🎯 点击当前位置标记');
                // InfoWindow 会自动显示（因为 infoWindowEnable 为 true）
              },
            )
          : Marker(
              position: currentPosition.value!,
               alpha: 0.0, // 🎯 完全透明，不显示系统marker
              anchor: const Offset(0.5, 0.5), // 设置锚点为图片中心
               infoWindowEnable: true, // 允许点击时显示 InfoWindow
              infoWindow: InfoWindow(
                title: currentTitle,
                snippet: currentSnippet,
              ),
              customInfoWindowBuilder: (context) => _buildTrackInfoWindow(
                currentTitle, 
                currentSnippet.isNotEmpty ? currentSnippet : "当前位置", 
                ""
              ),
              onTap: (String markerId) {
                DebugUtil.info('🎯 点击当前位置标记');
                // InfoWindow 会自动显示（因为 infoWindowEnable 为 true）
              },
            );
        
        markers.add(currentMarker);
      } catch (e) {
        DebugUtil.error(' 创建当前位置标记失败: $e');
        // 降级：使用无图标的简单标记
        try {
          final String fallbackTitle = '当前位置';
          final String fallbackSnippet = '轨迹回放当前位置';
          
          markers.add(
            Marker(
              position: currentPosition.value!,
               alpha: 0.0, // 🎯 完全透明，不显示系统marker
              anchor: const Offset(0.5, 0.5), // 设置锚点为图片中心
               infoWindowEnable: true, // 允许点击时显示 InfoWindow
              infoWindow: InfoWindow(
                title: fallbackTitle,
                snippet: fallbackSnippet,
              ),
              customInfoWindowBuilder: (context) => _buildTrackInfoWindow(
                fallbackTitle, 
                fallbackSnippet.isNotEmpty ? fallbackSnippet : "当前位置", 
                ""
              ),
              onTap: (String markerId) {
                DebugUtil.info('点击了当前位置: $markerId');
              },
            ),
          );
        } catch (fallbackError) {
          DebugUtil.error(' 简单当前位置标记也失败: $fallbackError');
        }
      }
    }
    return markers;
  }


  /// 创建播放头像标记
  /// [position] 标记位置
  Future<void> _createReplayAvatarMarker(LatLng position) async {
    try {
      // 获取当前查看的用户头像
      final avatarUrl = isOneself.value == 1 ? myAvatar.value : partnerAvatar.value;
      
      DebugUtil.info('🎭 创建播放头像标记，头像URL: $avatarUrl');
      
      // 使用 MapMarkerUtil 创建圆形头像标记
      final icon = await MapMarkerUtil.createCircleAvatarMarker(
        avatarUrl.isNotEmpty ? avatarUrl : null,
        size: 180.0,  // 标记大小
        borderWidth: 3.0,  // 边框宽度
      );
      
      // 创建标记
      replayAvatarMarker.value = Marker(
        position: position,
        icon: icon,
        anchor: const Offset(0.5, 0.5), // 设置锚点为图片中心
      );
      
      DebugUtil.success('✅ 播放头像标记创建成功');
    } catch (e) {
      DebugUtil.error('❌ 创建播放头像标记失败: $e');
      replayAvatarMarker.value = null;
    }
  }

  /// 更新播放头像标记位置 - 异步版本（兼容性保留）
  /// [position] 新位置
  Future<void> _updateReplayAvatarMarkerPosition(LatLng position) async {
    _updateReplayAvatarMarkerSync(position);
  }

  /// 更新播放头像标记位置 - 同步版本（性能优化）
  /// [position] 新位置
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
          anchor: currentMarker.anchor,
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

  /// 优化的标记更新方法 - 减少重建频率
  /// [position] 新位置
  void _updateReplayAvatarMarkerOptimized(LatLng position) {
    if (replayAvatarMarker.value == null) {
      // 如果标记不存在，创建新标记
      _createReplayAvatarMarker(position);
      return;
    }

    try {
      final currentMarker = replayAvatarMarker.value!;
      
      // 计算旋转角度（如果需要方向指示）
      final rotation = _getRotationAngle();
      
      // 只有在位置或角度变化显著时才重建标记
      final oldPosition = currentMarker.position;
      final positionChanged = _calculateDistance(oldPosition, position) > 0.1; // 0.1米阈值
      final rotationChanged = (currentMarker.rotation - rotation).abs() > 0.1; // 0.1弧度阈值
      
      if (positionChanged || rotationChanged) {
        replayAvatarMarker.value = Marker(
          position: position,
          icon: currentMarker.icon,
          anchor: currentMarker.anchor,
          rotation: rotation,
          alpha: 1.0, // 确保完全不透明
          zIndex: 999, // 确保在最上层
        );
        
        // 降低日志频率
        if ((currentReplayIndex.value % 50) == 0) {
          DebugUtil.info('🎯 优化更新头像: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}, 角度: ${(rotation * 180 / pi).toStringAsFixed(1)}°');
        }
      }
    } catch (e) {
      DebugUtil.error('❌ 优化标记更新失败: $e');
      // 降级到基础更新方法
      _updateReplayAvatarMarkerSync(position);
    }
  }

  /// 平滑移动地图视角
  /// [position] 目标位置
  void _moveMapToLocationSmooth(LatLng position) {
    try {
      // 使用更平滑的地图移动
      _moveMapToLocation(position);
    } catch (e) {
      DebugUtil.warning('平滑地图移动失败: $e');
    }
  }

  /// 计算小人的朝向角度
  double _getRotationAngle() {
    if (trackPoints.length < 2 || currentReplayIndex.value >= trackPoints.length - 1) return 0;

    // 确保索引在有效范围内
    final currentIndex = currentReplayIndex.value.clamp(0, trackPoints.length - 2);
    final current = trackPoints[currentIndex];
    final next = trackPoints[currentIndex + 1];

    final dx = next.longitude - current.longitude;
    final dy = next.latitude - current.latitude;

    // 计算角度，并调整基准方向
    // 由于箭头图片指向正左方，需要加上π/2使其指向正确方向
    final angle = atan2(dx, dy);
    return angle + pi / 2; // 调整90度，因为箭头原本指向左方
  }

  /// 公开的获取旋转角度方法
  double getRotationAngle() {
    return _getRotationAngle();
  }

  /// 在两点之间进行插值
  LatLng _interpolatePosition(LatLng start, LatLng end, double t) {
    // 确保插值参数在0-1之间，避免异常值
    final clampedT = t.clamp(0.0, 1.0);
    final lat = start.latitude + (end.latitude - start.latitude) * clampedT;
    final lng = start.longitude + (end.longitude - start.longitude) * clampedT;
    return LatLng(lat, lng);
  }

  
  
  /// 计算两点间距离（米）
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // 地球半径（米）
    final double lat1Rad = point1.latitude * pi / 180;
    final double lat2Rad = point2.latitude * pi / 180;
    final double deltaLatRad = (point2.latitude - point1.latitude) * pi / 180;
    final double deltaLngRad = (point2.longitude - point1.longitude) * pi / 180;
    
    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// 计算累计距离（从startIndex到endIndex）
  double _calculateCumulativeDistance(int startIndex, int endIndex) {
    if (trackPoints.isEmpty || startIndex >= endIndex) return 0.0;
    
    double totalDistance = 0.0;
    for (int i = startIndex; i < endIndex && i < trackPoints.length - 1; i++) {
      totalDistance += _calculateDistance(trackPoints[i], trackPoints[i + 1]);
    }
    return totalDistance;
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
    
    // 根据基础速度计算播放时间（秒）
    // 播放时间 = 距离 / 速度 * 3600（转换为秒）
    final calculatedSeconds = (totalDistanceKm / _baseSpeedKmh * 3600).round();
    
    // 应用限制：最短3秒，最长15秒
    final clampedSeconds = calculatedSeconds.clamp(
      _minReplayDuration.inSeconds, 
      _maxReplayDuration.inSeconds
    );
    
    // 对于很短的轨迹（小于100米），使用最短时间
    if (totalDistanceKm < 0.1) {
      return _minReplayDuration;
    }
    
    // 对于中等长度轨迹，使用计算出的时间
    if (totalDistanceKm <= 2.0) {
      return Duration(seconds: clampedSeconds);
    }
    
    // 对于长轨迹，使用最长时间
    return _maxReplayDuration;
  }
  
  /// 更新播放状态（距离、时间、速度，但不更新进度因为已实时更新）
  void _updateReplayStatus() {
    // 更新距离显示
    final distanceKm = _cumulativeDistance / 1000;
    replayDistance.value = "${distanceKm.toStringAsFixed(2)}km";
    
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
      final speed = distance; // 米/秒
      currentSpeed.value = "${speed.toStringAsFixed(0)}m/s";
    }
  }
  
  /// 跳转到指定索引（用于进度条拖动）
  void seekToIndex(int newIndex) {
    if (trackPoints.isEmpty) return;
    
    final safeIndex = newIndex.clamp(0, trackPoints.length - 1);
    currentReplayIndex.value = safeIndex;
    
    // 更新当前位置
    currentPosition.value = trackPoints[safeIndex];
    _moveMapToLocation(trackPoints[safeIndex]);
    
    // 如果存在播放头像标记，更新其位置
    if (replayAvatarMarker.value != null) {
      _updateReplayAvatarMarkerPosition(trackPoints[safeIndex]);
    }
    
    // 更新累计距离
    _cumulativeDistance = _calculateCumulativeDistance(0, safeIndex);
    
    // 🎯 手动更新进度（因为这是用户拖动）
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

  /// 开始回放 - 使用AnimationController替代Timer
  void startReplay() {
    if (trackPoints.isEmpty) {
      CustomToast.show(Get.context!, '暂无轨迹数据可回放');
      return;
    }
    
    // 检查地图是否就绪
    if (!isMapReady.value) {
      CustomToast.show(Get.context!, '地图正在加载中，请稍后再试');
      DebugUtil.warning('地图未就绪，无法开始回放');
      return;
    }
    
    print('🎬 开始播放回放...');
    
    // 停止之前的动画
    _replayAnimationController?.dispose();
    
    isReplaying.value = true;
    showFullPlayer.value = true; // 显示完整播放器
    print('🎬 showFullPlayer = ${showFullPlayer.value}');

    // 确保currentReplayIndex在有效范围内
    currentReplayIndex.value = currentReplayIndex.value.clamp(0, trackPoints.length - 1);

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

    // 设置动画监听器的更新频率（60fps）
    _replayAnimationController!.addListener(() {
      // 确保动画以60fps的频率更新
    });

    // 监听动画值变化
    _replayAnimation!.addListener(_onReplayAnimationUpdate);
    
    // 监听动画完成
    _replayAnimationController!.addStatusListener(_onReplayAnimationStatus);

    final totalDistance = _calculateTotalTrackDistance();
    print('🎬 开始播放: 轨迹点=${trackPoints.length}, 总距离=${(totalDistance/1000).toStringAsFixed(2)}km, 起始进度=${startProgress.toStringAsFixed(3)}, 播放时长=${optimalDuration.inSeconds}秒');
    
    // 开始动画
    _replayAnimationController!.forward();
  }
  
  /// 动画更新回调
  void _onReplayAnimationUpdate() {
    if (_replayAnimation == null || trackPoints.isEmpty) return;
    
    final progress = _replayAnimation!.value;
    final totalPoints = trackPoints.length;
    
    // 计算当前应该在哪个轨迹点，使用更高精度
    final exactIndex = progress * (totalPoints - 1);
    final currentIndex = exactIndex.floor().clamp(0, totalPoints - 2);
    final nextIndex = (currentIndex + 1).clamp(0, totalPoints - 1);
    final interpolationProgress = exactIndex - currentIndex;
    
    // 更新当前索引（用于UI显示）
    if (currentReplayIndex.value != currentIndex) {
      currentReplayIndex.value = currentIndex;
      _cumulativeDistance = _calculateCumulativeDistance(0, currentIndex);
      _updateReplayStatus();
      _checkPassingStopPoint(currentIndex);
    }
    
    // 使用更平滑的插值计算当前位置
    final startPoint = trackPoints[currentIndex];
    final endPoint = trackPoints[nextIndex];
    
    // 应用多级平滑处理 - 使用新的超平滑算法
    final smoothProgress = _applyMultiLevelSmoothing(interpolationProgress.clamp(0.0, 1.0));
    
    // 计算平滑插值位置
    final newPosition = _interpolatePosition(startPoint, endPoint, smoothProgress);
    
    // 只有当位置变化足够大时才更新，减少不必要的重建
    if (currentPosition.value == null || 
        _calculateDistance(currentPosition.value!, newPosition) > 0.5) { // 0.5米阈值
      currentPosition.value = newPosition;
      
      // 使用优化的标记更新方法
      _updateReplayAvatarMarkerOptimized(newPosition);
    }
    
    // 更新播放进度
    replayProgress.value = progress.clamp(0.0, 1.0);
    
    // 平滑移动地图视角（降低频率）
    if ((progress * 1000).round() % 100 == 0) { // 每100毫秒更新一次地图位置，减少频率
      _moveMapToLocationSmooth(newPosition);
    }
  }

  /// 动画状态监听
  void _onReplayAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // 播放完成
      currentReplayIndex.value = trackPoints.length - 1;
      _showReplayCompleteMessage();
      
      // 播放完成后停止并隐藏头像
      isReplaying.value = false;
      _replayAnimationController?.stop();
      _replayAnimationController?.reset();
      replaySpeed.value = 1.0;
      _replayStartTime = null;
      _cumulativeDistance = _calculateCumulativeDistance(0, trackPoints.length - 1);
      replayDistance.value = "";
      replayTime.value = "00:00:00";
      replayProgress.value = 1.0; // 设置为完成状态
      currentSpeed.value = "";
      
      // 🎯 播放完成后隐藏头像标记
      replayAvatarMarker.value = null;
      currentPosition.value = null; // 清除当前位置，避免显示其他标记
      
      DebugUtil.info('🏁 轨迹播放完成，头像已隐藏');
    }
  }

  /// 应用高级平滑处理，减少闪现效果
  double _applyAdvancedSmoothing(double t) {
    // 使用五次Hermite插值，提供更平滑的过渡
    // 这个函数在0和1处的一阶和二阶导数都为0，提供超平滑的过渡
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
  }
  
  /// 应用贝塞尔曲线平滑处理
  double _applyCubicBezierSmoothing(double t) {
    // 使用三次贝塞尔曲线 (0.25, 0.1, 0.25, 1.0) 提供自然的缓动效果
    const double c2 = 0.1;
    const double c3 = 0.25;
    
    if (t <= 0.0) return 0.0;
    if (t >= 1.0) return 1.0;
    
    // 简化的三次贝塞尔曲线计算
    final double t2 = t * t;
    final double t3 = t2 * t;
    final double mt = 1.0 - t;
    final double mt2 = mt * mt;
    
    return 3.0 * mt2 * t * c2 + 3.0 * mt * t2 * c3 + t3;
  }
  
  /// 多级平滑处理 - 结合多种算法
  double _applyMultiLevelSmoothing(double t) {
    // 第一级：五次Hermite插值
    double smoothed = _applyAdvancedSmoothing(t);
    
    // 第二级：轻微的贝塞尔曲线调整
    smoothed = smoothed * 0.8 + _applyCubicBezierSmoothing(t) * 0.2;
    
    return smoothed.clamp(0.0, 1.0);
  }
  
  /// 检查是否经过停留点
  void _checkPassingStopPoint(int currentIndex) {
    if (currentIndex >= trackPoints.length || stopPoints.isEmpty) return;
    
    final currentPos = trackPoints[currentIndex];
    
    // 检查当前位置是否靠近任何停留点
    for (final stop in stopPoints) {
      final distance = _calculateDistance(
        currentPos, 
        LatLng(stop.lat, stop.lng)
      );
      
      // 如果距离小于50米，认为经过了停留点
      if (distance < 50) {
        DebugUtil.info('🚩 经过停留点: ${stop.locationName}');
        // 可以在这里添加UI提示，比如闪烁标记点或显示toast
        break;
      }
    }
  }
  
  /// 显示回放完成消息
  void _showReplayCompleteMessage() {
    // CustomToast.show(
    //   Get.context!, 
    //   '轨迹回放完成！总距离：${moveDistance.value}，总停留：${stayDuration.value}'
    // );
  }

  /// 暂停
  void pauseReplay() {
    isReplaying.value = false;
    _replayAnimationController?.stop();
    // 暂停时保留头像标记，不清除
  }

  /// 停止并重置
  void stopReplay() {
    isReplaying.value = false;
    _replayAnimationController?.stop();
    _replayAnimationController?.reset();
    currentReplayIndex.value = 0;
    replaySpeed.value = 1.0; // 重置播放速度
    // 重置播放状态
    _replayStartTime = null;
    _cumulativeDistance = 0.0;
    replayDistance.value = "";
    replayTime.value = "00:00:00";
    
    // 🎭 清除播放头像标记
    if (replayAvatarMarker.value != null) {
      DebugUtil.info('🧹 停止播放时清除播放头像标记');
      replayAvatarMarker.value = null;
    }
    replayProgress.value = 0.0; // 重置进度
    currentSpeed.value = ""; // 重置速度
    // 清除当前位置，避免显示橙色标记
    currentPosition.value = null;
    
    // 重置地图位置到起点，但不设置currentPosition
    if (trackPoints.isNotEmpty) {
      _moveMapToLocation(trackPoints.first);
    }
    
    DebugUtil.info('⏹️ 轨迹播放已停止，头像已隐藏');
  }
  
  /// 关闭播放器并重置动画
  void closePlayer() {
    stopReplay(); // 停止当前播放
    showFullPlayer.value = false; // 隐藏完整播放器
    
    // 🎯 确保头像标记被清除
    replayAvatarMarker.value = null;
    currentPosition.value = null; // 清除当前位置标记
    
    // 重置地图视图到初始状态
    if (trackPoints.isNotEmpty) {
      _moveMapToLocation(trackPoints.first);
    }
    
    DebugUtil.info('❌ 播放器已关闭，所有标记已清除');
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
    
    // 如果正在播放，重新启动以应用新速度
    if (isReplaying.value) {
      final wasReplaying = isReplaying.value;
      pauseReplay();
      if (wasReplaying) {
        startReplay();
      }
    }
  }
  
  /// 根据进度跳转（用于进度条拖动）
  void seekReplay(double progress) {
    if (trackPoints.isEmpty) return;
    final targetIndex = (progress * (trackPoints.length - 1)).round();
    seekToIndex(targetIndex);
  }

  /// 已移除虚拟数据加载方法，改为统一使用真实API数据
  
  /// 已移除虚拟数据生成方法，改为统一使用真实API数据

  @override
  void onClose() {
    DebugUtil.info('🧹 开始清理轨迹页面资源和缓存...');
    
    // ✅ 关闭所有 InfoWindow
    _closeAllInfoWindows();
    
    // 重置地图就绪状态
    isMapReady.value = false;
    
    // 安全地清理所有定时器和动画资源
    try {
      _replayAnimationController?.dispose();
      _replayAnimationController = null;
    } catch (e) {
      debugPrint('清理replayAnimationController时出错: $e');
    }
    
    try {
      _debounceTimer?.cancel();
      _debounceTimer = null;
    } catch (e) {
      debugPrint('清理debounceTimer时出错: $e');
    }
    
    // 清理地图控制器
    // AMapController 无需手动dispose
    
    // 清空大型数据结构
    trackPoints.clear();
    stopPoints.clear();
    stayMarkers.clear();
    trackStartEndMarkers.clear();
    stopRecords.clear();
    
    // 不使用缓存，无需处理缓存清理
    
    // 重置所有状态
    isLoading.value = false;
    isReplaying.value = false;
    showFullPlayer.value = false;
    currentReplayIndex.value = 0;
    replaySpeed.value = 1.0;
    animationProgress.value = 0.0;
    currentPosition.value = null;
    
    // 重置统计数据
    stayCount.value = 0;
    stayDuration.value = "";
    moveDistance.value = "";
    replayDistance.value = "";
    replayTime.value = "00:00:00";
    
    DebugUtil.success(' 轨迹页面资源清理完成');
    super.onClose();
  }
  
}
