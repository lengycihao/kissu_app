# 📊 Android 屏幕使用时长功能实现说明

## 功能概述

本项目已成功集成 Android 端的屏幕使用时长统计功能，可以获取以下数据：

- ✅ 今日屏幕使用总时长
- ✅ 指定日期范围的使用时长
- ✅ 应用使用详情（按使用时长排序）
- ✅ 今日解锁次数统计
- ✅ 过去N天的每日使用数据

---

## 技术实现方案

### 📦 使用的插件

**`usage_stats: ^1.3.1`**

- 专门用于获取 Android 设备的应用使用统计
- 提供权限检查和请求功能
- 支持查询使用时长和事件记录

---

## 实现步骤详解

### 1️⃣ 添加依赖

**文件：** `pubspec.yaml`

```yaml
dependencies:
  usage_stats: ^1.3.1  # 屏幕使用时长统计
```

### 2️⃣ 添加权限声明

**文件：** `android/app/src/main/AndroidManifest.xml`

```xml
<!-- 使用情况访问权限：用于获取应用使用时长统计（需用户手动授权） -->
<uses-permission android:name="android.permission.PACKAGE_USAGE_STATS" tools:ignore="ProtectedPermissions" />
```

**注意：** 这是一个特殊权限，无法通过弹窗直接申请，必须引导用户到系统设置页面手动授权。

### 3️⃣ 扩展权限服务

**文件：** `lib/services/permission_service.dart`

新增功能：
- `isUsageAccessGranted()` - 检查权限状态
- `requestUsageAccessPermission()` - 请求权限（跳转到系统设置）

```dart
/// 检查使用情况访问权限状态
Future<bool> isUsageAccessGranted() async {
  if (Platform.isAndroid) {
    try {
      final bool granted = await UsageStats.checkUsagePermission() ?? false;
      return granted;
    } catch (e) {
      print("检查使用情况访问权限时发生错误: $e");
      return false;
    }
  }
  return true;
}

/// 请求使用情况访问权限
Future<bool> requestUsageAccessPermission() async {
  if (Platform.isAndroid) {
    // 跳转到系统设置
    await openUsageAccessSettings();
    // 等待后再次检查
    await Future.delayed(const Duration(milliseconds: 500));
    return await isUsageAccessGranted();
  }
  return true;
}
```

### 4️⃣ 创建屏幕使用服务

**文件：** `lib/services/screen_usage_service.dart`

提供的主要 API：

```dart
// 获取今日屏幕使用总时长（毫秒）
Future<int> getTodayScreenTime()

// 获取指定日期范围的屏幕使用时长
Future<int> getScreenTimeByDateRange(DateTime startDate, DateTime endDate)

// 获取今日应用使用详情（按使用时长排序，可限制返回数量）
Future<List<ScreenUsageData>> getTodayAppUsageStats({int? limit})

// 获取过去N天的每日屏幕使用时长
Future<Map<String, int>> getScreenTimeByDays(int days)

// 获取今日解锁次数
Future<int> getTodayUnlockCount()

// 检查是否有权限
Future<bool> hasPermission()

// 请求权限（跳转到系统设置）
Future<void> requestPermission()
```

### 5️⃣ 集成到用机报告页面

**文件：** `lib/pages/usage_report/usage_report_controller.dart`

在页面初始化时自动检查权限：

```dart
@override
void onInit() {
  super.onInit();
  // ...
  _checkAndRequestPermission();
}

Future<void> _checkAndRequestPermission() async {
  final bool isGranted = await _permissionService.isUsageAccessGranted();
  
  if (isGranted) {
    // 有权限，加载数据
    loadData();
  } else {
    // 无权限，显示引导弹窗
    _showPermissionDialog();
  }
}
```

### 6️⃣ 添加测试入口

**文件：** `lib/pages/mine/mine_controller.dart`

在"我的"页面添加了"屏幕使用测试"入口，点击后会：

