# SafeAMapWidget 使用指南

## 概述

`SafeAMapWidget` 是一个经过优化的高德地图组件包装器，专门解决Flutter中嵌入原生地图时的常见问题。

## 解决的问题

### 1. 花屏问题 ✅
- **原因**：Flutter渲染引擎（Skia/Impeller）与原生Platform View渲染不一致
- **解决方案**：
  - 延迟渲染机制：等待Flutter渲染树稳定后再创建Platform View
  - RepaintBoundary隔离：将地图渲染层与其他Widget隔离
  - 帧率限制：限制地图渲染为30fps，降低渲染压力

### 2. mapId不匹配错误 ✅
- **原因**：地图初始化时序问题
- **解决方案**：使用Completer确保地图完全初始化后再进行操作

### 3. 白屏问题 ✅
- **原因**：隐私声明未正确配置
- **解决方案**：自动配置正确的隐私声明参数

## 核心优化点

### 1. 延迟渲染机制
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  Future.delayed(const Duration(milliseconds: 50), () {
    setState(() {
      _shouldRender = true; // 启用地图渲染
    });
  });
});
```
- 在Flutter渲染树完全构建后才创建Platform View
- 避免初始化时的渲染冲突

### 2. RepaintBoundary隔离
```dart
RepaintBoundary(
  child: _buildAMapWidget(),
)
```
- 创建独立的渲染层
- 减少与其他Widget的渲染干扰
- 提高整体渲染性能

### 3. 渲染帧率限制
```dart
await controller.setRenderFps(30);
```
- 限制地图渲染为30fps
- 降低GPU压力
- 减少花屏概率

### 4. 渐进式加载
- 第一阶段：显示"准备地图..."占位符（50ms）
- 第二阶段：创建地图并显示"地图加载中..."（200ms）
- 第三阶段：地图完全就绪，移除遮罩

## 使用方法

### 基础用法

```dart
import 'package:kissu/widgets/safe_amap_widget.dart';

SafeAMapWidget(
  initialCameraPosition: CameraPosition(
    target: LatLng(39.909187, 116.397451),
    zoom: 15,
  ),
  onMapCreated: (controller) {
    // 地图创建完成回调
    print('地图已就绪');
  },
)
```

### 完整示例

```dart
class MapPage extends StatefulWidget {
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with WidgetsBindingObserver {
  AMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    // 监听应用生命周期
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 可以根据生命周期优化地图行为
    if (state == AppLifecycleState.paused) {
      // 应用进入后台，可以暂停地图更新
    } else if (state == AppLifecycleState.resumed) {
      // 应用恢复前台
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeAMapWidget(
        initialCameraPosition: CameraPosition(
          target: LatLng(39.909187, 116.397451),
          zoom: 15,
        ),
        markers: _markers,
        onMapCreated: (controller) {
          setState(() {
            _mapController = controller;
          });
          print('地图初始化完成');
        },
        onTap: (latLng) {
          print('点击位置: ${latLng.latitude}, ${latLng.longitude}');
        },
        myLocationStyleOptions: MyLocationStyleOptions(
          myLocationType: MyLocationType.follow,
          showMyLocation: true,
        ),
      ),
    );
  }
}
```

### 高级配置

```dart
SafeAMapWidget(
  initialCameraPosition: CameraPosition(
    target: LatLng(39.909187, 116.397451),
    zoom: 15,
  ),
  // 地图类型
  mapType: MapType.normal,
  
  // 手势控制
  zoomGesturesEnabled: true,
  scrollGesturesEnabled: true,
  rotateGesturesEnabled: true,
  tiltGesturesEnabled: true,
  
  // UI控件
  compassEnabled: false,
  scaleEnabled: false,
  
  // 覆盖物
  markers: markers,
  polylines: polylines,
  polygons: polygons,
  circles: circles,
  
  // 定位配置
  myLocationStyleOptions: MyLocationStyleOptions(
    myLocationType: MyLocationType.follow,
    showMyLocation: true,
  ),
  
  // 事件回调
  onMapCreated: _onMapCreated,
  onTap: _onMapTap,
  onLongPress: _onMapLongPress,
  onLocationChanged: _onLocationChanged,
  onCameraMove: _onCameraMove,
  onCameraMoveEnd: _onCameraMoveEnd,
  onPoiTouched: _onPoiTouched,
)
```

## 性能优化建议

### 1. 页面切换时的处理

```dart
// 使用KeepAliveClientMixin保持地图状态（如果需要）
class _MapPageState extends State<MapPage> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用
    return SafeAMapWidget(...);
  }
}
```

### 2. 控制Marker数量

```dart
// 避免一次性添加大量Marker
void _addMarkersGradually(List<LatLng> positions) async {
  Set<Marker> markers = {};
  
  for (int i = 0; i < positions.length; i++) {
    markers.add(Marker(
      markerId: MarkerId('marker_$i'),
      position: positions[i],
    ));
    
    // 每10个Marker刷新一次
    if (i % 10 == 0) {
      setState(() {
        _markers = Set.from(markers);
      });
      await Future.delayed(Duration(milliseconds: 16));
    }
  }
  
  setState(() {
    _markers = markers;
  });
}
```

### 3. 内存管理

```dart
@override
void dispose() {
  // 清理资源
  _markers.clear();
  _polylines.clear();
  _mapController = null;
  super.dispose();
}
```

## 常见问题

### Q1: 为什么地图加载时有短暂的空白？
**A**: 这是延迟渲染机制的正常现象（约50ms），用于避免花屏。你可以通过调整 `initState` 中的延迟时间来优化体验：

```dart
// 在 SafeAMapWidget 的 _SafeAMapWidgetState 中
Future.delayed(const Duration(milliseconds: 30), () { // 减少到30ms
  if (mounted) {
    setState(() {
      _shouldRender = true;
    });
  }
});
```

### Q2: 地图操作有延迟怎么办？
**A**: 如果30fps的帧率限制导致操作不流畅，可以临时调整：

```dart
void _onMapCreated(AMapController controller) async {
  // 地图操作时提高帧率
  await controller.setRenderFps(60);
  
  // 操作完成后降低帧率
  Future.delayed(Duration(seconds: 2), () {
    controller.setRenderFps(30);
  });
}
```

### Q3: 如何在不同页面复用地图？
**A**: 建议每个页面独立创建地图实例，而不是尝试复用，这样可以避免生命周期问题。

## 测试建议

1. **设备测试**：在不同Android版本和品牌设备上测试
2. **场景测试**：
   - 快速切换页面
   - 长时间使用
   - 大量Marker加载
   - 内存压力测试
3. **性能监控**：使用Flutter DevTools观察渲染性能

## 更新日志

### v1.1 (当前版本)
- ✅ 添加延迟渲染机制，解决花屏问题
- ✅ 使用RepaintBoundary隔离渲染层
- ✅ 添加帧率限制（30fps）
- ✅ 优化初始化流程
- ✅ 改进错误处理

### v1.0
- 基础地图封装
- mapId错误处理
- 隐私声明配置

## 相关文档

- [地图花屏问题解决方案](./amap_screen_flicker_fix.md)
- [高德地图官方文档](https://lbs.amap.com/api/flutter/summary)

