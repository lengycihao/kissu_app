import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';

/// 安全的Toast工具类
/// 解决在Controller中调用CustomToast.show时可能出现的context问题
class SafeToastUtil {
  /// 显示Toast消息
  /// 自动处理context获取和验证
  static void show(
    String message, {
    Duration duration = const Duration(seconds: 2),
    Color backgroundColor = const Color(0xffFFF7D0),
    Color textColor = const Color(0xFF8B4513),
    double fontSize = 13.0,
    double maxWidth = 275.0,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
  }) {
    // 尝试多种方式获取有效的context
    BuildContext? context = _getValidContext();
    
    if (context != null && context.mounted) {
      CustomToast.show(
        context,
        message,
        duration: duration,
        backgroundColor: backgroundColor,
        textColor: textColor,
        fontSize: fontSize,
        maxWidth: maxWidth,
        padding: padding,
      );
    } else {
      // 如果无法获取有效context，使用Get.snackbar作为备选方案
      _showFallbackToast(message, backgroundColor, textColor);
    }
  }

  /// 显示成功Toast
  static void showSuccess(String message) {
    show(
      message,
      backgroundColor: const Color(0xFF4CAF50),
      textColor: Colors.white,
    );
  }

  /// 显示错误Toast
  static void showError(String message) {
    show(
      message,
      backgroundColor: const Color(0xFFF44336),
      textColor: Colors.white,
    );
  }

  /// 显示警告Toast
  static void showWarning(String message) {
    show(
      message,
      backgroundColor: const Color(0xFFFF9800),
      textColor: Colors.white,
    );
  }

  /// 显示信息Toast
  static void showInfo(String message) {
    show(
      message,
      backgroundColor: const Color(0xFF2196F3),
      textColor: Colors.white,
    );
  }

  /// 获取有效的BuildContext
  static BuildContext? _getValidContext() {
    // 方法1: 尝试从Get.context获取
    BuildContext? context = Get.context;
    if (context != null && context.mounted) {
      return context;
    }

    // 方法2: 尝试从Get.overlayContext获取
    context = Get.overlayContext;
    if (context != null && context.mounted) {
      return context;
    }

    // 方法3: 尝试从当前路由获取
    try {
      context = Get.context;
      if (context != null && context.mounted) {
        return context;
      }
    } catch (e) {
      print('SafeToastUtil: Error getting current context: $e');
    }

    // 方法4: 尝试从Navigator获取
    try {
      context = Navigator.of(Get.context!, rootNavigator: true).context;
      if (context != null && context.mounted) {
        return context;
      }
    } catch (e) {
      print('SafeToastUtil: Error getting navigator context: $e');
    }

    return null;
  }

  /// 备选方案：使用Get.snackbar显示消息
  static void _showFallbackToast(String message, Color backgroundColor, Color textColor) {
    try {
      Get.snackbar(
        '',
        message,
        backgroundColor: backgroundColor,
        colorText: textColor,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(20),
        borderRadius: 6,
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,
        forwardAnimationCurve: Curves.easeOutBack,
        reverseAnimationCurve: Curves.easeInBack,
        animationDuration: const Duration(milliseconds: 300),
        titleText: const SizedBox.shrink(),
        messageText: Text(
          message,
          style: TextStyle(
            color: textColor,
            fontSize: 13.0,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      );
    } catch (e) {
      // 最后的备选方案：打印到控制台
      print('SafeToastUtil: Failed to show toast: $message');
      print('SafeToastUtil: Error: $e');
    }
  }
}
