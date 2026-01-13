import 'dart:io';
import 'package:flutter_android_oaid_plugin/flutter_android_oaid_plugin.dart';
import 'package:kissu_app/network/tools/logging/log_manager.dart';

/// OAID 获取工具类
/// 
/// 使用 flutter_android_oaid_plugin 插件获取 OAID
class OaidUtil {
  static OaidUtil? _instance;
  static OaidUtil get instance => _instance ??= OaidUtil._();

  OaidUtil._();

  String? _cachedOaid;

  /// 获取 OAID
  Future<String?> getOaid() async {
    // 返回缓存
    if (_cachedOaid != null) {
      return _cachedOaid;
    }

    // 只支持 Android
    if (!Platform.isAndroid) {
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

