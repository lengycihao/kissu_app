# 情侣关系动画功能实现文档

## 功能概述

当收到腾讯IM的自定义消息时，根据消息类型（`msg_type`）自动播放对应的GIF动画并执行相应操作：

### 绑定消息 (`msg_type = "bind"`)
1. 播放绑定成功动画（`assets/gif/bind_success.gif`，**5秒**）
2. 刷新用户信息（从服务器获取最新数据）
3. 刷新当前页面数据
4. 动画播放完成后自动跳转到**VIP会员页面**

### 解绑消息 (`msg_type = "unbind"`)
1. 播放解绑成功动画（`assets/gif/unbind_success.gif`，**2秒**）
2. 刷新用户信息（从服务器获取最新数据）
3. 刷新当前页面数据

## 实现架构

### 1. 核心组件

#### RelationshipAnimationOverlay (lib/widgets/relationship_animation_overlay.dart)
- **作用**: GIF动画叠加层Widget
- **特性**:
  - 全屏半透明黑色背景
  - GIF动画居中显示（300x300）
  - 淡入淡出效果（300ms）
  - 自动播放3秒后关闭
  - 动画完成后触发回调

#### RelationshipAnimationService (lib/services/relationship_animation_service.dart)
- **作用**: 管理动画显示的全局服务
- **功能**:
  - `showBindAnimation({VoidCallback? onComplete})`: 显示绑定成功动画（5秒），支持完成回调
  - `showUnbindAnimation({VoidCallback? onComplete})`: 显示解绑成功动画（2秒），支持完成回调
  - `refreshCurrentPage()`: 刷新当前活动页面（首页、我的、定位、足迹）
  - 防止重复显示（_isShowingAnimation标志）
  - 使用Get.dialog在全局叠加层显示

#### TencentIMService 增强 (lib/services/tencent_im_service.dart)
- **新增方法**: 
  - `_handleRelationshipMessage(String? customData)`: 解析自定义消息JSON
  - `_handleBindMessage(RelationshipAnimationService)`: 处理绑定消息
  - `_handleUnbindMessage(RelationshipAnimationService)`: 处理解绑消息
- **流程**:
  1. 接收自定义消息（elemType = 2）
  2. 解析JSON获取msg_type
  3. 刷新用户信息
  4. 刷新当前页面
  5. 播放对应动画
  6. （仅绑定）动画完成后跳转VIP页面

### 2. 消息处理流程

#### 绑定消息流程
```
IM自定义消息 (msg_type: "bind")
    ↓
onRecvNewMessage 回调
    ↓
检测 elemType == 2
    ↓
_handleRelationshipMessage()
    ↓
_handleBindMessage()
    ↓
刷新用户信息（AuthService.refreshUserInfoFromServer）
    ↓
刷新当前页面（refreshCurrentPage）
    ↓
播放绑定动画（5秒）
    ↓
动画完成回调
    ↓
跳转到VIP页面
```

#### 解绑消息流程
```
IM自定义消息 (msg_type: "unbind")
    ↓
onRecvNewMessage 回调
    ↓
检测 elemType == 2
    ↓
_handleRelationshipMessage()
    ↓
_handleUnbindMessage()
    ↓
刷新用户信息（AuthService.refreshUserInfoFromServer）
    ↓
刷新当前页面（refreshCurrentPage）
    ↓
播放解绑动画（2秒）
```

### 3. 消息格式

自定义消息的数据结构：
```json
{
  "msg_type": "bind",  // 或 "unbind"
  "from_user": "用户ID",
  "nickname": "昵称",
  "time": "2025-10-30 20:20:45",
  "desc": "绑定情侣关系"
}
```

## 文件清单

### 新增文件
1. `lib/widgets/relationship_animation_overlay.dart` - GIF动画叠加层Widget
2. `lib/services/relationship_animation_service.dart` - 动画管理服务

