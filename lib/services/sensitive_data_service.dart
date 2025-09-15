import 'dart:async';
import 'package:get/get.dart';
import 'package:kissu_app/network/public/sensitive_data_api.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';

/// 敏感数据上报服务
/// 负责监听各种系统事件并上报敏感数据
class SensitiveDataService extends GetxService {
  static SensitiveDataService get instance => Get.find<SensitiveDataService>();
  
  final SensitiveDataApi _api = SensitiveDataApi();
  final Connectivity _connectivity = Connectivity();
  final Battery _battery = Battery();
  final NetworkInfo _networkInfo = NetworkInfo();
  
  // 网络状态监听
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  // 电池状态监听
  StreamSubscription<BatteryState>? _batterySubscription;
  
  // 当前网络状态
  String _currentNetworkName = 'unknown';
  
  // 当前电池状态
  BatteryState _currentBatteryState = BatteryState.unknown;
  
  // 是否正在充电
  bool _isCharging = false;
  
  @override
  void onInit() {
    super.onInit();
    _initializeService();
  }
  
  @override
  void onClose() {
    _dispose();
    super.onClose();
  }
  
  /// 初始化服务
  void _initializeService() {
    _startNetworkMonitoring();
    _startBatteryMonitoring();
  }
  
  /// 开始网络状态监听
  void _startNetworkMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _handleNetworkChange(results);
      },
    );
  }
  
  /// 开始电池状态监听
  void _startBatteryMonitoring() {
    _batterySubscription = _battery.onBatteryStateChanged.listen(
      (BatteryState state) {
        _handleBatteryStateChange(state);
      },
    );
  }
  
  /// 处理网络状态变化
  void _handleNetworkChange(List<ConnectivityResult> results) async {
    if (results.isEmpty) return;
    
    final result = results.first;
    String networkName = 'unknown';
    
    switch (result) {
      case ConnectivityResult.wifi:
        // 获取WiFi SSID
        try {
          final wifiName = await _networkInfo.getWifiName();
          networkName = wifiName ?? 'wifi_unknown';
        } catch (e) {
          print('获取WiFi SSID失败: $e');
          networkName = '未知wifi';
        }
        break;
      case ConnectivityResult.mobile:
        networkName = 'mobile';
        break;
      case ConnectivityResult.ethernet:
        networkName = 'ethernet';
        break;
      case ConnectivityResult.bluetooth:
        networkName = 'bluetooth';
        break;
      case ConnectivityResult.vpn:
        networkName = 'vpn';
        break;
      case ConnectivityResult.other:
        networkName = 'other';
        break;
      case ConnectivityResult.none:
        networkName = 'none';
        break;
    }
    
    // 如果网络名称发生变化，上报网络更换事件
    if (_currentNetworkName != networkName) {
      _currentNetworkName = networkName;
      await _reportNetworkChange(networkName);
    }
  }
  
  /// 处理电池状态变化
  void _handleBatteryStateChange(BatteryState state) async {
    final wasCharging = _isCharging;
    _isCharging = state == BatteryState.charging;
    _currentBatteryState = state;
    
    // 获取当前电量
    final batteryLevel = await _battery.batteryLevel;
    
    // 如果充电状态发生变化，上报充电事件
    if (wasCharging != _isCharging) {
      if (_isCharging) {
        await _reportChargingStart(batteryLevel);
      } else {
        await _reportChargingEnd(batteryLevel);
      }
    }
  }
  
  /// 上报APP打开事件
  Future<void> reportAppOpen() async {
    if (!_shouldReport()) return;
    
    try {
      final result = await _api.reportAppOpen();
      if (result.isSuccess) {
        print('✅ 敏感数据上报成功: APP打开');
      } else {
        print('❌ 敏感数据上报失败: APP打开 - ${result.msg}');
      }
    } catch (e) {
      print('❌ 敏感数据上报异常: APP打开 - $e');
    }
  }
  
  /// 上报定位打开事件
  Future<void> reportLocationOpen() async {
    if (!_shouldReport()) return;
    
    try {
      final result = await _api.reportLocationOpen();
      if (result.isSuccess) {
        print('✅ 敏感数据上报成功: 定位打开');
      } else {
        print('❌ 敏感数据上报失败: 定位打开 - ${result.msg}');
      }
    } catch (e) {
      print('❌ 敏感数据上报异常: 定位打开 - $e');
    }
  }
  
  /// 上报定位关闭事件
  Future<void> reportLocationClose() async {
    if (!_shouldReport()) return;
    
    try {
      final result = await _api.reportLocationClose();
      if (result.isSuccess) {
        print('✅ 敏感数据上报成功: 定位关闭');
      } else {
        print('❌ 敏感数据上报失败: 定位关闭 - ${result.msg}');
      }
    } catch (e) {
      print('❌ 敏感数据上报异常: 定位关闭 - $e');
    }
  }
  
  /// 上报网络更换事件
  Future<void> _reportNetworkChange(String networkName) async {
    if (!_shouldReport()) return;
    
    try {
      final result = await _api.reportNetworkChange(networkName: networkName);
      if (result.isSuccess) {
        print('✅ 敏感数据上报成功: 网络更换 - $networkName');
      } else {
        print('❌ 敏感数据上报失败: 网络更换 - ${result.msg}');
      }
    } catch (e) {
      print('❌ 敏感数据上报异常: 网络更换 - $e');
    }
  }
  
  /// 上报开始充电事件
  Future<void> _reportChargingStart(int power) async {
    if (!_shouldReport()) return;
    
    try {
      final result = await _api.reportChargingStart(power: power);
      if (result.isSuccess) {
        print('✅ 敏感数据上报成功: 开始充电 - 电量$power%');
      } else {
        print('❌ 敏感数据上报失败: 开始充电 - ${result.msg}');
      }
    } catch (e) {
      print('❌ 敏感数据上报异常: 开始充电 - $e');
    }
  }
  
  /// 上报结束充电事件
  Future<void> _reportChargingEnd(int power) async {
    if (!_shouldReport()) return;
    
    try {
      final result = await _api.reportChargingEnd(power: power);
      if (result.isSuccess) {
        print('✅ 敏感数据上报成功: 结束充电 - 电量$power%');
      } else {
        print('❌ 敏感数据上报失败: 结束充电 - ${result.msg}');
      }
    } catch (e) {
      print('❌ 敏感数据上报异常: 结束充电 - $e');
    }
  }
  
  /// 检查是否应该上报（有token且已登录）
  bool _shouldReport() {
    return UserManager.isLoggedIn && UserManager.userToken != null;
  }
  
  /// 手动上报网络更换事件（用于测试）
  Future<void> manualReportNetworkChange(String networkName) async {
    // 如果传入的是'wifi'，尝试获取实际的WiFi SSID
    if (networkName == 'wifi') {
      try {
        final wifiName = await _networkInfo.getWifiName();
        networkName = wifiName ?? 'wifi_unknown';
      } catch (e) {
        print('获取WiFi SSID失败: $e');
        networkName = 'wifi_unknown';
      }
    }
    await _reportNetworkChange(networkName);
  }
  
  /// 手动上报充电事件（用于测试）
  Future<void> manualReportCharging(bool isCharging, int power) async {
    if (isCharging) {
      await _reportChargingStart(power);
    } else {
      await _reportChargingEnd(power);
    }
  }
  
  /// 获取当前服务状态
  Map<String, dynamic> getServiceStatus() {
    return {
      'isInitialized': true,
      'currentNetworkName': _currentNetworkName,
      'currentBatteryState': _currentBatteryState.toString(),
      'isCharging': _isCharging,
      'shouldReport': _shouldReport(),
    };
  }
  
  /// 清理资源
  void _dispose() {
    _connectivitySubscription?.cancel();
    _batterySubscription?.cancel();
  }
}
