import 'dart:async';
import 'package:get/get.dart';
import 'package:kissu_app/network/public/sensitive_data_api.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/services/screen_lock_service.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:kissu_app/services/privacy_compliance_manager.dart';
import 'package:kissu_app/utils/debug_util.dart';

/// 敏感数据上报服务
/// 负责监听各种系统事件并上报敏感数据
class SensitiveDataService extends GetxService {
  static SensitiveDataService get instance => Get.find<SensitiveDataService>();
  
  final SensitiveDataApi _api = SensitiveDataApi();
  final NetworkInfo _networkInfo = NetworkInfo();
  
  @override
  void onInit() {
    super.onInit();
    // 🔒 隐私合规：不在服务初始化时自动启动监听
    // 等待隐私政策同意后再启动监听
    // _initializeService(); // 移除自动初始化
  }
  
  @override
  void onClose() {
    _dispose();
    super.onClose();
  }
  
  /// 初始化服务（隐私合规版本）
  /// 只有在用户同意隐私政策后才调用此方法
  void startMonitoring() {
    if (!_shouldReport()) {
      // 增强日志：输出详细的检查结果
      final canCollect = _canCollectSensitiveData();
      final isLoggedIn = UserManager.isLoggedIn;
      final hasToken = UserManager.userToken != null;
      DebugUtil.warning('无法启动敏感数据监听 - 隐私合规检查: $canCollect, 已登录: $isLoggedIn, 有Token: $hasToken');
      return;
    }
    
    // 网络/充电上报改由原生保活服务处理，Flutter 侧不再监听这两类广播
    
    // 启动锁屏/解锁事件监听（在隐私合规且已登录后）
    try {
      if (!Get.isRegistered<ScreenLockService>()) {
        Get.put(ScreenLockService());
      }
      ScreenLockService.instance.startListening();
      DebugUtil.success('锁屏/解锁事件监听已启动');
    } catch (e) {
      DebugUtil.error('启动锁屏/解锁监听失败: $e');
    }
    DebugUtil.success('敏感数据监听已启动（用户已同意隐私政策）');
  }
  
  /// 上报APP打开事件
  Future<void> reportAppOpen() async {
    if (!_shouldReport()) return;
    
    try {
      final result = await _api.reportAppOpen();
      if (result.isSuccess) {
        DebugUtil.success('敏感数据上报成功: APP打开');
      } else {
        DebugUtil.error('敏感数据上报失败: APP打开 - ${result.msg}');
      }
    } catch (e) {
      DebugUtil.error('敏感数据上报异常: APP打开 - $e');
    }
  }
  
  /// 上报定位打开事件
  Future<void> reportLocationOpen() async {
    if (!_shouldReport()) return;
    
    try {
      final result = await _api.reportLocationOpen();
      if (result.isSuccess) {
        DebugUtil.success('敏感数据上报成功: 定位打开');
      } else {
        DebugUtil.error('敏感数据上报失败: 定位打开 - ${result.msg}');
      }
    } catch (e) {
      DebugUtil.error('敏感数据上报异常: 定位打开 - $e');
    }
  }
  
  /// 上报定位关闭事件
  Future<void> reportLocationClose() async {
    if (!_shouldReport()) return;
    
    try {
      final result = await _api.reportLocationClose();
      if (result.isSuccess) {
        DebugUtil.success('敏感数据上报成功: 定位关闭');
      } else {
        DebugUtil.error('敏感数据上报失败: 定位关闭 - ${result.msg}');
      }
    } catch (e) {
      DebugUtil.error('敏感数据上报异常: 定位关闭 - $e');
    }
  }
  
  /// 上报更换无线网络事件
  Future<void> _reportWifiChange(String networkName) async {
    if (!_shouldReport()) return;
    
    try {
      final result = await _api.reportWifiChange(networkName: networkName);
      if (result.isSuccess) {
        DebugUtil.success('敏感数据上报成功: 更换无线网络 - $networkName');
      } else {
        DebugUtil.error('敏感数据上报失败: 更换无线网络 - ${result.msg}');
      }
    } catch (e) {
      DebugUtil.error('敏感数据上报异常: 更换无线网络 - $e');
    }
  }
  
  /// 上报更换移动网络事件
  Future<void> _reportMobileNetworkChange() async {
    if (!_shouldReport()) return;
    
    try {
      final result = await _api.reportMobileNetworkChange();
      if (result.isSuccess) {
        DebugUtil.success('敏感数据上报成功: 更换移动网络');
      } else {
        DebugUtil.error('敏感数据上报失败: 更换移动网络 - ${result.msg}');
      }
    } catch (e) {
      DebugUtil.error('敏感数据上报异常: 更换移动网络 - $e');
    }
  }
  
  /// 上报开始充电事件
  Future<void> _reportChargingStart(int power) async {
    if (!_shouldReport()) return;
    
    try {
      final result = await _api.reportChargingStart(power: power);
      if (result.isSuccess) {
        DebugUtil.success('敏感数据上报成功: 开始充电 - 电量$power%');
      } else {
        DebugUtil.error('敏感数据上报失败: 开始充电 - ${result.msg}');
      }
    } catch (e) {
      DebugUtil.error('敏感数据上报异常: 开始充电 - $e');
    }
  }
  
