# 弹窗使用示例

## 快速参考指南

这是新增三个弹窗在实际业务场景中的使用示例。

---

## 1. 删除位置提醒弹窗

### 使用场景
当用户尝试删除位置提醒记录时，显示此弹窗进行二次确认。

### 导入
```dart
import 'package:kissu_app/widgets/dialogs/delete_location_reminder_dialog.dart';
```

### 完整示例
```dart
// 在位置提醒列表页面中
class LocationReminderPage extends StatelessWidget {
  
  Future<void> _handleDeleteReminder(String reminderId) async {
    // 显示确认弹窗
    final result = await DeleteLocationReminderDialogUtil.show(
      onConfirm: () {
        print('用户确认删除位置提醒');
      },
      onCancel: () {
        print('用户取消删除');
      },
    );
    
    // 根据用户选择执行操作
    if (result == true) {
      // 用户点击了"确认"按钮
      try {
        // 调用删除API
        await LocationReminderService.deleteReminder(reminderId);
        
        // 显示成功提示
        OKToastUtil.show('删除成功');
        
        // 刷新列表
        _refreshList();
      } catch (e) {
        OKToastUtil.showError('删除失败: $e');
      }
    } else {
      // 用户点击了"取消"按钮或关闭了弹窗
      print('用户取消了删除操作');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('位置提醒 $index'),
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _handleDeleteReminder('reminder_$index'),
          ),
        );
      },
    );
  }
}
```

---

## 2. 检查对方位置权限弹窗

### 使用场景
当检测到对方未开通位置权限时，提示用户告知对方开启权限。

### 导入
```dart
import 'package:kissu_app/widgets/dialogs/partner_location_permission_dialog.dart';
```

### 完整示例
```dart
// 在位置监控页面中
class LocationMonitorController extends GetxController {
  
  Future<void> checkPartnerLocationPermission() async {
    try {
      // 调用API检查对方的位置权限状态
      final hasPermission = await LocationService.checkPartnerLocationPermission();
      
      if (!hasPermission) {
        // 对方没有开启位置权限，显示提示弹窗
        await PartnerLocationPermissionDialogUtil.show(
          onConfirm: () {
            print('用户已知道对方未开通位置权限');
            
            // 可以在这里记录用户已查看提示
            _recordUserViewed('partner_location_permission_tip');
          },
        );
      } else {
        // 对方已开启位置权限，继续正常业务
        _loadPartnerLocation();
      }
    } catch (e) {
      print('检查对方位置权限失败: $e');
    }
  }
  
  @override
  void onInit() {
    super.onInit();
    // 页面加载时检查对方权限
    checkPartnerLocationPermission();
  }
}

// 在位置监控页面 UI 中
class LocationMonitorPage extends GetView<LocationMonitorController> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('位置监控')),
      body: Center(
        child: Column(
          children: [
            Text('对方位置监控'),
            
            // 手动检查按钮
            ElevatedButton(
              onPressed: controller.checkPartnerLocationPermission,
              child: Text('检查对方权限'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 自动检查场景
```dart
// 在应用启动或特定时机自动检查
class AppInitializer {
  
  static Future<void> autoCheckPermissions() async {
    // 只在用户已绑定另一半时检查
    if (UserManager.isBound) {
      // 延迟执行，避免影响启动速度
      await Future.delayed(Duration(seconds: 2));
      
      final hasPermission = await LocationService.checkPartnerLocationPermission();
      
      if (!hasPermission) {
        // 显示提示（可以设置每天只提示一次）
        final lastShownDate = await StorageService.getLastShownDate('partner_permission_tip');
        final today = DateTime.now().toString().substring(0, 10);
        
        if (lastShownDate != today) {
          await PartnerLocationPermissionDialogUtil.show();
          await StorageService.setLastShownDate('partner_permission_tip', today);
        }
      }
    }
  }
}
```

---

## 3. 自己未开通通知权限弹窗

### 使用场景
当检测到用户未开通通知权限时，引导用户开启通知。

### 导入
```dart
import 'package:kissu_app/widgets/dialogs/self_notification_permission_dialog.dart';
```

### 完整示例
```dart
// 在位置提醒设置页面中
class LocationReminderSettingController extends GetxController {
  final PermissionService _permissionService = PermissionService();
  
