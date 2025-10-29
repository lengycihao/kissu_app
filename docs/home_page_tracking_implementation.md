# 首页埋点实现文档

## 概述
根据 `api_type.md` 中的要求，为首页实现了完整的浏览事件埋点功能。

## 埋点事件

### 事件ID
`home_page`

### 事件参数

| 参数名 | 说明 | 数据类型 | 示例 |
|--------|------|----------|------|
| device_id | 虚拟用户ID（通过设备号生成） | String | "550e8400-e29b-41d4-a716-446655440000" |
| user_id | 用户ID（已登录时） | String | "12345" |
| stay_duration | 页面停留时长 | 自动计算 | 由eventBegin和eventEnd自动计算 |
| scroll_times | 页面滑动次数 | String | "3" |

## 实现细节

### 1. 页面停留时长记录

**实现方式：** 使用友盟的 `eventBegin` 和 `eventEnd` 方法自动计算停留时长

**代码位置：** `lib/pages/home/home_controller.dart`

```dart
// 页面初始化时开始计时
@override
void onInit() {
  super.onInit();
  _startPageTracking(); // 开始记录页面停留时长
  // ... 其他初始化代码
}

// 页面销毁时结束计时并上报
@override
void onClose() {
  _endPageTracking(); // 结束记录并上报数据
  // ... 其他清理代码
  super.onClose();
}
```

### 2. 页面滑动次数统计

**实现方式：** 监听 `ScrollController` 的滚动事件，统计用户手指触发的横向滚动次数

**关键逻辑：**
- 当滚动距离超过 10 像素时，判定为一次有效滑动
- 使用 300ms 延迟定时器判断滚动是否结束，避免连续滚动被计数多次
- 每次开始新的滚动时，滑动次数加 1

**代码实现：**
```dart
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
}
```

### 3. 数据上报

**时机：** 页面销毁时（`onClose`）

**上报内容：**
1. 虚拟用户ID（必填）
2. 用户ID（已登录时填写）
3. 页面滑动次数

**代码实现：**
```dart
Future<void> _endPageTracking() async {
  try {
    // 先结束计时
    await UmengAnalytics.eventEnd('home_page');
    
    // 获取虚拟用户ID
    final deviceId = await UmengAnalytics.getOrCreateVirtualUserId();
    
    // 获取用户ID（如果已登录）
    final user = UserManager.currentUser;
    final userId = user?.id?.toString() ?? '';
    
    // 构建埋点参数
    final params = <String, String>{
      'device_id': deviceId,
      'scroll_times': scrollTimes.value.toString(),
    };
    
    // 如果有用户ID，添加到参数中
    if (userId.isNotEmpty) {
      params['user_id'] = userId;
    }
    
    // 上报首页浏览事件
    await UmengAnalytics.logEventWithParams('home_page', params);
    
    debugPrint('✅ 首页埋点上报成功');
  } catch (e) {
    debugPrint('❌ 首页埋点：上报数据失败 - $e');
  }
}
```

## 新增变量

在 `HomeController` 中新增了以下变量：

```dart
// 埋点相关 - 页面滑动次数
var scrollTimes = 0.obs;           // 滑动次数计数器
double _lastScrollOffset = 0.0;    // 上次滚动位置
bool _isScrolling = false;         // 是否正在滚动
Timer? _scrollEndTimer;            // 滚动结束判定定时器
```

## 测试说明

### 测试场景

1. **停留时长测试**
   - 进入首页，等待一段时间后退出
   - 检查日志输出的停留时长是否正确

2. **滑动次数测试**
   - 进入首页，横向滑动背景图片
   - 每次手指滑动应该计数一次
   - 检查日志输出的滑动次数

3. **数据上报测试**
   - 退出首页时，应自动上报埋点数据
   - 检查日志确认上报成功
   - 检查友盟后台是否收到数据

### 日志示例

```
📊 首页埋点：开始记录页面停留时长
📊 首页埋点：滚动监听器已设置
📊 首页埋点：记录滑动次数 = 1
📊 首页埋点：滚动结束
📊 首页埋点：记录滑动次数 = 2
📊 首页埋点：滚动结束
📊 首页埋点：结束记录并上报数据
✅ 首页埋点上报成功: device_id=550e8400-e29b-41d4-a716-446655440000, user_id=12345, scroll_times=2
```

## 注意事项

1. **停留时长计算**
   - 停留时长由友盟SDK自动计算，在 `eventBegin` 和 `eventEnd` 之间的时间
   - 不需要在参数中传递 `stay_duration`，SDK会自动记录

2. **滑动次数统计**
   - 只统计有效滑动（移动距离 > 10像素）
   - 使用300ms延迟判断滚动结束，避免连续滚动被重复计数
   - 记录的是用户手指触发的滚动次数，不是滚动事件触发次数

3. **资源清理**
   - 在 `onClose` 中清理了滚动定时器，避免内存泄漏
   - 确保页面销毁时正确上报数据

4. **兼容性**
   - 使用了现有的友盟统计工具类 `UmengAnalytics`
   - 与现有的埋点实现保持一致的风格

## 相关文件

- `lib/pages/home/home_controller.dart` - 首页控制器，包含埋点实现
- `lib/pages/home/home_page.dart` - 首页视图
- `lib/utils/umeng_analytics_util.dart` - 友盟统计工具类
- `api_type.md` - 埋点需求文档

## 更新日期

2025-10-25

