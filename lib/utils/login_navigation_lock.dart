import 'package:get/get.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';

/// 登录页导航锁
/// 用于防止登录页重复跳转，解决退出登录和被挤掉时的闪烁问题
class LoginNavigationLock {
  // 标记是否正在导航到登录页
  static bool _isNavigatingToLogin = false;
  
  // 标记是否已经导航到登录页（防止重复导航）
  static bool _hasNavigatedToLogin = false;
  
  // 导航锁的超时时间（秒），超过这个时间后自动重置
  static const int _navigationTimeoutSeconds = 5;

  /// 尝试导航到登录页（带锁保护）
  /// 返回 true 表示成功获取锁并执行导航，false 表示已有其他线程正在导航
  static bool navigateToLoginSafely() {
    // 如果已经在导航中，直接返回
    if (_isNavigatingToLogin) {
      logDebug('⏸️ 正在导航到登录页，跳过重复导航', tag: 'LoginNavLock');
      return false;
    }
    
    // 如果已经导航过，检查是否需要重置（超时后重置）
    if (_hasNavigatedToLogin) {
      logDebug('⏸️ 已经导航到登录页，跳过重复导航', tag: 'LoginNavLock');
      return false;
    }
    
    // 获取锁
    _isNavigatingToLogin = true;
    _hasNavigatedToLogin = true;
    
    logInfo('🔒 获取登录页导航锁，开始导航到登录页', tag: 'LoginNavLock');
    
    try {
      // 检查Get路由是否已经初始化
      if (Get.isRegistered<GetMaterialController>()) {
        Get.offAllNamed(KissuRoutePath.login);
        logDebug('✅ 已成功导航到登录页', tag: 'LoginNavLock');
      } else {
        logWarning('⚠️ Get路由尚未初始化，延迟导航...', tag: 'LoginNavLock');
        // 延迟导航，等待Get路由初始化完成
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_isNavigatingToLogin) {
            try {
              Get.offAllNamed(KissuRoutePath.login);
              logDebug('✅ 延迟导航到登录页成功', tag: 'LoginNavLock');
            } catch (e) {
              logError('❌ 延迟导航失败: $e', tag: 'LoginNavLock', error: e);
              // 导航失败时重置锁，允许重试
              _isNavigatingToLogin = false;
              _hasNavigatedToLogin = false;
            }
          }
        });
      }
      
      // 设置超时重置（防止锁永久持有）
      Future.delayed(Duration(seconds: _navigationTimeoutSeconds), () {
        _isNavigatingToLogin = false;
        logDebug('🔄 登录页导航锁超时重置', tag: 'LoginNavLock');
      });
      
      return true;
    } catch (e) {
      logError('❌ 导航到登录页失败: $e', tag: 'LoginNavLock', error: e);
      // 导航失败时重置锁，允许重试
      _isNavigatingToLogin = false;
      _hasNavigatedToLogin = false;
      return false;
    }
  }
  
  /// 检查是否正在导航到登录页
  static bool get isNavigating => _isNavigatingToLogin;
  
  /// 检查是否已经导航到登录页
  static bool get hasNavigated => _hasNavigatedToLogin;
  
  /// 重置导航状态（登录成功后调用）
  static void reset() {
    _isNavigatingToLogin = false;
    _hasNavigatedToLogin = false;
    logDebug('🔄 登录页导航锁已重置', tag: 'LoginNavLock');
  }
  
  /// 强制重置导航状态（应用启动时调用）
  static void forceReset() {
    _isNavigatingToLogin = false;
    _hasNavigatedToLogin = false;
    logDebug('🔄 登录页导航锁已强制重置', tag: 'LoginNavLock');
  }
}





















