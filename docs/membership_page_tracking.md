# 会员页面埋点实现文档

## 概述

本文档详细说明了在会员页面（VIP Page）中实现的4个埋点事件，包括事件名称、参数、触发时机和代码位置。

## 实现原理

所有埋点方法统一在 `TrackingService` 中实现，涵盖浏览事件和点击事件。

## 埋点事件列表

### 1. 会员页面 - 浏览事件 (membership_page)

**事件ID**: `membership_page`

**事件类型**: 浏览事件

**参数**:
- device_id: 虚拟用户ID
- user_id: 用户ID
- stay_duration: 页面停留时长（如：2s）
- can_scroll: 页面是否滑动（是/否）
- scroll_times: 页面滑动次数（如：3次）
- previous_name: 上个页面名称
- is_vip: 是否开通会员（开通/未开通）
- previous_id: 上个页面id

**触发场景**: 用户退出会员页面时，自动上报页面浏览数据

**代码位置**:
- 埋点方法: `lib/services/tracking_service.dart` - `TrackingService.trackMembershipPageView()`
- 调用位置: `lib/pages/vip/vip_controller.dart` - `VipController.onClose()` → `_trackPageView()`

**实现逻辑**:

1. **页面进入时**（`onInit()`）:
   - 记录进入时间: `_pageEnterTime = DateTime.now()`
   - 初始化滚动控制器: `mainScrollController = ScrollController()`
   - 从路由参数获取上个页面信息: `Get.arguments`
   - 初始化滚动检测变量: `hasScrolled`, `scrollTimes`

2. **页面滚动时**（`handleScroll()`）:
   - 监听 `ScrollUpdateNotification`
   - 当滑动距离 > 10px 时，标记 `hasScrolled = true`
   - 累计滚动次数 `scrollTimes++`

3. **页面退出时**（`onClose()` → `_trackPageView()`）:
   - 计算停留时长: `DateTime.now().difference(_pageEnterTime)`
   - 获取会员状态: `UserManager.isVip ? '开通' : '未开通'`
   - 上报埋点数据

**实现代码**:

```dart
// Controller 中的实现
@override
void onInit() {
  super.onInit();
  
  // 记录进入时间
  _pageEnterTime = DateTime.now();
  
  // 初始化控制器
  pageController = PageController();
  commentScrollController = ScrollController();
  priceScrollController = ScrollController();
  mainScrollController = ScrollController();
  
  // 从路由参数获取上个页面信息
  final args = Get.arguments as Map<String, dynamic>?;
  previousPageName = args?['previousPageName'] ?? '未知页面';
  previousPageId = args?['previousPageId'] ?? 'unknown';
  
  // 设置支付结果监听
  _setupPaymentResultListener();
}

@override
void onClose() {
  if (_isDisposed) return;
  _isDisposed = true;
  
  // 上报页面浏览埋点
  _trackPageView();
  
  // 释放资源...
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
    
    // 获取会员状态
    final isVip = UserManager.isVip ? '开通' : '未开通';
    
    await TrackingService.trackMembershipPageView(
      stayDuration: stayDuration,
      canScroll: hasScrolled.value,
      scrollTimes: scrollTimes.value,
      previousName: previousPageName,
      isVip: isVip,
      previousId: previousPageId,
    );
    
    debugPrint('✅ 会员页面浏览埋点上报成功');
  } catch (e) {
    debugPrint('❌ 会员页面浏览埋点上报失败: $e');
  }
}
```

**UI 集成**（`vip_page.dart`）:

```dart
return Scaffold(
  body: Stack(
    children: [
      // 主要内容区域
      NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          controller.handleScroll(notification);
          return false;
        },
        child: SingleChildScrollView(
          controller: controller.mainScrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            // ...内容
          ),
        ),
      ),
      // ...其他组件
    ],
  ),
);
```

---

### 2. 会员页面返回 - 点击事件 (membership_leave)

**事件ID**: `membership_leave`

**事件类型**: 点击事件

**参数**:
- device_id: 虚拟用户ID
- user_id: 用户ID
- click_time: 点击时间（格式：年/月/日 时:分:秒）

**触发场景**: 用户点击会员页面的返回按钮时

**代码位置**:
- 埋点方法: `lib/services/tracking_service.dart` - `TrackingService.trackMembershipLeave()`
- 调用位置: `lib/pages/vip/vip_controller.dart` - `VipController.onBackTap()`

**实现代码**:

```dart
/// 返回按钮点击（用于埋点）
Future<void> onBackTap() async {
  // 上报返回按钮埋点
  await TrackingService.trackMembershipLeave();
  debugPrint('✅ 会员页面返回按钮埋点上报成功');
  
  Get.back();
}
```

**UI 集成**:

