# 会员挽留弹窗埋点实现文档

## 📋 概述
本文档记录了**会员页面挽留弹窗**（`VipCancelRetentionDialog`）的友盟埋点集成实现。挽留弹窗在用户点击会员页面返回按钮时弹出，提供"全部解锁"和"下次再说"两个选项。

---

## 🎯 埋点事件

### 会员挽留弹窗点击事件
**事件名称**: `vipretention_popup`  
**事件类型**: 点击事件  
**触发时机**: 用户在会员页面点击返回时弹出挽留弹窗，用户点击弹窗中的任一按钮

#### 参数说明
| 参数名 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `device_id` | String | 虚拟用户ID（通过设备号生成） | "abc123..." |
| `user_id` | String | 用户ID | "12345" |
| `button_name` | String | 点击按钮名称 | "全部解锁", "下次再说" |
| `click_time` | String | 点击时间（年/月/日 时:分:秒） | "2025/10/30 14:30:45" |
| `vip_price` | String | 会员金额 | "12.80" |
| `vip_name` | String | 会员名称 | "双人月度会员" |
| `pay_type` | String | 支付方式 | "微信", "支付宝" |
| `is_renew` | String | 是否是续费 | "是续费", "不是续费" |
| `previous_name` | String | 上个页面名称 | "我的页面" |
| `pay_result` | String | 支付结果 | "点击支付", "支付成功", "下次再说" |

#### 实现位置
- **Service**: `TrackingService.trackVipRetentionPopup()`
- **Controller**: `VipController`
- **Dialog**: `VipCancelRetentionDialog`
- **上报时机**: 
  - 点击"全部解锁"时立即上报（`pay_result` = "点击支付"）
  - 支付成功后再次上报（`pay_result` = "支付成功"）
  - 点击"下次再说"时立即上报（`pay_result` = "下次再说"）

---

## 🔧 实现细节

### 1. TrackingService 中的埋点方法

在 `lib/services/tracking_service.dart` 中添加了挽留弹窗埋点方法：

```dart
/// 埋点：会员挽留弹窗 - 点击事件
/// 
/// 事件ID: vipretention_popup
/// 
/// 参数：
/// - device_id: 虚拟用户ID（通过用户设备号生成）
/// - user_id: 用户ID
/// - button_name: 点击按钮名称（"全部解锁"或"下次再说"）
/// - click_time: 点击时间（格式：年/月/日 时:分:秒）
/// - vip_price: 会员金额（如：12.80）
/// - vip_name: 会员名称（如：双人月度会员）
/// - pay_type: 支付方式（如：支付宝、微信）
/// - is_renew: 是否是续费（是续费、不是续费）
/// - previous_name: 上个页面名称
/// - pay_result: 支付结果（如：支付成功、点击支付、下次再说）
static Future<void> trackVipRetentionPopup({
  required String buttonName,
  required String vipPrice,
  required String vipName,
  required String payType,
  required String isRenew,
  required String previousName,
  required String payResult,
}) async {
  final params = await _buildBaseParams();
  params['button_name'] = buttonName;
  params['vip_price'] = vipPrice;
  params['vip_name'] = vipName;
  params['pay_type'] = payType;
  params['is_renew'] = isRenew;
  params['previous_name'] = previousName;
  params['pay_result'] = payResult;
  await _trackEvent('vipretention_popup', params, '会员挽留弹窗');
}
```

### 2. VipController 中的埋点方法

在 `lib/pages/vip/vip_controller.dart` 中添加了两个私有方法：

#### 2.1 点击"全部解锁"的埋点
```dart
/// 上报挽留弹窗埋点 - 点击"全部解锁"
Future<void> _trackRetentionDialogUnlock(VipPackageModel package, String payResult) async {
  try {
    // 获取支付方式
    final payType = selectedPaymentMethod.value == 0 ? '微信' : '支付宝';
    
    // 判断是否是续费
    final isRenew = UserManager.isVip ? '是续费' : '不是续费';
    
    await TrackingService.trackVipRetentionPopup(
      buttonName: '全部解锁',
      vipPrice: package.vipPrice,
      vipName: package.title,
      payType: payType,
      isRenew: isRenew,
      previousName: previousPageName,
      payResult: payResult,
    );
    
    debugPrint('✅ 会员挽留弹窗埋点上报成功: 按钮=全部解锁, 套餐=${package.title}, 金额=${package.vipPrice}, 支付方式=$payType, 续费=$isRenew, 上个页面=$previousPageName, 结果=$payResult');
  } catch (e) {
    debugPrint('❌ 会员挽留弹窗埋点上报失败: $e');
  }
}
```

