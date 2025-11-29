# MainActivity 重构迁移指南

## 📋 概述

原 `MainActivity.kt` 文件有 **2483 行**代码，现已重构为模块化架构，拆分成 8 个独立的 Handler 类。

## 📁 新文件结构

```
android/app/src/main/kotlin/com/yuluo/kissu/
├── MainActivity.kt                          # 主Activity（保留）
├── MainActivity_Refactored.kt               # 重构后的参考实现
└── handlers/                                # 新增：Handler目录
    ├── PaymentHandler.kt                    # 支付处理器
    ├── ShareHandler.kt                      # 分享处理器
    ├── AppUsageHandler.kt                   # 应用使用统计
    ├── LocationHandler.kt                   # 定位GPS
    ├── AppInfoHandler.kt                    # 应用信息
    ├── SystemHandler.kt                     # 系统功能
    ├── AnalyticsHandler.kt                  # 友盟统计
    ├── ForegroundServiceHandler.kt          # 前台服务
    └── README.md                            # Handler说明文档
```

## 🚀 快速开始

### 方案一：直接替换（推荐用于新项目）

```bash
# 1. 备份原文件
cd android/app/src/main/kotlin/com/yuluo/kissu/
cp MainActivity.kt MainActivity_Backup.kt

# 2. 替换为重构版本
mv MainActivity_Refactored.kt MainActivity.kt

# 3. 编译测试
cd ../../../../../../..
flutter clean
flutter build apk --debug
```

### 方案二：渐进式迁移（推荐用于生产项目）

保留原 `MainActivity.kt`，逐步将功能迁移到 Handler 中。

## 📝 详细迁移步骤

### Step 1: 创建 Handler 目录

所有 Handler 文件已创建在 `handlers/` 目录下。

### Step 2: 修改 MainActivity

在现有的 `MainActivity.kt` 中添加 Handler 引用：

```kotlin
import com.yuluo.kissu.handlers.*

class MainActivity : FlutterActivity(), IWXAPIEventHandler {
    
    // 添加 Handler 实例
    private lateinit var paymentHandler: PaymentHandler
    private lateinit var shareHandler: ShareHandler
    private lateinit var appUsageHandler: AppUsageHandler
    private lateinit var locationHandler: LocationHandler
    private lateinit var appInfoHandler: AppInfoHandler
    private lateinit var systemHandler: SystemHandler
    private lateinit var analyticsHandler: AnalyticsHandler
    private lateinit var foregroundServiceHandler: ForegroundServiceHandler
    
    // ... 其余代码
}
```

### Step 3: 初始化 Handler

在 `configureFlutterEngine` 方法中初始化：

```kotlin
override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    
    // 初始化所有 Handler
    paymentHandler = PaymentHandler(this)
    shareHandler = ShareHandler(this)
    appUsageHandler = AppUsageHandler(this)
    locationHandler = LocationHandler(this)
    appInfoHandler = AppInfoHandler(this)
    systemHandler = SystemHandler(this)
    analyticsHandler = AnalyticsHandler(this)
    foregroundServiceHandler = ForegroundServiceHandler(this)
    
    // 初始化需要初始化的 Handler
    paymentHandler.initialize()
    locationHandler.initialize(EventChannel(flutterEngine.dartExecutor.binaryMessenger, GPS_STATUS_CHANNEL))
    systemHandler.initialize(EventChannel(flutterEngine.dartExecutor.binaryMessenger, SCREEN_LOCK_CHANNEL))
    
    // 注册通道（见下一步）
}
```

### Step 4: 替换通道处理逻辑

将原来的 `MethodChannel` 处理逻辑替换为 Handler 调用：

**原代码**:
```kotlin
MethodChannel(messenger, PAYMENT_CHANNEL).setMethodCallHandler { call, result ->
    when (call.method) {
        "isWechatInstalled" -> {
            result.success(isWechatAppInstalled())
        }
        "payWithWechat" -> {
            // ... 大量代码
        }
        // ... 更多方法
    }
}
```

**新代码**:
```kotlin
MethodChannel(messenger, PAYMENT_CHANNEL).setMethodCallHandler { call, result ->
    paymentHandler.handleMethodCall(call, result)
}
```

### Step 5: 更新生命周期方法

```kotlin
override fun onResume() {
    super.onResume()
    analyticsHandler.onResume()
}

override fun onPause() {
    super.onPause()
    analyticsHandler.onPause()
}

override fun onDestroy() {
    super.onDestroy()
    
    // 清理所有 Handler
    paymentHandler.cleanup()
    locationHandler.cleanup()
    systemHandler.cleanup()
}

override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
    super.onActivityResult(requestCode, resultCode, data)
    shareHandler.onActivityResult(requestCode, resultCode, data)
    paymentHandler.wxApi?.handleIntent(data, this)
}
```

### Step 6: 更新微信支付回调

```kotlin
override fun onResp(resp: BaseResp?) {
    paymentHandler.onWechatPayResp(resp)
}
```

### Step 7: 删除旧代码

逐步删除 `MainActivity.kt` 中已迁移到 Handler 的代码：

- ❌ 删除 `payWithWechat()` 方法
- ❌ 删除 `payWithAlipay()` 方法
- ❌ 删除 `getInstalledApps()` 方法
- ❌ 删除 `shareToWechat()` 方法
- ❌ 删除所有已迁移的私有方法

