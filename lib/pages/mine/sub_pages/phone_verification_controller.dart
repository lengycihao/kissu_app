import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PhoneVerificationController extends GetxController {
  // 输入内容
  final phoneNumber = ''.obs;
  final verificationCode = ''.obs;
  
  // 状态控制
  final isCodeSent = false.obs;
  final countdown = 0.obs;
  final canResend = true.obs;
  final isLoading = false.obs;
  
  Timer? _countdownTimer;
  
  @override
  void onClose() {
    _countdownTimer?.cancel();
    super.onClose();
  }
  
  // 验证手机号格式
  bool validatePhoneNumber() {
    final phone = phoneNumber.value.trim();
    if (phone.isEmpty) {
      Get.snackbar(
        '提示',
        '请输入手机号',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
    
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      Get.snackbar(
        '提示',
        '请输入正确的手机号',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
    
    return true;
  }
  
  // 发送验证码
  Future<void> sendVerificationCode() async {
    if (!validatePhoneNumber()) return;
    
    if (!canResend.value) {
      Get.snackbar(
        '提示',
        '请等待${countdown.value}秒后重试',
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    
    isLoading.value = true;
    
    try {
      // 模拟发送验证码
      await Future.delayed(const Duration(seconds: 1));
      
      isCodeSent.value = true;
      startCountdown();
      
      Get.snackbar(
        '提示',
        '验证码已发送',
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar(
        '错误',
        '发送验证码失败，请重试',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
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
      Get.snackbar(
        '提示',
        '请输入验证码',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
    
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      Get.snackbar(
        '提示',
        '请输入6位数字验证码',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
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
  void showCancellationDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          '确认注销',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          '注销账户后，您的所有数据将被永久删除，无法恢复。确定要注销吗？',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              '取消',
              style: TextStyle(
                color: Color(0xFF999999),
                fontSize: 16,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await performCancellation();
            },
            child: const Text(
              '确认注销',
              style: TextStyle(
                color: Color(0xFFFF4444),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 执行注销操作
  Future<void> performCancellation() async {
    isLoading.value = true;
    
    try {
      // 模拟注销请求
      await Future.delayed(const Duration(seconds: 2));
      
      Get.snackbar(
        '提示',
        '账户已注销',
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      
      // 延迟后返回到登录页面
      await Future.delayed(const Duration(seconds: 1));
      // TODO: 导航到登录页面
      // Get.offAllNamed('/login');
      Get.until((route) => route.isFirst);
    } catch (e) {
      Get.snackbar(
        '错误',
        '注销失败，请重试',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
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