# 状态页面埋点集成文档

## 概述

本文档记录了状态设置页面的三个埋点事件集成。这些埋点事件通过统一的 `TrackingService` 进行管理，包括页面浏览事件、设置完成事件和删除状态事件。

## 变更日期

2025-10-27

## 新增埋点事件

### 1. 状态页面浏览事件 (state_current_page)

**触发位置：** 状态设置页面  
**触发时机：** 用户离开状态页面时（onClose）  
**代码位置：** `lib/pages/location/location_state_controller.dart` - `_trackPageView()` 方法

**事件参数：**
- `device_id`: 虚拟用户ID
- `user_id`: 用户ID（已登录时）
- `is_bind`: 用户情侣绑定状态（已绑定/未绑定）
- `is_vip`: 用户充值状态（已充值/未充值）
- `stay_duration`: 页面停留时长（如：2s）
- `scroll_times`: 页面滑动次数（如：3次）

**实现方式：**
```dart
// 在页面控制器的 onClose 中自动调用
await TrackingService.trackStatePageView(
  isBind: isBind,
  isVip: isVip,
  stayDuration: stayDuration,
  scrollTimes: scrollTimes,
);
```

**说明：**
- 页面进入时记录时间戳 `_pageEnterTime`
- 页面关闭时计算停留时长（当前时间 - 进入时间）
- 通过 `NotificationListener<ScrollNotification>` 监听滑动事件
- 每次 `ScrollUpdateNotification` 触发时增加滑动计数

### 2. 设置完成事件 (state_setting_complet)

**触发位置：** 状态设置页面 - 替换确认弹窗  
**触发时机：** 用户点击"是否要替换之前的状态？"弹窗的确认按钮时  
**代码位置：** `lib/pages/location/location_state_controller.dart` - `confirmReplace()` 方法

**事件参数：**
- `device_id`: 虚拟用户ID
- `user_id`: 用户ID（已登录时）
- `state_info`: 状态类型（如：亲亲、开心、玩游戏）
- `state_duration`: 状态有效期（如：1小时、2小时、3小时）
- `click_time`: 确定时间（格式：年/月/日 时:分:秒）

**实现方式：**
```dart
// 在替换确认弹窗的确认按钮点击时调用
await TrackingService.trackStateSettingComplete(
  stateInfo: stateInfo,
  stateDurationHours: stateDurationHours,
);
```

**说明：**
- 仅在用户已有状态，且选择新状态后点击保存时触发
- 埋点在调用设置状态接口 `_doSetStatus()` 前上报
- 记录的是最终确认设置的状态信息和有效期

### 3. 删除状态事件 (state_delete)

**触发位置：** 状态设置页面 - 删除确认弹窗  
**触发时机：** 用户点击"确定要删除吗？"弹窗的确认按钮时  
**代码位置：** `lib/pages/location/location_state_controller.dart` - `deleteStatus()` 方法

**事件参数：**
- `device_id`: 虚拟用户ID
- `user_id`: 用户ID（已登录时）
- `click_time`: 点击删除时间（格式：年/月/日 时:分:秒）

**实现方式：**
```dart
// 在删除确认弹窗的确认按钮点击时调用
await TrackingService.trackStateDelete();
```

**说明：**
- 埋点在调用删除接口 `_api.deleteFaceStatus()` 前上报
- 确保即使删除失败，埋点也已记录用户的删除意图

## TrackingService 新增方法

在 `lib/services/tracking_service.dart` 中新增了以下 3 个静态方法：

### 1. trackStatePageView()
```dart
static Future<void> trackStatePageView({
  required bool isBind,
  required bool isVip,
  required String stayDuration,
  required int scrollTimes,
})
```
- 必填参数：绑定状态、VIP状态、停留时长、滑动次数

### 2. trackStateSettingComplete()
```dart
static Future<void> trackStateSettingComplete({
  required String stateInfo,
  required int stateDurationHours,
})
```
- 必填参数：状态信息、状态有效期（小时数）

### 3. trackStateDelete()
```dart
static Future<void> trackStateDelete()
```
- 无额外参数，仅记录删除事件

## 代码变更总结

### 修改的文件

#### 1. lib/services/tracking_service.dart
- 新增 3 个状态页面埋点方法
- 所有方法遵循统一的命名规范和参数格式
- 添加了详细的注释说明

#### 2. lib/pages/location/location_state_controller.dart
- 导入 `TrackingService` 和 `UserManager`
- 新增页面埋点相关字段：
  - `_pageEnterTime`: 记录页面进入时间
  - `_scrollCount`: 记录页面滑动次数
