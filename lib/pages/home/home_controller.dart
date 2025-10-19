import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:kissu_app/utils/pag_preloader.dart'; // 注释掉PAG预加载器导入
import 'package:kissu_app/services/home_scroll_service.dart';
import 'package:kissu_app/pages/location/location_v2_binding.dart';
import 'package:kissu_app/pages/location/location_v2_page.dart';
import 'package:kissu_app/pages/mine/mine_binding.dart';
import 'package:kissu_app/pages/mine/mine_page.dart';
import 'package:kissu_app/pages/usage_report/usage_report_binding.dart';
import 'package:kissu_app/pages/usage_report/usage_report_page.dart';
import 'package:kissu_app/pages/track/track_binding.dart';
import 'package:kissu_app/pages/track/track_page.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/utils/screen_adaptation.dart';
import 'package:kissu_app/widgets/dialogs/dialog_manager.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';
import 'package:kissu_app/widgets/guide_overlay_widget.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog.dart';
import 'package:kissu_app/services/simple_location_service.dart';
import 'package:kissu_app/services/app_lifecycle_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kissu_app/pages/agreement/agreement_webview_page.dart';
import 'package:kissu_app/network/public/location_api.dart';
import 'package:kissu_app/network/public/auth_service.dart';
import 'package:kissu_app/network/public/service_locator.dart';
import 'package:kissu_app/network/public/index_api.dart';
// import 'package:kissu_app/utils/memory_manager.dart'; // 注释掉未使用的导入
import 'dart:math';
import 'dart:async';
import 'package:kissu_app/services/version_service.dart';
// import 'package:kissu_app/widgets/pag_animation_widget.dart'; // 暂时移除PAG依赖


class HomeController extends GetxController {
  // 后面可以加逻辑，比如当前选中的按钮索引
  var selectedIndex = 0.obs;
  
  // App启动标记 - 静态变量，app被杀掉时会自动重置
  static bool _hasAppStartedThisSession = false;
  
  // 绑定弹窗控制标志位 - 静态变量，确保整个app会话期间只显示一次
  static bool _hasShownBindingDialogThisSession = false;
  
  // VIP购买弹窗控制标志位 - 静态变量，确保整个app会话期间只显示一次
  static bool _hasShownVipDialogThisSession = false;
  
  // 防重复刷新用户信息的变量
  bool _isRefreshingUserInfo = false;
  DateTime? _lastUserInfoRefreshTime;
  
  // 滚动控制器，用于控制背景图片的初始位置
  late ScrollController scrollController;
  
  // 绑定状态
  var isBound = false.obs;
  
  // 轮播图当前索引
  var currentSwiperIndex = 0.obs;
  
  // 视图模式：true=屏视图，false=岛视图（默认屏视图）
  var isScreenView = true.obs;
  
  // 头像信息
  var userAvatar = "assets/kissu3_love_avater.webp".obs;
  var partnerAvatar = "assets/kissu_home_add_avair.webp".obs;
  
  // 定位服务相关
  late SimpleLocationService _locationService;
  var isLocationPermissionRequested = false.obs;
  var isLocationServiceStarted = false.obs;
  
  // 认证服务相关
  late AuthService _authService;
  
  // 红点相关
  var redDotCount = 0.obs;
  var systemNoticeRedDot = 0.obs; // 系统消息红点数量
  var interactionNoticeRedDot = 0.obs; // 互动消息红点数量
  var isRedDot = false.obs; // 是否显示红点（基于is_red_dot字段）
  var isActivity = false.obs;
  var activityIcon = ''.obs;
  var activityLink = ''.obs;
  var activityTitle = ''.obs;
  
  // 距离信息
  var distance = "0KM".obs;
  
  // 停留点数量
  var stayCount = 0.obs;
  
  // 恋爱天数
  var loveDays = 0.obs;
  
  // 天气数据相关
  var weatherIconUrl = Rxn<String>();
  var weather = Rxn<String>();
  var minTemp = Rxn<String>();
  var maxTemp = Rxn<String>();
  var currentTemp = Rxn<String>();
  var isWeatherLoading = true.obs;
  
  // 照片墙数据
  var photoWallUrl = "assets/kissu_icon.webp".obs;
  
  // 引导层显示状态
  var showGuideOverlay = false.obs;
  
  // 当前引导图类型
  var currentGuideType = GuideType.swipe.obs;
  
  
  // PAG动画相关 - 暂时移除
  // var pagAnimations = <Map<String, dynamic>>[].obs;
  
  // 红点轮询定时器
  Timer? _redDotPollingTimer;
  
  // 应用生命周期服务
  late AppLifecycleService _appLifecycleService;
  
  // 应用生命周期监听
  StreamSubscription<AppLifecycleState>? _appLifecycleSubscription;

  @override
  void onInit() {
    super.onInit();
    
    debugPrint('🏠 HomeController 初始化 - 绑定弹窗标志位状态: $_hasShownBindingDialogThisSession');
    
    // 检查是否是app启动时首次进入
    checkAndRefreshUserInfoOnAppStartup();
    
    // 初始化滚动控制器，如果有预设位置则使用预设位置
    _initializeScrollController();
    
    // 初始化认证服务
    _authService = getIt<AuthService>();
    
    // 预加载首页PAG资源 (已注释)
    // _preloadPagAssets();
    
    _initializeLocationService();
    loadIndexData(); // 加载首页所有数据（替代原来的分别加载）
    _loadViewMode(); // 加载视图模式
    _startRedDotPolling(); // 启动红点轮询
    _setupAppLifecycleListener(); // 设置应用生命周期监听
    _setupRedDotListeners(); // 设置红点监听器
  }

  @override
  void onReady() {
    super.onReady();
    
    // 检查版本更新（在引导图和其他弹窗之前检查）
    _checkVersionUpdate();
    
    // 注意：引导图检查将在数据加载完成后执行，确保绑定状态已获取
    // 在 loadIndexData() 完成后会调用 _checkAndShowGuide1()
    
    // 注意：绑定弹窗将在所有其他弹窗之后显示，在_executeOtherLogic()中调用
  }
  
