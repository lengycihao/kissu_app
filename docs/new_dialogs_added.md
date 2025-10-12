# 新增三个弹窗组件文档

## 概述
在弹窗测试页面（Dialog Showcase Page）中新增了三个弹窗组件，所有弹窗使用与"解除关系弹窗"相同的背景样式。

---

## 1. 删除位置提醒弹窗

### 文件路径
`lib/widgets/dialogs/delete_location_reminder_dialog.dart`

### 设计规格
- **标题**: "确定要删除吗？"
- **内容**: "删除数据后将无法恢复数据，请谨慎操作！"
- **按钮**: 
  - 左侧：取消（灰色背景）
  - 右侧：确认（粉色渐变背景）
- **背景**: 使用 `assets/location/kissu3_state_delete_bg.webp`

### 使用方法
```dart
// 显示弹窗
final result = await DeleteLocationReminderDialogUtil.show(
  onConfirm: () {
    // 确认删除的回调
    print('用户确认删除');
  },
  onCancel: () {
    // 取消删除的回调
    print('用户取消删除');
  },
);

// result 为 true 表示确认，false 表示取消
```

### 特点
- 不可通过点击外部关闭（`barrierDismissible: false`）
- 必须点击按钮才能关闭
- 提供确认和取消两个回调

---

## 2. 检查对方位置权限弹窗

### 文件路径
`lib/widgets/dialogs/partner_location_permission_dialog.dart`

### 设计规格
- **标题行**: Row 布局
  - 左侧：提示
  - 右侧：关闭按钮（X）
- **副标题**: "系统检查Ta没有开通位置权限~" (14pt, #333333)
- **内容**: "建议Ta开通位置权限，否则将无法监控ta的位置~！"
- **按钮**: 
  - 知道了（粉色渐变背景，全宽）
- **背景**: 使用 `assets/location/kissu3_notice_middle_bg.webp`

### 使用方法
```dart
// 显示弹窗
final result = await PartnerLocationPermissionDialogUtil.show(
  onConfirm: () {
    // 用户点击"知道了"的回调
    print('用户已知道对方未开通位置权限');
  },
);

// result 为 true 表示点击了"知道了"
```

### 特点
- 可通过点击外部关闭（`barrierDismissible: true`）
- 可点击右上角关闭按钮
- 单按钮设计，用于通知用户

---

## 3. 自己未开通通知权限弹窗

### 文件路径
`lib/widgets/dialogs/self_notification_permission_dialog.dart`

### 设计规格
- **标题行**: Row 布局
  - 左侧：提示
  - 右侧：关闭按钮（X）
- **副标题**: "你还没有开通消息通知哦!" (14pt, #333333)
- **内容**: "建议开通消息通知权限～开通后，当 Ta 的位置发生变化，系统会第一时间向通知你；若未开通，可能会导致你错过通知"
- **按钮**: 
  - 左侧：知道了（灰色背景）
  - 右侧：去开启（粉色渐变背景）
- **背景**: 使用 `assets/location/kissu3_notice_big_bg.webp`

### 使用方法
```dart
// 显示弹窗
final result = await SelfNotificationPermissionDialogUtil.show(
  onKnow: () {
    // 用户点击"知道了"的回调
    print('用户点击了知道了');
  },
  onGoSettings: () {
    // 用户点击"去开启"后的回调（已自动跳转到设置）
    print('已跳转到通知设置页面');
  },
);

// result 为 true 表示点击了"去开启"
// result 为 false 表示点击了"知道了"
```

### 特点
- 可通过点击外部关闭（`barrierDismissible: true`）
- 可点击右上角关闭按钮
- 点击"去开启"会自动跳转到系统的通知设置页面
- 使用 `PermissionService.openNotificationSettings()` 跳转
- 参考了"我的页面 → 系统权限 → 开启通知提醒"的实现

---

## 在弹窗测试页面中的位置

所有三个弹窗都已添加到 `lib/pages/dialog_showcase/dialog_showcase_page.dart` 的"业务特定弹窗"分组中：

1. **删除位置提醒弹窗** - 确认删除位置提醒数据
2. **对方未开通位置权限提示** - 检查对方是否打开位置权限
3. **自己未开通通知权限提示** - 提示开通消息通知权限

---

## 访问路径

1. 打开应用
2. 进入"我的"页面
3. 点击"弹窗测试"菜单项
4. 滚动到"业务特定弹窗"分组
5. 点击对应的弹窗项目进行测试

---

## 技术实现细节

### 共同特点
- 所有弹窗都使用 `Get.dialog` 进行显示
- 背景图片位于 `assets/location/` 目录下，每个弹窗使用不同的背景：
  - 删除位置提醒弹窗：`kissu3_state_delete_bg.webp`
  - 对方位置权限弹窗：`kissu3_notice_middle_bg.webp`
  - 自己通知权限弹窗：`kissu3_notice_big_bg.webp`
- 按钮圆角半径统一为 22
- 容器宽度统一为 320
- 容器圆角半径统一为 20
- 内边距统一为 24

### 按钮样式
1. **主要按钮（粉色渐变）**:
   - 渐变色: `Color(0xFFFF839E)` → `Color(0xFFFF4E7A)`
   - 白色文字
   - 字体大小: 16pt
   - 字重: w500

2. **次要按钮（灰色）**:
   - 背景色: `Color(0xFFF5F5F5)`
   - 文字颜色: `Color(0xFF666666)`
   - 字体大小: 16pt
   - 字重: w500

### 关闭按钮
- 使用 `Icons.close`
- 大小: 24
- 颜色: `Color(0xFF999999)`
- 位置: 右上角

---

## 依赖
- `get`: 状态管理和路由
- `flutter/material.dart`: UI 组件
- `PermissionService`: 用于跳转到系统设置（仅第三个弹窗需要）

---

## 注意事项

1. **删除位置提醒弹窗**: 必须点击按钮关闭，不能通过点击外部关闭
2. **对方位置权限弹窗**: 可通过多种方式关闭（外部点击、关闭按钮、知道了按钮）
3. **自己通知权限弹窗**: 点击"去开启"会自动跳转到系统设置，应用可能会进入后台

---

## 测试清单

### 删除位置提醒弹窗
- [ ] 弹窗显示正常
- [ ] 标题和内容文字正确
- [ ] 点击"取消"按钮关闭弹窗
- [ ] 点击"确认"按钮关闭弹窗
- [ ] 点击外部不能关闭弹窗
- [ ] 回调函数正常触发

### 对方位置权限弹窗
- [ ] 弹窗显示正常
- [ ] 标题、副标题和内容文字正确
- [ ] 关闭按钮可以关闭弹窗
- [ ] 点击"知道了"按钮关闭弹窗
- [ ] 点击外部可以关闭弹窗
- [ ] 回调函数正常触发

### 自己通知权限弹窗
- [ ] 弹窗显示正常
- [ ] 标题、副标题和内容文字正确
- [ ] 关闭按钮可以关闭弹窗
- [ ] 点击"知道了"按钮关闭弹窗
- [ ] 点击"去开启"按钮跳转到系统设置
- [ ] 点击外部可以关闭弹窗
- [ ] 回调函数正常触发
- [ ] 从设置返回应用后状态正常

---

## 更新日期
2025-10-11

