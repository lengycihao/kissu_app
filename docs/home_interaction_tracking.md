# 首页交互埋点实现文档

## 概述

本文档详细说明了在首页中实现的3个交互埋点事件：屏视图按钮、岛视图按钮和底部导航。这些埋点用于追踪用户在首页的交互行为。

---

## 实现的埋点事件

### 1. 屏视图按钮 - 点击事件 (home_banner)

**事件ID**: `home_banner`

**事件类型**: 点击事件

**参数**:
- device_id: 虚拟用户ID
- user_id: 用户ID
- is_drag: 是否手动滑动（1是、0否）
- click_time: 点击时间（格式：年/月/日 时:分:秒）
- click_type: 点击类型（定位、足迹、绑定、会员）
- is_vip: 是否会员（是会员、不是会员）
- is_bind: 是否绑定（是绑定、未绑定）

**触发场景**: 用户点击屏视图中的 Banner 卡片时

**代码位置**:
- 埋点方法: `lib/services/tracking_service.dart` - `TrackingService.trackHomeBannerClick()`
- 调用位置: 
  - `lib/pages/home/home_page.dart` - `_buildBanner()` (未绑定状态)
  - `lib/pages/home/home_page.dart` - `_buildBannerBind()` (已绑定状态)

**实现逻辑**:

1. **未绑定状态** (`_buildBanner()`):
   - 定位 Banner (index=0): 点击显示绑定弹窗
   - 足迹 Banner (index=1): 点击显示绑定弹窗
   - 天气 Banner (index=2): 无点击事件

2. **已绑定状态** (`_buildBannerBind()`):
   - 定位 Banner (index=0): 点击跳转到定位页面（带会员检查）
   - 足迹 Banner (index=1): 点击跳转到足迹页面
   - 天气 Banner (index=2): 无点击事件

3. **手动滑动检测**:
   - 使用 `Listener.onPointerDown` 检测用户触摸
   - 触摸时标记 `isBannerManuallyDragged = true`
   - 自动播放切换后重置为 `false`

**实现代码示例**:

```dart
// 未绑定状态 - 屏视图 Banner
Widget _buildBanner() {
  return Listener(
    onPointerDown: (_) {
      // 用户触摸了 banner，标记为手动滑动
      controller.isBannerManuallyDragged.value = true;
    },
    child: Swiper(
      itemBuilder: (BuildContext context, int index) {
        return GestureDetector(
          onTap: () async {
            if (index < 2) {
              // 获取点击类型
              final clickType = index == 0 ? '定位' : '足迹';
              
              // 上报埋点：屏视图 Banner 点击
              await TrackingService.trackHomeBannerClick(
                isDrag: controller.isBannerManuallyDragged.value,
                clickType: clickType,
                isVip: UserManager.isVip,
                isBind: false, // 未绑定状态
              );
              
              // 显示绑定弹窗
              CustomBottomDialog.show(
                context: context,
                caller: BindingDialogCaller.home,
              );
            }
          },
          // ... Banner UI
        );
      },
      // ...
    ),
  );
}

// 已绑定状态 - 屏视图 Banner
Widget _buildBannerBind() {
  return Listener(
    onPointerDown: (_) {
      controller.isBannerManuallyDragged.value = true;
    },
    child: Swiper(
      itemBuilder: (BuildContext context, int index) {
        return GestureDetector(
          onTap: () async {
            if (index == 0) {
              // 定位 Banner
              await TrackingService.trackHomeBannerClick(
                isDrag: controller.isBannerManuallyDragged.value,
                clickType: '定位',
                isVip: UserManager.isVip,
                isBind: true,
              );
              VipNavigationHelper.navigateToLocationWithVipCheck();
            } else if (index == 1) {
              // 足迹 Banner
              await TrackingService.trackHomeBannerClick(
                isDrag: controller.isBannerManuallyDragged.value,
                clickType: '足迹',
                isVip: UserManager.isVip,
                isBind: true,
              );
              Get.to(() => TrackPage(), binding: TrackBinding());
            }
          },
          // ... Banner UI
        );
      },
      // ...
    ),
  );
}
```

**TrackingService 方法**:

