import 'package:flutter/foundation.dart';

/// 调试工具类
/// 提供统一的调试输出接口，在发布版本中自动禁用
class DebugUtil {
  /// 打印基础调试信息
  /// 只在调试模式下输出，发布版本中会被自动移除
  static void print(Object? message) {
    if (kDebugMode) {
      debugPrint(message?.toString());
    }
  }

  /// 打印信息级别的调试信息
  /// 只在调试模式下输出，发布版本中会被自动移除
  static void info(Object? message) {
    if (kDebugMode) {
      debugPrint('INFO: ${message?.toString()}');
    }
  }

  /// 打印错误信息
  /// 只在调试模式下输出，发布版本中会被自动移除
  static void error(Object? message) {
    if (kDebugMode) {
      debugPrint('ERROR: ${message?.toString()}');
    }
  }

  /// 打印错误信息（别名）
  /// 只在调试模式下输出，发布版本中会被自动移除
  static void printError(Object? message) {
    error(message);
  }

  /// 打印警告信息
  /// 只在调试模式下输出，发布版本中会被自动移除
  static void warning(Object? message) {
    if (kDebugMode) {
      debugPrint('WARNING: ${message?.toString()}');
    }
  }

  /// 打印警告信息（别名）
  /// 只在调试模式下输出，发布版本中会被自动移除
  static void printWarning(Object? message) {
    warning(message);
  }

  /// 打印成功信息
  /// 只在调试模式下输出，发布版本中会被自动移除
  static void success(Object? message) {
    if (kDebugMode) {
      debugPrint('SUCCESS: ${message?.toString()}');
    }
  }

  /// 打印检查信息
  /// 只在调试模式下输出，发布版本中会被自动移除
  static void check(Object? message) {
    if (kDebugMode) {
      debugPrint('CHECK: ${message?.toString()}');
    }
  }

  /// 打印启动信息
  /// 只在调试模式下输出，发布版本中会被自动移除
  static void launch(Object? message) {
    if (kDebugMode) {
      debugPrint('LAUNCH: ${message?.toString()}');
    }
  }

  /// 打印网络请求信息
  /// 只在调试模式下输出，发布版本中会被自动移除
  static void printNetwork(Object? message) {
    if (kDebugMode) {
      debugPrint('NETWORK: ${message?.toString()}');
    }
  }

  /// 打印带标签的调试信息
  /// 只在调试模式下输出，发布版本中会被自动移除
  static void printWithTag(String tag, Object? message) {
    if (kDebugMode) {
      debugPrint('[$tag]: ${message?.toString()}');
    }
  }
}
