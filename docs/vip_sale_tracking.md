# 19元弹窗支付埋点实现文档

## 概述

本文档详细说明了19元VIP弹窗（折扣弹窗）的支付埋点实现。该埋点用于追踪用户从折扣弹窗入口购买VIP会员的行为。

---

## 埋点事件

### 19元弹窗 - 支付点击事件 (vip_sale)

**事件ID**: `vip_sale`

**事件类型**: 点击事件

**参数**:
- device_id: 虚拟用户ID（通过用户设备号生成）
- user_id: 用户ID
- click_time: 点击时间（格式：年/月/日 时:分:秒）
- vip_price: 会员金额（如：12.80）
- vip_name: 会员名称（如：双人月度会员）
- pay_type: 支付方式（如：支付宝）
- is_renew: 是否是续费（是续费、不是续费）
- previous_name: 上个页面名称
- pay_result: 支付结果（如：支付成功）

**触发场景**: 用户从折扣弹窗入口支付VIP成功时

**与 membership_open 的区别**: 
- `vip_sale`: 从折扣弹窗入口支付成功时上报
- `membership_open`: 从会员页面正常购买按钮支付成功时上报

---

## 实现详情

### 1. TrackingService 埋点方法

在 `lib/services/tracking_service.dart` 中添加了19元弹窗支付埋点方法：

```dart
/// 埋点：19元弹窗 - 支付点击事件
/// 
/// 事件ID: vip_sale
/// 
/// 参数：
/// - device_id: 虚拟用户ID
/// - user_id: 用户ID
/// - click_time: 点击时间
/// - vip_price: 会员金额（如：12.80）
/// - vip_name: 会员名称（如：双人月度会员）
/// - pay_type: 支付方式（如：支付宝）
/// - is_renew: 是否是续费（是续费、不是续费）
/// - previous_name: 上个页面名称
/// - pay_result: 支付结果（如：支付成功）
/// 
/// 触发场景：从19元弹窗支付成功时
static Future<void> trackVipSale({
  required String vipPrice,
  required String vipName,
  required String payType,
  required String isRenew,
  required String previousName,
  required String payResult,
}) async {
  final params = await _buildBaseParams();
  params['vip_price'] = vipPrice;
  params['vip_name'] = vipName;
  params['pay_type'] = payType;
  params['is_renew'] = isRenew;
  params['previous_name'] = previousName;
  params['pay_result'] = payResult;
  await _trackEvent('vip_sale', params, '19元弹窗支付');
}
```

---

### 2. VipController 集成

#### 2.1 添加弹窗入口标识

在 `lib/pages/vip/vip_controller.dart` 中添加了标识字段：

```dart
bool isFromDialogPurchase = false; // 是否从弹窗入口支付
```

#### 2.2 标记支付入口

**从弹窗购买**（`_purchaseVipFromDialog()`）:

```dart
void _purchaseVipFromDialog() async {
  // ...
  
  try {
    isPurchasing.value = true;
    
    // 标记为从弹窗入口支付
    isFromDialogPurchase = true;
    
    // 处理购买过程
    await _processPurchase(package);
    
  } finally {
    isPurchasing.value = false;
  }
}
```

**正常购买**（`purchaseVip()`）:

```dart
void purchaseVip() async {
  // ...
  
  try {
    isPurchasing.value = true;
    
    // 标记为非弹窗入口支付
    isFromDialogPurchase = false;
    
    // 处理购买过程
    await _processPurchase(package);
    
  } finally {
    isPurchasing.value = false;
  }
}
```

#### 2.3 支付成功后的埋点上报

在 `_handlePaymentSuccess()` 中根据入口标识选择上报不同的埋点：

```dart
Future<void> _handlePaymentSuccess(VipPackageModel package) async {
  try {
    _logger.i('支付成功，开始处理后续操作...');
    
    // 判断是否从弹窗入口支付
    if (isFromDialogPurchase) {
      // 上报19元弹窗埋点
      await _trackVipSale(package, '支付成功');
      debugPrint('✅ 19元弹窗支付埋点已上报');
    } else {
      // 上报开通会员埋点
      await _trackMembershipOpen(package, '支付成功');
    }
    
    // 刷新页面数据并返回上一页
    await _refreshMinePageAndReturn();
    
  } catch (e) {
    _logger.e('支付成功后处理异常: $e');
    Get.back();
  }
}
```

#### 2.4 埋点上报方法

添加了 `_trackVipSale()` 方法，与 `_trackMembershipOpen()` 参数完全一致：

