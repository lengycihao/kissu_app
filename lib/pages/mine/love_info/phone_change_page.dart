import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'dart:async';

import '../../../network/public/auth_api.dart';
import '../../../utils/user_manager.dart';
import '../../../widgets/custom_toast_widget.dart';

class PhoneChangeController extends GetxController {
  final phoneNumber = ''.obs;
  final verificationCode = ''.obs;
  final isLoading = false.obs;
  final loadingText = '正在更换手机号...'.obs;
  final countdownTime = 0.obs;

  Timer? _timer;
  late final FocusNode phoneFocusNode;
  late final FocusNode codeFocusNode;
  late final TextEditingController phoneController;
  late final TextEditingController codeController;

  @override
  void onInit() {
    super.onInit();
    phoneFocusNode = FocusNode();
    codeFocusNode = FocusNode();
    phoneController = TextEditingController();
    codeController = TextEditingController();
  }

  @override
  void onClose() {
    _timer?.cancel();
    phoneFocusNode.dispose();
    codeFocusNode.dispose();
    phoneController.dispose();
    codeController.dispose();
    super.onClose();
  }

  bool get isCountdownActive => countdownTime.value > 0;

  String get codeButtonText {
    if (isCountdownActive) {
      return '${countdownTime.value}秒后重试';
    }
    return '获取验证码';
  }

  void validatePhoneNumber() {
    if (isCountdownActive) return;

    String phone = phoneController.text.trim();

    // 手机号格式验证
    if (phone.isEmpty) {
      CustomToast.show(Get.context!, '请输入手机号');
      return;
    }

    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      CustomToast.show(Get.context!, '请输入正确的手机号');
      return;
    }

    // 开始倒计时
    startCountdown();
    // 发送验证码
    sendVerificationCode(phone);
  }

  void startCountdown() {
    countdownTime.value = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdownTime.value > 0) {
        countdownTime.value--;
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> sendVerificationCode(String phone) async {
    try {
      final authApi = AuthApi();
      final result = await authApi.getPhoneCode(
        phone: phone,
        type: 'change_phone',
      );
      if (result.isSuccess) {
        CustomToast.show(Get.context!, '验证码已发送');
      } else {
        CustomToast.show(Get.context!, result.msg ?? '发送验证码失败');
        // 如果发送失败，停止倒计时
        _timer?.cancel();
        countdownTime.value = 0;
      }
    } catch (e) {
      CustomToast.show(Get.context!, '发送验证码失败：$e');
      // 如果发送失败，停止倒计时
      _timer?.cancel();
      countdownTime.value = 0;
    }
  }

  Future<void> changePhone() async {
    String phone = phoneController.text.trim();
    String code = codeController.text.trim();

    if (phone.isEmpty) {
      CustomToast.show(Get.context!, '请输入手机号');
      return;
    }

    if (code.isEmpty) {
      CustomToast.show(Get.context!, '请输入验证码');
      return;
    }

    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      CustomToast.show(Get.context!, '请输入正确的手机号');
      return;
    }

    isLoading.value = true;

    try {
      final authApi = AuthApi();
      final result = await authApi.changePhone(phone: phone, captcha: code);

      if (result.isSuccess) {
        loadingText.value = '更换成功';

        // 延迟执行退出操作
        Timer(Duration(milliseconds: 1000), () async {
          isLoading.value = false;
          await _logoutAndNavigateToLogin();
        });
      } else {
        isLoading.value = false;
        CustomToast.show(Get.context!, result.msg ?? '更换手机号失败');
      }
    } catch (e) {
      isLoading.value = false;
      CustomToast.show(Get.context!, '更换手机号失败：$e');
    }
  }

  /// 退出账号并跳转到登录页
  Future<void> _logoutAndNavigateToLogin() async {
    try {
      // 执行退出操作
      await UserManager.logout();

      // 跳转到登录页面并清除所有页面栈
      Get.offAllNamed(KissuRoutePath.login);
    } catch (e) {
      // 即使退出失败也要跳转到登录页
      Get.offAllNamed(KissuRoutePath.login);
    }
  }
}

class PhoneChangePage extends StatelessWidget {
  const PhoneChangePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PhoneChangeController());

    return Scaffold(
      body: Obx(
        () => Stack(
            fit: StackFit.expand,
            children: [
              // 背景图片
              Image.asset('assets/kissu_mine_bg.webp', fit: BoxFit.cover),

              SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: 34,
                    top: MediaQuery.of(context).padding.top + 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 页面顶部的标题和返回按钮
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Get.back(),
                            child: Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.centerLeft,
                              child: Image.asset(
                                'assets/kissu_mine_back.webp',
                                width: 24,
                                height: 24,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '更换手机号绑定',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF333333),
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          const SizedBox(width: 40), // 平衡布局
                        ],
                      ),
                      const SizedBox(height: 40),

                      Padding(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: 40,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              'assets/kissu_change_phone_title.png',
                              width: 96,
                              height: 21,
                            ),
                            const SizedBox(height: 20),
                            _buildInputField(
                              '请输入手机号',
                              false,
                              controller.phoneNumber,
                              context,
                              focusNode: controller.phoneFocusNode,
                              controller: controller.phoneController,
                            ),
                            const SizedBox(height: 20),
                            _buildInputField(
                              '请输入验证码',
                              true,
                              controller.verificationCode,
                              context,
                              focusNode: controller.codeFocusNode,
                              controller: controller.codeController,
                            ),
                            const SizedBox(height: 40),

                            // 确认更换按钮
                            GestureDetector(
                              onTap: () async {
                                // 释放所有焦点并收起键盘
                                controller.phoneFocusNode.unfocus();
                                controller.codeFocusNode.unfocus();
                                FocusScope.of(context).unfocus();
                                await controller.changePhone();
                              },
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8B4CB),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Center(
                                  child: Text(
                                    '完成',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildInputField(
    String hintText,
    bool isCodeField,
    RxString field,
    BuildContext context, {
    required FocusNode focusNode,
    required TextEditingController controller,
  }) {
    final phoneController = Get.find<PhoneChangeController>();

    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: (value) {
        field.value = value;
      },
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF333333),
        height: 1.0, // 设置行高为1.0确保垂直居中
      ),
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(
          color: Color(0xFF999999),
          fontSize: 16,
          height: 1.0, // 设置占位符行高为1.0确保垂直居中
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18, // 增加垂直内边距确保居中
        ),
        isDense: true, // 减少默认内边距
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Color(0xFF6D383E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Color(0xFF6D383E)),
        ),
        suffixIcon: isCodeField
            ? Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      // 释放所有焦点并收起键盘
                      phoneController.phoneFocusNode.unfocus();
                      phoneController.codeFocusNode.unfocus();
                      FocusScope.of(context).unfocus();
                      phoneController.validatePhoneNumber();
                    },
                    child: Obx(
                      () => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 21),
                        child: Text(
                          phoneController.codeButtonText,
                          style: TextStyle(
                            color: phoneController.isCountdownActive
                                ? const Color(0xFF999999)
                                : const Color(0xFFFF839E),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : null,
      ),
      keyboardType: isCodeField ? TextInputType.number : TextInputType.phone,
      inputFormatters: isCodeField
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ]
          : [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
    );
  }
}
