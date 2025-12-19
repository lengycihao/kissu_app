# 腾讯云IM厂商通道配置指南

## 概述

腾讯云IM支持多种Android厂商推送通道，包括：
- **小米推送**（Mi Push）
- **华为推送**（HMS Push）
- **OPPO推送**（OPush）
- **vivo推送**（vivo Push）
- **魅族推送**（Flyme Push）
- **荣耀推送**（Honor Push）
- **FCM推送**（Firebase Cloud Messaging，作为兜底）

**重要**：厂商通道需要在**腾讯云IM控制台**配置，代码中不需要额外配置。腾讯云IM SDK会自动根据设备品牌选择合适的推送通道。

## 配置步骤

### 1. 登录腾讯云IM控制台

1. 访问 [腾讯云IM控制台](https://console.cloud.tencent.com/im)
2. 选择您的应用（SDKAppID: 1600095370）
3. 进入 **"应用配置"** -> **"离线推送配置"**

### 2. 配置各厂商推送通道

#### 2.1 小米推送（Mi Push）

**获取参数**：
1. 访问 [小米开放平台](https://dev.mi.com/console/)
2. 创建应用并获取：
   - **AppID**
   - **AppKey**
   - **AppSecret**

**在腾讯云IM控制台配置**：
- 填写小米推送的 AppID、AppKey、AppSecret
- 保存配置

#### 2.2 华为推送（HMS Push）

**获取参数**：
1. 访问 [华为开发者联盟](https://developer.huawei.com/consumer/cn/)
2. 创建应用并获取：
   - **AppID**
   - **AppSecret**
3. 下载 `agconnect-services.json` 文件（需要配置到Android项目中）

**在腾讯云IM控制台配置**：
- 填写华为推送的 AppID、AppSecret
- 保存配置

**Android项目配置**（额外步骤）：
- 将 `agconnect-services.json` 文件放到 `android/app/` 目录下
- 在 `android/app/build.gradle` 中添加：
  ```gradle
  dependencies {
      // 华为推送依赖
      implementation 'com.huawei.hms:push:6.x.x'
  }
  ```

#### 2.3 OPPO推送（OPush）

**获取参数**：
1. 访问 [OPPO开放平台](https://open.oppomobile.com/)
2. 创建应用并获取：
   - **AppKey**
   - **MasterSecret**

**在腾讯云IM控制台配置**：
- 填写OPPO推送的 AppKey、MasterSecret
- 保存配置

#### 2.4 vivo推送（vivo Push）

**获取参数**：
1. 访问 [vivo开放平台](https://dev.vivo.com.cn/)
2. 创建应用并获取：
   - **AppID**
   - **AppKey**
   - **AppSecret**

**在腾讯云IM控制台配置**：
- 填写vivo推送的 AppID、AppKey、AppSecret
- 保存配置

#### 2.5 魅族推送（Flyme Push）

**获取参数**：
1. 访问 [魅族开放平台](https://open.flyme.cn/)
2. 创建应用并获取：
   - **AppID**
   - **AppSecret**

**在腾讯云IM控制台配置**：
- 填写魅族推送的 AppID、AppSecret
- 保存配置

#### 2.6 FCM推送（Firebase Cloud Messaging）

**获取参数**：
1. 访问 [Firebase控制台](https://console.firebase.google.com/)
2. 创建项目并添加Android应用
3. 下载 `google-services.json` 文件
4. 获取 **Server Key**（在项目设置 -> 云消息传递中）

**在腾讯云IM控制台配置**：
- 填写FCM的 Server Key
- 保存配置

**Android项目配置**（额外步骤）：
- 将 `google-services.json` 文件放到 `android/app/` 目录下
- 在 `android/app/build.gradle` 中添加：
  ```gradle
  dependencies {
      // Google Services插件
      classpath 'com.google.gms:google-services:4.4.0'
  }
  
  // 在文件末尾添加
  apply plugin: 'com.google.gms.google-services'
  ```

## 推送通道优先级

腾讯云IM SDK会自动根据设备品牌选择推送通道，优先级如下：

1. **厂商通道**（如果已配置且设备支持）：
   - 小米设备 → 小米推送
   - 华为设备 → 华为推送
   - OPPO设备 → OPPO推送
   - vivo设备 → vivo推送
   - 魅族设备 → 魅族推送
   - 荣耀设备 → 荣耀推送

2. **FCM通道**（如果已配置）：
   - 作为厂商通道的兜底方案

3. **本机通道**：
   - 如果以上通道都不可用，使用本机通道（需要App在后台运行）

## 代码配置

**好消息**：腾讯云IM的厂商通道配置**完全在控制台完成**，代码中不需要额外配置！

当前代码已经支持：
- ✅ 推送服务注册（`_registerPushService()`）
- ✅ 推送通知点击处理（`_handlePushNotificationClick()`）
- ✅ 自动选择推送通道（由腾讯云IM SDK自动处理）

**只需要配置 `appKey`**：
```dart
// lib/services/tencent_im_service.dart 第1383行
const String? appKey = "your_app_key_here"; // 从腾讯云IM控制台获取
```

## 推荐配置顺序

1. **优先配置厂商通道**（按用户占比）：
   - 小米、华为、OPPO、vivo（覆盖大部分用户）
   - 魅族、荣耀（覆盖小众用户）

2. **配置FCM通道**（作为兜底）：
   - 适用于非厂商设备或厂商通道不可用时

3. **本机通道**（自动兜底）：
   - 无需配置，SDK自动使用

## 测试验证

配置完成后，测试步骤：

1. **配置appKey**：
   - 在代码中配置从控制台获取的 `appKey`

2. **重新编译运行**：
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

3. **测试推送**：
   - 将App切换到后台或完全关闭
   - 让其他用户发送消息
   - 检查是否能收到推送通知

4. **查看日志**：
   - 搜索 "推送服务注册成功（Android平台）"
   - 确认推送注册成功

5. **测试不同设备**：
   - 在不同品牌的Android设备上测试
   - 确认推送能正常到达

## 常见问题

### Q1: 为什么我的设备收不到推送？

**检查清单**：
1. ✅ `appKey` 是否已配置
2. ✅ 腾讯云IM控制台是否已配置对应厂商的推送通道
3. ✅ 设备是否已授予通知权限
4. ✅ 设备网络是否正常
5. ✅ 查看日志确认推送注册是否成功

### Q2: 需要配置所有厂商通道吗？

**不需要**。建议按用户占比配置：
- **必须配置**：小米、华为、OPPO、vivo（覆盖80%+用户）
- **建议配置**：FCM（作为兜底）
- **可选配置**：魅族、荣耀（如果用户中有这些设备）

### Q3: 华为推送需要额外配置吗？

**是的**。华为推送需要：
1. 在腾讯云IM控制台配置华为推送参数
2. 下载 `agconnect-services.json` 文件
3. 将文件放到 `android/app/` 目录
4. 在 `build.gradle` 中添加华为推送依赖

### Q4: FCM推送需要额外配置吗？

**是的**。FCM推送需要：
1. 在腾讯云IM控制台配置FCM Server Key
2. 下载 `google-services.json` 文件
3. 将文件放到 `android/app/` 目录
4. 在 `build.gradle` 中添加Google Services插件

### Q5: 代码中需要指定使用哪个通道吗？

**不需要**。腾讯云IM SDK会自动根据设备品牌选择最合适的推送通道，无需在代码中指定。

## 参考文档

- 腾讯云IM离线推送文档：https://cloud.tencent.com/document/product/269/44516
- 小米推送文档：https://dev.mi.com/console/doc/detail?pId=1822
- 华为推送文档：https://developer.huawei.com/consumer/cn/doc/development/HMS-Guides/push-introduction
- OPPO推送文档：https://open.oppomobile.com/wiki/doc#id=10196
- vivo推送文档：https://dev.vivo.com.cn/documentCenter/doc/180
- 魅族推送文档：https://open.flyme.cn/openweb/views/push.html

