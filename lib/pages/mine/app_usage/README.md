# App使用记录功能说明

## 功能概述
本功能实现了对Android系统中已安装应用的使用记录采集和上报，包括：
- 筛选需要监控的应用
- 采集当天每小时的使用时长
- 记录每次打开和关闭的具体时间
- 上报使用数据到服务器

## 文件结构

```
lib/pages/mine/app_usage/
├── models/
│   └── app_usage_record.dart          # 数据模型
├── api/
│   └── app_usage_api.dart             # 上报API
├── app_usage_page.dart                # 主页面（应用列表和筛选）
├── app_usage_controller.dart          # 控制器（业务逻辑）
├── app_usage_binding.dart             # GetX绑定
├── app_usage_test_page.dart           # 测试页面
└── README.md                          # 本文档
```

## 核心功能

### 1. 数据模型 (app_usage_record.dart)

#### AppUsageSession - 应用使用会话
记录单次打开和关闭的时间：
- `openTime`: 打开时间（毫秒时间戳）
- `closeTime`: 关闭时间（毫秒时间戳）
- `duration`: 使用时长（毫秒）

#### HourlyUsageRecord - 每小时使用记录
记录某个小时的使用情况：
- `hour`: 小时（0-23）
- `totalDuration`: 该小时总使用时长（毫秒）
- `sessions`: 该小时的所有使用会话列表

#### AppUsageRecord - 应用使用记录
完整的应用使用记录：
- `appName`: 应用名称
- `packageName`: 应用包名
- `iconBase64`: 应用图标的base64编码
- `date`: 日期（yyyy-MM-dd）
- `hourlyRecords`: 每小时使用记录列表（只包含有使用的小时）

#### AppUsageBatchReport - 批量上报
用于批量上报多个应用的使用记录。

### 2. 上报API (app_usage_api.dart)

#### 主要方法：

**reportAppUsage(List<AppUsageRecord> records)**
- 批量上报多个应用的使用记录
- 自动添加上报日期
- 返回上报结果

**reportSingleAppUsage(AppUsageRecord record)**
- 上报单个应用的使用记录

**getUsageHistory(startDate, endDate)**
- 获取历史使用记录（服务端功能）

### 3. 主页面 (app_usage_page.dart)

#### 功能特性：
- ✅ 显示所有已安装的用户应用（自动过滤系统应用）
- ✅ 应用搜索功能
- ✅ 应用筛选（选择需要监控的应用）
- ✅ 点击已筛选应用查看详细使用数据
- ✅ 右上角上传按钮一键上报数据
- ✅ 下拉刷新

#### UI说明：
- **搜索框**: 支持按应用名称或包名搜索
- **说明文字**: 显示已筛选应用数量
- **应用列表**: 
  - 未筛选应用：显示"筛选"按钮（灰色）
  - 已筛选应用：显示"已筛选"按钮（粉色），点击可查看详情
- **上传按钮**: 点击上报所有已筛选应用的使用数据

### 4. 控制器 (app_usage_controller.dart)

#### 主要功能：

**toggleSelection(String packageName)**
- 切换应用的筛选状态
- 自动保存到SharedPreferences

**collectAndReportUsageData()**
- 采集所有已筛选应用的使用数据
- 只上报有使用记录的应用
- 自动上报到服务器

**getDetailedUsageData(String packageName)**
- 获取单个应用的详细使用数据
- 用于显示使用详情

### 5. Native实现 (MainActivity.kt)

#### 新增方法：

**getDetailedUsageData(packageName)**
- 获取单个应用的详细使用数据
- 包含每小时使用时长
- 包含每次打开/关闭时间
- 自动处理跨小时会话拆分

**getBatchDetailedUsageData(packageNames)**
- 批量获取多个应用的详细使用数据
- 提高采集效率

#### 数据采集逻辑：
1. 获取当天0点到当前时间的使用事件
2. 收集应用的 MOVE_TO_FOREGROUND（打开）和 MOVE_TO_BACKGROUND（关闭）事件
3. 配对打开和关闭事件，构建使用会话
4. 按小时分组统计，自动拆分跨小时会话
5. 只返回有使用记录的小时数据

### 6. 测试页面 (app_usage_test_page.dart)

#### 功能特性：
- 📊 显示当前筛选应用列表
- 🧪 测试数据采集功能
- 📤 测试数据上报功能
- 🎯 测试完整流程（采集+上报）
- 📋 显示详细的测试结果
- 🗑️ 清除测试数据

#### 测试结果展示：
- 采集应用数量
- 有使用记录的应用数量
- 总打开次数
- 每个应用的详细信息：
  - 应用名称和包名
  - 总使用时长
  - 打开次数
  - 各小时使用情况

## 使用流程

### 1. 筛选应用
1. 打开 AppUsagePage
2. 浏览或搜索应用
3. 点击"筛选"按钮选择需要监控的应用
4. 已筛选的应用会显示"已筛选"标记

### 2. 查看使用详情
1. 点击已筛选的应用
2. 查看该应用的详细使用数据
3. 包含：日期、总时长、打开次数、各小时使用情况

### 3. 上报数据
1. 筛选好需要监控的应用后
2. 点击右上角的上传按钮
3. 系统自动采集并上报所有已筛选应用的使用数据
4. 只上报有使用记录的应用

### 4. 测试功能
1. 打开 AppUsageTestPage（需要在路由中添加）
2. 查看当前筛选的应用
3. 点击"测试完整流程"按钮
4. 查看采集和上报结果

## 权限要求

应用需要"使用情况访问"权限（Usage Access Permission）：
- 首次使用时会提示授权
- 点击"去授权"打开系统设置页面
- 找到应用并开启权限

## 数据上报格式

```json
{
  "reportDate": "2025-11-04",
  "records": [
    {
      "appName": "微信",
      "packageName": "com.tencent.mm",
      "iconBase64": "base64编码的图标",
      "date": "2025-11-04",
      "totalDuration": 3600000,
      "totalSessions": 15,
      "hourlyRecords": [
        {
          "hour": 9,
          "totalDuration": 1200000,
          "sessions": [
            {
              "openTime": 1730692800000,
              "closeTime": 1730693400000,
              "duration": 600000
            }
          ]
        }
      ]
    }
  ]
}
```

## 注意事项

1. **权限问题**：
   - 必须授予"使用情况访问"权限
   - 该权限需要用户在系统设置中手动开启
   - 没有权限时会自动提示

2. **系统应用过滤**：
   - 自动过滤系统应用，只显示用户安装的应用
   - 保留用户更新过的系统应用

3. **数据采集范围**：
   - 只采集当天（0点到当前时间）的数据
   - 只上报有使用记录的应用
   - 只统计前台使用时长

4. **性能优化**：
   - 应用列表获取在后台线程进行
   - 批量获取使用数据提高效率
   - 图标压缩为64x64，JPEG格式，减小传输量

5. **会话拆分**：
   - 跨小时的使用会话会自动拆分
   - 确保每小时统计的准确性

## API端点

需要在服务器实现以下接口：

**POST /app-usage/report**
- 接收批量应用使用记录
- 参数格式见"数据上报格式"部分

**GET /app-usage/history**
- 查询历史使用记录
- 参数：startDate, endDate

## 后续扩展

可以考虑添加的功能：
- 定时自动上报（每天定时）
- 数据可视化（图表展示）
- 使用趋势分析
- 应用分类统计
- 导出使用报告

## 路由配置示例

```dart
// 在路由配置中添加测试页面
GetPage(
  name: '/app-usage-test',
  page: () => const AppUsageTestPage(),
  binding: AppUsageBinding(),
),
```

