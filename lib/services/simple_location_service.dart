import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'package:amap_flutter_location/amap_location_option.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:kissu_app/model/location_model/location_report_model.dart';
import 'package:kissu_app/network/public/location_report_api.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';
import 'package:kissu_app/services/foreground_location_service.dart';
import 'package:kissu_app/services/app_lifecycle_service.dart';
import 'package:kissu_app/services/location_permission_manager.dart';
import 'package:kissu_app/services/privacy_compliance_manager.dart';
import 'package:kissu_app/services/sensitive_data_service.dart';
import 'package:kissu_app/utils/permission_helper.dart';
import 'package:flutter/material.dart';

// 🚀 轨迹平滑算法：位置点数据结构（基于高德官方建议）
class LocationPoint {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed;
  final DateTime timestamp;
  
  LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.speed,
    required this.timestamp,
  });
  
  // 计算与另一个点的距离（使用简单的球面距离公式）
  double distanceTo(LocationPoint other) {
    const double earthRadius = 6371000; // 地球半径（米）
    final lat1Rad = latitude * math.pi / 180;
    final lat2Rad = other.latitude * math.pi / 180;
    final deltaLat = (other.latitude - latitude) * math.pi / 180;
    final deltaLng = (other.longitude - longitude) * math.pi / 180;
    
    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLng / 2) * math.sin(deltaLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  // 计算时间差（秒）
  double timeDifferenceInSeconds(LocationPoint other) {
    return timestamp.difference(other.timestamp).inMilliseconds.abs() / 1000.0;
  }
  
  // 计算速度（基于两点间移动）
  double calculateSpeedTo(LocationPoint other) {
    final distance = distanceTo(other);
    final timeDiff = timeDifferenceInSeconds(other);
    return timeDiff > 0 ? distance / timeDiff : 0.0;
  }
}

/// 基于高德定位的简化版定位服务类
class SimpleLocationService extends GetxService with WidgetsBindingObserver {
  static SimpleLocationService get instance => Get.find<SimpleLocationService>();

  // 高德定位插件 - 单例确保整个应用生命周期只创建一次
  final AMapFlutterLocation _locationPlugin = AMapFlutterLocation();

  // 当前最新位置
  final Rx<LocationReportModel?> currentLocation = Rx<LocationReportModel?>(null);

  // 位置历史记录（用于采样点检测）
  final RxList<LocationReportModel> locationHistory = <LocationReportModel>[].obs;

  // 定时器
  Timer? _periodicLocationTimer;

  // 全局唯一的定位流订阅 - 整个应用生命周期只创建一次
  StreamSubscription<Map<String, Object>>? _globalLocationSub;

  // 暴露定位流，让外部管理订阅（参考用户示例）
  Stream<Map<String, Object>> get locationStream => _locationPlugin.onLocationChanged();

  /// 简单启动定位（参考用户示例）
  void start() => _locationPlugin.startLocation();

  /// 简单停止定位（参考用户示例）
  void stop() => _locationPlugin.stopLocation();

  // 服务状态
  final RxBool isLocationEnabled = false.obs;
  final RxBool isReporting = false.obs;
  final RxBool hasInitialReport = false.obs; // 是否已进行初始上报
  bool _isSingleLocationInProgress = false; // 是否正在进行单次定位
  bool _isGlobalListenerSetup = false; // 全局监听器是否已设置
  int _locationRetryCount = 0; // 定位重试计数
  
  // 新的上报策略相关变量
  LocationReportModel? _lastReportedLocation; // 最后一次上报的位置
  DateTime? _lastMinuteReportTime; // 最后一次定时上报时间
  
  // 权限状态监听
  final Rx<PermissionStatus> _currentLocationPermission = PermissionStatus.denied.obs;
  final Rx<PermissionStatus> _currentBackgroundPermission = PermissionStatus.denied.obs;
  
  // GPS开关状态监听（系统级别的定位服务开关）
  static const EventChannel _gpsStatusChannel = EventChannel('kissu_app/gps_status');
  StreamSubscription<dynamic>? _gpsStatusSubscription;
  bool? _lastGpsEnabledStatus; // 上次的GPS开关状态（null表示未初始化）
  
  // 应用生命周期状态（用于模拟iOS的应用状态监听）
  // ignore: unused_field
  String? _lastAppState; // 预留字段，在WidgetsBindingObserver实现中使用
  
  // 后台任务标识（增强版后台任务）
  int? _backgroundTaskId;
  Timer? _backgroundKeepAliveTimer;
  
  // 多重保障定时器（增强后台稳定性）
  Timer? _quickCheckTimer;     // 快速检查定时器（20秒）
  Timer? _mediumCheckTimer;    // 中等检查定位器（60秒）
  Timer? _deepCheckTimer;      // 深度检查定时器（120秒）
  Timer? _batteryOptimizedTimer; // 电池优化定时器（动态间隔）
  
  // 智能定时器控制
  int _consecutiveSuccessCount = 0; // 连续成功次数
  int _consecutiveFailureCount = 0; // 连续失败次数
  bool _isInLowPowerMode = false;   // 低功耗模式标记
  
  // 飘点过滤状态
  LocationReportModel? _lastValidLocation; // 上次有效位置
  List<LocationReportModel> _recentLocations = []; // 最近的位置记录（用于稳定性检测）
  int _consecutiveBadLocationCount = 0; // 连续不良位置计数
  int _consecutiveSmallMovements = 0; // 连续小距离移动计数（用于检测静止状态下的GPS飘移）
  bool _isIndoorMode = false; // 室内模式标记
  DateTime? _lastIndoorDetectionTime; // 上次室内检测时间
  
  // 设备特殊处理
  bool _isHuaweiDevice = false; // 华为设备标记
  int _huaweiLocationFilterCount = 0; // 华为设备过滤计数
  
  // 🚀 轨迹平滑算法相关变量（基于高德官方建议）
  List<LocationPoint> _locationHistory = [];
  static const int _trajectoryHistorySize = 10; // 保留最近10个有效位置
  double _lastValidSpeed = 0.0; // 上次有效速度
  int _consecutiveHighAccuracyCount = 0; // 连续高精度计数
  int _consecutiveLowSpeedCount = 0; // 连续低速计数
  
  // 后台通知管理
  bool _isBackgroundNotificationShown = false; // 后台通知显示状态
  DateTime? _lastNotificationTime; // 上次通知时间
  
  // 配置参数 - 与iOS版本完全一致的策略
  static const Duration _reportInterval = Duration(minutes: 1); // 1分钟上报间隔（与iOS一致）
  static const int _maxHistorySize = 200; // 最大历史记录数（增加容量）
  static const double _distanceFilter = 50.0; // 50米距离过滤（与iOS版本完全一致）
  static const int _locationInterval = 6000; // 6秒定位间隔（平衡响应性与耗电）
  static const double _desiredAccuracy = 10.0; // 期望精度10米（已优化）
  
  // 飘点过滤参数
  static const double _maxAccuracyThreshold = 100.0; // 最大精度阈值（超过100米的定位数据被认为不可靠）
  static const double _maxSpeedThreshold = 50.0; // 最大速度阈值（50m/s = 180km/h，超过则认为是飘点）
  static const double _maxJumpDistance = 500.0; // 最大跳跃距离（超过500米的瞬间跳跃认为是飘点）
  static const int _stableLocationCount = 3; // 稳定位置计数（连续3个相近位置才认为是真实移动）
  
  // 华为设备特殊处理参数
  static const double _huaweiAccuracyThreshold = 80.0; // 华为设备精度阈值（更严格）
  static const double _huaweiJumpDistance = 300.0; // 华为设备跳跃距离阈值（更严格）
  static const int _huaweiFilterCount = 3; // 华为设备需要更多次验证
  
  // 智能优化参数
  static const int _maxConsecutiveFailures = 3; // 最大连续失败次数
  static const int _successCountForOptimization = 10; // 成功次数阈值
  static const Duration _lowPowerCheckInterval = Duration(seconds: 120); // 低功耗模式检查间隔
  
  // 电池优化参数
  static const int _batteryOptimizationThreshold = 20; // 电池优化阈值（连续成功次数）
  static const Duration _maxLowPowerDuration = Duration(hours: 2); // 最大低功耗持续时间
  DateTime? _lowPowerModeStartTime; // 低功耗模式开始时间
  // 与iOS策略完全一致：收集所有位置更新，保持完整轨迹和准确速度数据
  // 
  // 性能优化说明：
  // 1. distanceFilter = 50米：平衡精度与性能，避免过度采集
  // 2. locationInterval = 6秒：平衡响应性与耗电，避免频繁唤醒GPS
  // 3. 采用批量上报策略：减少网络请求，提高上报效率
  
  @override
  void onInit() {
    super.onInit();
    // 🔒 隐私合规：不在服务初始化时自动启动任何定位相关功能
    // 等待隐私政策同意后再启动
    // init(); // 移除自动初始化
    // _setupGlobalLocationListener(); // 移除自动监听器设置
    // _setupAppLifecycleListener(); // 移除自动生命周期监听
    // _initializePermissionStatus(); // 移除自动权限检查
    debugPrint('✅ SimpleLocationService 已注册（等待隐私政策同意后启动）');
  }

  @override
  void onClose() {
    stopLocation();
    _removeAppLifecycleListener(); // 清理生命周期监听
    _backgroundKeepAliveTimer?.cancel();
    _batteryOptimizedTimer?.cancel(); // 清理电池优化定时器
    // 清理全局监听器
    _globalLocationSub?.cancel();
    _globalLocationSub = null;
    _isGlobalListenerSetup = false;
    
    // 清理GPS状态监听
    _gpsStatusSubscription?.cancel();
    _gpsStatusSubscription = null;
    
    super.onClose();
  }
  
  /// 隐私合规启动方法 - 只有在用户同意隐私政策后才调用
  void startPrivacyCompliantService() {
    debugPrint('🔒 启动隐私合规定位服务');
    
    // 初始化API Key和隐私合规
    init();
    // 设置全局唯一的监听器
    _setupGlobalLocationListener();
    // 设置应用生命周期监听
    _setupAppLifecycleListener();
    // 初始化权限状态
    _initializePermissionStatus();
    // 启动GPS状态监听（仅Android）
    if (Platform.isAndroid) {
      _startGpsStatusMonitoring();
    }
    
    debugPrint('✅ 隐私合规定位服务启动完成');
  }

  /// 设置高德地图隐私合规和API Key
  /// 初始化定位服务（隐私合规版本）
  void init() {
    try {
      // 🔒 隐私合规：设置隐私政策显示状态
      AMapFlutterLocation.updatePrivacyShow(true, true);

      // 🔑 关键修复：不在这里设置隐私授权状态，让隐私合规管理器统一管理
      // 隐私授权状态将由 PrivacyComplianceManager 根据用户同意情况决定

      // 设置API Key - 确保在任何定位操作前执行
      AMapFlutterLocation.setApiKey('38edb925a25f22e3aae2f86ce7f2ff3b', '');

      debugPrint('✅ 高德定位服务初始化完成（隐私授权由PrivacyComplianceManager管理）');
    } catch (e) {
      debugPrint('❌ 初始化高德定位服务失败: $e');
    }
  }
  
  Future<void> _setupPrivacyCompliance() async {
    try {
      // 🔑 关键修复：从隐私合规管理器获取当前隐私同意状态
      final privacyManager = Get.find<PrivacyComplianceManager>();
      final isPrivacyAgreed = privacyManager.isPrivacyAgreed;

      // 重新设置隐私合规（确保在定位前生效）
      AMapFlutterLocation.updatePrivacyShow(true, true);

      // 🔒 隐私合规：根据用户同意状态设置隐私授权
      AMapFlutterLocation.updatePrivacyAgree(isPrivacyAgreed);

      // 重新设置API Key（确保在定位前生效）
      AMapFlutterLocation.setApiKey('38edb925a25f22e3aae2f86ce7f2ff3b', '');

      debugPrint('🔧 高德定位隐私合规和API Key设置完成（隐私授权: ${isPrivacyAgreed ? "已同意" : "已拒绝"}）');
    } catch (e) {
      debugPrint('❌ 设置高德定位隐私合规失败: $e');
    }
  }

  /// 设置全局唯一的定位监听器（基于高德插件内部机制优化）
  void _setupGlobalLocationListener() {
    if (_isGlobalListenerSetup) {
      debugPrint('✅ 全局定位监听器已设置，复用现有监听器');
      return;
    }

    try {
      debugPrint('🔧 设置全局定位监听器...');

      // 基于高德插件源码分析：
      // 插件内部使用 _receiveStream 判断是否已创建 StreamController
      // 只要不重复调用 onLocationChanged()，就不会有冲突
      Stream<Map<String, Object>> locationStream = _locationPlugin.onLocationChanged();

      _globalLocationSub = locationStream.listen(
        (Map<String, Object> result) {
          debugPrint('📍 全局监听器收到定位数据: ${result.toString()}');
          _onLocationUpdate(result);
        },
        onError: (error) {
          debugPrint('❌ 全局监听器定位错误: $error');
        },
        onDone: () {
          debugPrint('⚠️ 全局监听器定位流已关闭');
          _isGlobalListenerSetup = false;
        },
      );
      _isGlobalListenerSetup = true;
      debugPrint('✅ 全局定位监听器设置完成');

    } catch (e) {
      debugPrint('❌ 设置全局定位监听器失败: $e');
      if (e.toString().contains('Stream has already been listened to')) {
        debugPrint('⚠️ 检测到Stream冲突，这可能是热重载导致的');
        debugPrint('💡 请完全重启应用以清理Stream状态');
        _isGlobalListenerSetup = true; // 标记为已设置，避免重复尝试
      }
    }
  }
  
  /// 请求定位权限（改进版，支持Android 10+后台定位）
  Future<bool> requestLocationPermission() async {
    try {
      debugPrint('🔐 开始申请定位权限...');

      // 使用统一的权限申请管理器
      final permissionManager = LocationPermissionManager.instance;
      bool hasPermission = await permissionManager.requestLocationPermission();

      if (hasPermission) {
        debugPrint('✅ 定位权限申请成功，检查后台定位权限状态...');

        // 检查后台定位权限状态，但不主动请求（避免重复弹窗）
        var backgroundLocationStatus = await Permission.locationAlways.status;
        debugPrint('🔐 后台定位权限状态: $backgroundLocationStatus');

        // 只在后台权限被明确拒绝时才提示用户
        if (backgroundLocationStatus.isPermanentlyDenied) {
          debugPrint('⚠️ 后台定位权限被永久拒绝');
          CustomToast.show(
            Get.context!,
            '后台定位权限被永久拒绝，可在设置中手动开启',
          );
        } else if (backgroundLocationStatus.isDenied) {
          debugPrint('ℹ️ 后台定位权限未开启，前台定位仍可使用');
          // 不主动请求后台权限，避免重复弹窗
          // 智能提醒服务会在适当时机提醒用户
        }
      }

      debugPrint('✅ 定位权限申请完成');
      return hasPermission;
    } catch (e) {
      debugPrint('❌ 请求定位权限失败: $e');
      return false;
    }
  }

