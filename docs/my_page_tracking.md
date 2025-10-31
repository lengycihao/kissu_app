# 我的页面埋点集成文档

## 📋 概述
本文档记录了**我的页面**（`MinePage`）的友盟埋点集成实现。我的页面是用户查看个人信息、会员状态、恋爱信息和应用设置的主要入口。

---

## 🎯 埋点事件

### 页面浏览埋点
**事件名称**: `my_page`  
**事件类型**: 浏览事件  
**触发时机**: 用户退出我的页面时（点击返回或切换到其他页面）

#### 参数说明
| 参数名 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `device_id` | String | 虚拟用户ID（通过设备号生成） | "abc123..." |
| `user_id` | String | 用户ID | "12345" |
| `stay_duration` | String | 页面停留时长 | "2s", "30s", "120s" |
| `can_scroll` | String | 页面是否滑动 | "是", "否" |
| `scroll_times` | String | 页面滑动次数 | "0次", "3次", "10次" |

#### 实现位置
- **Service**: `TrackingService.trackMyPageView()`
- **Controller**: `MineController`
- **Page**: `MinePage`
- **上报时机**: 页面关闭时（`onClose()`）计算停留时长和滑动数据后上报

---

## 🔧 实现细节

### 1. TrackingService 中的埋点方法

在 `lib/services/tracking_service.dart` 中添加了我的页面浏览埋点方法：

```dart
/// 埋点：我的页面 - 浏览事件
/// 
/// 事件ID: my_page
/// 
/// 参数：
/// - device_id: 虚拟用户ID（通过用户设备号生成）
/// - user_id: 用户ID（已登录时）
/// - stay_duration: 页面停留时长（如：2s）
/// - can_scroll: 页面是否滑动（是/否）
/// - scroll_times: 页面滑动次数（如：3次）
static Future<void> trackMyPageView({
  required String stayDuration,
  required bool canScroll,
  required int scrollTimes,
}) async {
  try {
    final params = await _buildBaseParams();
    params.remove('click_time');
    params['stay_duration'] = stayDuration;
    params['can_scroll'] = canScroll ? '是' : '否';
    params['scroll_times'] = '${scrollTimes}次';
    await _trackEvent('my_page', params, '我的页面-浏览事件');
  } catch (e) {
    debugPrint('❌ 我的页面浏览埋点：上报数据失败 - $e');
  }
}
```

### 2. MineController 中的实现

在 `lib/pages/mine/mine_controller.dart` 中添加了页面浏览时长统计和滑动监听：

#### 2.1 初始化页面数据收集
```dart
// 页面浏览时长统计
DateTime? _pageEnterTime;

// 滑动相关
late ScrollController scrollController;
var scrollTimes = 0.obs; // 滑动次数
var hasScrolled = false.obs; // 是否滑动过

@override
void onInit() {
  super.onInit();
  _initSettingItems();
  
  // 初始化滚动控制器
  scrollController = ScrollController();
  
  // 记录页面进入时间（用于计算停留时长）
  _pageEnterTime = DateTime.now();
  
  // 加载用户信息
  loadUserInfo();
  _silentRefreshUserInfo();
}
```

#### 2.2 滑动事件处理
```dart
/// 处理滑动事件
void handleScroll(ScrollNotification notification) {
  if (notification is ScrollUpdateNotification) {
    // 只要发生滚动，标记为已滑动
    if (!hasScrolled.value) {
      hasScrolled.value = true;
    }
    
    // 滑动距离超过 10 像素时，计数一次
    if (notification.scrollDelta!.abs() > 10) {
      scrollTimes.value++;
      debugPrint('📊 我的页面：滑动次数 = ${scrollTimes.value}');
    }
  }
}
```

#### 2.3 页面关闭时上报埋点
```dart
@override
void onClose() {
  // 上报页面浏览埋点
  _trackPageView();
  
  // 释放滚动控制器
  scrollController.dispose();
  
  super.onClose();
}

/// 上报页面浏览埋点
Future<void> _trackPageView() async {
  if (_pageEnterTime == null) return;
  
  try {
    // 计算停留时长
    final duration = DateTime.now().difference(_pageEnterTime!);
    final seconds = duration.inSeconds;
    final stayDuration = '${seconds}s';
    
    // 上报埋点
    await TrackingService.trackMyPageView(
      stayDuration: stayDuration,
      canScroll: hasScrolled.value,
      scrollTimes: scrollTimes.value,
    );
    
    debugPrint('✅ 我的页面浏览埋点上报成功: 停留时长=$stayDuration, 是否滑动=${hasScrolled.value}, 滑动次数=${scrollTimes.value}');
  } catch (e) {
    debugPrint('❌ 我的页面浏览埋点上报失败: $e');
  }
}
```

### 3. MinePage 中的实现

在 `lib/pages/mine/mine_page.dart` 中给 `SingleChildScrollView` 添加了滑动监听：

```dart
Expanded(
  child: RefreshIndicator(
    onRefresh: controller.onRefresh,
    child: NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        controller.handleScroll(notification);
        return false;
      },
      child: SingleChildScrollView(
        controller: controller.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 页面内容...
          ],
        ),
      ),
    ),
  ),
),
```

---

## 🎬 触发流程

1. **用户进入我的页面**
   - Controller 在 `onInit()` 中记录进入时间
   - 初始化 ScrollController
   - 初始化滑动相关变量

2. **用户浏览和滑动页面**
   - `NotificationListener` 监听滑动事件
   - `ScrollUpdateNotification` 触发时，调用 `handleScroll()`
   - 记录是否滑动和滑动次数

3. **用户退出我的页面**
   - Controller 在 `onClose()` 中触发埋点上报
   - 计算停留时长（当前时间 - 进入时间）
   - 获取滑动数据（是否滑动、滑动次数）
   - 调用 `TrackingService.trackMyPageView()` 上报数据
   - 释放 ScrollController 资源

---

## 📊 滑动检测逻辑

### 判断是否滑动
- 只要发生任何滚动事件（`ScrollUpdateNotification`），就标记 `hasScrolled = true`
- 即使只滑动很小的距离也会被记录

### 滑动次数统计
- 只有滑动距离超过 10 像素时才计数
- 每次满足条件的滑动，`scrollTimes` 增加 1
- 避免微小的抖动被计入滑动次数

---

## ✅ 验证要点

1. **停留时长计算准确**：退出页面时正确计算秒数
2. **滑动检测灵敏**：任何滚动都能被检测到
3. **滑动次数合理**：避免过度计数，只记录明显的滑动
4. **埋点参数完整**：device_id、user_id、stay_duration、can_scroll、scroll_times 都正确上报
5. **资源正确释放**：ScrollController 在 onClose 中被正确释放

---

## 📝 变更日期

2025-10-30

---

## 🔗 相关文件

- `lib/services/tracking_service.dart` - 埋点服务类
- `lib/pages/mine/mine_controller.dart` - 我的页面控制器
- `lib/pages/mine/mine_page.dart` - 我的页面UI组件
- `api_type.md` - 埋点事件定义文档

---

## 🎯 页面功能说明

我的页面主要包含以下功能模块：
- **用户信息展示**：昵称、头像、匹配码、绑定状态
- **会员卡片**：会员状态、到期时间、开通按钮
- **快捷入口**：定位、足迹、用机记录
- **应用设置**：防偷拍检测、首页视图、系统权限、关于我们等

用户在此页面的浏览和滑动行为都会被准确记录和上报。

