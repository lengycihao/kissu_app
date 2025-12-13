import 'dart:io';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kissu_app/network/public/auth_api.dart';
import 'package:kissu_app/utils/oaid_util.dart';
import 'package:kissu_app/utils/debug_util.dart';

/// App激活服务
/// 负责在新用户首次安装时调用激活接口（appStart）
/// 获取到 OAID 后调用；若获取不到 OAID 也会继续调用
class AppActivationService extends GetxService {
  static AppActivationService get instance => Get.find<AppActivationService>();

  // SharedPreferences 键
  static const String _hasActivatedKey = 'app_has_activated';

  /// 检查是否已经激活过
  Future<bool> hasActivated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_hasActivatedKey) ?? false;
    } catch (e) {
      DebugUtil.error('检查激活状态失败: $e');
      return false;
    }
  }

  /// 标记已激活
  Future<void> markActivated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasActivatedKey, true);
      DebugUtil.success('已标记App激活状态');
    } catch (e) {
      DebugUtil.error('标记激活状态失败: $e');
    }
  }

  /// 尝试激活App（新用户首次安装时调用）
  /// 获取到OAID后调用；若获取不到OAID也继续调用
  Future<void> tryActivate() async {
    // 检查是否已经激活过
    if (await hasActivated()) {
      DebugUtil.info('App已激活过，跳过激活接口调用');
      return;
    }

    // 只支持 Android 平台（OAID只在Android上可用）
    if (!Platform.isAndroid) {
      DebugUtil.info('非Android平台，跳过激活接口调用');
      return;
    }

    try {
      // 获取 OAID（如果获取失败也继续调用激活接口）
      DebugUtil.info('开始获取OAID用于激活接口...');
      final oaid = await OaidUtil.instance.getOaid();
      
      if (oaid == null || oaid.isEmpty) {
        DebugUtil.warning('OAID获取失败，仍然调用激活接口');
      } else {
        DebugUtil.info('OAID获取成功，开始调用激活接口...');
      }
      
      // 调用激活接口
      final authApi = AuthApi();
      final result = await authApi.appStart();
      
      if (result.isSuccess) {
        // 激活成功，标记已激活
        await markActivated();
        DebugUtil.success('App激活接口调用成功');
      } else {
        DebugUtil.warning('App激活接口调用失败: ${result.msg}');
        // 失败时不标记，允许下次重试
      }
    } catch (e) {
      DebugUtil.error('App激活接口调用异常: $e');
      // 异常时不标记，允许下次重试
    }
  }

  /// 清除激活状态（用于测试或重新激活）
  Future<void> clearActivationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_hasActivatedKey);
      DebugUtil.info('激活状态已清除');
    } catch (e) {
      DebugUtil.error('清除激活状态失败: $e');
    }
  }
}