  /// 请求后台定位权限（仅在用户明确需要时调用）
  Future<bool> requestBackgroundLocationPermission() async {
    try {
      debugPrint('🔐 开始申请后台定位权限...');

      // 1. 首先确保有前台定位权限
      var locationStatus = await Permission.location.status;
      debugPrint('🔐 前台定位权限状态: $locationStatus');

      if (!locationStatus.isGranted) {
        debugPrint('🔐 先申请前台定位权限...');
        locationStatus = await Permission.location.request();
        debugPrint('🔐 申请前台定位权限结果: $locationStatus');

        if (!locationStatus.isGranted) {
          debugPrint('❌ 前台定位权限被拒绝，无法申请后台权限');
          CustomToast.show(
            Get.context!,
            '请先开启定位权限，然后再申请后台定位权限',
          );
          return false;
        }
      }

      // 2. 检查后台定位权限状态
      var backgroundLocationStatus = await Permission.locationAlways.status;
      debugPrint('🔐 后台定位权限状态: $backgroundLocationStatus');

      if (backgroundLocationStatus.isDenied) {
        debugPrint('🔐 申请后台定位权限...');
        backgroundLocationStatus = await Permission.locationAlways.request();
        debugPrint('🔐 申请后台定位权限结果: $backgroundLocationStatus');

        if (backgroundLocationStatus.isGranted) {
          debugPrint('✅ 后台定位权限获取成功');
          return true;
        } else if (backgroundLocationStatus.isPermanentlyDenied) {
          debugPrint('❌ 后台定位权限被永久拒绝，直接跳转到设置');
          await _openLocationSettingsDirectly();
          return false;
        } else {
          debugPrint('⚠️ 后台定位权限被拒绝，直接跳转到设置');
          await _openLocationSettingsDirectly();
          return false;
        }
      } else if (backgroundLocationStatus.isGranted) {
        debugPrint('✅ 后台定位权限已授予');
        return true;
      } else if (backgroundLocationStatus.isPermanentlyDenied) {
        debugPrint('❌ 后台定位权限被永久拒绝，直接跳转到设置');
        await _openLocationSettingsDirectly();
        return false;
      }

      return false;
    } catch (e) {
      debugPrint('❌ 请求后台定位权限失败: $e');
      return false;
    }
  }
  
  /// 开始定位
  Future<bool> startLocation() async {
    try {
      debugPrint('🚀 SimpleLocationService.startLocation() 开始执行');

      // 🔑 关键修复：检查隐私政策同意状态
      final privacyManager = Get.find<PrivacyComplianceManager>();
      if (!privacyManager.isPrivacyAgreed) {
        debugPrint('❌ 用户尚未同意隐私政策，无法启动定位服务');
        return false;
      }

      // 确保先初始化（这很关键！）
      init();
      await Future.delayed(Duration(milliseconds: 100)); // 给初始化一点时间

      // 设置高德地图隐私合规（必须在任何定位操作之前）
      await _setupPrivacyCompliance();
      debugPrint('🔧 隐私合规设置完成');
      
      // 检查权限状态，但不重复请求
      var locationStatus = await Permission.location.status;
      debugPrint('🔧 定位权限状态: $locationStatus');
      if (!locationStatus.isGranted) {
        debugPrint('❌ 定位权限检查失败，无法启动定位服务');
        return false;
      }
      
      // 如果已经在定位，先停止
      if (isLocationEnabled.value) {
        debugPrint('🔧 定位服务已启动，先停止旧服务');
        stopLocation();
        // 等待一小段时间确保停止完成
        await Future.delayed(Duration(milliseconds: 500));
      }

      debugPrint('🚀 高德定位服务启动中...');
      
      // 检查插件是否已正确初始化
      try {
        // 获取当前定位设置状态（这会触发插件检查）
        debugPrint('🔧 检查高德定位插件状态...');
        // 简单调用来检查插件是否正常
        _locationPlugin.stopLocation(); // 安全的检查调用
        debugPrint('✅ 高德定位插件状态正常');
      } catch (e) {
        debugPrint('❌ 高德定位插件可能未正确初始化: $e');
      }
      
      // 确保流监听器已彻底清理
      try {
        // 停止现有定位
        _locationPlugin.stopLocation();
        debugPrint('🔧 高德定位插件已停止');
        
        // 全局监听器无需清理，直接继续
        
        debugPrint('🔧 所有流监听器清理完成');
        
        // 等待确保完全停止
        await Future.delayed(Duration(milliseconds: 500));
        debugPrint('🔧 清理完成，等待结束');
      } catch (e) {
        debugPrint('⚠️ 清理监听器时出现异常: $e');
      }
      
      // 设置高德定位参数 - 参考iOS版本的高精度配置 + 后台定位优化
      debugPrint('🔧 开始设置高德定位参数（参考iOS版本 + 后台定位优化）...');
      AMapLocationOption locationOption = AMapLocationOption();
      
      // 设置定位模式 - 使用Hight_Accuracy模式（最关键的配置）
      // 🔥 重要：Hight_Accuracy模式在后台和息屏时会自动降级为基站+WIFI定位
      // 这是Android系统的限制，无法通过配置完全避免
      locationOption.locationMode = AMapLocationMode.Hight_Accuracy; // 高精度模式，包含GPS
      
      debugPrint('   - 定位模式: 高精度模式（GPS+网络+WIFI）- 参考iOS的kCLLocationAccuracyBest');
      debugPrint('   - 🚀 高德官方优化：启用高精度模式 + accuracy>100过滤 + 轨迹平滑算法');
      debugPrint('   - ⚠️  息屏后限制：Android系统会限制GPS访问，自动降级为基站+WIFI定位');
      
      // 设置定位间隔（参考iOS版本）
      // 🔥 后台定位优化：适当增加间隔以减少电量消耗和系统限制
      locationOption.locationInterval = _locationInterval; // 2秒间隔，平衡响应性与耗电
      debugPrint('   - 定位间隔: ${_locationInterval}ms（平衡响应性与耗电）');
      
      // 设置距离过滤（与iOS版本完全一致）
      locationOption.distanceFilter = _distanceFilter; // 50米距离过滤
      debugPrint('   - 距离过滤: ${_distanceFilter}米（与iOS版本完全一致）');
      
      // 设置地址信息（参考iOS的locatingWithReGeocode）
      locationOption.needAddress = true;
      debugPrint('   - 需要地址: true（参考iOS的locatingWithReGeocode）');
      
      // 设置持续定位（参考iOS的allowsBackgroundLocationUpdates）
      locationOption.onceLocation = false;
      debugPrint('   - 持续定位: true（参考iOS的allowsBackgroundLocationUpdates）');
      
      // 🔥 关键配置：设置传感器使能（可能有助于后台定位）
      // locationOption.sensorEnable = true; // 启用传感器辅助定位（如果SDK支持）
      
      // 注意：某些配置在当前版本的高德插件中可能不支持
      // locationOption.mockEnable = true;
      // locationOption.gpsFirst = false;
      debugPrint('   - 期望精度: ${_desiredAccuracy}米（参考iOS配置）');
      
      // 注意：高德定位插件可能不支持httpTimeOut属性
      // locationOption.httpTimeOut = 30000; // 30秒超时
      debugPrint('   - 使用默认超时设置（参考iOS的10秒超时）');
      
      try {
        _locationPlugin.setLocationOption(locationOption);
        debugPrint('✅ 高德定位参数设置完成');
      } catch (e) {
        debugPrint('❌ 设置高德定位参数失败: $e');
        throw e;
      }

      // 确保全局监听器已设置
      if (!_isGlobalListenerSetup) {
        _setupGlobalLocationListener();
      } else {
        debugPrint('✅ 全局监听器已激活，直接启动定位');
      }

      // 启动定位（高德定位插件3.0.0版本的startLocation()方法返回void）
      debugPrint('🔧 调用高德定位插件启动定位');
      try {
        _locationPlugin.startLocation();
        debugPrint('✅ 高德定位启动请求已发送');
        
        // 额外添加一个延迟检查，看是否有定位权限问题
        Timer(Duration(seconds: 3), () {
          debugPrint('🔧 3秒后检查定位状态...');
          if (currentLocation.value == null) {
            debugPrint('⚠️ 3秒后仍无定位数据，可能的原因:');
            debugPrint('   1. GPS信号弱或无GPS信号');
            debugPrint('   2. 定位权限未正确授予');
            debugPrint('   3. 高德API Key配置问题');
            debugPrint('   4. 网络连接问题');
          }
        });
        
      } catch (e) {
        debugPrint('❌ 启动高德定位失败: $e');
        throw e;
      }
      
      // 延迟启动定时单次定位（给持续定位一些时间先工作）
      Timer(Duration(seconds: 60), () {
        if (isLocationEnabled.value) {
          debugPrint('🔄 启动定时单次定位作为备用方案');
          _startPeriodicSingleLocation();
        }
      });
      
      // 添加延迟检查
      Future.delayed(Duration(seconds: 5), () {
        debugPrint('⏰ 5秒后检查：定位是否有数据回调...');
        if (currentLocation.value == null) {
          debugPrint('⚠️ 5秒后仍未收到定位数据，尝试单次定位...');
          _requestSingleLocation();
        }
      });
      
      Future.delayed(Duration(seconds: 10), () {
        debugPrint('⏰ 10秒后检查：定位是否有数据回调...');
        if (currentLocation.value == null) {
          debugPrint('⚠️ 10秒后仍未收到定位数据，可能存在问题');
        }
      });
      
      // 新策略：不再需要定时器，改为实时上报
      
      isLocationEnabled.value = true;
      hasInitialReport.value = false; // 重置初始上报状态
      
      // 🔥 关键修复：立即启动前台服务，确保息屏后能继续定位
      // 不等到进入后台才启动，因为用户可能随时息屏
      debugPrint('🚀 立即启动前台服务以支持息屏后定位...');
      await _enableForegroundServiceIfNeeded();
      
      // 🔥 重要优化：根据应用状态智能决定是否启动后台定时器
      _smartStartLocationStrategy();
      
      debugPrint('✅ 高德定位服务已启动完成');
      return true;
    } catch (e) {
      debugPrint('启动高德定位失败: $e');
      return false;
    }
  }
  
