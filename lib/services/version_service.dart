import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:kissu_app/network/public/version_api.dart';
import 'package:kissu_app/widgets/dialogs/version_update_dialog.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/network/tools/logging/log_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kissu_app/constants/app_constants.dart';

/// 版本更新服务
class VersionService extends GetxService {
  /// 当前应用版本号（数字格式）
  int? _currentVersionNum;
  
  /// 是否正在显示更新弹窗（防止重复弹窗）
  bool _isDialogShowing = false;
  
  /// 上次检查时间（用于前台恢复检查冷却）
  DateTime? _lastCheckTime;
  
  /// 检查冷却时间（前台恢复时至少间隔5s钟才再次检查）
  static const Duration _checkCooldown = Duration(seconds: 5);
  
  static const String _packageName = AppConstants.packageName;
  
  /// SharedPreferences key: 用户点击"稍后更新"时记录的日期（yyyy-MM-dd）
  static const String _spKeyDismissDate = 'version_update_dismiss_date';
  
  /// 记录用户点击了"稍后更新"，当天不再弹出
  Future<void> dismissUpdateToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    await prefs.setString(_spKeyDismissDate, dateStr);
  }
  
  /// 检查今天是否已经点击过"稍后更新"
  Future<bool> _isDismissedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissDate = prefs.getString(_spKeyDismissDate);
    if (dismissDate == null) return false;
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return dismissDate == todayStr;
  }
  
  /// 获取当前版本号（数字格式）
  Future<int> getCurrentVersionNum() async {
    if (_currentVersionNum != null) {
      return _currentVersionNum!;
    }
    
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String version = packageInfo.version; // 例如: "1.0.1"
      
      // 将版本号转换为数字格式
       
      List<String> parts = version.split('.');
      if (parts.length == 3) {
        int major = int.tryParse(parts[0]) ?? 0;
        int minor = int.tryParse(parts[1]) ?? 0;
        int patch = int.tryParse(parts[2]) ?? 0;
        _currentVersionNum = major * 1000000 + minor * 1000 + patch;
      } else {
        _currentVersionNum = 0;
      }
      
      return _currentVersionNum!;
    } catch (e) {
      logger.error('获取版本号失败: $e', tag: 'VersionService', error: e);
      _currentVersionNum = 0;
      return 0;
    }
  }
  
  /// 检查版本更新（首页自动检查，只弹出强更新和弱更新）
  Future<void> checkVersionForHomePage(BuildContext context) async {
    try {
      if (_isDialogShowing) return;
      
      final versionInfo = await VersionApi.checkVersion();
      if (versionInfo == null) return;
      
      final currentVersionNum = await getCurrentVersionNum();
      _lastCheckTime = DateTime.now();
      
      // 比较版本号
      if (versionInfo.versionNum > currentVersionNum) {
        if (versionInfo.isForced) {
          // 强更新（upgradeType=3）：始终弹窗，用户无法跳过
          _showUpdateDialog(context, versionInfo);
        } else {
          // 非强更新（upgradeType=1,2）：如果今天已点击"稍后更新"则不再弹出
          final dismissed = await _isDismissedToday();
          if (!dismissed) {
            _showUpdateDialog(context, versionInfo);
          }
        }
      }
    } catch (e) {
      logger.error('检查版本更新失败: $e', tag: 'VersionService', error: e);
    }
  }
  
  /// 检查版本更新（后台切回前台时调用，带冷却时间）
  Future<void> checkVersionOnResume() async {
    try {
      // 如果弹窗正在显示，跳过
      if (_isDialogShowing) return;
      
      // 冷却时间内不重复检查
      if (_lastCheckTime != null &&
          DateTime.now().difference(_lastCheckTime!) < _checkCooldown) {
        logger.debug('版本检查冷却中，跳过本次检查', tag: 'VersionService');
        return;
      }
      
      final currentContext = Get.context;
      if (currentContext == null) return;
      
      // 延迟一小段时间，确保页面已完全恢复
      await Future.delayed(const Duration(milliseconds: 500));
      
      await checkVersionForHomePage(currentContext);
    } catch (e) {
      logger.error('前台恢复版本检查失败: $e', tag: 'VersionService', error: e);
    }
  }
  
  /// 检查版本更新（关于我们页面手动检查，所有类型都弹窗）
  Future<void> checkVersionForAboutPage(BuildContext context) async {
    try {
      final versionInfo = await VersionApi.checkVersion();
      if (versionInfo == null) {
        // 检查失败，提示用户
        OKToastUtil.show('检查更新失败，请稍后重试');
        return;
      }
      
      final currentVersionNum = await getCurrentVersionNum();
      
      // 比较版本号
      if (versionInfo.versionNum > currentVersionNum) {
        // 有新版本，所有类型都弹窗
        _showUpdateDialog(context, versionInfo);
      } else {
        // 已是最新版本
        OKToastUtil.show('当前已是最新版本');
      }
    } catch (e) {
      logger.error('检查版本更新失败: $e', tag: 'VersionService', error: e);
      OKToastUtil.show('检查更新失败，请稍后重试');
    }
  }
  
  /// 显示更新弹窗
  void _showUpdateDialog(BuildContext context, VersionInfo versionInfo) {
    _isDialogShowing = true;
     showDialog(
      context: context,
      barrierDismissible: false, // 禁止点击外部关闭
      builder: (context) => VersionUpdateDialog(
        versionInfo: versionInfo,
      ),
    ).then((_) {
      _isDialogShowing = false;
    });
  }
  
  /// 根据手机品牌打开对应的应用市场
  static Future<void> openAppStore() async {
    // 获取设备信息
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final brand = androidInfo.brand.toLowerCase();
    
    // 华为/荣耀 + 鸿蒙系统：直接打开华为应用市场首页（app不在鸿蒙应用市场）
    final isHuaweiOrHonor = brand.contains('huawei') || brand.contains('honor');
    if (isHuaweiOrHonor && _isHarmonyOS(androidInfo)) {
      try {
        final launched = await launchUrl(
          Uri.parse('appmarket://'),
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
      } catch (_) {}
      // scheme 打不开，尝试网页
      try {
        final launched = await launchUrl(
          Uri.parse('https://appgallery.huawei.com'),
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
      } catch (_) {}
      OKToastUtil.show('无法打开应用市场');
      return;
    }
    
    // 品牌对应的应用市场 scheme
    final Map<String, String> storeSchemes = {
      'xiaomi': 'mimarket://details?id=$_packageName',
      'redmi': 'mimarket://details?id=$_packageName',
      'huawei': 'appmarket://details?id=$_packageName',
      'honor': 'appmarket://details?id=$_packageName',
      'vivo': 'vivomarket://details?id=$_packageName',
      'oppo': 'market://details?id=$_packageName',
      // 'realme': 'oppomarket://details?id=$_packageName',
      // 'oneplus': 'oppomarket://details?id=$_packageName',
      'meizu': 'mstore://details?package_name=$_packageName',
    };
    
    // 品牌对应的网页备用链接
    final Map<String, String> storeFallbacks = {
      'xiaomi': 'https://app.mi.com/details?id=$_packageName',
      'redmi': 'https://app.mi.com/details?id=$_packageName',
      'huawei': 'https://appgallery.huawei.com/app/$_packageName',
      'honor': 'https://appgallery.huawei.com/app/$_packageName',
      'vivo': 'https://h5.appstore.vivo.com.cn/h5/detail/$_packageName',
      'oppo': 'https://store.oppo.com/cn/app/details?pkgname=$_packageName',
      // 'realme': 'https://store.oppo.com/cn/app/details?pkgname=$_packageName',
      // 'oneplus': 'https://store.oppo.com/cn/app/details?pkgname=$_packageName',
      'meizu': 'https://app.meizu.com/apps/public/detail?package_name=$_packageName',
    };
    
    // 先尝试品牌对应的应用市场 scheme（直接 launch，不用 canLaunchUrl）
    final schemeUrl = storeSchemes[brand];
    if (schemeUrl != null) {
      try {
        final launched = await launchUrl(
          Uri.parse(schemeUrl),
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
      } catch (_) {}
    }
    
    // scheme 打不开，尝试网页备用链接
    final fallbackUrl = storeFallbacks[brand];
    if (fallbackUrl != null) {
      try {
        final launched = await launchUrl(
          Uri.parse(fallbackUrl),
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
      } catch (_) {}
    }
    
    // 兜底：使用系统默认应用市场
    try {
      final launched = await launchUrl(
        Uri.parse('market://details?id=$_packageName'),
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    } catch (_) {}
    
    OKToastUtil.show('无法打开应用市场');
  }
  
  /// 检测是否为鸿蒙系统（与 SystemPermissionController 相同的逻辑）
  static bool _isHarmonyOS(AndroidDeviceInfo androidInfo) {
    final brand = androidInfo.brand.toLowerCase();
    final displayLower = androidInfo.display.toLowerCase();
    final fingerprintLower = androidInfo.fingerprint.toLowerCase();
    final hostLower = androidInfo.host.toLowerCase();
    final osVersion = Platform.operatingSystemVersion.toLowerCase();
    final versionRelease = androidInfo.version.release;
    
    // 方式1：包含 harmony / ohos 关键字
    if (displayLower.contains('harmony') ||
        fingerprintLower.contains('harmony') ||
        hostLower.contains('harmony') ||
        displayLower.contains('ohos') ||
        fingerprintLower.contains('ohos') ||
        osVersion.contains('harmony') ||
        osVersion.contains('ohos')) {
      return true;
    }
    
    // 方式2：华为/荣耀设备 display/osVersion 以 "system" 开头
    final isHuaweiOrHonor = brand.contains('huawei') || brand.contains('honor');
    if (isHuaweiOrHonor && 
        (displayLower.startsWith('system') || osVersion.startsWith('system'))) {
      return true;
    }
    
    // 方式3：华为/荣耀设备 version.release 为 "5.x.x" 格式
    if (isHuaweiOrHonor) {
      final parts = versionRelease.split('.');
      final majorVersion = int.tryParse(parts[0]) ?? 0;
      if (majorVersion >= 5 && parts.length > 1) {
        return true;
      }
    }
    
    return false;
  }
}

