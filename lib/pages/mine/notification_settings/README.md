# 通知设置页面

## 📱 页面说明

通知设置页面用于管理用户的各类推送通知开关，包括位置轨迹、Kissu状态、手机状态和系统通知等。

## 🎨 UI设计

### 页面布局
- **背景**：使用 `assets/4.0/kissu4_new_use_bg.webp` 作为背景图
- **背景色**：`#F7F7F7`
- **模块间距**：16px

### 模块样式
- **容器**：白色背景，圆角12px，内边距16px
- **标题**：16pt，#333333，bold
- **内容第一行**：13pt，#333333
- **内容第二行**：11pt，#333333

### 开关样式
- **开关大小**：38×20
- **开启图标**：`assets/4.0/kissu4_setting_switch_open.webp`
- **关闭图标**：`assets/4.0/kissu4_setting_switch_close.webp`

## 📂 文件结构

```
notification_settings/
├── notification_settings_page.dart      # 页面UI
├── notification_settings_controller.dart # 控制器
├── notification_settings_binding.dart   # 依赖注入
└── README.md                            # 说明文档
```

## 🔧 功能模块

### 1. 位置轨迹
- ✅ 到达离开通知
- ✅ 停留时间通知
- ✅ 位置异常通知

### 2. Kissu
- ⭕ 账号状态通知（默认关闭）
- ✅ 更换手机通知
- ✅ 定位权限通知

### 3. 手机状态
- ✅ 电池状态通知
- ⭕ 网络状态通知（默认关闭）
- ⭕ 屏幕状态通知（默认关闭）

### 4. 系统通知
- ✅ 版本更新通知
- ✅ 活动推送通知
- ✅ 服务消息通知

## 🚀 使用方法

### 路由跳转
```dart
Get.toNamed(KissuRoutePath.notificationSettings);
```

### 在 mine_controller.dart 中添加入口
```dart
SettingItem(
  icon: "assets/4.0/kissu4_notice.webp",
  title: "通知设置",
  onTap: () => _onNotificationSettingsTap(),
),
```

## 📝 数据说明

### 当前状态
- ✅ 使用假数据（临时）
- ⏳ 接口对接（待开发）

### 数据模型
```dart
class NotificationItem {
  final String id;           // 唯一标识
  final String title;        // 标题
  final String description;  // 描述
  final bool isEnabled;      // 是否启用
}
```

## 🔌 接口对接（预留）

### 获取设置
```dart
Future<void> loadSettings() async {
  // TODO: 调用接口获取用户的通知设置
  // final settings = await NotificationApi.getSettings();
}
```

### 保存设置
```dart
Future<void> saveSettings() async {
  // TODO: 调用接口保存所有设置
  // await NotificationApi.saveSettings(settings);
}
```

### 切换开关
```dart
void toggleSwitch(NotificationItem item) {
  // 更新本地状态
  // TODO: 调用接口保存设置
  print('通知设置已更新: ${item.id} = ${item.isEnabled}');
}
```

## 🎯 待办事项

- [ ] 对接后端接口
- [ ] 实现设置持久化
- [ ] 添加加载状态
- [ ] 添加错误处理
- [ ] 添加埋点统计

## 📸 效果预览

页面效果参考设计图，包含：
- 顶部导航栏（返回按钮 + 标题）
- 4个通知模块
- 每个模块包含多个通知项
- 每个通知项有标题、描述和开关

## 🔗 相关文件

- 路由定义：`lib/routers/kissu_route_path.dart`
- 路由配置：`lib/routers/kissu_route.dart`
- 入口配置：`lib/pages/mine/mine_controller.dart`
