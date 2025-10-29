# 会员可见按钮埋点集成文档

## 📋 概述
本文档记录了**会员可见/开通会员按钮**的友盟埋点集成实现。该埋点记录用户在用机记录页面各标签下的列表中点击"会员可查看"或"开通会员"按钮，准备跳转到会员开通页面时的操作。

---

## 🎯 埋点事件详情

### 会员可见按钮点击埋点
**事件名称**: 会员可见  
**事件ID**: `membership_only`  
**事件类型**: 点击事件  
**触发时机**: 非会员用户点击会员相关按钮准备跳转到VIP开通页面时

#### 参数说明
| 参数名 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `device_id` | String | 虚拟用户ID（通过设备号生成） | "abc123..." |
| `user_id` | String | 用户ID | "12345" |
| `click_time` | String | 点击时间（年/月/日 时:分:秒） | "2025/10/27 15:30:25" |

---

## 📍 埋点触发位置

### 1. 通用记录项 - 会员可查看按钮
**文件**: `lib/pages/usage_report/common/generic_record_item.dart`  
**组件**: `GenericRecordItemWidget`  
**方法**: `_navigateToVipPage()`

**显示条件**: 
- 用户非会员
- 记录类型为敏感类型（3-8, 10-16, 21）

**按钮样式**:
- 文字: "会员可查看"
- 颜色: `#FF9500`（橙色）
- 图标: 橙色箭头 (`kissu3_vip_go.webp`)

**使用场景**:
- 敏感记录列表（类型 3-8, 10-16, 21）
- 定位异常记录列表

```dart
// GenericRecordItemWidget 中的实现
Widget _buildVipViewButton() {
  final isVip = UserManager.isVip;
  final buttonText = isVip ? '查看' : '会员可查看';
  
  return GestureDetector(
    onTap: () {
      if (isVip) {
        onTap?.call();
      } else {
        _navigateToVipPage();  // 触发埋点
      }
    },
    child: Row(
      children: [
        Text(buttonText),
        Image.asset('assets/phone_history/kissu3_vip_go.webp'),
      ],
    ),
  );
}

void _navigateToVipPage() async {
  // 上报会员可见按钮埋点
  await TrackingService.trackMembershipOnly();
  
  // 跳转到VIP页面
  Get.toNamed(KissuRoutePath.vip)?.then((_) {
    _refreshVipStatus();
  });
}
```

---

### 2. 屏幕使用时长记录项 - 会员可查看按钮
**文件**: `lib/pages/usage_report/common/screen_time_item.dart`  
**组件**: `ScreenTimeItemWidget`  
**方法**: `_buildVipViewButton()`

**显示条件**: 
- 用户非会员
- 在屏幕使用时长列表中

**按钮样式**:
- 文字: "会员可查看"
- 颜色: `#FF9500`（橙色）
- 图标: 橙色箭头

**数据脱敏**:
- 时间段显示为: `*~*点`
- 使用时长显示为: `****`
- 应用图标替换为 VIP 图标

```dart
// ScreenTimeItemWidget 中的实现
Widget _buildVipViewButton() {
  return GestureDetector(
    onTap: () async {
      // 上报会员可见按钮埋点
      await TrackingService.trackMembershipOnly();
      
      // 跳转到VIP页面
      await Get.toNamed(KissuRoutePath.vip);
      await UserManager.refreshUserInfo();
      onVipStatusChanged?.call();
    },
    child: Row(
      children: [
        Text('会员可查看'),
        Image.asset('assets/phone_history/kissu3_vip_go.webp'),
      ],
    ),
  );
}
```

---

### 3. 解锁记录项 - 毛玻璃遮罩
**文件**: `lib/pages/usage_report/common/type19_unlock_record_item.dart`  
**组件**: `Type19UnlockRecordItemWidget`  
**方法**: `_buildBlurOverlay()`

**显示条件**: 
- 用户非会员
- 记录类型为 19（解锁记录）

**UI 样式**:
- 整个记录项被毛玻璃效果遮罩
- 中间显示"会员可查看"文字和箭头
- 毛玻璃透明度: 0.92

