import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/pages/track/stay_point.dart';
import 'package:kissu_app/model/location_model/location_model.dart';
import 'package:intl/intl.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';
import 'package:kissu_app/utils/debug_util.dart';
import 'package:kissu_app/services/location_permission_manager.dart'; 
import 'package:kissu_app/utils/user_manager.dart';

// 导入各个管理器
import 'package:kissu_app/pages/track/managers/track_map_manager.dart';
import 'package:kissu_app/pages/track/managers/track_user_manager.dart';
import 'package:kissu_app/pages/track/managers/track_data_manager.dart';
import 'package:kissu_app/pages/track/managers/track_ui_manager.dart';
import 'package:kissu_app/pages/track/managers/track_marker_manager.dart';
import 'package:kissu_app/services/analytics/analytics_helper.dart';

// 导出初始坐标信息类，供外部使用
export 'package:kissu_app/pages/track/managers/track_marker_manager.dart'
    show InitialCoordinateInfo;

/// 轨迹页面控制器 - 协调器模式
/// 负责协调各个管理器，处理业务逻辑
class TrackController extends GetxController with GetTickerProviderStateMixin {
  /// 各个管理器实例
  late final TrackMapManager _mapManager;
  late final TrackUserManager _userManager;
  late final TrackDataManager _dataManager;
  late final TrackUIManager _uiManager;
  late final TrackMarkerManager _markerManager;

  /// 数据版本控制，确保异步操作的一致性
  int _dataVersion = 0;

 

  /// 构造函数
  TrackController() {
    // 初始化各个管理器
    _mapManager = TrackMapManager();
    _userManager = TrackUserManager();
    _dataManager = TrackDataManager();
    _uiManager = TrackUIManager();
    _markerManager = TrackMarkerManager();
  }

  /// ===== 对外暴露的属性（保持原有接口不变） =====

  // 来自 UserManager
  RxString get myAvatar => _userManager.myAvatar;
  RxString get partnerAvatar => _userManager.partnerAvatar;
  RxBool get isBindPartner => _userManager.isBindPartner; 

  // 来自 DataManager
  RxInt get isOneself => _dataManager.currentUserType; // 当前显示的用户类型
  Rx<LocationResponse?> get mySelfData => _dataManager.myselfData; // 自己的数据
  Rx<LocationResponse?> get partnerData => _dataManager.partnerData; // 另一半的数据
  Rx<LocationResponse?> get locationData =>
      Rx<LocationResponse?>(_dataManager.currentData); // 当前显示的数据
  RxBool get hasValidTrackData => _dataManager.hasValidTrackData;
  Rx<DateTime> get selectedDate => _dataManager.selectedDate;
  RxInt get stayCount => _dataManager.stayCount;
  RxString get stayDuration => _dataManager.stayDuration;
  RxString get moveDistance => _dataManager.moveDistance;
  RxBool get isLoading => _dataManager.isLoading;
  List<LatLng> get trackPoints => _dataManager.trackPoints;
  List<StayPoint> get stopPoints => _dataManager.stopPoints;

  // 来自 MapManager
  RxBool get isMapReady => _mapManager.isMapReady;
  RxInt get mapType => _mapManager.mapType;
  AMapController? get mapController => _mapManager.mapController;

  // 来自 UIManager
  RxBool get isBackButtonRotated => _uiManager.isBackButtonRotated;
  AnimationController get backButtonAnimationController =>
      _uiManager.backButtonAnimationController;
  Animation<double> get backButtonRotationAnimation =>
      _uiManager.backButtonRotationAnimation;
  RxInt get selectedDateIndex => _uiManager.selectedDateIndex;
  RxList<String> get recentDays => _uiManager.recentDays;
  RxInt get selectedDayIndex => _uiManager.selectedDayIndex;
  RxDouble get sheetPercent => _uiManager.sheetPercent;

  // 来自 MarkerManager
  RxList<Marker> get stopMarkers => _markerManager.stopMarkers;
  RxList<Marker> get trackStartEndMarkers =>
      _markerManager.trackStartEndMarkers;
  RxList<Circle> get highlightCircles => _markerManager.highlightCircles;
  RxList<StopRecord> get stopRecords => _markerManager.stopRecords;
  Marker? get tempInfoWindowMarker => _markerManager.tempInfoWindowMarker;