```dart
static Future<void> trackHomeBannerClick({
  required bool isDrag,
  required String clickType,
  required bool isVip,
  required bool isBind,
}) async {
  try {
    final params = await _buildBaseParams();
    params['is_drag'] = isDrag ? '1' : '0';
    params['click_type'] = clickType;
    params['is_vip'] = isVip ? '是会员' : '不是会员';
    params['is_bind'] = isBind ? '是绑定' : '未绑定';
    await _trackEvent('home_banner', params, '屏视图Banner点击');
  } catch (e) {
    debugPrint('❌ 屏视图Banner点击埋点：上报数据失败 - $e');
  }
}
```

---

### 2. 岛视图按钮 - 点击事件 (home_island)

**事件ID**: `home_island`

**事件类型**: 点击事件

**参数**:
- device_id: 虚拟用户ID
- user_id: 用户ID
- click_time: 点击时间（格式：年/月/日 时:分:秒）
- is_vip: 是否会员（是会员、不是会员）
- is_bind: 是否绑定（是绑定、未绑定）
- click_type: 点击类型（定位、足迹、绑定、会员）

**触发场景**: 用户点击岛视图中的按钮时

**代码位置**:
- 埋点方法: `lib/services/tracking_service.dart` - `TrackingService.trackHomeIslandClick()`
- 调用位置: `lib/pages/home/home_page.dart` - `_AnimatedIslandView` 中的按钮点击

**实现逻辑**:

岛视图包含3个按钮：
1. **足迹按钮**: 点击跳转到足迹页面
2. **定位按钮**: 点击跳转到定位页面（带会员检查）
3. **天气按钮**: 无点击事件（不显示箭头）

**实现代码示例**:

```dart
// 岛视图中的按钮
Column(
  children: [
    // 足迹按钮
    IslandViewButton(
      iconAsset: "assets/home_list_type_foot.webp",
      title: "TA的足迹",
      value: stayCountText,
      valueColor: Color(0xffFF6591),
      onTap: () async {
        // 上报埋点：岛视图按钮点击
        await TrackingService.trackHomeIslandClick(
          clickType: '足迹',
          isVip: UserManager.isVip,
          isBind: controller.isBound.value,
        );
        
        Get.to(() => TrackPage(), binding: TrackBinding());
      },
    ),
    SizedBox(height: 4),
    // 定位按钮
    IslandViewButton(
      iconAsset: "assets/home_list_type_location.webp",
      title: "我们相距",
      value: distanceText,
      valueColor: Color(0xff6D5DFF),
      onTap: () async {
        // 上报埋点：岛视图按钮点击
        await TrackingService.trackHomeIslandClick(
          clickType: '定位',
          isVip: UserManager.isVip,
          isBind: controller.isBound.value,
        );
        
        // 距离按钮 - 添加会员检查
        VipNavigationHelper.navigateToLocationWithVipCheck();
      },
    ),
    SizedBox(height: 4),
    // 天气按钮（无点击事件）
    IslandViewButton(
      iconAsset: "assets/home_list_type_weather.webp",
      title: "当前天气",
      value: weatherText,
      valueColor: Color(0xff00D1C1),
      // 没有 onTap，不显示箭头
    ),
  ],
)
```

**TrackingService 方法**:

```dart
static Future<void> trackHomeIslandClick({
  required String clickType,
  required bool isVip,
  required bool isBind,
}) async {
  try {
    final params = await _buildBaseParams();
    params['click_type'] = clickType;
    params['is_vip'] = isVip ? '是会员' : '不是会员';
    params['is_bind'] = isBind ? '是绑定' : '未绑定';
    await _trackEvent('home_island', params, '岛视图按钮点击');
  } catch (e) {
    debugPrint('❌ 岛视图按钮点击埋点：上报数据失败 - $e');
  }
}
```

---

### 3. 底部导航 - 点击事件 (bottom_navigation)

**事件ID**: `bottom_navigation`

**事件类型**: 点击事件

**参数**:
- device_id: 虚拟用户ID
- user_id: 用户ID
- click_time: 点击时间（格式：年/月/日 时:分:秒）
- bottom_name: 底部导航名称（如：定位、足迹）

**触发场景**: 用户点击首页底部导航按钮时

