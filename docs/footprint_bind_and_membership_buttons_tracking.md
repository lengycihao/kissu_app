# 足迹页面绑定和会员按钮埋点集成文档

## 📋 概述
本文档记录了**足迹页面**（`TrackPage`）中两个关键按钮的友盟埋点集成实现：
1. **立即去绑定按钮** - 未绑定状态下引导用户绑定伴侣
2. **开通会员按钮** - 非会员状态下引导用户开通会员

---

## 🎯 埋点事件列表

### 1. 立即去绑定按钮埋点
**事件名称**: `footprint_bind_now_button`  
**事件类型**: 点击事件  
**触发时机**: 用户在未绑定状态下点击"立即去绑定"按钮时

#### 参数说明
| 参数名 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `device_id` | String | 虚拟用户ID（通过设备号生成） | "abc123..." |
| `user_id` | String | 用户ID | "12345" |
| `click_time` | String | 操作时间 | "2025-01-15 14:30:25" |

#### 实现位置
- **Service**: `TrackingService.trackFootprintBindNowButton()`
- **Page**: `_TrackPageContentState._buildDateModule()` in `TrackPage`
- **上报时机**: 按钮点击时立即上报，在显示绑定弹窗之前

#### 代码实现
```dart
// 未绑定时显示带背景图的绑定模块
return Container(
  margin: EdgeInsets.symmetric(horizontal: 14),
  height: 125,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    image: DecorationImage(
      image: AssetImage('assets/3.0/kissu3_track__bind_bg.webp'),
      fit: BoxFit.cover,
    ),
  ),
  child: Stack(
    children: [
      // 立即去绑定按钮（在背景图上）
      Positioned(
        right: 12,
        top: 12,
        child: GestureDetector(
          onTap: () async {
            // 上报立即去绑定按钮埋点
            await _trackBindNowButton();
            // 显示绑定弹窗
            if (mounted && context.mounted) {
              CustomBottomDialog.show(context: context).then((_) {
                // 绑定完成后刷新当前用户数据
                widget.controller.refreshCurrentUserData();
              });
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFFFF88AA),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              '立即去绑定',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
      // ... 日期选择器
    ],
  ),
);

/// 上报立即去绑定按钮埋点
Future<void> _trackBindNowButton() async {
  try {
    await TrackingService.trackFootprintBindNowButton();
    DebugUtil.info('✅ 足迹页面-立即去绑定按钮埋点上报成功');
  } catch (e) {
    DebugUtil.error('❌ 足迹页面-立即去绑定按钮埋点上报失败: $e');
  }
}
```

---

### 2. 开通会员按钮埋点
**事件名称**: `footprint_open_membership_button`  
**事件类型**: 点击事件  
**触发时机**: 用户在非会员状态下，查看另一半数据时，点击会员蒙版上的开通会员按钮

#### 参数说明
| 参数名 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `device_id` | String | 虚拟用户ID（通过设备号生成） | "abc123..." |
| `user_id` | String | 用户ID | "12345" |
| `click_time` | String | 操作时间 | "2025-01-15 14:35:10" |

#### 实现位置
- **Service**: `TrackingService.trackFootprintOpenMembershipButton()`
- **Page**: `_TrackPageContentState.build()` in `TrackPage` - VIP遮罩层
- **上报时机**: 按钮点击时立即上报，在跳转到VIP页面之前

