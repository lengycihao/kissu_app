# Circle（圆形）覆盖物使用说明

## 功能说明

在高德地图插件中新增了 `Circle`（圆形）覆盖物支持，可用于绘制电子围栏、范围标识等场景。

## 基本使用

### 1. 导入依赖

```dart
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
```

### 2. 创建圆形覆盖物

```dart
Set<Circle> _circles = {
  Circle(
    center: LatLng(39.909187, 116.397451),  // 圆心坐标
    radius: 1000,                            // 半径（米）
    strokeWidth: 2,                          // 边框宽度
    strokeColor: Colors.blue,                // 边框颜色
    fillColor: Colors.blue.withOpacity(0.3), // 填充颜色
    visible: true,                           // 是否可见
  ),
};
```

### 3. 在地图上显示

```dart
AMapWidget(
  initialCameraPosition: CameraPosition(
    target: LatLng(39.909187, 116.397451),
    zoom: 12,
  ),
  circles: _circles,  // 添加圆形覆盖物
  onMapCreated: (controller) {
    // 地图创建完成
  },
)
```

## 完整示例

```dart
import 'package:flutter/material.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';

class CircleMapExample extends StatefulWidget {
  @override
  _CircleMapExampleState createState() => _CircleMapExampleState();
}

class _CircleMapExampleState extends State<CircleMapExample> {
  Set<Circle> _circles = {};

  @override
  void initState() {
    super.initState();
    _circles = {
      // 电子围栏示例
      Circle(
        center: LatLng(39.909187, 116.397451),
        radius: 1000,  // 1公里
        strokeWidth: 2,
        strokeColor: Color(0xCC00BFFF),
        fillColor: Color(0x4D00BFFF),
        visible: true,
      ),
      // 多个圆形
      Circle(
        center: LatLng(39.899, 116.407),
        radius: 500,  // 500米
        strokeWidth: 3,
        strokeColor: Colors.red,
        fillColor: Colors.red.withOpacity(0.2),
        visible: true,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('圆形覆盖物示例')),
      body: AMapWidget(
        initialCameraPosition: CameraPosition(
          target: LatLng(39.909187, 116.397451),
          zoom: 12,
        ),
        circles: _circles,
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          // 动态添加圆形
          setState(() {
            _circles = {
              ..._circles,
              Circle(
                center: LatLng(39.919, 116.387),
                radius: 800,
                strokeWidth: 2,
                strokeColor: Colors.green,
                fillColor: Colors.green.withOpacity(0.3),
                visible: true,
              ),
            };
          });
        },
      ),
    );
  }
}
```

## Circle 属性说明

| 属性 | 类型 | 必填 | 说明 | 默认值 |
|------|------|------|------|--------|
| center | LatLng | 是 | 圆形的中心点坐标 | - |
| radius | double | 是 | 圆形的半径，单位：米 | - |
| strokeWidth | double | 否 | 边框宽度（逻辑像素） | 10 |
| strokeColor | Color | 否 | 边框颜色 | Color(0xCC00BFFF) |
| fillColor | Color | 否 | 填充颜色 | Color(0x4D00BFFF) |
| visible | bool | 否 | 是否可见 | true |

## 动态更新圆形

```dart
// 更新圆形（通过 copyWith）
setState(() {
  _circles = _circles.map((circle) {
    return circle.copyWith(
      radiusParam: 2000,  // 修改半径
      fillColorParam: Colors.red.withOpacity(0.3),  // 修改颜色
    );
  }).toSet();
});

// 删除所有圆形
setState(() {
  _circles = {};
});

// 删除特定圆形
setState(() {
  _circles = _circles.where((circle) => circle.radius > 500).toSet();
});
```

## 电子围栏应用场景

```dart
// 电子围栏示例：以某个位置为中心，绘制安全区域
Circle createGeofence(LatLng center, double radiusInMeters) {
  return Circle(
    center: center,
    radius: radiusInMeters,
    strokeWidth: 3,
    strokeColor: Color(0xFF4CAF50),  // 绿色边框
    fillColor: Color(0x334CAF50),    // 半透明绿色填充
    visible: true,
  );
}

// 使用
setState(() {
  _circles = {
    createGeofence(LatLng(39.909187, 116.397451), 1000),
  };
});
```

## 注意事项

1. **性能优化**：避免在地图上绘制过多的圆形覆盖物，建议不超过 50 个
2. **半径单位**：radius 的单位是米，不是像素
3. **颜色透明度**：建议 fillColor 使用半透明颜色，以便看到下层地图
4. **唯一标识**：每个 Circle 内部会自动生成唯一 ID，无需手动指定

## 平台支持

- ✅ Android：完全支持
- ❌ iOS：暂不支持（如需 iOS 支持，可联系开发者）

## 更新日志

- 2024-10-07：新增 Circle 覆盖物支持，包含 Dart 层和 Android 原生层实现

