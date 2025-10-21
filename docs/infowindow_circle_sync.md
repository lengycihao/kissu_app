# InfoWindow 和围栏圆圈同步显示/隐藏实现

## 📋 需求
确保地图上的 InfoWindow 和围栏圆圈在**相同时机**出现和消失，保持视觉一致性。

## 🔧 修改内容

### 1. LogUtil.e() 编译错误修复
**文件**: `plugins/amap_flutter_map-3.0.0/android/src/main/java/com/amap/flutter/map/core/MapController.java`

修复了4处 `LogUtil.e()` 调用缺少 `Throwable` 参数的编译错误：
- 第484行：创建围栏圆圈错误日志
- 第500行：隐藏围栏圆圈错误日志
- 第517行：清除围栏圆圈错误日志
- 第535行：解析颜色错误日志

**修改前**:
```java
LogUtil.e(CLASS_NAME, "Error creating geofence circle: " + e.getMessage());
```

**修改后**:
```java
LogUtil.e(CLASS_NAME, "Error creating geofence circle", e);
```

---

### 2. 创建统一清除方法
**文件**: `lib/pages/track/track_controller.dart`

新增 `clearMapHighlights()` 方法，统一清除 InfoWindow 和围栏圆圈：

```dart
/// 🎯 统一清除：同时隐藏 InfoWindow 和清除圆圈
/// 确保 InfoWindow 和圆圈在相同时机出现和消失
void clearMapHighlights() {
  DebugUtil.info('🧹 [MapHighlights] 清除所有地图高亮（InfoWindow + 围栏圆圈）');
  _hideAllInfoWindows();
  clearAllHighlightCircles();
}
```

---

### 3. 修改 drawHighlightCircle() 方法
**文件**: `lib/pages/track/track_controller.dart`

**关键修改**: 移除了绘制圆圈时自动隐藏 InfoWindow 的逻辑，确保圆圈和 InfoWindow 可以同时显示。

**修改前**:
```dart
void drawHighlightCircle(LatLng center) {
  DebugUtil.info('🎯 开始绘制高亮圆圈: ${center.latitude}, ${center.longitude}');
  
  // 🎯 绘制圆圈时隐藏所有 InfoWindow（避免视觉混乱）
  _hideAllInfoWindows();  // ❌ 这行导致了问题！
  
  if (mapController != null) {
    // ... 绘制圆圈代码
  }
}
```

**修改后**:
```dart
/// 绘制高亮圆圈（使用原生地图API）
/// 🎯 不会隐藏 InfoWindow，确保圆圈和 InfoWindow 同时显示
void drawHighlightCircle(LatLng center) {
  DebugUtil.info('🎯 开始绘制高亮圆圈: ${center.latitude}, ${center.longitude}');
  
  // ✅ 移除了 _hideAllInfoWindows() 调用
  
  if (mapController != null) {
    // ... 绘制圆圈代码
    DebugUtil.success('✅ 高亮圆圈已绘制（使用原生API），InfoWindow保持显示');
  }
}
```

---

### 4. 更新地图点击事件
**文件**: `lib/pages/track/track_page.dart`

**修改前**:
```dart
onTap: (LatLng position) {
  // 点击地图时清除高亮圆圈
  widget.controller.clearAllHighlightCircles();  // ❌ 只清除了圆圈
},
```

**修改后**:
```dart
onTap: (LatLng position) {
  // 🎯 点击地图时统一清除：InfoWindow + 围栏圆圈
  widget.controller.clearMapHighlights();  // ✅ 同时清除两者
},
```

---

### 5. 修复降级 Marker 的 onTap 行为
**文件**: `lib/pages/track/track_controller.dart`

确保所有 marker 点击都使用统一的行为（显示 InfoWindow + 绘制圆圈）。

**修改前**:
```dart
onTap: (String markerId) {
  DebugUtil.info('🎯 点击地图上的停留点: ${stop.locationName}');
  _moveMapToLocation(LatLng(stop.lat, stop.lng));  // ❌ 只移动地图，没有圆圈
},
```

