import 'dart:async';

import 'package:get/get.dart';

import 'package:kissu_app/network/example/http_manager_example.dart';

import 'package:kissu_app/network/public/service_locator.dart';

import 'package:kissu_app/network/public/auth_service.dart';

import 'package:kissu_app/network/interceptor/api_response_interceptor.dart';
import 'package:kissu_app/pages/widget_center/widget_center_controller.dart';

import 'package:kissu_app/services/analytics/analytics_manager.dart';

import 'package:kissu_app/services/payment_service.dart';

// 🔥 已废弃：极光推送（推送现在走腾讯IM）

// import 'package:kissu_app/services/jpush_service.dart';

import 'package:kissu_app/services/share_service.dart';

import 'package:kissu_app/services/permission_state_service.dart';

import 'package:kissu_app/services/simple_location_service.dart';

import 'package:kissu_app/services/location_permission_service.dart';

import 'package:kissu_app/services/app_lifecycle_service.dart';

import 'package:kissu_app/services/sensitive_data_service.dart';

import 'package:kissu_app/services/app_usage_auto_report_service.dart';

import 'package:kissu_app/services/screen_lock_service.dart';

import 'package:kissu_app/services/smart_background_location_reminder.dart';

import 'package:kissu_app/services/foreground_location_service.dart';

import 'package:kissu_app/services/geofence_monitoring_service.dart';

import 'package:kissu_app/services/city_storage_service.dart';

import 'package:kissu_app/services/tencent_im_service.dart';

import 'package:kissu_app/services/relationship_animation_service.dart';

import 'package:kissu_app/utils/debug_util.dart';

import 'package:kissu_app/services/view_mode_service.dart';

import 'package:kissu_app/services/home_scroll_service.dart';

import 'package:kissu_app/services/first_launch_service.dart';

import 'package:kissu_app/services/version_service.dart';

import 'package:kissu_app/services/privacy_compliance_manager.dart';

import 'package:kissu_app/services/app_activation_service.dart';

import 'package:kissu_app/services/permission_upload_service.dart';

import 'package:kissu_app/network/tools/config/app_configN.dart';

import 'package:kissu_app/services/lottie_preload_service.dart';

import 'package:kissu_app/utils/map_style_loader.dart';

import 'package:kissu_app/services/map_preload_service.dart';

import 'package:kissu_app/network/utils/log_util.dart';

import 'package:kissu_app/network/interceptor/business_header_interceptor.dart';



/// 🚀 应用初始化器

/// 在启动页执行所有耗时的初始化操作，避免阻塞app启动

class AppInitializer {

  static bool _isInitialized = false;

  static bool _isInitializing = false; // 🔒 添加初始化中标志，防止并发调用

  static final List<Completer<void>> _waitingCompleters = []; // 等待初始化的Completer列表

  

  /// 初始化应用（在启动页调用）

