# Kissu App

Flutter 移动应用项目

## 快速开始

⚠️ **首次运行请务必阅读** [SETUP.md](SETUP.md) 配置环境！

### 环境要求
- Flutter SDK 3.8.0+
- Android SDK (API 36 / Android 16)
- Dart SDK 3.8.0+

### 快速配置
```bash
# 1. 配置本地 SDK 路径
cp android/local.properties.example android/local.properties
# 编辑 local.properties 填入你的 SDK 路径

# 2. 安装依赖
flutter pub get

# 3. 运行项目
flutter run
```

详细配置说明请查看 [SETUP.md](SETUP.md)

## 项目结构
- `lib/` - Dart 源代码
- `android/` - Android 原生代码
- `ios/` - iOS 原生代码
- `plugins/` - 本地插件（高德地图、网络扫描等）
- `assets/` - 资源文件
- `docs/` - 项目文档

## 技术栈
- Flutter 3.8.0+
- GetX 状态管理
- 高德地图 & 定位
- 极光推送
- 腾讯IM SDK
- 微信支付/分享
- 支付宝支付
- 友盟统计

## 开发文档
更多开发文档请查看 `docs/` 目录
