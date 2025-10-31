# 首页埋点实现文档

## 概述

本文档详细说明了在首页（Home Page）中实现的3个埋点事件，包括事件名称、参数、触发时机和代码位置。

## 实现的埋点事件

### 1. 首页页面 - 浏览事件 (home_page)

**事件ID**: `home_page`

**事件类型**: 浏览事件

**参数**:
- device_id: 虚拟用户ID
- user_id: 用户ID
- stay_duration: 页面停留时长（如：2s）
- scroll_times: 页面滑动次数（如：3次）

**触发场景**: 用户退出首页时，自动上报页面浏览数据

**代码位置**:
- 埋点方法: `lib/services/tracking_service.dart` - `TrackingService.trackHomePageView()`
- 调用位置: `lib/pages/home/home_controller.dart` - `HomeController.onClose()` → `_endPageTracking()`

**实现逻辑**:

1. **页面进入时**（`onInit()` → `_startPageTracking()`）:
   - 记录进入时间: `_pageEnterTime = DateTime.now()`
   - 初始化滚动监听器: `_setupScrollListener()`

2. **页面滚动时**（`_setupScrollListener()`）:
   - 监听 `ScrollController` 的滚动事件
   - 当滑动距离 > 10px 时，累计滚动次数 `scrollTimes++`
   - 使用定时器判断滚动结束（300ms无滚动）

3. **页面退出时**（`onClose()` → `_endPageTracking()`）:
   - 计算停留时长: `DateTime.now().difference(_pageEnterTime)`
   - 上报埋点数据

**实现代码**:

```dart
// Controller 中的实现
class HomeController extends GetxController {
  // 埋点相关字段
  var scrollTimes = 0.obs;
  double _lastScrollOffset = 0.0;
  bool _isScrolling = false;
  Timer? _scrollEndTimer;
  DateTime? _pageEnterTime;

  @override
  void onInit() {
    super.onInit();
    
    // 埋点：开始记录页面停留时长
    _startPageTracking();
    
    // 添加滚动监听器，统计滑动次数
    _setupScrollListener();
  }

  @override
  void onClose() {
    // 埋点：结束页面停留时长记录并上报
    _endPageTracking();
    
    // 清理滚动定时器
    _scrollEndTimer?.cancel();
    
    super.onClose();
  }

  /// 开始页面浏览追踪
  Future<void> _startPageTracking() async {
    try {
      debugPrint('📊 首页埋点：开始记录页面停留时长');
      // 记录进入时间
      _pageEnterTime = DateTime.now();
    } catch (e) {
      debugPrint('❌ 首页埋点：开始记录失败 - $e');
    }
  }
  
  /// 结束页面浏览追踪并上报埋点数据
  Future<void> _endPageTracking() async {
    if (_pageEnterTime == null) return;
    
    try {
      debugPrint('📊 首页埋点：结束记录并上报数据');
      
      // 计算停留时长
      final duration = DateTime.now().difference(_pageEnterTime!);
      final seconds = duration.inSeconds;
      final stayDuration = '${seconds}s';
      
      // 使用统一的 TrackingService 上报
      await TrackingService.trackHomePageView(
        stayDuration: stayDuration,
        scrollTimes: scrollTimes.value,
      );
      
      debugPrint('✅ 首页埋点上报成功: 停留时长=$stayDuration, 滑动次数=${scrollTimes.value}');
    } catch (e) {
      debugPrint('❌ 首页埋点：上报数据失败 - $e');
    }
  }

  /// 设置滚动监听器
  void _setupScrollListener() {
    scrollController.addListener(() {
      final currentOffset = scrollController.offset;
      
      // 判断是否发生了显著的滚动（距离大于10像素）
      if ((currentOffset - _lastScrollOffset).abs() > 10) {
        if (!_isScrolling) {
          // 开始一次新的滚动
          _isScrolling = true;
          scrollTimes.value++;
          debugPrint('📊 首页埋点：记录滑动次数 = ${scrollTimes.value}');
        }
        _lastScrollOffset = currentOffset;
        
        // 取消之前的定时器
        _scrollEndTimer?.cancel();
        
        // 设置新的定时器，300ms后如果没有新的滚动则认为滚动结束
        _scrollEndTimer = Timer(const Duration(milliseconds: 300), () {
          _isScrolling = false;
          debugPrint('📊 首页埋点：滚动结束');
        });
      }
    });
    
    debugPrint('📊 首页埋点：滚动监听器已设置');
  }
}
```

---

### 2. 头像绑定另一半 - 点击事件 (bind_partner_avatar)

**事件ID**: `bind_partner_avatar`

**事件类型**: 点击事件

**参数**:
- device_id: 虚拟用户ID
- user_id: 用户ID
- click_time: 点击时间（格式：年/月/日 时:分:秒）

**触发场景**: 用户点击首页另一半头像时（无论绑定还是未绑定状态）

