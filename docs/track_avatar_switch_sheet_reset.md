# 轨迹页面和定位页面切换头像时下半屏复位功能

## 需求描述

在轨迹页面和定位页面，每次切换头像（无论是切换到自己还是另一半）时，将下半屏（DraggableScrollableSheet）恢复到底部吸顶的初始位置。

## 需求背景

这个功能是为了在用户切换查看对象时，提供统一的视觉体验：
- **统一初始状态**：每次切换头像后，都从底部吸顶位置开始查看，保持一致性
- **避免混淆**：防止用户在不同的面板高度状态下切换，导致UI显示混乱
- **更好的体验**：让用户明确知道已经切换了查看对象，从初始状态重新浏览
- **修复灰屏问题**：定位页面在下半屏处于顶部吸顶时切换头像会导致地图不可见（灰屏），复位到底部可以解决这个问题

## 技术实现

### 1. 底部吸顶位置定义

在 `track_page.dart` 中定义：

```dart
initialHeight = 190;  // 固定像素值
minHeight = 190;      // 固定像素值
```

转换为 DraggableScrollableSheet 的比例：
```dart
initialChildSize = initialHeight / screenHeight  // 约为 0.23-0.25（取决于屏幕高度）
minChildSize = minHeight / screenHeight
```

### 2. 复位方法

使用 `TrackUIManager` 中的 `collapseToBottomPosition()` 方法：

```dart
/// 收起底部面板到底部吸顶位置
void collapseToBottomPosition() {
  if (_draggableController != null) {
    try {
      // 动态计算底部吸顶位置
      const minHeight = 190.0;
      final screenHeight = Get.context != null 
          ? MediaQuery.of(Get.context!).size.height 
          : 800.0;
      final bottomSnapSize = minHeight / screenHeight;
      
      _draggableController!.animateTo(
        bottomSnapSize,  // 收起到底部吸顶位置
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      DebugUtil.info('🎯 收起底部面板到底部吸顶位置');
    } catch (e) {
      DebugUtil.error('❌ 收起底部面板到底部位置失败: $e');
    }
  }
}
```

**关键特性**：
- **动态计算**：根据实际屏幕高度计算比例，适配不同设备
- **平滑动画**：300ms 缓动动画，视觉效果自然
- **异常处理**：内部有 try-catch，不影响正常切换功能

### 3. 代码修改

#### 修改文件1：`lib/pages/track/track_controller.dart`

在 `onAvatarTapped` 方法中添加下半屏复位逻辑：

```dart
/// 头像点击时切换用户视角（优化版本）
void onAvatarTapped(bool isMyself) {
  DebugUtil.info('🎯 头像点击开始 - isMyself: $isMyself');
  
  // 🎬 切换头像时重置轨迹播放状态
  if (isReplaying.value) {
    DebugUtil.info('🛑 检测到正在播放轨迹，切换头像时重置播放状态');
    _replayManager.resetReplayState();
  }
  
  // 计算目标用户类型
  final targetUserType = isMyself ? 1 : 0;
  
  // 如果点击的是当前用户，不做任何处理
  if (isOneself.value == targetUserType) {
    DebugUtil.info('点击的是当前用户头像，不切换');
    return;
  }
  
  // 📱 每次切换头像时，将下半屏恢复到底部吸顶位置
  DebugUtil.info('💡 切换头像，恢复下半屏到底部吸顶位置');
  _uiManager.collapseToBottomPosition();
  
  // 执行用户切换
  DebugUtil.info('🔄 切换到${isMyself ? "自己" : "另一半"}');
  _dataManager.switchUser(targetUserType);
  _clearDataForAvatarSwitch();
  _updateMapAfterUserSwitch();
}
```

#### 修改文件2：`lib/pages/location/location_v2_controller.dart`

**步骤1：添加 `collapseToBottomPosition` 方法**

