import 'dart:io';
import 'package:flutter_android_oaid_plugin/flutter_android_oaid_plugin.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/tools/logging/log_manager.dart';
import 'package:kissu_app/services/privacy_compliance_manager.dart';

/// OAID 获取工具类
/// 
/// 使用 flutter_android_oaid_plugin 插件获取 OAID
/// 🔒 隐私合规：只有在用户同意隐私政策后才获取OAID
class OaidUtil {
  static OaidUtil? _instance;
  static OaidUtil get instance => _instance ??= OaidUtil._();

  OaidUtil._();

  String? _cachedOaid;

  /// 检查是否可以收集敏感数据（用户已同意隐私政策）
  bool _canCollectSensitiveData() {
    try {
      if (Get.isRegistered<PrivacyComplianceManager>()) {
        final privacyManager = Get.find<PrivacyComplianceManager>();
        return privacyManager.isPrivacyAgreed;
      }
    } catch (e) {
      logger.error('检查隐私合规状态失败', tag: 'OaidUtil', error: e);
    }
    // 如果无法检查隐私状态，默认不允许收集
    return false;
  }

  /// 获取 OAID
  /// 🔒 隐私合规：只有在用户同意隐私政策后才获取
  Future<String?> getOaid() async {
    // 返回缓存
    if (_cachedOaid != null) {
      return _cachedOaid;
    }

    // 只支持 Android
    if (!Platform.isAndroid) {
      return null;
    }

    // 🔒 隐私合规检查：用户未同意隐私政策时不获取OAID
    if (!_canCollectSensitiveData()) {
      logger.warning('隐私政策未同意，跳过 OAID 获取', tag: 'OaidUtil');
      return null;
    }

    try {
      final oaid = await FlutterAndroidOaidPlugin.getOAID();
      if (oaid.isNotEmpty) {
        _cachedOaid = oaid;
        logger.info('OAID 获取成功: ${oaid.substring(0, 8)}...', tag: 'OaidUtil');
        return oaid;
      } else {
        logger.warning('OAID 获取失败', tag: 'OaidUtil');
        return null;
      }
    } catch (e) {
      logger.error('OAID 获取异常', tag: 'OaidUtil', error: e);
      return null;
    }
  }

  /// 清除缓存
  void clearCache() {
    _cachedOaid = null;
  }
}

