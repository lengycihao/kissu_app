# 底部导航埋点实现文档

## 概述

本文档说明了首页底部导航栏的埋点实现，用于追踪用户在底部导航栏的点击行为。

## 埋点事件

### 底部导航点击事件

**事件ID**: `bottom_navigation`

**触发时机**: 用户点击首页底部导航栏的任意按钮

**参数说明**:

| 参数名 | 类型 | 说明 | 示例值 |
|--------|------|------|--------|
| device_id | String | 虚拟用户ID（通过设备号生成） | "abc123..." |
| user_id | String | 用户ID（已登录时） | "12345" |
| click_time | String | 点击时间（格式：年/月/日 时:分:秒） | "2025/10/25 14:30:45" |
| bottom_name | String | 底部导航名称 | "定位"、"足迹"、"用机记录"、"我的" |

**bottom_name 可能的值**:

| 索引 | 导航名称 | 说明 |
|------|---------|------|
| 0 | 定位 | 跳转到定位页面（会检查会员状态） |
| 1 | 足迹 | 跳转到足迹（地图）页面 |
| 2 | 用机记录 | 跳转到用机记录页面 |
| 3 | 我的 | 跳转到我的页面 |

## 代码实现位置

### TrackingService（埋点服务）

**文件**: `lib/services/tracking_service.dart`

**方法**: `trackBottomNavigationClick()`

**方法签名**:

```dart
static Future<void> trackBottomNavigationClick({
  required String bottomName,
}) async
```

**使用示例**:

```dart
// 点击定位按钮
await TrackingService.trackBottomNavigationClick(bottomName: '定位');

// 点击足迹按钮
await TrackingService.trackBottomNavigationClick(bottomName: '足迹');

// 点击用机记录按钮
await TrackingService.trackBottomNavigationClick(bottomName: '用机记录');

// 点击我的按钮
await TrackingService.trackBottomNavigationClick(bottomName: '我的');
```

### HomeController（首页控制器）

**文件**: `lib/pages/home/home_controller.dart`

**方法**: `onButtonTap(int index)`

**实现逻辑**:

1. 根据点击的按钮索引（index）确定导航名称（bottomName）
2. 调用埋点方法上报点击事件
3. 执行对应的页面跳转逻辑

**代码示例**:

```dart
void onButtonTap(int index) async {
  selectedIndex.value = index;
  debugPrint("🔍 底部导航按钮 $index 被点击");

  // 获取底部导航名称
  String bottomName = '';
  switch (index) {
    case 0:
      bottomName = '定位';
      break;
    case 1:
      bottomName = '足迹';
      break;
    case 2:
      bottomName = '用机记录';
      break;
    case 3:
      bottomName = '我的';
      break;
  }

  // 埋点：底部导航点击
  if (bottomName.isNotEmpty) {
    await TrackingService.trackBottomNavigationClick(bottomName: bottomName);
  }

  // 执行导航逻辑
  switch (index) {
    case 0:
      // 定位（新版）- 添加会员检查
      VipNavigationHelper.navigateToLocationWithVipCheck();
      break;
    case 1:
      // 地图
      Get.to(() => TrackPage(), binding: TrackBinding());
      break;
    case 2:
      // 用机记录
      Get.to(() => const UsageReportPage(), binding: UsageReportBinding());
      break;
    case 3:
      // 我的 - 每次点击时刷新数据
      _navigateToMinePage();
      break;
  }
}
```

### HomePage（首页视图）

**文件**: `lib/pages/home/home_page.dart`

**位置**: 底部导航栏容器（约 215-257 行）

底部导航栏使用 `InkWell` 包裹，点击时调用 `controller.onButtonTap(index)` 方法：

```dart
Align(
  alignment: Alignment.bottomCenter,
  child: Container(
    height: 90,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFFFD4D0), width: 1),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(4, (index) {
        return InkWell(
          onTap: () => controller.onButtonTap(index),
          borderRadius: BorderRadius.circular(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                controller.getTopIconPath(index),
                width: 42,
                height: 42,
              ),
              Image.asset(
                controller.getBottomIconPath(index),
                width: index == 2 ? 48 : 24,
                height: 14,
                fit: BoxFit.contain,
              ),
            ],
          ),
        );
      }),
    ),
  ),
)
```