```dart
/// 收起底部面板到底部吸顶位置（切换头像时使用）
void collapseToBottomPosition() {
  if (_draggableController != null) {
    try {
      // 动态计算底部吸顶位置（对应 snapSizes 中的第一个位置）
      const minHeight = 190.0;
      final screenHeight = Get.context != null 
          ? MediaQuery.of(Get.context!).size.height 
          : 800.0;
      final bottomSnapSize = minHeight / screenHeight;
      
      _draggableController!.animateTo(
        bottomSnapSize, // 收起到底部吸顶位置
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      debugPrint('🎯 定位页面：收起底部面板到底部吸顶位置');
    } catch (e) {
      debugPrint('❌ 定位页面：收起底部面板到底部位置失败: $e');
    }
  }
}
```

**步骤2：修改 `onAvatarTapped` 方法**

在方法开头添加重复点击判断和下半屏复位逻辑：

```dart
Future<void> onAvatarTapped(bool isMyself) async {
  if (isSwitchingView.value) return;

  // 计算目标用户类型
  final targetUserType = isMyself ? 1 : 0;
  
  // 如果点击的是当前用户，不做任何处理
  if (isOneself.value == targetUserType) {
    debugPrint('🎯 定位页面：点击的是当前用户头像，不切换');
    return;
  }

  // 📱 每次切换头像时，将下半屏恢复到底部吸顶位置
  debugPrint('💡 定位页面：切换头像，恢复下半屏到底部吸顶位置');
  collapseToBottomPosition();

  isSwitchingView.value = true;
  
  // ... 后续的切换逻辑保持不变 ...
}
```

## 执行流程

### 轨迹页面执行流程

完整的用户头像切换流程：

```
用户点击头像（自己或另一半）
    ↓
检查是否正在播放轨迹 → 如果是，重置播放状态
    ↓
计算目标用户类型
    ├─ 点击自己：targetUserType = 1
    └─ 点击另一半：targetUserType = 0
    ↓
检查是否点击的是当前用户 → 如果是，直接返回
    ↓
【核心功能】下半屏复位到底部吸顶位置
    ├─ 计算底部吸顶比例：190 / screenHeight
    ├─ 调用 _uiManager.collapseToBottomPosition()
    └─ 执行动画：300ms，Curves.easeInOut
    ↓
执行用户切换逻辑
    ├─ _dataManager.switchUser(targetUserType)
    ├─ _clearDataForAvatarSwitch()
    └─ _updateMapAfterUserSwitch()
    ↓
页面更新完成
```

### 定位页面执行流程

完整的用户头像切换流程：

```
用户点击头像（自己或另一半）
    ↓
检查是否正在切换中 → 如果是，直接返回（防止重复点击）
    ↓
计算目标用户类型
    ├─ 点击自己：targetUserType = 1
    └─ 点击另一半：targetUserType = 0
    ↓
检查是否点击的是当前用户 → 如果是，直接返回
    ↓
【核心功能】下半屏复位到底部吸顶位置
    ├─ 计算底部吸顶比例：190 / screenHeight
    ├─ 调用 collapseToBottomPosition()
    └─ 执行动画：300ms，Curves.easeInOut（与淡出动画并行）
    ↓
设置切换状态标志：isSwitchingView = true
    ↓
启动安全定时器（5秒超时保护）
    ↓
执行淡出动画（遮罩层覆盖）
    ↓
在遮罩下执行数据切换
    ├─ 更新 isOneself 状态
    ├─ 调用 loadLocationData() 获取最新数据
    └─ 移动地图到目标用户位置（无动画）
    ↓
执行淡入动画（遮罩层消失）
    ↓
重置切换状态：isSwitchingView = false
    ↓
页面更新完成
```

**关键差异**：
- 轨迹页面：下半屏复位与数据切换同步进行
- 定位页面：下半屏复位在淡出动画开始前执行，与遮罩动画并行，用户在遮罩下看不到复位过程

## DraggableScrollableSheet 吸附点配置

### 轨迹页面（track_page.dart）

在 `track_page.dart` 中配置了三个吸附点：

```dart
snap: true,  // 启用吸附效果
snapSizes: [
  minHeight / screenHeight,           // 【1】底部吸顶位置（190px）
  middleSnapSize,                     // 【2】中间位置（约0.5，根据绑定状态调整）
  (screenHeight - 100) / screenHeight, // 【3】顶部位置（距离顶部100px）
],
snapAnimationDuration: const Duration(milliseconds: 200),
```

