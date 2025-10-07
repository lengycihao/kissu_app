# 🔧 GeofenceMonitoringService 修复说明

## 📋 问题总结

GeofenceMonitoringService 在初次创建时存在以下问题：

### 1. 导入错误
- ❌ 错误导入了不存在的 `LocationReportModel`
- ✅ 修复：移除该导入，因为 `SimpleLocationService.locationStream` 返回的是 `Map<String, Object>`

### 2. 位置数据类型错误
- ❌ `_onLocationUpdate` 方法期望接收 `LocationReportModel` 对象
- ✅ 修复：改为接收 `Map<String, Object>` 并手动解析经纬度

### 3. SafeAMapWidget 缺少参数
- ❌ `SafeAMapWidget` 不支持 `circles` 和 `myLocationStyleOptions` 参数
- ✅ 修复：在 `SafeAMapWidget` 中添加这两个参数的支持

### 4. MyLocationStyleOptions 参数名错误
- ❌ 使用了不存在的 `strokeColor` 参数
- ✅ 修复：改为正确的参数名 `circleStrokeColor`

---

## 🔧 详细修复

### 修复 1：移除错误导入

**文件**：`lib/services/geofence_monitoring_service.dart`

```diff
- import 'package:kissu_app/models/location_report_model.dart';
```

---

### 修复 2：修正位置更新回调

**文件**：`lib/services/geofence_monitoring_service.dart`

```dart
// ❌ 原代码
void _onLocationUpdate(LocationReportModel location) {
  final userLat = double.parse(location.latitude);
  final userLng = double.parse(location.longitude);
  // ...
}

// ✅ 修复后
void _onLocationUpdate(Map<String, Object> locationData) {
  // 从Map中提取经纬度
  final latitude = locationData['latitude'];
  final longitude = locationData['longitude'];
  
  if (latitude == null || longitude == null) {
    debugPrint('⚠️ 无效的位置数据');
    return;
  }
  
  final userLat = double.tryParse(latitude.toString());
  final userLng = double.tryParse(longitude.toString());
  
  if (userLat == null || userLng == null) {
    debugPrint('⚠️ 无法解析经纬度');
    return;
  }
  // ...
}
```

**说明**：
- `SimpleLocationService.locationStream` 发出的是原始高德定位数据 `Map<String, Object>`
- 需要手动提取 `latitude` 和 `longitude` 字段
- 添加了空值检查，确保数据有效性

---

### 修复 3：扩展 SafeAMapWidget

**文件**：`lib/widgets/safe_amap_widget.dart`

```diff
class SafeAMapWidget extends StatefulWidget {
  final CameraPosition initialCameraPosition;
  final void Function(AMapController)? onMapCreated;
  final Set<Marker>? markers;
  final Set<Polyline>? polylines;
  final Set<Polygon>? polygons;
+ final Set<Circle>? circles;
+ final MyLocationStyleOptions? myLocationStyleOptions;
  // ...其他参数
  
  const SafeAMapWidget({
    Key? key,
    required this.initialCameraPosition,
    this.onMapCreated,
    this.markers,
    this.polylines,
    this.polygons,
+   this.circles,
+   this.myLocationStyleOptions,
    // ...其他参数
  }) : super(key: key);
```

```diff
Widget _buildAMapWidget() {
  return AMapWidget(
    initialCameraPosition: widget.initialCameraPosition,
    onMapCreated: _onMapCreated,
    markers: widget.markers ?? <Marker>{},
    polylines: widget.polylines ?? <Polyline>{},
    polygons: widget.polygons ?? <Polygon>{},
+   circles: widget.circles ?? <Circle>{},
+   myLocationStyleOptions: widget.myLocationStyleOptions,
    // ...其他参数
  );
}
```

**说明**：
- 添加 `circles` 支持，用于在地图上显示圆形围栏
- 添加 `myLocationStyleOptions` 支持，用于自定义定位蓝点样式
- 保持与 `AMapWidget` 原生参数的一致性

---

### 修复 4：修正参数名

**文件**：`lib/pages/location/location_reminder/geofence_map_view_page.dart`

```diff
myLocationStyleOptions: MyLocationStyleOptions(
  true,
- strokeColor: const Color(0xFFFF88AA),
+ circleStrokeColor: const Color(0xFFFF88AA),
  circleFillColor: const Color(0x33FF88AA),
),
```

**说明**：
- `MyLocationStyleOptions` 的参数名是 `circleStrokeColor`，不是 `strokeColor`
- 参考高德地图官方文档：
  - `circleFillColor`：精度圈填充色
  - `circleStrokeColor`：精度圈边框色
  - `circleStrokeWidth`：精度圈边框宽度

---

## ✅ 验证结果

修复后，所有 linter 错误已清除：

```bash
✅ lib/services/geofence_monitoring_service.dart - 无错误
✅ lib/pages/location/location_reminder/ - 无错误
✅ lib/widgets/safe_amap_widget.dart - 无错误
✅ lib/main.dart - 无错误
```

---

## 🎯 功能测试建议

### 1. 测试围栏监测
```
1. 进入"位置提醒"页面
2. 创建一个围栏（半径200米，到达提醒）
3. 确保定位服务已启动
4. 移动到围栏外，等待定位更新
5. 移动进入围栏内
6. 验证是否收到通知
```

### 2. 测试地图显示
```
1. 在位置提醒列表，点击右上角"地图"按钮
2. 验证所有围栏是否显示为蓝色圆圈
3. 暂停一个围栏，验证是否变为灰色
4. 点击"我的位置"按钮，验证地图是否移动到当前位置
```

### 3. 测试状态管理
```
1. 创建多个围栏（激活/暂停混合）
2. 进入围栏地图视图
3. 验证只有激活的围栏才触发提醒
4. 验证围栏状态正确保存和恢复
```

---

## 📚 技术要点

### SimpleLocationService 位置流

```dart
// SimpleLocationService 提供两种访问位置的方式：

// 1. 通过 Stream（用于实时监听）
Stream<Map<String, Object>> get locationStream => 
    _locationPlugin.onLocationChanged();

// 2. 通过 currentLocation（用于获取最新位置）
final Rx<LocationReportModel?> currentLocation;
```

**GeofenceMonitoringService 的使用策略**：
- 使用 `locationStream` 进行实时监听（`Map<String, Object>`）
- 使用 `currentLocation.value` 进行状态查询（`LocationReportModel`）

---

## 🔄 相关文件

| 文件 | 修改内容 |
|------|---------|
| `lib/services/geofence_monitoring_service.dart` | 修复位置更新回调，移除错误导入 |
| `lib/widgets/safe_amap_widget.dart` | 添加 circles 和 myLocationStyleOptions 支持 |
| `lib/pages/location/location_reminder/geofence_map_view_page.dart` | 修正参数名 |
| `lib/main.dart` | 注册 GeofenceMonitoringService |
| `lib/pages/location/location_reminder/location_reminder_controller.dart` | 启动/停止围栏监测 |

---

## 📌 注意事项

1. **权限要求**：
   - 定位权限（必须）
   - 通知权限（用于发送提醒）

2. **依赖服务**：
   - 依赖 `SimpleLocationService` 提供位置数据
   - 依赖 `flutter_local_notifications` 发送通知

3. **性能优化**：
   - 只监测激活状态的围栏
   - 使用高效的 Haversine 算法计算距离
   - 状态改变时才触发通知，避免重复

4. **内存管理**：
   - 页面关闭时自动停止监测
   - 围栏状态持久化到 SharedPreferences

---

**修复完成时间**：2024-10-07  
**版本**：v1.0.0