```dart
/// 上报19元弹窗支付埋点
Future<void> _trackVipSale(VipPackageModel package, String payResult) async {
  try {
    // 获取支付方式
    final payType = selectedPaymentMethod.value == 0 ? '支付宝' : '微信';
    
    // 判断是否是续费
    final isRenew = UserManager.isVip ? '是续费' : '不是续费';
    
    await TrackingService.trackVipSale(
      vipPrice: package.vipPrice,
      vipName: package.title,
      payType: payType,
      isRenew: isRenew,
      previousName: previousPageName,
      payResult: payResult,
    );
    
    debugPrint('✅ 19元弹窗支付埋点上报成功: 套餐=${package.title}, 金额=${package.vipPrice}, 支付方式=$payType, 续费=$isRenew, 上个页面=$previousPageName, 结果=$payResult');
  } catch (e) {
    debugPrint('❌ 19元弹窗支付埋点上报失败: $e');
  }
}
```

---

## 弹窗触发逻辑

### 1. 折扣弹窗显示条件

折扣弹窗在以下情况显示：

1. **进入VIP页面时**: 如果第一个套餐有折扣（`hasDiscount = true`），延迟500ms后显示
2. **切换套餐时**: 如果选中的套餐有折扣，立即显示

```dart
// 加载VIP套餐数据
Future<void> _loadVipPackages() async {
  // ...
  if (vipPackages.isNotEmpty) {
    selectedPriceIndex.value = 0;
    
    // 检查第一个套餐是否有折扣
    final firstPackage = vipPackages[0];
    if (firstPackage.hasDiscount) {
      // 延迟显示折扣弹窗
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isDisposed && isPageVisible.value) {
          _showDiscountDialog(firstPackage);
        }
      });
    }
  }
}

// 切换套餐时检查折扣
void selectPrice(int index) {
  // ...
  final package = vipPackages[index];
  if (package.hasDiscount) {
    _showDiscountDialog(package);
  }
}
```

### 2. 折扣弹窗结构

`DiscountBottomSheet` 是一个从底部弹出的弹窗，包含：
- 折扣套餐信息
- 支付方式选择（支付宝/微信）
- 立即支付按钮

```dart
void _showDiscountDialog(VipPackageModel package) {
  showModalBottomSheet(
    context: Get.context!,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DiscountBottomSheet(
      package: package,
      onPayment: (int paymentMethod) {
        // 同步支付方式选择
        selectedPaymentMethod.value = paymentMethod;
        
        // 关闭弹窗
        Navigator.pop(context);
        
        // 执行购买（使用当前选中的套餐）
        _purchaseVipFromDialog();  // 标记为从弹窗支付
      },
    ),
  );
}
```

---

## 支付流程

### 完整支付流程图

```
用户进入VIP页面
    ↓
检查套餐是否有折扣
    ↓
[有折扣] → 显示折扣弹窗 → 用户选择支付方式 → 点击立即支付
    ↓                                                ↓
    ↓                                     设置 isFromDialogPurchase = true
    ↓                                                ↓
    ↓                                        调用 _processPurchase()
    ↓                                                ↓
    ↓                                          调用支付SDK
    ↓                                                ↓
    ↓                                         [支付成功]
    ↓                                                ↓
    ↓                                     调用 _handlePaymentSuccess()
    ↓                                                ↓
    ↓                                   判断 isFromDialogPurchase?
    ↓                                                ↓
    ↓                                           [是] → 上报 vip_sale 埋点
    ↓                                           [否] → 上报 membership_open 埋点
    ↓                                                ↓
    └────────────────────────────────────────────────┘
                           ↓
                刷新用户信息并返回上一页

[无折扣] → 正常购买流程 → 点击购买按钮
                           ↓
                设置 isFromDialogPurchase = false
                           ↓
                    （后续流程同上）
```

---

## 上个页面名称来源

`previousPageName` 和 `previousPageId` 从路由参数传递：

### 首页跳转到VIP页面

在 `lib/pages/home/home_controller.dart` 中：

```dart
void _showVipPurchaseDialog() {
  // ...
  DialogManager.showVipPurchase(
    context: currentContext,
    onConfirm: () {
      Get.toNamed(
        KissuRoutePath.vip,
        arguments: {
          'previousPageName': '首页',
          'previousPageId': 'home_page',
        },
      );
    },
  );
}
```

### 我的页面跳转到VIP页面

在 `lib/pages/mine/mine_controller.dart` 中：

```dart
Future<void> onRenewTap() async {
  // ...
  Get.toNamed(
    KissuRoutePath.vip,
    arguments: {
      'previousPageName': '我的页面',
      'previousPageId': 'my_page',
    },
  );
}
```

### VipController 接收参数

在 `lib/pages/vip/vip_controller.dart` 的 `onInit()` 中：

```dart
@override
void onInit() {
  super.onInit();
  
  // 从路由参数获取上个页面信息
  final args = Get.arguments as Map<String, dynamic>?;
  previousPageName = args?['previousPageName'] ?? '未知页面';
  previousPageId = args?['previousPageId'] ?? 'unknown';
  
  // ...
}
```

