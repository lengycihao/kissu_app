# 我的页面点击事件埋点实现文档

## 概述

本文档详细说明了在我的页面（Mine Page）中实现的13个点击事件埋点，包括事件名称、参数、触发时机和代码位置。

## 实现原理

所有埋点方法统一在 `TrackingService` 中实现，包含以下通用参数：
- `device_id`: 虚拟用户ID（通过设备号生成）
- `user_id`: 用户ID
- `click_time`: 点击时间（格式：年/月/日 时:分:秒）

## 埋点事件列表

### 1. 我的页面-返回 (my_leave_event)

**事件ID**: `my_leave_event`

**事件类型**: 点击事件

**参数**:
- device_id: 虚拟用户ID
- user_id: 用户ID
- click_time: 点击时间

**触发场景**: 用户点击我的页面的返回按钮

**代码位置**:
- 埋点方法: `lib/services/tracking_service.dart` - `TrackingService.trackMyLeaveEvent()`
- 调用位置: `lib/pages/mine/mine_controller.dart` - `MineController.onBackTap()`

**实现代码**:
```dart
void onBackTap() {
  // 上报返回按钮点击埋点
  TrackingService.trackMyLeaveEvent();
  Get.back();
}
```

---

### 2. 恋爱信息入口点击 (edit_info_page)

**事件ID**: `edit_info_page`

**事件类型**: 点击事件

**参数**:
- device_id: 虚拟用户ID
- user_id: 用户ID
- click_time: 点击时间

**触发场景**: 用户点击恋爱信息入口（包括标签、已绑定状态下的头像）

**代码位置**:
- 埋点方法: `lib/services/tracking_service.dart` - `TrackingService.trackEditInfoPage()`
- 调用位置: 
  - `lib/pages/mine/mine_controller.dart` - `MineController.onLabelTap()`
  - `lib/pages/mine/mine_controller.dart` - `MineController.onAvatarTap()`
  - `lib/pages/mine/mine_controller.dart` - `MineController.onPartnerAvatarTap()` (已绑定状态)

**实现代码**:
```dart
void onLabelTap() async {
  // 上报恋爱信息入口点击埋点
  await TrackingService.trackEditInfoPage();
  
  await Get.to(
    LoveInfoPage(),
    transition: Transition.rightToLeft,
  );
  onPageResumed();
}
```

---

### 3. 绑定页面 (my_bind_page)

**事件ID**: `my_bind_page`

**事件类型**: 点击事件

**参数**:
- device_id: 虚拟用户ID
- user_id: 用户ID
- click_time: 点击时间

**触发场景**: 用户在未绑定状态下点击另一半头像，打开绑定弹窗

**代码位置**:
- 埋点方法: `lib/services/tracking_service.dart` - `TrackingService.trackMyBindPage()`
- 调用位置: `lib/pages/mine/mine_controller.dart` - `MineController.onPartnerAvatarTap()` (未绑定状态)

**实现代码**:
```dart
void onPartnerAvatarTap() async {
  if (!isBound.value) {
    // 上报绑定页面点击埋点
    await TrackingService.trackMyBindPage();
    
    if (Get.context != null) {
      CustomBottomDialog.show(
        context: Get.context!,
        caller: BindingDialogCaller.mine,
      );
    }
  } else {
    await TrackingService.trackEditInfoPage();
    // ...跳转到恋爱信息页面
  }
}
```

---

### 4. 开通会员 (my_open_membership)

**事件ID**: `my_open_membership`

**事件类型**: 点击事件

**参数**:
- device_id: 虚拟用户ID
- user_id: 用户ID
- click_time: 点击时间
- vip_page_type: 会员页面类型（"会员页面" 或 "终身会员页面"）

**触发场景**: 用户点击会员相关按钮，根据会员状态跳转到不同页面

**代码位置**:
- 埋点方法: `lib/services/tracking_service.dart` - `TrackingService.trackMyOpenMembership()`
- 调用位置: `lib/pages/mine/mine_controller.dart` - `MineController.onRenewTap()`

**实现代码**:
```dart
void onRenewTap() async {
  if (isForeverVip.value) {
    // 上报开通会员点击埋点（终身会员页面）
    await TrackingService.trackMyOpenMembership(vipPageType: '终身会员页面');
    Get.toNamed(KissuRoutePath.foreverVip);
  } else {
    // 上报开通会员点击埋点（会员页面）
    await TrackingService.trackMyOpenMembership(vipPageType: '会员页面');
    Get.toNamed(KissuRoutePath.vip);
  }
}
```

---

### 5. 意见与反馈 (feedback)