**吸附点说明**：
- **第1个吸附点**：底部吸顶位置（190px），显示头像、设备信息、日期选择器
- **第2个吸附点**：中间位置（约屏幕50%），显示部分停留点列表
- **第3个吸附点**：顶部位置（距顶部100px），全屏显示停留点列表

**切换头像时的行为**：
- 无论当前在哪个吸附点，都会动画收起到第1个吸附点（底部吸顶位置）

### 定位页面（location_v2_page.dart）

在 `location_v2_page.dart` 中配置了两个吸附点（非会员查看另一半时禁用拖动）：

```dart
snap: true,  // 启用吸附效果
snapSizes: shouldLimitDrag
    ? null  // 非会员查看另一半：禁用吸附，锁定在底部
    : [
        middleSnapSize,                     // 【1】中间位置（约0.5，根据绑定状态调整）
        (screenHeight - 100) / screenHeight, // 【2】顶部位置（距离顶部100px）
      ],
snapAnimationDuration: const Duration(milliseconds: 200),
```

**吸附点说明**：
- **第1个吸附点**：中间位置（约屏幕50%），显示部分位置记录列表
- **第2个吸附点**：顶部位置（距顶部100px），全屏显示位置记录列表
- **特殊情况**：非会员查看另一半时，`shouldLimitDrag = true`，下半屏锁定在底部（190px），无法拖动

**切换头像时的行为**：
- 无论当前在哪个吸附点，都会动画收起到底部吸顶位置（190px）
- 如果从顶部吸顶位置切换，可以避免灰屏问题（地图被完全遮挡）

## 测试场景

### 场景1：从底部位置切换头像（✅ 保持位置）

**适用页面**：轨迹页面、定位页面

**前置条件**：
- 下半屏在底部吸顶位置（190px）

**操作步骤**：
1. 点击另一个头像

**预期结果**：
- ✅ 下半屏保持在底部吸顶位置（无明显变化）
- ✅ 页面切换到目标用户的数据
- ✅ 控制台输出：
  - 轨迹页面：`💡 切换头像，恢复下半屏到底部吸顶位置`
  - 定位页面：`💡 定位页面：切换头像，恢复下半屏到底部吸顶位置`

### 场景2：从中间位置切换头像（✅ 触发复位）

**适用页面**：轨迹页面、定位页面

**前置条件**：
- 下半屏在中间吸附位置（约50%高度）

**操作步骤**：
1. 点击另一个头像

**预期结果**：
- ✅ 下半屏动画收起到底部吸顶位置（190px）
- ✅ 动画时长：300ms，流畅自然
- ✅ 页面切换到目标用户的数据
- ✅ 控制台输出：
  - 轨迹页面：`💡 切换头像，恢复下半屏到底部吸顶位置`
  - 定位页面：`💡 定位页面：切换头像，恢复下半屏到底部吸顶位置`

### 场景3：从顶部位置切换头像（✅ 触发复位，修复灰屏）

**适用页面**：轨迹页面、定位页面

**前置条件**：
- 下半屏在顶部吸附位置（接近全屏）
- 返回按钮已旋转90度（轨迹页面）

**操作步骤**：
1. 点击另一个头像

**预期结果**：
- ✅ 下半屏动画收起到底部吸顶位置（190px）
- ✅ 返回按钮恢复原位（不再旋转）
- ✅ 页面切换到目标用户的数据
- ✅ **定位页面特别说明**：修复了灰屏问题，地图重新可见
- ✅ 控制台输出：
  - 轨迹页面：`💡 切换头像，恢复下半屏到底部吸顶位置`
  - 定位页面：`💡 定位页面：切换头像，恢复下半屏到底部吸顶位置`

### 场景4：重复点击相同头像（❌ 不触发）

**适用页面**：轨迹页面、定位页面

**前置条件**：
- 当前查看自己的数据
- 下半屏在任意位置

**操作步骤**：
1. 再次点击自己的头像

