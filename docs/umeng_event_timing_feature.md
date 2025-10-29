# 友盟事件计时功能使用指南

## 功能概述

友盟埋点新增事件计时功能，可以自动记录事件的停留时长。该功能包含完善的安全销毁机制，防止内存泄漏。

## 核心方法

### 1. `eventBegin()` - 开始计时

开始记录事件的时间点。

```dart
// 基础用法
await UmengAnalytics.eventBegin('video_play');

// 带参数
await UmengAnalytics.eventBegin('video_play', params: {
  'video_id': '12345',
  'video_title': '教学视频',
});
```

### 2. `eventEnd()` - 结束计时

结束事件计时，自动计算并上报时长到友盟。

```dart
// 基础用法
await UmengAnalytics.eventEnd('video_play');

// 带参数（会覆盖 eventBegin 时的参数）
await UmengAnalytics.eventEnd('video_play', params: {
  'video_id': '12345',
  'completion_rate': '95%',
});
```

### 3. `endAllEvents()` - 批量结束所有事件

结束所有正在计时的事件，**强烈建议在页面销毁时调用**。

```dart
@override
void onClose() {
  UmengAnalytics.endAllEvents();
  super.onClose();
}
```

### 4. 辅助方法

```dart
// 检查事件是否正在计时
bool isActive = UmengAnalytics.isEventActive('video_play');

// 获取所有正在计时的事件列表（用于调试）
List<String> activeEvents = UmengAnalytics.getActiveEvents();

// 清理超时事件（可选，一般不需要手动调用）
await UmengAnalytics.cleanupTimeoutEvents();
```

## 完整使用示例

### 示例1：视频播放时长统计

```dart
class VideoPlayerController extends GetxController {
  
  @override
  void onInit() {
    super.onInit();
    // 页面进入时开始计时
    UmengAnalytics.eventBegin('video_play', params: {
      'video_id': videoId,
      'video_name': videoName,
    });
  }
  
  @override
  void onClose() {
    // 页面销毁时自动结束所有计时事件
    UmengAnalytics.endAllEvents();
    super.onClose();
  }
  
  // 用户主动退出视频时
  void exitVideo() {
    UmengAnalytics.eventEnd('video_play', params: {
      'video_id': videoId,
      'exit_reason': 'user_close',
    });
    Get.back();
  }
}
```

### 示例2：功能模块使用时长

```dart
class FeatureController extends GetxController {
  
  void enterFeature() {
    // 进入功能时开始计时
    UmengAnalytics.eventBegin('feature_usage', params: {
      'feature_name': 'chat',
    });
  }
  
  void exitFeature() {
    // 退出功能时结束计时
    UmengAnalytics.eventEnd('feature_usage', params: {
      'feature_name': 'chat',
      'message_sent': messageSentCount.toString(),
    });
  }
  
  @override
  void onClose() {
    // 确保页面销毁时清理所有未结束的事件
    UmengAnalytics.endAllEvents();
    super.onClose();
  }
}
```

### 示例3：使用 try-finally 确保清理

```dart
Future<void> someOperation() async {
  try {
    await UmengAnalytics.eventBegin('complex_operation');
    
    // 执行复杂操作
    await doSomething();
    
  } finally {
    // 无论成功或失败，都确保结束计时
    await UmengAnalytics.eventEnd('complex_operation');
  }
}
```

## 安全机制说明

### 1. 防止重复开始

如果同一个事件ID重复调用 `eventBegin()`，会自动结束之前的计时器并警告。

```dart
await UmengAnalytics.eventBegin('test_event');
await UmengAnalytics.eventBegin('test_event'); // ⚠️ 会警告并自动结束之前的计时
```

### 2. 超时检测

事件计时超过 30 分钟会自动警告，提示可能忘记调用 `eventEnd()`。

### 3. 未开始检测

如果事件未调用 `eventBegin()` 就调用 `eventEnd()`，会记录警告但不会崩溃。

```dart
await UmengAnalytics.eventEnd('non_exist_event'); // ⚠️ 会警告但不会报错
```

### 4. 异常处理

即使原生方法调用失败，也会清理本地记录，防止内存泄漏。

## 最佳实践

### ✅ 推荐做法

1. **页面销毁时必须清理**
```dart
@override
void onClose() {
  UmengAnalytics.endAllEvents(); // 👍 防止内存泄漏
  super.onClose();
}
```

2. **使用 try-finally 保证清理**
```dart
try {
  await UmengAnalytics.eventBegin('event');
  await doWork();
} finally {
  await UmengAnalytics.eventEnd('event'); // 👍 确保一定会执行
}
```

3. **事件ID命名规范**
```dart
// 👍 使用英文或拼音，下划线分隔
UmengAnalytics.eventBegin('video_play');
UmengAnalytics.eventBegin('page_stay_duration');
UmengAnalytics.eventBegin('feature_usage_time');
```

### ❌ 不推荐做法

1. **忘记调用 endAllEvents()**
```dart
@override
void onClose() {
  // ❌ 没有清理事件，可能导致内存泄漏
  super.onClose();
}
```

2. **事件开始后没有结束**
```dart
void someFunction() {
  UmengAnalytics.eventBegin('test');
  // ❌ 没有调用 eventEnd()，会一直计时
}
```

3. **使用中文事件ID**
```dart
// ❌ 不推荐使用中文
UmengAnalytics.eventBegin('视频播放');

// 👍 推荐使用英文或拼音
UmengAnalytics.eventBegin('video_play');
```

## 应用生命周期集成（可选）

在应用进入后台时清理所有计时事件：

```dart
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.detached) {
      // 应用进入后台或即将终止时，清理所有计时事件
      UmengAnalytics.endAllEvents();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(...);
  }
}
```

## 友盟后台查看

上报后，在友盟后台可以看到：
- **事件ID**：如 `video_play`
- **事件时长**：自动计算的秒数
- **事件参数**：自定义参数（如 video_id、completion_rate 等）
- **统计维度**：平均时长、总时长、时长分布等

## 技术实现

### Dart 层
- 使用 `Map<String, DateTime>` 记录所有进行中的事件
- 本地计算时长并验证
- 提供多种安全清理方法

### Android 层
- 调用友盟 SDK 的 `MobclickAgent.onEventBegin()` 和 `MobclickAgent.onEventEnd()`
- 支持带参数和不带参数两种方式

## 常见问题

### Q: 如果忘记调用 eventEnd() 会怎样？
A: 
1. 本地会一直保存该事件的计时器
2. 超过 30 分钟会打印警告日志
3. 建议在页面 `onClose()` 中调用 `endAllEvents()` 自动清理

### Q: 可以同时计时多个不同的事件吗？
A: 可以！每个事件ID独立计时，互不影响。

```dart
await UmengAnalytics.eventBegin('video_play');
await UmengAnalytics.eventBegin('chat_session');
// 两个事件同时计时
```

### Q: eventBegin 和 eventEnd 的参数必须一致吗？
A: 事件ID必须一致，参数可以不同。eventEnd 的参数会覆盖 eventBegin 的参数。

### Q: 如何调试查看当前有哪些事件正在计时？
A: 使用 `getActiveEvents()` 方法：

```dart
List<String> activeEvents = UmengAnalytics.getActiveEvents();
print('正在计时的事件: $activeEvents');
```

## 更新日期

2025-10-25

## 相关文件

- `lib/utils/umeng_analytics_util.dart` - Dart 层实现
- `android/app/src/main/kotlin/com/yuluo/kissu/MainActivity.kt` - Android 原生实现

