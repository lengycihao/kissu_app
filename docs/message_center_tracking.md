# 互动消息页面（消息中心）埋点实现文档

## 概述

本文档详细说明了在互动消息页面（消息中心）中实现的3个埋点事件，包括事件名称、参数、触发时机和代码位置。

## 实现原理

所有埋点方法统一在 `TrackingService` 中实现，涵盖浏览事件和点击事件。

## 埋点事件列表

### 1. 互动消息页面 - 浏览事件 (message_center_page)

**事件ID**: `message_center_page`

**事件类型**: 浏览事件

**参数**:
- device_id: 虚拟用户ID
- user_id: 用户ID
- stay_duration: 页面停留时长（如：2s）
- can_scroll: 页面是否滑动（是/否）
- is_bind: 情侣绑定状态（已绑定/未绑定）

**触发场景**: 用户退出消息中心页面时，自动上报页面浏览数据

**代码位置**:
- 埋点方法: `lib/services/tracking_service.dart` - `TrackingService.trackMessageCenterPageView()`
- 调用位置: `lib/pages/message_center/message_center_controller.dart` - `MessageCenterController.onClose()` → `_trackPageView()`

**实现逻辑**:

1. **页面进入时**（`onInit()`）:
   - 记录进入时间: `_pageEnterTime = DateTime.now()`
   - 初始化滚动控制器: `scrollController = ScrollController()`
   - 初始化滚动检测变量: `hasScrolled`, `scrollTimes`

2. **页面滚动时**（`handleScroll()`）:
   - 监听 `ScrollUpdateNotification`
   - 当滑动距离 > 10px 时，标记 `hasScrolled = true`
   - 累计滚动次数 `scrollTimes++`

3. **页面退出时**（`onClose()` → `_trackPageView()`）:
   - 计算停留时长: `DateTime.now().difference(_pageEnterTime)`
   - 获取绑定状态: `user?.isHalfUser == 1 ? '已绑定' : '未绑定'`
   - 上报埋点数据

**实现代码**:

```dart
// Controller 中的实现
@override
void onInit() {
  super.onInit();
  
  // 记录进入时间
  _pageEnterTime = DateTime.now();
  
  // 初始化滚动控制器
  scrollController = ScrollController();
  
  loadMessages();
}

@override
void onClose() {
  // 上报页面浏览埋点
  _trackPageView();
  
  // 释放滚动控制器
  scrollController.dispose();
  
  super.onClose();
}

/// 处理滚动事件
bool handleScroll(ScrollNotification notification) {
  if (notification is ScrollUpdateNotification) {
    final delta = notification.scrollDelta ?? 0;
    if (delta.abs() > 10) {
      if (!hasScrolled.value) {
        hasScrolled.value = true;
      }
      scrollTimes.value++;
    }
  }
  return false;
}

/// 上报页面浏览埋点
Future<void> _trackPageView() async {
  if (_pageEnterTime == null) return;
  
  try {
    final duration = DateTime.now().difference(_pageEnterTime!);
    final seconds = duration.inSeconds;
    final stayDuration = '${seconds}s';
    
    // 获取绑定状态
    final user = UserManager.currentUser;
    final isBind = (user?.isHalfUser == 1) ? '已绑定' : '未绑定';
    
    await TrackingService.trackMessageCenterPageView(
      stayDuration: stayDuration,
      canScroll: hasScrolled.value,
      isBind: isBind,
    );
    
    debugPrint('✅ 互动消息页面浏览埋点上报成功');
  } catch (e) {
    debugPrint('❌ 互动消息页面浏览埋点上报失败: $e');
  }
}
```

**UI 集成**（`message_center_page.dart`）:

```dart
return NotificationListener<ScrollNotification>(
  onNotification: (notification) {
    controller.handleScroll(notification);
    return false;
  },
  child: ListView.builder(
    controller: controller.scrollController,
    physics: const AlwaysScrollableScrollPhysics(),
    // ...
  ),
);
```

---

### 2. 接收绑定按钮 - 点击事件 (accept_bind_button)

**事件ID**: `accept_bind_button`

**事件类型**: 点击事件

**参数**:
- device_id: 虚拟用户ID
- user_id: 用户ID
- click_time: 点击时间（格式：年/月/日 时:分:秒）
- other_id: 绑定情侣id

