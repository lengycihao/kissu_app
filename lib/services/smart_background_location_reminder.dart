import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:kissu_app/services/simple_location_service.dart';
import 'package:kissu_app/services/app_lifecycle_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';

/// 智能后台定位权限提醒服务
class SmartBackgroundLocationReminder extends GetxService {
  static SmartBackgroundLocationReminder get instance => Get.find<SmartBackgroundLocationReminder>();
  
  // 提醒状态管理
  final RxBool _isReminderEnabled = true.obs;
  final RxInt _reminderCount = 0.obs;
  final Rxn<DateTime> _lastReminderTime = Rxn<DateTime>();
  final Rxn<DateTime> _lastAppBackgroundTime = Rxn<DateTime>();
  
  // 智能提醒配置
  static const int _maxReminderCount = 3; // 最多提醒3次
  static const Duration _reminderCooldown = Duration(hours: 6); // 提醒冷却时间6小时
  static const Duration _backgroundTimeThreshold = Duration(minutes: 2); // 后台时间阈值2分钟
  static const Duration _reminderDelay = Duration(seconds: 2); // 回到前台后延迟5秒提醒
  
  // 存储键名
  static const String _keyReminderEnabled = 'smart_background_reminder_enabled';
  static const String _keyReminderCount = 'smart_background_reminder_count';
  static const String _keyLastReminderTime = 'smart_background_reminder_last_time';
  static const String _keyUserDismissed = 'smart_background_reminder_user_dismissed';
  
  Timer? _reminderTimer;
  StreamSubscription? _appLifecycleSubscription;
  
  @override
  void onInit() {
    super.onInit();
    _loadReminderSettings();
    _setupAppLifecycleListener();
  }
  
  @override
  void onClose() {
    _reminderTimer?.cancel();
    _appLifecycleSubscription?.cancel();
    super.onClose();
  }
  
  /// 加载提醒设置
  void _loadReminderSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isReminderEnabled.value = prefs.getBool(_keyReminderEnabled) ?? true;
      _reminderCount.value = prefs.getInt(_keyReminderCount) ?? 0;
      
      final lastReminderTimeStr = prefs.getString(_keyLastReminderTime);
      if (lastReminderTimeStr != null) {
        _lastReminderTime.value = DateTime.parse(lastReminderTimeStr);
      }
      