## ✅ 测试清单

迁移完成后，请测试以下功能：

### 支付功能
- [ ] 微信支付
- [ ] 支付宝支付
- [ ] 支付取消
- [ ] 支付超时

### 分享功能
- [ ] 分享到微信
- [ ] 分享到朋友圈
- [ ] 分享到QQ
- [ ] 分享到QQ空间

### 应用使用统计
- [ ] 获取应用列表（特别测试小米手机）
- [ ] 获取应用使用时长
- [ ] 获取详细使用数据
- [ ] 批量获取使用数据

### 定位功能
- [ ] GPS状态监听
- [ ] 打开定位设置
- [ ] GPS状态变化通知

### 应用信息
- [ ] 获取应用名称
- [ ] 批量获取应用名称
- [ ] 切换应用图标

### 系统功能
- [ ] 屏幕锁定监听
- [ ] 设备白名单引导
- [ ] 打开白名单设置

### 友盟统计
- [ ] 事件上报
- [ ] 页面统计
- [ ] 用户画像

### 前台服务
- [ ] 启动前台服务
- [ ] 停止前台服务
- [ ] 更新通知

## 🐛 常见问题

### Q1: 编译错误 "Unresolved reference: handlers"

**解决方案**: 确保 `handlers` 包已正确创建，并且所有 Handler 文件都在正确的包路径下。

```kotlin
// 检查 import 语句
import com.yuluo.kissu.handlers.*
```

### Q2: 小米手机应用列表显示不全

**解决方案**: 已在 `AppUsageHandler` 中修复，兼容了 `AdaptiveIconDrawable` 等图标类型。

```kotlin
// 新代码已兼容各种图标类型
val bitmap = when (iconDrawable) {
    is BitmapDrawable -> iconDrawable.bitmap
    else -> {
        // 手动绘制为 Bitmap
    }
}
```

### Q3: 支付回调不工作

**解决方案**: 确保在 `onActivityResult` 和 `onResp` 中调用了 Handler 的方法。

```kotlin
override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
    super.onActivityResult(requestCode, resultCode, data)
    paymentHandler.wxApi?.handleIntent(data, this)
}

override fun onResp(resp: BaseResp?) {
    paymentHandler.onWechatPayResp(resp)
}
```

### Q4: GPS状态监听不工作

**解决方案**: 确保在 `configureFlutterEngine` 中初始化了 `LocationHandler`。

```kotlin
locationHandler.initialize(
    EventChannel(flutterEngine.dartExecutor.binaryMessenger, GPS_STATUS_CHANNEL)
)
```

## 📊 代码统计

### 重构前
- **MainActivity.kt**: 2483 行
- **单文件包含所有功能**

### 重构后
- **MainActivity.kt**: ~300 行（减少 88%）
- **PaymentHandler.kt**: ~350 行
- **ShareHandler.kt**: ~200 行
- **AppUsageHandler.kt**: ~400 行
- **LocationHandler.kt**: ~150 行
- **AppInfoHandler.kt**: ~120 行
- **SystemHandler.kt**: ~180 行
- **AnalyticsHandler.kt**: ~100 行
- **ForegroundServiceHandler.kt**: ~150 行

**总计**: ~2050 行（分布在 9 个文件中）

## 🎯 优势总结

### 1. 可维护性 ⬆️
- 每个 Handler 只负责单一功能
- 代码结构清晰，易于理解

### 2. 可测试性 ⬆️
- 每个 Handler 可以独立测试
- 便于编写单元测试

### 3. 可扩展性 ⬆️
- 添加新功能只需创建新的 Handler
- 不影响现有代码

### 4. 团队协作 ⬆️
- 多人可以同时开发不同的 Handler
- 减少代码冲突

### 5. Bug修复 ⬆️
- 问题定位更快
- 修复范围更小

## 📚 参考文档

- [Handler 详细说明](app/src/main/kotlin/com/yuluo/kissu/handlers/README.md)
- [MainActivity 重构参考](app/src/main/kotlin/com/yuluo/kissu/MainActivity_Refactored.kt)

## 💡 最佳实践

1. **逐步迁移**: 不要一次性替换所有代码，先迁移一个模块，测试通过后再迁移下一个
2. **保留备份**: 迁移过程中保留原文件的备份
3. **充分测试**: 每迁移一个模块都要进行完整测试
4. **代码审查**: 迁移完成后进行代码审查
5. **文档更新**: 及时更新相关文档

## 🔄 回滚方案

如果迁移后出现问题，可以快速回滚：

```bash
# 恢复备份
cp MainActivity_Backup.kt MainActivity.kt

# 删除 handlers 目录（可选）
rm -rf handlers/

# 重新编译
flutter clean
flutter build apk --debug
```

## ✨ 下一步

重构完成后，可以考虑：

1. **添加单元测试**: 为每个 Handler 编写单元测试
2. **依赖注入**: 使用 Dagger/Hilt 进行依赖注入
3. **接口抽象**: 为 Handler 定义统一接口
4. **错误处理**: 统一错误处理机制
5. **日志管理**: 统一日志输出格式

---

**祝重构顺利！** 🎉

如有问题，请参考 `handlers/README.md` 或查看 `MainActivity_Refactored.kt` 示例代码。
