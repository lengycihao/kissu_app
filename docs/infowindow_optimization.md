# InfoWindow 优化文档

## 概述
本次优化为高德地图插件添加了全局和精准的 InfoWindow 控制功能，并在轨迹页面优化了 InfoWindow 的显示和隐藏逻辑，提升用户体验。

## 优化内容

### 1. 地图插件层面的改进

#### 1.1 Marker 新增 infoWindowId 字段
**文件**: `plugins/amap_flutter_map-3.0.0/lib/src/types/marker.dart`

在 `Marker` 类中添加了 `infoWindowId` 字段，用于唯一标识 InfoWindow：

```dart
/// InfoWindow 的唯一标识符（用于精准控制 InfoWindow 的显示和隐藏）
/// 如果不设置，则使用 Marker 的 id 作为默认标识
final String? infoWindowId;
```

**特点**:
- 可选字段，如果不设置则使用 Marker 的 id
- 支持在 `copyWith()` 方法中传递
- 已添加到 `toMap()` 序列化方法中
- 已添加到 `operator ==` 比较方法中

#### 1.2 AMapController 新增 InfoWindow 控制方法
**文件**: `plugins/amap_flutter_map-3.0.0/lib/src/amap_controller.dart`

添加了三个新方法：

```dart
/// 隐藏所有 InfoWindow
Future<void> hideAllInfoWindows();

/// 隐藏指定 Marker 的 InfoWindow
Future<void> hideInfoWindow(String markerId);

/// 显示指定 Marker 的 InfoWindow
Future<void> showInfoWindow(String markerId);
```

#### 1.3 MethodChannel 层实现
**文件**: `plugins/amap_flutter_map-3.0.0/lib/src/core/method_channel_amap_flutter_map.dart`

实现了与原生端的通信接口：
- `map#hideAllInfoWindows` - 隐藏所有 InfoWindow
- `map#hideInfoWindow` - 隐藏指定 InfoWindow
- `map#showInfoWindow` - 显示指定 InfoWindow

### 2. Android 端实现

#### 2.1 常量定义
**文件**: `plugins/amap_flutter_map-3.0.0/android/src/main/java/com/amap/flutter/map/utils/Const.java`

新增方法常量：
```java
public static final String METHOD_MAP_HIDE_ALL_INFO_WINDOWS = "map#hideAllInfoWindows";
public static final String METHOD_MAP_HIDE_INFO_WINDOW = "map#hideInfoWindow";
public static final String METHOD_MAP_SHOW_INFO_WINDOW = "map#showInfoWindow";
```

#### 2.2 MapController 实现
**文件**: `plugins/amap_flutter_map-3.0.0/android/src/main/java/com/amap/flutter/map/core/MapController.java`

添加了：
- `markersController` 引用字段
- `setMarkersController()` 方法
- 三个方法的 case 分支处理

#### 2.3 MarkersController 实现
**文件**: `plugins/amap_flutter_map-3.0.0/android/src/main/java/com/amap/flutter/map/overlays/marker/MarkersController.java`

新增三个公共方法：

```java
/// 隐藏所有 InfoWindow
public void hideAllInfoWindows()

/// 隐藏指定 Marker 的 InfoWindow
public void hideInfoWindowByMarkerId(String dartMarkerId)

/// 显示指定 Marker 的 InfoWindow
public void showInfoWindowByMarkerId(String dartMarkerId)
```

**实现细节**:
- `hideAllInfoWindows()`: 调用 `CustomInfoWindowAdapter.hideCurrentInfoWindow()` 并清空选中状态
- `hideInfoWindowByMarkerId()`: 通过 markerId 查找对应的 MarkerController 并调用 `hideInfoWindow()`
- `showInfoWindowByMarkerId()`: 通过 markerId 查找对应的 MarkerController 并调用 `showInfoWindow()`

#### 2.4 AMapPlatformView 连接
**文件**: `plugins/amap_flutter_map-3.0.0/android/src/main/java/com/amap/flutter/map/AMapPlatformView.java`

在初始化时建立 MapController 和 MarkersController 的连接：
```java
mapController.setMarkersController(markersController);
```

### 3. iOS 端实现

#### 3.1 AMapMarkerController 头文件
**文件**: `plugins/amap_flutter_map-3.0.0/ios/Classes/OverlayController/AMapMarkerController.h`