**事件ID**: `feedback`

**事件类型**: 点击事件

**参数**:
- device_id: 虚拟用户ID
- user_id: 用户ID
- click_time: 点击时间

**触发场景**: 用户点击意见与反馈菜单项

**代码位置**:
- 埋点方法: `lib/services/tracking_service.dart` - `TrackingService.trackFeedback()`
- 调用位置: `lib/pages/mine/mine_controller.dart` - `_initSettingItems()` 中的 "意见反馈" 设置项

**实现代码**:
```dart
SettingItem(
  icon: "assets/kissu_mine_item_yjfk.webp",
  title: "意见反馈",
  onTap: () async {
    await TrackingService.trackFeedback();
    Get.toNamed(KissuRoutePath.feedback);
  },
),
```

---

### 6. 联系我们 (contact_customer_service)

**事件ID**: `contact_customer_service`

**事件类型**: 点击事件

**参数**:
- device_id: 虚拟用户ID
- user_id: 用户ID
- click_time: 点击时间

**触发场景**: 用户点击联系我们菜单项

**代码位置**:
- 埋点方法: `lib/services/tracking_service.dart` - `TrackingService.trackContactCustomerService()`
- 调用位置: 
  - `lib/pages/mine/mine_controller.dart` - `_onContactTap()`
  - `lib/pages/mine/mine_controller.dart` - `_initSettingItems()` 中的 "联系我们" 设置项

**实现代码**:
```dart
void _onContactTap() async {
  // 上报联系我们点击埋点
  await TrackingService.trackContactCustomerService();
  openContact();
}
```

---

### 7. 关于我们 (about_us)

**事件ID**: `about_us`

**事件类型**: 点击事件

**参数**:
- device_id: 虚拟用户ID
- user_id: 用户ID
- click_time: 点击时间

**触发场景**: 用户点击关于我们菜单项

**代码位置**:
- 埋点方法: `lib/services/tracking_service.dart` - `TrackingService.trackAboutUs()`
- 调用位置: `lib/pages/mine/mine_controller.dart` - `_initSettingItems()` 中的 "关于我们" 设置项

**实现代码**:
```dart
SettingItem(
  icon: "assets/kissu_mine_item_gywm.webp",
  title: "关于我们",
  onTap: () async {
    await TrackingService.trackAboutUs();
    Get.to(
      AboutUsPage(),
      transition: Transition.rightToLeft,
    );
  },
),
```

---

### 8. 首页视图 (home_view)

**事件ID**: `home_view`

**事件类型**: 点击事件

**参数**:
- device_id: 虚拟用户ID
- user_id: 用户ID
- click_time: 点击时间

**触发场景**: 用户点击首页视图菜单项

**代码位置**:
- 埋点方法: `lib/services/tracking_service.dart` - `TrackingService.trackHomeView()`
- 调用位置: `lib/pages/mine/mine_controller.dart` - `_initSettingItems()` 中的 "首页视图" 设置项

**实现代码**:
```dart
SettingItem(
  icon: "assets/kissu_mine_item_syst.webp",
  title: "首页视图",
  onTap: () async {
    await TrackingService.trackHomeView();
    Get.to(
      SettingHomePage(),
      transition: Transition.rightToLeft,
    );
  },
),
```

---

### 9. 系统权限 (system_permissions)

**事件ID**: `system_permissions`

**事件类型**: 点击事件

**参数**:
- device_id: 虚拟用户ID
- user_id: 用户ID
- click_time: 点击时间

**触发场景**: 用户点击系统权限菜单项

**代码位置**:
- 埋点方法: `lib/services/tracking_service.dart` - `TrackingService.trackSystemPermissions()`
- 调用位置: `lib/pages/mine/mine_controller.dart` - `_initSettingItems()` 中的 "系统权限" 设置项

**实现代码**:
```dart
SettingItem(
  icon: "assets/kissu_mine_item_xtqx.webp",
  title: "系统权限",
  onTap: () async {
    await TrackingService.trackSystemPermissions();
    Get.toNamed(KissuRoutePath.systemPermission);
  },
),
```

---

### 10. 常见问题 (faq)

**事件ID**: `faq`

**事件类型**: 点击事件

**参数**:
- device_id: 虚拟用户ID
- user_id: 用户ID
- click_time: 点击时间

**触发场景**: 用户点击常见问题菜单项

**代码位置**:
- 埋点方法: `lib/services/tracking_service.dart` - `TrackingService.trackFaq()`
- 调用位置: `lib/pages/mine/mine_controller.dart` - `_initSettingItems()` 中的 "常见问题" 设置项

