# 定位页面地图右侧按钮埋点集成文档

## 概述

本文档记录了在定位页面地图右侧的三个浮动按钮（当前状态、Ta的足迹、位置提醒）上新增的埋点事件。这些埋点事件通过统一的 `TrackingService` 进行管理，保持了代码的一致性和可维护性。

## 变更日期

2025-10-27

## 新增埋点事件

### 1. 当前状态按钮 (location_current_state)

**触发位置：** 定位页面地图右侧第一个浮动按钮  
**触发时机：** 用户点击"当前状态"按钮，跳转到状态页面时  
**代码位置：** `lib/pages/location/widgets/floating_action_buttons.dart` - 状态按钮的 `onTap` 回调

**事件参数：**
- `device_id`: 虚拟用户ID
- `user_id`: 用户ID
- `click_time`: 点击时间（格式：年/月/日 时:分:秒）

**实现方式：**
```dart
// 在状态按钮的 onTap 回调中调用
TrackingService.trackCurrentStateButton();
```

### 2. Ta的足迹按钮 (location_her_track)

**触发位置：** 定位页面地图右侧第二个浮动按钮  
**触发时机：** 用户点击"轨迹"按钮，跳转到轨迹页面时  
**代码位置：** `lib/pages/location/widgets/floating_action_buttons.dart` - 轨迹按钮的 `onTap` 回调

**事件参数：**
- `device_id`: 虚拟用户ID
- `user_id`: 用户ID
- `click_time`: 点击时间（格式：年/月/日 时:分:秒）

**实现方式：**
```dart
// 在轨迹按钮的 onTap 回调中调用
TrackingService.trackHerTrackButton();
```

### 3. 位置提醒按钮 (location_location_knock)

**触发位置：** 定位页面地图右侧第三个浮动按钮  
**触发时机：** 用户点击"位置提醒"按钮，跳转到位置提醒页面时  
**代码位置：** `lib/pages/location/widgets/floating_action_buttons.dart` - 位置提醒按钮的 `onTap` 回调

**事件参数：**
- `device_id`: 虚拟用户ID
- `user_id`: 用户ID
- `click_time`: 点击时间（格式：年/月/日 时:分:秒）

**实现方式：**
```dart
// 在位置提醒按钮的 onTap 回调中调用
TrackingService.trackLocationReminderButton();
```

## TrackingService 新增方法

在 `lib/services/tracking_service.dart` 中新增了以下 3 个静态方法：

### 1. trackCurrentStateButton()
```dart
static Future<void> trackCurrentStateButton()
```
- 无额外参数，仅记录点击事件

### 2. trackHerTrackButton()
```dart
static Future<void> trackHerTrackButton()
```
- 无额外参数，仅记录点击事件

### 3. trackLocationReminderButton()
```dart
static Future<void> trackLocationReminderButton()
```
- 无额外参数，仅记录点击事件

## 代码变更总结

### 修改的文件

1. **lib/services/tracking_service.dart**
   - 新增 3 个地图右侧按钮埋点方法
   - 所有方法遵循统一的命名规范和参数格式
   - 添加了详细的注释说明

2. **lib/pages/location/widgets/floating_action_buttons.dart**
   - 导入 `TrackingService`
   - 在状态按钮的 `onTap` 回调中添加 `trackCurrentStateButton()` 埋点
   - 在轨迹按钮的 `onTap` 回调中添加 `trackHerTrackButton()` 埋点
   - 在位置提醒按钮的 `onTap` 回调中添加 `trackLocationReminderButton()` 埋点

### 代码质量保证

✅ 所有代码通过 Linter 检查，无警告和错误  
✅ 遵循项目现有的埋点命名规范  
✅ 使用统一的 `TrackingService` 管理所有埋点  
✅ 添加了详细的注释说明  
✅ 埋点在页面跳转前触发，确保数据准确记录

## 埋点事件映射

| 功能描述 | 事件ID | 触发位置 | 触发时机 |
|---------|--------|---------|---------|
| 当前状态按钮 | `location_current_state` | 地图右侧第一个按钮 | 点击跳转到状态页面 |
| Ta的足迹按钮 | `location_her_track` | 地图右侧第二个按钮 | 点击跳转到轨迹页面 |
| 位置提醒按钮 | `location_location_knock` | 地图右侧第三个按钮 | 点击跳转到位置提醒页面 |

## 按钮布局说明

定位页面右侧的三个浮动按钮从上到下依次为：

```
┌──────────────────┐
│                  │
│        地图       │
│                  │
│              ┌─┐ │  ← 1. 当前状态按钮
│              └─┘ │
│                  │
│              ┌─┐ │  ← 2. Ta的足迹按钮（轨迹）
│              └─┘ │
│                  │
│              ┌─┐ │  ← 3. 位置提醒按钮
│              └─┘ │
│                  │
└──────────────────┘
```

### 按钮行为特性

