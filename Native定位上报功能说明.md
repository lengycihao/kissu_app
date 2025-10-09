# 🚀 Native 定位上报功能说明

## 📋 问题背景

**问题**：应用被杀掉后，Flutter 的定位上报逻辑停止工作，导致无法继续上报定位数据到服务器。

**原因**：
- 当用户从最近任务杀掉APP时，Flutter 引擎被销毁
- 所有 Dart 代码（包括定位上报逻辑）停止执行
- 前台服务虽然可以通过 `onTaskRemoved` 重启，但 Flutter 层的上报逻辑无法运行

**解决方案**：在 Native (Kotlin) 端实现定位上报功能，确保应用被杀后仍能继续上报定位。

---

## ✅ 已实现的功能

### 1️⃣ LocationReportService (Native 定位上报服务)

**文件路径**：`android/app/src/main/kotlin/com/yuluo/kissu/LocationReportService.kt`

**核心功能**：
- ✅ 接收高德定位数据
- ✅ 智能上报策略（首次立即上报 / 60秒定时上报 / 移动50米触发上报）
- ✅ 使用原生 HTTP 请求上报到服务器
- ✅ 从 SharedPreferences 读取用户 Token
- ✅ 支持保存/清除用户 Token 和 API 配置

**上报策略**：
```kotlin
1. 首次定位：立即上报
2. 定时上报：距离上次上报超过 60 秒
3. 距离触发：距离上次上报位置超过 50 米
```

**HTTP 请求**：
```kotlin
POST https://service-api.ikissu.cn/location/report
Headers:
  - Content-Type: application/json
  - token: <用户token>
  - version: <应用版本>
  - pkg: com.yuluo.kissu
  - os: 1 (Android)
  - model: <设备型号>
  - osversion: <Android版本>

Body:
{
  "locations": "[{\"longitude\":\"120.22\",\"latitude\":\"30.27\",\"location_time\":\"1696655000\",\"speed\":\"0.0\",\"altitude\":\"0.0\",\"accuracy\":\"50.0\",\"location_name\":\"浙江省杭州市上城区\"}]"
}
```

### 2️⃣ ForegroundLocationService (前台定位服务)

**文件路径**：`android/app/src/main/kotlin/com/yuluo/kissu/ForegroundLocationService.kt`

**新增功能**：
- ✅ 集成高德定位监听
- ✅ 启动/停止高德定位
- ✅ 定位成功后自动调用 `LocationReportService` 上报
- ✅ 应用被杀后通过 `onTaskRemoved` 自动重启（延迟2秒）

**高德定位配置**：
```kotlin
- 定位模式：Hight_Accuracy (高精度)
- 定位间隔：15秒
- 返回地址信息：是
- 允许模拟位置：否
- 持续定位：是
```

### 3️⃣ MainActivity (Token 管理)

**文件路径**：`android/app/src/main/kotlin/com/yuluo/kissu/MainActivity.kt`

**新增方法**：
- ✅ `saveUserToken` - 保存用户 Token 和 API 配置
- ✅ `clearUserToken` - 清除用户 Token

**MethodChannel 调用**：
```dart
// 保存 Token
await MethodChannel('kissu_app/foreground_service').invokeMethod('saveUserToken', {
  'token': 'user_token_here',
  'userId': '12345',
  'baseUrl': 'https://service-api.ikissu.cn',
});

// 清除 Token
await MethodChannel('kissu_app/foreground_service').invokeMethod('clearUserToken');
```

### 4️⃣ NativeLocationReportService (Flutter 封装)

**文件路径**：`lib/services/native_location_report_service.dart`

**核心功能**：
- ✅ 封装 MethodChannel 调用
- ✅ 自动从 AuthService 获取 Token 和用户信息
- ✅ 自动获取 API 基础 URL

**使用方法**：
```dart
// 保存 Token（登录成功后自动调用）
await NativeLocationReportService.saveUserToken();

// 清除 Token（登出时自动调用）
await NativeLocationReportService.clearUserToken();
```

### 5️⃣ AuthService (自动同步 Token)

**文件路径**：`lib/network/public/auth_service.dart`

**修改内容**：
- ✅ 登录成功后自动保存 Token 到 Native
- ✅ 登出时自动清除 Native 端的 Token

**自动调用流程**：
```dart
登录成功 → _handleLoginSuccess() → NativeLocationReportService.saveUserToken()
登出 → clearLocalUserData() → NativeLocationReportService.clearUserToken()
```

---

## 🔄 完整工作流程

### 应用正常运行时

