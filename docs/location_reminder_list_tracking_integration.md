# 位置提醒列表页面埋点集成文档

## 📋 概述

本文档记录位置提醒列表页面（LocationReminderPage）的友盟埋点集成实现，包括3个埋点事件的触发时机、参数说明和实现细节。

## 🎯 埋点事件列表

### 1. 页面浏览事件（location_knock_list）

**触发时机**：用户离开位置提醒列表页面时

**事件ID**：`location_knock_list`

**事件类型**：浏览事件

**参数说明**：
| 参数名 | 中文名称 | 说明 | 示例值 | API字段 |
|--------|---------|------|--------|---------|
| device_id | 虚拟用户ID | 通过用户设备号生成的虚拟用户ID | "abc123..." | device_id |
| user_id | 用户ID | 已登录用户的ID | "12345" | user_id |
| stay_duration | 页面停留时长 | 记录此用户的停留时长 | "15s" | stay_duration |
| scroll_times | 页面滑动次数 | 记录页面滑动次数 | "5次" | scroll_times |

**触发流程**：
1. 用户进入位置提醒列表页面
2. Controller 在 `onInit()` 中记录进入时间
3. 用户浏览、滑动列表（滑动次数自动统计）
4. 用户离开页面（返回或跳转）
5. Controller 在 `onClose()` 中计算停留时长
6. 调用 `TrackingService.trackLocationKnockListPageView()` 上报埋点

---

### 2. 添加地点位置事件（location_knock_add）

**触发时机**：用户点击"添加地点"按钮时

**事件ID**：`location_knock_add`

**事件类型**：点击事件

**参数说明**：
| 参数名 | 中文名称 | 说明 | 示例值 | API字段 |
|--------|---------|------|--------|---------|
| device_id | 虚拟用户ID | 通过用户设备号生成的虚拟用户ID | "abc123..." | device_id |
| user_id | 用户ID | 已登录用户的ID | "12345" | user_id |
| click_time | 点击时间 | 点击的时间 | "2025/10/25 14:30:45" | click_time |

**触发流程**：
1. 用户点击列表底部的"添加地点"卡片
2. 立即调用 `TrackingService.trackLocationKnockAdd()` 上报埋点
3. 跳转到位置选择页面（LocationPickerPage）

---

### 3. 删除操作事件（location_knock_delete）

**触发时机**：用户在删除确认弹窗中点击"确定"按钮时

**事件ID**：`location_knock_delete`

**事件类型**：点击事件

**参数说明**：
| 参数名 | 中文名称 | 说明 | 示例值 | API字段 |
|--------|---------|------|--------|---------|
| device_id | 虚拟用户ID | 通过用户设备号生成的虚拟用户ID | "abc123..." | device_id |
| user_id | 用户ID | 已登录用户的ID | "12345" | user_id |
| click_time | 点击时间 | 点击的时间 | "2025/10/25 14:30:45" | click_time |

**触发流程**：
1. 用户点击某个位置提醒项右侧的删除图标
2. 显示删除确认弹窗："确定要删除吗？"
3. 用户点击弹窗中的"确定"按钮
4. 立即调用 `TrackingService.trackLocationKnockDelete()` 上报埋点
5. 调用删除API执行实际删除操作

---

## 🔧 技术实现

### 1. TrackingService 新增方法

在 `lib/services/tracking_service.dart` 中新增了3个埋点方法：

```dart
// ==================== 位置提醒列表页埋点 ====================

/// 埋点：位置提醒列表 - 页面浏览
static Future<void> trackLocationKnockListPageView({
  required String stayDuration,
  required int scrollTimes,
}) async {
  final params = await _buildBaseParams();
  params['stay_duration'] = stayDuration;
  params['scroll_times'] = '${scrollTimes}次';
  await _trackEvent('location_knock_list', params, '位置提醒列表-页面浏览');
}

/// 埋点：位置提醒列表 - 添加地点位置
static Future<void> trackLocationKnockAdd() async {
  final params = await _buildBaseParams();
  await _trackEvent('location_knock_add', params, '位置提醒列表-添加地点位置');
}

/// 埋点：位置提醒列表 - 删除操作
static Future<void> trackLocationKnockDelete() async {
  final params = await _buildBaseParams();
  await _trackEvent('location_knock_delete', params, '位置提醒列表-删除操作');
}
```