**代码位置**:
- 埋点方法: `lib/services/tracking_service.dart` - `TrackingService.trackBottomNavigationClick()`
- 调用位置: `lib/pages/home/home_controller.dart` - `HomeController.onButtonTap()`

**实现逻辑**:

底部导航包含4个按钮：
1. **定位** (index=0): 跳转到定位页面（带会员检查）
2. **足迹** (index=1): 跳转到足迹页面
3. **用机记录** (index=2): 跳转到用机记录页面
4. **我的** (index=3): 跳转到我的页面

**实现代码示例**:

```dart
// HomeController 中的底部导航点击
void onButtonTap(int index) async {
  selectedIndex.value = index;
  debugPrint("🔍 底部导航按钮 $index 被点击");

  // 获取底部导航名称
  String bottomName = '';
  switch (index) {
    case 0:
      bottomName = '定位';
      break;
    case 1:
      bottomName = '足迹';
      break;
    case 2:
      bottomName = '用机记录';
      break;
    case 3:
      bottomName = '我的';
      break;
  }

  // 埋点：底部导航点击
  if (bottomName.isNotEmpty) {
    await TrackingService.trackBottomNavigationClick(bottomName: bottomName);
  }

  // 执行导航逻辑
  switch (index) {
    case 0:
      // 定位（新版）- 添加会员检查
      VipNavigationHelper.navigateToLocationWithVipCheck();
      break;
    case 1:
      // 地图
      await Get.to(
        () => TrackPage(),
        binding: TrackBinding(),
        transition: Transition.downToUp,
      );
      onPageResumed();
      break;
    case 2:
      // 用机记录
      await Get.to(
        () => const UsageReportPage(),
        binding: UsageReportBinding(),
        transition: Transition.downToUp,
      );
      onPageResumed();
      break;
    case 3:
      // 我的
      _navigateToMinePage();
      break;
  }
}
```

**TrackingService 方法**:

```dart
static Future<void> trackBottomNavigationClick({
  required String bottomName,
}) async {
  try {
    final params = await _buildBaseParams();
    params['bottom_name'] = bottomName;
    await _trackEvent('bottom_navigation', params, '底部导航点击');
  } catch (e) {
    debugPrint('❌ 底部导航点击埋点：上报数据失败 - $e');
  }
}
```

---

## 技术要点

### 1. 手动滑动检测

屏视图 Banner 使用 `Listener.onPointerDown` 检测用户触摸：
- **手动滑动**: 用户触摸 Banner → `isBannerManuallyDragged = true` → `is_drag = '1'`
- **自动播放**: Banner 自动切换 → 延迟重置 → `is_drag = '0'`

```dart
Listener(
  onPointerDown: (_) {
    controller.isBannerManuallyDragged.value = true;
  },
  child: Swiper(
    onIndexChanged: (index) {
      controller.currentSwiperIndex.value = index;
      // 延迟重置手动滑动标记
      Future.delayed(const Duration(milliseconds: 100), () {
        controller.isBannerManuallyDragged.value = false;
      });
    },
    // ...
  ),
)
```

### 2. 动态获取用户状态

所有埋点都动态获取用户的会员和绑定状态：
- **is_vip**: 通过 `UserManager.isVip` 实时获取
- **is_bind**: 通过 `controller.isBound.value` 或直接判断绑定状态

```dart
await TrackingService.trackHomeBannerClick(
  isDrag: controller.isBannerManuallyDragged.value,
  clickType: clickType,
  isVip: UserManager.isVip,  // 动态获取会员状态
  isBind: controller.isBound.value,  // 动态获取绑定状态
);
```

### 3. 统一的埋点接口

所有埋点使用 `TrackingService` 统一封装：
- 自动获取 `device_id`, `user_id`, `click_time` 基础参数
- 添加事件特有参数
- 统一错误处理和日志输出

### 4. 埋点时机

- **屏视图/岛视图**: 在按钮 `onTap` 中先上报埋点，再执行跳转
- **底部导航**: 在 `onButtonTap` 中先上报埋点，再执行导航逻辑

---

## 修改的文件

### 1. lib/services/tracking_service.dart
- ✅ 已实现3个静态埋点方法：
  - `trackHomeBannerClick()` - 屏视图 Banner 点击
  - `trackHomeIslandClick()` - 岛视图按钮点击
  - `trackBottomNavigationClick()` - 底部导航点击

