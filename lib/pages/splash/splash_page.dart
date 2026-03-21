import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/network/public/auth_service.dart';
import 'package:kissu_app/network/public/service_locator.dart';
import 'package:kissu_app/services/home_scroll_service.dart';
import 'package:kissu_app/services/first_launch_service.dart';
import 'package:kissu_app/services/privacy_compliance_manager.dart';
// 🔥 已废弃：极光推送（推送现在走腾讯IM）
// import 'package:kissu_app/services/jpush_service.dart';
import 'package:kissu_app/services/app_activation_service.dart';
import 'package:kissu_app/utils/debug_util.dart';
import 'package:kissu_app/pages/login/agree_richtext_page.dart';
import 'package:kissu_app/services/app_initializer.dart';
import 'package:kissu_app/pages/home/home_page.dart';
import 'package:kissu_app/pages/home/home_binding.dart';
import 'package:kissu_app/services/analytics/analytics_manager.dart';
import 'package:kissu_app/services/analytics/analytics_events.dart';
import 'package:kissu_app/services/analytics/analytics_helper.dart';
import 'package:kissu_app/services/guide_service.dart';
import 'package:kissu_app/pages/guide/guide_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with WidgetsBindingObserver {
  static const MethodChannel _appIconChannel = MethodChannel(
    'app_icon_channel',
  );

  bool _imagesLoaded = false;
  String _currentIconId = 'default';
  bool _isShowingPrivacyDialog = false; // 🔥 标记是否正在显示隐私协议弹窗
  int? _privacyDialogEnterTime; // 隐私弹窗进入时间（用于埋点）

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 🔥 添加生命周期监听
    _loadCurrentIcon();
    _preloadImagesAndNavigate();

    // 🔥 修复：移除固定超时，改为在隐私协议弹窗关闭后再启动超时
    // 避免第一次下载时，隐私协议弹窗还没显示完就被强制跳转
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 🔥 移除生命周期监听
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 🔥 修复：应用生命周期变化时，如果正在显示隐私协议弹窗，不处理
    if (_isShowingPrivacyDialog) {
      DebugUtil.warning('⚠️ 应用生命周期变化: $state，但隐私协议弹窗正在显示，忽略');
      return;
    }
    super.didChangeAppLifecycleState(state);
  }

  /// 从原生获取当前正在使用的 App 图标 ID，用于匹配启动页 logo
  Future<void> _loadCurrentIcon() async {
    try {
      final String? iconId = await _appIconChannel.invokeMethod<String>(
        'getCurrentIcon',
      );
      if (!mounted) return;
      if (iconId != null && iconId.isNotEmpty) {
        setState(() {
          _currentIconId = iconId;
        });
      }
    } catch (e) {
      DebugUtil.error('获取当前 App 图标失败: $e');
    }
  }

  /// 确保应用已完成初始化，带超时与异常保护
  Future<void> _ensureAppInitialized({
    required Duration timeout,
    required String contextTag,
  }) async {
    if (AppInitializer.isInitialized) return;

    DebugUtil.warning('应用尚未初始化完成（$contextTag），等待初始化...');
    try {
      await AppInitializer.initialize().timeout(
        timeout,
        onTimeout: () {
          DebugUtil.error('⚠️ 应用初始化超时（${timeout.inSeconds}秒，$contextTag），强制继续');
        },
      );
    } catch (e) {
      DebugUtil.error('⚠️ 应用初始化失败（$contextTag）: $e，继续启动流程');
    }
  }

  /// 预加载所有启动页图片，避免闪烁
  Future<void> _preloadImagesAndNavigate() async {
    // 🚀 优化：立即显示启动页，不等待图片加载
    if (mounted) {
      setState(() {
        _imagesLoaded = true;
      });
    }

    try {
      // 🚀 关键优化：只预加载关键图片（背景、标题、logo），其他后台加载
      // 🔥 优化：减少图片预加载时间到0.5秒，加快启动速度
      Future<void> criticalImages;
      try {
        criticalImages =
            Future.wait([
              precacheImage(
                const AssetImage('assets/mipmap-xxhdpi/flash.webp'),
                context,
              ),
              precacheImage(
                const AssetImage('assets/mipmap-xxhdpi/flash_title.webp'),
                context,
              ),
              precacheImage(AssetImage(_getSplashLogoAsset()), context),
            ]).timeout(
              const Duration(milliseconds: 500), // 🔥 减少到0.5秒
            );
      } catch (e) {
        DebugUtil.warning('关键图片预加载超时，继续启动: $e');
        criticalImages = Future.value();
      }

      // 🚀 应用初始化在后台执行，不阻塞启动页显示
      // 🔥 修复：如果已经初始化完成，不再重复初始化
      if (!AppInitializer.isInitialized) {
        final initFuture = AppInitializer.initialize()
            .timeout(
              const Duration(seconds: 8),
              onTimeout: () {
                DebugUtil.warning('⚠️ 应用初始化超时（8秒），继续启动流程');
              },
            )
            .catchError((e) {
              DebugUtil.error('应用初始化失败: $e，继续启动');
            });

        // 后台继续初始化（不阻塞）
        initFuture.then((_) {
          // DebugUtil.success('应用初始化完成');
        });
      } else {
        // DebugUtil.info('应用已经初始化完成，跳过重复初始化');
      }

      // 等待关键图片加载完成（最多0.5秒）
      try {
        await criticalImages;
      } catch (e) {
        DebugUtil.warning('关键图片加载失败: $e，继续启动');
      }

      // 🔥 关键优化：继续导航逻辑，不等待完整初始化完成
      // 🔥 修复：不在这里设置超时，因为可能显示隐私协议弹窗
      // 超时保护会在隐私协议弹窗关闭后或直接进入登录检查时启动
      await _checkLoginStatusAndNavigate();

      // 后台预加载其他图标（不阻塞）
      Future.wait([
            precacheImage(
              const AssetImage('assets/mipmap-xxhdpi/flash_icon.webp'),
              context,
            ),
            precacheImage(
              const AssetImage('assets/mipmap-xxhdpi/flash_icon2.webp'),
              context,
            ),
            precacheImage(
              const AssetImage('assets/mipmap-xxhdpi/flash_icon3.webp'),
              context,
            ),
            precacheImage(
              const AssetImage('assets/mipmap-xxhdpi/flash_icon4.webp'),
              context,
            ),
            precacheImage(
              const AssetImage('assets/mipmap-xxhdpi/flash_icon5.webp'),
              context,
            ),
            precacheImage(
              const AssetImage('assets/mipmap-xxhdpi/flash_icon6.webp'),
              context,
            ),
            precacheImage(
              const AssetImage('assets/mipmap-xxhdpi/flash_icon7.webp'),
              context,
            ),
            precacheImage(
              const AssetImage('assets/mipmap-xxhdpi/flash_icon8.webp'),
              context,
            ),
            precacheImage(
              const AssetImage('assets/mipmap-xxhdpi/flash_icon9.webp'),
              context,
            ),
            precacheImage(
              const AssetImage('assets/mipmap-xxhdpi/flash_icon10.webp'),
              context,
            ),
          ])
          .then((_) {
            // 预加载完成
          })
          .catchError((e) {
            DebugUtil.warning('其他图标预加载失败: $e');
          });
    } catch (e) {
      DebugUtil.error('预加载启动页图片失败: $e');
      // ✅ 即使预加载失败，也继续执行，不会卡住
      await _checkLoginStatusAndNavigate();
    }
  }

  Future<void> _checkLoginStatusAndNavigate() async {
    // 🚀 优化：移除固定延迟，立即检查登录状态
    try {
      // 🚀 确保应用已初始化（关键！必须在访问任何服务之前）
      // 🔥 优化：减少等待时间到1秒，加快启动速度
      await _ensureAppInitialized(
        timeout: const Duration(seconds: 1), // 🔥 从3秒减少到1秒
        contextTag: '首次初始化',
      );

      // 🔑 现在可以安全访问服务了（带异常保护和超时保护）
      try {
        // 🔥 修复：统一使用FirstLaunchService检查，避免双重检查逻辑冲突
        bool shouldShowPrivacyDialog = true; // 🔥 修复：默认显示弹窗，确保首次下载必弹
        try {
          final firstLaunchService = FirstLaunchService.instance;
          // 🔥 修复：增加超时时间到8秒，让FirstLaunchService内部有足够时间读取（含3次重试）
          // FirstLaunchService内部已经有缓存和智能判断逻辑
          shouldShowPrivacyDialog = await firstLaunchService
              .shouldShowFirstAgreement()
              .timeout(
                const Duration(seconds: 8),
                onTimeout: () {
                  DebugUtil.warning('⚠️ 检查首次协议状态超时（8秒），默认显示弹窗（首次下载合规要求）');
                  return true; // 🔥 修复：超时时显示弹窗，确保首次下载必弹（合规要求）
                },
              );
        } catch (e) {
          DebugUtil.error('⚠️ 检查首次协议状态失败: $e，默认显示弹窗（首次下载合规要求）');
          shouldShowPrivacyDialog = true; // 🔥 修复：出错时显示弹窗，确保首次下载必弹
        }

        if (shouldShowPrivacyDialog) {
          // DebugUtil.info('首次启动，在启动页显示隐私政策弹窗');
          await _showPrivacyDialog();
          // 🔥 隐私协议同意后，检查是否需要显示引导页
          final navigatedToGuide = await _checkAndShowGuidePage();
          if (navigatedToGuide) {
            // 已导航到引导页，停止后续逻辑
            return;
          }
          return;
        }

        // 🔥 隐私合规修复：用户已同意隐私协议，需要初始化SDK
        // 这确保SDK只在用户明确同意后才初始化，符合应用市场要求
        try {
          final privacyManager = Get.find<PrivacyComplianceManager>();
          if (privacyManager.isPrivacyAgreed &&
              !privacyManager.isSdkInitialized) {
            // DebugUtil.info('用户已同意隐私政策，开始初始化SDK...');
            await privacyManager
                .initializeSdks()
                .timeout(
                  const Duration(seconds: 5),
                  onTimeout: () {
                    DebugUtil.warning('⚠️ SDK初始化超时（5秒），继续启动流程');
                  },
                )
                .catchError((e) {
                  DebugUtil.error('SDK初始化失败: $e，继续启动流程');
                });
          }
        } catch (e) {
          DebugUtil.error('⚠️ 初始化SDK失败: $e，继续启动流程');
        }
      } catch (e) {
        DebugUtil.error('⚠️ 获取服务失败: $e，跳过隐私检查直接进入登录检查');
        // 如果服务获取失败，直接进入登录状态检查
      }

      // 隐私政策已同意，检查是否需要显示引导页
      final navigatedToGuide = await _checkAndShowGuidePage();
      if (navigatedToGuide) {
        // 已导航到引导页，停止后续逻辑（引导页会自己处理后续导航）
        return;
      }
      
      // 继续正常的登录状态检查
      // 🔥 修复：如果隐私政策已同意，启动超时保护（3-4秒内必须跳转）
      _startNavigationTimeout();
      await _continueLoginStatusCheck();
    } catch (e) {
      DebugUtil.error('检查登录状态失败: $e，跳转到登录页面');
      // 🔥 修复：确保即使出错也能跳转，避免卡在启动页
      if (mounted) {
        Get.offAllNamed(KissuRoutePath.login);
      }
    }
  }

  /// 检查并显示引导页（如果需要）
  /// 返回 true 表示已导航到引导页，调用者应停止后续导航逻辑
  Future<bool> _checkAndShowGuidePage() async {
    try {
      final shouldShowGuide = await GuideService.instance.shouldShowGuide();
      if (shouldShowGuide && mounted) {
        DebugUtil.info('首次启动，导航到引导页');
        // 标记引导页已显示（在导航前标记，避免重复显示）
        await GuideService.instance.markGuideShown();
        // 直接替换导航到引导页，不是弹出
        Get.off(
          () => const GuidePage(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 300),
        );
        // 返回 true 表示已导航到引导页，调用者应停止后续导航逻辑
        return true;
      }
    } catch (e) {
      DebugUtil.error('检查引导页状态失败: $e，继续启动流程');
    }
    return false;
  }

  /// 继续登录状态检查（隐私政策同意后）
  Future<void> _continueLoginStatusCheck() async {
    try {
      // 🔥 修复：如果已经初始化完成，不再重复等待
      if (!AppInitializer.isInitialized) {
        // 🚀 再次确保应用已初始化（带超时保护）
        // 🔥 优化：减少等待时间到0.5秒，加快启动速度
        await _ensureAppInitialized(
          timeout: const Duration(milliseconds: 500), // 🔥 从2秒减少到0.5秒
          contextTag: '二次初始化',
        );
      }

      // 🛡️ 安全获取AuthService（带异常保护和超时保护）
      AuthService authService;
      try {
        // 🔥 修复：添加超时保护，避免服务获取阻塞
        // 🔥 优化：减少超时时间到0.5秒
        authService = await Future.value(getIt<AuthService>()).timeout(
          const Duration(milliseconds: 500), // 🔥 从1秒减少到0.5秒
          onTimeout: () {
            DebugUtil.error('⚠️ 获取AuthService超时');
            throw TimeoutException(
              '获取AuthService超时',
              const Duration(milliseconds: 500),
            );
          },
        );
      } catch (e) {
        DebugUtil.error('⚠️ AuthService未注册: $e，跳转到登录页');
        if (mounted) {
          Get.offAllNamed(KissuRoutePath.login);
        }
        return;
      }

      // DebugUtil.info('启动页检查登录状态: ${authService.isLoggedIn}');
      // DebugUtil.info(
      //   '用户token: ${authService.userToken != null ? "存在" : "不存在"}',
      // );

      if (authService.isLoggedIn && authService.userToken != null) {
        // 用户已登录，检查是否需要完善信息
        // 🚀 直接使用authService，避免通过UserManager访问未初始化的服务
        if (authService.needsPerfectInfo) {
          // DebugUtil.info('用户已登录但需要完善信息，跳转到信息完善页面');
          if (mounted) {
            Get.offAllNamed(KissuRoutePath.infoSetting);
          }
        } else {
          // DebugUtil.success('用户已登录且信息完整，直接跳转到首页');
          // 在跳转到首页前预设滚动位置（不阻塞跳转）
          try {
            _presetHomeScrollPosition();
          } catch (e) {
            DebugUtil.warning('预设首页滚动位置失败: $e，继续跳转');
          }
          // 使用自定义淡入过渡动画
          if (mounted) {
            Get.off(
              () => KissuHomePage(),
              binding: HomeBinding(),
              transition: Transition.fadeIn,
              duration: const Duration(milliseconds: 500),
              routeName: KissuRoutePath.home,
              preventDuplicates: false,
            );
          }
        }
      } else {
        // DebugUtil.info('用户未登录，跳转到登录页面');
        if (mounted) {
          Get.offAllNamed(KissuRoutePath.login);
        }
      }
    } catch (e) {
      DebugUtil.error('继续登录状态检查失败: $e，跳转到登录页面');
      // 🔥 修复：确保即使出错也能跳转，避免卡在启动页
      if (mounted) {
        Get.offAllNamed(KissuRoutePath.login);
      }
    }
  }

  /// 🔑 关键方法：在启动页显示隐私政策弹窗（使用原有的精美设计）
  Future<void> _showPrivacyDialog() async {
    // 🔥 修复：防止重复显示
    if (_isShowingPrivacyDialog) {
      DebugUtil.warning('⚠️ 隐私协议弹窗已在显示中，跳过重复显示');
      return;
    }

    _isShowingPrivacyDialog = true; // 🔥 标记正在显示

    // 记录弹窗进入时间（埋点，十位时间戳）
    _privacyDialogEnterTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // 🔥 修复：为对话框显示添加超时保护，防止无限等待
    bool? result;
    try {
      // 完全按照您原有的showDialogWithCloseButtonWithFirst方法实现
      result =
          await showGeneralDialog<bool>(
            context: context,
            barrierDismissible: false, // 修改为false，不允许点击外部关闭
            barrierLabel: MaterialLocalizations.of(
              context,
            ).modalBarrierDismissLabel,
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
                  height: 300.0, // 使用您原来的高度
                  decoration: BoxDecoration(
                    image: const DecorationImage(
                      image: AssetImage('assets/images/kissu_privacy_bg.webp'),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 0),
                      Text(
                        '用户协议及隐私政策',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff333333),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 15,
                          right: 15,
                          bottom: 15,
                          top: 20,
                        ),
                        child: const AgreementRichText(
                          textAlign: TextAlign.left,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            child: Container(
                              width: double.infinity,
                              height: 36,
                              margin: EdgeInsets.only(
                                left: 15,
                                right: 15,
                                bottom: 15,
                                top: 15,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Color(0xFFFF9AD9),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                '同意',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xffffffff),
                                ),
                              ),
                            ),
                            onTap: () {
                              Navigator.of(context).pop(true); // 返回 true 表示同意
                            },
                          ),
                          GestureDetector(
                            child: Container(
                              child: Text(
                                '拒绝',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xff999999),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            onTap: () {
                              Navigator.of(context).pop(false); // 返回 true 表示同意
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
              final scaleAnimation = Tween<double>(begin: 0.0, end: 1.0)
                  .animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.elasticOut, // 回弹效果
                    ),
                  );

              // 消失动画：由大到小
              final scaleOutAnimation = Tween<double>(begin: 1.0, end: 0.0)
                  .animate(
                    CurvedAnimation(
                      parent: secondaryAnimation,
                      curve: Curves.easeInBack,
                    ),
                  );

              // 透明度动画
              final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              );

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
          ).timeout(
            const Duration(seconds: 30), // 🔥 修复：添加30秒超时，防止对话框无限等待
            onTimeout: () {
              DebugUtil.error('⚠️ 隐私政策对话框显示超时（30秒），默认拒绝并退出应用');
              return false; // 超时则默认拒绝
            },
          );
    } catch (e) {
      DebugUtil.error('⚠️ 显示隐私政策对话框失败: $e，退出应用');
      result = false; // 出错则默认拒绝
    }

    // 🔥 修复：重置标记
    _isShowingPrivacyDialog = false;

    // 🔥 保存埋点所需的时间数据（用于SDK初始化后上报）
    final int? savedEnterTime = _privacyDialogEnterTime;
    final int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final int? duration = savedEnterTime != null ? currentTime - savedEnterTime : null;
    _privacyDialogEnterTime = null;

    // 🔥 修复：只有当用户明确拒绝（false）时才退出，null表示Dialog被意外关闭，重新显示
    if (result == true) {
      // 用户同意，初始化SDK并继续
      try {
        await _initializeSDKsAfterAgreement();
        
        // 🔥 隐私合规优化：确保虚拟用户ID已获取后再上报埋点
        // 如果SDK初始化时OAID获取失败或超时，这里再尝试一次
        await AnalyticsManager.instance.initMockUserIdAfterPrivacyAgreed();
        
        // 在SDK初始化完成后再上报埋点（此时虚拟用户ID已获取）
        if (savedEnterTime != null && duration != null) {
          // 记录页面浏览事件
          AnalyticsManager.instance.trackPageView(
            pageId: UserAgreementEvents.pageId,
            eventId: UserAgreementEvents.page,
            enterTime: savedEnterTime,
            duration: duration,
          );
          // 记录操作事件（同意）
          await AnalyticsHelper.trackAgreementOperation(agree: true);
        }
        
        _navigateToNextPage();
      } catch (e) {
        DebugUtil.error('⚠️ 初始化SDK失败: $e，继续导航');
        // 即使初始化失败，也尝试获取OAID并上报埋点
        try {
          await AnalyticsManager.instance.initMockUserIdAfterPrivacyAgreed();
        } catch (_) {}
        if (savedEnterTime != null && duration != null) {
          AnalyticsManager.instance.trackPageView(
            pageId: UserAgreementEvents.pageId,
            eventId: UserAgreementEvents.page,
            enterTime: savedEnterTime,
            duration: duration,
          );
          await AnalyticsHelper.trackAgreementOperation(agree: true);
        }
        _navigateToNextPage();
      }
    } else if (result == false) {
      // 用户明确拒绝，需要立即上报埋点（因为会退出应用，此时没有虚拟用户ID）
      if (savedEnterTime != null && duration != null) {
        AnalyticsManager.instance.trackPageView(
          pageId: UserAgreementEvents.pageId,
          eventId: UserAgreementEvents.page,
          enterTime: savedEnterTime,
          duration: duration,
        );
        await AnalyticsHelper.trackAgreementOperation(agree: false);
      }
      _exitApp();
    } else {
      // result == null，Dialog被意外关闭（可能是应用生命周期变化或系统原因），重新显示Dialog
      DebugUtil.warning('⚠️ 隐私政策Dialog被意外关闭（result=null），重新显示');
      // 延迟一下再重新显示，避免立即重复，并检查mounted状态
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && Get.currentRoute == KissuRoutePath.splash) {
          DebugUtil.info('重新显示隐私政策Dialog');
          _showPrivacyDialog();
        } else {
          DebugUtil.warning('页面已销毁或已跳转，不再重新显示Dialog');
        }
      });
    }
  }

  /// 🔥 修复：在隐私协议弹窗关闭后，启动超时保护（3-4秒内必须跳转）
  void _startNavigationTimeout() {
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        // 🔥 修复：再次检查是否正在显示Dialog，如果是则不强制跳转
        if (_isShowingPrivacyDialog || Get.isDialogOpen == true) {
          DebugUtil.warning('⚠️ 启动页强制超时（3.5秒），但隐私协议弹窗正在显示，不强制跳转');
          return;
        }
        DebugUtil.warning('⚠️ 启动页强制超时（3.5秒），强制跳转到登录页');
        try {
          // 检查是否已经跳转
          if (Get.currentRoute == KissuRoutePath.splash) {
            Get.offAllNamed(KissuRoutePath.login);
          }
        } catch (e) {
          DebugUtil.error('强制跳转失败: $e');
        }
      }
    });
  }

  /// 用户同意后初始化SDK
  Future<void> _initializeSDKsAfterAgreement() async {
    DebugUtil.info('用户在启动页同意隐私政策');

    // 🔥 修复：标记同意状态（带超时保护）
    try {
      await FirstLaunchService.instance.markFirstAgreementAgreed().timeout(
        const Duration(seconds: 1),
        onTimeout: () {
          DebugUtil.warning('⚠️ 标记首次协议同意状态超时，继续初始化');
        },
      );
    } catch (e) {
      DebugUtil.error('⚠️ 标记首次协议同意状态失败: $e，继续初始化');
    }

    // 🔑 关键：启用隐私相关功能（带超时保护）
    try {
      final privacyManager = Get.find<PrivacyComplianceManager>();
      await privacyManager.agreeToPrivacyPolicy().timeout(
        const Duration(seconds: 5), // 🔥 修复：添加5秒超时，避免隐私功能初始化阻塞
        onTimeout: () {
          DebugUtil.error('⚠️ 隐私政策同意流程超时（5秒），继续启动');
        },
      );
      DebugUtil.success('✅ 隐私政策同意完成，所有功能已启用');

      // 🔥 新增：用户同意隐私政策后立即申请关键权限（后台执行，不阻塞）
      _requestEssentialPermissionsAfterAgreement()
          .then((_) {
            DebugUtil.success('关键权限申请完成');
          })
          .catchError((e) {
            DebugUtil.error('关键权限申请失败: $e');
          });

      // 🔥 激活：仅在新用户同意隐私协议后调用（后台执行，不阻塞）
      _activateIfNeeded()
          .then((_) {
            DebugUtil.success('激活接口调用完成');
          })
          .catchError((e) {
            DebugUtil.error('激活接口调用失败: $e');
          });
    } catch (e) {
      DebugUtil.error('❌ 启用隐私功能失败: $e，继续启动流程');
      // 🔥 修复：即使隐私功能初始化失败，也不阻塞启动流程
    }
  }

  /// 🔥 新增：用户同意隐私政策后立即申请关键权限（网络权限 + 通知权限）
  Future<void> _requestEssentialPermissionsAfterAgreement() async {
    // DebugUtil.info('🔐 开始申请关键权限（网络 + 通知）...');

    try {
      // � 已废弃：极光推送（推送现在走腾讯IM）
      // 直接使用 permission_handler 申请通知权限
      final permissionStatus = await Permission.notification.request();

      if (permissionStatus.isGranted) {
        // DebugUtil.success('✅ 通知权限申请成功');
      } else if (permissionStatus.isDenied) {
        DebugUtil.warning('⚠️ 用户拒绝了通知权限');
      } else if (permissionStatus.isPermanentlyDenied) {
        DebugUtil.warning('⚠️ 用户永久拒绝了通知权限，需要手动到设置中开启');
      } else {
        DebugUtil.warning('⚠️ 通知权限申请状态: $permissionStatus');
      }

      // 注意：网络权限（INTERNET）在Android中是普通权限，不需要运行时申请
      // 已在 AndroidManifest.xml 中声明，应用安装时自动授予
      // DebugUtil.success('✅ 网络权限已通过Manifest声明（无需运行时申请）');
    } catch (e) {
      DebugUtil.error('❌ 申请关键权限失败: $e');
      // 即使权限申请失败，也不阻塞应用启动流程
    }
  }

  /// 激活接口调用（新用户，同意隐私后）
  Future<void> _activateIfNeeded() async {
    try {
      if (Get.isRegistered<AppActivationService>()) {
        final activationService = Get.find<AppActivationService>();
        await activationService.tryActivate();
      } else {
        DebugUtil.warning('AppActivationService 未注册，跳过激活');
      }
    } catch (e) {
      DebugUtil.error('调用激活接口失败: $e');
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
      // DebugUtil.success('已预设首页背景滚动位置');
    } catch (e) {
      DebugUtil.error('预设首页滚动位置失败: $e');
    }
  }

  /// 根据当前 App 图标选择启动页 logo 资源
  String _getSplashLogoAsset() {
    switch (_currentIconId) {
      case 'logo_2':
        return 'assets/mipmap-xxhdpi/flash_icon2.webp';
      case 'logo_3':
        return 'assets/mipmap-xxhdpi/flash_icon3.webp';
      case 'logo_4':
        return 'assets/mipmap-xxhdpi/flash_icon4.webp';
      case 'logo_5':
        return 'assets/mipmap-xxhdpi/flash_icon5.webp';
      case 'logo_6':
        return 'assets/mipmap-xxhdpi/flash_icon6.webp';
      case 'logo_7':
        return 'assets/mipmap-xxhdpi/flash_icon7.webp';
      case 'logo_8':
        return 'assets/mipmap-xxhdpi/flash_icon8.webp';
      case 'logo_9':
        return 'assets/mipmap-xxhdpi/flash_icon9.webp';
      case 'logo_10':
        return 'assets/mipmap-xxhdpi/flash_icon10.webp';
      case 'logo_11':
        return 'assets/mipmap-xxhdpi/flash_icon11.webp';
      case 'logo_12':
        return 'assets/mipmap-xxhdpi/flash_icon12.webp';
      case 'logo_13':
        return 'assets/mipmap-xxhdpi/flash_icon13.webp';
      case 'logo_14':
        return 'assets/mipmap-xxhdpi/flash_icon14.webp';
      case 'logo_15':
        return 'assets/mipmap-xxhdpi/flash_icon15.webp';
      case 'logo_16':
        return 'assets/mipmap-xxhdpi/flash_icon16.webp';
      case 'logo_17':
        return 'assets/mipmap-xxhdpi/flash_icon17.webp';
      case 'logo_18':
        return 'assets/mipmap-xxhdpi/flash_icon18.webp';

      case 'default':
      default:
        return 'assets/mipmap-xxhdpi/flash_icon.webp';
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
    final titleWidth = 175.0 * scale;
    final titleHeight = 218.0 * scale;
    final iconWidth = 85.0 * scale;
    final iconHeight = 34.0 * scale;

    return Scaffold(
      body: AnimatedOpacity(
        opacity: _imagesLoaded ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: double.infinity,
          height: double.infinity,

          decoration: const BoxDecoration(
            color: Colors.white,
            image: DecorationImage(
              image: AssetImage('assets/mipmap-xxhdpi/flash.webp'),
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
            ),
          ),
          child: Stack(
            children: [
              //logo
              Transform.translate(
                offset: Offset(0, -135),
                child: Center(
                  child: Image.asset(
                    _getSplashLogoAsset(),
                    width: titleWidth,
                    height: titleHeight,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                bottom: 70 * scale,
                left: 0,
                right: 0,
                child: Image.asset(
                  'assets/mipmap-xxhdpi/flash_title.webp',
                  width: iconWidth,
                  height: iconHeight,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
