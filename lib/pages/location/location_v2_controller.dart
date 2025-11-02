import 'dart:async';
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
import 'package:kissu_app/services/tracking_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog.dart';
import 'package:kissu_app/pages/mine/sub_pages/question_page.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/services/map_preload_service.dart';
import 'widgets/location_tips_manager.dart';
import 'services/marker_builder.dart';
import 'services/location_data_helper.dart';

class LocationV2Controller extends GetxController with GetTickerProviderStateMixin {
  final isOneself = 1.obs;  // 默认看自己
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
  final isBackButtonRotated = false.obs;
  final isSwitchingView = false.obs;
  final distance = "".obs;
  final updateTime = "".obs;
  final currentLocationText = "位置信息加载中...".obs;
  final myDeviceModel = "未知".obs;
  final myBatteryLevel = "未知".obs;
  final myNetworkName = "WiFi".obs;
  final speed = "0m/s".obs;
  final isWifi = "1".obs;
  final deviceId = "".obs;
  final locationTime = "".obs;
  final weatherIcon = "".obs;
  final weather = "".obs;
  final RxList<LocationRecord> locationRecords = <LocationRecord>[].obs;
  final Rx<LocationResponseModel?> locationData = Rx<LocationResponseModel?>(null);
  final sheetPercent = 0.3.obs;
  final isLoading = false.obs;
  final mapType = 1.obs;
  
  // 用于跟踪上一次的滑动状态，避免重复埋点
  String _lastScrollStatus = '';

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
  OverlayEntry? _overlayEntry;

  BitmapDescriptor? _cachedMyIcon;
  BitmapDescriptor? _cachedPartnerIcon;
  String? _cachedMyAvatar;
  String? _cachedPartnerAvatar;
  Face? _cachedMyFace;
  Face? _cachedPartnerFace;
  bool? _cachedIsBindPartner;
  
  // 🚀 持久化Marker缓存（跨页面访问复用）
  BitmapDescriptor? _persistentMyIcon;
  BitmapDescriptor? _persistentPartnerIcon;
  String? _lastMyCacheKey;
  String? _lastPartnerCacheKey;

  final RxList<Marker> _trackStartEndMarkers = <Marker>[].obs;
  final RxSet<Polyline> _polylines = <Polyline>{}.obs;
  
  // 🚀 修复：管理 ever 监听器，确保正确清理
  Worker? _locationServiceWorker;

