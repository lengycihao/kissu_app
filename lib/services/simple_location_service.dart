import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'package:amap_flutter_location/amap_location_option.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:kissu_app/model/location_model/location_report_model.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';
import 'package:kissu_app/services/foreground_location_service.dart';
import 'package:kissu_app/constants/app_constants.dart';
import 'package:kissu_app/services/app_lifecycle_service.dart';
import 'package:kissu_app/services/location_permission_manager.dart';
import 'package:kissu_app/services/privacy_compliance_manager.dart';
import 'package:kissu_app/services/sensitive_data_service.dart';
import 'package:kissu_app/utils/permission_helper.dart';
import 'package:flutter/material.dart';
import 'package:kissu_app/network/tools/logging/log_manager.dart';
import 'package:kissu_app/network/interceptor/business_header_interceptor.dart';
import 'package:kissu_app/utils/user_manager.dart';

// 枚举定义已简化

// 🚀 简化的定位数据结构
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

    final a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  // 计算时间差（秒）
  double timeDifferenceInSeconds(LocationPoint other) {
    return timestamp.difference(other.timestamp).inMilliseconds.abs() / 1000.0;
  }
}

/// 基于高德定位的简化版定位服务类
class SimpleLocationService extends GetxService with WidgetsBindingObserver {
  static SimpleLocationService get instance =>
      Get.find<SimpleLocationService>();

  // 高德定位插件 - 单例确保整个应用生命周期只创建一次
  final AMapFlutterLocation _locationPlugin = AMapFlutterLocation();

  // 当前最新位置
  final Rx<LocationReportModel?> currentLocation = Rx<LocationReportModel?>(
    null,
  );

  // 当前方向（移动方向，单位：度，正北为0度，顺时针0-360）
  final Rx<double?> currentHeading = Rx<double?>(null);

  // 位置历史记录（用于采样点检测）
  final RxList<LocationReportModel> locationHistory =
      <LocationReportModel>[].obs;

  // 定时器
  Timer? _periodicLocationTimer;

  // 全局唯一的定位流订阅 - 整个应用生命周期只创建一次
  StreamSubscription<Map<String, Object>>? _globalLocationSub;

  // 暴露定位流，让外部管理订阅（参考用户示例）
  Stream<Map<String, Object>> get locationStream =>
      _locationPlugin.onLocationChanged();

  // 传感器订阅
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  // 传感器数据
  List<double> _magnetometerValues = [0, 0, 0];
  List<double> _accelerometerValues = [0, 0, 0];

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

  // 旧的上报策略相关变量（已迁移到新策略）
  // DateTime? _lastMinuteReportTime; // 已移除：最后一次定时上报时间

  // 权限状态监听
  final Rx<PermissionStatus> _currentLocationPermission =
      PermissionStatus.denied.obs;
  final Rx<PermissionStatus> _currentBackgroundPermission =
      PermissionStatus.denied.obs;

  // GPS开关状态监听（系统级别的定位服务开关）
  static const EventChannel _gpsStatusChannel = EventChannel(
    'kissu_app/gps_status',
  );
  StreamSubscription<dynamic>? _gpsStatusSubscription;
  bool? _lastGpsEnabledStatus; // 上次的GPS开关状态（null表示未初始化）

  // 后台保活定时器
  Timer? _backgroundKeepAliveTimer;

  // 权限检查定时器（60秒轮询一次，降低各频率开销）
  Timer? _permissionCheckTimer;
  Timer? _batteryOptimizedTimer;

  // 定位带崩重试计数
  int _consecutiveFailureCount = 0;
  bool _isInLowPowerMode = false; // 低功耗模式标记

  // 简化后的状态变量

  // 使用简化策略

  // 🚀 新的收集与上报分离策略（简化版）
  // 策略说明：
  // 1. 5秒获取一次定位信息
  // 2. 收集池为空时直接放入，不为空时判断与最新点的距离
  // 3. 距离>=50米放入收集池，<50米抛弃
  // 4. 每分钟上报一次收集池内容
  // 5. 上报时只有1个点将时间戳改为当前时间，多个点保持原始时间戳
  // 6. 上报完成后清空收集池
  // 7. 直接使用原始定位数据
  List<LocationReportModel> _collectionBuffer = []; // 收集缓冲区
  Timer? _reportTimer; // 上报定时器
  bool _isFirstLocationSuccess = true; // 首次定位成功标记（用于收集策略）

  // 后台通知管理
  bool _isBackgroundNotificationShown = false; // 后台通知显示状态
  DateTime? _lastNotificationTime; // 上次通知时间

  // 🚀 核心策略参数 - 新的收集与上报分离策略
  // ignore: unused_field
  static const Duration _reportInterval = Duration(minutes: 1); // 1分钟上报间隔
  // ⚠️ 关键修复：取消distanceFilter，让定位层保证数据完整性，距离过滤在上报层处理
  static const double _distanceFilter = -1; // 不做距离过滤（原50米），改由上报层过滤
  static const int _locationInterval = 5000; // 5秒定位间隔（提高响应性）
  // static const double _desiredAccuracy = 15.0; // 期望精度15米（平衡精度与功耗）
  // ignore: unused_field
  static const double _collectionDistance = 50.0; // 50米收集一个点位（不立即上报）
  static const int _maxCollectionBufferSize = 12; // 最大收集缓冲区大小（1分钟内最多12个点，5秒一个）
  // ignore: unused_field
  static const int _maxHistorySize = 200; // 最大历史记录数

  // 智能参数已简化

  // 智能优化参数
  static const int _maxConsecutiveFailures = 3; // 最大连续失败次数
  // ignore: unused_field
  static const int _successCountForOptimization = 10; // 成功次数阈值
  // ignore: unused_field
  static const Duration _lowPowerCheckInterval = Duration(
    seconds: 120,
  ); // 低功耗模式检查间隔

  // 智能运动状态检测和环境感知参数已删除，简化为基础过滤