```dart
// 固定的返回按钮
Positioned(
  left: 20,
  top: 55,
  child: GestureDetector(
    onTap: controller.onBackTap,
    child: Image(
      image: AssetImage('assets/kissu_mine_back.webp'),
      width: 22,
      height: 22,
    ),
  ),
),
```

---

### 3. 会员服务协议 - 点击事件 (membership_service_agreement)

**事件ID**: `membership_service_agreement`

**事件类型**: 点击事件

**参数**:
- device_id: 虚拟用户ID
- user_id: 用户ID
- click_time: 点击时间（格式：年/月/日 时:分:秒）

**触发场景**: 用户点击《会员服务协议》链接时

**代码位置**:
- 埋点方法: `lib/services/tracking_service.dart` - `TrackingService.trackMembershipServiceAgreement()`
- 调用位置: `lib/pages/vip/vip_controller.dart` - `VipController.onServiceAgreementTap()`

**实现代码**:

```dart
/// 服务协议点击（用于埋点）
Future<void> onServiceAgreementTap() async {
  // 上报服务协议点击埋点
  await TrackingService.trackMembershipServiceAgreement();
  debugPrint('✅ 会员服务协议点击埋点上报成功');
}
```

**UI 集成**:

```dart
TextSpan(
  text: '《会员服务协议》',
  style: const TextStyle(
    fontSize: 12,
    color: Color(0xFFFF839E),
   ),
  recognizer: TapGestureRecognizer()
    ..onTap = () async {
      // 上报服务协议点击埋点
      await controller.onServiceAgreementTap();
      AgreementUtils.toVipAgreement();
    },
),
```

---

### 4. 开通会员 - 点击事件 (membership_open)

**事件ID**: `membership_open`

**事件类型**: 点击事件

**参数**:
- device_id: 虚拟用户ID
- user_id: 用户ID
- click_time: 点击时间（格式：年/月/日 时:分:秒）
- vip_price: 会员金额（如：12.80）
- vip_name: 会员名称（如：双人月度会员）
- pay_type: 支付方式（如：支付宝）
- is_renew: 是否是续费（是续费/不是续费）
- previous_name: 上个页面名称
- pay_result: 支付结果（如：支付成功）

**触发场景**: 用户完成支付后，在支付成功回调中上报

**代码位置**:
- 埋点方法: `lib/services/tracking_service.dart` - `TrackingService.trackMembershipOpen()`
- 调用位置: `lib/pages/vip/vip_controller.dart` - `VipController._handlePaymentSuccess()` → `_trackMembershipOpen()`

**实现代码**:

```dart
/// 支付成功后的处理
Future<void> _handlePaymentSuccess(VipPackageModel package) async {
  try {
    _logger.i('支付成功，开始处理后续操作...');
    
    // 上报开通会员埋点
    await _trackMembershipOpen(package, '支付成功');
    
    // 等待用户信息刷新完成
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 刷新页面数据并返回上一页
    await _refreshMinePageAndReturn();
    
  } catch (e) {
    _logger.e('支付成功后处理异常: $e');
    Get.back();
  }
}

/// 上报开通会员埋点
Future<void> _trackMembershipOpen(VipPackageModel package, String payResult) async {
  try {
    // 获取支付方式
    final payType = selectedPaymentMethod.value == 0 ? '支付宝' : '微信';
    
    // 判断是否是续费
    final isRenew = UserManager.isVip ? '是续费' : '不是续费';
    
    await TrackingService.trackMembershipOpen(
      vipPrice: package.price?.toString() ?? '0.00',
      vipName: package.title ?? '未知套餐',
      payType: payType,
      isRenew: isRenew,
      previousName: previousPageName,
      payResult: payResult,
    );
    
    debugPrint('✅ 开通会员埋点上报成功');
  } catch (e) {
    debugPrint('❌ 开通会员埋点上报失败: $e');
  }
}
```

---

## 修改的文件

### 1. lib/services/tracking_service.dart
- 新增4个静态埋点方法：
  - `trackMembershipPageView({...})` - 会员页面浏览
  - `trackMembershipLeave()` - 会员页面返回
  - `trackMembershipServiceAgreement()` - 会员服务协议
  - `trackMembershipOpen({...})` - 开通会员

### 2. lib/pages/vip/vip_controller.dart

**新增导入**:
```dart
import 'package:kissu_app/services/tracking_service.dart';
```

**新增字段**:
```dart
// 主内容滚动控制器（用于埋点检测）
late ScrollController mainScrollController;

// 页面浏览埋点相关
DateTime? _pageEnterTime;
var scrollTimes = 0.obs;
var hasScrolled = false.obs;
String previousPageName = ''; // 上个页面名称
String previousPageId = ''; // 上个页面ID
```

**修改的方法**:
- `onInit()`: 添加进入时间记录、滚动控制器初始化、路由参数获取
- `onClose()`: 添加页面浏览埋点上报
- `_handlePaymentSuccess()`: 添加开通会员埋点

