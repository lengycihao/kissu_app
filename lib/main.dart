import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kissu_app/network/utils/dir_util.dart';
import 'package:kissu_app/utils/memory_manager.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kissu_app/routers/kissu_route.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:oktoast/oktoast.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 确保Flutter绑定初始化
  
  // � 优化：只做最基础的同步初始化，让启动页快速显示
  // 屏幕方向锁定（同步操作，不耗时）
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // 初始化目录工具配置（同步操作）
  setInitDir(initTempDir: true);
  
  // 初始化内存管理器（同步操作）
  MemoryManager.initialize();
  
  // 设置状态栏样式（同步操作）
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark,
    ),
  );
  
  // 🚀 关键优化：所有耗时初始化都移到启动页执行，这里只做最基础的设置
  // 这样可以让启动页秒开，用户体验更好

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
      // 全局 builder，用于在所有页面上叠加截图反馈按钮
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            // 全局截图反馈浮动按钮
          ],
        );
      },
    );
  }

}