**预期结果**：
- ❌ 不触发任何操作（检测到点击的是当前用户头像）
- ❌ 下半屏位置不变
- ✅ 控制台输出：
  - 轨迹页面：`点击的是当前用户头像，不切换`
  - 定位页面：`🎯 定位页面：点击的是当前用户头像，不切换`

### 场景5：切换头像时正在播放轨迹（✅ 先停止播放）

**适用页面**：轨迹页面（定位页面无轨迹播放功能）

**前置条件**：
- 正在播放轨迹回放
- 下半屏在任意位置

**操作步骤**：
1. 点击另一个头像

**预期结果**：
- ✅ 轨迹播放立即停止
- ✅ 下半屏动画收起到底部吸顶位置
- ✅ 页面切换到目标用户的轨迹数据
- ✅ 控制台输出：
  - `🛑 检测到正在播放轨迹，切换头像时重置播放状态`
  - `💡 切换头像，恢复下半屏到底部吸顶位置`

### 场景6：不同屏幕尺寸设备（✅ 自适应）

**适用页面**：轨迹页面、定位页面

**测试设备**：
- 小屏手机（如 iPhone SE，屏高 667px）
- 中屏手机（如 iPhone 12，屏高 844px）
- 大屏手机（如 iPhone 14 Pro Max，屏高 932px）

**操作步骤**：
1. 在不同设备上切换头像

**预期结果**：
- ✅ 在所有设备上，下半屏都收起到 190px 的固定高度
- ✅ 底部吸顶位置的比例自动适配：
  - 小屏：190 / 667 ≈ 0.285
  - 中屏：190 / 844 ≈ 0.225
  - 大屏：190 / 932 ≈ 0.204
- ✅ 视觉效果一致，都显示相同的内容区域

### 场景7：定位页面灰屏问题修复（✅ 核心场景）

**适用页面**：定位页面

**问题描述**：
- 在定位页面，当下半屏处于顶部吸顶位置时，切换头像会导致地图不可见（灰屏）
- 原因：下半屏完全遮挡了地图，切换后地图重新渲染但仍被遮挡

**前置条件**：
- 下半屏在顶部吸附位置（接近全屏）
- 地图被下半屏完全遮挡

**操作步骤**：
1. 点击另一个头像

**预期结果**：
- ✅ 下半屏立即开始收起动画（300ms）
- ✅ 同时执行淡出遮罩动画
- ✅ 地图在遮罩下重新渲染
- ✅ 遮罩消失后，下半屏已回到底部，地图完全可见
- ✅ **不再出现灰屏问题**
- ✅ 控制台输出：`💡 定位页面：切换头像，恢复下半屏到底部吸顶位置`

## 用户体验说明

### 1. 动画效果

- **流畅自然**：使用 300ms 的 easeInOut 动画，视觉效果平滑
- **不突兀**：在数据加载的同时进行动画，用户感知良好
- **可预期**：每次切换头像都有一致的行为，用户能快速适应

### 2. 交互逻辑

- **统一体验**：无论切换到谁，都从底部吸顶位置开始
- **智能判断**：重复点击相同头像不触发复位
- **播放优先**：如果正在播放轨迹，先停止播放再执行复位
- **响应式设计**：自动适配不同屏幕尺寸

### 3. 视觉反馈

- **位置变化明显**：从中间或顶部收起时，用户能清楚感知到切换动作
- **返回按钮联动**：如果从顶部收起，返回按钮会同步恢复原位
- **内容重置**：下半屏内的停留点列表也会重置到顶部

## 与其他功能的交互

### 1. 与轨迹播放的交互

**优先级**：先停止播放 → 再复位下半屏 → 最后切换数据

```dart
// 🎬 切换头像时重置轨迹播放状态
if (isReplaying.value) {
  DebugUtil.info('🛑 检测到正在播放轨迹，切换头像时重置播放状态');
  _replayManager.resetReplayState();
}
```

### 2. 与返回按钮的交互

**联动效果**：下半屏收起时，返回按钮自动恢复原位

- 当下半屏从顶部（>0.85）收起到底部（<0.85）时
- `TrackUIManager` 会监听 `sheetPercent` 的变化
- 自动触发返回按钮的反向旋转动画