### 2. LocationReminderController 实现

在 `lib/pages/location/location_reminder/location_reminder_controller.dart` 中实现页面浏览埋点：

#### 导入依赖
```dart
import 'package:kissu_app/services/tracking_service.dart';
import 'package:kissu_app/utils/debug_util.dart';
```

#### 添加字段
```dart
// 页面埋点相关
DateTime? _pageEnterTime; // 页面进入时间
int _scrollCount = 0; // 页面滑动次数
```

#### 生命周期方法
```dart
@override
void onInit() {
  super.onInit();
  // 记录页面进入时间
  _pageEnterTime = DateTime.now();
  // ... 其他初始化
}

@override
void onClose() {
  // 上报页面浏览埋点
  _trackPageView();
  // ... 其他清理
  super.onClose();
}
```

#### 埋点方法
```dart
/// 增加滑动次数计数
void incrementScrollCount() {
  _scrollCount++;
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
    await TrackingService.trackLocationKnockListPageView(
      stayDuration: stayDuration,
      scrollTimes: _scrollCount,
    );
    
    DebugUtil.info('✅ 位置提醒列表页面浏览埋点上报成功');
  } catch (e) {
    DebugUtil.error('❌ 位置提醒列表页面浏览埋点上报失败: $e');
  }
}
```

### 3. LocationReminderPage 实现

在 `lib/pages/location/location_reminder/location_reminder_page.dart` 中实现滑动监听和点击埋点：

#### 导入依赖
```dart
import 'package:kissu_app/services/tracking_service.dart';
import 'package:kissu_app/utils/debug_util.dart';
```

#### 滑动监听器
```dart
body: Container(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  child: Obx(() {
    final showAddButton = controller.reminders.length < 20;
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        // 监听滑动更新事件
        if (scrollNotification is ScrollUpdateNotification) {
          controller.incrementScrollCount();
        }
        return false;
      },
      child: ListView.builder(
        // ... ListView 配置
      ),
    );
  }),
),
```

#### 添加地点埋点
```dart
Widget _buildAddLocationItem(BuildContext context) {
  return GestureDetector(
    onTap: () async {
      // 上报添加地点埋点
      try {
        await TrackingService.trackLocationKnockAdd();
        DebugUtil.info('✅ 位置提醒列表-添加地点埋点上报成功');
      } catch (e) {
        DebugUtil.error('❌ 位置提醒列表-添加地点埋点上报失败: $e');
      }
      
      // 跳转到位置选择页面
      final result = await Get.to(() => LocationPickerPage());
      // ...
    },
    // ...
  );
}
```

#### 删除操作埋点
```dart
void _showDeleteDialog(BuildContext context, String reminderId) async {
  await DeleteLocationReminderDialogUtil.show(
    onConfirm: () async {
      // 上报删除操作埋点
      try {
        await TrackingService.trackLocationKnockDelete();
        DebugUtil.info('✅ 位置提醒列表-删除操作埋点上报成功');
      } catch (e) {
        DebugUtil.error('❌ 位置提醒列表-删除操作埋点上报失败: $e');
      }
      
      // 执行删除操作
      final success = await controller.removeReminder(reminderId);
      // ...
    },
    onCancel: () {
      // 弹窗消失，不需要额外操作
    },
  );
}
```

---

## 📊 埋点数据示例

### 页面浏览事件示例
```json
{
  "event_id": "location_knock_list",
  "device_id": "abc123def456",
  "user_id": "12345",
  "stay_duration": "25s",
  "scroll_times": "8次",
  "click_time": "2025/10/25 14:30:45"
}
```

### 添加地点事件示例
```json
{
  "event_id": "location_knock_add",
  "device_id": "abc123def456",
  "user_id": "12345",
  "click_time": "2025/10/25 14:31:20"
}
```

### 删除操作事件示例
```json
{
  "event_id": "location_knock_delete",
  "device_id": "abc123def456",
  "user_id": "12345",
  "click_time": "2025/10/25 14:32:15"
}
```

---

## 🎯 关键实现要点

