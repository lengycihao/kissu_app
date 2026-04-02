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
  // 后台通知管理
  bool _isBackgroundNotificationShown = false; // 后台通知显示状态
  DateTime? _lastNotificationTime; // 上次通知时间

  // 🚀 核心策略参数
  static const double _distanceFilter = -1; // 不做距离过滤，由上报层处理
  static const int _locationInterval = 5000; // 5秒定位间隔


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
 
      // 1. 首先确保有前台定位权限
      var locationStatus = await Permission.location.status;
      // logger.info('前台定位权限状态: $locationStatus', tag: 'Location');

      if (!locationStatus.isGranted) {
        // logger.info('先申请前台定位权限...', tag: 'Location');
        locationStatus = await Permission.location.request();
 
        if (!locationStatus.isGranted) {
          logger.error('前台定位权限被拒绝，无法申请后台权限', tag: 'Location');
          CustomToast.show(Get.context!, '请先开启定位权限，然后再申请后台定位权限');
          return false;
        }
      }

      // 2. 检查后台定位权限状态
      var backgroundLocationStatus = await Permission.locationAlways.status;
 
      if (backgroundLocationStatus.isDenied) {
        // logger.info('申请后台定位权限...', tag: 'Location');
        backgroundLocationStatus = await Permission.locationAlways.request();
 
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
         AMapFlutterLocation.updatePrivacyAgree(true);
      }

      // 确保先初始化（这很关键！）
      init();
      await Future.delayed(Duration(milliseconds: 100)); // 给初始化一点时间

      // 设置高德地图隐私合规（必须在任何定位操作之前）
      await _setupPrivacyCompliance();
 
      // 检查权限状态，但不重复请求
      var locationStatus = await Permission.location.status;
      // logger.info('定位权限状态: $locationStatus', tag: 'Location');
      if (!locationStatus.isGranted) {
        logger.error('定位权限检查失败，无法启动定位服务', tag: 'Location');
        return false;
      }

      // 如果已经在定位，先停止
      if (isLocationEnabled.value) {
         stopLocation();
        // 等待一小段时间确保停止完成
        await Future.delayed(Duration(milliseconds: 500));
      }

      try {

        _locationPlugin.stopLocation(); // 安全的检查调用
       } catch (e) {
        logger.error('高德定位插件可能未正确初始化: ', tag: 'Location');
      }

      // 确保流监听器已彻底清理
      try {
        // 停止现有定位
        _locationPlugin.stopLocation();
        // 等待确保完全停止
        await Future.delayed(Duration(milliseconds: 500));
       } catch (e) {
        logger.warning('清理监听器时出现异常: $e', tag: 'Location');
      }
      AMapLocationOption locationOption = AMapLocationOption();

      locationOption.locationMode =
          AMapLocationMode.Hight_Accuracy; // 高精度模式，包含GPS

      locationOption.locationInterval = _locationInterval; // 5秒间隔，平衡响应性与耗电
 
      // ✅ 关键修复：取消距离过滤，让定位层保证数据完整性
      locationOption.distanceFilter = -1;
      // logger.debug('- 距离过滤: ${_distanceFilter}米（设为0以避免与时间间隔冲突）', tag: 'Location');
      // 设置地址信息
      locationOption.needAddress = false;
      // 设置持续定位
      locationOption.onceLocation = false;
      try {
        _locationPlugin.setLocationOption(locationOption);
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
       } catch (e) {
        logger.error('启动高德定位失败: ', tag: 'Location');
        throw e;
      }

      // 添加延迟检查
      Future.delayed(Duration(seconds: 5), () {
         if (currentLocation.value == null) {
          logger.warning('5秒后仍未收到定位数据，尝试单次定位...', tag: 'Location');
          _requestSingleLocation();
        }
      });

      // 新策略：不再需要定时器，改为实时上报

      isLocationEnabled.value = true;
      hasInitialReport.value = false; // 重置初始上报状态

      // 🔥 关键修复：立即启动前台服务，确保息屏后能继续定位

      await _enableForegroundServiceIfNeeded();

      // 🔥 重要优化：根据应用状态智能决定是否启动后台定时器
      _smartStartLocationStrategy();

      // 🚀 每次启动定位服务时，立即尝试获取一次定位并放入收集池
       _requestInitialLocationForCollection();

       return true;
    } catch (e) {
      logger.error('启动高德定位失败: $e', tag: 'Location');
      return false;
    }
  }

  /// 处理位置更新
  void _onLocationUpdate(Map<String, Object> result) {
    try {
 
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

        // ✅ 优化：使用指数退避策略进行智能重试
        if (shouldRetry && _locationRetryCount < 5) {
          _locationRetryCount++;
          // 指数退避：2秒、4秒、8秒、16秒、32秒
          final delaySeconds = 2 * (1 << (_locationRetryCount - 1)); // 2^(n-1)
           

          // 使用指数退避延迟后重试
          Future.delayed(Duration(seconds: delaySeconds), () async {
            try {
              await _lightweightReinitializePlugin();
              _locationPlugin.startLocation();
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
         return;
      }

      // 成功定位，重置重试计数
      _locationRetryCount = 0;

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

      // 更新后台通知状态
      if (_isBackgroundNotificationShown) {
        String locationText =
            address ??
            '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
        _updateBackgroundNotification('定位正常 - $locationText');
      }

      // 如果正在进行单次定位，现在收到了数据，说明单次定位成功
      if (_isSingleLocationInProgress) {
        _isSingleLocationInProgress = false;
        // 延迟重启持续定位，给单次定位一点时间完成
        Timer(Duration(milliseconds: 500), () {
          _restartContinuousLocation();
        });
      }
    } catch (e) {
      logger.error('处理高德位置更新失败: $e', tag: 'Location');
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
      // 🆕 清空当前位置数据，避免关闭定位后仍然使用旧位置
      currentLocation.value = null;

      // 🔥 停止前台服务（在这里才真正停止）
      _disableForegroundServiceIfNeeded();

      } catch (e) {
      logger.error('停止高德定位失败: $e', tag: 'Location');
    }
  }

  /// 🚀 每次启动时主动获取一次定位放入收集池
  Future<void> _requestInitialLocationForCollection() async {
    try {
 
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
 
      // 设置超时，如果10秒内没有收到定位，则重启持续定位
      Timer(Duration(seconds: 10), () {
        if (_isSingleLocationInProgress) {
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
 
      // 设置超时，如果10秒内没有收到定位，则重启持续定位
      Timer(Duration(seconds: 10), () {
        if (_isSingleLocationInProgress) {
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
       AMapLocationOption locationOption = AMapLocationOption();
      locationOption.locationMode = AMapLocationMode.Hight_Accuracy;
      locationOption.locationInterval = _locationInterval; // 5秒间隔（平衡性能）
      locationOption.distanceFilter = _distanceFilter; //
      // 优化已实现
      locationOption.needAddress = false;
      locationOption.onceLocation = false; // 持续定位

      _locationPlugin.setLocationOption(locationOption);
     } catch (e) {
      logger.error('重新设置持续定位参数失败: ', tag: 'Location');
    }
  }

  /// 处理定位超时的智能恢复策略
  Future<void> _handleLocationTimeout() async {
    try {
 
      if (_locationRetryCount < 3) {
        _locationRetryCount++;
 
        // 根据重试次数采用不同策略
        switch (_locationRetryCount) {
          case 1:
            // 第一次超时：重新启动监听器
             // 全局监听器已激活，无需重新设置
            _locationPlugin.startLocation();
            break;

          case 2:
            // 第二次超时：强制重新初始化插件
             await _lightweightReinitializePlugin();
            // 全局监听器已激活，无需重新设置
            _locationPlugin.startLocation();
            break;

          case 3:
            // 第三次超时：尝试切换定位模式
             await _switchToHighAccuracyMode();
            break;

          default:
            // 最后策略：重启持续定位
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

     } catch (e) {
      logger.error('切换高精度定位模式失败: ', tag: 'Location');
      throw e;
    }
  }

  /// 轻量级重新初始化插件（避免Stream冲突）
  Future<void> _lightweightReinitializePlugin() async {
    try {
 
      // 只停止定位，不干扰Stream
      _locationPlugin.stopLocation();
      await Future.delayed(Duration(milliseconds: 300));

      // 重新设置隐私合规和API Key
      await _setupPrivacyCompliance();

      await Future.delayed(Duration(milliseconds: 200));
     } catch (e) {
      logger.error('轻量级重新初始化插件失败: ', tag: 'Location');
      throw e;
    }
  }

  // 旧的Stream监听器方法已移除，现在使用全局监听器

  /// 重启持续定位
  Future<void> _restartContinuousLocation() async {
    try {
 
      _locationPlugin.stopLocation();
      await Future.delayed(Duration(milliseconds: 300));

      // 重新设置持续定位参数
      _setupContinuousLocation();

      // 重新开始定位（不需要重新设置监听器，因为监听器是持续的）
      _locationPlugin.startLocation();
     } catch (e) {
      logger.error('重启持续定位失败: ', tag: 'Location');
    }
  }

  /// 检查服务状态（用于测试）
  bool get isServiceRunning => isLocationEnabled.value;

  /// 尝试纯网络定位（不依赖GPS）
  Future<void> tryNetworkLocationOnly() async {
 
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

      // 启动定位
      _locationPlugin.startLocation();
 
      // 等待15秒
      await Future.delayed(Duration(seconds: 15));

       
    } catch (e) {
      logger.error('网络定位出错: ', tag: 'Location');
    }
  }

  /// 获取位置历史记录数量
  int get historyCount => locationHistory.length;

  /// 获取当前是否有位置数据
  bool get hasLocation => currentLocation.value != null;

  /// 获取当前定位精度
  String get currentAccuracy => currentLocation.value?.accuracy ?? '0.0';

  /// 外部接口：确保后台策略激活
  void ensureBackgroundStrategyActive() {
    if (!isLocationEnabled.value) return;
    _startEnhancedBackgroundStrategy();
  }

  /// 外部接口：优化前台策略
  void optimizeForegroundStrategy() {
    if (!isLocationEnabled.value) return;
    _stopEnhancedBackgroundStrategy();
  }

  /// 智能启动策略：根据应用状态决定是否启动后台定时器
  void _smartStartLocationStrategy() {
    try {
      // 获取应用生命周期状态
      final appLifecycle = AppLifecycleService.instance;
      final isInBackground = appLifecycle.isInBackground;
      if (isInBackground) {
        // 应用在后台，启动增强后台策略
        _startEnhancedBackgroundStrategy();
      } else {
        // 应用在前台，只启动基础定位，不启动后台定时器
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
    WidgetsBinding.instance.addObserver(this);
  }

  /// 清理生命周期监听
  void _removeAppLifecycleListener() {
    WidgetsBinding.instance.removeObserver(this);
  }

  /// 真实的应用状态变化监听
  void didChangeAppLifecycleState(AppLifecycleState state) {

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
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  /// 应用进入后台（真实状态检测）
  void _onAppDidEnterBackground() {
    _startEnhancedBackgroundStrategy();
  }

  /// 应用进入前台（真实状态检测）
  void _onAppWillEnterForeground() {
    _stopEnhancedBackgroundStrategy();
  }

  /// 应用即将终止
  void _onAppWillTerminate() {
    _saveLocationDataBeforeTermination();
  }

  /// 启动增强的后台策略
  void _startEnhancedBackgroundStrategy() {
    // 启用前台服务模式（Android）
    _enableForegroundServiceIfNeeded();

    // 2. 增强位置采集频率（后台模式）
    _enableBackgroundLocationMode();

    // 4. 显示后台运行通知
    _showBackgroundNotification();
  }

  /// 停止增强的后台策略
  void _stopEnhancedBackgroundStrategy() {

    // 2. 恢复正常位置采集
    _enableForegroundLocationMode();

    // 4. 隐藏后台运行通知
    _hideBackgroundNotification();
  }

  /// 启用后台位置模式
  void _enableBackgroundLocationMode() {
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

    } catch (e) {
      logger.error('启用后台位置模式失败: ', tag: 'Location');
    }
  }

  /// 启用前台位置模式
  void _enableForegroundLocationMode() {
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

    } catch (e) {
      logger.error('启用前台位置模式失败: ', tag: 'Location');
    }
  }

  /// 应用终止前保存数据
  void _saveLocationDataBeforeTermination() {

    // 隐藏后台通知
    _hideBackgroundNotification();
  }

  /// 显示后台运行通知
  void _showBackgroundNotification() {
    if (_isBackgroundNotificationShown) {
      return;
    }

    try {
      // 检查通知频率限制（避免过于频繁）
      final now = DateTime.now();
      if (_lastNotificationTime != null &&
          now.difference(_lastNotificationTime!).inMinutes < 5) {
        return;
      }

      _isBackgroundNotificationShown = true;
      _lastNotificationTime = now;

    } catch (e) {
      logger.error('显示后台通知失败: ', tag: 'Location');
      _isBackgroundNotificationShown = false;
    }
  }

  /// 隐藏后台运行通知
  void _hideBackgroundNotification() {
    if (!_isBackgroundNotificationShown) {
      return;
    }

    try {
      _isBackgroundNotificationShown = false;


    } catch (e) {
      logger.error('隐藏后台通知失败: ', tag: 'Location');
    }
  }

  /// 更新后台通知内容
  void _updateBackgroundNotification(String status) {
    if (!_isBackgroundNotificationShown) return;

    try {

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
        return;
      }

      final success = await foregroundService.startForegroundService();

      if (success) {

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


// MARK: - 权限管理扩展（参考iOS版本的权限处理）
extension PermissionManagementExtension on SimpleLocationService {
  /// 初始化权限状态（参考iOS版本的权限监听）
  void _initializePermissionStatus() {
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

    if (from.isDenied && to.isGranted) {
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

    if (from.isDenied && to.isGranted) {
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
                _handleGpsStatusChange(isEnabled);
              }
            },
            onError: (dynamic error) {
              logger.error('GPS状态监听错误: $error', tag: 'Location');
            },
            cancelOnError: false, // 发生错误时不取消订阅
          );
    } catch (e) {
      logger.error('启动GPS状态监听失败: ', tag: 'Location');
    }
  }

  /// 处理GPS开关状态变化（系统级别的定位服务开关）
  void _handleGpsStatusChange(bool isGpsEnabled) {
    // 首次初始化，只记录状态不上报
    if (_lastGpsEnabledStatus == null) {
      _lastGpsEnabledStatus = isGpsEnabled;
      return;
    }

    // 检查状态是否发生变化
    if (_lastGpsEnabledStatus == isGpsEnabled) {
      // 状态未变化，无需处理
      return;
    }

    _lastGpsEnabledStatus = isGpsEnabled;

    if (isGpsEnabled) {
      // GPS开启
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

// MARK: - 权限辅助扩展
extension LocationValidationExtension on SimpleLocationService {
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