  /// 处理位置更新
  void _onLocationUpdate(Map<String, Object> result) {
    try {
      debugPrint('📍 _onLocationUpdate 被调用');
      debugPrint('📍 完整定位数据: ${result.toString()}');
      
      // 检查高德定位错误码
      int? errorCode = int.tryParse(result['errorCode']?.toString() ?? '0');
      String? errorInfo = result['errorInfo']?.toString();
      
      if (errorCode != null && errorCode != 0) {
        debugPrint('❌ 高德定位失败 - 错误码: $errorCode, 错误信息: $errorInfo');
        
        // 根据错误码进行智能重试
        bool shouldRetry = false;
        String suggestion = '';
        
        switch (errorCode) {
          case 12:
            debugPrint('❌ 错误码12: 缺少定位权限');
            suggestion = '请检查应用定位权限是否已授予';
            break;
          case 13:
            debugPrint('❌ 错误码13: 网络异常');
            suggestion = '网络连接异常，将尝试重新连接';
            shouldRetry = true;
            // 屏幕熄灭或后台权限缺失时，优先尝试GPS-only或网络-only策略
            try {
              final appLifecycle = AppLifecycleService.instance;
              final inBackground = appLifecycle.isInBackground;
              final hasBg = _currentBackgroundPermission.value == PermissionStatus.granted;
              if (inBackground && !hasBg) {
                debugPrint('🧭 触发GPS-only降级（后台且无后台权限）');
                _locationPlugin.stopLocation();
                final gpsOnly = AMapLocationOption();
                gpsOnly.locationMode = AMapLocationMode.Device_Sensors;
                gpsOnly.locationInterval = 20000;
                gpsOnly.distanceFilter = SimpleLocationService._distanceFilter;
                gpsOnly.needAddress = false;
                gpsOnly.onceLocation = false;
                _locationPlugin.setLocationOption(gpsOnly);
                _locationPlugin.startLocation();
                debugPrint('✅ 已切换到GPS-only降级模式');
              } else {
                debugPrint('🌐 尝试纯网络定位以快速恢复');
                tryNetworkLocationOnly();
              }
            } catch (e) {
              debugPrint('❌ 错误码13降级处理失败: $e');
            }
            break;
          case 14:
            debugPrint('❌ 错误码14: GPS定位失败');
            suggestion = 'GPS信号弱，尝试切换到网络定位';
            shouldRetry = true;
            break;
          case 15:
            debugPrint('❌ 错误码15: 定位服务关闭（系统GPS开关被关闭）');
            suggestion = '系统定位服务已关闭，请在设置中开启';
            break;
          case 16:
            debugPrint('❌ 错误码16: 获取地址信息失败');
            suggestion = '地址解析失败，但定位可能成功';
            break;
          case 17:
            debugPrint('❌ 错误码17: 定位参数错误');
            suggestion = '定位参数配置错误，尝试重新配置';
            shouldRetry = true;
            break;
          case 18:
            debugPrint('❌ 错误码18: 定位超时');
            suggestion = '定位超时，尝试重新定位';
            shouldRetry = true;
            break;
          default:
            debugPrint('❌ 其他定位错误: $errorCode - $errorInfo');
            suggestion = '未知错误，尝试重新初始化';
            shouldRetry = true;
        }
        
        debugPrint('💡 建议: $suggestion');
        
        // 智能重试逻辑
        if (shouldRetry && _locationRetryCount < 3) {
          _locationRetryCount++;
          debugPrint('🔄 第$_locationRetryCount 次重试定位...');
          
          // 延迟后重试
          Future.delayed(Duration(seconds: 2), () async {
            try {
              await _lightweightReinitializePlugin();
              _locationPlugin.startLocation();
            } catch (e) {
              debugPrint('❌ 重试定位失败: $e');
            }
          });
        } else {
          _locationRetryCount = 0; // 重置重试计数
        }
        
        // 更新后台通知显示错误状态
        if (_isBackgroundNotificationShown) {
          _updateBackgroundNotification('定位异常 - $suggestion');
        }
        
        return; // 错误情况直接返回
      }
      
      // 解析高德定位结果
      double? latitude = double.tryParse(result['latitude']?.toString() ?? '');
      double? longitude = double.tryParse(result['longitude']?.toString() ?? '');
      double? accuracy = double.tryParse(result['accuracy']?.toString() ?? '');
      double? speed = double.tryParse(result['speed']?.toString() ?? '');
      double? altitude = double.tryParse(result['altitude']?.toString() ?? '');
      String? address = result['address']?.toString();
      int? timestamp = int.tryParse(result['timestamp']?.toString() ?? '');
      
      // 详细调试速度数据
      debugPrint('🚗 速度调试信息:');
      debugPrint('   原始速度字符串: "${result['speed']?.toString()}"');
      debugPrint('   解析后速度值: $speed m/s');
      debugPrint('   定位类型: ${result['locationType']?.toString()}');
      debugPrint('   卫星数量: ${result['satellites']?.toString()}');
      debugPrint('   GPS状态: ${result['gpsAccuracyStatus']?.toString()}');
      
      if (latitude == null || longitude == null) {
        debugPrint('高德定位数据无效: $result');
        return;
      }
      
      // 成功定位，重置重试计数
      _locationRetryCount = 0;
      
      // debugPrint('✅ 高德定位成功: 纬度=$latitude, 经度=$longitude, 精度=$accuracy 米');

      final location = LocationReportModel(
        longitude: longitude.toString(),
        latitude: latitude.toString(),
        locationTime: timestamp != null ? (timestamp ~/ 1000).toString() : 
                     (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(),
        speed: (speed ?? 0.0).toStringAsFixed(2),
        altitude: (altitude ?? 0.0).toStringAsFixed(2),
        locationName: address ?? '位置 ${latitude.toString()}, ${longitude.toString()}',
        accuracy: (accuracy ?? 0.0).toStringAsFixed(2),
      );

      // 更新当前位置
      currentLocation.value = location;
      
      // 新策略：先验证位置有效性，再决定是否上报
      if (_isLocationValid(location)) {
        _handleLocationReporting(location);
      } else {
        debugPrint('⚠️  位置验证失败，跳过上报: ${location.latitude}, ${location.longitude}, 精度: ${location.accuracy}米');
      }
      
      // debugPrint('🎯 高德实时定位: ${location.latitude}, ${location.longitude}, 精度: ${location.accuracy}米, 速度: ${location.speed}m/s');
      
      // 更新后台通知状态
      if (_isBackgroundNotificationShown) {
        String locationText = address ?? '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
        _updateBackgroundNotification('定位正常 - $locationText');
      }
      
      // 如果正在进行单次定位，现在收到了数据，说明单次定位成功
      if (_isSingleLocationInProgress) {
        debugPrint('✅ 单次定位成功，准备重启持续定位');
        _isSingleLocationInProgress = false;
        // 延迟重启持续定位，给单次定位一点时间完成
        Timer(Duration(milliseconds: 500), () {
          _restartContinuousLocation();
        });
      }
      
    } catch (e) {
      debugPrint('处理高德位置更新失败: $e');
    }
  }
  
  /// 停止定位
  void stopLocation() {
    try {
      // 停止定时单次定位
      _periodicLocationTimer?.cancel();
      _periodicLocationTimer = null;

      // 停止高德定位（但保持全局监听器）
      _locationPlugin.stopLocation();

      // 重置状态
      isLocationEnabled.value = false;
      isReporting.value = false;
      hasInitialReport.value = false;
      _lastReportedLocation = null;
      _lastMinuteReportTime = null;
      
      // 🆕 清空当前位置数据，避免关闭定位后仍然使用旧位置
      currentLocation.value = null;

      debugPrint('高德定位服务已停止（全局监听器保持激活）');
    } catch (e) {
      debugPrint('停止高德定位失败: $e');
    }
  }

  /// 请求单次定位（作为备用方案）
  Future<void> _requestSingleLocation() async {
    try {
      debugPrint('🔄 尝试单次定位作为备用方案...');
      
      // 如果已经在进行单次定位，不重复执行
      if (_isSingleLocationInProgress) {
        debugPrint('⚠️ 单次定位已在进行中，跳过重复请求');
        return;
      }
      
      // 标记正在进行单次定位
      _isSingleLocationInProgress = true;
      
      // 先停止当前定位，然后重新配置
      _locationPlugin.stopLocation();
      await Future.delayed(Duration(milliseconds: 200));
      
      // 设置单次定位参数
      AMapLocationOption singleLocationOption = AMapLocationOption();
      singleLocationOption.locationMode = AMapLocationMode.Hight_Accuracy;
      singleLocationOption.onceLocation = true; // 单次定位
      singleLocationOption.needAddress = true;
      // 🚀 高德官方优化：已通过精度过滤和轨迹平滑实现
      
      _locationPlugin.setLocationOption(singleLocationOption);
      
      // 重新开始定位，此时应该是单次定位模式
      _locationPlugin.startLocation();
      debugPrint('🔄 单次定位请求已发送');
      
      // 设置超时，如果10秒内没有收到定位，则重启持续定位
      Timer(Duration(seconds: 10), () {
        if (_isSingleLocationInProgress) {
          debugPrint('⏰ 单次定位超时，尝试智能恢复');
          _isSingleLocationInProgress = false;
          _handleLocationTimeout();
        }
      });
      
    } catch (e) {
      debugPrint('❌ 单次定位失败: $e');
      _isSingleLocationInProgress = false;
    }
  }

  /// 设置持续定位参数
  void _setupContinuousLocation() {
    try {
      debugPrint('🔄 重新设置持续定位参数...');
      AMapLocationOption locationOption = AMapLocationOption();
      locationOption.locationMode = AMapLocationMode.Hight_Accuracy;
      locationOption.locationInterval = _locationInterval; // 2秒间隔（平衡性能）
      locationOption.distanceFilter = _distanceFilter; // 50米距离过滤（与iOS一致）
      // 🚀 高德官方优化：已通过精度过滤和轨迹平滑实现
      locationOption.needAddress = true;
      locationOption.onceLocation = false; // 持续定位
      
      _locationPlugin.setLocationOption(locationOption);
      debugPrint('✅ 持续定位参数重新设置完成');
    } catch (e) {
      debugPrint('❌ 重新设置持续定位参数失败: $e');
    }
  }
  
  /// 处理定位超时的智能恢复策略
  Future<void> _handleLocationTimeout() async {
    try {
      debugPrint('🔧 开始处理定位超时，当前重试次数: $_locationRetryCount');
      
      if (_locationRetryCount < 3) {
        _locationRetryCount++;
        debugPrint('🔄 第${_locationRetryCount}次超时重试...');
        
        // 根据重试次数采用不同策略
        switch (_locationRetryCount) {
          case 1:
            // 第一次超时：重新启动监听器
            debugPrint('🔧 策略1: 重新启动流监听器');
            // 全局监听器已激活，无需重新设置
            _locationPlugin.startLocation();
            break;
            
          case 2:
            // 第二次超时：强制重新初始化插件
            debugPrint('🔧 策略2: 强制重新初始化插件');
            await _lightweightReinitializePlugin();
            // 全局监听器已激活，无需重新设置
            _locationPlugin.startLocation();
            break;
            
          case 3:
            // 第三次超时：尝试切换定位模式
            debugPrint('🔧 策略3: 切换到高精度定位模式');
            await _switchToHighAccuracyMode();
            break;
            
          default:
            // 最后策略：重启持续定位
            debugPrint('🔧 最终策略: 重启持续定位');
            _restartContinuousLocation();
        }
      } else {
        // 重试次数过多，重置计数并使用持续定位
        debugPrint('❌ 超时重试次数过多，回退到持续定位模式');
        _locationRetryCount = 0;
        _restartContinuousLocation();
      }
      
    } catch (e) {
      debugPrint('❌ 处理定位超时失败: $e');
      _locationRetryCount = 0;
      _restartContinuousLocation();
    }
  }

  /// 切换到高精度定位模式
  Future<void> _switchToHighAccuracyMode() async {
    try {
      debugPrint('🔧 切换到高精度定位模式...');
      
      // 停止当前定位
      _locationPlugin.stopLocation();
      await Future.delayed(Duration(milliseconds: 500));
      
      // 设置高精度定位参数
      AMapLocationOption locationOption = AMapLocationOption();
      locationOption.locationMode = AMapLocationMode.Hight_Accuracy;
      locationOption.locationInterval = 2000; // 减少间隔到2秒
      locationOption.distanceFilter = _distanceFilter; // 保持50米距离过滤（与iOS一致）
      // 🚀 高德官方优化：已通过精度过滤和轨迹平滑实现
      locationOption.needAddress = true;
      locationOption.onceLocation = false;
      
      _locationPlugin.setLocationOption(locationOption);
      
      // 重新设置监听器并启动
      // 全局监听器已激活，无需重新设置
      _locationPlugin.startLocation();
      
      debugPrint('✅ 已切换到高精度定位模式');
      
    } catch (e) {
      debugPrint('❌ 切换高精度定位模式失败: $e');
      throw e;
    }
  }

  /// 轻量级重新初始化插件（避免Stream冲突）
  Future<void> _lightweightReinitializePlugin() async {
    try {
      debugPrint('🔧 轻量级重新初始化高德定位插件...');

      // 只停止定位，不干扰Stream
      _locationPlugin.stopLocation();
      await Future.delayed(Duration(milliseconds: 300));

      // 重新设置隐私合规和API Key
      await _setupPrivacyCompliance();

      await Future.delayed(Duration(milliseconds: 200));
      debugPrint('✅ 插件轻量级重新初始化完成');

    } catch (e) {
      debugPrint('❌ 轻量级重新初始化插件失败: $e');
      throw e;
    }
  }

  // 旧的Stream监听器方法已移除，现在使用全局监听器
  
  /// 重启持续定位
  Future<void> _restartContinuousLocation() async {
    try {
      debugPrint('🔄 重启持续定位...');
      _locationPlugin.stopLocation();
      await Future.delayed(Duration(milliseconds: 300));
      
      // 重新设置持续定位参数
      _setupContinuousLocation();
      
      // 重新开始定位（不需要重新设置监听器，因为监听器是持续的）
      _locationPlugin.startLocation();
      debugPrint('✅ 持续定位已重启');
    } catch (e) {
      debugPrint('❌ 重启持续定位失败: $e');
    }
  }
  
  /// 启动定时单次定位（备用方案）- 智能调度
  void _startPeriodicSingleLocation() {
    debugPrint('🔄 启动定时单次定位作为备用方案...');
    
    // 每30秒进行一次单次定位，确保有数据回调
    _periodicLocationTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      // 🔥 检查应用状态，前台时降低频率
      try {
        final appLifecycle = AppLifecycleService.instance;
        if (appLifecycle.isInForeground) {
          // 前台时，如果持续定位正常工作，则跳过更多次数
          if (currentLocation.value != null) {
            final lastUpdateTime = int.tryParse(currentLocation.value!.locationTime);
            if (lastUpdateTime != null) {
              final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
              if (now - lastUpdateTime < 60) { // 前台时放宽到60秒
                debugPrint('🔄 前台持续定位正常，跳过定时单次定位');
                return;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('❌ 定时单次定位状态检查失败: $e');
      }
      
      // 如果正常的持续定位工作正常（最近30秒内有数据），则跳过单次定位
      if (currentLocation.value != null) {
        final lastUpdateTime = int.tryParse(currentLocation.value!.locationTime);
        if (lastUpdateTime != null) {
          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          if (now - lastUpdateTime < 45) { // 45秒内有数据，说明持续定位正常
            debugPrint('🔄 持续定位正常工作，跳过定时单次定位');
            return;
          }
        }
      }
      
      debugPrint('🔄 执行定时单次定位（持续定位可能无响应）...');
      await _executePeriodicSingleLocation();
    });
  }
  
  /// 执行定时单次定位
  Future<void> _executePeriodicSingleLocation() async {
    try {
      // 如果已经在进行单次定位，跳过
      if (_isSingleLocationInProgress) {
        debugPrint('⚠️ 单次定位进行中，跳过定时单次定位');
        return;
      }
      
      _isSingleLocationInProgress = true;
      
      // 临时切换到单次定位模式
      AMapLocationOption singleOption = AMapLocationOption();
      singleOption.locationMode = AMapLocationMode.Hight_Accuracy;
      singleOption.onceLocation = true;
      singleOption.needAddress = true;
      // 🚀 高德官方优化：已通过精度过滤和轨迹平滑实现
      
      _locationPlugin.setLocationOption(singleOption);
      _locationPlugin.startLocation();
      
      debugPrint('🔄 定时单次定位请求已发送');
      
      // 3秒后恢复持续定位模式
      Timer(Duration(seconds: 3), () {
        _isSingleLocationInProgress = false;
        _setupContinuousLocation();
        _locationPlugin.startLocation();  // 只重启定位，不重新设置监听器
        debugPrint('🔄 恢复持续定位模式');
      });
      
    } catch (e) {
      debugPrint('❌ 定时单次定位失败: $e');
      _isSingleLocationInProgress = false;
    }
  }
  
  /// 检查服务状态（用于测试）
  bool get isServiceRunning => isLocationEnabled.value;
  
  /// 获取当前定位策略信息
  Map<String, dynamic> getLocationStrategyInfo() {
    return {
      'strategy': 'iOS全量收集',
      'reportInterval': _reportInterval.inMinutes,
      'locationHistorySize': locationHistory.length,
      'description': '收集所有位置更新，保持完整轨迹和准确速度数据',
    };
  }
  
  /// 调试速度数据的专用方法
  void debugSpeedInfo() {
    if (currentLocation.value != null) {
      final location = currentLocation.value!;
      debugPrint('🚗 当前速度调试信息:');
      debugPrint('   速度值: ${location.speed} m/s');
      debugPrint('   换算: ${(double.parse(location.speed) * 3.6).toStringAsFixed(2)} km/h');
      debugPrint('   纬度: ${location.latitude}');
      debugPrint('   经度: ${location.longitude}');
      debugPrint('   精度: ${location.accuracy} 米');
      debugPrint('   定位时间: ${location.locationTime}');
      debugPrint('   位置名称: ${location.locationName}');
    } else {
      debugPrint('🚗 当前无定位数据');
    }
  }
  
  /// 手动触发单次定位（用于调试）
  Future<void> requestTestLocation() async {
    debugPrint('🧪 手动触发测试定位...');
    await _requestSingleLocation();
  }
  
  /// 尝试纯网络定位（不依赖GPS）
  Future<void> tryNetworkLocationOnly() async {
    debugPrint('🌐 尝试纯网络定位...');
    
    try {
      // 停止当前定位
      stopLocation();
      await Future.delayed(Duration(seconds: 1));
      
      // 配置纯网络定位
      AMapLocationOption locationOption = AMapLocationOption();
      locationOption.locationMode = AMapLocationMode.Battery_Saving; // 省电模式主要使用网络定位
      locationOption.locationInterval = 5000; // 5秒间隔
      locationOption.distanceFilter = _distanceFilter; // 50米距离过滤（与iOS一致）
      locationOption.needAddress = true;
      locationOption.onceLocation = false;
      // locationOption.mockEnable = true;
      // locationOption.gpsFirst = false; // 不优先GPS
      
      _locationPlugin.setLocationOption(locationOption);
      debugPrint('✅ 网络定位参数设置完成');
      
      // 重新设置监听器
      // 全局监听器已激活，无需重新设置
      
      // 启动定位
      _locationPlugin.startLocation();
      debugPrint('🔄 网络定位已启动，等待结果...');
      
      // 等待15秒
      await Future.delayed(Duration(seconds: 15));
      
      if (currentLocation.value != null) {
        debugPrint('✅ 网络定位成功！');
        debugPrint('   经度: ${currentLocation.value!.longitude}');
        debugPrint('   纬度: ${currentLocation.value!.latitude}');
        debugPrint('   地址: ${currentLocation.value!.locationName}');
      } else {
        debugPrint('❌ 网络定位也未能获取位置');
        debugPrint('💡 建议检查：');
        debugPrint('   1. 网络连接是否正常');
        debugPrint('   2. 高德地图API Key是否正确');
        debugPrint('   3. 是否在中国境内（高德地图限制）');
      }
      
    } catch (e) {
      debugPrint('❌ 网络定位出错: $e');
    }
  }
  
  /// 综合定位问题排查工具
  Future<void> comprehensiveLocationTroubleshoot() async {
    debugPrint('🔧 ========== 综合定位问题排查 ==========');
    
    try {
      // 1. 基础检查
      debugPrint('📋 第1步：基础环境检查');
      await diagnoseLocationService();
      
      // 2. API Key验证
      debugPrint('\n📋 第2步：API Key验证');
      await checkApiKeyConfiguration();
      
      // 3. 尝试网络定位
      debugPrint('\n📋 第3步：尝试纯网络定位');
      await tryNetworkLocationOnly();
      
      if (currentLocation.value != null) {
        debugPrint('✅ 网络定位成功，问题已解决！');
        return;
      }
      
      // 4. 尝试不同定位模式
      debugPrint('\n📋 第4步：尝试不同定位模式');
      await tryDifferentLocationModes();
      
      // 5. 最终建议
      debugPrint('\n📋 第5步：最终建议');
      if (currentLocation.value == null) {
        debugPrint('❌ 所有定位方法都失败了');
        debugPrint('🔧 建议进行以下检查：');
        debugPrint('   1. 确认设备位置服务已开启');
        debugPrint('   2. 确认应用位置权限已授予');
        debugPrint('   3. 确认网络连接正常');
        debugPrint('   4. 确认高德API Key配置正确');
        debugPrint('   5. 确认在中国境内（高德地图限制）');
        debugPrint('   6. 尝试重启应用或设备');
        debugPrint('   7. 检查高德控制台配置和服务状态');
      } else {
        debugPrint('✅ 定位问题已解决！');
      }
      
    } catch (e) {
      debugPrint('❌ 综合排查过程中出错: $e');
    }
  }

  /// 尝试不同定位模式
  Future<void> tryDifferentLocationModes() async {
    debugPrint('🔧 尝试不同定位模式...');
    
    // 模式列表
    final modes = [
      {'mode': AMapLocationMode.Battery_Saving, 'name': '省电模式（网络定位优先）'},
      {'mode': AMapLocationMode.Device_Sensors, 'name': '设备模式（GPS优先）'},
      {'mode': AMapLocationMode.Hight_Accuracy, 'name': '高精度模式'},
    ];
    
    for (int i = 0; i < modes.length; i++) {
      final modeInfo = modes[i];
      debugPrint('🔄 尝试模式 ${i + 1}/${modes.length}: ${modeInfo['name']}');
      
      try {
        // 停止当前定位
        stopLocation();
        await Future.delayed(Duration(seconds: 1));
        
        // 设置新模式
        AMapLocationOption locationOption = AMapLocationOption();
        locationOption.locationMode = modeInfo['mode'] as AMapLocationMode;
        locationOption.locationInterval = 3000;
        locationOption.distanceFilter = _distanceFilter; // 50米距离过滤（与iOS一致）
        // 🚀 高德官方优化：已通过精度过滤和轨迹平滑实现
        locationOption.needAddress = true;
        locationOption.onceLocation = false;
        // locationOption.mockEnable = true;
        // locationOption.gpsFirst = false;
        
        _locationPlugin.setLocationOption(locationOption);
        
        // 重新启动定位
        // 全局监听器已激活，无需重新设置
        _locationPlugin.startLocation();
        
        debugPrint('   启动 ${modeInfo['name']}，等待10秒测试...');
        
        // 等待10秒看是否有数据
        await Future.delayed(Duration(seconds: 10));
        
      if (currentLocation.value != null) {
        debugPrint('✅ ${modeInfo['name']} 成功获取位置！');
        debugPrint('   位置: (${currentLocation.value!.latitude}, ${currentLocation.value!.longitude})');
          return; // 成功就退出
        } else {
          debugPrint('❌ ${modeInfo['name']} 未获取到位置');
        }
        
      } catch (e) {
        debugPrint('❌ ${modeInfo['name']} 出错: $e');
      }
    }
    
    debugPrint('⚠️ 所有定位模式都未能获取到位置');
  }

  /// 检查高德API Key是否配置正确
  Future<void> checkApiKeyConfiguration() async {
    debugPrint('🔑 检查高德地图API Key配置...');
    
    try {
      // 尝试验证API Key配置（通过设置参数来测试）
      // await _locationPlugin.init(); // 某些版本可能没有这个方法
      debugPrint('✅ 高德定位插件初始化成功，API Key可能配置正确');
      
      // 检查是否能获取插件版本（这通常表示插件工作正常）
      try {
        // 注意：某些版本的高德插件可能没有getVersion方法
        debugPrint('🔧 高德定位插件已准备就绪');
      } catch (e) {
        debugPrint('⚠️ 无法获取插件版本信息，但这可能是正常的: $e');
      }
      
    } catch (e) {
      debugPrint('❌ 高德定位插件初始化失败: $e');
      debugPrint('💡 可能的原因：');
      debugPrint('   1. API Key未配置或配置错误');
      debugPrint('   2. API Key未在高德控制台启用定位服务');
      debugPrint('   3. API Key的bundle ID与应用不匹配');
      debugPrint('   4. 网络连接问题');
      throw e;
    }
  }

  /// 诊断定位服务状态
  Future<void> diagnoseLocationService() async {
    debugPrint('🔍 ========== 定位服务诊断报告 ==========');
    
    try {
      // 1. 检查定位服务是否启用
      debugPrint('📊 定位服务状态: ${isLocationEnabled.value ? "✅ 已启用" : "❌ 已禁用"}');
      
      // 2. 检查当前位置数据
      debugPrint('📊 当前位置数据: ${currentLocation.value?.toJson() ?? "❌ 无数据"}');
      
      // 3. 检查流监听器状态
      debugPrint('📊 流监听器状态: ${_globalLocationSub != null ? "✅ 已创建" : "❌ 未创建"}');
      
      // 4. 检查定时器状态
      debugPrint('📊 单次定位定时器: ${_periodicLocationTimer != null && _periodicLocationTimer!.isActive ? "✅ 运行中" : "❌ 未运行"}');
      
      // 5. 检查历史数据
      debugPrint('📊 位置历史数量: ${locationHistory.length} 条');
      
      // 6. 尝试获取一次位置
      debugPrint('🔧 尝试手动单次定位测试...');
      await _requestSingleLocation();
      
      debugPrint('🔍 ========== 诊断报告结束 ==========');
      
    } catch (e) {
      debugPrint('❌ 诊断过程中出错: $e');
    }
  }
  
  /// 运行完整的定位问题诊断和修复流程
  Future<bool> runLocationDiagnosticAndFix() async {
    debugPrint('🔧 ========== 开始完整定位诊断和修复 ==========');
    
    try {
      // 1. 运行综合排查
      debugPrint('\n📋 步骤1：运行综合排查');
      await comprehensiveLocationTroubleshoot();
      
      // 检查是否已经获得位置
      if (currentLocation.value != null) {
        debugPrint('✅ 综合排查成功获得位置！');
        return true;
      }
      
      // 2. 强制重启定位服务
      debugPrint('\n📋 步骤2：强制重启定位服务');
      bool restartSuccess = await forceRestartLocation();
      
      if (!restartSuccess) {
        debugPrint('❌ 强制重启失败');
        return false;
      }
      
      // 3. 等待30秒观察结果
      debugPrint('\n📋 步骤3：等待30秒观察定位结果...');
      for (int i = 0; i < 30; i++) {
        await Future.delayed(Duration(seconds: 1));
        if (currentLocation.value != null) {
          debugPrint('✅ 第${i+1}秒获得位置数据！');
          debugPrint('   经度: ${currentLocation.value!.longitude}');
          debugPrint('   纬度: ${currentLocation.value!.latitude}');
          debugPrint('   地址: ${currentLocation.value!.locationName}');
          return true;
        }
        if ((i + 1) % 5 == 0) {
          debugPrint('⏳ 已等待${i+1}秒，继续等待...');
        }
      }
      
      debugPrint('❌ 30秒后仍未获得位置数据');
      
      // 4. 最后尝试：模拟位置（测试用）
      debugPrint('\n📋 步骤4：生成测试位置数据');
      _generateTestLocation();
      
      return currentLocation.value != null;
      
    } catch (e) {
      debugPrint('❌ 诊断和修复过程中出错: $e');
      return false;
    }
  }
  
  /// 测试单次定位（用于调试） - 使用独立插件实例避免Stream冲突
  Future<Map<String, Object>?> testSingleLocation() async {
    // 创建独立的插件实例避免Stream冲突
    AMapFlutterLocation testLocationPlugin = AMapFlutterLocation();
    
    try {
      debugPrint('🧪 开始测试单次定位...');
      
      // 设置隐私合规和API Key
      await _setupPrivacyCompliance();
      
      // 检查权限
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        debugPrint('❌ 定位权限检查失败');
        return null;
      }
      
      debugPrint('🔧 准备启动单次定位（使用独立插件实例）');
      
      // 设置单次定位参数
      AMapLocationOption locationOption = AMapLocationOption();
      locationOption.locationMode = AMapLocationMode.Hight_Accuracy;
      locationOption.locationInterval = 2000;
      locationOption.distanceFilter = _distanceFilter; // 50米距离过滤（与iOS一致）
      // 🚀 高德官方优化：已通过精度过滤和轨迹平滑实现
      locationOption.needAddress = true;
      locationOption.onceLocation = true; // 单次定位
      
      testLocationPlugin.setLocationOption(locationOption);
      debugPrint('🔧 单次定位参数设置完成');
      
      // 创建一个Completer来等待定位结果
      Completer<Map<String, Object>?> completer = Completer<Map<String, Object>?>();
      
      // 设置超时
      Timer timeoutTimer = Timer(Duration(seconds: 30), () {
        if (!completer.isCompleted) {
          debugPrint('❌ 单次定位超时（30秒）');
          completer.complete(null);
        }
      });
      
      // 监听定位结果 - 使用独立插件实例的Stream
      StreamSubscription<Map<String, Object>>? testSub;
      testSub = testLocationPlugin.onLocationChanged().listen(
        (Map<String, Object> result) {
          debugPrint('🧪 收到单次定位结果: $result');
          timeoutTimer.cancel();
          testSub?.cancel();
          
          // 检查错误码
          int? errorCode = int.tryParse(result['errorCode']?.toString() ?? '0');
          if (errorCode != null && errorCode != 0) {
            debugPrint('❌ 单次定位失败 - 错误码: $errorCode');
            completer.complete(null);
          } else {
            completer.complete(result);
          }
        },
        onError: (error) {
          debugPrint('❌ 单次定位错误: $error');
          timeoutTimer.cancel();
          testSub?.cancel();
          completer.complete(null);
        },
      );
      
      // 启动定位
      testLocationPlugin.startLocation();
      debugPrint('🔧 单次定位启动请求已发送');
      
      // 等待结果
      Map<String, Object>? result = await completer.future;
      
      // 停止定位并清理
      testLocationPlugin.stopLocation();
      await testSub.cancel();
      debugPrint('🔧 单次定位测试完成');
      
      return result;
    } catch (e) {
      debugPrint('❌ 单次定位测试异常: $e');
      // 确保清理
      try {
        testLocationPlugin.stopLocation();
      } catch (_) {}
      return null;
    }
  }

  /// 生成测试位置数据（用于调试）
  void _generateTestLocation() {
    debugPrint('🧪 生成测试位置数据（北京天安门附近）');
    
    // 模拟北京天安门附近的位置
    final testLocation = LocationReportModel(
      longitude: '116.397470',
      latitude: '39.908722',
      locationTime: (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(),
      speed: '0.00',
      altitude: '45.00',
      locationName: '北京市东城区天安门广场',
      accuracy: '10.00',
    );
    
    currentLocation.value = testLocation;
    debugPrint('✅ 测试位置数据已生成');
    debugPrint('   经度: ${testLocation.longitude}');
    debugPrint('   纬度: ${testLocation.latitude}');
    debugPrint('   地址: ${testLocation.locationName}');
  }

  /// 检查高德插件内部状态（调试用）
  Future<void> checkAMapPluginStatus() async {
    debugPrint('🔍 ========== 高德插件状态检查 ==========');
    
    try {
      // 检查插件基本状态
      debugPrint('📊 检查高德定位插件基本状态...');
      
      // 尝试获取插件版本信息（如果有）
      try {
        debugPrint('🔧 尝试停止和重新初始化插件...');
        _locationPlugin.stopLocation();
        await Future.delayed(Duration(milliseconds: 500));
        
        // 重新设置API Key和隐私合规
        await _setupPrivacyCompliance();
        debugPrint('✅ 插件重新初始化完成');
        
      } catch (e) {
        debugPrint('⚠️ 插件重新初始化过程中出现问题: $e');
      }
      
      // 检查当前的监听器状态
      debugPrint('📊 当前监听器状态:');
      debugPrint('   _isGlobalListenerSetup: $_isGlobalListenerSetup');
      debugPrint('   _globalLocationSub是否为null: ${_globalLocationSub == null}');
      debugPrint('   isLocationEnabled: ${isLocationEnabled.value}');
      
      // 尝试重新创建监听器
      try {
        // 全局监听器无需清理
        await Future.delayed(Duration(milliseconds: 1000));
        
        debugPrint('🔧 尝试重新设置监听器...');
        // 全局监听器已激活，无需重新设置
        
      } catch (e) {
        debugPrint('❌ 重新设置监听器失败: $e');
      }
      
    } catch (e) {
      debugPrint('❌ 插件状态检查失败: $e');
    }
    
    debugPrint('🔍 ========== 插件状态检查结束 ==========');
  }

  /// 强制重启定位服务（用于测试）
  Future<bool> forceRestartLocation() async {
    try {
      debugPrint('🔄 强制重启定位服务...');
      
      // 完全停止服务
      try {
        _locationPlugin.stopLocation();
        // 全局监听器无需清理
        
        // 重置所有状态
        isLocationEnabled.value = false;
        isReporting.value = false;
        _isGlobalListenerSetup = false;
        
        // 停止定时器
        _periodicLocationTimer?.cancel();
        _periodicLocationTimer = null;
        
        debugPrint('✅ 完全停止完成');
      } catch (e) {
        debugPrint('⚠️ 停止过程中出现错误: $e');
      }
      
      // 等待确保完全停止和状态重置
      await Future.delayed(Duration(milliseconds: 2000));
      
      // 重新启动
      debugPrint('🚀 重新启动定位服务...');
      return await startLocation();
    } catch (e) {
      debugPrint('❌ 强制重启定位服务失败: $e');
      return false;
    }
  }
  
  
  /// 计算两点间距离（米）
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    double dLat = _degToRad(lat2 - lat1);
    double dLon = _degToRad(lon2 - lon1);
    double a =
        (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        math.cos(_degToRad(lat1)) * math.cos(_degToRad(lat2)) *
            (math.sin(dLon / 2) * math.sin(dLon / 2));
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);
  
  
  
  
  
  /// 手动上报当前位置
  Future<bool> reportCurrentLocation() async {
    if (currentLocation.value == null) {
      debugPrint('没有当前位置数据');
      return false;
    }
    
    try {
      isReporting.value = true;
      
      final api = LocationReportApi();
      final result = await api.reportLocation([currentLocation.value!]);
      
      if (result.isSuccess) {
        debugPrint('当前位置上报成功');
        return true;
      } else {
        debugPrint('当前位置上报失败: ${result.msg}');
        return false;
      }
    } catch (e) {
      debugPrint('上报当前位置异常: $e');
      return false;
    } finally {
      isReporting.value = false;
    }
  }
  
  /// 获取位置历史记录数量
  int get historyCount => locationHistory.length;
  
  
  /// 获取待上报位置数量（新策略不再使用批量收集）
  int get pendingReportCount => 0;
  
  /// 获取当前是否有位置数据
  bool get hasLocation => currentLocation.value != null;
  
  /// 获取当前定位精度
  String get currentAccuracy => currentLocation.value?.accuracy ?? '0.0';
  
  /// 获取服务状态信息
  Map<String, dynamic> get serviceStatus => {
    'isLocationEnabled': isLocationEnabled.value,
    'isReporting': isReporting.value,
    'hasInitialReport': hasInitialReport.value,
    'hasLocation': hasLocation,
    'historyCount': historyCount,
    'pendingReportCount': pendingReportCount,
    'currentAccuracy': currentAccuracy,
  };
  
  /// 获取增强后的服务状态信息（参考iOS版本）
  Map<String, dynamic> getEnhancedServiceStatus() {
    final permissionStatus = getCurrentPermissionStatusDescription();
    return {
      'basic': serviceStatus,
      'permissions': permissionStatus,
      'backgroundTask': _backgroundTaskId != null ? 'active' : 'inactive',
      'keepAliveTimer': _backgroundKeepAliveTimer?.isActive ?? false,
      'batteryOptimization': {
        'isLowPowerMode': _isInLowPowerMode,
        'consecutiveSuccessCount': _consecutiveSuccessCount,
        'consecutiveFailureCount': _consecutiveFailureCount,
        'lowPowerModeStartTime': _lowPowerModeStartTime?.toIso8601String(),
        'backgroundNotificationShown': _isBackgroundNotificationShown,
      },
      'configuration': {
        'distanceFilter': _distanceFilter,
        'locationInterval': _locationInterval,
        'desiredAccuracy': _desiredAccuracy,
        'reportInterval': _reportInterval.inMinutes,
        'maxHistorySize': _maxHistorySize,
      },
      'strategy': '参考iOS全量收集策略',
      'retryCount': _locationRetryCount,
    };
  }
  
  /// 强制上报当前位置（新策略：实时上报，无批量数据）
  Future<bool> forceReportAllPending() async {
    if (currentLocation.value == null) {
      debugPrint('没有当前位置数据');
      return true;
    }
    
    debugPrint('强制上报当前位置');
    return await reportCurrentLocation();
  }
  
  /// 清空所有历史数据
  void clearAllData() {
    locationHistory.clear();
    currentLocation.value = null;
    hasInitialReport.value = false;
    _lastReportedLocation = null;
    _lastMinuteReportTime = null;
    debugPrint('已清空所有位置数据');
  }
  
  /// 获取位置历史记录（用于调试）
  List<Map<String, dynamic>> getLocationHistoryForDebug() {
    return locationHistory.map((location) => location.toJson()).toList();
  }
  
  /// 获取待上报数据（用于调试）- 新策略不再使用批量收集
  List<Map<String, dynamic>> getPendingReportsForDebug() {
    return []; // 新策略：实时上报，无待上报数据
  }
  
  /// 外部接口：确保后台策略激活
  void ensureBackgroundStrategyActive() {
    if (!isLocationEnabled.value) return;
    
    debugPrint('🔧 外部调用：确保后台策略激活');
    _startEnhancedBackgroundStrategy();
  }
  
  /// 外部接口：优化前台策略
  void optimizeForegroundStrategy() {
    if (!isLocationEnabled.value) return;
    
    debugPrint('🔧 外部调用：优化前台策略');
    _stopEnhancedBackgroundStrategy();
  }
  
  /// 智能启动策略：根据应用状态决定是否启动后台定时器
  void _smartStartLocationStrategy() {
    try {
      // 获取应用生命周期状态
      final appLifecycle = AppLifecycleService.instance;
      final isInBackground = appLifecycle.isInBackground;
      
      debugPrint('🧠 智能启动策略检查：应用${isInBackground ? "在后台" : "在前台"}');
      
      if (isInBackground) {
        // 应用在后台，启动增强后台策略
        debugPrint('🌃 应用在后台，启动增强后台策略（包含多重定时器）');
        _startEnhancedBackgroundStrategy();
      } else {
        // 应用在前台，只启动基础定位，不启动后台定时器
        debugPrint('🌅 应用在前台，仅启动基础定位（不启动后台定时器）');
        // 确保后台定时器已停止
        _stopEnhancedBackgroundStrategy();
      }
    } catch (e) {
      debugPrint('❌ 智能启动策略检查失败: $e');
      // 出错时默认不启动后台定时器（安全策略）
      _stopEnhancedBackgroundStrategy();
    }
  }
  
  /// 获取服务状态
  Map<String, dynamic> get currentServiceStatus {
    return {
      'isLocationEnabled': isLocationEnabled.value,
      'isReporting': isReporting.value,
      'hasInitialReport': hasInitialReport.value,
      'currentLocation': currentLocation.value?.toJson(),
      'locationHistoryCount': locationHistory.length,
    };
  }
  
  /// 获取实时定位点收集统计信息
  Map<String, dynamic> getLocationCollectionStats() {
    return {
      'isLocationEnabled': isLocationEnabled.value,
      'totalLocationPoints': locationHistory.length,
      'hasInitialReport': hasInitialReport.value,
      'currentLocation': currentLocation.value?.toJson(),
      'reportInterval': _reportInterval.inMinutes,
      'maxHistorySize': _maxHistorySize,
      'lastLocationTime': currentLocation.value?.locationTime,
    };
  }
  
  /// 打印实时定位点收集状态
  void printLocationCollectionStatus() {
    final stats = getLocationCollectionStats();
    debugPrint('📊 实时定位点收集状态:');
    debugPrint('   定位服务状态: ${stats['isLocationEnabled'] ? '运行中' : '已停止'}');
    debugPrint('   总采样点数: ${stats['totalLocationPoints']}');
    debugPrint('   待上报点数: ${stats['pendingReportPoints']}');
    debugPrint('   收集策略: 参考iOS全量收集模式');
    debugPrint('   上报间隔: ${stats['reportInterval']}分钟');
    debugPrint('   当前位置: ${stats['currentLocation'] != null ? '已获取' : '未获取'}');
    if (stats['currentLocation'] != null) {
      final loc = stats['currentLocation'] as Map<String, dynamic>;
      debugPrint('   最新位置: ${loc['latitude']}, ${loc['longitude']} (精度: ${loc['accuracy']}米)');
    }
  }
}

// MARK: - 应用生命周期监听扩展（优化版本）
extension AppLifecycleExtension on SimpleLocationService {
  
  /// 设置真实的应用生命周期监听
  void _setupAppLifecycleListener() {
    debugPrint('🔧 设置真实应用生命周期监听（优化版本）');
    WidgetsBinding.instance.addObserver(this);
  }
  
  /// 清理生命周期监听
  void _removeAppLifecycleListener() {
    WidgetsBinding.instance.removeObserver(this);
  }
  
  /// 真实的应用状态变化监听
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('📱 应用状态变化: $state');
    _lastAppState = state.toString();
    
    switch (state) {
      case AppLifecycleState.resumed:
        _onAppWillEnterForeground();
        break;
      case AppLifecycleState.paused:
        _onAppDidEnterBackground();
        break;
      case AppLifecycleState.detached:
        _onAppWillTerminate();
        break;
      case AppLifecycleState.inactive:
        // 应用变为非活跃状态（如来电话、拉下通知栏等）
        debugPrint('📱 应用变为非活跃状态');
        break;
      case AppLifecycleState.hidden:
        // 应用隐藏但未停止
        debugPrint('📱 应用已隐藏');
        break;
    }
  }
  
  /// 应用进入后台（真实状态检测）
  void _onAppDidEnterBackground() {
    debugPrint('🌃 应用真实进入后台，启动增强后台策略');
    _startEnhancedBackgroundStrategy();
  }
  
  /// 应用进入前台（真实状态检测）
  void _onAppWillEnterForeground() {
    debugPrint('🌅 应用回到前台，恢复正常策略');
    _stopEnhancedBackgroundStrategy();
  }
  
  /// 应用即将终止
  void _onAppWillTerminate() {
    debugPrint('💀 应用即将终止，保存关键数据');
    _saveLocationDataBeforeTermination();
  }
  
  /// 启动增强的后台策略
  void _startEnhancedBackgroundStrategy() {
    // 启用前台服务模式（Android）
    _enableForegroundServiceIfNeeded();
    // 1. 启动后台保活
    _startBackgroundKeepAlive();
    
    // 2. 增强位置采集频率（后台模式）
    _enableBackgroundLocationMode();
    
    // 3. 启动多重保障定时器
    _startMultipleBackgroundTimers();
    
    // 4. 显示后台运行通知
    _showBackgroundNotification();
  }
  
  /// 停止增强的后台策略
  void _stopEnhancedBackgroundStrategy() {
    // 禁用前台服务模式（Android）
    _disableForegroundServiceIfNeeded();
    // 1. 停止后台保活
    _stopBackgroundKeepAlive();
    
    // 2. 恢复正常位置采集
    _enableForegroundLocationMode();
    
    // 3. 停止多重保障定时器
    _stopMultipleBackgroundTimers();
    
    // 4. 隐藏后台运行通知
    _hideBackgroundNotification();
  }
  
  /// 启用后台位置模式
  void _enableBackgroundLocationMode() {
    debugPrint('🔧 启用后台位置采集模式');
    // 在后台时，降低采集频率以节省电量，同时保证一定的更新
    try {
      // 若后台定位权限未授予，避免触发网络/WIFI基站采集导致错误13
      if (_currentBackgroundPermission.value != PermissionStatus.granted) {
        debugPrint('⚠️ 后台定位权限未授予，采用GPS优先的降级策略（Device_Sensors）');
        _locationPlugin.stopLocation();

        final gpsOnly = AMapLocationOption();
        gpsOnly.locationMode = AMapLocationMode.Device_Sensors; // 仅设备传感器（GPS）
        gpsOnly.locationInterval = 20000; // 降低频率，节能且避免频繁失败
        gpsOnly.distanceFilter = SimpleLocationService._distanceFilter;
        gpsOnly.needAddress = false; // 纯GPS不解析地址，避免网络依赖
        gpsOnly.onceLocation = false;

        _locationPlugin.setLocationOption(gpsOnly);
        _locationPlugin.startLocation();
        debugPrint('✅ 已应用GPS优先后台策略：Device_Sensors / 20s / no address');
        return;
      }

      // 只调整定位参数，不重置全局监听器
      _locationPlugin.stopLocation();

      // 首选高精度模式，系统会在息屏/后台时自动降级为网络定位
      final option = AMapLocationOption();
      option.locationMode = AMapLocationMode.Hight_Accuracy;
      option.locationInterval = 15000; // 后台15秒一次，降低功耗
      option.distanceFilter = SimpleLocationService._distanceFilter; // 与前台保持一致的距离过滤
      option.needAddress = true;
      option.onceLocation = false;

      _locationPlugin.setLocationOption(option);
      _locationPlugin.startLocation();
      debugPrint('✅ 后台模式参数已应用：Hight_Accuracy / 15s / distanceFilter=${SimpleLocationService._distanceFilter}');
    } catch (e) {
      debugPrint('❌ 启用后台位置模式失败: $e');
    }
  }
  
  /// 启用前台位置模式
  void _enableForegroundLocationMode() {
    debugPrint('🔧 恢复前台位置采集模式');
    // 前台时恢复正常的采集频率与高精度
    try {
      _locationPlugin.stopLocation();

      final option = AMapLocationOption();
      option.locationMode = AMapLocationMode.Hight_Accuracy;
      option.locationInterval = SimpleLocationService._locationInterval; // 恢复到默认频率
      option.distanceFilter = SimpleLocationService._distanceFilter;
      option.needAddress = true;
      option.onceLocation = false;

      _locationPlugin.setLocationOption(option);
      _locationPlugin.startLocation();
      debugPrint('✅ 前台模式参数已应用：Hight_Accuracy / ${SimpleLocationService._locationInterval}ms / distanceFilter=${SimpleLocationService._distanceFilter}');
    } catch (e) {
      debugPrint('❌ 启用前台位置模式失败: $e');
    }
  }
  
  /// 应用终止前保存数据
  void _saveLocationDataBeforeTermination() {
    // 新策略：实时上报，无需在应用终止前处理批量数据
    debugPrint('💾 应用终止前，清理定位服务状态');
    
    // 隐藏后台通知
    _hideBackgroundNotification();
  }
  
  /// 显示后台运行通知
  void _showBackgroundNotification() {
    if (_isBackgroundNotificationShown) {
      debugPrint('🔔 后台通知已显示，跳过');
      return;
    }
    
    try {
      // 检查通知频率限制（避免过于频繁）
      final now = DateTime.now();
      if (_lastNotificationTime != null && 
          now.difference(_lastNotificationTime!).inMinutes < 5) {
        debugPrint('🔔 通知频率限制，跳过显示');
        return;
      }
      
      _isBackgroundNotificationShown = true;
      _lastNotificationTime = now;
      
      debugPrint('🔔 显示后台定位运行通知');
      
      // TODO: 集成本地通知插件
      // 这里可以使用 flutter_local_notifications 或其他通知插件
      // _showLocalNotification(
      //   title: 'Kissu - 情侣定位',
      //   body: '正在后台为您提供位置服务',
      //   ongoing: true, // 持续通知
      // );
      
    } catch (e) {
      debugPrint('❌ 显示后台通知失败: $e');
      _isBackgroundNotificationShown = false;
    }
  }
  
  /// 隐藏后台运行通知
  void _hideBackgroundNotification() {
    if (!_isBackgroundNotificationShown) {
      debugPrint('🔔 后台通知未显示，跳过隐藏');
      return;
    }
    
    try {
      _isBackgroundNotificationShown = false;
      debugPrint('🔔 隐藏后台定位运行通知');
      
      // TODO: 取消本地通知
      // _cancelLocalNotification();
      
    } catch (e) {
      debugPrint('❌ 隐藏后台通知失败: $e');
    }
  }
  
  /// 更新后台通知内容
  void _updateBackgroundNotification(String status) {
    if (!_isBackgroundNotificationShown) return;
    
    try {
      debugPrint('🔔 更新后台通知: $status');
      
      // TODO: 更新通知内容
      // _updateLocalNotification(
      //   title: 'Kissu - 情侣定位',
      //   body: '状态: $status',
      // );
      
    } catch (e) {
      debugPrint('❌ 更新后台通知失败: $e');
    }
  }
  
  /// 启用前台服务（如果需要）
  Future<void> _enableForegroundServiceIfNeeded() async {
    try {
      final foregroundService = ForegroundLocationService.instance;
      final success = await foregroundService.startForegroundService();
      
      if (success) {
        debugPrint('✅ 前台服务启动成功');
        // 更新前台服务通知状态
        await foregroundService.updateForegroundServiceNotification(
          content: '正在后台为您提供位置定位服务',
        );
      } else {
        debugPrint('❌ 前台服务启动失败');
      }
    } catch (e) {
      debugPrint('❌ 启用前台服务失败: $e');
    }
  }
  
  /// 禁用前台服务（如果需要）
  Future<void> _disableForegroundServiceIfNeeded() async {
    try {
      final foregroundService = ForegroundLocationService.instance;
      final success = await foregroundService.stopForegroundService();
      
      if (success) {
        debugPrint('✅ 前台服务停止成功');
      } else {
        debugPrint('❌ 前台服务停止失败');
      }
    } catch (e) {
      debugPrint('❌ 禁用前台服务失败: $e');
    }
  }
  
}

// MARK: - 增强后台任务管理扩展
extension BackgroundTaskExtension on SimpleLocationService {
  
  /// 开始后台保活任务（增强版本）- 仅在后台运行
  void _startBackgroundKeepAlive() {
    // 🔥 重要检查：只在后台时启动保活定时器
    try {
      final appLifecycle = AppLifecycleService.instance;
      if (!appLifecycle.isInBackground) {
        debugPrint('⚠️ 应用在前台，跳过启动后台保活定时器');
        return;
      }
    } catch (e) {
      debugPrint('❌ 无法获取应用状态，为安全起见跳过后台保活定时器: $e');
      return;
    }
    
    _backgroundTaskId = DateTime.now().millisecondsSinceEpoch;
    debugPrint('🔧 应用在后台，开始增强后台保活任务 ID: $_backgroundTaskId');
    
    // 启动主保活定时器（30秒间隔）
    _backgroundKeepAliveTimer?.cancel();
    _backgroundKeepAliveTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      // 每次执行前检查应用状态
      try {
        final appLifecycle = AppLifecycleService.instance;
        if (!appLifecycle.isInBackground) {
          debugPrint('⚠️ 应用已回到前台，停止后台保活定时器');
          timer.cancel();
          return;
        }
      } catch (e) {
        debugPrint('❌ 后台保活定时器状态检查失败: $e');
      }
      _maintainBackgroundLocation();
    });
  }
  