### 1. 页面浏览埋点
- **记录时机**：页面进入时（onInit）记录时间戳
- **上报时机**：页面离开时（onClose）计算停留时长并上报
- **滑动统计**：通过 `NotificationListener<ScrollNotification>` 监听滑动事件
- **计数逻辑**：每次 `ScrollUpdateNotification` 触发时增加计数

### 2. 添加地点埋点
- **触发点**：点击"添加地点"按钮时立即上报
- **执行顺序**：先上报埋点 → 再跳转页面
- **埋点独立**：埋点与业务逻辑解耦，即使跳转失败埋点也已记录

### 3. 删除操作埋点
- **触发点**：删除确认弹窗的"确定"按钮点击时
- **执行顺序**：先上报埋点 → 再调用删除API
- **埋点独立**：即使删除失败，埋点也已记录用户的操作意图

---

## 🧪 测试建议

建议在以下场景下验证埋点是否正确触发：

### 1. 页面浏览埋点测试
- ✅ 进入位置提醒列表页面后立即返回（停留时长约0-1秒）
- ✅ 进入页面后停留10秒，不滑动（滑动次数为0次）
- ✅ 进入页面后上下滑动5次，停留15秒
- ✅ 进入页面后滑动多次，从不同入口返回（返回按钮、系统手势等）

### 2. 添加地点埋点测试
- ✅ 点击"添加地点"按钮，验证埋点上报
- ✅ 点击后取消添加（验证埋点已记录点击行为）
- ✅ 点击后完成添加（验证埋点不重复上报）

### 3. 删除操作埋点测试
- ✅ 点击删除图标 → 点击确定按钮（验证埋点上报）
- ✅ 点击删除图标 → 点击取消按钮（验证埋点不上报）
- ✅ 点击删除图标 → 点击弹窗外部关闭（验证埋点不上报）
- ✅ 删除成功（验证埋点已记录）
- ✅ 删除失败（验证埋点已记录用户操作意图）

### 4. 用户状态测试
- ✅ 未登录状态下各埋点的 user_id 字段是否为空
- ✅ 已登录状态下各埋点的 user_id 字段是否正确

---

## 📝 注意事项

1. **页面浏览埋点触发时机**：
   - 在 `onClose()` 中上报，确保完整记录停留时长和滑动次数
   - 使用非阻塞调用，避免影响页面关闭流程

2. **滑动次数统计**：
   - 使用 `ScrollUpdateNotification` 监听，每次滑动更新都会触发计数
   - 滑动次数可能较多，这是正常现象（符合实际用户行为）

3. **点击埋点时机**：
   - 添加地点埋点：点击按钮时立即上报
   - 删除操作埋点：**仅在确认弹窗的确定按钮点击时上报**

4. **埋点调用顺序**：
   - 添加地点埋点：在跳转前调用
   - 删除操作埋点：在调用删除API前调用
   - 页面浏览埋点：在 `onClose()` 中调用

5. **错误处理**：
   - 所有埋点调用都包含 try-catch 错误处理
   - 埋点失败不影响业务功能正常执行
   - 使用 DebugUtil 记录埋点成功/失败日志

6. **用户信息获取**：
   - 通过 `UserManager.currentUser` 获取当前用户信息
   - device_id 和 click_time 在 `TrackingService._buildBaseParams()` 中自动生成
   - user_id 仅在已登录状态下包含

---

## 📚 相关文件

### 核心文件
- `lib/services/tracking_service.dart` - 埋点服务（新增3个方法）
- `lib/pages/location/location_reminder/location_reminder_controller.dart` - Controller（新增页面埋点）
- `lib/pages/location/location_reminder/location_reminder_page.dart` - 页面（新增滑动监听和点击埋点）

### 依赖文件
- `lib/utils/umeng_analytics_util.dart` - 友盟分析工具（获取虚拟用户ID）
- `lib/utils/user_manager.dart` - 用户管理（获取用户信息）
- `lib/utils/debug_util.dart` - 调试工具（日志输出）
- `lib/widgets/dialogs/delete_location_reminder_dialog.dart` - 删除确认弹窗

---

## 🔄 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| 1.0.0 | 2025-10-27 | 初始版本，实现3个埋点事件 |

---

## 📞 联系方式

如有问题或建议，请联系开发团队。

---

**文档更新日期**：2025年10月27日

