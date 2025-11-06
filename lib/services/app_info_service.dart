import 'dart:io';
import 'package:flutter/services.dart';
import 'package:kissu_app/network/tools/logging/log_manager.dart';

/// 应用信息服务
/// 用于获取系统中已安装应用的信息（如应用名称等）
class AppInfoService {
  static final AppInfoService _instance = AppInfoService._internal();
  factory AppInfoService() => _instance;
  AppInfoService._internal();

  static const MethodChannel _channel = MethodChannel('kissu_app/app_info');

  /// 获取单个应用的名称
  /// 
  /// [packageName] 应用包名
  /// 
  /// 返回应用的真实名称，如果获取失败则返回包名的最后一部分
  Future<String> getAppName(String packageName) async {
    if (!Platform.isAndroid) {
      // iOS 不支持此功能
      return packageName.split('.').last;
    }

    try {
      final String? appName = await _channel.invokeMethod('getAppName', {
        'packageName': packageName,
      });
      return appName ?? packageName.split('.').last;
    } catch (e) {
      logger.error('获取应用名称失败: $packageName, $e', tag: 'AppInfoService', error: e);
      return packageName.split('.').last;
    }
  }

  /// 批量获取应用名称
  /// 
  /// [packageNames] 应用包名列表
  /// 
  /// 返回一个 Map，key 为包名，value 为应用名称
  Future<Map<String, String>> getAppNames(List<String> packageNames) async {
    if (!Platform.isAndroid || packageNames.isEmpty) {
      // iOS 或空列表，返回包名的最后一部分
      return Map.fromEntries(
        packageNames.map((pkg) => MapEntry(pkg, pkg.split('.').last)),
      );
    }

    try {
      logger.debug('🔍 正在获取 ${packageNames.length} 个应用的名称...', tag: 'AppInfoService');
      final result = await _channel.invokeMethod('getAppNames', {
        'packageNames': packageNames,
      });
      
      if (result is Map) {
        // 将 Map<dynamic, dynamic> 转换为 Map<String, String>
        final appNamesMap = result.map((key, value) => MapEntry(
          key.toString(),
          value.toString(),
        ));
        logger.debug('✅ 成功获取应用名称: $appNamesMap', tag: 'AppInfoService');
        return appNamesMap;
      }
      
      // 如果返回结果不是 Map，使用备用方案
      logger.warning('⚠️ 返回结果不是 Map，使用备用方案', tag: 'AppInfoService');
      return Map.fromEntries(
        packageNames.map((pkg) => MapEntry(pkg, pkg.split('.').last)),
      );
    } catch (e) {
      logger.error('❌ 批量获取应用名称失败: $e', tag: 'AppInfoService', error: e);
      // 返回包名的最后一部分作为备用
      return Map.fromEntries(
        packageNames.map((pkg) => MapEntry(pkg, pkg.split('.').last)),
      );
    }
  }
}

