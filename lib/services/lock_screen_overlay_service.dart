import 'dart:io';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/tools/logging/log_manager.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';

/// 锁机服务 - 通过 MethodChannel 调用原生锁屏悬浮窗
class LockScreenOverlayService {
  static const _channel = MethodChannel('kissu_app/lock_screen_overlay');
  static const _tag = 'LockScreenOverlay';

  /// 初始化MethodChannel监听（从原生调用Flutter）
  /// 应在app启动时调用一次
  static void setupMethodCallHandler() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'navigateToQuestionPage':
          logger.info('收到原生跳转答题页面请求', tag: _tag);
          Get.toNamed(KissuRoutePath.lockScreenQuestion);
          break;
        default:
          break;
      }
    });
  }

  /// 检查悬浮窗权限
  static Future<bool> checkOverlayPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('checkOverlayPermission');
      return result ?? false;
    } catch (e) {
      logger.error('检查悬浮窗权限失败: $e', tag: _tag);
      return false;
    }
  }

  /// 请求悬浮窗权限
  static Future<bool> requestOverlayPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('requestOverlayPermission');
      return result ?? false;
    } catch (e) {
      logger.error('请求悬浮窗权限失败: $e', tag: _tag);
      return false;
    }
  }

  /// 锁定屏幕
  /// [minutes] 锁定时长（分钟）
  static Future<bool> lockScreen({required int minutes}) async {
    if (!Platform.isAndroid) return false;
    try {
      final hasPermission = await checkOverlayPermission();
      if (!hasPermission) {
        logger.warning('缺少悬浮窗权限，无法锁屏', tag: _tag);
        return false;
      }
      final result = await _channel.invokeMethod<bool>('lockScreen', {
        'minutes': minutes,
      });
      logger.info('锁屏请求已发送: ${minutes}分钟', tag: _tag);
      return result ?? false;
    } catch (e) {
      logger.error('锁屏失败: $e', tag: _tag);
      return false;
    }
  }

  /// 解锁屏幕
  static Future<bool> unlockScreen() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('unlockScreen');
      logger.info('解锁请求已发送', tag: _tag);
      return result ?? false;
    } catch (e) {
      logger.error('解锁失败: $e', tag: _tag);
      return false;
    }
  }

  /// 获取当前锁屏状态
  static Future<String> getScreenLock() async {
    if (!Platform.isAndroid) return '';
    try {
      final result = await _channel.invokeMethod<String>('getScreenLock');
      return result ?? '';
    } catch (e) {
      logger.error('获取锁屏状态失败: $e', tag: _tag);
      return '';
    }
  }

  /// 停止锁机服务
  static Future<bool> stopService() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('stopService');
      return result ?? false;
    } catch (e) {
      logger.error('停止锁机服务失败: $e', tag: _tag);
      return false;
    }
  }

  /// 🔥 检查并恢复锁屏（app打开时调用，确保重启后锁屏不丢失）
  static Future<void> checkAndRestoreLockScreen() async {
    if (!Platform.isAndroid) return;
    try {
      final lockState = await getScreenLock();
      if (lockState.isEmpty) return;

      // 有锁屏数据，确保锁屏服务正在运行
      logger.info('🔒 检测到活跃锁屏数据，确保锁屏服务运行中', tag: _tag);
      await _channel.invokeMethod<bool>('ensureLockServiceRunning');
    } catch (e) {
      logger.error('🔒 检查锁屏恢复失败: $e', tag: _tag);
    }
  }

  /// 恢复悬浮窗显示（答题页面退出但未解锁时调用）
  static Future<bool> showOverlayAgain() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('showOverlayAgain');
      logger.info('恢复悬浮窗显示', tag: _tag);
      return result ?? false;
    } catch (e) {
      logger.error('恢复悬浮窗显示失败: $e', tag: _tag);
      return false;
    }
  }
}
