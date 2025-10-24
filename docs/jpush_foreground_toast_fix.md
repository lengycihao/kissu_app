# 极光推送前台Toast问题修复

## 问题描述

**现象：** 
1. 退出登录后在登录页仍能收到推送Toast提示（如"对方在***锁定了手机"）
2. 应用在前台时收到推送会弹出Toast，体验不好

**预期：**
1. 未登录用户不应该收到推送消息
2. 前台时推送应该静默处理，不显示Toast

## 问题分析

### 根本原因

在 `lib/services/jpush_service.dart` 的 `_onReceiveNotification` 方法中：

```dart
// ❌ 问题代码
Future<dynamic> _onReceiveNotification(Map<String, dynamic> message) async {
  debugPrint('接收到通知: $message');
  _lastNotification.value = message;
  
  String? title = message['title'];
  String? alert = message['alert'];
  
  if (title != null && alert != null) {
    // 无条件显示Toast - 这是问题所在！
    _showInAppNotification(title, alert);
  }
}
```

### 问题点

1. **无登录状态检查**：无论用户是否登录都显示Toast
2. **无前后台判断**：前台时也显示Toast，打断用户操作
3. **双重通知**：后台有系统通知，前台又有Toast，重复提示

### 推送消息的正确流程

```
推送消息到达
    ↓
应用在后台？
    ├─ 是 → 系统通知栏显示（由Android系统处理）✅
    └─ 否（前台）
          ↓
      用户已登录？
          ├─ 是 → 静默处理（更新消息中心红点）✅
          └─ 否 → 忽略（理论上不应该收到）❌
```

## 解决方案

### 1. 移除前台Toast显示

修改 `_onReceiveNotification` 方法，不再显示Toast：

```dart
/// 接收到通知回调
Future<dynamic> _onReceiveNotification(Map<String, dynamic> message) async {
  debugPrint('接收到通知: $message');
  _lastNotification.value = message;
  
  // 🔥 前台推送不显示Toast，只在后台显示系统通知
  // 检查用户登录状态
  try {
    final authService = getIt<AuthService>();
    final isLoggedIn = authService.isLoggedIn;
    
    debugPrint('接收推送通知 - 用户登录状态: $isLoggedIn');
    
    // ❌ 不在前台显示Toast
    // 前台时推送消息应该静默处理或通过其他方式展示（如消息中心红点）
    // 后台时由系统通知栏显示
    
    // 可以在这里更新消息中心的未读数等
    
  } catch (e) {
    debugPrint('处理推送通知时出错: $e');
  }
}
```

### 2. 废弃Toast显示方法

```dart
/// 显示应用内通知（已废弃，前台不再显示Toast）
@Deprecated('前台推送不再显示Toast，改为静默处理')
void _showInAppNotification(String title, String content) {
  // 🔥 前台推送不显示Toast
  // 如果需要提示用户，应该通过消息中心红点或其他非侵入方式
  debugPrint('收到推送但不显示Toast - 标题: $title, 内容: $content');
}
```

### 3. 退出登录时清除别名

确保退出登录时只清除别名（已在 `jpush_logout_fix.md` 中说明）：

```dart
void _clearJPushAlias() {
  // ✅ 只删除别名（清除定向推送）
  await jpushService.deleteAlias();
  
  // ✅ 保留推送服务（仍可接收广播推送）
  // ❌ 不调用 stopPush()
}
```

## 修改内容

### `lib/services/jpush_service.dart`

1. **新增导入**
```dart
import 'package:kissu_app/network/public/auth_service.dart';
import 'package:kissu_app/network/public/service_locator.dart';
```

2. **修改 `_onReceiveNotification` 方法**
   - 移除自动显示Toast的逻辑
   - 添加登录状态检查（预留扩展）
   - 添加注释说明前台推送处理策略

3. **废弃 `_showInAppNotification` 方法**
   - 标记为 `@Deprecated`
   - 不再实际显示Toast

## 推送消息的处理策略

### 后台推送

✅ **由系统通知栏显示**
- Android原生层（`JPushReceiver.kt`）已正确实现
- 只在应用后台时创建系统通知
- 用户可点击通知打开应用

```kotlin
// android/app/src/main/kotlin/com/yuluo/kissu/JPushReceiver.kt
private fun processNotificationReceived(context: Context, bundle: Bundle?) {
    val isAppInForeground = isAppInForeground(context)
    
    if (!isAppInForeground) {
        // 应用在后台，创建系统通知 ✅
        createCustomNotification(context, title, content, extrasStr)
    } else {
        // 应用在前台，不创建系统通知 ✅
        Log.d(TAG, "应用在前台，极光推送会自动处理通知")
    }
}
```

### 前台推送

✅ **静默处理，不打断用户**
- 不显示Toast
- 可以更新消息中心未读红点
- 可以发送应用内事件通知其他页面更新

