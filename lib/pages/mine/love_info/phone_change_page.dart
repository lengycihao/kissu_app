import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kissu_app/widgets/common_back_button.dart';

import '../../../network/public/auth_api.dart';
import '../../../utils/user_manager.dart';
import '../../../utils/login_navigation_lock.dart';
import '../../../widgets/custom_toast_widget.dart';
import '../../../widgets/loading_dots_widget.dart';

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
    final phone = phoneController.text.trim();
    final code = codeController.text.trim();

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
        // 显示成功提示
        CustomToast.show(Get.context!, '手机号更换成功');

        // 延迟执行退出操作
        Timer(const Duration(milliseconds: 800), () async {
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
      // 🔧 使用登录页导航锁，防止重复跳转导致闪烁
      // 先尝试获取锁并跳转到登录页
      final navigated = LoginNavigationLock.navigateToLoginSafely();
      if (!navigated) {
        // 如果已经有其他线程正在导航，直接返回
        return;
      }

      // 然后在后台调用退出登录API（不阻塞UI）
      UserManager.logout().catchError((e) {
        // 退出登录API失败不影响UI，因为已经跳转到登录页了
      });
    } catch (e) {
      // 即使出错也要尝试跳转到登录页（使用导航锁）
      LoginNavigationLock.navigateToLoginSafely();
    }
  }
}

class PhoneChangePage extends StatelessWidget {
  const PhoneChangePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PhoneChangeController());

    return Scaffold(
      backgroundColor: const Color(0xFFffffff), // 和其他页面保持一致的灰色背景
      body: Stack(
        children: [
          // 背景图片 - 和其他页面保持一致
          Positioned.fill(
            child: Image.asset(
              "assets/4.0/kissu4_new_use_bg.webp",
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),

          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 34,
                top: MediaQuery.of(context).padding.top + 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 页面顶部的标题和返回按钮
                  Row(
                    children: [
                      CommonBackButton(
                        onTap: () => Get.back(),
                        assetPath: 'assets/images/kissu_mine_back.webp',
                        iconSize: 24,
                      ),
                      
                      const SizedBox(width: 40), // 平衡布局
                    ],
                  ),
 
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 40,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("请输入手机号",style: TextStyle(
                          color: Color(0xff333333),fontSize: 14,fontWeight: FontWeight.w500
                        ),),
                        const SizedBox(height: 20),
                        _buildInputField(
                          '请输入手机号',
                          false,
                          controller.phoneNumber,
                          context,
                          phoneChangeController: controller,
                          focusNode: controller.phoneFocusNode,
                          controller: controller.phoneController,
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          '请输入验证码',
                          true,
                          controller.verificationCode,
                          context,
                          phoneChangeController: controller,
                          focusNode: controller.codeFocusNode,
                          controller: controller.codeController,
                        ),
                        const SizedBox(height: 40),

                        // 确认更换按钮
                        GestureDetector(
                          onTap: () async {
                            // 如果正在加载，防止重复点击
                            if (controller.isLoading.value) return;

                            // 释放所有焦点并收起键盘
                            controller.phoneFocusNode.unfocus();
                            controller.codeFocusNode.unfocus();
                            FocusScope.of(context).unfocus();
                            await controller.changePhone();
                          },
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFA9E0),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Obx(
                              () => Center(
                                child: controller.isLoading.value
                                    ? const LoadingDotsWidget(
                                        color: Colors.white,
                                        size: 4.0,
                                      )
                                    : const Text(
                                        '立即绑定',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
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
    );
  }

  Widget _buildInputField(
    String hintText,
    bool isCodeField,
    RxString field,
    BuildContext context, {
    required PhoneChangeController phoneChangeController,
    required FocusNode focusNode,
    required TextEditingController controller,
  }) {
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
          borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
        ),
        suffixIcon: isCodeField
            ? Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      // 释放所有焦点并收起键盘
                      phoneChangeController.phoneFocusNode.unfocus();
                      phoneChangeController.codeFocusNode.unfocus();
                      FocusScope.of(context).unfocus();
                      phoneChangeController.validatePhoneNumber();
                    },
                    child: Obx(
                      () => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 21),
                        child: Text(
                          phoneChangeController.codeButtonText,
                          style: TextStyle(
                            color: phoneChangeController.isCountdownActive
                                ? const Color(0xFF999999)
                                : const Color(0xFFFF9AD9),
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
              FilteringTextInputFormatter.digitsOnly, // 验证码只能输入数字，无位数限制
            ]
          : [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
    );
  }
}
