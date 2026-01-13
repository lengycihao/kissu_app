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
import 'package:kissu_app/utils/source_page_utils.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:intl/intl.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';
import 'package:kissu_app/utils/debug_util.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog.dart';
import 'package:kissu_app/pages/usage_report/widgets/map_marker_util.dart';
import 'package:kissu_app/services/location_permission_manager.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog_controller.dart';

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
  
  /// 轨迹点缓存池 - 用于避免重复计算
  final Map<String, List<LatLng>> _trackPointsCache = {};
  
  /// 地图就绪状态
  final isMapReady = false.obs;
  
  /// 轨迹线状态管理 - 用于解决高德地图轨迹线更新问题
  final RxBool hasValidTrackData = false.obs;

  /// 🔒 动画锁机制，防止地图变化时的滑动冲突
  bool _isAnimating = false;

  /// 返回按钮旋转状态
  final isBackButtonRotated = false.obs;
  
  /// 返回按钮动画控制器
  late AnimationController backButtonAnimationController;
  late Animation<double> backButtonRotationAnimation;
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
    
    // 初始化返回按钮动画控制器
    _initBackButtonAnimation();
    
    // 监听下半屏滑动位置变化
    _listenToSheetChanges();
    
    // 加载用户信息
    _loadUserInfo();
    // 请求定位权限并加载初始数据
    _requestLocationPermissionAndLoadData();
    
  }

  
  /// 初始化返回按钮动画控制器
  void _initBackButtonAnimation() {
    backButtonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    backButtonRotationAnimation = Tween<double>(
      begin: 0.0,
      end: -0.25, // -90度 (逆时针旋转90度)
    ).animate(CurvedAnimation(
      parent: backButtonAnimationController,
      curve: Curves.easeInOut,
    ));
  }
  
  /// 监听下半屏滑动位置变化
  void _listenToSheetChanges() {
    sheetPercent.listen((percent) {
      // 当滑动到顶部吸顶位置时（约0.85以上），触发按钮旋转
      final topThreshold = 0.85;
      
      if (percent >= topThreshold && !isBackButtonRotated.value) {
        // 滑动到顶部，按钮逆时针旋转90度
        isBackButtonRotated.value = true;
        backButtonAnimationController.forward();
      } else if (percent < topThreshold && isBackButtonRotated.value) {
        // 滑动离开顶部，按钮顺时针旋转回原位
        isBackButtonRotated.value = false;
        backButtonAnimationController.reverse();
      }
    });
  }
  
  /// 处理旋转状态下的返回按钮点击
  void handleBackButtonTap([ScrollController? scrollController]) {
    if (isBackButtonRotated.value) {
      // 如果按钮已旋转，将下半屏回滚到底部，并重置ScrollView
      _scrollToBottom(scrollController);
    } else {
      // 正常返回
      Get.back();
    }
  }
  
  /// 将下半屏滚动到底部
  void _scrollToBottom([ScrollController? scrollController]) {
    // 先将下半屏回滚到底部
    if (_draggableController != null) {
      _draggableController!.animateTo(
        0.3, // 回到初始位置
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ).then((_) {
        // 下半屏回滚完成后，再重置ScrollView到顶部
        if (scrollController != null && scrollController.hasClients) {
          scrollController.animateTo(
            0.0, // 滚动到顶部
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  /// 请求定位权限并加载数据（每次打开都检查）
  Future<void> _requestLocationPermissionAndLoadData() async {
    try {
      DebugUtil.check('轨迹页面检查权限状态...');
      
      // 使用统一的权限管理器
      final hasPermission = await LocationPermissionManager.instance.requestLocationPermission();
      
      if (hasPermission) {
        DebugUtil.success('轨迹页面权限已授予，加载数据');
        Future.microtask(() => _loadDataAsync());
      } else {
        DebugUtil.error('轨迹页面权限未授予');
        // 权限被拒绝的提示已经在权限管理器中处理
      }
    } catch (e) {
      DebugUtil.error('轨迹页面权限请求失败: $e');
      CustomToast.show(
        Get.context!,
        '定位权限请求失败',
      );
    }
  }

  // 🔧 已移除旧的_showLocationPermissionDialog方法
  // 现在统一使用LocationPermissionManager.instance.requestLocationPermission()

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

  /// 地图初始相机位置 - 使用统一的计算逻辑
  CameraPosition get initialCameraPosition {
    // 如果已有轨迹数据，使用计算的最佳位置
    if (trackPoints.isNotEmpty) {
      final optimalPosition = _calculateOptimalCameraPosition();
      if (optimalPosition != null) {
        return optimalPosition;
      }
    }
    
    // 如果有位置数据但没有轨迹点，尝试使用起点或终点
    if (locationData.value != null) {
      final data = locationData.value!;
      if (data.trace?.startPoint.lat != 0.0 && data.trace?.startPoint.lng != 0.0) {
        return CameraPosition(
          target: LatLng(data.trace!.startPoint.lat, data.trace!.startPoint.lng),
          zoom: 16.0,
        );
      }
      if (data.trace?.endPoint.lat != 0.0 && data.trace?.endPoint.lng != 0.0) {
        return CameraPosition(
          target: LatLng(data.trace!.endPoint.lat, data.trace!.endPoint.lng),
          zoom: 16.0,
        );
      }
    }
    
    // 默认杭州坐标
    return const CameraPosition(
      target: LatLng(30.2741, 120.2206),
      zoom: 16.0,
    );
  }

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

  /// 自动调整地图视图以显示所有轨迹点（统一的相机位置管理方法）
  Future<void> _fitMapToTrackPoints() async {
    if (!isMapReady.value || mapController == null) {
      DebugUtil.warning('地图未就绪或控制器为空，无法调整视图');
      return;
    }
    
    CameraPosition? targetPosition;
    
    // 检查是否有轨迹数据
    final hasTrackData = trackPoints.isNotEmpty || stopPoints.isNotEmpty;
    
    // 如果没有任何位置信息，显示全国地图视图
    if (!hasTrackData) {
      DebugUtil.info('🗺️ 无位置信息，显示全国地图视图');
      targetPosition = CameraPosition(
        target: LatLng(35.86166, 104.195397), // 中国地理中心
        zoom:3.0, // 可以看到全国的缩放级别 (越小范围越大)
      );
    }
    // 优先使用轨迹点计算最佳位置
    else if (trackPoints.isNotEmpty) {
      DebugUtil.info('开始自动调整地图视图，轨迹点数量: ${trackPoints.length}');
      targetPosition = _calculateOptimalCameraPosition();
    } 
    // 如果没有轨迹点，尝试使用位置数据的起点或终点
    else if (locationData.value != null) {
      final data = locationData.value!;
      if (data.trace?.startPoint.lat != 0.0 && data.trace?.startPoint.lng != 0.0) {
        targetPosition = CameraPosition(
          target: LatLng(data.trace!.startPoint.lat, data.trace!.startPoint.lng),
          zoom: 16.0,
        );
        DebugUtil.info('使用起点作为地图中心');
      } else if (data.trace?.endPoint.lat != 0.0 && data.trace?.endPoint.lng != 0.0) {
        targetPosition = CameraPosition(
          target: LatLng(data.trace!.endPoint.lat, data.trace!.endPoint.lng),
          zoom: 16.0,
        );
        DebugUtil.info('使用终点作为地图中心');
      }
    }
    
    // 如果没有任何有效位置，使用默认杭州坐标
    if (targetPosition == null) {
      DebugUtil.warning('没有有效位置数据，使用默认杭州坐标');
      targetPosition = const CameraPosition(
        target: LatLng(30.2741, 120.2206),
        zoom: 16.0,
      );
    }
    
    try {
      await mapController!.moveCamera(
        CameraUpdate.newCameraPosition(targetPosition),
      );
      DebugUtil.success('地图已自动调整到最佳视图 - 缩放级别: ${targetPosition.zoom}');
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
    
    // 🎯 立即隐藏 InfoWindow（第一次）
    _hideAllInfoWindows();
    
    // 🎯 延迟后再次隐藏（第二次），确保 Marker 创建后的 InfoWindow 也被隐藏
    Future.delayed(const Duration(milliseconds: 50), () {
      _hideAllInfoWindows();
      DebugUtil.info('🔒 地图初始化后关闭所有 InfoWindow (50ms)');
    });
    
    // 🎯 延迟后第三次隐藏，确保完全没有闪现
    Future.delayed(const Duration(milliseconds: 150), () {
      _hideAllInfoWindows();
      DebugUtil.info('🔒 地图初始化后关闭所有 InfoWindow (150ms)');
    });
    
    // 🎯 延迟后第四次隐藏，最后一次保险
    Future.delayed(const Duration(milliseconds: 300), () {
      _hideAllInfoWindows();
      DebugUtil.info('🔒 地图初始化后关闭所有 InfoWindow (300ms)');
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
  /// 注意：此方法只负责移动地图，不负责清理高亮状态
  void moveToStopPoint(double latitude, double longitude) {
    // 检查地图是否就绪
    if (!isMapReady.value || mapController == null) {
      DebugUtil.warning('地图未就绪或控制器为空，无法移动到停留点');
      return;
    }
    
    // 🎯 计算偏移后的目标位置，使目标点在屏幕上更靠上，避免被底部面板遮挡
    // 在 zoom 18.0 级别下，纬度偏移 0.001 约等于 110 米
    // 偏移 0.0008 约等于向南移动 88 米，使目标点在视觉上向上移动
    final adjustedLatitude = latitude - 0.0008;
    final targetLocation = LatLng(adjustedLatitude, longitude);
    
    try {
      // 移动地图并调整缩放级别以更好地显示该点
      mapController?.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: targetLocation,
            zoom: 18.0, // 使用较高的缩放级别以便更清楚地看到该位置
          ),
        ),
      );
      
      DebugUtil.info('地图移动到停留点: $latitude, $longitude（调整后相机中心: $adjustedLatitude, $longitude）');
    } catch (e) {
      DebugUtil.error('移动地图到停留点失败: $e');
    }
  }

  /// 清除所有高亮圆圈（使用原生地图API）
  void clearAllHighlightCircles() {
    DebugUtil.info('🧹 [HighlightCircles] 清除围栏圆圈');
    if (mapController != null) {
      mapController!.clearGeofenceCircle();
      DebugUtil.success('✅ [HighlightCircles] 围栏圆圈已清除');
    } else {
      DebugUtil.warning('⚠️ [HighlightCircles] MapController未初始化');
    }
  }

  /// 隐藏所有 InfoWindow
  void _hideAllInfoWindows() {
    if (mapController != null) {
      try {
        mapController!.hideAllInfoWindows();
        DebugUtil.info('🎯 已隐藏所有 InfoWindow');
      } catch (e) {
        DebugUtil.error('❌ 隐藏所有 InfoWindow 失败: $e');
      }
    }
  }

  /// 🎯 统一清除：同时隐藏 InfoWindow 和清除圆圈
  /// 确保 InfoWindow 和圆圈在相同时机出现和消失
  void clearMapHighlights() {
    DebugUtil.info('🧹 [MapHighlights] 清除所有地图高亮（InfoWindow + 围栏圆圈）');
    _hideAllInfoWindows();
    clearAllHighlightCircles();
  }

  /// 绘制高亮圆圈（使用原生地图API）
  /// 🎯 不会隐藏 InfoWindow，确保圆圈和 InfoWindow 同时显示
  void drawHighlightCircle(LatLng center) {
    DebugUtil.info('🎯 开始绘制高亮圆圈: ${center.latitude}, ${center.longitude}');
    
    if (mapController != null) {
      try {
        // 使用原生地图API绘制围栏圆圈（会自动清除之前的圆圈）
        mapController!.showGeofenceCircle(
          latitude: center.latitude,
          longitude: center.longitude,
          radius: 100.0, // 100米半径
          strokeColor: '#FFFFFF', // 白色边框
          fillColor: '#61FFE3EB', // #61 = 38% 不透明度，背景色 #FFE3EB
          strokeWidth: 3.0,
        );
        DebugUtil.success('✅ 高亮圆圈已绘制（使用原生API），InfoWindow保持显示');
      } catch (e) {
        DebugUtil.error('❌ 绘制高亮圆圈失败: $e');
      }
    } else {
      DebugUtil.warning('⚠️ MapController未初始化，无法绘制圆圈');
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
      
      // 🔧 修复：从定位页面跳转时，强制切换到"自己"的视角
      // 因为定位页面点击的是"我的"停留点，所以应该显示自己的轨迹
      if (isOneself.value != 1) {
        DebugUtil.info('🔄 检测到从定位页面跳转，强制切换到自己的视角');
        isOneself.value = 1;
        // 立即切换数据，确保后续处理使用正确的数据
        _switchToCurrentUserData();
      }
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
    
    // 🧹 首先清除之前的所有地图高亮（InfoWindow + 围栏圆圈）
    clearMapHighlights();
    
    // // 🔍 查找对应的Marker坐标
    // final matchingMarker = stayMarkers.firstWhereOrNull((marker) {
    //   final distance = _calculateDistanceBetweenPointsStatic(
    //     marker.position, 
    //     LatLng(stopPoint?.lat ?? latitude, stopPoint?.lng ?? longitude)
    //   );
    //   return distance < 10; // 10米范围内
    // });
    
    // if (matchingMarker != null) {
    //   DebugUtil.info('🎯 找到匹配的Marker坐标: (${matchingMarker.position.latitude}, ${matchingMarker.position.longitude})');
    //   DebugUtil.info('🎯 传入参数坐标: ($latitude, $longitude)');
      
    //   // 计算坐标差异
    //   final distance = _calculateDistanceBetweenPointsStatic(matchingMarker.position, targetLocation);
    //   DebugUtil.warning('⚠️ 坐标差异: ${distance.toStringAsFixed(2)}米');
      
    //   if (distance > 5) {
    //     DebugUtil.error('❌ 围栏圆圈将使用不同的坐标！Marker在(${matchingMarker.position.latitude}, ${matchingMarker.position.longitude})，围栏在($latitude, $longitude)');
    //   }
    // }
    
    DebugUtil.info('🎯 地图控制器状态: ${mapController != null ? "已就绪" : "未就绪"}');
    DebugUtil.info('🎯 地图就绪状态: ${isMapReady.value}');
    
    // 移动地图到停留点
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
      
      // 🎯 等待清除操作完成，确保地图更新生效
      await Future.delayed(const Duration(milliseconds: 50));
      
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
      
      // 🎯 触发地图更新以显示临时标记（不重新加载数据）
      _forceMapUpdate();
      
      DebugUtil.success('✅ 临时 InfoWindow 已创建并触发地图更新');
      
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

  /// 🎯 已移除旧的高亮圆圈实现，现在使用原生地图API
  /// 参见: drawHighlightCircle() 和 clearAllHighlightCircles()

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
  static const Duration _minReplayDuration = Duration(seconds: 3); // 最短播放时长（保留用于向后兼容）
  
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
    // 🎯 加载状态已在 selectDate 中设置，这里直接加载数据
    DebugUtil.info('📍 开始加载数据，当前 isLoading = ${isLoading.value}');
    _resetReplayState();
    
    // 增加数据版本号，确保数据一致性
    final currentVersion = ++_dataVersion;
    
    // 立即清空旧数据，给用户即时反馈
    _clearDataInstantly();
    
    final dateString = DateFormat('yyyy-MM-dd').format(selectedDate.value);
    
    // 记录加载开始时间，确保动画至少显示 500ms
    final loadStartTime = DateTime.now();
    
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
      // 确保加载动画至少显示 500ms，让用户能看到
      final loadDuration = DateTime.now().difference(loadStartTime);
      final minDisplayDuration = const Duration(milliseconds: 500);
      
      if (loadDuration < minDisplayDuration) {
        final remainingTime = minDisplayDuration - loadDuration;
        DebugUtil.info('⏱️ 加载用时 ${loadDuration.inMilliseconds}ms，延迟 ${remainingTime.inMilliseconds}ms 以显示动画');
        await Future.delayed(remainingTime);
      }
      
      DebugUtil.info('✅ 数据加载完成，设置 isLoading = false');
      isLoading.value = false;
    }
  }

  /// 实际执行数据加载 - 支持缓存的智能加载（带防抖）
  /// 并发请求两个用户的数据，避免切换时重新请求
  Future<void> _performLoadLocationData() async {
    // 🎯 切换日期时始终显示加载动画（已在 selectDate 中设置）
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
      // 无数据时显示全国地图 - 延迟确保清空操作完成
      Future.microtask(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        await _fitMapToTrackPoints();
        DebugUtil.success('🗺️ 已切换到全国地图视图（无数据）');
      });
      return;
    }
    
    // 更新当前显示的数据
    locationData.value = currentData;
    
    // 从API数据中更新头像信息
    _updateAvatarsFromApiData(currentData);
    
    DebugUtil.success('✅ 切换到 ${isOneself.value == 1 ? "自己" : "另一半"} 的数据');
    
    // 立即更新统计数据（同步）
    _updateStatistics();
    
    // 异步更新其他数据
    Future.microtask(() async {
      try {
        // 使用优化的批量渲染轨迹数据
        await _batchRenderTrackPoints();
        
        // ⚠️ 必须先更新停留点数据，stopRecords依赖stopPoints
        await _batchRenderStopPoints();
        
        // 更新停留记录（这会更新列表数据）
        await _updateStopRecords();
        
        DebugUtil.success('✅ 所有数据更新完成！');
      } catch (e) {
        DebugUtil.error('❌ 数据更新失败: $e');
        // 即使出错也尝试更新统计数据
        _updateStatistics();
      }
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
    
    // 🎯 注意：围栏圆圈现在由原生地图API管理，不需要在这里保存和恢复
    
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
    
    // 异步触发地图更新，避免阻塞UI
    Future.microtask(() => _forceMapUpdate());
    
    DebugUtil.success('✅ [ClearInstantly] 数据已清空，显示加载状态');
  }
  
  /// 智能清空数据 - 头像切换专用，提供更好的用户反馈
  void _clearDataForAvatarSwitch() {
    DebugUtil.info('🧹 [ClearAvatar] 开始清空数据（头像切换）...');
    
    // 🎯 注意：围栏圆圈现在由原生地图API管理，已在 onAvatarTapped() 中清除
    
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
    
    DebugUtil.info('🔄 [ForceMapUpdate] 开始强制更新地图');
    
    // 强制刷新所有响应式变量，让UI重新构建
    trackPoints.refresh();
    stopPoints.refresh();
    stayMarkers.refresh();
    trackStartEndMarkers.refresh();
    
    // 🎯 触发地图页面的缓存更新（通过更新任意响应式变量）
    // 这会让地图页面重新计算版本并更新缓存
    update();
    
    DebugUtil.info('✅ [ForceMapUpdate] 地图强制更新完成');
  }
  
  /// 设置地图就绪状态
  void setMapReady(bool ready) {
    isMapReady.value = ready;
    DebugUtil.info('地图就绪状态更新: $ready');
    
    // 如果地图刚就绪，恢复所有地图元素并调整视图
    if (ready) {
      // 延迟一帧确保地图完全就绪
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 如果有数据，恢复地图元素
        if (trackPoints.isNotEmpty || stopPoints.isNotEmpty || 
            stayMarkers.isNotEmpty || trackStartEndMarkers.isNotEmpty) {
          DebugUtil.info('地图就绪，恢复所有轨迹数据到地图');
          _forceMapUpdate();
        }
        
        // ✅ 无论是否有数据，都调整地图视图（有数据显示轨迹，无数据显示全国地图）
        _fitMapToTrackPoints();
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
    
    // 🎯 注意：围栏圆圈现在由原生地图API管理，不需要在这里清除
    
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
      
      // 直接使用原始停留点，不进行任何位置调整
      stopPoints.value = rawStopPoints;
      DebugUtil.success('✅ [StopPoints] 使用原始停留点，数量: ${stopPoints.length}');
      
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
    
    // 使用原始的 stopPoints 坐标
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
    } catch (e) {
      DebugUtil.error('❌ [StopRecords] 处理停留记录失败: $e');
      stopRecords.clear();
    }
  }
  
  /// 在后台线程处理停留记录数据
  static List<StopRecord> _processStopRecords(List<TrackStopPoint> stopPoints) {
    return stopPoints.map((stop) {
      return StopRecord(
        latitude: stop.lat,   // 使用原始坐标
        longitude: stop.lng,  // 使用原始坐标
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

  /// 切换查看用户（自己/另一半）
  void switchUser() {
    isOneself.value = isOneself.value == 1 ? 0 : 1;
    
    // 🎯 切换用户时清除所有地图高亮（InfoWindow + 围栏圆圈）
    clearMapHighlights();
    
    // 切换用户时，立即清空数据并异步加载，避免卡顿
    _clearDataForAvatarSwitch();
    Future.microtask(() => _loadDataAsync());
  }
  
  /// 立即清理地图上的所有内容，避免切换头像时卡顿
  void _clearMapImmediately() {
    DebugUtil.info('🧹 立即清理地图内容...');
    
    // 1. 清除所有地图高亮（InfoWindow + 围栏圆圈）
    clearMapHighlights();
    
    // 2. 立即清空轨迹数据，让地图变空
    trackPoints.clear();
    stopPoints.clear();
    stayMarkers.clear();
    
    // 3. 清空停留记录
    stopRecords.clear();
    
    // 4. 重置统计数据（这些是局部变量，不是响应式变量）
    // totalDistance 和 totalDuration 会在 _updateStatistics() 中重新计算
    
    DebugUtil.success('✅ 地图内容已立即清理完成');
  }
  
  /// 带分批渲染的用户数据切换（已废弃，保留用于兼容性）
  // ignore: unused_element
  void _switchToCurrentUserDataWithBatchRendering() {
    final currentData = isOneself.value == 1 ? mySelfData.value : partnerData.value;
    
    if (currentData == null) {
      DebugUtil.warning('⚠️ 当前用户数据为空');
      _clearData();
      // 无数据时显示全国地图 - 延迟确保清空操作完成
      Future.microtask(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        await _fitMapToTrackPoints();
        DebugUtil.success('🗺️ 已切换到全国地图视图（无数据）');
      });
      return;
    }
    
    // 更新当前显示的数据
    locationData.value = currentData;
    
    // 从API数据中更新头像信息
    _updateAvatarsFromApiData(currentData);
    
    DebugUtil.success('✅ 切换到 ${isOneself.value == 1 ? "自己" : "另一半"} 的数据');
    
    // 立即更新统计数据
    _updateStatistics();
    
    // 🚀 使用优化的分批渲染
    _batchRenderTrackData();
  }
  
  /// 分批渲染轨迹数据，避免阻塞UI
  Future<void> _batchRenderTrackData() async {
    try {
      DebugUtil.info('🚀 开始分批渲染轨迹数据...');
      
      // 第一批：立即更新统计数据（最快）
      _updateStatistics();
      
      // 等待一帧，让UI有机会更新
      await Future.delayed(const Duration(milliseconds: 16));
      
      // 第二批：分批渲染轨迹点
      await _batchRenderTrackPoints();
      
      // 等待一帧
      await Future.delayed(const Duration(milliseconds: 16));
      
      // 第三批：分批渲染停留点
      await _batchRenderStopPoints();
      
      // 等待一帧
      await Future.delayed(const Duration(milliseconds: 16));
      
      // 第四批：更新停留记录
      await _updateStopRecords();
      
      DebugUtil.success('✅ 分批渲染完成！');
    } catch (e) {
      DebugUtil.error('❌ 分批渲染失败: $e');
    }
  }
  
  /// 简化的轨迹点渲染方法 - 直接交给SDK处理
  /// 💡 让原生SDK处理大量数据的绘制，而不是在Flutter层分批
  Future<void> _batchRenderTrackPoints() async {
    final data = locationData.value;
    if (data == null) {
      DebugUtil.warning('⚠️ 没有位置数据');
      return;
    }
    
    // 生成缓存键
    final cacheKey = '${isOneself.value}_${selectedDate.value.toIso8601String()}';
    
    // 先检查缓存
    if (_trackPointsCache.containsKey(cacheKey)) {
      final cachedPoints = _trackPointsCache[cacheKey]!;
      DebugUtil.info('📦 使用缓存的轨迹点数据，总数: ${cachedPoints.length}');
      trackPoints.value = cachedPoints;
      return;
    }
    
    // 获取原始轨迹点数据
    List<LatLng> rawPoints = [];
    
    try {
      if (data.locations != null && data.locations!.isNotEmpty) {
        // 使用 locations 数组（旧版API）
        rawPoints = await compute(_processLocationData, data.locations!);
      } else if (data.trace?.stops != null && data.trace!.stops.isNotEmpty) {
        // 使用 trace.stops 生成轨迹点（新版API）
        rawPoints = await compute(_processStopsAsTrackData, data.trace!.stops);
      } else {
        DebugUtil.warning('⚠️ 没有轨迹点数据');
        trackPoints.clear();
        return;
      }
    } catch (e) {
      DebugUtil.error('处理轨迹点数据失败: $e');
      return;
    }
    
    // ✅ 正确的做法：一次性传给SDK，让原生代码处理
    // 高德的原生SDK能高效处理大量点的绘制
    DebugUtil.info('📍 一次性加载所有轨迹点，总数: ${rawPoints.length}');
    trackPoints.value = rawPoints;
    
    // 缓存数据
    _trackPointsCache[cacheKey] = rawPoints;
    
    // 限制缓存大小，避免内存占用过多
    if (_trackPointsCache.length > 10) {
      final oldestKey = _trackPointsCache.keys.first;
      _trackPointsCache.remove(oldestKey);
    }
    
    DebugUtil.success('✅ 轨迹点加载完成');
  }
  
  /// 分批渲染停留点
  Future<void> _batchRenderStopPoints() async {
    final trace = locationData.value?.trace;
    if (trace == null || trace.stops.isEmpty) {
      DebugUtil.warning('⚠️ 没有停留点数据');
      return;
    }
    
    final rawStops = trace.stops;
    const batchSize = 20; // 每批处理20个停留点
    
    DebugUtil.info('🏠 开始分批渲染停留点，总数: ${rawStops.length}，批次大小: $batchSize');
    
    // 清空现有停留点
    stopPoints.clear();
    stayMarkers.clear();
    
    // 分批添加停留点
    for (int i = 0; i < rawStops.length; i += batchSize) {
      final endIndex = (i + batchSize < rawStops.length) ? i + batchSize : rawStops.length;
      final batch = rawStops.sublist(i, endIndex);
      
      // 转换并添加这一批停留点
      final batchStopPoints = batch
          .where((stop) => stop.lat != 0.0 && stop.lng != 0.0)
          .toList();
      
      stopPoints.addAll(batchStopPoints);
      
      // 创建自定义Marker（使用原有的自定义图标逻辑）
      await _createCustomMarkersForBatch(batchStopPoints, stopPoints.length - batchStopPoints.length);
      
      DebugUtil.info('🏠 已渲染停留点批次 ${(i / batchSize + 1).ceil()}/${(rawStops.length / batchSize).ceil()}');
      
      // 每批之间等待一帧，避免阻塞UI
      if (i + batchSize < rawStops.length) {
        await Future.delayed(const Duration(milliseconds: 8));
      }
    }
    
    DebugUtil.success('✅ 停留点分批渲染完成，总数: ${stopPoints.length}');
  }

  /// 为批次创建自定义停留点Marker
  Future<void> _createCustomMarkersForBatch(List<TrackStopPoint> batchStops, int startIndex) async {
    final List<Marker> batchMarkers = [];
    
    for (int i = 0; i < batchStops.length; i++) {
      final stop = batchStops[i];
      final globalIndex = startIndex + i;
      
      // 根据 pointType 和 serialNumber 判断点的类型
      bool isEndPoint = stop.pointType == 'end' || stop.serialNumber == '终';
      bool isStartPoint = stop.pointType == 'start' || stop.serialNumber == '起';
      
      // 跳过终点和起点，只显示中间停留点
      if (isEndPoint || isStartPoint) {
        continue;
      }
      
      // 使用停留点的实际serialNumber作为显示编号
      String displayNumber = stop.serialNumber ?? (globalIndex + 1).toString();
      
      try {
        BitmapDescriptor? icon;
        
        // 创建自定义停留点图标
        try {
          icon = await _createCustomStayPointIcon(displayNumber);
        } catch (iconError) {
          // 降级方案：使用粉色默认标记
          icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
        }
        
        // 创建标记
        final stopInfo = _parseStopInfo(stop);
        final String infoTitle = stopInfo['locationName']!;
        final String infoSnippet = '${stop.startTime ?? ''} ${stop.duration?.isNotEmpty == true ? '停留${stop.duration}' : ''}';
        
        final marker = Marker(
          position: LatLng(stop.lat, stop.lng),
          icon: icon,
          anchor: const Offset(0.5, 0.5),
          infoWindowEnable: true,
          autoShowCustomInfoWindow: false,
          draggable: true,
          isTrackStyle: true,
          stayDuration: stopInfo['stayDuration'],
          stayTime: stopInfo['stayTime'],
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
            drawHighlightCircle(newPosition);
          },
          onTap: (String markerId) {
            unawaited(_moveToStopPointWithHighlightInternal(
              stop.lat, 
              stop.lng, 
              stopPoint: stop,
            ));
          },
        );
        
        batchMarkers.add(marker);
      } catch (e) {
        DebugUtil.warning('创建停留点 $displayNumber 标记失败: $e');
      }
    }
    
    // 添加到主列表
    stayMarkers.addAll(batchMarkers);
  }


  /// 头像点击时切换用户视角（优化版本）
  void onAvatarTapped(bool isMyself) {
    DebugUtil.info('🎯 头像点击开始 - isMyself: $isMyself');
    
    // 🎬 切换头像时重置轨迹播放状态
    if (isReplaying.value) {
      DebugUtil.info('🛑 检测到正在播放轨迹，切换头像时重置播放状态');
      _resetReplayState();
    }
    
    // 更新状态
    final newValue = isMyself ? 1 : 0;
    if (isOneself.value == newValue) {
      DebugUtil.info('已经是当前用户视角，无需切换');
      return;
    }
    
    isOneself.value = newValue;
    DebugUtil.info('🔄 切换到${isMyself ? "自己" : "另一半"}的视角');
    
    // 立即清理不需要的数据，减少内存占用
    _clearMapImmediately();
    
    // 🚀 优化的数据切换流程
    _performOptimizedUserSwitch(isMyself);
  }
  
  /// 执行优化的用户切换
  void _performOptimizedUserSwitch(bool isMyself) {
    final currentData = isMyself ? mySelfData.value : partnerData.value;
    
    if (currentData == null) {
      DebugUtil.warning('⚠️ 目标用户数据为空');
      _clearData();
      // 无数据时显示全国地图 - 延迟确保清空操作完成
      Future.microtask(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        await _fitMapToTrackPoints();
        DebugUtil.success('🗺️ 已切换到全国地图视图（无数据）');
      });
      return;
    }
    
    // 更新数据源
    locationData.value = currentData;
    _updateAvatarsFromApiData(currentData);
    
    // 先渲染基本数据，快速响应
    _updateStatistics();
    
    // 异步更新轨迹数据和停留记录
    Future.microtask(() async {
      // 使用优化的批量渲染
      await _batchRenderTrackPoints();
      
      // ⚠️ 必须先更新停留点数据，stopRecords依赖stopPoints
      await _batchRenderStopPoints();
      
      // 更新停留记录（这会更新列表数据）
      await _updateStopRecords();
      
      // 移动地图到对应位置
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _moveToTargetUserTrackLocation(isMyself);
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
    
    // 🎯 使用智能相机移动方法，提供更好的用户体验
    _moveToLocationWithSmartTrackAnimation(targetLocation, userName);
  }

  /// 🆕 轨迹页面智能相机移动方法
  Future<void> _moveToLocationWithSmartTrackAnimation(LatLng targetLocation, String userName) async {
    if (mapController == null) {
      DebugUtil.error('地图控制器为空，无法移动相机');
      return;
    }

    try {
      // 🎯 获取当前相机位置，用于更精确的轨迹动画决策
      final currentPosition = await mapController!.getCameraPosition();
      final currentZoom = currentPosition?.zoom ?? 15.0;
      final currentTarget = currentPosition?.target;
      
      DebugUtil.info('🎯 轨迹页面当前相机位置: $currentTarget, 缩放: $currentZoom');

      // 计算当前位置到目标位置的距离（如果有当前位置）
      double distance = 0;
      if (currentTarget != null) {
        distance = _calculateDistance(currentTarget, targetLocation);
      }
      
      DebugUtil.info('🎯 轨迹页面智能相机移动: 目标位置=$targetLocation, 距离=${distance.toStringAsFixed(0)}米, 轨迹点数=${trackPoints.length}');
      
      // 🎯 轨迹页面专用的动画策略 - 综合考虑距离和轨迹数据量
      if (trackPoints.length > 10 && distance > 1000) {
        // 有丰富轨迹数据且距离较远：先聚焦用户位置，再自动适配轨迹
        await _performTrackFocusThenFit(targetLocation, userName);
      } else if (trackPoints.length > 1) {
        // 有轨迹数据：使用两段式动画
        await _performTrackTwoStageAnimation(targetLocation, userName);
      } else {
        // 没有轨迹数据：直接移动到用户位置
        await _performTrackDirectMove(targetLocation, userName);
      }

      DebugUtil.success('✅ 轨迹页面智能相机移动完成: $userName');
    } catch (e) {
      DebugUtil.error('❌ 轨迹页面智能相机移动失败: $e');
    }
  }

  /// 🎯 轨迹页面聚焦后适配动画（丰富轨迹数据）
  Future<void> _performTrackFocusThenFit(LatLng target, String userName) async {
    // 第一阶段：快速移动到用户位置并聚焦
    await mapController!.moveCamera(
      CameraUpdate.newCameraPosition(CameraPosition(
        target: target,
        zoom: 16.0, // 聚焦到用户位置
      )),
      animated: true,
      duration: 600,
    );
    
    DebugUtil.info('🎯 轨迹页面聚焦完成: $userName');
    
    // 第二阶段：延迟后自动适配完整轨迹
    Future.delayed(const Duration(milliseconds: 1200), () {
      _fitMapToTrackPoints();
    });
  }

  /// 🎯 轨迹页面两段式动画（少量轨迹数据）
  Future<void> _performTrackTwoStageAnimation(LatLng target, String userName) async {
    // 第一阶段：移动到目标位置，使用中等缩放
    await mapController!.moveCamera(
      CameraUpdate.newCameraPosition(CameraPosition(
        target: target,
        zoom: 14.5, // 中等缩放，便于看到周围环境
      )),
      animated: true,
      duration: 700,
    );
    await Future.delayed(const Duration(milliseconds: 200));

    // 第二阶段：放大到轨迹查看的合适级别
    await mapController!.moveCamera(
      CameraUpdate.zoomTo(16.0),
      animated: true,
      duration: 500,
    );
    
    // 第三阶段：延迟后适配轨迹
    Future.delayed(const Duration(milliseconds: 800), () {
      _fitMapToTrackPoints();
    });

    DebugUtil.info('🎯 轨迹页面两段式动画完成: $userName');
  }

  /// 🎯 轨迹页面直接移动（无轨迹数据）
  Future<void> _performTrackDirectMove(LatLng target, String userName) async {
    final targetPosition = CameraPosition(
      target: target,
      zoom: 16.0, // 适合查看单点位置的缩放级别
    );

    await mapController!.moveCamera(
      CameraUpdate.newCameraPosition(targetPosition),
      animated: true,
      duration: 800,
    );
    
    DebugUtil.info('🎯 轨迹页面直接移动完成: $userName');
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
      // 🎯 加载状态已在 selectDate 中设置，这里直接加载数据
      
      // 异步调用数据加载，避免阻塞UI
      await _performLoadLocationDataDirect();
      
      // 数据加载完成后，异步调整地图视图（统一使用 _fitMapToTrackPoints）
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          // 异步调整地图视图，避免阻塞
          await Future.delayed(const Duration(milliseconds: 100));
          
          // 🎯 统一使用 _fitMapToTrackPoints 来调整相机位置
          // 这个方法会根据轨迹点计算最佳视图，确保所有轨迹都可见
          await _fitMapToTrackPoints();
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
      CustomBottomDialog.show(context: Get.context!, caller: SourcePageUtilsCaller.track);
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
    
    // 🎯 切换日期时始终显示加载动画，提升用户体验
    DebugUtil.info('🎬 设置 isLoading = true，准备显示加载动画');
    isLoading.value = true;
    
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
          // 🎯 移动地图并绘制高亮圆圈
          unawaited(_moveToStopPointWithHighlightInternal(
            stop.lat, 
            stop.lng, 
            stopPoint: stop,
          ));
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
        
        // ✅ 多次隐藏 InfoWindow，防止闪现
        _hideAllInfoWindows(); // 立即隐藏
        Future.delayed(const Duration(milliseconds: 50), () {
          _hideAllInfoWindows();
          DebugUtil.info('🔒 停留点标记创建后关闭所有 InfoWindow (50ms)');
        });
        Future.delayed(const Duration(milliseconds: 150), () {
          _hideAllInfoWindows();
          DebugUtil.info('🔒 停留点标记创建后关闭所有 InfoWindow (150ms)');
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
          'assets/images/kissu_location_start.webp',
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
              'assets/images/kissu_location_end.webp',
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
        
        // ✅ 多次隐藏 InfoWindow，防止闪现
        _hideAllInfoWindows(); // 立即隐藏
        Future.delayed(const Duration(milliseconds: 50), () {
          _hideAllInfoWindows();
          DebugUtil.info('🔒 起终点标记创建后关闭所有 InfoWindow (50ms)');
        });
        Future.delayed(const Duration(milliseconds: 150), () {
          _hideAllInfoWindows();
          DebugUtil.info('🔒 起终点标记创建后关闭所有 InfoWindow (150ms)');
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

  /// 平滑标记更新方法 - 无阈值检查，每帧都更新
  /// [position] 新位置
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
      
      // 🎯 无阈值检查，每一帧都更新位置，确保平滑移动
      replayAvatarMarker.value = Marker(
        position: position,
        icon: currentMarker.icon,
        anchor: currentMarker.anchor,
        rotation: rotation,
        alpha: 1.0, // 确保完全不透明
        zIndex: 999, // 确保在最上层
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

  /// 在两点之间进行插值（线性插值）
  LatLng _interpolatePosition(LatLng start, LatLng end, double t) {
    // 确保插值参数在0-1之间，避免异常值
    final clampedT = t.clamp(0.0, 1.0);
    
    // 使用高精度线性插值，确保平滑过渡
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
    
    // 🎯 优化播放时长计算，确保有足够的时间进行平滑插值
    // 根据轨迹点数量和距离综合计算
    final pointCount = trackPoints.length;
    
    // 基于距离的时长计算（每公里约5-8秒）
    final distanceBasedSeconds = (totalDistanceKm * 6).round();
    
    // 基于点数的时长计算（确保每个点之间有足够的插值时间）
    final pointBasedSeconds = (pointCount * 0.05).round(); // 每个点约50ms
    
    // 取两者的较大值，确保动画足够平滑
    var optimalSeconds = distanceBasedSeconds > pointBasedSeconds 
        ? distanceBasedSeconds 
        : pointBasedSeconds;
    
    // 应用限制：最短5秒，最长20秒（增加时长以获得更平滑的动画）
    optimalSeconds = optimalSeconds.clamp(5, 20);
    
    // 对于很短的轨迹（小于100米），使用最短时间
    if (totalDistanceKm < 0.1) {
      return const Duration(seconds: 5);
    }
    
    return Duration(seconds: optimalSeconds);
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
    
    // 🎯 移除阈值检查，每一帧都更新位置，确保平滑移动
    currentPosition.value = newPosition;
    
    // 直接更新标记位置，不使用优化方法中的阈值检查
    _updateReplayAvatarMarkerSmooth(newPosition);
    
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
    
    // ✅ 清除所有地图高亮（InfoWindow + 围栏圆圈）
    clearMapHighlights();
    
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
      backButtonAnimationController.dispose();
    } catch (e) {
      debugPrint('清理backButtonAnimationController时出错: $e');
    }
    
    try {
      _debounceTimer?.cancel();
      _debounceTimer = null;
    } catch (e) {
      debugPrint('清理debounceTimer时出错: $e');
    }
    
    
    // 清理轨迹点缓存（保留最近10个）
    if (_trackPointsCache.length > 10) {
      final keys = _trackPointsCache.keys.toList();
      for (int i = 0; i < keys.length - 10; i++) {
        _trackPointsCache.remove(keys[i]);
      }
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