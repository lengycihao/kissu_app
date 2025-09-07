# Kissu App 认证系统使用指南

## 概述
本项目已实现完整的用户认证和数据管理系统，包括自动登录、token过期处理、用户数据缓存等功能。

## 已实现功能

### 1. 自动登录检测
- 应用启动时自动检测用户登录状态
- 已登录用户直接进入首页
- 未登录用户进入登录页面
- 实现文件：`lib/main.dart`

### 2. Token过期处理
- HTTP请求拦截器自动检测401响应
- 业务层面错误码检测（401, 1001, 1002, 10001, 403）
- 错误消息关键词检测（token、unauthorized、未授权等）
- 自动清除用户数据并跳转到登录页
- 实现文件：`lib/network/interceptor/api_response_interceptor.dart`

### 3. 用户数据缓存
- 使用FlutterSecureStorage安全存储用户信息
- 登录成功后自动缓存用户数据
- 提供便捷的用户数据访问接口
- 实现文件：`lib/network/public/auth_service.dart`

### 4. 全局用户数据访问
- UserManager工具类提供静态方法访问用户数据
- 包括用户ID、昵称、头像、VIP状态等
- 实现文件：`lib/utils/user_manager.dart`

### 5. 退出登录功能
- 调用/drop/out API
- 清除本地缓存数据
- 跳转到登录页面
- 带确认对话框的安全退出
- 实现文件：`lib/pages/mine/mine_controller.dart`

### 6. 验证码倒计时
- 30秒倒计时功能
- 防止重复发送验证码
- 实现文件：`lib/pages/login/login_controller.dart`

## 核心类说明

### AuthService
负责用户认证和数据管理的核心服务类。

主要方法：
- `loginWithCode()` - 验证码登录
- `logout()` - 退出登录
- `updateUserInfo()` - 更新用户信息
- `isLoggedIn` - 检查登录状态

### UserManager
提供全局用户数据访问的工具类。

主要属性：
- `isLoggedIn` - 是否已登录
- `userNickname` - 用户昵称
- `userAvatar` - 用户头像
- `isVip` - 是否VIP用户

### ApiResponseInterceptor
网络请求响应拦截器，处理token过期等情况。

主要功能：
- HTTP 401状态码检测
- 业务错误码检测
- 自动清除数据并跳转登录页

## 使用示例

### 检查登录状态
```dart
if (UserManager.isLoggedIn) {
  // 用户已登录
  String nickname = UserManager.userNickname ?? '用户';
}
```

### 获取用户信息
```dart
String? avatar = UserManager.userAvatar;
bool isVip = UserManager.isVip;
String? phone = UserManager.userPhone;
```

### 退出登录
```dart
final controller = Get.find<MineController>();
await controller.logout();
```

## 安全特性

1. **安全存储**：使用FlutterSecureStorage加密存储用户数据
2. **自动清理**：token过期时自动清除所有本地数据
3. **错误处理**：完善的异常处理和回退机制
4. **防重放**：验证码倒计时防止重复发送

## 初始化流程

应用启动时的初始化顺序：
1. 初始化服务定位器（GetIt）
2. 预加载用户数据
3. 初始化HTTP管理器
4. 根据登录状态确定初始路由

## 网络请求流程

1. 业务请求头自动添加（设备信息、签名等）
2. 请求发送
3. 响应拦截检查
4. Token过期自动处理
5. 返回统一格式数据

## 注意事项

1. 确保在使用UserManager前已初始化AuthService
2. 退出登录会清除所有本地数据
3. Token过期时会自动跳转到登录页，无需手动处理
4. 所有网络请求都会自动添加认证信息

## 扩展建议

1. 可根据实际业务需求调整token过期检测的错误码
2. 可添加token自动刷新机制
3. 可增加生物识别登录功能
4. 可添加多账户切换功能
