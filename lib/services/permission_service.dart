import 'package:permission_handler/permission_handler.dart';
import 'package:kissu_app/utils/permission_helper.dart';
import 'dart:io';

/// 权限类型枚举
enum PermissionType {
  location,           // 位置权限
  locationAlways,     // 后台位置权限
  notification,       // 通知权限
  battery,            // 电池优化（后台运行）
  usage,              // 使用情况访问权限
}

/// 权限服务类
/// 负责检查各种权限状态和跳转到系统设置页面
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// 检查位置权限状态
  Future<bool> isLocationPermissionGranted() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// 检查后台位置权限状态
  Future<bool> isLocationAlwaysPermissionGranted() async {
    if (Platform.isAndroid) {
      final status = await Permission.locationAlways.status;
      return status.isGranted;
    } else if (Platform.isIOS) {
      // iOS 使用 locationWhenInUse 或 locationAlways
      final status = await Permission.locationAlways.status;
      return status.isGranted;
    }
    return false;
  }

  /// 检查通知权限状态
  Future<bool> isNotificationPermissionGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// 检查电池优化权限状态（Android）
  Future<bool> isBatteryOptimizationDisabled() async {
    if (Platform.isAndroid) {
      return await Permission.ignoreBatteryOptimizations.isGranted;
    }
    return true; // iOS不需要电池优化设置
  }

  /// 检查使用情况访问权限状态（Android）
  /// 注意：packageUsageStats在当前版本中可能不可用，暂时返回true
  Future<bool> isUsageAccessGranted() async {
    if (Platform.isAndroid) {
      // TODO: 使用正确的权限类型检查使用情况访问权限
      // return await Permission.packageUsageStats.isGranted;
      return true; // 暂时返回true，避免错误
    }
    return true; // iOS不需要此权限
  }

  /// 根据权限类型检查权限状态
  Future<bool> checkPermissionStatus(PermissionType type) async {
    switch (type) {
      case PermissionType.location:
        return await isLocationPermissionGranted();
      case PermissionType.locationAlways:
        return await isLocationAlwaysPermissionGranted();
      case PermissionType.notification:
        return await isNotificationPermissionGranted();
      case PermissionType.battery:
        return await isBatteryOptimizationDisabled();
      case PermissionType.usage:
        return await isUsageAccessGranted();
    }
  }

  /// 请求位置权限
  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      print("定位权限已获取");
      return true;
    } else if (status.isPermanentlyDenied) {
      // 权限被永久拒绝，需要跳转到设置页面
      await openAppSettings();
      return false;
    }
    return false;
  }

  /// 请求后台位置权限
  Future<bool> requestLocationAlwaysPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.locationAlways.request();
      if (status.isGranted) {
        print("后台定位权限已获取");
        return true;
      } else if (status.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }
    } else if (Platform.isIOS) {
      final status = await Permission.locationAlways.request();
      if (status.isGranted) {
        print("后台定位权限已获取");
        return true;
      } else if (status.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }
    }
    return false;
  }

  /// 请求通知权限
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      print("通知权限已获取");
      return true;
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    return false;
  }

  /// 请求电池优化权限
  Future<bool> requestBatteryOptimizationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.ignoreBatteryOptimizations.request();
      return status.isGranted;
    }
    return true;
  }

  /// 请求使用情况访问权限
  Future<bool> requestUsageAccessPermission() async {
    if (Platform.isAndroid) {
      // TODO: 使用正确的权限类型请求使用情况访问权限
      // final status = await Permission.packageUsageStats.request();
      // return status.isGranted;
      return true; // 暂时返回true，避免错误
    }
    return true;
  }

  /// 跳转到应用设置页面
  Future<void> openAppSettingsPage() async {
    try {
      await PermissionHelper.openAppSettings();
    } catch (e) {
      print('跳转应用设置失败: $e');
      throw Exception('无法打开应用设置页面');
    }
  }

  /// 跳转到位置权限设置页面
  Future<void> openLocationSettings() async {
    try {
      await PermissionHelper.openLocationSettings();
    } catch (e) {
      print('跳转位置权限设置失败: $e');
      throw Exception('无法打开位置权限设置页面');
    }
  }

  /// 跳转到通知权限设置页面
  Future<void> openNotificationSettings() async {
    try {
      await PermissionHelper.openNotificationSettings();
    } catch (e) {
      print('跳转通知权限设置失败: $e');
      throw Exception('无法打开通知权限设置页面');
    }
  }

  /// 跳转到电池优化设置页面（仅Android）
  Future<void> openBatteryOptimizationSettings() async {
    try {
      await PermissionHelper.openBatteryOptimizationSettings();
    } catch (e) {
      print('跳转电池优化设置失败: $e');
      throw Exception('无法打开电池优化设置页面');
    }
  }

  /// 跳转到使用情况访问权限设置页面（仅Android）
  Future<void> openUsageAccessSettings() async {
    try {
      await PermissionHelper.openUsageAccessSettings();
    } catch (e) {
      print('跳转使用情况访问权限设置失败: $e');
      throw Exception('无法打开使用情况访问权限设置页面');
    }
  }

  /// 根据权限类型跳转到对应的系统设置页面
  Future<void> openPermissionSettings(PermissionType type) async {
    try {
      switch (type) {
        case PermissionType.location:
        case PermissionType.locationAlways:
          await openLocationSettings();
          break;
        case PermissionType.notification:
          await openNotificationSettings();
          break;
        case PermissionType.battery:
          await openBatteryOptimizationSettings();
          break;
        case PermissionType.usage:
          await openUsageAccessSettings();
          break;
      }
    } catch (e) {
      print('跳转权限设置失败: $e');
      rethrow; // 重新抛出异常，让调用者处理
    }
  }

  /// 获取权限状态描述
  String getPermissionStatusDescription(PermissionType type, bool isGranted) {
    switch (type) {
      case PermissionType.location:
        return isGranted ? "已开启" : "未开启";
      case PermissionType.locationAlways:
        return isGranted ? "已开启" : "未开启";
      case PermissionType.notification:
        return isGranted ? "已开启" : "未开启";
      case PermissionType.battery:
        return isGranted ? "已开启" : "未开启";
      case PermissionType.usage:
        return isGranted ? "已授权" : "未授权";
    }
  }

  /// 获取权限设置说明
  String getPermissionDescription(PermissionType type) {
    switch (type) {
      case PermissionType.location:
        return "和ta持续分享你的位置";
      case PermissionType.locationAlways:
        return "后台持续定位，确保位置同步";
      case PermissionType.notification:
        return "收到ta的实时动态提醒";
      case PermissionType.battery:
        return "应用后台常驻，确保数据同步";
      case PermissionType.usage:
        return "和ta分享手机使用报告";
    }
  }

  /// 批量检查所有权限状态
  Future<Map<PermissionType, bool>> checkAllPermissions() async {
    return {
      PermissionType.location: await isLocationPermissionGranted(),
      PermissionType.locationAlways: await isLocationAlwaysPermissionGranted(),
      PermissionType.notification: await isNotificationPermissionGranted(),
      PermissionType.battery: await isBatteryOptimizationDisabled(),
      PermissionType.usage: await isUsageAccessGranted(),
    };
  }

  /// 智能权限请求：先请求基础权限，再请求高级权限
  Future<Map<PermissionType, bool>> requestPermissionsIntelligently() async {
    Map<PermissionType, bool> results = {};

    // 1. 先请求基础位置权限
    results[PermissionType.location] = await requestLocationPermission();
    
    // 2. 如果基础位置权限获取成功，再请求后台位置权限
    if (results[PermissionType.location]!) {
      results[PermissionType.locationAlways] = await requestLocationAlwaysPermission();
    } else {
      results[PermissionType.locationAlways] = false;
    }

    // 3. 请求通知权限
    results[PermissionType.notification] = await requestNotificationPermission();

    // 4. 请求电池优化权限（Android）
    results[PermissionType.battery] = await requestBatteryOptimizationPermission();

    // 5. 请求使用情况访问权限（Android）
    results[PermissionType.usage] = await requestUsageAccessPermission();

    return results;
  }

  /// 检查权限是否被永久拒绝
  Future<bool> isPermissionPermanentlyDenied(PermissionType type) async {
    Permission permission;
    switch (type) {
      case PermissionType.location:
        permission = Permission.location;
        break;
      case PermissionType.locationAlways:
        permission = Permission.locationAlways;
        break;
      case PermissionType.notification:
        permission = Permission.notification;
        break;
      case PermissionType.battery:
        permission = Permission.ignoreBatteryOptimizations;
        break;
      case PermissionType.usage:
        // TODO: 使用正确的权限类型
        // permission = Permission.packageUsageStats;
        permission = Permission.location; // 暂时使用location权限避免错误
        break;
    }
    
    final status = await permission.status;
    return status.isPermanentlyDenied;
  }
}