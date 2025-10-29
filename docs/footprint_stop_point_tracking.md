# 足迹页面停留点点击和关闭埋点集成文档

## 📋 概述
本文档记录了**足迹页面**（`TrackPage`）中停留点相关的友盟埋点集成实现，包括停留点点击和 InfoWindow 关闭两个埋点事件。

---

## 🎯 埋点事件列表

### 1. 停留点点击埋点
**事件名称**: `footprint_stay_button`  
**事件类型**: 点击事件  
**触发时机**: 用户点击地图上的停留点标记时

#### 参数说明
| 参数名 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `device_id` | String | 虚拟用户ID（通过设备号生成） | "abc123..." |
| `user_id` | String | 用户ID | "12345" |
| `click_time` | String | 操作时间 | "2025-01-15 14:30:25" |

#### 实现位置
- **Manager**: `TrackMarkerManager.handleStopPointTap()`
- **方法**: `_trackStopPointClick()`
- **上报时机**: 停留点被点击时立即上报

#### 代码实现
```dart
/// 处理停留点点击
void handleStopPointTap(dynamic stopPoint) {
  DebugUtil.info('停留点被点击: ${stopPoint.title}');
  
  // 上报停留点点击埋点
  _trackStopPointClick();
  
  // 先清除之前的高亮（InfoWindow + 圆圈）
  clearMapHighlights();
  
  // 延迟执行，避免与清除操作冲突
  Future.delayed(const Duration(milliseconds: 100), () {
    // 1. 先收起下半屏到底部吸顶位置
    collapseToBottomPosition?.call();
    
    // 2. 等待面板收起动画完成后移动地图
    Future.delayed(const Duration(milliseconds: 300), () {
      _moveMapToLocation(stopPoint.position);
      
      // 3. 等待地图移动完成后显示InfoWindow
      Future.delayed(const Duration(milliseconds: 500), () async {
        await _showStopPointInfo(stopPoint);
        
        // 4. InfoWindow创建完成后再绘制高亮圆圈
        Future.delayed(const Duration(milliseconds: 200), () {
          drawHighlightCircle(stopPoint.position);
        });
      });
    });
  });
}

/// 上报停留点点击埋点
Future<void> _trackStopPointClick() async {
  try {
    await TrackingService.trackFootprintStayButton();
    DebugUtil.info('✅ 足迹页面-停留点点击埋点上报成功');
  } catch (e) {
    DebugUtil.error('❌ 足迹页面-停留点点击埋点上报失败: $e');
  }
}
```

---

### 2. 停留位置关闭按钮埋点
**事件名称**: `footprint_stay_close_button`  
**事件类型**: 点击事件  
**触发时机**: 用户关闭 InfoWindow 时（点击关闭按钮或点击地图其他区域）

#### 参数说明
| 参数名 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `device_id` | String | 虚拟用户ID（通过设备号生成） | "abc123..." |
| `user_id` | String | 用户ID | "12345" |
| `click_time` | String | 操作时间 | "2025-01-15 14:30:30" |

#### 实现位置
- **Page**: `_TrackPageContentState` in `TrackPage`
- **回调**: `onInfoWindowClose` in `AMapWidget`
- **方法**: `_trackInfoWindowClose()`
- **上报时机**: InfoWindow 关闭时

#### 代码实现
```dart
// 在 AMapWidget 中配置关闭回调
SafeAMapWidget(
  initialCameraPosition: widget.controller.initialCameraPosition,
  onMapCreated: widget.controller.onMapCreated,
  markers: _cachedMarkers,
  polylines: _cachedPolylines,
  circles: widget.controller.highlightCircles.toSet(),
  // ... 其他配置
  onTap: (LatLng position) {
    widget.controller.clearMapHighlights();
  },
  onInfoWindowClose: () {
    // 上报关闭埋点
    _trackInfoWindowClose();
    widget.controller.clearAllHighlightCircles();
  },
)

/// 上报 InfoWindow 关闭埋点
Future<void> _trackInfoWindowClose() async {
  try {
    await TrackingService.trackFootprintStayCloseButton();
    DebugUtil.info('✅ 足迹页面-停留位置关闭按钮埋点上报成功');
  } catch (e) {
    DebugUtil.error('❌ 足迹页面-停留位置关闭按钮埋点上报失败: $e');
  }
}
```

---

## 🔧 TrackingService 方法

### 方法列表

#### 1. trackFootprintStayButton
```dart
/// 埋点：足迹页 - 停留点点击
/// 
/// 事件ID: footprint_stay_button
/// 
/// 参数：
/// - device_id: 虚拟用户ID
/// - user_id: 用户ID
/// - click_time: 操作时间
static Future<void> trackFootprintStayButton() async {
  final params = await _buildBaseParams();
  await _trackEvent('footprint_stay_button', params, '足迹页面-停留点点击');
}
```