  @override
  void onInit() {
    super.onInit();
    try {
      // 先加载本地用户信息（立即显示）
      _loadUserInfo();
      
      // 🚀 修复：如果未绑定，立即清空伴侣位置缓存
      if (!isBindPartner.value) {
        debugPrint('⚠️ 未绑定状态，清空伴侣位置缓存');
        partnerLocation.value = null;
        actualPartnerLocation.value = null;
        partnerAvatar.value = "";
        partnerFace.value = null;
        partnerOnlineStatus.value = null;
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
      
      // 开始页面浏览事件计时
      _startPageViewTracking();
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
  
  /// 开始页面浏览事件计时
  Future<void> _startPageViewTracking() async {
    try {
      // 获取位置权限状态
      final locationStatus = await Permission.location.status;
      final hasLocation = locationStatus.isGranted;
      
      await TrackingService.trackLocationPageBegin(
        isBindPartner: isBindPartner.value,
        isVip: isVip.value,
        hasLocation: hasLocation,
      );
    } catch (e) {
      debugPrint('开始页面浏览事件计时失败: $e');
    }
  }
  
  /// 结束页面浏览事件计时
  Future<void> _endPageViewTracking() async {
    try {
      // 获取位置权限状态
      final locationStatus = await Permission.location.status;
      final hasLocation = locationStatus.isGranted;
      
      await TrackingService.trackLocationPageEnd(
        isBindPartner: isBindPartner.value,
        isVip: isVip.value,
        hasLocation: hasLocation,
      );
    } catch (e) {
      debugPrint('结束页面浏览事件计时失败: $e');
    }
  }

  void _initBackButtonAnimation() {
    backButtonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    backButtonRotationAnimation = Tween<double>(
      begin: 0.0,
      end: -0.25,
    ).animate(CurvedAnimation(
      parent: backButtonAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _initSwitchTransitionAnimation() {
    switchTransitionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    switchTransitionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: switchTransitionController,
      curve: Curves.easeInOut,
    ));
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
      
      // 根据百分比判断当前所处的滑动状态
      _trackScrollStatus(percent);
    });
  }
  
  /// 跟踪下半屏滑动状态埋点
  void _trackScrollStatus(double percent) {
    String currentStatus = _getScrollStatus(percent);
    
    // 只有当状态发生变化时才触发埋点
    if (currentStatus != _lastScrollStatus && currentStatus.isNotEmpty) {
      _lastScrollStatus = currentStatus;
      TrackingService.trackSwipeOperation(
        isVip: isVip.value,
        scrollStatus: currentStatus,
      );
    }
  }
  
  /// 根据百分比获取滑动状态
  String _getScrollStatus(double percent) {
    // 定义三个状态的阈值范围
    // 小屏（底部）：0.15 - 0.35
    // 中屏（中间）：0.45 - 0.65
    // 大屏（顶部）：0.80 - 0.95
    
    if (percent >= 0.15 && percent < 0.35) {
      return '小屏';
    } else if (percent >= 0.45 && percent < 0.65) {
      return '中屏';
    } else if (percent >= 0.80 && percent <= 0.95) {
      return '大屏';
    }
    
    // 处于过渡状态，不触发埋点
    return '';
  }
  

  void handleBackButtonTap([ScrollController? scrollController]) {
    if (isBackButtonRotated.value) {
      _scrollToBottom(scrollController);
    } else {
      Get.back();
    }
  }

  void setDraggableController(DraggableScrollableController controller) {
    _draggableController = controller;
  }

  void _scrollToBottom([ScrollController? scrollController]) {
    if (_draggableController != null) {
      _draggableController!.animateTo(
        0.3,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ).then((_) {
        if (scrollController != null && scrollController.hasClients) {
          scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
          );
        }
      });
    }
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
    loadLocationData().then((_) {
      debugPrint('📊 位置数据加载完成');
    }).catchError((e) {
      debugPrint('位置数据加载失败: $e');
    });
    
    // 并行检查定位权限
    _checkLocationPermissionOnPageEnter().then((_) {
      debugPrint('📊 定位权限检查完成');
    }).catchError((e) {
      debugPrint('定位权限检查失败: $e');
    });
  }

  void _initLocationService() {
    try {
      _locationService = SimpleLocationService.instance;
      
      // 🚀 优化：无论绑定与否，自己的位置都优先使用实时定位数据
      // 实时定位数据更新时，marker位置也要跟着更新
      // 🚀 修复：将 ever 返回的 Worker 保存起来，以便在 onClose 时清理
      _locationServiceWorker = ever(_locationService.currentLocation, (location) {
        if (location != null) {
          debugPrint('📍 监听到定位服务位置更新，使用真实定位数据（优先级高于接口）');
          
          // 解析位置
          final lat = double.tryParse(location.latitude);
          final lng = double.tryParse(location.longitude);
          
          if (lat != null && lng != null) {
            final newPosition = LatLng(lat, lng);
            final isFirstTime = actualMyLocation.value == null;
            
            // 🚀 优化：始终更新为真实定位数据（无论是否绑定）
            debugPrint('🎯 更新actualMyLocation为真实定位: $newPosition');
            actualMyLocation.value = newPosition;
            
            // 🚀 修复：只有在地图已初始化时才更新marker，避免Channel未初始化错误
            if (mapController != null) {
              _initTrackStartEndMarkers();
            } else {
              debugPrint('⚠️ 地图未初始化，暂不更新marker（等待地图创建完成）');
            }
            
            // 第一次获取位置时，移动相机（未绑定时才自动移动）
            if (isFirstTime && !isBindPartner.value && mapController != null) {
              Future.delayed(const Duration(milliseconds: 100), () {
                mapController?.moveCamera(
                  CameraUpdate.newLatLngZoom(newPosition, 18.0),
                  animated: true,
                  duration: 300, // 0.3秒动画时长
                );
              });
            }
          }
        }
      });
      
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

  // 🚀 使用 MarkerBuilder 创建头像标记
  Future<BitmapDescriptor> _createAvatarMarker(
    String avatarUrl, {
    String? defaultAsset,
    required String baseAsset,
    Face? face,
  }) async {
    return _markerBuilder.createAvatarMarker(
      avatarUrl,
      defaultAsset: defaultAsset,
      baseAsset: baseAsset,
      face: face,
    );
  }

  Future<void> _initTrackStartEndMarkers() async {
    _trackStartEndMarkers.clear();

    if (_needsUpdateIconCache()) {
      await _updateIconCache();
    }

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
            final BitmapDescriptor myIcon = _cachedMyIcon ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);

            final capturedPos = myPos; // 捕获非空值到局部变量
            final myMarker = Marker(
              position: capturedPos,
              icon: myIcon,
              anchor: const Offset(0.5, 1.0),
              onTap: (String markerId) {
                _moveMapToLocation(capturedPos);
              },
            );
            myMarker.setIdForCopy('my_marker');
            tempMarkers.add(myMarker);
          } catch (e) {
            debugPrint('Create my marker error: $e');
          }
        }
      } else {
        // 已绑定时显示两个人的位置
      final LatLng? myPos = actualMyLocation.value ?? myLocation.value;
      if (myPos != null) {
        try {
          final BitmapDescriptor myIcon = _cachedMyIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);

          final myMarker = Marker(
            position: myPos,
            icon: myIcon,
            anchor: const Offset(0.5, 1.0),
            onTap: (String markerId) {
              _moveMapToLocation(myPos);
            },
          );
          myMarker.setIdForCopy('my_marker');
          tempMarkers.add(myMarker);
        } catch (e) {
          debugPrint('Create my marker error: $e');
        }
      }

