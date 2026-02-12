import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/mine/mine_binding.dart';
import 'package:kissu_app/services/home_scroll_service.dart';
import 'package:kissu_app/pages/mine/mine_page.dart';
import 'package:kissu_app/pages/mine/love_info/love_info_page.dart';
import 'package:kissu_app/pages/mine/device_usage/device_usage_page.dart';
import 'package:kissu_app/pages/mine/device_usage/device_usage_binding.dart';
import 'package:kissu_app/pages/track/track_binding.dart';
import 'package:kissu_app/pages/track/track_page.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/utils/source_page_utils.dart';
import 'package:kissu_app/utils/vip_navigation_helper.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/utils/screen_adaptation.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';
import 'package:kissu_app/widgets/guide_overlay_widget.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog.dart'; 
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/services/simple_location_service.dart';
import 'package:kissu_app/services/app_lifecycle_service.dart';
import 'package:kissu_app/services/location_permission_manager.dart';
import 'package:kissu_app/services/app_usage_auto_report_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kissu_app/pages/agreement/agreement_webview_page.dart';
import 'package:kissu_app/pages/home/widget/seeding_webview_page.dart';
 import 'package:kissu_app/network/public/auth_service.dart';
import 'package:kissu_app/network/public/service_locator.dart';
import 'package:kissu_app/network/public/index_api.dart';
import 'package:kissu_app/network/http_resultN.dart';
 import 'dart:async';
import 'package:kissu_app/services/version_service.dart'; 
import 'package:kissu_app/services/tencent_im_service.dart';
import 'package:kissu_app/services/gif_preload_service.dart';
import 'package:kissu_app/pages/home/services/home_popup_service.dart';
import 'package:kissu_app/services/analytics/analytics_helper.dart';
import 'package:kissu_app/services/analytics/analytics_manager.dart';
import 'package:kissu_app/services/analytics/analytics_events.dart';
import 'package:kissu_app/services/analytics/analytics_params.dart';


class HomeController extends GetxController {
  // 当前选中的按钮索引
  var selectedIndex = 0.obs;
  
  // App启动标记 - 静态变量，app被杀掉时会自动重置
  static bool _hasAppStartedThisSession = false;
  
  // 🔥 弹窗显示状态标志，防止弹窗和引导图同时显示（与服务类共享）
  var _isShowingDialog = false.obs;
  bool get isShowingDialog => _isShowingDialog.value;
  
  // 保存VIP数据，用于在onReady中检查
  VipData? _cachedVipData;

  // 防重复刷新用户信息的变量
  bool _isRefreshingUserInfo = false;
  DateTime? _lastUserInfoRefreshTime;
  
  // 滚动控制器，用于控制背景图片的初始位置
  late ScrollController scrollController;
  
  // 绑定状态
  var isBound = false.obs;
  
  // 轮播图当前索引
  var currentSwiperIndex = 0.obs;
  
  // Banner 手动滑动标记
  // 用于追踪用户是否手动滑动了 banner
  // true = 用户手动滑动，false = 自动播放
  
  // 首页埋点追踪
  int? _homePageEnterTime;
  bool _hasTrackedHomePageExit = false;
  var isBannerManuallyDragged = false.obs;
  
  // 视图模式：true=屏视图，false=岛视图（默认屏视图）
  var isScreenView = true.obs;
  
  // 头像信息
  var userAvatar = "assets/3.0/kissu3_love_avater.webp".obs;
  var partnerAvatar = "assets/images/kissu_home_add_avair.webp".obs;
  
  // 会员状态
  var isVip = false.obs;
  var isForeverVip = false.obs; // 是否为终身会员
  
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

  // 拉屎游戏相关
  var crapLink = ''.obs;
  var crapStatus = '0'.obs; // "1"展示 "0"不展示

  // 种草相关
  var seedingLink = ''.obs;
  var seedingStatus = '0'.obs; // "1"展示 "0"不展示
  var seedingIcon = ''.obs;
  var showSeedingButton = false.obs; // 是否显示种草按钮

  /// 聊天未读消息数（来自腾讯 IM，另一半会话的未读总数）
  final RxInt chatUnreadCount = 0.obs;
  
  // 距离信息
  var distance = "0KM".obs;
  
  // 停留点数量
  var stayCount = 0.obs;
  
  // 出行工具 (1=行走, 2=骑车, 3=坐车)
  var travelTool = 1.obs;
  
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
  var photoWallUrl = "assets/images/kissu_icon.webp".obs;
  
  // 引导层显示状态
  var showGuideOverlay = false.obs;
  
  // 当前引导图类型
  var currentGuideType = GuideType.swipe.obs;
  
  // 🔥 优化：防重复调用标志
  bool _isLoadingIndexData = false;
  DateTime? _lastLoadIndexDataTime;
  static const Duration _minLoadIndexDataInterval = Duration(seconds: 3); // 最小调用间隔3秒
  
  // 应用生命周期服务
  late AppLifecycleService _appLifecycleService;
  
  // 应用生命周期监听
  StreamSubscription<AppLifecycleState>? _appLifecycleSubscription;
  
  // 弹窗和引导图服务
  late HomePopupService _popupService;

  @override
  void onInit() {
    super.onInit();
    
    // 埋点：记录首页进入时间
    _homePageEnterTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _hasTrackedHomePageExit = false;
    
    // 初始化弹窗和引导图服务
    _popupService = HomePopupService(
      isBound: isBound,
      isVip: isVip,
      showGuideOverlay: showGuideOverlay,
      currentGuideType: currentGuideType,
      isShowingDialog: _isShowingDialog,
      onRefreshAfterBinding: _refreshAfterBinding,
      getCachedVipData: () => _cachedVipData,
      onNavigateToNextPage: _trackHomePageExit,
    );
    
    logDebug('🏠 HomeController 初始化 - 绑定弹窗标志位状态: ${HomePopupService.hasShownBindingDialogThisSession}');
    
    // 🔥 修复：先初始化认证服务，再调用同步授权应用（避免LateInitializationError）
    _authService = getIt<AuthService>();
    
    // 进入首页即同步授权应用
    _syncAuthApp();
    
    // 先加载本地用户信息（立即显示）
    loadUserInfo();
    
    // 然后静默刷新用户信息
    _silentRefreshUserInfo();
    
    // 初始化滚动控制器，如果有预设位置则使用预设位置
    _initializeScrollController();
    
    // 🚀 预加载定位页面GIF动画（在后台异步执行，不阻塞首页加载）
    _preloadLocationGifs();
    
    _initializeLocationService();
    loadIndexData(); // 加载首页所有数据（弹窗流程在onReady中独立触发）
    _loadViewMode(); // 加载视图模式
    _setupAppLifecycleListener(); // 设置应用生命周期监听
    _setupRedDotListeners(); // 设置红点监听器
    _setupChatUnreadListener(); // 监听聊天未读数
  }