1. 检查权限状态
2. 如果未授权，显示引导弹窗并跳转到系统设置
3. 如果已授权，获取并显示以下数据：
   - 今日屏幕使用总时长
   - 今日解锁次数
   - 应用使用排行 TOP 5
4. 提供"查看详情"按钮跳转到完整的用机报告页面

---

## 使用方法

### 在代码中使用

```dart
import 'package:kissu_app/services/screen_usage_service.dart';
import 'package:kissu_app/services/permission_service.dart';

// 1. 检查权限
final permissionService = PermissionService();
final hasPermission = await permissionService.isUsageAccessGranted();

if (!hasPermission) {
  // 请求权限（会跳转到系统设置）
  await permissionService.requestUsageAccessPermission();
}

// 2. 获取屏幕使用数据
final screenUsageService = ScreenUsageService();

// 获取今日使用时长（毫秒）
final todayMs = await screenUsageService.getTodayScreenTime();
final todayMinutes = (todayMs / (1000 * 60)).round();

// 获取应用使用详情（前10个）
final appStats = await screenUsageService.getTodayAppUsageStats(limit: 10);

for (var stat in appStats) {
  print('应用: ${stat.packageName}');
  print('使用时长: ${stat.formattedUsageTime}');
}

// 获取过去7天的使用数据
final weekData = await screenUsageService.getScreenTimeByDays(7);
weekData.forEach((date, timeMs) {
  final minutes = (timeMs / (1000 * 60)).round();
  print('$date: $minutes 分钟');
});
```

### 测试步骤

1. 运行应用
2. 进入"我的"页面
3. 点击"屏幕使用测试"
4. 首次点击会提示授权，点击"去授权"
5. 在系统设置中找到 Kissu 应用，开启"使用情况访问权限"
6. 返回应用，再次点击"屏幕使用测试"
7. 查看统计数据

---

## 权限申请流程

```
用户点击功能
    ↓
检查权限状态
    ↓
┌─────────────────┐
│   是否已授权？   │
└─────────────────┘
    ↓           ↓
   是          否
    ↓           ↓
显示数据    显示引导弹窗
              ↓
         用户点击"去授权"
              ↓
      跳转到系统设置页面
              ↓
      用户手动开启权限
              ↓
         返回应用
              ↓
       再次检查权限
              ↓
         显示数据
```

---

## 注意事项

### ⚠️ 权限特殊性

`PACKAGE_USAGE_STATS` 是 Android 的特殊权限（Protected Permission），特点：

1. **无法通过弹窗直接申请** - 必须跳转到系统设置页面
2. **需要用户手动授权** - 在设置中找到应用并开启
3. **敏感权限** - 部分厂商可能限制使用
4. **仅 Android 支持** - iOS 没有对应功能

### 📱 兼容性说明

- **最低版本：** Android 5.0 (API 21)
- **推荐版本：** Android 6.0+ (API 23+)
- **测试设备：** 建议在真机上测试（模拟器可能无法正常获取数据）

### 🔍 可能遇到的问题

#### 1. 获取不到数据

**原因：**
- 权限未授予
- 系统禁用了使用统计功能
- 模拟器环境限制

**解决：**
- 检查权限状态
- 在真机上测试
- 确认系统版本 >= Android 5.0

#### 2. 数据不准确

**原因：**
- 系统缓存延迟
- 不同厂商实现差异
- 时区问题

**解决：**
- 使用真实设备长时间测试
- 考虑添加数据校准机制

#### 3. 权限被拒绝后无法再次申请

**解决：**
- 提供"去设置"按钮，引导用户手动开启
- 已在代码中实现跳转功能

---

## 数据模型

### ScreenUsageData

```dart
class ScreenUsageData {
  final String packageName;          // 应用包名
  final String appName;               // 应用名称
  final int totalTimeInForeground;    // 前台使用时长（毫秒）
  final DateTime firstTimeStamp;      // 首次使用时间
  final DateTime lastTimeStamp;       // 最后使用时间
  final int lastTimeUsed;             // 最后使用时长（毫秒）
  
  // 便捷属性
  double get usageHours;              // 使用时长（小时）
  double get usageMinutes;            // 使用时长（分钟）
  String get formattedUsageTime;      // 格式化时长（如：2小时30分钟）
}
```

