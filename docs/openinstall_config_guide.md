# OpenInstall 配置指南

## 概述

OpenInstall 是一个专业的移动应用推广和统计平台，支持渠道统计、携带参数安装、快速安装与一键拉起等功能。本指南将帮助您完成 OpenInstall 在 Flutter 项目中的完整配置。

## 一、准备工作

### 1. 注册 OpenInstall 账号
- 访问 [OpenInstall 控制台](https://developer.openinstall.io/)
- 注册账号并创建应用
- 获取应用的 `appkey` 和 `scheme`
- 获取 iOS 的关联域名（Associated Domains）

### 2. 获取配置信息
在 OpenInstall 控制台中，您需要获取以下信息：
- **Android AppKey**: 用于 Android 平台配置
- **iOS AppKey**: 用于 iOS 平台配置  
- **Scheme**: 用于应用间跳转
- **Associated Domains**: iOS 通用链接域名

## 二、Flutter 项目配置

### 1. 添加依赖

在 `pubspec.yaml` 文件中添加 OpenInstall 插件：

```yaml
dependencies:
  openinstall_flutter_plugin: ^2.5.4
```

### 2. 安装依赖

```bash
flutter pub get
```

## 三、Android 平台配置

### 1. 配置 AppKey

在 `android/app/build.gradle` 文件中添加 AppKey 配置：

```gradle
android {
    defaultConfig {
        // ... 其他配置
        manifestPlaceholders += [
            OPENINSTALL_APPKEY: "your_android_appkey_here"
        ]
    }
}
```

### 2. 配置 Scheme

在 `android/app/src/main/AndroidManifest.xml` 文件中添加 intent-filter：

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:theme="@style/LaunchTheme"
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
    android:hardwareAccelerated="true"
    android:windowSoftInputMode="adjustResize">
    
    <!-- 原有的 intent-filter -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>
    
    <!-- 添加 OpenInstall 的 intent-filter -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <data android:scheme="your_scheme_here"/>
    </intent-filter>
</activity>
```

### 3. 添加权限（可选）

如果需要广告平台统计功能，在 `AndroidManifest.xml` 中添加权限：

```xml
<uses-permission android:name="android.permission.READ_PHONE_STATE"/>
```

## 四、iOS 平台配置

### 1. 配置 AppKey

在 `ios/Runner/Info.plist` 文件中添加 AppKey：

```xml
<key>com.openinstall.APP_KEY</key>
<string>your_ios_appkey_here</string>
```

### 2. 配置 Associated Domains

#### 2.1 开启 Associated Domains 服务
- 访问 [苹果开发者网站](https://developer.apple.com/)
- 选择 Certificate, Identifiers & Profiles
- 选择相应的 AppID，开启 Associated Domains
- 更新相应的 mobileprovision 证书

#### 2.2 配置关联域名

在 `ios/Runner/Runner.entitlements` 文件中添加：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.associated-domains</key>
    <array>
        <string>applinks:your_domain.openinstall.io</string>
    </array>
</dict>
</plist>
```

### 3. 配置 Scheme

在 Xcode 中配置 URL Types：
- 打开 `ios/Runner.xcworkspace`
- 选择 Runner target
- 在 Info 标签页的 URL Types 中添加新的 URL Type
- 设置 Identifier 和 URL Schemes

### 4. 添加隐私权限（可选）

如果需要广告平台统计功能，在 `ios/Runner/Info.plist` 中添加：

```xml
<key>NSUserTrackingUsageDescription</key>
<string>为了您可以精准获取到优质推荐内容，需要您允许使用该权限</string>
```

## 五、代码集成

### 1. 初始化服务

在 `main.dart` 中初始化 OpenInstall：

```dart
import 'package:kissu_app/services/openinstall_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ... 其他初始化代码
  
  // 初始化 OpenInstall 服务
  try {
    await OpenInstallService.init();
    print('OpenInstall服务初始化完成');
  } catch (e) {
    print('OpenInstall服务初始化失败: $e');
  }
  
  runApp(MyApp());
}
```

### 2. 使用服务

```dart
import 'package:kissu_app/services/openinstall_service.dart';

class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  @override
  void initState() {
    super.initState();
    _initOpenInstall();
  }

  void _initOpenInstall() async {
    // 注册唤醒监听器
    OpenInstallService.registerWakeupHandler((params) {
      print('应用被唤醒，收到参数: $params');
      // 处理唤醒参数
    });

    // 获取安装参数
    final params = await OpenInstallService.getInstallParams();
    if (params != null) {
      print('安装参数: $params');
      // 处理安装参数
    }
  }

  void _reportRegister() async {
    // 用户注册时调用
    await OpenInstallService.reportRegister();
  }

  void _reportEffectPoint() async {
    // 上报效果点
    await OpenInstallService.reportEffectPoint(
      pointId: 'user_click',
      pointValue: 1,
    );
  }
}
```

## 六、高级配置

### 1. Android 广告平台配置

```dart
// 在初始化前配置
await OpenInstallService.configAndroid({
  'adEnabled': true,
  'oaid': 'your_oaid',
  'gaid': 'your_gaid',
  'imeiDisabled': false,
  'macDisabled': true,
});
```

### 2. iOS 广告平台配置

```dart
// 在初始化前配置
await OpenInstallService.configIos({
  'adEnable': true,
  'ASAEnable': true,
  'ASADebug': false, // 正式环境请设置为 false
  'idfaStr': 'your_idfa_string', // 可选
});
```

### 3. 权限处理

对于 Android 平台，如果需要 READ_PHONE_STATE 权限：

```dart
import 'package:permission_handler/permission_handler.dart';

// 请求权限
if (await Permission.phone.request().isGranted) {
  // 权限获取成功，可以初始化 OpenInstall
  await OpenInstallService.init();
} else {
  // 权限被拒绝，仍然需要初始化（OpenInstall 会使用其他标识）
  await OpenInstallService.init();
}
```

## 七、测试验证

### 1. 上传安装包

- 导出 Android APK 或 iOS IPA 包
- 上传到 OpenInstall 控制台进行集成检查

### 2. 在线测试

- 在 OpenInstall 控制台进行在线模拟测试
- 测试安装参数获取和唤醒功能

### 3. 真机测试

- 使用 OpenInstall 提供的测试链接进行真机测试
- 验证渠道统计和参数传递功能

## 八、常见问题

### 1. Android 平台问题

**问题**: 无法获取安装参数
**解决**: 检查 AppKey 配置和 intent-filter 设置

**问题**: 唤醒功能不工作
**解决**: 确认 scheme 配置正确，检查 MainActivity 的 launchMode

### 2. iOS 平台问题

**问题**: 通用链接不工作
**解决**: 检查 Associated Domains 配置和证书更新

**问题**: 权限弹窗不显示
**解决**: 将 configIos 和 init 方法放在应用进入前台时调用

### 3. 通用问题

**问题**: 初始化失败
**解决**: 检查网络连接和 AppKey 配置

**问题**: 参数获取为空
**解决**: 确认测试链接正确，检查超时设置

## 九、最佳实践

1. **初始化时机**: 在应用启动时尽早初始化 OpenInstall
2. **错误处理**: 对所有 OpenInstall 相关操作进行异常处理
3. **参数验证**: 对获取到的参数进行有效性验证
4. **调试模式**: 开发环境可以开启调试模式，生产环境关闭
5. **权限处理**: 合理处理权限请求，提供用户友好的说明

## 十、技术支持

- [OpenInstall 官方文档](https://www.openinstall.io/doc/)
- [Flutter 插件文档](https://pub.dev/packages/openinstall_flutter_plugin)
- [OpenInstall 控制台](https://developer.openinstall.io/)

---

**注意**: 本指南基于 OpenInstall Flutter Plugin 2.5.4 版本编写，不同版本可能存在差异，请参考官方最新文档。
