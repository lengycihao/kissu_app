# 足迹页面埋点集成文档

## 📋 概述
本文档记录了**足迹页面**（`TrackPage`）的友盟埋点集成实现，包括页面浏览和滑动状态两个埋点事件。

---

## 🎯 埋点事件列表

### 1. 页面浏览埋点
**事件名称**: `footprint_page`  
**事件类型**: 浏览事件  
**触发时机**: 用户离开足迹页面时

#### 参数说明
| 参数名 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `device_id` | String | 虚拟用户ID（通过设备号生成） | "abc123..." |
| `user_id` | String | 用户ID | "12345" |
| `stay_duration` | String | 页面停留时长 | "120s" |
| `is_bind` | String | 用户情侣绑定状态 | "已绑定" / "未绑定" |
| `is_vip` | String | 用户充值状态 | "已充值" / "未充值" |
| `can_location` | String | 位置权限 | "已开启" / "未开启" |

#### 实现位置
- **Controller**: `TrackController.onClose()`
- **方法**: `_trackPageView()`
- **上报时机**: 页面关闭时（onClose 生命周期）

#### 代码实现
```dart
@override
void onClose() {
  DebugUtil.info('🧹 开始清理轨迹页面资源和缓存...');
  
  // 上报页面浏览埋点
  _trackPageView();
  
  // ... 清理其他资源
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
    
    // 获取用户信息
    final user = UserManager.currentUser;
    final isBind = _userManager.isBindPartner.value;
    // 检查 VIP 状态：isVip == 1 表示是会员
    final isVip = user?.isVip == 1;
    
    // 获取位置权限状态
    final canLocation = await LocationPermissionManager.instance.checkLocationPermissionSilently();
    
    // 上报埋点
    await TrackingService.trackFootprintPageView(
      stayDuration: stayDuration,
      isBind: isBind,
      isVip: isVip,
      canLocation: canLocation,
    );
    
    DebugUtil.info('✅ 足迹页面浏览埋点上报成功: 停留时长=$stayDuration, 绑定=$isBind, VIP=$isVip, 位置权限=$canLocation');
  } catch (e) {
    DebugUtil.error('❌ 足迹页面浏览埋点上报失败: $e');
  }
}
```

---

### 2. 滑动状态埋点
**事件名称**: `footprint_page_swipe_state`  
**事件类型**: 点击事件  
**触发时机**: 用户滑动底部面板，状态发生改变时

#### 参数说明
| 参数名 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `device_id` | String | 虚拟用户ID（通过设备号生成） | "abc123..." |
| `user_id` | String | 用户ID | "12345" |
| `click_time` | String | 操作时间 | "2025-01-15 14:30:25" |
| `click_state` | String | 滑动状态 | "小屏" / "中屏" / "大屏" |

#### 屏幕状态说明
- **小屏**：底部面板在底部位置（minHeight ≈ 190px）
- **中屏**：底部面板在中间位置（约占屏幕 50%）
- **大屏**：底部面板吸顶（距离顶部 100px）

#### 状态判断逻辑
```dart
// 计算各个状态的阈值
final minPercent = minHeight / screenHeight;  // 小屏（底部）
final maxPercent = maxHeight / screenHeight;  // 大屏（顶部吸顶）

// 中屏的阈值：介于小屏和大屏之间的中间位置（允许一定容差）
// 判断逻辑：小屏和大屏各占 20% 的范围，中间 60% 的范围都算中屏
final smallToMediumThreshold = minPercent + (maxPercent - minPercent) * 0.2;
final mediumToLargeThreshold = minPercent + (maxPercent - minPercent) * 0.8;

// 判断当前屏幕状态
String currentState;
if (extent <= smallToMediumThreshold) {
  currentState = '小屏';
} else if (extent >= mediumToLargeThreshold) {
  currentState = '大屏';
} else {
  currentState = '中屏';
}
```

#### 实现位置
- **Page**: `_TrackPageContentState` in `TrackPage`
- **监听器**: `NotificationListener<DraggableScrollableNotification>`
- **上报时机**: 滑动状态改变时（从小屏→中屏、中屏→大屏等）

