# 高德地图 Logo 位置设置功能

## 功能说明

为 `amap_flutter_map-3.0.0` 插件添加了设置地图 Logo 位置的功能，可以将 Logo 放置在左下角、中下方或右下角。

## 修改文件

### Dart 侧
1. **plugins/amap_flutter_map-3.0.0/lib/src/types/ui.dart**
   - 添加了 `LogoPosition` 枚举：
     - `bottomLeft`: 左下角（默认）
     - `bottomCenter`: 中下方
     - `bottomRight`: 右下角

2. **plugins/amap_flutter_map-3.0.0/lib/src/amap_widget.dart**
   - 在 `AMapWidget` 中添加了 `logoPosition` 参数
   - 在 `_AMapOptions` 中添加了相应的处理逻辑
   - 将参数序列化为 Map 传递给原生层

### Android 侧
1. **plugins/amap_flutter_map-3.0.0/android/src/main/java/com/amap/flutter/map/core/AMapOptionsSink.java**
   - 添加了 `setLogoPosition(int logoPosition)` 接口方法

2. **plugins/amap_flutter_map-3.0.0/android/src/main/java/com/amap/flutter/map/core/MapController.java**
   - 实现了 `setLogoPosition` 方法
   - 调用高德地图 SDK 的 `amap.getUiSettings().setLogoPosition(logoPosition)` 方法

3. **plugins/amap_flutter_map-3.0.0/android/src/main/java/com/amap/flutter/map/AMapOptionsBuilder.java**
   - 实现了 `setLogoPosition` 方法
   - 通过 `options.logoPosition(logoPosition)` 设置初始 logo 位置

4. **plugins/amap_flutter_map-3.0.0/android/src/main/java/com/amap/flutter/map/utils/ConvertUtil.java**
   - 在 `interpretAMapOptions` 方法中添加了 `logoPosition` 参数的解析

## 使用方法

```dart
AMapWidget(
  logoPosition: LogoPosition.bottomRight, // 设置 Logo 位置为右下角
  // ... 其他参数
)
```

## 枚举值对应关系

| Dart 枚举 | Index | Android 常量 |
|----------|-------|-------------|
| `LogoPosition.bottomLeft` | 0 | `LOGO_POSITION_BOTTOM_LEFT` |
| `LogoPosition.bottomCenter` | 1 | `LOGO_POSITION_BOTTOM_CENTER` |
| `LogoPosition.bottomRight` | 2 | `LOGO_POSITION_BOTTOM_RIGHT` |

## 应用场景

在 `lib/pages/usage_report/widgets/location_anomaly_card.dart` 中已应用此功能，将地图 Logo 设置为右下角，避免与左侧的信息展示区域冲突。

