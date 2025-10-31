# 绑定页面埋点集成文档

## 📋 概述
本文档记录了**绑定页面**（`CustomBottomDialog`）的友盟埋点集成实现。绑定页面是一个底部弹窗，用户可以通过输入匹配码、扫描二维码或分享等方式绑定另一半。

---

## 🎯 埋点事件列表

### 1. 页面浏览埋点
**事件名称**: `bind_page`  
**事件类型**: 浏览事件  
**触发时机**: 用户关闭绑定弹窗时

#### 参数说明
| 参数名 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `device_id` | String | 虚拟用户ID（通过设备号生成） | "abc123..." |
| `user_id` | String | 用户ID | "12345" |
| `stay_duration` | String | 页面停留时长 | "2s", "30s", "120s" |
| `previous_name` | String | 上一个页面名称 | "首页", "定位页面", "足迹页面" |
| `previous_id` | String | 上一个页面ID | "home", "location", "track" |

#### 实现位置
- **Service**: `TrackingService.trackBindPageView()`
- **Controller**: `CustomBottomDialogController`
- **上报时机**: 弹窗关闭时（`onClose()`）计算停留时长后上报

### 2. 绑定按钮点击埋点
**事件名称**: `bind_code_button`  
**事件类型**: 点击事件  
**触发时机**: 用户输入匹配码后点击确认绑定按钮时

#### 参数说明
| 参数名 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `device_id` | String | 虚拟用户ID | "abc123..." |
| `user_id` | String | 用户ID | "12345" |
| `click_time` | String | 点击时间（年/月/日 时:分:秒） | "2025/10/30 14:30:25" |

#### 实现位置
- **Service**: `TrackingService.trackBindCodeButton()`
- **Controller**: `CustomBottomDialogController.bindPartner()`
- **上报时机**: 点击确认按钮时，在调用绑定API之前

### 3. 微信邀请点击埋点
**事件名称**: `wechat_invite`  
**事件类型**: 点击事件  
**触发时机**: 用户点击微信分享按钮时

#### 参数说明
| 参数名 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `device_id` | String | 虚拟用户ID | "abc123..." |
| `user_id` | String | 用户ID | "12345" |
| `click_time` | String | 点击时间（年/月/日 时:分:秒） | "2025/10/30 14:30:25" |

#### 实现位置
- **Service**: `TrackingService.trackWechatInvite()`
- **Controller**: `CustomBottomDialogController.shareToWechat()`
- **上报时机**: 点击微信分享按钮时，在关闭弹窗之前

### 4. QQ邀请点击埋点
**事件名称**: `qq_invite`  
**事件类型**: 点击事件  
**触发时机**: 用户点击QQ分享按钮时

#### 参数说明
| 参数名 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `device_id` | String | 虚拟用户ID | "abc123..." |
| `user_id` | String | 用户ID | "12345" |
| `click_time` | String | 点击时间（年/月/日 时:分:秒） | "2025/10/30 14:30:25" |

#### 实现位置
- **Service**: `TrackingService.trackQQInvite()`
- **Controller**: `CustomBottomDialogController.shareToQQ()`
- **上报时机**: 点击QQ分享按钮时，在关闭弹窗之前

### 5. 扫码按钮点击埋点
**事件名称**: `scan_to_bind`  
**事件类型**: 点击事件  
**触发时机**: 用户点击扫描二维码按钮时

#### 参数说明
| 参数名 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `device_id` | String | 虚拟用户ID | "abc123..." |
| `user_id` | String | 用户ID | "12345" |
| `click_time` | String | 点击时间（年/月/日 时:分:秒） | "2025/10/30 14:30:25" |

#### 实现位置
- **Service**: `TrackingService.trackScanToBind()`
- **Controller**: `CustomBottomDialogController.scanQRCode()`
- **上报时机**: 点击扫码按钮时，在跳转到扫码页面之前

---

## 🔧 实现细节

### 1. TrackingService 中的埋点方法

在 `lib/services/tracking_service.dart` 中添加了5个埋点方法：

#### 1.1 页面浏览埋点
```dart
/// 埋点：绑定页面 - 浏览事件
static Future<void> trackBindPageView({
  required String stayDuration,
  required String previousName,
  required String previousId,
}) async {
  try {
    final params = await _buildBaseParams();
    params.remove('click_time');
    params['stay_duration'] = stayDuration;
    params['previous_name'] = previousName;
    params['previous_id'] = previousId;
    await _trackEvent('bind_page', params, '绑定页面-浏览事件');
  } catch (e) {
    debugPrint('❌ 绑定页面浏览埋点：上报数据失败 - $e');
  }
}
```

#### 1.2 绑定按钮埋点
```dart
/// 埋点：绑定按钮 - 点击事件
static Future<void> trackBindCodeButton() async {
  final params = await _buildBaseParams();
  await _trackEvent('bind_code_button', params, '绑定按钮点击');
}
```

#### 1.3 微信邀请埋点
```dart
/// 埋点：微信邀请 - 点击事件
static Future<void> trackWechatInvite() async {
  final params = await _buildBaseParams();
  await _trackEvent('wechat_invite', params, '微信邀请点击');
}
```

#### 1.4 QQ邀请埋点
```dart
/// 埋点：QQ邀请 - 点击事件
static Future<void> trackQQInvite() async {
  final params = await _buildBaseParams();
  await _trackEvent('qq_invite', params, 'QQ邀请点击');
}
```

#### 1.5 扫码按钮埋点
```dart
/// 埋点：扫码按钮 - 点击事件
static Future<void> trackScanToBind() async {
  final params = await _buildBaseParams();
  await _trackEvent('scan_to_bind', params, '扫码按钮点击');
}
```