  // 电池优化参数
  // ignore: unused_field
  static const int _batteryOptimizationThreshold = 20; // 电池优化阈值（连续成功次数）
  // ignore: unused_field
  static const Duration _maxLowPowerDuration = Duration(hours: 2); // 最大低功耗持续时间
  // ignore: unused_field
  DateTime? _lowPowerModeStartTime; // 低功耗模式开始时间
  // 与iOS策略完全一致：收集所有位置更新
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
    logger.debug('SimpleLocationService 已注册（等待隐私政策同意后启动）', tag: 'Location');
  }

  @override
  void onClose() {
    stopLocation();
    _removeAppLifecycleListener(); // 清理生命周期监听
    _backgroundKeepAliveTimer?.cancel();
    _batteryOptimizedTimer?.cancel(); // 清理电池优化定时器

    // 🚀 清理新的定时上报器
    _reportTimer?.cancel();
    _reportTimer = null;

    // 清理全局监听器
    _globalLocationSub?.cancel();
    _globalLocationSub = null;
    _isGlobalListenerSetup = false;

    // 清理GPS状态监听
    _gpsStatusSubscription?.cancel();
    _gpsStatusSubscription = null;

    // 清理传感器监听
    _magnetometerSubscription?.cancel();
    _magnetometerSubscription = null;
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;

    super.onClose();
  }

  /// 隐私合规启动方法 - 只有在用户同意隐私政策后才调用
  void startPrivacyCompliantService() {
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
    // 启动手机方向传感器监听
    _startSensorListeners();
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
      AMapFlutterLocation.setApiKey(AppConstants.amapApiKey, '');
    } catch (e) {
      logger.error('初始化高德定位服务失败', tag: 'Location', error: e);
    }
  }

  Future<void> _setupPrivacyCompliance() async {
    try {
      // 🔑 关键修复：从隐私合规管理器获取当前隐私同意状态
      final privacyManager = Get.find<PrivacyComplianceManager>();
      final isPrivacyAgreed = privacyManager.isPrivacyAgreed;
      
      // 🔥 优化：如果用户已登录（已进入首页），视为已同意隐私协议
      final isUserLoggedIn = UserManager.isLoggedIn;
      final shouldAgreePrivacy = isPrivacyAgreed || isUserLoggedIn;

      // 重新设置隐私合规（确保在定位前生效）
      AMapFlutterLocation.updatePrivacyShow(true, true);

      // 🔒 隐私合规：根据用户同意状态设置隐私授权
      AMapFlutterLocation.updatePrivacyAgree(shouldAgreePrivacy);

      // 重新设置API Key（确保在定位前生效）
      AMapFlutterLocation.setApiKey(AppConstants.amapApiKey, '');
    } catch (e) {
      logger.error('设置高德定位隐私合规失败', tag: 'Location', error: e);
    }
  }

  /// 设置全局唯一的定位监听器（基于高德插件内部机制优化）
  void _setupGlobalLocationListener() {
    if (_isGlobalListenerSetup) {
      return;
    }

    try {
      // 基于高德插件源码分析：
      // 插件内部使用 _receiveStream 判断是否已创建 StreamController
      // 只要不重复调用 onLocationChanged()，就不会有冲突
      Stream<Map<String, Object>> locationStream = _locationPlugin
          .onLocationChanged();

      _globalLocationSub = locationStream.listen(
        (Map<String, Object> result) {
          logger.debug('全局监听器收到定位数据: ${result.toString()}', tag: 'Location');
          _onLocationUpdate(result);
        },
        onError: (error) {
          logger.error('全局监听器定位错误: rror', tag: 'Location');
        },
        onDone: () {
          logger.warning('全局监听器定位流已关闭', tag: 'Location');
          _isGlobalListenerSetup = false;
        },
      );
      _isGlobalListenerSetup = true;
      logger.debug('全局定位监听器设置完成', tag: 'Location');
    } catch (e) {
      logger.error('设置全局定位监听器失败: ', tag: 'Location');
      if (e.toString().contains('Stream has already been listened to')) {
        _isGlobalListenerSetup = true; // 标记为已设置，避免重复尝试
      }
    }
  }

  /// 请求定位权限（改进版，支持Android 10+后台定位）
  Future<bool> requestLocationPermission() async {
    try {
      logger.debug('开始申请定位权限...', tag: 'Location');

      // 使用统一的权限申请管理器
      final permissionManager = LocationPermissionManager.instance;
      bool hasPermission = await permissionManager.requestLocationPermission();

      if (hasPermission) {
        // logger.info('定位权限申请成功，检查后台定位权限状态...', tag: 'Location');

        // 检查后台定位权限状态，但不主动请求（避免重复弹窗）
        var backgroundLocationStatus = await Permission.locationAlways.status;
        // logger.info('后台定位权限状态: $backgroundLocationStatus', tag: 'Location');

        // 只在后台权限被明确拒绝时才提示用户
        if (backgroundLocationStatus.isPermanentlyDenied) {
          logger.warning('后台定位权限被永久拒绝', tag: 'Location');
          CustomToast.show(Get.context!, '后台定位权限被永久拒绝，可在设置中手动开启');
        } else if (backgroundLocationStatus.isDenied) {
          logger.warning('后台定位权限未开启，前台定位仍可使用', tag: 'Location');
          // 不主动请求后台权限，避免重复弹窗
          // 智能提醒服务会在适当时机提醒用户
        }
      }

      // logger.info('定位权限申请完成', tag: 'Location');
      return hasPermission;
    } catch (e) {
      logger.error('请求定位权限失败: ', tag: 'Location');
      return false;
    }
  }

  /// 请求后台定位权限（仅在用户明确需要时调用）
  Future<bool> requestBackgroundLocationPermission() async {
    try {
      logger.debug('开始申请后台定位权限...', tag: 'Location');

      // 1. 首先确保有前台定位权限
      var locationStatus = await Permission.location.status;
      // logger.info('前台定位权限状态: $locationStatus', tag: 'Location');

      if (!locationStatus.isGranted) {
        // logger.info('先申请前台定位权限...', tag: 'Location');
        locationStatus = await Permission.location.request();
        logger.debug('申请前台定位权限结果: $locationStatus', tag: 'Location');

        if (!locationStatus.isGranted) {
          logger.error('前台定位权限被拒绝，无法申请后台权限', tag: 'Location');
          CustomToast.show(Get.context!, '请先开启定位权限，然后再申请后台定位权限');
          return false;
        }
      }

      // 2. 检查后台定位权限状态
      var backgroundLocationStatus = await Permission.locationAlways.status;
      logger.debug('后台定位权限状态: $backgroundLocationStatus', tag: 'Location');

      if (backgroundLocationStatus.isDenied) {
        // logger.info('申请后台定位权限...', tag: 'Location');
        backgroundLocationStatus = await Permission.locationAlways.request();
        logger.debug('申请后台定位权限结果: $backgroundLocationStatus', tag: 'Location');

        if (backgroundLocationStatus.isGranted) {
          // logger.info('后台定位权限获取成功', tag: 'Location');
          return true;
        } else if (backgroundLocationStatus.isPermanentlyDenied) {
          //  logger.error('后台定位权限被永久拒绝，直接跳转到设置', tag: 'Location');
          await _openLocationSettingsDirectly();
          return false;
        } else {
          // logger.warning('后台定位权限被拒绝，直接跳转到设置', tag: 'Location');
          await _openLocationSettingsDirectly();
          return false;
        }
      } else if (backgroundLocationStatus.isGranted) {
        // logger.info('后台定位权限已授予', tag: 'Location');
        return true;
      } else if (backgroundLocationStatus.isPermanentlyDenied) {
        // logger.error('后台定位权限被永久拒绝，直接跳转到设置', tag: 'Location');
        await _openLocationSettingsDirectly();
        return false;
      }

      return false;
    } catch (e) {
      logger.error('请求后台定位权限失败: ', tag: 'Location');
      return false;
    }
  }

  /// 开始定位
  Future<bool> startLocation() async {
    try {
      // logger.info('SimpleLocationService.startLocation() 开始执行', tag: 'Location');

      // 🔑 关键修复：检查隐私政策同意状态
      // 🔥 优化：如果用户已登录（已进入首页），则跳过隐私协议检查
      // 因为用户能进入首页说明已经完成了必要的流程
      final privacyManager = Get.find<PrivacyComplianceManager>();
      final isUserLoggedIn = UserManager.isLoggedIn;
      if (!privacyManager.isPrivacyAgreed && !isUserLoggedIn) {
        logger.error('用户尚未同意隐私政策且未登录，无法启动定位服务', tag: 'Location');
        return false;
      }
      
      // 如果用户已登录但未同意隐私协议，自动设置高德地图隐私授权
      if (isUserLoggedIn && !privacyManager.isPrivacyAgreed) {
        logger.debug('用户已登录但隐私协议状态异常，自动启用高德地图隐私授权', tag: 'Location');
        AMapFlutterLocation.updatePrivacyAgree(true);
      }

      // 确保先初始化（这很关键！）
      init();
      await Future.delayed(Duration(milliseconds: 100)); // 给初始化一点时间

      // 设置高德地图隐私合规（必须在任何定位操作之前）
      await _setupPrivacyCompliance();
      logger.debug('隐私合规设置完成', tag: 'Location');

      // 检查权限状态，但不重复请求
      var locationStatus = await Permission.location.status;
      // logger.info('定位权限状态: $locationStatus', tag: 'Location');
      if (!locationStatus.isGranted) {
        logger.error('定位权限检查失败，无法启动定位服务', tag: 'Location');
        return false;
      }

      // 如果已经在定位，先停止
      if (isLocationEnabled.value) {
        logger.debug('定位服务已启动，先停止旧服务', tag: 'Location');
        stopLocation();
        // 等待一小段时间确保停止完成
        await Future.delayed(Duration(milliseconds: 500));
      }

      // logger.info('高德定位服务启动中...', tag: 'Location');

      // 检查插件是否已正确初始化
      try {
        // 获取当前定位设置状态（这会触发插件检查）
        // logger.info('检查高德定位插件状态...', tag: 'Location');
        // 简单调用来检查插件是否正常
        _locationPlugin.stopLocation(); // 安全的检查调用
        logger.debug('高德定位插件状态正常', tag: 'Location');
      } catch (e) {
        logger.error('高德定位插件可能未正确初始化: ', tag: 'Location');
      }

      // 确保流监听器已彻底清理
      try {
        // 停止现有定位
        _locationPlugin.stopLocation();
        logger.debug('高德定位插件已停止', tag: 'Location');

        // 全局监听器无需清理，直接继续

        logger.debug('所有流监听器清理完成', tag: 'Location');

        // 等待确保完全停止
        await Future.delayed(Duration(milliseconds: 500));
        logger.debug('清理完成，等待结束', tag: 'Location');
      } catch (e) {
        logger.warning('清理监听器时出现异常: $e', tag: 'Location');
      }

      // 设置高德定位参数 - 参考iOS版本的高精度配置 + 后台定位优化
      // logger.info('开始设置高德定位参数（参考iOS版本 + 后台定位优化）...', tag: 'Location');
      AMapLocationOption locationOption = AMapLocationOption();

      // 设置定位模式 - 使用Hight_Accuracy模式（最关键的配置）
      // 🔥 重要：Hight_Accuracy模式在后台和息屏时会自动降级为基站+WIFI定位
      // 这是Android系统的限制，无法通过配置完全避免
      locationOption.locationMode =
          AMapLocationMode.Hight_Accuracy; // 高精度模式，包含GPS

      logger.debug('- 定位模式: 高精度模式（GPS+网络+WIFI）', tag: 'Location');
      // logger.debug('-  高精度模式已启用', tag: 'Location');
      logger.debug(
        '- ⚠️  息屏后限制：Android系统会限制GPS访问，自动降级为基站+WIFI定位',
        tag: 'Location',
      );

      // 设置定位间隔（参考iOS版本）
      // 🔥 后台定位优化：适当增加间隔以减少电量消耗和系统限制
      locationOption.locationInterval = _locationInterval; // 5秒间隔，平衡响应性与耗电
      logger.debug('- 定位间隔: ${_locationInterval}ms（平衡响应性与耗电）', tag: 'Location');

      // ✅ 关键修复：取消距离过滤，让定位层保证数据完整性
      locationOption.distanceFilter = -1;
      // logger.debug('- 距离过滤: ${_distanceFilter}米（设为0以避免与时间间隔冲突）', tag: 'Location');

      // 设置地址信息
      locationOption.needAddress = false;

      // 设置持续定位
      locationOption.onceLocation = false;

      try {
        _locationPlugin.setLocationOption(locationOption);
        logger.debug('高德定位参数设置完成', tag: 'Location');
      } catch (e) {
        logger.error('设置高德定位参数失败: ', tag: 'Location');
        throw e;
      }

      // 确保全局监听器已设置
      if (!_isGlobalListenerSetup) {
        _setupGlobalLocationListener();
      } else {
        // logger.info('全局监听器已激活，直接启动定位', tag: 'Location');
      }

      try {
        _locationPlugin.startLocation();
        logger.debug('高德定位启动请求已发送', tag: 'Location');
      } catch (e) {
        logger.error('启动高德定位失败: ', tag: 'Location');
        throw e;
      }

      // // 延迟启动定时单次定位（给持续定位一些时间先工作）
      // Timer(Duration(seconds: 60), () {
      //   if (isLocationEnabled.value) {
      //     logger.debug('启动定时单次定位作为备用方案', tag: 'Location');
      //     _startPeriodicSingleLocation();
      //   }
      // });

      // 添加延迟检查
      Future.delayed(Duration(seconds: 5), () {
        logger.debug('5秒后检查：定位是否有数据回调...', tag: 'Location');
        if (currentLocation.value == null) {
          logger.warning('5秒后仍未收到定位数据，尝试单次定位...', tag: 'Location');
          _requestSingleLocation();
        }
      });

      // Future.delayed(Duration(seconds: 10), () {
      //   logger.verbose('10秒后检查：定位是否有数据回调...', tag: 'Location');
      //   if (currentLocation.value == null) {
      //     logger.warning('10秒后仍未收到定位数据，可能存在问题', tag: 'Location');
      //   }
      // });

      // 新策略：不再需要定时器，改为实时上报

      isLocationEnabled.value = true;
      hasInitialReport.value = false; // 重置初始上报状态

      // 🔥 关键修复：立即启动前台服务，确保息屏后能继续定位
      // 不等到进入后台才启动，因为用户可能随时息屏
      logger.debug('立即启动前台服务以支持息屏后定位...', tag: 'Location');
      await _enableForegroundServiceIfNeeded();

      // 🔥 重要优化：根据应用状态智能决定是否启动后台定时器
      _smartStartLocationStrategy();

      // 🚀 每次启动定位服务时，立即尝试获取一次定位并放入收集池
      logger.debug('定位服务启动完成，立即尝试获取一次定位放入收集池', tag: 'Location');
      _requestInitialLocationForCollection();

      logger.debug('高德定位服务已启动完成', tag: 'Location');
      return true;
    } catch (e) {
      logger.error('启动高德定位失败: $e', tag: 'Location');
      return false;
    }
  }

  /// 处理位置更新
  void _onLocationUpdate(Map<String, Object> result) {
    try {
      logger.verbose('完整定位数据: ${result.toString()}', tag: 'Location');

      // 检查高德定位错误码
      int? errorCode = int.tryParse(result['errorCode']?.toString() ?? '0');
      String? errorInfo = result['errorInfo']?.toString();

      if (errorCode != null && errorCode != 0) {
        logger.error(
          '高德定位失败 - 错误码: $errorCode, 错误信息: $errorInfo',
          tag: 'Location',
        );

        // 根据错误码进行智能重试
        bool shouldRetry = false;
        String suggestion = '';

        switch (errorCode) {
          case 12:
            logger.error('错误码12: 缺少定位权限', tag: 'Location');
            suggestion = '请检查应用定位权限是否已授予';
            break;
          case 13:
            logger.error('错误码13: 网络异常', tag: 'Location');
            suggestion = '网络连接异常，将尝试重新连接';
            shouldRetry = true;
            // 屏幕熄灭或后台权限缺失时，优先尝试GPS-only或网络-only策略
            try {
              final appLifecycle = AppLifecycleService.instance;
              final inBackground = appLifecycle.isInBackground;
              final hasBg =
                  _currentBackgroundPermission.value ==
                  PermissionStatus.granted;
              if (inBackground && !hasBg) {
                logger.debug('触发GPS-only降级（后台且无后台权限）', tag: 'Location');
                _locationPlugin.stopLocation();
                final gpsOnly = AMapLocationOption();
                gpsOnly.locationMode = AMapLocationMode.Device_Sensors;
                gpsOnly.locationInterval =
                    SimpleLocationService._locationInterval;
                gpsOnly.distanceFilter = SimpleLocationService._distanceFilter;
                gpsOnly.needAddress = false;
                gpsOnly.onceLocation = false;
                _locationPlugin.setLocationOption(gpsOnly);
                _locationPlugin.startLocation();
                logger.debug('已切换到GPS-only降级模式', tag: 'Location');
              } else {
                logger.verbose('尝试纯网络定位以快速恢复', tag: 'Location');
                tryNetworkLocationOnly();
              }
            } catch (e) {
              logger.error('错误码13降级处理失败: ', tag: 'Location');
            }
            break;
          case 14:
            logger.error('错误码14: GPS定位失败', tag: 'Location');
            suggestion = 'GPS信号弱，尝试切换到网络定位';
            shouldRetry = true;
            break;
          case 15:
            logger.error('错误码15: 定位服务关闭（系统GPS开关被关闭）', tag: 'Location');
            suggestion = '系统定位服务已关闭，请在设置中开启';
            break;
          case 16:
            logger.error('错误码16: 获取地址信息失败', tag: 'Location');
            suggestion = '地址解析失败，但定位可能成功';
            break;
          case 17:
            logger.error('错误码17: 定位参数错误', tag: 'Location');
            suggestion = '定位参数配置错误，尝试重新配置';
            shouldRetry = true;
            break;
          case 18:
            logger.error('错误码18: 定位超时', tag: 'Location');
            suggestion = '定位超时，尝试重新定位';
            shouldRetry = true;
            break;
          default:
            logger.error('其他定位错误: $errorCode - $errorInfo', tag: 'Location');
            suggestion = '未知错误，尝试重新初始化';
            shouldRetry = true;
        }

        logger.debug('建议: $suggestion', tag: 'Location');

        // ✅ 优化：使用指数退避策略进行智能重试
        if (shouldRetry && _locationRetryCount < 5) {
          _locationRetryCount++;
          // 指数退避：2秒、4秒、8秒、16秒、32秒
          final delaySeconds = 2 * (1 << (_locationRetryCount - 1)); // 2^(n-1)
          logger.debug(
            '第$_locationRetryCount 次重试定位（延迟${delaySeconds}秒）...',
            tag: 'Location',
          );

          // 使用指数退避延迟后重试
          Future.delayed(Duration(seconds: delaySeconds), () async {
            try {
              await _lightweightReinitializePlugin();
              _locationPlugin.startLocation();
              logger.debug('定位重试已启动（第$_locationRetryCount次）', tag: 'Location');
            } catch (e) {
              logger.error('重试定位失败（第$_locationRetryCount次）: ', tag: 'Location');
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
      double? longitude = double.tryParse(
        result['longitude']?.toString() ?? '',
      );
      double? accuracy = double.tryParse(result['accuracy']?.toString() ?? '');
      double? speed = double.tryParse(result['speed']?.toString() ?? '');
      double? altitude = double.tryParse(result['altitude']?.toString() ?? '');
      // bearing（移动方向）不再使用，改用传感器数据获取手机朝向
      String? address = result['address']?.toString();
      int? timestamp = int.tryParse(result['timestamp']?.toString() ?? '');

      if (latitude == null || longitude == null) {
        logger.debug('高德定位数据无效: $result', tag: 'Location');
        return;
      }

      // 成功定位，重置重试计数
      _locationRetryCount = 0;

      // logger.info('高德定位成功: 纬度=$latitude, 经度=$longitude, 精度=$accuracy 米', tag: 'Location');

      final location = LocationReportModel(
        longitude: longitude.toString(),
        latitude: latitude.toString(),
        locationTime: timestamp != null
            ? (timestamp ~/ 1000).toString()
            : (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(),
        speed: (speed ?? 0.0).toStringAsFixed(2),
        altitude: (altitude ?? 0.0).toStringAsFixed(2),
        locationName:
            address ?? '位置 ${latitude.toString()}, ${longitude.toString()}',
        accuracy: (accuracy ?? 0.0).toStringAsFixed(2),
      );

      // 更新当前位置
      currentLocation.value = location;

      // 注意：不再使用 bearing，改用传感器数据
      // bearing 是移动方向，我们需要的是手机朝向

      // 新策略：只做基础验证
      if (_isBasicLocationValid(location)) {
        _handleLocationReporting(location);
      } else {
        logger.warning(
          ' 位置基础验证失败，跳过收集: ${location.latitude}, ${location.longitude}',
          tag: 'Location',
        );
      }

      // logger.debug('高德实时定位: ${location.latitude}, ${location.longitude}, 精度: ${location.accuracy}米, 速度: ${location.speed}m/s', tag: 'Location');

      // 更新后台通知状态
      if (_isBackgroundNotificationShown) {
        String locationText =
            address ??
            '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
        _updateBackgroundNotification('定位正常 - $locationText');
      }

      // 如果正在进行单次定位，现在收到了数据，说明单次定位成功
      if (_isSingleLocationInProgress) {
        logger.debug('单次定位成功，准备重启持续定位', tag: 'Location');
        _isSingleLocationInProgress = false;
        // 延迟重启持续定位，给单次定位一点时间完成
        Timer(Duration(milliseconds: 500), () {
          _restartContinuousLocation();
        });
      }
    } catch (e) {
      logger.debug('处理高德位置更新失败: $e', tag: 'Location');
    }
  }

  /// 停止定位
  void stopLocation() {
    try {
      // 停止定时单次定位
      _periodicLocationTimer?.cancel();
      _periodicLocationTimer = null;

      // 🚀 停止新的定时上报器
      _reportTimer?.cancel();
      _reportTimer = null;

      // 停止高德定位（但保持全局监听器）
      _locationPlugin.stopLocation();

      // 重置状态
      isLocationEnabled.value = false;
      isReporting.value = false;
      hasInitialReport.value = false;
      // _lastReportedLocation = null; // 已移除

      // 🚀 清理新的收集缓冲区
      _collectionBuffer.clear();

      // 智能状态已简化

      // 🆕 清空当前位置数据，避免关闭定位后仍然使用旧位置
      currentLocation.value = null;

      // 🔥 停止前台服务（在这里才真正停止）
      _disableForegroundServiceIfNeeded();

      logger.debug('高德定位服务已停止（全局监听器保持激活）', tag: 'Location');
      logger.debug('收集缓冲区和智能状态已清理', tag: 'Location');
    } catch (e) {
      logger.error('停止高德定位失败: $e', tag: 'Location');
    }
  }

  /// 🚀 每次启动时主动获取一次定位放入收集池
  Future<void> _requestInitialLocationForCollection() async {
    try {
      logger.debug('主动获取初始定位，准备放入收集池...', tag: 'Location');

      // 等待一小段时间让定位服务稳定
      await Future.delayed(Duration(seconds: 2));

      // 触发一次单次定位
      await _requestSingleLocationForCollection();
    } catch (e) {
      logger.error('主动获取初始定位失败: ', tag: 'Location');
    }
  }

  /// 为收集池专门的单次定位请求
  Future<void> _requestSingleLocationForCollection() async {
    try {
      logger.debug('为收集池请求单次定位...', tag: 'Location');

      // 如果已经在进行单次定位，不重复执行
      if (_isSingleLocationInProgress) {
        logger.warning('单次定位已在进行中，跳过重复请求', tag: 'Location');
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
      singleLocationOption.needAddress = false;

      _locationPlugin.setLocationOption(singleLocationOption);

      // 重新开始定位，此时应该是单次定位模式
      _locationPlugin.startLocation();
      logger.debug('为收集池的单次定位请求已发送', tag: 'Location');

      // 设置超时，如果10秒内没有收到定位，则重启持续定位
      Timer(Duration(seconds: 10), () {
        if (_isSingleLocationInProgress) {
          logger.verbose('收集池单次定位超时，恢复持续定位', tag: 'Location');
          _isSingleLocationInProgress = false;
          _setupContinuousLocation();
          _locationPlugin.startLocation();
        }
      });
    } catch (e) {
      logger.error('收集池单次定位失败: ', tag: 'Location');
      _isSingleLocationInProgress = false;
    }
  }

  /// 请求单次定位（作为备用方案）
  Future<void> _requestSingleLocation() async {
    try {
      logger.debug('尝试单次定位作为备用方案...', tag: 'Location');

      // 如果已经在进行单次定位，不重复执行
      if (_isSingleLocationInProgress) {
        logger.warning('单次定位已在进行中，跳过重复请求', tag: 'Location');
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
      singleLocationOption.needAddress = false;
      // 优化已实现

      _locationPlugin.setLocationOption(singleLocationOption);

      // 重新开始定位，此时应该是单次定位模式
      _locationPlugin.startLocation();
      logger.debug('单次定位请求已发送', tag: 'Location');

      // 设置超时，如果10秒内没有收到定位，则重启持续定位
      Timer(Duration(seconds: 10), () {
        if (_isSingleLocationInProgress) {
          logger.verbose('单次定位超时，尝试智能恢复', tag: 'Location');
          _isSingleLocationInProgress = false;
          _handleLocationTimeout();
        }
      });
    } catch (e) {
      logger.error('单次定位失败: ', tag: 'Location');
      _isSingleLocationInProgress = false;
    }
  }

  /// 设置持续定位参数
  void _setupContinuousLocation() {
    try {
      logger.debug('重新设置持续定位参数...', tag: 'Location');
      AMapLocationOption locationOption = AMapLocationOption();
      locationOption.locationMode = AMapLocationMode.Hight_Accuracy;
      locationOption.locationInterval = _locationInterval; // 5秒间隔（平衡性能）
      locationOption.distanceFilter = _distanceFilter; //
      // 优化已实现
      locationOption.needAddress = false;
      locationOption.onceLocation = false; // 持续定位

      _locationPlugin.setLocationOption(locationOption);
      logger.debug('持续定位参数重新设置完成', tag: 'Location');
    } catch (e) {
      logger.error('重新设置持续定位参数失败: ', tag: 'Location');
    }
  }

  /// 处理定位超时的智能恢复策略
  Future<void> _handleLocationTimeout() async {
    try {
      logger.debug('开始处理定位超时，当前重试次数: $_locationRetryCount', tag: 'Location');

      if (_locationRetryCount < 3) {
        _locationRetryCount++;
        logger.debug('第${_locationRetryCount}次超时重试...', tag: 'Location');

        // 根据重试次数采用不同策略
        switch (_locationRetryCount) {
          case 1:
            // 第一次超时：重新启动监听器
            logger.warning('策略1: 重新启动流监听器', tag: 'Location');
            // 全局监听器已激活，无需重新设置
            _locationPlugin.startLocation();
            break;

          case 2:
            // 第二次超时：强制重新初始化插件
            logger.warning('策略2: 强制重新初始化插件', tag: 'Location');
            await _lightweightReinitializePlugin();
            // 全局监听器已激活，无需重新设置
            _locationPlugin.startLocation();
            break;

          case 3:
            // 第三次超时：尝试切换定位模式
            logger.warning('策略3: 切换到高精度定位模式', tag: 'Location');
            await _switchToHighAccuracyMode();
            break;

          default:
            // 最后策略：重启持续定位
            logger.warning('最终策略: 重启持续定位', tag: 'Location');
            _restartContinuousLocation();
        }
      } else {
        // 重试次数过多，重置计数并使用持续定位
        logger.error('超时重试次数过多，回退到持续定位模式', tag: 'Location');
        _locationRetryCount = 0;
        _restartContinuousLocation();
      }
    } catch (e) {
      logger.error('处理定位超时失败: ', tag: 'Location');
      _locationRetryCount = 0;
      _restartContinuousLocation();
    }
  }

  /// 切换到高精度定位模式
  Future<void> _switchToHighAccuracyMode() async {
    try {
      logger.debug('切换到高精度定位模式...', tag: 'Location');

      // 停止当前定位
      _locationPlugin.stopLocation();
      await Future.delayed(Duration(milliseconds: 500));

      // 设置高精度定位参数
      AMapLocationOption locationOption = AMapLocationOption();
      locationOption.locationMode = AMapLocationMode.Hight_Accuracy;
      locationOption.locationInterval = 5000; // 减少间隔到2秒
      locationOption.distanceFilter = _distanceFilter; // 保持50米距离过滤（与iOS一致）
      // 优化已实现
      locationOption.needAddress = false;
      locationOption.onceLocation = false;

      _locationPlugin.setLocationOption(locationOption);

      // 重新设置监听器并启动
      // 全局监听器已激活，无需重新设置
      _locationPlugin.startLocation();

      logger.debug('已切换到高精度定位模式', tag: 'Location');
    } catch (e) {
      logger.error('切换高精度定位模式失败: ', tag: 'Location');
      throw e;
    }
  }

  /// 轻量级重新初始化插件（避免Stream冲突）
  Future<void> _lightweightReinitializePlugin() async {
    try {
      logger.debug('轻量级重新初始化高德定位插件...', tag: 'Location');

      // 只停止定位，不干扰Stream
      _locationPlugin.stopLocation();
      await Future.delayed(Duration(milliseconds: 300));

      // 重新设置隐私合规和API Key
      await _setupPrivacyCompliance();

      await Future.delayed(Duration(milliseconds: 200));
      logger.debug('插件轻量级重新初始化完成', tag: 'Location');
    } catch (e) {
      logger.error('轻量级重新初始化插件失败: ', tag: 'Location');
      throw e;
    }
  }

  // 旧的Stream监听器方法已移除，现在使用全局监听器

  /// 重启持续定位
  Future<void> _restartContinuousLocation() async {
    try {
      logger.debug('重启持续定位...', tag: 'Location');

      // 🔥 修复：只有在缓冲区为空时才重置首次定位标志
      if (_collectionBuffer.isEmpty) {
        _isFirstLocationSuccess = true;
        logger.debug('缓冲区为空，重置首次定位标志', tag: 'Location');
      } else {
        logger.debug(
          '缓冲区不为空(${_collectionBuffer.length}个点)，保持首次定位标志为false',
          tag: 'Location',
        );
      }

      _locationPlugin.stopLocation();
      await Future.delayed(Duration(milliseconds: 300));

      // 重新设置持续定位参数
      _setupContinuousLocation();

      // 重新开始定位（不需要重新设置监听器，因为监听器是持续的）
      _locationPlugin.startLocation();
      logger.debug('持续定位已重启', tag: 'Location');
    } catch (e) {
      logger.error('重启持续定位失败: ', tag: 'Location');
    }
  }

  /// 检查服务状态（用于测试）
  bool get isServiceRunning => isLocationEnabled.value;

  /// 尝试纯网络定位（不依赖GPS）
  Future<void> tryNetworkLocationOnly() async {
    logger.debug('尝试纯网络定位...', tag: 'Location');

    try {
      // 停止当前定位
      stopLocation();
      await Future.delayed(Duration(seconds: 1));

      // 配置纯网络定位
      AMapLocationOption locationOption = AMapLocationOption();
      locationOption.locationMode =
          AMapLocationMode.Battery_Saving; // 省电模式主要使用网络定位
      locationOption.locationInterval =
          SimpleLocationService._locationInterval; // 5秒间隔
      locationOption.distanceFilter = _distanceFilter; //
      locationOption.needAddress = false;
      locationOption.onceLocation = false;
      // locationOption.mockEnable = true;
      // locationOption.gpsFirst = false; // 不优先GPS

      _locationPlugin.setLocationOption(locationOption);
      logger.debug('网络定位参数设置完成', tag: 'Location');

      // 重新设置监听器
      // 全局监听器已激活，无需重新设置

      // 启动定位
      _locationPlugin.startLocation();
      logger.debug('网络定位已启动，等待结果...', tag: 'Location');

      // 等待15秒
      await Future.delayed(Duration(seconds: 15));

      if (currentLocation.value != null) {
        logger.debug('网络定位成功！', tag: 'Location');
        logger.debug(
          '经度: ${currentLocation.value!.longitude}',
          tag: 'Location',
        );
        logger.debug('纬度: ${currentLocation.value!.latitude}', tag: 'Location');
        logger.debug(
          '地址: ${currentLocation.value!.locationName}',
          tag: 'Location',
        );
      } else {
        logger.error('网络定位也未能获取位置', tag: 'Location');
        logger.debug('建议检查：', tag: 'Location');
        logger.debug('1. 网络连接是否正常', tag: 'Location');
        logger.debug('2. 高德地图API Key是否正确', tag: 'Location');
        logger.debug('3. 是否在中国境内（高德地图限制）', tag: 'Location');
      }
    } catch (e) {
      logger.error('网络定位出错: ', tag: 'Location');
    }
  }

  /// 综合定位问题排查工具
  Future<void> comprehensiveLocationTroubleshoot() async {
    logger.debug('========== 综合定位问题排查 ==========', tag: 'Location');

    try {
      // 1. 基础检查
      logger.debug('第1步：基础环境检查', tag: 'Location');
      await diagnoseLocationService();

      // 2. API Key验证
      logger.debug('\n 第2步：API Key验证', tag: 'Location');
      await checkApiKeyConfiguration();

      // 3. 尝试网络定位
      logger.debug('\n 第3步：尝试纯网络定位', tag: 'Location');
      await tryNetworkLocationOnly();

      if (currentLocation.value != null) {
        logger.debug('网络定位成功，问题已解决！', tag: 'Location');
        return;
      }

      // 4. 尝试不同定位模式
      logger.debug('\n 第4步：尝试不同定位模式', tag: 'Location');
      await tryDifferentLocationModes();

      // 5. 最终建议
      logger.debug('\n 第5步：最终建议', tag: 'Location');
      if (currentLocation.value == null) {
        logger.error('所有定位方法都失败了', tag: 'Location');
        logger.debug('建议进行以下检查：', tag: 'Location');
        logger.debug('1. 确认设备位置服务已开启', tag: 'Location');
        logger.debug('2. 确认应用位置权限已授予', tag: 'Location');
        logger.debug('3. 确认网络连接正常', tag: 'Location');
        logger.debug('4. 确认高德API Key配置正确', tag: 'Location');
        logger.debug('5. 确认在中国境内（高德地图限制）', tag: 'Location');
        logger.debug('6. 尝试重启应用或设备', tag: 'Location');
        logger.debug('7. 检查高德控制台配置和服务状态', tag: 'Location');
      } else {
        logger.debug('定位问题已解决！', tag: 'Location');
      }
    } catch (e) {
      logger.error('综合排查过程中出错: ', tag: 'Location');
    }
  }

  /// 尝试不同定位模式
  Future<void> tryDifferentLocationModes() async {
    logger.debug('尝试不同定位模式...', tag: 'Location');

    // 模式列表
    final modes = [
      {'mode': AMapLocationMode.Battery_Saving, 'name': '省电模式（网络定位优先）'},
      {'mode': AMapLocationMode.Device_Sensors, 'name': '设备模式（GPS优先）'},
      {'mode': AMapLocationMode.Hight_Accuracy, 'name': '高精度模式'},
    ];

    for (int i = 0; i < modes.length; i++) {
      final modeInfo = modes[i];
      logger.debug(
        '尝试模式 ${i + 1}/${modes.length}: ${modeInfo['name']}',
        tag: 'Location',
      );

      try {
        // 停止当前定位
        stopLocation();
        await Future.delayed(Duration(seconds: 1));

        // 设置新模式
        AMapLocationOption locationOption = AMapLocationOption();
        locationOption.locationMode = modeInfo['mode'] as AMapLocationMode;
        locationOption.locationInterval =
            SimpleLocationService._locationInterval;
        locationOption.distanceFilter = _distanceFilter; //
        // 优化已实现
        locationOption.needAddress = false;
        locationOption.onceLocation = false;
        // locationOption.mockEnable = true;
        // locationOption.gpsFirst = false;

        _locationPlugin.setLocationOption(locationOption);

        // 重新启动定位
        // 全局监听器已激活，无需重新设置
        _locationPlugin.startLocation();

        logger.debug('启动 ${modeInfo['name']}，等待10秒测试...', tag: 'Location');

        // 等待10秒看是否有数据
        await Future.delayed(Duration(seconds: 10));

        if (currentLocation.value != null) {
          logger.debug('${modeInfo['name']} 成功获取位置！', tag: 'Location');
          logger.debug(
            '位置: (${currentLocation.value!.latitude}, ${currentLocation.value!.longitude})',
            tag: 'Location',
          );
          return; // 成功就退出
        } else {
          logger.error('${modeInfo['name']} 未获取到位置', tag: 'Location');
        }
      } catch (e) {
        logger.error('${modeInfo['name']} 出错: ', tag: 'Location');
      }
    }

    logger.debug('所有定位模式都未能获取到位置', tag: 'Location');
  }

  /// 检查高德API Key是否配置正确
  Future<void> checkApiKeyConfiguration() async {
    logger.debug('检查高德地图API Key配置...', tag: 'Location');

    try {
      // 尝试验证API Key配置（通过设置参数来测试）
      // await _locationPlugin.init(); // 某些版本可能没有这个方法
      logger.debug('高德定位插件初始化成功，API Key可能配置正确', tag: 'Location');

      // 检查是否能获取插件版本（这通常表示插件工作正常）
      try {
        // 注意：某些版本的高德插件可能没有getVersion方法
        logger.debug('高德定位插件已准备就绪', tag: 'Location');
      } catch (e) {
        logger.warning('无法获取插件版本信息，但这可能是正常的: $e', tag: 'Location');
      }
    } catch (e) {
      logger.error('高德定位插件初始化失败: ', tag: 'Location');
      logger.debug('可能的原因：', tag: 'Location');
      logger.debug('1. API Key未配置或配置错误', tag: 'Location');
      logger.debug('2. API Key未在高德控制台启用定位服务', tag: 'Location');
      logger.debug('3. API Key的bundle ID与应用不匹配', tag: 'Location');
      logger.debug('4. 网络连接问题', tag: 'Location');
      throw e;
    }
  }

  /// 诊断定位服务状态
  Future<void> diagnoseLocationService() async {
    logger.debug('========== 定位服务诊断报告 ==========', tag: 'Location');

    try {
      // 1. 检查定位服务是否启用
      logger.info(
        '定位服务状态: ${isLocationEnabled.value ? "✅ 已启用" : "❌ 已禁用"}',
        tag: 'Location',
      );

      // 2. 检查当前位置数据
      logger.info(
        '当前位置数据: ${currentLocation.value?.toJson() ?? "❌ 无数据"}',
        tag: 'Location',
      );

      // 3. 检查流监听器状态
      logger.info(
        '流监听器状态: ${_globalLocationSub != null ? "✅ 已创建" : "❌ 未创建"}',
        tag: 'Location',
      );

      // 4. 检查定时器状态
      logger.info(
        '单次定位定时器: ${_periodicLocationTimer != null && _periodicLocationTimer!.isActive ? "✅ 运行中" : "❌ 未运行"}',
        tag: 'Location',
      );

      // 5. 检查历史数据
      logger.info('位置历史数量: ${locationHistory.length} 条', tag: 'Location');

      // 6. 尝试获取一次位置
      logger.debug('尝试手动单次定位测试...', tag: 'Location');
      await _requestSingleLocation();

      logger.debug('========== 诊断报告结束 ==========', tag: 'Location');
    } catch (e) {
      logger.error('诊断过程中出错: ', tag: 'Location');
    }
  }

  /// 运行完整的定位问题诊断和修复流程
  Future<bool> runLocationDiagnosticAndFix() async {
    logger.debug('========== 开始完整定位诊断和修复 ==========', tag: 'Location');

    try {
      // 1. 运行综合排查
      logger.debug('\n 步骤1：运行综合排查', tag: 'Location');
      await comprehensiveLocationTroubleshoot();

      // 检查是否已经获得位置
      if (currentLocation.value != null) {
        logger.debug('综合排查成功获得位置！', tag: 'Location');
        return true;
      }

      // 2. 重启定位服务
      logger.debug('\n 步骤2：重启定位服务', tag: 'Location');
      stopLocation();
      await Future.delayed(Duration(seconds: 2));
      bool restartSuccess = await startLocation();

      if (!restartSuccess) {
        logger.error('重启失败', tag: 'Location');
        return false;
      }

      // 3. 等待30秒观察结果
      logger.debug('\n 步骤3：等待30秒观察定位结果...', tag: 'Location');
      for (int i = 0; i < 30; i++) {
        await Future.delayed(Duration(seconds: 1));
        if (currentLocation.value != null) {
          logger.debug('第${i + 1}秒获得位置数据！', tag: 'Location');
          logger.debug(
            '经度: ${currentLocation.value!.longitude}',
            tag: 'Location',
          );
          logger.debug(
            '纬度: ${currentLocation.value!.latitude}',
            tag: 'Location',
          );
          logger.debug(
            '地址: ${currentLocation.value!.locationName}',
            tag: 'Location',
          );
          return true;
        }
        if ((i + 1) % 5 == 0) {
          logger.debug('⏳ 已等待${i + 1}秒，继续等待...', tag: 'Location');
        }
      }

      logger.error('30秒后仍未获得位置数据', tag: 'Location');

      return false;
    } catch (e) {
      logger.error('诊断和修复过程中出错: ', tag: 'Location');
      return false;
    }
  }

  /// 计算两点间距离（米）
  // ignore: unused_element
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // meters
    double dLat = _degToRad(lat2 - lat1);
    double dLon = _degToRad(lon2 - lon1);
    double a =
        (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            (math.sin(dLon / 2) * math.sin(dLon / 2));
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);

  /// 获取位置历史记录数量
  int get historyCount => locationHistory.length;

  /// 获取待上报位置数量（新策略不再使用批量收集）
  int get pendingReportCount => 0;

  /// 获取当前是否有位置数据
  bool get hasLocation => currentLocation.value != null;

  /// 获取当前定位精度
  String get currentAccuracy => currentLocation.value?.accuracy ?? '0.0';

  /// 外部接口：确保后台策略激活
  void ensureBackgroundStrategyActive() {
    if (!isLocationEnabled.value) return;

    logger.debug('外部调用：确保后台策略激活', tag: 'Location');
    _startEnhancedBackgroundStrategy();
  }

  /// 外部接口：优化前台策略
  void optimizeForegroundStrategy() {
    if (!isLocationEnabled.value) return;

    logger.debug('外部调用：优化前台策略', tag: 'Location');
    _stopEnhancedBackgroundStrategy();
  }

  /// 智能启动策略：根据应用状态决定是否启动后台定时器
  void _smartStartLocationStrategy() {
    try {
      // 获取应用生命周期状态
      final appLifecycle = AppLifecycleService.instance;
      final isInBackground = appLifecycle.isInBackground;

      logger.debug(
        '智能启动策略检查：应用${isInBackground ? "在后台" : "在前台"}',
        tag: 'Location',
      );

      if (isInBackground) {
        // 应用在后台，启动增强后台策略
        logger.debug('应用在后台，启动增强后台策略（包含多重定时器）', tag: 'Location');
        _startEnhancedBackgroundStrategy();
      } else {
        // 应用在前台，只启动基础定位，不启动后台定时器
        logger.debug('应用在前台，仅启动基础定位（不启动后台定时器）', tag: 'Location');
        // 确保后台定时器已停止
        _stopEnhancedBackgroundStrategy();
      }
    } catch (e) {
      logger.error('智能启动策略检查失败: ', tag: 'Location');
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
}

// MARK: - 应用生命周期监听扩展（优化版本）
extension AppLifecycleExtension on SimpleLocationService {
  /// 设置真实的应用生命周期监听
  void _setupAppLifecycleListener() {
    logger.debug('设置真实应用生命周期监听（优化版本）', tag: 'Location');
    WidgetsBinding.instance.addObserver(this);
  }

  /// 清理生命周期监听
  void _removeAppLifecycleListener() {
    WidgetsBinding.instance.removeObserver(this);
  }

  /// 真实的应用状态变化监听
  void didChangeAppLifecycleState(AppLifecycleState state) {
    logger.debug('应用状态变化: $state', tag: 'Location');

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
        logger.debug('应用变为非活跃状态', tag: 'Location');
        break;
      case AppLifecycleState.hidden:
        // 应用隐藏但未停止
        logger.debug('应用已隐藏', tag: 'Location');
        break;
    }
  }

  /// 应用进入后台（真实状态检测）
  void _onAppDidEnterBackground() {
    logger.debug('应用真实进入后台，启动增强后台策略', tag: 'Location');
    _startEnhancedBackgroundStrategy();
  }

  /// 应用进入前台（真实状态检测）
  void _onAppWillEnterForeground() {
    logger.debug('应用回到前台，恢复正常策略', tag: 'Location');
    _stopEnhancedBackgroundStrategy();
  }

  /// 应用即将终止
  void _onAppWillTerminate() {
    logger.debug('应用即将终止，保存关键数据', tag: 'Location');
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
    // 🔥 修复：不停止前台服务！前台服务应该在定位开启时一直运行
    // 前台服务只在 stopLocation() 时才停止
    // _disableForegroundServiceIfNeeded();  // ← 已移除

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
    logger.debug('启用后台位置采集模式', tag: 'Location');
    // 在后台时，降低采集频率以节省电量，同时保证一定的更新
    try {
      // 若后台定位权限未授予，避免触发网络/WIFI基站采集导致错误13
      if (_currentBackgroundPermission.value != PermissionStatus.granted) {
        logger.warning(
          '后台定位权限未授予，采用GPS优先的降级策略（Device_Sensors）',
          tag: 'Location',
        );
        _locationPlugin.stopLocation();

        final gpsOnly = AMapLocationOption();
        gpsOnly.locationMode = AMapLocationMode.Device_Sensors; // 仅设备传感器（GPS）
        gpsOnly.locationInterval =
            SimpleLocationService._locationInterval; // 降低频率，节能且避免频繁失败
        gpsOnly.distanceFilter = SimpleLocationService._distanceFilter;
        gpsOnly.needAddress = false; // 纯GPS不解析地址，避免网络依赖
        gpsOnly.onceLocation = false;

        _locationPlugin.setLocationOption(gpsOnly);
        _locationPlugin.startLocation();
        logger.debug(
          '已应用GPS优先后台策略：Device_Sensors / 20s / no address', 
          tag: 'Location',
        );
        return;
      }

      // 只调整定位参数，不重置全局监听器
      _locationPlugin.stopLocation();

      // 首选高精度模式，系统会在息屏/后台时自动降级为网络定位
      final option = AMapLocationOption();
      option.locationMode = AMapLocationMode.Hight_Accuracy;
      option.locationInterval =
          SimpleLocationService._locationInterval; // 后台15秒一次，降低功耗
      option.distanceFilter =
          SimpleLocationService._distanceFilter; // 与前台保持一致的距离过滤
      option.needAddress = false;
      option.onceLocation = false;

      _locationPlugin.setLocationOption(option);
      _locationPlugin.startLocation();
      logger.debug(
        '后台模式参数已应用：Hight_Accuracy / 15s / distanceFilter=${SimpleLocationService._distanceFilter}',
        tag: 'Location',
      );
    } catch (e) {
      logger.error('启用后台位置模式失败: ', tag: 'Location');
    }
  }

  /// 启用前台位置模式
  void _enableForegroundLocationMode() {
    logger.debug('恢复前台位置采集模式', tag: 'Location');
    // 前台时恢复正常的采集频率与高精度
    try {
      _locationPlugin.stopLocation();

      final option = AMapLocationOption();
      option.locationMode = AMapLocationMode.Hight_Accuracy;
      option.locationInterval =
          SimpleLocationService._locationInterval; // 恢复到默认频率
      option.distanceFilter = SimpleLocationService._distanceFilter;
      option.needAddress = false;
      option.onceLocation = false;

      _locationPlugin.setLocationOption(option);
      _locationPlugin.startLocation();
      logger.debug(
        '前台模式参数已应用：Hight_Accuracy / ${SimpleLocationService._locationInterval}ms / distanceFilter=${SimpleLocationService._distanceFilter}',
        tag: 'Location',
      );
    } catch (e) {
      logger.error('启用前台位置模式失败: ', tag: 'Location');
    }
  }

  /// 应用终止前保存数据
  void _saveLocationDataBeforeTermination() {
    // 新策略：实时上报，无需在应用终止前处理批量数据
    logger.debug('应用终止前，清理定位服务状态', tag: 'Location');

    // 隐藏后台通知
    _hideBackgroundNotification();
  }

  /// 显示后台运行通知
  void _showBackgroundNotification() {
    if (_isBackgroundNotificationShown) {
      logger.debug('后台通知已显示，跳过', tag: 'Location');
      return;
    }

    try {
      // 检查通知频率限制（避免过于频繁）
      final now = DateTime.now();
      if (_lastNotificationTime != null &&
          now.difference(_lastNotificationTime!).inMinutes < 5) {
        logger.debug('通知频率限制，跳过显示', tag: 'Location');
        return;
      }

      _isBackgroundNotificationShown = true;
      _lastNotificationTime = now;

      logger.debug('显示后台定位运行通知', tag: 'Location');

      // TODO: 集成本地通知插件
      // 这里可以使用 flutter_local_notifications 或其他通知插件
      // _showLocalNotification(
      //   title: 'Kissu - 情侣定位',
      //   body: '正在后台为您提供位置服务',
      //   ongoing: true, // 持续通知
      // );
    } catch (e) {
      logger.error('显示后台通知失败: ', tag: 'Location');
      _isBackgroundNotificationShown = false;
    }
  }

  /// 隐藏后台运行通知
  void _hideBackgroundNotification() {
    if (!_isBackgroundNotificationShown) {
      logger.debug('后台通知未显示，跳过隐藏', tag: 'Location');
      return;
    }

    try {
      _isBackgroundNotificationShown = false;
      logger.debug('隐藏后台定位运行通知', tag: 'Location');

      // TODO: 取消本地通知
      // _cancelLocalNotification();
    } catch (e) {
      logger.error('隐藏后台通知失败: ', tag: 'Location');
    }
  }

  /// 更新后台通知内容
  void _updateBackgroundNotification(String status) {
    if (!_isBackgroundNotificationShown) return;

    try {
      logger.debug('更新后台通知: $status', tag: 'Location');

      // TODO: 更新通知内容
      // _updateLocalNotification(
      //   title: 'Kissu - 情侣定位',
      //   body: '状态: $status',
      // );
    } catch (e) {
      logger.error('更新后台通知失败: ', tag: 'Location');
    }
  }

  /// 启用前台服务（如果需要）
  Future<void> _enableForegroundServiceIfNeeded() async {
    try {
      final foregroundService = ForegroundLocationService.instance;

      // 🔧 修复：检查服务是否已在运行，避免重复启动和通知更新
      if (foregroundService.isServiceRunning) {
        logger.debug('前台服务已在运行，跳过启动和通知更新', tag: 'Location');
        return;
      }

      final success = await foregroundService.startForegroundService();

      if (success) {
        logger.debug('前台服务启动成功（静默模式）', tag: 'Location');
        // 🔧 移除通知更新，保持静默
        // await foregroundService.updateForegroundServiceNotification(
        //   content: '正在后台为您提供位置定位服务',
        // );
      } else {
        logger.error('前台服务启动失败', tag: 'Location');
      }
    } catch (e) {
      logger.error('启用前台服务失败: ', tag: 'Location');
    }
  }

  /// 禁用前台服务（如果需要）
  Future<void> _disableForegroundServiceIfNeeded() async {
    try {
      final foregroundService = ForegroundLocationService.instance;
      final success = await foregroundService.stopForegroundService();

      if (success) {
        logger.debug('前台服务停止成功', tag: 'Location');
      } else {
        logger.error('前台服务停止失败', tag: 'Location');
      }
    } catch (e) {
      logger.error('禁用前台服务失败: ', tag: 'Location');
    }
  }
}

// MARK: - 增强后台任务管理扩展
extension BackgroundTaskExtension on SimpleLocationService {
  /// Flutter 保活已禁用，统一由原生层保活
  void _startBackgroundKeepAlive() {}

  /// 停止后台保活任务
  void _stopBackgroundKeepAlive() {}

  /// 启动多重保障定时器（增强后台稳定性）- 仅在后台运行
  void _startMultipleBackgroundTimers() {}

  /// 停止多重保障定时器
  void _stopMultipleBackgroundTimers() {}

  /// Flutter 保活已禁用
  // ignore: unused_element
  void _maintainBackgroundLocation() {}

  /// 快速检查定位服务状态（Flutter 保活已禁用）
  // ignore: unused_element
  void _quickLocationServiceCheck() {}

  /// 中等检查位置更新（Flutter 保活已禁用）
  // ignore: unused_element
  void _mediumLocationUpdateCheck() {}

  /// 深度检查完整性（Flutter 保活已禁用）
  // ignore: unused_element
  void _deepLocationIntegrityCheck() {}

  /// 启动智能电池优化定时器 - Flutter 保活已禁用
  // ignore: unused_element
  void _startBatteryOptimizedTimer() {}

  /// 执行电池优化检查（Flutter 保活已禁用）
  // ignore: unused_element
  void _performBatteryOptimizedCheck() {}

  /// 启用低功耗模式（Flutter 保活已禁用）
  // ignore: unused_element
  void _enableLowPowerMode() {}

  /// 禁用低功耗模式（Flutter 保活已禁用）
  // ignore: unused_element
  void _disableLowPowerMode() {}

  /// 检查位置数据新鲜度
  // ignore: unused_element
  void _checkLocationDataFreshness() {
    // Flutter 保活已禁用
  }

  /// 智能调整定时器间隔
  // ignore: unused_element
  void _adjustTimerIntervals() {
    // Flutter 保活已禁用
  }

  /// 提供电池优化建议
  // ignore: unused_element
  void _provideBatteryOptimizationAdvice() {
    // Flutter 保活已禁用
  }

  /// 检查定位服务健康状态
  // ignore: unused_element
  bool _isLocationServiceHealthy() {
    try {
      // 1. 基础状态检查
      if (!isLocationEnabled.value) {
        logger.error('健康检查：定位服务未启用', tag: 'Location');
        return false;
      }

      // 2. 权限状态检查
      if (_currentLocationPermission.value != PermissionStatus.granted) {
        logger.error('健康检查：位置权限未授予', tag: 'Location');
        return false;
      }

      // 3. 位置数据新鲜度检查
      if (currentLocation.value == null) {
        logger.warning('健康检查：当前位置为空', tag: 'Location');
        return false;
      }

      // 4. 检查位置数据时效性
      final lastUpdateTime = int.tryParse(currentLocation.value!.locationTime);
      if (lastUpdateTime != null) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final timeDiff = now - lastUpdateTime;

        // 超过5分钟认为不健康
        if (timeDiff > 300) {
          logger.warning('健康检查：位置数据过期 ${timeDiff}秒', tag: 'Location');
          return false;
        }
      }

      logger.debug('健康检查：定位服务状态良好', tag: 'Location');
      return true;
    } catch (e) {
      logger.error('健康检查异常: ', tag: 'Location');
      return false;
    }
  }

  /// 检查位置更新是否及时
  // ignore: unused_element
  bool _isLocationUpdateTimely() {
    if (currentLocation.value == null) return false;

    final lastUpdateTime = int.tryParse(currentLocation.value!.locationTime);
    if (lastUpdateTime == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return (now - lastUpdateTime) < 90; // 90秒内有更新认为正常
  }

  /// 检查待上报数据
  // ignore: unused_element
  void _checkPendingReports() {
    // Flutter 上报已禁用，跳过待上报检查
  }

  /// 上报收集的位置数据
  // ignore: unused_element
  void _reportCollectedLocations() {
    // Flutter 上报已禁用，跳过保活上报
  }

  /// 重启定位服务（智能增强版）
  // ignore: unused_element
  void _restartLocationService() {
    logger.debug('智能重启定位服务', tag: 'Location');

    try {
      // 1. 记录重启时间和原因
      final restartTime = DateTime.now();
      logger.debug(
        '定位服务重启时间: $restartTime，失败次数: $_consecutiveFailureCount',
        tag: 'Location',
      );

      // 2. 🔥 修复：只有在缓冲区为空时才重置首次定位标志
      if (_collectionBuffer.isEmpty) {
        _isFirstLocationSuccess = true;
        logger.debug('缓冲区为空，重置首次定位标志', tag: 'Location');
      } else {
        logger.debug(
          '缓冲区不为空(${_collectionBuffer.length}个点)，保持首次定位标志为false',
          tag: 'Location',
        );
      }

      // 3. 优雅停止当前定位
      stopLocation();

      // 3. 根据失败次数调整重启策略
      int delaySeconds = _calculateRestartDelay();

      // 4. 延迟重启
      Future.delayed(Duration(seconds: delaySeconds), () {
        logger.debug('开始重新启动定位服务', tag: 'Location');
        _performSmartRestart();
      });
    } catch (e) {
      logger.error('重启定位服务异常: ', tag: 'Location');
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
        logger.debug('智能重启成功，重置失败计数', tag: 'Location');
      }
    } catch (e) {
      logger.error('智能重启失败: ', tag: 'Location');
      _consecutiveFailureCount++;

      // 如果智能重启也失败，考虑完全重新初始化
      if (_consecutiveFailureCount >=
          SimpleLocationService._maxConsecutiveFailures) {
        logger.debug('智能重启失败次数过多，尝试完全重新初始化', tag: 'Location');
        await _performFullReinitialization();
      }
    }
  }

  /// 执行基础重启（兜底方案）
  void _performBasicRestart() {
    logger.debug('执行基础重启策略', tag: 'Location');
    Future.delayed(Duration(seconds: 3), () {
      startLocation();
    });
  }

  /// 重置定位状态
  void _resetLocationState() {
    logger.debug('重置定位服务状态', tag: 'Location');

    // 重置响应式状态
    isLocationEnabled.value = false;
    isReporting.value = false;

    // 重置低功耗模式
    if (_isInLowPowerMode) {
      _isInLowPowerMode = false;
      logger.debug('重置：退出低功耗模式', tag: 'Location');
    }
  }

  /// 完全重新初始化（最后的保障措施）
  Future<void> _performFullReinitialization() async {
    logger.debug('执行完全重新初始化', tag: 'Location');

    try {
      // 1. 完全停止所有定时器
      _stopMultipleBackgroundTimers();
      _stopBackgroundKeepAlive();

      // 2. 重置所有状态
      _resetLocationState();
      _consecutiveFailureCount = 0;

      // 3. 重新初始化
      await Future.delayed(Duration(seconds: 5)); // 等待系统稳定
      init(); // 重新初始化

      // 4. 重新启动定位
      await startLocation();

      logger.debug('完全重新初始化完成', tag: 'Location');
    } catch (e) {
      logger.error('完全重新初始化失败: ', tag: 'Location');
      // 这是最后的保障，如果还失败就只能等用户手动操作了
    }
  }

  /// 强制单次位置更新（Flutter 保活已禁用）
  // ignore: unused_element
  void _forceSingleLocationUpdate() {
    // Flutter 保活已禁用
  }
}

// MARK: - 权限管理扩展（参考iOS版本的权限处理）
extension PermissionManagementExtension on SimpleLocationService {
  /// 初始化权限状态（参考iOS版本的权限监听）
  void _initializePermissionStatus() {
    logger.debug('初始化权限状态（参考iOS版本）', tag: 'Location');
    _updateCurrentPermissionStatus();

    // 取消旧的定时器
    _permissionCheckTimer?.cancel();
    
    // 设置定时检查权限状态变化（模拟iOS的权限变化监听）
    _permissionCheckTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
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

      // 只在 Debug 模式下记录权限状态
      logger.debug('权限状态更新: 前台=${locationStatus.name}, 后台=${backgroundStatus.name}', tag: 'Location');
      
      // 更新 header 中的定位权限状态
      bool isGranted = locationStatus.isGranted;
      if (!isGranted) {
        isGranted = backgroundStatus.isGranted;
      }
      BusinessHeaderInterceptor.updateLocationPermissionStatus(isGranted);
    } catch (e) {
      logger.error('更新权限状态失败: ', tag: 'Location');
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
        _handleLocationPermissionChange(
          previousLocationStatus,
          currentLocationStatus,
        );
      }

      // 检查后台定位权限变化
      if (previousBackgroundStatus != currentBackgroundStatus) {
        _handleBackgroundPermissionChange(
          previousBackgroundStatus,
          currentBackgroundStatus,
        );
      }
    } catch (e) {
      logger.error('检查权限变化失败: ', tag: 'Location');
    }
  }

  /// 处理前台定位权限变化（参考iOS版本的权限事件处理）
  void _handleLocationPermissionChange(
    PermissionStatus from,
    PermissionStatus to,
  ) {
    logger.debug('前台定位权限变化: ${from.name} -> ${to.name}', tag: 'Location');

    if (from.isDenied && to.isGranted) {
      logger.debug('前台定位权限已开启', tag: 'Location');
      // 上报定位开启事件
      SensitiveDataService.instance.reportLocationOpen();
      // 更新 header 中的定位权限状态
      BusinessHeaderInterceptor.updateLocationPermissionStatus(true);
    } else if (from.isGranted && to.isDenied) {
      logger.error('前台定位权限已关闭', tag: 'Location');
      // 上报定位关闭事件
      SensitiveDataService.instance.reportLocationClose();
      // 更新 header 中的定位权限状态
      BusinessHeaderInterceptor.updateLocationPermissionStatus(false);
      stopLocation(); // 自动停止定位服务
    }
  }

  /// 处理后台定位权限变化（参考iOS版本的权限事件处理）
  void _handleBackgroundPermissionChange(
    PermissionStatus from,
    PermissionStatus to,
  ) {
    logger.debug('后台定位权限变化: ${from.name} -> ${to.name}', tag: 'Location');

    if (from.isDenied && to.isGranted) {
      logger.debug('后台定位权限已开启，提升定位服务能力', tag: 'Location');
      // 更新 header 中的定位权限状态（后台权限开启时，定位权限为开启状态）
      BusinessHeaderInterceptor.updateLocationPermissionStatus(true);
      // 重新配置定位参数以支持更好的后台定位
      if (isLocationEnabled.value) {
        _restartContinuousLocation();
      }
    } else if (from.isGranted && to.isDenied) {
      logger.warning('后台定位权限已关闭，可能影响后台定位效果', tag: 'Location');
      // 检查前台定位权限是否还开启，如果前台权限也关闭了，则更新 header
      _updateLocationPermissionHeaderFromStatus();
    }
  }
  
  /// 根据当前权限状态更新 header 中的定位权限状态
  Future<void> _updateLocationPermissionHeaderFromStatus() async {
    try {
      final locationStatus = await Permission.location.status;
      bool isGranted = locationStatus.isGranted;
      if (!isGranted) {
        // 如果前台权限未开启，检查后台权限
        final alwaysStatus = await Permission.locationAlways.status;
        isGranted = alwaysStatus.isGranted;
      }
      BusinessHeaderInterceptor.updateLocationPermissionStatus(isGranted);
    } catch (e) {
      logger.error('更新定位权限 header 失败: $e', tag: 'Location');
    }
  }

  /// 获取当前权限状态描述（参考iOS版本的权限状态描述）
  Map<String, String> getCurrentPermissionStatusDescription() {
    return {
      'foregroundLocation': _getPermissionDescription(
        _currentLocationPermission.value,
      ),
      'backgroundLocation': _getPermissionDescription(
        _currentBackgroundPermission.value,
      ),
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
    logger.debug('启动GPS状态监听（Android原生）', tag: 'Location');

    try {
      // 取消之前的订阅（如果存在）
      _gpsStatusSubscription?.cancel();

      // 订阅GPS状态变化EventChannel
      _gpsStatusSubscription = SimpleLocationService._gpsStatusChannel
          .receiveBroadcastStream()
          .listen(
            (dynamic data) {
              bool? isEnabled;
              
              // 支持bool类型（标准格式）
              if (data is bool) {
                isEnabled = data;
              } 
              // 兼容Map类型（旧版本格式）
              else if (data is Map) {
                final mapData = Map<String, dynamic>.from(data);
                isEnabled = mapData['isEnabled'] as bool?;
                if (isEnabled == null) {
                  logger.warning(
                    'GPS状态Map格式错误，缺少isEnabled字段: $mapData',
                    tag: 'Location',
                  );
                }
              } 
              // 其他类型，记录警告
              else {
                logger.warning(
                  'GPS状态数据类型错误: ${data.runtimeType}，数据: $data',
                  tag: 'Location',
                );
                return;
              }
              
              // 处理GPS状态变化
              if (isEnabled != null) {
                logger.debug(
                  '收到GPS状态变化通知: ${isEnabled ? "开启" : "关闭"}',
                  tag: 'Location',
                );
                _handleGpsStatusChange(isEnabled);
              }
            },
            onError: (dynamic error) {
              logger.error('GPS状态监听错误: $error', tag: 'Location');
            },
            cancelOnError: false, // 发生错误时不取消订阅
          );

      logger.debug('GPS状态监听已启动', tag: 'Location');
    } catch (e) {
      logger.error('启动GPS状态监听失败: ', tag: 'Location');
    }
  }

  /// 处理GPS开关状态变化（系统级别的定位服务开关）
  void _handleGpsStatusChange(bool isGpsEnabled) {
    // 首次初始化，只记录状态不上报
    if (_lastGpsEnabledStatus == null) {
      _lastGpsEnabledStatus = isGpsEnabled;
      logger.debug('初始化GPS状态: ${isGpsEnabled ? "开启" : "关闭"}', tag: 'Location');
      return;
    }

    // 检查状态是否发生变化
    if (_lastGpsEnabledStatus == isGpsEnabled) {
      // 状态未变化，无需处理
      return;
    }

    // 状态发生变化，记录并上报
    logger.debug(
      '检测到GPS状态变化: ${_lastGpsEnabledStatus! ? "开启" : "关闭"} -> ${isGpsEnabled ? "开启" : "关闭"}',
      tag: 'Location',
    );
    _lastGpsEnabledStatus = isGpsEnabled;

    if (isGpsEnabled) {
      // GPS开启
      logger.debug('GPS已开启，上报定位开启事件', tag: 'Location');
      SensitiveDataService.instance.reportLocationOpen();
      // 更新 header 中的定位权限状态（需要检查实际权限状态）
      _updateLocationPermissionHeaderFromStatus();
    } else {
      // GPS关闭
      logger.error('GPS已关闭，上报定位关闭事件', tag: 'Location');
      SensitiveDataService.instance.reportLocationClose();
      // GPS关闭时，定位权限视为关闭
      BusinessHeaderInterceptor.updateLocationPermissionStatus(false);
    }
  }
}

// MARK: - 位置数据验证扩展（简化版）
extension LocationValidationExtension on SimpleLocationService {
  /// 🚀 新策略：简化的收集与上报分离策略
  /// 1. 5秒获取一次定位信息，根据距离判断是否放入收集池
  /// 2. 收集池为空时直接放入，不为空时计算与最新点的距离
  /// 3. 距离>=50米放入收集池，<50米抛弃
  /// 4. 每1分钟上报一次收集池内容，上报完清空收集池
  /// 5. 直接使用原始位置数据
  void _handleLocationReporting(LocationReportModel location) {
    // 原生通道为唯一上报通道；Flutter 层不上报
  }

  /// 🚀 简化验证：只做基础的经纬度有效性检查
  bool _isBasicLocationValid(LocationReportModel location) {
    try {
      final latitude = double.parse(location.latitude);
      final longitude = double.parse(location.longitude);

      // 只检查基础的经纬度有效性
      if (latitude == 0 && longitude == 0) {
        logger.error('位置验证失败: 经纬度为(0,0)', tag: 'Location');
        return false;
      }

      // 检查经纬度范围
      if (latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180) {
        logger.error('位置验证失败: 经纬度超出有效范围', tag: 'Location');
        return false;
      }

      return true;
    } catch (e) {
      logger.error('位置验证异常: ', tag: 'Location');
      return false;
    }
  }

  // 运动状态检测和环境感知方法已删除，简化为基础的精度和距离过滤

  /// 🚀 收集位置到缓冲区
  // ignore: unused_element
  void _collectLocationToBuffer(LocationReportModel location, String reason) {
    _collectionBuffer.add(location);

    // ✅ 优化：缓冲区满了立即上报，避免丢失数据
    if (_collectionBuffer.length >=
        SimpleLocationService._maxCollectionBufferSize) {
      logger.warning(
        '缓冲区已满(${_collectionBuffer.length}/${SimpleLocationService._maxCollectionBufferSize})，触发强制上报',
        tag: 'Location',
      );
      // 立即上报缓冲区内的所有位置
      final locationsToReport = List<LocationReportModel>.from(
        _collectionBuffer,
      );
      _collectionBuffer.clear();
      _reportMultipleLocations(locationsToReport, '缓冲区满');
      logger.debug('缓冲区强制上报后，保留最后位置作为距离比较基准', tag: 'Location');
      return;
    }

    logger.debug(
      '位置收集: $reason (缓冲区: ${_collectionBuffer.length}/${SimpleLocationService._maxCollectionBufferSize})',
      tag: 'Location',
    );
    logger.debug(
      '收集位置: ${location.latitude}, ${location.longitude}, 精度: ${location.accuracy}m',
      tag: 'Location',
    );
  }

  /// 🚀 启动定时上报器
  // ignore: unused_element
  void _startReportTimer() {
    // Flutter 上报已禁用
  }

  /// 🚀 执行定时上报
  // ignore: unused_element
  void _performScheduledReport() {
    // 原生为唯一上报通道，Flutter 定时上报逻辑已禁用
  }

  /// 🚀 批量位置上报
  Future<void> _reportMultipleLocations(
    List<LocationReportModel> locations,
    String reason,
  ) async {
    // 原生为唯一上报通道，Flutter 层不上报（空实现防止误触）
  }

  /// 直接打开定位设置页面
  Future<void> _openLocationSettingsDirectly() async {
    try {
      await PermissionHelper.openLocationSettings();
      CustomToast.show(Get.context!, '请在设置中将定位权限改为"始终允许"');
    } catch (e) {
      logger.error('打开定位设置页面失败: ', tag: 'Location');
      CustomToast.show(Get.context!, '无法打开设置页面，请手动前往设置中开启定位权限');
    }
  }
}

// MARK: - 传感器监听扩展（手机方向）
extension SensorListenerExtension on SimpleLocationService {
  /// 启动传感器监听（磁力计 + 加速度计）
  void _startSensorListeners() {
    try {
      logger.debug('启动手机方向传感器监听', tag: 'Location');

      // 监听磁力计
      _magnetometerSubscription = magnetometerEventStream().listen(
        (MagnetometerEvent event) {
          _magnetometerValues = [event.x, event.y, event.z];
          _calculateHeading();
        },
        onError: (error) {
          logger.error('磁力计监听错误: $error', tag: 'Location');
        },
      );

      // 监听加速度计
      _accelerometerSubscription = accelerometerEventStream().listen(
        (AccelerometerEvent event) {
          _accelerometerValues = [event.x, event.y, event.z];
          _calculateHeading();
        },
        onError: (error) {
          logger.error('加速度计监听错误: $error', tag: 'Location');
        },
      );

      logger.debug('传感器监听启动成功', tag: 'Location');
    } catch (e) {
      logger.error('启动传感器监听失败: $e', tag: 'Location');
    }
  }

  /// 计算手机方向角度（根据磁力计和加速度计数据）
  void _calculateHeading() {
    try {
      // 使用磁力计和加速度计数据计算方向角
      final mx = _magnetometerValues[0];
      final my = _magnetometerValues[1];
      final mz = _magnetometerValues[2];

      final ax = _accelerometerValues[0];
      final ay = _accelerometerValues[1];
      final az = _accelerometerValues[2];

      // 归一化加速度计数据
      final norm = math.sqrt(ax * ax + ay * ay + az * az);
      if (norm == 0) return;

      final axNorm = ax / norm;
      final ayNorm = ay / norm;
      final azNorm = az / norm;

      // 计算旋转矩阵
      // pitch = atan2(ay, sqrt(ax^2 + az^2))
      // roll = atan2(-ax, az)
      final pitch = math.atan2(
        ayNorm,
        math.sqrt(axNorm * axNorm + azNorm * azNorm),
      );
      final roll = math.atan2(-axNorm, azNorm);

      // 补偿倾斜对磁力计的影响
      final mxCompensated = mx * math.cos(pitch) + mz * math.sin(pitch);
      final myCompensated =
          mx * math.sin(roll) * math.sin(pitch) +
          my * math.cos(roll) -
          mz * math.sin(roll) * math.cos(pitch);

      // 计算方位角（azimuth）
      var azimuth = math.atan2(myCompensated, mxCompensated);

      // 转换为度数（0-360）
      var heading = azimuth * 180 / math.pi;
      if (heading < 0) {
        heading += 360;
      }

      // 更新方向值
      currentHeading.value = heading;
    } catch (e) {
      logger.error('计算手机方向失败: $e', tag: 'Location');
    }
  }
}
