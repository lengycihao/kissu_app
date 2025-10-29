# 足迹页面日期按钮和轨迹回放按钮埋点集成文档

## 📋 概述
本文档记录了**足迹页面**（`TrackPage`）中两个核心交互按钮的友盟埋点集成实现：
1. **日期按钮** - 用户选择查看某一天的足迹数据
2. **轨迹回放按钮** - 用户点击播放按钮查看轨迹动画回放

---

## 🎯 埋点事件列表

### 1. 日期按钮埋点
**事件名称**: `date_button`  
**事件类型**: 点击事件  
**触发时机**: 用户点击日期选择器中的任意日期按钮时

#### 参数说明
| 参数名 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `device_id` | String | 虚拟用户ID（通过设备号生成） | "abc123..." |
| `user_id` | String | 用户ID | "12345" |
| `click_time` | String | 点击时间（年/月/日 时:分:秒） | "2025/10/27 14:30:25" |
| `is_bind` | String | 用户情侣绑定状态 | "已绑定" 或 "未绑定" |

#### 实现位置
- **Service**: `TrackingService.trackDateButton(bool isBind)`
- **Component**: `TrackDateSelector` widget in `lib/pages/track/widgets/track_date_selector.dart`
- **上报时机**: 日期按钮点击时立即上报，在切换日期数据之前

#### 代码实现
```dart
// TrackDateSelector 组件中的点击事件
return Obx(
  () => GestureDetector(
    onTap: () async {
      // 上报日期按钮埋点
      if (isBind != null) {
        try {
          await TrackingService.trackDateButton(isBind!);
          DebugUtil.info('✅ 足迹页面-日期按钮埋点上报成功');
        } catch (e) {
          DebugUtil.error('❌ 足迹页面-日期按钮埋点上报失败: $e');
        }
      }
      
      currentSelectedIndex.value = index;
      print('📅 选择日期: ${date.toString().split(' ')[0]}');
      if (onSelect != null) {
        onSelect!(date);
      }
    },
    child: Container(
      // 日期按钮UI...
    ),
  ),
);

// TrackPage 中传入绑定状态
TrackDateSelector(
  selectedIndex: widget.controller.selectedDateIndex,
  isBind: widget.controller.isBindPartner.value,  // 传入绑定状态
  onSelect: (date) {
    widget.controller.selectDate(date);
  },
)
```

---

### 2. 轨迹回放按钮埋点
**事件名称**: `foot_moving`  
**事件类型**: 点击事件  
**触发时机**: 用户点击播放按钮**开始**轨迹回放时（暂停时不上报）

#### 参数说明
| 参数名 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `device_id` | String | 虚拟用户ID（通过设备号生成） | "abc123..." |
| `user_id` | String | 用户ID | "12345" |
| `click_time` | String | 点击时间（年/月/日 时:分:秒） | "2025/10/27 14:35:10" |

#### 实现位置
- **Service**: `TrackingService.trackFootMoving()`
- **Component**: `_ReplayProgressBar` widget in `TrackPage`
- **上报时机**: 点击播放按钮开始回放时立即上报，在执行 `startReplay()` 之前

#### 代码实现
```dart
// 播放/暂停按钮
GestureDetector(
  onTap: () async {
    if (controller.isReplaying.value) {
      // 暂停时不上报埋点
      controller.pauseReplay();
    } else {
      // 开始播放时上报埋点
      try {
        await TrackingService.trackFootMoving();
        DebugUtil.info('✅ 足迹页面-轨迹回放按钮埋点上报成功');
      } catch (e) {
        DebugUtil.error('❌ 足迹页面-轨迹回放按钮埋点上报失败: $e');
      }
      controller.startReplay();
    }
  },
  child: Obx(
    () => Container(
      width: 20,
      height: 20,
      padding: const EdgeInsets.all(4),
      child: Image(
        image: AssetImage(
          controller.isReplaying.value
              ? 'assets/3.0/kissu3_pause.webp'  // 暂停图标
              : 'assets/3.0/kissu3_play.webp',   // 播放图标
        ),
        width: 20,
        height: 20,
        fit: BoxFit.contain,
      ),
    ),
  ),
)
```