**代码位置**:
- 埋点方法: `lib/services/tracking_service.dart` - `TrackingService.trackPartnerAvatarClick()`
- 调用位置: `lib/pages/home/home_page.dart` - 另一半头像点击事件

**实现代码**:

```dart
// 已绑定状态 - 点击头像跳转到恋爱信息页
GestureDetector(
  onTap: () {
    // 埋点：点击另一半头像（已绑定状态）
    TrackingService.trackPartnerAvatarClick();
    // 已绑定状态下点击头像跳转到恋爱信息页
    controller.navigateToLoveInfoPage();
  },
  child: NoPlaceholderImage(/* ... */),
)

// 未绑定状态 - 点击头像显示绑定弹窗
GestureDetector(
  onTap: () {
    // 埋点：点击另一半头像（未绑定状态）
    TrackingService.trackPartnerAvatarClick();
    // 显示绑定弹窗
    CustomBottomDialog.show(
      context: context,
      caller: BindingDialogCaller.home,
    );
  },
  child: NoPlaceholderImage(/* ... */),
)
```

---

### 3. 消息中心按钮 - 点击事件 (message_center_button)

**事件ID**: `message_center_button`

**事件类型**: 点击事件

**参数**:
- device_id: 虚拟用户ID
- user_id: 用户ID
- click_time: 点击时间（格式：年/月/日 时:分:秒）

**触发场景**: 用户点击首页右上角消息中心按钮时

**代码位置**:
- 埋点方法: `lib/services/tracking_service.dart` - `TrackingService.trackMessageCenterClick()`
- 调用位置: `lib/pages/home/home_controller.dart` - `HomeController.onMessageCenterTap()`

**实现代码**:

```dart
// 消息中心按钮点击
void onMessageCenterTap() {
  // 埋点：点击消息中心按钮
  TrackingService.trackMessageCenterClick();
  
  // 跳转到消息列表页面（一级页面）
  debugPrint('📭 点击消息中心按钮，进入消息列表');
  Get.toNamed(KissuRoutePath.messageList);
}
```

---

## 修改的文件

### 1. lib/services/tracking_service.dart
- 新增1个静态埋点方法：
  - `trackHomePageView({required String stayDuration, required int scrollTimes})` - 首页页面浏览

### 2. lib/pages/home/home_controller.dart

**新增字段**:
```dart
DateTime? _pageEnterTime; // 页面进入时间
```

**修改的方法**:
- `_startPageTracking()`: 改为记录进入时间
- `_endPageTracking()`: 改为使用 TrackingService 统一上报，添加 stay_duration 参数

**已有方法**（无需修改）:
- `_setupScrollListener()`: 滚动次数统计已实现
- `onMessageCenterTap()`: 消息中心按钮埋点已实现

### 3. lib/pages/home/home_page.dart
- 头像点击埋点已实现（无需修改）
- 位置：另一半头像的 GestureDetector 的 onTap 事件

---

## 技术要点

### 1. 页面停留时长计算
使用 `DateTime` 记录进入和退出时间，计算差值得到停留时长：
```dart
final duration = DateTime.now().difference(_pageEnterTime!);
final seconds = duration.inSeconds;
final stayDuration = '${seconds}s';
```

### 2. 滚动次数统计
使用 `ScrollController` 监听滚动事件：
- 检测滚动距离是否 > 10px（避免误触）
- 使用定时器判断滚动结束（300ms无滚动）
- 每次有效滚动累计 `scrollTimes++`

### 3. 统一埋点接口
所有埋点统一使用 `TrackingService` 封装，确保：
- 参数格式一致
- 错误处理统一
- 便于维护和追踪

---

## 注意事项

1. **页面停留时长**: 从 `onInit()` 开始计时，到 `onClose()` 结束，记录完整停留时长
2. **滚动阈值**: 设置10px阈值避免轻微晃动误判为滚动
3. **资源管理**: 在 `onClose()` 中正确释放定时器资源
4. **埋点时机**: 
   - 页面浏览埋点在 `onClose()` 时上报，确保记录完整停留时长
   - 按钮点击埋点在点击时立即上报

---

## 测试建议

1. **页面浏览埋点测试**:
   - 进入首页，停留不同时长后退出，验证 `stay_duration` 是否准确
   - 在首页滑动，验证 `scroll_times` 是否正确累计
   - 不滑动直接退出，验证 `scroll_times` 是否为 "0次"

2. **头像点击埋点测试**:
   - 未绑定状态点击头像，验证埋点是否上报
   - 已绑定状态点击头像，验证埋点是否上报
   - 验证两种状态下埋点参数是否一致

3. **消息中心按钮埋点测试**:
   - 点击消息中心按钮，验证埋点是否上报
   - 验证埋点参数（device_id、user_id、click_time）是否正确

4. **友盟后台验证**:
   - 登录友盟后台，查看 `home_page`、`bind_partner_avatar`、`message_center_button` 事件
   - 验证各参数数据是否正确接收

---

## 更新日期

2025-10-30