  @override
  void onInit() {
    super.onInit();

 

    // 手动调用继承 GetxController 的管理器的 onInit() 方法
    // 因为它们是通过构造函数创建的，不会自动调用 onInit()
    _uiManager.onInit();

    // 初始化各管理器的依赖关系
    _setupManagerDependencies();

    // 确保初始状态下播放控制器可见
    sheetPercent.value = 0.3;

    // 重置地图就绪状态
    isMapReady.value = false;

    // 初始化日期选择器索引（默认选择今天，索引为6）
    selectedDateIndex.value = 6;

    // 加载用户信息（先用本地数据）
    _userManager.loadUserInfo();

    // 🎯 根据绑定状态设置默认显示用户
    // 默认已经是显示自己（currentUserType = 1），只有已绑定时才切换到显示另一半
    if (_userManager.isBindPartner.value) {
      _dataManager.currentUserType.value = 0; // 显示另一半
      logDebug('🎯 已绑定，切换到显示另一半的轨迹');
    } else {
      logDebug('🎯 未绑定，保持显示自己的轨迹');
    }

    // 然后静默刷新用户信息
    _silentRefreshUserInfo();

    // 请求定位权限并加载初始数据
    _requestLocationPermissionAndLoadData();
  }

  @override
  void onReady() {
    super.onReady();
    // 页面准备就绪时，确保已经静默刷新
  }

  /// 页面重新获得焦点时的回调（从其他页面返回时会调用）
  void onPageResumed() {
    logDebug('🗺️ 足迹页面重新获得焦点，静默刷新用户信息');
    // 先用本地数据（已经在onInit中加载）
    // 然后静默刷新用户信息
    _silentRefreshUserInfo();
  }

  /// 静默刷新用户信息（不阻塞UI）
  Future<void> _silentRefreshUserInfo() async {
    try {
      logDebug('🔄 足迹页面：静默刷新用户信息');
      final success = await UserManager.refreshUserInfo();
      if (success) {
        // 刷新成功后重新加载本地数据到UI
        _userManager.loadUserInfo();

        // 🎯 刷新后重新检查绑定状态，确保显示正确的用户
        if (_userManager.isBindPartner.value &&
            _dataManager.currentUserType.value != 0) {
          _dataManager.currentUserType.value = 0; // 已绑定：切换到显示另一半
          logDebug('🎯 刷新后发现已绑定，切换到显示另一半的轨迹');
        } else if (!_userManager.isBindPartner.value &&
            _dataManager.currentUserType.value != 1) {
          _dataManager.currentUserType.value = 1; // 未绑定：切换到显示自己
          logDebug('🎯 刷新后发现未绑定，切换到显示自己的轨迹');
        }
      }
    } catch (e) {
      logError('❌ 足迹页面：静默刷新用户信息失败: $e');
    }
  }

  /// 设置管理器之间的依赖关系
  void _setupManagerDependencies() {
    // 设置 MapManager 的依赖
    // MapManager 相对独立，不需要其他依赖

    // 设置 MarkerManager 的依赖
    _markerManager.setDependencies(
      getMapController: () => _mapManager.mapController,
      isMapReady: () => _mapManager.isMapReady.value,
      getCurrentUserAvatar: () =>
          _userManager.getUserAvatar(_dataManager.currentUserType.value),
      onMapMove: _mapManager.moveMapToLocation,
      expandToMiddlePosition: _uiManager.expandToMiddlePosition,
      collapseToMinPosition: _uiManager.collapseToMinPosition,
      collapseToBottomPosition: _uiManager.collapseToBottomPosition,
    );
  }

  /// ===== 地图相关方法 =====

  /// 地图创建完成回调
  void onMapCreated(AMapController controller) {
    _mapManager.onMapCreated(controller, _markerManager.hideAllInfoWindows);

    // 延迟处理初始坐标和自动显示InfoWindow
    Future.delayed(const Duration(milliseconds: 300), () {
      // 先检查是否需要切换用户
      _checkAndSwitchUserForInitialCoordinates();
    });
  }

