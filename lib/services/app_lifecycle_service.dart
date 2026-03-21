import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/services/simple_location_service.dart';
import 'package:kissu_app/network/interceptor/business_header_interceptor.dart';
import 'package:kissu_app/services/permission_service.dart';
import 'package:kissu_app/services/sensitive_data_service.dart';
import 'package:kissu_app/services/tencent_im_service.dart';
import 'package:kissu_app/services/screen_lock_service.dart';
import 'package:kissu_app/services/version_service.dart';

/// 应用生命周期服务
class AppLifecycleService extends GetxService with WidgetsBindingObserver {
  static AppLifecycleService get instance => Get.find<AppLifecycleService>();
  
  // 应用状态
  final Rx<AppLifecycleState> appState = AppLifecycleState.resumed.obs;
  
  // 通知权限状态（用于监听变化）
  bool? _lastNotificationPermissionStatus;
  
  @override
  void onInit() {
    super.onInit();
    // 注册生命周期观察者
    WidgetsBinding.instance.addObserver(this);
    // 初始化通知权限状态
    _initNotificationPermissionStatus();
  }
  
  /// 初始化通知权限状态
  Future<void> _initNotificationPermissionStatus() async {
    try {
      final permissionService = PermissionService();
      _lastNotificationPermissionStatus = await permissionService.isNotificationPermissionGranted();
      debugPrint('📱 初始通知权限状态: $_lastNotificationPermissionStatus');
    } catch (e) {
      debugPrint('❌ 初始化通知权限状态失败: $e');
    }
  }
  
  @override
  void onClose() {
    // 移除生命周期观察者
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    appState.value = state;
    
    debugPrint('应用状态变化: $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
      case AppLifecycleState.inactive:
        _onAppInactive();
        break;
      case AppLifecycleState.detached:
        _onAppDetached();
        break;
      case AppLifecycleState.hidden:
        _onAppHidden();
        break;
    }
  }
  
  /// 应用恢复前台
  void _onAppResumed() {
    logger.debug('🔄 应用恢复前台，优化前台策略');
    
    // 🔧 修复：App恢复前台时清除网络信息缓存，避免使用过期数据
    try {
      BusinessHeaderInterceptor.clearNetworkCache();
      logger.debug('📡 已清除过期的网络信息缓存');
    } catch (e) {
      logger.error('❌ 清除网络缓存失败: $e');
    }
    
    // 🔧 修复：App恢复前台时清除电量缓存，确保获取最新电量
    try {
      BusinessHeaderInterceptor.clearBatteryCache();
      logger.debug('🔋 已清除过期的电量缓存');
    } catch (e) {
      logger.error('❌ 清除电量缓存失败: $e');
    }
    
    // 检查通知权限变化
    _checkNotificationPermissionChange();
    
    // 🔥 新增：检查并确保 IM 登录状态
    _ensureIMLoginStatus();
    
    // 🔥 新增：检查并确保锁屏监听服务正常运行
    _ensureScreenLockListening();
    
    // 🔥 新增：后台切回前台时检查版本更新
    _checkVersionUpdate();
    
    try {
      final simpleLocationService = SimpleLocationService.instance;
      if (simpleLocationService.isLocationEnabled.value) {
        // 应用回到前台，优化前台策略
        _optimizeForegroundStrategy();
        logger.debug('✅ 前台策略已优化');
      }
    } catch (e) {
      logger.error('❌ 前台策略优化失败: $e');
    }
  }
  
  /// 🔥 新增：确保 IM 登录状态
  Future<void> _ensureIMLoginStatus() async {
    try {
      if (Get.isRegistered<TencentIMService>()) {
        final imService = Get.find<TencentIMService>();
        await imService.ensureIMLoginStatus();
      }
    } catch (e) {
      logger.error('❌ 检查IM登录状态失败: $e');
    }
  }
  
