# Ta的手机使用记录 - 接口对接说明

## 接口信息

### API端点
`/v4/get/today/screen/unlock/stat`

### 请求参数
- `date`: 日期，格式：`2025-11-28`（可选，不传默认返回当天）

### 返回数据结构
```json
{
  "screen_use_data": {
    "hours": 6,
    "minutes": 48,
    "trend": 2,
    "trend_text": "比昨天多6小时48分钟",
    "hourly_usage_stat": [
      {
        "hour": 0,
        "duration": 0,
        "minutes": 0,
        "hour_label": [0, 1]
      }
    ]
  },
  "unlock_phone_data": {
    "unlock_number": 3,
    "trend": 2,
    "trend_text": "比昨天多3次",
    "unlock_phone_stat": [
      {
        "hour": 0,
        "unlock_number": 0,
        "hour_label": [0, 1]
      }
    ]
  }
}
```

## 数据字段说明

### screen_use_data（屏幕使用时间模块）
- `hours`: 总小时数
- `minutes`: 总分钟数
- `trend`: 趋势（0=持平，1=下降，2=上升）
- `trend_text`: 趋势文本描述
- `hourly_usage_stat`: 每小时统计数据
  - `hour`: 小时（0-23）
  - `minutes`: 该小时使用分钟数（**柱状图Y轴使用此字段**）
  - `duration`: 持续时间
  - `hour_label`: 时间段标签

### unlock_phone_data（手机解锁次数模块）
- `unlock_number`: 总解锁次数
- `trend`: 趋势（0=持平，1=下降，2=上升）
- `trend_text`: 趋势文本描述
- `unlock_phone_stat`: 每小时统计数据
  - `hour`: 小时（0-23）（**柱状图X轴使用此字段**）
  - `unlock_number`: 该小时解锁次数（**柱状图Y轴使用此字段**）
  - `hour_label`: 时间段标签

## 趋势显示逻辑

### trend字段含义
- `0`: 持平 - **不显示趋势文本和图标**
- `1`: 下降 - 显示下降图标 `kissu4_use_down.webp`
- `2`: 上升 - 显示上升图标 `kissu4_use_up.webp`

### 显示规则
```dart
if (trend == 0 || trendText.isEmpty) {
  // 不显示任何趋势信息
  return const SizedBox.shrink();
}

// trend == 1 显示下降图标
// trend == 2 显示上升图标
String iconPath = trend == 1 
    ? "assets/4.0/kissu4_use_down.webp"
    : "assets/4.0/kissu4_use_up.webp";
```

## 实现文件

### 1. 数据模型
**文件**: `lib/pages/mine/device_usage/models/screen_unlock_stat_model.dart`

包含以下模型类：
- `ScreenUnlockStatModel`: 顶层数据模型
- `ScreenUseData`: 屏幕使用数据
- `HourlyUsageStat`: 每小时使用统计
- `UnlockPhoneData`: 解锁数据
- `UnlockPhoneStat`: 每小时解锁统计

### 2. API服务
**文件**: `lib/network/public/usage_record_api.dart`

新增方法：
```dart
Future<HttpResultN<ScreenUnlockStatModel>> getScreenUnlockStat({
  String? date,
})
```

**文件**: `lib/network/public/api_request.dart`

新增端点：
```dart
static const getScreenUnlockStat = '/v4/get/today/screen/unlock/stat';
```

### 3. 控制器
**文件**: `lib/pages/mine/device_usage/app_usage_detail_controller.dart`

#### 新增字段
```dart
// API实例
final _usageRecordApi = UsageRecordApi();

// 选中日期
var selectedDate = DateTime.now().obs;

// 趋势数据
var screenTrend = 0.obs;
var screenTrendText = ''.obs;
var unlockTrend = 0.obs;
var unlockTrendText = ''.obs;

// 加载状态
var isLoading = false.obs;
```

#### 核心方法
```dart
/// 加载数据
Future<void> loadData() async {
  // 1. 格式化日期
  final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);
  
  // 2. 调用API
  final result = await _usageRecordApi.getScreenUnlockStat(date: dateStr);
  
  // 3. 处理屏幕使用数据
  if (data.screenUseData != null) {
    // 初始化24小时数据
    final screenUsageList = List<int>.filled(24, 0);
    
    // 填充每小时数据（使用minutes字段）
    for (var stat in screenData.hourlyUsageStat) {
      if (stat.hour >= 0 && stat.hour < 24) {
        screenUsageList[stat.hour] = stat.minutes;
      }
    }
    
    todayScreenUsage.value = screenUsageList;
    screenTrend.value = screenData.trend;
    screenTrendText.value = screenData.trendText;
  }
  
  // 4. 处理解锁数据
  if (data.unlockPhoneData != null) {
    // 初始化24小时数据
    final unlockCountList = List<int>.filled(24, 0);
    
    // 填充每小时数据（使用unlockNumber字段）
    for (var stat in unlockData.unlockPhoneStat) {
      if (stat.hour >= 0 && stat.hour < 24) {
        unlockCountList[stat.hour] = stat.unlockNumber;
      }
    }
    
    todayUnlockCount.value = unlockCountList;
    unlockTrend.value = unlockData.trend;
    unlockTrendText.value = unlockData.trendText;
  }
}

/// 切换日期
void changeDate(DateTime date) {
  selectedDate.value = date;
  loadData(); // 重新加载数据
}
```

### 4. 页面UI
**文件**: `lib/pages/mine/device_usage/app_usage_detail_page.dart`