#### 代码实现
```dart
// VIP遮罩层 - 覆盖整个滚动区域（带毛玻璃效果）
// 非会员时，只有在查看另一半时才显示会员蒙版，查看自己时不显示
Obx(() {
  final isSelf = widget.controller.isOneself.value;
  final showMask = !UserManager.isVip && isSelf != 1;
  
  return showMask
    ? Positioned.fill(
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 10.0,
              sigmaY: 10.0,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF).withOpacity(0.2),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: GestureDetector(
                onTap: () {
                  // 点击遮罩层时跳转到VIP页面
                  Get.toNamed(KissuRoutePath.vip);
                },
                child: Container(
                  color: Colors.transparent,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 开通会员按钮图片
                        GestureDetector(
                          onTap: () async {
                            // 上报开通会员按钮埋点
                            await _trackOpenMembershipButton();
                            // 点击图片时跳转到VIP页面
                            Get.toNamed(KissuRoutePath.vip);
                          },
                          child: Image.asset(
                            'assets/kissu_go_bind.webp',
                            width: 111,
                            height: 34,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 提示文字
                        const Text(
                          '实时查看"另一半"的位置和行程轨迹',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      )
    : const SizedBox.shrink();
})

/// 上报开通会员按钮埋点
Future<void> _trackOpenMembershipButton() async {
  try {
    await TrackingService.trackFootprintOpenMembershipButton();
    DebugUtil.info('✅ 足迹页面-开通会员按钮埋点上报成功');
  } catch (e) {
    DebugUtil.error('❌ 足迹页面-开通会员按钮埋点上报失败: $e');
  }
}
```

---

## 🔧 TrackingService 方法

### 方法列表

#### 1. trackFootprintBindNowButton
```dart
/// 埋点：足迹页 - 立即去绑定按钮
/// 
/// 事件ID: footprint_bind_now_button
/// 
/// 参数：
/// - device_id: 虚拟用户ID
/// - user_id: 用户ID
/// - click_time: 操作时间
static Future<void> trackFootprintBindNowButton() async {
  final params = await _buildBaseParams();
  await _trackEvent('footprint_bind_now_button', params, '足迹页面-立即去绑定按钮');
}
```

#### 2. trackFootprintOpenMembershipButton
```dart
/// 埋点：足迹页 - 开通会员按钮
/// 
/// 事件ID: footprint_open_membership_button
/// 
/// 参数：
/// - device_id: 虚拟用户ID
/// - user_id: 用户ID
/// - click_time: 操作时间
static Future<void> trackFootprintOpenMembershipButton() async {
  final params = await _buildBaseParams();
  await _trackEvent('footprint_open_membership_button', params, '足迹页面-开通会员按钮');
}
```

---

## 📝 实现要点

### 1. 立即去绑定按钮

#### UI 设计
- **位置**: 日期选择器上方背景图的右上角
- **样式**: 粉色圆角按钮（`#FF88AA`）
- **文字**: "立即去绑定"，白色文字，12px，中等粗细
- **显示条件**: 仅在未绑定状态下显示

#### 交互流程
1. 用户点击"立即去绑定"按钮
2. **立即上报埋点**（在任何UI操作之前）
3. 显示绑定弹窗（`CustomBottomDialog`）
4. 用户在弹窗中输入对方匹配码或使用其他绑定方式
5. 绑定成功后，弹窗关闭
6. 刷新当前用户数据（`refreshCurrentUserData()`）
7. 页面自动更新，隐藏绑定引导，显示正常内容

#### 关键点
- 埋点在最开始上报，确保即使后续操作失败也能记录用户行为
- 使用 `mounted` 和 `context.mounted` 检查，确保在组件有效时才显示弹窗
- 绑定完成后刷新数据，让页面立即反映最新状态

### 2. 开通会员按钮

#### UI 设计
- **位置**: 会员蒙版中央
- **样式**: 图片按钮（`assets/kissu_go_bind.webp`），111x34px
- **蒙版效果**: 毛玻璃模糊效果（sigmaX: 10.0, sigmaY: 10.0）+ 半透明白色背景
- **提示文字**: "实时查看"另一半"的位置和行程轨迹"
- **显示条件**: 
  - 用户为非会员（`!UserManager.isVip`）
  - 且正在查看另一半的数据（`isOneself != 1`）

#### 交互流程
1. 用户点击会员蒙版上的按钮图片
2. **立即上报埋点**（在跳转之前）
3. 跳转到 VIP 页面（`Get.toNamed(KissuRoutePath.vip)`）
4. 用户在 VIP 页面完成购买
5. 返回足迹页面
6. 页面自动更新，移除会员蒙版，显示完整内容

#### 关键点
- 埋点在跳转之前上报，记录用户转化意向
- 会员蒙版有两个点击区域：
  - 整个遮罩层点击 → 跳转到VIP页面（无埋点）
  - 按钮图片点击 → **上报埋点** + 跳转到VIP页面
