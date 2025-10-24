# 友盟统计集成文档

## 📋 概述

本文档描述了 Kissu App 中友盟统计的完整集成方案，包括 Android 原生端和 Flutter 端的实现。

## 🎯 集成方式

### 架构选择
采用 **MethodChannel** 方式集成友盟统计：
- **优点**：完全控制初始化时机、更好的隐私合规、灵活的配置
- **缺点**：需要编写原生代码（已完成）

### 主要组件

1. **Android 原生端**：`MainActivity.kt` - 处理友盟 SDK 的初始化和方法调用
2. **Flutter 端**：`UmengAnalytics` 工具类 - 提供统一的埋点 API
3. **隐私合规**：`PrivacyComplianceManager` - 确保在用户同意后初始化

## 📱 Android 端配置

### 1. 依赖配置 (`build.gradle.kts`)

```kotlin
dependencies {
    // 友盟统计 SDK
    implementation("com.umeng.umsdk:common:9.6.8")        // 必选，基础组件库
    implementation("com.umeng.umsdk:asms:1.8.3")          // 必选，统计SDK
}
```

### 2. AndroidManifest.xml 配置

```xml
<!-- 友盟统计配置 -->
<meta-data
    android:name="UMENG_APPKEY"
    android:value="674f7f5f7e09ea12cb5e4d1e" />
<meta-data
    android:name="UMENG_CHANNEL"
    android:value="default" />
```

### 3. 原生代码实现

在 `MainActivity.kt` 中实现的 MethodChannel 方法：

| 方法名 | 功能 | 参数 | 说明 |
|--------|------|------|------|
| `umeng_init` | 初始化友盟统计 | appKey, channel, logEnabled | 必须在用户同意隐私政策后调用 |
| `umeng_onEvent` | 记录自定义事件 | eventId, properties | 业务埋点核心方法 |
| `umeng_onPageStart` | 页面开始访问 | pageName | 配合 onPageEnd 使用 |
| `umeng_onPageEnd` | 页面结束访问 | pageName | 自动计算页面停留时长 |
| `umeng_setUserId` | 设置用户ID | userId | 登录时调用 |
| `umeng_clearUserId` | 清除用户ID | - | 退出登录时调用 |
| `umeng_setUserProfile` | 设置用户属性 | properties | ⚠️ 友盟不直接支持，仅占位 |
| `umeng_flush` | 手动上报数据 | - | 一般不需要手动调用 |

## 🎨 Flutter 端使用

### 工具类：`UmengAnalytics`

#### 初始化

```dart
// 在隐私政策同意后自动初始化（由 PrivacyComplianceManager 调用）
await UmengAnalytics.init(
  appKey: '674f7f5f7e09ea12cb5e4d1e',  // 可选，使用默认值
  channel: 'default',                   // 可选，使用默认值
  logEnabled: true,                     // 可选，debug模式启用日志
);
```

#### 事件埋点

```dart
// 简单事件（只有事件ID）
UmengAnalytics.onEvent('button_click');

// 带参数的事件（推荐）
UmengAnalytics.onEvent('purchase_completed', {
  'product_id': '12345',
  'amount': '99.99',
  'currency': 'CNY',
  'payment_method': 'alipay',
});
```

#### 页面统计

```dart
class MyPage extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    UmengAnalytics.onPageStart('MyPage');
  }

  @override
  void dispose() {
    UmengAnalytics.onPageEnd('MyPage');
    super.dispose();
  }
}
```

#### 用户标识

```dart
// 登录时设置用户ID
await UmengAnalytics.setUserId(userId);

// 退出登录时清除
await UmengAnalytics.clearUserId();
```

## 🔒 隐私合规

### 初始化时机

友盟统计的初始化严格遵循隐私合规要求：

1. **应用启动时**：不初始化友盟统计
2. **用户同意隐私政策后**：`PrivacyComplianceManager` 自动调用 `UmengAnalytics.init()`
3. **用户拒绝隐私政策**：友盟统计不会被初始化

### 实现代码

```dart
// privacy_compliance_manager.dart
Future<void> _enableUmengAnalytics() async {
  try {
    await UmengAnalytics.init();
    DebugUtil.success('友盟统计已初始化');
  } catch (e) {
    DebugUtil.error('初始化友盟统计失败: $e');
  }
}
```

## 📊 业务埋点规范

### 埋点命名规范

- **格式**：`模块_动作_对象`（全小写，单词用下划线分隔）
- **示例**：
  - `home_click_banner` - 首页点击banner
  - `track_view_detail` - 轨迹查看详情
  - `mine_edit_profile` - 我的页编辑资料

### 参数命名规范

- 使用有意义的参数名
- 值必须是字符串类型
- 关键业务参数要完整记录

### 示例

```dart
// ✅ 好的埋点
UmengAnalytics.onEvent('product_purchase', {
  'product_id': '12345',
  'product_name': 'VIP会员',
  'price': '99.00',
  'payment_method': 'alipay',
  'source_page': 'mine',
});

// ❌ 不好的埋点
UmengAnalytics.onEvent('click', {
  'type': '1',
  'data': 'xxx',
});
```

## 🚀 已完成的埋点

### 登录模块 (`login_controller.dart`)

```dart
// 登录成功埋点
UmengAnalytics.onEvent('user_login_success', {
  'login_method': 'sms_code',
  'user_id': loginResponse.userId.toString(),
  'user_type': 'normal',
});
UmengAnalytics.setUserId(loginResponse.userId.toString());

// 退出登录埋点
UmengAnalytics.onEvent('user_logout', {
  'user_id': currentUser?.userId.toString() ?? 'unknown',
  'logout_source': 'mine_page',
});
UmengAnalytics.clearUserId();
```

## 🛠️ 调试

### 启用日志

```dart
// 在 init 时启用调试日志
await UmengAnalytics.init(logEnabled: true);
```

### Android Logcat 查看

```bash
# 过滤友盟统计日志
adb logcat | grep "UmengAnalytics"
```

### 常见日志输出

```
D/UmengAnalytics: 友盟统计初始化成功
D/UmengAnalytics: 记录事件: user_login_success, 参数: {login_method=sms_code, user_id=12345}
D/UmengAnalytics: 页面访问开始: HomePage
D/UmengAnalytics: 页面访问结束: HomePage
D/UmengAnalytics: 设置用户ID: 12345
```

## ⚠️ 注意事项

### 1. 用户属性设置限制

友盟统计 Android SDK **不直接支持**自定义用户属性设置（`setUserProfile`）。如需记录用户属性，建议：

- 通过事件参数方式上报
- 或使用友盟的用户画像功能（需要单独集成）

### 2. 数据上报时机

- 友盟 SDK 会自动批量上报数据
- 一般无需手动调用 `flush()`
- 应用进入后台时会自动上报

### 3. 性能影响

- 友盟统计对性能影响很小
- 事件记录是异步的，不会阻塞主线程
- 建议在关键业务节点进行埋点

## 🔗 相关文档

- [友盟统计 Android SDK 文档](https://developer.umeng.com/docs/119267/detail/118584)
- [友盟统计初始化文档](./umeng_analytics_init.md)
- [业务埋点 CSV 文件](../埋点.csv)

## 📝 更新日志

- 2025-10-24: 完成友盟统计 Android 原生集成
- 2025-10-24: 添加 Flutter 工具类和隐私合规支持
- 2025-10-24: 完成登录模块埋点示例