  @override
  void onReady() {
    super.onReady();
    
    // 检查版本更新（在引导图和其他弹窗之前检查）
    _checkVersionUpdate();
    
    // 立即检查定位权限并开始弹窗流程（不等待数据加载完成）
    // 弹窗流程优先级：定位权限 -> 绑定弹窗 -> VIP购买弹窗 -> VIP推广 -> 引导图
    _checkLocationPermissionAndShowBindingDialog();
    
    // 启动App使用记录自动上报服务
    _startAppUsageAutoReport();
    
    // 延迟检查VIP到期弹窗（等待数据加载完成，且整个会话期间只检查一次）
    Future.delayed(const Duration(milliseconds: 500), () {
      _popupService.checkVipOuttimeDialogOnce();
    });
    
    // 延迟检查VIP过期提醒弹窗（type=2时显示，每天一次）
    Future.delayed(const Duration(milliseconds: 600), () {
      _popupService.checkVipExpireReminderDialogOnce();
    });
  }
  
  /// 启动App使用记录自动上报服务
  void _startAppUsageAutoReport() {
    try {
      if (Get.isRegistered<AppUsageAutoReportService>()) {
        final service = Get.find<AppUsageAutoReportService>();
        service.start();
        logWarning('✅ App使用记录自动上报服务已启动');
      } else {
        logWarning('⚠️ App使用记录自动上报服务未注册');
      }
    } catch (e) {
      logError('❌首页启动App使用记录自动上报服务失败', error: e);
    }
  }
  
  /// 页面重新获得焦点时的回调（从其他页面返回时会调用）
  /// 埋点：上报首页离开事件
  void _trackHomePageExit() {
    if (_hasTrackedHomePageExit || _homePageEnterTime == null) return;
    _hasTrackedHomePageExit = true;
    
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final duration = currentTime - _homePageEnterTime!;
    
    // 计算会员状态
    final userInfo = UserManager.currentUser;
    int vipStatus = 0;
    if (userInfo != null) {
      final isVip = userInfo.isVip ?? 0;
      final vipEndTime = userInfo.vipEndTime ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      if (isVip == 1) {
        vipStatus = (vipEndTime > now) ? 1 : 2;
      }
    }
    
    AnalyticsManager.instance.trackPageView(
      pageId: HomeEvents.pageId,
      eventId: HomeEvents.page,
      enterTime: _homePageEnterTime!,
      duration: duration,
      exitType: ExitTypeValue.nextPage,
      params: {
        AnalyticsParams.vipStatus: vipStatus,
        AnalyticsParams.bindStatus: userInfo?.bindStatus ?? 0,
        AnalyticsParams.action188: userInfo?.isCheckIn ?? 0,
        AnalyticsParams.bindNum: userInfo?.bindNum ?? 0,
      },
    );
    
    logDebug('📊 首页离开埋点：停留${duration}秒，进入时间=${_homePageEnterTime}');
  }
  
  /// 供Widget调用的首页离开埋点方法（公开方法）
  void trackHomePageExitFromWidget() {
    _trackHomePageExit();
  }
  
  void onPageResumed() {
    // 埋点：重新记录首页进入时间
    _homePageEnterTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _hasTrackedHomePageExit = false;
    debugPrint('🏠 首页重新获得焦点，刷新数据');
    
    // 🔥 修复：页面重新获得焦点时，检查并重置弹窗状态，防止卡死
    if (_isShowingDialog.value) {
      logWarning('⚠️ 检测到弹窗状态异常，强制重置');
      _isShowingDialog.value = false;
    }
    
    // 🔥 修复：确保引导图状态正确
    if (showGuideOverlay.value && _isShowingDialog.value) {
      logWarning('⚠️ 检测到引导图和弹窗同时显示，隐藏引导图');
      hideGuideOverlay();
    }
    
    _syncAuthApp();
    // 🔥 优化：页面恢复时刷新首页数据（带防重复调用保护）
    loadIndexData();
    // 然后静默刷新用户信息
    _silentRefreshUserInfo();
  }

  /// 调用同步授权应用接口
  Future<void> _syncAuthApp() async {
    try {
      await _authService.syncAuthApp();
      logWarning('🔄 同步授权应用完成');
    } catch (e) {
      logError('❌ 同步授权应用失败', error: e);
    }
  }
  
  /// 静默刷新用户信息（不阻塞UI）
  Future<void> _silentRefreshUserInfo() async {
    try {
      logWarning('🔄 首页：静默刷新用户信息');
      await refreshUserInfoFromServer();
    } catch (e) {
      logError('❌ 首页：静默刷新用户信息失败', error: e);
    }
  }
  
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
        
