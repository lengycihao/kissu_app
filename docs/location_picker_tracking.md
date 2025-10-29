# 添加地点页面埋点集成文档

## 📋 概述
本文档记录了**添加地点页面**（`LocationPickerPage`）的友盟埋点集成实现，包括页面浏览和保存操作两个埋点事件。

---

## 🎯 埋点事件列表

### 1. 页面浏览埋点
**事件名称**: `location_knock_address_add`  
**事件类型**: 浏览事件  
**触发时机**: 用户离开添加地点页面时

#### 参数说明
| 参数名 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `device_id` | String | 虚拟用户ID（通过设备号生成） | "abc123..." |
| `user_id` | String | 用户ID | "12345" |
| `stay_duration` | String | 页面停留时长 | "45s" |

#### 实现位置
- **Controller**: `LocationPickerController.onClose()`
- **方法**: `_trackPageView()`
- **上报时机**: 页面关闭时（onClose 生命周期）

#### 代码实现
```dart
@override
void onClose() {
  // 上报页面浏览埋点
  _trackPageView();
  noteController.dispose();
  super.onClose();
}

/// 上报页面浏览埋点
Future<void> _trackPageView() async {
  if (_pageEnterTime == null) return;
  
  try {
    // 计算停留时长
    final duration = DateTime.now().difference(_pageEnterTime!);
    final seconds = duration.inSeconds;
    final stayDuration = '${seconds}s';
    
    // 上报埋点
    await TrackingService.trackLocationKnockAddressAddPageView(
      stayDuration: stayDuration,
    );
    
    DebugUtil.info('✅ 添加地点页面浏览埋点上报成功: 停留时长=$stayDuration');
  } catch (e) {
    DebugUtil.error('❌ 添加地点页面浏览埋点上报失败: $e');
  }
}
```

---

### 2. 保存操作埋点
**事件名称**: `location_knock_address_save`  
**事件类型**: 点击事件  
**触发时机**: 用户点击保存按钮时

#### 参数说明
| 参数名 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `device_id` | String | 虚拟用户ID（通过设备号生成） | "abc123..." |
| `user_id` | String | 用户ID | "12345" |
| `click_time` | String | 点击时间 | "2025-01-15 14:30:25" |

#### 实现位置
- **Page**: `LocationPickerPage` 保存按钮点击回调
- **上报时机**: 点击保存按钮时（在实际保存操作之前）

#### 代码实现
```dart
return GestureDetector(
  onTap: () async {
    if (!canSave) {
      // ... 提示逻辑
    }
    
    // 上报保存操作埋点
    try {
      await TrackingService.trackLocationKnockAddressSave();
      DebugUtil.info('✅ 添加地点页面-保存操作埋点上报成功');
    } catch (e) {
      DebugUtil.error('❌ 添加地点页面-保存操作埋点上报失败: $e');
    }
    
    final reminder = await controller.saveLocation();
    if (reminder != null) {
      Get.back(result: reminder);
    }
  },
  child: Container(/* 保存按钮UI */),
);
```

---

## 🔧 TrackingService 方法

### 方法列表

#### 1. trackLocationKnockAddressAddPageView
```dart
/// 位置提醒-添加地点页面-浏览埋点
/// 
/// @param stayDuration 停留时长（如：45s）
static Future<void> trackLocationKnockAddressAddPageView({
  required String stayDuration,
}) async {
  await _trackEvent(
    eventName: 'location_knock_address_add',
    properties: {
      'stay_duration': stayDuration,
    },
  );
}
```

#### 2. trackLocationKnockAddressSave
```dart
/// 位置提醒-添加地点页面-保存操作埋点
static Future<void> trackLocationKnockAddressSave() async {
  await _trackEvent(eventName: 'location_knock_address_save');
}
```

---

## 📝 实现要点

### 1. 页面停留时长计算
- 在 `onInit()` 中记录进入时间：`_pageEnterTime = DateTime.now()`
- 在 `onClose()` 中计算时长：`DateTime.now().difference(_pageEnterTime!)`
- 格式化为秒数：`'${seconds}s'`

### 2. 埋点上报时机
- **页面浏览埋点**: 在 `onClose()` 生命周期方法中上报
- **保存操作埋点**: 在保存按钮点击时立即上报（在实际保存前）

### 3. 异常处理
- 所有埋点方法都使用 try-catch 包裹
- 失败时打印错误日志，但不影响正常业务流程
- 使用 `DebugUtil` 记录成功和失败日志

---

## 🧪 测试验证

### 测试场景

#### 场景1：页面浏览埋点
1. 打开位置提醒列表页面
2. 点击"添加地点"按钮
3. 在添加地点页面停留一段时间（如30秒）
4. 返回上一页
5. **预期**: 控制台输出 `✅ 添加地点页面浏览埋点上报成功: 停留时长=30s`

#### 场景2：保存操作埋点
1. 打开添加地点页面
2. 选择一个位置
3. 输入备注
4. 点击"保存"按钮
5. **预期**: 控制台输出 `✅ 添加地点页面-保存操作埋点上报成功`

### 验证清单
- [ ] 页面浏览埋点在页面关闭时上报
- [ ] 停留时长计算正确
- [ ] 保存操作埋点在点击保存时上报
- [ ] 所有埋点包含 device_id 和 user_id
- [ ] 点击时间格式正确（yyyy-MM-dd HH:mm:ss）
- [ ] 埋点失败不影响业务功能

---

## 📊 数据示例

### 页面浏览埋点数据
```json
{
  "event_name": "location_knock_address_add",
  "properties": {
    "device_id": "abc123...",
    "user_id": "12345",
    "stay_duration": "45s"
  }
}
```

### 保存操作埋点数据
```json
{
  "event_name": "location_knock_address_save",
  "properties": {
    "device_id": "abc123...",
    "user_id": "12345",
    "click_time": "2025-01-15 14:30:25"
  }
}
```

---

## 🔗 相关文档
- [位置提醒列表页面埋点集成](./location_reminder_tracking.md)
- [友盟埋点服务文档](./umeng_event_timing_feature.md)
- [Mine 页面埋点集成](./mine_page_umeng_tracking.md)

---

## ✅ 集成完成
- ✅ TrackingService 方法已添加
- ✅ LocationPickerController 页面浏览埋点已实现
- ✅ LocationPickerPage 保存操作埋点已实现
- ✅ 调试日志已完善
- ✅ 文档已创建

**最后更新**: 2025-01-15

