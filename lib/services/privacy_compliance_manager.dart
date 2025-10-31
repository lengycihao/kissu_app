import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'package:kissu_app/services/share_service.dart';
import 'package:kissu_app/services/sensitive_data_service.dart';
import 'package:kissu_app/services/simple_location_service.dart';
import 'package:kissu_app/services/jpush_service.dart';
import 'package:kissu_app/services/openinstall_service.dart';
import 'package:kissu_app/services/screen_lock_service.dart';
import 'package:kissu_app/utils/debug_util.dart';
import 'package:kissu_app/utils/umeng_analytics_util.dart';

/// 安全的隐私合规管理器
/// 采用渐进式初始化策略，确保第三方SDK功能不受影响
class PrivacyComplianceManager extends GetxService {
  static PrivacyComplianceManager get instance => Get.find<PrivacyComplianceManager>();
  
  // 隐私政策相关键值
  static const String _privacyAgreedKey = 'privacy_policy_agreed';
  static const String _privacyVersionKey = 'privacy_policy_version';
  static const String _currentPrivacyVersion = '1.0.0'; // 隐私政策版本
  
  // 合规状态
  final RxBool _isPrivacyAgreed = false.obs;
  final RxBool _isSdkInitialized = false.obs;
  final RxBool _isInitializing = false.obs;
  
  // Getters
  bool get isPrivacyAgreed => _isPrivacyAgreed.value;
  bool get isSdkInitialized => _isSdkInitialized.value;
  bool get isInitializing => _isInitializing.value;
  bool get canCollectSensitiveData => isPrivacyAgreed && isSdkInitialized;
  
  @override
  Future<void> onInit() async {
    super.onInit();
    await _loadPrivacyStatus();
  }
  
  /// 加载隐私政策同意状态
  /// 🔑 关键改进：只加载状态，不自动初始化SDK，等待用户明确同意
  Future<void> _loadPrivacyStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final agreed = prefs.getBool(_privacyAgreedKey) ?? false;
      final version = prefs.getString(_privacyVersionKey) ?? '';
      
      if (kDebugMode) {
        DebugUtil.info('📋 加载隐私政策状态 - agreed: $agreed, version: $version, 当前版本: $_currentPrivacyVersion');
      }
      
