# MainActivity 重构说明

## 概述
原 `MainActivity.kt` 文件有 2483 行代码，包含了所有功能的实现，难以维护。现已将其拆分为多个独立的 Handler 类，每个类负责特定的功能模块。

## 文件结构

```
handlers/
├── PaymentHandler.kt              # 支付处理器（微信、支付宝）
├── ShareHandler.kt                # 分享处理器（友盟分享）
├── AppUsageHandler.kt             # 应用使用统计处理器
├── LocationHandler.kt             # 定位和GPS处理器
├── AppInfoHandler.kt              # 应用信息处理器
├── SystemHandler.kt               # 系统功能处理器（屏幕锁定、白名单）
├── AnalyticsHandler.kt            # 友盟统计处理器
├── ForegroundServiceHandler.kt    # 前台服务处理器
└── README.md                      # 本文件
```

## 各模块功能说明

### 1. PaymentHandler（支付处理器）
**文件**: `PaymentHandler.kt`  
**功能**:
- 微信支付
- 支付宝支付
- 支付结果回调处理
- 支付超时管理

**主要方法**:
- `initialize()` - 初始化微信API和支付结果广播接收器
- `handleMethodCall()` - 处理Flutter端的支付方法调用
- `onWechatPayResp()` - 处理微信支付回调

### 2. ShareHandler（分享处理器）
**文件**: `ShareHandler.kt`  
**功能**:
- 分享到微信/朋友圈
- 分享到QQ/QQ空间
- 友盟分享SDK集成

**主要方法**:
- `handleMethodCall()` - 处理分享方法调用
- `shareToWechat()` - 分享到微信
- `shareToQQ()` - 分享到QQ
- `onActivityResult()` - 处理分享回调

### 3. AppUsageHandler（应用使用统计处理器）
**文件**: `AppUsageHandler.kt`  
**功能**:
- 获取已安装应用列表（兼容各种图标类型）
- 获取应用使用时长
- 获取详细使用数据（每小时统计、会话记录）
- 批量获取使用数据

**主要方法**:
- `getInstalledApps()` - 获取应用列表
- `getDetailedUsageData()` - 获取详细使用数据
- `cleanupSessions()` - 清理和合并会话数据
- `buildHourlyRecords()` - 构建每小时统计记录

**重要修复**:
- ✅ 兼容 `AdaptiveIconDrawable`、`VectorDrawable` 等各种图标类型
- ✅ 解决小米手机应用列表显示不全的问题

### 4. LocationHandler（定位和GPS处理器）
**文件**: `LocationHandler.kt`  
**功能**:
- GPS状态监听
- 打开定位设置页面
- GPS状态事件流

**主要方法**:
- `initialize()` - 初始化GPS状态监听
- `isGpsEnabled()` - 检查GPS是否开启
- `openLocationSettings()` - 打开定位设置

### 5. AppInfoHandler（应用信息处理器）
**文件**: `AppInfoHandler.kt`  
**功能**:
- 获取应用名称
- 批量获取应用名称
- 切换应用图标

**主要方法**:
- `getAppName()` - 获取单个应用名称
- `getAppNames()` - 批量获取应用名称
- `changeAppIcon()` - 切换应用图标

### 6. SystemHandler（系统功能处理器）
**文件**: `SystemHandler.kt`  
**功能**:
- 屏幕锁定/解锁监听
- 设备白名单引导
- SHA1签名打印

**主要方法**:
- `initialize()` - 初始化屏幕锁定监听
- `handleWhitelistCall()` - 处理白名单相关调用
- `printSHA1()` - 打印应用签名

### 7. AnalyticsHandler（友盟统计处理器）
**文件**: `AnalyticsHandler.kt`  
**功能**:
- 友盟事件上报
- 页面统计
- 用户画像设置

**主要方法**:
- `handleMethodCall()` - 处理统计方法调用
- `onResume()` / `onPause()` - Activity生命周期回调

### 8. ForegroundServiceHandler（前台服务处理器）
**文件**: `ForegroundServiceHandler.kt`  
**功能**:
- 启动前台定位服务
- 停止前台服务
- 更新通知内容

**主要方法**:
- `startForegroundService()` - 启动前台服务
- `stopForegroundService()` - 停止前台服务
- `updateNotification()` - 更新通知

## 使用方式

### 在 MainActivity 中使用

```kotlin
class MainActivity : FlutterActivity(), IWXAPIEventHandler {
    
    // 声明处理器
    private lateinit var paymentHandler: PaymentHandler
    private lateinit var shareHandler: ShareHandler
    // ... 其他处理器
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 初始化处理器
        paymentHandler = PaymentHandler(this)
        shareHandler = ShareHandler(this)
        // ... 初始化其他处理器
        
        // 初始化需要初始化的处理器
        paymentHandler.initialize()
        
        // 注册通道
        MethodChannel(messenger, PAYMENT_CHANNEL).setMethodCallHandler { call, result ->
            paymentHandler.handleMethodCall(call, result)
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        // 清理资源
        paymentHandler.cleanup()
    }
}
```

## 迁移步骤

1. **备份原文件**
   ```bash
   cp MainActivity.kt MainActivity_Backup.kt
   ```

2. **替换 MainActivity**
   - 将 `MainActivity_Refactored.kt` 重命名为 `MainActivity.kt`
   - 或者直接修改现有的 `MainActivity.kt`，参考 `MainActivity_Refactored.kt` 的结构

3. **测试功能**
   - 测试支付功能（微信、支付宝）
   - 测试分享功能
   - 测试应用使用统计
   - 测试定位和GPS功能
   - 测试其他所有功能

4. **删除备份**（确认无问题后）
   ```bash
   rm MainActivity_Backup.kt
   ```

## 优势

### ✅ 代码组织
- 每个Handler只负责单一功能模块
- 代码更易于理解和维护
- 降低代码耦合度

### ✅ 可测试性
- 每个Handler可以独立测试
- 便于编写单元测试

### ✅ 可扩展性
- 添加新功能只需创建新的Handler
- 不影响现有代码

### ✅ 团队协作
- 多人可以同时开发不同的Handler
- 减少代码冲突

## 注意事项

1. **生命周期管理**
   - 需要在 `MainActivity` 的 `onCreate`、`onDestroy` 等生命周期方法中调用对应Handler的方法

2. **资源清理**
   - 每个Handler的 `cleanup()` 方法必须在 `onDestroy` 中调用

3. **权限检查**
   - 某些Handler需要特定权限，确保在 `AndroidManifest.xml` 中已声明

4. **线程安全**
   - 涉及异步操作的Handler需要注意线程安全

## 后续优化建议

1. **依赖注入**
   - 可以考虑使用 Dagger/Hilt 进行依赖注入

2. **接口抽象**
   - 为Handler定义统一的接口，便于管理

3. **错误处理**
   - 统一错误处理机制

4. **日志管理**
   - 统一日志输出格式

## 版本历史

- **v1.0** (2025-11-26)
  - 初始版本
  - 拆分 MainActivity 为 8 个独立的 Handler
  - 修复小米手机应用列表显示不全的问题