- 新增 `incrementScrollCount()` 方法：增加滑动计数
- 在 `onInit()` 中记录页面进入时间
- 在 `onClose()` 中调用 `_trackPageView()` 上报浏览埋点
- 新增 `_trackPageView()` 方法：计算停留时长和上报浏览埋点
- 在 `confirmReplace()` 中添加 `_trackStateSettingComplete()` 埋点调用
- 新增 `_trackStateSettingComplete()` 方法：上报设置完成埋点
- 在 `deleteStatus()` 中添加 `trackStateDelete()` 埋点调用

#### 3. lib/pages/location/location_state_page.dart
- 在表情列表 `ListView.builder` 外层添加 `NotificationListener<ScrollNotification>`
- 监听 `ScrollUpdateNotification` 事件
- 每次滑动时调用 `controller.incrementScrollCount()` 增加计数

### 代码质量保证

✅ 所有代码通过 Linter 检查，无警告和错误  
✅ 遵循项目现有的埋点命名规范  
✅ 使用统一的 `TrackingService` 管理所有埋点  
✅ 添加了详细的注释说明  
✅ 埋点在关键操作前触发，确保数据准确记录

## 埋点事件映射

| 功能描述 | 事件ID | 触发位置 | 触发时机 |
|---------|--------|---------|---------|
| 状态页面浏览 | `state_current_page` | 状态设置页面 | 页面关闭时（onClose） |
| 设置完成 | `state_setting_complet` | 替换确认弹窗 | 点击确认按钮 |
| 删除状态 | `state_delete` | 删除确认弹窗 | 点击确认按钮 |

## 页面流程说明

### 设置状态流程

```
用户进入状态页面
    ↓
记录进入时间 (_pageEnterTime)
    ↓
浏览表情列表（滑动时增加计数）
    ↓
选择表情 → 选择有效期 → 点击底部确定按钮
    ↓
[已有状态] → 显示替换确认弹窗
    ↓
点击"确认"按钮
    ↓
【上报设置完成埋点】← 关键埋点触发点
    ↓
调用设置状态接口
    ↓
返回定位页面并刷新
    ↓
【上报页面浏览埋点】← 页面关闭时触发
```

### 删除状态流程

```
用户在状态页面（已有状态）
    ↓
点击"删除"按钮
    ↓
显示删除确认弹窗："确定要删除吗？"
    ↓
点击"确认"按钮
    ↓
【上报删除状态埋点】← 关键埋点触发点
    ↓
调用删除状态接口
    ↓
返回定位页面并刷新
    ↓
【上报页面浏览埋点】← 页面关闭时触发
```

## 使用示例

### 示例 1：页面浏览埋点（自动触发）
```dart
// 用户进入页面
@override
void onInit() {
  super.onInit();
  _pageEnterTime = DateTime.now(); // 记录进入时间
  _loadFaceStatusWithCache();
}

// 用户离开页面
@override
void onClose() {
  _trackPageView(); // 自动上报浏览埋点
  super.onClose();
}

// 计算停留时长并上报
Future<void> _trackPageView() async {
  final duration = DateTime.now().difference(_pageEnterTime!);
  final stayDuration = '${duration.inSeconds}s';
  
  await TrackingService.trackStatePageView(
    isBind: isBind,
    isVip: isVip,
    stayDuration: stayDuration,
    scrollTimes: _scrollCount,
  );
}
```

### 示例 2：设置完成埋点
```dart
// 用户点击替换确认弹窗的确认按钮
void confirmReplace() {
  if (tempSelectedEmoji.value == null) return;
  
  // 更新有效期
  selectedExpireHours.value = tempSelectedExpireHours.value!;
  selectedEmoji.value = tempSelectedEmoji.value;
  
  // 上报设置完成埋点
  _trackStateSettingComplete();
  
  // 调用设置状态接口
  _doSetStatus();
}

Future<void> _trackStateSettingComplete() async {
  await TrackingService.trackStateSettingComplete(
    stateInfo: selectedEmoji.value!.name,
    stateDurationHours: selectedExpireHours.value,
  );
}
```

### 示例 3：删除状态埋点
```dart
// 用户点击删除确认弹窗的确认按钮
Future<void> deleteStatus() async {
  // 上报删除状态埋点
  await TrackingService.trackStateDelete();
  
  // 调用接口删除状态
  final result = await _api.deleteFaceStatus();
  
  if (result.isSuccess) {
    // 删除成功，清空本地状态
    hasStatus.value = false;
    // ...
    _returnToLocationPageAndRefresh();
  }
}
```

## 代码实现细节

### 页面浏览埋点 - 滑动监听

