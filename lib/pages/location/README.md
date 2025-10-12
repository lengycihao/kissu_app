# 位置提醒模块 - 自定义导航栏功能

## 📋 功能概述

重新设计了添加位置提醒页面的顶部导航栏，支持城市选择和POI搜索功能。

### 🎯 主要功能

1. **自定义导航栏**
   - 返回按钮
   - 地址搜索框（点击跳转POI搜索页面）
   - 城市定位按钮（显示当前城市，点击切换城市）

2. **城市列表页面**
   - 定位/最近访问城市（最多3个）
   - 热门城市（北京、上海、广州等）
   - 按首字母分组的城市列表
   - 城市搜索功能

3. **POI搜索页面**
   - 关键词搜索
   - 城市筛选
   - 搜索结果列表（默认20条）
   - 支持选择POI自动定位到地图

## 📁 文件结构

```
lib/
├── models/
│   ├── city_model.dart              # 城市数据模型
│   └── poi_model.dart                # POI数据模型
├── services/
│   ├── city_storage_service.dart    # 城市本地存储服务（最近访问）
│   └── amap_poi_service.dart        # 高德地图POI搜索服务
├── pages/location/
│   ├── city_list/                   # 城市列表页面
│   │   ├── city_list_page.dart
│   │   ├── city_list_controller.dart
│   │   └── city_list_binding.dart
│   ├── poi_search/                  # POI搜索页面
│   │   ├── poi_search_page.dart
│   │   ├── poi_search_controller.dart
│   │   └── poi_search_binding.dart
│   └── location_reminder/
│       └── location_picker/
│           ├── location_picker_page.dart       # 已修改：自定义导航栏
│           └── location_picker_controller.dart # 已修改：新增方法
```

## 🔧 核心实现

### 1. 城市数据模型 (CityModel)

```dart
class CityModel {
  final String cityName;  // 城市名称（如：杭州市）
  final String adcode;    // 行政区划代码（如：330100）
}
```

### 2. POI数据模型 (PoiModel)

```dart
class PoiModel {
  final String id;
  final String name;      // POI名称
  final String address;   // 详细地址
  final String location;  // 经纬度："longitude,latitude"
  final String adcode;
  final String cityname;
  final String? distance; // 距离（米）
}
```

### 3. 城市本地存储 (CityStorageService)

使用 `SharedPreferences` 保存最近访问的城市：

```dart
// 获取最近访问的城市（最多3个）
List<CityModel> getRecentCities()

// 添加城市到最近访问列表
Future<bool> addRecentCity(CityModel city)

// 清空最近访问列表
Future<bool> clearRecentCities()
```

**存储规则：**
- 最多保存3个最近访问的城市
- 如果城市已存在，将其移到第一位
- 新城市添加到第一位
- 超过3个时删除最后一个

### 4. POI搜索服务 (AMapPoiService)

调用高德地图 Web API 进行POI搜索：

```dart
// 搜索POI
Future<List<PoiModel>> searchPoi({
  required String keyword,  // 搜索关键词
  required String city,     // 城市adcode或名称
  int page = 1,             // 页码
  int pageSize = 20,        // 每页数量
})
```

**API接口：** `https://restapi.amap.com/v3/place/text`

### 5. 自定义导航栏

在 `LocationPickerPage` 中实现自定义AppBar：

```dart
Widget _buildTopBar(BuildContext context) {
  return Container(
    child: Row(
      children: [
        // 返回按钮
        GestureDetector(onTap: () => Get.back()),
        
        // 搜索框（点击跳转POI搜索）
        GestureDetector(onTap: () => _goToPoiSearch()),
        
        // 城市选择按钮
        Obx(() => GestureDetector(onTap: () => _goToCityList())),
      ],
    ),
  );
}
```

## 🔄 页面跳转流程

### 1. 城市选择流程

```
LocationPickerPage (点击城市按钮)
    ↓
CityListPage (选择城市)
    ↓
返回选中的 CityModel
    ↓
LocationPickerController.updateCurrentCity()
```

