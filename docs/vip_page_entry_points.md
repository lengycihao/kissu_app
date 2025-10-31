# 会员页面入口埋点参数配置

## 概述

本文档记录所有跳转到会员页面的入口位置，以及传递的上个页面信息参数（`previousPageName` 和 `previousPageId`）。

## 入口列表

### 1. 我的页面 - 会员按钮

**文件**: `lib/pages/mine/mine_controller.dart`

**方法**: `onRenewTap()`

**跳转代码**:
```dart
Get.toNamed(
  KissuRoutePath.vip,
  arguments: {
    'previousPageName': '我的页面',
    'previousPageId': 'my_page',
  },
);
```

**说明**: 
- 页面已有埋点：`my_page`
- 从我的页面点击VIP按钮跳转
- 同时也会跳转到终身会员页面（foreverVip），参数相同

---

### 2. 足迹页面 - VIP遮罩层

**文件**: `lib/pages/track/track_page.dart`

**位置**: 遮罩层点击事件

**跳转代码**:
```dart
Get.toNamed(
  KissuRoutePath.vip,
  arguments: {
    'previousPageName': '足迹页面',
    'previousPageId': 'footprint_page',
  },
);
```

**说明**: 
- 页面已有埋点：`footprint_page`
- 非会员用户看到的VIP遮罩层点击后跳转

---

### 3. 定位页面 - 开通会员按钮

**文件**: `lib/pages/location/location_v2_controller.dart`

**方法**: `onOpenMembershipButtonTap()`

**跳转代码**:
```dart
Get.toNamed(
  KissuRoutePath.vip,
  arguments: {
    'previousPageName': '定位页面',
    'previousPageId': 'location_page',
  },
)?.then((_) {
  refreshUserInfo();
});
```

**说明**: 
- 页面已有埋点：`location_page`
- 点击定位页面的"开通会员"按钮跳转
- 返回后会刷新用户信息

---

### 4. 首页 - VIP购买弹窗

**文件**: `lib/pages/home/home_controller.dart`

**方法**: `_showVipPurchaseDialog()` 的 `onConfirm` 回调

**跳转代码**:
```dart
Get.toNamed(
  KissuRoutePath.vip,
  arguments: {
    'previousPageName': '首页',
    'previousPageId': 'undo', // 首页还没有单独的页面浏览埋点
  },
);
```

**说明**: 
- 页面暂无埋点：使用 `undo`
- 从首页的VIP购买弹窗点击"立即查看"按钮跳转

---

### 5. 屏幕使用详情页 - VIP遮罩层

**文件**: `lib/pages/usage_report/widgets/screen_time_detail_page.dart`

**位置**: VIP遮罩层点击事件

**跳转代码**:
```dart
await Get.toNamed(
  KissuRoutePath.vip,
  arguments: {
    'previousPageName': '屏幕使用详情页',
    'previousPageId': 'undo', // 该页面还没有埋点
  },
);
// VIP页面返回后刷新用户信息
await UserManager.refreshUserInfo();
_controller.loadData();
```

**说明**: 
- 页面暂无埋点：使用 `undo`
- 非会员用户看到的VIP遮罩层点击后跳转
- 返回后刷新用户信息并重新加载数据

---

### 6. 用机记录页面 - 通用记录项会员按钮

**文件**: `lib/pages/usage_report/common/generic_record_item.dart`

**方法**: `_onVipButtonTap()`

**跳转代码**:
```dart
Get.toNamed(
  KissuRoutePath.vip,
  arguments: {
    'previousPageName': '用机记录页面',
    'previousPageId': 'device_usage_record_page',
  },
)?.then((_) {
  _refreshVipStatus();
});
```

**说明**: 
- 页面已有埋点：`device_usage_record_page`
- 从用机记录的通用记录项点击会员按钮跳转
- 返回后刷新会员状态

---

### 7. 用机记录页面 - 解锁记录项会员按钮

**文件**: `lib/pages/usage_report/common/type19_unlock_record_item.dart`

**位置**: VIP遮罩层点击事件

**跳转代码**:
```dart
await Get.toNamed(
  KissuRoutePath.vip,
  arguments: {
    'previousPageName': '用机记录页面',
    'previousPageId': 'device_usage_record_page',
  },
);
await UserManager.refreshUserInfo();
onVipStatusChanged?.call();
```

**说明**: 
- 页面已有埋点：`device_usage_record_page`
- 从用机记录的解锁记录项点击会员按钮跳转
- 返回后刷新用户信息并通知父组件

---

### 8. 用机记录页面 - 屏幕时间项会员按钮

**文件**: `lib/pages/usage_report/common/screen_time_item.dart`

**位置**: VIP按钮点击事件

**跳转代码**:
```dart
await Get.toNamed(
  KissuRoutePath.vip,
  arguments: {
    'previousPageName': '用机记录页面',
    'previousPageId': 'device_usage_record_page',
  },
);
await UserManager.refreshUserInfo();
onVipStatusChanged?.call();
```

**说明**: 
- 页面已有埋点：`device_usage_record_page`
- 从用机记录的屏幕时间项点击会员按钮跳转
- 返回后刷新用户信息并通知父组件

---

## 埋点事件ID映射表

| 页面名称 | 埋点事件ID | 是否已有埋点 |
|---------|-----------|------------|
| 我的页面 | `my_page` | ✅ |
| 足迹页面 | `footprint_page` | ✅ |
| 定位页面 | `location_page` | ✅ |
| 首页 | `undo` | ❌ 暂无 |
| 屏幕使用详情页 | `undo` | ❌ 暂无 |
| 用机记录页面 | `device_usage_record_page` | ✅ |
| 状态页面 | `state_current_page` | ✅ |
| 位置提醒列表 | `location_knock_list_page` | ✅ |
| 添加地点页面 | `location_knock_address_add_page` | ✅ |
| 绑定页面 | `bind_page` | ✅ |
| 互动消息页面 | `message_center_page` | ✅ |
| 会员页面 | `membership_page` | ✅ |

---

## 使用规范

### 新增会员页面入口时

当需要新增一个跳转到会员页面的入口时，必须传递以下参数：

```dart
Get.toNamed(
  KissuRoutePath.vip,
  arguments: {
    'previousPageName': '页面中文名称',
    'previousPageId': '页面埋点事件ID', // 如果该页面还没有埋点，传 'undo'
  },
);
```

### 页面名称规范

- 使用中文全称，例如："我的页面"、"足迹页面"
- 保持简洁明了，便于数据分析

### 页面ID规范

- 如果页面已有浏览事件埋点，使用该埋点的事件ID
- 如果页面暂无埋点，统一使用 `undo`
- 页面ID应该是小写字母加下划线的格式，例如：`my_page`、`footprint_page`

---

## 注意事项

1. **参数传递**: 所有跳转到会员页面的地方都必须传递上个页面信息
2. **命名一致性**: 同一个页面在不同地方跳转时，传递的页面名称和ID必须一致
3. **埋点ID更新**: 如果某个页面后续添加了浏览埋点，需要更新所有相关入口的 `previousPageId`
4. **数据分析**: 通过这些参数，可以分析用户从哪些页面进入会员页面，优化转化路径

---

## 更新日期

2025-10-30