```dart
// 在表情列表外层添加滑动监听器
NotificationListener<ScrollNotification>(
  onNotification: (notification) {
    // 监听滑动事件，当用户滑动时记录次数
    if (notification is ScrollUpdateNotification) {
      controller.incrementScrollCount();
    }
    return false;
  },
  child: ListView.builder(
    // 表情列表内容
  ),
)
```

### 用户状态判断逻辑

```dart
// 判断是否已绑定伴侣
// bind_status == '1' 表示已绑定，其他值表示未绑定
final isBind = user?.bindStatus == '1';

// 判断是否为VIP用户
// is_vip == 1 表示是VIP，其他值表示不是VIP
final isVip = user?.isVip == 1;
```

## 注意事项

1. **页面浏览埋点触发时机**：页面关闭时（onClose）上报，确保完整记录停留时长和滑动次数。

2. **滑动次数统计**：使用 `ScrollUpdateNotification` 监听滑动，每次滑动事件触发时增加计数。注意：这可能会统计到很小的滑动，实际滑动次数可能较多。

3. **设置完成埋点触发条件**：
   - 仅在用户已有状态，且选择新状态后点击保存时触发
   - 在替换确认弹窗点击"确认"按钮时上报
   - 记录的是最终确认设置的状态信息和有效期

4. **删除状态埋点触发时机**：在删除确认弹窗点击"确认"按钮时上报，在调用删除接口前。

5. **埋点调用顺序**：
   - 设置完成埋点：在 `_doSetStatus()` 前调用
   - 删除状态埋点：在 `_api.deleteFaceStatus()` 前调用
   - 页面浏览埋点：在 `onClose()` 中调用

6. **用户信息获取**：
   - 通过 `UserManager.currentUser` 获取当前用户信息
   - 判断绑定状态：`bindStatus == '1'` 表示已绑定，其他值表示未绑定
   - 判断VIP状态：`isVip == 1` 表示是VIP，其他值表示不是VIP

## 测试建议

建议在以下场景下验证埋点是否正确触发：

### 1. 页面浏览埋点
- ✅ 进入状态页面，停留 10 秒后返回，验证 `stay_duration` 是否约为 10s
- ✅ 进入状态页面，上下滑动 5 次后返回，验证 `scroll_times` 是否记录滑动次数
- ✅ 验证 `is_bind` 是否正确反映用户绑定状态
- ✅ 验证 `is_vip` 是否正确反映用户VIP状态

### 2. 设置完成埋点
- ✅ 用户已有状态，选择新表情 → 选择有效期 → 点击确定 → 弹窗确认，验证埋点触发
- ✅ 验证 `state_info` 是否正确记录表情名称（如：亲亲、开心）
- ✅ 验证 `state_duration` 是否正确记录有效期（如：1小时、2小时）
- ✅ 验证 `click_time` 是否记录确认时间

### 3. 删除状态埋点
- ✅ 用户已有状态，点击删除 → 弹窗确认，验证埋点触发
- ✅ 验证 `click_time` 是否记录删除时间
- ✅ 验证删除失败时埋点是否也已上报

### 4. 边界情况
- ✅ 用户进入页面立即返回（停留时长 0s）
- ✅ 用户进入页面不滑动直接返回（滑动次数 0次）
- ✅ 未登录用户访问页面（user_id 为空）
- ✅ 未绑定伴侣的用户（is_bind = 未绑定）
- ✅ 非VIP用户（is_vip = 未充值）

## 相关弹窗说明

### 替换确认弹窗
- **标题**：是否要替换之前的状态？
- **触发条件**：用户已有状态，选择新表情后点击保存
- **确认按钮**：替换之前的状态，并上报设置完成埋点
- **取消按钮**：不替换，保持当前临时状态

### 删除确认弹窗
- **标题**：确定要删除吗？
- **触发条件**：用户已有状态，点击删除按钮
- **确认按钮**：删除当前状态，并上报删除状态埋点
- **取消按钮**：不删除，关闭弹窗

### 返回确认弹窗
- **标题**：确定要放弃当前更改吗？
- **触发条件**：用户有未保存的更改时点击返回
- **确认按钮**：放弃更改并返回
- **取消按钮**：继续编辑
- **注意**：此弹窗不涉及埋点

## API 映射参考

根据 `api_type.md` 文档，三个埋点事件对应关系：

| 事件名称 | 事件ID | 中文名称 | 参数 |
|---------|--------|---------|------|
| 状态页面浏览 | `state_current_page` | 状态页面浏览事件 | device_id, user_id, is_bind, is_vip, stay_duration, scroll_times |
| 设置完成 | `state_setting_complet` | 设置状态完成 | device_id, user_id, state_info, state_duration, click_time |
| 删除状态 | `state_delete` | 状态删除操作 | device_id, user_id, click_time |