  /// 页面重新获得焦点时的回调（从其他页面返回时会调用）
  void onPageResumed() {
    debugPrint('🏠 首页重新获得焦点，不需要刷新用户信息（已在onInit中处理）');
  }
  
  
  /// 预加载首页PAG资源 (已注释)
  // void _preloadPagAssets() {
  //   // 异步预加载，不阻塞页面初始化
  //   Future.microtask(() async {
  //     try {
  //       await PagPreloader.preloadHomePagAssets();
  //       debugPrint('🎬 首页PAG资源预加载完成');
  //     } catch (e) {
  //       debugPrint('🎬 首页PAG资源预加载失败: $e');
  //     }
  //   });
  // }

  /// 初始化滚动控制器，如果有预设位置则使用预设位置
  void _initializeScrollController() {
    try {
      final homeScrollService = Get.find<HomeScrollService>();
      
      if (homeScrollService.hasPresetPosition) {
        // 使用预设的滚动位置创建ScrollController
        final presetOffset = homeScrollService.presetScrollOffset!;
        scrollController = ScrollController(initialScrollOffset: presetOffset);
        
        // 使用后清除预设位置
        homeScrollService.clearPresetPosition();
        
        debugPrint('✅ 使用预设滚动位置创建ScrollController: ${presetOffset}');
      } else {
        // 没有预设位置，使用默认居中偏移
        _setDefaultCenterOffset();
        debugPrint('⚠️ 没有预设位置，使用默认居中偏移');
      }
    } catch (e) {
      // 如果获取服务失败，使用默认居中偏移
      _setDefaultCenterOffset();
      debugPrint('❌ 获取HomeScrollService失败，使用默认居中偏移: $e');
    }
  }
  
  /// 设置默认的居中偏移
  void _setDefaultCenterOffset() {
    // 使用屏幕适配工具计算滚动偏移
    final defaultOffset = ScreenAdaptation.getPresetScrollOffset();
    
    scrollController = ScrollController(initialScrollOffset: defaultOffset);
    debugPrint('🎯 使用自适应居中偏移创建ScrollController: 屏幕宽度=${ScreenAdaptation.screenWidth}, 动态背景宽度=${ScreenAdaptation.getDynamicContainerSize().width}, 默认偏移=${defaultOffset}');
  }
  
  @override
  void onClose() {
    debugPrint('🧹 HomeController 销毁 - 绑定弹窗标志位: $_hasShownBindingDialogThisSession, VIP弹窗标志位: $_hasShownVipDialogThisSession（静态变量不会被清除）');
    
    // 安全地清理ScrollController
    try {
      scrollController.dispose();
    } catch (e) {
      debugPrint('清理ScrollController时出错: $e');
    }
    
    // 清理PAG动画缓存资源 (已注释)
    // try {
    //   MemoryManager.clearAllCaches();
    //   debugPrint('🧹 首页Controller销毁，清理资源');
    // } catch (e) {
    //   debugPrint('清理资源时出错: $e');
    // }
    
    // 停止红点轮询
    _stopRedDotPolling();
    
    // 取消应用生命周期监听
    _appLifecycleSubscription?.cancel();
    
    super.onClose();
  }
  
  /// 初始化定位服务
  void _initializeLocationService() {
    try {
      // 获取定位服务实例
      _locationService = SimpleLocationService.instance;

      // 只检查权限状态，不自动启动服务
      _checkLocationPermissionStatusOnly();
    } catch (e) {
      debugPrint('初始化定位服务失败: $e');
    }
  }

  /// 首页请求定位权限并启动服务（仅在第一次进入时）
  Future<void> _requestLocationPermissionOnHomePage() async {
    try {
      debugPrint('🏠 首页开始请求定位权限...');

      // 检查是否已经请求过权限
      final prefs = await SharedPreferences.getInstance();
      bool hasRequested = prefs.getBool('location_permission_requested') ?? false;
      
      if (hasRequested) {
        debugPrint('🏠 已请求过定位权限，直接检查服务状态');
        await _checkLocationServiceStatus();
        return;
      }

      debugPrint('🏠 首次进入首页，开始请求定位权限');

      // 请求定位权限
      bool hasPermission = await _locationService.requestLocationPermission();

      if (hasPermission) {
        debugPrint('🏠 首页定位权限获取成功');
        await _handleLocationPermissionGranted();
      } else {
        debugPrint('🏠 首页定位权限被拒绝');
        await _handleLocationPermissionDenied();
      }

      // 标记已请求过权限
      await prefs.setBool('location_permission_requested', true);
      
      debugPrint('🏠 定位权限申请流程完成');
    } catch (e) {
      debugPrint('🏠 首页请求定位权限失败: $e');
    }
  }

  /// 检查定位服务状态
  Future<void> _checkLocationServiceStatus() async {
    try {
      if (!_locationService.isLocationEnabled.value) {
        debugPrint('🏠 首页启动定位服务...');
        bool started = await _locationService.startLocation();

        if (started) {
          isLocationServiceStarted.value = true;
          debugPrint('🏠 首页定位服务启动成功');
        } else {
          debugPrint('🏠 首页定位服务启动失败');
        }
      } else {
        debugPrint('🏠 首页定位服务已在运行');
        isLocationServiceStarted.value = true;
      }
    } catch (e) {
      debugPrint('🏠 首页检查定位服务状态失败: $e');
    }
  }

  /// 处理定位权限获取成功
  Future<void> _handleLocationPermissionGranted() async {
    try {
      debugPrint('🎯 首页用户同意定位权限，启动定位服务');
      
      // 启动定位服务
      bool success = await _locationService.startLocation();
      
      if (success) {
        isLocationServiceStarted.value = true;
        debugPrint('✅ 首页定位服务启动成功');
        
        // 显示成功提示
        CustomToast.show(
          Get.context!,
          '定位服务已启动，开始记录您的足迹',
        );
      } else {
        debugPrint('❌ 首页定位服务启动失败');
        CustomToast.show(
          Get.context!,
          '定位服务启动失败，请检查定位设置',
        );
      }
    } catch (e) {
      debugPrint('处理首页定位权限同意失败: $e');
    }
  }

