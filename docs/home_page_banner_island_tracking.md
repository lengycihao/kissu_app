# 首页 Banner/岛视图埋点实现文档

## 概述

本文档说明了首页底部 Banner（屏视图）和岛视图按钮的埋点实现。

## 埋点事件

### 1. 屏视图 Banner 点击事件

**事件ID**: `home_banner`

**触发时机**: 用户点击首页底部的 Banner（定位、足迹）

**参数说明**:

| 参数名 | 类型 | 说明 | 示例值 |
|--------|------|------|--------|
| device_id | String | 虚拟用户ID（通过设备号生成） | "abc123..." |
| user_id | String | 用户ID（已登录时） | "12345" |
| is_drag | String | 是否手动滑动（"1"=是，"0"=否） | "1" |
| click_time | String | 点击时间（格式：年/月/日 时:分:秒） | "2025/10/25 14:30:45" |
| click_type | String | 点击类型 | "定位"、"足迹" |
| is_vip | String | 是否会员 | "是会员"、"不是会员" |
| is_bind | String | 是否绑定 | "是绑定"、"未绑定" |

**is_drag 参数说明**:
- `is_drag = "1"`: 用户手动滑动到该 Banner 后点击
- `is_drag = "0"`: Banner 自动播放到该位置后用户点击

**实现逻辑**:
1. 使用 `Listener` 组件包裹 `Swiper`，监听 `onPointerDown` 事件
2. 当用户触摸 Banner 时，设置 `isBannerManuallyDragged = true`
3. 在 `onIndexChanged` 回调中，延迟 100ms 后重置 `isBannerManuallyDragged = false`
4. 点击 Banner 时，根据 `isBannerManuallyDragged` 的值上报埋点

**使用示例**:

```dart
// 屏视图 Banner 点击（未绑定状态）
await TrackingService.trackHomeBannerClick(
  isDrag: controller.isBannerManuallyDragged.value,
  clickType: '定位', // 或 '足迹'
  isVip: UserManager.isVip,
  isBind: false,
);

// 屏视图 Banner 点击（已绑定状态）
await TrackingService.trackHomeBannerClick(
  isDrag: controller.isBannerManuallyDragged.value,
  clickType: '定位', // 或 '足迹'
  isVip: UserManager.isVip,
  isBind: true,
);
```

### 2. 岛视图按钮点击事件

**事件ID**: `home_island`

**触发时机**: 用户点击岛视图中的按钮（定位、足迹）

**参数说明**:

| 参数名 | 类型 | 说明 | 示例值 |
|--------|------|------|--------|
| device_id | String | 虚拟用户ID（通过设备号生成） | "abc123..." |
| user_id | String | 用户ID（已登录时） | "12345" |
| click_time | String | 点击时间（格式：年/月/日 时:分:秒） | "2025/10/25 14:30:45" |
| is_vip | String | 是否会员 | "是会员"、"不是会员" |
| is_bind | String | 是否绑定 | "是绑定"、"未绑定" |
| click_type | String | 点击类型 | "定位"、"足迹" |

**使用示例**:

```dart
// 岛视图 - 足迹按钮点击
await TrackingService.trackHomeIslandClick(
  clickType: '足迹',
  isVip: UserManager.isVip,
  isBind: controller.isBound.value,
);

// 岛视图 - 定位按钮点击
await TrackingService.trackHomeIslandClick(
  clickType: '定位',
  isVip: UserManager.isVip,
  isBind: controller.isBound.value,
);
```

## 代码实现位置

### TrackingService（埋点服务）

**文件**: `lib/services/tracking_service.dart`

**方法**:
- `trackHomeBannerClick()`: 屏视图 Banner 点击埋点
- `trackHomeIslandClick()`: 岛视图按钮点击埋点

### HomeController（首页控制器）

**文件**: `lib/pages/home/home_controller.dart`

**新增变量**:
- `isBannerManuallyDragged`: 追踪用户是否手动滑动 Banner

### HomePage（首页视图）

**文件**: `lib/pages/home/home_page.dart`

**修改位置**:
1. `_buildBanner()`: 屏视图 Banner（未绑定状态）
   - 添加 `Listener` 监听触摸事件
   - 在 Banner 点击时上报埋点