  /// 🔥 新增：确保锁屏监听服务正常运行
  void _ensureScreenLockListening() {
    try {
      if (Get.isRegistered<ScreenLockService>()) {
        final screenLockService = Get.find<ScreenLockService>();
        final status = screenLockService.getServiceStatus();
        
        // 如果服务未初始化或订阅已丢失，重新启动监听
        if (status['isInitialized'] != true || status['hasSubscription'] != true) {
          logger.debug('🔒 锁屏监听服务状态异常，尝试重新启动...');
          screenLockService.startListening();
        } else {
          logger.debug('🔒 锁屏监听服务运行正常');
        }
      }
    } catch (e) {
      logger.error('❌ 检查锁屏监听服务失败: $e');
    }
  }
  
  /// 检查通知权限变化
  Future<void> _checkNotificationPermissionChange() async {
    try {
      final permissionService = PermissionService();
      final currentStatus = await permissionService.isNotificationPermissionGranted();
      
      // 如果是第一次检查，只记录状态
      if (_lastNotificationPermissionStatus == null) {
        _lastNotificationPermissionStatus = currentStatus;
        logger.debug('📱 首次检查通知权限: $currentStatus');
        return;
      }
      
      // 检查是否发生变化
      if (_lastNotificationPermissionStatus != currentStatus) {
        logger.debug('📱 通知权限发生变化: $_lastNotificationPermissionStatus -> $currentStatus');
        
        // 上报权限变化事件
        final sensitiveDataService = SensitiveDataService.instance;
        if (currentStatus) {
          // 用户开启了通知权限
          await sensitiveDataService.reportNotificationEnabled();
        } else {
          // 用户关闭了通知权限
          await sensitiveDataService.reportNotificationDisabled();
        }
        
        // 更新状态
        _lastNotificationPermissionStatus = currentStatus;
      } else {
        logger.debug('📱 通知权限无变化: $currentStatus');
      }
    } catch (e) {
      logger.error('❌ 检查通知权限变化失败: $e');
    }
  }
  
  /// 应用进入后台
  void _onAppPaused() {
    logger.debug('📱 应用进入后台，启动增强后台策略');
    
    // 继续使用SimpleLocationService进行后台定位
    try {
      final simpleLocationService = SimpleLocationService.instance;
      if (!simpleLocationService.isLocationEnabled.value) {
        simpleLocationService.startLocation();
        logger.debug('✅ 启动后台定位服务');
      } else {
        logger.debug('ℹ️ 后台定位服务已在运行，继续定位');
      }
      
      // 确保后台增强策略已启动
      _ensureBackgroundStrategyActive();
    } catch (e) {
      logger.error('❌ 后台定位服务失败: $e');
    }
  }
  
  /// 应用变为非活跃状态
  void _onAppInactive() {
    logger.debug('⏸️ 应用变为非活跃状态');
  }
  
  /// 应用被分离
  void _onAppDetached() {
    logger.debug('🔌 应用被分离');
    
    // 停止定位服务
    try {
      final simpleLocationService = SimpleLocationService.instance;
      if (simpleLocationService.isLocationEnabled.value) {
        simpleLocationService.stopLocation();
        logger.debug('✅ 已停止SimpleLocationService');
      } else {
        logger.debug('ℹ️ SimpleLocationService未运行，无需停止');
      }
    } catch (e) {
      logger.error('❌ 停止定位服务失败: $e');
    }
  }
  
  /// 应用被隐藏
  void _onAppHidden() {
    logger.debug('👁️ 应用被隐藏');
    
    // 🔧 修复：hidden状态下不重复启动后台策略
    // 因为 paused 状态已经启动了后台策略
    // 避免重复调用导致通知频繁弹出
    logger.debug('ℹ️ 应用已隐藏，后台策略应该已在paused状态启动');
  }
  
  /// 获取当前应用状态
  AppLifecycleState get currentAppState => appState.value;
  
  /// 检查是否在后台
  bool get isInBackground => 
      appState.value == AppLifecycleState.paused || 
      appState.value == AppLifecycleState.hidden;
  
