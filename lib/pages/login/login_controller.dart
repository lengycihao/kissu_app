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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kissu_app/services/location_permission_service.dart';

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
  var codeButtonText = "获取验证码".obs; // 验证码按钮文本
  var codeButtonColor = const Color(0xFFFF839E).obs; // 验证码按钮颜色

  late BuildContext context;

  @override
  void onInit() {
    super.onInit();
    // 重置token失效处理状态，防止重复弹窗
    ApiResponseInterceptor.resetUnauthorizedState();
    _loadAgreementStatus();
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
      print('加载协议状态失败: $e');
      isChecked.value = false;
    }
  }

  /// 保存协议同意状态
  Future<void> _saveAgreementStatus(bool agreed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_agreed_privacy_terms', agreed);
    } catch (e) {
      print('保存协议状态失败: $e');
    }
  }

  /// 清除协议同意状态（注销账户时调用）
  static Future<void> clearAgreementStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('has_agreed_privacy_terms');
      print('协议状态已清除');
    } catch (e) {
      print('清除协议状态失败: $e');
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
      OKToastUtil.show ('请输入有效的手机号');
    }
  }

  // 发送验证码
  Future<void> _sendVerificationCode() async {
    try {
      final result = await authApi.getPhoneCode(
        phone: phoneNumber.value,
        type: 'login', // 登录验证码
      );

      if (result.isSuccess) {OKToastUtil.show("验证码发送成功");
         _startCountdown(); // 启动倒计时
      } else {
        OKToastUtil.show(result.msg ?? '验证码发送失败');
      }
    } catch (e) {
      OKToastUtil.show('验证码发送失败: $e');
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
    codeButtonText.value = '获取验证码';
    codeButtonColor.value = const Color(0xFFFF839E);
  }


  @override
  void onClose() {
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
    // 如果正在登录，防止重复点击
    if (isLoading.value) {
      return;
    }

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

      // ✅ 通过 getIt 获取 AuthService 单例
      final result = await authService.loginWithCode(
        phoneNumber: name,
        code: psw,
      );

      if (result.isSuccess) {
        // 登录成功，保存协议同意状态
        await _saveAgreementStatus(true);

        OKToastUtil.show(  '登录成功');
        // 延迟一下让用户看到成功提示，然后跳转
        await Future.delayed(const Duration(milliseconds: 800));

        // 首次登录请求定位权限
        _requestLocationPermissionAfterLogin();

        //判断是否需要完善信息
        if (UserManager.needsPerfectInfo) {
          // 需要完善信息，跳转到信息完善页面
          Get.offAllNamed(KissuRoutePath.infoSetting);
        } else {
          // 使用命名路由跳转，确保HomeBinding被正确初始化
          Get.offAllNamed(KissuRoutePath.home);
        }
      } else {
        OKToastUtil.show(result.msg ?? '登录失败');
      }
    } catch (e) {
        OKToastUtil.show("登录失败");
    } finally {
      // 结束加载状态
      isLoading.value = false;
    }
  }

  bool isValidPhone(String phone) {
    final regExp = RegExp(r'^1[3-9]\d{9}$');
    return regExp.hasMatch(phone);
  }

  /// 登录成功后请求定位权限
  void _requestLocationPermissionAfterLogin() {
    try {
      // 异步请求定位权限，不阻塞页面跳转
      Future.microtask(() async {
        try {
          final locationPermissionService = Get.find<LocationPermissionService>();
          await locationPermissionService.requestLocationPermissionAfterLogin();
        } catch (e) {
          debugPrint('请求定位权限失败: $e');
        }
      });
    } catch (e) {
      debugPrint('启动定位权限请求失败: $e');
    }
  }

  // 处理协议链接点击
  void _handleLinkTap(String linkName) {
    switch (linkName) {
      case '用户协议':
        print('跳转到用户协议页面');
         OKToastUtil.show('用户协议页面（待实现）');
        // TODO: 实现跳转到用户协议页面
        // Get.toNamed('/user-agreement');
        break;
      case '隐私协议':
        print('跳转到隐私协议页面');
         OKToastUtil.show('隐私协议页面（待实现）');
        // TODO: 实现跳转到隐私协议页面
        // Get.toNamed('/privacy-policy');
        break;
      default:
        print('未知链接: $linkName');
        break;
    }
  }
}