添加方法声明：
```objc
/// 隐藏所有 InfoWindow
- (void)hideAllInfoWindows;

/// 隐藏指定 Marker 的 InfoWindow
- (void)hideInfoWindowByMarkerId:(NSString *)markerId;

/// 显示指定 Marker 的 InfoWindow
- (void)showInfoWindowByMarkerId:(NSString *)markerId;
```

#### 3.2 AMapMarkerController 实现
**文件**: `plugins/amap_flutter_map-3.0.0/ios/Classes/OverlayController/AMapMarkerController.m`

实现方法：
```objc
- (void)hideAllInfoWindows {
    // 遍历所有标注视图，隐藏callout
    for (id<MAAnnotation> annotation in self.mapView.annotations) {
        MAAnnotationView *view = [self.mapView viewForAnnotation:annotation];
        if (view && view.calloutView) {
            [view setSelected:NO animated:NO];
        }
    }
}

- (void)hideInfoWindowByMarkerId:(NSString *)markerId {
    AMapMarker *marker = _markerDict[markerId];
    if (marker && marker.annotation) {
        MAAnnotationView *view = [self.mapView viewForAnnotation:marker.annotation];
        if (view) {
            [view setSelected:NO animated:NO];
        }
    }
}

- (void)showInfoWindowByMarkerId:(NSString *)markerId {
    AMapMarker *marker = _markerDict[markerId];
    if (marker && marker.annotation) {
        MAAnnotationView *view = [self.mapView viewForAnnotation:marker.annotation];
        if (view) {
            [view setSelected:YES animated:YES];
        }
    }
}
```

#### 3.3 AMapViewController 集成
**文件**: `plugins/amap_flutter_map-3.0.0/ios/Classes/AMapViewController.m`

添加方法调用处理：
```objc
[self.channel addMethodName:@"map#hideAllInfoWindows" withHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
    [weakSelf.markerController hideAllInfoWindows];
    result(nil);
}];

[self.channel addMethodName:@"map#hideInfoWindow" withHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
    NSString *markerId = call.arguments[@"markerId"];
    if (markerId) {
        [weakSelf.markerController hideInfoWindowByMarkerId:markerId];
        result(nil);
    } else {
        result([FlutterError errorWithCode:@"INVALID_ARGUMENT" message:@"markerId is null" details:nil]);
    }
}];

[self.channel addMethodName:@"map#showInfoWindow" withHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
    NSString *markerId = call.arguments[@"markerId"];
    if (markerId) {
        [weakSelf.markerController showInfoWindowByMarkerId:markerId];
        result(nil);
    } else {
        result([FlutterError errorWithCode:@"INVALID_ARGUMENT" message:@"markerId is null" details:nil]);
    }
}];
```

### 4. 轨迹页面应用层优化

#### 4.1 新增 _hideAllInfoWindows() 方法
**文件**: `lib/pages/track/track_controller.dart`

添加了私有方法来隐藏所有 InfoWindow：

```dart
/// 隐藏所有 InfoWindow
void _hideAllInfoWindows() {
  if (mapController != null) {
    try {
      mapController!.hideAllInfoWindows();
      DebugUtil.info('🎯 已隐藏所有 InfoWindow');
    } catch (e) {
      DebugUtil.error('❌ 隐藏所有 InfoWindow 失败: $e');
    }
  }
}
```

#### 4.2 切换头像时隐藏 InfoWindow

在以下方法中添加了 InfoWindow 隐藏逻辑：

**switchUser() 方法**:
```dart
void switchUser() {
  isOneself.value = isOneself.value == 1 ? 0 : 1;
  
  // 🎯 切换用户时隐藏所有 InfoWindow
  _hideAllInfoWindows();
  
  _clearDataForAvatarSwitch();
  Future.microtask(() => _loadDataAsync());
}
```

**onAvatarTapped() 方法**:
```dart
void onAvatarTapped(bool isMyself) {
  DebugUtil.info('🎯 头像点击开始 - isMyself: $isMyself');
  
  // 🎯 切换头像时隐藏所有 InfoWindow
  _hideAllInfoWindows();
  
  if (isReplaying.value) {
    DebugUtil.info('🛑 检测到正在播放轨迹，切换头像时重置播放状态');
    _resetReplayState();
  }
  // ... 其他逻辑
}
```

#### 4.3 点击停留点时隐藏 InfoWindow

