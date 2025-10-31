# 项目环境配置指南

## 前置要求
- Flutter SDK 3.8.0+
- Android SDK (API 36 / Android 16)
- Dart SDK 3.8.0+

## 初次运行配置步骤

### 1. 克隆项目
```bash
git clone <your-repo-url>
cd kissu_app
```

### 2. 配置 Android SDK 路径
```bash
# 复制模板文件
cp android/local.properties.example android/local.properties

# 编辑 android/local.properties，填入你的 SDK 路径
# Windows 示例：
# sdk.dir=D:\\developDependence\\Android\\SDK
# flutter.sdk=D:\\developDependence\\flutter

# Mac/Linux 示例：
# sdk.dir=/Users/username/Library/Android/sdk
# flutter.sdk=/Users/username/flutter
```

### 3. 配置签名文件（用于发布构建）
```bash
# 复制模板文件
cp android/key.properties.example android/key.properties

# 如果需要发布版本，需要获取签名密钥文件 kissu1.keystore
# 将其放置在 android/app/ 目录下
# 注意：签名密钥不应提交到Git仓库
```

### 4. 安装依赖
```bash
flutter pub get
```

### 5. 运行项目
```bash
# Debug 模式
flutter run

# Release 模式（需要配置签名）
flutter run --release
```

## 常见问题

### 问题1: SDK路径错误
**错误信息**: `SDK location not found`
**解决方案**: 检查 `android/local.properties` 中的 SDK 路径是否正确

### 问题2: 签名失败
**错误信息**: `Keystore file not found`
**解决方案**: 
- Debug 模式不需要签名文件，可以正常运行
- Release 模式需要联系项目管理员获取签名文件

### 问题3: 依赖下载失败
**解决方案**: 
```bash
# 清理缓存后重新获取依赖
flutter clean
flutter pub get
```

## 本地插件说明
项目使用了本地版本的插件，已包含在 `plugins/` 目录：
- amap_flutter_map (高德地图)
- amap_flutter_location (高德定位)
- amap_flutter_base (高德基础组件)
- ping_discover_network_forked (网络扫描)

## 第三方SDK配置
项目集成了以下第三方SDK，需要确保配置正确：
- 高德地图 API Key（在 AndroidManifest.xml 中配置）
- 友盟统计 APPKEY
- 微信支付/分享 APPID
- 支付宝支付
- OpenInstall 渠道统计
- 极光推送
- 腾讯IM SDK

详细配置请查看 `android/app/build.gradle.kts` 中的 manifestPlaceholders。