**触发场景**: 用户在消息中心点击"同意绑定"按钮时

**代码位置**:
- 埋点方法: `lib/services/tracking_service.dart` - `TrackingService.trackAcceptBindButton()`
- 调用位置: `lib/pages/message_center/message_center_controller.dart` - `MessageCenterController._affirmBind()`

**实现代码**:

```dart
/// 同意绑定
Future<void> _affirmBind(MessageItem message) async {
  try {
    debugPrint('开始同意绑定，消息ID: ${message.id}');
    
    // 上报接收绑定按钮点击埋点
    await TrackingService.trackAcceptBindButton(
      otherId: message.fromUserId.isNotEmpty ? message.fromUserId : message.id,
    );
    
    final result = await HttpManagerN.instance.executePost(
      ApiRequest.affirmBind,
      jsonParam: {'system_notice_id': message.id},
      paramEncrypt: false,
    );
    
    if (result.isSuccess) {
      CustomToast.show(Get.context!, '绑定成功');
      
      // 刷新用户信息并更新缓存
      await _refreshUserInfoAfterBind();
      
      // 重新加载消息列表
      await loadMessages();
      
      debugPrint('✅ 接收绑定按钮埋点上报成功: other_id=${message.fromUserId}');
    } else {
      CustomToast.show(Get.context!, result.msg ?? '绑定失败');
    }
  } catch (e) {
    debugPrint('同意绑定失败: $e');
    CustomToast.show(Get.context!, '绑定失败: $e');
  }
}
```

**数据模型扩展**:

为了获取 `other_id`（情侣ID），扩展了 `MessageItem` 数据模型，添加了 `fromUserId` 字段：

```dart
class MessageItem {
  final String id;
  final String title;
  final String content;
  final String statusText;
  final String date;
  final int isOperate;
  final String fromUserId; // 发送者/情侣的用户ID

  MessageItem({
    required this.id,
    required this.title,
    required this.content,
    required this.statusText,
    required this.date,
    required this.isOperate,
    this.fromUserId = '',
  });

  factory MessageItem.fromJson(Map<String, dynamic> json) {
    return MessageItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      statusText: json['status_text'] ?? '',
      date: json['date'] ?? '',
      isOperate: json['is_operate'] ?? 0,
      // 尝试从多个字段获取情侣ID
      fromUserId: json['from_user_id']?.toString() ?? json['user_id']?.toString() ?? '',
    );
  }
}
```

---

### 3. 拒绝绑定按钮 - 点击事件 (reject_bind_button)

**事件ID**: `reject_bind_button`

**事件类型**: 点击事件

**参数**:
- device_id: 虚拟用户ID
- user_id: 用户ID
- click_time: 点击时间（格式：年/月/日 时:分:秒）

**触发场景**: 用户在消息中心点击"拒绝绑定"按钮时

**代码位置**:
- 埋点方法: `lib/services/tracking_service.dart` - `TrackingService.trackRejectBindButton()`
- 调用位置: `lib/pages/message_center/message_center_controller.dart` - `MessageCenterController._refuseBind()`

**实现代码**:

```dart
/// 拒绝绑定
Future<void> _refuseBind(MessageItem message) async {
  try {
    debugPrint('开始拒绝绑定，消息ID: ${message.id}');
    
    // 上报拒绝绑定按钮点击埋点
    await TrackingService.trackRejectBindButton();
    
    final result = await HttpManagerN.instance.executePost(
      ApiRequest.refuseBind,
      jsonParam: {'system_notice_id': message.id},
      paramEncrypt: false,
    );
    
    if (result.isSuccess) {
      CustomToast.show(Get.context!, '已拒绝绑定');
      
      // 重新加载消息列表
      await loadMessages();
      
      debugPrint('✅ 拒绝绑定按钮埋点上报成功');
    } else {
      CustomToast.show(Get.context!, result.msg ?? '操作失败');
    }
  } catch (e) {
    debugPrint('拒绝绑定失败: $e');
    CustomToast.show(Get.context!, '操作失败: $e');
  }
}
```

---

## 修改的文件

### 1. lib/services/tracking_service.dart
- 新增3个静态埋点方法：
  - `trackAcceptBindButton({required String otherId})` - 接收绑定按钮
  - `trackRejectBindButton()` - 拒绝绑定按钮
  - `trackMessageCenterPageView({required String stayDuration, required bool canScroll, required String isBind})` - 互动消息页面浏览

