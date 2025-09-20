import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/network/public/auth_service.dart';
import 'package:kissu_app/network/public/service_locator.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/services/home_scroll_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatusAndNavigate();
  }

  Future<void> _checkLoginStatusAndNavigate() async {
    // 延迟2秒显示启动页面
    await Future.delayed(const Duration(seconds: 2));
    
    try {
      // 获取AuthService实例
      final authService = getIt<AuthService>();
      
      // 确保用户数据已加载
      await authService.loadCurrentUser();
      
      print('启动页检查登录状态: ${authService.isLoggedIn}');
      print('用户token: ${authService.userToken != null ? "存在" : "不存在"}');
      
      if (authService.isLoggedIn && authService.userToken != null) {
        // 用户已登录，检查是否需要完善信息
        if (UserManager.needsPerfectInfo) {
          print('用户已登录但需要完善信息，跳转到信息完善页面');
          Get.offAllNamed(KissuRoutePath.infoSetting);
        } else {
          print('用户已登录且信息完整，直接跳转到首页');
          // 在跳转到首页前预设滚动位置
          _presetHomeScrollPosition();
          Get.offAllNamed(KissuRoutePath.home);
        }
      } else {
        print('用户未登录，跳转到登录页面');
        Get.offAllNamed(KissuRoutePath.login);
      }
    } catch (e) {
      print('检查登录状态失败: $e，跳转到登录页面');
      Get.offAllNamed(KissuRoutePath.login);
    }
  }

  /// 预设首页滚动位置
  void _presetHomeScrollPosition() {
    try {
      final homeScrollService = getIt<HomeScrollService>();
      homeScrollService.calculateAndSetPresetPosition();
      print('✅ 已预设首页背景滚动位置');
    } catch (e) {
      print('❌ 预设首页滚动位置失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 获取屏幕尺寸
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // 基于375*812的设计稿计算缩放比例
    const designWidth = 375.0;
    const designHeight = 812.0;
    final scaleX = screenWidth / designWidth;
    final scaleY = screenHeight / designHeight;
    
    // 使用较小的缩放比例保持比例
    final scale = scaleX < scaleY ? scaleX : scaleY;
    
    // 计算图片尺寸（保持原始比例）
    final titleWidth = 107.0 * scale;
    final titleHeight = 221.0 * scale;
    final bpWidth = 316.0 * scale;
    final bpHeight = 265.0 * scale;
    
    // 计算间距
    final spacing = 110.0 * scale;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/mipmap-xxhdpi/flash.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // flash_title 图片
              Image.asset(
                'assets/flash_title.png',
                width: titleWidth,
                height: titleHeight,
                fit: BoxFit.contain,
              ),
              SizedBox(height: spacing),
              // flash_bp 图片
              Image.asset(
                'assets/flash_bp.png',
                width: bpWidth,
                height: bpHeight,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