  /// 高德地图PlatformView销毁时回调，释放Controller引用避免继续发送指令
  void onMapDisposed() {
    logDebug('🧹 足迹页面：地图PlatformView已销毁，清理控制器引用');
    _mapManager.onMapDisposed();
  }

  /// 检查并切换用户（从定位页面跳转时）
  void _checkAndSwitchUserForInitialCoordinates() {
    final initialInfo = _markerManager.getInitialCoordinateInfo();
    if (initialInfo == null) {
      // 没有初始坐标信息，不需要切换
      return;
    }

    final targetUserType = initialInfo.targetUserType;
    if (targetUserType == null) {
      // 没有目标用户类型，不需要切换
      logDebug('🎯 没有目标用户类型信息，直接显示InfoWindow');
      Future.delayed(const Duration(milliseconds: 200), () {
        _markerManager.checkAutoShowInfoWindow(stopPoints);
      });
      return;
    }

    logDebug(
      '🎯 检查用户切换：目标用户类型=$targetUserType，当前用户类型=${isOneself.value}',
    );

    // 如果当前显示的用户类型不是目标用户类型，需要切换
    if (isOneself.value != targetUserType) {
      logDebug(
        '🔄 需要切换用户：从${isOneself.value == 1 ? "自己" : "另一半"}切换到${targetUserType == 1 ? "自己" : "另一半"}',
      );

      // 切换用户类型
      _dataManager.switchUser(targetUserType);

      // 清除旧数据
      _clearDataForAvatarSwitch();

      // 重新加载目标用户的数据
      Future.microtask(() async {
        await _loadDataAsync();

        // 数据加载完成后，处理初始坐标和自动显示InfoWindow
        Future.delayed(const Duration(milliseconds: 500), () {
          _markerManager.checkAutoShowInfoWindow(stopPoints);
        });
      });
    } else {
      logDebug('✅ 用户类型已匹配，无需切换');

      // 直接处理初始坐标和自动显示InfoWindow
      Future.delayed(const Duration(milliseconds: 200), () {
        _markerManager.checkAutoShowInfoWindow(stopPoints);
      });
    }
  }

  /// 设置地图就绪状态
  void setMapReady(bool ready) {
    _mapManager.setMapReady(ready);
  }

  /// 切换地图类型
  void switchMapType(int type) {
    _mapManager.switchMapType(type);
  }

  /// 地图初始相机位置
  CameraPosition get initialCameraPosition {
    
    // 如果已有轨迹数据，使用计算的最佳位置
    if (trackPoints.isNotEmpty) {
      final optimalPosition = _mapManager.calculateOptimalCameraPosition(
        trackPoints,
      );
      if (optimalPosition != null) {
        return optimalPosition;
      }
    }

    // 使用数据管理器的默认位置
    return _dataManager.getDefaultCameraPosition();
  }

  /// ===== 用户相关方法 =====

  /// 切换查看用户（自己/另一半）
  void switchUser() {
    final newUserType = isOneself.value == 1 ? 0 : 1;
    _dataManager.switchUser(newUserType);
    _clearDataForAvatarSwitch();
    _updateMapAfterUserSwitch();
  }

  /// 头像点击时切换用户视角（优化版本）
  void onAvatarTapped(bool isMyself) {
    // 埋点：头像切换
    AnalyticsHelper.trackTrackAvatarChange(
      avatarName: isMyself ? 'mine' : 'partner',
    );
    
    logDebug('🎯 头像点击开始 - isMyself: $isMyself');

    // 计算目标用户类型
    final targetUserType = isMyself ? 1 : 0;

    // 如果点击的是当前用户，不做任何处理
    if (isOneself.value == targetUserType) {
      logDebug('点击的是当前用户头像，不切换');
      return;
    }

    // 📱 每次切换头像时，将下半屏恢复到底部吸顶位置
    logDebug('💡 切换头像，恢复下半屏到底部吸顶位置');
    _uiManager.collapseToBottomPosition();

    // 执行用户切换
    logDebug('🔄 切换到${isMyself ? "自己" : "另一半"}');
    _dataManager.switchUser(targetUserType);
    _clearDataForAvatarSwitch();
    _updateMapAfterUserSwitch();
  }