  /// 处理定位权限被拒绝
  Future<void> _handleLocationPermissionDenied() async {
    try {
      debugPrint('❌ 首页定位权限被拒绝');
      CustomToast.show(
        Get.context!,
        '需要定位权限来记录您的足迹，可在设置中开启',
      );
    } catch (e) {
      debugPrint('处理首页定位权限拒绝失败: $e');
    }
  }
  
  /// 只检查定位权限状态，不自动启动服务
  Future<void> _checkLocationPermissionStatusOnly() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasRequested = prefs.getBool('location_permission_requested') ?? false;
      
      if (hasRequested) {
        // 已经请求过权限，检查服务状态（但不自动启动）
        debugPrint('已请求过定位权限，检查服务状态');
        if (_locationService.isLocationEnabled.value) {
          isLocationServiceStarted.value = true;
        }
      }
    } catch (e) {
      debugPrint('检查定位权限状态失败: $e');
    }
  }

  
  /// 请求定位权限并启动服务
  Future<void> _requestLocationPermissionAndStartService() async {
    try {
      isLocationPermissionRequested.value = true;
      
      // 请求定位权限
      bool hasPermission = await _locationService.requestLocationPermission();
      
      if (hasPermission) {
        // 权限获取成功，启动定位服务
        debugPrint('定位权限获取成功，启动定位服务');
        bool started = await _locationService.startLocation();
        
        if (started) {
          isLocationServiceStarted.value = true;
          debugPrint('定位服务启动成功，开始记录和上报位置');
          
          // 保存已请求权限的状态
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('location_permission_requested', true);
          
          // 显示成功提示
          CustomToast.show(
            Get.context!,
            '定位服务已启动，开始记录您的足迹',
          );
        } else {
          debugPrint('定位服务启动失败');
          CustomToast.show(
            Get.context!,
            '定位服务启动失败，请检查定位设置',
          );
        }
      } else {
        debugPrint('定位权限被拒绝');
        CustomToast.show(
          Get.context!,
          '需要定位权限来记录您的足迹',
        );
      }
    } catch (e) {
      debugPrint('请求定位权限并启动服务失败: $e');
      CustomToast.show(
        Get.context!,
        '定位服务初始化失败',
      );
    }
  }
  
  /// 加载首页所有数据（新的统一接口）
  Future<void> loadIndexData() async {
    try {
      debugPrint('🏠 开始加载首页数据...');
      
      final result = await IndexApi().getIndexData();
      
      if (result.isSuccess && result.data != null) {
        final indexData = result.data!;
        
        // 更新红点信息
        systemNoticeRedDot.value = indexData.isSystemNoticeRedDot;
        interactionNoticeRedDot.value = indexData.isInteractionNoticeRedDot;
        // 是否显示红点（基于is_red_dot字段）
        isRedDot.value = indexData.isRedDot == 1;
        // 红点总数 = 系统消息红点 + 互动消息红点（保留用于其他逻辑）
        redDotCount.value = systemNoticeRedDot.value + interactionNoticeRedDot.value;
        isActivity.value = indexData.activity.isActivity == 1;
        activityIcon.value = indexData.activity.isActivityIcon;
        activityLink.value = indexData.activity.activityLink;
        activityTitle.value = indexData.activity.activityTitle;
        
        debugPrint('📊 红点信息更新: 系统消息=${systemNoticeRedDot.value}, 互动消息=${interactionNoticeRedDot.value}, 总数=${redDotCount.value}, 显示红点=${isRedDot.value}');
        
        // 更新位置信息
        distance.value = indexData.location.distance;
        stayCount.value = indexData.location.stayCount;
        
        // 更新用户信息
        loveDays.value = indexData.user.loverDays;
        isBound.value = indexData.user.isBind == 1;
        
        // 更新头像
        if (indexData.user.headPortrait.isNotEmpty) {
          userAvatar.value = indexData.user.headPortrait;
        }
        
        if (isBound.value && indexData.user.halfHeadPortrait.isNotEmpty) {
          partnerAvatar.value = indexData.user.halfHeadPortrait;
        } else if (!isBound.value) {
          partnerAvatar.value = "assets/kissu_home_add_avair.webp";
        }
        
        // 更新照片墙
        if (indexData.photo.photoWall.isNotEmpty) {
          photoWallUrl.value = indexData.photo.photoWall;
          debugPrint('📸 照片墙URL: ${photoWallUrl.value}');
        } else {
          photoWallUrl.value = "assets/kissu_icon.webp";
          debugPrint('📸 照片墙为空，使用默认图片');
        }
        
        // 更新天气数据
        _updateWeatherData(indexData.weather);
        
        debugPrint('✅ 首页数据加载成功: 绑定状态=${isBound.value}, 恋爱天数=${loveDays.value}, 距离=${distance.value}');
        
        // 数据加载完成后，检查是否需要显示引导图（确保绑定状态已获取）
        _checkAndShowGuide1();
      } else {
        debugPrint('❌ 首页数据加载失败: ${result.msg}');
        // 失败时回退到加载本地用户信息
        loadUserInfo();
        // 即使失败也要检查引导图（使用本地缓存的绑定状态）
        _checkAndShowGuide1();
      }
    } catch (e) {
      debugPrint('❌ 首页数据加载异常: $e');
      // 异常时回退到加载本地用户信息
      loadUserInfo();
      // 异常情况下也要检查引导图（使用本地缓存的绑定状态）
      _checkAndShowGuide1();
    }
  }

  /// 加载用户信息和绑定状态
  void loadUserInfo() {
    final user = UserManager.currentUser;
    if (user != null) {
      // 用户头像
      if (user.headPortrait?.isNotEmpty == true) {
        userAvatar.value = user.headPortrait!;
      }
      
      // 绑定状态处理 (0从未绑定，1已绑定，2已解绑)
      final bindStatus = user.bindStatus.toString();
      isBound.value = bindStatus.toString() == "1";
      
      if (isBound.value) {
        // 已绑定状态，获取伴侣头像
        _loadPartnerAvatar(user);
        // 获取距离信息
        _loadDistanceInfo();
        // 加载恋爱天数
        _loadLoveDays(user);
        // 天气数据现在从首页接口统一获取，不再单独调用
      } else {
        // 未绑定状态，重置伴侣头像
        partnerAvatar.value = "assets/kissu_home_add_avair.webp";
        // 重置距离信息
        distance.value = "0KM";
        // 重置停留点数量
        stayCount.value = 0;
        // 重置恋爱天数
        loveDays.value = 0;
      }
    }
  }
  
  /// 检查并刷新用户信息（只在app启动时首次调用）
  Future<void> checkAndRefreshUserInfoOnAppStartup() async {
    // 如果app已经启动过，跳过刷新
    if (_hasAppStartedThisSession) {
      debugPrint('⏭️ App已在此会话中启动过，跳过用户信息刷新');
      return;
    }
    
    try {
      debugPrint('🚀 App首次启动，刷新用户信息...');
      await refreshUserInfoFromServer();
      
      // 标记app已启动
      _hasAppStartedThisSession = true;
      debugPrint('✅ 用户信息已刷新，已标记app启动状态');
    } catch (e) {
      debugPrint('❌ App启动时刷新用户信息失败: $e');
    }
  }
  
  /// 从服务器刷新用户信息并更新缓存
  Future<void> refreshUserInfoFromServer() async {
    // 防重复调用：如果正在刷新中，直接返回
    if (_isRefreshingUserInfo) {
      debugPrint('⏭️ 用户信息正在刷新中，跳过重复调用');
      return;
    }
    
    // 防重复调用：如果最近已经刷新过，跳过
    final now = DateTime.now();
    if (_lastUserInfoRefreshTime != null && 
        now.difference(_lastUserInfoRefreshTime!).inSeconds < 3) {
      debugPrint('⏭️ 用户信息最近已刷新（${now.difference(_lastUserInfoRefreshTime!).inSeconds}秒前），跳过重复调用');
      return;
    }
    
    _isRefreshingUserInfo = true;
    _lastUserInfoRefreshTime = now;
    
    try {
      debugPrint('🔄 开始从服务器刷新用户信息...');
      
      final success = await _authService.refreshUserInfoFromServer();
      
      if (success) {
        debugPrint('✅ 用户信息刷新成功，重新加载本地用户信息');
        // 刷新成功后重新加载用户信息到UI
        loadUserInfo();
      } else {
        debugPrint('⚠️ 用户信息刷新失败，使用本地缓存数据');
      }
    } catch (e) {
      debugPrint('❌ 刷新用户信息时发生异常: $e');
      // 异常情况下继续使用本地缓存，不影响用户体验
    } finally {
      _isRefreshingUserInfo = false;
    }
  }
  
  /// 加载伴侣头像
  void _loadPartnerAvatar(user) {
    // 优先使用loverInfo中的头像
    if (user.loverInfo?.headPortrait?.isNotEmpty == true) {
      partnerAvatar.value = user.loverInfo!.headPortrait!;
    } 
    // 其次使用halfUserInfo中的头像
    else if (user.halfUserInfo?.headPortrait?.isNotEmpty == true) {
      partnerAvatar.value = user.halfUserInfo!.headPortrait!;
    }
    // 否则使用默认头像
    else {
      partnerAvatar.value = "assets/kissu3_love_avater.webp";
    }
  }
  
  /// 加载恋爱天数
  void _loadLoveDays(user) {
    if (user.loverInfo?.loveDays != null && user.loverInfo!.loveDays! > 0) {
      loveDays.value = user.loverInfo!.loveDays!;  // 直接使用服务器数据
      debugPrint('🏠 加载恋爱天数: ${loveDays.value}天');
    } else {
      loveDays.value = 0;
      debugPrint('🏠 恋爱天数数据为空，设置为0');
    }
  }
  
  /// 加载距离信息和停留点数量（已废弃，现在使用 loadIndexData）
  @Deprecated('使用 loadIndexData() 替代')
  Future<void> _loadDistanceInfo() async {
    try {
      debugPrint('📍 开始获取距离信息和停留点数量...');
      final result = await LocationApi().getLocation();
      
      if (result.isSuccess && result.data != null) {
        final locationData = result.data!;
        
        // 获取用户和伴侣的位置数据
        final userLocation = locationData.userLocationMobileDevice;
        final partnerLocation = locationData.halfLocationMobileDevice;
        
        // 优先使用用户数据中的距离信息
        if (userLocation?.distance != null && userLocation!.distance!.isNotEmpty) {
          distance.value = userLocation.distance!;
          debugPrint('📍 获取到距离信息: ${distance.value}');
        } else if (partnerLocation?.distance != null && partnerLocation!.distance!.isNotEmpty) {
          distance.value = partnerLocation.distance!;
          debugPrint('📍 获取到距离信息: ${distance.value}');
        } else {
          // 如果都没有距离信息，尝试计算距离
          if (userLocation?.latitude != null && userLocation?.longitude != null &&
              partnerLocation?.latitude != null && partnerLocation?.longitude != null) {
            final userLat = double.tryParse(userLocation!.latitude!);
            final userLng = double.tryParse(userLocation.longitude!);
            final partnerLat = double.tryParse(partnerLocation!.latitude!);
            final partnerLng = double.tryParse(partnerLocation.longitude!);
            
            if (userLat != null && userLng != null && partnerLat != null && partnerLng != null) {
              final calculatedDistance = _calculateDistance(userLat, userLng, partnerLat, partnerLng);
              distance.value = "${calculatedDistance.toStringAsFixed(1)}KM";
              debugPrint('📍 计算得到距离: ${distance.value}');
            } else {
              distance.value = "0KM";
              debugPrint('📍 无法解析坐标，设置默认距离');
            }
          } else {
            distance.value = "0KM";
            debugPrint('📍 缺少位置信息，设置默认距离');
          }
        }
        
        // 获取停留点数量（优先从伴侣数据获取，因为要显示"TA的足迹"）
        final partnerStayCollect = partnerLocation?.stayCollect;
        if (partnerStayCollect != null && partnerStayCollect.stayCount != null) {
          stayCount.value = partnerStayCollect.stayCount!;
          debugPrint('📍 获取到停留点数量: ${stayCount.value}');
        } else {
          stayCount.value = 0;
          debugPrint('📍 停留点数量为空，设置默认值0');
        }
      } else {
        debugPrint('❌ 获取距离信息失败: ${result.msg}');
        distance.value = "0KM";
        stayCount.value = 0;
      }
    } catch (e) {
      debugPrint('❌ 获取距离信息异常: $e');
      distance.value = "0KM";
      stayCount.value = 0;
    }
  }
  
  /// 计算两点间距离（使用Haversine公式）
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // 地球半径（公里）
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
    final double c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }
  
  /// 角度转弧度
  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }
  
  
  /// 绑定成功后刷新数据
  Future<void> _refreshAfterBinding() async {
    try {
      // 刷新用户信息
      await UserManager.refreshUserInfo();
      
      // 重新加载当前页面数据
      loadIndexData();
      
      // 首页绑定状态已刷新
    } catch (e) {
      // 刷新首页绑定状态失败
    }
  }
  
  /// 外部调用的刷新方法（用于其他页面通知首页更新）
  Future<void> refreshUserInfoAndState() async {
    try {
      print('🏠 首页收到刷新通知，正在更新用户信息...');
      // 不需要再次调用 UserManager.refreshUserInfo()，因为调用方已经刷新了
      loadIndexData();
      print('🏠 首页绑定状态已更新: ${isBound.value}');
    } catch (e) {
      print('🏠 首页刷新绑定状态失败: $e');
    }
  }

  void onButtonTap(int index) {
    selectedIndex.value = index;
    debugPrint("🔍 底部导航按钮 $index 被点击");

    switch (index) {
      case 0:
        // 定位（新版）
        debugPrint("📍 准备跳转到定位V2页面");
        Get.to(() => LocationV2Page(), binding: LocationV2Binding());
        break;
      case 1:
        // 地图
        Get.to(() =>  TrackPage(), binding: TrackBinding());
        break;
      case 2:
        // 用机记录
        Get.to(() => const UsageReportPage(), binding: UsageReportBinding());
        break;
      case 3:
        // 我的 - 每次点击时刷新数据
        _navigateToMinePage();
        break;
      default:
        // 其他功能待实现
        break;
    }
  }

  // 点击通知按钮
  void onNotificationTap() {
    // 跳转到消息列表页面（一级页面）
    // 注意：红点不在这里清除，而是在进入各个详情页时清除
    debugPrint('📭 点击消息中心按钮，进入消息列表');
    Get.toNamed(KissuRoutePath.messageList);
  }

  // 点击钱包按钮
  void onMoneyTap() {
    // 示例逻辑：跳转到钱包/充值页面

    // 或者增加调试打印
    // 钱包按钮被点击
  }

  /// 获取顶部图标路径
  String getTopIconPath(int index) {
    switch (index) {
      case 0:
        return "assets/kissu_home_tab_location.webp";
      case 1:
        return "assets/kissu_home_tab_foot.webp";
      case 2:
        return "assets/kissu_home_tab_history.webp";
      case 3:
        return "assets/kissu_home_tab_mine.webp";
      default:
        return "assets/kissu_home_tab_location.webp";
    }
  }

  /// 获取底部图标路径
  String getBottomIconPath(int index) {
    switch (index) {
      case 0:
        return "assets/kissu_home_tab_locationT.webp";
      case 1:
        return "assets/kissu_home_tab_mapT.webp";
      case 2:
        return "assets/kissu_home_tab_historyT.webp";
      case 3:
        return "assets/kissu_home_tab_mineT.webp";
      default:
        return "assets/kissu_home_tab_locationT.webp";
    }
  }
  
  /// 手动启动定位服务
  Future<void> startLocationService() async {
    await _requestLocationPermissionAndStartService();
  }

  /// 手动请求后台定位权限
  Future<void> requestBackgroundLocationPermission() async {
    try {
      debugPrint('🏠 首页手动请求后台定位权限');
      bool success = await _locationService.requestBackgroundLocationPermission();
      
      if (success) {
        CustomToast.show(
          Get.context!,
          '后台定位权限已获取，可以后台记录足迹',
        );
      }
    } catch (e) {
      debugPrint('🏠 首页请求后台定位权限失败: $e');
    }
  }
  
  /// 停止定位服务
  void stopLocationService() {
    try {
      _locationService.stopLocation();
      isLocationServiceStarted.value = false;
      debugPrint('定位服务已停止');
      CustomToast.show(
        Get.context!,
        '定位服务已停止',
      );
    } catch (e) {
      debugPrint('停止定位服务失败: $e');
    }
  }
  
  /// 获取定位服务状态
  Map<String, dynamic> getLocationServiceStatus() {
    return _locationService.serviceStatus;
  }
  
  /// 手动上报当前位置
  Future<bool> reportCurrentLocation() async {
    return await _locationService.reportCurrentLocation();
  }
  
  /// 强制上报所有待上报数据
  Future<bool> forceReportAllPending() async {
    return await _locationService.forceReportAllPending();
  }
  
  /// 加载视图模式
  Future<void> _loadViewMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getBool('home_view_mode') ?? true; // 默认屏视图
      isScreenView.value = savedMode;
      debugPrint('加载视图模式: ${savedMode ? "屏视图" : "岛视图"}');
    } catch (e) {
      debugPrint('加载视图模式失败: $e');
      isScreenView.value = true; // 出错时默认屏视图
    }
  }
  
  /// 保存视图模式
  Future<void> _saveViewMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('home_view_mode', isScreenView.value);
      debugPrint('保存视图模式: ${isScreenView.value ? "屏视图" : "岛视图"}');
    } catch (e) {
      debugPrint('保存视图模式失败: $e');
    }
  }
  
  /// 切换视图模式
  void toggleViewMode() {
    isScreenView.value = !isScreenView.value;
    _saveViewMode();
    debugPrint('切换到: ${isScreenView.value ? "屏视图" : "岛视图"}');
  }
  
  /// 加载红点信息（已废弃，现在使用 loadIndexData）
  @Deprecated('使用 loadIndexData() 替代')
  Future<void> loadRedDotInfo() async {
    // 此方法已废弃，红点信息现在通过 /index 接口统一获取
    debugPrint('⚠️ loadRedDotInfo() 已废弃，请使用 loadIndexData()');
  }
  
  /// 启动红点轮询（每10秒刷新一次）
  void _startRedDotPolling() {
    // 先停止现有的定时器（如果有）
    _stopRedDotPolling();
    
    // 创建新的定时器，每10秒执行一次
    _redDotPollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      debugPrint('🔔 定时刷新首页数据...');
      loadIndexData(); // 使用新的统一接口
    });
    
    debugPrint('✅ 红点轮询已启动（每10秒刷新）');
  }
  
  /// 停止红点轮询
  void _stopRedDotPolling() {
    if (_redDotPollingTimer != null) {
      _redDotPollingTimer?.cancel();
      _redDotPollingTimer = null;
      debugPrint('⏹️ 红点轮询已停止');
    }
  }
  
  /// 设置红点监听器，当子红点变化时自动更新总红点数
  void _setupRedDotListeners() {
    // 监听系统消息红点变化
    ever(systemNoticeRedDot, (_) {
      redDotCount.value = systemNoticeRedDot.value + interactionNoticeRedDot.value;
      debugPrint('📊 系统消息红点变化，更新总红点数: ${redDotCount.value}');
    });
    
    // 监听互动消息红点变化
    ever(interactionNoticeRedDot, (_) {
      redDotCount.value = systemNoticeRedDot.value + interactionNoticeRedDot.value;
      debugPrint('📊 互动消息红点变化，更新总红点数: ${redDotCount.value}');
    });
  }

  /// 设置应用生命周期监听
  void _setupAppLifecycleListener() {
    try {
      _appLifecycleService = AppLifecycleService.instance;
      
      // 监听应用状态变化
      _appLifecycleSubscription = _appLifecycleService.appState.listen((state) {
        _handleAppLifecycleChange(state);
      });
      
      debugPrint('📱 首页应用生命周期监听已设置');
    } catch (e) {
      debugPrint('❌ 设置首页应用生命周期监听失败: $e');
    }
  }
  
  /// 处理应用生命周期变化
  void _handleAppLifecycleChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _onAppEnteredBackground();
        break;
      case AppLifecycleState.resumed:
        _onAppReturnedToForeground();
        break;
      default:
        break;
    }
  }
  
  /// 应用进入后台
  void _onAppEnteredBackground() {
    debugPrint('📱 首页：应用进入后台，停止红点轮询');
    _stopRedDotPolling();
  }
  
  /// 应用返回前台
  void _onAppReturnedToForeground() {
    debugPrint('📱 首页：应用返回前台，先获取红点数据再启动轮询');
    
    // 先立即获取一次首页数据
    loadIndexData().then((_) {
      // 获取完成后再启动轮询
      _startRedDotPolling();
    });
  }
  
  /// 初始化PAG动画 - 暂时移除
  // void _initPAGAnimations() {
  //   try {
  //     debugPrint('🚀 开始初始化PAG动画配置...');
  //     
  //     // 配置五个PAG动画的位置和大小
  //     pagAnimations.value = [
  //       {
  //         'assetPath': 'assets/pag/home_bg_clothes.pag',
  //         'x': 1228,
  //         'y': 68,
  //         'width': 272,
  //         'height': 174,
  //       },
  //       {
  //         'assetPath': 'assets/pag/home_bg_leaf.pag',
  //         'x': 675,
  //         'y': 268,
  //         'width': 232,
  //         'height': 119,
  //       },
  //       {
  //         'assetPath': 'assets/pag/home_bg_kitchen.pag',
  //         'x': 22,
  //         'y': 139,
  //         'width': 174,
  //         'height': 364,
  //       },
  //       {
  //         'assetPath': 'assets/pag/home_bg_music.pag',
  //         'x': 352,
  //         'y': 260,
  //         'width': 130,
  //         'height': 108,
  //       },
  //       {
  //         'assetPath': 'assets/pag/home_bg_person.pag',
  //         'x': 395,
  //         'y': 293,
  //         'width': 350,
  //         'height': 380,
  //       },
  //     ];
  //     
  //     debugPrint('🎯 PAG动画配置完成，共${pagAnimations.length}个动画');
  //   } catch (e) {
  //     debugPrint('❌ PAG动画初始化失败: $e');
  //   }
  // }
  
  /// 跳转到H5页面
  void navigateToH5(String url) {
    if (url.isNotEmpty) {
      Get.to(() => AgreementWebViewPage(
        title: activityTitle.value.isNotEmpty ? activityTitle.value : '活动详情',
        url: url,
      ));
      debugPrint('跳转到H5页面: $url');
    } else {
      debugPrint('H5链接为空，无法跳转');
    }
  }
  
  /// 跳转到我的页面，先刷新数据
  Future<void> _navigateToMinePage() async {
    try {
      debugPrint('🔄 准备跳转到我的页面，先刷新用户数据...');
      
      // 先刷新用户信息
      await refreshUserInfoFromServer();
      
      // 然后跳转到我的页面
      Get.to(() => MinePage(), binding: MineBinding());
      debugPrint('✅ 用户数据刷新完成，已跳转到我的页面');
    } catch (e) {
      debugPrint('❌ 跳转到我的页面时刷新数据失败: $e');
      // 即使刷新失败也要跳转，不影响用户体验
      Get.to(() => MinePage(), binding: MineBinding());
    }
  }

  /// 检查版本更新（首页自动检查）
  Future<void> _checkVersionUpdate() async {
    try {
      debugPrint('🔄 开始检查版本更新');
      
      // 延迟一段时间后检查，避免影响首页加载
      await Future.delayed(const Duration(milliseconds: 800));
      
      final currentContext = Get.context;
      if (currentContext != null) {
        final versionService = Get.find<VersionService>();
        await versionService.checkVersionForHomePage(currentContext);
        debugPrint('✅ 版本检查完成');
      } else {
        debugPrint('⚠️ 无法获取Context，跳过版本检查');
      }
    } catch (e) {
      debugPrint('❌ 检查版本更新失败: $e');
    }
  }

  /// 检查并显示VIP推广弹窗
  Future<void> _checkAndShowVipPromo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shouldShow = prefs.getBool('should_show_vip_promo') ?? false;
      
      debugPrint('🔍 检查VIP推广标识: $shouldShow');
      
      if (shouldShow) {
        debugPrint('🎁 检测到需要显示VIP推广弹窗');
        
        // 立即清除标识，防止重复显示（在延迟显示之前就清除）
        await prefs.remove('should_show_vip_promo');
        debugPrint('🧹 VIP推广标识已清除（在显示弹窗前）');
        
        // 延迟后显示弹窗，确保首页已完全加载
        await Future.delayed(const Duration(milliseconds: 500));
        
        try {
          final currentContext = Get.context;
          if (currentContext != null) {
            await DialogManager.showHuaweiVipPromo(currentContext);
            debugPrint('✅ VIP推广弹窗已显示并关闭');
          }
        } catch (e) {
          debugPrint('❌ 显示VIP推广弹窗失败: $e');
        }
      } else {
        debugPrint('ℹ️ 无需显示VIP推广弹窗');
      }
    } catch (e) {
      debugPrint('❌ 检查VIP推广标识失败: $e');
    }
  }

  /// 显示引导层
  void displayGuideOverlay() {
    currentGuideType.value = GuideType.datingTime;
    showGuideOverlay.value = true;
    debugPrint('📱 显示引导层');
  }

  /// 隐藏引导层
  void hideGuideOverlay() {
    showGuideOverlay.value = false;
    debugPrint('📱 隐藏引导层');
  }

  /// 检查并显示引导图1（新用户引导）
  Future<void> _checkAndShowGuide1() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasShownGuide1 = prefs.getBool('has_shown_guide1') ?? false;
      
      debugPrint('🔍 检查引导图1显示状态: $hasShownGuide1 (已绑定: ${isBound.value})');
      
      if (!hasShownGuide1) {
        debugPrint('📱 首次登录，显示引导图1');
        
        // 立即标记已显示，防止重复显示
        await prefs.setBool('has_shown_guide1', true);
        
        // 延迟显示引导图1，确保首页完全加载
        Future.delayed(const Duration(milliseconds: 500), () {
          _showGuide1();
        });
      } else {
        debugPrint('ℹ️ 引导图1已显示过，检查是否需要显示引导图2 (已绑定: ${isBound.value})');
        
        // 如果已绑定，检查是否需要显示引导图2
        if (isBound.value) {
          _checkAndShowGuide2();
        } else {
          // 未绑定状态，执行其他逻辑
          _executeOtherLogic();
        }
      }
    } catch (e) {
      debugPrint('❌ 检查引导图1状态失败: $e');
      // 出错时执行其他逻辑
      _executeOtherLogic();
    }
  }

  /// 检查并显示绑定弹窗
  Future<void> _checkAndShowBindingDialog() async {
    try {
      // 检查是否已绑定
      if (isBound.value) {
        debugPrint('🔗 用户已绑定，不显示绑定弹窗');
        return;
      }

      // 检查本次会话是否已显示过绑定弹窗
      if (_hasShownBindingDialogThisSession) {
        debugPrint('📱 本次会话已显示过绑定弹窗，不再显示');
        return;
      }

      debugPrint('💕 用户未绑定且本次会话未显示过绑定弹窗，准备显示绑定弹窗');

      // 延迟显示绑定弹窗，确保首页完全加载
      Future.delayed(const Duration(milliseconds: 800), () {
        _showBindingDialog();
      });
      
    } catch (e) {
      debugPrint('❌ 检查绑定弹窗时发生错误: $e');
    }
  }

  /// 显示引导图1
  void _showGuide1() {
    currentGuideType.value = GuideType.swipe;
    showGuideOverlay.value = true;
    debugPrint('📱 显示引导图1');
  }

  /// 引导图1关闭后的回调
  void onGuide1Dismissed() {
    hideGuideOverlay();
    debugPrint('📱 引导图1已关闭，检查是否需要显示引导图2 (已绑定: ${isBound.value})');
    
    // 如果已绑定，检查是否需要显示引导图2
    if (isBound.value) {
      _checkAndShowGuide2();
    } else {
      // 未绑定状态，执行其他逻辑
      _executeOtherLogic();
    }
  }

  /// 引导图2关闭后的回调
  void onGuide2Dismissed() {
    hideGuideOverlay();
    debugPrint('📱 引导图2已关闭，执行后续逻辑 (已绑定: ${isBound.value})');
    
    // 引导图2关闭后执行其他逻辑（定位权限 -> VIP购买弹窗）
    _executeOtherLogicAfterGuide2();
  }

  /// 执行其他逻辑（引导图1关闭后，未绑定状态）
  void _executeOtherLogic() {
    // 按顺序执行：定位权限 -> VIP推广 -> 绑定弹窗
    
    // 1. 延迟请求定位权限并启动服务
    Future.delayed(Duration(seconds: 1), () async {
      await _requestLocationPermissionOnHomePage();
      
      // 2. 定位权限处理完成后，延迟检查VIP推广弹窗
      Future.delayed(Duration(milliseconds: 500), () async {
        await _checkAndShowVipPromo();
        
        // 3. VIP推广弹窗处理完成后，最后检查绑定弹窗
        Future.delayed(Duration(milliseconds: 500), () {
          _checkAndShowBindingDialog();
        });
      });
    });
  }

  /// 执行其他逻辑（引导图2关闭后，已绑定状态）
  void _executeOtherLogicAfterGuide2() {
    // 按顺序执行：定位权限 -> VIP购买弹窗
    
    // 1. 延迟请求定位权限并启动服务
    Future.delayed(Duration(seconds: 1), () async {
      await _requestLocationPermissionOnHomePage();
      
      // 2. 定位权限处理完成后，延迟检查VIP购买弹窗
      Future.delayed(Duration(milliseconds: 500), () async {
        await _checkAndShowVipPurchaseDialog();
      });
    });
  }

  /// 检查并显示VIP购买弹窗
  Future<void> _checkAndShowVipPurchaseDialog() async {
    try {
      // 1. 检查是否已绑定
      if (!isBound.value) {
        debugPrint('💎 用户未绑定，不显示VIP购买弹窗');
        return;
      }

      // 2. 检查是否为会员
      if (UserManager.isVip) {
        debugPrint('💎 用户已是VIP会员，不显示VIP购买弹窗');
        return;
      }

      // 3. 检查本次会话是否已显示过VIP购买弹窗
      if (_hasShownVipDialogThisSession) {
        debugPrint('💎 本次会话已显示过VIP购买弹窗，不再显示');
        return;
      }

      debugPrint('💎 用户已绑定且非会员，本次会话未显示过VIP购买弹窗，准备显示');

      // 延迟显示VIP购买弹窗，确保首页完全加载
      Future.delayed(const Duration(milliseconds: 800), () {
        _showVipPurchaseDialog();
      });
      
    } catch (e) {
      debugPrint('❌ 检查VIP购买弹窗时发生错误: $e');
    }
  }

  /// 显示VIP购买弹窗
  void _showVipPurchaseDialog() {
    try {
      final currentContext = Get.context;
      if (currentContext == null) {
        debugPrint('❌ 无法获取Context，跳过显示VIP购买弹窗');
        return;
      }

      debugPrint('💎 显示VIP购买弹窗');
      
      // 标记本次会话已显示
      _hasShownVipDialogThisSession = true;
      
      DialogManager.showVipPurchase(
        context: currentContext,
        onConfirm: () {
          debugPrint('💎 点击了立即查看按钮，跳转到VIP页面');
          // 弹窗会自动关闭，然后跳转到VIP页面
          Get.toNamed(KissuRoutePath.vip);
        },
        barrierDismissible: true,
      );
      
    } catch (e) {
      debugPrint('❌ 显示VIP购买弹窗时发生错误: $e');
    }
  }

  /// 显示VIP开通弹窗（调试用）
  void showVipPurchaseDialog() {
    _showVipPurchaseDialog();
  }

  /// 检查并显示引导图2（相恋时间设置引导）
  /// 在引导图1关闭后，已绑定状态下检查是否第一次显示
  Future<void> _checkAndShowGuide2() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasShownGuide2 = prefs.getBool('has_shown_guide2') ?? false;
      
      debugPrint('🔍 检查引导图2显示状态: $hasShownGuide2');
      
      if (!hasShownGuide2) {
        debugPrint('📱 显示引导图2（已绑定且第一次进入首页）');
        
        // 立即标记已显示，防止重复显示
        await prefs.setBool('has_shown_guide2', true);
        
        // 延迟显示引导图2
        Future.delayed(const Duration(milliseconds: 1000), () {
          displayGuideOverlay();
        });
      } else {
        debugPrint('ℹ️ 引导图2已显示过，执行其他逻辑');
        // 引导图2已显示过，执行其他逻辑
        _executeOtherLogicAfterGuide2();
      }
    } catch (e) {
      debugPrint('❌ 检查引导图2状态失败: $e');
      // 出错时执行其他逻辑
      _executeOtherLogic();
    }
  }

  /// 检查并显示引导层（调试模式：一直显示）
  Future<void> checkAndShowGuide() async {
    try {
      debugPrint('🔍 调试模式：强制显示引导层');
      
      // 延迟显示引导层，确保首页完全加载
      Future.delayed(const Duration(milliseconds: 1000), () {
        displayGuideOverlay();
        debugPrint('✅ 引导层已显示（调试模式）');
      });
    } catch (e) {
      debugPrint('❌ 显示引导层失败: $e');
    }
  }


  /// 显示绑定弹窗
  void _showBindingDialog() {
    try {
      final currentContext = Get.context;
      if (currentContext == null) {
        debugPrint('❌ 无法获取Context，跳过显示绑定弹窗');
        return;
      }

      debugPrint('💑 显示绑定弹窗');
      
      // 标记本次会话已显示
      _hasShownBindingDialogThisSession = true;
      
      // 使用CustomBottomDialog显示绑定弹窗
      CustomBottomDialog.show(
        context: currentContext,
        onClose: () {
          debugPrint('💑 绑定弹窗已关闭');
        },
      ).then((result) {
        // 无论用户是确认绑定还是关闭弹窗，都已经标记为已显示
        debugPrint('💑 绑定弹窗已关闭，结果: $result');
        // 延迟执行刷新，确保弹窗完全关闭后再执行
        Future.delayed(const Duration(milliseconds: 300), () {
          _refreshAfterBinding();
        });
      });
      
    } catch (e) {
      debugPrint('❌ 显示绑定弹窗时发生错误: $e');
    }
  }

  /// 更新天气数据（从首页接口数据中解析）
  void _updateWeatherData(WeatherData weatherData) {
    try {
      debugPrint('🌤️ 开始解析首页天气数据');
      
      // 解析 base 数据
      if (weatherData.base.isNotEmpty) {
        final base = weatherData.base.first;
        weatherIconUrl.value = base.weatherIcon.isNotEmpty ? base.weatherIcon : null;
        weather.value = base.weather.isNotEmpty ? base.weather : null;
        currentTemp.value = base.temperature.isNotEmpty ? base.temperature : null;
        debugPrint('🌤️ 解析 base 数据: icon=${weatherIconUrl.value}, weather=${weather.value}, temp=${currentTemp.value}');
      }
      
      // 解析 all 数据
      if (weatherData.all.isNotEmpty) {
        final all = weatherData.all.first;
        if (all.casts.isNotEmpty) {
          final todayCast = all.casts.first;
          minTemp.value = todayCast.nighttemp.isNotEmpty ? todayCast.nighttemp : null;
          maxTemp.value = todayCast.daytemp.isNotEmpty ? todayCast.daytemp : null;
          debugPrint('🌤️ 解析 all 数据: min=${minTemp.value}, max=${maxTemp.value}');
        }
      }
      
      isWeatherLoading.value = false;
      debugPrint('✅ 天气数据解析成功');
    } catch (e) {
      debugPrint('❌ 天气数据解析异常: $e');
      isWeatherLoading.value = false;
    }
  }
  
}