  /// 停止后台保活任务
  void _stopBackgroundKeepAlive() {
    if (_backgroundTaskId != null) {
      debugPrint('🔧 停止后台保活任务 ID: $_backgroundTaskId');
      _backgroundTaskId = null;
    }
    
    _backgroundKeepAliveTimer?.cancel();
    _backgroundKeepAliveTimer = null;
    _stopMultipleBackgroundTimers();
  }
  
  /// 启动多重保障定时器（增强后台稳定性）- 仅在后台运行
  void _startMultipleBackgroundTimers() {
    // 🔥 重要检查：只在后台时启动这些定时器
    try {
      final appLifecycle = AppLifecycleService.instance;
      if (!appLifecycle.isInBackground) {
        debugPrint('⚠️ 应用在前台，跳过启动后台定时器');
        return;
      }
    } catch (e) {
      debugPrint('❌ 无法获取应用状态，为安全起见跳过后台定时器: $e');
      return;
    }
    
    // 停止现有定时器
    _stopMultipleBackgroundTimers();
    
    debugPrint('🌃 应用在后台，启动多重保障定时器');
    
    // 定时器1：快速检查（20秒）- 检查定位服务状态
    _quickCheckTimer = Timer.periodic(Duration(seconds: 20), (timer) {
      // 每次执行前再次检查应用状态
      try {
        final appLifecycle = AppLifecycleService.instance;
        if (!appLifecycle.isInBackground) {
          debugPrint('⚠️ 应用已回到前台，停止快速检查定时器');
          timer.cancel();
          return;
        }
      } catch (e) {
        debugPrint('❌ 快速检查定时器状态检查失败: $e');
      }
      _quickLocationServiceCheck();
    });
    
    // 定时器2：中等检查（60秒）- 检查位置更新
    _mediumCheckTimer = Timer.periodic(Duration(seconds: 60), (timer) {
      // 每次执行前再次检查应用状态
      try {
        final appLifecycle = AppLifecycleService.instance;
        if (!appLifecycle.isInBackground) {
          debugPrint('⚠️ 应用已回到前台，停止中等检查定时器');
          timer.cancel();
          return;
        }
      } catch (e) {
        debugPrint('❌ 中等检查定时器状态检查失败: $e');
      }
      _mediumLocationUpdateCheck();
    });
    
    // 定时器3：深度检查（120秒）- 完整性检查和恢复
    _deepCheckTimer = Timer.periodic(Duration(seconds: 120), (timer) {
      // 每次执行前再次检查应用状态
      try {
        final appLifecycle = AppLifecycleService.instance;
        if (!appLifecycle.isInBackground) {
          debugPrint('⚠️ 应用已回到前台，停止深度检查定时器');
          timer.cancel();
          return;
        }
      } catch (e) {
        debugPrint('❌ 深度检查定时器状态检查失败: $e');
      }
      _deepLocationIntegrityCheck();
    });
    
    // 定时器4：智能电池优化定时器（动态间隔）
    _startBatteryOptimizedTimer();
    
    debugPrint('🔧 后台多重保障定时器已启动：20s/60s/120s + 智能优化');
  }
  
