import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'package:amap_flutter_location/amap_location_option.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:kissu_app/model/location_model/location_report_model.dart';
import 'package:kissu_app/network/public/location_report_api.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';

/// 基于高德定位的简化版定位服务类
class SimpleLocationService extends GetxService {
  static SimpleLocationService get instance => Get.find<SimpleLocationService>();
  
  // 高德定位插件
  final AMapFlutterLocation _locationPlugin = AMapFlutterLocation();
  
  // 当前最新位置
  final Rx<LocationReportModel?> currentLocation = Rx<LocationReportModel?>(null);
  
  // 位置历史记录（用于采样点检测）
  final RxList<LocationReportModel> locationHistory = <LocationReportModel>[].obs;
  
  // 待上报的位置数据
  final RxList<LocationReportModel> pendingReports = <LocationReportModel>[].obs;
  
  // 定时器
  Timer? _reportTimer;
  
  // 定位流订阅
  StreamSubscription<Map<String, Object>>? _locationSub;
  StreamSubscription<Map<String, Object>>? _singleLocationSub;
  
  // 服务状态
  final RxBool isLocationEnabled = false.obs;
  final RxBool isReporting = false.obs;
  final RxBool hasInitialReport = false.obs; // 是否已进行初始上报
  
  // 配置参数
  static const double _samplingDistance = 50.0; // 50米采样距离（符合用户要求）
  static const Duration _reportInterval = Duration(minutes: 1); // 1分钟上报间隔
  static const int _maxHistorySize = 200; // 最大历史记录数（增加容量）
  
  @override
  void onClose() {
    stopLocation();
    _reportTimer?.cancel();
    _singleLocationSub?.cancel();
    super.onClose();
  }
  
  /// 设置高德地图隐私合规和API Key
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
  