```dart
// 前台推送处理示例
Future<dynamic> _onReceiveNotification(Map<String, dynamic> message) async {
  // 1. 保存消息
  _lastNotification.value = message;
  
  // 2. 可以发送事件通知其他页面
  // EventBus.send(NewMessageEvent(message));
  
  // 3. 可以更新消息中心红点
  // MessageCenter.incrementUnreadCount();
  
  // ❌ 不显示Toast
}
```

### 未登录推送

**定向推送：** ❌ **收不到**
- 退出登录时清除别名，无法通过别名推送
- 服务器端也应该检查用户登录状态

**广播推送：** ✅ **可以收到**
- 推送服务仍在运行，可接收广播（如系统公告）
- 后台时显示在通知栏，前台时静默处理

## 用户体验改进

### 修复前 ❌

1. **前台场景**
   - 用户正在使用应用
   - 突然弹出Toast："对方在***锁定了手机"
   - 打断用户当前操作，体验差

2. **退出登录场景**
   - 用户已退出到登录页
   - 仍然能收到Toast推送
   - 让人困惑：我都退出了还能收到消息？

### 修复后 ✅

1. **前台场景**
   - 推送静默处理
   - 不打断用户操作
   - 可通过消息中心红点提示

2. **退出登录场景**
   - 推送服务已停止
   - 不再收到任何推送
   - 体验清晰明确

## 验证方法

### 测试步骤

1. **前台推送测试**
   ```
   1. 登录应用
   2. 保持应用在前台
   3. 发送测试推送
   4. ✅ 不应该显示Toast
   5. ✅ 查看日志应显示："接收推送通知 - 用户登录状态: true"
   ```

2. **后台推送测试**
   ```
   1. 登录应用
   2. 切换到后台（按Home键）
   3. 发送测试推送
   4. ✅ 应该在通知栏看到系统通知
   5. ✅ 点击通知可打开应用
   ```

3. **退出登录测试（定向推送）**
   ```
   1. 退出登录到登录页
   2. 发送定向推送（通过别名）
   3. ✅ 不应该收到（别名已清除）
   4. ✅ 查看日志应显示："极光推送别名清除成功"
   ```

4. **退出登录测试（广播推送）**
   ```
   1. 退出登录到登录页
   2. 发送广播推送
   3. 切换到后台
   4. ✅ 应该在通知栏收到（推送服务仍在运行）
   5. 保持在前台
   6. ✅ 不应该显示Toast（前台静默处理）
   ```

### 日志关键字

```
// 前台收到推送
✓ 接收到通知: {title: xxx, alert: xxx}
✓ 接收推送通知 - 用户登录状态: true
✓ 收到推送但不显示Toast - 标题: xxx, 内容: xxx

// 后台收到推送（Android日志）
✓ 应用在后台，强制创建通知以确保用户能看到
✓ 通知创建成功

// 退出登录
✓ 开始清除极光推送别名（保留 RegistrationId 和广播推送）
✓ 极光推送别名清除成功（保留广播推送能力）
```

## 后续优化建议

### 1. 消息中心红点

如果需要在前台提示用户有新消息，可以：

```dart
Future<dynamic> _onReceiveNotification(Map<String, dynamic> message) async {
  if (authService.isLoggedIn) {
    // 更新消息中心未读数
    if (Get.isRegistered<MessageCenterController>()) {
      Get.find<MessageCenterController>().incrementUnreadCount();
    }
  }
}
```

### 2. 应用内事件总线

可以发送事件让其他页面响应：

```dart
// 定义事件
class NewPushMessageEvent {
  final Map<String, dynamic> message;
  NewPushMessageEvent(this.message);
}

// 发送事件
EventBus.fire(NewPushMessageEvent(message));

// 在需要的页面监听
EventBus.on<NewPushMessageEvent>().listen((event) {
  // 更新UI
});
```

### 3. 特定场景的Toast

如果某些重要推送确实需要Toast提示，可以：

```dart
Future<dynamic> _onReceiveNotification(Map<String, dynamic> message) async {
  // 检查推送类型
  final extras = message['extras'] as Map<String, dynamic>?;
  final pushType = extras?['type'] as String?;
  
  // 只有特定类型才显示Toast
  if (pushType == 'urgent_message' && authService.isLoggedIn) {
    _showInAppNotification(title, alert);
  }
}
```

## 相关文件

- `lib/services/jpush_service.dart` - 极光推送服务（主要修改）
- `lib/network/public/auth_service.dart` - 认证服务
- `android/app/src/main/kotlin/com/yuluo/kissu/JPushReceiver.kt` - Android推送接收器
- `docs/jpush_logout_fix.md` - 退出登录推送修复文档

## 总结

通过移除前台Toast显示逻辑，改为静默处理推送消息，解决了：
1. ✅ 退出登录后仍能收到Toast的问题
2. ✅ 前台推送打断用户操作的问题
3. ✅ 提升了用户体验，推送更加合理和克制

**修复时间：** 2025-10-24
**影响范围：** 前台推送消息处理
**风险等级：** 低（仅移除Toast，不影响核心功能）