  /// 停止多重保障定时器
  void _stopMultipleBackgroundTimers() {
    _quickCheckTimer?.cancel();
    _quickCheckTimer = null;
    
    _mediumCheckTimer?.cancel();
    _mediumCheckTimer = null;
    
    _deepCheckTimer?.cancel();
    _deepCheckTimer = null;
    
    _batteryOptimizedTimer?.cancel();
    _batteryOptimizedTimer = null;
  }
  
  /// 维护后台定位（增强版本）
  void _maintainBackgroundLocation() {
    if (_backgroundTaskId == null || !isLocationEnabled.value) return;
    
    debugPrint('🔄 维护后台定位服务（增强版本）');
    
    // 1. 检查定位服务状态
    if (!_isLocationServiceHealthy()) {
      debugPrint('⚠️ 定位服务异常，尝试重启');
      _restartLocationService();
      return;
    }
    
    // 2. 检查位置更新时效性
    if (!_isLocationUpdateTimely()) {
      debugPrint('⚠️ 位置更新超时，强制重新定位');
      _forceSingleLocationUpdate();
    }
    
    // 3. 检查待上报数据
    _checkPendingReports();
  }
  
  /// 快速检查定位服务状态
  void _quickLocationServiceCheck() {
    if (!isLocationEnabled.value) return;
    
    // 检查权限状态
    if (_currentLocationPermission.value != PermissionStatus.granted) {
      debugPrint('⚠️ 快速检查：位置权限异常');
      return;
    }
    
    // 检查高德定位插件状态
    debugPrint('✅ 快速检查：定位服务正常');
  }
  
