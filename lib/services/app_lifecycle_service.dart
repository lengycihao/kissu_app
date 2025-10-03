import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:kissu_app/services/simple_location_service.dart';
import 'package:kissu_app/widgets/pag_animation_widget.dart';
import 'package:kissu_app/utils/pag_preloader.dart';
import 'package:kissu_app/network/interceptor/business_header_interceptor.dart';

/// 应用生命周期服务
class AppLifecycleService extends GetxService with WidgetsBindingObserver {
  static AppLifecycleService get instance => Get.find<AppLifecycleService>();
  
  // 应用状态
  final Rx<AppLifecycleState> appState = AppLifecycleState.resumed.obs;
  
  @override
  void onInit() {
    super.onInit();
    // 注册生命周期观察者
    WidgetsBinding.instance.addObserver(this);
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
    debugPrint('🔄 应用恢复前台，优化前台策略');
    
    // 🔧 修复：App恢复前台时清除网络信息缓存，避免使用过期数据
    try {
      BusinessHeaderInterceptor.clearNetworkCache();
      debugPrint('📡 已清除过期的网络信息缓存');
    } catch (e) {
      debugPrint('❌ 清除网络缓存失败: $e');
    }
    
    try {
      final simpleLocationService = SimpleLocationService.instance;
      if (simpleLocationService.isLocationEnabled.value) {
        // 应用回到前台，优化前台策略
        _optimizeForegroundStrategy();
        debugPrint('✅ 前台策略已优化');
      }
    } catch (e) {
      debugPrint('❌ 前台策略优化失败: $e');
    }
  }
  
  /// 应用进入后台
  void _onAppPaused() {
    debugPrint('📱 应用进入后台，启动增强后台策略');
    
    // 继续使用SimpleLocationService进行后台定位
    try {
      final simpleLocationService = SimpleLocationService.instance;
      if (!simpleLocationService.isLocationEnabled.value) {
        simpleLocationService.startLocation();
        debugPrint('✅ 启动后台定位服务');
      } else {
        debugPrint('ℹ️ 后台定位服务已在运行，继续定位');
      }
      
      // 确保后台增强策略已启动
      _ensureBackgroundStrategyActive();
    } catch (e) {
      debugPrint('❌ 后台定位服务失败: $e');
    }
  }
  
  /// 应用变为非活跃状态
  void _onAppInactive() {
    debugPrint('⏸️ 应用变为非活跃状态');
  }
  
  /// 应用被分离
  void _onAppDetached() {
    debugPrint('🔌 应用被分离');
    
    // 停止定位服务
    try {
      final simpleLocationService = SimpleLocationService.instance;
      if (simpleLocationService.isLocationEnabled.value) {
        simpleLocationService.stopLocation();
        debugPrint('✅ 已停止SimpleLocationService');
      } else {
        debugPrint('ℹ️ SimpleLocationService未运行，无需停止');
      }
    } catch (e) {
      debugPrint('❌ 停止定位服务失败: $e');
    }
    
    // 清理PAG动画资源，防止MediaCodec错误
    try {
      PagAnimationWidget.clearAllAssets();
      PagPreloader.clearCache();
      debugPrint('✅ 已清理PAG动画资源');
    } catch (e) {
      debugPrint('❌ 清理PAG动画资源失败: $e');
    }
  }
  
  /// 应用被隐藏
  void _onAppHidden() {
    debugPrint('👁️ 应用被隐藏');
    
    // 继续使用SimpleLocationService进行后台定位
    try {
      final simpleLocationService = SimpleLocationService.instance;
      if (!simpleLocationService.isLocationEnabled.value) {
        simpleLocationService.startLocation();
        debugPrint('✅ 启动隐藏状态定位服务');
      } else {
        debugPrint('ℹ️ 隐藏状态定位服务已在运行，继续定位');
      }
    } catch (e) {
      debugPrint('❌ 启动隐藏状态定位失败: $e');
    }
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
        debugPrint('✅ 根据应用状态启动定位服务: ${appState.value}');
      } else {
        debugPrint('ℹ️ 定位服务已在运行，当前应用状态: ${appState.value}');
      }
    } catch (e) {
      debugPrint('❌ 启动定位服务失败: $e');
    }
  }
  
  /// 停止定位服务
  void stopLocationService() {
    try {
      final simpleLocationService = SimpleLocationService.instance;
      if (simpleLocationService.isLocationEnabled.value) {
        simpleLocationService.stopLocation();
        debugPrint('✅ 停止定位服务');
      } else {
        debugPrint('ℹ️ 定位服务未运行，无需停止');
      }
    } catch (e) {
      debugPrint('❌ 停止定位服务失败: $e');
    }
  }
  
  /// 获取定位服务状态
  Map<String, dynamic> getLocationServiceStatus() {
    try {
      final simpleLocationService = SimpleLocationService.instance;
      return simpleLocationService.currentServiceStatus;
    } catch (e) {
      debugPrint('❌ 获取定位服务状态失败: $e');
      return {};
    }
  }
  
  /// 确保后台策略激活
  void _ensureBackgroundStrategyActive() {
    try {
      final simpleLocationService = SimpleLocationService.instance;
      simpleLocationService.ensureBackgroundStrategyActive();
      debugPrint('✅ 后台增强策略已确保激活');
    } catch (e) {
      debugPrint('❌ 激活后台策略失败: $e');
    }
  }
  
  /// 优化前台策略
  void _optimizeForegroundStrategy() {
    try {
      final simpleLocationService = SimpleLocationService.instance;
      simpleLocationService.optimizeForegroundStrategy();
      debugPrint('✅ 前台策略已优化');
    } catch (e) {
      debugPrint('❌ 优化前台策略失败: $e');
    }
  }
  
  /// 获取应用生命周期和定位服务的综合状态
  Map<String, dynamic> getComprehensiveStatus() {
    try {
      final simpleLocationService = SimpleLocationService.instance;
      return {
        'appState': appState.value.toString(),
        'isInForeground': isInForeground,
        'isInBackground': isInBackground,
        'locationService': simpleLocationService.serviceStatus,
        'locationCollection': simpleLocationService.getLocationCollectionStats(),
      };
    } catch (e) {
      debugPrint('❌ 获取综合状态失败: $e');
      return {};
    }
  }
  
  /// 打印应用生命周期和定位服务的综合状态
  void printComprehensiveStatus() {
    final status = getComprehensiveStatus();
    debugPrint('📊 应用生命周期和定位服务综合状态:');
    debugPrint('   应用状态: ${status['appState']}');
    debugPrint('   是否在前台: ${status['isInForeground']}');
    debugPrint('   是否在后台: ${status['isInBackground']}');
    debugPrint('   定位服务状态: ${status['locationService']['isLocationEnabled'] ? '运行中' : '已停止'}');
    debugPrint('   总采样点数: ${status['locationCollection']['totalLocationPoints']}');
    debugPrint('   待上报点数: ${status['locationCollection']['pendingReportPoints']}');
  }
}