  Future<void> enableLocationReminder() async {
    // 先检查通知权限
    final hasNotificationPermission = await _permissionService.isNotificationGranted();
    
    if (!hasNotificationPermission) {
      // 显示提示弹窗
      final result = await SelfNotificationPermissionDialogUtil.show(
        onKnow: () {
          print('用户选择稍后开启');
          OKToastUtil.show('建议开启通知权限以接收位置提醒');
        },
        onGoSettings: () {
          print('用户选择去设置页面开启');
          // 这里会自动跳转到系统设置
        },
      );
      
      if (result == true) {
        // 用户点击了"去开启"
        print('用户已跳转到设置页面');
        
        // 可以延迟检查权限状态
        Future.delayed(Duration(seconds: 2), () async {
          final granted = await _permissionService.isNotificationGranted();
          if (granted) {
            OKToastUtil.show('通知权限已开启');
            _enableReminderFeature();
          }
        });
      } else {
        // 用户点击了"知道了"或关闭了弹窗
        print('用户暂时不开启通知权限');
      }
    } else {
      // 已有通知权限，直接开启功能
      _enableReminderFeature();
    }
  }
  
  void _enableReminderFeature() {
    // 开启位置提醒功能
    print('位置提醒功能已开启');
  }
}

// 在页面 UI 中
class LocationReminderSettingPage extends GetView<LocationReminderSettingController> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('位置提醒设置')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: Text('开启位置提醒'),
              subtitle: Text('当Ta到达或离开指定位置时通知你'),
              value: controller.isReminderEnabled.value,
              onChanged: (value) {
                if (value) {
                  controller.enableLocationReminder();
                } else {
                  controller.disableLocationReminder();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

### 应用启动时检查
```dart
// 在应用主控制器中
class MainController extends GetxController {
  final PermissionService _permissionService = PermissionService();
  
  @override
  void onInit() {
    super.onInit();
    _checkNotificationPermission();
  }
  
  Future<void> _checkNotificationPermission() async {
    // 延迟检查，避免影响启动速度
    await Future.delayed(Duration(seconds: 3));
    
    // 检查是否已经提示过（每周提示一次）
    final lastCheck = await StorageService.getInt('notification_permission_check_time');
    final now = DateTime.now().millisecondsSinceEpoch;
    final oneWeek = 7 * 24 * 60 * 60 * 1000;
    
    if (lastCheck == null || (now - lastCheck) > oneWeek) {
      final hasPermission = await _permissionService.isNotificationGranted();
      
      if (!hasPermission && UserManager.isBound) {
        // 用户已绑定但未开启通知，显示提示
        await SelfNotificationPermissionDialogUtil.show();
        await StorageService.setInt('notification_permission_check_time', now);
      }
    }
  }
}
```

### 在系统权限页面中使用
```dart
// 系统权限页面已有通知权限检查，可以在用户未授权时显示弹窗
class SystemPermissionController extends GetxController {
  
  Future<void> onNotificationPermissionTap() async {
    final isGranted = isNotificationGranted.value;
    
    if (!isGranted) {
      // 显示友好的引导弹窗
      final result = await SelfNotificationPermissionDialogUtil.show();
      
      if (result == true) {
        // 用户已跳转到设置，等待返回后重新检查
        print('等待用户从设置返回');
      }
    }
  }
}
```

---

## 组合使用示例

### 场景：创建位置提醒功能
```dart
class CreateLocationReminderController extends GetxController {
  final PermissionService _permissionService = PermissionService();
  
  Future<void> createReminder() async {
    // 1. 先检查自己的通知权限
    final hasNotification = await _permissionService.isNotificationGranted();
    if (!hasNotification) {
      final result = await SelfNotificationPermissionDialogUtil.show();
      if (result != true) {
        // 用户没有选择去开启，提示并返回
        OKToastUtil.show('需要开启通知权限才能使用位置提醒功能');
        return;
      }
    }
    
    // 2. 检查对方的位置权限
    final partnerHasLocation = await LocationService.checkPartnerLocationPermission();
    if (!partnerHasLocation) {
      await PartnerLocationPermissionDialogUtil.show();
      // 提示后继续，因为对方可能稍后开启
    }
    
    // 3. 创建位置提醒
    try {
      await LocationReminderService.createReminder(/* 参数 */);
      OKToastUtil.show('位置提醒创建成功');
      Get.back();
    } catch (e) {
      OKToastUtil.showError('创建失败: $e');
    }
  }
  
  Future<void> deleteReminder(String id) async {
    // 删除时使用删除确认弹窗
    final result = await DeleteLocationReminderDialogUtil.show();
    
    if (result == true) {
      try {
        await LocationReminderService.deleteReminder(id);
        OKToastUtil.show('删除成功');
        _refreshList();
      } catch (e) {
        OKToastUtil.showError('删除失败: $e');
      }
    }
  }
}
```

---

## 最佳实践

### 1. 避免频繁弹窗
```dart
// 使用本地存储记录弹窗显示次数和时间
class DialogFrequencyController {
  static const String _keyPrefix = 'dialog_shown_';
  
  // 检查是否应该显示弹窗（每天最多一次）
  static Future<bool> shouldShowDialog(String dialogId) async {
    final key = '$_keyPrefix$dialogId';
    final lastShown = await StorageService.getString(key);
    final today = DateTime.now().toString().substring(0, 10);
    
    return lastShown != today;
  }
  
  // 记录弹窗已显示
  static Future<void> markDialogShown(String dialogId) async {
    final key = '$_keyPrefix$dialogId';
    final today = DateTime.now().toString().substring(0, 10);
    await StorageService.setString(key, today);
  }
}

// 使用示例
Future<void> checkAndShowDialog() async {
  if (await DialogFrequencyController.shouldShowDialog('partner_location')) {
    await PartnerLocationPermissionDialogUtil.show();
    await DialogFrequencyController.markDialogShown('partner_location');
  }
}
```

### 2. 处理应用从后台返回
```dart
class AppLifecycleController extends GetxController with WidgetsBindingObserver {
  bool _isWaitingForPermission = false;
  
  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isWaitingForPermission) {
      // 从设置返回，重新检查权限
      _recheckPermission();
      _isWaitingForPermission = false;
    }
  }
  
  Future<void> showNotificationDialog() async {
    final result = await SelfNotificationPermissionDialogUtil.show();
    
    if (result == true) {
      // 用户选择去设置
      _isWaitingForPermission = true;
    }
  }
  
  Future<void> _recheckPermission() async {
    final hasPermission = await PermissionService().isNotificationGranted();
    if (hasPermission) {
      OKToastUtil.show('通知权限已开启');
    } else {
      OKToastUtil.show('通知权限未开启');
    }
  }
}
```

### 3. 链式弹窗
```dart
// 按顺序检查多个条件
Future<void> checkAllConditions() async {
  // 第一步：检查自己的通知权限
  final hasNotification = await PermissionService().isNotificationGranted();
  if (!hasNotification) {
    final result = await SelfNotificationPermissionDialogUtil.show();
    if (result != true) {
      return; // 用户拒绝，终止流程
    }
  }
  
  // 第二步：检查对方的位置权限
  final partnerHasLocation = await LocationService.checkPartnerLocationPermission();
  if (!partnerHasLocation) {
    await PartnerLocationPermissionDialogUtil.show();
    // 不阻断流程，继续下一步
  }
  
  // 第三步：执行主要业务逻辑
  await _performMainAction();
}
```

---

## 注意事项

1. **删除弹窗** 应该在真正执行删除操作之前显示，而不是之后
2. **权限弹窗** 应该在检测到权限缺失时立即显示，或在用户尝试使用需要权限的功能时显示
3. **通知权限弹窗** 的"去开启"按钮会使应用进入后台，需要正确处理应用生命周期
4. 避免在短时间内重复显示同一个弹窗
5. 考虑用户体验，不要在应用启动时立即显示弹窗

---

## 测试建议

1. 测试弹窗在不同场景下的表现（有网络/无网络）
2. 测试从设置返回应用后的状态恢复
3. 测试快速点击按钮是否会导致重复操作
4. 测试弹窗在不同屏幕尺寸下的显示效果
5. 测试弹窗的关闭方式（点击外部、关闭按钮、确认按钮）

---

## 更新日期
2025-10-11

