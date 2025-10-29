# 首页另一半头像点击埋点实现文档

## 概述
根据 `api_type.md` 中的要求，为首页右上角的另一半头像点击事件实现了完整的埋点功能。

## 埋点事件

### 事件ID
`bind_partner_avatar`（头像绑定另一半）

### 事件类型
点击事件

### 事件参数

| 参数名 | 说明 | 数据类型 | 示例 |
|--------|------|----------|------|
| device_id | 虚拟用户ID（通过设备号生成） | String | "550e8400-e29b-41d4-a716-446655440000" |
| user_id | 用户ID（已登录时） | String | "12345" |
| click_time | 点击时间 | String | "2025/10/25 14:30:45" |

## 实现细节

### 1. 触发场景

该埋点在以下两种场景下触发：

1. **未绑定状态**：用户点击右上角的"加号"按钮（显示绑定弹窗）
2. **已绑定状态**：用户点击右上角的另一半头像（跳转到恋爱信息页）

### 2. 代码实现

#### Controller 层实现

**文件位置：** `lib/pages/home/home_controller.dart`

```dart
/// 埋点：点击另一半头像（绑定伴侣头像）
Future<void> trackPartnerAvatarClick() async {
  try {
    // 获取虚拟用户ID
    final deviceId = await UmengAnalytics.getOrCreateVirtualUserId();
    
    // 获取用户ID（如果已登录）
    final user = UserManager.currentUser;
    final userId = user?.id?.toString() ?? '';
    
    // 获取当前时间，格式：年/月/日 时:分:秒
    final now = DateTime.now();
    final clickTime = '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    
    // 构建埋点参数
    final params = <String, String>{
      'device_id': deviceId,
      'click_time': clickTime,
    };
    
    // 如果有用户ID，添加到参数中
    if (userId.isNotEmpty) {
      params['user_id'] = userId;
    }
    
    // 上报点击事件
    await UmengAnalytics.logEventWithParams('bind_partner_avatar', params);
    
    debugPrint('✅ 另一半头像点击埋点上报成功: device_id=$deviceId, user_id=$userId, click_time=$clickTime');
  } catch (e) {
    debugPrint('❌ 另一半头像点击埋点：上报数据失败 - $e');
  }
}
```

#### View 层调用

**文件位置：** `lib/pages/home/home_page.dart`

##### 场景1：未绑定状态（点击加号按钮）

```dart
GestureDetector(
  onTap: () {
    // 埋点：点击另一半头像（未绑定状态）
    controller.trackPartnerAvatarClick();
    // 显示绑定弹窗
    CustomBottomDialog.show(context: context);
  },
  child: Container(
    // ... 加号按钮UI
  ),
)
```

##### 场景2：已绑定状态（点击另一半头像）

```dart
GestureDetector(
  onTap: () {
    // 埋点：点击另一半头像（已绑定状态）
    controller.trackPartnerAvatarClick();
    // 已绑定状态下点击头像跳转到恋爱信息页
    Get.to(() => const LoveInfoPage());
  },
  child: NoPlaceholderImage(
    // ... 头像UI
  ),
)
```

### 3. 时间格式处理

点击时间使用以下格式：`年/月/日 时:分:秒`

**实现代码：**
```dart
final now = DateTime.now();
final clickTime = '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
```

**示例输出：**
- `2025/10/25 14:30:45`
- `2025/01/05 09:08:03`

### 4. 数据上报逻辑

1. **获取虚拟用户ID**：通过 `UmengAnalytics.getOrCreateVirtualUserId()` 获取或创建设备唯一标识
2. **获取用户ID**：从 `UserManager.currentUser` 获取当前登录用户的ID
3. **记录点击时间**：获取当前系统时间并格式化
4. **构建参数**：将必填参数和可选参数组装成 Map
5. **上报事件**：调用 `UmengAnalytics.logEventWithParams()` 上报数据

## 测试说明

### 测试场景

#### 场景1：未绑定状态测试
1. 进入首页（未绑定另一半）
2. 点击右上角的"加号"按钮
3. 应该触发埋点并显示绑定弹窗
4. 检查日志输出确认埋点上报成功

#### 场景2：已绑定状态测试
1. 进入首页（已绑定另一半）
2. 点击右上角的另一半头像
3. 应该触发埋点并跳转到恋爱信息页
4. 检查日志输出确认埋点上报成功

### 日志示例

#### 未绑定状态点击
```
✅ 另一半头像点击埋点上报成功: device_id=550e8400-e29b-41d4-a716-446655440000, user_id=12345, click_time=2025/10/25 14:30:45
```

#### 已绑定状态点击
```
✅ 另一半头像点击埋点上报成功: device_id=550e8400-e29b-41d4-a716-446655440000, user_id=12345, click_time=2025/10/25 15:45:30
```

#### 上报失败
```
❌ 另一半头像点击埋点：上报数据失败 - [错误信息]
```

## 注意事项

1. **时间格式**
   - 严格按照 `年/月/日 时:分:秒` 格式
   - 月、日、时、分、秒不足两位时需要补零
   - 使用24小时制

2. **用户ID处理**
   - 用户未登录时，`user_id` 参数为空字符串，不会添加到上报参数中
   - 用户已登录时，才会包含 `user_id` 参数

3. **虚拟用户ID**
   - 通过设备号生成的唯一标识
   - 即使用户未登录也能追踪用户行为
   - 与用户ID是两个独立的标识

4. **埋点时机**
   - 在用户点击时立即触发，不等待后续操作结果
   - 异步上报，不阻塞UI交互
   - 上报失败不影响正常功能

5. **兼容性**
   - 使用了现有的友盟统计工具类 `UmengAnalytics`
   - 与现有的埋点实现保持一致的风格
   - 支持未绑定和已绑定两种状态

## UI 位置说明

右上角另一半头像的位置：
- **位置**：首页右上角，距离顶部 55px，距离右侧 25px
- **未绑定状态**：显示白色背景的加号按钮
- **已绑定状态**：显示另一半的真实头像
- **尺寸**：38x38 像素
- **旋转角度**：顺时针 30 度

## 相关文件

- `lib/pages/home/home_controller.dart` - 首页控制器，包含埋点方法
- `lib/pages/home/home_page.dart` - 首页视图，调用埋点方法
- `lib/utils/umeng_analytics_util.dart` - 友盟统计工具类
- `api_type.md` - 埋点需求文档

## 更新日期

2025-10-25