  /// 获取实际的绑定状态（不受当前查看用户影响）
  bool getActualBindStatus() {
    return _userManager.isBindPartner.value;
  }

  /// ===== UI相关方法 =====

  /// 处理旋转状态下的返回按钮点击
  void handleBackButtonTap([ScrollController? scrollController]) {
    // 埋点：返回按钮点击
    AnalyticsHelper.trackTrackBack();
    
    _uiManager.handleBackButtonTap(scrollController);
  }

  /// 设置底部面板控制器
  void setDraggableController(DraggableScrollableController controller) {
    _uiManager.setDraggableController(controller);
  }

  /// 设置停留点列表的ScrollController
  void setListScrollController(ScrollController? controller) {
    _uiManager.setListScrollController(controller);
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
    _markerManager.setInitialCoordinates(
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      duration: duration,
      startTime: startTime,
      endTime: endTime,
      targetUserType: targetUserType,
    );
  }

  /// ===== 数据相关方法 =====

  /// 选择日期
  void selectDate(DateTime date) {
    logDebug(
      '📅 TrackController.selectDate 被调用: ${DateFormat('yyyy-MM-dd').format(date)}',
    );

    // 保存之前的日期，用于对比
    final previousDate = selectedDate.value;

    // 更新选中的日期
    selectedDate.value = date;

    // 计算索引（0-6，对应最近7天）
    final today = DateTime.now();
    final difference = today.difference(date).inDays;
    final index = 6 - difference.clamp(0, 6);
    selectedDateIndex.value = index;

    logDebug('📅 日期索引更新为: $index');

    // 只有日期真正改变时才加载新数据
    if (previousDate.year != date.year ||
        previousDate.month != date.month ||
        previousDate.day != date.day) {
      // 🎯 立即设置加载状态，确保UI响应
      _dataManager.isLoading.value = true;

      // 立即清空数据，给用户即时反馈
      _clearDataInstantly();

      // 延迟加载新数据，确保UI有时间更新
      Future.delayed(const Duration(milliseconds: 100), () {
        _loadDataAsync();
      });
    }
  }

  /// ===== 轨迹回放相关方法 =====

  /// ===== 标记相关方法 =====

  /// 清除所有高亮圆圈
  void clearAllHighlightCircles() {
    _markerManager.clearAllHighlightCircles();
  }

  /// 清除地图高亮
  void clearMapHighlights() {
    _markerManager.clearMapHighlights();
  }

  /// 绘制高亮圆圈
  void drawHighlightCircle(LatLng center) {
    _markerManager.drawHighlightCircle(center);
  }

  /// 获取所有轨迹线
  Set<Polyline> get polylines {
    if (!hasValidTrackData.value || trackPoints.isEmpty) {
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
      logError('创建轨迹线失败: $e');
      return {};
    }
  }

  /// 获取所有标记
  Set<Marker> get markers {
    final markers = <Marker>[];

    try {
      // 使用 MarkerManager 获取所有标记
      markers.addAll(_markerManager.getAllMarkers());

      logDebug('标记总数: ${markers.length}');
    } catch (e) {
      logError('获取标记失败: $e');
    }

    return markers.toSet();
  }

  /// ===== 内部方法 =====

  /// 请求定位权限并加载数据
  Future<void> _requestLocationPermissionAndLoadData() async {
    try {
      logDebug('轨迹页面检查权限状态...');

      final hasPermission = await LocationPermissionManager.instance
          .requestLocationPermission();

      if (hasPermission) {
        logDebug('轨迹页面权限已授予，加载数据');
        Future.microtask(() => _loadDataAsync());
      } else {
        logWarning('轨迹页面权限未授予');
      }
    } catch (e) {
      logError('轨迹页面权限请求失败: $e');
      CustomToast.show(Get.context!, '定位权限请求失败');
    }
  }

