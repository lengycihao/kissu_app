# 定位页面额外埋点集成文档

## 概述

本文档记录了在定位页面（Location V2）中新增的 4 个埋点事件的集成情况。这些埋点事件已经通过统一的 `TrackingService` 进行管理，保持了代码的一致性和可维护性。

## 变更日期

2025-10-25

## 新增埋点事件

### 1. 开启自己定位按钮 (enable_own_location_button)

**触发位置：** 地图上方的定位权限提示浮窗  
**触发时机：** 用户点击"请开启实时定位，更好体验KissU"提示时  
**代码位置：** `lib/pages/location/widgets/location_tips_manager.dart` - `onPermissionTipTap()`

**事件参数：**
- `device_id`: 虚拟用户ID
- `user_id`: 用户ID
- `click_time`: 点击时间（格式：年/月/日 时:分:秒）
- `location_status`: 定位状态（开启/关闭）

**实现方式：**
```dart
// 在 LocationTipsManager 的 onPermissionTipTap() 方法中调用
await TrackingService.trackEnableOwnLocation(isEnabled: true);
```

### 2. 对方开启定位状态提示 (partner_location_status_prompt)

**触发位置：** 地图上方的对方定位未开启提示浮窗  
**触发时机：** 用户关闭"对方未开启定位，赶快提醒对方哦~"提示时  
**代码位置：** `lib/pages/location/widgets/location_tips_manager.dart` - `onPartnerLocationTipClose()`

**事件参数：**
- `device_id`: 虚拟用户ID
- `user_id`: 用户ID
- `click_time`: 点击时间（格式：年/月/日 时:分:秒）

**实现方式：**
```dart
// 在 LocationTipsManager 的 onPartnerLocationTipClose() 方法中调用
TrackingService.trackPartnerLocationStatusPrompt();
```

### 3. 人物切换按钮 (character_switch_button)

**触发位置：** 页面顶部的头像切换区域  
**触发时机：** 用户点击顶部头像，切换查看自己或对方的定位时  
**代码位置：** `lib/pages/location/location_v2_controller.dart` - `onAvatarTapped()`

**事件参数：**
- `device_id`: 虚拟用户ID
- `user_id`: 用户ID
- `click_time`: 点击时间（格式：年/月/日 时:分:秒）
- `switch_status`: 切换状态（自己/TA）

**实现方式：**
```dart
// 在 LocationV2Controller 的 onAvatarTapped() 方法中调用
await TrackingService.trackCharacterSwitch(isMyself: isMyself);
```

### 4. 离线提示"查看原因" (location_offline_reason)

**触发位置：** 下半屏列表顶部的离线提示横幅  
**触发时机：** 用户点击"Ta离线啦"横幅中的"查看原因"按钮时  
**代码位置：** `lib/pages/location/location_v2_controller.dart` - `navigateToQuestionPage()`

**事件参数：**
- `device_id`: 虚拟用户ID
- `user_id`: 用户ID
- `click_time`: 点击时间（格式：年/月/日 时:分:秒）

**实现方式：**
```dart
// 在 LocationV2Controller 的 navigateToQuestionPage() 方法中调用
TrackingService.trackLocationOfflineReason();
```

## TrackingService 新增方法

在 `lib/services/tracking_service.dart` 中新增了以下 4 个静态方法：

### 1. trackEnableOwnLocation()
```dart
static Future<void> trackEnableOwnLocation({required bool isEnabled})
```
- 参数 `isEnabled`: true = 开启，false = 关闭

### 2. trackPartnerLocationStatusPrompt()
```dart
static Future<void> trackPartnerLocationStatusPrompt()
```
- 无额外参数，仅记录点击事件

### 3. trackCharacterSwitch()
```dart
static Future<void> trackCharacterSwitch({required bool isMyself})
```
- 参数 `isMyself`: true = 切换到自己，false = 切换到TA

### 4. trackLocationOfflineReason()
```dart
static Future<void> trackLocationOfflineReason()
```
- 无额外参数，仅记录点击事件

## 代码变更总结

### 修改的文件

1. **lib/services/tracking_service.dart**
   - 新增 4 个定位页面埋点方法
   - 所有方法遵循统一的命名规范和参数格式

2. **lib/pages/location/location_v2_controller.dart**
   - 在 `onAvatarTapped()` 方法中添加人物切换埋点
   - 在 `navigateToQuestionPage()` 方法中添加离线查看原因埋点
   - 清理未使用的导入（`umeng_analytics_util.dart`, `intl/intl.dart`）

3. **lib/pages/location/widgets/location_tips_manager.dart**
   - 导入 `TrackingService`
   - 在 `onPermissionTipTap()` 方法中添加开启定位埋点
   - 在 `onPartnerLocationTipClose()` 方法中添加对方定位提示埋点

### 代码质量保证

✅ 所有代码通过 Linter 检查，无警告和错误  
✅ 遵循项目现有的埋点命名规范  
✅ 使用统一的 `TrackingService` 管理所有埋点  
✅ 清理了未使用的导入  
✅ 添加了详细的注释说明

## 埋点事件映射

| 功能描述 | 事件ID | 触发位置 | 触发时机 |
|---------|--------|---------|---------|
| 开启自己定位按钮 | `enable_own_location_button` | 定位权限提示浮窗 | 点击提示时 |
| 对方开启定位状态提示 | `partner_location_status_prompt` | 对方定位未开启提示 | 关闭提示时 |
| 人物切换按钮 | `character_switch_button` | 顶部头像区域 | 切换头像时 |
| 离线提示查看原因 | `location_offline_reason` | 离线提示横幅 | 点击"查看原因"时 |

## 使用示例

### 示例 1：记录用户开启定位
```dart
// 用户点击定位权限提示，跳转到设置
await TrackingService.trackEnableOwnLocation(isEnabled: true);
```

### 示例 2：记录对方定位提示交互
```dart
// 用户关闭对方未开启定位的提示
TrackingService.trackPartnerLocationStatusPrompt();
```

### 示例 3：记录头像切换
```dart
// 用户点击头像切换到查看TA的位置
await TrackingService.trackCharacterSwitch(isMyself: false);
```

### 示例 4：记录查看离线原因
```dart
// 用户点击查看离线原因
TrackingService.trackLocationOfflineReason();
```

## 注意事项

1. **定位权限提示埋点**：当用户点击定位权限提示时，说明当前是未开启状态，因此 `isEnabled` 参数传 `true` 表示用户希望开启定位。

2. **对方定位提示埋点**：该埋点在用户手动关闭提示时触发，记录用户与提示的交互行为。

3. **头像切换埋点**：埋点在切换动画开始前触发，确保即使切换过程中出现异常也能记录到用户的操作意图。

4. **离线查看原因埋点**：在导航到问题页面前触发，记录用户关注离线问题的行为。

## 测试建议

建议在以下场景下验证埋点是否正确触发：

1. ✅ 首次进入定位页面，点击定位权限提示
2. ✅ 对方未开启定位时，关闭提示横幅
3. ✅ 切换查看自己和对方的定位
4. ✅ 对方离线时，点击"查看原因"按钮

## 相关文档

- [TrackingService 使用指南](tracking_service_guide.md)
- [定位页面滑动埋点重构](location_swipe_tracking_refactor.md)
- [友盟埋点集成总结](umeng_analytics_integration.md)

## 维护建议

1. 后续如需添加新的定位页面埋点，请统一在 `TrackingService` 中添加方法
2. 保持埋点命名规范一致性
3. 在埋点方法上添加详细的注释说明
4. 更新本文档记录新增的埋点事件

