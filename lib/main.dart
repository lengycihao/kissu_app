import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kissu_app/network/example/http_manager_example.dart';
import 'package:kissu_app/network/public/service_locator.dart';
import 'package:kissu_app/network/public/auth_service.dart';
import 'package:kissu_app/network/interceptor/api_response_interceptor.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kissu_app/routers/kissu_route.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 确保Flutter绑定初始化
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

    print('应用初始化完成');
  } catch (e) {
    print('应用初始化失败: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
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
          print('用户已登录，进入首页: ${authService.userNickname}');
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