        logDebug('✅ 使用预设滚动位置创建ScrollController: $presetOffset');
      } else {
        // 没有预设位置，使用默认居中偏移
        _setDefaultCenterOffset();
        logWarning('⚠️ 没有预设位置，使用默认居中偏移');
      }
    } catch (e) {
      // 如果获取服务失败，使用默认居中偏移
      _setDefaultCenterOffset();
      logError('❌ 获取HomeScrollService失败，使用默认居中偏移', error: e);
    }
  }
  
  /// 设置默认的居中偏移
  void _setDefaultCenterOffset() {
    // 使用屏幕适配工具计算滚动偏移
    final defaultOffset = ScreenAdaptation.getPresetScrollOffset();
    
    scrollController = ScrollController(initialScrollOffset: defaultOffset);
    logDebug('🎯 使用自适应居中偏移创建ScrollController: 屏幕宽度=${ScreenAdaptation.screenWidth}, 动态背景宽度=${ScreenAdaptation.getDynamicContainerSize().width}, 默认偏移=$defaultOffset');
  }
  
  @override
  void onClose() {
    logDebug('🧹 HomeController 销毁 - 弹窗服务静态变量不会被清除');
    
    // 清理弹窗服务资源
    _popupService.dispose();
    
    // 安全地清理ScrollController
    try {
      scrollController.dispose();
    } catch (e) {
      logError('清理ScrollController时出错', error: e);
    }
    
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
      logError('初始化定位服务失败', error: e);
    }
  }

  /// 首页请求定位权限并启动服务（仅在第一次进入时）
  Future<void> _requestLocationPermissionOnHomePage() async {
    try {
      logDebug('🏠 首页开始请求定位权限...');

      // 检查是否已经请求过权限
      final prefs = await SharedPreferences.getInstance();
      bool hasRequested = prefs.getBool('location_permission_requested') ?? false;
      
      if (hasRequested) {
        logDebug('🏠 已请求过定位权限，检查服务状态并启动弹窗流程');
        await _checkLocationServiceStatus();
        // 🔥 修复：即使已经请求过权限，也要启动弹窗流程
        await _popupService.startPopupFlow();
        return;
      }

      logDebug('🏠 首次进入首页，开始请求定位权限');

      // 请求定位权限
      bool hasPermission = await _locationService.requestLocationPermission();

      if (hasPermission) {
        logDebug('🏠 首页定位权限获取成功');
        await _handleLocationPermissionGranted();
      } else {
        logDebug('🏠 首页定位权限被拒绝');
        await _handleLocationPermissionDenied();
      }

      // 标记已请求过权限
      await prefs.setBool('location_permission_requested', true);
      
      logDebug('🏠 定位权限申请流程完成');
    } catch (e) {
      logError('🏠 首页请求定位权限失败', error: e);
    }
  }

  /// 检查定位服务状态
  Future<void> _checkLocationServiceStatus() async {
    try {
      if (!_locationService.isLocationEnabled.value) {
        logDebug('🏠 首页启动定位服务...');
        bool started = await _locationService.startLocation();

        if (started) {
          isLocationServiceStarted.value = true;
          logDebug('🏠 首页定位服务启动成功');
        } else {
          logDebug('🏠 首页定位服务启动失败');
        }
      } else {
        logDebug('🏠 首页定位服务已在运行');
        isLocationServiceStarted.value = true;
      }
    } catch (e) {
      logError('🏠 首页检查定位服务状态失败', error: e);
    }
  }

  /// 处理定位权限获取成功
  Future<void> _handleLocationPermissionGranted() async {
    try {
      logDebug('🎯 首页用户同意定位权限，启动弹窗流程');
      
      // 启动定位服务（后台异步进行）
      _locationService.startLocation().then((success) {
        if (success) {
          isLocationServiceStarted.value = true;
          logDebug('✅ 首页定位服务启动成功');
        } else {
          logDebug('❌ 首页定位服务启动失败');
        }
      });
      
      // 使用弹窗服务启动弹窗流程
      await _popupService.startPopupFlow();
    } catch (e) {
      logError('处理首页定位权限同意失败', error: e);
    }
  }

  /// 处理定位权限被拒绝
  Future<void> _handleLocationPermissionDenied() async {
    try {
      logDebug('❌ 首页定位权限被拒绝，启动弹窗流程');
      // 使用弹窗服务启动弹窗流程
      await _popupService.startPopupFlow();
    } catch (e) {
      logError('处理首页定位权限拒绝失败', error: e);
    }
  }
  
  /// 只检查定位权限状态，不自动启动服务
  /// 🚀 修复：检查定位权限状态并启动服务（避免首页不上报位置）
  Future<void> _checkLocationPermissionStatusOnly() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasRequested = prefs.getBool('location_permission_requested') ?? false;
      
      if (hasRequested) {
        logDebug('已请求过定位权限，检查服务状态');
        
        // 🚀 修复：如果已有权限但服务未启动，主动启动服务
        if (!_locationService.isLocationEnabled.value) {
          // 先检查是否有权限
          var locationStatus = await Permission.location.status;
          if (locationStatus.isGranted) {
            logDebug('🏠 已有定位权限但服务未启动，主动启动服务（避免不上报位置）');
            bool started = await _locationService.startLocation();
            if (started) {
              isLocationServiceStarted.value = true;
              logDebug('✅ 首页定位服务已启动，开始收集和上报位置');
            }
          }
        } else {
          isLocationServiceStarted.value = true;
          logDebug('✅ 定位服务已在运行中');
        }
      }
    } catch (e) {
      logError('检查定位权限状态失败', error: e);
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
        logDebug('定位权限获取成功，启动定位服务');
        bool started = await _locationService.startLocation();
        
        if (started) {
          isLocationServiceStarted.value = true;
          logDebug('定位服务启动成功，开始记录和上报位置');
          
          // 保存已请求权限的状态
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('location_permission_requested', true);
          
          // 显示成功提示
          CustomToast.show(
            Get.context!,
            '定位服务已启动，开始记录您的足迹',
          );
        } else {
          logDebug('定位服务启动失败');
          CustomToast.show(
            Get.context!,
            '定位服务启动失败，请检查定位设置',
          );
        }
      } else {
        logDebug('定位权限被拒绝');
        CustomToast.show(
          Get.context!,
          '需要定位权限来记录您的足迹',
        );
      }
    } catch (e) {
      logError('请求定位权限并启动服务失败', error: e);
      CustomToast.show(
        Get.context!,
        '定位服务初始化失败',
      );
    }
  }
  
  /// 加载首页所有数据（新的统一接口）
  /// 仅负责加载和更新首页数据，不涉及弹窗逻辑
  /// 🔥 优化：添加防重复调用和超时保护
  Future<void> loadIndexData() async {
    // 🔥 防重复调用：如果正在加载，直接返回
    if (_isLoadingIndexData) {
      logDebug('⏭️ 首页数据正在加载中，跳过重复调用');
      return;
    }
    
    // 🔥 防频繁调用：如果距离上次调用不足最小间隔，直接返回
    final now = DateTime.now();
    if (_lastLoadIndexDataTime != null && 
        now.difference(_lastLoadIndexDataTime!) < _minLoadIndexDataInterval) {
      logDebug('⏭️ 首页数据最近已加载（${now.difference(_lastLoadIndexDataTime!).inSeconds}秒前），跳过重复调用');
      return;
    }
    
    _isLoadingIndexData = true;
    _lastLoadIndexDataTime = now;
    
    try {
      logDebug('🏠 开始加载首页数据...');
      
      // 🔥 优化：添加超时保护，防止请求无限挂起
      final result = await IndexApi().getIndexData().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          logError('❌ 首页数据加载超时（10秒）');
          return HttpResultN.failure(-1, '请求超时');
        },
      );
      
      if (result.isSuccess && result.data != null) {
        final indexData = result.data!;
        
        // 🔥 优化：直接更新响应式变量（GetX会自动优化UI重建）
        // 更新会员状态
        isVip.value = UserManager.isVip;
        isForeverVip.value = UserManager.isForeverVip;
        
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
        
        // 更新拉屎游戏信息
        if (indexData.crapGame != null) {
          crapLink.value = indexData.crapGame!.crapLink;
          crapStatus.value = indexData.crapGame!.crapStatus;
          logDebug('💩 拉屎游戏信息更新: link=${crapLink.value}, status=${crapStatus.value}');
        } else {
          // 如果没有返回 crap_game 数据，使用默认值
          crapLink.value = '';
          crapStatus.value = '0';
          logDebug('💩 拉屎游戏数据为空，使用默认值');
        }
        
        // 更新种草信息
        if (indexData.seeding != null) {
          seedingLink.value = indexData.seeding!.seedingLink;
          seedingStatus.value = indexData.seeding!.seedingStatus;
          seedingIcon.value = indexData.seeding!.seedingIcon;
          logDebug('🌱 种草信息更新: link=${seedingLink.value}, status=${seedingStatus.value}, icon=${seedingIcon.value}');
          
          // 更新按钮显示状态
          _updateSeedingButtonVisibility();
        } else {
          // 如果没有返回 seeding 数据，使用默认值
          seedingLink.value = '';
          seedingStatus.value = '0';
          seedingIcon.value = '';
          showSeedingButton.value = false;
          logDebug('🌱 种草数据为空，使用默认值');
        }
        
        logDebug('📊 红点信息更新: 系统消息=${systemNoticeRedDot.value}, 互动消息=${interactionNoticeRedDot.value}, 总数=${redDotCount.value}, 显示红点=${isRedDot.value}');
        
        // 更新位置信息
        distance.value = indexData.location.distance;
        stayCount.value = indexData.location.stayCount;
        travelTool.value = indexData.location.travelTool;

        // 更新另一半设备信息（half_user_data）
        if (indexData.halfUserData != null) {
          final half = indexData.halfUserData!;
          halfDevicePower.value = half.power;
          halfDeviceNetworkName.value = half.networkName;
          halfDeviceMobileModel.value = half.mobileModel;
          halfDeviceDistance.value = half.distance;
          logDebug(
              '📱 half_user_data 更新: power=${halfDevicePower.value}, network=${halfDeviceNetworkName.value}, model=${halfDeviceMobileModel.value}, distance=${halfDeviceDistance.value}');
        }
        
        // 更新用户信息
        loveDays.value = indexData.user.loverDays;
        isBound.value = indexData.user.isBind == 1;
        
        // 🚀 优化：更新头像（确保即使为空也有默认值）
        if (indexData.user.headPortrait.isNotEmpty) {
          userAvatar.value = indexData.user.headPortrait;
          logDebug('✅ 用户头像已更新: ${userAvatar.value}');
        } else {
          // 服务器返回空头像时，保持默认头像
          logDebug('⚠️ 服务器返回的用户头像为空，使用默认头像');
        }
        
        if (isBound.value && indexData.user.halfHeadPortrait.isNotEmpty) {
          partnerAvatar.value = indexData.user.halfHeadPortrait;
          logDebug('✅ 伴侣头像已更新: ${partnerAvatar.value}');
        } else if (!isBound.value) {
          partnerAvatar.value = "assets/images/kissu_home_add_avair.webp";
          logDebug('📌 未绑定状态，使用加号图标');
        } else {
          // 已绑定但服务器返回空头像时，使用默认头像
          partnerAvatar.value = "assets/3.0/kissu3_love_avater.webp";
          logWarning('⚠️ 服务器返回的伴侣头像为空，使用默认头像');
        }
        
        // 更新照片墙
        if (indexData.photo.photoWall.isNotEmpty) {
          photoWallUrl.value = indexData.photo.photoWall;
          logDebug('📸 照片墙URL: ${photoWallUrl.value}');
        } else {
          photoWallUrl.value = "assets/images/kissu_icon.webp";
          logWarning('📸 照片墙为空，使用默认图片');
        }
        
        // 🚀 优化：预加载网络头像（在批量更新后异步执行，不阻塞UI）
        if (indexData.user.headPortrait.isNotEmpty) {
          _precacheAvatarImage(indexData.user.headPortrait);
        }
        if (isBound.value && indexData.user.halfHeadPortrait.isNotEmpty) {
          _precacheAvatarImage(indexData.user.halfHeadPortrait);
        }
        
        // 更新天气数据
        _updateWeatherData(indexData.weather);
        
        // 缓存VIP数据，用于在onReady中检查（只检查一次）
        _cachedVipData = indexData.vipData;
        
        logDebug('✅ 首页数据加载成功: 绑定状态=${isBound.value}, 恋爱天数=${loveDays.value}, 距离=${distance.value}');
      } else {
        logWarning('❌ 首页数据加载失败: ${result.msg}');
        // 失败时回退到加载本地用户信息
        loadUserInfo();
      }
    } catch (e) {
      logError('❌ 首页数据加载异常: $e');
      // 异常时回退到加载本地用户信息
      loadUserInfo();
    } finally {
      _isLoadingIndexData = false;
    }
  }

  /// 加载用户信息和绑定状态
  void loadUserInfo() {
    final user = UserManager.currentUser;
    // 更新会员状态
    isVip.value = UserManager.isVip;
    isForeverVip.value = UserManager.isForeverVip;
    
    if (user != null) {
      // 🚀 优化：用户头像（确保有值，即使本地缓存也为空）
      if (user.headPortrait?.isNotEmpty == true) {
        userAvatar.value = user.headPortrait!;
        logDebug('✅ 从本地加载用户头像: ${userAvatar.value}');
      } else {
        // 本地也没有头像时，使用默认头像
        userAvatar.value = "assets/3.0/kissu3_love_avater.webp";
        logWarning('⚠️ 本地用户头像为空，使用默认头像');
      }
      
      // 绑定状态处理 (0从未绑定，1已绑定，2已解绑)
      final bindStatus = user.bindStatus.toString();
      isBound.value = bindStatus.toString() == "1";
      
      if (isBound.value) {
        // 已绑定状态，获取伴侣头像
        _loadPartnerAvatar(user);
        // 获取距离信息
        // _loadDistanceInfo();
        // 加载恋爱天数
        _loadLoveDays(user);
        // 天气数据现在从首页接口统一获取，不再单独调用
      } else {
        // 未绑定状态，重置伴侣头像
        partnerAvatar.value = "assets/images/kissu_home_add_avair.webp";
        logDebug('📌 未绑定状态，使用加号图标');
        // 重置距离信息
        distance.value = "0KM";
        // 重置停留点数量
        stayCount.value = 0;
        // 重置恋爱天数
        loveDays.value = 0;
      }
    } else {
      // 🚀 优化：用户未登录或用户信息为空时，确保使用默认头像
      userAvatar.value = "assets/3.0/kissu3_love_avater.webp";
      partnerAvatar.value = "assets/images/kissu_home_add_avair.webp";
      logDebug('⚠️ 用户信息为空，使用默认头像');
    }
  }
  
  /// 检查并刷新用户信息（只在app启动时首次调用）
  Future<void> checkAndRefreshUserInfoOnAppStartup() async {
    // 如果app已经启动过，跳过刷新
    if (_hasAppStartedThisSession) {
      logDebug('⏭️ App已在此会话中启动过，跳过用户信息刷新');
      return;
    }
    
    try {
      logDebug('🚀 App首次启动，刷新用户信息...');
      await refreshUserInfoFromServer();
      
      // 标记app已启动
      _hasAppStartedThisSession = true;
      logDebug('✅ 用户信息已刷新，已标记app启动状态');
    } catch (e) {
      logError('❌ App启动时刷新用户信息失败: $e');
    }
  }
  
  /// 从服务器刷新用户信息并更新缓存
  Future<void> refreshUserInfoFromServer() async {
    // 防重复调用：如果正在刷新中，直接返回
    if (_isRefreshingUserInfo) {
      logDebug('⏭️ 用户信息正在刷新中，跳过重复调用');
      return;
    }
    
    // 防重复调用：如果最近已经刷新过，跳过
    final now = DateTime.now();
    if (_lastUserInfoRefreshTime != null && 
        now.difference(_lastUserInfoRefreshTime!).inSeconds < 3) {
      logDebug('⏭️ 用户信息最近已刷新（${now.difference(_lastUserInfoRefreshTime!).inSeconds}秒前），跳过重复调用');
      return;
    }
    
    _isRefreshingUserInfo = true;
    _lastUserInfoRefreshTime = now;
    
    try {
      logDebug('🔄 开始从服务器刷新用户信息...');
      
      final success = await _authService.refreshUserInfoFromServer();
      
      if (success) {
        logDebug('✅ 用户信息刷新成功，重新加载本地用户信息');
        // 刷新成功后重新加载用户信息到UI
        loadUserInfo();
      } else {
        logDebug('⚠️ 用户信息刷新失败，使用本地缓存数据');
      }
    } catch (e) {
      logError('❌ 刷新用户信息时发生异常: $e');
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
      logDebug('✅ 从loverInfo加载伴侣头像: ${partnerAvatar.value}');
      // 🚀 优化：预加载网络头像
      _precacheAvatarImage(partnerAvatar.value);
    } 
    // 其次使用halfUserInfo中的头像
    else if (user.halfUserInfo?.headPortrait?.isNotEmpty == true) {
      partnerAvatar.value = user.halfUserInfo!.headPortrait!;
      logDebug('✅ 从halfUserInfo加载伴侣头像: ${partnerAvatar.value}');
      // 🚀 优化：预加载网络头像
      _precacheAvatarImage(partnerAvatar.value);
    }
    // 否则使用默认头像
    else {
      partnerAvatar.value = "assets/3.0/kissu3_love_avater.webp";
      logWarning('⚠️ 伴侣头像为空，使用默认头像');
    }
  }
  
  /// 🚀 预加载头像图片到缓存
  void _precacheAvatarImage(String imageUrl) {
    if (imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      return; // 只预加载网络图片
    }
    
    try {
      if (Get.context != null) {
        precacheImage(
          NetworkImage(imageUrl),
          Get.context!,
        ).then((_) {
          logDebug('✅ 头像预加载成功: $imageUrl');
        }).catchError((error) {
          logWarning('⚠️ 头像预加载失败: $imageUrl, 错误: $error');
        });
      }
    } catch (e) {
      logError('⚠️ 头像预加载异常: $e');
    }
  }
  
  /// 加载恋爱天数
  void _loadLoveDays(user) {
    // 直接使用服务器返回的loveDays数据
    if (user.loverInfo?.loveDays != null) {
      loveDays.value = user.loverInfo!.loveDays!;
      logDebug('🏠 加载恋爱天数: ${loveDays.value}天');
    } else {
      loveDays.value = 0;
      logDebug('🏠 恋爱天数数据为空，设置为0');
    }
  }
  
  /// 加载距离信息和停留点数量（已废弃，现在使用 loadIndexData）
  // @Deprecated('使用 loadIndexData() 替代')
  // Future<void> _loadDistanceInfo() async {
  //   try {
  //     debugPrint('📍 开始获取距离信息和停留点数量...');
  //     final result = await LocationApi().getLocation();
      
  //     if (result.isSuccess && result.data != null) {
  //       final locationData = result.data!;
        
  //       // 获取用户和伴侣的位置数据
  //       final userLocation = locationData.userLocationMobileDevice;
  //       final partnerLocation = locationData.halfLocationMobileDevice;
        
  //       // 优先使用用户数据中的距离信息
  //       if (userLocation?.distance != null && userLocation!.distance!.isNotEmpty) {
  //         distance.value = userLocation.distance!;
  //         debugPrint('📍 获取到距离信息: ${distance.value}');
  //       } else if (partnerLocation?.distance != null && partnerLocation!.distance!.isNotEmpty) {
  //         distance.value = partnerLocation.distance!;
  //         debugPrint('📍 获取到距离信息: ${distance.value}');
  //       } else {
  //         // 如果都没有距离信息，尝试计算距离
  //         if (userLocation?.latitude != null && userLocation?.longitude != null &&
  //             partnerLocation?.latitude != null && partnerLocation?.longitude != null) {
  //           final userLat = double.tryParse(userLocation!.latitude!);
  //           final userLng = double.tryParse(userLocation.longitude!);
  //           final partnerLat = double.tryParse(partnerLocation!.latitude!);
  //           final partnerLng = double.tryParse(partnerLocation.longitude!);
            
  //           if (userLat != null && userLng != null && partnerLat != null && partnerLng != null) {
  //             final calculatedDistance = _calculateDistance(userLat, userLng, partnerLat, partnerLng);
  //             distance.value = "${calculatedDistance.toStringAsFixed(1)}KM";
  //             debugPrint('📍 计算得到距离: ${distance.value}');
  //           } else {
  //             distance.value = "0KM";
  //             debugPrint('📍 无法解析坐标，设置默认距离');
  //           }
  //         } else {
  //           distance.value = "0KM";
  //           debugPrint('📍 缺少位置信息，设置默认距离');
  //         }
  //       }
        
  //       // 获取停留点数量（优先从伴侣数据获取，因为要显示"TA的足迹"）
  //       final partnerStayCollect = partnerLocation?.stayCollect;
  //       if (partnerStayCollect != null && partnerStayCollect.stayCount != null) {
  //         stayCount.value = partnerStayCollect.stayCount!;
  //         debugPrint('📍 获取到停留点数量: ${stayCount.value}');
  //       } else {
  //         stayCount.value = 0;
  //         debugPrint('📍 停留点数量为空，设置默认值0');
  //       }
  //     } else {
  //       debugPrint('❌ 获取距离信息失败: ${result.msg}');
  //       distance.value = "0KM";
  //       stayCount.value = 0;
  //     }
  //   } catch (e) {
  //     debugPrint('❌ 获取距离信息异常: $e');
  //     distance.value = "0KM";
  //     stayCount.value = 0;
  //   }
  // }
  
  // /// 计算两点间距离（使用Haversine公式）
  // double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
  //   const double earthRadius = 6371; // 地球半径（公里）
    
  //   final double dLat = _degreesToRadians(lat2 - lat1);
  //   final double dLng = _degreesToRadians(lng2 - lng1);
    
  //   final double a = sin(dLat / 2) * sin(dLat / 2) +
  //       cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
  //   final double c = 2 * asin(sqrt(a));
    
  //   return earthRadius * c;
  // }
  
  // /// 角度转弧度
  // double _degreesToRadians(double degrees) {
  //   return degrees * (3.14159265359 / 180);
  // }
  
  
  /// 绑定成功后刷新数据
  Future<void> _refreshAfterBinding() async {
    try {
      // 刷新用户信息
      await UserManager.refreshUserInfo();
      
      // 重新加载当前页面数据，但不触发引导图检查（避免重复弹窗）
      loadIndexData();
      
      // 绑定弹窗关闭后，继续弹窗流程（VIP购买弹窗 -> VIP推广弹窗 -> 引导图）
      logDebug('💑 绑定弹窗关闭后，继续弹窗流程');
      Future.delayed(const Duration(milliseconds: 500), () async {
        await _popupService.checkAndShowVipPurchaseDialog();
        
        Future.delayed(const Duration(milliseconds: 500), () async {
          await _popupService.checkAndShowVipPromo();
          
          Future.delayed(const Duration(milliseconds: 500), () {
            _popupService.checkAndShowGuide1();
          });
        });
      });
      
      // 首页绑定状态已刷新
    } catch (e) {
      // 刷新首页绑定状态失败
    }
  }
  
  /// 外部调用的刷新方法（用于其他页面通知首页更新）
  Future<void> refreshUserInfoAndState() async {
    try {
      logDebug('🏠 首页收到刷新通知，正在更新用户信息...', tag: 'Home');
      // 不需要再次调用 UserManager.refreshUserInfo()，因为调用方已经刷新了
      // 外部刷新时不触发引导图检查，避免重复弹窗
      loadIndexData();
      logDebug('🏠 首页绑定状态已更新: ${isBound.value}', tag: 'Home');
    } catch (e) {
      logError('🏠 首页刷新绑定状态失败: $e', tag: 'Home', error: e);
    }
  }

  void onButtonTap(int index) async {
    selectedIndex.value = index;
    logDebug("🔍 底部导航按钮 $index 被点击");
    
    // 埋点：底部导航栏点击
    final navigationNames = ['定位', '足迹', '聊天', '用机记录', '我的'];
    if (index >= 0 && index < navigationNames.length) {
      AnalyticsHelper.trackBottomNavigation(navigationName: navigationNames[index]);
    }
    
    // 埋点：首页离开（进入下一页）
    _trackHomePageExit();
    
    // 执行导航逻辑
    switch (index) {
      case 0:
        // 定位（新版）- 添加会员检查
        logDebug("📍 准备跳转到定位V2页面（检查会员状态）");
        VipNavigationHelper.navigateToLocationWithVipCheck();
        break;
      case 1:
        // 地图 - 返回时刷新首页数据
        await Get.to(
          () => TrackPage(),
          binding: TrackBinding(),
          transition: Transition.downToUp,
        );
        logDebug('🔙 从足迹页面返回首页，刷新数据');
        onPageResumed();
        break;
      case 2:
        // 聊天 - 未绑定时弹出绑定弹窗，已绑定才进入聊天页面
        if (!isBound.value) {
          // 未绑定，弹出绑定弹窗
          final currentContext = Get.context;
          if (currentContext != null) {
            CustomBottomDialog.show(
              context: currentContext,
              caller: SourcePageUtilsCaller.home,
              sourceEvent: HomeEvents.bottomNavigation, // 底部导航点击
              onClose: () {
                logDebug('💑 聊天入口绑定弹窗已关闭');
                // 绑定弹窗关闭后刷新首页数据
                onPageResumed();
              },
            );
          }
          return;
        }
        // 已绑定 - 打开时就清空未读数，返回时刷新首页数据
        try {
          final im = TencentIMService.instance;
          im.clearC2CUnreadCount();
        } catch (_) {}
        await Get.toNamed(
          KissuRoutePath.chat,
        );
        logDebug('🔙 从聊天页面返回首页，刷新数据');
        onPageResumed();
        break;
      case 3:
        // 用机记录 - 返回时刷新首页数据
        await Get.to(
          () => const DeviceUsagePage(sourceEvent: HomeEvents.bottomNavigation),
          binding: DeviceUsageBinding(),
          transition: Transition.downToUp,
        );
        logDebug('🔙 从用机记录页面返回首页，刷新数据');
        onPageResumed();
        break;
      case 4:
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
    logDebug('📭 点击消息中心按钮，进入消息列表');
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
        return "assets/images/kissu_home_tab_location.webp";
      case 1:
        return "assets/images/kissu_home_tab_foot.webp"; 
      case 2:
        return "assets/images/kissu_home_tab_chat.webp"; // 聊天
      case 3:
        return "assets/images/kissu_home_tab_history.webp"; // 用机记录
      case 4:
        return "assets/images/kissu_home_tab_mine.webp";
      default:
        return "assets/images/kissu_home_tab_location.webp";
    }
  }

  /// 获取底部图标路径（已废弃，现在使用文字）
  String getBottomIconPath(int index) {
    switch (index) {
      case 0:
        return "assets/images/kissu_home_tab_locationT.webp";
      case 1:
        return "assets/images/kissu_home_tab_mapT.webp"; 
      case 2:
        return "assets/images/kissu_home_tab_chatT.webp"; // 聊天文字图标
      case 3:
        return "assets/images/kissu_home_tab_historyT.webp"; // 用机记录文字图标
      case 4:
        return "assets/images/kissu_home_tab_mineT.webp";
      default:
        return "assets/images/kissu_home_tab_locationT.webp";
    }
  }

  /// 获取tab标题文字
  String getTabTitle(int index) {
    switch (index) {
      case 0:
        return "定位";
      case 1:
        return "足迹";
      case 2:
        return "聊天";
      case 3:
        return "用机记录";
      case 4:
        return "我的";
      default:
        return "";
    }
  }
  
  /// 手动启动定位服务
  Future<void> startLocationService() async {
    await _requestLocationPermissionAndStartService();
  }

  /// 手动请求后台定位权限
  Future<void> requestBackgroundLocationPermission() async {
    try {
      logDebug('🏠 首页手动请求后台定位权限');
      bool success = await _locationService.requestBackgroundLocationPermission();
      
      if (success) {
        CustomToast.show(
          Get.context!,
          '后台定位权限已获取，可以后台记录足迹',
        );
      }
    } catch (e) {
      logError('🏠 首页请求后台定位权限失败: $e');
    }
  }
  
  /// 停止定位服务
  void stopLocationService() {
    try {
      _locationService.stopLocation();
      isLocationServiceStarted.value = false;
      logDebug('定位服务已停止');
      CustomToast.show(
        Get.context!,
        '定位服务已停止',
      );
    } catch (e) {
      logError('停止定位服务失败: $e');
    }
  }
  
  /// 获取定位服务状态
  // Map<String, dynamic> getLocationServiceStatus() {
  //   return _locationService.serviceStatus;
  // }
  
  // /// 手动上报当前位置
  // Future<bool> reportCurrentLocation() async {
  //   return await _locationService.reportCurrentLocation();
  // }
  
  // /// 强制上报所有待上报数据
  // Future<bool> forceReportAllPending() async {
  //   return await _locationService.forceReportAllPending();
  // }
  
  /// 加载视图模式
  Future<void> _loadViewMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getBool('home_view_mode') ?? true; // 默认屏视图
      isScreenView.value = savedMode;
      logDebug('加载视图模式: ${savedMode ? "屏视图" : "岛视图"}');
    } catch (e) {
      logError('加载视图模式失败: $e');
      isScreenView.value = true; // 出错时默认屏视图
    }
  }
  
  /// 保存视图模式
  Future<void> _saveViewMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('home_view_mode', isScreenView.value);
      logDebug('保存视图模式: ${isScreenView.value ? "屏视图" : "岛视图"}');
    } catch (e) {
      logError('保存视图模式失败: $e');
    }
  }
  
  /// 切换视图模式
  void toggleViewMode() {
    isScreenView.value = !isScreenView.value;
    _saveViewMode();
    logDebug('切换到: ${isScreenView.value ? "屏视图" : "岛视图"}');
  }

  /// 另一半设备信息（来自 /index 接口的 half_user_data）
  /// 供聊天页面顶部设备信息栏使用
  final RxString halfDevicePower = '未知'.obs;
  final RxString halfDeviceNetworkName = '未知'.obs;
  final RxString halfDeviceMobileModel = '未知'.obs;
  final RxString halfDeviceDistance = '未知'.obs;
  
   
  
  /// 设置红点监听器，当子红点变化时自动更新总红点数
  void _setupRedDotListeners() {
    // 监听系统消息红点变化
    ever(systemNoticeRedDot, (_) {
      redDotCount.value = systemNoticeRedDot.value + interactionNoticeRedDot.value;
      logDebug('📊 系统消息红点变化，更新总红点数: ${redDotCount.value}');
    });
    
    // 监听互动消息红点变化
    ever(interactionNoticeRedDot, (_) {
      redDotCount.value = systemNoticeRedDot.value + interactionNoticeRedDot.value;
      logDebug('📊 互动消息红点变化，更新总红点数: ${redDotCount.value}');
    });
  }

  /// 监听腾讯 IM 单聊未读数变化，用于首页底部聊天角标
  void _setupChatUnreadListener() {
    try {
      final im = TencentIMService.instance;
      chatUnreadCount.value = im.c2cUnreadCount.value;
      ever<int>(im.c2cUnreadCount, (value) {
        chatUnreadCount.value = value;
        logDebug('💬 IM 未读数更新: $value');
      });
      // 初次进入首页时主动同步一次（处理离线消息未读）
      im.syncC2CUnreadCount();
    } catch (e) {
      logError('⚠️ 初始化聊天未读监听失败: $e');
    }
  }

  /// 设置应用生命周期监听
  void _setupAppLifecycleListener() {
    try {
      _appLifecycleService = AppLifecycleService.instance;
      
      // 监听应用状态变化
      _appLifecycleSubscription = _appLifecycleService.appState.listen((state) {
        _handleAppLifecycleChange(state);
      });
      
      logDebug('📱 首页应用生命周期监听已设置');
    } catch (e) {
      logError('❌ 设置首页应用生命周期监听失败: $e');
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
    logDebug('📱 首页：应用进入后台');
    // 埋点：首页离开（切换到后台）
    _trackHomePageExitToBackground();
  }
  
  /// 埋点：首页离开（切换到后台）
  void _trackHomePageExitToBackground() {
    if (_hasTrackedHomePageExit || _homePageEnterTime == null) return;
    _hasTrackedHomePageExit = true;
    
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final duration = currentTime - _homePageEnterTime!;
    
    // 计算会员状态
    final userInfo = UserManager.currentUser;
    int vipStatus = 0;
    if (userInfo != null) {
      final isVip = userInfo.isVip ?? 0;
      final vipEndTime = userInfo.vipEndTime ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      if (isVip == 1) {
        vipStatus = (vipEndTime > now) ? 1 : 2;
      }
    }
    
    AnalyticsManager.instance.trackPageView(
      pageId: HomeEvents.pageId,
      eventId: HomeEvents.page,
      enterTime: _homePageEnterTime!,
      duration: duration,
      exitType: ExitTypeValue.toBackground,
      params: {
        AnalyticsParams.vipStatus: vipStatus,
        AnalyticsParams.bindStatus: userInfo?.bindStatus ?? 0,
        AnalyticsParams.action188: userInfo?.isCheckIn ?? 0,
        AnalyticsParams.bindNum: userInfo?.bindNum ?? 0,
      },
    );
    
    logDebug('� 首页离开埋点（切换到后台）：停留${duration}秒');
  }
  
  /// 应用返回前台
  void _onAppReturnedToForeground() {
    logDebug('📱 首页：应用返回前台，刷新首页数据');
    
    // 埋点：重新记录首页进入时间（从后台恢复）
    if (_hasTrackedHomePageExit) {
      _homePageEnterTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      _hasTrackedHomePageExit = false;
      logDebug('📊 首页从后台恢复，重新记录进入时间');
    }
    
    // 🔥 优化：应用返回前台时刷新一次首页数据（带防重复调用保护）
    loadIndexData();
  }
  
  /// 跳转到H5页面
  Future<void> navigateToH5(
    String url, {
    bool showAppBar = true,
    String? title,
    Color? backgroundColor,
    bool showLoadingIndicator = true, // 是否显示加载动画，默认显示
  }) async {
    if (url.isNotEmpty) {
      // 埋点：首页离开（进入下一页）
      _trackHomePageExit();
      
      await Get.to(
        () => AgreementWebViewPage(
          title: title ??
              (activityTitle.value.isNotEmpty
                  ? activityTitle.value
                  : '活动详情'),
          url: url,
          showAppBar: showAppBar,
          backgroundColor: backgroundColor,
          showLoadingIndicator: showLoadingIndicator,
        ),
        transition: Transition.rightToLeft,
      );
      
      // 从H5页面返回后，重置埋点状态
      _homePageEnterTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      _hasTrackedHomePageExit = false;
      logDebug('🔙 从H5页面返回首页，重置埋点状态，新进入时间=${_homePageEnterTime}');
    } else {
      logDebug('H5链接为空，无法跳转');
    }
  }
  
  /// 跳转到我的页面，先刷新数据
  Future<void> _navigateToMinePage() async {
    try {
      logDebug('🔄 准备跳转到我的页面，先刷新用户数据...');
      
      // 先刷新用户信息
      await refreshUserInfoFromServer();
      
      // 然后跳转到我的页面，并在返回时刷新首页数据
      await Get.to(
        () => MinePage(),
        binding: MineBinding(),
        transition: Transition.downToUp,
      );
      
      // 从我的页面返回时，刷新首页数据
      logDebug('🔙 从我的页面返回首页，刷新数据');
      onPageResumed();
    } catch (e) {
      logError('❌ 跳转到我的页面时刷新数据失败: $e');
      // 即使刷新失败也要跳转，不影响用户体验
      await Get.to(
        () => MinePage(),
        binding: MineBinding(),
        transition: Transition.downToUp,
      );
      // 返回时也要刷新
      logDebug('🔙 从我的页面返回首页（异常流程），刷新数据');
      onPageResumed();
    }
  }
  
  /// 跳转到恋爱信息页面，并在返回时刷新首页数据
  Future<void> navigateToLoveInfoPage() async {
    // 埋点：首页离开（进入下一页）
    _trackHomePageExit();
    
    logDebug('💕 从首页跳转到恋爱信息页面');
    await Get.to(
      () => const LoveInfoPage(),
      transition: Transition.rightToLeft,
    );
    // 从恋爱信息页面返回时，刷新首页数据
    logDebug('💕 从恋爱信息页面返回首页，刷新数据');
    onPageResumed();
  }

  /// 检查版本更新（首页自动检查）
  Future<void> _checkVersionUpdate() async {
    try {
      logDebug('🔄 开始检查版本更新');
      
      // 延迟一段时间后检查，避免影响首页加载
      await Future.delayed(const Duration(milliseconds: 800));
      
      final currentContext = Get.context;
      if (currentContext != null) {
        final versionService = Get.find<VersionService>();
        await versionService.checkVersionForHomePage(currentContext);
        logDebug('✅ 版本检查完成');
      } else {
        logDebug('⚠️ 无法获取Context，跳过版本检查');
      }
    } catch (e) {
      logError('❌ 检查版本更新失败: $e');
    }
  }

  /// 显示引导层
  void displayGuideOverlay() {
    _popupService.displayGuideOverlay();
  }

  /// 隐藏引导层
  void hideGuideOverlay() {
    _popupService.hideGuideOverlay();
  }

  /// 引导图1关闭后的回调
  void onGuide1Dismissed() {
    _popupService.onGuide1Dismissed();
  }

  /// 引导图2关闭后的回调
  void onGuide2Dismissed() {
    _popupService.onGuide2Dismissed();
  }

  /// 检查定位权限状态并显示绑定弹窗
  Future<void> _checkLocationPermissionAndShowBindingDialog() async {
    try {
      logDebug('🔍 检查定位权限状态...');
      
      // 检查定位权限状态
      final permissionManager = LocationPermissionManager.instance;
      bool hasLocationPermission = await permissionManager.isLocationPermissionGranted();
      
      if (hasLocationPermission) {
        logDebug('✅ 用户已有定位权限，启动弹窗流程');
        // 使用弹窗服务启动弹窗流程
        await _popupService.startPopupFlow();
      } else {
        logDebug('❌ 用户没有定位权限，优先级顺序：请求权限 -> 绑定弹窗 -> VIP购买弹窗 -> VIP推广 -> 引导图');
        // 没有定位权限，请求权限（权限回调中会启动弹窗流程）
        await _requestLocationPermissionOnHomePage();
      }
    } catch (e) {
      logError('❌ 检查定位权限状态失败: $e');
      await _requestLocationPermissionOnHomePage();
    }
  }

  /// 显示VIP开通弹窗（调试用）
  void showVipPurchaseDialog() {
    _popupService.showVipPurchaseDialogForDebug();
  }

  /// 检查并显示引导层（调试模式：一直显示）
  Future<void> checkAndShowGuide() async {
    await _popupService.checkAndShowGuideDebug();
  }
  
  /// 更新种草按钮显示状态
  /// 规则：
  /// 1. 未绑定或未开通会员：每次打开都显示
  /// 2. 已开通会员：关闭后每天只显示一次
  Future<void> _updateSeedingButtonVisibility() async {
    try {
      // 检查 seedingStatus 是否为 "1"
      if (seedingStatus.value != '1') {
        showSeedingButton.value = false;
        logDebug('🌱 种草按钮不显示：seedingStatus=${seedingStatus.value}');
        return;
      }
      
      // 检查是否已绑定和是否为会员
      final bound = isBound.value;
      final vip = isVip.value;
      
      // 未绑定或未开通会员：每次打开都显示
      if (!bound || !vip) {
        showSeedingButton.value = true;
        logDebug('🌱 种草按钮显示：未绑定或未开通会员');
        return;
      }
      
      // 已开通会员：检查今天是否已关闭过
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toString().substring(0, 10); // YYYY-MM-DD
      final lastClosedDate = prefs.getString('seeding_button_last_closed_date') ?? '';
      
      if (lastClosedDate == today) {
        // 今天已关闭过，不显示
        showSeedingButton.value = false;
        logDebug('🌱 种草按钮不显示：今天已关闭过（$today）');
      } else {
        // 今天还未关闭过，显示
        showSeedingButton.value = true;
        logDebug('🌱 种草按钮显示：今天还未关闭过');
      }
    } catch (e) {
      logError('❌ 更新种草按钮显示状态失败: $e');
      showSeedingButton.value = false;
    }
  }
  
  /// 关闭种草按钮
  Future<void> closeSeedingButton() async {
    try {
      // 埋点：种草浮动按钮关闭
      _trackSeedingButtonClick(btnStatus: 0);
      
      showSeedingButton.value = false;
      
      // 如果是会员，记录今天已关闭
      if (isVip.value && isBound.value) {
        final prefs = await SharedPreferences.getInstance();
        final today = DateTime.now().toString().substring(0, 10); // YYYY-MM-DD
        await prefs.setString('seeding_button_last_closed_date', today);
        logDebug('🌱 种草按钮已关闭，记录日期：$today');
      } else {
        logDebug('🌱 种草按钮已关闭（非会员，不记录日期）');
      }
    } catch (e) {
      logError('❌ 关闭种草按钮失败: $e');
    }
  }
  
  /// 打开种草链接
  void openSeedingLink() {
    if (seedingLink.value.isNotEmpty) {
      // 埋点：种草浮动按钮点击（进入）
      _trackSeedingButtonClick(btnStatus: 1);
      
      // 埋点：首页离开（进入下一页）
      _trackHomePageExit();
      
      logDebug('🌱 打开种草链接: ${seedingLink.value}');
      Get.to(
        () => SeedingWebViewPage(
          url: seedingLink.value,
        ),
      );
    } else {
      logWarning('⚠️ 种草链接为空');
    }
  }
  
  /// 埋点：种草浮动按钮点击
  void _trackSeedingButtonClick({required int btnStatus}) {
    final userInfo = UserManager.currentUser;
    
    // 计算会员状态
    int vipStatus = 0;
    if (userInfo != null) {
      final isVip = userInfo.isVip ?? 0;
      final vipEndTime = userInfo.vipEndTime ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      if (isVip == 1) {
        vipStatus = (vipEndTime > now) ? 1 : 2;
      }
    }
    
    AnalyticsManager.instance.trackClick(
      pageId: HomeEvents.pageId,
      eventId: HomeEvents.seedingEvent,
      params: {
        AnalyticsParams.clickTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        AnalyticsParams.vipStatus: vipStatus,
        AnalyticsParams.bindStatus: userInfo?.bindStatus ?? 0,
        AnalyticsParams.action188: userInfo?.isCheckIn ?? 0,
        AnalyticsParams.bindNum: userInfo?.bindNum ?? 0,
        AnalyticsParams.btnStatus: btnStatus,
      },
    );
  }

  /// 更新天气数据（从首页接口数据中解析）
  void _updateWeatherData(WeatherData weatherData) {
    try {
      logDebug('🌤️ 开始解析首页天气数据');
      
      // 解析 base 数据
      if (weatherData.base.isNotEmpty) {
        final base = weatherData.base.first;
        weatherIconUrl.value = base.weatherIcon.isNotEmpty ? base.weatherIcon : null;
        weather.value = base.weather.isNotEmpty ? base.weather : null;
        currentTemp.value = base.temperature.isNotEmpty ? base.temperature : null;
          logDebug('🌤️ 解析 base 数据: icon=${weatherIconUrl.value}, weather=${weather.value}, temp=${currentTemp.value}');
      }
      
      // 解析 all 数据
      if (weatherData.all.isNotEmpty) {
        final all = weatherData.all.first;
        if (all.casts.isNotEmpty) {
          final todayCast = all.casts.first;
          minTemp.value = todayCast.nighttemp.isNotEmpty ? todayCast.nighttemp : null;
          maxTemp.value = todayCast.daytemp.isNotEmpty ? todayCast.daytemp : null;
          logDebug('🌤️ 解析 all 数据: min=${minTemp.value}, max=${maxTemp.value}');
        }
      }
      
      isWeatherLoading.value = false;
      logDebug('✅ 天气数据解析成功');
    } catch (e) {
      logError('❌ 天气数据解析异常: $e');
      isWeatherLoading.value = false;
    }
  }
  
  /// 预加载定位页面GIF动画
  /// 
  /// 在首页初始化时调用，提前加载定位页面需要的GIF动画
  /// 这样进入定位页面时可以直接从缓存读取，无需等待解码
  void _preloadLocationGifs() {
    // 延迟执行，避免影响首页加载性能
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        // 获取设备像素比
        final window = WidgetsBinding.instance.platformDispatcher.views.first;
        final devicePixelRatio = window.devicePixelRatio;
        
        // 预加载定位页面的GIF
        await GifPreloadService.preloadLocationGifs(devicePixelRatio);
        logDebug('✅ 定位页面GIF预加载已启动');
      } catch (e) {
        logError('❌ 预加载GIF失败: $e');
      }
    });
  }
  
}

