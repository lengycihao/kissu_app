# 轨迹页面缓存导致InfoWindow显示错误的修复

## 问题描述

### 复现步骤
1. 进入轨迹页面
2. 切换到"另一半"的头像查看另一半的轨迹
3. 退出轨迹页面
4. 进入定位页面
5. 点击定位页面中"我的"停留点
6. 跳转到轨迹页面

### 问题现象
InfoWindow 错误地标记在了"另一半"的轨迹停留点上，而不是"我的"停留点上。

### 根本原因
1. **控制器复用问题**：`TrackPage` 使用 `Get.put(TrackController())`，导致控制器在页面退出时不会被销毁
2. **状态残留**：用户切换到另一半（`isOneself=0`）后退出，控制器保留了这个状态
3. **错误匹配**：再次进入时，虽然传入了自己的坐标，但控制器的 `isOneself` 仍然是 0，导致在另一半的轨迹中查找停留点

## 修复方案

### 1. 修复控制器生命周期管理（track_page.dart）

**修复前**：
```dart
final controller = Get.put(TrackController());
```

**修复后**：
```dart
// 🔧 修复：使用 Get.find 而不是 Get.put，让 TrackBinding 管理控制器生命周期
// 如果控制器不存在，则创建一个临时的（这种情况不应该发生，因为使用了 TrackBinding）
final controller = Get.isRegistered<TrackController>() 
    ? Get.find<TrackController>() 
    : Get.put(TrackController());
```

**效果**：
- ✅ 让 `TrackBinding` 正确管理控制器的生命周期
- ✅ 页面退出时控制器会被正确销毁（通过 `Get.lazyPut`）
- ✅ 避免控制器状态残留

### 2. 强制切换到正确的用户视角（track_controller.dart）

**修复前**：
```dart
void setInitialCoordinates({
  required double latitude,
  required double longitude,
  String? locationName,
  String? duration,
  String? startTime,
  String? endTime,
  bool autoShowInfoWindow = false,
}) {
  initialCoordinateInfo.value = InitialCoordinateInfo(...);
  
  if (autoShowInfoWindow) {
    _shouldAutoShowInfoWindow = true;
  }
}
```

**修复后**：
```dart
void setInitialCoordinates({
  required double latitude,
  required double longitude,
  String? locationName,
  String? duration,
  String? startTime,
  String? endTime,
  bool autoShowInfoWindow = false,
}) {
  initialCoordinateInfo.value = InitialCoordinateInfo(...);
  
  if (autoShowInfoWindow) {
    _shouldAutoShowInfoWindow = true;
    
    // 🔧 修复：从定位页面跳转时，强制切换到"自己"的视角
    // 因为定位页面点击的是"我的"停留点，所以应该显示自己的轨迹
    if (isOneself.value != 1) {
      DebugUtil.info('🔄 检测到从定位页面跳转，强制切换到自己的视角');
      isOneself.value = 1;
      // 立即切换数据，确保后续处理使用正确的数据
      _switchToCurrentUserData();
    }
  }
}
```

**效果**：
- ✅ 从定位页面跳转时，自动切换到"自己"的视角
- ✅ 确保 InfoWindow 显示在正确的轨迹点上
- ✅ 不影响其他场景的使用

## 技术细节

### TrackBinding 的作用
```dart
class TrackBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => TrackController());
  }
}
```

- `Get.lazyPut`：延迟创建控制器，只有在首次使用时才创建
- 页面退出时，控制器会被自动销毁（如果没有被 `Get.put` 持久化）

### 为什么使用 autoShowInfoWindow 作为判断条件

1. **语义明确**：`autoShowInfoWindow=true` 明确表示需要自动显示 InfoWindow
2. **场景唯一**：只有从定位页面跳转时才会传递 `autoShowInfoWindow=true`
3. **逻辑合理**：从定位页面点击的是"我的"停留点，所以应该显示"我的"轨迹

## 测试验证

### 测试步骤
1. ✅ 进入轨迹页面，默认显示"另一半"的轨迹
2. ✅ 切换到"另一半"的头像，确认显示另一半的轨迹
3. ✅ 退出轨迹页面
4. ✅ 进入定位页面
5. ✅ 点击"我的"停留点
6. ✅ 确认跳转到轨迹页面后，显示"我的"轨迹
7. ✅ 确认 InfoWindow 正确显示在"我的"停留点上

### 回归测试
- ✅ 从首页跳转到轨迹页面，功能正常
- ✅ 从"我的"页面跳转到轨迹页面，功能正常
- ✅ 在轨迹页面切换用户视角，功能正常
- ✅ 轨迹页面的其他功能（播放、日期选择等）正常

## 相关文件

### 修改的文件
1. `lib/pages/track/track_page.dart` - 修复控制器生命周期管理
2. `lib/pages/track/track_controller.dart` - 强制切换到正确的用户视角

### 相关文件（未修改）
1. `lib/pages/location/location_v2_page.dart` - 定位页面的跳转逻辑（已正确传递参数）
2. `lib/pages/track/track_binding.dart` - TrackBinding 定义
3. `lib/pages/home/home_page.dart` - 首页跳转逻辑
4. `lib/pages/home/home_controller.dart` - 首页控制器跳转逻辑
5. `lib/pages/mine/mine_controller.dart` - 我的页面跳转逻辑

## 总结

这个问题的核心是 **控制器生命周期管理不当** 导致的状态残留。通过以下两个修复：

1. **让 TrackBinding 正确管理控制器生命周期**：避免控制器持久化导致的状态残留
2. **智能切换用户视角**：根据跳转场景自动切换到正确的用户视角

确保了 InfoWindow 始终显示在正确的轨迹点上。

## 修复日期
2025-10-21