---

## 技术要点

### 1. 支付入口标识

使用 `isFromDialogPurchase` 布尔标识来区分支付入口：
- `true`: 从折扣弹窗支付 → 上报 `vip_sale`
- `false`: 从正常购买按钮支付 → 上报 `membership_open`

### 2. 参数完全一致

`vip_sale` 和 `membership_open` 的参数完全一致：
- vip_price: 会员金额
- vip_name: 会员名称
- pay_type: 支付方式
- is_renew: 是否是续费
- previous_name: 上个页面名称
- pay_result: 支付结果

### 3. 状态管理

- `isFromDialogPurchase` 在每次支付时都会明确设置
- 支付成功后根据这个标识选择上报不同的埋点
- 保证了埋点上报的准确性

### 4. 上个页面名称

`previousPageName` 从路由参数传递，确保：
- 从首页进入 → `previousName = '首页'`
- 从我的页面进入 → `previousName = '我的页面'`
- 其他入口 → `previousName = '未知页面'`

---

## 测试建议

### 1. 折扣弹窗显示测试

**测试场景**:
- 进入VIP页面，验证有折扣套餐时是否显示折扣弹窗
- 切换套餐，验证切换到有折扣套餐时是否显示折扣弹窗
- 验证无折扣套餐时不显示折扣弹窗

### 2. 支付流程测试

**从折扣弹窗支付**:
1. 点击折扣弹窗中的立即支付按钮
2. 完成支付流程
3. 验证支付成功后是否上报 `vip_sale` 埋点
4. 验证埋点参数是否正确：
   - `vip_price`: 套餐价格
   - `vip_name`: 套餐名称
   - `pay_type`: 支付方式（支付宝/微信）
   - `is_renew`: 续费状态
   - `previous_name`: 上个页面名称
   - `pay_result`: '支付成功'

**从正常购买按钮支付**:
1. 关闭折扣弹窗（如果有）
2. 点击页面底部的购买按钮
3. 完成支付流程
4. 验证支付成功后是否上报 `membership_open` 埋点（不是 `vip_sale`）

### 3. 参数验证测试

**会员金额测试**:
- 验证 `vip_price` 格式是否正确（如：12.80）
- 验证不同套餐的价格是否正确获取

**会员名称测试**:
- 验证 `vip_name` 是否正确获取套餐标题
- 验证中文名称是否正确传递

**支付方式测试**:
- 选择支付宝支付 → 验证 `pay_type = '支付宝'`
- 选择微信支付 → 验证 `pay_type = '微信'`

**续费状态测试**:
- 非会员用户购买 → 验证 `is_renew = '不是续费'`
- 会员用户续费 → 验证 `is_renew = '是续费'`

**上个页面名称测试**:
- 从首页进入 → 验证 `previous_name = '首页'`
- 从我的页面进入 → 验证 `previous_name = '我的页面'`

### 4. 友盟后台验证

登录友盟后台，查看 `vip_sale` 事件：
- 验证事件是否正确上报
- 验证各参数数据是否完整
- 对比 `vip_sale` 和 `membership_open` 的区别

---

## 注意事项

1. **埋点时机**: 埋点在支付成功后立即上报，在刷新用户信息之前

2. **入口标识**: 每次支付前都会明确设置 `isFromDialogPurchase`，确保埋点准确性

3. **参数一致性**: `vip_sale` 和 `membership_open` 参数完全一致，只是事件ID不同

4. **上个页面名称**: 需要确保所有跳转到VIP页面的地方都正确传递 `previousPageName` 参数

5. **错误处理**: `TrackingService` 内部已包含错误处理，即使埋点失败也不影响支付流程

6. **日志输出**: 
   - 成功: `✅ 19元弹窗支付埋点上报成功: 套餐=xxx, 金额=xxx, ...`
   - 失败: `❌ 19元弹窗支付埋点上报失败: [错误信息]`

---

## 修改的文件

### 1. lib/services/tracking_service.dart
- ✅ 新增 `trackVipSale()` 方法
- 位置: 在会员页面埋点方法之前

### 2. lib/pages/vip/vip_controller.dart
- ✅ 新增 `isFromDialogPurchase` 标识字段
- ✅ 在 `_purchaseVipFromDialog()` 中设置 `isFromDialogPurchase = true`
- ✅ 在 `purchaseVip()` 中设置 `isFromDialogPurchase = false`
- ✅ 在 `_handlePaymentSuccess()` 中根据标识选择上报不同埋点
- ✅ 新增 `_trackVipSale()` 方法

---

## 相关文档

- [会员页面埋点](./membership_page_tracking.md)
- [首页VIP弹窗埋点](./home_vip_alert_tracking.md)
- [TrackingService 使用指南](../lib/services/tracking_service.dart)

---

## 更新日期

2025-10-30