**moveToStopPoint() 方法**:
```dart
void moveToStopPoint(double latitude, double longitude) {
  // 🎯 点击停留点时隐藏所有 InfoWindow
  _hideAllInfoWindows();
  
  // 检查地图是否就绪
  if (!isMapReady.value || mapController == null) {
    DebugUtil.warning('地图未就绪或控制器为空，无法移动到停留点');
    return;
  }
  // ... 其他逻辑
}
```

#### 4.4 绘制高亮圆圈时隐藏 InfoWindow

**drawHighlightCircle() 方法**:
```dart
void drawHighlightCircle(LatLng center) {
  DebugUtil.info('🎯 开始绘制高亮圆圈: ${center.latitude}, ${center.longitude}');
  
  // 先清除之前的高亮圆圈
  clearAllHighlightCircles();
  
  // 🎯 绘制圆圈时隐藏所有 InfoWindow（避免视觉混乱）
  _hideAllInfoWindows();
  
  // ... 其他逻辑
}
```

## 优化效果

### 用户体验提升

1. **切换头像时**：
   - ✅ 自动隐藏所有 InfoWindow
   - ✅ 避免显示上一个用户的停留点信息
   - ✅ 视觉更加干净清爽

2. **点击停留点时**：
   - ✅ 先隐藏之前的 InfoWindow
   - ✅ 移动地图到新位置
   - ✅ 绘制高亮圆圈
   - ✅ 避免多个 InfoWindow 同时显示

3. **绘制高亮圆圈时**：
   - ✅ 自动隐藏 InfoWindow
   - ✅ 确保高亮圆圈是唯一的视觉焦点
   - ✅ 避免信息重叠混乱

### 技术优势

1. **跨平台一致性**：
   - Android 和 iOS 使用相同的接口
   - 行为完全一致

2. **灵活性**：
   - 支持隐藏所有 InfoWindow
   - 支持精准控制单个 InfoWindow
   - 支持显示指定 InfoWindow

3. **扩展性**：
   - 添加了 `infoWindowId` 字段，为未来功能预留
   - 方法设计简洁，易于维护和扩展

4. **健壮性**：
   - 所有操作都有错误处理
   - 提供详细的日志输出
   - 空值检查完善

## 测试建议

### 功能测试

1. **切换头像**：
   - 在自己和另一半之间切换
   - 验证 InfoWindow 是否正确隐藏

2. **点击停留点**：
   - 点击列表中的停留点
   - 验证地图移动和 InfoWindow 隐藏

3. **点击地图上的停留点 Marker**：
   - 点击不同的 Marker
   - 验证 InfoWindow 的显示和隐藏

4. **绘制高亮圆圈**：
   - 触发高亮圆圈绘制
   - 验证 InfoWindow 是否被隐藏

### 平台测试

1. **Android 测试**：
   - 测试所有 InfoWindow 控制功能
   - 验证日志输出

2. **iOS 测试**：
   - 测试所有 InfoWindow 控制功能
   - 验证日志输出

### 边界条件测试

1. 地图未初始化时调用方法
2. Marker 不存在时调用方法
3. 快速连续切换头像
4. 快速连续点击停留点

## 相关文件

### Flutter 层
- `plugins/amap_flutter_map-3.0.0/lib/src/types/marker.dart`
- `plugins/amap_flutter_map-3.0.0/lib/src/amap_controller.dart`
- `plugins/amap_flutter_map-3.0.0/lib/src/core/method_channel_amap_flutter_map.dart`
- `lib/pages/track/track_controller.dart`

### Android 层
- `plugins/amap_flutter_map-3.0.0/android/src/main/java/com/amap/flutter/map/utils/Const.java`
- `plugins/amap_flutter_map-3.0.0/android/src/main/java/com/amap/flutter/map/core/MapController.java`
- `plugins/amap_flutter_map-3.0.0/android/src/main/java/com/amap/flutter/map/AMapPlatformView.java`
- `plugins/amap_flutter_map-3.0.0/android/src/main/java/com/amap/flutter/map/overlays/marker/MarkersController.java`

### iOS 层
- `plugins/amap_flutter_map-3.0.0/ios/Classes/OverlayController/AMapMarkerController.h`
- `plugins/amap_flutter_map-3.0.0/ios/Classes/OverlayController/AMapMarkerController.m`
- `plugins/amap_flutter_map-3.0.0/ios/Classes/AMapViewController.m`

## 更新日期
2025-10-21

