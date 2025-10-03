# 修复息屏后定位失败问题

## 问题描述

用户反馈：手机息屏一会后出现定位失败错误：

```
W/System.err: java.lang.SecurityException: listen
I/flutter: ❌ 高德定位失败 - 错误码: 13, 错误信息: 网络定位失败，请检查设备是否插入sim卡，是否开启移动网络或开启了wifi模块
错误详细信息:获取到的基站和WIFI信息均为空，请检查是否授予APP定位权限或后台运行没有后台定位权限
```

## 根本原因分析

### 1. 缺少关键权限
高德SDK进行网络定位（基站+WIFI）需要以下权限：
- `ACCESS_WIFI_STATE`: 获取WIFI状态信息
- `READ_PHONE_STATE`: 获取基站信息

**原因**：AndroidManifest.xml中缺少这两个权限声明

### 2. 前台服务启动时机问题
原代码逻辑：
- 定位服务启动时：不启动前台服务
- 应用进入后台时：才启动前台服务

**问题**：如果用户在应用前台时就息屏，前台服务还没有启动，导致系统限制访问位置信息

### 3. Android系统限制
Android 10+系统对后台应用访问位置信息有严格限制：
- 息屏后，系统会限制非前台服务应用访问GPS、WIFI、基站信息
- 没有前台服务保护的应用，会在息屏后几分钟内被限制位置访问

## 解决方案

### 1. 添加缺失的权限（✅ 已完成）

**文件**: `android/app/src/main/AndroidManifest.xml`

```xml
<!-- WiFi状态权限：用于获取WIFI信息进行网络定位（高德SDK必需） -->
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />

<!-- 手机状态权限：用于获取基站信息进行网络定位（高德SDK必需） -->
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
```

### 2. 修改前台服务启动时机（✅ 已完成）

**文件**: `lib/services/simple_location_service.dart`

**修改前**：
```dart
// 只在进入后台时才启动前台服务
_smartStartLocationStrategy();
```

**修改后**：
```dart
// 立即启动前台服务，确保息屏后能继续定位
debugPrint('🚀 立即启动前台服务以支持息屏后定位...');
await _enableForegroundServiceIfNeeded();

// 根据应用状态智能决定是否启动后台定时器
_smartStartLocationStrategy();
```

### 3. 添加配置说明（✅ 已完成）

在定位参数配置中添加了关于后台定位限制的说明：

```dart
// 🔥 重要：Hight_Accuracy模式在后台和息屏时会自动降级为基站+WIFI定位
// 这是Android系统的限制，无法通过配置完全避免
locationOption.locationMode = AMapLocationMode.Hight_Accuracy;

debugPrint('   - ⚠️  息屏后限制：Android系统会限制GPS访问，自动降级为基站+WIFI定位');
```

## 技术原理说明

### 为什么需要这些权限？

1. **ACCESS_WIFI_STATE**:
   - 允许应用获取WIFI扫描结果
   - 高德SDK通过WIFI AP信息进行位置定位
   - 息屏后，这是主要的定位数据源之一

2. **READ_PHONE_STATE**:
   - 允许应用获取基站信息（Cell Tower）
   - 高德SDK通过基站三角定位计算位置
   - 在无WIFI环境下的主要定位方式

### 为什么需要前台服务？

Android 8.0+系统对后台应用的行为有严格限制：

1. **后台位置访问限制**:
   - 息屏后，系统会限制后台应用访问位置API
   - 前台服务可以绕过这些限制

2. **进程保活**:
   - 前台服务会提高应用进程优先级
   - 防止应用在息屏后被系统杀死

3. **用户知情权**:
   - 前台服务会显示持续通知
   - 让用户知道应用正在后台运行

### 息屏后的定位能力变化

| 状态 | GPS | WIFI | 基站 | 定位精度 |
|------|-----|------|------|---------|
| 屏幕亮起（前台） | ✅ 全功能 | ✅ 全功能 | ✅ 全功能 | 5-20米 |
| 屏幕亮起（后台） | ✅ 全功能 | ✅ 全功能 | ✅ 全功能 | 5-20米 |
| 息屏（有前台服务） | ⚠️ 受限 | ✅ 有限 | ✅ 正常 | 50-500米 |
| 息屏（无前台服务） | ❌ 无法访问 | ❌ 快速受限 | ❌ 快速受限 | 定位失败 |

**说明**：
- ✅ 全功能：正常访问，高频率更新
- ⚠️ 受限：可以访问，但频率降低
- ❌ 无法访问：系统阻止访问，定位失败

## 预期效果

修复后的行为：

1. **应用启动定位时**：
   - ✅ 立即启动前台服务
   - ✅ 显示"Kissu - 情侣定位"通知
   - ✅ 配置高德SDK使用高精度模式

2. **用户息屏后**：
   - ✅ 前台服务保持运行
   - ✅ 可以访问WIFI和基站信息
   - ✅ 继续进行网络定位（精度降低但可用）
   - ⚠️ GPS信号受限（系统限制）

3. **定位精度预期**：
   - 屏幕亮起：5-20米（GPS+网络）
   - 息屏状态：50-500米（网络定位）
   - ⚠️ 这是Android系统的正常行为，无法完全避免

## 测试验证

### 测试步骤

1. **编译并安装应用**：
   ```bash
   flutter clean
   flutter build apk --release
   ```

2. **测试息屏定位**：
   - 打开应用，进入定位页面
   - 等待定位成功（看到位置标记）
   - 息屏等待3-5分钟
   - 亮屏查看定位是否继续更新

3. **检查前台服务通知**：
   - 下拉通知栏
   - 应该看到"Kissu - 情侣定位"持续通知
   - 通知内容显示"正在后台为您提供位置定位服务"

### 预期结果

- ✅ 息屏后不再出现错误码13
- ✅ 前台服务通知持续显示
- ✅ 定位数据继续更新（可能精度降低）
- ✅ 不再出现"基站和WIFI信息均为空"错误

## 注意事项

### 1. 权限申请

`READ_PHONE_STATE`是危险权限，但对于定位功能：
- Android 10以下：高德SDK自动处理
- Android 10+：主要用于基站定位辅助
- 不需要显式在代码中申请（由系统和SDK处理）

### 2. 用户体验

前台服务会显示持续通知：
- ✅ 符合Android系统规范
- ✅ 让用户知情应用在后台运行
- ⚠️ 用户可能误以为是耗电提醒

### 3. 电量消耗

息屏定位会增加电量消耗：
- 前台服务：轻微影响
- 网络定位：中等影响
- GPS定位：显著影响（但息屏时系统会自动限制）

### 4. 不同厂商的差异

不同手机厂商的后台策略不同：
- **小米/OPPO/VIVO**: 后台限制较严格，可能需要用户手动设置"允许后台运行"
- **华为/荣耀**: 需要在"应用启动管理"中允许自动启动
- **三星/谷歌**: 系统限制较宽松，通常工作正常

## 相关链接

- [高德定位SDK错误码说明](https://lbs.amap.com/api/android-location-sdk/guide/utilities/errorcode/)
- [Android后台位置访问限制](https://developer.android.com/about/versions/10/privacy/changes#background-location)
- [前台服务最佳实践](https://developer.android.com/develop/background-work/services/foreground-services)

## 修改历史

- 2025-10-03: 初次修复 - 添加缺失权限和修改前台服务启动时机