### 3. 与停留点点击的交互

**不冲突**：停留点点击也会触发下半屏复位，但使用的是同一个方法

```dart
// 在 track_controller.dart 中
void onStayPointTap(StayPoint point) {
  // ... 其他逻辑 ...
  _uiManager.collapseToBottomPosition();  // 同样的复位方法
}
```

### 4. 与日期切换的交互

**独立功能**：日期切换不会触发下半屏复位

- 日期切换只刷新数据，不改变下半屏位置
- 用户可以在任意下半屏位置切换日期

## 性能优化

### 1. 避免重复动画

```dart
// 如果点击的是当前用户，不做任何处理
if (isOneself.value == targetUserType) {
  DebugUtil.info('点击的是当前用户头像，不切换');
  return;  // 提前返回，避免执行动画
}
```

### 2. 动画与数据加载并行

下半屏复位动画（300ms）与数据切换并行执行：
- 用户看到流畅的动画效果
- 数据在后台加载
- 动画结束时数据基本已准备好

### 3. 控制器复用

使用同一个 `DraggableScrollableController`：
- 不需要重新创建控制器
- 减少内存开销
- 动画性能更好

## 相关代码文件

- `lib/pages/track/track_controller.dart` - 轨迹页面主控制器（修改）
- `lib/pages/track/managers/track_ui_manager.dart` - UI管理器（使用 collapseToBottomPosition）
- `lib/pages/track/track_page.dart` - 轨迹页面UI（DraggableScrollableSheet配置）

## 注意事项

### 1. 屏幕高度获取

`collapseToBottomPosition()` 方法中动态获取屏幕高度：

```dart
final screenHeight = Get.context != null 
    ? MediaQuery.of(Get.context!).size.height 
    : 800.0;  // 降级方案
```

**降级方案**：如果无法获取 context，使用默认值 800.0

### 2. 执行顺序

下半屏复位操作在用户数据切换之前执行：
```
复位动画开始 → 数据切换 → 清理数据 → 更新地图 → 动画结束
```

这样可以让动画和数据加载并行，提升用户体验。

### 3. 异常处理

`collapseToBottomPosition()` 方法内部已有 try-catch 处理：
- 如果 `_draggableController` 为 null，不会执行动画
- 如果动画执行失败，会输出错误日志但不影响用户切换
- 数据切换逻辑不依赖动画是否成功

### 4. 兼容性

此功能对所有用户生效，无需区分会员状态：
- 会员和非会员都有相同的体验
- 不影响其他触发面板收起的操作（如点击停留点）
- 与现有功能完全兼容

## 可能的扩展

### 1. 可配置的复位行为

可以考虑添加配置选项，让用户选择：
- **始终复位**（当前实现）
- **保持位置**（会员特权）
- **智能复位**（根据上下文决定）

### 2. 复位动画的自定义

可以考虑提供不同的动画效果：
- **快速复位**：200ms，Curves.easeOut
- **平滑复位**：300ms，Curves.easeInOut（当前）
- **弹性复位**：400ms，Curves.elasticOut

### 3. 添加haptic反馈

在复位时添加触觉反馈：
```dart
HapticFeedback.lightImpact();  // 轻微震动
```

### 4. 数据埋点

建议添加数据埋点，统计：
- 用户切换头像的频率
- 切换时下半屏的位置分布
- 切换后的停留时长

## 调试日志

功能执行时会输出以下日志：

```
🎯 头像点击开始 - isMyself: false
🛑 检测到正在播放轨迹，切换头像时重置播放状态  // 如果正在播放
💡 切换头像，恢复下半屏到底部吸顶位置
🎯 收起底部面板到底部吸顶位置
🔄 切换到另一半
```

如果点击的是当前用户：
```
🎯 头像点击开始 - isMyself: true
点击的是当前用户头像，不切换
```

如果动画执行失败：
```
❌ 收起底部面板到底部位置失败: [错误信息]
```

## 参考资料

- Flutter DraggableScrollableSheet 官方文档
- GetX 状态管理文档
- Material Design 动画指南
- iOS Human Interface Guidelines - 手势交互