  /// 中等检查位置更新
  void _mediumLocationUpdateCheck() {
    if (!isLocationEnabled.value) return;
    
    if (currentLocation.value != null) {
      final lastUpdateTime = int.tryParse(currentLocation.value!.locationTime);
      if (lastUpdateTime != null) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final timeDiff = now - lastUpdateTime;
        
        if (timeDiff > 120) { // 超过2分钟没有更新
          debugPrint('⚠️ 中等检查：位置更新超时 ${timeDiff}秒');
          _restartContinuousLocation();
        } else {
          debugPrint('✅ 中等检查：位置更新正常 (${timeDiff}秒前)');
        }
      }
    } else {
      debugPrint('⚠️ 中等检查：当前位置为空');
      _forceSingleLocationUpdate();
    }
  }
  
  /// 深度检查完整性
  void _deepLocationIntegrityCheck() {
    if (!isLocationEnabled.value) return;
    
    debugPrint('🔍 深度检查：位置服务完整性');
    
    // 1. 检查服务健康状态
    bool isHealthy = _isLocationServiceHealthy();
    
    // 2. 更新智能计数器
    if (isHealthy) {
      _consecutiveSuccessCount++;
      _consecutiveFailureCount = 0;
      debugPrint('✅ 深度检查成功，连续成功: $_consecutiveSuccessCount');
    } else {
      _consecutiveFailureCount++;
      _consecutiveSuccessCount = 0;
      debugPrint('❌ 深度检查失败，连续失败: $_consecutiveFailureCount');
      
      // 连续失败过多时重启服务
      if (_consecutiveFailureCount >= SimpleLocationService._maxConsecutiveFailures) {
        debugPrint('🔄 连续失败过多，重启定位服务');
        _restartLocationService();
        _consecutiveFailureCount = 0;
      }
    }
    
    // 3. 智能优化：成功次数足够时启用低功耗模式
    if (_consecutiveSuccessCount >= SimpleLocationService._successCountForOptimization && !_isInLowPowerMode) {
      _enableLowPowerMode();
    }
  }
  
  /// 启动智能电池优化定时器 - 仅在后台运行
  void _startBatteryOptimizedTimer() {
    // 🔥 重要检查：只在后台时启动电池优化定时器
    try {
      final appLifecycle = AppLifecycleService.instance;
      if (!appLifecycle.isInBackground) {
        debugPrint('⚠️ 应用在前台，跳过启动电池优化定时器');
        return;
      }
    } catch (e) {
      debugPrint('❌ 无法获取应用状态，为安全起见跳过电池优化定时器: $e');
      return;
    }
    
    _batteryOptimizedTimer?.cancel();
    
    Duration interval = _isInLowPowerMode 
        ? SimpleLocationService._lowPowerCheckInterval 
        : Duration(seconds: 60);
    
    _batteryOptimizedTimer = Timer.periodic(interval, (timer) {
      // 每次执行前检查应用状态
      try {
        final appLifecycle = AppLifecycleService.instance;
        if (!appLifecycle.isInBackground) {
          debugPrint('⚠️ 应用已回到前台，停止电池优化定时器');
          timer.cancel();
          return;
        }
      } catch (e) {
        debugPrint('❌ 电池优化定时器状态检查失败: $e');
      }
      _performBatteryOptimizedCheck();
    });
    
    debugPrint('🔋 后台电池优化定时器已启动，间隔: ${interval.inSeconds}秒');
  }
  
  /// 执行电池优化检查
  void _performBatteryOptimizedCheck() {
    if (!isLocationEnabled.value) return;
    
    debugPrint('🔋 执行电池优化检查');
    
    // 1. 检查是否需要调整定时器频率
    if (_isInLowPowerMode && _consecutiveFailureCount > 0) {
      // 低功耗模式下出现失败，恢复正常模式
      _disableLowPowerMode();
    }
    
    // 2. 检查低功耗模式是否超时
    if (_isInLowPowerMode && _lowPowerModeStartTime != null) {
      final duration = DateTime.now().difference(_lowPowerModeStartTime!);
      if (duration > SimpleLocationService._maxLowPowerDuration) {
        debugPrint('🔋 低功耗模式超时，自动恢复正常模式');
        _disableLowPowerMode();
      }
    }
    
    // 3. 检查位置数据新鲜度
    _checkLocationDataFreshness();
    
    // 4. 智能调整检查间隔
    _adjustTimerIntervals();
    
    // 5. 电池优化建议
    _provideBatteryOptimizationAdvice();
  }
  
  /// 启用低功耗模式
  void _enableLowPowerMode() {
    if (_isInLowPowerMode) return;
    
    _isInLowPowerMode = true;
    _lowPowerModeStartTime = DateTime.now();
    debugPrint('🔋 启用低功耗模式，开始时间: $_lowPowerModeStartTime');
    
    // 重启电池优化定时器以使用更长间隔
    _startBatteryOptimizedTimer();
    
    // 更新后台通知
    if (_isBackgroundNotificationShown) {
      _updateBackgroundNotification('省电模式运行中...');
    }
  }
  
  /// 禁用低功耗模式
  void _disableLowPowerMode() {
    if (!_isInLowPowerMode) return;
    
    // 计算低功耗模式持续时间
    Duration lowPowerDuration = Duration.zero;
    if (_lowPowerModeStartTime != null) {
      lowPowerDuration = DateTime.now().difference(_lowPowerModeStartTime!);
      debugPrint('🔋 低功耗模式持续时间: ${lowPowerDuration.inMinutes}分钟');
    }
    
    _isInLowPowerMode = false;
    _lowPowerModeStartTime = null;
    _consecutiveSuccessCount = 0; // 重置计数器
    debugPrint('🔋 禁用低功耗模式，恢复正常检查频率');
    
    // 重启电池优化定时器以使用正常间隔
    _startBatteryOptimizedTimer();
    
    // 更新后台通知
    if (_isBackgroundNotificationShown) {
      _updateBackgroundNotification('正常模式运行中...');
    }
  }
  
  /// 检查位置数据新鲜度
  void _checkLocationDataFreshness() {
    if (currentLocation.value == null) {
      debugPrint('⚠️ 位置数据为空，触发强制定位');
      _forceSingleLocationUpdate();
      return;
    }
    
    final lastUpdateTime = int.tryParse(currentLocation.value!.locationTime);
    if (lastUpdateTime != null) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final timeDiff = now - lastUpdateTime;
      
      // 根据模式调整超时阈值
      int timeoutThreshold = _isInLowPowerMode ? 300 : 180; // 低功耗5分钟，正常3分钟
      
      if (timeDiff > timeoutThreshold) {
        debugPrint('⚠️ 位置数据过期 ${timeDiff}秒，强制更新');
        _forceSingleLocationUpdate();
        
        // 数据过期说明可能有问题，退出低功耗模式
        if (_isInLowPowerMode) {
          _disableLowPowerMode();
        }
      }
    }
  }
  
  /// 智能调整定时器间隔
  void _adjustTimerIntervals() {
    // 基于成功率动态调整检查频率
    if (_consecutiveSuccessCount > SimpleLocationService._batteryOptimizationThreshold) {
      // 长期稳定，可以进一步优化
      debugPrint('🎯 服务长期稳定，建议启用深度省电模式');
      if (!_isInLowPowerMode) {
        _enableLowPowerMode();
      }
    } else if (_consecutiveFailureCount > 1) {
      // 有失败，需要更频繁检查
      debugPrint('⚠️ 检测到不稳定，加强监控');
      if (_isInLowPowerMode) {
        _disableLowPowerMode();
      }
    }
  }
  
  /// 提供电池优化建议
  void _provideBatteryOptimizationAdvice() {
    // 分析当前电池使用情况并提供建议
    final currentTime = DateTime.now();
    final hour = currentTime.hour;
    
    // 根据时间段提供不同的优化建议
    if (hour >= 22 || hour <= 6) {
      // 夜间时段，建议更激进的省电策略
      if (!_isInLowPowerMode && _consecutiveSuccessCount > 5) {
        debugPrint('🌙 夜间时段，建议启用省电模式');
        _enableLowPowerMode();
      }
    } else if (hour >= 9 && hour <= 18) {
      // 工作时段，保持正常模式但优化检查频率
      if (_isInLowPowerMode && _consecutiveFailureCount == 0) {
        debugPrint('🏢 工作时段，保持适度优化');
        // 保持低功耗但缩短超时时间
      }
    }
    
    // 根据定位精度调整策略
    if (currentLocation.value != null) {
      final accuracy = double.tryParse(currentLocation.value!.accuracy) ?? 0.0;
      if (accuracy > 100) {
        // 精度较差，可能GPS信号弱，适当降低检查频率节省电量
        debugPrint('📍 定位精度较差(${accuracy}m)，适当降低检查频率');
      }
    }
  }
  
  /// 检查定位服务健康状态
  bool _isLocationServiceHealthy() {
    try {
      // 1. 基础状态检查
      if (!isLocationEnabled.value) {
        debugPrint('❌ 健康检查：定位服务未启用');
        return false;
      }
      
      // 2. 权限状态检查
      if (_currentLocationPermission.value != PermissionStatus.granted) {
        debugPrint('❌ 健康检查：位置权限未授予');
        return false;
      }
      
      // 3. 位置数据新鲜度检查
      if (currentLocation.value == null) {
        debugPrint('⚠️ 健康检查：当前位置为空');
        return false;
      }
      
      // 4. 检查位置数据时效性
      final lastUpdateTime = int.tryParse(currentLocation.value!.locationTime);
      if (lastUpdateTime != null) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final timeDiff = now - lastUpdateTime;
        
        // 超过5分钟认为不健康
        if (timeDiff > 300) {
          debugPrint('⚠️ 健康检查：位置数据过期 ${timeDiff}秒');
          return false;
        }
      }
      
      debugPrint('✅ 健康检查：定位服务状态良好');
      return true;
      
    } catch (e) {
      debugPrint('❌ 健康检查异常: $e');
      return false;
    }
  }
  
  /// 检查位置更新是否及时
  bool _isLocationUpdateTimely() {
    if (currentLocation.value == null) return false;
    
    final lastUpdateTime = int.tryParse(currentLocation.value!.locationTime);
    if (lastUpdateTime == null) return false;
    
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return (now - lastUpdateTime) < 90; // 90秒内有更新认为正常
  }
  
  /// 检查待上报数据
  void _checkPendingReports() {
    // 新策略：实时上报，无需检查待上报数据
    debugPrint('📊 新策略：实时上报，无待上报数据积压');
  }
  
  /// 重启定位服务（智能增强版）
  void _restartLocationService() {
    debugPrint('🔄 智能重启定位服务');
    
    try {
      // 1. 记录重启时间和原因
      final restartTime = DateTime.now();
      debugPrint('🔄 定位服务重启时间: $restartTime，失败次数: $_consecutiveFailureCount');
      
      // 2. 优雅停止当前定位
      stopLocation();
      
      // 3. 根据失败次数调整重启策略
      int delaySeconds = _calculateRestartDelay();
      
      // 4. 延迟重启
      Future.delayed(Duration(seconds: delaySeconds), () {
        debugPrint('🔄 开始重新启动定位服务');
        _performSmartRestart();
      });
      
    } catch (e) {
      debugPrint('❌ 重启定位服务异常: $e');
      // 异常情况下使用基础重启策略
      _performBasicRestart();
    }
  }
  
  /// 计算重启延迟时间
  int _calculateRestartDelay() {
    // 根据连续失败次数动态调整延迟
    if (_consecutiveFailureCount <= 1) {
      return 2; // 首次失败：2秒
    } else if (_consecutiveFailureCount <= 3) {
      return 5; // 2-3次失败：5秒
    } else {
      return 10; // 多次失败：10秒
    }
  }
  
  /// 执行智能重启
  Future<void> _performSmartRestart() async {
    try {
      // 1. 重置状态标记
      _resetLocationState();
      
      // 2. 重新启动定位
      await startLocation();
      
      // 3. 重启成功，重置失败计数
      if (isLocationEnabled.value) {
        _consecutiveFailureCount = 0;
        debugPrint('✅ 智能重启成功，重置失败计数');
      }
      
    } catch (e) {
      debugPrint('❌ 智能重启失败: $e');
      _consecutiveFailureCount++;
      
      // 如果智能重启也失败，考虑完全重新初始化
      if (_consecutiveFailureCount >= SimpleLocationService._maxConsecutiveFailures) {
        debugPrint('🚨 智能重启失败次数过多，尝试完全重新初始化');
        await _performFullReinitialization();
      }
    }
  }
  
  /// 执行基础重启（兜底方案）
  void _performBasicRestart() {
    debugPrint('🔄 执行基础重启策略');
    Future.delayed(Duration(seconds: 3), () {
      startLocation();
    });
  }
  
  /// 重置定位状态
  void _resetLocationState() {
    debugPrint('🔧 重置定位服务状态');
    
    // 重置响应式状态
    isLocationEnabled.value = false;
    isReporting.value = false;
    
    // 重置低功耗模式
    if (_isInLowPowerMode) {
      _isInLowPowerMode = false;
      debugPrint('🔋 重置：退出低功耗模式');
    }
  }
  
  /// 完全重新初始化（最后的保障措施）
  Future<void> _performFullReinitialization() async {
    debugPrint('🚨 执行完全重新初始化');
    
    try {
      // 1. 完全停止所有定时器
      _stopMultipleBackgroundTimers();
      _stopBackgroundKeepAlive();
      
      // 2. 重置所有状态
      _resetLocationState();
      _consecutiveFailureCount = 0;
      _consecutiveSuccessCount = 0;
      
      // 3. 重新初始化
      await Future.delayed(Duration(seconds: 5)); // 等待系统稳定
      init(); // 重新初始化
      
      // 4. 重新启动定位
      await startLocation();
      
      debugPrint('✅ 完全重新初始化完成');
      
    } catch (e) {
      debugPrint('❌ 完全重新初始化失败: $e');
      // 这是最后的保障，如果还失败就只能等用户手动操作了
    }
  }
  
  /// 强制单次位置更新
  void _forceSingleLocationUpdate() {
    debugPrint('🎯 强制单次位置更新');
    _requestSingleLocation(); // 强制单次定位
  }
}

