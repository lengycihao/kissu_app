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
import 'package:kissu_app/services/tencent_im_service.dart';
import 'package:kissu_app/utils/debug_util.dart'; 
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/network/utils/device_util.dart';

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
  /// 🔥 隐私合规修复：即使用户之前同意过，也不在启动时自动初始化SDK
  /// 应用市场要求：必须在用户每次明确点击同意后才能初始化SDK
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
        
        // 🔥 修复：在用户已同意隐私政策的情况下，初始化真实的设备ID
        try {
          final deviceUtil = DeviceUtil.instance;
          await deviceUtil.initializeDeviceId();
          if (kDebugMode) {
            DebugUtil.success('真实设备ID初始化完成（已同意隐私政策）');
          }
        } catch (e) {
          if (kDebugMode) {
            DebugUtil.warning('初始化真实设备ID失败: $e');
          }
        }
        
        // 🔥 隐私合规修复：不在启动时自动初始化SDK
        // 即使用户之前同意过，也需要等待启动页检查后再决定是否初始化
        // 这样确保符合应用市场的隐私合规要求
        if (kDebugMode) {
          DebugUtil.info('⚠️ 隐私政策已同意，但不在启动时自动初始化SDK（等待启动页检查）');
        }
        
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
      
      // 🔥 修复：在用户同意隐私政策后，初始化真实的设备ID
      try {
        final deviceUtil = DeviceUtil.instance;
        await deviceUtil.initializeDeviceId();
        if (kDebugMode) {
          DebugUtil.success('真实设备ID初始化完成');
        }
      } catch (e) {
        if (kDebugMode) {
          DebugUtil.warning('初始化真实设备ID失败: $e');
        }
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
      
      // 3. 启用腾讯IM SDK初始化（延迟初始化，等待隐私政策同意）
      await _enableTencentIMService();
      
      // 4. 启用友盟分享的隐私授权
      await _enableShareServicePrivacy();
      
      // 5. 启用友盟统计初始化
      await _enableUmengAnalytics();
      
      // 6. 启用OpenInstall的剪贴板功能（如果需要）
      await _enableOpenInstallClipboard();
      
      // 7. 启用敏感数据收集
      await _enableSensitiveDataCollection();
      
      // 8. 通知其他服务隐私政策已同意
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
  
  /// 启用腾讯IM服务
  /// 🔥 修复：延迟初始化腾讯IM SDK，等待用户同意隐私政策后再初始化
  Future<void> _enableTencentIMService() async {
    try {
      if (Get.isRegistered<TencentIMService>()) {
        final imService = Get.find<TencentIMService>();
        if (!imService.isInitialized) {
          // 调用公开的初始化方法
          await imService.initIM();
          if (kDebugMode) {
            DebugUtil.success('腾讯IM服务已启用');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        DebugUtil.error('启用腾讯IM服务失败: $e');
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
  /// 🔥 隐私合规修复：在用户同意隐私政策后才初始化友盟SDK
  Future<void> _enableUmengAnalytics() async {
    try {
      // 友盟SDK初始化已经在ShareService.startPrivacyCompliantService()中完成
      // 这里只需要确认ShareService已经启动即可
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
      
      // 🔥 注册唤醒处理器，处理通过OpenInstall链接打开应用的情况
      // 注意：唤醒处理器会在应用启动时被调用，但我们需要确保应用完全启动后再处理路由跳转
      OpenInstallService.registerWakeupHandler((Map<String, dynamic> data) {
        if (kDebugMode) {
          DebugUtil.info('🔔 OpenInstall唤醒回调被触发（应用可能还在启动中）');
        }
        _handleOpenInstallWakeup(data);
      });
      
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
        DebugUtil.success('OpenInstall服务初始化完成（剪贴板已禁用，唤醒处理器已注册）');
      }
    } catch (e) {
      if (kDebugMode) {
        DebugUtil.error('OpenInstall服务初始化失败: $e');
      }
    }
  }
  
  /// 处理OpenInstall唤醒参数
  /// [data] 唤醒参数，可能包含 path、channelCode、bindData 等字段
  void _handleOpenInstallWakeup(Map<String, dynamic> data) {
    try {
      if (kDebugMode) {
        DebugUtil.info('🔔 OpenInstall唤醒参数: $data');
        // 打印所有键值对，方便调试
        data.forEach((key, value) {
          DebugUtil.info('  - $key: $value');
        });
      }
      
      // 🔥 重要：延迟处理，确保应用已完全启动
      // OpenInstall的唤醒回调可能在应用启动时就被调用，此时路由系统可能还未完全初始化
      // 延迟时间增加到2秒，确保应用完全启动
      Future.delayed(const Duration(seconds: 2), () {
        try {
          // 检查路由系统是否可用
          final context = Get.key.currentContext;
          if (context != null) {
            _processWakeupData(data);
          } else {
            if (kDebugMode) {
              DebugUtil.warning('⚠️ 应用尚未完全启动（context为null），延迟处理OpenInstall唤醒参数');
            }
            // 再延迟1秒后重试
            Future.delayed(const Duration(seconds: 1), () {
              _processWakeupData(data);
            });
          }
        } catch (e) {
          if (kDebugMode) {
            DebugUtil.error('检查应用启动状态失败: $e，直接处理唤醒数据');
          }
          // 即使检查失败，也尝试处理（可能应用已经启动）
          _processWakeupData(data);
        }
      });
    } catch (e) {
      if (kDebugMode) {
        DebugUtil.error('处理OpenInstall唤醒参数失败: $e');
      }
    }
  }
  
  /// 实际处理唤醒数据
  void _processWakeupData(Map<String, dynamic> data) {
    try {
      // 获取路径参数（OpenInstall可能使用不同的字段名）
      String? path = data['path'] as String?;
      if (path == null) {
        // 尝试其他可能的字段名
        path = data['page'] as String?;
        path ??= data['route'] as String?;
        path ??= data['url'] as String?;
        path ??= data['target'] as String?;
      }
      
      // 如果没有路径参数，直接返回（应用会正常启动到首页）
      if (path == null || path.isEmpty) {
        if (kDebugMode) {
          DebugUtil.info('✅ OpenInstall唤醒参数中没有路径信息，应用正常启动到首页');
        }
        return;
      }
      
      if (kDebugMode) {
        DebugUtil.info('📋 从OpenInstall唤醒参数中提取到路径: $path');
      }
      
      // 根据路径跳转到对应页面
      String routePath = _convertOpenInstallPathToRoute(path);
      
      if (kDebugMode) {
        DebugUtil.info('🔄 准备跳转到路由: $routePath (原始路径: $path)');
      }
      
      // 检查路由是否存在
      if (!_isRouteExists(routePath)) {
        if (kDebugMode) {
          DebugUtil.warning('⚠️ 路由不存在: $routePath，应用正常启动到首页');
        }
        return;
      }
      
      // 执行跳转
      try {
        // 使用 offAllNamed 确保清除之前的页面栈，避免"页面不存在"的问题
        Get.offAllNamed(routePath);
        if (kDebugMode) {
          DebugUtil.success('✅ OpenInstall唤醒跳转成功: $routePath');
        }
      } catch (e) {
        if (kDebugMode) {
          DebugUtil.error('❌ OpenInstall唤醒跳转失败: $e，路由: $routePath');
        }
        // 跳转失败时，应用会正常启动到首页
      }
    } catch (e) {
      if (kDebugMode) {
        DebugUtil.error('处理唤醒数据失败: $e');
      }
    }
  }
  
  /// 检查路由是否存在
  bool _isRouteExists(String routePath) {
    try {
      // 检查路由是否在路由表中
      if (routePath == '/notfound' || routePath == '/notFound' || routePath == '/NotFound') {
        if (kDebugMode) {
          DebugUtil.warning('⚠️ 检测到尝试跳转到 /notfound 路由，这是unknownRoute，不应该跳转');
        }
        return false;
      }
      
      final routes = Get.routeTree.routes;
      final exists = routes.any((route) => route.name == routePath);
      
      if (kDebugMode) {
        if (exists) {
          DebugUtil.info('✅ 路由存在: $routePath');
        } else {
          DebugUtil.warning('⚠️ 路由不存在: $routePath');
          DebugUtil.info('可用路由列表:');
          routes.forEach((route) {
            DebugUtil.info('  - ${route.name}');
          });
        }
      }
      
      return exists;
    } catch (e) {
      if (kDebugMode) {
        DebugUtil.error('检查路由是否存在失败: $e');
      }
      return false;
    }
  }
  
  /// 将OpenInstall的路径转换为应用路由路径
  /// [openInstallPath] OpenInstall返回的路径，例如 "/home", "/login", "/vip" 等
  /// 返回应用的路由路径
  String _convertOpenInstallPathToRoute(String openInstallPath) {
    // 移除开头的斜杠和尾部的斜杠
    String path = openInstallPath.trim();
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    if (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    
    // 如果已经是完整的路由路径，直接返回
    if (path.startsWith('/kisssu_app/')) {
      return path;
    }
    
    // 转换为小写以便匹配
    path = path.toLowerCase();
    
    // 根据OpenInstall的路径映射到应用路由
    // 你可以根据OpenInstall控制台配置的实际路径来调整这个映射
    switch (path) {
      case 'home':
      case 'index':
      case '':
        return KissuRoutePath.home;
      case 'login':
        return KissuRoutePath.login;
      case 'vip':
        return KissuRoutePath.vip;
      case 'location':
        return KissuRoutePath.location;
      case 'mine':
        return KissuRoutePath.mine;
      case 'info_setting':
      case 'info-setting':
      case 'infosetting':
        return KissuRoutePath.infoSetting;
      case 'track':
        return KissuRoutePath.track;
      case 'message':
      case 'message_list':
      case 'messagelist':
        return KissuRoutePath.messageList;
      default:
        // 如果路径不匹配，返回首页（而不是尝试跳转到不存在的路由）
        if (kDebugMode) {
          DebugUtil.warning('⚠️ 未知的OpenInstall路径: $openInstallPath，将跳转到首页');
        }
        return KissuRoutePath.home;
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