```dart
// Type19UnlockRecordItemWidget 中的实现
Widget _buildBlurOverlay() {
  return GestureDetector(
    onTap: () async {
      // 上报会员可见按钮埋点
      await TrackingService.trackMembershipOnly();
      
      // 跳转到VIP页面
      await Get.toNamed(KissuRoutePath.vip);
      await UserManager.refreshUserInfo();
      onVipStatusChanged?.call();
    },
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
      ),
      child: Center(
        child: Row(
          children: [
            Text('会员可查看'),
            Image.asset('assets/phone_history/kissu3_vip_go.webp'),
          ],
        ),
      ),
    ),
  );
}
```

---

### 4. 屏幕使用时长详情页 - 开通会员遮罩
**文件**: `lib/pages/usage_report/widgets/screen_time_detail_page.dart`  
**页面**: `ScreenTimeDetailPage`  
**位置**: 柱状图区域的毛玻璃遮罩层

**显示条件**: 
- 用户非会员
- 在屏幕使用时长详情页面

**UI 样式**:
- 覆盖整个柱状图区域（不覆盖标题）
- 毛玻璃透明度: 0.92
- 中间显示:
  - 第一行: VIP 图标 + "开通会员" + 箭头图标
  - 第二行: "解锁对方屏幕使用报告"

```dart
// ScreenTimeDetailPage 中的实现
if (!UserManager.isVip)
  Positioned(
    top: 25, // 从标题下方开始
    child: GestureDetector(
      onTap: () async {
        // 上报会员可见按钮埋点
        await TrackingService.trackMembershipOnly();
        
        // 跳转到VIP页面
        await Get.toNamed(KissuRoutePath.vip);
        await UserManager.refreshUserInfo();
        _controller.loadData();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
        ),
        child: Column(
          children: [
            // 第一行：会员图标 + 开通会员 + 箭头图标
            Row(
              children: [
                Image.asset('assets/phone_history/kissu3_vip_logo.webp'),
                Text('开通会员'),
                Image.asset('assets/phone_history/kissu3_vip_go.webp'),
              ],
            ),
            // 第二行：解锁对方屏幕使用报告
            Text('解锁对方屏幕使用报告'),
          ],
        ),
      ),
    ),
  ),
```

---

## 🔧 TrackingService 方法

### trackMembershipOnly()
```dart
/// 埋点：会员可见按钮点击
/// 
/// 事件ID: membership_only
/// 
/// 参数：
/// - device_id: 虚拟用户ID
/// - user_id: 用户ID
/// - click_time: 点击时间
/// 
/// 触发场景：
/// - 用机记录页面各标签下的"会员可查看"按钮点击
/// - 屏幕使用时长详情页的"开通会员"毛玻璃遮罩点击
/// - 解锁记录项的毛玻璃遮罩点击
static Future<void> trackMembershipOnly() async {
  final params = await _buildBaseParams();
  await _trackEvent('membership_only', params, '会员可见按钮');
}
```

---

## 📊 触发场景总览

### 用机记录页面结构
```
用机记录页面
├── 全部记录标签
│   ├── 敏感记录（类型 3-8, 10-16, 21）
│   │   └── 会员可查看按钮 ✅ 埋点触发点
│   ├── 屏幕使用时长记录（类型 20）
│   │   └── 会员可查看按钮 ✅ 埋点触发点
│   └── 解锁记录（类型 19）
│       └── 毛玻璃遮罩 ✅ 埋点触发点
│
├── 敏感记录标签
│   └── 敏感记录列表
│       └── 会员可查看按钮 ✅ 埋点触发点
│
├── 解锁记录标签
│   └── 解锁记录列表（类型 19）
│       └── 毛玻璃遮罩 ✅ 埋点触发点
│
└── 屏幕使用时长详情页
    └── 柱状图毛玻璃遮罩 ✅ 埋点触发点
```

