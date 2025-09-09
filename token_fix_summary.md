# Token失效重复弹窗修复

## 问题描述
当账号被顶掉或token失效时，会出现重复弹窗提示，用户反馈会连续弹出5次提示。

## 解决方案

### 1. 在ApiResponseInterceptor中添加防重复机制

```dart
// 防重复弹窗机制
static bool _isHandlingUnauthorized = false;
static DateTime? _lastUnauthorizedTime;
```

### 2. 统一token失效处理入口

将所有token失效的处理统一到`_handleTokenExpired`方法：
- 检查是否正在处理中
- 检查距离上次处理时间（3秒内不重复处理）
- 只显示一次消息提示
- 只执行一次跳转登录页

### 3. 在登录页重置状态

在LoginController的onInit中调用`ApiResponseInterceptor.resetUnauthorizedState()`重置状态。

## 修改的文件

1. `lib/network/interceptor/api_response_interceptor.dart`
   - 添加防重复弹窗机制
   - 统一token失效处理逻辑
   - 添加状态重置方法

2. `lib/pages/login/login_controller.dart`
   - 在onInit中重置token失效处理状态

## 效果

- ✅ token失效时只会显示一次提示
- ✅ 只会执行一次跳转登录页操作
- ✅ 3秒内的重复请求会被忽略
- ✅ 进入登录页时会重置状态，避免状态残留