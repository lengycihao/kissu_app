import 'package:flutter/services.dart';
import 'package:kissu_app/network/public/auth_service.dart';
import 'package:kissu_app/network/public/service_locator.dart';
import 'package:kissu_app/network/tools/config/app_configN.dart';
import 'package:kissu_app/network/tools/logging/log_manager.dart';

/// Native 定位上报服务（供 Native 端使用）
/// 
/// 功能：
/// 1. 保存用户 Token 到 SharedPreferences（供 Native 端使用）
/// 2. 应用被杀后，Native 端可以继续上报定位数据
class NativeLocationReportService {
  static const MethodChannel _channel =
      MethodChannel('kissu_app/foreground_service');

  /// 保存用户 Token 和 API 配置
  /// 
  /// 在登录成功后调用，确保 Native 端能够上报定位
  static Future<bool> saveUserToken() async {
    try {
      final authService = getIt<AuthService>();
      
      // 检查用户是否登录
      if (!authService.isLoggedIn || authService.userToken == null) {
        logger.warning('⚠️ 用户未登录，无法保存 Token', tag: 'NativeLocationReportService');
        return false;
      }
      
      final token = authService.userToken!;
      final userId = authService.userId ?? '';
      final baseUrl = AppConfigN.baseApiUrl;
      
      logger.debug('🔐 保存用户 Token 到 Native：userId=$userId, baseUrl=$baseUrl', tag: 'NativeLocationReportService');
      
      final result = await _channel.invokeMethod('saveUserToken', {
        'token': token,
        'userId': userId,
        'baseUrl': baseUrl,
        'channel': AppConfigN.appChannel,
      });
      
      if (result is Map) {
        final success = result['success'] as bool? ?? false;
        final message = result['message'] as String? ?? '';
        
        if (success) {
          logger.debug('✅ Native Token 保存成功', tag: 'NativeLocationReportService');
        } else {
          logger.error('❌ Native Token 保存失败: $message', tag: 'NativeLocationReportService');
        }
        
        return success;
      }
      
      return false;
    } catch (e) {
      logger.error('❌ 保存 Native Token 异常: $e', tag: 'NativeLocationReportService', error: e);
      return false;
    }
  }
  
  /// 清除用户 Token（登出时调用）
  static Future<bool> clearUserToken() async {
    try {
      logger.debug('🗑️ 清除 Native Token', tag: 'NativeLocationReportService');
      
      final result = await _channel.invokeMethod('clearUserToken');
      
      if (result is Map) {
        final success = result['success'] as bool? ?? false;
        final message = result['message'] as String? ?? '';
        
        if (success) {
          logger.debug('✅ Native Token 已清除', tag: 'NativeLocationReportService');
        } else {
          logger.error('❌ Native Token 清除失败: $message', tag: 'NativeLocationReportService');
        }
        
        return success;
      }
      
      return false;
    } catch (e) {
      logger.error('❌ 清除 Native Token 异常: $e', tag: 'NativeLocationReportService', error: e);
      return false;
    }
  }
}