      logDebug('📱 智能提醒设置已加载: 启用=${_isReminderEnabled.value}, 次数=${_reminderCount.value}');
    } catch (e) {
      logError('❌ 加载提醒设置失败: $e');
    }
  }
  
  /// 保存提醒设置
  void _saveReminderSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyReminderEnabled, _isReminderEnabled.value);
      await prefs.setInt(_keyReminderCount, _reminderCount.value);
      
      if (_lastReminderTime.value != null) {
        await prefs.setString(_keyLastReminderTime, _lastReminderTime.value!.toIso8601String());
      }
      
      logDebug('📱 智能提醒设置已保存');
    } catch (e) {
      logError('❌ 保存提醒设置失败: $e');
    }
  }
  
  /// 设置应用生命周期监听
  void _setupAppLifecycleListener() {
    try {
      final appLifecycleService = AppLifecycleService.instance;
      
      // 监听应用状态变化
      _appLifecycleSubscription = appLifecycleService.appState.listen((state) {
        _handleAppLifecycleChange(state);
      });
      
      logDebug('📱 智能提醒应用生命周期监听已设置');
    } catch (e) {
      logError('❌ 设置应用生命周期监听失败: $e');
    }
  }
  
  /// 处理应用生命周期变化
  void _handleAppLifecycleChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _onAppEnteredBackground();
        break;
      case AppLifecycleState.resumed:
        _onAppReturnedToForeground();
        break;
      default:
        break;
    }
  }
  
  /// 应用进入后台
  void _onAppEnteredBackground() {
    // 只在第一次进入后台时记录时间，避免重复更新
    if (_lastAppBackgroundTime.value == null) {
      _lastAppBackgroundTime.value = DateTime.now();
      logDebug('📱 应用进入后台，记录时间: ${_lastAppBackgroundTime.value}');
    } else {
      logDebug('📱 应用已在后台，不重复记录时间（当前记录: ${_lastAppBackgroundTime.value}）');
    }
  }
  
  /// 应用返回前台
  void _onAppReturnedToForeground() {
    logDebug('📱 应用返回前台，检查是否需要提醒后台定位权限');
    
    // 延迟检查，让应用完全恢复
    _reminderTimer?.cancel();
    _reminderTimer = Timer(_reminderDelay, () {
      _checkAndShowBackgroundLocationReminder();
      // 检查完成后清空后台时间，为下次进入后台做准备
      _lastAppBackgroundTime.value = null;
      logDebug('📱 已清空后台时间记录，为下次后台检测做准备');
    });
  }
  
  /// 检查并显示后台定位权限提醒
  Future<void> _checkAndShowBackgroundLocationReminder() async {
    try {
      // 1. 检查基础条件
      if (!_shouldShowReminder()) {
        logInfo('📱 不满足提醒条件，跳过');
        return;
      }
      
      // 2. 检查后台时间是否足够长
      if (!_hasBeenInBackgroundLongEnough()) {
        logInfo('📱 后台时间不足，跳过提醒');
        return;
      }
      
      // 3. 检查定位服务状态
      if (!_isLocationServiceActive()) {
        logInfo('📱 定位服务未激活，跳过提醒');
        return;
      }
      
      // 4. 检查后台定位权限状态
      final backgroundPermissionStatus = await _checkBackgroundLocationPermission();
      if (backgroundPermissionStatus == BackgroundLocationPermissionStatus.granted) {
        logInfo('📱 后台定位权限已授予，跳过提醒');
        return;
      }
      
      // 5. 显示智能提醒
      _showSmartBackgroundLocationReminder(backgroundPermissionStatus);
      
    } catch (e) {
      logError('❌ 检查后台定位权限提醒失败: $e');
    }
  }
  
  /// 检查是否应该显示提醒
  bool _shouldShowReminder() {
    // 检查提醒是否启用
    if (!_isReminderEnabled.value) {
      return false;
    }
    
    // 检查提醒次数限制
    if (_reminderCount.value >= _maxReminderCount) {
      logInfo('📱 已达到最大提醒次数限制: ${_reminderCount.value}');
      return false;
    }
    
    // 检查冷却时间
    if (_lastReminderTime.value != null) {
      final timeSinceLastReminder = DateTime.now().difference(_lastReminderTime.value!);
      if (timeSinceLastReminder < _reminderCooldown) {
        logInfo('📱 提醒冷却中，剩余时间: ${_reminderCooldown - timeSinceLastReminder}');
        return false;
      }
    }
    
    return true;
  }
  
  
  /// 检查是否在后台足够长时间
  bool _hasBeenInBackgroundLongEnough() {
    if (_lastAppBackgroundTime.value == null) {
      logDebug('📱 后台时间检查: _lastAppBackgroundTime 为 null');
      return false;
    }
    
    final backgroundDuration = DateTime.now().difference(_lastAppBackgroundTime.value!);
    final thresholdSeconds = _backgroundTimeThreshold.inSeconds;
    final actualSeconds = backgroundDuration.inSeconds;
    
    logDebug('📱 后台时间检查:');
    logDebug('   - 进入后台时间: ${_lastAppBackgroundTime.value}');
    logDebug('   - 当前时间: ${DateTime.now()}');
    logDebug('   - 后台持续时长: ${actualSeconds}秒');
    logDebug('   - 要求阈值: ${thresholdSeconds}秒 (${_backgroundTimeThreshold.inMinutes}分钟)');
    logDebug('   - 是否满足: ${backgroundDuration >= _backgroundTimeThreshold}');
    
    return backgroundDuration >= _backgroundTimeThreshold;
  }
  
  /// 检查定位服务是否激活
  bool _isLocationServiceActive() {
    try {
      final locationService = SimpleLocationService.instance;
      return locationService.isLocationEnabled.value;
    } catch (e) {
      logError('❌ 检查定位服务状态失败: $e');
      return false;
    }
  }
  
  /// 检查后台定位权限状态
  Future<BackgroundLocationPermissionStatus> _checkBackgroundLocationPermission() async {
    try {
      final status = await Permission.locationAlways.status;
      
      if (status.isGranted) {
        return BackgroundLocationPermissionStatus.granted;
      } else if (status.isPermanentlyDenied) {
        return BackgroundLocationPermissionStatus.permanentlyDenied;
      } else {
        return BackgroundLocationPermissionStatus.denied;
      }
    } catch (e) {
      logError('❌ 检查后台定位权限失败: $e');
      return BackgroundLocationPermissionStatus.denied;
    }
  }
  
  /// 显示智能后台定位权限提醒
  void _showSmartBackgroundLocationReminder(BackgroundLocationPermissionStatus permissionStatus) {
    if (Get.context == null) {
      logError('❌ Context不可用，无法显示提醒');
      return;
    }
    
    // 更新提醒统计
    _reminderCount.value++;
    _lastReminderTime.value = DateTime.now();
    _saveReminderSettings();
    
    logDebug('📱 显示智能后台定位权限提醒 (第${_reminderCount.value}次)');
    
    // 根据权限状态显示不同的提醒内容
    final reminderContent = _getReminderContent(permissionStatus);
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        child: Container(
          padding: EdgeInsets.all(24),
          constraints: BoxConstraints(maxWidth: 340),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey[50]!],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部图标和标题
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange[300]!, Colors.orange[500]!],
                  ),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              SizedBox(height: 20),
              
              // 标题
              Text(
                '位置权限提醒',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              
              // 主要消息
              Text(
                reminderContent.message,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              
             
               
              // 按钮区域
              Column(
                children: [
                  // 主要操作按钮
                  Container(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        Get.back();
                        await _handleReminderAction(permissionStatus);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[500],
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: Colors.orange.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 20),
                          SizedBox(width: 8),
                          Text(
                            reminderContent.actionText,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // 次要操作按钮
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          child: TextButton(
                            onPressed: () => Get.back(),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: Colors.grey[300]!, width: 1),
                              ),
                            ),
                            child: Text(
                              '稍后再说',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 44,
                          child: TextButton(
                            onPressed: () {
                              _handleUserDismissed();
                              Get.back();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: Colors.grey[300]!, width: 1),
                              ),
                            ),
                            child: Text(
                              '不再提醒',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
  
  /// 获取提醒内容
  ReminderContent _getReminderContent(BackgroundLocationPermissionStatus status) {
    switch (status) {
      case BackgroundLocationPermissionStatus.denied:
        return ReminderContent(
          message: '为了让您的足迹记录更完整，建议开启后台定位权限，即使切换到其他应用也能继续记录轨迹。',
          actionText: '立即开启',
        );
      case BackgroundLocationPermissionStatus.permanentlyDenied:
        return ReminderContent(
          message: '后台定位权限需要在系统设置中手动开启，开启后您的足迹轨迹将更加完整和准确。',
          actionText: '打开设置',
        );
      case BackgroundLocationPermissionStatus.granted:
        return ReminderContent(
          message: '后台定位权限已开启，您的足迹轨迹将得到完整记录。',
          actionText: '确定',
        );
    }
  }
  
  /// 处理用户永久关闭提醒
  void _handleUserDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUserDismissed, true);
    _isReminderEnabled.value = false;
    logDebug('📱 用户选择不再提醒，已永久关闭智能提醒');
  }
  
  /// 处理提醒操作
  Future<void> _handleReminderAction(BackgroundLocationPermissionStatus status) async {
    switch (status) {
      case BackgroundLocationPermissionStatus.denied:
        await _requestBackgroundLocationPermission();
        break;
      case BackgroundLocationPermissionStatus.permanentlyDenied:
        await _openAppSettings();
        break;
      case BackgroundLocationPermissionStatus.granted:
        // 权限已授予，无需操作
        break;
    }
  }
  
  /// 请求后台定位权限
  Future<void> _requestBackgroundLocationPermission() async {
    try {
      logDebug('📱 用户选择开启后台定位权限');
      
      final locationService = SimpleLocationService.instance;
      final success = await locationService.requestBackgroundLocationPermission();
      
      if (success) {
        CustomToast.show(Get.context!, '后台定位权限开启成功！');
        // 权限获取成功，可以减少后续提醒频率
        _optimizeReminderFrequency();
      } else {
        // 不显示额外的错误提示，因为 SimpleLocationService 已经显示了具体的错误信息
        logDebug('📱 后台定位权限请求失败');
      }
    } catch (e) {
      logError('❌ 请求后台定位权限失败: $e');
      CustomToast.show(Get.context!, '权限请求失败，请稍后重试');
    }
  }
  
  /// 打开应用设置
  Future<void> _openAppSettings() async {
    try {
      logDebug('📱 用户选择打开应用设置');
      await openAppSettings();
    } catch (e) {
      logError('❌ 打开应用设置失败: $e');
      CustomToast.show(Get.context!, '无法打开设置，请手动前往系统设置');
    }
  }
  
  /// 优化提醒频率（权限获取成功后）
  void _optimizeReminderFrequency() {
    // 重置提醒次数，但增加冷却时间
    _reminderCount.value = 0;
    _lastReminderTime.value = DateTime.now().add(Duration(days: 1)); // 24小时内不再提醒
    _saveReminderSettings();
    
    logDebug('📱 后台权限获取成功，已优化提醒频率');
  }
  
  /// 手动触发智能提醒检查（用于测试或特殊场景）
  Future<void> manualTriggerReminder() async {
    logDebug('📱 手动触发智能提醒检查');
    await _checkAndShowBackgroundLocationReminder();
  }
  
  /// 直接显示弹窗（用于测试新UI效果）
  void showTestDialog() {
    logDebug('📱 显示测试弹窗');
    _showSmartBackgroundLocationReminder(BackgroundLocationPermissionStatus.denied);
  }
  
  /// 重置提醒设置（用于测试或重新启用）
  void resetReminderSettings() async {
    _reminderCount.value = 0;
    _lastReminderTime.value = null;
    _isReminderEnabled.value = true;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyReminderCount);
    await prefs.remove(_keyLastReminderTime);
    await prefs.remove(_keyUserDismissed);
    await prefs.setBool(_keyReminderEnabled, true);
    
    logDebug('📱 智能提醒设置已重置');
  }
  
  /// 获取提醒统计信息
  Map<String, dynamic> getReminderStats() {
    return {
      'enabled': _isReminderEnabled.value,
      'reminderCount': _reminderCount.value,
      'maxReminderCount': _maxReminderCount,
      'lastReminderTime': _lastReminderTime.value?.toIso8601String(),
      'cooldownHours': _reminderCooldown.inHours,
    };
  }
}

/// 后台定位权限状态枚举
enum BackgroundLocationPermissionStatus {
  granted,      // 已授予
  denied,       // 被拒绝
  permanentlyDenied, // 永久拒绝
}

/// 提醒内容数据类
class ReminderContent {
  final String message;
  final String actionText;
  
  ReminderContent({
    required this.message,
    required this.actionText,
  });
}
