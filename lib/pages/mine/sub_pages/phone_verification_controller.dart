import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../network/public/auth_api.dart';
import '../../../utils/user_manager.dart';
import '../../../routers/kissu_route_path.dart';
import '../../../widgets/dialogs/confirm_dialog.dart';
import '../../../widgets/custom_toast_widget.dart';

class PhoneVerificationController extends GetxController {
  // 输入内容
  final phoneNumber = ''.obs;
  final verificationCode = ''.obs;

  // 状态控制
  final isCodeSent = false.obs;
  final countdown = 0.obs;
  final canResend = true.obs;
  final isLoading = false.obs;

  // TextField控制器
  late TextEditingController verificationCodeController;

  Timer? _countdownTimer;

  @override
  void onInit() {
    super.onInit();
    // 初始化TextEditingController
    verificationCodeController = TextEditingController();
    // 监听输入变化，同步到响应式变量
    verificationCodeController.addListener(() {
      verificationCode.value = verificationCodeController.text;
    });
    // 初始化时自动填充用户手机号
    loadUserPhone();
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    verificationCodeController.dispose();
    super.onClose();
  }

  /// 加载用户手机号
  void loadUserPhone() {
    final userPhone = UserManager.userPhone;
    if (userPhone?.isNotEmpty == true) {
      phoneNumber.value = userPhone!;
    }
  }

  // 验证手机号格式
  bool validatePhoneNumber() {
    final phone = phoneNumber.value.trim();
    if (phone.isEmpty) {
      CustomToast.show(
        Get.context!,
        '未获取到绑定手机号',
      );
      return false;
    }

    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      CustomToast.show(
        Get.context!,
        '绑定手机号格式不正确',
      );
      return false;
    }

    return true;
  }

  // 发送验证码
  Future<void> sendVerificationCode() async {
    if (!validatePhoneNumber()) return;

    if (!canResend.value) {
      CustomToast.show(
        Get.context!,
        '请等待${countdown.value}秒后重试',
      );
      return;
    }

    isLoading.value = true;

    try {
      // 调用发送验证码API，type为logout
      final authApi = AuthApi();
      final result = await authApi.getPhoneCode(
        phone: phoneNumber.value.trim(),
        type: 'logout',
      );

      if (result.isSuccess) {
        isCodeSent.value = true;
        startCountdown();

        CustomToast.show(
          Get.context!,
          '验证码已发送', 
        );
      } else {
        CustomToast.show(
          Get.context!,
          result.msg ?? '发送验证码失败',
        );
      }
    } catch (e) {
      CustomToast.show(
        Get.context!,
        '发送验证码失败：$e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // 开始倒计时
  void startCountdown() {
    countdown.value = 60;
    canResend.value = false;

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.value > 0) {
        countdown.value--;
      } else {
        timer.cancel();
        canResend.value = true;
      }
    });
  }

  // 验证验证码
  bool validateCode() {
    final code = verificationCode.value.trim();
    if (code.isEmpty) {
      CustomToast.show(
        Get.context!,
        '请输入验证码',
      );
      return false;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      CustomToast.show(
        Get.context!,
        '请输入6位数字验证码',
      );
      return false;
    }

    return true;
  }

  // 确认注销
  Future<void> confirmCancellation() async {
    if (!validatePhoneNumber() || !validateCode()) return;

    // 显示确认对话框
    showCancellationDialog();
  }

  // 显示注销确认对话框
  void showCancellationDialog() async {
    final result = await CancellationConfirmDialog.show(Get.context!);
    if (result == true) {
      // 执行注销操作
      await performCancellation();
    }
  }

  // 执行注销操作
  Future<void> performCancellation() async {
    isLoading.value = true;

    try {
      // 调用注销API
      final authApi = AuthApi();
      final result = await authApi.cancelAccount(
        captcha: verificationCode.value.trim(),
      );

      if (result.isSuccess) {
        // 清除本地用户数据（注销成功后只清理本地数据，不再调用退出登录API）
        await UserManager.clearLocalUserData();

        // 跳转到登录页面并显示成功消息
        Get.offAllNamed(KissuRoutePath.login);

        // 延迟显示消息，确保页面已经切换
        Future.delayed(const Duration(milliseconds: 500), () {
          CustomToast.show(
            Get.context!,
            '账号注销成功',
          );
        });
      } else {
        CustomToast.show(
          Get.context!,
          result.msg ?? '注销失败，请重试',
        );
      }
    } catch (e) {
      CustomToast.show(
        Get.context!,
        '注销失败：$e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // 返回上一页
  void goBack() {
    Get.back();
  }
}