2. `_buildBannerBind()`: 屏视图 Banner（已绑定状态）
   - 添加 `Listener` 监听触摸事件
   - 在 Banner 点击时上报埋点

3. `_AnimatedIslandViewState`: 岛视图
   - 在足迹按钮点击时上报埋点
   - 在定位按钮点击时上报埋点

## 手动滑动检测原理

### 问题背景

Banner 使用了 `Swiper` 组件，具有自动播放功能。需要区分用户点击的 Banner 是：
1. 用户手动滑动到该位置后点击
2. 自动播放到该位置后用户点击

### 解决方案

使用 `Listener` 组件包裹 `Swiper`，监听用户的触摸事件：

```dart
Listener(
  onPointerDown: (_) {
    // 用户触摸了 banner，标记为手动滑动
    controller.isBannerManuallyDragged.value = true;
  },
  child: Swiper(
    onIndexChanged: (index) {
      controller.currentSwiperIndex.value = index;
      // 索引变化后，延迟重置手动滑动标记
      Future.delayed(const Duration(milliseconds: 100), () {
        controller.isBannerManuallyDragged.value = false;
      });
    },
    // ... 其他配置
  ),
)
```

### 工作流程

1. **初始状态**: `isBannerManuallyDragged = false`
2. **用户触摸 Banner**: `onPointerDown` 触发，设置 `isBannerManuallyDragged = true`
3. **索引变化**: `onIndexChanged` 触发，延迟 100ms 后重置为 `false`
4. **用户点击**: 根据 `isBannerManuallyDragged` 的值判断是否为手动滑动

### 时序说明

- **自动播放场景**:
  1. Banner 自动切换 → `onIndexChanged` 触发
  2. 延迟 100ms 后 → `isBannerManuallyDragged = false`
  3. 用户点击 → 上报 `is_drag = "0"`

- **手动滑动场景**:
  1. 用户触摸 → `onPointerDown` 触发 → `isBannerManuallyDragged = true`
  2. 用户滑动 → Banner 切换 → `onIndexChanged` 触发
  3. 用户点击（在 100ms 内）→ 上报 `is_drag = "1"`
  4. 延迟 100ms 后 → `isBannerManuallyDragged = false`

## 注意事项

1. **天气 Banner**: 天气 Banner 不需要点击事件，因此不会上报埋点
2. **未绑定状态**: 点击定位/足迹 Banner 会显示绑定弹窗，不会跳转页面
3. **已绑定状态**: 点击定位 Banner 会检查会员状态，点击足迹 Banner 会直接跳转
4. **岛视图天气按钮**: 天气按钮没有点击事件，不会上报埋点
5. **异步上报**: 所有埋点方法都是异步的，使用 `await` 确保上报完成后再执行后续操作

## 测试建议

### 屏视图 Banner 测试

1. **自动播放点击测试**:
   - 等待 Banner 自动切换到定位 Banner
   - 点击定位 Banner
   - 检查埋点：`is_drag` 应为 "0"

2. **手动滑动点击测试**:
   - 手动滑动到足迹 Banner
   - 立即点击足迹 Banner
   - 检查埋点：`is_drag` 应为 "1"

3. **绑定状态测试**:
   - 未绑定状态：检查 `is_bind` 为 "未绑定"
   - 已绑定状态：检查 `is_bind` 为 "是绑定"

### 岛视图按钮测试

1. **足迹按钮点击测试**:
   - 点击足迹按钮
   - 检查埋点：`click_type` 应为 "足迹"

2. **定位按钮点击测试**:
   - 点击定位按钮
   - 检查埋点：`click_type` 应为 "定位"

3. **会员状态测试**:
   - 非会员状态：检查 `is_vip` 为 "不是会员"
   - 会员状态：检查 `is_vip` 为 "是会员"

## 相关文档

- [友盟埋点集成文档](umeng_analytics_integration.md)
- [TrackingService 使用指南](tracking_service_guide.md)
- [首页功能说明](home_page_features.md)

## 更新日志

- 2025/10/25: 初始版本，实现屏视图 Banner 和岛视图按钮埋点

