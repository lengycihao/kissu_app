# 自动退出登录问题分析

## 问题现象
用户偶尔会自动退出登录，被强制跳转到登录页面。

## 根本原因

### 1. Token 关键词匹配过于宽泛（⚠️ 高危）

**位置**: `lib/network/interceptor/api_response_interceptor.dart`

**问题**:
```dart
final tokenExpiredKeywords = [
  'token',  // ❌ 太宽泛！
  // ...
];
```

关键词 `'token'` 会匹配任何包含它的错误消息，例如：
- "Invalid token format" → 触发退出 ❌
- "Token parameter missing" → 触发退出 ❌

### 2. 防重复处理时间窗口太短

**位置**: `lib/network/interceptor/api_response_interceptor.dart`

```dart
// 3秒内不重复处理
if (now.difference(_lastUnauthorizedTime!) < const Duration(seconds: 3)) {
  return;
}
```

快速操作时，多个请求可能在 3 秒外触发多次退出。

---

## 解决方案

### 方案 1：移除宽泛的 token 关键词（优先级：⭐⭐⭐⭐⭐）

**修改**: `lib/network/interceptor/api_response_interceptor.dart`

```dart
final tokenExpiredKeywords = [
  // 'token',  // ❌ 移除这个！
  'token无效',
  'token过期',
  'token失效',
  'invalid token',
  'expired token',
  'token expired',
  'login expired',
  'session expired',
  '未授权',
  '登录失效',
  '登录过期',
  '请重新登录',
];
```

### 方案 2：延长防重复时间窗口（优先级：⭐⭐⭐⭐）

**修改**: `lib/network/interceptor/api_response_interceptor.dart`

```dart
// 3 秒 → 10 秒
if (_lastUnauthorizedTime != null && 
    now.difference(_lastUnauthorizedTime!) < const Duration(seconds: 10)) {
  return;
}
```

## 总结

优先修复方案 1（移除 `'token'` 关键词），这将解决大部分自动退出的问题。