**实现代码**:
```dart
SettingItem(
  icon: "assets/kissu_mine_item_cjwt.webp",
  title: "常见问题",
  onTap: () async {
    await TrackingService.trackFaq();
    Get.to(
      QuestionPage(),
      transition: Transition.rightToLeft,
    );
  },
),
```

---

### 11. 账号及隐私安全 (account_privacy_security)

**事件ID**: `account_privacy_security`

**事件类型**: 点击事件

**参数**:
- device_id: 虚拟用户ID
- user_id: 用户ID
- click_time: 点击时间

**触发场景**: 用户点击账号及隐私安全菜单项

**代码位置**:
- 埋点方法: `lib/services/tracking_service.dart` - `TrackingService.trackAccountPrivacySecurity()`
- 调用位置: `lib/pages/mine/mine_controller.dart` - `_initSettingItems()` 中的 "账号及隐私安全" 设置项

**实现代码**:
```dart
SettingItem(
  icon: "assets/kissu_mine_item_ysaq.webp",
  title: "账号及隐私安全",
  onTap: () async {
    await TrackingService.trackAccountPrivacySecurity();
    Get.to(
      PrivacySettingPage(),
      transition: Transition.rightToLeft,
    );
  },
),
```

---

### 12. 分享App (my_share)

**事件ID**: `my_share`

**事件类型**: 点击事件

**参数**:
- device_id: 虚拟用户ID
- user_id: 用户ID
- click_time: 点击时间

**触发场景**: 用户点击分享APP菜单项

**代码位置**:
- 埋点方法: `lib/services/tracking_service.dart` - `TrackingService.trackMyShare()`
- 调用位置: `lib/pages/mine/mine_controller.dart` - `_onShareAppTap()`

**实现代码**:
```dart
void _onShareAppTap() async {
  // 上报分享App点击埋点
  await TrackingService.trackMyShare();
  ShareBottomSheet.showShareApp(Get.context!);
}
```

---

### 13. 防偷拍检查 (safe_check)

**事件ID**: `safe_check`

**事件类型**: 点击事件

**参数**:
- device_id: 虚拟用户ID
- user_id: 用户ID
- click_time: 点击时间

**触发场景**: 用户点击防偷拍检查菜单项

**代码位置**:
- 埋点方法: `lib/services/tracking_service.dart` - `TrackingService.trackSafeCheck()`
- 调用位置: `lib/pages/mine/mine_controller.dart` - `_onAntiSpyTap()`

**实现代码**:
```dart
void _onAntiSpyTap() async {
  // 上报防偷拍检查点击埋点
  await TrackingService.trackSafeCheck();
  Get.toNamed(KissuRoutePath.antiSpy);
}
```

---

## 修改的文件

### 1. lib/services/tracking_service.dart
- 新增13个静态埋点方法
- 所有方法使用统一的参数构建（`_buildBaseParams()`）和事件上报（`_trackEvent()`）

### 2. lib/pages/mine/mine_controller.dart
修改的方法：
- `onBackTap()`: 添加返回事件埋点
- `onLabelTap()`: 添加恋爱信息入口点击埋点
- `onPartnerAvatarTap()`: 根据绑定状态分别添加绑定页面/恋爱信息入口埋点
- `onAvatarTap()`: 添加恋爱信息入口点击埋点（已绑定状态）
- `onRenewTap()`: 添加开通会员埋点，传递不同的页面类型参数
- `_onShareAppTap()`: 添加分享App埋点
- `_onAntiSpyTap()`: 添加防偷拍检查埋点
- `_onContactTap()`: 新增方法，添加联系我们埋点
- `_initSettingItems()`: 为各设置项的 onTap 添加对应埋点

## 注意事项

1. **异步处理**: 所有埋点调用都使用 `await`，确保在执行后续操作前完成埋点上报
2. **状态判断**: `onPartnerAvatarTap()` 和 `onRenewTap()` 根据用户状态上报不同的埋点
3. **时间格式**: 点击时间自动在 `_buildBaseParams()` 中生成，格式为 "年/月/日 时:分:秒"
4. **用户ID**: 如果用户未登录，`user_id` 字段会为空字符串
5. **设备ID**: 使用设备唯一标识符生成虚拟用户ID

## 测试建议

1. 测试每个菜单项的点击，确认埋点正常触发
2. 测试绑定状态切换时，头像点击是否触发正确的埋点
3. 测试会员状态切换时，VIP按钮是否传递正确的页面类型
4. 检查友盟后台，确认所有事件都能正常接收和统计

## 更新日期

2025-10-30