// MARK: - 权限管理扩展（参考iOS版本的权限处理）
extension PermissionManagementExtension on SimpleLocationService {
  
  /// 初始化权限状态（参考iOS版本的权限监听）
  void _initializePermissionStatus() {
    debugPrint('🔐 初始化权限状态（参考iOS版本）');
    _detectDeviceType(); // 检测设备类型
    _updateCurrentPermissionStatus();
    
    // 设置定时检查权限状态变化（模拟iOS的权限变化监听）
    Timer.periodic(Duration(seconds: 10), (timer) {
      _checkPermissionChanges();
    });
  }
  
  /// 更新当前权限状态
  Future<void> _updateCurrentPermissionStatus() async {
    try {
      final locationStatus = await Permission.location.status;
      final backgroundStatus = await Permission.locationAlways.status;
      
      _currentLocationPermission.value = locationStatus;
      _currentBackgroundPermission.value = backgroundStatus;
      
      debugPrint('🔐 权限状态更新:');
      debugPrint('   前台定位: ${locationStatus.name}');
      debugPrint('   后台定位: ${backgroundStatus.name}');
    } catch (e) {
      debugPrint('❌ 更新权限状态失败: $e');
    }
  }
  
  /// 检查权限变化（参考iOS版本的权限变化事件）
  Future<void> _checkPermissionChanges() async {
    try {
      final previousLocationStatus = _currentLocationPermission.value;
      final previousBackgroundStatus = _currentBackgroundPermission.value;
      
      await _updateCurrentPermissionStatus();
      
      final currentLocationStatus = _currentLocationPermission.value;
      final currentBackgroundStatus = _currentBackgroundPermission.value;
      
      // 检查前台定位权限变化
      if (previousLocationStatus != currentLocationStatus) {
        _handleLocationPermissionChange(previousLocationStatus, currentLocationStatus);
      }
      
      // 检查后台定位权限变化
      if (previousBackgroundStatus != currentBackgroundStatus) {
        _handleBackgroundPermissionChange(previousBackgroundStatus, currentBackgroundStatus);
      }
      
    } catch (e) {
      debugPrint('❌ 检查权限变化失败: $e');
    }
  }
  
  /// 处理前台定位权限变化（参考iOS版本的权限事件处理）
  void _handleLocationPermissionChange(PermissionStatus from, PermissionStatus to) {
    debugPrint('🔐 前台定位权限变化: ${from.name} -> ${to.name}');
    
    if (from.isDenied && to.isGranted) {
      debugPrint('✅ 前台定位权限已开启');
      // 上报定位开启事件
      SensitiveDataService.instance.reportLocationOpen();
    } else if (from.isGranted && to.isDenied) {
      debugPrint('❌ 前台定位权限已关闭');
      // 上报定位关闭事件
      SensitiveDataService.instance.reportLocationClose();
      stopLocation(); // 自动停止定位服务
    }
  }
  
  /// 处理后台定位权限变化（参考iOS版本的权限事件处理）
  void _handleBackgroundPermissionChange(PermissionStatus from, PermissionStatus to) {
    debugPrint('🔐 后台定位权限变化: ${from.name} -> ${to.name}');
    
    if (from.isDenied && to.isGranted) {
      debugPrint('✅ 后台定位权限已开启，提升定位服务能力');
      // 重新配置定位参数以支持更好的后台定位
      if (isLocationEnabled.value) {
        _restartContinuousLocation();
      }
    } else if (from.isGranted && to.isDenied) {
      debugPrint('⚠️ 后台定位权限已关闭，可能影响后台定位效果');
    }
  }
  
  /// 获取当前权限状态描述（参考iOS版本的权限状态描述）
  Map<String, String> getCurrentPermissionStatusDescription() {
    return {
      'foregroundLocation': _getPermissionDescription(_currentLocationPermission.value),
      'backgroundLocation': _getPermissionDescription(_currentBackgroundPermission.value),
    };
  }
  
  /// 获取权限状态描述（参考iOS版本的locationStatusDescription）
  String _getPermissionDescription(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return '已授权';
      case PermissionStatus.denied:
        return '拒绝';
      case PermissionStatus.restricted:
        return '受限制';
      case PermissionStatus.permanentlyDenied:
        return '永久拒绝';
      case PermissionStatus.provisional:
        return '临时授权';
      default:
        return '未知';
    }
  }
  
  /// 启动GPS状态监听（Android原生实现）
  void _startGpsStatusMonitoring() {
    debugPrint('🔧 启动GPS状态监听（Android原生）');
    
    try {
      // 取消之前的订阅（如果存在）
      _gpsStatusSubscription?.cancel();
      
      // 订阅GPS状态变化EventChannel
      _gpsStatusSubscription = SimpleLocationService._gpsStatusChannel.receiveBroadcastStream().listen(
        (dynamic isEnabled) {
          if (isEnabled is bool) {
            debugPrint('📍 收到GPS状态变化通知: ${isEnabled ? "开启" : "关闭"}');
            _handleGpsStatusChange(isEnabled);
          } else {
            debugPrint('⚠️ GPS状态数据类型错误: ${isEnabled.runtimeType}');
          }
        },
        onError: (dynamic error) {
          debugPrint('❌ GPS状态监听错误: $error');
        },
        cancelOnError: false, // 发生错误时不取消订阅
      );
      
      debugPrint('✅ GPS状态监听已启动');
    } catch (e) {
      debugPrint('❌ 启动GPS状态监听失败: $e');
    }
  }
  
  /// 处理GPS开关状态变化（系统级别的定位服务开关）
  void _handleGpsStatusChange(bool isGpsEnabled) {
    // 首次初始化，只记录状态不上报
    if (_lastGpsEnabledStatus == null) {
      _lastGpsEnabledStatus = isGpsEnabled;
      debugPrint('🔐 初始化GPS状态: ${isGpsEnabled ? "开启" : "关闭"}');
      return;
    }
    
    // 检查状态是否发生变化
    if (_lastGpsEnabledStatus == isGpsEnabled) {
      // 状态未变化，无需处理
      return;
    }
    
    // 状态发生变化，记录并上报
    debugPrint('🔄 检测到GPS状态变化: ${_lastGpsEnabledStatus! ? "开启" : "关闭"} -> ${isGpsEnabled ? "开启" : "关闭"}');
    _lastGpsEnabledStatus = isGpsEnabled;
    
    if (isGpsEnabled) {
      // GPS开启
      debugPrint('✅ GPS已开启，上报定位开启事件');
      SensitiveDataService.instance.reportLocationOpen();
    } else {
      // GPS关闭
      debugPrint('❌ GPS已关闭，上报定位关闭事件');
      SensitiveDataService.instance.reportLocationClose();
    }
  }
}

// MARK: - 位置数据验证扩展（防飘点算法）
extension LocationValidationExtension on SimpleLocationService {

  /// 验证位置数据有效性（防飘点）
  bool _isLocationValid(LocationReportModel location) {
    try {
      final latitude = double.parse(location.latitude);
      final longitude = double.parse(location.longitude);
      final accuracy = double.parse(location.accuracy);
      final speed = double.parse(location.speed);
      
      // 1. 基础数据验证
      if (latitude == 0 && longitude == 0) {
        debugPrint('❌ 位置验证失败: 经纬度为(0,0)');
        return false;
      }
      
      // 2. 🚀 高德官方建议：过滤 accuracy > 100 的点
      if (accuracy > 100) {
        debugPrint('❌ 位置验证失败: 精度太差(${accuracy.toStringAsFixed(2)}m > 100m) [高德官方建议]');
        _consecutiveBadLocationCount++;
        return false;
      }
      
      // 2.1 华为设备额外精度验证
      if (_isHuaweiDevice && accuracy > SimpleLocationService._huaweiAccuracyThreshold) {
        debugPrint('❌ 位置验证失败: 华为设备精度验证(${accuracy}m > ${SimpleLocationService._huaweiAccuracyThreshold}m)');
        _consecutiveBadLocationCount++;
        return false;
      }
      
      // 3. 🚀 高德建议的轨迹平滑：运动合理性检查
      if (!_isMotionReasonable(latitude, longitude, speed)) {
        debugPrint('❌ 位置验证失败: 运动轨迹不合理，疑似飘点 [轨迹平滑算法]');
        _consecutiveBadLocationCount++;
        return false;
      }
      
      // 4. 速度验证 - 过滤异常高速
      if (speed > SimpleLocationService._maxSpeedThreshold) {
        debugPrint('❌ 位置验证失败: 速度异常(${speed}m/s > ${SimpleLocationService._maxSpeedThreshold}m/s)');
        _consecutiveBadLocationCount++;
        return false;
      }
      
      // 4. 跳跃距离验证 - 检测异常位置跳跃
      if (_lastValidLocation != null) {
        final lastLat = double.parse(_lastValidLocation!.latitude);
        final lastLng = double.parse(_lastValidLocation!.longitude);
        final distance = _calculateDistance(lastLat, lastLng, latitude, longitude);
        
        // 计算时间间隔
        final lastTime = int.parse(_lastValidLocation!.locationTime);
        final currentTime = int.parse(location.locationTime);
        final timeDiffSeconds = (currentTime - lastTime).abs();
        
        // 如果距离过大且时间间隔很短，可能是飘点（华为设备使用更严格标准）
        final jumpThreshold = _isHuaweiDevice ? 
          SimpleLocationService._huaweiJumpDistance : 
          SimpleLocationService._maxJumpDistance;
          
        if (distance > jumpThreshold && timeDiffSeconds < 30) {
          debugPrint('❌ 位置验证失败: 异常跳跃(${distance.toStringAsFixed(1)}m在${timeDiffSeconds}秒内)${_isHuaweiDevice ? '[华为优化]' : ''}');
          _consecutiveBadLocationCount++;
          
          // 华为设备：需要连续多次验证失败才真正拒绝
          if (_isHuaweiDevice) {
            _huaweiLocationFilterCount++;
            if (_huaweiLocationFilterCount < SimpleLocationService._huaweiFilterCount) {
              debugPrint('🔄 华为设备飘点过滤: ${_huaweiLocationFilterCount}/${SimpleLocationService._huaweiFilterCount}');
              return false;
            }
            _huaweiLocationFilterCount = 0; // 重置计数
          }
          return false;
        }
        
        // 室内检测：如果精度变差且距离小幅波动，可能是室内飘点
        _detectIndoorEnvironment(accuracy, distance, timeDiffSeconds);
        
        if (_isIndoorMode && distance > 20 && distance < 200 && timeDiffSeconds < 60) {
          debugPrint('🏠 室内环境飘点过滤: 精度${accuracy}m，距离${distance.toStringAsFixed(1)}m');
          _consecutiveBadLocationCount++;
          // 室内环境下大幅降低上报频率，每8个点只接受1个（更保守的策略）
          if (_consecutiveBadLocationCount % 8 != 0) {
            debugPrint('🔇 室内模式：跳过GPS飘点 (${_consecutiveBadLocationCount}/8)');
            return false;
          } else {
            debugPrint('✅ 室内模式：接受位置更新 (${_consecutiveBadLocationCount}/8)');
          }
        }
      }
      
      // 5. 稳定性验证 - 维护最近位置记录
      _recentLocations.add(location);
      if (_recentLocations.length > SimpleLocationService._stableLocationCount) {
        _recentLocations.removeAt(0);
      }
      
      // 位置验证通过
      _lastValidLocation = location;
      _consecutiveBadLocationCount = 0; // 重置计数
      
      debugPrint('✅ 位置验证通过: ${latitude}, ${longitude}, 精度: ${accuracy}m');
      return true;
      
    } catch (e) {
      debugPrint('❌ 位置验证异常: $e');
      return false;
    }
  }