**新增方法**:
- `handleScroll()`: 处理滚动事件，检测页面是否滑动
- `_trackPageView()`: 上报页面浏览埋点
- `onBackTap()`: 返回按钮点击（含埋点）
- `onServiceAgreementTap()`: 服务协议点击（含埋点）
- `_trackMembershipOpen()`: 上报开通会员埋点

### 3. lib/pages/vip/vip_page.dart
- 在 `SingleChildScrollView` 外包裹 `NotificationListener<ScrollNotification>`
- 为 `SingleChildScrollView` 添加 `controller: controller.mainScrollController`
- 添加 `physics: const AlwaysScrollableScrollPhysics()` 确保列表可滚动
- 修改返回按钮的 `onTap` 为 `controller.onBackTap`
- 修改服务协议的点击事件，调用 `controller.onServiceAgreementTap()`

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

### 3. 上个页面信息获取
通过路由参数传递上个页面信息：
```dart
// 跳转时传递参数
Get.toNamed(
  KissuRoutePath.vip,
  arguments: {
    'previousPageName': '我的页面',
    'previousPageId': 'mine',
  },
);

// Controller 中接收参数
final args = Get.arguments as Map<String, dynamic>?;
previousPageName = args?['previousPageName'] ?? '未知页面';
previousPageId = args?['previousPageId'] ?? 'unknown';
```

### 4. 会员状态判断
使用 `UserManager.isVip` 判断会员状态：
```dart
final isVip = UserManager.isVip ? '开通' : '未开通';
```

### 5. 支付信息收集
在支付成功回调中收集支付相关信息：
- 套餐信息：从 `VipPackageModel` 获取
- 支付方式：从 `selectedPaymentMethod` 获取（0=支付宝，1=微信）
- 是否续费：根据当前会员状态判断
- 支付结果：从支付回调参数获取

---

## 使用方法

### 从其他页面跳转到会员页面

需要传递上个页面信息：

```dart
// 示例：从我的页面跳转
Get.toNamed(
  KissuRoutePath.vip,
  arguments: {
    'previousPageName': '我的页面',
    'previousPageId': 'mine',
  },
);
```

建议的页面ID映射：
- 首页: `home`
- 我的页面: `mine`
- 定位页面: `location`
- 足迹页面: `track`
- 用机记录页面: `usage_report`
- 其他: 根据实际情况定义

---

## 注意事项

1. **异步处理**: 所有埋点调用都使用 `await`，确保在执行后续操作前完成埋点上报
2. **资源管理**: 在 `onClose()` 中释放 `mainScrollController`，避免内存泄漏
3. **滚动阈值**: 设置滚动距离阈值（10px），避免因轻微晃动误判为滚动
4. **会员状态**: 使用 `UserManager.isVip` 判断会员状态
5. **支付时机**: 开通会员埋点在支付成功回调中上报，确保支付成功后才记录
6. **路由参数**: 必须在跳转时传递 `previousPageName` 和 `previousPageId`，否则默认为"未知页面"
7. **埋点时机**: 
   - 页面浏览埋点在 `onClose()` 时上报，确保记录完整停留时长
   - 返回按钮埋点在点击时立即上报
   - 服务协议埋点在点击时立即上报
   - 开通会员埋点在支付成功后上报

---

## 测试建议

1. **页面浏览埋点测试**:
   - 从不同页面进入会员页面，验证 `previous_name` 和 `previous_id` 是否正确
   - 停留不同时长后退出，验证 `stay_duration` 是否准确
   - 在页面中滑动列表，验证 `can_scroll` 是否为 "是"，`scroll_times` 是否累计
   - 不滑动直接退出，验证 `can_scroll` 是否为 "否"，`scroll_times` 是否为 "0次"
   - 测试会员和非会员状态，验证 `is_vip` 参数是否正确

2. **返回按钮埋点测试**:
   - 点击返回按钮，验证埋点是否上报
   - 验证埋点参数（device_id、user_id、click_time）是否正确

3. **服务协议埋点测试**:
   - 点击《会员服务协议》链接，验证埋点是否上报
   - 验证点击后是否正常跳转到协议页面

4. **开通会员埋点测试**:
   - 选择不同套餐进行支付，验证 `vip_price` 和 `vip_name` 是否正确
   - 使用支付宝和微信分别支付，验证 `pay_type` 是否正确
   - 会员状态下续费，验证 `is_renew` 是否为 "是续费"
   - 非会员状态下购买，验证 `is_renew` 是否为 "不是续费"
   - 支付成功后，验证 `pay_result` 是否为 "支付成功"

5. **友盟后台验证**:
   - 登录友盟后台，查看 `membership_page`、`membership_leave`、`membership_service_agreement`、`membership_open` 事件
   - 验证各参数数据是否正确接收

---

## 更新日期

2025-10-30

