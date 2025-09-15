import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

/// 权限状态管理服务
/// 用于跟踪不同页面的权限请求状态
class PermissionStateService extends GetxService {
  static PermissionStateService get instance => Get.find<PermissionStateService>();
  
  /// 轨迹页面是否已经请求过权限（在当前app生命周期内）
  final RxBool trackPagePermissionRequested = false.obs;
  
  /// 轨迹页面权限是否被拒绝（在当前app生命周期内）
  final RxBool trackPagePermissionDenied = false.obs;
  
  /// 定位页面权限请求状态（每次进入都重置）
  final RxBool locationPagePermissionRequested = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    _loadPermissionStates();
  }
  
  /// 加载权限状态
  Future<void> _loadPermissionStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 检查app是否被重启（通过检查启动时间戳）
      final lastStartTime = prefs.getInt('app_last_start_time') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final appRestarted = (currentTime - lastStartTime) > 30000; // 30秒内认为是同一生命周期
      
      if (appRestarted) {
        // App被重启，重置轨迹页面权限状态
        trackPagePermissionRequested.value = false;
        trackPagePermissionDenied.value = false;
        print('🔄 App重启，重置轨迹页面权限状态');
      } else {
        // 同一生命周期，保持状态
        trackPagePermissionRequested.value = prefs.getBool('track_page_permission_requested') ?? false;
        trackPagePermissionDenied.value = prefs.getBool('track_page_permission_denied') ?? false;
        print('📱 同一生命周期，保持权限状态: requested=${trackPagePermissionRequested.value}, denied=${trackPagePermissionDenied.value}');
      }
      
      // 更新启动时间戳
      await prefs.setInt('app_last_start_time', currentTime);
      
    } catch (e) {
      print('❌ 加载权限状态失败: $e');
    }
  }
  
  /// 标记轨迹页面已请求权限
  Future<void> markTrackPagePermissionRequested() async {
    trackPagePermissionRequested.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('track_page_permission_requested', true);
      print('✅ 标记轨迹页面已请求权限');
    } catch (e) {
      print('❌ 保存轨迹页面权限请求状态失败: $e');
    }
  }
  
  /// 标记轨迹页面权限被拒绝
  Future<void> markTrackPagePermissionDenied() async {
    trackPagePermissionDenied.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('track_page_permission_denied', true);
      print('❌ 标记轨迹页面权限被拒绝');
    } catch (e) {
      print('❌ 保存轨迹页面权限拒绝状态失败: $e');
    }
  }
  
  /// 重置轨迹页面权限状态（app重启时调用）
  Future<void> resetTrackPagePermissionState() async {
    trackPagePermissionRequested.value = false;
    trackPagePermissionDenied.value = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('track_page_permission_requested');
      await prefs.remove('track_page_permission_denied');
      print('🔄 重置轨迹页面权限状态');
    } catch (e) {
      print('❌ 重置轨迹页面权限状态失败: $e');
    }
  }
  
  /// 检查轨迹页面是否应该请求权限
  bool shouldRequestTrackPagePermission() {
    // 如果已经请求过且被拒绝，则不再请求
    if (trackPagePermissionRequested.value && trackPagePermissionDenied.value) {
      print('🚫 轨迹页面权限已被拒绝，不再请求');
      return false;
    }
    
    // 如果还没有请求过，可以请求
    if (!trackPagePermissionRequested.value) {
      print('✅ 轨迹页面可以请求权限');
      return true;
    }
    
    // 如果请求过但没有被拒绝，说明权限已获取，不需要再请求
    print('✅ 轨迹页面权限已获取，无需再请求');
    return false;
  }
  
  /// 检查定位页面是否应该请求权限（每次进入都请求）
  bool shouldRequestLocationPagePermission() {
    // 定位页面每次进入都请求权限
    print('✅ 定位页面每次进入都请求权限');
    return true;
  }
  
  /// 获取当前定位权限状态
  Future<PermissionStatus> getCurrentLocationPermissionStatus() async {
    return await Permission.location.status;
  }
  
  /// 检查是否有定位权限
  Future<bool> hasLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }
  
  /// 检查权限是否被永久拒绝
  Future<bool> isLocationPermissionPermanentlyDenied() async {
    final status = await Permission.location.status;
    return status.isPermanentlyDenied;
  }
}
