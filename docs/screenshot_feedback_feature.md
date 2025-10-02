# 截屏反馈功能文档

## 功能概述

当用户在应用内截屏时，会在屏幕左侧中间位置自动显示一个"意见反馈"浮动按钮。点击该按钮后，会自动将截图带入意见反馈页面，方便用户快速反馈问题。当用户点击反馈按钮或删除截图后，浮动按钮自动消失。

## 实现架构

### 1. Android端截屏监听

**文件**: `android/app/src/main/kotlin/com/yuluo/kissu/ScreenshotObserver.kt`

- 使用 `ContentObserver` 监听媒体库变化
- 通过文件名和路径关键字识别截屏行为
- 关键字包括: "screenshot", "screen_shot", "screencapture", "截屏", "截图" 等
- 仅检测10秒内的新增图片，避免误判
- 内置去重机制，避免重复触发

**关键方法**:
- `startObserving()`: 开始监听媒体库
- `stopObserving()`: 停止监听
- `onScreenshotCaptured`: 截屏回调，返回截图文件路径

### 2. Android端通信桥接

**文件**: `android/app/src/main/kotlin/com/yuluo/kissu/MainActivity.kt`

**MethodChannel**: `kissu_app/screenshot`

**支持方法**:
- `startListening`: 开始截屏监听
- `stopListening`: 停止截屏监听
- `onScreenshotCaptured`: 回调方法，传递截图路径到Flutter层

### 3. Flutter端截屏服务

**文件**: `lib/services/screenshot_service.dart`

**主要功能**:
- 与Android端建立MethodChannel通信
- 管理多个截屏监听器
- 统一分发截屏事件

**核心方法**:
- `startListening()`: 启动截屏监听（仅Android）
- `stopListening()`: 停止截屏监听
- `addListener(callback)`: 添加截屏事件监听器
- `removeListener(callback)`: 移除监听器

**使用示例**:
```dart
final screenshotService = Get.find<ScreenshotService>();

// 添加监听器
screenshotService.addListener((screenshotPath) {
  print('检测到截屏: $screenshotPath');
  // 处理截屏事件
});

// 启动监听
await screenshotService.startListening();
```

### 4. 截屏反馈浮动按钮

**文件**: `lib/widgets/screenshot_feedback_button.dart`

**组件结构**:
- `ScreenshotFeedbackButtonController`: 控制器，管理按钮显示/隐藏和动画
- `ScreenshotFeedbackButton`: 浮动按钮UI组件

**功能特性**:
- 位置: 屏幕左侧中间（垂直居中）
- 动画: 从左侧滑入/滑出
- 样式: 粉色渐变背景，圆角设计
- 自动隐藏: 点击后自动隐藏

**核心方法**:
- `show(screenshotPath)`: 显示按钮并保存截图路径
- `hide()`: 隐藏按钮
- `_handleFeedbackTap()`: 处理点击事件，跳转到意见反馈页面

### 5. 意见反馈页面增强

**文件**: `lib/pages/mine/sub_pages/feed_back_page.dart`

**新增功能**:
- 支持通过路由参数接收外部传入的截图
- 在 `onInit()` 中检查 `Get.arguments['screenshotPath']`
- 自动将截图设置到 `selectedImage`

**路由跳转示例**:
```dart
Get.toNamed(
  KissuRoutePath.feedback,
  arguments: {'screenshotPath': '/path/to/screenshot.png'},
);
```

### 6. 路由配置

**文件**: 
- `lib/routers/kissu_route_path.dart`: 添加 `feedback` 路由常量
- `lib/routers/kissu_route.dart`: 注册意见反馈页面路由
- `lib/pages/mine/mine_controller.dart`: 修改跳转方式为路由跳转

## 使用流程

1. **用户截屏** → 系统保存截图到相册
2. **截屏监听器检测** → `ScreenshotObserver` 检测到媒体库变化
3. **通知Flutter层** → 通过MethodChannel发送截图路径
4. **显示浮动按钮** → `ScreenshotFeedbackButtonController.show()`
5. **用户点击按钮** → 跳转到意见反馈页面
6. **自动填充截图** → 意见反馈页面接收并显示截图
7. **按钮消失** → 点击后自动隐藏

## 初始化配置

**文件**: `lib/main.dart`

在应用启动时自动初始化：

```dart
// 步骤17: 初始化截屏服务和按钮控制器
final screenshotService = Get.put(ScreenshotService(), permanent: true);
Get.put(ScreenshotFeedbackButtonController(), permanent: true);

// 启动截屏监听
screenshotService.startListening();

// 添加截屏回调
screenshotService.addListener((screenshotPath) {
  final buttonController = Get.find<ScreenshotFeedbackButtonController>();
  buttonController.show(screenshotPath);
});
```

## HomePage集成

**文件**: `lib/pages/home/home_page.dart`

在HomePage的Stack中添加截屏反馈按钮：

```dart
Stack(
  children: [
    // ... 其他UI组件
    
    // 截屏反馈浮动按钮
    const ScreenshotFeedbackButton(),
  ],
)
```

## 平台支持

- ✅ **Android**: 完整支持
- ❌ **iOS**: 暂不支持（可后续扩展）

## 权限要求

Android需要读取外部存储权限（用于监听媒体库）：
- `READ_EXTERNAL_STORAGE` (Android 12及以下)
- `READ_MEDIA_IMAGES` (Android 13+)

权限已在 `AndroidManifest.xml` 中配置。

## 技术亮点

1. **无侵入式设计**: 通过全局监听实现，无需修改现有页面逻辑
2. **智能识别**: 多关键字匹配 + 时间窗口限制，准确识别截屏
3. **优雅的动画**: 使用SlideTransition实现流畅的滑入/滑出效果
4. **去重机制**: 避免同一截图重复触发
5. **灵活的监听器模式**: 支持多个监听器，易于扩展

## 注意事项

1. **仅Android平台生效**: iOS平台会自动跳过初始化
2. **截图识别延迟**: 通常在截屏后1-2秒内检测到
3. **按钮位置**: 固定在左侧中间，不会随页面滚动
4. **生命周期管理**: 服务和控制器使用 `permanent: true` 保持全局存活

## 测试建议

1. 在应用内任意页面截屏，观察是否出现浮动按钮
2. 点击浮动按钮，检查是否正确跳转到意见反馈页面
3. 确认意见反馈页面是否正确显示截图
4. 多次截屏，验证去重机制是否正常工作
5. 删除截图后点击按钮，验证按钮是否消失

## 未来优化方向

1. 支持iOS平台截屏监听
2. 支持多张截图
3. 添加截图预览功能
4. 自定义按钮位置
5. 支持拖拽移动按钮位置

