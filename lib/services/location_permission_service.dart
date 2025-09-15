import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kissu_app/services/simple_location_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// 定位权限管理服务
class LocationPermissionService extends GetxService {
  static LocationPermissionService get instance => Get.find<LocationPermissionService>();
  
  // SharedPreferences 键
  static const String _hasRequestedLocationKey = 'has_requested_location_permission';
  
  /// 检查是否是首次登录且未请求过定位权限
  Future<bool> shouldRequestLocationPermission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasRequested = prefs.getBool(_hasRequestedLocationKey) ?? false;
      return !hasRequested;
    } catch (e) {
      debugPrint('检查定位权限请求状态失败: $e');
      return true; // 默认需要请求
    }
  }
  
  /// 标记已请求过定位权限
  Future<void> markLocationPermissionRequested() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasRequestedLocationKey, true);
      debugPrint('已标记定位权限请求状态');
    } catch (e) {
      debugPrint('标记定位权限请求状态失败: $e');
    }
  }
  
  /// 首次登录成功后请求定位权限
  Future<void> requestLocationPermissionAfterLogin() async {
    try {
      // 检查是否需要请求权限
      bool shouldRequest = await shouldRequestLocationPermission();
      if (!shouldRequest) {
        debugPrint('已请求过定位权限，跳过请求');
        return;
      }
      
      debugPrint('首次登录，请求定位权限');
      
      // 使用permission_handler请求权限
      var status = await Permission.location.status;
      if (status.isDenied) {
        status = await Permission.location.request();
      }
      
      bool hasPermission = status.isGranted;
      
      if (hasPermission) {
        debugPrint('定位权限已获取，启动定位服务');
        await _handleLocationPermissionGranted();
      } else {
        debugPrint('定位权限被拒绝');
        await _handleLocationPermissionDenied();
      }
      
      // 标记已请求过权限
      await markLocationPermissionRequested();
    } catch (e) {
      debugPrint('请求定位权限失败: $e');
      await markLocationPermissionRequested();
    }
  }
  
  
  /// 处理用户同意定位权限
  Future<void> _handleLocationPermissionGranted() async {
    try {
      debugPrint('🎯 用户同意定位权限，启动定位服务');
      
      // 获取定位服务实例
      final locationService = Get.find<SimpleLocationService>();
      
      // 启动定位服务
      bool success = await locationService.startLocation();
      
      if (success) {
        debugPrint('✅ 定位服务启动成功');
      } else {
        debugPrint('❌ 定位服务启动失败');
      }
    } catch (e) {
      debugPrint('处理定位权限同意失败: $e');
    }
  }
  
  /// 处理用户拒绝定位权限
  Future<void> _handleLocationPermissionDenied() async {
    try {
      debugPrint('❌ 用户拒绝定位权限');
      
      // 可以在这里添加一些提示或引导
      // 比如显示如何手动开启定位权限的说明
      
    } catch (e) {
      debugPrint('处理定位权限拒绝失败: $e');
    }
  }
  
  /// 手动触发定位权限请求（用于设置页面等）
  Future<void> requestLocationPermissionManually() async {
    try {
      debugPrint('手动请求定位权限');
      
      // 使用permission_handler请求权限
      var status = await Permission.location.status;
      if (status.isDenied) {
        status = await Permission.location.request();
      }
      
      bool hasPermission = status.isGranted;
      
      if (hasPermission) {
        debugPrint('定位权限已获取，启动定位服务');
        await _handleLocationPermissionGranted();
      } else {
        debugPrint('定位权限被拒绝');
        await _handleLocationPermissionDenied();
      }
    } catch (e) {
      debugPrint('手动请求定位权限失败: $e');
    }
  }
  
  /// 重置定位权限请求状态（用于测试）
  Future<void> resetLocationPermissionRequest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_hasRequestedLocationKey);
      debugPrint('已重置定位权限请求状态');
    } catch (e) {
      debugPrint('重置定位权限请求状态失败: $e');
    }
  }
  
  /// 获取定位权限请求状态
  Future<Map<String, dynamic>> getLocationPermissionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasRequested = prefs.getBool(_hasRequestedLocationKey) ?? false;
      
      return {
        'hasRequested': hasRequested,
        'shouldRequest': !hasRequested,
      };
    } catch (e) {
      debugPrint('获取定位权限状态失败: $e');
      return {
        'hasRequested': false,
        'shouldRequest': true,
      };
    }
  }
}