#### 2.2 点击"下次再说"的埋点
```dart
/// 上报挽留弹窗埋点 - 点击"下次再说"
Future<void> _trackRetentionDialogCancel() async {
  try {
    // 获取当前选中的套餐，如果没有则使用第一个
    VipPackageModel? package;
    if (selectedPriceIndex.value >= 0 && selectedPriceIndex.value < vipPackages.length) {
      package = vipPackages[selectedPriceIndex.value];
    } else if (vipPackages.isNotEmpty) {
      package = vipPackages.first;
    }
    
    // 如果没有套餐数据，使用默认值
    final vipPrice = package?.vipPrice ?? '0.00';
    final vipName = package?.title ?? '未知套餐';
    
    // 获取支付方式
    final payType = selectedPaymentMethod.value == 0 ? '微信' : '支付宝';
    
    // 判断是否是续费
    final isRenew = UserManager.isVip ? '是续费' : '不是续费';
    
    await TrackingService.trackVipRetentionPopup(
      buttonName: '下次再说',
      vipPrice: vipPrice,
      vipName: vipName,
      payType: payType,
      isRenew: isRenew,
      previousName: previousPageName,
      payResult: '下次再说',
    );
    
    debugPrint('✅ 会员挽留弹窗埋点上报成功: 按钮=下次再说, 套餐=$vipName, 金额=$vipPrice, 支付方式=$payType, 续费=$isRenew, 上个页面=$previousPageName');
  } catch (e) {
    debugPrint('❌ 会员挽留弹窗埋点上报失败: $e');
  }
}
```

### 3. 埋点调用流程

#### 3.1 显示挽留弹窗时的绑定
```dart
/// 显示挽留弹窗
Future<bool> _showRetentionDialog() async {
  // ...
  final result = await VipCancelRetentionDialog.show(
    context: context,
    onUnlock: () {
      debugPrint('💫 用户点击"全部解锁"');
      _handleUnlockFromRetention();
    },
    onCancel: () {
      debugPrint('💫 用户点击"下次再说"');
      _trackRetentionDialogCancel();  // 上报"下次再说"埋点
    },
    barrierDismissible: true,
  );
  // ...
}
```

#### 3.2 点击"全部解锁"的处理
```dart
/// 从挽留弹窗点击"全部解锁"
Future<void> _handleUnlockFromRetention() async {
  // ...
  // 标记为从挽留弹窗入口支付
  isFromRetentionDialog = true;
  retentionDialogPackage = firstPackage;
  
  // 上报挽留弹窗埋点 - 点击"全部解锁"（pay_result = "点击支付"）
  await _trackRetentionDialogUnlock(firstPackage, '点击支付');
  
  // 执行支付流程
  await _processPurchase(firstPackage);
  // ...
}
```

#### 3.3 支付成功后的处理
```dart
/// 支付成功后的处理
Future<void> _handlePaymentSuccess(VipPackageModel package) async {
  // 判断是否从挽留弹窗入口支付
  if (isFromRetentionDialog && retentionDialogPackage != null) {
    // 上报挽留弹窗支付成功埋点（pay_result = "支付成功"）
    await _trackRetentionDialogUnlock(retentionDialogPackage!, '支付成功');
    
    // 重置标记
    isFromRetentionDialog = false;
    retentionDialogPackage = null;
  }
  // ...
}
```

---

## 📊 埋点上报时机

### 场景1: 用户点击"全部解锁"并成功支付
1. **第一次上报**: 用户点击"全部解锁"按钮时
   - `button_name` = "全部解锁"
   - `pay_result` = "点击支付"

2. **第二次上报**: 用户支付成功后
   - `button_name` = "全部解锁"
   - `pay_result` = "支付成功"

### 场景2: 用户点击"下次再说"
1. **上报一次**: 用户点击"下次再说"按钮时
   - `button_name` = "下次再说"
   - `pay_result` = "下次再说"

---

## 🔍 数据示例

### 示例1: 点击"全部解锁"并支付成功

**第一次上报（点击按钮时）:**
```json
{
  "event_id": "vipretention_popup",
  "device_id": "abc123...",
  "user_id": "12345",
  "button_name": "全部解锁",
  "click_time": "2025/10/30 14:30:45",
  "vip_price": "12.80",
  "vip_name": "双人月度会员",
  "pay_type": "微信",
  "is_renew": "不是续费",
  "previous_name": "我的页面",
  "pay_result": "点击支付"
}
```