### 修改文件
1. `lib/services/tencent_im_service.dart`
   - 添加导入: `dart:convert`, `RelationshipAnimationService`, `AuthService`, `KissuRoutePath`
   - 修改消息监听器: 检测 `elemType == 2` 而不是 `customElem`
   - 添加 `_handleRelationshipMessage()`: 消息分发逻辑
   - 添加 `_handleBindMessage()`: 绑定消息完整处理流程
   - 添加 `_handleUnbindMessage()`: 解绑消息完整处理流程

2. `lib/services/relationship_animation_service.dart`
   - 添加控制器导入: `HomeController`, `MineController`, `LocationV2Controller`, `TrackController`
   - 修改 `showBindAnimation()`: 支持onComplete回调参数
   - 修改 `showUnbindAnimation()`: 支持onComplete回调参数
   - 添加 `refreshCurrentPage()`: 刷新所有已注册的页面控制器

3. `lib/widgets/relationship_animation_overlay.dart`
   - 添加 `duration` 参数: 支持自定义动画时长
   - 修改动画尺寸: 从固定300x300改为屏幕宽度的80%

4. `lib/main.dart`
   - 添加 `RelationshipAnimationService` 导入
   - 在步骤6.1.1注册 `RelationshipAnimationService`

### 资源文件（已存在）
- `assets/gif/bind_success.gif` - 绑定成功动画
- `assets/gif/unbind_success.gif` - 解绑成功动画

## 使用说明

### 自动触发
当收到包含 `msg_type` 的自定义IM消息时，系统会自动：
1. 检测消息类型
2. 显示对应的全屏GIF动画
3. 3秒后自动关闭

### 手动触发（测试用）
```dart
// 显示绑定动画
RelationshipAnimationService.instance.showBindAnimation();

// 显示解绑动画
RelationshipAnimationService.instance.showUnbindAnimation();
```

## 技术细节

### 动画控制
- **播放时长**: 3000ms（固定）
- **淡入时长**: 300ms
- **淡出时长**: 300ms
- **背景透明度**: 30%黑色遮罩
- **防重复播放**: 通过 `_isShowingAnimation` 标志位

### 错误处理
- JSON解析失败：记录错误日志，不影响其他消息
- 动画服务未初始化：记录警告，优雅降级
- GIF资源缺失：Flutter会显示占位图

### 日志标记
所有日志使用统一标签：
- `TencentIMService` - IM消息处理
- `RelationshipAnimationService` - 动画服务

## 测试建议

1. **功能测试**:
   - 发送bind类型自定义消息，验证绑定动画
   - 发送unbind类型自定义消息，验证解绑动画
   - 验证动画播放时长约3秒

2. **边界测试**:
   - 快速连续发送多条消息，验证防重复机制
   - 发送非bind/unbind类型消息，验证不触发动画
   - 发送格式错误的JSON，验证错误处理

3. **UI测试**:
   - 验证动画居中显示
   - 验证背景半透明效果
   - 验证淡入淡出效果流畅

## 注意事项

1. **服务初始化顺序**:
   - `RelationshipAnimationService` 必须在 `TencentIMService` 之后初始化
   - 确保在main.dart中正确注册

2. **资源文件**:
   - GIF文件必须放在 `assets/gif/` 目录
   - 文件名必须精确匹配：`bind_success.gif` 和 `unbind_success.gif`
   - pubspec.yaml中已包含 `assets/gif/` 配置

3. **性能考虑**:
   - GIF自动循环播放由Flutter处理
   - 通过定时器在3秒后关闭，避免无限播放
   - 使用Get.dialog的overlay机制，性能开销较小

## 未来改进方向

1. 支持自定义动画时长（从消息中读取）
2. 支持更多消息类型和动画
3. 添加音效配合动画播放
4. 支持用户手势关闭动画
5. 添加动画播放完成的全局回调

---

**版本**: 1.0  
**创建日期**: 2025-10-30  
**作者**: AI Assistant

