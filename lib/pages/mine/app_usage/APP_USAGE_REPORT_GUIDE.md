# App使用记录采集上报服务使用指南

## 📋 功能概述

根据 `api.md` 需求实现的完整 App 使用记录采集上报服务，包括：

1. ✅ **自动全量上报** - 每天第一次打开app时上报当天截止到当前时间的所有数据
2. ✅ **定时增量上报** - 之后每2分钟自动增量上报新产生的数据
3. ✅ **午夜自动上报** - 每天23:59:59自动增量上报并清空本地记录
4. ✅ **智能增量对比** - 自动筛选出新增的使用记录，避免重复上报
5. ✅ **本地缓存管理** - 记录每个应用最后上报的会话时间，用于增量对比
6. ✅ **调试功能** - 在调试页面提供完整的测试和查看功能

## 🏗️ 架构设计

### 文件结构

```
lib/pages/mine/app_usage/
├── services/
│   └── app_usage_report_service.dart    # 核心服务类
├── models/
│   └── app_usage_record.dart            # 数据模型
├── api/
│   └── app_usage_api.dart               # API接口
├── app_usage_controller.dart            # 控制器（集成服务）
└── app_usage_debug_page.dart            # 调试页面
```

### 核心类：AppUsageReportService

**单例模式**，提供以下功能：

#### 主要方法

- `initialize(Set<String> selectedApps)` - 初始化服务，启动定时器
- `stop()` - 停止服务

#### 调试方法

- `debugViewPendingData()` - 查看待上报数据（全量/增量）
- `debugFullReport()` - 手动触发全量上报
- `debugIncrementalReport()` - 手动触发增量上报
- `debugClearLocalData()` - 清空本地缓存记录

## 🚀 使用方法

### 1. 在 AppUsageController 中初始化服务

```dart
@override
void onInit() {
  super.onInit();
  _loadData();
  _checkPermission();
  _loadUsageData();
  
  // 初始化上报服务
  initializeReportService();
}

@override
void onClose() {
  // 停止上报服务
  stopReportService();
  super.onClose();
}
```

### 2. 在调试页面使用

打开 **App使用记录采集调试** 页面，右上角有两个按钮：

#### 🐛 调试菜单（虫子图标）

- **查看待上报数据** - 查看当前全量数据和增量数据
  - 显示全量数据、增量数据、已上报记录的统计
  - 可切换查看全量/增量数据详情
  
- **全量上报** - 手动触发全量上报
  - 上报当天所有使用记录
  - 更新本地缓存记录
  
- **增量上报** - 手动触发增量上报
  - 只上报新增的使用记录
  - 自动对比本地缓存，筛选增量数据
  
- **清空本地记录** - 清空本地缓存
  - 清除所有上报记录
  - 下次上报将是全量上报

#### ☁️ 上报按钮（云上传图标）

- 直接调用原有的上报方法
- 上报所有筛选应用的使用记录

## 📊 数据上报格式

### 上报数据结构

```json
{
  "reportDate": "2025-11-26",
  "records": [
    {
      "appName": "微信",
      "packageName": "com.tencent.mm",
      "iconBase64": "base64编码的图标",
      "date": "2025-11-26",
      "totalDuration": 3600000,
      "totalSessions": 5,
      "hourlyRecords": [
        {
          "hour": 9,
          "totalDuration": 600000,
          "sessionCount": 2,
          "sessions": [
            {
              "openTime": 1732593600000,
              "closeTime": 1732594200000,
              "duration": 600000,
              "isRunning": false
            }
          ]
        }
      ]
    }
  ]
}
```

### 字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| appName | String | 应用名称 |
| packageName | String | 应用包名 |
| iconBase64 | String | 应用图标（Base64编码） |
| date | String | 日期（yyyy-MM-dd） |
| totalDuration | int | 总使用时长（毫秒） |
| totalSessions | int | 总打开次数 |
| hourlyRecords | Array | 每小时使用记录 |
| hour | int | 小时（0-23） |
| sessionCount | int | 该小时打开次数 |
| sessions | Array | 会话列表 |
| openTime | int | 打开时间戳（毫秒） |
| closeTime | int | 关闭时间戳（毫秒，-1表示运行中） |
| duration | int | 使用时长（毫秒） |
| isRunning | bool | 是否正在运行 |

## 🔄 工作流程

### 首次启动流程

```
1. 检查是否是新的一天
   ├─ 是 → 清除旧数据，标记为未上报
   └─ 否 → 加载上次上报记录

2. 执行首次全量上报
   ├─ 采集当天所有使用数据
   ├─ 上报到服务器
   └─ 保存上报记录（每个应用最后一条会话的打开时间）

3. 启动定时器
   ├─ 每2分钟执行增量上报
   └─ 每天23:59:59执行午夜上报
```