### 2. POI搜索流程

```
LocationPickerPage (点击搜索框)
    ↓
PoiSearchPage (输入关键词搜索)
    ↓
返回选中的 PoiModel
    ↓
LocationPickerController.updateLocationFromPoi()
    ↓
更新地图标记和地址信息
```

## 🎨 UI设计说明

### 城市列表页面 (CityListPage)

1. **顶部搜索栏**
   - 返回按钮
   - 搜索输入框（实时搜索）

2. **定位/最近访问**
   - 显示当前定位城市（带定位图标）
   - 显示最近访问的城市（最多3个）
   - 使用灰色胶囊式按钮

3. **热门城市**
   - 固定7个热门城市（北京、广州、杭州、上海、深圳、天津、武汉）
   - 3列网格布局

4. **城市列表**
   - 按首字母分组（A-Z）
   - 字母索引导航（右侧）
   - 点击城市返回

### POI搜索页面 (PoiSearchPage)

1. **顶部导航栏**
   - 返回按钮
   - 搜索输入框
   - 城市选择按钮（带定位图标）

2. **搜索结果列表**
   - POI名称（加粗）
   - 详细地址
   - 距离标签（如果有）

## 🔌 API集成

### 城市列表API

**接口：** `/get/region`

**返回格式：**
```json
{
  "region": [
    {
      "first_letter": "A",
      "city_list": [
        {
          "city_name": "安庆市",
          "adcode": "340800"
        }
      ]
    }
  ],
  "hot_cities": [
    {
      "city_name": "北京市",
      "adcode": "110100"
    }
  ]
}
```

### 高德POI搜索API

**接口：** `https://restapi.amap.com/v3/place/text`

**参数：**
- `key`: API Key
- `keywords`: 搜索关键词
- `city`: 城市adcode
- `offset`: 每页数量
- `page`: 页码
- `extensions`: all（返回详细信息）

## 🚀 使用方法

### 1. 初始化服务

在 `main.dart` 中已自动初始化：

```dart
await Get.putAsync(() => CityStorageService().init(), permanent: true);
```

### 2. 使用示例

#### 跳转到城市选择页面

```dart
final result = await Get.to(() => const CityListPage());
if (result != null && result is CityModel) {
  print('选中城市: ${result.cityName}');
}
```

#### 跳转到POI搜索页面

```dart
final result = await Get.to(() => const PoiSearchPage());
if (result != null && result is PoiModel) {
  print('选中POI: ${result.name}');
  print('经纬度: ${result.longitude}, ${result.latitude}');
}
```

#### 保存最近访问的城市

```dart
final cityService = Get.find<CityStorageService>();
await cityService.addRecentCity(
  CityModel(cityName: '杭州市', adcode: '330100')
);
```

## 📝 TODO

- [ ] 实现字母索引快速滚动功能
- [ ] 添加城市列表缓存（避免频繁请求API）
- [ ] 支持城市定位自动获取（目前默认杭州）
- [ ] POI搜索支持加载更多（分页）
- [ ] 添加搜索历史记录
- [ ] 优化城市列表加载速度（虚拟列表）

## 🐛 已知问题

1. 城市列表暂时使用默认数据，需要从 `/get/region` API 加载
2. 当前定位城市默认为"杭州"，需要集成定位服务
3. 城市切换后地图不会自动移动到该城市中心（已预留TODO）

## 📱 测试建议

1. **城市选择测试**
   - 点击城市按钮 → 进入城市列表
   - 搜索城市 → 验证搜索功能
   - 选择城市 → 验证返回结果
   - 再次进入 → 验证最近访问记录

2. **POI搜索测试**
   - 点击搜索框 → 进入搜索页面
   - 选择城市 → 验证城市切换
   - 搜索关键词 → 验证搜索结果
   - 选择POI → 验证地图定位

3. **本地存储测试**
   - 选择3个不同城市
   - 重启应用
   - 验证最近访问记录是否保留

## 📄 许可

本模块使用高德地图 Web API，需要有效的API Key。

