import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/network/public/auth_service.dart';
import 'package:kissu_app/network/public/service_locator.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/services/home_scroll_service.dart';
import 'package:kissu_app/services/first_launch_service.dart';
import 'package:kissu_app/services/privacy_compliance_manager.dart';
import 'package:kissu_app/utils/debug_util.dart';
import 'package:kissu_app/pages/login/agree_richtext_page.dart';
import 'package:kissu_app/widgets/dialogs/base_dialog.dart';

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
      // 🔑 关键改进：首先检查是否需要显示隐私政策弹窗
      final firstLaunchService = FirstLaunchService.instance;
      final shouldShowPrivacyDialog = await firstLaunchService.shouldShowFirstAgreement();
      
      if (shouldShowPrivacyDialog) {
        DebugUtil.info('首次启动，在启动页显示隐私政策弹窗');
        await _showPrivacyDialog();
        return;
      }
      
      // 检查隐私政策合规状态
      final privacyManager = Get.find<PrivacyComplianceManager>();
      if (!privacyManager.isPrivacyAgreed) {
        DebugUtil.warning('隐私政策未同意，在启动页显示隐私政策弹窗');
        await _showPrivacyDialog();
        return;
      }
      
      // 隐私政策已同意，继续正常的登录状态检查
      await _continueLoginStatusCheck();
      
    } catch (e) {
      DebugUtil.error('检查登录状态失败: $e，跳转到登录页面');
      Get.offAllNamed(KissuRoutePath.login);
    }
  }

  /// 继续登录状态检查（隐私政策同意后）
  Future<void> _continueLoginStatusCheck() async {
    try {
      final authService = getIt<AuthService>();
      await authService.loadCurrentUser();
      
      DebugUtil.info('启动页检查登录状态: ${authService.isLoggedIn}');
      DebugUtil.info('用户token: ${authService.userToken != null ? "存在" : "不存在"}');
      
      if (authService.isLoggedIn && authService.userToken != null) {
        // 用户已登录，检查是否需要完善信息
        if (UserManager.needsPerfectInfo) {
          DebugUtil.info('用户已登录但需要完善信息，跳转到信息完善页面');
          Get.offAllNamed(KissuRoutePath.infoSetting);
        } else {
          DebugUtil.success('用户已登录且信息完整，直接跳转到首页');
          // 在跳转到首页前预设滚动位置
          _presetHomeScrollPosition();
          Get.offAllNamed(KissuRoutePath.home);
        }
      } else {
        DebugUtil.info('用户未登录，跳转到登录页面');
        Get.offAllNamed(KissuRoutePath.login);
      }
    } catch (e) {
      DebugUtil.error('继续登录状态检查失败: $e，跳转到登录页面');
      Get.offAllNamed(KissuRoutePath.login);
    }
  }

  /// 🔑 关键方法：在启动页显示隐私政策弹窗（使用原有的精美设计）
  Future<void> _showPrivacyDialog() async {
    // 标记已显示弹窗
    FirstLaunchService.instance.markFirstAgreementShown();
    
    // 完全按照您原有的showDialogWithCloseButtonWithFirst方法实现
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false, // 修改为false，不允许点击外部关闭
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: const Color(0xB3000000),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.only(top: 20, left: 10, right: 10),
            height: 400.0, // 使用您原来的高度
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage('assets/kissu_privacy_bg.webp'),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    top: 40
                  ),
                  child: const AgreementRichText(
                    textAlign: TextAlign.left,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    DialogButton(
                      text: '暂不同意',
                      width: 100,
                      backgroundImage: 'assets/kissu_dialop_common_cancel_bg.webp',
                      onTap: () {
                        Navigator.of(context).pop(false); // 返回 false 表示取消
                      },
                    ),
                    DialogButton(
                      text: '同意并继续',
                      width: 100,
                      backgroundImage: 'assets/kissu_dialop_common_sure_bg.webp',
                      onTap: () {
                        Navigator.of(context).pop(true); // 返回 true 表示同意
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // 出现动画：由小到大，带回弹效果
        final scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut, // 回弹效果
          ),
        );

        // 消失动画：由大到小
        final scaleOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInBack),
        );

        // 透明度动画
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: animation.status == AnimationStatus.reverse
                ? scaleOutAnimation
                : scaleAnimation,
            child: child,
          ),
        );
      },
    );

    if (result == true) {
      // 用户同意，初始化SDK并继续
      await _initializeSDKsAfterAgreement();
      _navigateToNextPage();
    } else {
      // 用户拒绝，退出应用
      _exitApp();
    }
  }


  /// 用户同意后初始化SDK
  Future<void> _initializeSDKsAfterAgreement() async {
    DebugUtil.info('用户在启动页同意隐私政策');
    FirstLaunchService.instance.markFirstAgreementAgreed();
    
    // 🔑 关键：启用隐私相关功能
    try {
      final privacyManager = Get.find<PrivacyComplianceManager>();
      await privacyManager.agreeToPrivacyPolicy();
      DebugUtil.success('✅ 隐私政策同意完成，所有功能已启用');
    } catch (e) {
      DebugUtil.error('❌ 启用隐私功能失败: $e');
    }
  }

  /// 导航到下一个页面
  Future<void> _navigateToNextPage() async {
    // 继续正常的登录状态检查
    await _continueLoginStatusCheck();
  }

  /// 用户拒绝隐私政策，退出应用
  void _exitApp() {
    DebugUtil.warning('用户在启动页不同意隐私政策，退出应用');
    FirstLaunchService.instance.exitApp();
  }

  /// 预设首页滚动位置
  void _presetHomeScrollPosition() {
    try {
      final homeScrollService = getIt<HomeScrollService>();
      homeScrollService.calculateAndSetPresetPosition();
      DebugUtil.success('已预设首页背景滚动位置');
    } catch (e) {
      DebugUtil.error('预设首页滚动位置失败: $e');
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
    final titleWidth = 127.0 * scale;
    final titleHeight = 258.0 * scale;
    final iconWidth = 80.0 * scale;
    final iconHeight = 80.0 * scale;
    // 计算间距
    final spacing = 110.0 * scale;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/mipmap-xxhdpi/flash.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Transform.translate(
              offset: Offset(0, -100 ),
              child: Center(
              child:Image.asset(
                    'assets/mipmap-xxhdpi/flash_title.webp',
                    width: titleWidth,
                    height: titleHeight,
                    fit: BoxFit.contain,
                  ),
            ),
            ),
            Positioned(
              bottom: 60*scale,
              left: 0,
              right: 0,
              child: Image.asset(
                      'assets/mipmap-xxhdpi/flash_icon.webp',
                      width: iconWidth,
                      height: iconHeight,
                      fit: BoxFit.contain,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