### 会员功能限制类型
| 记录类型 | 类型说明 | 限制方式 | 埋点触发位置 |
|---------|---------|---------|-------------|
| 类型 3-8 | 敏感应用（社交、约会等） | "会员可查看"按钮 | `generic_record_item.dart` |
| 类型 10-16 | 敏感应用（其他类型） | "会员可查看"按钮 | `generic_record_item.dart` |
| 类型 19 | 解锁记录 | 毛玻璃遮罩 | `type19_unlock_record_item.dart` |
| 类型 20 | 屏幕使用时长 | "会员可查看"按钮 + 数据脱敏 | `screen_time_item.dart` |
| 类型 21 | 其他敏感记录 | "会员可查看"按钮 | `generic_record_item.dart` |
| 屏幕使用时长详情 | 柱状图详情页 | 毛玻璃遮罩 | `screen_time_detail_page.dart` |

---

## 🎨 UI 设计规范

### 1. 会员可查看按钮
**样式规范**:
```dart
// 按钮文字
Text(
  '会员可查看',
  style: TextStyle(fontSize: 13, color: Color(0xFFFF9500)),
)

// 箭头图标
Image.asset(
  'assets/phone_history/kissu3_vip_go.webp',
  width: 6,
  height: 6,
)
```

**布局**:
- 水平排列: 文字 + 4px 间距 + 箭头图标
- 居中对齐
- 文字大小: 13px
- 颜色: `#FF9500`（橙色）

