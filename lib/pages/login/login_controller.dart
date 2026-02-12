import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/interceptor/api_response_interceptor.dart';
import 'package:kissu_app/network/public/auth_api.dart';
import 'package:kissu_app/network/public/auth_service.dart';
import 'package:kissu_app/network/public/service_locator.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/utils/toast_toalog.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/utils/login_navigation_lock.dart';
import 'package:kissu_app/utils/agreement_utils.dart';
import 'package:kissu_app/services/analytics/analytics_page_ids.dart';
import 'package:kissu_app/services/analytics/analytics_helper.dart';
import 'package:kissu_app/services/analytics/analytics_manager.dart';
import 'package:kissu_app/services/analytics/analytics_events.dart';
import 'package:kissu_app/services/analytics/analytics_params.dart';
import 'package:kissu_app/pages/mine/love_info/love_info_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kissu_app/services/openinstall_service.dart';
import 'package:kissu_app/services/app_usage_auto_report_service.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';

class LoginController extends GetxController {
  var isChecked = false.obs;
  var phoneNumber = ''.obs;
  var verificationCode = ''.obs;
  final authService = getIt<AuthService>();
  final authApi = AuthApi(); // 添加 AuthApi 实例

  // 倒计时相关变量
  var countdownSeconds = 0.obs; // 倒计时秒数
  var isCountdownActive = false.obs; // 是否正在倒计时
  Timer? _countdownTimer; // 倒计时定时器

  // 加载状态
  var isLoading = false.obs; // 是否正在登录
  var loadingText = "正在登录...".obs; // loading文案
  var codeButtonText = "发送验证码".obs; // 验证码按钮文本
  var codeButtonColor = const Color(0xFFFF9AD9).obs; // 验证码按钮颜色

  // 登录防抖
  DateTime? _lastLoginTime;
  static const Duration _loginDebounceDelay = Duration(
    milliseconds: 1000,
  ); // 1秒防抖

  late BuildContext context;

  // 埋点相关
  int? _pageEnterTime;
  int _exitType = ExitTypeValue.back;
  bool _hasTrackedExit = false;
  VoidCallback? onNavigateToNextPage;

  @override
  void onInit() {
    super.onInit();

    // 埋点：记录页面进入时间
    _pageEnterTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // 注册页面离开回调
    onNavigateToNextPage = () {
      _trackPageExit(ExitTypeValue.nextPage);
    };

    // 重置token失效处理状态，防止重复弹窗
    ApiResponseInterceptor.resetUnauthorizedState();
    _loadAgreementStatus();
    // 🔑 移除登录页面的隐私弹窗检查，现在在启动页处理
    // _checkAndShowFirstAgreement();
  }

