# 敏感数据上报功能

## 功能概述

本功能实现了敏感数据上报API `/reporting/sensitive/record`，用于上报用户的各种敏感行为事件。

## 支持的事件类型

| 事件类型 | 值 | 描述 | 扩展参数 |
|---------|---|------|---------|
| 打开APP | 2 | 应用启动时触发 | 无 |
| 打开定位 | 4 | 定位服务启动时触发 | 无 |
| 关闭定位 | 5 | 定位服务停止时触发 | 无 |
| 更换网络 | 6 | 网络状态发生变化时触发 | `{"network_name": "WiFi SSID名称"}` |
| 开始充电 | 7 | 设备开始充电时触发 | `{"power": 手机电量}` |
| 结束充电 | 8 | 设备结束充电时触发 | `{"power": 手机电量}` |

## 实现文件

### 1. API接口层
- `lib/network/public/sensitive_data_api.dart` - 敏感数据上报API接口
- `lib/network/public/api_request.dart` - 添加了API路径常量

### 2. 服务层
- `lib/services/sensitive_data_service.dart` - 敏感数据上报服务，负责监听各种事件并自动上报

### 3. 集成层
- `lib/main.dart` - 应用启动时初始化服务并上报APP打开事件
- `lib/services/simple_location_service.dart` - 定位服务中集成敏感数据上报
- `lib/network/public/service_locator.dart` - 服务注册

### 4. 测试页面
- `lib/pages/test/sensitive_data_test_page.dart` - 敏感数据上报功能测试页面

## 功能特性

### 自动监听和上报
- **网络状态监听**: 使用 `connectivity_plus` 包监听网络状态变化
- **电池状态监听**: 使用 `battery_plus` 包监听充电状态变化
- **定位状态监听**: 在定位服务启动/停止时自动上报

### 条件检查
- 只有在用户已登录且有有效token时才会进行上报
- 通过 `UserManager.isLoggedIn` 和 `UserManager.userToken` 进行检查

### 错误处理
- 所有上报操作都有异常捕获和日志记录
- 网络错误不会影响应用的正常运行

## 使用方法

### 1. 自动上报
服务会在以下时机自动上报：
- 应用启动时上报APP打开事件
- 定位服务启动时上报定位打开事件
- 定位服务停止时上报定位关闭事件
- 网络状态变化时上报网络更换事件
- 充电状态变化时上报充电事件

### 2. 手动上报
可以通过 `SensitiveDataService` 手动触发上报：

```dart
final service = getIt<SensitiveDataService>();

// 上报APP打开事件
await service.reportAppOpen();

// 上报定位打开事件
await service.reportLocationOpen();

// 上报定位关闭事件
await service.reportLocationClose();

// 手动上报网络更换事件
await service.manualReportNetworkChange('wifi');

// 手动上报充电事件
await service.manualReportCharging(true, 85); // 开始充电，电量85%
```

### 3. 测试功能
可以访问测试页面 `SensitiveDataTestPage` 来测试各种上报功能。

## 依赖包

在 `pubspec.yaml` 中添加了以下依赖：
- `connectivity_plus: ^6.0.5` - 网络状态监听
- `battery_plus: ^7.0.0` - 电池状态监听
- `network_info_plus: ^4.0.2` - 网络信息获取（包括WiFi SSID）

## 注意事项

1. **权限要求**: 需要确保应用有相应的权限来监听网络和电池状态，以及获取WiFi信息
2. **隐私合规**: 敏感数据上报需要符合相关隐私法规要求
3. **网络依赖**: 上报功能依赖网络连接，在网络不可用时会静默失败
4. **性能影响**: 监听服务会持续运行，但影响很小

## 调试

可以通过以下方式查看服务状态：

```dart
final service = getIt<SensitiveDataService>();
final status = service.getServiceStatus();
print('服务状态: $status');
```

状态信息包括：
- `currentNetworkName`: 当前网络名称
- `currentBatteryState`: 当前电池状态
- `isCharging`: 是否正在充电
- `shouldReport`: 是否应该进行上报（基于登录状态）
