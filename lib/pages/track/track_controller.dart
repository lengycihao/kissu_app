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
import 'package:kissu_app/pages/track/component/custom_stay_point_info_window.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:intl/intl.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:kissu_app/utils/debug_util.dart';
import 'package:kissu_app/widgets/dialogs/permission_request_dialog.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog.dart';

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

class TrackController extends GetxController {
  /// 当前查看的用户类型 (1: 自己, 0: 另一半)
  final isOneself = 0.obs; // 默认选择另一半
  
  /// 地图就绪状态
  final isMapReady = false.obs;
  
  /// 轨迹线状态管理 - 用于解决高德地图轨迹线更新问题
  final RxBool hasValidTrackData = false.obs;
  
  /// 移除了自定义图标，直接使用彩色默认标记
  
  /// 用户信息
  final myAvatar = "".obs;
  final partnerAvatar = "".obs;
  final isBindPartner = false.obs;
  
  /// 播放控制器UI状态 - true显示完整播放器，false显示简单按钮
  final showFullPlayer = false.obs;
  /// 播放期间已行走的距离
  final replayDistance = "".obs;
  /// 播放时间
  final replayTime = "00:00:00".obs;
  
  /// 当前选择的日期
  final selectedDate = DateTime.now().obs;
  
  /// 日期选择器的选中索引（0-6，对应最近7天）
  final selectedDateIndex = 6.obs; // 默认选择今天（最右边）
  
  /// 位置数据
  final Rx<LocationResponse?> locationData = Rx<LocationResponse?>(null);
  
  /// 停留点点击回调
  Function(TrackStopPoint, LatLng)? onStayPointTapped;
  
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
    if (mapController == null) {
      DebugUtil.warning('地图控制器为空，无法调整视图');
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
    
    // 检查是否有初始坐标需要高亮显示
    _handleInitialCoordinates();
  }
  