#### 代码实现
```dart
// 监听底部面板滑动
NotificationListener<DraggableScrollableNotification>(
  onNotification: (notification) {
    widget.controller.sheetPercent.value = notification.extent;
    
    // 监听滑动状态变化并上报埋点
    _onSheetPercentChanged(notification.extent);
    
    return true;
  },
  // ...
)

/// 监听滑动面板百分比变化，判断屏幕状态并上报埋点
void _onSheetPercentChanged(double extent) {
  // 计算各个状态的阈值
  final minPercent = minHeight / screenHeight;  // 小屏（底部）
  final maxPercent = maxHeight / screenHeight;  // 大屏（顶部吸顶）
  
  // 中屏的阈值：介于小屏和大屏之间的中间位置（允许一定容差）
  final smallToMediumThreshold = minPercent + (maxPercent - minPercent) * 0.2;
  final mediumToLargeThreshold = minPercent + (maxPercent - minPercent) * 0.8;
  
  // 判断当前屏幕状态
  String currentState;
  if (extent <= smallToMediumThreshold) {
    currentState = '小屏';
  } else if (extent >= mediumToLargeThreshold) {
    currentState = '大屏';
  } else {
    currentState = '中屏';
  }
  
  // 只有当状态真正改变时才上报埋点（避免频繁上报）
  if (_lastScreenState != null && _lastScreenState != currentState) {
    _trackSwipeState(currentState);
  }
  
  // 更新上一次的状态
  _lastScreenState = currentState;
}

/// 上报滑动状态埋点
Future<void> _trackSwipeState(String clickState) async {
  try {
    await TrackingService.trackFootprintPageSwipeState(
      clickState: clickState,
    );
    DebugUtil.info('✅ 足迹页面-滑动状态埋点上报成功: $clickState');
  } catch (e) {
    DebugUtil.error('❌ 足迹页面-滑动状态埋点上报失败: $e');
  }
}
```

---

## 🔧 TrackingService 方法

### 方法列表

#### 1. trackFootprintPageView
```dart
/// 埋点：足迹页 - 页面浏览
/// 
/// @param stayDuration 停留时长（如：120s）
/// @param isBind 是否绑定情侣
/// @param isVip 是否是会员
/// @param canLocation 是否有位置权限
static Future<void> trackFootprintPageView({
  required String stayDuration,
  required bool isBind,
  required bool isVip,
  required bool canLocation,
}) async {
  final params = await _buildBaseParams();
  params['stay_duration'] = stayDuration;
  params['is_bind'] = isBind ? '已绑定' : '未绑定';
  params['is_vip'] = isVip ? '已充值' : '未充值';
  params['can_location'] = canLocation ? '已开启' : '未开启';
  
  await _trackEvent('footprint_page', params, '足迹页面-页面浏览');
}
```

#### 2. trackFootprintPageSwipeState
```dart
/// 埋点：足迹页 - 滑动状态
/// 
/// @param clickState 滑动状态：小屏、中屏、大屏
static Future<void> trackFootprintPageSwipeState({
  required String clickState,
}) async {
  final params = await _buildBaseParams();
  params['click_state'] = clickState;
  
  await _trackEvent('footprint_page_swipe_state', params, '足迹页面-滑动状态');
}
```

---

## 📝 实现要点

### 1. 页面停留时长计算
- 在 `onInit()` 中记录进入时间：`_pageEnterTime = DateTime.now()`
- 在 `onClose()` 中计算时长：`DateTime.now().difference(_pageEnterTime!)`
- 格式化为秒数：`'${seconds}s'`

### 2. 用户状态获取
- **绑定状态**: 从 `_userManager.isBindPartner.value` 获取
- **VIP 状态**: 从 `user?.isVip == 1` 判断
- **位置权限**: 通过 `LocationPermissionManager.instance.checkLocationPermissionSilently()` 获取

### 3. 滑动状态判断
- **状态阈值**: 小屏和大屏各占 20% 范围，中间 60% 范围算中屏
- **状态缓存**: 使用 `_lastScreenState` 记录上一次状态，避免重复上报
- **触发时机**: 只在状态真正改变时上报（如：小屏→中屏）

