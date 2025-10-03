# 企业微信SDK集成文档

## 📦 SDK下载

### 方式1：从GitHub下载（推荐）
访问企业微信官方SDK仓库：
```
https://github.com/WecomTeam/MobileSDK
```

下载文件：`lib_wwapi-2.0.12.6.aar` (或最新版本)

### 方式2：直接下载链接
```
https://github.com/WecomTeam/MobileSDK/raw/master/Android/lib_wwapi-2.0.12.6.aar
```

### 安装步骤
1. 下载 `lib_wwapi-2.0.12.6.aar` 文件
2. 将文件放到项目目录：`android/libs/lib_wwapi-2.0.12.6.aar`
3. 完成！其他配置已自动完成

## ✅ 已完成的配置

### 1. Gradle依赖配置
文件：`android/app/build.gradle.kts`
```kotlin
dependencies {
    // 企业微信 SDK
    implementation(files("../libs/lib_wwapi-2.0.12.6.aar"))
    ...
}
```

### 2. AndroidManifest配置
文件：`android/app/src/main/AndroidManifest.xml`
```xml
<!-- 企业微信SDK Activity -->
<activity
    android:name="com.tencent.wework.api.WWAPIActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:theme="@android:style/Theme.Translucent.NoTitleBar">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
    </intent-filter>
</activity>
```

### 3. MainActivity实现
文件：`android/app/src/main/kotlin/com/yuluo/kissu/MainActivity.kt`

实现了多方案客服拉起策略：

#### 方案1：企业微信SDK（优先级最高）
如果用户安装了企业微信APP，使用官方SDK直接拉起客服会话
```kotlin
val wwApi = WWAPIFactory.createWWAPI(context)
wwApi.registerApp(wechatAppId)
wwApi.openUrl(kfidUrl)
```

#### 方案2：微信深链接（推荐）
通过微信deep link直接打开客服页面
```kotlin
weixin://dl/businessWebview?url=<encoded_kfid_url>
```

#### 方案3：微信应用内打开
直接用微信打开客服链接
```kotlin
Intent(ACTION_VIEW).apply {
    setPackage("com.tencent.mm")
    data = Uri.parse(kfidUrl)
}
```

#### 方案4：浏览器降级
最后降级到系统浏览器打开

## 🔧 配置信息

### 微信AppID
```
wxca15128b8c388c13
```
（已在AndroidManifest.xml中配置为meta-data: WECHAT_APP_ID）

### 客服链接
```
https://work.weixin.qq.com/kfid/kfcf77b8b4a2a2a61d9
```
（在 `lib/pages/mine/mine_controller.dart` 第281行）

## 📱 使用方法

### Flutter端调用
```dart
import 'package:kissu_app/utils/permission_helper.dart';

// 打开企业微信客服
const String kfidUrl = 'https://work.weixin.qq.com/kfid/kfcf77b8b4a2a2a61d9';
await PermissionHelper.openWeComKf(kfidUrl);
```

### 当前调用位置
- 文件：`lib/pages/mine/mine_controller.dart`
- 方法：`openContactChannel()`
- 行号：第277-284行

## 🔐 企业微信后台配置

### 必需配置项

1. **获取应用签名**
   - 下载签名生成工具：`Gen_Signature_Android.apk`
   - 安装到测试设备
   - 输入包名：`com.yuluo.kissu`
   - 获取签名字符串

2. **在企业微信管理后台配置**
   - 登录：https://work.weixin.qq.com/
   - 进入"应用管理"
   - 选择或创建应用
   - 填写：
     - 应用包名：`com.yuluo.kissu`
     - 应用签名：（从工具获取）
   - 获取Schema用于回调

3. **配置可信域名**
   - 在应用详情中配置可信域名
   - 建议添加：`ikissu.cn`、`ulink.ikissu.cn`

## 🧪 测试步骤

### 1. 编译运行
```bash
cd android
./gradlew assembleDebug
```

### 2. 安装APK到测试设备
```bash
flutter install
```

### 3. 测试场景

#### 场景A：已安装企业微信
1. 在APP中点击"联系客服"
2. 预期：直接拉起企业微信客服对话

#### 场景B：已安装微信（未安装企业微信）
1. 在APP中点击"联系客服"
2. 预期：通过微信深链接打开客服对话

#### 场景C：未安装微信和企业微信
1. 在APP中点击"联系客服"
2. 预期：使用浏览器打开客服页面

### 4. 查看日志
```bash
adb logcat | grep "MainActivity"
```

关键日志标签：
- `✅ 通过企业微信SDK拉起客服成功` - SDK调用成功
- `✅ 通过微信深链接拉起客服成功` - 深链接成功
- `⚠️ 降级到浏览器打开客服链接` - 降级到浏览器

## 🐛 常见问题

### Q1: 编译失败 - 找不到 lib_wwapi
**原因**：SDK文件未下载或路径错误

**解决**：
```bash
# 检查文件是否存在
ls -la android/libs/lib_wwapi-2.0.12.6.aar

# 如果不存在，从GitHub下载
curl -L -o android/libs/lib_wwapi-2.0.12.6.aar \
  https://github.com/WecomTeam/MobileSDK/raw/master/Android/lib_wwapi-2.0.12.6.aar
```

### Q2: 拉起失败，直接打开浏览器
**原因**：
1. 未安装微信/企业微信
2. 应用签名未在企业微信后台配置
3. 客服ID (kfid) 配置错误

**解决**：
1. 安装微信APP测试
2. 使用签名工具获取正确签名并在后台配置
3. 确认kfid链接正确

### Q3: ClassNotFoundException: com.tencent.wework.api.IWWAPI
**原因**：企业微信APP未安装，SDK类不存在

**说明**：这是正常现象，代码已做异常处理，会自动降级到其他方案

## 📊 集成方案对比

| 方案 | 优先级 | 优点 | 缺点 | 依赖条件 |
|------|--------|------|------|----------|
| 企业微信SDK | ⭐⭐⭐⭐⭐ | 最官方，功能完整 | 需要用户安装企业微信 | 企业微信APP + SDK |
| 微信深链接 | ⭐⭐⭐⭐ | 直接拉起微信，体验好 | 需要微信支持 | 微信APP |
| 应用内打开 | ⭐⭐⭐ | 简单可靠 | 可能被微信拦截 | 微信APP |
| 浏览器降级 | ⭐⭐ | 兜底方案，一定能打开 | 体验较差 | 无 |

## 🎯 推荐配置

当前实现已经是**最佳实践**：
- ✅ 多方案自动切换
- ✅ 优雅降级机制
- ✅ 详细日志输出
- ✅ 异常处理完善

只需下载SDK文件即可完成集成！

## 📝 更新日志

### 2025-10-03
- ✅ 集成企业微信SDK原生支持
- ✅ 实现多方案自动切换逻辑
- ✅ 配置AndroidManifest和Gradle
- ✅ 添加详细日志和异常处理

