import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amap_map/amap_map.dart';
import 'package:x_amap_base/x_amap_base.dart';
import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'package:kissu_app/network/example/http_manager_example.dart';
import 'package:kissu_app/network/public/service_locator.dart';
import 'package:kissu_app/network/public/auth_service.dart';
import 'package:kissu_app/network/interceptor/api_response_interceptor.dart';
import 'package:kissu_app/services/payment_service.dart';
import 'package:kissu_app/services/jpush_service.dart';
import 'package:kissu_app/services/share_service.dart';
import 'package:kissu_app/services/permission_state_service.dart';
import 'package:kissu_app/services/simple_location_service.dart';
import 'package:kissu_app/services/location_permission_service.dart';
import 'package:kissu_app/services/app_lifecycle_service.dart';
import 'package:kissu_app/services/sensitive_data_service.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kissu_app/routers/kissu_route.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:oktoast/oktoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 确保Flutter绑定初始化
  
  // 设置高德地图隐私合规（必须在任何定位操作之前）
  try {
    // 设置定位插件隐私合规
    AMapFlutterLocation.updatePrivacyShow(true, true);
    AMapFlutterLocation.updatePrivacyAgree(true);
    
    // 设置地图插件隐私合规
    const AMapPrivacyStatement amapPrivacyStatement = 
        AMapPrivacyStatement(hasContains: true, hasShow: true, hasAgree: true);
    AMapInitializer.updatePrivacyAgree(amapPrivacyStatement);
    
    // 设置高德地图API Key
    AMapFlutterLocation.setApiKey('38edb925a25f22e3aae2f86ce7f2ff3b', '');
    
    print('高德地图隐私合规设置完成');
  } catch (e) {
    print('设置高德地图隐私合规失败: $e');
  }
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark,
    ),
  );
  try {
    // 步骤1: 初始化服务定位器
    await setupServiceLocator();

    // 步骤2: 预加载用户数据（确保AuthService能正确获取缓存）
    final authService = getIt<AuthService>();
    await authService.loadCurrentUser();
    print('用户数据预加载完成，登录状态: ${authService.isLoggedIn}');

    // 步骤3: 初始化HTTP管理器（会使用已注册的AuthService）
    await HttpManagerExample.initializeHttpManager();

    // 步骤4: 重置token失效处理状态，确保拦截器正常工作
    ApiResponseInterceptor.resetUnauthorizedState();
    print('Token失效拦截器状态已重置');

    // 步骤5: 初始化支付服务
    Get.put(PaymentService(), permanent: true);
    print('支付服务初始化完成');

    // 步骤6: 初始化极光推送服务
    Get.put(JPushService(), permanent: true);
    print('极光推送服务初始化完成');
    
    // 步骤7: 初始化友盟分享服务
    Get.put(ShareService(), permanent: true);
    print('友盟分享服务初始化完成');
    
    // 步骤8: 初始化权限状态管理服务
    Get.put(PermissionStateService(), permanent: true);
    print('权限状态管理服务初始化完成');
    
    // 步骤9: 初始化定位服务
    try {
      final locationService = SimpleLocationService();
      locationService.init(); // 关键：立即调用init方法设置API Key和隐私合规
      Get.put(locationService, permanent: true);
      print('定位服务初始化完成');
    } catch (e) {
      print('定位服务初始化失败: $e');
    }

    // 步骤9.1: 应用启动时检测和申请定位权限
    try {
      await _checkAndRequestLocationPermission();
    } catch (e) {
      print('❌ 应用启动时检测定位权限失败: $e');
    }
    
    // 步骤10: 初始化定位权限服务
    Get.put(LocationPermissionService(), permanent: true);
    print('定位权限服务初始化完成');
    
    // 步骤11: 初始化应用生命周期服务
    Get.put(AppLifecycleService(), permanent: true);
    print('应用生命周期服务初始化完成');
    
    // 步骤12: 初始化敏感数据上报服务
    Get.put(SensitiveDataService(), permanent: true);
    print('敏感数据上报服务初始化完成');
    
    // 步骤13: 上报APP打开事件
    try {
      final sensitiveDataService = getIt<SensitiveDataService>();
      await sensitiveDataService.reportAppOpen();
      print('APP打开事件上报完成');
    } catch (e) {
      print('APP打开事件上报失败: $e');
    }

    print('应用初始化完成');
  } catch (e) {
    print('应用初始化失败: $e');
  }

  runApp(OKToast(
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // 安全地初始化高德地图
    try {
      AMapInitializer.init(context, apiKey: const AMapApiKey(
        androidKey: '38edb925a25f22e3aae2f86ce7f2ff3b',
        iosKey: '38edb925a25f22e3aae2f86ce7f2ff3b',
      ));
      print('高德地图初始化成功');
    } catch (e) {
      print('高德地图初始化失败: $e');
    }
    
    return GetMaterialApp(
      title: 'Kissu App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations
            .delegate, // 👈 关键：提供 CupertinoLocalizations
      ],
      supportedLocales: const [
        Locale('zh', 'CN'), // 简体中文
        Locale('en', 'US'), // 英文（可选）
      ],
      locale: const Locale('zh', 'CN'), // 👈 默认中文
      getPages: KissuRoute.routes,
      initialRoute: _getInitialRoute(), // 动态获取初始路由
      unknownRoute: GetPage(
        name: '/notfound',
        page: () => Scaffold(body: Center(child: Text('页面不存在'))),
      ),
    );
  }

  /// 根据登录状态确定初始路由
  String _getInitialRoute() {
    try {
      // 确保服务定位器已初始化
      if (!getIt.isRegistered<AuthService>()) {
        print('AuthService 尚未注册，默认进入登录页');
        return KissuRoutePath.login;
      }
      
      final authService = getIt<AuthService>();
      // 检查用户是否已登录且有有效token
      if (authService.isLoggedIn && authService.userToken?.isNotEmpty == true) {
        final user = authService.currentUser;
        // 检查是否需要完善信息
        if (user != null && (user.nickname?.isEmpty ?? true)) {
          print('用户需要完善信息，进入信息设置页');
          return KissuRoutePath.infoSetting;
        } else {
          // 已登录且信息完善，直接进入首页
          print('用户已登录，进入首页: ${authService.userNickname ?? "未知用户"}');
          return KissuRoutePath.home;
        }
      } else {
        // 未登录或token无效，进入登录页
        print('用户未登录或token无效，进入登录页');
        return KissuRoutePath.login;
      }
    } catch (e) {
      // 发生错误时默认进入登录页
      print('检查登录状态时发生错误: $e，默认进入登录页');
      return KissuRoutePath.login;
    }
  }
}