```
1. 用户登录
   ↓
2. AuthService._handleLoginSuccess()
   ↓
3. NativeLocationReportService.saveUserToken()
   ↓
4. Token 保存到 SharedPreferences
   ↓
5. 启动前台定位服务
   ↓
6. ForegroundLocationService 启动高德定位
   ↓
7. 高德定位回调 onLocationChanged()
   ↓
8. LocationReportService.reportLocation()
   ↓
9. 检查上报策略（首次/60秒/50米）
   ↓
10. 发送 HTTP 请求到服务器
   ↓
11. 服务器响应成功
   ↓
12. 更新最后上报时间和位置
```

### 应用被杀后

```
1. 用户从最近任务杀掉APP
   ↓
2. ForegroundLocationService.onTaskRemoved() 被调用
   ↓
3. 检查 location_service_enabled 标志
   ↓
4. 使用 AlarmManager 设置2秒后重启服务
   ↓
5. 2秒后，系统自动重启 ForegroundLocationService
   ↓
6. 服务启动 → onCreate() → 初始化高德定位
   ↓
7. startLocationForegroundService() → 启动高德定位
   ↓
8. 高德定位回调 onLocationChanged()
   ↓
9. LocationReportService.reportLocation()
   ↓
10. 从 SharedPreferences 读取 Token
   ↓
11. 发送 HTTP 请求到服务器 ✅
   ↓
12. 继续上报定位数据！
```

---

## 🧪 测试步骤

### 步骤1：登录并启动定位

1. 打开 Kissu APP
2. 登录账号
3. 确保定位服务已启动
4. 通知栏显示 "Kissu - 情侣定位"

### 步骤2：检查 Token 是否保存

使用 `adb logcat` 查看日志：

```bash
adb logcat | grep -E "(AuthService|LocationReportService|MainActivity)"
```

**预期日志**：
```
I/flutter: 登录成功
D/MainActivity: 用户Token和API配置已保存: userId=12345, baseUrl=https://service-api.ikissu.cn
D/LocationReportService: ✅ 用户Token已保存: 12345
```

### 步骤3：检查定位是否启动

**预期日志**：
```
D/ForegroundLocationService: 前台定位服务创建
D/ForegroundLocationService: 高德定位客户端创建成功
D/ForegroundLocationService: 🚀 高德定位已启动：高精度模式 / 15秒间隔
```

### 步骤4：检查定位是否上报

**预期日志**：
```
D/ForegroundLocationService: 📍 定位成功: 经度=120.22, 纬度=30.27, 精度=50.0m
D/ForegroundLocationService: 📍 定位地址: 浙江省杭州市上城区运河东路149-151号
D/ForegroundLocationService: 📍 定位类型: Wifi定位
D/LocationReportService: 🚀 首次定位，立即上报
D/LocationReportService: 🚀 开始上报定位数据
D/LocationReportService: 📡 API地址: https://service-api.ikissu.cn/location/report
D/LocationReportService: 📡 HTTP响应码: 200
D/LocationReportService: ✅ 定位上报成功: 30.275756, 120.220316
```

### 步骤5：杀掉APP

1. 按 Home 键，将应用切换到后台
2. 打开最近任务列表
3. 向上滑动，杀掉 Kissu APP

**预期日志**：
```
D/ForegroundLocationService: ⚠️ 应用任务被移除（用户杀掉APP）
D/ForegroundLocationService: 🔄 应用被杀掉，但定位服务应保持运行，准备重启服务...
D/ForegroundLocationService: ✅ 已设置2秒后自动重启定位服务
D/ForegroundLocationService: 前台定位服务销毁
```

### 步骤6：等待2-3秒，观察服务是否重启

**预期日志**：
```
... 2秒后 ...

D/ForegroundLocationService: 前台定位服务创建
D/ForegroundLocationService: WakeLock 创建成功
D/ForegroundLocationService: 定位上报服务创建成功
D/ForegroundLocationService: 高德定位客户端创建成功
D/ForegroundLocationService: 🚀 高德定位已启动：高精度模式 / 15秒间隔
D/ForegroundLocationService: 前台定位服务启动成功
```

### 步骤7：等待定位上报

**预期日志**：
```
... 15秒后（第一次定位）...

D/ForegroundLocationService: 📍 定位成功: 经度=120.22, 纬度=30.27, 精度=50.0m
D/LocationReportService: 🚀 首次定位，立即上报
D/LocationReportService: 📡 HTTP响应码: 200
D/LocationReportService: ✅ 定位上报成功: 30.275756, 120.220316

... 60秒后（定时上报）...

D/ForegroundLocationService: 📍 定位成功: 经度=120.22, 纬度=30.27, 精度=48.0m
D/LocationReportService: ⏰ 时间触发上报: 距离上次上报60秒
D/LocationReportService: 📡 HTTP响应码: 200
D/LocationReportService: ✅ 定位上报成功: 30.275756, 120.220316
```

