import 'dart:io' show Platform;
import 'package:flutter/services.dart';

/// 权限设置助手类
/// 通过MethodChannel调用Android原生代码打开具体的权限设置页面
class PermissionHelper {
  static const MethodChannel _channel = MethodChannel('app.location/settings');
  static const MethodChannel _wechatChannel = MethodChannel('app.wechat/launch');

  /// 打开定位设置页面
  static Future<void> openLocationSettings() async {
    try {
      await _channel.invokeMethod('openLocationSettings');
    } on PlatformException catch (e) {
      print("打开定位设置失败: ${e.message}");
    }
  }

  /// 打开通知管理页面
  static Future<void> openNotificationSettings() async {
    try {
      await _channel.invokeMethod('openNotificationSettings');
    } on PlatformException catch (e) {
      print("打开通知设置失败: ${e.message}");
      // 降级到通用应用设置
      await _channel.invokeMethod('openAppSettings');
    }
  }

  /// 打开电池优化设置页面
  static Future<void> openBatteryOptimizationSettings() async {
    try {
      await _channel.invokeMethod('openBatteryOptimizationSettings');
    } on PlatformException catch (e) {
      print("打开电池优化设置失败: ${e.message}");
      // 降级到通用应用设置
      await _channel.invokeMethod('openAppSettings');
    }
  }

  /// 打开使用情况访问设置页面
  static Future<void> openUsageAccessSettings() async {
    try {
      await _channel.invokeMethod('openUsageAccessSettings');
    } on PlatformException catch (e) {
      print("打开使用情况访问设置失败: ${e.message}");
      // 降级到通用应用设置
      await _channel.invokeMethod('openAppSettings');
    }
  }

  /// 打开通用应用设置页面
  static Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } on PlatformException catch (e) {
      print("打开应用设置失败: ${e.message}");
    }
  }

  /// 打开企业微信客服会话（直接使用客服ID）
  /// [corpId] 企业微信 CorpID
  /// [kfId] 客服 ID
  /// 
  /// 注意：此方法只通过企业微信SDK拉起，失败会抛出异常
  static Future<void> openWeComKfWithParams({
    required String corpId,
    required String kfId,
    String? agentId,
  }) async {
    if (Platform.isAndroid) {
      await _wechatChannel.invokeMethod('openWeComKfWithParams', {
        'corpId': corpId,
        'kfId': kfId,
        'agentId': agentId,
      });
    } else {
      throw UnsupportedError('仅支持 Android 平台');
    }
  }
}
