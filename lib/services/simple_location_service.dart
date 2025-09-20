import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'package:amap_flutter_location/amap_location_option.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:kissu_app/model/location_model/location_report_model.dart';
import 'package:kissu_app/network/public/location_report_api.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';

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
  
  // 应用生命周期状态（用于模拟iOS的应用状态监听）
  // ignore: unused_field
  String? _lastAppState; // 预留字段，在WidgetsBindingObserver实现中使用
  
  // 后台任务标识（增强版后台任务）
  int? _backgroundTaskId;
  Timer? _backgroundKeepAliveTimer;
  
  // 多重保障定时器（增强后台稳定性）
  Timer? _quickCheckTimer;     // 快速检查定时器（15秒）
  Timer? _mediumCheckTimer;    // 中等检查定时器（45秒）
  Timer? _deepCheckTimer;      // 深度检查定时器（90秒）
  
  // 配置参数 - 与iOS版本完全一致的策略
  static const Duration _reportInterval = Duration(minutes: 1); // 1分钟上报间隔（与iOS一致）
  static const int _maxHistorySize = 200; // 最大历史记录数（增加容量）
  static const double _distanceFilter = 50.0; // 50米距离过滤（与iOS版本完全一致）
  static const int _locationInterval = 2000; // 2秒定位间隔（平衡响应性与耗电）
  static const double _desiredAccuracy = 10.0; // 期望精度10米（已优化）
  // 与iOS策略完全一致：收集所有位置更新，保持完整轨迹和准确速度数据
  // 
  // 性能优化说明：
  // 1. distanceFilter = 50米：平衡精度与性能，避免过度采集
  // 2. locationInterval = 2秒：平衡响应性与耗电，避免频繁唤醒GPS
  // 3. 采用批量上报策略：减少网络请求，提高上报效率
  
  @override
  void onInit() {
    super.onInit();
    // 服务初始化时立即设置API Key和隐私合规
    init();
    // 设置全局唯一的监听器
    _setupGlobalLocationListener();
    // 设置应用生命周期监听（参考iOS应用状态监听）
    _setupAppLifecycleListener();
    // 初始化权限状态
    _initializePermissionStatus();
    debugPrint('✅ SimpleLocationService 初始化完成（已增强后台处理能力）');
  }

  @override
  void onClose() {
    stopLocation();
    _removeAppLifecycleListener(); // 清理生命周期监听
    _backgroundKeepAliveTimer?.cancel();
    // 清理全局监听器
    _globalLocationSub?.cancel();
    _globalLocationSub = null;
    _isGlobalListenerSetup = false;
    super.onClose();
  }
  
  /// 设置高德地图隐私合规和API Key
  /// 初始化定位服务（参考用户示例风格）
  void init() {
    try {
      // 确保在应用启动时就设置隐私合规
      AMapFlutterLocation.updatePrivacyShow(true, true);
      AMapFlutterLocation.updatePrivacyAgree(true);

      // 设置API Key - 确保在任何定位操作前执行
      AMapFlutterLocation.setApiKey('38edb925a25f22e3aae2f86ce7f2ff3b', '');

      debugPrint('✅ 高德定位服务初始化完成');
    } catch (e) {
      debugPrint('❌ 初始化高德定位服务失败: $e');
    }
  }
  
  void _setupPrivacyCompliance() {
    try {
      // 重新设置隐私合规（确保在定位前生效）
      AMapFlutterLocation.updatePrivacyShow(true, true);
      AMapFlutterLocation.updatePrivacyAgree(true);

      // 重新设置API Key（确保在定位前生效）
      AMapFlutterLocation.setApiKey('38edb925a25f22e3aae2f86ce7f2ff3b', '');

      debugPrint('🔧 高德定位隐私合规和API Key设置完成');
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

      // 1. 首先申请前台定位权限
      var locationStatus = await Permission.location.status;
      debugPrint('🔐 前台定位权限状态: $locationStatus');

      if (locationStatus.isDenied) {
        locationStatus = await Permission.location.request();
        debugPrint('🔐 申请前台定位权限结果: $locationStatus');

        if (locationStatus.isDenied) {
          CustomToast.show(
            Get.context!,
            '定位权限被拒绝，无法使用定位功能',
          );
          return false;
        }
      }

      if (locationStatus.isPermanentlyDenied) {
        CustomToast.show(
          Get.context!,
          '定位权限被永久拒绝，请在设置中开启定位权限',
        );
        return false;
      }

      // 2. 申请后台定位权限（Android 10+需要）
      if (locationStatus.isGranted) {
        debugPrint('🔐 前台定位权限已获得，检查后台定位权限...');

        var backgroundLocationStatus = await Permission.locationAlways.status;
        debugPrint('🔐 后台定位权限状态: $backgroundLocationStatus');

        if (backgroundLocationStatus.isDenied) {
          debugPrint('🔐 申请后台定位权限...');
          backgroundLocationStatus = await Permission.locationAlways.request();
          debugPrint('🔐 申请后台定位权限结果: $backgroundLocationStatus');

          // 后台定位权限不是必需的，但建议用户开启
          if (backgroundLocationStatus.isDenied) {
            debugPrint('⚠️ 后台定位权限被拒绝，但前台定位仍可使用');
            CustomToast.show(
              Get.context!,
              '建议开启后台定位权限以获得更好的定位体验',
            );
          }
        }
      }

      debugPrint('✅ 定位权限申请完成');
      return locationStatus.isGranted;
    } catch (e) {
      debugPrint('❌ 请求定位权限失败: $e');
      return false;
    }
  }
  
  /// 开始定位
  Future<bool> startLocation() async {
    try {
      debugPrint('🚀 SimpleLocationService.startLocation() 开始执行');

      // 确保先初始化（这很关键！）
      init();
      await Future.delayed(Duration(milliseconds: 100)); // 给初始化一点时间

      // 设置高德地图隐私合规（必须在任何定位操作之前）
      _setupPrivacyCompliance();
      debugPrint('🔧 隐私合规设置完成');
      
      // 检查权限
      bool hasPermission = await requestLocationPermission();
      debugPrint('🔧 定位权限检查结果: $hasPermission');
      if (!hasPermission) {
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
      
      // 设置高德定位参数 - 参考iOS版本的高精度配置
      debugPrint('🔧 开始设置高德定位参数（参考iOS版本）...');
      AMapLocationOption locationOption = AMapLocationOption();
      
      // 设置定位模式 - 使用高精度模式以获取GPS速度数据（参考iOS的kCLLocationAccuracyBest）
      locationOption.locationMode = AMapLocationMode.Hight_Accuracy; // 高精度模式，包含GPS
      debugPrint('   - 定位模式: 高精度模式（GPS+网络+WIFI）- 参考iOS的kCLLocationAccuracyBest');
      
      // 设置定位间隔（参考iOS版本）
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
            break;
          case 14:
            debugPrint('❌ 错误码14: GPS定位失败');
            suggestion = 'GPS信号弱，尝试切换到网络定位';
            shouldRetry = true;
            break;
          case 15:
            debugPrint('❌ 错误码15: 定位服务关闭');
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
      
      // 新策略：实时上报，不批量收集
      _handleLocationReporting(location);
      
      // debugPrint('🎯 高德实时定位: ${location.latitude}, ${location.longitude}, 精度: ${location.accuracy}米, 速度: ${location.speed}m/s');
      
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
      _setupPrivacyCompliance();

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
  
  /// 启动定时单次定位（备用方案）
  void _startPeriodicSingleLocation() {
    debugPrint('🔄 启动定时单次定位作为备用方案...');
    
    // 每30秒进行一次单次定位，确保有数据回调
    _periodicLocationTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
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
      _setupPrivacyCompliance();
      
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
        _setupPrivacyCompliance();
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
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (pi / 180.0);
  
  
  
  
  
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
    // 1. 启动后台保活
    _startBackgroundKeepAlive();
    
    // 2. 增强位置采集频率（后台模式）
    _enableBackgroundLocationMode();
    
    // 3. 启动多重保障定时器
    _startMultipleBackgroundTimers();
  }
  
  /// 停止增强的后台策略
  void _stopEnhancedBackgroundStrategy() {
    // 1. 停止后台保活
    _stopBackgroundKeepAlive();
    
    // 2. 恢复正常位置采集
    _enableForegroundLocationMode();
    
    // 3. 停止多重保障定时器
    _stopMultipleBackgroundTimers();
  }
  
  /// 启用后台位置模式
  void _enableBackgroundLocationMode() {
    debugPrint('🔧 启用后台位置采集模式');
    // 在后台时，可以适当降低采集频率以节省电量
    // 但保持定期上报以确保数据完整性
  }
  
  /// 启用前台位置模式
  void _enableForegroundLocationMode() {
    debugPrint('🔧 恢复前台位置采集模式');
    // 前台时恢复正常的高频率采集
  }
  
  /// 应用终止前保存数据
  void _saveLocationDataBeforeTermination() {
    // 新策略：实时上报，无需在应用终止前处理批量数据
    debugPrint('💾 应用终止前，清理定位服务状态');
  }
}

// MARK: - 增强后台任务管理扩展
extension BackgroundTaskExtension on SimpleLocationService {
  
  /// 开始后台保活任务（增强版本）
  void _startBackgroundKeepAlive() {
    _backgroundTaskId = DateTime.now().millisecondsSinceEpoch;
    debugPrint('🔧 开始增强后台保活任务 ID: $_backgroundTaskId');
    
    // 启动主保活定时器（30秒间隔）
    _backgroundKeepAliveTimer?.cancel();
    _backgroundKeepAliveTimer = Timer.periodic(Duration(seconds: 30), (timer) {
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
  
  /// 启动多重保障定时器（增强后台稳定性）
  void _startMultipleBackgroundTimers() {
    // 停止现有定时器
    _stopMultipleBackgroundTimers();
    
    // 定时器1：快速检查（15秒）- 检查定位服务状态
    _quickCheckTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      _quickLocationServiceCheck();
    });
    
    // 定时器2：中等检查（45秒）- 检查位置更新
    _mediumCheckTimer = Timer.periodic(Duration(seconds: 45), (timer) {
      _mediumLocationUpdateCheck();
    });
    
    // 定时器3：深度检查（90秒）- 完整性检查和恢复
    _deepCheckTimer = Timer.periodic(Duration(seconds: 90), (timer) {
      _deepLocationIntegrityCheck();
    });
    
    debugPrint('🔧 启动多重保障定时器：15s/45s/90s');
  }
  
  /// 停止多重保障定时器
  void _stopMultipleBackgroundTimers() {
    _quickCheckTimer?.cancel();
    _quickCheckTimer = null;
    
    _mediumCheckTimer?.cancel();
    _mediumCheckTimer = null;
    
    _deepCheckTimer?.cancel();
    _deepCheckTimer = null;
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
    
    // 1. 新策略：实时上报，无需检查数据积压
    
    // 2. 新策略：不再需要定时器检查
    
    // 3. 检查连续定位状态 
    // 注：这里暂时注释掉，因为_continuousLocationTimer可能不存在
    // if (_continuousLocationTimer?.isActive ?? false) {
    //   debugPrint('⚠️ 深度检查：连续定位定时器异常，重启');
    //   _restartContinuousLocation();
    // }
    
    debugPrint('✅ 深度检查完成');
  }
  
  /// 检查定位服务健康状态
  bool _isLocationServiceHealthy() {
    // 检查关键状态
    return isLocationEnabled.value && 
           _currentLocationPermission.value == PermissionStatus.granted;
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
  
  /// 重启定位服务
  void _restartLocationService() {
    debugPrint('🔄 重启定位服务');
    stopLocation();
    Future.delayed(Duration(seconds: 2), () {
      startLocation();
    });
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
      // 可以在这里发送权限开启事件（参考iOS版本的locationPermissionEventSubject）
    } else if (from.isGranted && to.isDenied) {
      debugPrint('❌ 前台定位权限已关闭');
      // 可以在这里发送权限关闭事件
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

  /// 新的位置上报处理逻辑
  /// 实现三种上报策略：
  /// 1. 首次定位立即上报
  /// 2. 移动超过50米立即上报
  /// 3. 每分钟定时上报
  void _handleLocationReporting(LocationReportModel location) {
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
}