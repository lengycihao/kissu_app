import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/permission_service.dart';

/// 权限设置页面
/// 展示各种权限状态并提供设置入口
class PermissionSettingPage extends StatefulWidget {
  const PermissionSettingPage({Key? key}) : super(key: key);

  @override
  State<PermissionSettingPage> createState() => _PermissionSettingPageState();
}

class _PermissionSettingPageState extends State<PermissionSettingPage> {
  final PermissionService _permissionService = PermissionService();
  Map<PermissionType, bool> _permissionStatus = {};

  @override
  void initState() {
    super.initState();
    _checkAllPermissions();
  }

  /// 检查所有权限状态
  Future<void> _checkAllPermissions() async {
    final status = await _permissionService.checkAllPermissions();
    setState(() {
      _permissionStatus = status;
    });
  }

  /// 请求单个权限
  Future<void> _requestPermission(PermissionType type) async {
    bool result = false;
    
    switch (type) {
      case PermissionType.location:
        result = await _permissionService.requestLocationPermission();
        break;
      case PermissionType.locationAlways:
        result = await _permissionService.requestLocationAlwaysPermission();
        break;
      case PermissionType.notification:
        result = await _permissionService.requestNotificationPermission();
        break;
      case PermissionType.battery:
        result = await _permissionService.requestBatteryOptimizationPermission();
        break;
      case PermissionType.usage:
        result = await _permissionService.requestUsageAccessPermission();
        break;
    }

    if (result) {
      Get.snackbar(
        "权限获取成功",
        _permissionService.getPermissionDescription(type),
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        "权限获取失败",
        "请在设置中手动开启权限",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }

    // 重新检查权限状态
    await _checkAllPermissions();
  }

  /// 跳转到权限设置页面
  Future<void> _openPermissionSettings(PermissionType type) async {
    await _permissionService.openPermissionSettings(type);
  }

  /// 智能请求所有权限
  Future<void> _requestAllPermissions() async {
    final results = await _permissionService.requestPermissionsIntelligently();
    
    int grantedCount = results.values.where((granted) => granted).length;
    int totalCount = results.length;
    
    Get.snackbar(
      "权限请求完成",
      "已获取 $grantedCount/$totalCount 个权限",
      backgroundColor: grantedCount == totalCount ? Colors.green : Colors.orange,
      colorText: Colors.white,
    );

    // 重新检查权限状态
    await _checkAllPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("权限设置"),
        backgroundColor: Colors.pink[100],
        foregroundColor: Colors.pink[800],
      ),
      body: Column(
        children: [
          // 智能请求按钮
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _requestAllPermissions,
              icon: const Icon(Icons.auto_fix_high),
              label: const Text("一键获取所有权限"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink[400],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          
          // 权限列表
          Expanded(
            child: ListView(
              children: PermissionType.values.map((type) {
                final isGranted = _permissionStatus[type] ?? false;
                return _buildPermissionItem(type, isGranted);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建权限项
  Widget _buildPermissionItem(PermissionType type, bool isGranted) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          _getPermissionIcon(type),
          color: isGranted ? Colors.green : Colors.orange,
          size: 28,
        ),
        title: Text(
          _getPermissionTitle(type),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_permissionService.getPermissionDescription(type)),
            // const SizedBox(height: 4),
            // Text(
            //   _permissionService.getPermissionStatusDescription(type, isGranted),
            //   style: TextStyle(
            //     color: isGranted ? Colors.green : Colors.orange,
            //     fontWeight: FontWeight.w500,
            //   ),
            // ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isGranted) ...[
              TextButton(
                onPressed: () => _requestPermission(type),
                child: const Text("请求"),
              ),
              const SizedBox(width: 8),
            ],
            TextButton(
              onPressed: () => _openPermissionSettings(type),
              child: const Text("设置"),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取权限图标
  IconData _getPermissionIcon(PermissionType type) {
    switch (type) {
      case PermissionType.location:
        return Icons.location_on;
      case PermissionType.locationAlways:
        return Icons.location_searching;
      case PermissionType.notification:
        return Icons.notifications;
      case PermissionType.battery:
        return Icons.battery_charging_full;
      case PermissionType.usage:
        return Icons.analytics;
    }
  }

  /// 获取权限标题
  String _getPermissionTitle(PermissionType type) {
    switch (type) {
      case PermissionType.location:
        return "位置权限";
      case PermissionType.locationAlways:
        return "后台位置权限";
      case PermissionType.notification:
        return "通知权限";
      case PermissionType.battery:
        return "电池优化";
      case PermissionType.usage:
        return "使用情况访问";
    }
  }
}
