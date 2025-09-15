import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';

/// 基于OKToast的可靠Toast工具类
/// 完全匹配原来的CustomToast样式，屏幕中间显示
class OKToastUtil {
  /// 显示Toast消息
  static void show(
    String message, {
    Duration duration = const Duration(seconds: 2),
    Color backgroundColor = const Color(0xffFFF7D0), // 使用您原来的粉色背景
    Color textColor = const Color(0xFF8B4513), // 使用您原来的白色文字
    double fontSize = 13.0, // 使用您原来的字体大小
    double maxWidth = 275.0, // 使用您原来的最大宽度
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 5), // 使用您原来的内边距
  }) {
    showToast(
      message,
      duration: duration,
      position: ToastPosition.center, // 屏幕中间显示
      backgroundColor: backgroundColor,
      textStyle: TextStyle(
        color: textColor,
        fontSize: fontSize,
        height: 1.2,
      ),
      textPadding: padding,
      textAlign: TextAlign.center,
      radius: 6.0, // 圆角
      dismissOtherToast: true, // 自动替换之前的Toast
    );
  }

  /// 显示成功消息
  static void showSuccess(String message) {
    show(
      message,
      backgroundColor: const Color(0xff4CAF50), // 绿色
      duration: const Duration(seconds: 2),
    );
  }

  /// 显示错误消息
  static void showError(String message) {
    show(
      message,
      backgroundColor: const Color(0xffF44336), // 红色
      duration: const Duration(seconds: 3),
    );
  }

  /// 显示警告消息
  static void showWarning(String message) {
    show(
      message,
      backgroundColor: const Color(0xffFF9800), // 橙色
      duration: const Duration(seconds: 2),
    );
  }

  /// 显示信息消息
  static void showInfo(String message) {
    show(
      message,
      backgroundColor: const Color(0xff2196F3), // 蓝色
      duration: const Duration(seconds: 2),
    );
  }

  /// 显示验证码发送成功消息（使用原来的粉色样式）
  static void showVerificationCodeSent() {
    show('验证码发送成功');
  }

  /// 取消所有Toast
  static void dismissAll() {
    dismissAllToast();
  }
}