**修改后**:
```dart
onTap: (String markerId) {
  DebugUtil.info('🎯 点击地图上的停留点: ${stop.locationName}');
  // 🎯 移动地图并绘制高亮圆圈
  unawaited(_moveToStopPointWithHighlightInternal(
    stop.lat, 
    stop.lng, 
    stopPoint: stop,
  ));  // ✅ 显示 InfoWindow + 绘制圆圈
},
```

---

## 📍 完整行为场景

### 场景1: 点击地图上的 Marker
**行为**: 
1. 关闭所有现有 InfoWindow
2. 移动地图到目标位置
3. 500ms 后显示该 Marker 的 InfoWindow
4. 200ms 后绘制围栏圆圈

**结果**: ✅ InfoWindow 和圆圈同时显示

**相关代码**: `_moveToStopPointWithHighlightInternal()` 方法

---

### 场景2: 点击底部列表中的停留点
**行为**: 
1. 调用 `moveToStopPointWithHighlight()`
2. 内部调用 `_moveToStopPointWithHighlightInternal()`
3. 同场景1

**结果**: ✅ InfoWindow 和圆圈同时显示

**相关代码**: `stop_list_page.dart` 的列表项点击事件

---

### 场景3: 点击地图空白处
**行为**: 
1. 调用 `clearMapHighlights()`
2. 同时隐藏所有 InfoWindow
3. 同时清除围栏圆圈

**结果**: ✅ InfoWindow 和圆圈同时消失

**相关代码**: `track_page.dart` 的 `onTap` 事件

---

### 场景4: 点击 InfoWindow 关闭按钮
**行为**: 
1. InfoWindow 关闭
2. 同时清除围栏圆圈

**结果**: ✅ InfoWindow 和圆圈同时消失

**相关代码**: `track_page.dart` 的 `onInfoWindowClose` 事件

---

### 场景5: 拖拽 Marker
**行为**: 
1. 拖拽结束时调用 `drawHighlightCircle()`
2. 只绘制圆圈（不自动显示 InfoWindow）

**结果**: ✅ 只显示圆圈（符合预期，拖拽时不需要 InfoWindow）

**相关代码**: Marker 的 `onDragEnd` 回调

---

## 🧪 验证清单

测试所有场景，确保 InfoWindow 和圆圈的显示/隐藏保持同步：

- [ ] 点击地图上的停留点 Marker → InfoWindow 和圆圈同时出现
- [ ] 点击底部列表的停留点 → InfoWindow 和圆圈同时出现
- [ ] 点击地图空白处 → InfoWindow 和圆圈同时消失
- [ ] 点击 InfoWindow 的关闭按钮 → InfoWindow 和圆圈同时消失
- [ ] 点击另一个 Marker → 前一个的 InfoWindow 和圆圈消失，新的同时出现
- [ ] 拖拽 Marker → 只显示圆圈（符合预期）
- [ ] 从定位页面跳转到轨迹页面 → InfoWindow 和圆圈同时出现

---

## 🎯 关键要点

1. **统一入口**: 所有清除操作都通过 `clearMapHighlights()` 统一处理
2. **独立绘制**: `drawHighlightCircle()` 不再隐藏 InfoWindow，两者独立控制
3. **时序控制**: 在 `_moveToStopPointWithHighlightInternal()` 中使用延迟确保正确的显示顺序
4. **一致性**: 所有 marker 点击都使用相同的逻辑路径

---

## 📝 注意事项

1. **时序问题**: InfoWindow 和圆圈的显示有短暂的时间差（200ms），这是为了确保地图动画完成后再绘制圆圈
2. **拖拽特殊处理**: 拖拽结束时只绘制圆圈，不显示 InfoWindow，这是合理的 UX 设计
3. **动画锁**: 使用动画锁机制防止用户在地图变化时滑动面板造成冲突

---

## 🔄 相关文件

- `plugins/amap_flutter_map-3.0.0/android/src/main/java/com/amap/flutter/map/core/MapController.java`
- `lib/pages/track/track_controller.dart`
- `lib/pages/track/track_page.dart`
- `lib/pages/track/component/stop_list_page.dart`