### 4. 埋点上报时机
- **页面浏览埋点**: 在 `onClose()` 生命周期方法中上报
- **滑动状态埋点**: 在滑动监听器中实时判断并上报

### 5. 异常处理
- 所有埋点方法都使用 try-catch 包裹
- 失败时打印错误日志，但不影响正常业务流程
- 使用 `DebugUtil` 记录成功和失败日志

---

## 🧪 测试验证

### 测试场景

#### 场景1：页面浏览埋点
1. 打开足迹页面
2. 停留一段时间（如2分钟）
3. 返回上一页或切换到其他页面
4. **预期**: 控制台输出 `✅ 足迹页面浏览埋点上报成功: 停留时长=120s, 绑定=true, VIP=false, 位置权限=true`

#### 场景2：滑动状态埋点 - 小屏→中屏
1. 打开足迹页面（默认底部面板在底部，小屏状态）
2. 向上滑动底部面板到中间位置
3. **预期**: 控制台输出 `✅ 足迹页面-滑动状态埋点上报成功: 中屏`

#### 场景3：滑动状态埋点 - 中屏→大屏
1. 从中屏状态继续向上滑动到顶部
2. **预期**: 控制台输出 `✅ 足迹页面-滑动状态埋点上报成功: 大屏`

#### 场景4：滑动状态埋点 - 大屏→中屏→小屏
1. 从大屏状态向下滑动到中间
2. **预期**: 控制台输出 `✅ 足迹页面-滑动状态埋点上报成功: 中屏`
3. 继续向下滑动到底部
4. **预期**: 控制台输出 `✅ 足迹页面-滑动状态埋点上报成功: 小屏`

### 验证清单
- [ ] 页面浏览埋点在页面关闭时上报
- [ ] 停留时长计算正确
- [ ] 绑定状态、VIP 状态、位置权限参数正确
- [ ] 滑动状态在状态改变时上报
- [ ] 小屏、中屏、大屏判断逻辑正确
- [ ] 同一状态不会重复上报
- [ ] 所有埋点包含 device_id 和 user_id
- [ ] 点击时间格式正确（yyyy-MM-dd HH:mm:ss）
- [ ] 埋点失败不影响业务功能

---

## 📊 数据示例

### 页面浏览埋点数据
```json
{
  "event_name": "footprint_page",
  "properties": {
    "device_id": "abc123...",
    "user_id": "12345",
    "stay_duration": "120s",
    "is_bind": "已绑定",
    "is_vip": "已充值",
    "can_location": "已开启"
  }
}
```

### 滑动状态埋点数据
```json
{
  "event_name": "footprint_page_swipe_state",
  "properties": {
    "device_id": "abc123...",
    "user_id": "12345",
    "click_time": "2025-01-15 14:30:25",
    "click_state": "中屏"
  }
}
```

---

## 🎨 屏幕状态可视化

```
┌─────────────────────────────┐
│         顶部 (100px)         │ ← 大屏吸顶位置
├─────────────────────────────┤
│                             │
│        【大屏状态】          │
│     (80%-100% 高度)         │
│                             │
│─────────────────────────────│
│                             │
│        【中屏状态】          │
│     (20%-80% 高度)          │
│                             │
│─────────────────────────────│
│        【小屏状态】          │
│     (0%-20% 高度)           │
├─────────────────────────────┤
│         底部 (190px)         │ ← 小屏底部位置
└─────────────────────────────┘
```

---

## 🔗 相关文档
- [位置提醒列表页面埋点集成](./location_reminder_tracking.md)
- [添加地点页面埋点集成](./location_picker_tracking.md)
- [友盟埋点服务文档](./umeng_event_timing_feature.md)
- [Mine 页面埋点集成](./mine_page_umeng_tracking.md)

---

## ✅ 集成完成
- ✅ TrackingService 方法已添加
- ✅ TrackController 页面浏览埋点已实现
- ✅ TrackPage 滑动状态埋点已实现
- ✅ 状态判断逻辑已完善
- ✅ 调试日志已完善
- ✅ 文档已创建

**最后更新**: 2025-01-15