      final LatLng? partnerPos = actualPartnerLocation.value ?? partnerLocation.value;
      if (partnerPos != null) {
        try {
          final BitmapDescriptor partnerIcon = _cachedPartnerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

          final partnerMarker = Marker(
            position: partnerPos,
            icon: partnerIcon,
            anchor: const Offset(0.5, 1.0),
            onTap: (String markerId) {
              _moveMapToLocation(partnerPos);
            },
          );
          partnerMarker.setIdForCopy('partner_marker');
          tempMarkers.add(partnerMarker);
        } catch (e) {
          debugPrint('Create partner marker error: $e');
          }
        }
      }

      if (tempMarkers.isNotEmpty) {
        _trackStartEndMarkers.value = tempMarkers;
        // 🚀 使用原生呼吸动画（性能优秀，60fps流畅）
        _startNativeBreathAnimation();
      } else {
        _trackStartEndMarkers.clear();
        _stopNativeBreathAnimation();
      }
    } catch (e) {
      debugPrint('Init track markers error: $e');
    }
  }

  void _moveMapToLocation(LatLng location) {
    if (mapController != null) {
      mapController!.moveCamera(
        CameraUpdate.newLatLngZoom(location, 16.0),
      );
    }
  }

  void _updatePolylines() {
    _polylines.clear();

    // 未绑定时不显示连线
    if (!isBindPartner.value) {
      return;
    }

    if (myLocation.value != null && partnerLocation.value != null) {
      final List<LatLng> connectionPoints = [
        myLocation.value!,
        partnerLocation.value!,
      ];

      _polylines.add(Polyline(
        points: connectionPoints,
        color: const Color(0xFFFF4B99),
        width: 6,
        visible: true,
        alpha: 1.0,
        dashLineType: DashLineType.circle,
        capType: CapType.round,
      ));
    }
  }

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

      debugPrint('📍 双人位置：我(${myPos.latitude}, ${myPos.longitude}) 伴侣(${partnerPos.latitude}, ${partnerPos.longitude}) 中心($center)');
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
      _initTrackStartEndMarkers();
    } else if (myLocation.value != null || partnerLocation.value != null) {
      _initTrackStartEndMarkers();
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mapController != null && isClosed == false) {
        _animateMapToShowBothUsersAsync();
      }
    });
  }

  void _animateMapToLocation(LatLng location) {
    if (mapController == null) return;
    try {
      unawaited(mapController!.moveCamera(
        CameraUpdate.newLatLngZoom(location, 16.0),
        animated: true,
        duration: 1500,
      ));
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
            duration: 500,
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
        final double swLat = myPos.latitude < partnerPos.latitude ? myPos.latitude : partnerPos.latitude;
        final double swLng = myPos.longitude < partnerPos.longitude ? myPos.longitude : partnerPos.longitude;
        final double neLat = myPos.latitude > partnerPos.latitude ? myPos.latitude : partnerPos.latitude;
        final double neLng = myPos.longitude > partnerPos.longitude ? myPos.longitude : partnerPos.longitude;
        
        final bounds = LatLngBounds(
          southwest: LatLng(swLat, swLng),
          northeast: LatLng(neLat, neLng),
        );
        
        debugPrint('📍 已绑定，使用原生LatLngBounds移动地图到双人中心位置');
        debugPrint('📍 bounds: southwest($swLat, $swLng), northeast($neLat, $neLng)');
        
        await mapController!.moveCamera(
          CameraUpdate.newLatLngBounds(bounds, 100), // 100像素边距
          animated: true,
          duration: 500,
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

    // 人物切换按钮埋点
    await TrackingService.trackCharacterSwitch(isMyself: isMyself);

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
          const Duration(milliseconds: 500),
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

  Future<void> _moveToTargetUserLocationInstant(bool isMyself) async {
    if (mapController == null) return;

    LatLng? targetLocation;
    if (isMyself) {
      targetLocation = actualMyLocation.value;
    } else {
      targetLocation = actualPartnerLocation.value;
    }

    if (targetLocation == null) return;

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
      // 地图模式切换埋点
      _trackMapModeSwitch(type);
    }
  }
  
  /// 地图模式切换埋点
  Future<void> _trackMapModeSwitch(int mapType) async {
    await TrackingService.trackMapModeSwitch(mapType: mapType);
  }

  Future<void> refreshLocationData() async {
    // 刷新地图按钮埋点
    await _trackRefreshMapButton();
    await loadLocationData();
  }
  
  /// 刷新地图按钮埋点
  Future<void> _trackRefreshMapButton() async {
    await TrackingService.trackRefreshMapButton();
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
          partnerLocation.value = null;
          actualPartnerLocation.value = null;
          partnerAvatar.value = "";
          partnerFace.value = null;
          partnerOnlineStatus.value = null;
          // 强制设置为看自己
          isOneself.value = 1;
        } else {
          // 已绑定时，更新头像和对方数据
          debugPrint('✅ [已绑定] 更新头像和对方位置数据');
          
          if (locationDataResult.userLocationMobileDevice != null) {
            _updateMyAvatarData(locationDataResult.userLocationMobileDevice!);
            
            // 🚀 优化：如果有实时定位数据，就不用接口数据更新自己的位置
            if (actualMyLocation.value == null) {
              debugPrint('📍 [已绑定] 没有实时定位数据，使用接口数据作为备用');
              _updateActualMyLocationData(locationDataResult.userLocationMobileDevice!);
            } else {
              debugPrint('📍 [已绑定] 已有实时定位数据，保持使用（接口数据作为备用）');
            }
          }
          
          // 对方的位置正常使用接口数据
          if (locationDataResult.halfLocationMobileDevice != null) {
            _updatePartnerAvatarData(locationDataResult.halfLocationMobileDevice!);
            _updateActualPartnerLocationData(locationDataResult.halfLocationMobileDevice!);
          }
        }

        UserLocationMobileDevice? currentUser;
        UserLocationMobileDevice? partnerUser;

        // 未绑定时只使用自己的数据
        if (!isBindPartner.value) {
          currentUser = locationDataResult.userLocationMobileDevice;
          partnerUser = null;
        } else if (isOneself.value == 1) {
          currentUser = locationDataResult.userLocationMobileDevice;
          partnerUser = locationDataResult.halfLocationMobileDevice;
        } else {
          currentUser = locationDataResult.halfLocationMobileDevice;
          partnerUser = locationDataResult.userLocationMobileDevice;
        }

        if (currentUser != null) {
          _updateCurrentUserData(currentUser);
        }

        if (partnerUser != null) {
          _updatePartnerData(partnerUser);
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
      debugPrint('Load location data error: $e\n${stackTrace.toString().split('\n').take(10).join('\n')}');

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

  void _updateActualMyLocationData(UserLocationMobileDevice userData) {
    LocationDataHelper.updateLocationData(
      userData: userData,
      location: actualMyLocation,
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

  void performBindAction() {
    // 立即去绑定按钮埋点
    _trackBindNowButton();
    
    if (Get.context != null) {
      CustomBottomDialog.show(context: Get.context!).then((_) {
        refreshUserInfo();
      });
    }
  }
  
  /// 立即去绑定按钮埋点
  Future<void> _trackBindNowButton() async {
    await TrackingService.trackBindNowButton();
  }

  /// 位置提醒按钮点击处理
  Future<void> onLocationReminderButtonTap() async {
    // 埋点：位置提醒按钮点击
    await TrackingService.trackLocationReminderButton();
    
    // 判断绑定状态
    if (!isBindPartner.value) {
      // 未绑定 -> 弹出绑定弹窗
      debugPrint('📍 位置提醒：未绑定，弹出绑定弹窗');
      // 上报埋点：定位-立刻去绑定（位置提醒未绑定场景）
      await TrackingService.trackLocationToBind();
      performBindAction();
    } else if (!isVip.value) {
      // 已绑定但非会员 -> 跳转到开通会员页面
      debugPrint('📍 位置提醒：已绑定但非会员，跳转到开通会员页面');
      onOpenMembershipButtonTap();
    } else {
      // 已绑定且是会员 -> 跳转到位置提醒页面
      debugPrint('📍 位置提醒：已绑定且是会员，跳转到位置提醒页面');
      Get.toNamed(KissuRoutePath.locationReminder);
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
    // 开通会员按钮埋点
    await TrackingService.trackOpenMembershipButton();
    
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
    // 离线提示"查看原因"埋点
    TrackingService.trackLocationOfflineReason();
    
    if (problemId == null) {
      Get.to(
        () => const QuestionPage(),
        transition: Transition.rightToLeft,
      );
      return;
    }
    Get.to(
      () => QuestionPage(targetProblemId: problemId),
      transition: Transition.rightToLeft,
    );
  }

  bool _needsUpdateIconCache() {
    return _cachedMyAvatar != myAvatar.value ||
        _cachedPartnerAvatar != partnerAvatar.value ||
        _cachedMyFace != myFace.value ||
        _cachedPartnerFace != partnerFace.value ||
        _cachedIsBindPartner != isBindPartner.value;
  }

  Future<void> _updateIconCache() async {
    final markerStartTime = DateTime.now();
    
    try {
      // 🚀 优化：我的头像Marker（使用全局缓存）
      if (myAvatar.value.isNotEmpty) {
        final cacheKey = MapPreloadService.generateMarkerCacheKey(
          avatarUrl: myAvatar.value,
          faceUrl: myFace.value?.faceUrl,
        );
        
        // 检查是否需要重新创建
        if (_lastMyCacheKey != cacheKey || _persistentMyIcon == null) {
          // 先尝试从全局缓存获取
          final globalCached = MapPreloadService.instance.getCachedMarker(cacheKey);
          
          if (globalCached != null) {
            _persistentMyIcon = globalCached;
            debugPrint('🎯 使用全局缓存的我的Marker');
          } else {
            // 创建新的Marker
            _persistentMyIcon = await _createAvatarMarker(
              myAvatar.value,
              defaultAsset: 'assets/kissu3_love_avater.webp',
              baseAsset: 'assets/3.0/kissu3_location_she.webp',
              face: myFace.value,
            );
            
            // 保存到全局缓存
            MapPreloadService.instance.cacheMarker(cacheKey, _persistentMyIcon!);
          }
          
          _lastMyCacheKey = cacheKey;
        }
        
        _cachedMyIcon = _persistentMyIcon;
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
        if (_lastPartnerCacheKey != cacheKey || _persistentPartnerIcon == null) {
          // 先尝试从全局缓存获取
          final globalCached = MapPreloadService.instance.getCachedMarker(cacheKey);
          
          if (globalCached != null) {
            _persistentPartnerIcon = globalCached;
            debugPrint('🎯 使用全局缓存的Ta的Marker');
          } else {
            // 创建新的Marker
            _persistentPartnerIcon = await _createAvatarMarker(
              partnerAvatar.value,
              defaultAsset: 'assets/kissu3_love_avater.webp',
              baseAsset: 'assets/3.0/kissu3_location_she.webp',
              face: partnerFace.value,
            );
            
            // 保存到全局缓存
            MapPreloadService.instance.cacheMarker(cacheKey, _persistentPartnerIcon!);
          }
          
          _lastPartnerCacheKey = cacheKey;
        }
        
        _cachedPartnerIcon = _persistentPartnerIcon;
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

  /// 🎯 启动原生呼吸动画（iOS原版实现）
  /// 
  /// 🎨 iOS原版效果：
  /// - 横向拉伸：X=1.03, Y=0.98（横向拉伸3%，纵向压缩2%）
  /// - 纵向拉伸：X=0.98, Y=1.03（横向压缩2%，纵向拉伸3%）
  /// - 两种状态交替变换，产生自然的"呼吸"效果
  /// - 动画时长：0.4秒（与iOS原版完全一致）
  /// 
  /// ✅ 性能优势：
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
          duration: 400,  // iOS原版：0.4秒
        );
        if (mySuccess) {
          debugPrint('✅ 我的Marker呼吸动画已启动(iOS原版效果)');
        }
      }

      // 为"Ta的"Marker启动动画（iOS原版参数）
      if (isBindPartner.value && actualPartnerLocation.value != null) {
        final partnerSuccess = await mapController!.startMarkerBreathAnimation(
          markerId: 'partner_marker',
          duration: 400,  // iOS原版：0.4秒
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
      await mapController!.stopMarkerBreathAnimation(markerId: 'partner_marker');
      debugPrint('✅ Marker呼吸动画已停止');
    } catch (e) {
      debugPrint('❌ 停止原生动画失败: $e');
    }
  }

  @override
  void onClose() {
    // 结束页面浏览事件计时
    _endPageViewTracking();
    
    // 🚀 修复：清理定位服务监听器，避免内存泄漏和重复监听
    try {
      _locationServiceWorker?.dispose();
      _locationServiceWorker = null;
      debugPrint('✅ 定位服务监听器已清理');
    } catch (e) {
      debugPrint('Dispose location service worker error: $e');
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

    _cachedMyIcon = null;
    _cachedPartnerIcon = null;
    _cachedMyAvatar = null;
    _cachedPartnerAvatar = null;
    _cachedMyFace = null;
    _cachedPartnerFace = null;
    _cachedIsBindPartner = null;

    super.onClose();
  }
}
// 🚀 LocationRecord 类已移至 services/location_data_helper.dart