  /// 加载协议同意状态
  Future<void> _loadAgreementStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // 检查是否曾经同意过协议（退出登录时保持同意状态）
      final hasAgreedBefore =
          prefs.getBool('has_agreed_privacy_terms') ?? false;
      isChecked.value = hasAgreedBefore;
    } catch (e) {
      logWarning('加载协议状态失败: $e', tag: 'Login', error: e);
      isChecked.value = false;
    }
  }

  /// 保存协议同意状态
  Future<void> _saveAgreementStatus(bool agreed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_agreed_privacy_terms', agreed);
    } catch (e) {
      logWarning('保存协议状态失败: $e', tag: 'Login', error: e);
    }
  }

  /// 清除协议同意状态（注销账户时调用）
  static Future<void> clearAgreementStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('has_agreed_privacy_terms');
      logDebug('协议状态已清除', tag: 'Login');
    } catch (e) {
      logWarning('清除协议状态失败: $e', tag: 'Login', error: e);
    }
  }

  // /// 重置首次协议状态（用于测试）
  // Future<void> resetFirstAgreementForTesting() async {
  //   try {
  //     await FirstLaunchService.instance.resetFirstAgreementStatus();
  //     OKToastUtil.show('首次协议状态已重置，下次启动将重新显示弹窗');
  //   } catch (e) {
  //     OKToastUtil.show('重置失败: $e');
  //   }
  // }

  /// 获取OpenInstall邀请码
  Future<String?> _getOpenInstallFriendCode() async {
    try {
      // 统一通过 OpenInstallService 的解析逻辑获取（兼容 bindData 为字符串或其他字段名）
      final inviteCode = await OpenInstallService.getInviteCode();
      if (inviteCode != null && inviteCode.isNotEmpty) {
        logDebug('获取到OpenInstall邀请码: $inviteCode', tag: 'Login');
        return inviteCode;
      }

      logDebug('未获取到OpenInstall邀请码', tag: 'Login');
      return "";
    } catch (e) {
      logWarning('获取OpenInstall邀请码失败: $e', tag: 'Login', error: e);
      return "";
    }
  }

  // 校验手机号并发送验证码
  Future<void> validatePhoneNumber() async {
    // 如果正在倒计时，不允许重复发送
    if (isCountdownActive.value) {
      OKToastUtil.show('请等待倒计时结束后再次获取');
      return;
    }

    if (isValidPhone(phoneNumber.value)) {
      await _sendVerificationCode();
    } else {
      AnalyticsHelper.trackGetVerificationCode(success: false);
      OKToastUtil.show('请输入有效的手机号');
    }
  }

  // 发送验证码
  Future<void> _sendVerificationCode() async {
    try {
      final result = await authApi.getPhoneCode(
        phone: phoneNumber.value,
        type: 'login', // 登录验证码
      );

      if (result.isSuccess) {
        OKToastUtil.show("验证码发送成功");
        _startCountdown(); // 启动倒计时
        // 埋点：验证码发送成功
        AnalyticsHelper.trackGetVerificationCode(success: true);
      } else {
        OKToastUtil.show(result.msg ?? '验证码发送失败');
        // 埋点：验证码发送失败
        AnalyticsHelper.trackGetVerificationCode(success: false);
      }
    } catch (e) {
      OKToastUtil.show('验证码发送失败: $e');
      // 埋点：验证码发送失败（异常）
      AnalyticsHelper.trackGetVerificationCode(success: false);
    }
  }

  // 启动30秒倒计时
  void _startCountdown() {
    countdownSeconds.value = 30;
    isCountdownActive.value = true;
    codeButtonText.value = '${countdownSeconds.value}s';
    codeButtonColor.value = const Color(0xFF999999);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdownSeconds.value > 0) {
        countdownSeconds.value--;
        codeButtonText.value = '${countdownSeconds.value}s';
      } else {
        _stopCountdown();
      }
    });
  }

  // 停止倒计时
  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    isCountdownActive.value = false;
    countdownSeconds.value = 0;
    codeButtonText.value = '发送验证码';
    codeButtonColor.value = const Color(0xFFFF839E);
  }

  @override
  void onClose() {
    _trackPageExit(_exitType);
    _stopCountdown(); // 控制器销毁时停止倒计时
    super.onClose();
  }

  // // 登录逻辑
  // void login() {
  //   ToastDialog.showDialogWithCloseButton(
  //     context,
  //     '温馨提示', // 标题
  //     '为了更好的保障你的权益，请阅读并同意《用户协议》和《隐私协议》后进行登录', // 内容
  //     () {
  //       // 确认按钮点击回调
  //       Get.to(() => InfoSettingPage());
  //     },
  //     height: 245.0, // 传递弹窗的高度（例如：500.0）
  //   );
  //   if (isChecked.value) {
  //     print("登录成功");
  //   } else {
  //     print("请同意隐私协议和用户协议");
  //   }
  // }

  void login() {
    // 防抖检查：如果距离上次点击时间小于1秒，直接返回
    final now = DateTime.now();
    if (_lastLoginTime != null &&
        now.difference(_lastLoginTime!) < _loginDebounceDelay) {
      logDebug('⏱️ 登录按钮防抖：距离上次点击时间过短，忽略本次点击');
      return;
    }

    // 如果正在登录，防止重复点击
    if (isLoading.value) {
      logDebug('⏱️ 登录按钮防抖：正在登录中，忽略本次点击');
      return;
    }

    // 更新最后点击时间
    _lastLoginTime = now;

    if (phoneNumber.value.isEmpty || verificationCode.value.isEmpty) {
      OKToastUtil.show('账号或验证码不能为空');
      return;
    } else if (!isChecked.value) {
      ToastDialog.showDialogWithCloseButton(
        context,
        '温馨提示', // 标题
        '为了更好的保障你的权益，请阅读并同意《用户协议》和《隐私协议》后进行登录', // 内容
        () {
          Navigator.pop(context);
          isChecked.value = true;

          _loginWithApi(name: phoneNumber.value, psw: verificationCode.value);
        },
        height: 230.0, // 传递弹窗的高度（例如：500.0）
        onLinkTap: (linkName) {
          // 处理链接点击
          _handleLinkTap(linkName);
        },
      );

      return;
    } else {
      _loginWithApi(name: phoneNumber.value, psw: verificationCode.value);
    }
  }

  Future<void> _loginWithApi({
    required String name,
    required String psw,
  }) async {
    try {
      // 开始加载
      isLoading.value = true;

      // 获取OpenInstall邀请码
      String? friendCode = await _getOpenInstallFriendCode();

      // ✅ 通过 getIt 获取 AuthService 单例，传递friendCode
      final result = await authService.loginWithCode(
        phoneNumber: name,
        code: psw,
        friendCode: friendCode,
      );

      if (result.isSuccess) {
        // 埋点：上报手机号输入事件
        AnalyticsHelper.trackPhoneInput(hasInput: phoneNumber.value.isNotEmpty);
        // 埋点：上报验证码输入事件
        AnalyticsHelper.trackCodeInput(
          hasInput: verificationCode.value.isNotEmpty,
        );
        // 埋点：登录成功
        AnalyticsHelper.trackLoginButton(success: true);

        // 登录成功，保存协议同意状态
        await _saveAgreementStatus(true);

        OKToastUtil.show('登录成功');
        // 延迟一下让用户看到成功提示，然后跳转
        await Future.delayed(const Duration(milliseconds: 200));

        // 检查是否需要显示VIP推广弹窗，并保存标识到SharedPreferences
        final shouldShowVipPromo = result.data?.isGiveVip == 1;

        // 保存VIP推广标识到SharedPreferences（无论是true还是false都要保存，覆盖旧值）
        await _saveVipPromoFlag(shouldShowVipPromo);

        // 启动App使用记录自动上报服务（登录成功后）
        _startAppUsageAutoReport();

        // 清理恋爱信息控制器，避免跨账号复用旧的本地数据
        _clearLoveInfoController();

        // 重置登录页导航锁（登录成功后）
        LoginNavigationLock.reset();

        // 首次登录请求定位权限
        //判断是否需要完善信息
        if (UserManager.needsPerfectInfo) {
          // 需要完善信息，跳转到信息完善页面，传入来源页面为登录页面
          Get.offAllNamed(KissuRoutePath.infoSetting);
        } else {
          // 使用命名路由跳转，确保HomeBinding被正确初始化
          Get.offAllNamed(KissuRoutePath.home);
        }
      } else {
        // 埋点：上报手机号输入事件
        AnalyticsHelper.trackPhoneInput(hasInput: phoneNumber.value.isNotEmpty);
        // 埋点：上报验证码输入事件
        AnalyticsHelper.trackCodeInput(
          hasInput: verificationCode.value.isNotEmpty,
        );
        // 埋点：登录失败
        AnalyticsHelper.trackLoginButton(success: false);

        OKToastUtil.show(result.msg ?? '登录失败');
      }
    } catch (e) {
      // 埋点：上报手机号输入事件
      AnalyticsHelper.trackPhoneInput(hasInput: phoneNumber.value.isNotEmpty);
      // 埋点：上报验证码输入事件
      AnalyticsHelper.trackCodeInput(
        hasInput: verificationCode.value.isNotEmpty,
      );
      // 埋点：登录失败（异常）
      AnalyticsHelper.trackLoginButton(success: false);

      logError('❌登录失败: $e', tag: 'Login', error: e);
      OKToastUtil.show("登录失败");
    } finally {
      // 结束加载状态
      isLoading.value = false;
    }
  }

  void _clearLoveInfoController() {
    if (Get.isRegistered<LoveInfoController>()) {
      Get.delete<LoveInfoController>(force: true);
      logDebug('🧹 登录成功，恋爱信息控制器已重置', tag: 'Login');
    }
  }

  bool isValidPhone(String phone) {
    final regExp = RegExp(r'^1[3-9]\d{9}$');
    return regExp.hasMatch(phone);
  }

  // 处理协议链接点击
  void _handleLinkTap(String linkName) {
    switch (linkName) {
      case '用户协议':
        logDebug('跳转到用户协议页面', tag: 'Login');
        AgreementUtils.toUserAgreement();
        break;
      case '隐私协议':
        logDebug('跳转到隐私协议页面', tag: 'Login');
        AgreementUtils.toPrivacyAgreement();
        break;
      default:
        logWarning('未知链接: $linkName', tag: 'Login');
        break;
    }
  }

  /// 保存VIP推广标识
  Future<void> _saveVipPromoFlag(bool shouldShow) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('should_show_vip_promo', shouldShow);
      logDebug('VIP推广标识已保存: $shouldShow');
    } catch (e) {
      logError('保存VIP推广标识失败: $e');
    }
  }

  /// 启动App使用记录自动上报服务（登录成功后）
  void _startAppUsageAutoReport() {
    try {
      if (Get.isRegistered<AppUsageAutoReportService>()) {
        final service = Get.find<AppUsageAutoReportService>();
        // 登录时强制全量上报，确保换账号后也能正确上报
        service.restart(forceFullReport: true);
        logInfo('✅ App使用记录自动上报服务已重启（登录后，强制全量上报）', tag: 'Login');
      } else {
        logWarning('⚠️ App使用记录自动上报服务未注册', tag: 'Login');
      }
    } catch (e) {
      logError('❌ 启动App使用记录自动上报服务失败: $e', tag: 'Login', error: e);
    }
  }

  /// 上报页面离开埋点
  void _trackPageExit(int exitType) {
    if (_hasTrackedExit || _pageEnterTime == null) return;
    _hasTrackedExit = true;

    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final duration = currentTime - _pageEnterTime!;

    AnalyticsManager.instance.trackPageView(
      pageId: LoginEvents.pageId,
      eventId: LoginEvents.page,
      enterTime: _pageEnterTime!,
      duration: duration,
      exitType: exitType,
    );
  }

  void onAppPaused() {
    _exitType = ExitTypeValue.toBackground;
    _trackPageExit(ExitTypeValue.toBackground);
  }

  void onAppResumed() {
    _pageEnterTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _hasTrackedExit = false;
    _exitType = ExitTypeValue.back;
  }
}