#### 2. trackFootprintStayCloseButton
```dart
/// 埋点：足迹页 - 停留位置关闭按钮
/// 
/// 事件ID: footprint_stay_close_button
/// 
/// 参数：
/// - device_id: 虚拟用户ID
/// - user_id: 用户ID
/// - click_time: 操作时间
static Future<void> trackFootprintStayCloseButton() async {
  final params = await _buildBaseParams();
  await _trackEvent('footprint_stay_close_button', params, '足迹页面-停留位置关闭按钮');
}
```

---

## 📝 实现要点

### 1. 停留点点击流程
1. 用户点击地图上的停留点标记
2. 触发 `handleStopPointTap` 方法
3. **立即上报埋点**（在任何UI操作之前）
4. 清除之前的高亮（InfoWindow + 圆圈）
5. 收起底部面板到底部吸顶位置
6. 移动地图相机到停留点位置
7. 显示停留点的 InfoWindow
8. 绘制高亮圆圈

**关键点**：埋点在最开始上报，确保即使后续操作失败也能记录用户行为。

### 2. InfoWindow 关闭监听
- 使用高德地图提供的 `onInfoWindowClose` 回调
- 该回调在以下情况触发：
  - 用户点击 InfoWindow 上的关闭按钮
  - 用户点击地图上的其他区域
  - 用户点击另一个停留点（会先关闭当前 InfoWindow）
  - 代码主动调用 `clearMapHighlights()`

### 3. 埋点上报时机
- **停留点点击埋点**: 在点击事件处理的**最开始**上报，不受后续UI操作影响
- **关闭按钮埋点**: 在 InfoWindow 关闭回调中上报，之后再清理高亮圆圈

### 4. 异常处理
- 所有埋点方法都使用 try-catch 包裹
- 失败时打印错误日志，但不影响正常业务流程
- 使用 `DebugUtil` 记录成功和失败日志

---

## 🎨 停留点交互流程图

```
┌─────────────────────────────────────────────────────────┐
│                      用户点击停留点                        │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
          ┌─────────────────────────┐
          │  上报停留点点击埋点     │ ✅ footprint_stay_button
          │  (立即上报，不等待)     │
          └─────────┬───────────────┘
                    │
                    ▼
          ┌─────────────────────────┐
          │  清除旧的 InfoWindow    │
          │  和高亮圆圈             │
          └─────────┬───────────────┘
                    │
                    ▼
          ┌─────────────────────────┐
          │  收起底部面板到底部      │
          └─────────┬───────────────┘
                    │
                    ▼
          ┌─────────────────────────┐
          │  移动地图相机到停留点    │
          └─────────┬───────────────┘
                    │
                    ▼
          ┌─────────────────────────┐
          │  显示停留点 InfoWindow  │
          └─────────┬───────────────┘
                    │
                    ▼
          ┌─────────────────────────┐
          │  绘制高亮圆圈           │
          └─────────────────────────┘
                    │
                    │ (用户点击关闭或地图其他区域)
                    ▼
          ┌─────────────────────────┐
          │  InfoWindow 关闭回调    │
          └─────────┬───────────────┘
                    │
                    ▼
          ┌─────────────────────────┐
          │  上报关闭按钮埋点       │ ✅ footprint_stay_close_button
          └─────────┬───────────────┘
                    │
                    ▼
          ┌─────────────────────────┐
          │  清除高亮圆圈           │
          └─────────────────────────┘
```

---

## 🧪 测试验证

### 测试场景

#### 场景1：点击停留点显示 InfoWindow
1. 打开足迹页面，地图上显示多个停留点
2. 点击任意一个停留点标记
3. **预期**: 
   - 控制台输出 `✅ 足迹页面-停留点点击埋点上报成功`
   - 底部面板收起到底部吸顶位置
   - 地图相机移动到停留点位置
   - 显示停留点的 InfoWindow（包含位置名称、停留时长、停留时间）
   - 停留点周围显示蓝色高亮圆圈

#### 场景2：点击关闭按钮关闭 InfoWindow
1. 在显示 InfoWindow 的状态下
2. 点击 InfoWindow 上的关闭按钮（X）
3. **预期**:
   - 控制台输出 `✅ 足迹页面-停留位置关闭按钮埋点上报成功`
   - InfoWindow 消失
   - 高亮圆圈消失

#### 场景3：点击地图其他区域关闭 InfoWindow
1. 在显示 InfoWindow 的状态下
2. 点击地图上的空白区域（非停留点）
3. **预期**:
   - 控制台输出 `✅ 足迹页面-停留位置关闭按钮埋点上报成功`
   - InfoWindow 消失
   - 高亮圆圈消失