### 2. lib/pages/message_center/message_center_controller.dart

**新增导入**:
```dart
import 'package:kissu_app/services/tracking_service.dart';
```

**新增字段**:
```dart
// 页面浏览埋点相关
DateTime? _pageEnterTime;
late ScrollController scrollController;
var scrollTimes = 0.obs;
var hasScrolled = false.obs;
```

**修改的方法**:
- `onInit()`: 添加进入时间记录和滚动控制器初始化
- `onClose()`: 添加页面浏览埋点上报和资源释放
- `_affirmBind()`: 添加接收绑定按钮埋点
- `_refuseBind()`: 添加拒绝绑定按钮埋点

**新增方法**:
- `handleScroll()`: 处理滚动事件，检测页面是否滑动
- `_trackPageView()`: 上报页面浏览埋点

**数据模型修改**:
- `MessageItem`: 添加 `fromUserId` 字段用于保存情侣ID

### 3. lib/pages/message_center/message_center_page.dart
- 在 `ListView.builder` 外包裹 `NotificationListener<ScrollNotification>`
- 为 `ListView.builder` 添加 `controller: controller.scrollController`
- 添加 `physics: const AlwaysScrollableScrollPhysics()` 确保列表可滚动

---

## 技术要点

### 1. 页面停留时长计算
使用 `DateTime` 记录进入和退出时间，计算差值得到停留时长：
```dart
final duration = DateTime.now().difference(_pageEnterTime!);
final seconds = duration.inSeconds;
final stayDuration = '${seconds}s';
```

### 2. 滚动检测
使用 `NotificationListener<ScrollNotification>` 监听滚动事件：
- 检测 `ScrollUpdateNotification` 类型
- 判断滚动距离是否 > 10px（避免误触）
- 更新 `hasScrolled` 和 `scrollTimes` 状态

### 3. 绑定状态判断
从 `UserManager.currentUser` 获取当前用户信息，使用 `bindStatus` 字段判断：
```dart
// bindStatus: 0从未绑定，1绑定中，2已解绑
final isBind = (user?.bindStatus.toString() == "1") ? '已绑定' : '未绑定';
```

### 4. other_id 获取策略
- 优先从 `message.fromUserId` 获取（API 返回的发送者ID）
- 如果为空，使用 `message.id` 作为备用（消息ID）
- 在数据模型解析时尝试多个字段：`from_user_id`、`user_id`

---

## 注意事项

1. **异步处理**: 所有埋点调用都使用 `await`，确保在执行后续操作前完成埋点上报
2. **资源管理**: 在 `onClose()` 中释放 `ScrollController`，避免内存泄漏
3. **滚动阈值**: 设置滚动距离阈值（10px），避免因轻微晃动误判为滚动
4. **绑定状态**: 根据 `user.bindStatus` 字段判断绑定状态（0=从未绑定，1=已绑定，2=已解绑）
5. **数据模型兼容**: `fromUserId` 字段设置默认值为空字符串，确保向后兼容
6. **埋点时机**: 
   - 页面浏览埋点在 `onClose()` 时上报，确保记录完整停留时长
   - 按钮点击埋点在按钮点击时立即上报，在 API 调用之前执行

---

## 测试建议

1. **页面浏览埋点测试**:
   - 进入消息中心页面，停留不同时长后退出，验证 `stay_duration` 是否准确
   - 在页面中滑动列表，验证 `can_scroll` 是否为 "是"
   - 不滑动直接退出，验证 `can_scroll` 是否为 "否"
   - 测试已绑定和未绑定状态，验证 `is_bind` 参数是否正确

2. **接收绑定按钮测试**:
   - 点击"同意绑定"按钮，验证埋点是否上报
   - 检查 `other_id` 参数是否正确（应为发送绑定邀请的用户ID）
   - 验证埋点上报后，绑定流程是否正常执行

3. **拒绝绑定按钮测试**:
   - 点击"拒绝绑定"按钮，验证埋点是否上报
   - 验证埋点参数（device_id、user_id、click_time）是否正确

4. **友盟后台验证**:
   - 登录友盟后台，查看 `message_center_page`、`accept_bind_button`、`reject_bind_button` 事件
   - 验证各参数数据是否正确接收

---

## 更新日期

2025-10-30