  /// 上报结束充电事件
  Future<void> _reportChargingEnd(int power) async {
    if (!_shouldReport()) return;
    
    try {
      final result = await _api.reportChargingEnd(power: power);
      if (result.isSuccess) {
        DebugUtil.success('敏感数据上报成功: 结束充电 - 电量$power%');
      } else {
        DebugUtil.error('敏感数据上报失败: 结束充电 - ${result.msg}');
      }
    } catch (e) {
      DebugUtil.error('敏感数据上报异常: 结束充电 - $e');
    }
  }
  
  /// 上报手机解锁事件
  Future<void> reportScreenUnlock({int? timestampSeconds}) async {
    if (!_shouldReport()) return;
    
    try {
      final result = await _api.reportScreenUnlock(timestampSeconds: timestampSeconds);
      if (result.isSuccess) {
        DebugUtil.success('敏感数据上报成功: 手机解锁');
      } else {
        DebugUtil.error('敏感数据上报失败: 手机解锁 - ${result.msg}');
      }
    } catch (e) {
      DebugUtil.error('敏感数据上报异常: 手机解锁 - $e');
    }
  }
  
  /// 上报手机锁屏事件
  Future<void> reportScreenLock({int? timestampSeconds}) async {
    if (!_shouldReport()) return;
    
    try {
      final result = await _api.reportScreenLock(timestampSeconds: timestampSeconds);
      if (result.isSuccess) {
        DebugUtil.success('敏感数据上报成功: 手机锁屏');
      } else {
        DebugUtil.error('敏感数据上报失败: 手机锁屏 - ${result.msg}');
      }
    } catch (e) {
      DebugUtil.error('敏感数据上报异常: 手机锁屏 - $e');
    }
  }
  
  /// 上报开启消息通知事件
  Future<void> reportNotificationEnabled() async {
    if (!_shouldReport()) return;
    
    try {
      final result = await _api.reportNotificationEnabled();
      if (result.isSuccess) {
        DebugUtil.success('敏感数据上报成功: 开启消息通知');
      } else {
        DebugUtil.error('敏感数据上报失败: 开启消息通知 - ${result.msg}');
      }
    } catch (e) {
      DebugUtil.error('敏感数据上报异常: 开启消息通知 - $e');
    }
  }
  
  /// 上报关闭消息通知事件
  Future<void> reportNotificationDisabled() async {
    if (!_shouldReport()) return;
    
    try {
      final result = await _api.reportNotificationDisabled();
      if (result.isSuccess) {
        DebugUtil.success('敏感数据上报成功: 关闭消息通知');
      } else {
        DebugUtil.error('敏感数据上报失败: 关闭消息通知 - ${result.msg}');
      }
    } catch (e) {
      DebugUtil.error('敏感数据上报异常: 关闭消息通知 - $e');
    }
  }
  
  /// 检查是否应该上报（隐私合规 + 有token且已登录）
  bool _shouldReport() {
    // 首先检查隐私合规状态
    if (!_canCollectSensitiveData()) {
      return false;
    }
    
    // 然后检查用户登录状态
    return UserManager.isLoggedIn && UserManager.userToken != null;
  }
  
  /// 检查是否可以收集敏感数据
  bool _canCollectSensitiveData() {
    try {
      if (Get.isRegistered<PrivacyComplianceManager>()) {
        final privacyManager = Get.find<PrivacyComplianceManager>();
        final canCollect = privacyManager.canCollectSensitiveData;
        
        // 增强日志：输出详细的隐私合规状态
        if (!canCollect) {
          DebugUtil.warning('隐私合规检查失败 - isPrivacyAgreed: ${privacyManager.isPrivacyAgreed}, '
              'isSdkInitialized: ${privacyManager.isSdkInitialized}, '
              'isInitializing: ${privacyManager.isInitializing}');
        }
        
        return canCollect;
      } else {
        DebugUtil.error('PrivacyComplianceManager 未注册到 GetX');
      }
    } catch (e) {
      DebugUtil.error('检查隐私合规状态失败: $e');
    }
    // 如果无法检查隐私状态，默认不允许收集
    return false;
  }
  
  /// 手动上报网络更换事件（用于测试）
  Future<void> manualReportNetworkChange(String networkName) async {
    // 如果传入的是'wifi'，尝试获取实际的WiFi SSID
    if (networkName == 'wifi') {
      try {
        final wifiName = await _networkInfo.getWifiName();
        networkName = wifiName ?? 'wifi_unknown';
      } catch (e) {
        DebugUtil.error('获取WiFi SSID失败: $e');
        networkName = 'wifi_unknown';
      }
      await _reportWifiChange(networkName);
    } else if (networkName == 'mobile') {
      await _reportMobileNetworkChange();
    }
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
      'shouldReport': _shouldReport(),
      'networkHandledByNative': true,
      'chargingHandledByNative': true,
    };
  }
  
  /// 清理资源
  void _dispose() {
  }
}