### 2. 毛玻璃遮罩
**样式规范**:
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.92),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Center(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('会员可查看'),
        SizedBox(width: 4),
        Image.asset('assets/phone_history/kissu3_vip_go.webp'),
      ],
    ),
  ),
)
```

**效果**:
- 背景: 白色，透明度 0.92
- 圆角: 12px
- 内容居中显示
- 点击整个遮罩区域触发

### 3. 开通会员遮罩（详情页专用）
**样式规范**:
```dart
Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    // 第一行：会员图标 + 开通会员 + 箭头图标
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/phone_history/kissu3_vip_logo.webp',
          width: 16,
          height: 16,
        ),
        SizedBox(width: 4),
        Text('开通会员', style: TextStyle(fontSize: 13, color: Color(0xFFFF9500))),
        SizedBox(width: 4),
        Image.asset(
          'assets/phone_history/kissu3_vip_go.webp',
          width: 6,
          height: 6,
        ),
      ],
    ),
    SizedBox(height: 8),
    // 第二行：解锁对方屏幕使用报告
    Text(
      '解锁对方屏幕使用报告',
      style: TextStyle(fontSize: 12, color: Color(0xFF333333)),
    ),
  ],
)
```

---

## 📝 实现要点

### 1. 埋点时机
- ✅ 在跳转到 VIP 页面**之前**上报埋点
- ✅ 记录用户的开通会员意图
- ✅ 即使用户取消跳转或跳转失败，也能统计到点击行为

### 2. 异步处理
```dart
void _navigateToVipPage() async {
  // 1. 先上报埋点
  try {
    await TrackingService.trackMembershipOnly();
    print('✅ 会员可见按钮埋点上报成功');
  } catch (e) {
    print('❌ 会员可见按钮埋点上报失败: $e');
  }
  
  // 2. 再跳转页面
  Get.toNamed(KissuRoutePath.vip)?.then((_) {
    // 3. 返回后刷新状态
    _refreshVipStatus();
  });
}
```

### 3. 错误处理
- 使用 `try-catch` 捕获埋点异常
- 埋点失败不影响跳转功能
- 输出日志但不抛出异常
- 确保用户体验不受影响

### 4. 状态刷新
```dart
// VIP 页面返回后的处理流程
Get.toNamed(KissuRoutePath.vip)?.then((_) {
  // 1. 刷新用户信息
  UserManager.refreshUserInfo().then((success) {
    if (success) {
      print('✅ 会员状态刷新成功');
      // 2. 通知父组件刷新UI
      if (onVipStatusChanged != null) {
        onVipStatusChanged!();
      }
    }
  });
});
```

### 5. 组件通信
- 使用 `onVipStatusChanged` 回调通知父组件
- 父组件收到通知后重新加载数据
- 确保 UI 实时更新（会员按钮消失，数据显示）

---

## 🧪 测试验证

### 测试场景

#### 场景1：敏感记录-会员可查看按钮
**前置条件**: 非会员用户，有敏感记录

**操作步骤**:
1. 打开用机记录页面
2. 切换到"全部记录"或"敏感记录"标签
3. 找到敏感记录项（类型 3-8, 10-16, 21）
4. 点击右侧的"会员可查看"按钮

**预期结果**:
- ✅ 控制台输出 `✅ 会员可见按钮埋点上报成功`
- ✅ 跳转到 VIP 开通页面
- ✅ 埋点包含 `device_id`, `user_id`, `click_time`

#### 场景2：屏幕使用时长-会员可查看按钮
**前置条件**: 非会员用户，有屏幕使用时长记录

**操作步骤**:
1. 打开用机记录页面
2. 切换到"全部记录"标签
3. 找到屏幕使用时长记录（显示 `*~*点` 和 `****`）
4. 点击右侧的"会员可查看"按钮

**预期结果**:
- ✅ 控制台输出 `✅ 会员可见按钮埋点上报成功`
- ✅ 跳转到 VIP 开通页面
- ✅ 数据脱敏显示正确

#### 场景3：解锁记录-毛玻璃遮罩
**前置条件**: 非会员用户，有解锁记录

**操作步骤**:
1. 打开用机记录页面
2. 切换到"解锁记录"标签
3. 找到解锁记录项（类型 19）
4. 点击毛玻璃遮罩区域

**预期结果**:
- ✅ 控制台输出 `✅ 会员可见按钮埋点上报成功`
- ✅ 跳转到 VIP 开通页面
- ✅ 毛玻璃效果显示正确

#### 场景4：屏幕使用时长详情页-开通会员遮罩
**前置条件**: 非会员用户

**操作步骤**:
1. 打开用机记录页面
2. 切换到"全部记录"标签
3. 点击某个屏幕使用时长记录
4. 进入屏幕使用时长详情页
5. 点击柱状图区域的毛玻璃遮罩

**预期结果**:
- ✅ 控制台输出 `✅ 会员可见按钮埋点上报成功`
- ✅ 跳转到 VIP 开通页面
- ✅ 毛玻璃遮罩显示"开通会员"和"解锁对方屏幕使用报告"

#### 场景5：开通会员后返回
**前置条件**: 非会员用户

**操作步骤**:
1. 点击任意"会员可查看"按钮
2. 在 VIP 页面完成支付
3. 返回用机记录页面

**预期结果**:
- ✅ "会员可查看"按钮消失
- ✅ 敏感数据正常显示（不再脱敏）
- ✅ 毛玻璃遮罩消失
- ✅ 用户会员状态更新

#### 场景6：开通会员后未返回（取消支付）
**前置条件**: 非会员用户

**操作步骤**:
1. 点击任意"会员可查看"按钮
2. 在 VIP 页面取消支付
3. 返回用机记录页面

**预期结果**:
- ✅ "会员可查看"按钮仍然显示
- ✅ 敏感数据仍然脱敏
- ✅ 毛玻璃遮罩仍然显示
- ✅ 埋点已上报（记录了用户的开通意图）

#### 场景7：会员用户查看记录
**前置条件**: 已开通会员

**操作步骤**:
1. 打开用机记录页面
2. 浏览各类记录

**预期结果**:
- ✅ 不显示"会员可查看"按钮
- ✅ 不显示毛玻璃遮罩
- ✅ 所有数据正常显示
- ✅ 不触发会员可见埋点

### 验证清单
- [ ] 敏感记录的"会员可查看"按钮点击上报埋点
- [ ] 屏幕使用时长的"会员可查看"按钮点击上报埋点
- [ ] 解锁记录的毛玻璃遮罩点击上报埋点
- [ ] 屏幕使用时长详情页的毛玻璃遮罩点击上报埋点
- [ ] 埋点在跳转页面之前上报
- [ ] 埋点失败不影响跳转功能
- [ ] 会员用户不显示会员限制相关 UI
- [ ] VIP 页面返回后正确刷新会员状态
- [ ] 开通会员后 UI 自动更新
- [ ] 所有埋点包含 device_id 和 user_id
- [ ] 调试日志输出正确

---

## 📊 数据示例

### 会员可见按钮埋点数据
```json
{
  "event_name": "membership_only",
  "properties": {
    "device_id": "abc123...",
    "user_id": "12345",
    "click_time": "2025/10/27 15:30:25"
  }
}
```

---

## 🎯 数据分析价值

### 通过 `membership_only` 埋点可以分析：

1. **会员转化漏斗**
   - 非会员用户点击"会员可查看"的次数
   - 点击后实际开通会员的转化率
   - 识别转化漏斗中的流失环节

2. **功能吸引力分析**
   - 哪种记录类型最能激发用户开通会员的意愿
   - 敏感记录 vs 屏幕使用时长 vs 解锁记录的点击率对比
   - 最受关注的会员功能

3. **用户行为路径**
   - 用户在哪个页面/标签下最常点击"会员可查看"
   - 用户从点击到实际开通会员的时间间隔
   - 多次点击但未开通的用户特征

4. **会员价值感知**
   - 非会员用户对会员功能的兴趣程度
   - 不同用户群体的付费意愿差异
   - 会员功能的展示效果评估

5. **产品优化方向**
   - 是否需要更明显的会员功能引导
   - 会员价值是否充分展示
   - 定价策略的合理性
   - 免费内容和付费内容的平衡

6. **用户分层**
   - 高意向用户（多次点击"会员可查看"）
   - 低意向用户（很少点击）
   - 针对不同意向的用户制定不同的转化策略

---

## 📌 注意事项

### 1. 会员状态判断
```dart
// 判断是否显示会员限制
if (!UserManager.isVip) {
  // 显示"会员可查看"按钮或毛玻璃遮罩
}
```

### 2. 记录类型判断
```dart
// 判断是否是敏感类型
bool _shouldShowVipIcon() {
  final eventType = record.eventType;
  if (UserManager.isVip) {
    return false;
  }
  // 类型 3-8, 10-16, 21 是敏感类型
  return (eventType >= 3 && eventType <= 8) ||
         (eventType >= 10 && eventType <= 16) ||
         eventType == 21;
}
```

### 3. 数据脱敏规则
**屏幕使用时长记录脱敏**:
- 时间段: `*~*点`
- 使用时长: `****`
- 应用图标: 替换为 VIP 图标

**敏感记录脱敏**:
- 整个记录项显示毛玻璃遮罩（类型 19）
- 或显示"会员可查看"按钮（类型 3-8, 10-16, 21）

### 4. 埋点上报顺序
```
用户点击按钮/遮罩
    ↓