---

## API 文档

### ScreenUsageService API

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `getTodayScreenTime()` | - | `Future<int>` | 获取今日总使用时长（毫秒） |
| `getScreenTimeByDateRange()` | `DateTime startDate, DateTime endDate` | `Future<int>` | 获取指定日期范围使用时长 |
| `getTodayAppUsageStats()` | `int? limit` | `Future<List<ScreenUsageData>>` | 获取今日应用使用详情 |
| `getAppUsageStatsByDateRange()` | `DateTime startDate, DateTime endDate, int? limit` | `Future<List<ScreenUsageData>>` | 获取指定日期范围应用使用详情 |
| `getScreenTimeByDays()` | `int days` | `Future<Map<String, int>>` | 获取过去N天的每日使用数据 |
| `getTodayUnlockCount()` | - | `Future<int>` | 获取今日解锁次数 |
| `hasPermission()` | - | `Future<bool>` | 检查是否有权限 |
| `requestPermission()` | - | `Future<void>` | 请求权限（跳转设置） |

### PermissionService API（新增）

| 方法 | 返回值 | 说明 |
|------|--------|------|
| `isUsageAccessGranted()` | `Future<bool>` | 检查使用统计权限状态 |
| `requestUsageAccessPermission()` | `Future<bool>` | 请求使用统计权限 |

---

## 文件清单

### 新增文件

1. ✅ `lib/services/screen_usage_service.dart` - 屏幕使用服务
2. ✅ `lib/pages/usage_report/widgets/screen_time_detail_controller.dart` - 屏幕使用详情控制器

### 修改文件

1. ✅ `pubspec.yaml` - 添加 usage_stats 依赖
2. ✅ `android/app/src/main/AndroidManifest.xml` - 添加权限声明
3. ✅ `lib/services/permission_service.dart` - 扩展权限检查和申请
4. ✅ `lib/pages/usage_report/usage_report_controller.dart` - 添加权限检查逻辑
5. ✅ `lib/pages/mine/mine_controller.dart` - 添加测试入口
6. ✅ `lib/models/screen_time_model.dart` - 扩展数据模型

---

## 下一步优化建议

### 🚀 功能扩展

1. **每小时使用数据统计** - 通过 queryEvents 实现更细粒度的统计
2. **应用分类统计** - 按应用类型（社交、游戏、工具等）分类统计
3. **使用习惯分析** - 分析用户的使用高峰时段和习惯
4. **周报/月报** - 生成定期使用报告
5. **数据导出** - 支持导出统计数据

### 🎨 UI 优化

1. **图表展示** - 使用更丰富的图表展示数据（已有基础实现）
2. **趋势分析** - 显示使用时长的变化趋势
3. **对比分析** - 与历史数据对比
4. **目标设置** - 允许用户设置使用时长目标

### 🔧 技术优化

1. **数据缓存** - 减少频繁查询，提升性能
2. **后台同步** - 定期后台获取数据
3. **异常处理** - 更完善的错误处理和用户提示
4. **权限引导优化** - 更友好的权限引导流程

---

## 总结

✅ **已完成：**
- Android 端屏幕使用时长获取功能
- 权限检查和申请流程
- 基础数据统计和展示
- 测试入口和示例代码

⚠️ **注意事项：**
- 特殊权限需要用户手动授权
- 建议在真机上测试
- 不同厂商可能有实现差异

📝 **使用建议：**
- 在用户首次使用相关功能时申请权限
- 提供清晰的权限说明和价值介绍
- 做好异常情况的处理和提示

---

**开发完成时间：** 2025-10-07
**技术栈：** Flutter + usage_stats ^1.3.1
**支持平台：** Android 5.0+