#### 场景4：点击另一个停留点
1. 在显示停留点A的 InfoWindow 时
2. 点击另一个停留点B
3. **预期**:
   - 先输出 `✅ 足迹页面-停留位置关闭按钮埋点上报成功`（关闭A）
   - 再输出 `✅ 足迹页面-停留点点击埋点上报成功`（点击B）
   - 停留点A的 InfoWindow 和圆圈消失
   - 停留点B的 InfoWindow 和圆圈显示

### 验证清单
- [ ] 点击停留点立即上报埋点
- [ ] 停留点点击埋点在UI操作之前上报
- [ ] InfoWindow 正确显示停留点信息
- [ ] 高亮圆圈正确绘制在停留点周围
- [ ] 点击关闭按钮触发关闭埋点
- [ ] 点击地图其他区域触发关闭埋点
- [ ] 点击另一个停留点先触发关闭埋点再触发点击埋点
- [ ] 所有埋点包含 device_id 和 user_id
- [ ] 操作时间格式正确（yyyy-MM-dd HH:mm:ss）
- [ ] 埋点失败不影响业务功能

---

## 📊 数据示例

### 停留点点击埋点数据
```json
{
  "event_name": "footprint_stay_button",
  "properties": {
    "device_id": "abc123...",
    "user_id": "12345",
    "click_time": "2025-01-15 14:30:25"
  }
}
```

### 停留位置关闭按钮埋点数据
```json
{
  "event_name": "footprint_stay_close_button",
  "properties": {
    "device_id": "abc123...",
    "user_id": "12345",
    "click_time": "2025-01-15 14:30:30"
  }
}
```

---

## 🔍 InfoWindow 显示内容

InfoWindow 显示以下信息：
- **标题**: 停留点位置名称（如：公司、家、咖啡店等）
- **停留时长**: 在该位置停留的时长（如：停留2小时30分钟）
- **停留时间**: 停留的时间段（如：09:00~11:30）

示例：
```
┌─────────────────────────────────┐
│  ×                              │ ← 关闭按钮
│  📍 星巴克咖啡                   │ ← 位置名称
│  ⏱️ 停留1小时15分钟              │ ← 停留时长
│  🕐 14:00~15:15                 │ ← 停留时间
└─────────────────────────────────┘
         │
         ▼
    停留点标记 (粉色圆圈 + 数字)
         │
    ○○○○○○○○○ ← 蓝色高亮圆圈（100米半径）
```

---

## 🎯 停留点标记说明

- **外观**: 粉色圆形标记，中间显示停留点序号
- **编号**: 使用 `serialNumber` 字段，与底部列表保持一致
- **自适应**: 
  - 个位数（1-9）：圆形标记
  - 多位数（10+）：椭圆形标记（自动调整宽度）
- **样式**: 
  - 背景色：粉色 (#FF69B4)
  - 边框：白色，2px宽度
  - 文字：白色，粗体

---

## 📌 注意事项

### 1. 埋点上报顺序
- 停留点点击埋点必须在**最开始**上报
- 不要等待UI操作完成再上报
- 即使后续操作失败，用户行为也应该被记录

### 2. InfoWindow 关闭触发场景
`onInfoWindowClose` 回调会在多种场景下触发：
- ✅ 用户主动点击关闭按钮
- ✅ 用户点击地图其他区域
- ✅ 用户点击另一个停留点
- ❌ 代码主动调用 `clearMapHighlights()` **不会**触发此回调

### 3. 避免重复上报
- 代码主动调用 `clearMapHighlights()` 时，不会触发 `onInfoWindowClose`
- 因此不用担心在代码清理时重复上报关闭埋点
- 只有用户主动关闭时才会上报

### 4. 与底部列表的联动
- 底部列表点击跳转到定位页时，应该在定位页上报埋点
- 足迹页的停留点点击埋点只记录**地图上**的点击行为
- 两个页面的埋点互不干扰

---

## 🔗 相关文档
- [足迹页面埋点集成（页面浏览和滑动状态）](./footprint_page_tracking.md)
- [位置提醒列表页面埋点集成](./location_reminder_tracking.md)
- [添加地点页面埋点集成](./location_picker_tracking.md)
- [友盟埋点服务文档](./umeng_event_timing_feature.md)

---

## ✅ 集成完成
- ✅ TrackingService 方法已添加
- ✅ TrackMarkerManager 停留点点击埋点已实现
- ✅ TrackPage InfoWindow 关闭埋点已实现
- ✅ 调试日志已完善
- ✅ 文档已创建

**最后更新**: 2025-01-15

