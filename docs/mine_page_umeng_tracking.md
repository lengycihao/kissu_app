# "我的"页面友盟停留时长统计

## 📋 需求说明

在"我的"页面（MinePage）统计用户停留时长，上报友盟事件。

### 事件信息
- **事件ID**: `personal_info_page`
- **参数**:
  - `device_id`: 虚拟用户ID（设备ID）
  - `user_id`: 用户ID
  - `stay_duration`: 页面停留时长（秒）- **由友盟SDK自动计算**

## ✅ 已完成集成

### 1. 代码位置
`lib/pages/mine/mine_controller.dart`

### 2. 实现方式

#### 2.1 导入依赖
```dart
import 'package:kissu_app/utils/umeng_analytics_util.dart';
```

#### 2.2 页面初始化时开始计时
```dart
@override
void onInit() {
  super.onInit();
  _initSettingItems();
  loadUserInfo();
  
  // 开始统计页面停留时长
  _startPageStayTracking();
}

/// 开始统计"我的"页面停留时长
Future<void> _startPageStayTracking() async {
  try {
    // 获取虚拟用户ID（设备ID）
    final deviceId = await UmengAnalytics.getOrCreateVirtualUserId();
    
    // 获取用户ID
    final userId = UserManager.userId ?? 'unknown';
    
    // 开始计时
    await UmengAnalytics.eventBegin('personal_info_page', params: {
      'device_id': deviceId,
      'user_id': userId,
    });
    
    print('📊 开始统计"我的"页面停留时长 - device_id: $deviceId, user_id: $userId');
  } catch (e) {
    print('❌ 开始页面停留统计失败: $e');
  }
}
```

#### 2.3 页面销毁时结束计时
```dart
@override
void onClose() {
  // ⚠️ 重要：页面销毁时结束计时，友盟会自动计算停留时长
  _endPageStayTracking();
  super.onClose();
}

/// 结束"我的"页面停留时长统计
Future<void> _endPageStayTracking() async {
  try {
    // 获取虚拟用户ID（设备ID）
    final deviceId = await UmengAnalytics.getOrCreateVirtualUserId();
    
    // 获取用户ID
    final userId = UserManager.userId ?? 'unknown';
    
    // 结束计时（友盟会自动计算 stay_duration）
    await UmengAnalytics.eventEnd('personal_info_page', params: {
      'device_id': deviceId,
      'user_id': userId,
    });
    
    print('📊 结束"我的"页面停留统计 - device_id: $deviceId, user_id: $userId');
  } catch (e) {
    print('❌ 结束页面停留统计失败: $e');
  }
}
```

## 🔍 工作原理

### 1. 自动计算停留时长
- 调用 `eventBegin()` 时，友盟SDK记录开始时间
- 调用 `eventEnd()` 时，友盟SDK自动计算时长（秒）
- **不需要手动传递 `stay_duration` 参数**

### 2. 数据流程
```
用户打开页面
    ↓
onInit() 触发
    ↓
_startPageStayTracking() 执行
    ↓
获取 device_id 和 user_id
    ↓
调用 UmengAnalytics.eventBegin()
    ↓
【用户浏览页面...】
    ↓
用户关闭页面
    ↓
onClose() 触发
    ↓
_endPageStayTracking() 执行
    ↓
调用 UmengAnalytics.eventEnd()
    ↓
友盟自动计算停留时长并上报
```

### 3. 参数说明

#### device_id（虚拟用户ID）
- **来源**: `UmengAnalytics.getOrCreateVirtualUserId()`
- **特点**: 
  - 首次生成后永久保存在本地
  - 用于标识唯一设备
  - 即使用户未登录也能统计

#### user_id（用户ID）
- **来源**: `UserManager.userId`
- **特点**:
  - 用户登录后才有值
  - 未登录时为 `'unknown'`
  - 可用于关联用户行为

#### stay_duration（停留时长）
- **来源**: 友盟SDK自动计算
- **单位**: 秒
- **计算方式**: `eventEnd时间 - eventBegin时间`

## 📊 友盟后台查看

### 1. 登录友盟后台
访问：https://mobile.umeng.com/

### 2. 查看事件统计
路径：**统计分析 → 事件分析 → 选择事件 `personal_info_page`**

### 3. 可查看的数据
- **事件时长**: 平均时长、总时长、时长分布
- **事件参数**: 按 `device_id` 或 `user_id` 筛选
- **时长分布**: 0-10秒、10-30秒、30-60秒等分段统计
- **趋势图**: 按日期查看时长变化趋势

### 4. 示例数据展示
| 日期 | 触发次数 | 平均时长 | 总时长 |
|------|---------|---------|--------|
| 2025-10-25 | 1,234 | 45秒 | 15小时 |
| 2025-10-24 | 1,156 | 42秒 | 13.5小时 |

## 🛡️ 安全机制

### 1. 异常处理
- 所有操作都包裹在 `try-catch` 中
- 失败时打印日志，不影响页面正常使用

### 2. 防止内存泄漏
- `onClose()` 确保页面销毁时结束计时
- 即使忘记调用 `eventEnd()`，30分钟后自动警告

### 3. 重复开始保护
- 如果重复调用 `eventBegin()`，会自动结束之前的计时

### 4. 未开始保护
- 如果未调用 `eventBegin()` 就调用 `eventEnd()`，会警告但不崩溃

## 🧪 测试方法

### 1. 本地测试
```dart
// 1. 打开"我的"页面
// 2. 观察控制台输出
📊 开始统计"我的"页面停留时长 - device_id: xxx, user_id: xxx

// 3. 停留一段时间后返回
// 4. 观察控制台输出
📊 结束"我的"页面停留统计 - device_id: xxx, user_id: xxx
```

### 2. 友盟后台验证
1. 等待 5-10 分钟（友盟数据有延迟）
2. 登录友盟后台
3. 查看事件 `personal_info_page`
4. 确认有新的事件数据上报

## 📝 注意事项

### ✅ 正确做法
1. **在 `onInit()` 中调用 `eventBegin()`**
2. **在 `onClose()` 中调用 `eventEnd()`**
3. **不要手动传递 `stay_duration` 参数**（友盟自动计算）
4. **使用 `try-catch` 包裹所有调用**

### ❌ 错误做法
1. ❌ 忘记在 `onClose()` 中调用 `eventEnd()`
2. ❌ 手动计算并传递 `stay_duration` 参数
3. ❌ 在多个地方重复调用 `eventBegin()`
4. ❌ 不处理异常，导致页面崩溃

## 🔗 相关文档

- [友盟事件计时功能完整文档](./umeng_event_timing_feature.md)
- [友盟统计集成文档](./umeng_analytics_integration.md)

## 📅 更新记录

- **2025-10-25**: 完成"我的"页面停留时长统计集成
  - 在 `MineController` 中添加 `_startPageStayTracking()` 方法
  - 在 `MineController` 中添加 `_endPageStayTracking()` 方法
  - 在 `onInit()` 中开始计时
  - 在 `onClose()` 中结束计时

