# 友盟统计埋点 - 初始化文档

## 概述

友盟统计已集成到项目中，目前提供了基础的初始化和统计功能。

## 友盟配置信息

- **AppKey**: `6879fbe579267e0210b67be9`
- **已配置位置**: `android/app/build.gradle.kts`

## 初始化

### 在隐私合规管理器中初始化

友盟统计必须在用户同意隐私政策后才能初始化。建议在 `PrivacyComplianceManager` 中调用：

```dart
// lib/services/privacy_compliance_manager.dart

import 'package:kissu_app/utils/umeng_analytics_util.dart';

class PrivacyComplianceManager {
  // 用户同意隐私政策后调用
  Future<void> onUserAgreePrivacy() async {
    // ... 其他初始化代码 ...
    
    // 初始化友盟统计
    await UmengAnalytics.init(
      logEnabled: true, // 开发环境建议开启日志，生产环境设为false
    );
    
    // ... 其他初始化代码 ...
  }
}
```

### 初始化参数说明

```dart
await UmengAnalytics.init({
  String? appKey,        // 友盟AppKey，不传则使用默认配置的key
  String? channel,       // 渠道标识，默认为'Umeng'
  bool logEnabled,       // 是否开启日志，默认为false
});
```

## 可用的统计方法

### 1. 页面统计

```dart
// 页面开始
UmengAnalytics.pageStart('PageName');

// 页面结束（必须成对调用）
UmengAnalytics.pageEnd('PageName');
```

**使用示例（GetX）**:

```dart
class HomeController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    UmengAnalytics.pageStart('home_page');
  }
  
  @override
  void onClose() {
    UmengAnalytics.pageEnd('home_page');
    super.onClose();
  }
}
```

### 2. 事件统计

```dart
// 简单事件
UmengAnalytics.logEvent('event_name');

// 带参数的事件
UmengAnalytics.logEventWithParams('event_name', {
  'param1': 'value1',
  'param2': 'value2',
});

// 带数值的事件
UmengAnalytics.logEventWithValue('event_name', 100);

// 带参数和数值的事件
UmengAnalytics.logEventWithParamsAndValue('event_name', {
  'param1': 'value1',
}, 100);
```

### 3. 用户管理

```dart
// 登录时设置用户ID
await UmengAnalytics.setUserId('user_12345');

// 退出登录时清除用户ID
await UmengAnalytics.clearUserId();

// 设置用户属性
await UmengAnalytics.setUserProfile({
  'gender': 'male',
  'age': '25',
  'vip_level': '3',
});
```

### 4. 其他方法

```dart
// 手动触发数据上报（一般不需要手动调用）
await UmengAnalytics.flush();

// 设置Session统计
await UmengAnalytics.setSessionContinueMillis(enabled: true);

// 设置后台统计
await UmengAnalytics.setScenarioType(enabled: false);
```

## 注意事项

1. **必须先初始化**: 所有统计方法调用前必须先调用 `init()` 方法初始化
2. **隐私合规**: 必须在用户同意隐私政策后才能初始化
3. **页面统计**: `pageStart()` 和 `pageEnd()` 必须成对使用
4. **参数类型**: 事件参数的 key 和 value 都必须是 String 类型
5. **日志开关**: 生产环境建议关闭日志（`logEnabled: false`）

## Android 原生支持

友盟统计已在 Android 端完整实现，通过 MethodChannel 与 Flutter 通信。相关代码位于：

- **Flutter 侧**: `lib/utils/umeng_analytics_util.dart`
- **Android 侧**: `android/app/src/main/kotlin/com/yuluo/kissu/MainActivity.kt`

## 待完善

- [ ] 具体的事件ID定义（等待业务需求确定）
- [ ] 页面名称常量定义（等待业务需求确定）
- [ ] 实际使用示例（等待业务场景确定）

## 下一步

请提供需要统计的具体事件列表，包括：
- 事件ID（如：login、register、purchase等）
- 事件参数（如果有）
- 页面名称列表

我会据此创建对应的常量定义和使用示例。