  /// 检查是否在前台
  bool get isInForeground => appState.value == AppLifecycleState.resumed;
  
  /// 启动定位服务（根据当前应用状态）
  Future<void> startLocationServiceIfNeeded() async {
    try {
      final simpleLocationService = SimpleLocationService.instance;
      if (!simpleLocationService.isLocationEnabled.value) {
        await simpleLocationService.startLocation();
        logger.debug('✅ 根据应用状态启动定位服务: ${appState.value}');
      } else {
        logger.debug('ℹ️ 定位服务已在运行，当前应用状态: ${appState.value}');
      }
    } catch (e) {
      logger.error('❌ 启动定位服务失败: $e');
    }
  }
  
  /// 停止定位服务
  void stopLocationService() {
    try {
      final simpleLocationService = SimpleLocationService.instance;
      if (simpleLocationService.isLocationEnabled.value) {
        simpleLocationService.stopLocation();
        logger.debug('✅ 停止定位服务');
      } else {
        logger.debug('ℹ️ 定位服务未运行，无需停止');
      }
    } catch (e) {
      logger.error('❌ 停止定位服务失败: $e');
    }
  }
  
  /// 获取定位服务状态
  // Map<String, dynamic> getLocationServiceStatus() {
  //   try {
  //     final simpleLocationService = SimpleLocationService.instance;
  //     return simpleLocationService.currentServiceStatus;
  //   } catch (e) {
  //     debugPrint('❌ 获取定位服务状态失败: $e');
  //     return {};
  //   }
  // }
  
  /// 确保后台策略激活
  void _ensureBackgroundStrategyActive() {
    try {
      final simpleLocationService = SimpleLocationService.instance;
      simpleLocationService.ensureBackgroundStrategyActive();
      logger.debug('✅ 后台增强策略已确保激活');
    } catch (e) {
      logger.error('❌ 激活后台策略失败: $e');
    }
  }
  
  /// 🔥 新增：后台切回前台时检查版本更新
  Future<void> _checkVersionUpdate() async {
    try {
      if (Get.isRegistered<VersionService>()) {
        final versionService = Get.find<VersionService>();
        await versionService.checkVersionOnResume();
      }
    } catch (e) {
      logger.error('❌ 前台恢复版本检查失败: $e');
    }
  }
  
  /// 优化前台策略
  void _optimizeForegroundStrategy() {
    try {
      final simpleLocationService = SimpleLocationService.instance;
      simpleLocationService.optimizeForegroundStrategy();
      logger.debug('✅ 前台策略已优化');
    } catch (e) {
      logger.error('❌ 优化前台策略失败: $e');
    }
  }
  
  /// 获取应用生命周期和定位服务的综合状态
  // Map<String, dynamic> getComprehensiveStatus() {
  //   try {
  //     final simpleLocationService = SimpleLocationService.instance;
  //     return {
  //       'appState': appState.value.toString(),
  //       'isInForeground': isInForeground,
  //       'isInBackground': isInBackground,
  //       'locationService': simpleLocationService.serviceStatus,
  //       'locationCollection': simpleLocationService.getLocationCollectionStats(),
  //     };
  //   } catch (e) {
  //     debugPrint('❌ 获取综合状态失败: $e');
  //     return {};
  //   }
  // }
  
  /// 打印应用生命周期和定位服务的综合状态
  // void printComprehensiveStatus() {
  //   final status = getComprehensiveStatus();
  //   debugPrint('📊 应用生命周期和定位服务综合状态:');
  //   debugPrint('   应用状态: ${status['appState']}');
  //   debugPrint('   是否在前台: ${status['isInForeground']}');
  //   debugPrint('   是否在后台: ${status['isInBackground']}');
  //   debugPrint('   定位服务状态: ${status['locationService']['isLocationEnabled'] ? '运行中' : '已停止'}');
  //   debugPrint('   总采样点数: ${status['locationCollection']['totalLocationPoints']}');
  //   debugPrint('   待上报点数: ${status['locationCollection']['pendingReportPoints']}');
  // }
}