## 工作流程

### 用户点击底部导航按钮

1. **用户点击**: 用户点击底部导航栏的任意按钮
2. **触发回调**: `InkWell` 的 `onTap` 回调触发，调用 `controller.onButtonTap(index)`
3. **确定名称**: 根据按钮索引（0-3）确定导航名称
4. **上报埋点**: 调用 `TrackingService.trackBottomNavigationClick()` 上报埋点
5. **执行导航**: 根据按钮索引执行对应的页面跳转逻辑

### 时序图

```
用户点击按钮
    ↓
InkWell.onTap
    ↓
HomeController.onButtonTap(index)
    ↓
确定 bottomName (定位/足迹/用机记录/我的)
    ↓
TrackingService.trackBottomNavigationClick(bottomName)
    ↓
构建埋点参数 (device_id, user_id, click_time, bottom_name)
    ↓
UmengAnalytics.trackEvent('bottom_navigation', params)
    ↓
执行页面跳转逻辑
```

## 特殊说明

### 1. 定位按钮的会员检查

点击定位按钮时，会通过 `VipNavigationHelper.navigateToLocationWithVipCheck()` 检查用户的会员状态：
- **非会员**: 弹出会员开通弹窗
- **会员**: 直接跳转到定位页面

**注意**: 无论是否弹出会员弹窗，都会上报埋点。

### 2. 我的按钮的刷新逻辑

点击我的按钮时，会调用 `_navigateToMinePage()` 方法，该方法会：
1. 刷新用户数据
2. 跳转到我的页面

### 3. 异步上报

埋点方法是异步的（`async/await`），确保埋点上报完成后再执行页面跳转逻辑。

## 测试建议

### 功能测试

1. **定位按钮点击测试**:
   - 点击定位按钮
   - 检查埋点：`bottom_name` 应为 "定位"
   - 验证会员检查逻辑是否正常

2. **足迹按钮点击测试**:
   - 点击足迹按钮
   - 检查埋点：`bottom_name` 应为 "足迹"
   - 验证是否跳转到足迹页面

3. **用机记录按钮点击测试**:
   - 点击用机记录按钮
   - 检查埋点：`bottom_name` 应为 "用机记录"
   - 验证是否跳转到用机记录页面

4. **我的按钮点击测试**:
   - 点击我的按钮
   - 检查埋点：`bottom_name` 应为 "我的"
   - 验证是否跳转到我的页面

### 参数验证

1. **device_id**: 验证虚拟用户ID是否正确生成
2. **user_id**: 验证已登录用户的ID是否正确获取
3. **click_time**: 验证点击时间格式是否正确（年/月/日 时:分:秒）
4. **bottom_name**: 验证导航名称是否与点击的按钮对应

### 埋点数据验证

可以通过以下方式验证埋点数据：

1. **查看日志**: 在控制台查看埋点日志
   ```
   ✅ 底部导航点击埋点：上报数据成功 - {device_id: xxx, user_id: xxx, click_time: 2025/10/25 14:30:45, bottom_name: 定位}
   ```

2. **友盟后台**: 登录友盟后台，查看 `bottom_navigation` 事件的数据

3. **调试模式**: 在友盟 SDK 的调试模式下，实时查看埋点上报情况

## 注意事项

1. **埋点优先**: 埋点上报在页面跳转之前执行，确保数据不丢失
2. **异步处理**: 使用 `await` 确保埋点上报完成后再执行后续操作
3. **错误处理**: 埋点方法内部有 try-catch，上报失败不会影响页面跳转
4. **参数一致性**: 确保 `bottom_name` 的值与 API 文档保持一致
5. **索引映射**: 底部导航按钮的索引（0-3）与导航名称的映射关系要保持正确

## 相关文档

- [友盟埋点集成文档](umeng_analytics_integration.md)
- [TrackingService 使用指南](tracking_service_guide.md)
- [首页 Banner/岛视图埋点文档](home_page_banner_island_tracking.md)
- [首页功能说明](home_page_features.md)

## 更新日志

- 2025/10/25: 初始版本，实现底部导航点击埋点