#### 动态日期显示
```dart
Obx(() {
  final selectedDate = controller.selectedDate.value;
  final now = DateTime.now();
  final isToday = selectedDate.year == now.year &&
      selectedDate.month == now.month &&
      selectedDate.day == now.day;
  
  final dateStr = DateFormat('M月d日').format(selectedDate);
  final displayText = isToday ? '$dateStr（今天）' : dateStr;
  
  return Text(
    displayText,
    style: const TextStyle(fontSize: 11, color: Color(0xFF333333)),
  );
})
```

**显示规则**：
- 如果是今天：显示 "11月29日（今天）"
- 如果不是今天：显示 "11月28日"

#### 屏幕使用时间趋势显示
```dart
Obx(() {
  final trend = controller.screenTrend.value;
  final trendText = controller.screenTrendText.value;
  
  // trend为0时不显示
  if (trend == 0 || trendText.isEmpty) {
    return const SizedBox.shrink();
  }
  
  // 根据trend显示不同的图标
  String iconPath = trend == 1 
      ? "assets/4.0/kissu4_use_down.webp"  // 下降
      : "assets/4.0/kissu4_use_up.webp";   // 上升
  
  return Row(
    children: [
      Image.asset(iconPath, width: 12, height: 12),
      const SizedBox(width: 4),
      Text(trendText, style: TextStyle(...)),
    ],
  );
})
```

#### 解锁次数趋势显示
```dart
Obx(() {
  final trend = controller.unlockTrend.value;
  final trendText = controller.unlockTrendText.value;
  
  // trend为0时不显示
  if (trend == 0 || trendText.isEmpty) {
    return const SizedBox.shrink();
  }
  
  // 根据trend显示不同的图标
  String iconPath = trend == 1 
      ? "assets/4.0/kissu4_use_down.webp"  // 下降
      : "assets/4.0/kissu4_use_up.webp";   // 上升
  
  return Row(
    children: [
      Image.asset(iconPath, width: 12, height: 12),
      const SizedBox(width: 4),
      Text(trendText, style: TextStyle(...)),
    ],
  );
})
```

## 柱状图数据映射

### 屏幕使用时间图表
- **X轴**: `hour` 字段（0-23点）
- **Y轴**: `minutes` 字段（使用分钟数）
- **单位**: 分钟

### 解锁次数图表
- **X轴**: `hour` 字段（0-23点）
- **Y轴**: `unlockNumber` 字段（解锁次数）
- **单位**: 次

## 数据流程

```
1. 用户选择日期
   ↓
2. DateSelector 触发 onSelect 回调
   ↓
3. controller.changeDate(date) 被调用
   ↓
4. selectedDate 更新
   ↓
5. loadData() 被调用
   ↓
6. 格式化日期为 yyyy-MM-dd
   ↓
7. 调用 API: getScreenUnlockStat(date: dateStr)
   ↓
8. 解析返回数据
   ↓
9. 填充 24 小时数据数组
   - 屏幕使用: todayScreenUsage
   - 解锁次数: todayUnlockCount
   ↓
10. 更新趋势数据
   - screenTrend, screenTrendText
   - unlockTrend, unlockTrendText
   ↓
11. UI 自动响应更新（Obx）
```

## 初始化流程

```dart
@override
void onInit() {
  super.onInit();
  // 加载今天的数据
  loadData();
}
```

页面初始化时自动加载今天的数据，不需要传递 date 参数。

## 错误处理

### API调用失败
```dart
if (!result.isSuccess || result.data == null) {
  // 使用空数据
  todayScreenUsage.value = List.filled(24, 0);
  todayUnlockCount.value = List.filled(24, 0);
  screenTrend.value = 0;
  screenTrendText.value = '';
  unlockTrend.value = 0;
  unlockTrendText.value = '';
}
```

### 异常捕获
```dart
try {
  // API调用
} catch (e) {
  DebugUtil.error('💥 数据加载异常: $e');
  // 使用空数据
} finally {
  isLoading.value = false;
}
```

## 测试要点

### 1. 日期切换测试
- 切换不同日期，验证数据是否正确加载
- 验证日期格式是否正确（yyyy-MM-dd）

### 2. 趋势显示测试
- **trend = 0**: 不显示任何趋势信息
- **trend = 1**: 显示下降图标和文本
- **trend = 2**: 显示上升图标和文本

### 3. 数据映射测试
- 验证屏幕使用时间使用 `minutes` 字段
- 验证解锁次数使用 `unlockNumber` 字段
- 验证X轴使用 `hour` 字段（0-23）

### 4. 空数据测试
- API返回空数据时，图表显示为空
- 不会崩溃或报错

### 5. 加载状态测试
- `isLoading` 在加载时为 true
- 加载完成后为 false

## 注意事项

1. **日期格式**: 必须使用 `yyyy-MM-dd` 格式
2. **趋势显示**: trend为0时必须隐藏，不能显示空白占位
3. **数据字段**: 
   - 屏幕使用时间使用 `minutes` 字段
   - 解锁次数使用 `unlockNumber` 字段
4. **24小时数据**: 初始化为24个元素的数组，索引对应小时
5. **图表显示**: 只显示0-18点的数据（前19个小时）

## 相关资源

- API文档: `api.md`
- 数据模型: `screen_unlock_stat_model.dart`
- API服务: `usage_record_api.dart`
- 控制器: `app_usage_detail_controller.dart`
- 页面: `app_usage_detail_page.dart`

## 完成日期
2025-11-29
