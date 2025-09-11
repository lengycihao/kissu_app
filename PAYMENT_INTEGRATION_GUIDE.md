# 支付集成指南

本文档说明如何在现有代码基础上集成真实的微信支付和支付宝支付。

## 当前状态

目前 `PaymentService` 类已经实现了基本的支付流程框架，但为了避免编译错误，使用了模拟的API调用。要启用真实的支付功能，你需要按照以下步骤进行：

## 1. 微信支付集成

### 1.1 配置微信应用

1. 在微信开放平台注册应用并获取 `AppID`
2. 在微信商户平台配置支付参数
3. 更新 `PaymentService` 中的 `appId`：
   ```dart
   await fluwx.registerWxApi(
     appId: "你的真实微信AppID", // 替换这里
     doOnAndroid: true,
     doOnIOS: true,
   );
   ```

### 1.2 取消注释并修复微信支付代码

在 `PaymentService.payWithWechat()` 方法中：

```dart
// 1. 取消注释检查微信安装状态的代码
bool isWechatInstalled = await fluwx.isWeChatInstalled;

// 2. 取消注释真实的微信支付调用
final result = await fluwx.pay(
  appId: appId,
  partnerId: partnerId,
  prepayId: prepayId,
  packageValue: packageValue,
  nonceStr: nonceStr,
  timeStamp: timeStamp,
  sign: sign,
);

// 3. 处理支付结果
if (result.isSuccessful) {
  // 支付成功
  return true;
} else if (result.isCancelled) {
  // 用户取消
  return false;
} else {
  // 支付失败
  return false;
}
```

### 1.3 Android 配置

在 `android/app/src/main/AndroidManifest.xml` 中添加：

```xml
<activity
    android:name=".wxapi.WXPayEntryActivity"
    android:exported="true"
    android:launchMode="singleTop">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <data android:scheme="你的微信AppID" />
    </intent-filter>
</activity>
```

### 1.4 iOS 配置

在 `ios/Runner/Info.plist` 中添加：

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>weixin</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>你的微信AppID</string>
        </array>
    </dict>
</array>
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>weixin</string>
    <string>wechat</string>
</array>
```

## 2. 支付宝支付集成

### 2.1 配置支付宝应用

1. 在支付宝开放平台创建应用并获取 `AppID`
2. 配置应用公钥和私钥
3. 获取支付宝公钥

### 2.2 取消注释并修复支付宝支付代码

在 `PaymentService.payWithAlipay()` 方法中：

```dart
// 1. 取消注释检查支付宝安装状态的代码
bool isAlipayInstalled = await tobias.isAliPayInstalled();

// 2. 取消注释真实的支付宝支付调用
final result = await tobias.pay(orderInfo);

// 3. 处理支付结果
final resultStatus = result['resultStatus'] as String?;
if (resultStatus == '9000') {
  // 支付成功
  return true;
} else if (resultStatus == '6001') {
  // 用户取消
  return false;
} else {
  // 支付失败
  return false;
}
```

### 2.3 Android 配置

在 `android/app/build.gradle` 中添加：

```gradle
android {
    defaultConfig {
        manifestPlaceholders = [
            ALIPAY_SCHEME: "alipay你的AppID"
        ]
    }
}
```

在 `android/app/src/main/AndroidManifest.xml` 中添加：

```xml
<activity
    android:name="com.alipay.sdk.app.H5PayActivity"
    android:configChanges="orientation|keyboardHidden|navigation|screenSize"
    android:exported="false"
    android:screenOrientation="behind"
    android:windowSoftInputMode="adjustResize|stateHidden" />

<activity
    android:name="com.alipay.sdk.app.H5AuthActivity"
    android:configChanges="orientation|keyboardHidden|navigation"
    android:exported="false"
    android:screenOrientation="behind"
    android:windowSoftInputMode="adjustResize|stateHidden" />
```

### 2.4 iOS 配置

在 `ios/Runner/Info.plist` 中添加：

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>alipay</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>alipay你的AppID</string>
        </array>
    </dict>
</array>
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>alipay</string>
    <string>alipayshare</string>
</array>
```

## 3. 服务器端集成

### 3.1 微信支付服务器端

确保你的服务器 `/pay/wxPay` 接口返回正确的微信支付参数：

```json
{
  "code": 200,
  "msg": "success",
  "data": {
    "appId": "wxca15128b8c388c13",
    "partnerId": "商户号",
    "prepayId": "预支付ID",
    "packageValue": "Sign=WXPay",
    "nonceStr": "随机字符串",
    "timestamp": "时间戳",
    "sign": "签名"
  }
}
```

### 3.2 支付宝支付服务器端

确保你的服务器 `/pay/aliPay` 接口返回正确的支付宝订单字符串：

```json
{
  "code": 200,
  "msg": "success", 
  "data": {
    "orderString": "支付宝订单信息字符串"
  }
}
```

## 4. 测试

### 4.1 测试环境

1. 微信支付：使用微信提供的沙箱环境
2. 支付宝：使用支付宝提供的沙箱环境

### 4.2 测试步骤

1. 在测试设备上安装微信和支付宝应用
2. 确保网络连接正常
3. 测试各种支付场景：
   - 正常支付
   - 取消支付
   - 网络异常
   - 应用未安装

## 5. 错误处理

已经在 `PaymentService` 中实现了完整的错误处理机制：

- 支付SDK初始化失败
- 应用未安装检测
- 网络错误处理
- 用户取消处理
- 支付失败处理

## 6. 注意事项

1. **安全性**：所有支付参数的生成和签名必须在服务器端完成
2. **证书**：确保正确配置支付证书
3. **权限**：确保应用具有必要的网络和存储权限
4. **测试**：充分测试各种边界情况
5. **日志**：保留详细的支付日志用于调试

## 7. 当前代码修改点

要启用真实支付，你需要修改以下位置：

1. `lib/services/payment_service.dart` 第30行：取消注释微信初始化
2. `lib/services/payment_service.dart` 第86行：取消注释微信支付调用
3. `lib/services/payment_service.dart` 第153行：取消注释支付宝支付调用
4. `lib/services/payment_service.dart` 第222行：取消注释微信安装检查
5. `lib/services/payment_service.dart` 第232行：取消注释支付宝安装检查

完成这些修改后，你的支付功能就可以正常工作了！