**第二次上报（支付成功时）:**
```json
{
  "event_id": "vipretention_popup",
  "device_id": "abc123...",
  "user_id": "12345",
  "button_name": "全部解锁",
  "click_time": "2025/10/30 14:31:20",
  "vip_price": "12.80",
  "vip_name": "双人月度会员",
  "pay_type": "微信",
  "is_renew": "不是续费",
  "previous_name": "我的页面",
  "pay_result": "支付成功"
}
```

### 示例2: 点击"下次再说"

```json
{
  "event_id": "vipretention_popup",
  "device_id": "abc123...",
  "user_id": "12345",
  "button_name": "下次再说",
  "click_time": "2025/10/30 14:30:45",
  "vip_price": "19.80",
  "vip_name": "双人季度会员",
  "pay_type": "支付宝",
  "is_renew": "是续费",
  "previous_name": "我的页面",
  "pay_result": "下次再说"
}
```

---

## ✅ 测试验证

### 测试步骤

1. **进入会员页面**
   - 从"我的页面"点击会员卡片，进入会员页面
   - 观察控制台，确认 `previousPageName` 为"我的页面"

2. **测试"下次再说"**
   - 点击会员页面的返回按钮
   - 在弹出的挽留弹窗中点击"下次再说"
   - 观察控制台日志：
     ```
     ✅ 会员挽留弹窗埋点上报成功: 按钮=下次再说, 套餐=xxx, 金额=xxx, 支付方式=xxx, 续费=xxx, 上个页面=我的页面
     ```

3. **测试"全部解锁"并取消支付**
   - 点击会员页面的返回按钮
   - 在弹出的挽留弹窗中点击"全部解锁"
   - 观察控制台日志：
     ```
     ✅ 会员挽留弹窗埋点上报成功: 按钮=全部解锁, 套餐=xxx, 金额=xxx, 支付方式=微信, 续费=xxx, 上个页面=我的页面, 结果=点击支付
     ```
   - 在支付页面点击取消
   - 确认没有第二次埋点上报

4. **测试"全部解锁"并完成支付**
   - 点击会员页面的返回按钮
   - 在弹出的挽留弹窗中点击"全部解锁"
   - 观察第一次埋点上报（`pay_result` = "点击支付"）
   - 完成支付流程
   - 观察第二次埋点上报（`pay_result` = "支付成功"）

### 验证要点

- ✅ `device_id` 和 `user_id` 正确填充
- ✅ `button_name` 根据点击按钮正确设置
- ✅ `click_time` 格式为 "年/月/日 时:分:秒"
- ✅ `vip_price` 和 `vip_name` 来自实际选择的套餐
- ✅ `pay_type` 根据选择的支付方式设置
- ✅ `is_renew` 根据用户VIP状态正确设置
- ✅ `previous_name` 为跳转前的页面名称
- ✅ `pay_result` 根据不同场景正确设置

---

## 🎯 关键特性

1. **完整的支付流程跟踪**: 从点击"全部解锁"到支付成功，都有埋点记录
2. **准确的支付方式记录**: 默认使用微信支付
3. **续费状态识别**: 根据用户当前VIP状态判断是否续费
4. **套餐信息完整**: 记录套餐价格、名称等详细信息
5. **来源页面追踪**: 记录从哪个页面进入会员页面

---

## 📝 注意事项

1. **挽留弹窗与其他支付入口的区分**
   - 使用 `isFromRetentionDialog` 标记区分挽留弹窗支付
   - 使用 `isFromDialogPurchase` 标记区分19元弹窗支付
   - 普通支付流程不设置这些标记

2. **套餐信息获取**
   - "全部解锁"默认使用第一个套餐
   - "下次再说"使用当前选中的套餐，如无则使用第一个

3. **支付方式默认值**
   - 挽留弹窗点击"全部解锁"时，默认设置为微信支付

4. **标记重置**
   - 支付成功后重置 `isFromRetentionDialog` 和 `retentionDialogPackage`
   - 普通支付流程开始时也会重置这些标记

---

## 🔗 相关文件

- `lib/services/tracking_service.dart` - 埋点服务
- `lib/pages/vip/vip_controller.dart` - VIP页面控制器
- `lib/widgets/dialogs/vip_cancel_retention_dialog.dart` - 挽留弹窗组件
- `api.md` - 埋点需求文档

---

## 📅 更新日志

- **2025/10/30**: 初始版本，完成会员挽留弹窗埋点实现