---

## 🔧 TrackingService 方法

### 方法列表

#### 1. trackDateButton
```dart
/// 埋点：足迹页 - 日期按钮
/// 
/// 事件ID: date_button
/// 
/// 参数：
/// - device_id: 虚拟用户ID
/// - user_id: 用户ID
/// - click_time: 点击时间
/// - is_bind: 用户情侣绑定状态（已绑定/未绑定）
static Future<void> trackDateButton(bool isBind) async {
  final params = await _buildBaseParams();
  params['is_bind'] = isBind ? '已绑定' : '未绑定';
  await _trackEvent('date_button', params, '足迹页面-日期按钮');
}
```

#### 2. trackFootMoving
```dart
/// 埋点：足迹页 - 轨迹回放按钮
/// 
/// 事件ID: foot_moving
/// 
/// 参数：
/// - device_id: 虚拟用户ID
/// - user_id: 用户ID
/// - click_time: 点击时间
static Future<void> trackFootMoving() async {
  final params = await _buildBaseParams();
  await _trackEvent('foot_moving', params, '足迹页面-轨迹回放按钮');
}
```

---

## 📝 实现要点

### 1. 日期按钮埋点

#### UI 组件设计
- **组件名称**: `TrackDateSelector`
- **位置**: `lib/pages/track/widgets/track_date_selector.dart`
- **功能**: 显示最近7天的日期选择器（今天及之前6天）
- **样式**: 横向排列的7个日期按钮，选中时高亮显示

#### 日期显示规则
- **今天**: 显示 "今天"
- **昨天**: 显示 "昨天"
- **其他**: 显示 "周一" ~ "周日"
- 每个日期下方显示对应的日期数字

#### 绑定状态传递
为了上报绑定状态，需要在两个地方传递 `isBind` 参数：

1. **TrackDateSelector 组件接收参数**
```dart
class TrackDateSelector extends StatelessWidget {
  final RxInt? selectedIndex;
  final void Function(DateTime date)? onSelect;
  final bool? isBind;  // 新增：接收绑定状态
  // ... 其他参数
}
```

2. **TrackPage 传入绑定状态**
```dart
// 已绑定状态
TrackDateSelector(
  selectedIndex: widget.controller.selectedDateIndex,
  isBind: widget.controller.isBindPartner.value,  // 传入 true
  onSelect: (date) => widget.controller.selectDate(date),
)

// 未绑定状态
TrackDateSelector(
  selectedIndex: widget.controller.selectedDateIndex,
  isBind: widget.controller.isBindPartner.value,  // 传入 false
  onSelect: (date) => widget.controller.selectDate(date),
)
```

#### 埋点上报时机
```
用户点击日期按钮
    ↓
上报埋点（包含绑定状态）
    ↓
更新选中索引
    ↓
触发 onSelect 回调
    ↓
controller.selectDate(date)
    ↓
加载该日期的足迹数据
```

#### 关键点
- 埋点在最开始上报，记录用户的日期选择行为
- 即使数据加载失败，也能统计用户的操作意图
- 绑定状态参数用于分析已绑定/未绑定用户的行为差异
- 使用 `isBind != null` 判断，避免在未传入状态时报错

### 2. 轨迹回放按钮埋点

#### UI 组件设计
- **组件名称**: `_ReplayProgressBar`
- **位置**: 足迹页面内部组件（`TrackPage`）
- **功能**: 提供轨迹回放控制（播放/暂停）和进度条
- **显示条件**: 当日足迹点数量 >= 3 时显示

#### 播放按钮逻辑
- **播放中**: 显示暂停图标（`kissu3_pause.webp`），点击暂停回放
- **已暂停**: 显示播放图标（`kissu3_play.webp`），点击开始回放
- **状态管理**: 通过 `controller.isReplaying.value` 控制