  /// 处理初始坐标高亮显示
  void _handleInitialCoordinates() {
    final initialInfo = initialCoordinateInfo.value;
    if (initialInfo != null) {
      DebugUtil.info('处理初始坐标高亮显示: ${initialInfo.latitude}, ${initialInfo.longitude}');
      
      // 延迟执行，确保地图完全加载
      Future.delayed(const Duration(milliseconds: 500), () {
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
        
        // 使用增强版方法：移动地图、绘制高亮圆圈、显示InfoWindow
        moveToStopPointWithHighlight(
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
    mapController?.moveCamera(CameraUpdate.newLatLng(location));
  }
  
  /// 移动地图到停留点（公共方法，用于列表点击）
  void moveToStopPoint(double latitude, double longitude) {
    final targetLocation = LatLng(latitude, longitude);
    
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
  }

  /// 清除所有高亮圆圈
  void clearAllHighlightCircles() {
    highlightCircles.clear();
    DebugUtil.info('清除所有高亮圆圈');
  }

  /// 绘制高亮圆圈（使用Polygon实现）
  void drawHighlightCircle(LatLng center) {
    // 先清除之前的高亮圆圈
    clearAllHighlightCircles();
    
    // 创建圆形Polygon，参考iOS实现：半径100米，白色边框，粉色填充
    final circlePoints = generateCirclePoints(center, 100.0); // 100米半径（翻倍）
    
    final circle = Polygon(
      points: circlePoints,
      strokeColor: const Color(0xFFFFFFFF), // 白色边框
      strokeWidth: 3.0,
      fillColor: const Color(0xFFFFE3EB).withOpacity(0.38), // 背景色 #FFE3EB，不透明度38%
    );
    
    highlightCircles.add(circle);
    DebugUtil.info('绘制高亮圆圈: ${center.latitude}, ${center.longitude}');
  }

  /// 生成精确圆形的多边形顶点（使用球面几何学）
  List<LatLng> generateCirclePoints(LatLng center, double radius, {int sides = 180}) {
    final points = <LatLng>[];
    // 地球半径（米）
    const double earthRadius = 6378137.0;
    
    // 将角度转换为弧度
    final double centerLatRad = center.latitude * pi / 180.0;
    final double centerLngRad = center.longitude * pi / 180.0;
    
    // 计算角度增量
    final double angleIncrement = 2 * pi / sides;
    for (int i = 0; i < sides; i++) {
      final double angle = angleIncrement * i;
      // 计算圆上点的经纬度（弧度）
      final double latRad = asin(
        sin(centerLatRad) * cos(radius / earthRadius) +
        cos(centerLatRad) * sin(radius / earthRadius) * cos(angle)
      );
      
      final double lngRad = centerLngRad + atan2(
        sin(angle) * sin(radius / earthRadius) * cos(centerLatRad),
        cos(radius / earthRadius) - sin(centerLatRad) * sin(latRad)
      );
      
      // 转换为度并添加到点列表
      points.add(LatLng(
        latRad * 180.0 / pi,
        lngRad * 180.0 / pi
      ));
    }
    return points;
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
  }) {
    initialCoordinateInfo.value = InitialCoordinateInfo(
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      duration: duration,
      startTime: startTime,
      endTime: endTime,
    );
    DebugUtil.info('设置初始坐标: $latitude, $longitude, 位置: $locationName');
  }
  
  /// 收起底部面板到最小高度
  void collapseBottomSheet() {
    if (_draggableController != null) {
      _draggableController!.animateTo(
        0.4, // 最小高度比例
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 移动地图到停留点并高亮显示（增强版方法）
  void moveToStopPointWithHighlight(double latitude, double longitude, {TrackStopPoint? stopPoint}) {
    final targetLocation = LatLng(latitude, longitude);
    
    // 0. 启动地图移动保护机制
    CustomStayPointInfoWindowManager.startMapMoving();
    
    // 1. 移动地图到停留点
    moveToStopPoint(latitude, longitude);
    
    // 2. 绘制高亮圆圈
    drawHighlightCircle(targetLocation);
    
    // 3. 收起底部面板，避免遮挡地图
    collapseBottomSheet();
    
    // 4. 显示InfoWindow（如果有停留点回调和stopPoint数据）
    if (onStayPointTapped != null && stopPoint != null) {
      onStayPointTapped!(stopPoint, targetLocation);
    }
    
    // 5. 延迟结束保护机制（等待所有动画完成）
    Future.delayed(const Duration(milliseconds: 1500), () {
      CustomStayPointInfoWindowManager.stopMapMoving();
    });
  }

  /// 轨迹点（从API数据获取）
  final RxList<LatLng> trackPoints = <LatLng>[].obs;

  /// 停留点列表（从API数据获取）
  final RxList<TrackStopPoint> stopPoints = <TrackStopPoint>[].obs;

  /// 停留点 marker 列表
  final RxList<Marker> stayMarkers = <Marker>[].obs;

  /// 轨迹起点和终点 marker 列表
  final RxList<Marker> trackStartEndMarkers = <Marker>[].obs;

  /// 高亮圆圈覆盖物列表（使用Polygon实现）
  final RxList<Polygon> highlightCircles = <Polygon>[].obs;

  /// 轨迹回放状态
  final currentReplayIndex = 0.obs;
  final isReplaying = false.obs; // 改为响应式变量
  final replaySpeed = 1.0.obs; // 播放速度倍数
  Timer? _replayTimer;

  /// 平滑动画相关
  final currentPosition = Rx<LatLng?>(null);
  final animationProgress = 0.0.obs;
  static const int animationSteps = 20; // 每两个点之间的插值步数
  int _currentStep = 0;
  
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
  
  /// 完全非阻塞的数据加载方法（用于头像切换）
  void _performLoadLocationDataDirectNonBlocking() {
    // 不等待任何异步操作，完全非阻塞
    Future(() async {
      try {
        // 增加数据版本号，确保数据一致性
        final currentVersion = ++_dataVersion;
        
        final dateString = DateFormat('yyyy-MM-dd').format(selectedDate.value);
        final isOneSelfValue = isOneself.value == 1;
        
        DebugUtil.info('非阻塞智能请求数据: $dateString, isOneself=$isOneSelfValue');
        
        final result = await TrackApi.getTrack(
          date: dateString,
          isOneself: isOneSelfValue ? 1 : 0,
          useCache: true, // 启用缓存
        );
        
        if (result.isSuccess && result.data != null) {
          // 检查数据版本是否还有效
          if (currentVersion != _dataVersion) {
            DebugUtil.warning('数据版本已过期，放弃数据处理');
            return;
          }
          
          // 更新数据
          locationData.value = result.data;
          
          // 从API数据中更新头像信息
          _updateAvatarsFromApiData(result.data!);
          
          DebugUtil.success('非阻塞获取到最新数据');
          
          // 使用完全非阻塞的渐进式数据更新
          _progressiveDataUpdateNonBlocking();
          
        } else {
          CustomToast.show(Get.context!, result.msg ?? '获取数据失败');
          _clearData();
        }
      } catch (e, stackTrace) {
        DebugUtil.error('非阻塞数据加载异常: $e');
        DebugUtil.error('异常堆栈: $stackTrace');
        CustomToast.show(Get.context!, '加载数据失败，请稍后重试');
        _clearData();
      } finally {
        isLoading.value = false;
      }
    });
  }
  
  /// 直接执行数据加载 - 跳过防抖，用于头像切换
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
    final isOneSelfValue = isOneself.value == 1;
    
    try {
      // 📡 智能获取数据：自动使用缓存（历史数据）或API（今日数据）
      DebugUtil.info('智能请求数据: $dateString, isOneself=$isOneSelfValue');
      
      final result = await TrackApi.getTrack(
        date: dateString,
        isOneself: isOneSelfValue ? 1 : 0,
        useCache: true, // 启用缓存
      );
      
      if (result.isSuccess && result.data != null) {
        // 检查数据版本是否还有效
        if (currentVersion != _dataVersion) {
          DebugUtil.warning('数据版本已过期，放弃数据处理');
          return;
        }
        
        // 已移除虚拟数据标记，所有情况都使用真实API数据
        locationData.value = result.data;
        
        // 从API数据中更新头像信息
        _updateAvatarsFromApiData(result.data!);
        
        DebugUtil.success('获取到最新数据');
        
        // 使用渐进式数据更新，避免长时间阻塞UI
        await _progressiveDataUpdate();
        
      } else {
        CustomToast.show(Get.context!, result.msg ?? '获取数据失败');
        _clearData();
      }
    } catch (e, stackTrace) {
      DebugUtil.error('Track Controller loadLocationData error: $e');
      DebugUtil.error('请求参数: date=$dateString, isOneself=$isOneSelfValue');
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
    
    // 不再基于绑定状态使用虚拟数据，所有情况都从真实接口获取数据
    // 这样用户无论绑定与否都能看到真实的轨迹数据
    
    final dateString = DateFormat('yyyy-MM-dd').format(selectedDate.value);
    final isOneSelfValue = isOneself.value == 1;
    
    try {
      // 📡 智能获取数据：自动使用缓存（历史数据）或API（今日数据）
      DebugUtil.info('智能请求数据: $dateString, isOneself=$isOneSelfValue');
      
      final result = await TrackApi.getTrack(
        date: dateString,
        isOneself: isOneSelfValue ? 1 : 0,
        useCache: true, // 启用缓存
      );
      
      if (result.isSuccess && result.data != null) {
        // 检查数据版本是否还有效
        if (currentVersion != _dataVersion) {
          DebugUtil.warning('数据版本已过期，放弃数据处理');
          return;
        }
        
        
        // 已移除虚拟数据标记，所有情况都使用真实API数据
        locationData.value = result.data;
        
        // 从API数据中更新头像信息
        _updateAvatarsFromApiData(result.data!);
        
        DebugUtil.success('获取到最新数据');
        
        // 异步并行处理数据，避免阻塞UI
        await Future.wait([
          _updateStopRecords(),
          _updateTrackDataAsync(),
        ]);
        
        // 统计数据可以同步更新，因为很快
        _updateStatistics();
        
      } else {
        CustomToast.show(Get.context!, result.msg ?? '获取数据失败');
        _clearData();
      }
    } catch (e, stackTrace) {
      DebugUtil.error('Track Controller loadLocationData error: $e');
      DebugUtil.error('请求参数: date=$dateString, isOneself=$isOneSelfValue');
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
  
  /// 重置播放状态
  void _resetReplayState() {
    // 停止当前播放
    _replayTimer?.cancel();
    isReplaying.value = false;
    currentReplayIndex.value = 0;
    _currentStep = 0;
    replaySpeed.value = 1.0;
    currentPosition.value = null;
    animationProgress.value = 0.0;
  }
  
  /// 立即清空数据，给用户即时反馈 - 非阻塞版本
  void _clearDataInstantly() {
    // 清空轨迹相关数据
    trackPoints.clear();
    stopPoints.clear();
    stayMarkers.clear();
    trackStartEndMarkers.clear();
    stopRecords.clear();
    
    // 重置轨迹线状态
    hasValidTrackData.value = false;
    
    // 重置统计数据为加载状态
    stayCount.value = 0;
    stayDuration.value = "加载中...";
    moveDistance.value = "加载中...";
    
    // 异步触发地图更新，避免阻塞UI
    Future.microtask(() => _forceMapUpdate());
    
    DebugUtil.info('已立即清空旧数据，显示加载状态');
  }
  
  /// 智能清空数据 - 头像切换专用，提供更好的用户反馈
  void _clearDataForAvatarSwitch() {
    // 立即清空可视数据
    trackPoints.clear();
    stopPoints.clear();
    stayMarkers.clear();
    trackStartEndMarkers.clear();
    stopRecords.clear();
    
    // 重置轨迹线状态
    hasValidTrackData.value = false;
    
    // 显示切换状态，而不是加载状态
    stayCount.value = 0;
    stayDuration.value = "切换中...";
    moveDistance.value = "切换中...";
    
    // 异步触发地图更新
    Future.microtask(() => _forceMapUpdate());
    
    DebugUtil.info('头像切换：已清空旧数据，显示切换状态');
  }
  
  /// 强制地图更新，确保UI同步
  void _forceMapUpdate() {
    // 检查地图是否就绪
    if (!isMapReady.value) {
      DebugUtil.warning('地图未就绪，跳过强制更新');
      return;
    }
    
    // 强制刷新所有响应式变量，让UI重新构建
    trackPoints.refresh();
    stopPoints.refresh();
    stayMarkers.refresh();
    trackStartEndMarkers.refresh();
    DebugUtil.info('地图强制更新完成');
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
        
        // 重新处理数据
    await Future.wait([
      _updateStopRecords(),
      _updateTrackDataAsync(),
    ]);
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
    trackPoints.clear();
    stopPoints.clear();
    stayMarkers.clear();
    trackStartEndMarkers.clear();
    stopRecords.clear();
    stayCount.value = 0;
    stayDuration.value = "";
    moveDistance.value = "";
    
    // 强制触发地图更新，确保轨迹线被清空
    _forceMapUpdate();
  }

  /// 新的API结构不需要设备数据，直接使用trace数据

  /// 异步更新轨迹数据 - 优化性能版本
  Future<void> _updateTrackDataAsync() async {
    if (locationData.value == null) {
      DebugUtil.error('位置数据为空，无法更新轨迹');
      return;
    }
    
    final data = locationData.value!;
    final currentDate = DateFormat('yyyy-MM-dd').format(selectedDate.value);
    DebugUtil.info('更新轨迹数据: 日期=$currentDate, isOneself=${isOneself.value}, 位置点=${data.locations?.length ?? 0}个');
    
    // 在后台线程处理数据以避免阻塞UI
    final rawPoints = await compute(_processLocationData, data.locations ?? []);
    
    // 先检查数据有效性，再进行原子更新
    bool isValidData = rawPoints.isNotEmpty && rawPoints.length >= 2;
    
    // 原子更新：先更新状态，再更新数据
    hasValidTrackData.value = isValidData;
    trackPoints.value = rawPoints;
    DebugUtil.info('轨迹点数量: ${trackPoints.length} (使用原始精度)');
    
    // 立即触发地图更新，确保轨迹线显示
    _forceMapUpdate();
    
    // 异步处理停留点数据，避免阻塞主线程
    _processStopPointsAsync(data);
    
    // 异步更新标记，避免阻塞UI
    _updateMarkersAsync();
  }
  
  /// 异步处理停留点数据
  Future<void> _processStopPointsAsync(LocationResponse data) async {
    try {
      // 过滤停留点并调整到轨迹线上
      final rawStopPoints = data.trace?.stops
          .where((stop) => stop.lat != 0.0 && stop.lng != 0.0)
          .toList() ?? [];
      DebugUtil.info('原始停留点数量: ${rawStopPoints.length}');
      
      // 在后台线程处理停留点调整
      final adjustedStopPoints = await compute(_adjustStopPointsToTrackLineStatic, {
        'rawStopPoints': rawStopPoints,
        'trackPoints': trackPoints.toList(),
      });
      stopPoints.value = adjustedStopPoints;
      DebugUtil.info('调整后停留点数量: ${stopPoints.length}');
      
    } catch (e) {
      DebugUtil.error('处理停留点数据失败: $e');
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
  
  /// 在后台线程处理位置数据
  static List<LatLng> _processLocationData(List<TrackLocation> locations) {
    return locations
        .map((location) => LatLng(location.lat, location.lng))
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
    if (locationData.value == null) {
      DebugUtil.error(' locationData为空，无法更新停留记录');
      return;
    }
    
    DebugUtil.info('🔍 开始更新停留记录列表');
    
    // 从 trace.stops 获取停留记录数据
    final traceStops = locationData.value!.trace?.stops ?? [];
    DebugUtil.info('📊 trace.stops数量: ${traceStops.length}');
    
    if (traceStops.isEmpty) {
      DebugUtil.warning(' trace.stops为空');
      stopRecords.clear();
      return;
    }
    
    // 在后台线程处理停留记录数据转换
    try {
      final processedRecords = await compute(_processStopRecords, traceStops);
      stopRecords.value = processedRecords;
      DebugUtil.success(' 停留记录更新完成，总数量: ${stopRecords.length}');
    } catch (e) {
      DebugUtil.error(' 处理停留记录失败: $e');
      stopRecords.clear();
    }
  }
  
  /// 在后台线程处理停留记录数据
  static List<StopRecord> _processStopRecords(List<TrackStopPoint> traceStops) {
    return traceStops.map((stop) {
      return StopRecord(
        latitude: stop.lat,
        longitude: stop.lng,
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
    // 切换用户时，立即清空数据并异步加载，避免卡顿
    _clearDataForAvatarSwitch();
    Future.microtask(() => _loadDataAsync());
  }
  
  /// 强制刷新当前用户数据（用于头像点击）- 完全非阻塞版本
  void refreshCurrentUserData() {
    DebugUtil.info('🔄 刷新用户数据: isOneself=${isOneself.value}');
    
    // 立即清空数据，给用户即时反馈
    _clearDataForAvatarSwitch();
    
    // 使用scheduleMicrotask确保在下一个微任务中执行，完全避免阻塞
    scheduleMicrotask(() async {
      try {
        // 停止播放和清理状态
        _resetReplayState();
        
        // 异步加载数据，但不等待完成，完全非阻塞
        _loadDataAsyncNonBlocking();
      } catch (e) {
        DebugUtil.error('头像切换数据加载失败: $e');
      }
    });
  }
  
  /// 完全非阻塞的数据加载方法（用于头像切换）
  void _loadDataAsyncNonBlocking() {
    // 不等待任何异步操作，完全非阻塞
    Future(() async {
      try {
        // 显示加载状态（仅对今天的数据）
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final selectedDateString = DateFormat('yyyy-MM-dd').format(selectedDate.value);
        final isToday = selectedDateString == today;
        
        if (isToday) {
          isLoading.value = true;
        }
        
        // 异步调用数据加载，但不等待完成
        _performLoadLocationDataDirectNonBlocking();
        
      } catch (e) {
        DebugUtil.error('非阻塞数据加载失败: $e');
        isLoading.value = false;
      }
    });
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
  
  /// 完全非阻塞的渐进式数据更新（用于头像切换）
  void _progressiveDataUpdateNonBlocking() {
    // 不等待任何异步操作，完全非阻塞
    Future(() async {
      try {
        // 第一步：更新统计数据（最快）
        Future.microtask(() => _updateStatistics());
        
        // 第二步：更新停留记录（中等耗时）
        await _updateStopRecords();
        
        // 第三步：更新轨迹数据（最耗时）
        await _updateTrackDataAsync();
        
        DebugUtil.success('非阻塞渐进式数据更新完成');
      } catch (e) {
        DebugUtil.error('非阻塞渐进式数据更新失败: $e');
      }
    });
  }
  
  /// 渐进式数据更新 - 分步骤更新，避免长时间阻塞
  Future<void> _progressiveDataUpdate() async {
    try {
      // 第一步：更新统计数据（最快）
      Future.microtask(() => _updateStatistics());
      
      // 第二步：更新停留记录（中等耗时）
      await _updateStopRecords();
      
      // 第三步：更新轨迹数据（最耗时）
      await _updateTrackDataAsync();
      
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
      final marker = Marker(
        position: LatLng(stop.lat, stop.lng),
        infoWindow: InfoWindow(
          title: '停留点',
          snippet: stop.locationName ?? '未知位置',
        ),
        onTap: (String markerId) {
          DebugUtil.info('点击了停留点: ${stop.locationName}');
          if (trackPoints.isNotEmpty) {
            _moveMapToLocation(LatLng(stop.lat, stop.lng));
          }
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
      // 先计算有效的停留点数量（排除终点和起点）
      int validStopCount = 0;
      for (int i = 0; i < stopPoints.length; i++) {
        final stop = stopPoints[i];
        bool isEndPoint = stop.pointType == 'end' || stop.serialNumber == '终';
        bool isStartPoint = stop.pointType == 'start' || stop.serialNumber == '起';
        if (!isEndPoint && !isStartPoint) {
          validStopCount++;
        }
      }
      
      int stayPointIndex = validStopCount; // 从最大序号开始倒序
      
      for (int i = 0; i < stopPoints.length; i++) {
        final stop = stopPoints[i];
        
        // 根据 pointType 和 serialNumber 判断点的类型
        bool isEndPoint = stop.pointType == 'end' || stop.serialNumber == '终';
        bool isStartPoint = stop.pointType == 'start' || stop.serialNumber == '起';
        
        // 跳过终点和起点，只显示中间停留点
        if (isEndPoint || isStartPoint) {
          continue;
        }
        
        try {
          String title = '停留点 ${stayPointIndex}';
          BitmapDescriptor? icon;
          
          // 创建自定义停留点图标
          try {
            icon = await _createCustomStayPointIcon(stayPointIndex.toString());
            DebugUtil.success(' 停留点 ${stayPointIndex} 自定义图标创建成功');
          } catch (iconError) {
            DebugUtil.warning(' 停留点 ${stayPointIndex} 自定义图标创建失败，使用默认标记: $iconError');
            // 降级方案：使用粉色默认标记
            try {
              icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
            } catch (fallbackError) {
              DebugUtil.warning(' 默认标记也创建失败: $fallbackError');
            icon = null; // 使用系统默认标记
            }
          }
          
          // 创建标记，根据icon是否可用决定是否设置
          final marker = icon != null 
            ? Marker(
                position: LatLng(stop.lat, stop.lng),
                icon: icon,
                anchor: const Offset(0.5, 0.5), // 设置锚点为图片中心
                onTap: (String markerId) {
                  DebugUtil.info('点击了停留点: $title - ${stop.locationName}');
                  // 触发自定义信息窗口回调
                  final position = LatLng(stop.lat, stop.lng);
                  onStayPointTapped?.call(stop, position);
                  // 点击标记时，可以跳转到对应的轨迹回放位置
                  if (trackPoints.isNotEmpty) {
                    _moveMapToLocation(position);
                  }
                },
              )
            : Marker(
                position: LatLng(stop.lat, stop.lng),
                anchor: const Offset(0.5, 0.5), // 设置锚点为图片中心
                onTap: (String markerId) {
                  DebugUtil.info('点击了停留点: $title - ${stop.locationName}');
                  // 触发自定义信息窗口回调
                  final position = LatLng(stop.lat, stop.lng);
                  onStayPointTapped?.call(stop, position);
                  // 点击标记时，可以跳转到对应的轨迹回放位置
                  if (trackPoints.isNotEmpty) {
                    _moveMapToLocation(position);
                  }
                },
              );
          
          tempMarkers.add(marker);
          stayPointIndex--; // 倒序递减
          DebugUtil.success(' 停留点 ${stayPointIndex + 1} ($title) 标记创建成功');
        } catch (e) {
          DebugUtil.error(' 停留点 ${stayPointIndex} 标记创建失败: $e，尝试降级方案');
          // 降级方案：使用最基本的标记（完全不设置图标）
          try {
            String title = '停留点 ${stayPointIndex}';
            
            final fallbackMarker = Marker(
              position: LatLng(stop.lat, stop.lng),
              // 完全不设置icon，让系统使用最基础的默认标记
              onTap: (String markerId) {
                DebugUtil.info('点击了停留点: $title - ${stop.locationName}');
                // 触发自定义信息窗口回调
                final position = LatLng(stop.lat, stop.lng);
                onStayPointTapped?.call(stop, position);
                if (trackPoints.isNotEmpty) {
                  _moveMapToLocation(position);
                }
              },
            );
            
            tempMarkers.add(fallbackMarker);
            stayPointIndex--; // 倒序递减
            DebugUtil.success(' 停留点 ${stayPointIndex + 1} ($title) 降级标记创建成功');
          } catch (fallbackError) {
            DebugUtil.error(' 停留点 ${stayPointIndex} 降级方案也失败: $fallbackError，跳过此点');
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
      } else {
        DebugUtil.error(' 没有成功创建任何停留点标记');
      }
    } catch (e) {
      DebugUtil.error(' 停留点标记更新过程失败: $e');
      
      // 最后的降级方案：创建一个基础彩色标记
      try {
        if (stopPoints.isNotEmpty) {
          stayMarkers.add(Marker(
            position: LatLng(stopPoints.first.lat, stopPoints.first.lng),
            // 使用彩色默认图标
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(
              title: '位置点',
              snippet: stopPoints.first.locationName ?? '未知位置',
            ),
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
    
    // 先计算有效的停留点数量（排除终点和起点）
    int validStopCount = 0;
    for (int i = 0; i < stopPoints.length; i++) {
      final stop = stopPoints[i];
      if (stop.lat == 0.0 || stop.lng == 0.0) continue;
      bool isEndPoint = stop.pointType == 'end' || stop.serialNumber == '终';
      bool isStartPoint = stop.pointType == 'start' || stop.serialNumber == '起';
      if (!isEndPoint && !isStartPoint) {
        validStopCount++;
      }
    }
    
    int stayPointIndex = validStopCount; // 从最大序号开始倒序
    
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
      
      String title = '停留点 ${stayPointIndex}';
      
      // 使用最简单的默认标记
      final marker = Marker(
        position: LatLng(stop.lat, stop.lng),
        infoWindow: InfoWindow(
          title: title,
          snippet: '${stop.locationName ?? '未知位置'}\n${stop.startTime ?? ''} ${stop.duration?.isNotEmpty == true ? '停留${stop.duration}' : ''}',
        ),
        onTap: (String markerId) {
          DebugUtil.info('点击了停留点: $title - ${stop.locationName}');
          if (trackPoints.isNotEmpty) {
            _moveMapToLocation(LatLng(stop.lat, stop.lng));
          }
        },
      );
      
      stayMarkers.add(marker);
      stayPointIndex--; // 倒序递减
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
        final currentMarker = icon != null
          ? Marker(
              position: currentPosition.value!,
              icon: icon,
              anchor: const Offset(0.5, 0.5), // 设置锚点为图片中心
              infoWindow: InfoWindow(
                title: '当前位置',
                snippet: '轨迹回放当前位置',
              ),
              onTap: (String markerId) {
                DebugUtil.info('点击了当前位置: $markerId');
              },
            )
          : Marker(
              position: currentPosition.value!,
              anchor: const Offset(0.5, 0.5), // 设置锚点为图片中心
              infoWindow: InfoWindow(
                title: '当前位置',
                snippet: '轨迹回放当前位置',
              ),
              onTap: (String markerId) {
                DebugUtil.info('点击了当前位置: $markerId');
              },
            );
        
        markers.add(currentMarker);
      } catch (e) {
        DebugUtil.error(' 创建当前位置标记失败: $e');
        // 降级：使用无图标的简单标记
        try {
          markers.add(
            Marker(
              position: currentPosition.value!,
              anchor: const Offset(0.5, 0.5), // 设置锚点为图片中心
              infoWindow: InfoWindow(
                title: '当前位置',
                snippet: '轨迹回放当前位置',
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
  
  /// 更新播放状态（距离和时间）
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
  }
  
  /// 跳转到指定索引（用于进度条拖动）
  void seekToIndex(int newIndex) {
    if (trackPoints.isEmpty) return;
    
    final safeIndex = newIndex.clamp(0, trackPoints.length - 1);
    currentReplayIndex.value = safeIndex;
    
    // 更新当前位置
    currentPosition.value = trackPoints[safeIndex];
    _moveMapToLocation(trackPoints[safeIndex]);
    
    // 更新累计距离
    _cumulativeDistance = _calculateCumulativeDistance(0, safeIndex);
    
    // 如果正在播放，更新时间基准
    if (isReplaying.value && _replayStartTime != null) {
      // 根据当前进度调整开始时间，让时间显示更准确
      final progress = safeIndex / (trackPoints.length - 1);
      final estimatedTotalSeconds = 300; // 假设总时长5分钟，可以根据实际情况调整
      final currentSeconds = (progress * estimatedTotalSeconds).round();
      _replayStartTime = DateTime.now().subtract(Duration(seconds: currentSeconds));
    }
    
    _updateReplayStatus();
  }

  /// 开始回放
  void startReplay() {
    if (trackPoints.isEmpty) {
      CustomToast.show(Get.context!, '暂无轨迹数据可回放');
      return;
    }
    isReplaying.value = true;
    showFullPlayer.value = true; // 显示完整播放器
    _currentStep = 0;

    // 确保currentReplayIndex在有效范围内
    currentReplayIndex.value = currentReplayIndex.value.clamp(0, trackPoints.length - 1);

    // 设置初始位置
    if (currentPosition.value == null && trackPoints.isNotEmpty) {
      currentPosition.value = trackPoints[currentReplayIndex.value];
    }
    
    // 初始化播放时间跟踪
    _replayStartTime = DateTime.now();
    // 计算已经播放过的距离（从开始到当前索引）
    _cumulativeDistance = _calculateCumulativeDistance(0, currentReplayIndex.value);
    _updateReplayStatus();

    _replayTimer?.cancel();
    // 根据播放速度调整定时器间隔，使动画更流畅
    final intervalMs = (30 / replaySpeed.value).round(); // 从50ms改为30ms，让动画更流畅
    _replayTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      // 检查轨迹点是否仍然有效
      if (trackPoints.isEmpty) {
        stopReplay();
        return;
      }
      
      // 确保currentReplayIndex在有效范围内
      if (currentReplayIndex.value >= trackPoints.length) {
        currentReplayIndex.value = trackPoints.length - 1;
        stopReplay();
        return;
      }
      
      if (currentReplayIndex.value < trackPoints.length - 1) {
        final currentIndex = currentReplayIndex.value.clamp(0, trackPoints.length - 2);
        final startPoint = trackPoints[currentIndex];
        final endPoint = trackPoints[currentIndex + 1];

        // 计算插值进度，避免除零
        final progress = animationSteps > 0 ? _currentStep / animationSteps : 0.0;

        // 使用平滑插值算法，让动画更自然
        final smoothProgress = _applySmoothEasing(progress.clamp(0.0, 1.0));

        // 更新当前位置（插值）
        currentPosition.value = _interpolatePosition(
          startPoint,
          endPoint,
          smoothProgress,
        );

        // 平滑移动地图视角，添加一些延迟避免过于频繁
        if (_currentStep % 3 == 0) { // 每3步更新一次地图位置
          _moveMapToLocation(currentPosition.value!);
        }

        _currentStep++;

        // 到达下一个点
        if (_currentStep >= animationSteps) {
          _currentStep = 0;
          currentReplayIndex.value++;
          // 更新累计距离和播放状态
          _cumulativeDistance = _calculateCumulativeDistance(0, currentReplayIndex.value);
          _updateReplayStatus();
          
          // 检查是否经过停留点，给予提示
          _checkPassingStopPoint(currentReplayIndex.value);
        }
      } else {
        // 到达终点
        currentPosition.value = trackPoints.last;
        _showReplayCompleteMessage();
        stopReplay();
      }
    });
  }
  
  /// 应用平滑缓动函数，让动画更自然
  double _applySmoothEasing(double t) {
    // 使用ease-in-out缓动函数
    return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
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
    CustomToast.show(
      Get.context!, 
      '轨迹回放完成！总距离：${moveDistance.value}，总停留：${stayDuration.value}'
    );
  }

  /// 暂停
  void pauseReplay() {
    isReplaying.value = false;
    _replayTimer?.cancel();
  }

  /// 停止并重置
  void stopReplay() {
    isReplaying.value = false;
    _replayTimer?.cancel();
    currentReplayIndex.value = 0;
    _currentStep = 0;
    replaySpeed.value = 1.0; // 重置播放速度
    // 重置播放状态
    _replayStartTime = null;
    _cumulativeDistance = 0.0;
    replayDistance.value = "";
    replayTime.value = "00:00:00";
    // 重置位置
    if (trackPoints.isNotEmpty) {
      currentPosition.value = trackPoints.first;
      _moveMapToLocation(trackPoints.first);
    }
  }
  
  /// 关闭播放器并重置动画
  void closePlayer() {
    stopReplay(); // 停止当前播放
    showFullPlayer.value = false; // 隐藏完整播放器
    currentPosition.value = null; // 清除当前位置标记
    // 重置地图视图到初始状态
    if (trackPoints.isNotEmpty) {
      _moveMapToLocation(trackPoints.first);
    }
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

  /// 已移除虚拟数据加载方法，改为统一使用真实API数据
  
  /// 已移除虚拟数据生成方法，改为统一使用真实API数据

  @override
  void onClose() {
    DebugUtil.info('🧹 开始清理轨迹页面资源和缓存...');
    
    // 重置地图就绪状态
    isMapReady.value = false;
    
    // 安全地清理所有定时器和资源
    try {
      _replayTimer?.cancel();
      _replayTimer = null;
    } catch (e) {
      debugPrint('清理replayTimer时出错: $e');
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