### 2. lib/pages/home/home_page.dart
- ✅ 屏视图 Banner（未绑定状态）：`_buildBanner()`
  - 定位 Banner: 点击上报 `click_type='定位'`，显示绑定弹窗
  - 足迹 Banner: 点击上报 `click_type='足迹'`，显示绑定弹窗

- ✅ 屏视图 Banner（已绑定状态）：`_buildBannerBind()`
  - 定位 Banner: 点击上报 `click_type='定位'`，跳转定位页
  - 足迹 Banner: 点击上报 `click_type='足迹'`，跳转足迹页

- ✅ 岛视图按钮：`_AnimatedIslandView`
  - 足迹按钮: 点击上报 `click_type='足迹'`，跳转足迹页
  - 定位按钮: 点击上报 `click_type='定位'`，跳转定位页

### 3. lib/pages/home/home_controller.dart
- ✅ 底部导航点击：`onButtonTap()`
  - 定位按钮: 上报 `bottom_name='定位'`
  - 足迹按钮: 上报 `bottom_name='足迹'`
  - 用机记录按钮: 上报 `bottom_name='用机记录'`
  - 我的按钮: 上报 `bottom_name='我的'`

---

## 注意事项

1. **点击类型扩展**: 目前实现了"定位"和"足迹"两种点击类型，如果后续需要添加"绑定"或"会员"类型的 Banner/按钮，只需要在点击时传入对应的 `click_type` 参数即可。

2. **会员检查**: 定位相关的跳转都使用 `VipNavigationHelper.navigateToLocationWithVipCheck()` 进行会员权限检查。

3. **埋点时机**: 
   - 所有埋点都在执行业务逻辑（跳转、弹窗）**之前**上报
   - 使用 `await` 确保埋点上报完成

4. **绑定状态判断**:
   - 屏视图根据 `controller.isBound.value` 显示不同的 Banner Widget
   - 岛视图直接使用 `controller.isBound.value` 作为 `is_bind` 参数

5. **天气 Banner/按钮**: 天气相关的 Banner 和按钮都没有点击事件，不需要埋点。

---

## 测试建议

### 1. 屏视图 Banner 埋点测试

**未绑定状态测试**:
- 点击"定位" Banner，验证埋点上报：
  - `click_type='定位'`, `is_bind='未绑定'`, `is_drag='1'`（手动点击）
  - 是否正确显示绑定弹窗
- 点击"足迹" Banner，验证埋点上报：
  - `click_type='足迹'`, `is_bind='未绑定'`, `is_drag='1'`
- 等待 Banner 自动切换，然后点击，验证 `is_drag='0'`

**已绑定状态测试**:
- 点击"定位" Banner，验证埋点上报：
  - `click_type='定位'`, `is_bind='是绑定'`, `is_vip` 状态正确
  - 是否正确跳转到定位页
- 点击"足迹" Banner，验证埋点上报：
  - `click_type='足迹'`, `is_bind='是绑定'`
  - 是否正确跳转到足迹页

### 2. 岛视图按钮埋点测试

- 点击"足迹"按钮，验证埋点上报：
  - `click_type='足迹'`, `is_vip` 和 `is_bind` 状态正确
  - 是否正确跳转到足迹页
- 点击"定位"按钮，验证埋点上报：
  - `click_type='定位'`, `is_vip` 和 `is_bind` 状态正确
  - 是否正确跳转到定位页

### 3. 底部导航埋点测试

依次点击4个底部导航按钮，验证：
- "定位"按钮: `bottom_name='定位'`
- "足迹"按钮: `bottom_name='足迹'`
- "用机记录"按钮: `bottom_name='用机记录'`
- "我的"按钮: `bottom_name='我的'`

验证每次点击后是否正确跳转到对应页面。

### 4. 友盟后台验证

登录友盟后台，查看以下事件：
- `home_banner`: 验证各参数（is_drag, click_type, is_vip, is_bind）
- `home_island`: 验证各参数（click_type, is_vip, is_bind）
- `bottom_navigation`: 验证 bottom_name 参数

---

## 更新日期

2025-10-30