#### 埋点触发条件
```dart
if (controller.isReplaying.value) {
  // 当前正在播放 → 点击暂停 → ❌ 不上报埋点
  controller.pauseReplay();
} else {
  // 当前已暂停 → 点击播放 → ✅ 上报埋点
  await TrackingService.trackFootMoving();
  controller.startReplay();
}
```

**重要**: 只在**开始播放**时上报埋点，暂停时不上报。这样可以准确统计用户主动触发回放功能的次数。

#### 埋点上报时机
```
用户点击播放按钮（当前未播放状态）
    ↓
上报埋点
    ↓
controller.startReplay()
    ↓
启动轨迹动画回放
    ↓
按钮图标切换为暂停图标
```

#### 回放功能说明
- **进度条**: 显示当前回放进度，可拖动快进/快退
- **速度**: 轨迹点之间的动画时间由 controller 控制
- **循环**: 播放完成后可能会自动停止或循环（取决于实现）

#### 关键点
- 只在开始播放时上报埋点，不在暂停时上报
- 埋点在 `startReplay()` 之前执行，确保记录成功
- 即使回放启动失败，埋点也已经记录了用户的操作意图
- 进度条的拖动操作（`seekReplay`）不上报埋点

---

## 🎨 组件显示条件

### 日期选择器显示规则
```
┌─────────────────────────────────────────────────────────┐
│  足迹页面 - 日期选择器模块                               │
└─────────────────────┬───────────────────────────────────┘
                      │
          ┌───────────┴──────────┐
          │                      │
      已绑定 ✅               未绑定 ❌
          │                      │
          ▼                      ▼
  ┌───────────────────┐  ┌────────────────────┐
  │ 白色背景          │  │ 背景图 + 绑定按钮  │
  │ 日期选择器        │  │ 日期选择器（下方）  │
  │ 7个日期按钮       │  │ 7个日期按钮        │
  └───────────────────┘  └────────────────────┘
          │                      │
          └──────────┬───────────┘
                     │
                点击任意日期
                     ↓
           上报埋点（含绑定状态）
```

### 轨迹回放按钮显示规则
```
┌─────────────────────────────────────────────────────────┐
│  足迹页面 - 轨迹回放进度条                               │
└─────────────────────┬───────────────────────────────────┘
                      │
          ┌───────────┴──────────┐
          │                      │
    轨迹点 >= 3 ✅         轨迹点 < 3 ❌
          │                      │
          ▼                      ▼
  ┌───────────────────┐  ┌────────────────────┐
  │ 显示回放进度条    │  │ 显示虚拟数据提示   │
  │ - 播放/暂停按钮   │  │ "以下为虚拟数据"   │
  │ - 进度条          │  └────────────────────┘
  └───────────────────┘
          │
          ▼
    点击播放按钮
          │
          ├─── 当前未播放 ─→ 上报埋点 ─→ 开始播放
          │
          └─── 当前播放中 ─→ ❌不上报 ─→ 暂停播放
```

---

## 🧪 测试验证

### 测试场景

#### 场景1：已绑定用户点击日期按钮
**前置条件**: 用户已绑定伴侣

**操作步骤**:
1. 打开足迹页面
2. 观察显示白色背景的日期选择器
3. 点击任意日期按钮（例如"昨天"）

**预期结果**:
- ✅ 控制台输出 `✅ 足迹页面-日期按钮埋点上报成功`
- ✅ 埋点参数包含 `is_bind: "已绑定"`
- ✅ 页面加载选中日期的足迹数据
- ✅ 日期按钮高亮显示切换到新选中的日期

#### 场景2：未绑定用户点击日期按钮
**前置条件**: 用户未绑定伴侣

**操作步骤**:
1. 打开足迹页面
2. 观察显示背景图的日期选择器
3. 点击任意日期按钮