### 步骤8：验证通知是否显示

- 通知栏应该持续显示 "Kissu - 情侣定位"
- 点击通知可以打开应用

---

## ⚠️ 注意事项

### 1. 华为/荣耀手机

**问题**：华为手机可能阻止应用被杀后自动重启

**解决方案**：
1. 开启自启动权限
   - 设置 → 应用启动管理 → Kissu → 允许自启动
   
2. 禁用电池优化
   - 设置 → 电池 → 应用启动管理 → Kissu → 手动管理
   - 开启：允许后台活动、允许自启动、允许关联启动

3. 开启通知权限
   - 设置 → 通知 → Kissu → 允许通知

### 2. Android 12+

**问题**：Android 12 引入了更严格的后台启动限制

**解决方案**：
- 已使用 `AlarmManager.setExactAndAllowWhileIdle` 确保在 Doze 模式下也能重启
- 如果仍然无法重启，可能需要引导用户禁用电池优化

### 3. Token 过期

**问题**：如果用户 Token 过期，Native 端无法刷新 Token

**解决方案**：
- 当服务器返回 401 (Token 过期) 时，停止上报
- 等待用户重新打开应用，刷新 Token
- 用户重新登录后，Token 会自动同步到 Native

### 4. 网络请求失败

**问题**：网络不稳定时，上报可能失败

**解决方案**：
- 当前版本：失败后不重试，等待下次定位
- 未来优化：可以考虑实现本地缓存 + 重试机制

---

## 📊 数据流图

```
┌─────────────────────────────────────────────────────────────────┐
│                         Flutter 层                               │
├─────────────────────────────────────────────────────────────────┤
│  1. 用户登录 (AuthService)                                        │
│     ↓                                                            │
│  2. 保存用户信息                                                  │
│     ↓                                                            │
│  3. 调用 NativeLocationReportService.saveUserToken()            │
└─────────────────────────┬───────────────────────────────────────┘
                          │ MethodChannel
                          ↓
┌─────────────────────────────────────────────────────────────────┐
│                         Native 层                                │
├─────────────────────────────────────────────────────────────────┤
│  4. MainActivity.saveUserToken()                                │
│     ↓                                                            │
│  5. LocationReportService.saveUserToken()                       │
│     ↓                                                            │
│  6. 保存到 SharedPreferences                                      │
│     - user_token                                                 │
│     - user_id                                                    │
│     - base_api_url                                               │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ↓
┌─────────────────────────────────────────────────────────────────┐
│                   ForegroundLocationService                      │
├─────────────────────────────────────────────────────────────────┤
│  7. 启动高德定位                                                   │
│     ↓                                                            │
│  8. 定位回调 onLocationChanged()                                  │
│     ↓                                                            │
│  9. LocationReportService.reportLocation()                      │
│     ↓                                                            │
│  10. 检查上报策略                                                  │
│      - 首次定位？                                                  │
│      - 距离上次 ≥ 60秒？                                           │
│      - 距离上次 ≥ 50米？                                           │
│     ↓                                                            │
│  11. 从 SharedPreferences 读取 Token                              │
│     ↓                                                            │
│  12. 构建 HTTP 请求                                                │
│     ↓                                                            │
│  13. 发送到服务器                                                  │
└─────────────────────────┬───────────────────────────────────────┘
                          │ HTTP POST
                          ↓
┌─────────────────────────────────────────────────────────────────┐
│                         服务器                                    │
├─────────────────────────────────────────────────────────────────┤
│  POST /location/report                                          │
│  {                                                               │
│    "locations": "[{...}]"                                        │
│  }                                                               │
│     ↓                                                            │
│  返回 {"code": 200, "msg": "success"}                            │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🎯 总结

✅ **已实现**：
1. Native 端定位上报服务
2. 应用被杀后自动重启前台服务
3. 应用被杀后继续上报定位数据
4. 智能上报策略（首次/定时/距离触发）
5. 自动同步用户 Token 到 Native
6. 登录/登出时自动管理 Token

⚠️ **需要注意**：
1. 华为/荣耀手机需要用户手动开启自启动权限
2. Android 12+ 可能需要禁用电池优化
3. Token 过期需要用户重新登录
4. 网络不稳定时可能上报失败（未实现重试）

🚀 **后续优化方向**：
1. 实现上报失败重试机制
2. 添加本地缓存队列
3. 支持批量上报
4. 添加上报状态监控
5. 使用 WorkManager 替代 AlarmManager（更稳定）

---

**祝顺利！** 🎉