  /// 异步加载位置数据
  Future<void> _loadDataAsync() async {
    logDebug('📍 开始加载数据，当前 isLoading = ${isLoading.value}');

    // 增加数据版本号，确保数据一致性
    _dataVersion++;
    final currentVersion = _dataVersion;

    try {
      // 并行加载两个用户的数据
      await _dataManager.loadBothUsersData(date: selectedDate.value);

      // 检查版本号，如果不匹配说明有新的加载请求，放弃当前结果
      if (currentVersion != _dataVersion) {
        logWarning('数据版本不匹配，放弃当前加载结果');
        return;
      }

      // 更新头像（从第一个有数据的响应中获取）
      final dataForAvatar =
          _dataManager.myselfData.value ?? _dataManager.partnerData.value;
      if (dataForAvatar != null) {
        _userManager.updateAvatarsFromApiData(dataForAvatar);
      }

      // 更新地图和标记（内部会调用 _createMarkers）
      _updateMapAfterDataLoad();

      // 自动调整地图视图
      await _mapManager.fitMapToTrackPoints(
        trackPoints: trackPoints,
        stopPoints: stopPoints,
        locationData: _dataManager.currentData,
      );
    } catch (e) {
      logError('加载数据失败: $e');
    }
  }

  /// 数据加载完成后更新地图和标记
  Future<void> _updateMapAfterDataLoad() async {
    logDebug('🗺️ 数据加载完成，更新地图');

    // 重新创建标记
    await _createMarkers();

    // 强制地图更新
    _mapManager.forceMapUpdate(
      trackPoints: trackPoints,
      stopPoints: stopPoints,
      locationData: _dataManager.currentData,
    );
  }

  /// 用户切换后更新地图和标记
  Future<void> _updateMapAfterUserSwitch() async {
    logDebug('🔄 用户切换完成，更新地图和标记');

    // 重新创建标记
    await _createMarkers();

    // 强制地图更新
    _mapManager.forceMapUpdate(
      trackPoints: trackPoints,
      stopPoints: stopPoints,
      locationData: _dataManager.currentData,
    );

    // 移动地图到合适位置
    if (trackPoints.isNotEmpty) {
      await _mapManager.fitMapToTrackPoints(
        trackPoints: trackPoints,
        stopPoints: stopPoints,
        locationData: _dataManager.currentData,
      );
    }
  }

  /// 创建所有标记
  Future<void> _createMarkers() async {
    try {
      // 获取起点终点坐标
      final startPoint = _dataManager.getStartPoint();
      final endPoint = _dataManager.getEndPoint();

      // 创建停留点标记（排除与起终点重复的位置）
      await _markerManager.createStopMarkers(
        stopPoints: stopPoints,
        onStopPointTap: _markerManager.handleStopPointTap,
        startPoint: startPoint,
        endPoint: endPoint,
      );

      // 创建起终点标记
      await _markerManager.createTrackStartEndMarkers(
        startPoint: startPoint,
        endPoint: endPoint,
      );

      // 更新停留记录列表
      _markerManager.updateStopRecordsFromApiData(_dataManager.currentData);

      logDebug('所有标记创建完成');
    } catch (e) {
      logError('创建标记失败: $e');
    }
  }

  /// 立即清空数据，给用户即时反馈
  void _clearDataInstantly() {
    logDebug('🧹 [ClearInstantly] 开始立即清空数据（日期切换）...');

    // 清空地图标记
    _markerManager.clearMapImmediately();

    // 重置播放状态

    // 清空数据
    _dataManager.clearAllData();

    logDebug('✅ [ClearInstantly] 数据清空完成');
  }

  /// 智能清空数据 - 头像切换专用
  void _clearDataForAvatarSwitch() {
    logDebug('🧹 [ClearAvatar] 开始清空数据（头像切换）...');

    // 立即清理地图
    _markerManager.clearMapImmediately();

    // 清空轨迹线状态
    hasValidTrackData.value = false;

    logDebug('✅ [ClearAvatar] 清空完成');
  }