**预期结果**:
- ✅ 控制台输出 `✅ 足迹页面-日期按钮埋点上报成功`
- ✅ 埋点参数包含 `is_bind: "未绑定"`
- ✅ 页面加载选中日期的足迹数据
- ✅ 日期按钮高亮显示切换

#### 场景3：点击回放按钮开始播放
**前置条件**: 
- 当天有足迹数据
- 轨迹点数量 >= 3
- 当前未在播放状态

**操作步骤**:
1. 打开足迹页面，选择有足迹数据的日期
2. 观察页面显示回放进度条（不显示虚拟数据提示）
3. 点击播放按钮（播放图标）

**预期结果**:
- ✅ 控制台输出 `✅ 足迹页面-轨迹回放按钮埋点上报成功`
- ✅ 地图开始播放轨迹动画
- ✅ 按钮图标切换为暂停图标
- ✅ 进度条随动画进度更新

#### 场景4：点击暂停按钮
**前置条件**: 轨迹正在播放中

**操作步骤**:
1. 在轨迹播放过程中
2. 点击暂停按钮（暂停图标）

**预期结果**:
- ✅ 轨迹动画暂停
- ✅ 按钮图标切换为播放图标
- ❌ 控制台**不**输出埋点上报日志
- ✅ 进度条保持在当前位置

#### 场景5：拖动进度条
**前置条件**: 显示回放进度条

**操作步骤**:
1. 拖动进度条到任意位置

**预期结果**:
- ✅ 地图跳转到对应位置
- ❌ 控制台**不**输出埋点上报日志
- ✅ 如果正在播放，从新位置继续播放

#### 场景6：轨迹点不足3个
**前置条件**: 选择的日期足迹点 < 3

**操作步骤**:
1. 打开足迹页面
2. 选择足迹点较少的日期

**预期结果**:
- ✅ 不显示回放进度条
- ✅ 显示"以下为虚拟数据"提示
- ❌ 无法点击播放按钮

#### 场景7：连续点击播放按钮
**前置条件**: 显示回放进度条

**操作步骤**:
1. 点击播放按钮（开始播放）
2. 点击暂停按钮（暂停播放）
3. 再次点击播放按钮（继续播放）

**预期结果**:
- ✅ 第1次点击: 上报埋点
- ❌ 第2次点击: 不上报埋点（暂停）
- ✅ 第3次点击: 上报埋点（再次播放）

### 验证清单
- [ ] 已绑定用户点击日期按钮上报埋点，is_bind为"已绑定"
- [ ] 未绑定用户点击日期按钮上报埋点，is_bind为"未绑定"
- [ ] 点击日期后页面正常加载对应日期数据
- [ ] 点击播放按钮上报埋点
- [ ] 点击暂停按钮不上报埋点
- [ ] 拖动进度条不上报埋点
- [ ] 轨迹点不足3个时不显示回放按钮
- [ ] 连续播放-暂停-播放，每次播放都上报埋点
- [ ] 所有埋点包含 device_id 和 user_id
- [ ] 操作时间格式正确（年/月/日 时:分:秒）
- [ ] 埋点失败不影响业务功能

---

## 📊 数据示例

### 日期按钮埋点数据

#### 已绑定用户
```json
{
  "event_name": "date_button",
  "properties": {
    "device_id": "abc123...",
    "user_id": "12345",
    "click_time": "2025/10/27 14:30:25",
    "is_bind": "已绑定"
  }
}
```

#### 未绑定用户
```json
{
  "event_name": "date_button",
  "properties": {
    "device_id": "abc123...",
    "user_id": "67890",
    "click_time": "2025/10/27 14:32:10",
    "is_bind": "未绑定"
  }
}
```

### 轨迹回放按钮埋点数据
```json
{
  "event_name": "foot_moving",
  "properties": {
    "device_id": "abc123...",
    "user_id": "12345",
    "click_time": "2025/10/27 14:35:10"
  }
}
```

---

## 🎯 数据分析价值

### 日期按钮埋点分析
通过 `date_button` 埋点可以分析：

