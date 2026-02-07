import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/src/platform/platform.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../routers/kissu_route_path.dart';
import '../../../services/app_usage_auto_report_service.dart';
import '../../../services/permission_service.dart';
import '../../../utils/oktoast_util.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';

/// 系统权限页面控制器
enum SystemPermissionGuideType {
  preventSleep,
  lockInBackground,
  allowBackgroundRun,
  // 新增：权限类型的二级页面
  location,
  notification,
  appUsage,
}

enum SupportedBrand { huawei, oppo, vivo, xiaomi, other }

class SystemPermissionController extends GetxController
    with WidgetsBindingObserver {
  final PermissionService _permissionService = PermissionService();

  // 权限状态响应式变量
  final RxBool isLocationGranted = false.obs;
  final RxBool isLocationAlwaysGranted = false.obs; // “始终允许”定位权限
  final RxBool isNotificationGranted = false.obs;
  final RxBool isBatteryOptimized = false.obs;
  final RxBool isUsageAccessGranted = false.obs;

  // 加载状态
  final RxBool isLoading = false.obs;

  // 指引完成状态持久化 key
  static const _guidePreventSleepKey =
      'system_permission_guide_prevent_sleep_completed';
  static const _guideBackgroundRunKey =
      'system_permission_guide_background_run_completed';
  static const _guideLockBackgroundKey =
      'system_permission_guide_lock_background_completed';

  // 指引完成状态（持久化）
  final RxBool _preventSleepCompleted = false.obs;
  final RxBool _backgroundRunCompleted = false.obs;
  final RxBool _lockBackgroundCompleted = false.obs;

  // 本次进入 App 后是否在指引页点击过“去设置”（仅用于控制 UI）
  final RxBool _preventSleepOpenedThisSession = false.obs;
  final RxBool _backgroundRunOpenedThisSession = false.obs;

  final Rx<SupportedBrand> _currentBrand = SupportedBrand.huawei.obs;
  SupportedBrand get currentBrand => _currentBrand.value;
  bool get isXiaomiDevice => currentBrand == SupportedBrand.xiaomi;

  List<Map<String, dynamic>> get permissionItems {
    final items = List<Map<String, dynamic>>.from(_permissionItems);
    if (isXiaomiDevice) {
      items.removeWhere((item) => item['hideOnXiaomi'] == true);
    }
    return items;
  }

  final List<Map<String, dynamic>> _permissionItems = [
    {
      "icon": "assets/images/kissu_setting_ssdw.webp",
      "title": "开启实时定位",
      "subtitle": "和ta持续分享你的位置",
      "guideType": SystemPermissionGuideType.location,
    },
    {
      "icon": "assets/images/kissu_setting_htyx.webp",
      "title": "允许后台运行",
      "subtitle": "应用后台常驻，确保数据同步",
      "guideType": SystemPermissionGuideType.allowBackgroundRun,
    },
    {
      "icon": "assets/images/kissu_setting_tztx.webp",
      "title": "开启通知提醒",
      "subtitle": "收到ta的实时动态提醒",
      "guideType": SystemPermissionGuideType.notification,
    },
    {
      "icon": "assets/images/kissu_setting_cc.webp",
      "title": "允许获取应用使用权限",
      "subtitle": "和ta分享手机使用报告",
      "guideType": SystemPermissionGuideType.appUsage,
    },
    {
      "icon": "assets/images/kissu_setting_sleep.webp",
      "title": "防止程序休眠",
      "subtitle": "程序休眠会导致数据不准确",
      "guideType": SystemPermissionGuideType.preventSleep,
    },
    {
      "icon": "assets/images/kissu_setting_lock.webp",
      "title": "让程序锁在后台",
      "subtitle": "后台一直运行才能更新数据",
      "guideType": SystemPermissionGuideType.lockInBackground,
      "hideOnXiaomi": true,
    },
  ];

  static const Map<SystemPermissionGuideType, Map<SupportedBrand, String>>
  _guideAssets = {
    SystemPermissionGuideType.preventSleep: {
      SupportedBrand.huawei: 'assets/setting/kissu_sleep_huawei.webp',
      SupportedBrand.oppo: 'assets/setting/kissu_sleep_oppo.webp',
      SupportedBrand.vivo: 'assets/setting/kissu_sleep_vivo.webp',
      SupportedBrand.xiaomi: 'assets/setting/kissu_sleep_xiaomi.webp',
      SupportedBrand.other: 'assets/setting/kissu_sleep_huawei.webp',
    },
    SystemPermissionGuideType.lockInBackground: {
      SupportedBrand.huawei: 'assets/setting/kissu_lock_huawei.webp',
      SupportedBrand.oppo: 'assets/setting/kissu_lock_oppo.webp',
      SupportedBrand.vivo: 'assets/setting/kissu_lock_vivo.webp',
      SupportedBrand.other: 'assets/setting/kissu_lock_huawei.webp',
    },
    SystemPermissionGuideType.allowBackgroundRun: {
      SupportedBrand.huawei: 'assets/setting/kissu_back_huawei.webp',
      SupportedBrand.oppo: 'assets/setting/kissu_back_oppo.webp',
      SupportedBrand.vivo: 'assets/setting/kissu_back_vivo.webp',
      SupportedBrand.xiaomi: 'assets/setting/kissu_back_xiaomi.webp',
      SupportedBrand.other: 'assets/setting/kissu_back_huawei.webp',
    },
    // 新增：开启实时定位（基础定位权限）
    SystemPermissionGuideType.location: {
      SupportedBrand.huawei: 'assets/setting/kissu_location_huawei.webp',
      SupportedBrand.oppo: 'assets/setting/kissu_location_oppo.webp',
      SupportedBrand.vivo: 'assets/setting/kissu_location_vivo.webp',
      SupportedBrand.xiaomi: 'assets/setting/kissu_location_xiaomi.webp',
      SupportedBrand.other: 'assets/setting/kissu_location_huawei.webp',
    },
    // 新增：开启通知提醒
    SystemPermissionGuideType.notification: {
      SupportedBrand.huawei: 'assets/setting/kissu_notice_huawei.webp',
      SupportedBrand.oppo: 'assets/setting/kissu_notice_oppo.webp',
      SupportedBrand.vivo: 'assets/setting/kissu_notice_vivo.webp',
      SupportedBrand.xiaomi: 'assets/setting/kissu_notice_xiaomi.webp',
      SupportedBrand.other: 'assets/setting/kissu_notice_huawei.webp',
    },
    // 新增：允许获取应用使用权限
    SystemPermissionGuideType.appUsage: {
      SupportedBrand.huawei: 'assets/setting/kissu_appuse_huawei.webp',
      SupportedBrand.oppo: 'assets/setting/kissu_appuse_oppo.webp',
      SupportedBrand.vivo: 'assets/setting/kissu_appuse_vivo.webp',
      SupportedBrand.xiaomi: 'assets/setting/kissu_appuse_xiaomi.webp',
      SupportedBrand.other: 'assets/setting/kissu_appuse_huawei.webp',
    },
  };

  @override
  void onInit() {
    super.onInit();
    // 添加应用生命周期监听
    WidgetsBinding.instance.addObserver(this);
    _initDeviceBrand();
    _loadGuideCompletedStatus();
    // 初始化时检查权限状态
    checkAllPermissions();

    // 监听App使用记录权限变化
    ever(isUsageAccessGranted, (bool hasPermission) async {
      if (hasPermission) {
        // 权限已开启，通知自动上报服务检查并启动
        logDebug('检测到App使用记录权限已开启，通知自动上报服务', tag: 'SystemPermission');
        try {
          if (Get.isRegistered<AppUsageAutoReportService>()) {
            final service = Get.find<AppUsageAutoReportService>();
            await service.checkPermissionAndRestartIfNeeded();
            logDebug('✅ 已通知自动上报服务检查权限', tag: 'SystemPermission');
          }
        } catch (e) {
          logError('通知自动上报服务失败: $e', tag: 'SystemPermission', error: e);
        }
      }
    });
  }

  @override
  void onClose() {
    // 移除应用生命周期监听
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  Future<void> _initDeviceBrand() async {
    try {
      if (GetPlatform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final brand = androidInfo.brand.toLowerCase();
        _currentBrand.value = _mapBrand(brand);
        logDebug('检测到设备品牌: $brand', tag: 'SystemPermission');
      } else {
        _currentBrand.value = SupportedBrand.huawei;
      }
    } catch (e) {
      logError('初始化设备品牌失败: $e', tag: 'SystemPermission', error: e);
      _currentBrand.value = SupportedBrand.huawei;
    }
  }

  SupportedBrand _mapBrand(String brand) {
    if (brand.contains('huawei') ||
        brand.contains('honor') ||
        brand.contains('hw')) {
      return SupportedBrand.huawei;
    }
    if (brand.contains('oppo') ||
        brand.contains('oneplus') ||
        brand.contains('realme')) {
      return SupportedBrand.oppo;
    }
    if (brand.contains('vivo') || brand.contains('iqoo')) {
      return SupportedBrand.vivo;
    }
    if (brand.contains('xiaomi') ||
        brand.contains('mi') ||
        brand.contains('redmi')) {
      return SupportedBrand.xiaomi;
    }
    return SupportedBrand.huawei;
  }

  /// 加载指引完成状态（从本地缓存）
  Future<void> _loadGuideCompletedStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _preventSleepCompleted.value =
          prefs.getBool(_guidePreventSleepKey) ?? false;
      _backgroundRunCompleted.value =
          prefs.getBool(_guideBackgroundRunKey) ?? false;
      _lockBackgroundCompleted.value =
          prefs.getBool(_guideLockBackgroundKey) ?? false;
    } catch (e) {
      logError('加载指引完成状态失败: $e', tag: 'SystemPermission', error: e);
    }
  }

  /// 当前指引是否已完成（用于决定首次进入时按钮文案）
  bool isGuideCompleted(SystemPermissionGuideType type) {
    switch (type) {
      case SystemPermissionGuideType.preventSleep:
        return _preventSleepCompleted.value;
      case SystemPermissionGuideType.allowBackgroundRun:
        return _backgroundRunCompleted.value;
      case SystemPermissionGuideType.lockInBackground:
        return _lockBackgroundCompleted.value;
      case SystemPermissionGuideType.location:
        return isLocationAlwaysGranted.value; // 定位权限以“始终允许”为准
      case SystemPermissionGuideType.notification:
        return isNotificationGranted.value;
      case SystemPermissionGuideType.appUsage:
        return isUsageAccessGranted.value;
    }
  }

  /// 标记本次会话中是否点击过“去设置”（返回后要显示 再次设置/完成）
  void markGuideOpenedThisSession(SystemPermissionGuideType type) {
    switch (type) {
      case SystemPermissionGuideType.preventSleep:
        _preventSleepOpenedThisSession.value = true;
        break;
      case SystemPermissionGuideType.allowBackgroundRun:
        _backgroundRunOpenedThisSession.value = true;
        break;
      case SystemPermissionGuideType.lockInBackground:
        // 锁定后台没有“去设置”按钮，这里不需要记录
        break;
      case SystemPermissionGuideType.location:
      case SystemPermissionGuideType.notification:
      case SystemPermissionGuideType.appUsage:
        // 权限类型的指引不需要记录会话状态，因为权限状态是实时检查的
        break;
    }
  }

  bool isGuideOpenedThisSession(SystemPermissionGuideType type) {
    switch (type) {
      case SystemPermissionGuideType.preventSleep:
        return _preventSleepOpenedThisSession.value;
      case SystemPermissionGuideType.allowBackgroundRun:
        return _backgroundRunOpenedThisSession.value;
      case SystemPermissionGuideType.lockInBackground:
        return false;
      case SystemPermissionGuideType.location:
      case SystemPermissionGuideType.notification:
      case SystemPermissionGuideType.appUsage:
        return false; // 权限类型的指引不需要记录会话状态
    }
  }

  /// 持久化保存指引完成状态
  Future<void> markGuideCompleted(SystemPermissionGuideType type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      switch (type) {
        case SystemPermissionGuideType.preventSleep:
          _preventSleepCompleted.value = true;
          await prefs.setBool(_guidePreventSleepKey, true);
          break;
        case SystemPermissionGuideType.allowBackgroundRun:
          _backgroundRunCompleted.value = true;
          await prefs.setBool(_guideBackgroundRunKey, true);
          break;
        case SystemPermissionGuideType.lockInBackground:
          _lockBackgroundCompleted.value = true;
          await prefs.setBool(_guideLockBackgroundKey, true);
          break;
        case SystemPermissionGuideType.location:
        case SystemPermissionGuideType.notification:
        case SystemPermissionGuideType.appUsage:
          // 权限类型的指引不需要持久化保存，因为权限状态是实时检查的
          break;
      }
    } catch (e) {
      logError('保存指引完成状态失败: $e', tag: 'SystemPermission', error: e);
    }
  }

  /// 应用生命周期变化监听
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 当应用从后台回到前台时，重新检查权限状态
    if (state == AppLifecycleState.resumed) {
      logDebug('应用回到前台，重新检查权限状态', tag: 'SystemPermission');
      // 延迟检查，确保页面完全激活
      Future.delayed(const Duration(milliseconds: 500), () {
        checkAllPermissions();
      });
    }
  }

  /// 检查所有权限状态
  Future<void> checkAllPermissions() async {
    // 避免重复检查
    if (isLoading.value) return;

    isLoading.value = true;
    try {
      final permissions = await _permissionService.checkAllPermissions();

      // 批量更新，减少UI重建次数
      final newLocationGranted = permissions[PermissionType.location] ?? false;
      final newLocationAlwaysGranted =
          permissions[PermissionType.locationAlways] ?? false;
      final newNotificationGranted =
          permissions[PermissionType.notification] ?? false;
      final newBatteryOptimized = permissions[PermissionType.battery] ?? false;
      final newUsageAccessGranted = permissions[PermissionType.usage] ?? false;

      // 只在状态真正改变时才更新
      if (isLocationGranted.value != newLocationGranted) {
        isLocationGranted.value = newLocationGranted;
      }
      // 更新"始终允许"定位权限状态
      if (isLocationAlwaysGranted.value != newLocationAlwaysGranted) {
        isLocationAlwaysGranted.value = newLocationAlwaysGranted;
      }
      if (isNotificationGranted.value != newNotificationGranted) {
        isNotificationGranted.value = newNotificationGranted;
      }
      if (isBatteryOptimized.value != newBatteryOptimized) {
        isBatteryOptimized.value = newBatteryOptimized;
      }

      // App使用记录权限变化时，特别处理
      final previousUsageAccess = isUsageAccessGranted.value;
      if (isUsageAccessGranted.value != newUsageAccessGranted) {
        isUsageAccessGranted.value = newUsageAccessGranted;

        // 如果权限从无到有，立即通知自动上报服务
        if (!previousUsageAccess && newUsageAccessGranted) {
          logDebug('App使用记录权限从无到有，立即通知自动上报服务', tag: 'SystemPermission');
          try {
            if (Get.isRegistered<AppUsageAutoReportService>()) {
              final service = Get.find<AppUsageAutoReportService>();
              await service.checkPermissionAndRestartIfNeeded();
              logDebug('✅ 已通知自动上报服务启动', tag: 'SystemPermission');
            }
          } catch (e) {
            logError('通知自动上报服务失败: $e', tag: 'SystemPermission', error: e);
          }
        }
      }

      // 记录后台位置权限状态（用于调试）
      logDebug('后台位置权限: $newLocationAlwaysGranted', tag: 'SystemPermission');

      logDebug('权限状态检查完成:', tag: 'SystemPermission');
      logDebug('位置权限: ${isLocationGranted.value}', tag: 'SystemPermission');
      logDebug('通知权限: ${isNotificationGranted.value}', tag: 'SystemPermission');
      logDebug('电池优化: ${isBatteryOptimized.value}', tag: 'SystemPermission');
      logDebug(
        '使用情况访问: ${isUsageAccessGranted.value}',
        tag: 'SystemPermission',
      );
    } catch (e) {
      logError('检查权限状态时发生错误: $e', tag: 'SystemPermission', error: e);
      OKToastUtil.showError('检查权限状态失败');
    } finally {
      isLoading.value = false;
    }
  }

  /// 根据权限类型获取当前状态
  bool getPermissionStatus(PermissionType type) {
    switch (type) {
      case PermissionType.location:
        return isLocationGranted.value;
      case PermissionType.locationAlways:
        return isLocationGranted.value; // 后台位置权限基于基础位置权限
      case PermissionType.notification:
        return isNotificationGranted.value;
      case PermissionType.battery:
        return isBatteryOptimized.value;
      case PermissionType.usage:
        return isUsageAccessGranted.value;
      case PermissionType.photos:
        // 相册权限状态需要通过 PermissionService 检查
        return true; // 默认返回 true，实际状态由 PermissionService 管理
      case PermissionType.camera:
        // 相机权限状态需要通过 PermissionService 检查
        return true; // 默认返回 true，实际状态由 PermissionService 管理
    }
  }

  /// 根据权限类型获取状态描述
  String getPermissionStatusText(PermissionType type) {
    final isGranted = getPermissionStatus(type);
    return _permissionService.getPermissionStatusDescription(type, isGranted);
  }

  /// 根据权限类型获取按钮文本
  String getButtonText(PermissionType type) {
    final isGranted = getPermissionStatus(type);
    return isGranted ? "已开启" : "去设置";
  }

  /// 根据权限类型获取按钮颜色
  Color getButtonColor(PermissionType type) {
    final isGranted = getPermissionStatus(type);
    return isGranted ? const Color(0xFF999999) : const Color(0xFFFFA9E0);
  }

  /// 根据权限类型获取按钮是否可点击
  bool isButtonEnabled(PermissionType type) {
    return !getPermissionStatus(type);
  }

  /// 处理权限设置点击
  Future<void> onPermissionTap(PermissionType type) async {
    final isGranted = getPermissionStatus(type);

    if (isGranted) {
      // 权限已开启，不执行任何操作
      return;
    }

    try {
      // 跳转到对应的系统设置页面
      await _permissionService.openPermissionSettings(type);
    } catch (e) {
      logError('跳转系统设置失败: $e', tag: 'SystemPermission', error: e);
      OKToastUtil.showError('无法打开设置页面，请手动前往系统设置');
    }
  }

  // 始终定位权限的图片资源（已开启基础定位但未开启始终定位时使用）
  static const Map<SupportedBrand, String> _locationAlwaysAssets = {
    SupportedBrand.huawei: 'assets/setting/kissu_location_all_huawei.webp',
    SupportedBrand.oppo: 'assets/setting/kissu_location_all_oppo.webp',
    SupportedBrand.vivo: 'assets/setting/kissu_location_all_vivo.webp',
    SupportedBrand.xiaomi: 'assets/setting/kissu_location_all_xiaomi.webp',
    SupportedBrand.other: 'assets/setting/kissu_location_all_huawei.webp',
  };

  String getGuideAsset(SystemPermissionGuideType type) {
    // 定位权限特殊处理：根据权限状态返回不同图片
    if (type == SystemPermissionGuideType.location) {
      // 已开启基础定位（无论是否开启始终定位）：显示始终定位指引图片
      if (isLocationGranted.value) {
        return _locationAlwaysAssets[currentBrand] ?? _locationAlwaysAssets[SupportedBrand.huawei]!;
      }
    }
    
    final assets = _guideAssets[type];
    if (assets == null) {
      return '';
    }
    return assets[currentBrand] ?? assets[SupportedBrand.huawei]!;
  }

  void openGuidePage(SystemPermissionGuideType type) {
    switch (type) {
      case SystemPermissionGuideType.preventSleep:
        Get.toNamed(KissuRoutePath.systemPermissionPreventSleepGuide);
        break;
      case SystemPermissionGuideType.lockInBackground:
        Get.toNamed(KissuRoutePath.systemPermissionLockGuide);
        break;
      case SystemPermissionGuideType.allowBackgroundRun:
        Get.toNamed(KissuRoutePath.systemPermissionBackgroundGuide);
        break;
      case SystemPermissionGuideType.location:
        Get.toNamed(KissuRoutePath.systemPermissionLocationGuide);
        break;
      case SystemPermissionGuideType.notification:
        Get.toNamed(KissuRoutePath.systemPermissionNotificationGuide);
        break;
      case SystemPermissionGuideType.appUsage:
        Get.toNamed(KissuRoutePath.systemPermissionAppUsageGuide);
        break;
    }
  }

  /// 检查防止程序休眠权限状态
  Future<bool> checkPreventSleepPermission() async {
    return await _permissionService.isBatteryOptimizationDisabled();
  }

  /// 处理防止程序休眠点击：直接申请权限，失败则进入详情页面
  Future<void> handlePreventSleepTap() async {
    // 先检查权限状态
    final isGranted = await checkPreventSleepPermission();
    if (isGranted) {
      // 权限已开启，标记为已完成
      await markGuideCompleted(SystemPermissionGuideType.preventSleep);
      // 刷新权限状态
      await checkAllPermissions();
      return;
    }

    try {
      // 直接申请权限
      final granted = await _permissionService.requestBatteryOptimizationPermission();
      
      if (granted) {
        // 申请成功，标记为已完成
        await markGuideCompleted(SystemPermissionGuideType.preventSleep);
        // 刷新权限状态
        await checkAllPermissions();
      } else {
        // 申请失败，跳转到详情页面
        Get.toNamed(KissuRoutePath.systemPermissionPreventSleepGuide);
      }
    } catch (e) {
      logError('申请防止程序休眠权限失败: $e', tag: 'SystemPermission', error: e);
      // 申请失败，跳转到详情页面
      Get.toNamed(KissuRoutePath.systemPermissionPreventSleepGuide);
    }
  }

  Future<void> openGuideSetting(SystemPermissionGuideType type) async {
    try {
      // 不同指引跳转到不同的系统页面
      switch (type) {
        case SystemPermissionGuideType.preventSleep:
          // 防止程序休眠：
          // 先检查权限是否已开启
          final isAlreadyGranted = await _permissionService.isBatteryOptimizationDisabled();
          if (isAlreadyGranted) {
            // 权限已开启，跳转到系统电池优化设置页面
            await _permissionService.openBatteryOptimizationSettings();
          } else {
            // 权限未开启，申请权限
            final granted = await _permissionService.requestBatteryOptimizationPermission();
            if (granted) {
              // 申请成功，标记为已完成并刷新权限状态
              await markGuideCompleted(SystemPermissionGuideType.preventSleep);
              await checkAllPermissions();
            } else {
              // 如果用户拒绝，引导到通用电池优化设置页
              await _permissionService.openBatteryOptimizationSettings();
            }
          }
          break;
        case SystemPermissionGuideType.allowBackgroundRun:
          // 统一跳转到应用详情页，避免各品牌回退到系统首页
          await _permissionService.openSystemSettingsPage();
          break;
        case SystemPermissionGuideType.lockInBackground:
          // 其他指引：保持原有行为，跳转到应用详情页
          await _permissionService.openAppSettingsPage();
          break;
        case SystemPermissionGuideType.location:
          // 定位权限：分步骤申请
          // 1. 先检查是否有"始终允许"权限
          final hasAlwaysLocation = await _permissionService.isLocationAlwaysPermissionGranted();
          if (hasAlwaysLocation) {
            // 已有"始终允许"权限，跳转到系统定位权限设置页面
            await _permissionService.openLocationSettings();
          } else {
            // 2. 检查是否有基本定位权限
            final hasBasicLocation = await _permissionService.isLocationPermissionGranted();
            if (!hasBasicLocation) {
              // 没有基本定位权限，先申请基本定位权限
              await _permissionService.requestLocationPermission();
            } else {
              // 有基本定位权限，申请"始终允许"权限
              await _permissionService.requestLocationAlwaysPermission();
            }
          }
          await checkAllPermissions();
          break;
        case SystemPermissionGuideType.notification:
          // 通知权限：先检查是否已开启
          final hasNotification = await _permissionService.isNotificationPermissionGranted();
          if (hasNotification) {
            // 权限已开启，跳转到系统通知权限设置页面
            await _permissionService.openNotificationSettings();
          } else {
            // 权限未开启，申请通知权限
            await _permissionService.requestNotificationPermission();
          }
          await checkAllPermissions();
          break;
        case SystemPermissionGuideType.appUsage:
          // 应用使用权限：跳转到系统设置
          await _permissionService.openUsageAccessSettings();
          await checkAllPermissions();
          break;
      }
    } catch (e) {
      logError('打开教程关联设置失败: $e', tag: 'SystemPermission', error: e);
      OKToastUtil.showError('无法打开设置页面，请手动前往系统设置');
    }
  }

  /// 检查是否所有权限都已开启
  bool areAllPermissionsEnabled() {
    // 检查基础权限（定位权限以"始终允许"为准）
    final basicPermissionsEnabled = isLocationAlwaysGranted.value &&
        isNotificationGranted.value &&
        isBatteryOptimized.value &&
        isUsageAccessGranted.value;

    // 检查指引完成状态
    final guidesCompleted = _preventSleepCompleted.value &&
        _backgroundRunCompleted.value &&
        (isXiaomiDevice || _lockBackgroundCompleted.value); // 小米设备不需要检查锁定后台

    return basicPermissionsEnabled && guidesCompleted;
  }
}
