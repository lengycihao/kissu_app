# 位置提醒API集成说明

## 概述
已完成位置提醒功能与服务端API的集成，实现了从服务端获取和保存地理围栏数据。

## 修改文件清单

### 1. 新增文件
- `lib/network/public/geofence_api.dart` - 地理围栏API服务类

### 2. 修改文件
- `lib/network/public/api_request.dart` - 添加API路径定义
- `lib/pages/location/location_reminder/location_reminder_controller.dart` - 集成API调用
- `lib/pages/location/location_reminder/location_picker/location_picker_controller.dart` - 更新icon类型为int
- `lib/pages/location/location_reminder/location_picker/location_picker_page.dart` - 更新UI使用icon ID
- `lib/pages/location/location_reminder/location_reminder_page.dart` - 更新icon显示逻辑

## API接口说明

### 1. 获取地理围栏列表
**接口:** `/get/geofencing`
**方法:** GET
**返回格式:**
```json
[
  {
    "_id": "68e581b5cc3d8712ef0bd384",
    "geo_icon": 1,
    "geo_action": 1,
    "longitude": "120.220537109375",
    "latitude": "30.27528781467014",
    "geo_radius": "100",
    "remark": "备注",
    "location": "浙江省杭州市上城区四季青街道JWK(中豪湘悦商务中心)中豪湘悦中心"
  }
]
```

### 2. 保存地理围栏
**接口:** `/save/geofencing`
**方法:** POST
**参数:**
- `geo_icon`: 图标类型 (1-5)
  - 1: 公司
  - 2: 家
  - 3: 娱乐
  - 4: 健身房
  - 5: 商场
- `geo_action`: 提醒类型
  - 1: 离开位置提醒
  - 2: 到达位置提醒
- `longitude`: 经度（字符串）
- `latitude`: 纬度（字符串）
- `geo_radius`: 围栏半径（字符串，固定"100"）
- `remark`: 备注（可选）

## 数据模型映射

### 服务端 -> 客户端
```
_id          -> id
geo_icon     -> icon (1-5)
geo_action   -> type (1=离开, 2=到达)
longitude    -> longitude
latitude     -> latitude
geo_radius   -> radius
remark       -> note
location     -> address
```

### Icon类型映射
```
1 -> 公司 (company)
2 -> 家 (home)
3 -> 娱乐 (restaurant)
4 -> 健身房 (gym)
5 -> 商场 (shop)
```

## 主要功能

### 1. 初始化加载
- 页面初始化时自动从服务端加载位置提醒列表
- 如果服务端加载失败，自动降级到本地缓存
- 加载成功后同步到本地存储

### 2. 添加位置提醒
- 用户选择位置并填写信息后，调用服务端API保存
- 保存成功后重新从服务端加载列表，确保数据同步
- 保存失败显示错误提示

### 3. 数据持久化
- 主数据源：服务端
- 本地缓存：SharedPreferences（用于离线访问和快速加载）
- 双重保障：服务端 + 本地缓存

## 使用示例

### 1. 获取围栏列表
```dart
final geofenceApi = GeofenceApi();
final result = await geofenceApi.getGeofencingList();

if (result.isSuccess && result.data != null) {
  final reminders = result.data!
      .map((json) => LocationReminder.fromServerJson(json))
      .toList();
  // 处理围栏列表
}
```

### 2. 保存围栏
```dart
final geofenceApi = GeofenceApi();
final result = await geofenceApi.saveGeofencing(
  geoIcon: 2,              // 家
  geoAction: 2,            // 到达提醒
  longitude: 120.220537,
  latitude: 30.275288,
  geoRadius: 100,
  remark: '我的家',
);

if (result.isSuccess) {
  // 保存成功
}
```

## 测试要点

### 1. 正常流程测试
- [ ] 打开位置提醒页面，验证能否正确加载服务端数据
- [ ] 添加新的位置提醒，验证保存成功并显示在列表中
- [ ] 验证5种不同icon类型的显示
- [ ] 验证"到达"和"离开"两种提醒类型

### 2. 异常情况测试
- [ ] 网络断开时能否使用本地缓存数据
- [ ] 保存失败时的错误提示
- [ ] 服务端返回异常数据的处理
- [ ] 空列表的显示

### 3. 数据一致性测试
- [ ] 添加位置后，列表立即更新
- [ ] 多次进入页面，数据保持一致
- [ ] 本地缓存与服务端数据同步

## 注意事项

1. **围栏半径固定为100米**，与产品需求一致
2. **icon类型已从String改为int**，需要确保所有相关代码都已更新
3. **服务端返回的经纬度是字符串**，需要转换为double
4. **本地缓存作为备用**，服务端数据为主数据源
5. **保存成功后自动刷新列表**，确保显示最新数据

## 后续优化建议

1. 添加下拉刷新功能
2. 添加删除围栏的API接口和功能
3. 添加编辑围栏的功能
4. 优化加载状态显示（骨架屏）
5. 添加数据同步冲突处理机制