/// 检测和申请定位权限
Future<void> _checkAndRequestLocationPermission() async {
  try {
    print('🔐 应用启动检测定位权限...');

    // 检查是否首次启动
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;

    if (isFirstLaunch) {
      // 首次启动，标记已启动并申请权限
      await prefs.setBool('is_first_launch', false);
      print('🆕 检测到首次启动，申请定位权限');
      await _requestLocationPermissionOnStartup();
    } else {
      // 非首次启动，检查权限状态
      print('🔄 检测到非首次启动，检查定位权限状态');
      await _checkLocationPermissionOnStartup();
    }
  } catch (e) {
    print('❌ 检测定位权限失败: $e');
  }
}

/// 首次启动申请定位权限
Future<void> _requestLocationPermissionOnStartup() async {
  try {
    final locationStatus = await Permission.location.status;
    print('🔐 当前定位权限状态: $locationStatus');

    if (locationStatus.isDenied) {
      print('🔐 申请定位权限...');
      final result = await Permission.location.request();
      print('🔐 权限申请结果: $result');

      if (result.isGranted) {
        // 权限获取成功，启动定位服务
        print('✅ 定位权限获取成功，启动定位服务');
        await _startLocationServiceIfNeeded();
      } else {
        print('❌ 定位权限申请被拒绝');
      }
    } else if (locationStatus.isGranted) {
      print('✅ 定位权限已授予，启动定位服务');
      await _startLocationServiceIfNeeded();
    }
  } catch (e) {
    print('❌ 首次启动申请权限失败: $e');
  }
}

/// 非首次启动检查定位权限
Future<void> _checkLocationPermissionOnStartup() async {
  try {
    final locationStatus = await Permission.location.status;
    print('🔐 检查定位权限状态: $locationStatus');

    if (locationStatus.isGranted) {
      print('✅ 定位权限已授予，启动定位服务');
      await _startLocationServiceIfNeeded();
    } else if (locationStatus.isDenied) {
      print('⚠️ 定位权限被拒绝，将在需要时重新申请');
    } else if (locationStatus.isPermanentlyDenied) {
      print('❌ 定位权限被永久拒绝');
    }
  } catch (e) {
    print('❌ 检查定位权限状态失败: $e');
  }
}

/// 启动定位服务（如果需要）
Future<void> _startLocationServiceIfNeeded() async {
  try {
    if (Get.isRegistered<SimpleLocationService>()) {
      final locationService = Get.find<SimpleLocationService>();
      if (!locationService.isLocationEnabled.value) {
        final success = await locationService.startLocation();
        if (success) {
          print('✅ 应用启动时定位服务启动成功');
        } else {
          print('❌ 应用启动时定位服务启动失败');
        }
      } else {
        print('✅ 定位服务已在运行');
      }
    } else {
      print('⚠️ SimpleLocationService 尚未注册');
    }
  } catch (e) {
    print('❌ 启动定位服务失败: $e');
  }
}