### 2. CustomBottomDialogController 中的实现

在 `lib/widgets/dialogs/custom_bottom_dialog_controller.dart` 中添加了页面浏览时长统计和各按钮埋点上报：

#### 2.1 页面浏览时长统计
```dart
// 页面浏览时长统计
DateTime? _pageEnterTime;

@override
void onInit() {
  super.onInit();
  // 记录页面进入时间（用于计算停留时长）
  _pageEnterTime = DateTime.now();
  _loadUserInfo();
}

@override
void onClose() {
  // 上报页面浏览埋点
  _trackPageView();
  matchCodeController.dispose();
  super.onClose();
}
```

#### 2.2 绑定按钮埋点集成
```dart
/// 绑定另一半
Future<void> bindPartner() async {
  // ... 验证逻辑
  
  try {
    isLoading.value = true;
    
    // 上报绑定按钮点击埋点
    await TrackingService.trackBindCodeButton();
    
    // 调用绑定API
    final authApi = AuthApi();
    final result = await authApi.bindPartner(friendCode: inputCode);
    
    // ... 处理结果
  } catch (e) {
    OKToastUtil.show('绑定失败: $e');
  } finally {
    isLoading.value = false;
  }
}
```

#### 2.3 分享按钮埋点集成
```dart
/// 分享到QQ
void shareToQQ() {
  // 上报QQ邀请埋点
  TrackingService.trackQQInvite();
  Get.back();
  _shareInvite(target: 'QQ');
}

/// 分享到微信
void shareToWechat() {
  // 上报微信邀请埋点
  TrackingService.trackWechatInvite();
  Get.back();
  _shareInvite(target: '微信');
}
```

#### 2.4 扫码按钮埋点集成
```dart
/// 扫描二维码
void scanQRCode() {
  // 上报扫码按钮埋点
  TrackingService.trackScanToBind();
  
  Get.toNamed(KissuRoutePath.qrScanPage)?.then((value) {
    // ... 处理扫码结果
  });
}
```

### 3. 上一个页面信息的获取

通过 `BindingDialogCaller` 枚举来识别调用者页面，映射到对应的页面名称和ID：

```dart
/// 获取上一个页面信息（基于调用者类型）
Map<String, String> _getPreviousPageInfo() {
  if (caller == null) {
    return {'name': '未知页面', 'id': 'unknown'};
  }
  
  switch (caller!) {
    case BindingDialogCaller.home:
      return {'name': '首页', 'id': 'home'};
    case BindingDialogCaller.mine:
      return {'name': '我的页面', 'id': 'mine'};
    case BindingDialogCaller.loveInfo:
      return {'name': '恋爱信息页面', 'id': 'love_info'};
    case BindingDialogCaller.track:
      return {'name': '足迹页面', 'id': 'track'};
    case BindingDialogCaller.location:
      return {'name': '定位页面', 'id': 'location'};
    case BindingDialogCaller.usageReport:
      return {'name': '用机记录页面', 'id': 'usage_report'};
  }
}
```

---

## 📌 调用者页面映射表

| BindingDialogCaller | 页面名称 | 页面ID |
|---------------------|---------|--------|
| home | 首页 | home |
| mine | 我的页面 | mine |
| loveInfo | 恋爱信息页面 | love_info |
| track | 足迹页面 | track |
| location | 定位页面 | location |
| usageReport | 用机记录页面 | usage_report |

---

## 🎬 触发流程

### 页面浏览埋点流程
1. **用户打开绑定弹窗**
   - 各个页面调用 `CustomBottomDialog.show()`，并传入 `caller` 参数
   - Controller 在 `onInit()` 中记录进入时间

2. **用户在弹窗中操作**
   - 输入匹配码、扫描二维码、分享等操作
   - 可能绑定成功，也可能直接关闭

3. **用户关闭绑定弹窗**
   - Controller 在 `onClose()` 中触发埋点上报
   - 计算停留时长（当前时间 - 进入时间）
   - 根据 `caller` 获取上一个页面信息
   - 调用 `TrackingService.trackBindPageView()` 上报数据

### 按钮点击埋点流程
1. **绑定按钮**：用户输入匹配码 → 点击确认 → 上报埋点 → 调用API
2. **微信邀请**：用户点击微信图标 → 上报埋点 → 关闭弹窗 → 调起微信分享
3. **QQ邀请**：用户点击QQ图标 → 上报埋点 → 关闭弹窗 → 调起QQ分享
4. **扫码按钮**：用户点击扫码图标 → 上报埋点 → 跳转到扫码页面

---

## ✅ 验证要点

### 页面浏览埋点
1. **停留时长计算准确**：关闭弹窗时正确计算秒数
2. **上一个页面识别正确**：根据 `caller` 正确映射页面名称和ID
3. **埋点参数完整**：device_id、user_id、stay_duration、previous_name、previous_id 都正确上报
4. **兼容所有调用场景**：从首页、我的页面、足迹页面等各个入口都能正确上报

### 按钮点击埋点
1. **绑定按钮**：点击确认时上报，包含device_id、user_id、click_time
2. **微信/QQ邀请**：点击分享按钮时上报，包含device_id、user_id、click_time
3. **扫码按钮**：点击扫码按钮时上报，包含device_id、user_id、click_time
4. **时间格式正确**：click_time格式为"年/月/日 时:分:秒"

---

## 📝 变更日期

2025-10-30

---

## 🔗 相关文件

- `lib/services/tracking_service.dart` - 埋点服务类
- `lib/widgets/dialogs/custom_bottom_dialog_controller.dart` - 绑定弹窗控制器
- `lib/widgets/dialogs/custom_bottom_dialog.dart` - 绑定弹窗UI组件
- `api_type.md` - 埋点事件定义文档