  static Future<void> initialize() async {

    // 🔒 如果已经初始化完成，直接返回

    if (_isInitialized) {

      DebugUtil.warning('应用已经初始化过，跳过重复初始化');

      return;

    }

    

    // 🔒 如果正在初始化，等待当前初始化完成

    if (_isInitializing) {

      DebugUtil.check('应用正在初始化中，等待完成...');

      final completer = Completer<void>();

      _waitingCompleters.add(completer);

      return completer.future;

    }

    

    // 🔒 标记为正在初始化

    _isInitializing = true;

    

    try {

      DebugUtil.check('🚀 开始在启动页执行应用初始化...');

      

      // ========== 第一阶段：基础初始化（关键路径，必须快速完成）==========

      

      // 🚀 优化：并行执行不相互依赖的初始化步骤

      // 🔥 优化：减少超时时间，加快启动速度

      await Future.wait([

        // 步骤1: 初始化应用配置（同步操作，很快）

        AppConfigN.configuration().timeout(

          const Duration(milliseconds: 500), // 🔥 从1秒减少到0.5秒

          onTimeout: () => DebugUtil.warning('应用配置初始化超时'),

        ),

        

        // 步骤2: 初始化服务定位器

        setupServiceLocator().timeout(

        const Duration(seconds: 1), // 🔥 从2秒减少到1秒

        onTimeout: () => DebugUtil.error('服务定位器初始化超时'),

        ),

      ]);

      DebugUtil.check('应用配置和服务定位器初始化完成');



      // 步骤3: 预加载用户数据（必须在服务定位器之后）

      // 🔥 优化：减少超时时间，如果超时则跳过，不影响启动

      AuthService? authService;

      try {

        authService = getIt<AuthService>();

        await authService.loadCurrentUser().timeout(

          const Duration(milliseconds: 500), // 🔥 从1秒减少到0.5秒

          onTimeout: () => DebugUtil.warning('用户数据加载超时，继续启动'),

        );

        DebugUtil.check('用户数据预加载完成，登录状态: ${authService.isLoggedIn}');

      } catch (e) {

        DebugUtil.warning('用户数据预加载失败: $e，继续启动');

        // 如果获取失败，尝试重新获取

        try {

          authService = getIt<AuthService>();

        } catch (e2) {

          DebugUtil.error('无法获取AuthService: $e2');

        }

      }



      // 步骤4: 初始化HTTP管理器（必须在用户数据加载之后）

      await HttpManagerExample.initializeHttpManager().timeout(

        const Duration(seconds: 1),

        onTimeout: () => DebugUtil.warning('HTTP管理器初始化超时'),

      );

      DebugUtil.check('HTTP管理器初始化完成');



      // 🚀 优化：预初始化拦截器设备信息，避免每次请求都初始化

      try {

        await BusinessHeaderInterceptor.preInitializeDeviceInfo().timeout(

          const Duration(seconds: 1),

          onTimeout: () => DebugUtil.warning('设备信息预初始化超时'),

        );

        DebugUtil.check('设备信息预初始化完成');

      } catch (e) {

        DebugUtil.warning('设备信息预初始化失败: $e，将在首次请求时初始化');

      }



      // 🚀 优化：日志工具初始化移到后台，不阻塞启动

      LogUtil.instance.init().timeout(

        const Duration(seconds: 2),

        onTimeout: () => DebugUtil.warning('日志工具初始化超时'),

      ).then((_) {

        DebugUtil.check('日志工具初始化完成');

      }).catchError((e) {

        DebugUtil.error('日志工具初始化失败: $e');

      });



      // 步骤6: 重置token失效处理状态，确保拦截器正常工作

      ApiResponseInterceptor.resetUnauthorizedState();

      DebugUtil.check('Token失效拦截器状态已重置');

      

      // 记录是否需要自动登录IM

      final bool shouldAutoLoginIM = authService != null && authService.isLoggedIn && authService.currentUser != null;

      final currentUserForIM = authService?.currentUser; // 提前保存，避免后续作用域问题



      // ========== 第二阶段：第三方SDK初始化 ==========

      

      // 步骤7: 初始化埋点管理服务

      Get.put(AnalyticsManager(), permanent: true);

      DebugUtil.check('埋点管理服务初始化完成');

      

      // 步骤8: 初始化支付服务

      Get.put(PaymentService(), permanent: true);

      DebugUtil.check('支付服务初始化完成');



      // 🔥 已废弃：极光推送（推送现在走腾讯IM）

      // Get.put(JPushService(), permanent: true);

      // DebugUtil.info('极光推送服务已注册（等待隐私授权后初始化）');

      

      // 步骤9: 注册腾讯IM服务

      Get.put(TencentIMService(), permanent: true);

      DebugUtil.check('腾讯IM服务初始化完成');

      

      // 步骤10: 注册情侣关系动画服务

      Get.put(RelationshipAnimationService(), permanent: true);

      DebugUtil.check('情侣关系动画服务初始化完成');

      

      // 步骤11: IM自动登录（异步执行，不阻塞）

      if (shouldAutoLoginIM && currentUserForIM != null) {

        DebugUtil.check('检测到已登录用户，将在后台自动登录IM');

        final userForIM = currentUserForIM; // 保存引用

        Future.delayed(Duration.zero, () async {

          try {

            final imService = Get.find<TencentIMService>();

            await imService.loginIM(userForIM);

            DebugUtil.check('IM自动登录完成');

          } catch (e) {

            DebugUtil.error('自动登录IM失败: $e');

          }

        });

      }

      

      // 步骤12: 初始化友盟分享服务

      Get.put(ShareService(), permanent: true);

      DebugUtil.check('友盟分享服务初始化完成');

      

      // 步骤13: 初始化权限状态管理服务

      Get.put(PermissionStateService(), permanent: true);

      DebugUtil.check('权限状态管理服务初始化完成');

      

      // 步骤14: 初始化城市存储服务（异步初始化）

      Get.put(CityStorageService(), permanent: true);

      Future.delayed(Duration.zero, () async {

        try {

          await Get.find<CityStorageService>().init();

          DebugUtil.check('城市存储服务初始化完成');

        } catch (e) {

          DebugUtil.error('城市存储服务初始化失败: $e');

        }

      });

      

      // 步骤15: 注册定位服务（但不立即初始化，等待隐私授权）

      final locationService = SimpleLocationService();

      Get.put(locationService, permanent: true);

      locationService.init();

      DebugUtil.check('定位服务已注册（隐私授权已拒绝，等待用户同意后启用）');

      

      // 步骤16: 初始化定位权限服务

      Get.put(LocationPermissionService(), permanent: true);

      DebugUtil.check('定位权限服务初始化完成');

      

      // 步骤17: 初始化应用生命周期服务

      Get.put(AppLifecycleService(), permanent: true);

      DebugUtil.check('应用生命周期服务初始化完成');

      // 步骤17.5: 初始化小组件导航监听
      WidgetCenterController.setupWidgetNavigationHandler();
      DebugUtil.check('小组件导航监听初始化完成');

      

      // 步骤18: 初始化智能后台定位提醒服务

      Get.put(SmartBackgroundLocationReminder(), permanent: true);

      DebugUtil.check('智能后台定位提醒服务初始化完成');

      

      // 步骤19: 初始化前台定位服务

      Get.put(ForegroundLocationService(), permanent: true);

      DebugUtil.check('前台定位服务初始化完成');

      

      // 步骤20: 初始化电子围栏监测服务

      Get.put(GeofenceMonitoringService(), permanent: true);

      DebugUtil.check('电子围栏监测服务初始化完成');

      

      // 步骤21: 初始化敏感数据上报服务

      Get.put(SensitiveDataService(), permanent: true);

      DebugUtil.check('敏感数据上报服务初始化完成');

      

      // 步骤21.5: 初始化App使用记录自动上报服务

      Get.put(AppUsageAutoReportService(), permanent: true);

      DebugUtil.check('App使用记录自动上报服务初始化完成');

      

      // 步骤22: 初始化锁屏监听服务

      Get.put(ScreenLockService(), permanent: true);

      DebugUtil.check('锁屏监听服务初始化完成');

      

      // 步骤23: 初始化视图模式服务

      Get.put(ViewModeService(), permanent: true);

      DebugUtil.check('视图模式服务初始化完成');

      

      // 步骤24: 初始化首页滚动服务

      Get.put(HomeScrollService(), permanent: true);

      DebugUtil.check('首页滚动服务初始化完成');

      

      // 步骤25: 初始化首次启动服务

      Get.put(FirstLaunchService(), permanent: true);

      DebugUtil.check('首次启动服务初始化完成');

      

      // 步骤26: 初始化版本更新服务

      Get.put(VersionService(), permanent: true);

      DebugUtil.check('版本更新服务初始化完成');

      

      // 步骤26.5: 初始化App激活服务

      Get.put(AppActivationService(), permanent: true);

      DebugUtil.check('App激活服务初始化完成');

      

      // 步骤26.6: 初始化权限状态上传服务

      Get.put(PermissionUploadService(), permanent: true);

      DebugUtil.check('权限状态上传服务初始化完成');

      

      // 步骤27: 预加载VIP页面Lottie动画（非阻塞，后台执行）

      LottiePreloadService().preloadVipLottieAnimations().then((_) {

        DebugUtil.check('VIP页面Lottie动画预加载完成');

      }).catchError((e) {

        DebugUtil.error('VIP页面Lottie动画预加载失败: $e');

      });

      

      // 步骤28: 预加载地图自定义样式（非阻塞，后台执行）

      MapStyleLoader.preloadMapStyle().then((_) {

        DebugUtil.check('地图自定义样式预加载完成');

      }).catchError((e) {

        DebugUtil.error('地图自定义样式预加载失败: $e');

      });

      

      // 步骤29: 预加载地图资源（Marker图片等，非阻塞，后台执行）

      MapPreloadService.instance.preloadMapResources().then((_) {

        DebugUtil.check('地图Marker资源预加载完成');

      }).catchError((e) {

        DebugUtil.error('地图Marker资源预加载失败: $e');

      });

      

      // ========== 第三阶段：隐私合规管理器初始化 ==========

      

      // 步骤30: 初始化隐私合规管理器

      Get.put(PrivacyComplianceManager(), permanent: true);

      DebugUtil.check('隐私合规管理器初始化完成');

      

      _isInitialized = true;

      _isInitializing = false; // 🔒 重置初始化标志

      DebugUtil.check('✅ 应用初始化完成，等待用户隐私政策确认后启用完整功能');

      

      // 🔒 通知所有等待初始化的调用

      for (final completer in _waitingCompleters) {

        if (!completer.isCompleted) {

          completer.complete();

        }

      }

      _waitingCompleters.clear();

      

    } catch (e) {

      DebugUtil.error('❌ 应用初始化失败: $e');

      

      // 🔒 初始化失败时也要通知等待的调用

      for (final completer in _waitingCompleters) {

        if (!completer.isCompleted) {

          completer.completeError(e);

        }

      }

      _waitingCompleters.clear();

      _isInitializing = false; // 🔒 重置标志，允许重试

      

      rethrow;

    }

  }

  

  /// 检查是否已初始化

  static bool get isInitialized => _isInitialized;

}

