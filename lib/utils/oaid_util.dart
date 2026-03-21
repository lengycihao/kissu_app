import 'dart:io';
import 'package:flutter_android_oaid_plugin/flutter_android_oaid_plugin.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/tools/logging/log_manager.dart';
import 'package:kissu_app/services/privacy_compliance_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// 设备ID获取工具类
/// 
/// 优先使用 OAID，当 OAID 不可用时使用 UUID 作为备用
/// 🔒 隐私合规：只有在用户同意隐私政策后才获取OAID
class OaidUtil {
  static OaidUtil? _instance;
  static OaidUtil get instance => _instance ??= OaidUtil._();

  OaidUtil._();

  String? _cachedOaid;
  
  /// UUID 缓存（作为 OAID 的备用）
  String? _cachedUuid;
  
  /// UUID 本地存储 key
  static const String _uuidStorageKey = 'device_uuid_fallback';

  /// 检查是否可以收集敏感数据（用户已同意隐私政策）
  bool _canCollectSensitiveData() {
    try {
      final isRegistered = Get.isRegistered<PrivacyComplianceManager>();
      logger.info('PrivacyComplianceManager 是否注册: $isRegistered', tag: 'OaidUtil');
      if (isRegistered) {
        final privacyManager = Get.find<PrivacyComplianceManager>();
        final isAgreed = privacyManager.isPrivacyAgreed;
        logger.info('隐私政策是否同意: $isAgreed', tag: 'OaidUtil');
        return isAgreed;
      }
    } catch (e) {
      logger.error('检查隐私合规状态失败', tag: 'OaidUtil', error: e);
    }
    // 如果无法检查隐私状态，默认不允许收集
    logger.warning('PrivacyComplianceManager 未注册，默认不允许收集', tag: 'OaidUtil');
    return false;
  }

  /// 获取设备ID（优先 OAID，备用 UUID）
  /// 🔒 隐私合规：只有在用户同意隐私政策后才获取
  /// 返回值永远不为 null，确保埋点数据始终有 device_id
  Future<String?> getOaid() async {
    // logger.info('开始获取设备ID...', tag: 'OaidUtil');
    
    // 返回 OAID 缓存
    if (_cachedOaid != null) {
      // logger.info('返回缓存的设备ID: ${_cachedOaid!.substring(0, 8)}...', tag: 'OaidUtil');
      return _cachedOaid;
    }

    // 🔒 隐私合规检查：用户未同意隐私政策时不获取任何设备ID
    final canCollect = _canCollectSensitiveData();
    // logger.info('隐私合规检查结果: $canCollect', tag: 'OaidUtil');
    if (!canCollect) {
      logger.warning('隐私政策未同意，跳过设备ID获取', tag: 'OaidUtil');
      return null;
    }

    // Android: 尝试获取 OAID
    if (Platform.isAndroid) {
      try {
        final oaid = await FlutterAndroidOaidPlugin.getOAID();
        if (oaid.isNotEmpty) {
          _cachedOaid = oaid;
          // logger.info('OAID 获取成功: ${oaid.substring(0, 8)}...', tag: 'OaidUtil');
          return oaid;
        } else {
          logger.warning('OAID 获取失败，将使用 UUID 备用', tag: 'OaidUtil');
        }
      } catch (e) {
        logger.error('OAID 获取异常，将使用 UUID 备用', tag: 'OaidUtil', error: e);
      }
    }

    // OAID 不可用时，使用 UUID 作为备用
    final uuid = await _getOrCreateUuid();
    _cachedOaid = uuid; // 缓存 UUID 作为设备ID
    return uuid;
  }
  
  /// 获取或创建 UUID（持久化存储）
  Future<String> _getOrCreateUuid() async {
    // 返回内存缓存
    if (_cachedUuid != null) {
      return _cachedUuid!;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 尝试从本地存储读取
      String? storedUuid = prefs.getString(_uuidStorageKey);
      
      if (storedUuid != null && storedUuid.isNotEmpty) {
        _cachedUuid = storedUuid;
        // logger.info('UUID 从本地存储恢复: ${storedUuid.substring(0, 8)}...', tag: 'OaidUtil');
        return storedUuid;
      }
      
      // 生成新的 UUID
      final newUuid = const Uuid().v4();
      await prefs.setString(_uuidStorageKey, newUuid);
      _cachedUuid = newUuid;
      // logger.info('UUID 生成成功: ${newUuid.substring(0, 8)}...', tag: 'OaidUtil');
      return newUuid;
    } catch (e) {
      logger.error('UUID 获取/生成失败', tag: 'OaidUtil', error: e);
      // 最后的备用方案：生成一个临时 UUID（不持久化）
      final tempUuid = const Uuid().v4();
      _cachedUuid = tempUuid;
      return tempUuid;
    }
  }

  /// 清除缓存
  void clearCache() {
    _cachedOaid = null;
    _cachedUuid = null;
  }
}

