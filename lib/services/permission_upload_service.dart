import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kissu_app/network/public/lock_permission_api.dart';
import 'package:kissu_app/services/permission_service.dart';
import 'package:kissu_app/services/lock_screen_overlay_service.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';

/// 权限状态上传服务
/// - 首页启动时上传一次，成功后不再重复上传
/// - 用户在权限设置页面点击保存后，标记为"需要重传"，下次调用时重传
/// - 权限来源：定位(多处触发)、通知、app使用记录(多处触发)、其他均在权限设置页触发
class PermissionUploadService extends GetxService {
  static PermissionUploadService get instance =>
      Get.find<PermissionUploadService>();

  static const _kNeedReuploadKey = 'permission_need_reupload';

  /// 内存中的"本次已上传"标记——进程重启自动清零，无需 SharedPreferences
  bool _uploadedThisSession = false;

  final _api = LockPermissionApi();
  final _permissionService = PermissionService();

  /// 首页启动时调用：只有从未上传过（或被标记需要重传）才执行上传
  Future<void> uploadIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final needReupload = prefs.getBool(_kNeedReuploadKey) ?? false;

      if (_uploadedThisSession && !needReupload) {
        logDebug('⏭️ 权限状态本次已上传，跳过', tag: 'PermissionUpload');
        return;
      }

      await _doUpload();

      _uploadedThisSession = true;
      await prefs.setBool(_kNeedReuploadKey, false);
    } catch (e) {
      logError('权限状态上传失败: $e', tag: 'PermissionUpload', error: e);
    }
  }

  /// 重新登录时调用：重置会话标记，确保重新上报权限
  void resetSession() {
    _uploadedThisSession = false;
    logDebug('🔄 权限上传会话标记已重置（重新登录）', tag: 'PermissionUpload');
  }

  /// 权限设置页面保存后调用：标记需要重传，并立即触发一次上传
  Future<void> markDirtyAndUpload() async {
    try {
      _uploadedThisSession = false; // 重置会话标记，允许重新上传
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kNeedReuploadKey, true);
      await uploadIfNeeded();
    } catch (e) {
      logError('权限状态标记重传失败: $e', tag: 'PermissionUpload', error: e);
    }
  }

  /// 执行实际上传逻辑，收集所有权限状态
  Future<void> _doUpload() async {
    logDebug('📤 开始上传权限状态...', tag: 'PermissionUpload');

    final permissions = await _permissionService.checkAllPermissions();

    // 定位权限：0=否 1=有基础定位 2=始终允许
    final hasLocation = permissions[PermissionType.location] ?? false;
    final hasLocationAlways = permissions[PermissionType.locationAlways] ?? false;
    final isOpenLocation = hasLocationAlways ? 2 : (hasLocation ? 1 : 0);

    // 通知权限
    final isOpenNotice = (permissions[PermissionType.notification] ?? false) ? 1 : 0;

    // app使用记录权限
    final isOpenScreenUse = (permissions[PermissionType.usage] ?? false) ? 1 : 0;

    // 悬浮窗权限（对应 is_open_suspend_window）
    final overlayGranted = await LockScreenOverlayService.checkOverlayPermission();
    final isOpenSuspendWindow = overlayGranted ? 1 : 0;

    // 以下 3 项为系统权限指引（无法实时检查，从 SharedPreferences 读已完成标记）
    final prefs = await SharedPreferences.getInstance();
    final isOpenBackRun = (prefs.getBool('system_permission_guide_prevent_sleep_completed') ?? false) ? 1 : 0;
    final isOpenPreventSleep = isOpenBackRun; // 防休眠和防止程序休眠对应同一指引
    final isOpenSelfStarting = (prefs.getBool('system_permission_guide_background_run_completed') ?? false) ? 1 : 0;
    final isOpenProgramLock = (prefs.getBool('system_permission_guide_lock_background_completed') ?? false) ? 1 : 0;

    final result = await _api.setPermission(
      isOpenLocation: isOpenLocation,
      isOpenNoticeRemind: isOpenNotice,
      isOpenScreenUse: isOpenScreenUse,
      isOpenBackRun: isOpenBackRun,
      isOpenPreventProgramSleep: isOpenPreventSleep,
      isOpenSelfStarting: isOpenSelfStarting,
      isOpenProgramLock: isOpenProgramLock,
      isOpenSuspendWindow: isOpenSuspendWindow,
    );

    if (result.isSuccess) {
      logDebug('✅ 权限状态上传成功', tag: 'PermissionUpload');
    } else {
      logWarning('⚠️ 权限状态上传失败: ${result.msg}', tag: 'PermissionUpload');
      // 失败则保持 needReupload = true，下次重试
      await prefs.setBool(_kNeedReuploadKey, true);
    }
  }

}
