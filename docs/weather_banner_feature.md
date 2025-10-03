# 天气 Banner 功能说明

## 功能概述

在首页底部的 banner 轮播中添加了天气 banner，展示对象的天气信息。天气 banner 作为第三张，不区分是否绑定和是否开通会员。

## 实现细节

### 1. Banner 设计规格

- **背景图片**：`assets/3.0/KissuBannerBuilder.webp`
- **尺寸**：302×83 px
- **元素布局**：
  - 天气图标：位置 (22, 36)，大小 33×33 px，网络图片
  - 天气详情：距离图标 10px，字体 12pt，颜色 #333333
  - 最低温度：距离天气详情 15px，字体 13pt，颜色 #333333，宽度 22px
  - 温度条：距离最低温度 6px，尺寸 110×7 px，带圆角
    - 背景色：白色 (#FFFFFF)
    - 填充色：#FFDC73
    - 填充比例：基于当前温度在最低-最高温度区间的百分比
  - 最高温度：距离温度条 6px，字体 13pt，颜色 #333333，宽度 22px

### 2. 数据加载状态

- **加载中/失败状态**：只显示温度条的白色背景，其他元素隐藏
- **加载成功状态**：显示所有天气信息元素

### 3. 天气 API

- **接口地址**：`/weather/getWeather`
- **请求参数**：
  - `extensions`: "base,all"
  - `is_oneself`: 2（表示对象的天气）
- **返回数据**：
  - `lives.base[0].weather_icon`：天气图标 URL
  - `lives.base[0].weather`：天气描述
  - `lives.base[0].temperature`：当前温度
  - `lives.all[0].casts[0].nighttemp`：最低温度
  - `lives.all[0].casts[0].daytemp`：最高温度

### 4. 温度条计算逻辑

温度条的填充比例计算公式：

```dart
percentage = (currentTemp - minTemp) / (maxTemp - minTemp)
```

例如：
- 最高温度：30°C
- 最低温度：20°C
- 当前温度：24°C
- 填充比例：(24-20)/(30-20) = 40%

### 5. 文件修改清单

#### 新增文件
- `lib/models/weather_model.dart` - 天气数据模型
- `docs/weather_banner_feature.md` - 功能说明文档

#### 修改文件
- `lib/widgets/kissu_banner_builder.dart`
  - 添加天气 banner 常量定义
  - 添加 `buildWeatherBannerWidget()` 方法
  - 添加 `_buildTemperatureBar()` 方法
  - 添加 `_buildEmptyTemperatureBar()` 方法

- `lib/pages/home/home_controller.dart`
  - 添加天气数据相关的响应式变量
  - 添加 `_loadWeatherData()` 方法
  - 在 `onInit()` 中调用天气数据加载

- `lib/pages/home/home_page.dart`
  - 修改 `_buildBanner()` 方法，添加天气 banner（未绑定状态）
  - 修改 `_buildBannerBind()` 方法，添加天气 banner（已绑定状态）
  - 轮播数量从 2 张改为 3 张
  - 指示器点数从 2 个改为 3 个

- `lib/network/public/api_request.dart`
  - 添加 `getWeather` API 常量

## 使用方式

天气 banner 会在首页初始化时自动加载数据并显示。用户无需任何操作，天气信息会自动展示在 banner 轮播的第三张。

### 天气数据加载时机

1. **首次加载**：在首页 `onInit()` 中，通过 `loadUserInfo()` 检测到已绑定状态时自动加载
2. **定时轮询**：集成到红点轮询中，每 10 秒刷新一次（仅在已绑定状态下）
3. **应用返回前台**：应用从后台返回前台时，如果是已绑定状态，会立即刷新一次
4. **用户信息刷新**：调用 `refreshUserInfoFromServer()` 后，如果是已绑定状态，会重新加载天气数据

### 加载条件

- **绑定状态检查**：只有在 `isBound.value == true`（已绑定状态）时才会请求天气数据
- **未绑定状态**：不会请求天气接口，banner 只显示空状态（白色温度条背景）

## 注意事项

1. 天气 banner 不需要点击事件，仅用于信息展示
2. 当天气数据加载失败或未加载时，只显示白色温度条背景
3. 天气数据展示的是对象（另一半）的天气信息
4. 温度条的圆角设计使其更美观
5. 所有温度显示都带有 "°" 符号
6. 天气数据只在已绑定状态下才会请求，避免不必要的网络请求
7. 天气数据集成到红点轮询中，每 10 秒自动刷新一次