## 维护建议

1. **后续优化方向**：
   - 考虑优化滑动次数统计逻辑，避免统计过于频繁的小幅滑动
   - 可以添加滑动距离阈值，仅统计有效滑动
   - 考虑添加防抖机制，避免短时间内多次触发

2. **代码维护**：
   - 保持埋点命名规范一致性（使用 `state_` 前缀）
   - 在埋点方法上添加详细的注释说明
   - 更新本文档记录新增或修改的埋点事件

3. **错误处理**：
   - 埋点上报失败不应影响用户正常流程
   - 使用 try-catch 包裹埋点调用，避免异常中断业务逻辑
   - 记录详细的调试日志，便于问题排查

4. **性能考虑**：
   - 埋点调用使用异步方式，不阻塞主线程
   - 页面浏览埋点在 onClose 中上报，不影响用户操作
   - 设置完成和删除埋点在操作前上报，使用 await 确保埋点优先发送

## 相关文档

- [TrackingService 使用指南](tracking_service_guide.md)（如存在）
- [定位页面地图按钮埋点集成](location_map_buttons_tracking.md)
- [定位页面额外埋点集成](location_additional_tracking.md)
- [友盟埋点集成总结](umeng_analytics_integration.md)（如存在）
- [API 埋点类型定义](../api_type.md)

## 附录：完整代码片段

### LocationStateController 埋点相关代码

```dart
// 页面埋点相关字段
DateTime? _pageEnterTime;
int _scrollCount = 0;

void incrementScrollCount() {
  _scrollCount++;
}

@override
void onInit() {
  super.onInit();
  _pageEnterTime = DateTime.now();
  _loadFaceStatusWithCache();
}

@override
void onClose() {
  _trackPageView();
  super.onClose();
}

Future<void> _trackPageView() async {
  if (_pageEnterTime == null) return;
  
  try {
    final duration = DateTime.now().difference(_pageEnterTime!);
    final stayDuration = '${duration.inSeconds}s';
    
    final user = UserManager.currentUser;
    final isBind = user?.bindStatus == '1';
    final isVip = user?.isVip == 1;
    
    await TrackingService.trackStatePageView(
      isBind: isBind,
      isVip: isVip,
      stayDuration: stayDuration,
      scrollTimes: _scrollCount,
    );
    
    DebugUtil.info('✅ 状态页面浏览埋点上报成功');
  } catch (e) {
    DebugUtil.error('❌ 状态页面浏览埋点上报失败: $e');
  }
}

void confirmReplace() {
  if (tempSelectedEmoji.value == null) return;
  
  if (tempSelectedExpireHours.value != null) {
    selectedExpireHours.value = tempSelectedExpireHours.value!;
    topExpireHours.value = tempSelectedExpireHours.value!;
  }
  selectedEmoji.value = tempSelectedEmoji.value;
  
  _trackStateSettingComplete();
  
  _doSetStatus();
}

Future<void> _trackStateSettingComplete() async {
  if (selectedEmoji.value == null) return;
  
  try {
    await TrackingService.trackStateSettingComplete(
      stateInfo: selectedEmoji.value!.name,
      stateDurationHours: selectedExpireHours.value,
    );
    
    DebugUtil.info('✅ 状态设置完成埋点上报成功');
  } catch (e) {
    DebugUtil.error('❌ 状态设置完成埋点上报失败: $e');
  }
}

Future<void> deleteStatus() async {
  try {
    await TrackingService.trackStateDelete();
    
    final result = await _api.deleteFaceStatus();
    
    if (result.isSuccess) {
      hasStatus.value = false;
      // ...
      _returnToLocationPageAndRefresh();
    }
  } catch (e) {
    DebugUtil.error('❌ 删除状态异常: $e');
  }
}
```

### LocationStatePage 滑动监听代码

```dart
Widget _buildEmojiContent() {
  return Obx(() {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (controller.emojiCategories.isEmpty) {
      return const Center(child: Text('暂无表情'));
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            controller.incrementScrollCount();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemCount: controller.emojiCategories.length,
          itemBuilder: (context, categoryIndex) {
            // 表情分类和网格
          },
        ),
      ),
    );
  });
}
```

## 总结

本次集成为状态设置页面添加了完整的埋点体系，涵盖了页面浏览、状态设置和状态删除三个核心场景。通过统一的 `TrackingService` 管理，保证了代码的可维护性和一致性。所有埋点均在关键操作前触发，确保数据准确记录，同时不影响用户的正常使用体验。