### 增量上报流程

```
1. 采集当天全量数据

2. 筛选增量数据
   ├─ 遍历每个应用的所有会话
   ├─ 对比本地缓存的最后上报时间
   └─ 筛选出 openTime > lastReportedTime 的会话

3. 重新组织数据
   ├─ 按小时分组新增会话
   └─ 构建 HourlyUsageRecord

4. 上报增量数据

5. 更新本地缓存
   └─ 保存每个应用最新的会话打开时间
```

### 午夜上报流程

```
23:59:59 触发
   ├─ 执行最后一次增量上报
   ├─ 清空本地缓存记录
   ├─ 重置上报状态
   └─ 设置下一个午夜定时器
```

## 💾 本地存储

### SharedPreferences 存储的数据

| Key | 类型 | 说明 |
|-----|------|------|
| `last_reported_sessions` | String (JSON) | 每个应用最后上报的会话时间 |
| `has_reported_today` | bool | 今天是否已完成首次上报 |
| `last_report_date` | String | 最后上报日期（yyyy-MM-dd） |
| `selected_apps_for_usage` | List<String> | 筛选的应用包名列表 |

### 数据示例

```json
{
  "last_reported_sessions": {
    "com.tencent.mm": 1732593600000,
    "com.tencent.mobileqq": 1732590000000
  },
  "has_reported_today": true,
  "last_report_date": "2025-11-26"
}
```

## 🎯 使用场景

### 场景1：首次使用

```
用户打开app → 自动全量上报 → 每2分钟增量上报
```

### 场景2：跨天使用

```
23:59:59 → 午夜上报并清空
00:00:00 → 新的一天
用户打开app → 自动全量上报（新的一天的数据）
```

### 场景3：调试测试

```
1. 点击"查看待上报数据" → 查看全量和增量数据
2. 点击"全量上报" → 手动触发全量上报
3. 点击"增量上报" → 手动触发增量上报
4. 点击"清空本地记录" → 清空缓存，下次将全量上报
```

## ⚠️ 注意事项

1. **权限要求**
   - 需要"使用情况访问"权限
   - 在首次使用时会自动检查并引导用户授权

2. **性能优化**
   - 采用增量上报，避免重复上报大量数据
   - 定时器在后台运行，不影响用户体验
   - 数据采集在后台线程执行

3. **数据准确性**
   - 只上报有使用记录的应用
   - 自动过滤系统应用
   - 会话时间精确到毫秒

4. **异常处理**
   - 网络异常时不会丢失数据，下次会继续上报
   - 本地缓存异常时会自动重建
   - 定时器异常时会自动重启

## 🔧 调试技巧

### 1. 查看日志

所有操作都有详细日志，标签为 `AppUsageReportService`：

```
✅ App使用记录上报服务已启动
📤 开始执行当天首次全量上报...
📊 采集到 5 个应用的使用数据
✅ 首次全量上报成功: 5个应用
⏰ 定时上报已启动（每2分钟）
🌙 午夜定时器已设置
```

### 2. 测试增量上报

```
1. 清空本地记录
2. 全量上报
3. 使用一些应用
4. 查看待上报数据 → 查看增量数据
5. 增量上报
```

### 3. 测试跨天逻辑

```
1. 修改系统时间到23:59:58
2. 等待2秒，触发午夜上报
3. 查看日志确认清空记录
4. 修改系统时间到第二天
5. 重启app，确认执行全量上报
```

## 📝 API 接口

### 上报接口

```
POST /app-usage/report
```

**请求体：**
```json
{
  "reportDate": "2025-11-26",
  "records": [...]
}
```

**响应：**
```json
{
  "isSuccess": true,
  "code": 0,
  "msg": "上报成功"
}
```

## 🎉 完成状态

✅ 所有 api.md 中的需求已实现：

1. ✅ 上报 logo、包名、app名字、打开时间、关闭时间
2. ✅ 批量上报有数据的app使用记录
3. ✅ 每天第一次打开app时全量上报
4. ✅ 之后隔2分钟增量上报
5. ✅ 每天23:59:59增量上报并清空记录
6. ✅ 增量上报筛选数据（对比本地缓存）
7. ✅ 只上报有数据的应用
8. ✅ 在调试页面提供测试按钮
9. ✅ 数据组装完成，可以查看

现在你可以在 **App使用记录采集调试** 页面测试所有功能了！🚀
