import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kissu_app/network/utils/dir_util.dart';
import 'package:kissu_app/utils/memory_manager.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kissu_app/routers/kissu_route.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:oktoast/oktoast.dart';
import 'package:openinstall_flutter_plugin/openinstall_flutter_plugin.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/network/tools/logging/log_config.dart';
import 'package:kissu_app/network/tools/logging/log_level.dart';

void main() async {
  // 🔥 全局异常捕获：捕获所有未处理的异常并记录到日志
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized(); // 确保Flutter绑定初始化
    
    // 📝 初始化日志系统（尽早初始化，确保能捕获启动阶段的日志）
    await _initializeLogger();
    
    // 🔥 捕获 Flutter 框架异常
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      logFatal(
        'Flutter框架异常: ${details.exceptionAsString()}',
        tag: 'FlutterError',
        error: details.exception,
        stackTrace: details.stack,
      );
    };
    
    // 🔥 捕获 PlatformDispatcher 异常（Flutter 3.x）
    PlatformDispatcher.instance.onError = (error, stack) {
      logFatal(
        'Platform异常: $error',
        tag: 'PlatformError',
        error: error,
        stackTrace: stack,
      );
      return true;
    };
    
    // 🔒 隐私合规：在应用启动时立即禁用OpenInstall剪贴板读取
    // 必须在任何其他初始化之前执行，确保插件不会读取剪贴板
    if (Platform.isAndroid) {
      try {
        final openinstallPlugin = OpeninstallFlutterPlugin();
        openinstallPlugin.clipBoardEnabled(false);
        logInfo('OpenInstall剪贴板读取已禁用（隐私合规）', tag: 'App');
      } catch (e) {
        logWarning('禁用OpenInstall剪贴板失败: $e', tag: 'App');
      }
    }
    
    // 🚀 优化：只做最基础的同步初始化，让启动页快速显示
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
    
    logInfo('应用启动初始化完成', tag: 'App');
    
    // 🚀 关键优化：所有耗时初始化都移到启动页执行，这里只做最基础的设置
    // 这样可以让启动页秒开，用户体验更好

    runApp(OKToast(
      child: const MyApp(),
    ));
  }, (error, stackTrace) {
    // 🔥 捕获 Zone 内未处理的异步异常
    logFatal(
      '未捕获的异步异常: $error',
      tag: 'UncaughtError',
      error: error,
      stackTrace: stackTrace,
    );
  });
}

/// 初始化日志系统
Future<void> _initializeLogger() async {
  try {
    // 配置日志系统
    final logConfig = LogConfig(
      enableConsoleLog: !kReleaseMode, // Release模式关闭控制台日志
      enableFileLog: true, // 始终启用文件日志
      enableUpload: false, // 手动上传，不自动上传
      minLevel: kReleaseMode ? LogLevel.info : LogLevel.debug, // Release模式只记录info及以上
      minFileLevel: LogLevel.info, // 文件只记录info及以上
      logDir: 'logs',
      logFileName: 'app.log',
      maxFileSize: 2 * 1024 * 1024, // 单文件最大2MB
      maxFileCount: 7, // 最多保留7个文件
      logRetentionDays: const Duration(days: 7), // 保留7天
    );
    
    await logger.initialize(logConfig);
    logInfo('日志系统初始化完成', tag: 'Logger');
  } catch (e) {
    debugPrint('⚠️ 日志系统初始化失败: $e');
  }
}

/// 处理未知路由的Widget
/// 当路由不存在时，自动跳转到启动页
class _UnknownRouteHandler extends StatefulWidget {
  @override
  State<_UnknownRouteHandler> createState() => _UnknownRouteHandlerState();
}

class _UnknownRouteHandlerState extends State<_UnknownRouteHandler> {
  bool _hasRedirected = false;

  @override
  void initState() {
    super.initState();
    // 在下一帧跳转，避免在build过程中跳转
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasRedirected && mounted) {
        _hasRedirected = true;
        // 延迟跳转，确保路由系统已完全初始化
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            try {
              Get.offAllNamed(KissuRoutePath.splash);
            } catch (e) {
              // 如果跳转失败，忽略错误（应用可能还在启动中）
            }
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('正在加载...'),
          ],
        ),
      ),
    );
  }
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
      // 🔥 修改unknownRoute处理：当路由不存在时，自动跳转到启动页
      // 这样可以避免OpenInstall等deep link跳转到不存在路由时显示错误页面
      unknownRoute: GetPage(
        name: '/notfound',
        page: () {
          // 使用StatefulWidget来避免在build过程中跳转
          return _UnknownRouteHandler();
        },
      ),
       
      builder: (context, child) {
        // 🎯 禁用系统字体缩放，防止手机字体调大后布局错乱
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: Stack(
            children: [
              child ?? const SizedBox.shrink(),
              
            ],
          ),
        );
      },
    );
  }

}