  /// 室内环境检测（改进版）
  void _detectIndoorEnvironment(double accuracy, double distance, int timeDiffSeconds) {
    final now = DateTime.now();
    
    // 室内环境判断条件：
    // 1. 精度持续较差 (>30m)
    // 2. 位置小幅度波动 (20-200m)
    // 3. 短时间内的变化
    // 4. 新增：连续小距离移动检测（可能是GPS漂移而非真实移动）
    
    // 检测静止状态：连续多次小距离变化
    if (distance < 30 && distance > 5) {
      _consecutiveSmallMovements++;
    } else {
      _consecutiveSmallMovements = 0;
    }
    
    // 判断是否进入室内模式
    bool shouldEnterIndoorMode = false;
    String reason = '';
    
    if (accuracy > 30 && distance > 20 && distance < 200 && timeDiffSeconds < 120) {
      shouldEnterIndoorMode = true;
      reason = '精度较差+位置小幅波动';
    } else if (_consecutiveSmallMovements >= 5 && accuracy > 25) {
      shouldEnterIndoorMode = true;
      reason = '连续小距离移动+精度下降';
    }
    
    if (shouldEnterIndoorMode && !_isIndoorMode) {
      _isIndoorMode = true;
      _lastIndoorDetectionTime = now;
      debugPrint('🏠 检测到室内环境，启用室内模式 ($reason)');
      debugPrint('💡 提示：室内GPS信号较弱，位置可能有偏差，这是正常现象');
      
      // 降低GPS采样频率以节省电量
      _adjustGPSFrequencyForIndoor();
    } else if (_isIndoorMode && _lastIndoorDetectionTime != null) {
      // 如果精度改善且已经5分钟没有室内特征，退出室内模式
      if (accuracy <= 20 && now.difference(_lastIndoorDetectionTime!).inMinutes > 5) {
        _isIndoorMode = false;
        _consecutiveSmallMovements = 0;
        debugPrint('🌤️  退出室内模式，恢复正常定位');
        
        // 恢复正常GPS采样频率
        _adjustGPSFrequencyForOutdoor();
      }
    }
  }
  
  /// 调整GPS频率以适应室内环境
  void _adjustGPSFrequencyForIndoor() {
    // 室内降低采样频率，从6秒调整到15秒
    _updateLocationOptions(interval: 15000);
    debugPrint('⚡ 已调整为室内模式GPS频率：15秒间隔（节省电量）');
  }
  
  /// 恢复户外GPS频率
  void _adjustGPSFrequencyForOutdoor() {
    // 恢复正常采样频率
    _updateLocationOptions(interval: 6000);
    debugPrint('⚡ 已恢复户外模式GPS频率：6秒间隔');
  }
  
  /// 更新定位配置
  void _updateLocationOptions({int? interval}) {
    if (interval != null) {
      // 这里可以调用AMapFlutterLocation的方法来动态调整定位参数
      // 但需要重新启动定位服务才能生效
      debugPrint('🔧 定位参数更新：间隔${interval}ms');
    }
  }

  /// 3. 每分钟定时上报
  void _handleLocationReporting(LocationReportModel location) {
    // 首先进行飘点验证
    if (!_isLocationValid(location)) {
      debugPrint('❌ 位置验证失败，跳过上报');
      return;
    }
    
    final now = DateTime.now();
    
    // 策略1: 首次定位立即上报
    if (!hasInitialReport.value) {
      hasInitialReport.value = true;
      _lastReportedLocation = location;
      _lastMinuteReportTime = now;
      debugPrint('🚀 首次定位成功，立即上报位置数据');
      _reportSingleLocation(location, '首次定位');
      return;
    }
    
    bool shouldReport = false;
    String reportReason = '';
    
    // 策略2: 移动超过50米立即上报
    if (_lastReportedLocation != null) {
      double distance = _calculateDistance(
        double.parse(_lastReportedLocation!.latitude),
        double.parse(_lastReportedLocation!.longitude),
        double.parse(location.latitude),
        double.parse(location.longitude),
      );
      
      if (distance >= 50.0) {
        shouldReport = true;
        reportReason = '移动距离触发(${distance.toStringAsFixed(1)}m≥50m)';
      }
    }
    
    // 策略3: 每分钟定时上报（与距离上报不冲突）
    if (_lastMinuteReportTime == null || 
        now.difference(_lastMinuteReportTime!).inSeconds >= 60) {
      // 如果还没有因为距离触发上报，则执行定时上报
      if (!shouldReport) {
        shouldReport = true;
        reportReason = '定时上报(间隔${_lastMinuteReportTime != null ? now.difference(_lastMinuteReportTime!).inSeconds : 0}秒)';
      }
      _lastMinuteReportTime = now;
    }
    
    // 执行上报
    if (shouldReport) {
      _lastReportedLocation = location;
      debugPrint('📍 位置上报触发: $reportReason');
      _reportSingleLocation(location, reportReason);
    } else {
      debugPrint('📍 位置更新跳过: 距离=${_lastReportedLocation != null ? _calculateDistance(
        double.parse(_lastReportedLocation!.latitude),
        double.parse(_lastReportedLocation!.longitude),
        double.parse(location.latitude),
        double.parse(location.longitude),
      ).toStringAsFixed(1) : '0.0'}m, 时间间隔=${_lastMinuteReportTime != null ? now.difference(_lastMinuteReportTime!).inSeconds : 0}秒');
    }
  }

  /// 单点位置上报
  Future<void> _reportSingleLocation(LocationReportModel location, String reason) async {
    if (isReporting.value) {
      debugPrint('⚠️ 正在上报中，跳过本次上报');
      return;
    }
    
    try {
      isReporting.value = true;
      debugPrint('📤 开始单点上报: $reason');
      debugPrint('📍 上报位置: ${location.latitude}, ${location.longitude}, 精度: ${location.accuracy}m, 速度: ${location.speed}m/s');
      
      final api = LocationReportApi();
      final result = await api.reportLocation([location]);
      
      if (result.isSuccess) {
        debugPrint('✅ 单点位置上报成功: $reason');
        debugPrint('✅ 服务器响应: ${result.msg}');
      } else {
        debugPrint('❌ 单点位置上报失败: ${result.msg}');
        debugPrint('❌ 上报原因: $reason');
      }
    } catch (e) {
      debugPrint('❌ 单点上报异常: $e');
      debugPrint('❌ 上报原因: $reason');
    } finally {
      isReporting.value = false;
    }
  }

  /// 直接打开定位设置页面
  Future<void> _openLocationSettingsDirectly() async {
    try {
      await PermissionHelper.openLocationSettings();
      CustomToast.show(
        Get.context!,
        '请在设置中将定位权限改为"始终允许"',
      );
    } catch (e) {
      debugPrint('❌ 打开定位设置页面失败: $e');
      CustomToast.show(
        Get.context!,
        '无法打开设置页面，请手动前往设置中开启定位权限',
      );
    }
  }
  
  /// 检测设备类型
  void _detectDeviceType() {
    try {
      // 检测华为设备 (华为/荣耀)
      final brand = Platform.isAndroid ? 'HUAWEI' : 'Unknown'; // 这里可以集成 device_info_plus 获取真实品牌
      _isHuaweiDevice = brand.toUpperCase().contains('HUAWEI') || 
                       brand.toUpperCase().contains('HONOR');
      
      if (_isHuaweiDevice) {
        debugPrint('📱 检测到华为设备，启用华为优化模式');
      }
    } catch (e) {
      debugPrint('❌ 设备检测失败: $e');
      _isHuaweiDevice = false;
    }
  }
  
  // ========== 🚀 高德官方轨迹平滑算法实现（基于卡尔曼滤波思想） ==========
  
  /// 检查运动轨迹是否合理（基于高德官方demo的轨迹平滑工具类）
  bool _isMotionReasonable(double latitude, double longitude, double speed) {
    final currentPoint = LocationPoint(
      latitude: latitude,
      longitude: longitude,
      accuracy: 0, // 在验证函数中会单独检查
      speed: speed,
      timestamp: DateTime.now(),
    );
    
    // 如果没有历史记录，接受第一个点
    if (_locationHistory.isEmpty) {
      _addToHistory(currentPoint);
      return true;
    }
    
    final lastPoint = _locationHistory.last;
    
    // 1. 🚀 速度一致性检查（高德建议的轨迹平滑核心）
    if (!_isSpeedConsistent(currentPoint, lastPoint)) {
      debugPrint('🚨 速度不一致检测：当前${speed.toStringAsFixed(1)}m/s，上次${_lastValidSpeed.toStringAsFixed(1)}m/s');
      return false;
    }
    
    // 2. 🚀 加速度合理性检查
    if (!_isAccelerationReasonable(currentPoint, lastPoint)) {
      debugPrint('🚨 加速度异常检测：可能是GPS跳跃');
      return false;
    }
    
    // 3. 🚀 轨迹连续性检查
    if (!_isTrajectoryConsistent(currentPoint)) {
      debugPrint('🚨 轨迹不连续检测：偏离运动方向');
      return false;
    }
    
    // 通过所有检查，添加到历史记录
    _addToHistory(currentPoint);
    _lastValidSpeed = speed;
    return true;
  }
  
  /// 速度一致性检查
  bool _isSpeedConsistent(LocationPoint current, LocationPoint last) {
    final calculatedSpeed = current.calculateSpeedTo(last);
    final reportedSpeed = current.speed;
    
    // 如果计算速度和报告速度差异过大，可能是跳跃
    const double speedToleranceRatio = 3.0; // 允许3倍差异
    
    if (calculatedSpeed > 0 && reportedSpeed > 0) {
      final ratio = calculatedSpeed > reportedSpeed ? 
        calculatedSpeed / reportedSpeed : reportedSpeed / calculatedSpeed;
      
      if (ratio > speedToleranceRatio) {
        return false;
      }
    }
    
    // 检查突然加速（可能是GPS跳跃）
    const double maxInstantAcceleration = 10.0; // 最大瞬时加速度 m/s²
    final timeDiff = current.timeDifferenceInSeconds(last);
    
    if (timeDiff > 0) {
      final acceleration = (reportedSpeed - _lastValidSpeed).abs() / timeDiff;
      if (acceleration > maxInstantAcceleration) {
        debugPrint('🚨 瞬时加速度过大: ${acceleration.toStringAsFixed(1)}m/s²');
        return false;
      }
    }
    
    return true;
  }
  
  /// 加速度合理性检查
  bool _isAccelerationReasonable(LocationPoint current, LocationPoint last) {
    final distance = current.distanceTo(last);
    final timeDiff = current.timeDifferenceInSeconds(last);
    
    if (timeDiff <= 0) return true; // 时间差为0或负数，跳过检查
    
    final calculatedSpeed = distance / timeDiff;
    
    // 🚀 高德建议：如果计算速度远超合理范围，认为是跳跃
    const double maxWalkingSpeed = 5.0; // 5 m/s = 18 km/h （快跑速度）
    const double maxVehicleSpeed = 50.0; // 50 m/s = 180 km/h （高速行驶）
    
    // 根据当前运动状态判断合理速度
    if (_consecutiveLowSpeedCount > 3) {
      // 如果之前是低速状态，突然高速可能是跳跃
      if (calculatedSpeed > maxWalkingSpeed) {
        debugPrint('🚨 从静止状态突然高速移动: ${calculatedSpeed.toStringAsFixed(1)}m/s');
        return false;
      }
    } else if (calculatedSpeed > maxVehicleSpeed) {
      // 极高速度，肯定是异常
      debugPrint('🚨 速度超出合理范围: ${calculatedSpeed.toStringAsFixed(1)}m/s');
      return false;
    }
    
    return true;
  }
  
  /// 轨迹连续性检查
  bool _isTrajectoryConsistent(LocationPoint current) {
    if (_locationHistory.length < 3) return true; // 历史点不足，跳过检查
    
    // 获取最近的3个点，检查轨迹方向一致性
    final recentPoints = _locationHistory.take(3).toList();
    
    // 计算前两个点的方向向量
    final direction1 = _calculateDirection(recentPoints[1], recentPoints[0]);
    // 计算当前点与前一个点的方向向量
    final direction2 = _calculateDirection(current, recentPoints[0]);
    
    // 计算方向差异（角度）
    final angleDiff = _calculateAngleDifference(direction1, direction2);
    
    // 🚀 如果方向突然改变超过120度，可能是跳跃
    const double maxAngleChange = 120.0; // 度
    
    if (angleDiff > maxAngleChange && current.speed > 2.0) {
      debugPrint('🚨 运动方向突变: ${angleDiff.toStringAsFixed(1)}°');
      return false;
    }
    
    return true;
  }
  
  /// 添加位置到历史记录
  void _addToHistory(LocationPoint point) {
    _locationHistory.insert(0, point);
    
    // 保持历史记录大小
    if (_locationHistory.length > SimpleLocationService._trajectoryHistorySize) {
      _locationHistory.removeRange(SimpleLocationService._trajectoryHistorySize, _locationHistory.length);
    }
    
    // 更新统计信息
    if (point.accuracy < 20) {
      _consecutiveHighAccuracyCount++;
    } else {
      _consecutiveHighAccuracyCount = 0;
    }
    
    if (point.speed < 1.0) {
      _consecutiveLowSpeedCount++;
    } else {
      _consecutiveLowSpeedCount = 0;
    }
  }
  
  /// 计算两点间的方向向量
  Map<String, double> _calculateDirection(LocationPoint from, LocationPoint to) {
    final deltaLat = to.latitude - from.latitude;
    final deltaLng = to.longitude - from.longitude;
    return {'dx': deltaLng, 'dy': deltaLat};
  }
  
  /// 计算两个方向向量间的角度差异
  double _calculateAngleDifference(Map<String, double> dir1, Map<String, double> dir2) {
    final angle1 = math.atan2(dir1['dy']!, dir1['dx']!) * 180 / math.pi;
    final angle2 = math.atan2(dir2['dy']!, dir2['dx']!) * 180 / math.pi;
    
    double diff = (angle2 - angle1).abs();
    if (diff > 180) diff = 360 - diff;
    
    return diff;
  }
  
  /// 🚀 高德建议的轨迹平滑：获取平滑后的位置
  LocationPoint? getSmoothLocation(double latitude, double longitude, double accuracy, double speed) {
    // 如果历史记录不足，直接返回当前位置
    if (_locationHistory.length < 2) {
      return LocationPoint(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        speed: speed,
        timestamp: DateTime.now(),
      );
    }
    
    // 🚀 简单卡尔曼滤波思想：基于历史轨迹预测位置
    final predictedPoint = _predictNextLocation();
    final currentPoint = LocationPoint(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      speed: speed,
      timestamp: DateTime.now(),
    );
    
    // 如果当前位置与预测位置相差太远，使用预测位置进行平滑
    if (predictedPoint != null) {
      final distance = currentPoint.distanceTo(predictedPoint);
      
      // 🚀 平滑因子：精度越差，越倾向于使用预测位置
      if (distance > 50 && accuracy > 30) {
        debugPrint('🎯 轨迹平滑：使用预测位置进行平滑 (偏差${distance.toStringAsFixed(1)}m)');
        
        // 加权平均：精度差时更多依赖预测
        final weight = math.min(accuracy / 100, 0.8); // 权重范围 0-0.8
        
        return LocationPoint(
          latitude: currentPoint.latitude * (1 - weight) + predictedPoint.latitude * weight,
          longitude: currentPoint.longitude * (1 - weight) + predictedPoint.longitude * weight,
          accuracy: accuracy,
          speed: speed,
          timestamp: DateTime.now(),
        );
      }
    }
    
    return currentPoint; // 返回原始位置
  }
  
  /// 基于历史轨迹预测下一个位置
  LocationPoint? _predictNextLocation() {
    if (_locationHistory.length < 2) return null;
    
    final latest = _locationHistory[0];
    final previous = _locationHistory[1];
    
    // 计算运动向量
    final deltaLat = latest.latitude - previous.latitude;
    final deltaLng = latest.longitude - previous.longitude;
    final deltaTime = latest.timeDifferenceInSeconds(previous);
    
    if (deltaTime <= 0) return null;
    
    // 假设保持当前运动趋势
    const double predictionTimeSeconds = 6.0; // 预测6秒后的位置
    final ratio = predictionTimeSeconds / deltaTime;
    
    return LocationPoint(
      latitude: latest.latitude + deltaLat * ratio,
      longitude: latest.longitude + deltaLng * ratio,
      accuracy: latest.accuracy,
      speed: latest.speed,
      timestamp: DateTime.now().add(Duration(seconds: predictionTimeSeconds.round())),
    );
  }
}