- 按钮图片的点击事件会阻止冒泡到遮罩层
- 非会员查看自己的数据时不显示蒙版，让用户可以查看自己的足迹

---

## 🎨 按钮显示条件

### 立即去绑定按钮
```
┌─────────────────────────────────────────────────────────┐
│  条件判断：widget.controller.isBindPartner.value         │
└─────────────────────┬───────────────────────────────────┘
                      │
          ┌───────────┴──────────┐
          │                      │
      已绑定 ✅               未绑定 ❌
          │                      │
          ▼                      ▼
  ┌───────────────┐      ┌──────────────────┐
  │ 显示普通日期  │      │ 显示带背景图的   │
  │ 选择器        │      │ 绑定引导模块     │
  └───────────────┘      │                  │
                         │ - 背景图         │
                         │ - 立即去绑定按钮 │ ← 点击上报埋点
                         │ - 日期选择器     │
                         └──────────────────┘
```

### 开通会员按钮
```
┌─────────────────────────────────────────────────────────┐
│  条件判断：!UserManager.isVip && isOneself != 1          │
└─────────────────────┬───────────────────────────────────┘
                      │
          ┌───────────┴──────────────┐
          │                          │
    是会员 ✅                   非会员 ❌
    或查看自己                  且查看另一半
          │                          │
          ▼                          ▼
  ┌───────────────┐          ┌──────────────────┐
  │ 不显示蒙版    │          │ 显示会员蒙版     │
  │ 正常显示内容  │          │                  │
  └───────────────┘          │ - 毛玻璃模糊     │
                             │ - 开通会员按钮   │ ← 点击上报埋点
                             │ - 提示文字       │
                             └──────────────────┘
```

---

## 🧪 测试验证

### 测试场景

#### 场景1：未绑定用户点击立即去绑定按钮
**前置条件**: 用户未绑定伴侣

**操作步骤**:
1. 打开足迹页面
2. 观察日期选择器上方的背景图区域
3. 点击右上角的"立即去绑定"按钮

**预期结果**:
- ✅ 控制台输出 `✅ 足迹页面-立即去绑定按钮埋点上报成功`
- ✅ 弹出绑定弹窗（`CustomBottomDialog`）
- ✅ 弹窗显示匹配码输入、二维码分享等绑定选项
- ✅ 完成绑定后，背景图和绑定按钮消失，显示普通日期选择器

#### 场景2：已绑定用户不显示立即去绑定按钮
**前置条件**: 用户已绑定伴侣

**操作步骤**:
1. 打开足迹页面
2. 观察日期选择器区域

**预期结果**:
- ✅ 不显示背景图
- ✅ 不显示"立即去绑定"按钮
- ✅ 显示普通的白色日期选择器

#### 场景3：非会员点击开通会员按钮
**前置条件**: 
- 用户为非会员
- 已绑定伴侣
- 当前查看另一半的数据

**操作步骤**:
1. 打开足迹页面
2. 切换到另一半的头像
3. 观察页面出现毛玻璃模糊蒙版
4. 点击蒙版中央的按钮图片

**预期结果**:
- ✅ 控制台输出 `✅ 足迹页面-开通会员按钮埋点上报成功`
- ✅ 跳转到 VIP 页面
- ✅ 可以查看会员套餐和购买选项

#### 场景4：非会员查看自己的数据不显示会员蒙版
**前置条件**: 
- 用户为非会员
- 已绑定伴侣

**操作步骤**:
1. 打开足迹页面
2. 确保当前显示的是自己的头像（左边头像）
3. 观察页面内容

**预期结果**:
- ✅ 不显示会员蒙版
- ✅ 可以正常查看自己的足迹数据
- ✅ 切换到另一半头像时才显示会员蒙版

#### 场景5：会员用户不显示开通会员按钮
**前置条件**: 用户为会员

**操作步骤**:
1. 打开足迹页面
2. 切换到另一半的头像
3. 观察页面内容

**预期结果**:
- ✅ 不显示会员蒙版
- ✅ 不显示开通会员按钮
- ✅ 可以正常查看另一半的足迹数据

