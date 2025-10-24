# 轨迹页面停留点列表点击交互功能

## 功能说明

在轨迹页面下半屏的停留点列表中，点击任意停留点时会触发以下流程：

1. **收起下半屏** - 将底部面板收起到最小位置（30%高度）
2. **清除旧高亮** - 清除地图上之前的InfoWindow和高亮圆圈
3. **移动相机** - 将地图相机移动到点击的停留点位置（zoom=16）
4. **显示InfoWindow** - 显示该停留点的详细信息InfoWindow
5. **绘制高亮圆圈** - 在停留点周围绘制高亮圆圈

## 实现细节

### 1. StopListItem组件
- **文件**: `lib/pages/track/component/stop_list_page.dart`
- **功能**: 停留点列表项，已实现点击手势
- **点击逻辑**:
  ```dart
  onTap: () async {
    final controller = Get.find<TrackController>();
    final stopPoint = TrackStopPoint(...); // 创建停留点对象
    await controller.moveToStopPointWithHighlight(
      context, 
      record.latitude, 
      record.longitude, 
      stopPoint: stopPoint,
    );
  }
  ```

### 2. TrackController.moveToStopPointWithHighlight方法
- **文件**: `lib/pages/track/track_controller.dart`
- **完整流程**:
  ```dart
  1. 设置动画锁 (_mapManager.setAnimationLock(true))
  2. 收起下半屏 (_uiManager.collapseToMinPosition())
  3. 清除旧高亮 (_markerManager.clearMapHighlights())
  4. 移动相机 (mapController.moveCamera(...))
  5. 显示InfoWindow (_markerManager.showInfoWindowForStopPoint(stopPoint))
  6. 绘制高亮圆圈 (_markerManager.drawHighlightCircle(targetLocation))
  7. 释放动画锁
  ```

### 3. TrackUIManager新增方法
- **文件**: `lib/pages/track/managers/track_ui_manager.dart`
- **新增方法**: `collapseToMinPosition()`
- **功能**: 将底部面板收起到最小位置（0.3，即30%高度）
- **实现**:
  ```dart
  void collapseToMinPosition() {
    if (_draggableController != null) {
      _draggableController!.animateTo(
        0.3, // 收起到最小位置
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  ```

## 延迟时间设置

为确保流畅的用户体验，各步骤之间设置了合理的延迟：

- **步骤1→步骤2**: 100ms（收起面板后再清除高亮）
- **步骤2→步骤3**: 100ms（清除高亮后再移动相机）
- **步骤3→步骤4**: 500ms（相机移动完成后显示InfoWindow）
- **步骤4→步骤5**: 200ms（InfoWindow显示后绘制高亮圆圈）
- **动画锁释放**: 1500ms（整个流程完成后释放）

## 用户体验

1. **流畅动画**: 所有操作都使用动画过渡，避免突兀
2. **防止冲突**: 使用动画锁防止用户在地图变化时滑动面板
3. **清晰反馈**: 每个步骤都有日志输出，便于调试和追踪
4. **聚焦点位**: 收起面板后，用户可以清晰看到地图上的停留点和InfoWindow

## 调试日志

点击停留点时会输出以下日志（带标签`[StopPointClick]`）：
- `步骤1: 收起下半屏`
- `步骤2: 清除旧高亮`
- `步骤3: 移动相机到目标点`
- `步骤4: 显示InfoWindow`
- `步骤5: 绘制高亮圆圈`
- `✅ 完整流程执行完成！`

## 相关文件

- `lib/pages/track/component/stop_list_page.dart` - 停留点列表UI
- `lib/pages/track/track_controller.dart` - 主控制器，实现点击交互逻辑
- `lib/pages/track/managers/track_ui_manager.dart` - UI管理器，控制面板收起/展开
- `lib/pages/track/managers/track_marker_manager.dart` - 标记管理器，控制InfoWindow和高亮圆圈

## 测试建议

1. 点击停留点列表中的任意项，观察：
   - 底部面板是否流畅收起
   - 地图是否移动到正确位置
   - InfoWindow是否正确显示
   - 高亮圆圈是否正确绘制

2. 快速连续点击多个停留点，观察：
   - 是否会产生冲突
   - 动画是否流畅
   - 是否正确清除旧的高亮

3. 在底部面板处于不同高度时点击停留点，观察：
   - 是否都能正确收起到最小位置
   - 动画是否自然

