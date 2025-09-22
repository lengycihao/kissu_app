import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:kissu_app/services/smart_background_location_reminder.dart';
import 'package:kissu_app/services/foreground_location_service.dart';
import 'package:kissu_app/utils/debug_util.dart';
import 'package:kissu_app/services/view_mode_service.dart';
import 'package:kissu_app/services/first_launch_service.dart';
import 'package:kissu_app/services/openinstall_service.dart';
import 'package:kissu_app/services/privacy_compliance_manager.dart';
import 'package:kissu_app/network/utils/dir_util.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kissu_app/routers/kissu_route.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/network/utils/log_util.dart';
import 'package:kissu_app/utils/memory_manager.dart';
import 'package:oktoast/oktoast.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 确保Flutter绑定初始化
  
  // 初始化目录工具配置
  setInitDir(initTempDir: true);
  
  // 初始化日志工具
  await LogUtil.instance.init();
  
  // 初始化内存管理器
  MemoryManager.initialize();
  
  // 🔒 隐私合规：高德地图的所有初始化都移到用户同意隐私政策后
  // 避免在应用启动时就设置API Key触发SDK初始化
  // try {
  //   AMapFlutterLocation.updatePrivacyShow(true, true);
  //   AMapFlutterLocation.setApiKey('38edb925a25f22e3aae2f86ce7f2ff3b', '');
  //   DebugUtil.success('高德地图隐私合规预设置完成（等待用户同意）');
  // } catch (e) {
  //   DebugUtil.error('设置高德地图隐私合规失败: $e');
  // }
  
  DebugUtil.info('高德地图初始化延迟到隐私政策同意后');
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark,
    ),
  );
  try {
    // ========== 第一阶段：基础初始化（无隐私风险） ==========
    
    // 步骤1: 初始化服务定位器
    await setupServiceLocator();

    // 步骤2: 预加载用户数据（确保AuthService能正确获取缓存）
    final authService = getIt<AuthService>();
    await authService.loadCurrentUser();
    DebugUtil.info('用户数据预加载完成，登录状态: ${authService.isLoggedIn}');

    // 步骤3: 初始化HTTP管理器（会使用已注册的AuthService）
    await HttpManagerExample.initializeHttpManager();

    // 步骤4: 重置token失效处理状态，确保拦截器正常工作
    ApiResponseInterceptor.resetUnauthorizedState();
    DebugUtil.info('Token失效拦截器状态已重置');

    // ========== 第二阶段：第三方SDK初始化（保持现有功能） ==========
    
    // 步骤5: 初始化支付服务（用户需要，保持现有逻辑）
    Get.put(PaymentService(), permanent: true);
    DebugUtil.success('支付服务初始化完成');

    // 步骤6: 注册极光推送服务（但不立即初始化，等待隐私授权）
    Get.put(JPushService(), permanent: true);
    DebugUtil.info('极光推送服务已注册（等待隐私授权后初始化）');
    
    // 步骤7: 初始化友盟分享服务（保持现有逻辑，但不立即授权隐私）
    Get.put(ShareService(), permanent: true);
    DebugUtil.success('友盟分享服务初始化完成');
    
    // 步骤8: 初始化权限状态管理服务
    Get.put(PermissionStateService(), permanent: true);
    DebugUtil.success('权限状态管理服务初始化完成');
    
    // 步骤9: 注册定位服务（但不立即初始化，等待隐私授权）
    // 🔒 隐私合规：SimpleLocationService的初始化移到隐私政策同意后
    final locationService = SimpleLocationService();
    Get.put(locationService, permanent: true);
    // 初始化基础设置（明确拒绝隐私授权，直到用户同意）
    locationService.init();
    DebugUtil.info('定位服务已注册（隐私授权已拒绝，等待用户同意后启用）');
    
    // 步骤10: 初始化定位权限服务
    Get.put(LocationPermissionService(), permanent: true);
    DebugUtil.success('定位权限服务初始化完成');
    
    // 步骤11: 初始化应用生命周期服务
    Get.put(AppLifecycleService(), permanent: true);
    DebugUtil.success('应用生命周期服务初始化完成');
    
    // 步骤11.1: 初始化智能后台定位提醒服务
    Get.put(SmartBackgroundLocationReminder(), permanent: true);
    DebugUtil.success('智能后台定位提醒服务初始化完成');
    
    // 步骤11.2: 初始化前台定位服务
    Get.put(ForegroundLocationService(), permanent: true);
    DebugUtil.success('前台定位服务初始化完成');
    
    // 步骤12: 初始化敏感数据上报服务（但不立即上报）
    Get.put(SensitiveDataService(), permanent: true);
    DebugUtil.success('敏感数据上报服务初始化完成');
    
    // 步骤13: 初始化视图模式服务
    Get.put(ViewModeService(), permanent: true);
    DebugUtil.success('视图模式服务初始化完成');
    
    // 步骤14: 初始化首次启动服务
    Get.put(FirstLaunchService(), permanent: true);
    DebugUtil.success('首次启动服务初始化完成');
    
    // 步骤15: 注册OpenInstall服务（但不立即初始化，等待隐私授权）
    // 🔒 隐私合规：OpenInstall的初始化移到隐私政策同意后
    DebugUtil.info('OpenInstall服务已注册（等待隐私授权后初始化）');
    
    // ========== 第三阶段：隐私合规管理器初始化 ==========
    
    // 步骤16: 初始化隐私合规管理器
    Get.put(PrivacyComplianceManager(), permanent: true);
    DebugUtil.success('隐私合规管理器初始化完成');

    DebugUtil.success('应用基础初始化完成，等待用户隐私政策确认后启用完整功能');
  } catch (e) {
    DebugUtil.error('应用初始化失败: $e');
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
    
    return GetMaterialApp(
      title: 'Kissu',
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
      initialRoute: KissuRoutePath.splash, // 启动页
      unknownRoute: GetPage(
        name: '/notfound',
        page: () => Scaffold(body: Center(child: Text('页面不存在'))),
      ),
    );
  }

}