      // 检查版本是否匹配，如果隐私政策更新了需要重新同意
      if (agreed && version == _currentPrivacyVersion) {
        _isPrivacyAgreed.value = true;
        if (kDebugMode) {
          DebugUtil.success('✅ 隐私政策已同意，版本: $version');
        }
        
        // 🔑 关键修复：即使已同意，也要在启动时重新初始化SDK
        // 这样确保每次启动都是在用户已明确同意的前提下初始化
        await initializeSdks();
        
      } else {
        _isPrivacyAgreed.value = false;
        if (kDebugMode) {
          DebugUtil.warning('⚠️ 隐私政策未同意或版本过期 - agreed: $agreed, 当前版本: $_currentPrivacyVersion，已保存版本: $version');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        DebugUtil.error('❌ 加载隐私政策状态失败: $e');
      }
      _isPrivacyAgreed.value = false;
    }
  }
  
  /// 用户同意隐私政策
  Future<void> agreeToPrivacyPolicy() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_privacyAgreedKey, true);
      await prefs.setString(_privacyVersionKey, _currentPrivacyVersion);
      
      _isPrivacyAgreed.value = true;
      
      if (kDebugMode) {
        DebugUtil.success('用户已同意隐私政策，版本: $_currentPrivacyVersion');
      }
      
      // 自动初始化SDK
      await initializeSdks();
      
    } catch (e) {
      if (kDebugMode) {
        DebugUtil.error('保存隐私政策同意状态失败: $e');
      }
      throw Exception('保存隐私政策状态失败');
    }
  }
  
  /// 用户拒绝隐私政策
  Future<void> rejectPrivacyPolicy() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_privacyAgreedKey, false);
      await prefs.remove(_privacyVersionKey);
      
      _isPrivacyAgreed.value = false;
      _isSdkInitialized.value = false;
      
      if (kDebugMode) {
        DebugUtil.warning('用户拒绝隐私政策');
      }
      
    } catch (e) {
      if (kDebugMode) {
        DebugUtil.error('保存隐私政策拒绝状态失败: $e');
      }
    }
  }
  
  /// 清除隐私政策状态（注销时调用）
  Future<void> clearPrivacyStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_privacyAgreedKey);
      await prefs.remove(_privacyVersionKey);
      
      _isPrivacyAgreed.value = false;
      _isSdkInitialized.value = false;
      
      if (kDebugMode) {
        DebugUtil.success('隐私政策状态已清除');
      }
    } catch (e) {
      if (kDebugMode) {
        DebugUtil.error('清除隐私政策状态失败: $e');
      }
    }
  }
  
  /// 渐进式初始化SDK和服务
  /// 采用安全策略：只在用户同意后补充初始化，不影响已有功能
  Future<void> initializeSdks() async {
    if (!isPrivacyAgreed) {
      if (kDebugMode) {
        DebugUtil.warning('用户未同意隐私政策，跳过敏感数据相关初始化');
      }
      return;
    }
    
    if (isSdkInitialized || isInitializing) {
      if (kDebugMode) {
        DebugUtil.warning('隐私相关功能已初始化或正在初始化中');
      }
      return;
    }
    
    _isInitializing.value = true;
    
    try {
      if (kDebugMode) {
        DebugUtil.launch('开始补充初始化隐私相关功能');
      }
      
      // 🔑 关键修复：先设置 isSdkInitialized = true，然后再启用隐私功能
      // 这样在 _enablePrivacyFeatures() 内部调用 startMonitoring() 时，canCollectSensitiveData 就是 true
      _isSdkInitialized.value = true;
      
      // 安全策略：只补充隐私授权，不重复初始化已有服务
      await _enablePrivacyFeatures();
      
      if (kDebugMode) {
        DebugUtil.success('隐私相关功能启用完成');
      }
      
      // 上报APP打开事件
      await _reportAppOpen();
      
    } catch (e) {
      if (kDebugMode) {
        DebugUtil.error('隐私功能启用失败: $e');
      }
      // 🔑 如果初始化失败，重置状态
      _isSdkInitialized.value = false;
      rethrow;
    } finally {
      _isInitializing.value = false;
    }
  }
  
  /// 启用隐私相关功能（不重复初始化服务）
  Future<void> _enablePrivacyFeatures() async {
    try {
      // 1. 启用高德地图隐私授权
      await _enableAmapPrivacy();
      
      // 2. 启用极光推送初始化
      await _enableJPushService();
      
      // 3. 启用友盟分享的隐私授权
      await _enableShareServicePrivacy();
      
      // 4. 启用友盟统计初始化
      await _enableUmengAnalytics();
      
      // 5. 启用OpenInstall的剪贴板功能（如果需要）
      await _enableOpenInstallClipboard();
      
      // 6. 启用敏感数据收集
      await _enableSensitiveDataCollection();
      
      // 7. 通知其他服务隐私政策已同意
      _notifyPrivacyAgreement();
      
      if (kDebugMode) {
        DebugUtil.success('隐私功能启用完成');
      }
    } catch (e) {
      if (kDebugMode) {
        DebugUtil.error('启用隐私功能失败: $e');
      }
      rethrow;
    }
  }
  
  /// 启用高德地图隐私授权
  Future<void> _enableAmapPrivacy() async {
    try {
      // 🔑 用户同意隐私政策后，启用高德地图隐私授权
      AMapFlutterLocation.updatePrivacyAgree(true);
      if (kDebugMode) {
        DebugUtil.success('高德地图隐私授权已启用');
      }
    } catch (e) {
      if (kDebugMode) {
        DebugUtil.error('启用高德地图隐私授权失败: $e');
      }
    }
  }
  
  /// 启用极光推送服务
  Future<void> _enableJPushService() async {
    try {
      if (Get.isRegistered<JPushService>()) {
        final jpushService = Get.find<JPushService>();
        if (!jpushService.isInitialized) {
          await jpushService.initJPush();
          if (kDebugMode) {
            DebugUtil.success('极光推送服务已启用');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        DebugUtil.error('启用极光推送服务失败: $e');
      }
    }
  }
  
  /// 启用友盟分享的隐私授权
  Future<void> _enableShareServicePrivacy() async {
    try {
      if (Get.isRegistered<ShareService>()) {
        final shareService = Get.find<ShareService>();
        await shareService.setPrivacyPolicyGranted(true);
        if (kDebugMode) {
          DebugUtil.success('友盟分享隐私授权已启用');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        DebugUtil.error('启用友盟分享隐私授权失败: $e');
      }
    }
  }
  
  /// 启用友盟统计初始化
  Future<void> _enableUmengAnalytics() async {
    try {
      // 初始化友盟统计（包含 preInit）
      await UmengAnalytics.init();
      
      // 提交隐私政策授权结果（用户已同意）
      await UmengAnalytics.submitPolicyGrantResult(true);
      
      if (kDebugMode) {
        DebugUtil.success('友盟统计已初始化并授权隐私政策');
      }
    } catch (e) {
      if (kDebugMode) {
        DebugUtil.error('初始化友盟统计失败: $e');
      }
    }
  }
  
  /// 初始化OpenInstall服务（隐私合规版本）
  Future<void> _enableOpenInstallClipboard() async {
    try {
      // 🔒 在用户同意隐私政策后才初始化OpenInstall
      await OpenInstallService.init(enableClipboard: false); // 仍然禁用剪贴板
      
      // 获取邀请码（不涉及敏感权限）
      try {
        final inviteCode = await OpenInstallService.getInviteCode();
        if (inviteCode != null && inviteCode.isNotEmpty) {
          if (kDebugMode) {
            DebugUtil.info('检测到OpenInstall邀请码: $inviteCode');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          DebugUtil.error('获取OpenInstall邀请码失败: $e');
        }
      }
      
      if (kDebugMode) {
        DebugUtil.success('OpenInstall服务初始化完成（剪贴板已禁用）');
      }
    } catch (e) {
      if (kDebugMode) {
        DebugUtil.error('OpenInstall服务初始化失败: $e');
      }
    }
  }
  
  
  /// 启用敏感数据收集
  Future<void> _enableSensitiveDataCollection() async {
    try {
      // 启动敏感数据服务的监听功能
      if (Get.isRegistered<SensitiveDataService>()) {
        final sensitiveDataService = Get.find<SensitiveDataService>();
        sensitiveDataService.startMonitoring(); // 启动监听
        
        // 启动锁屏监听服务（在用户同意后）
        if (Get.isRegistered<ScreenLockService>()) {
          final screenLockService = Get.find<ScreenLockService>();
          screenLockService.startListening();
          if (kDebugMode) {
            DebugUtil.success('锁屏监听服务已启动');
          }
        }
        
        // 启动定位服务（在用户同意后）
        final locationService = Get.find<SimpleLocationService>();
        locationService.startPrivacyCompliantService();
        
        // 启动友盟分享服务（在用户同意后）
        final shareService = Get.find<ShareService>();
        shareService.startPrivacyCompliantService();
        if (kDebugMode) {
          DebugUtil.success('敏感数据收集已启用');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        DebugUtil.error('启用敏感数据收集失败: $e');
      }
    }
  }
  
  /// 通知其他服务隐私政策已同意
  void _notifyPrivacyAgreement() {
    try {
      // 通知业务请求头拦截器可以收集设备信息
      // 这里可以设置一个全局标志或通知相关服务
      
      if (kDebugMode) {
        DebugUtil.success('已通知所有服务隐私政策同意状态');
      }
    } catch (e) {
      if (kDebugMode) {
        DebugUtil.error('通知隐私政策同意状态失败: $e');
      }
    }
  }
  
  /// 上报APP打开事件
  Future<void> _reportAppOpen() async {
    try {
      if (Get.isRegistered<SensitiveDataService>()) {
        final sensitiveDataService = Get.find<SensitiveDataService>();
        await sensitiveDataService.reportAppOpen();
        if (kDebugMode) {
          DebugUtil.success('APP打开事件上报完成');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        DebugUtil.error('APP打开事件上报失败: $e');
      }
    }
  }
  
  /// 检查是否可以收集敏感数据
  bool canCollectData() {
    return canCollectSensitiveData;
  }
  
  /// 获取合规状态摘要
  Map<String, dynamic> getComplianceStatus() {
    return {
      'isPrivacyAgreed': isPrivacyAgreed,
      'isSdkInitialized': isSdkInitialized,
      'isInitializing': isInitializing,
      'canCollectSensitiveData': canCollectSensitiveData,
      'privacyVersion': _currentPrivacyVersion,
    };
  }
  
  /// 强制重新初始化SDK（用于测试）
  Future<void> reinitializeSdks() async {
    _isSdkInitialized.value = false;
    await initializeSdks();
  }
}