  /// 移动地图到停留点并高亮显示
  /// 从停留点列表点击时调用，会收起下半屏
  Future<void> moveToStopPointWithHighlight(
    BuildContext context,
    double latitude,
    double longitude, {
    dynamic stopPoint,
    ScrollController? scrollController,
  }) async {
    try {
      final targetLocation = LatLng(latitude, longitude);

      logDebug('🎯 [StopPointClick] 开始执行完整流程...');

      // 设置动画锁，防止用户在地图变化时滑动面板造成冲突
      _mapManager.setAnimationLock(true);

      // 0. 先将ScrollView归位（滚动到顶部）
      // 如果没有传入scrollController，尝试从UIManager获取
      final actualScrollController =
          scrollController ?? _uiManager.getListScrollController();
      if (actualScrollController != null && actualScrollController.hasClients) {
        try {
          await actualScrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          logDebug('🎯 [StopPointClick] 步骤0: ScrollView归位到顶部');
        } catch (e) {
          logWarning('⚠️ ScrollView归位失败: $e');
        }
        // 等待ScrollView归位动画完成
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // 1. 收起下半屏到底部吸顶位置
      _uiManager.collapseToBottomPosition();
      logDebug('🎯 [StopPointClick] 步骤1: 收起下半屏到底部吸顶位置');

      // 2. 等待面板收起动画
      await Future.delayed(const Duration(milliseconds: 100));

      // 3. 清除之前的所有地图高亮
      _markerManager.clearMapHighlights();
      logDebug('🎯 [StopPointClick] 步骤2: 清除旧高亮');

      // 4. 等待清除操作完成
      await Future.delayed(const Duration(milliseconds: 100));

      // 5. 移动地图到停留点
      if (isMapReady.value && mapController != null) {
        try {
          // 注意：不要 await moveCamera，它可能永远不会完成
          mapController!.moveCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: targetLocation, zoom: 18.0),
            ),
          );
          logDebug('🎯 [StopPointClick] 步骤3: 移动相机到目标点');
        } catch (e) {
          logError('移动地图到停留点失败: $e');
        }
      }

      // 6. 等待相机移动完成
      await Future.delayed(const Duration(milliseconds: 500));

      // 7. 显示对应停留点的 InfoWindow 并绘制高亮圆圈
      if (stopPoint != null) {
        try {
          await _markerManager.showInfoWindowForStopPoint(stopPoint);
          logDebug('🎯 [StopPointClick] 步骤4: 显示InfoWindow');
        } catch (e) {
          logError('❌ 显示InfoWindow失败: $e');
        }

        // 8. 等待InfoWindow显示完成
        await Future.delayed(const Duration(milliseconds: 200));

        // 9. 绘制高亮圆圈
        _markerManager.drawHighlightCircle(targetLocation);
        logDebug('🎯 [StopPointClick] 步骤5: 绘制高亮圆圈');
      } else {
        // 没有stopPoint时，只绘制高亮圆圈
        await Future.delayed(const Duration(milliseconds: 300));
        _markerManager.drawHighlightCircle(targetLocation);
        logDebug('🎯 [StopPointClick] 步骤4: 绘制高亮圆圈');
      }

      logDebug('✅ [StopPointClick] 完整流程执行完成！');

      // 释放动画锁
      await Future.delayed(const Duration(milliseconds: 500));
      _mapManager.setAnimationLock(false);
    } catch (e) {
      logError('❌ [StopPointClick] 执行失败: $e');
      _mapManager.setAnimationLock(false);
    }
  }

  /// 设置动画锁状态
  void setAnimationLock(bool isLocked) {
    _mapManager.setAnimationLock(isLocked);
  }

  /// 刷新当前用户数据
  Future<void> refreshCurrentUserData() async {
    logDebug('🔄 外部刷新请求: 重新加载当前日期的轨迹数据');

    try {
      await _loadDataAsync();
      logDebug('✅ 轨迹数据刷新完成');
    } catch (e) {
      logError('❌ 轨迹数据刷新失败: $e');
    }
  }

  @override
  void onClose() {
    logDebug('🧹 开始清理轨迹页面资源和缓存...');

 

    // 清理各管理器资源
    _mapManager.dispose();
    _dataManager.clearCache();
    _markerManager.clearAllMarkers();
    _markerManager.dispose(); // 🚀 清理防抖定时器

    // 手动调用继承 GetxController 的管理器的 onClose() 方法
    _uiManager.onClose();

    logDebug('✅ 轨迹页面资源清理完成');
    super.onClose();
  }

  
}
