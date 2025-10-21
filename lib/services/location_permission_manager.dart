import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import '../widgets/dialogs/location_permission_dialog.dart';
import '../widgets/custom_toast_widget.dart';

/// 定位权限申请管理器
/// 统一处理定位权限申请逻辑：先弹自定义弹窗，再弹系统权限申请
class LocationPermissionManager {
  static LocationPermissionManager? _instance;
  static LocationPermissionManager get instance => _instance ??= LocationPermissionManager._();
  
  LocationPermissionManager._();

  // 防重复弹窗标志
  bool _isShowingDialog = false;

  /// 请求定位权限（完整流程）
  /// 1. 先检查权限状态
  /// 2. 如果未授权，先弹自定义弹窗
  /// 3. 用户同意后，再弹系统权限申请
  /// 4. 处理权限申请结果
  Future<bool> requestLocationPermission({
    String? customMessage,
    bool showCustomDialog = true,
  }) async {
    try {
      // 防重复弹窗检查
      if (_isShowingDialog) {
        debugPrint('⚠️ 权限弹窗已在显示中，跳过重复请求');
        return false;
      }

      debugPrint('🔐 开始定位权限申请流程...');

      // 1. 检查当前权限状态
      var locationStatus = await Permission.location.status;
      debugPrint('🔐 当前定位权限状态: $locationStatus');

      // 如果已经授权，直接返回成功
      if (locationStatus.isGranted) {
        debugPrint('✅ 定位权限已授权');
        return true;
      }

      // 如果被永久拒绝，引导用户去设置页面
      if (locationStatus.isPermanentlyDenied) {
        debugPrint('❌ 定位权限被永久拒绝，引导用户去设置');
        _isShowingDialog = true;
        bool userConfirmed = await _showCustomPermissionDialog();
        _isShowingDialog = false;
        
        if (userConfirmed) {
          // 用户确认后，尝试打开系统设置
          await openAppSettings();
        }
        return false;
      }

      // 2. 如果未授权且需要显示自定义弹窗
      if (showCustomDialog) {
        debugPrint('💬 显示自定义权限申请弹窗...');
        
        _isShowingDialog = true;
        // 显示自定义弹窗
        final customResult = await LocationPermissionDialog.show(Get.context!);
        _isShowingDialog = false;
        
        // 如果用户拒绝自定义弹窗，直接返回失败
        if (customResult != true) {
          debugPrint('❌ 用户在自定义弹窗中拒绝了权限申请');
          return false;
        }
        
        debugPrint('✅ 用户同意自定义弹窗，继续系统权限申请...');
      }

      // 3. 申请系统权限
      debugPrint('🔐 申请系统定位权限...');
      locationStatus = await Permission.location.request();
      debugPrint('🔐 系统权限申请结果: $locationStatus');

      // 4. 处理权限申请结果
      if (locationStatus.isGranted) {
        debugPrint('✅ 定位权限申请成功');
        return true;
      } else if (locationStatus.isDenied) {
        debugPrint('❌ 定位权限被拒绝');
        CustomToast.show(
          Get.context!,
          '定位权限被拒绝，无法使用定位功能',
        );
        return false;
      } else if (locationStatus.isPermanentlyDenied) {
        debugPrint('❌ 定位权限被永久拒绝');
        // 🔧 修复：移除重复弹窗，已经在上面处理过永久拒绝的情况
        CustomToast.show(
          Get.context!,
          '定位权限被永久拒绝，请在设置中手动开启',
        );
        return false;
      }

      return false;
    } catch (e) {
      _isShowingDialog = false; // 确保异常时重置状态
      debugPrint('❌ 定位权限申请失败: $e');
      CustomToast.show(
        Get.context!,
        '定位权限申请失败，请重试',
      );
      return false;
    }
  }

  /// 检查定位权限状态
  Future<bool> isLocationPermissionGranted() async {
    try {
      var status = await Permission.location.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('❌ 检查定位权限状态失败: $e');
      return false;
    }
  }

  /// 检查定位权限是否被永久拒绝
  Future<bool> isLocationPermissionPermanentlyDenied() async {
    try {
      var status = await Permission.location.status;
      return status.isPermanentlyDenied;
    } catch (e) {
      debugPrint('❌ 检查定位权限永久拒绝状态失败: $e');
      return false;
    }
  }


  /// 显示自定义权限申请弹窗
  Future<bool> _showCustomPermissionDialog() async {
    try {
      // 检查是否已在显示弹窗
      if (_isShowingDialog) {
        debugPrint('⚠️ 权限弹窗已在显示中，跳过重复请求');
        return false;
      }

      final result = await LocationPermissionDialog.show(Get.context!);
      return result == true;
    } catch (e) {
      debugPrint('❌ 显示自定义权限弹窗失败: $e');
      return false;
    }
  }

  /// 静默检查权限状态（不弹窗）
  Future<bool> checkLocationPermissionSilently() async {
    try {
      var status = await Permission.location.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('❌ 静默检查定位权限失败: $e');
      return false;
    }
  }
}
