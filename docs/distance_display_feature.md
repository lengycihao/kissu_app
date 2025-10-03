# 距离显示功能文档

## 功能概述

在首页定位 Banner 上显示用户与另一半的距离信息。距离信息仅在**已绑定且已开通VIP**状态下显示。

## 实现细节

### 1. 距离背景和样式

- **距离背景图片**：`assets/3.0/kissu3_banner_juli_bg.webp`
- **背景尺寸**：64×18
- **背景坐标**：(153, 31)

### 2. 距离文字样式

距离文字格式为 "nKM"，其中：
- **数字部分 (n)**：
  - 字体大小：12pt
  - 颜色：#FF4B99（粉红色）
  - 字重：normal

- **单位部分 (KM)**：
  - 字体大小：10pt
  - 颜色：#333333（深灰色）
  - 字重：normal

### 3. 数据来源

距离数据从 `HomeController` 的 `distance` 字段获取：
- 类型：`RxString`（响应式字符串）
- 格式：例如 "0KM", "1.5KM", "10.2KM"
- 获取方式：通过 `_loadDistanceInfo()` 方法从服务器获取

## 代码文件

### 修改的文件

1. **`lib/widgets/kissu_banner_builder.dart`**
   - 添加距离背景常量（第 49-54 行）
   - 修改 `buildLocationBannerWidget` 方法签名，添加 `distance` 参数（第 272-280 行）
   - 在绑定开通VIP的定位Banner中添加距离背景和文字显示（第 473-497 行）
   - 添加 `_buildDistanceText` 方法用于构建距离文字（第 1006-1046 行）

2. **`lib/pages/home/home_page.dart`**
   - 在已绑定状态的定位Banner调用中添加 `distance` 参数（第 618 行）

## 显示逻辑

### 显示条件

距离信息只在以下条件同时满足时显示：
1. 用户已绑定（`isBound == true`）
2. 用户已开通VIP（`isVip == true`）
3. 查看定位Banner（index == 0）

### 文字解析逻辑

`_buildDistanceText` 方法会自动解析距离字符串：
- 查找第一个字母的位置
- 将字母前的部分作为数字（粉红色）
- 将字母及之后的部分作为单位（灰色）

例如：
- "1.5KM" → "1.5"（粉红色） + "KM"（灰色）
- "0KM" → "0"（粉红色） + "KM"（灰色）
- "100.5KM" → "100.5"（粉红色） + "KM"（灰色）

## 使用示例

```dart
KissuBannerBuilder.buildLocationBannerWidget(
  isBound: true,
  isVip: true,
  userAvatarUrl: userAvatarUrl,
  partnerAvatarUrl: partnerAvatarUrl,
  distance: "1.5KM", // 距离信息
  width: 302,
  height: 83,
)
```

## 资源文件

需要确保以下资源文件存在：
- `assets/3.0/kissu3_banner_juli_bg.webp` - 距离背景图片（64×18）

## 注意事项

1. 距离背景始终显示（只要是绑定开通VIP状态）
2. 距离文字只在 `distance` 不为空时显示
3. 距离数据会随着红点轮询自动更新（每10秒）
4. 距离信息仅在定位Banner上显示，足迹Banner和天气Banner不显示
5. 文字在距离背景上水平垂直居中对齐