### 验证清单
- [ ] 未绑定状态下显示"立即去绑定"按钮
- [ ] 点击"立即去绑定"按钮上报埋点
- [ ] 点击后弹出绑定弹窗
- [ ] 绑定完成后刷新数据并隐藏绑定按钮
- [ ] 已绑定状态下不显示"立即去绑定"按钮
- [ ] 非会员查看另一半时显示会员蒙版和按钮
- [ ] 点击开通会员按钮上报埋点
- [ ] 点击后跳转到VIP页面
- [ ] 会员用户不显示会员蒙版
- [ ] 非会员查看自己时不显示会员蒙版
- [ ] 所有埋点包含 device_id 和 user_id
- [ ] 操作时间格式正确（yyyy-MM-dd HH:mm:ss）
- [ ] 埋点失败不影响业务功能

---

## 📊 数据示例

### 立即去绑定按钮埋点数据
```json
{
  "event_name": "footprint_bind_now_button",
  "properties": {
    "device_id": "abc123...",
    "user_id": "12345",
    "click_time": "2025-01-15 14:30:25"
  }
}
```

### 开通会员按钮埋点数据
```json
{
  "event_name": "footprint_open_membership_button",
  "properties": {
    "device_id": "abc123...",
    "user_id": "12345",
    "click_time": "2025-01-15 14:35:10"
  }
}
```

---

## 🎯 页面状态说明

### 足迹页面的四种状态组合

| 绑定状态 | 会员状态 | 查看对象 | 显示效果 |
|---------|---------|---------|---------|
| 未绑定 ❌ | - | - | 显示背景图 + 立即去绑定按钮 |
| 已绑定 ✅ | 非会员 ❌ | 自己 | 正常显示，无蒙版 |
| 已绑定 ✅ | 非会员 ❌ | 另一半 | 显示会员蒙版 + 开通会员按钮 |
| 已绑定 ✅ | 会员 ✅ | 另一半 | 正常显示，无蒙版 |

### 按钮互斥性
- **立即去绑定按钮** 只在未绑定状态下显示
- **开通会员按钮** 只在已绑定 + 非会员 + 查看另一半时显示
- 两个按钮**不会同时显示**

---

## 📌 注意事项

### 1. 埋点上报顺序
- 立即去绑定按钮埋点在**显示弹窗之前**上报
- 开通会员按钮埋点在**跳转页面之前**上报
- 即使后续操作失败，用户行为也应该被记录

### 2. UI 层级关系
- 立即去绑定按钮在 Stack 中位于日期选择器上方
- 会员蒙版使用 `Positioned.fill` 覆盖整个滚动区域
- 会员蒙版的 z-index 最高，覆盖所有内容

### 3. 显示条件判断
- 绑定状态通过 `widget.controller.isBindPartner.value` 判断
- 会员状态通过 `UserManager.isVip` 判断
- 查看对象通过 `widget.controller.isOneself.value` 判断（1: 自己, 0: 另一半）

### 4. 数据刷新时机
- 绑定完成后调用 `refreshCurrentUserData()` 刷新数据
- 从VIP页面返回时，页面会自动重建，读取最新的会员状态
- 使用 `Obx` 包裹条件渲染，确保响应式更新

### 5. 图片资源
- 绑定模块背景图: `assets/3.0/kissu3_track__bind_bg.webp`
- 开通会员按钮图: `assets/kissu_go_bind.webp` (111x34px)

---

## 🔗 相关文档
- [足迹页面埋点集成（页面浏览和滑动状态）](./footprint_page_tracking.md)
- [足迹页面停留点点击和关闭埋点](./footprint_stop_point_tracking.md)
- [定位页开通会员按钮埋点](./location_page_open_membership_button_tracking.md)
- [定位页立即去绑定按钮埋点](./location_map_buttons_tracking.md)
- [友盟埋点服务文档](./umeng_event_timing_feature.md)

---

## ✅ 集成完成
- ✅ TrackingService 方法已添加
- ✅ 立即去绑定按钮UI已实现
- ✅ 立即去绑定按钮埋点已集成
- ✅ 开通会员按钮埋点已集成
- ✅ 调试日志已完善
- ✅ 文档已创建

**最后更新**: 2025-01-15