上报埋点（trackMembershipOnly）
    ↓
跳转到 VIP 页面
    ↓
用户在 VIP 页面操作（开通或取消）
    ↓
返回原页面
    ↓
刷新用户信息
    ↓
刷新 UI（如已开通，隐藏会员限制）
```

### 5. 回调链处理
```dart
// 层级关系
UsageReportPage
  └── AllRecordsPage
      └── GenericRecordItemWidget
          └── _navigateToVipPage()
              ↓
          onVipStatusChanged?.call()
              ↓
          父组件收到回调
              ↓
          Get.find<UsageReportController>().loadData()
              ↓
          重新加载数据，UI 自动更新
```

### 6. 调试日志
- 成功: `✅ 会员可见按钮埋点上报成功`
- 失败: `❌ 会员可见按钮埋点上报失败: $e`

---

## 🔗 相关文档
- [友盟埋点服务文档](./umeng_event_timing_feature.md)
- [用机记录页面埋点集成](./usage_report_page_tracking.md)
- [足迹页面绑定和会员按钮埋点](./footprint_bind_and_membership_buttons_tracking.md)

---

## ✅ 集成完成
- ✅ TrackingService 方法已添加（`trackMembershipOnly()`）
- ✅ generic_record_item.dart 中的 `_navigateToVipPage()` 已集成埋点
- ✅ screen_time_item.dart 中的 `_buildVipViewButton()` 已集成埋点
- ✅ type19_unlock_record_item.dart 中的 `_buildBlurOverlay()` 已集成埋点
- ✅ screen_time_detail_page.dart 中的毛玻璃遮罩已集成埋点
- ✅ 所有埋点在跳转页面之前上报
- ✅ 错误处理已完善
- ✅ 调试日志已添加
- ✅ 文档已创建

**最后更新**: 2025-10-27