1. **动态透明度**：按钮会根据下方列表的滑动位置动态调整透明度
   - 列表在中间位置时：完全可见（opacity = 1.0）
   - 列表向上滑动时：逐渐隐藏（opacity 从 1.0 → 0.0）
   - 完全隐藏时：禁用点击事件（IgnorePointer）

2. **位置适配**：按钮位置会根据是否绑定伴侣动态调整
   - 已绑定伴侣：对齐到屏幕中间位置
   - 未绑定伴侣：向下偏移 42px（设备信息模块高度差）

## 使用示例

### 示例 1：记录当前状态按钮点击
```dart
// 用户点击当前状态按钮
TrackingService.trackCurrentStateButton();
Get.toNamed(KissuRoutePath.locationState);
```

### 示例 2：记录Ta的足迹按钮点击
```dart
// 用户点击Ta的足迹按钮
TrackingService.trackHerTrackButton();
Get.toNamed(KissuRoutePath.track);
```

### 示例 3：记录位置提醒按钮点击
```dart
// 用户点击位置提醒按钮
TrackingService.trackLocationReminderButton();
Get.toNamed(KissuRoutePath.locationReminder);
```

## 代码实现细节

### FloatingActionButtons Widget

```dart
class FloatingActionButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 动态计算按钮位置和透明度
      return Positioned(
        right: 16,
        bottom: firstButtonBottom,
        child: Opacity(
          opacity: opacity,
          child: IgnorePointer(
            ignoring: opacity == 0.0,
            child: Column(
              children: [
                // 1. 状态按钮
                FloatingButton(
                  assetPath: 'assets/location/kissu3_location_state_an.webp',
                  onTap: () {
                    TrackingService.trackCurrentStateButton();
                    Get.toNamed(KissuRoutePath.locationState);
                  },
                ),
                
                // 2. 轨迹按钮（Ta的足迹）
                FloatingButton(
                  assetPath: 'assets/location/kissu3_location_track_an.webp',
                  onTap: () {
                    TrackingService.trackHerTrackButton();
                    Get.toNamed(KissuRoutePath.track);
                  },
                ),
                
                // 3. 位置提醒按钮
                FloatingButton(
                  assetPath: 'assets/location/kissu3_location_knock_an.webp',
                  onTap: () {
                    TrackingService.trackLocationReminderButton();
                    Get.toNamed(KissuRoutePath.locationReminder);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
```

## 注意事项

1. **埋点顺序**：埋点调用在页面跳转前执行，确保用户的点击行为被正确记录。

2. **按钮可见性**：埋点仅在按钮可见且可点击时触发（透明度 > 0 且未被 IgnorePointer 忽略）。

3. **同步调用**：由于埋点方法是异步的，但这里使用了同步调用（不加 await），这样不会阻塞页面跳转，提供更流畅的用户体验。

4. **事件命名规范**：
   - `location_current_state`: 当前状态（对应按钮位置：第一个）
   - `location_her_track`: Ta的足迹（对应按钮位置：第二个）
   - `location_location_knock`: 位置提醒（对应按钮位置：第三个）

## 测试建议

建议在以下场景下验证埋点是否正确触发：

1. ✅ 点击"当前状态"按钮，验证跳转到状态页面
2. ✅ 点击"Ta的足迹"按钮，验证跳转到轨迹页面
3. ✅ 点击"位置提醒"按钮，验证跳转到位置提醒页面
4. ✅ 上滑列表到顶部，确认按钮隐藏且不可点击
5. ✅ 下拉列表到中间，确认按钮显示且可点击

## 相关文档

- [TrackingService 使用指南](tracking_service_guide.md)（如存在）
- [定位页面额外埋点集成](location_additional_tracking.md)
- [定位页面滑动埋点重构](location_swipe_tracking_refactor.md)（如存在）
- [友盟埋点集成总结](umeng_analytics_integration.md)（如存在）

## 维护建议

1. 后续如需添加新的定位页面按钮埋点，请统一在 `TrackingService` 中添加方法
2. 保持埋点命名规范一致性（使用 `location_` 前缀）
3. 在埋点方法上添加详细的注释说明，包括事件ID、参数列表、触发场景
4. 更新本文档记录新增的埋点事件
5. 确保埋点调用不阻塞用户交互，优先保证用户体验流畅性

## API 映射参考

根据 `api_type.md` 文档，三个按钮的埋点事件对应关系：

| 按钮名称 | 事件ID | 中文名称 | 参数 |
|---------|--------|---------|------|
| 状态按钮 | `location_current_state` | 当前状态 | device_id, user_id, click_time |
| 轨迹按钮 | `location_her_track` | Ta的足迹 | device_id, user_id, click_time |
| 位置提醒按钮 | `location_location_knock` | 位置提醒 | device_id, user_id, click_time |

所有参数均通过 `TrackingService._buildBaseParams()` 方法自动生成，无需手动传入。

