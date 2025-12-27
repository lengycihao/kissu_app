import 'dart:async';
import 'dart:math' as dart_math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/network/public/location_api.dart';
import 'package:kissu_app/model/location_model/location_model.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';
import 'package:kissu_app/services/simple_location_service.dart';
import 'package:kissu_app/services/location_permission_manager.dart'; 
import 'package:permission_handler/permission_handler.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog.dart';
import 'package:kissu_app/pages/mine/sub_pages/question_page.dart';
import 'package:kissu_app/pages/mine/sub_pages/question_page_info.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/services/map_preload_service.dart';
import 'package:kissu_app/network/public/setting_api.dart';
import 'package:kissu_app/model/setting/common_question_model/common_question_model.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'widgets/location_tips_manager.dart';
import 'services/marker_builder.dart';
import 'services/location_data_helper.dart';
import 'package:kissu_app/pages/location/location_detail_page.dart';

class LocationV2Controller extends GetxController
    with GetTickerProviderStateMixin {
  final isOneself = 0.obs; // 默认看另一半
  final myAvatar = "".obs;
  final partnerAvatar = "".obs;
  final myFace = Rx<Face?>(null);
  final partnerFace = Rx<Face?>(null);
  final isBindPartner = false.obs;
  final isVip = false.obs;
  final partnerOnlineStatus = Rx<OnlineStatus?>(null);
  final myLocation = Rx<LatLng?>(null);
  final partnerLocation = Rx<LatLng?>(null);
  final actualMyLocation = Rx<LatLng?>(null);
  final actualPartnerLocation = Rx<LatLng?>(null);
  final currentHeading = Rx<double?>(null); // 当前方向角度（度）
  final isBackButtonRotated = false.obs;
  final isSwitchingView = false.obs;
  final distance = "".obs;
  final updateTime = "".obs;
  final currentLocationText = "位置信息加载中...".obs;
  final myDeviceModel = "未知".obs;
  final myBatteryLevel = "未知".obs;
  final myNetworkName = "未知".obs;
  final speed = "0m/s".obs;
  final isWifi = "1".obs;
  final locationTime = "".obs;
  final weatherIcon = "".obs;
  final weather = "".obs;
  final RxList<LocationRecord> locationRecords = <LocationRecord>[].obs;
  final Rx<LocationResponseModel?> locationData = Rx<LocationResponseModel?>(
    null,
  );
  final sheetPercent = 0.3.obs;
  final isLoading = false.obs;
  final mapType = 1.obs;

 

  late AnimationController backButtonAnimationController;
  late Animation<double> backButtonRotationAnimation;
  late AnimationController switchTransitionController;
  late Animation<double> switchTransitionAnimation;
  late LocationTipsManager tipsManager;
  late SimpleLocationService _locationService;
  late BuildContext pageContext;

  // 🚀 新的服务和工具类
  late MarkerBuilder _markerBuilder;

  DraggableScrollableController? _draggableController;
  AMapController? mapController;
  LatLng? _pendingInitialTarget;

  // 标记地图Channel是否可用，避免在Native View销毁后继续发消息导致Bad state错误
  bool _isMapChannelAvailable = true;
  OverlayEntry? _overlayEntry;
  
  // 🚀 节流机制：减少底座旋转更新频率，避免卡顿
  Timer? _pedestalUpdateTimer;
  bool _pendingPedestalUpdate = false;
  
  // 🚀 防抖机制：避免频繁重建 marker，减少卡顿
  Timer? _markerRebuildTimer;
  bool _pendingMarkerRebuild = false;

  // 缓存字段（用于判断是否需要重新创建 marker）
  Offset? _cachedMyAnchor; // 缓存的我的锚点位置
  Offset? _cachedPartnerAnchor; // 缓存的伴侣的锚点位置
  String? _cachedMyAvatar;
  String? _cachedPartnerAvatar;
  Face? _cachedMyFace;
  Face? _cachedPartnerFace;
  bool? _cachedIsBindPartner;

  // 🚀 持久化Marker缓存（跨页面访问复用）
  BitmapDescriptor? _persistentMyIcon; // 头像marker（不包含底座）
  BitmapDescriptor? _persistentMyPedestalIcon; // 底座marker（可旋转）
  BitmapDescriptor? _persistentPartnerIcon;
  BitmapDescriptor? _persistentPartnerPedestalIcon; // 伴侣底座marker
  BitmapDescriptor? _persistentPartnerRippleBgIcon;
  BitmapDescriptor? _persistentPartnerRippleIcon; // 🌊 伴侣波纹圆环marker
  BitmapDescriptor? _distanceLabelIcon; // 距离标签marker
  String? _lastDistanceText; // 上次的距离文本，用于判断是否需要重新创建
  BitmapDescriptor? _dashLineTexture; // 虚线纹理（32x8）
  String? _lastMyCacheKey;
  String? _lastPartnerCacheKey;

  // 🎯 近距离模式（<100米）相关变量
  bool _isCloseMode = false; // 是否处于近距离模式
  bool _closeGifStarted = false; // 近距离模式GIF是否已启动

  final RxList<Marker> _trackStartEndMarkers = <Marker>[].obs;
  final RxSet<Polyline> _polylines = <Polyline>{}.obs;
  
  // 细粒度更新ID，用于GetBuilder精准更新
  static const String markersUpdateId = 'markers_update';
  static const String polylinesUpdateId = 'polylines_update';

  // 🚀 修复：管理 ever 监听器，确保正确清理
  Worker? _locationServiceWorker;
  Worker? _headingWorker; // 方向监听器

  @override
  void onInit() {
    super.onInit();
    try {
      // 先加载本地用户信息（立即显示）
      _loadUserInfo();

      // 🚀 修复：如果未绑定，立即清空伴侣位置缓存
      if (!isBindPartner.value) {
        _clearPartnerData();
      }

      // 然后静默刷新用户信息
      _silentRefreshUserInfo();

      _initLocationService();

      // 🚀 初始化新的服务和工具类
      _markerBuilder = MarkerBuilder();

      tipsManager = LocationTipsManager(this);
      tipsManager.onInit();
      _initBackButtonAnimation();
      _initSwitchTransitionAnimation();
      _listenToSheetChanges();
      _initializePageAsync();

    // 如果通过路由参数传入初始跳转坐标，保存以便地图创建完成后移动到该位置
    try {
      final args = Get.arguments;
      if (args is Map<String, dynamic>) {
        final latRaw = args['latitude'] ?? args['lat'] ?? args['latitudeStr'];
        final lonRaw = args['longitude'] ?? args['lng'] ?? args['lon'] ?? args['longitudeStr'];
        if (latRaw != null && lonRaw != null) {
          final lat = double.tryParse(latRaw.toString());
          final lon = double.tryParse(lonRaw.toString());
          if (lat != null && lon != null) {
            _pendingInitialTarget = LatLng(lat, lon);
            debugPrint('📍 定位页面：收到路由参数初始跳转坐标 $_pendingInitialTarget');
          }
        }
      }
    } catch (e) {
      debugPrint('解析路由参数失败: $e');
    }

      
    } catch (e) {
      debugPrint('LocationController onInit error: $e');
    }
  }

  @override
  void onReady() {
    super.onReady();
    // 页面准备就绪时，确保已经静默刷新
  }

  /// 页面重新获得焦点时的回调（从其他页面返回时会调用）
  void onPageResumed() {
    debugPrint('📍 定位页面重新获得焦点，静默刷新用户信息');
    // 先用本地数据（已经在onInit中加载）
    // 然后静默刷新用户信息
    _silentRefreshUserInfo();
  }

  /// 静默刷新用户信息（不阻塞UI）
  Future<void> _silentRefreshUserInfo() async {
    try {
      debugPrint('🔄 定位页面：静默刷新用户信息');
      final success = await UserManager.refreshUserInfo();
      if (success) {
        // 刷新成功后重新加载本地数据到UI
        _loadUserInfo();
      }
    } catch (e) {
      debugPrint('❌ 定位页面：静默刷新用户信息失败: $e');
    }
  }

 

 

  void _initBackButtonAnimation() {
    backButtonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    backButtonRotationAnimation = Tween<double>(begin: 0.0, end: -0.25).animate(
      CurvedAnimation(
        parent: backButtonAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _initSwitchTransitionAnimation() {
    switchTransitionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    switchTransitionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: switchTransitionController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _listenToSheetChanges() {
    sheetPercent.listen((percent) {
      final topThreshold = 0.85;
      if (percent >= topThreshold && !isBackButtonRotated.value) {
        isBackButtonRotated.value = true;
        backButtonAnimationController.forward();
      } else if (percent < topThreshold && isBackButtonRotated.value) {
        isBackButtonRotated.value = false;
        backButtonAnimationController.reverse();
      }

     
    });
  }

 
 
  void handleBackButtonTap([ScrollController? scrollController]) {
     
    Get.back();
  }

  void setDraggableController(DraggableScrollableController controller) {
    _draggableController = controller;
  }

  

  /// 收起底部面板到底部吸顶位置（切换头像时使用）
  void collapseToBottomPosition() {
    if (_draggableController != null) {
      try {
        // 动态计算底部吸顶位置（对应 snapSizes 中的第一个位置）
        const minHeight = 190.0;
        final screenHeight = Get.context != null
            ? MediaQuery.of(Get.context!).size.height
            : 800.0;
        final bottomSnapSize = minHeight / screenHeight;

        _draggableController!.animateTo(
          bottomSnapSize, // 收起到底部吸顶位置
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        debugPrint('🎯 定位页面：收起底部面板到底部吸顶位置');
      } catch (e) {
        debugPrint('❌ 定位页面：收起底部面板到底部位置失败: $e');
      }
    }
  }

  /// 统一的异步初始化流程（优化：后台静默加载，不阻塞UI）
  void _initializePageAsync() {
    debugPrint('🚀 地图页面异步初始化流程开始（后台静默执行）');

    // 立即启动后台数据加载，不等待结果
    // 这样地图可以立即显示，数据到了再更新
    loadLocationData()
        .then((_) {
          debugPrint('📊 位置数据加载完成');
        })
        .catchError((e) {
          debugPrint('位置数据加载失败: $e');
        });

    // 并行检查定位权限
    _checkLocationPermissionOnPageEnter()
        .then((_) {
          debugPrint('📊 定位权限检查完成');
        })
        .catchError((e) {
          debugPrint('定位权限检查失败: $e');
        });
  }

  void _initLocationService() {
    try {
      _locationService = SimpleLocationService.instance;

      // 🚀 实时监听方向变化，像导航一样流畅
      // 直接更新底座rotation，不重新创建marker
      _headingWorker = ever(_locationService.currentHeading, (heading) {
        if (heading != null) {
          currentHeading.value = heading;

          // 实时更新底座rotation（不重新创建marker，毫秒级响应）
          // 仅在地图Controller和Channel均可用时才更新，避免在地图销毁后反复报错
          if (mapController != null && _isMapChannelAvailable) {
            _updatePedestalRotation();
          }
        }
      });

      // 🎯 已禁用：不再使用实时定位更新位置，只从接口获取位置
      // _locationServiceWorker = ever(_locationService.currentLocation, ...)
      // 位置数据现在只从 loadLocationData() 接口获取
    } catch (e) {
      debugPrint('Location service init error: $e');
    }
  }

  Future<void> _checkLocationPermissionOnPageEnter() async {
    try {
      var locationStatus = await Permission.location.status;
      if (locationStatus.isDenied || locationStatus.isPermanentlyDenied) {
        await _requestLocationPermissionAndStartService();
      } else if (locationStatus.isGranted) {
        await _locationService.startLocation();
      }
    } catch (e) {
      debugPrint('Check location permission error: $e');
    }
  }

  Future<void> _requestLocationPermissionAndStartService() async {
    try {
      final permissionManager = LocationPermissionManager.instance;
      bool hasPermission = await permissionManager.requestLocationPermission();
      if (hasPermission) {
        await _checkAndStartLocationService();
      }
    } catch (e) {
      debugPrint('Request location permission error: $e');
    }
  }

  Future<void> _checkAndStartLocationService() async {
    try {
      if (!UserManager.isLoggedIn) return;
      if (!_locationService.isLocationEnabled.value) {
        await _locationService.startLocation();
      }
    } catch (e) {
      debugPrint('Check and start location service error: $e');
    }
  }

  void _loadUserInfo() {
    final user = UserManager.currentUser;
    if (user != null) {
      final bindStatus = user.bindStatus.toString();
      isBindPartner.value = bindStatus == "1";
      isVip.value = UserManager.isVip;

      // 未绑定时强制设置为看自己
      if (!isBindPartner.value) {
        isOneself.value = 1;
      }

      if (myAvatar.value.isEmpty) {
        myAvatar.value = user.headPortrait ?? '';
      }

      if (isBindPartner.value && partnerAvatar.value.isEmpty) {
        if (user.loverInfo?.headPortrait?.isNotEmpty == true) {
          partnerAvatar.value = user.loverInfo!.headPortrait!;
        } else if (user.halfUserInfo?.headPortrait?.isNotEmpty == true) {
          partnerAvatar.value = user.halfUserInfo!.headPortrait!;
        }
      }
    }
  }

  /// 🚀 优化：抽取重复的实时定位获取逻辑
  LatLng? _tryGetCurrentLocationFromService() {
    try {
      final currentLoc = _locationService.currentLocation.value;
      if (currentLoc != null) {
        final lat = double.tryParse(currentLoc.latitude);
        final lng = double.tryParse(currentLoc.longitude);
        if (lat != null && lng != null) {
          return LatLng(lat, lng);
        }
      }
    } catch (e) {
      debugPrint('获取实时位置失败: $e');
    }
    return null;
  }

  // 🚀 使用 MarkerBuilder 创建头像标记（不包含底座）
  Future<Map<String, dynamic>> _createAvatarMarker(
    String avatarUrl, {
    String? defaultAsset,
    required String baseAsset,
    Face? face,
    bool useLargePedestal = false, // 是否使用大底座（用于计算anchor）
  }) async {
    return _markerBuilder.createAvatarMarker(
      avatarUrl,
      defaultAsset: defaultAsset,
      baseAsset: baseAsset,
      face: face,
      useLargePedestal: useLargePedestal,
      skipPedestal: true, // 底座作为独立marker，这里不绘制
    );
  }

  /// 🚀 实时更新底座旋转角度和位置（不重新创建marker，毫秒级响应）
  /// 🎯 添加节流机制，减少更新频率避免卡顿
  void _updatePedestalRotation() async {
    // 地图Channel不可用或Controller已被清理时，直接跳过
    if (!_isMapChannelAvailable || mapController == null) {
      return;
    }

    // 🚀 节流：如果已经有待处理的更新，标记需要更新但不立即执行
    if (_pedestalUpdateTimer != null && _pedestalUpdateTimer!.isActive) {
      _pendingPedestalUpdate = true;
      return;
    }

    // 🚀 立即执行一次更新，然后设置节流定时器
    _pendingPedestalUpdate = false;
    _pedestalUpdateTimer?.cancel();
    _pedestalUpdateTimer = Timer(const Duration(milliseconds: 100), () {
      // 如果节流期间有新的更新请求，执行最后一次更新
      if (_pendingPedestalUpdate && !isClosed && mapController != null) {
        _pendingPedestalUpdate = false;
        _performPedestalUpdate();
      }
      _pedestalUpdateTimer = null;
    });

    // 立即执行更新
    _performPedestalUpdate();
  }

  /// 执行实际的底座更新操作
  void _performPedestalUpdate() async {
    try {
      // 🎯 关键修复：始终使用最新的位置，确保与头像marker同步
      final myPos = actualMyLocation.value ?? myLocation.value;
      if (myPos == null || _persistentMyPedestalIcon == null) return;

      // 计算底座旋转角度
      final heading = currentHeading.value ?? 0.0;
      // 图片默认朝左（西=270度），要让它跟随手机方向
      // 手机朝北(0度)时，需要旋转90度才能从朝西变成朝北
      final rotation = heading + 90.0; // 🎯 修正：图片朝左需要+90度偏移

      // 🎯 修复：底座anchor固定为(0.5, 0.5)，因为底座图片的锚点就在中心
      // 创建新的底座marker（同时更新position、rotation和anchor）
      final pedestalMarker = Marker(
        position: myPos, // 🎯 使用最新位置
        icon: _persistentMyPedestalIcon!,
        anchor: const Offset(0.5, 0.5), // 🎯 底座图片的锚点在中心
        rotation: rotation, // 🎯 实时旋转角度
        zIndex: 1.0, // 底层
        clickable: false, // 底座不响应点击
      );
      pedestalMarker.setIdForCopy('my_pedestal');

      // 🎯 同时更新头像marker的位置（确保头像和底座不分离）
      if (_persistentMyIcon != null && _cachedMyAnchor != null) {
        final avatarMarker = Marker(
          position: myPos, // 🎯 使用与底座相同的位置
          icon: _persistentMyIcon!,
          anchor: _cachedMyAnchor!,
          zIndex: 2.0, // 上层
          onTap: (String markerId) {
            _moveMapToLocation(myPos);
          },
        );
        avatarMarker.setIdForCopy('my_marker');

        // 同时更新底座和头像
        await mapController?.updateMarker(pedestalMarker);
        await mapController?.updateMarker(avatarMarker);

        // debugPrint(
        //   '🎯 同步更新底座和头像位置: $myPos, 旋转: ${rotation.toStringAsFixed(1)}°',
        // );
      } else {
        // 如果头像marker还没创建，只更新底座
        await mapController?.updateMarker(pedestalMarker);
      }
    } catch (e) {
      debugPrint('更新底座旋转失败: $e');
      // 一旦检测到Channel未初始化的异常，后续不再尝试更新，避免持续卡顿
      final msg = e.toString();
      if (msg.contains('地图Channel未初始化') ||
          msg.contains('Bad state') ||
          msg.contains('mapId')) {
        _isMapChannelAvailable = false;
      }
    }
  }

  /// 🚀 防抖版本的 marker 重建方法，避免频繁更新导致卡顿
  void _initTrackStartEndMarkersDebounced() {
    // 如果已经有待处理的重建，标记需要重建但不立即执行
    if (_markerRebuildTimer != null && _markerRebuildTimer!.isActive) {
      _pendingMarkerRebuild = true;
      return;
    }

    // 立即执行一次重建，然后设置防抖定时器
    _pendingMarkerRebuild = false;
    _markerRebuildTimer?.cancel();
    _markerRebuildTimer = Timer(const Duration(milliseconds: 200), () {
      // 如果防抖期间有新的重建请求，执行最后一次重建
      if (_pendingMarkerRebuild && !isClosed) {
        _pendingMarkerRebuild = false;
        _initTrackStartEndMarkers();
      }
      _markerRebuildTimer = null;
    });

    // 立即执行重建
    _initTrackStartEndMarkers();
  }

  Future<void> _initTrackStartEndMarkers() async {
    // 🎯 防止重复创建：如果已经在近距离模式且GIF已启动，跳过整个方法
    if (_isCloseMode && _closeGifStarted && isBindPartner.value) {
      final distanceInMeters = _parseDistanceToMeters(distance.value);
      final bool shouldStayInCloseMode = distanceInMeters != null && distanceInMeters <= 100;
      if (shouldStayInCloseMode) {
        debugPrint('🎯 已在近距离模式且GIF已启动，跳过marker重建');
        return;
      }
    }
    
    // 🎯 优化：只在需要更新时才清空，减少闪烁
    if (_needsUpdateIconCache()) {
      await _updateIconCache();
    }

    // 清空旧的markers
    _trackStartEndMarkers.clear();
    // 触发GetBuilder精准更新
    update([markersUpdateId]);

    try {
      final List<Marker> tempMarkers = [];

      // 未绑定时只显示自己的位置
      if (!isBindPartner.value) {
        LatLng? myPos = actualMyLocation.value ?? myLocation.value;

        // 如果还没有位置数据，尝试从实时定位服务获取
        if (myPos == null) {
          myPos = _tryGetCurrentLocationFromService();
          if (myPos != null) {
            debugPrint('📍 使用实时定位服务创建 marker: $myPos');
          }
        }

        if (myPos != null) {
          try {
            final BitmapDescriptor myIcon =
                _persistentMyIcon ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);

            final capturedPos = myPos; // 捕获非空值到局部变量

            // 🎯 获取头像anchor，用于调试
            final avatarAnchor = _cachedMyAnchor ?? const Offset(0.5, 1.0);
            debugPrint(
              '📍 未绑定状态创建marker - 位置: $capturedPos, 头像anchor: $avatarAnchor',
            );

            // 🚀 添加底座marker（可旋转，zIndex=1，在下层）
            if (_persistentMyPedestalIcon != null) {
              // 计算底座旋转角度
              final heading = currentHeading.value ?? 0.0;
              final rotation = heading + 90.0; // 🎯 修正：图片朝左需要+90度偏移

              // 🎯 修复：底座anchor固定为(0.5, 0.5)，因为底座图片的锚点就在中心
              final pedestalMarker = Marker(
                position: capturedPos,
                icon: _persistentMyPedestalIcon!,
                anchor: const Offset(0.5, 0.5), // 🎯 底座图片的锚点在中心
                rotation: rotation, // 🎯 实时旋转角度
                zIndex: 1.0, // 底层
                clickable: false, // 底座不响应点击
              );
              pedestalMarker.setIdForCopy('my_pedestal');
              tempMarkers.add(pedestalMarker);
              debugPrint(
                '✅ 底座marker创建 - 位置: $capturedPos, anchor: (0.5, 0.5), 旋转: $rotation°',
              );
            }

            // 🚀 添加头像marker（不旋转，zIndex=2，在上层）
            final myMarker = Marker(
              position: capturedPos,
              icon: myIcon,
              anchor: avatarAnchor,
              zIndex: 2.0, // 上层
              onTap: (String markerId) {
                // 点击头像直接跳转到详情页（与聊天页面行为一致）
                try {
                  Get.to(
                    () => LocationDetailPage(
                      latitude: capturedPos.latitude,
                      longitude: capturedPos.longitude,
                      locationName: currentLocationText.value,
                      avatarUrl: myAvatar.value.isNotEmpty ? myAvatar.value : null,
                      isMyself: true,
                    ),
                    transition: Transition.rightToLeft,
                  );
                } catch (e) {
                  debugPrint('跳转到详情页失败，回退到移动相机: $e');
                  _moveMapToLocation(capturedPos);
                }
              },
            );
            myMarker.setIdForCopy('my_marker');
            tempMarkers.add(myMarker);
            debugPrint(
              '✅ 头像marker创建 - 位置: $capturedPos, anchor: $avatarAnchor',
            );
          } catch (e) {
            debugPrint('Create my marker error: $e');
          }
        }
      } else {
        // 已绑定时显示两个人的位置
        // 🎯 只使用接口返回的位置，不使用实时定位
        final LatLng? myPos = myLocation.value;
        final LatLng? partnerPos = partnerLocation.value;
        
        // 🎯 判断是否进入近距离模式（<100米）
        final distanceInMeters = _parseDistanceToMeters(distance.value);
        final bool shouldUseCloseMode = distanceInMeters != null && distanceInMeters <= 100;
        
        debugPrint('📍 距离判断: ${distance.value} = ${distanceInMeters}米, 近距离模式: $shouldUseCloseMode');
        
        // 🎯 近距离模式：两个摇摆头像 + GIF，位置以我的坐标为准
        if (shouldUseCloseMode && myPos != null) {
          debugPrint('🎯 进入近距离模式，创建摇摆头像和GIF');
          
          // 如果之前不是近距离模式，需要停止原有动画
          if (!_isCloseMode) {
            _stopNativeBreathAnimation();
          }
          _isCloseMode = true;
          
          // 创建近距离模式的markers
          await _createCloseModeMarkers(tempMarkers, myPos);
        } else {
          // 🎯 正常模式：分开的头像 + 连线
          debugPrint('🎯 进入正常模式，创建分开的头像');
          
          // 如果之前是近距离模式，需要停止GIF和摆动动画
          if (_isCloseMode) {
            await _stopCloseModeAnimations();
          }
          _isCloseMode = false;
          
          // 创建正常模式的markers
          await _createNormalModeMarkers(tempMarkers, myPos, partnerPos);
        }
      }

      if (tempMarkers.isNotEmpty) {
        _trackStartEndMarkers.value = tempMarkers;
        // 触发GetBuilder精准更新
        update([markersUpdateId]);
        // 🚀 延迟启动动画，确保 marker 已经完全添加到地图上
        // 延迟时间需要足够让地图完成 marker 的渲染
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!isClosed && mapController != null) {
            // 🎯 根据模式启动不同的动画
            if (_isCloseMode) {
              _startCloseModeAnimations();
            } else {
              _startNativeBreathAnimation();
            }
          }
        });
      } else {
        _trackStartEndMarkers.clear();
        // 🎯 停止所有动画
        if (_isCloseMode) {
          _stopCloseModeAnimations();
        } else {
          _stopNativeBreathAnimation();
        }
        // 触发GetBuilder精准更新
        update([markersUpdateId]);
      }
    } catch (e) {
      debugPrint('Init track markers error: $e');
    }
  }

  void _moveMapToLocation(LatLng location) {
    if (mapController != null) {
      mapController!.moveCamera(CameraUpdate.newLatLngZoom(location, 16.0));
    }
  }

  /// 解析距离字符串并转换为米数
  /// 支持格式： "100m", "1.5km", "10km" 等
  double? _parseDistanceToMeters(String distanceText) {
    if (distanceText.isEmpty || distanceText == "未知") {
      return null;
    }
    
    try {
      // 移除所有空格
      String cleaned = distanceText.trim().replaceAll(' ', '');
      
      // 🎯 处理 "<100米" 这种格式，表示小于100米
      if (cleaned.startsWith('<') || cleaned.startsWith('＜')) {
        // 移除 < 符号
        cleaned = cleaned.substring(1);
        // 继续解析后面的数字，返回的值会小于100，触发近距离模式
      }
      
      // 🎯 处理中文"米"结尾
      if (cleaned.endsWith('米')) {
        final metersStr = cleaned.substring(0, cleaned.length - 1);
        final meters = double.tryParse(metersStr);
        return meters;
      }
      
      // 🎯 处理中文"千米"或"公里"结尾
      if (cleaned.endsWith('千米') || cleaned.endsWith('公里')) {
        final kmStr = cleaned.endsWith('千米') 
            ? cleaned.substring(0, cleaned.length - 2)
            : cleaned.substring(0, cleaned.length - 2);
        final km = double.tryParse(kmStr);
        if (km != null) {
          return km * 1000;
        }
      }
      
      // 检查是否以 "m" 结尾（米）
      if (cleaned.toLowerCase().endsWith('m') && !cleaned.toLowerCase().endsWith('km')) {
        final metersStr = cleaned.substring(0, cleaned.length - 1);
        final meters = double.tryParse(metersStr);
        return meters;
      }
      
      // 检查是否以 "km" 结尾（千米）
      if (cleaned.toLowerCase().endsWith('km')) {
        final kmStr = cleaned.substring(0, cleaned.length - 2);
        final km = double.tryParse(kmStr);
        if (km != null) {
          return km * 1000; // 转换为米
        }
      }
      
      // 如果都不匹配，尝试直接解析为数字（假设是米）
      final meters = double.tryParse(cleaned);
      return meters;
    } catch (e) {
      debugPrint('解析距离失败: $distanceText, 错误: $e');
      return null;
    }
  }

  /// 使用墨卡托投影计算两点的中点
  /// 这是高德地图原生的做法，确保中点在屏幕投影上也是中点
  LatLng _projectedMiddle(LatLng p1, LatLng p2) {
    // 经纬度 → 墨卡托投影
    double lonToX(double lng) => lng * 20037508.34 / 180;
    double latToY(double lat) =>
        dart_math.log(dart_math.tan((90 + lat) * dart_math.pi / 360)) * 20037508.34 / dart_math.pi;

    // 墨卡托 → 经纬度（反投影）
    double xToLon(double x) => x / 20037508.34 * 180;
    double yToLat(double y) =>
        (180 / dart_math.pi) * (2 * dart_math.atan(dart_math.exp(y / 20037508.34 * dart_math.pi)) - dart_math.pi / 2);

    // 转换到投影坐标系
    final x1 = lonToX(p1.longitude);
    final y1 = latToY(p1.latitude);
    final x2 = lonToX(p2.longitude);
    final y2 = latToY(p2.latitude);

    // 在投影坐标系中计算中点
    final midX = (x1 + x2) / 2;
    final midY = (y1 + y2) / 2;

    // 反投影回经纬度
    return LatLng(yToLat(midY), xToLon(midX));
  }

  /// 🎯 创建近距离模式的markers（两个摇摆头像 + GIF）
  /// 参考测试页面的实现，所有元素使用相同坐标，通过不同锚点实现并排布局
  Future<void> _createCloseModeMarkers(List<Marker> tempMarkers, LatLng position) async {
    try {
      // 🎯 获取用户头像（与测试页面完全一致）
      final user = UserManager.currentUser;
      final myAvatarUrl = user?.headPortrait ?? '';
      final partnerAvatarUrl = user?.loverInfo?.headPortrait ?? 
                               user?.halfUserInfo?.headPortrait ?? '';
      
      debugPrint('🎯 近距离模式头像: 我=$myAvatarUrl, Ta=$partnerAvatarUrl, 位置=$position');

      // 1. 创建Ta的头像marker（左边，逆时针旋转20度）
      debugPrint('🎯 开始创建Ta的头像marker');
      final partnerMarkerData = await _markerBuilder.createAvatarWithBgMarker(
        partnerAvatarUrl,
        defaultAsset: 'assets/3.0/kissu3_love_avater.webp',
        bgAsset: 'assets/images/kissu_map_avair_bg.webp',
        designAvatarSize: 50.0,
        designBgWidth: 60.0,
        designBgHeight: 65.0,
        avatarOffsetY: 5.5,
        rotationDegrees: -20.0,
      );
      final partnerIcon = partnerMarkerData['descriptor'] as BitmapDescriptor?;
      final partnerAnchor = partnerMarkerData['anchor'] as Offset? ?? const Offset(0.5, 1.0);
      final partnerAnchorAdjusted = Offset(partnerAnchor.dx + 0.5, partnerAnchor.dy);
      debugPrint('🎯 Ta的头像: icon=${partnerIcon != null}, anchor=$partnerAnchor, adjusted=$partnerAnchorAdjusted');
      
      if (partnerIcon != null) {
        final partnerMarker = Marker(
          position: position,
          icon: partnerIcon,
          anchor: partnerAnchorAdjusted,
          zIndex: 2.0,
          clickable: true,
        );
        // 🎯 使用不同的marker ID，避免与正常模式冲突
        partnerMarker.setIdForCopy('close_partner_marker');
        tempMarkers.add(partnerMarker);
        debugPrint('✅ 近距离模式: Ta的头像marker创建成功（左边），位置: $position');
      } else {
        debugPrint('❌ 近距离模式: Ta的头像icon为null');
      }

      // 2. 创建我的头像marker（右边，顺时针旋转20度）
      debugPrint('🎯 开始创建我的头像marker，头像URL: $myAvatarUrl');
      final myMarkerData = await _markerBuilder.createAvatarWithBgMarker(
        myAvatarUrl,
        defaultAsset: 'assets/3.0/kissu3_love_avater.webp',
        bgAsset: 'assets/images/kissu_map_avair_bg.webp',
        designAvatarSize: 50.0,
        designBgWidth: 60.0,
        designBgHeight: 65.0,
        avatarOffsetY: 5.5,
        rotationDegrees: 20.0,
      );
      debugPrint('🎯 我的头像marker数据: $myMarkerData');
      final myIcon = myMarkerData['descriptor'] as BitmapDescriptor?;
      final myAnchor = myMarkerData['anchor'] as Offset? ?? const Offset(0.5, 1.0);
      final myAnchorAdjusted = Offset(myAnchor.dx - 0.5, myAnchor.dy);
      debugPrint('🎯 我的头像: icon=${myIcon != null}, anchor=$myAnchor, adjusted=$myAnchorAdjusted');
      
      if (myIcon != null) {
        final myMarker = Marker(
          position: position,
          icon: myIcon,
          anchor: myAnchorAdjusted,
          zIndex: 2.0,
          clickable: true,
        );
        // 🎯 使用不同的marker ID，避免与正常模式冲突
        myMarker.setIdForCopy('close_my_marker');
        tempMarkers.add(myMarker);
        debugPrint('✅ 近距离模式: 我的头像marker创建成功（右边），位置: $position');
      } else {
        debugPrint('❌ 近距离模式: 我的头像icon为null，无法创建marker');
      }

      // 3. 创建GIF动画marker（在两人头像底部尖尖下方）
      final gifMarker = Marker(
        position: position,
        icon: BitmapDescriptor.defaultMarker,
        anchor: const Offset(0.5, 0.8),
        zIndex: 1.0,
        clickable: false,
      );
      gifMarker.setIdForCopy('gif_marker');
      tempMarkers.add(gifMarker);
      debugPrint('✅ 近距离模式: GIF占位marker创建成功');

    } catch (e) {
      debugPrint('❌ 创建近距离模式markers失败: $e');
    }
  }

  /// 🎯 启动近距离模式的动画（GIF + 摆动）
  Future<void> _startCloseModeAnimations() async {
    if (mapController == null || !_isMapChannelAvailable) return;
    
    try {
      // 获取设备像素比
      final devicePixelRatio = pageContext.mounted 
          ? MediaQuery.of(pageContext).devicePixelRatio 
          : 3.0;
      final gifSizeW = (498 / 2 * devicePixelRatio).toInt();
      final gifSizeH = (633 / 2 * devicePixelRatio).toInt();

      // 启动GIF动画
      final success = await mapController!.startGifAnimation(
        markerId: 'gif_marker',
        assetPath: 'assets/gif/ceshi.gif',
        width: gifSizeW,
        height: gifSizeH,
      );
      if (success) {
        _closeGifStarted = true;
        debugPrint('✅ 近距离模式: GIF动画启动成功');
      }

      // 启动摆动动画
      // 左边头像（Ta）：从-20度摆动到-5度
      await mapController!.startSwingAnimation(
        markerId: 'close_partner_marker',
        fromAngle: -20.0,
        toAngle: -5.0,
        duration: 800,
      );
      debugPrint('✅ 近距离模式: Ta的摆动动画启动');

      // 右边头像（我）：从20度摆动到5度
      await mapController!.startSwingAnimation(
        markerId: 'close_my_marker',
        fromAngle: 20.0,
        toAngle: 5.0,
        duration: 800,
      );
      debugPrint('✅ 近距离模式: 我的摆动动画启动');
    } catch (e) {
      debugPrint('❌ 启动近距离模式动画失败: $e');
    }
  }

  /// 🎯 停止近距离模式的动画
  Future<void> _stopCloseModeAnimations() async {
    if (mapController == null || !_isMapChannelAvailable) return;
    
    try {
      // 停止GIF动画
      if (_closeGifStarted) {
        await mapController!.stopGifAnimation(markerId: 'gif_marker');
        _closeGifStarted = false;
        debugPrint('✅ 近距离模式: GIF动画已停止');
      }

      // 停止摆动动画
      await mapController!.stopSwingAnimation(markerId: 'close_partner_marker');
      await mapController!.stopSwingAnimation(markerId: 'close_my_marker');
      debugPrint('✅ 近距离模式: 摆动动画已停止');
    } catch (e) {
      debugPrint('❌ 停止近距离模式动画失败: $e');
    }
  }

  /// 🎯 创建正常模式的markers（分开的头像 + 底座 + 距离标签）
  Future<void> _createNormalModeMarkers(List<Marker> tempMarkers, LatLng? myPos, LatLng? partnerPos) async {
    // 创建我的marker
    if (myPos != null) {
      try {
        final BitmapDescriptor myIcon =
            _persistentMyIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);

        final myAvatarAnchor = _cachedMyAnchor ?? const Offset(0.5, 1.0);

        // 添加底座marker
        if (_persistentMyPedestalIcon != null) {
          final heading = currentHeading.value ?? 0.0;
          final rotation = heading + 90.0;

          final pedestalMarker = Marker(
            position: myPos,
            icon: _persistentMyPedestalIcon!,
            anchor: const Offset(0.5, 0.5),
            rotation: rotation,
            zIndex: 1.0,
            clickable: false,
          );
          pedestalMarker.setIdForCopy('my_pedestal');
          tempMarkers.add(pedestalMarker);
        }

        // 添加头像marker
        final myMarker = Marker(
          position: myPos,
          icon: myIcon,
          anchor: myAvatarAnchor,
          zIndex: 2.0,
          onTap: (String markerId) {
            try {
              Get.to(
                () => LocationDetailPage(
                  latitude: myPos.latitude,
                  longitude: myPos.longitude,
                  locationName: currentLocationText.value,
                  avatarUrl: myAvatar.value.isNotEmpty ? myAvatar.value : null,
                  isMyself: true,
                ),
                transition: Transition.rightToLeft,
              );
            } catch (e) {
              debugPrint('跳转到详情页失败: $e');
              _moveMapToLocation(myPos);
            }
          },
        );
        myMarker.setIdForCopy('my_marker');
        tempMarkers.add(myMarker);
      } catch (e) {
        debugPrint('Create my marker error: $e');
      }
    }

    // 创建伴侣的marker
    if (partnerPos != null) {
      try {
        final BitmapDescriptor partnerIcon =
            _persistentPartnerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

        final partnerAvatarAnchor = _cachedPartnerAnchor ?? const Offset(0.5, 1.0);

        // 添加伴侣底座marker
        if (_persistentPartnerPedestalIcon != null) {
          final partnerPedestalMarker = Marker(
            position: partnerPos,
            icon: _persistentPartnerPedestalIcon!,
            anchor: const Offset(0.5, 0.5),
            rotation: 0.0,
            zIndex: 1.0,
            clickable: false,
          );
          partnerPedestalMarker.setIdForCopy('partner_pedestal');
          tempMarkers.add(partnerPedestalMarker);
        }

        // 添加伴侣头像marker
        final partnerMarker = Marker(
          position: partnerPos,
          icon: partnerIcon,
          anchor: partnerAvatarAnchor,
          zIndex: 2.0,
          onTap: (String markerId) {
            try {
              Get.to(
                () => LocationDetailPage(
                  latitude: partnerPos.latitude,
                  longitude: partnerPos.longitude,
                  locationName:
                      (locationData.value?.halfLocationMobileDevice?.location) ?? '',
                  avatarUrl: partnerAvatar.value.isNotEmpty ? partnerAvatar.value : null,
                  isMyself: false,
                ),
                transition: Transition.rightToLeft,
              );
            } catch (e) {
              debugPrint('跳转到详情页失败: $e');
              _moveMapToLocation(partnerPos);
            }
          },
        );
        partnerMarker.setIdForCopy('partner_marker');
        tempMarkers.add(partnerMarker);

        // 添加距离标签marker（只在距离大于100米时显示）
        final distanceInMeters = _parseDistanceToMeters(distance.value);
        if (myPos != null && 
            distance.value.isNotEmpty && 
            distanceInMeters != null && 
            distanceInMeters > 100) {
          try {
            final midPoint = _projectedMiddle(myPos, partnerPos);
            final dx = partnerPos.longitude - myPos.longitude;
            final dy = partnerPos.latitude - myPos.latitude;
            final angleRad = dart_math.atan2(dx, dy);
            final angleDeg = (angleRad * 180 / dart_math.pi) + 95;

            if (_lastDistanceText != distance.value) {
              _distanceLabelIcon = await _markerBuilder.createDistanceLabelMarker(
                distanceText: distance.value,
              );
              _lastDistanceText = distance.value;
            }

            if (_distanceLabelIcon != null) {
              final distanceLabelMarker = Marker(
                position: midPoint,
                icon: _distanceLabelIcon!,
                anchor: const Offset(0.5, 0.5),
                rotation: angleDeg,
                zIndex: 1.8,
                clickable: false,
                isFlat: true,
              );
              distanceLabelMarker.setIdForCopy('distance_label');
              tempMarkers.add(distanceLabelMarker);
            }
          } catch (e) {
            debugPrint('Create distance label marker error: $e');
          }
        }
      } catch (e) {
        debugPrint('Create partner marker error: $e');
      }
    }
  }

  Future<void> _updatePolylines() async {
    _polylines.clear();

    // 未绑定时不显示连线
    if (!isBindPartner.value) {
      // 触发GetBuilder精准更新
      update([markersUpdateId]);
      return;
    }

    // 🎯 近距离模式下不显示连线
    if (_isCloseMode) {
      debugPrint('📍 近距离模式，不显示连线');
      update([markersUpdateId]);
      return;
    }

    // 🎯 只使用接口返回的位置，不使用实时定位
    final myPos = myLocation.value;
    final partnerPos = partnerLocation.value;

    if (myPos != null && partnerPos != null) {
      final List<LatLng> connectionPoints = [myPos, partnerPos];

      // 🎯 不再计算距离，直接使用 API 返回的 distance 字段
      // distance 值已在 _updateCurrentUserData 中从 userLocationMobileDevice.distance 获取

      // 加载虚线纹理（只加载一次）
      // 使用32x8标准尺寸纹理，符合2的n次方要求
      _dashLineTexture ??= await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(),
          'assets/texture/kissu4_dash_line.png',
        );

      _polylines.add(
        Polyline(
          points: connectionPoints,
          width: 8,
          visible: true,
          customTexture: _dashLineTexture!, // 使用32x8纹理实现虚线
          capType: CapType.round,
        ),
      );
      
      // 触发GetBuilder精准更新
      update([markersUpdateId]);
    }
  }


  // 使用getter避免直接暴露内部状态，减少不必要的重建
  Set<Marker> get markers => _trackStartEndMarkers.toSet();
  Set<Polyline> get polylines => _polylines;
  int get markersLength => _trackStartEndMarkers.length;
  int get polylinesLength => _polylines.length;

  CameraPosition get initialCameraPosition {
    // 🚀 修复：未绑定时对准自己的真实位置，缩放级别18（不使用伴侣位置）
    if (!isBindPartner.value) {
      debugPrint('📍 未绑定状态，只使用自己的位置初始化地图');

      // 优先使用 actualMyLocation
      if (actualMyLocation.value != null) {
        debugPrint('📍 使用 actualMyLocation: ${actualMyLocation.value}');
        return CameraPosition(target: actualMyLocation.value!, zoom: 18.0);
      }

      // 其次尝试从实时定位服务获取当前位置
      final serviceLocation = _tryGetCurrentLocationFromService();
      if (serviceLocation != null) {
        debugPrint('📍 未绑定时使用实时定位服务位置: $serviceLocation');
        return CameraPosition(target: serviceLocation, zoom: 18.0);
      }

      // 最后使用默认位置（天安门）
      debugPrint('📍 未绑定且无位置数据，使用默认位置（天安门）');
      return const CameraPosition(
        target: LatLng(39.9042, 116.4074), // 天安门坐标
        zoom: 3.0, // 大范围视图
      );
    }

    // 🚀 已绑定时的逻辑：使用中间位置和合理的缩放级别
    debugPrint('📍 已绑定状态，计算双人中心位置');
    if (myLocation.value != null && partnerLocation.value != null) {
      final myPos = myLocation.value!;
      final partnerPos = partnerLocation.value!;

      // 计算中心点
      final centerLat = (myPos.latitude + partnerPos.latitude) / 2;
      final centerLng = (myPos.longitude + partnerPos.longitude) / 2;
      final center = LatLng(centerLat, centerLng);

      debugPrint(
        '📍 双人位置：我(${myPos.latitude}, ${myPos.longitude}) 伴侣(${partnerPos.latitude}, ${partnerPos.longitude}) 中心($center)',
      );
      // 初始使用较低缩放级别，具体缩放由 _animateMapToShowBothUsersSync 中的 newLatLngBounds 精确控制
      return CameraPosition(target: center, zoom: 10.0);
    } else if (myLocation.value != null) {
      debugPrint('📍 只有我的位置: ${myLocation.value}');
      return CameraPosition(target: myLocation.value!, zoom: 16.0);
    } else {
      // 🚀 修复：已绑定但没有位置数据时，使用默认位置（不再使用 partnerLocation）
      debugPrint('📍 已绑定但无位置数据，使用默认位置（天安门）');
      return const CameraPosition(
        target: LatLng(39.9042, 116.4074), // 天安门坐标
        zoom: 3.0, // 大范围视图
      );
    }
  }

  void onMapCreated(AMapController controller) {
    mapController = controller;

    // 未绑定时，立即尝试使用实时位置创建 marker
    if (!isBindPartner.value) {
      _initTrackStartEndMarkersDebounced(); // 🚀 使用防抖版本，避免频繁更新
    } else if (myLocation.value != null || partnerLocation.value != null) {
      _initTrackStartEndMarkersDebounced(); // 🚀 使用防抖版本，避免频繁更新
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mapController != null && isClosed == false) {
        // 优先展示路由传入的目标位置
        if (_pendingInitialTarget != null) {
          _animateMapToLocation(_pendingInitialTarget!);
          _pendingInitialTarget = null;
        } else {
          _animateMapToShowBothUsersAsync();
        }
      }
    });
  }

  /// SafeAMapWidget销毁时回调，避免在地图已经被释放后继续发送方法通道消息
  void onMapDisposed() {
    if (mapController != null) {
      debugPrint('🧹 定位页面：地图PlatformView已销毁，清空Controller引用');
    }
    // 标记Channel不可用，后续所有地图操作都会直接跳过，防止Bad state日志刷屏
    _isMapChannelAvailable = false;
    mapController = null;
  }

  void _animateMapToLocation(LatLng location) {
    if (mapController == null) return;
    try {
      unawaited(
        mapController!.moveCamera(
          CameraUpdate.newLatLngZoom(location, 16.0),
          animated: true,
          duration: 1500,
        ),
      );
    } catch (e) {
      debugPrint('Animate map to location error: $e');
    }
  }

  Future<void> _animateMapToShowBothUsersAsync() async {
    if (mapController == null) return;
    await Future.microtask(() => _animateMapToShowBothUsersSync());
  }

  Future<void> _animateMapToShowBothUsersSync() async {
    // 🚀 修复：未绑定时对准自己的真实位置，缩放级别18（不使用伴侣位置）
    if (!isBindPartner.value) {
      debugPrint('📍 未绑定状态，地图只聚焦自己的位置');
      LatLng? targetLocation = actualMyLocation.value;

      // 如果没有位置数据，尝试从实时定位服务获取
      if (targetLocation == null) {
        targetLocation = _tryGetCurrentLocationFromService();
        if (targetLocation != null) {
          debugPrint('📍 地图动画使用实时定位服务位置: $targetLocation');
        }
      }

      if (targetLocation != null) {
        try {
          debugPrint('📍 未绑定状态，移动地图到自己的位置: $targetLocation');
          await mapController!.moveCamera(
            CameraUpdate.newLatLngZoom(targetLocation, 18.0),
            animated: true,
            duration: 300,
          );
        } catch (e) {
          debugPrint('Animate map error: $e');
        }
      } else {
        debugPrint('⚠️ 未绑定状态且无位置数据，地图保持默认位置');
      }
      return; // 🚀 关键：未绑定时直接返回，不执行下面的逻辑
    }

    // 🚀 已绑定时的逻辑
    debugPrint('📍 已绑定状态，计算双人地图位置');
    if (myLocation.value != null && partnerLocation.value != null) {
      final myPos = myLocation.value!;
      final partnerPos = partnerLocation.value!;

      try {
        // 🚀 优化：使用原生的 newLatLngBounds 自动计算最佳缩放层级
        // 计算西南角和东北角
        final double swLat = myPos.latitude < partnerPos.latitude
            ? myPos.latitude
            : partnerPos.latitude;
        final double swLng = myPos.longitude < partnerPos.longitude
            ? myPos.longitude
            : partnerPos.longitude;
        final double neLat = myPos.latitude > partnerPos.latitude
            ? myPos.latitude
            : partnerPos.latitude;
        final double neLng = myPos.longitude > partnerPos.longitude
            ? myPos.longitude
            : partnerPos.longitude;

        final bounds = LatLngBounds(
          southwest: LatLng(swLat, swLng),
          northeast: LatLng(neLat, neLng),
        );

        debugPrint('📍 已绑定，使用原生LatLngBounds移动地图到双人中心位置');
        debugPrint(
          '📍 bounds: southwest($swLat, $swLng), northeast($neLat, $neLng)',
        );

        await mapController!.moveCamera(
          CameraUpdate.newLatLngBounds(bounds, 150), // 100像素边距
          animated: true,
          duration: 300,
        );
      } catch (e) {
        debugPrint('Animate map error: $e');
      }
    } else if (myLocation.value != null) {
      debugPrint('📍 已绑定但只有我的位置，聚焦我的位置');
      _animateMapToLocation(myLocation.value!);
    } else {
      // 🚀 修复：已绑定但无位置数据时，不使用 partnerLocation
      debugPrint('📍 已绑定但无位置数据，地图保持默认位置');
    }
  }

  Future<void> onAvatarTapped(bool isMyself) async {
    if (isSwitchingView.value) return;

    // 计算目标用户类型
    final targetUserType = isMyself ? 1 : 0;

    // 如果点击的是当前用户，不做任何处理
    if (isOneself.value == targetUserType) {
      debugPrint('🎯 定位页面：点击的是当前用户头像，不切换');
      return;
    }

  

    // 📱 每次切换头像时，将下半屏恢复到底部吸顶位置
    debugPrint('💡 定位页面：切换头像，恢复下半屏到底部吸顶位置');
    collapseToBottomPosition();

    isSwitchingView.value = true;

    Timer? safetyTimer = Timer(const Duration(seconds: 5), () {
      if (isSwitchingView.value) {
        isSwitchingView.value = false;
        try {
          switchTransitionController.reset();
        } catch (e) {}
      }
    });

    try {
      await switchTransitionController.forward().timeout(
        const Duration(seconds: 1),
        onTimeout: () {},
      );

      if (isMyself) {
        isOneself.value = 1;
      } else {
        isOneself.value = 0;
        // 🚀 修复：切换到另一半时，先清空另一半的位置数据，避免显示旧marker
        debugPrint('📍 切换到另一半，先清空位置数据');
        actualPartnerLocation.value = null;
        partnerLocation.value = null;
        // 立即更新marker，清除旧的marker
        await _initTrackStartEndMarkers();
      }

      await loadLocationData().timeout(
        const Duration(seconds: 3),
        onTimeout: () {},
      );

      await _moveToTargetUserLocationInstant(isMyself);
      await Future.delayed(const Duration(milliseconds: 100));

      await switchTransitionController.reverse().timeout(
        const Duration(seconds: 1),
        onTimeout: () {
          switchTransitionController.reset();
        },
      );
    } catch (e, stackTrace) {
      debugPrint('Avatar tap error: $e\n$stackTrace');
      try {
        await switchTransitionController.reverse().timeout(
          const Duration(milliseconds: 300),
          onTimeout: () {
            switchTransitionController.reset();
          },
        );
      } catch (e2) {
        switchTransitionController.reset();
      }
    } finally {
      safetyTimer.cancel();
      isSwitchingView.value = false;
    }
  }

  // cycleIndex: 0 -> my, 1 -> partner, 2 -> both
  // 初始设置为2，使得第一次点击进入“我的”视图（顺序：我的->另一半->两人合屏）
  final RxInt _cycleIndex = 2.obs;

  /// 循环切换地图视图：按顺序 [我 -> 另一半 -> 两人合屏] 循环
  void cycleMapView() {
    try {
      final next = (_cycleIndex.value + 1) % 3;
      _cycleIndex.value = next;

      switch (next) {
        case 0:
          // 聚焦到我
          onAvatarTapped(true);
          break;
        case 1:
          // 聚焦到另一半
          onAvatarTapped(false);
          break;
        case 2:
          // 聚焦到展示两人（恢复初始的两人视图）
          _animateMapToShowBothUsersAsync();
          break;
        default:
          _animateMapToShowBothUsersAsync();
      }
    } catch (e) {
      debugPrint('cycleMapView 执行失败: $e');
    }
  }

  Future<void> _moveToTargetUserLocationInstant(bool isMyself) async {
    if (mapController == null) return;

    LatLng? targetLocation;
    if (isMyself) {
      targetLocation = actualMyLocation.value;
    } else {
      targetLocation = actualPartnerLocation.value;
    }

    // 🚀 修复：如果目标位置为空，移动到默认位置（天安门）
    if (targetLocation == null) {
      debugPrint('📍 目标位置为空，移动到默认位置（天安门）');
      try {
        mapController!.moveCamera(
          CameraUpdate.newLatLngZoom(
            const LatLng(39.9042, 116.4074), // 天安门坐标
            3.0, // 大范围视图
          ),
          animated: false,
        );
      } catch (e) {
        debugPrint('Move map to default location error: $e');
      }
      return;
    }

    try {
      mapController!.moveCamera(
        CameraUpdate.newLatLngZoom(targetLocation, 16.0),
        animated: false,
      );
    } catch (e) {
      debugPrint('Move map instantly error: $e');
    }
  }

  Future<void> forceRefreshMarkers() async {
    await _initTrackStartEndMarkers();
  }

  void switchMapType(int type) {
    if (mapType.value != type) {
      mapType.value = type;
       
    }
  }

  Future<void> refreshLocationData() async {
     
    await loadLocationData();
  }

  Future<void> loadLocationData({int retryCount = 0}) async { 
    
    if (isLoading.value && retryCount == 0) return;

    isLoading.value = true;

    try {
      final result = await LocationApi().getLocation();

      if (result.isSuccess && result.data != null) {
        final locationDataResult = result.data!;
        locationData.value = locationDataResult;

        // 🚀 优化：无论绑定与否，自己的位置都优先使用实时定位数据
        if (!isBindPartner.value) {
          debugPrint('⚠️ [未绑定] 只更新头像数据，不使用接口位置数据（保持真实定位数据）');

          // 只更新头像数据，不更新位置数据
          if (locationDataResult.userLocationMobileDevice != null) {
            _updateMyAvatarData(locationDataResult.userLocationMobileDevice!);
            // ❌ 不调用 _updateActualMyLocationData，保持使用真实定位服务的数据
          }

          // 清空对方的位置数据
          _clearPartnerData();
          // 强制设置为看自己
          isOneself.value = 1;
        } else {
          // 已绑定时，更新头像和对方数据
          debugPrint('✅ [已绑定] 更新头像和对方位置数据');

          if (locationDataResult.userLocationMobileDevice != null) {
            _updateMyAvatarData(locationDataResult.userLocationMobileDevice!);

            // 🎯 始终使用接口数据更新位置（不再使用实时定位）
            debugPrint('📍 [已绑定] 使用接口数据更新我的位置');
            _updateMyLocationData(locationDataResult.userLocationMobileDevice!);
          }

          // 对方的位置正常使用接口数据
          if (locationDataResult.halfLocationMobileDevice != null) {
            _updatePartnerAvatarData(
              locationDataResult.halfLocationMobileDevice!,
            );
            // 🎯 使用接口数据更新伴侣位置
            _updatePartnerLocationData(
              locationDataResult.halfLocationMobileDevice!,
            );
          } else {
            // 🚀 修复：如果halfLocationMobileDevice为null，清空所有位置数据
            debugPrint('📍 另一半数据为null，清空所有位置数据');
            actualPartnerLocation.value = null;
            partnerLocation.value = null;
          }
        }

        UserLocationMobileDevice? currentUser;

        // 未绑定时只使用自己的数据
        if (!isBindPartner.value) {
          currentUser = locationDataResult.userLocationMobileDevice;
        } else if (isOneself.value == 1) {
          currentUser = locationDataResult.userLocationMobileDevice;
        } else {
          currentUser = locationDataResult.halfLocationMobileDevice;
        }

        if (currentUser != null) {
          _updateCurrentUserData(currentUser);
        }

        // 🚀 修复：partnerLocation应该始终存储另一半的位置
        // 无论isOneself的值如何，另一半的位置数据都来自halfLocationMobileDevice
        // 所以应该检查halfLocationMobileDevice是否有位置，而不是检查partnerUser
        if (locationDataResult.halfLocationMobileDevice != null) {
          final halfLocationData = locationDataResult.halfLocationMobileDevice!;
          // 检查另一半是否有有效的位置数据
          final hasValidLocation = halfLocationData.latitude != null &&
              halfLocationData.longitude != null &&
              halfLocationData.latitude!.trim().isNotEmpty &&
              halfLocationData.longitude!.trim().isNotEmpty;
          
          if (hasValidLocation) {
            // 使用另一半的数据更新partnerLocation
            _updatePartnerData(halfLocationData);
          } else {
            // 🚀 修复：如果另一半没有位置数据，清空partnerLocation
            debugPrint('📍 另一半没有有效位置数据，清空partnerLocation');
            partnerLocation.value = null;
          }
        } else {
          // 🚀 修复：如果halfLocationMobileDevice为null，清空partnerLocation
          debugPrint('📍 halfLocationMobileDevice为null，清空partnerLocation');
          partnerLocation.value = null;
        }

        _updateLocationRecords(currentUser);
        await _initTrackStartEndMarkers();
      } else {
        if (retryCount < 2 && _shouldRetry(result.msg ?? '')) {
          isLoading.value = false;
          await Future.delayed(Duration(milliseconds: 1000 * (retryCount + 1)));
          return loadLocationData(retryCount: retryCount + 1);
        }
        _showFriendlyError(result.code, result.msg);
      }
    } catch (e, stackTrace) {
      debugPrint(
        'Load location data error: $e\n${stackTrace.toString().split('\n').take(10).join('\n')}',
      );

      if (retryCount < 2) {
        isLoading.value = false;
        await Future.delayed(Duration(milliseconds: 1000 * (retryCount + 1)));
        return loadLocationData(retryCount: retryCount + 1);
      }

      CustomToast.show(Get.context!, '加载位置数据失败，请稍后重试');
    } finally {
      isLoading.value = false;
    }
  }

  bool _shouldRetry(String errorMsg) {
    final msg = errorMsg.toLowerCase();
    return msg.contains('网络') ||
        msg.contains('超时') ||
        msg.contains('连接') ||
        msg.contains('timeout') ||
        msg.contains('connection') ||
        msg.contains('network');
  }

  void _showFriendlyError(int? code, String? msg) {
    String tip;
    final text = (msg ?? '').toLowerCase();

    if (code == 210 || text.contains('repeat')) {
      tip = '操作太频繁啦，请稍后再试';
    } else if (text.contains('网络') ||
        text.contains('超时') ||
        text.contains('timeout') ||
        text.contains('connect') ||
        text.contains('connection')) {
      tip = '网络不太给力，稍等片刻再试试';
    } else if (text.contains('ssl') ||
        text.contains('certificate') ||
        text.contains('handshake')) {
      tip = '网络安全验证失败，请稍后重试';
    } else if (text.contains('host') ||
        text.contains('refused') ||
        text.contains('reset')) {
      tip = '服务器连接异常，请稍后重试';
    } else {
      tip = msg ?? '获取定位数据失败，请稍后重试';
    }

    CustomToast.show(Get.context!, tip);
  }

  // 🚀 使用 LocationDataHelper 简化数据更新
  void _updateMyAvatarData(UserLocationMobileDevice userData) {
    LocationDataHelper.updateAvatarData(
      userData: userData,
      avatarUrl: myAvatar,
      face: myFace,
    );
  }

  void _updatePartnerAvatarData(UserLocationMobileDevice userData) {
    LocationDataHelper.updateAvatarData(
      userData: userData,
      avatarUrl: partnerAvatar,
      face: partnerFace,
      onlineStatus: partnerOnlineStatus,
    );
  }

  /// 🎯 更新我的位置数据（使用接口数据）
  void _updateMyLocationData(UserLocationMobileDevice userData) {
    LocationDataHelper.updateLocationData(
      userData: userData,
      location: myLocation,
    );
  }

  void _updatePartnerLocationData(UserLocationMobileDevice userData) {
    LocationDataHelper.updateLocationData(
      userData: userData,
      location: partnerLocation,
    );
  }

  void _updateActualPartnerLocationData(UserLocationMobileDevice userData) {
    LocationDataHelper.updateLocationData(
      userData: userData,
      location: actualPartnerLocation,
    );
  }

  void _updateCurrentUserData(UserLocationMobileDevice userData) {
    LocationDataHelper.updateCurrentUserData(
      userData: userData,
      myLocation: myLocation,
      deviceModel: myDeviceModel,
      batteryLevel: myBatteryLevel,
      networkName: myNetworkName,
      speed: speed,
      isWifi: isWifi,
      locationTime: locationTime,
      distance: distance,
      updateTime: updateTime,
      weatherIcon: weatherIcon,
      weather: weather,
      currentLocationText: currentLocationText,
    );
  }

  void _updatePartnerData(UserLocationMobileDevice partnerData) {
    LocationDataHelper.updateLocationData(
      userData: partnerData,
      location: partnerLocation,
    );
  }

  // 🚀 使用 LocationDataHelper 简化位置记录更新
  void _updateLocationRecords(UserLocationMobileDevice? userData) {
    locationRecords.clear();

    if (userData?.stops != null && userData!.stops!.isNotEmpty) {
      for (final stop in userData.stops!) {
        final record = LocationDataHelper.createLocationRecord(stop);
        locationRecords.add(record);
      }
    }

    _updatePolylines();
  }

  /// 清空伴侣数据（提取重复逻辑）
  void _clearPartnerData() {
    debugPrint('⚠️ 清空伴侣位置缓存');
    partnerLocation.value = null;
    actualPartnerLocation.value = null;
    partnerAvatar.value = "";
    partnerFace.value = null;
    partnerOnlineStatus.value = null;
  }

  void performBindAction() {
    

    if (Get.context != null) {
      CustomBottomDialog.show(context: Get.context!).then((_) {
        refreshUserInfo();
      });
    }
  }

  /// 位置提醒按钮点击处理
  Future<void> onLocationReminderButtonTap() async {
     

    // 判断绑定状态
    if (!isBindPartner.value) {
      // 未绑定 -> 弹出绑定弹窗
      debugPrint('📍 位置提醒：未绑定，弹出绑定弹窗');
       
      performBindAction();
    } else if (!isVip.value) {
      // 已绑定但非会员 -> 跳转到开通会员页面
      debugPrint('📍 位置提醒：已绑定但非会员，跳转到开通会员页面');
      onOpenMembershipButtonTap();
    } else {
      // 已绑定且是会员 -> 跳转到位置提醒页面
      debugPrint('📍 位置提醒：已绑定且是会员，跳转到位置提醒页面');
      // 从 locationData 中读取另一半定位开关状态（isOpenLocation: 1=已开启）
      bool partnerLocationOpen = true;
      try {
        final locData = locationData.value;
        if (locData?.halfLocationMobileDevice?.isOpenLocation != null) {
          partnerLocationOpen = locData!.halfLocationMobileDevice!.isOpenLocation == 1;
        }
      } catch (e) {
        debugPrint('读取另一半定位开关失败: $e');
      }

      Get.toNamed(
        KissuRoutePath.locationReminder,
        arguments: {
          'partnerLocationOpen': partnerLocationOpen,
          // 标记这是从“添加地点”入口跳转，用于决定是否展示另一半权限弹窗
          'fromAddLocationEntry': true,
        },
      );
    }
  }

  String _getDeviceDetailInfo(String componentText) {
    if (componentText == myDeviceModel.value) {
      return "设备型号：${myDeviceModel.value}";
    } else if (componentText == myBatteryLevel.value) {
      return "当前电量：${myBatteryLevel.value}";
    } else if (componentText == myNetworkName.value) {
      return "网络名称：${myNetworkName.value}";
    }
    return componentText;
  }

  void showTooltip(String text, Offset position) {
    hideTooltip();

    final detailText = _getDeviceDetailInfo(text);
    final screenSize = MediaQuery.of(pageContext).size;
    const padding = 12.0;
    final maxWidth = screenSize.width * 0.75;
    final estimatedHeight = 120.0;

    double left = position.dx;
    double top = position.dy;

    if (left + maxWidth + padding > screenSize.width) {
      left = screenSize.width - maxWidth - padding;
    }

    if (top + estimatedHeight + padding > screenSize.height) {
      top = screenSize.height - estimatedHeight - padding;
    }

    _overlayEntry = OverlayEntry(
      builder: (_) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: hideTooltip,
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              child: Material(
                color: Colors.transparent,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        detailText,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF333333),
                          height: 1.4,
                        ),
                      ),
                    ),
                    Positioned(
                      top: -8,
                      right: -8,
                      child: GestureDetector(
                        onTap: hideTooltip,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.grey,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(pageContext, rootOverlay: true).insert(_overlayEntry!);
  }

  void hideTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void refreshUserInfo() {
    UserManager.refreshUserInfo().then((_) {
      _loadUserInfo();
      loadLocationData();
    });
  }

  /// 开通会员按钮点击
  Future<void> onOpenMembershipButtonTap() async {
   
    // 跳转到会员页面
    Get.toNamed(
      KissuRoutePath.vip,
      arguments: {
        'previousPageName': '定位页面',
        'previousPageId': 'location_page',
      },
    )?.then((_) {
      refreshUserInfo();
    });
  }

  void navigateToQuestionPage(int? problemId) {
  
    if (problemId == null) {
      Get.to(() => const QuestionPage(), transition: Transition.rightToLeft);
      return;
    }

    _navigateToQuestionDetailDirectly(problemId);
  }

  /// 从定位页离线提示点击“查看原因”时
  /// 直接跳转到对应的问题详情页，避免先进入问题列表再二次跳转
  /// 这样返回时也会直接回到定位页，优化返回路径
  Future<void> _navigateToQuestionDetailDirectly(int problemId) async {
    try {
      final settingApi = SettingApi();
      final result = await settingApi.getProblemList();

      if (result.isSuccess && result.data != null) {
        final List<CommonQuestionModel> questions = result.data!;
        CommonQuestionModel? targetQuestion;
        for (final q in questions) {
          if (q.id == problemId) {
            targetQuestion = q;
            break;
          }
        }

        if (targetQuestion != null) {
          final CommonQuestionModel nonNullQuestion = targetQuestion;
          Get.to(
            () => QuestionPageInfo(question: nonNullQuestion),
            transition: Transition.rightToLeft,
          );
          return;
        } else {
          // 未找到对应问题时给出提示，退回到问题列表供用户自行浏览
          OKToastUtil.show('未找到对应的问题信息');
        }
      }
    } catch (e) {
      debugPrint('navigateToQuestionDetailDirectly error: $e');
    }

    // 兜底：如果接口异常或未找到问题，保持原有逻辑，先进入问题列表
    Get.to(
      () => QuestionPage(targetProblemId: problemId),
      transition: Transition.rightToLeft,
    );
  }

  bool _needsUpdateIconCache() {
    // 🎯 不再检查heading变化，heading由_updatePedestalRotation()实时处理
    // 只检查头像、表情等需要重新创建marker的变化
    return _cachedMyAvatar != myAvatar.value ||
        _cachedPartnerAvatar != partnerAvatar.value ||
        _cachedMyFace != myFace.value ||
        _cachedPartnerFace != partnerFace.value ||
        _cachedIsBindPartner != isBindPartner.value;
  }

  Future<void> _updateIconCache() async {
    final markerStartTime = DateTime.now();

    try {
      // 🚀 优化：我的头像Marker（方向变化时不使用全局缓存）
      if (myAvatar.value.isNotEmpty) {
        final cacheKey = MapPreloadService.generateMarkerCacheKey(
          avatarUrl: myAvatar.value,
          faceUrl: myFace.value?.faceUrl,
        );

        // 🎯 只在首次或头像/表情变化时创建marker，不再检查heading
        if (_lastMyCacheKey != cacheKey ||
            _persistentMyIcon == null ||
            _cachedMyAnchor == null) {
          // 尝试从全局缓存获取
          final globalCached = MapPreloadService.instance.getCachedMarker(
            cacheKey,
          );

          if (globalCached != null && _cachedMyAnchor != null) {
            // 只有当anchor已经被计算过时才使用全局缓存
            _persistentMyIcon = globalCached;
            debugPrint('🎯 使用全局缓存的我的Marker');
          } else {
            // 创建新的Marker（不包含底座，底座将作为独立marker）
            final markerData = await _createAvatarMarker(
              myAvatar.value,
              defaultAsset: 'assets/3.0/kissu3_love_avater.webp',
              baseAsset: 'assets/images/kissu_location_run.webp',
              face: myFace.value,
              useLargePedestal: true, // 底座尺寸配置（用于计算anchor）
            );
            _persistentMyIcon = markerData['descriptor'] as BitmapDescriptor;
            _cachedMyAnchor = markerData['anchor'] as Offset;

            // 保存到全局缓存
            MapPreloadService.instance.cacheMarker(
              cacheKey,
              _persistentMyIcon!,
            );
          }

          _lastMyCacheKey = cacheKey;
        }

        // 🎯 底座marker只在首次创建，之后不再重新创建
        if (_persistentMyPedestalIcon == null) {
          _persistentMyPedestalIcon = await _markerBuilder.createPedestalMarker(
            pedestalAsset: 'assets/images/kissu_location_run.webp',
            size: 800.0,
          );
        }

        // 更新缓存标记
        _cachedMyAvatar = myAvatar.value;
        _cachedMyFace = myFace.value;
      }

      // 🚀 优化：Ta的头像Marker（使用全局缓存）
      if (partnerAvatar.value.isNotEmpty) {
        final cacheKey = MapPreloadService.generateMarkerCacheKey(
          avatarUrl: partnerAvatar.value,
          faceUrl: partnerFace.value?.faceUrl,
        );

        // 检查是否需要重新创建
        if (_lastPartnerCacheKey != cacheKey ||
            _persistentPartnerIcon == null ||
            _cachedPartnerAnchor == null) {
          // 先尝试从全局缓存获取
          final globalCached = MapPreloadService.instance.getCachedMarker(
            cacheKey,
          );

          if (globalCached != null && _cachedPartnerAnchor != null) {
            // 只有当anchor已经被计算过时才使用全局缓存
            _persistentPartnerIcon = globalCached;
            debugPrint('🎯 使用全局缓存的Ta的Marker');
          } else {
            // 创建新的Marker（不包含底座，底座是独立marker）
            final markerData = await _createAvatarMarker(
              partnerAvatar.value,
              defaultAsset: 'assets/3.0/kissu3_love_avater.webp',
              baseAsset: 'assets/3.0/kissu3_location_she.webp',
              face: partnerFace.value,
            );
            _persistentPartnerIcon =
                markerData['descriptor'] as BitmapDescriptor;
            _cachedPartnerAnchor = markerData['anchor'] as Offset;

            // 保存到全局缓存
            MapPreloadService.instance.cacheMarker(
              cacheKey,
              _persistentPartnerIcon!,
            );
          }

          _lastPartnerCacheKey = cacheKey;
        }

        // 🎯 伴侣底座marker只在首次创建，之后不再重新创建
        if (_persistentPartnerPedestalIcon == null) {
          _persistentPartnerPedestalIcon = await _markerBuilder
              .createPedestalMarker(
                pedestalAsset: 'assets/3.0/kissu3_location_she.webp',
                size: 40.0,
              );
        }

        // 创建波纹静态背景marker（只创建一次）
        if (_persistentPartnerRippleBgIcon == null) {
          _persistentPartnerRippleBgIcon =
              await _markerBuilder.createRippleBackgroundMarker(
            size: 96.0,
          );
        }

        // 创建波纹圆环marker（只创建一次，带填充渐变和白色边框）
        if (_persistentPartnerRippleIcon == null) {
          _persistentPartnerRippleIcon =
              await _markerBuilder.createRippleRingMarker(
            size: 64.0, // 圆环大小（头像的1.3倍左右）
            color: const Color(0xFFFFA1C7), // 粉色
            strokeWidth: 3.0,
          );
        }

        // 更新缓存标记
        _cachedPartnerAvatar = partnerAvatar.value;
        _cachedPartnerFace = partnerFace.value;
        _cachedIsBindPartner = isBindPartner.value;
      }

      final markerDuration = DateTime.now().difference(markerStartTime);
      debugPrint('📊 Marker创建/缓存耗时: ${markerDuration.inMilliseconds}ms');
    } catch (e) {
      debugPrint('Update icon cache error: $e');
    }
  }

  /// 启动原生呼吸动画（iOS原版实现）
  ///
  /// iOS原版效果：
  /// - 横向拉伸：X=1.03, Y=0.98（横向拉伸，纵向压缩）
  /// - 纵向拉伸：X=0.98, Y=1.03（横向压缩，纵向拉伸）
  /// - 两种状态交替变换，产生自然的“呼吸”效果
  /// - 动画时长：0.4秒（与iOS原版完全一致）
  ///
  /// 性能优势：
  /// - 使用Android原生ScaleAnimation（GPU加速）
  /// - 60fps流畅运行
  /// - 零跨平台通信开销（只调用一次）
  /// - 完全在原生层执行，不占用Flutter线程
  void _startNativeBreathAnimation() async {
    if (mapController == null) {
      debugPrint('⚠️ MapController未初始化，跳过启动动画');
      return;
    }

    try {
      // 为"我的"Marker启动动画（iOS原版参数）
      if (actualMyLocation.value != null) {
        final mySuccess = await mapController!.startMarkerBreathAnimation(
          markerId: 'my_marker',
          duration: 400, // iOS原版：0.4秒
        );
        if (mySuccess) {
          debugPrint('✅ 我的Marker呼吸动画已启动(iOS原版效果)');
        }
      }

      // 为"Ta的"Marker启动动画（iOS原版参数）
      if (isBindPartner.value && actualPartnerLocation.value != null) {
        final partnerSuccess = await mapController!.startMarkerBreathAnimation(
          markerId: 'partner_marker',
          duration: 400, // iOS原版：0.4秒
        );
        if (partnerSuccess) {
          debugPrint('✅ Ta的Marker呼吸动画已启动(iOS原版效果)');
        }
      }
    } catch (e) {
      debugPrint('❌ 启动原生动画失败: $e');
    }
  }

  /// 🎯 停止原生呼吸动画
  void _stopNativeBreathAnimation() async {
    if (mapController == null) return;

    try {
      await mapController!.stopMarkerBreathAnimation(markerId: 'my_marker');
      await mapController!.stopMarkerBreathAnimation(
        markerId: 'partner_marker',
      );
      debugPrint('✅ Marker呼吸动画已停止');
    } catch (e) {
      debugPrint('❌ 停止原生动画失败: $e');
    }
  }

  @override
  void onClose() {
    

    // 🚀 修复：清理定位服务监听器，避免内存泄漏和重复监听
    try {
      _locationServiceWorker?.dispose();
      _locationServiceWorker = null;
      debugPrint('✅ 定位服务监听器已清理');
    } catch (e) {
      debugPrint('Dispose location service worker error: $e');
    }

    // 🚀 清理方向监听器
    try {
      _headingWorker?.dispose();
      _headingWorker = null;
      debugPrint('✅ 方向监听器已清理');
    } catch (e) {
      debugPrint('Dispose heading worker error: $e');
    }

    // 🚀 清理节流定时器
    try {
      _pedestalUpdateTimer?.cancel();
      _pedestalUpdateTimer = null;
      debugPrint('✅ 底座更新定时器已清理');
    } catch (e) {
      debugPrint('Dispose pedestal update timer error: $e');
    }

    // 🚀 清理防抖定时器
    try {
      _markerRebuildTimer?.cancel();
      _markerRebuildTimer = null;
      debugPrint('✅ Marker重建定时器已清理');
    } catch (e) {
      debugPrint('Dispose marker rebuild timer error: $e');
    }

    try {
      hideTooltip();
    } catch (e) {
      debugPrint('Hide tooltip error: $e');
    }

    try {
      tipsManager.onClose();
    } catch (e) {
      debugPrint('Close tips manager error: $e');
    }

    // 🚀 停止原生呼吸动画
    try {
      _stopNativeBreathAnimation();
    } catch (e) {
      debugPrint('Stop native breath animation error: $e');
    }

    // 🎯 停止近距离模式动画
    try {
      if (_isCloseMode) {
        _stopCloseModeAnimations();
      }
    } catch (e) {
      debugPrint('Stop close mode animations error: $e');
    }

    try {
      backButtonAnimationController.dispose();
    } catch (e) {
      debugPrint('Dispose backButtonAnimationController error: $e');
    }

    try {
      switchTransitionController.dispose();
    } catch (e) {
      debugPrint('Dispose switchTransitionController error: $e');
    }

    // 清理缓存字段
    _cachedMyAnchor = null;
    _cachedPartnerAnchor = null;
    _cachedMyAvatar = null;
    _cachedPartnerAvatar = null;
    _cachedMyFace = null;
    _cachedPartnerFace = null;
    _cachedIsBindPartner = null;

    super.onClose();
  }
}

// 🚀 LocationRecord 类已移至 services/location_data_helper.dart