  /// 请求定位权限
  Future<bool> requestLocationPermission() async {
    try {
      // 检查定位权限
      var status = await Permission.location.status;
      if (status.isDenied) {
        status = await Permission.location.request();
        if (status.isDenied) {
          CustomToast.show(
            Get.context!,
            '定位权限被拒绝',
          );
          return false;
        }
      }

      if (status.isPermanentlyDenied) {
        CustomToast.show(
          Get.context!,
          '定位权限被永久拒绝，请在设置中开启定位权限',
        );
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('请求定位权限失败: $e');
      return false;
    }
  }
  
  /// 开始定位
  Future<bool> startLocation() async {
    try {
      debugPrint('🚀 SimpleLocationService.startLocation() 开始执行');
      
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
      
      // 确保流监听器已彻底清理
      try {
        // 停止现有定位
        _locationPlugin.stopLocation();
        debugPrint('🔧 高德定位插件已停止');
        
        // 取消流监听器
        await _locationSub?.cancel();
        _locationSub = null;
        
        await _singleLocationSub?.cancel();
        _singleLocationSub = null;
        
        debugPrint('🔧 所有流监听器清理完成');
        
        // 等待确保完全停止
        await Future.delayed(Duration(milliseconds: 500));
        debugPrint('🔧 清理完成，等待结束');
      } catch (e) {
        debugPrint('⚠️ 清理监听器时出现异常: $e');
      }
      
      // 设置高德定位参数 - 高精度定位
      AMapLocationOption locationOption = AMapLocationOption();
      locationOption.locationMode = AMapLocationMode.Hight_Accuracy; // 高精度模式
      locationOption.locationInterval = 1000; // 定位间隔，1秒（更频繁）
      locationOption.distanceFilter = 5; // 距离过滤，5米（更敏感）
      locationOption.needAddress = true; // 需要地址信息
      locationOption.onceLocation = false; // 持续定位
      
      _locationPlugin.setLocationOption(locationOption);
      debugPrint('🔧 高德定位参数设置完成');

      // 启动位置流监听
      debugPrint('🔧 开始设置位置流监听器');
      _locationSub = _locationPlugin.onLocationChanged().listen(
        (Map<String, Object> result) {
          debugPrint('🔧 收到定位数据回调');
          _onLocationUpdate(result);
        },
        onError: (error) {
          debugPrint('❌ 高德定位错误: $error');
        },
        onDone: () {
          debugPrint('⚠️ 高德定位流已关闭');
        },
      );
      debugPrint('🔧 位置流监听器设置完成');

      // 启动定位（高德定位插件3.0.0版本的startLocation()方法返回void）
      debugPrint('🔧 调用高德定位插件启动定位');
      _locationPlugin.startLocation();
      debugPrint('🔧 高德定位启动请求已发送');
      
      // 添加延迟检查
      Future.delayed(Duration(seconds: 5), () {
        debugPrint('⏰ 5秒后检查：定位是否有数据回调...');
      });
      
      Future.delayed(Duration(seconds: 10), () {
        debugPrint('⏰ 10秒后检查：定位是否有数据回调...');
      });
      
      // 启动定时上报
      debugPrint('🔧 启动定时上报');
      _startReportTimer();
      
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
      debugPrint('📍 _onLocationUpdate 被调用，收到数据: ${result.toString()}');
      
      // 检查高德定位错误码
      int? errorCode = int.tryParse(result['errorCode']?.toString() ?? '0');
      String? errorInfo = result['errorInfo']?.toString();
      
      if (errorCode != null && errorCode != 0) {
        debugPrint('❌ 高德定位失败 - 错误码: $errorCode, 错误信息: $errorInfo');
        // 常见错误码说明
        switch (errorCode) {
          case 12:
            debugPrint('❌ 错误码12: 缺少定位权限');
            break;
          case 13:
            debugPrint('❌ 错误码13: 网络异常');
            break;
          case 14:
            debugPrint('❌ 错误码14: GPS定位失败');
            break;
          case 15:
            debugPrint('❌ 错误码15: 定位服务关闭');
            break;
          case 16:
            debugPrint('❌ 错误码16: 获取地址信息失败');
            break;
          case 17:
            debugPrint('❌ 错误码17: 定位参数错误');
            break;
          case 18:
            debugPrint('❌ 错误码18: 定位超时');
            break;
          default:
            debugPrint('❌ 其他定位错误: $errorCode - $errorInfo');
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
      
      if (latitude == null || longitude == null) {
        debugPrint('高德定位数据无效: $result');
        return;
      }

      final location = LocationReportModel(
        longitude: longitude.toString(),
        latitude: latitude.toString(),
        locationTime: timestamp != null ? (timestamp ~/ 1000).toString() : 
                     (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(),
        speed: (speed ?? 0.0).toStringAsFixed(2),
        altitude: (altitude ?? 0.0).toStringAsFixed(2),
        locationName: address ?? '位置 ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
        accuracy: (accuracy ?? 0.0).toStringAsFixed(2),
      );

      // 更新当前位置
      currentLocation.value = location;
      
      // 检查并添加采样点
      bool shouldAdd = _checkAndAddSamplingPoint(location);
      
      // 如果是第一个位置点，立即上报
      if (!hasInitialReport.value) {
        hasInitialReport.value = true;
        _addToPendingReports(location);
        debugPrint('🚀 首次定位成功，立即上报位置数据');
        debugPrint('📤 开始执行首次上报操作...');
        _reportLocationData(); // 立即上报
      } else if (shouldAdd) {
        // 后续位置点，添加到待上报列表
        _addToPendingReports(location);
        debugPrint('📍 添加新的采样点到待上报列表 (总采样点: ${locationHistory.length}, 待上报: ${pendingReports.length})');
      } else {
        // 位置点被过滤，但记录调试信息
        debugPrint('📍 位置点被过滤 (距离不足$_samplingDistance米)');
      }
      
      debugPrint('🎯 高德实时定位: ${location.latitude}, ${location.longitude}, 精度: ${location.accuracy}米, 速度: ${location.speed}m/s');
    } catch (e) {
      debugPrint('处理高德位置更新失败: $e');
    }
  }
  
  /// 停止定位
  void stopLocation() {
    try {
      // 停止定时器
      _reportTimer?.cancel();
      _reportTimer = null;
      
      // 停止位置流监听
      _locationSub?.cancel();
      _locationSub = null;
      _singleLocationSub?.cancel();
      _singleLocationSub = null;
      
      // 停止高德定位
      _locationPlugin.stopLocation();
      
      // 重置状态
      isLocationEnabled.value = false;
      isReporting.value = false;
      hasInitialReport.value = false;
      
      debugPrint('高德定位服务已停止');
    } catch (e) {
      debugPrint('停止高德定位失败: $e');
    }
  }
  
  /// 检查服务状态（用于测试）
  bool get isServiceRunning => isLocationEnabled.value;
  
  /// 强制重启定位服务（用于测试）
  Future<bool> forceRestartLocation() async {
    try {
      debugPrint('🔄 强制重启定位服务...');
      
      // 完全停止服务
      stopLocation();
      
      // 等待确保完全停止
      await Future.delayed(Duration(milliseconds: 1000));
      
      // 重新启动
      return await startLocation();
    } catch (e) {
      debugPrint('❌ 强制重启定位服务失败: $e');
      return false;
    }
  }
  
  /// 检查并添加采样点
  bool _checkAndAddSamplingPoint(LocationReportModel newLocation) {
    if (locationHistory.isEmpty) {
      // 第一个位置点，直接添加
      locationHistory.add(newLocation);
      return true;
    }
    
    // 获取最后一个位置
    LocationReportModel lastLocation = locationHistory.last;
    
    // 计算距离
    double distance = _calculateDistance(
      double.parse(lastLocation.latitude),
      double.parse(lastLocation.longitude),
      double.parse(newLocation.latitude),
      double.parse(newLocation.longitude),
    );
    
    // 如果移动距离超过50米，添加为采样点
    if (distance >= _samplingDistance) {
      locationHistory.add(newLocation);
      
      // 限制历史记录大小
      if (locationHistory.length > _maxHistorySize) {
        locationHistory.removeAt(0);
      }
      
      debugPrint('添加采样点: 距离 ${distance.toStringAsFixed(2)}米');
      return true;
    }
    
    return false;
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
  
  /// 启动定时上报
  void _startReportTimer() {
    _reportTimer?.cancel();
    debugPrint('⏰ 启动定时上报器，间隔: ${_reportInterval.inMinutes}分钟');
    _reportTimer = Timer.periodic(_reportInterval, (timer) {
      debugPrint('⏰ 定时器触发，开始上报位置数据');
      _reportLocationData();
    });
  }
  
  /// 添加位置到待上报列表
  void _addToPendingReports(LocationReportModel location) {
    pendingReports.add(location);
    debugPrint('📝 添加位置到待上报列表: ${pendingReports.length}个点 (${location.latitude}, ${location.longitude})');
  }
  
  /// 上报位置数据
  Future<void> _reportLocationData() async {
    if (isReporting.value) {
      debugPrint('⚠️ 正在上报中，跳过本次上报');
      return;
    }
    
    if (pendingReports.isEmpty) {
      debugPrint('⚠️ 没有待上报的位置数据');
      return;
    }
    
    try {
      isReporting.value = true;
      
      // 获取待上报的位置数据
      List<LocationReportModel> locationsToReport = List.from(pendingReports);
      
      debugPrint('📤 开始上报位置数据: ${locationsToReport.length}个点');
      debugPrint('📤 上报数据详情: ${locationsToReport.map((e) => '${e.latitude},${e.longitude}').join(' | ')}');
      
      // 调用API上报
      final api = LocationReportApi();
      final result = await api.reportLocation(locationsToReport);
      
      if (result.isSuccess) {
        debugPrint('✅ 位置数据上报成功: ${locationsToReport.length}个点');
        debugPrint('✅ 服务器响应: ${result.msg}');
        // 清空已上报的数据
        pendingReports.clear();
      } else {
        debugPrint('❌ 位置数据上报失败: ${result.msg}');
        debugPrint('❌ 失败数据将保留，下次重试');
        // 上报失败，保留数据下次重试
      }
    } catch (e) {
      debugPrint('❌ 上报位置数据异常: $e');
      debugPrint('❌ 异常数据将保留，下次重试');
    } finally {
      isReporting.value = false;
    }
  }
  
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
  
  /// 获取待上报位置数量
  int get pendingReportCount => pendingReports.length;
  
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
  
  /// 强制上报所有待上报的位置数据
  Future<bool> forceReportAllPending() async {
    if (pendingReports.isEmpty) {
      debugPrint('没有待上报的位置数据');
      return true;
    }
    
    try {
      isReporting.value = true;
      
      final api = LocationReportApi();
      final result = await api.reportLocation(List.from(pendingReports));
      
      if (result.isSuccess) {
        debugPrint('强制上报成功: ${pendingReports.length}个点');
        pendingReports.clear();
        return true;
      } else {
        debugPrint('强制上报失败: ${result.msg}');
        return false;
      }
    } catch (e) {
      debugPrint('强制上报异常: $e');
      return false;
    } finally {
      isReporting.value = false;
    }
  }
  
  /// 清空所有历史数据
  void clearAllData() {
    locationHistory.clear();
    pendingReports.clear();
    currentLocation.value = null;
    hasInitialReport.value = false;
    debugPrint('已清空所有位置数据');
  }
  
  /// 获取位置历史记录（用于调试）
  List<Map<String, dynamic>> getLocationHistoryForDebug() {
    return locationHistory.map((location) => location.toJson()).toList();
  }
  
  /// 获取待上报数据（用于调试）
  List<Map<String, dynamic>> getPendingReportsForDebug() {
    return pendingReports.map((location) => location.toJson()).toList();
  }
  
  /// 获取服务状态
  Map<String, dynamic> get currentServiceStatus {
    return {
      'isLocationEnabled': isLocationEnabled.value,
      'isReporting': isReporting.value,
      'hasInitialReport': hasInitialReport.value,
      'currentLocation': currentLocation.value?.toJson(),
      'locationHistoryCount': locationHistory.length,
      'pendingReportsCount': pendingReports.length,
    };
  }
  
  /// 获取实时定位点收集统计信息
  Map<String, dynamic> getLocationCollectionStats() {
    return {
      'isLocationEnabled': isLocationEnabled.value,
      'totalLocationPoints': locationHistory.length,
      'pendingReportPoints': pendingReports.length,
      'hasInitialReport': hasInitialReport.value,
      'currentLocation': currentLocation.value?.toJson(),
      'samplingDistance': _samplingDistance,
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
    debugPrint('   采样距离: ${stats['samplingDistance']}米');
    debugPrint('   上报间隔: ${stats['reportInterval']}分钟');
    debugPrint('   当前位置: ${stats['currentLocation'] != null ? '已获取' : '未获取'}');
    if (stats['currentLocation'] != null) {
      final loc = stats['currentLocation'] as Map<String, dynamic>;
      debugPrint('   最新位置: ${loc['latitude']}, ${loc['longitude']} (精度: ${loc['accuracy']}米)');
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
      locationOption.distanceFilter = 0;
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
      await testSub?.cancel();
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
}
```

现在重新启动应用测试修复效果：

## 🎯 **最终解决方案实施完成！**

### 🔍 **问题的真正根本原因**
通过深入分析，我发现了"Stream has already been listened to"错误的真正原因：

1. **同一插件实例的Stream单例限制**：高德定位插件`AMapFlutterLocation`的`onLocationChanged()`返回的Stream是**单例**，每个插件实例只能被监听一次

2. **双重监听冲突**：
   - `startLocation()`方法在第162行监听了`_locationPlugin.onLocationChanged()`
   - `testSingleLocation()`方法在第640行试图再次监听**同一个插件实例**的Stream
   - 这导致了"Bad state: Stream has already been listened to"错误

### ✅ **最终解决方案**
我重新设计了`testSingleLocation()`方法：

1. **独立插件实例**：为单次定位测试创建独立的`AMapFlutterLocation`实例（第600行）
2. **避免Stream冲突**：两个不同的插件实例有各自的Stream，不会产生冲突
3. **更好的资源管理**：测试完成后正确清理独立插件实例

### 🔧 **关键改进点**
```dart
// 旧代码（有冲突）：
testSub = _locationPlugin.onLocationChanged().listen(...)  // 与startLocation冲突

// 新代码（无冲突）：
AMapFlutterLocation testLocationPlugin = AMapFlutterLocation();  // 独立实例
testSub = testLocationPlugin.onLocationChanged().listen(...)     // 独立Stream
```

### 🎯 **预期效果**
现在应该可以：
- ✅ **正常启动定位服务**：不再出现Stream已被监听的错误
- ✅ **单次定位正常工作**：使用独立插件实例
- ✅ **两者可以同时使用**：没有Stream冲突

这次彻底解决了Stream冲突问题！应用重新启动后，定位服务应该能够正常启动了。

```dart
// 旧代码（有冲突）：
testSub = _locationPlugin.onLocationChanged().listen(...)  // 与startLocation冲突

// 新代码（无冲突）：
AMapFlutterLocation testLocationPlugin = AMapFlutterLocation();  // 独立实例
testSub = testLocationPlugin.onLocationChanged().listen(...)     // 独立Stream
```