1. **用户查看习惯**
   - 用户最常查看哪一天的数据（今天 vs 昨天 vs 更早）
   - 用户是否频繁切换日期查看
   - 日期切换频率与用户活跃度的关系

2. **绑定状态差异**
   - 已绑定用户 vs 未绑定用户的日期查看行为差异
   - 未绑定用户是否更多查看今天的数据
   - 绑定后用户查看历史数据的频率是否增加

3. **功能使用率**
   - 日期选择功能的使用频率
   - 哪些用户群体更喜欢查看历史足迹
   - 日期选择与其他功能（如回放）的关联性

### 轨迹回放按钮埋点分析
通过 `foot_moving` 埋点可以分析：

1. **功能使用率**
   - 回放功能的使用频率
   - 多少用户会使用回放功能
   - 回放功能的使用时段分布

2. **用户行为**
   - 用户平均每次访问使用几次回放
   - 回放功能与停留时长的关系
   - 回放功能是否提升用户粘性

3. **产品优化**
   - 回放按钮的可见性和易用性
   - 是否需要引导用户使用回放功能
   - 回放速度和交互是否需要优化

4. **与会员转化的关系**
   - 使用回放功能的用户是否更容易转化为会员
   - 非会员用户对回放功能的需求程度

---

## 📌 注意事项

### 1. 日期按钮埋点

#### 绑定状态获取
- 绑定状态通过 `widget.controller.isBindPartner.value` 获取
- 传递给 `TrackDateSelector` 组件的 `isBind` 参数
- 转换规则: `true` → "已绑定", `false` → "未绑定"

#### 组件复用性
- `TrackDateSelector` 组件设计为可复用
- `isBind` 参数设为可选（`bool?`），允许在其他页面不传该参数
- 只有在 `isBind != null` 时才上报埋点

#### 埋点时机
- 在日期按钮 `onTap` 事件中第一时间上报
- 不依赖数据加载结果，确保记录所有点击行为

### 2. 轨迹回放按钮埋点

#### 状态判断
- 通过 `controller.isReplaying.value` 判断当前播放状态
- 只在 `isReplaying == false` 时上报埋点（开始播放）
- `isReplaying == true` 时不上报（暂停操作）

#### 按钮图标
- 播放图标: `assets/3.0/kissu3_play.webp`
- 暂停图标: `assets/3.0/kissu3_pause.webp`
- 图标自动根据播放状态切换

#### 显示条件
- 只在 `trackPoints.length >= 3` 时显示回放进度条
- 轨迹点不足时显示虚拟数据提示，不提供回放功能

#### 进度条交互
- 进度条拖动（`seekReplay`）不上报埋点
- 只统计用户主动点击播放按钮的行为

### 3. 通用注意事项

#### 异步处理
- 埋点上报使用 `async/await` 确保完整执行
- 但不阻塞后续业务逻辑（埋点失败不影响功能）

#### 错误处理
- 使用 try-catch 捕获埋点异常
- 错误日志输出但不抛出，避免影响用户体验

#### 调试日志
- 成功: `✅ 足迹页面-xxx按钮埋点上报成功`
- 失败: `❌ 足迹页面-xxx按钮埋点上报失败: $e`

---

## 🔗 相关文档
- [足迹页面埋点集成（页面浏览和滑动状态）](./footprint_page_tracking.md)
- [足迹页面停留点点击和关闭埋点](./footprint_stop_point_tracking.md)
- [足迹页面绑定和会员按钮埋点](./footprint_bind_and_membership_buttons_tracking.md)
- [友盟埋点服务文档](./umeng_event_timing_feature.md)

---

## ✅ 集成完成
- ✅ TrackingService 方法已添加
- ✅ 日期按钮埋点已集成到 TrackDateSelector 组件
- ✅ 轨迹回放按钮埋点已集成到 _ReplayProgressBar 组件
- ✅ 绑定状态传递已实现
- ✅ 调试日志已完善
- ✅ 文档已创建

**最后更新**: 2025-10-27

