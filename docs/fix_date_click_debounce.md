# 用机记录日期连续点击防抖修复

## 问题描述

在用机记录页面连续点击日期时出现以下错误：

```
[LogManager] Not initialized. Message: DeviceUtil not initialized, using fallback deviceId
I/flutter (19408): ❌ Request GET /v2/get/sensitive/record - 4ms - Status: 210
I/flutter (19408): 📡 API响应状态: false
I/flutter (19408): 📡 API响应码: 210
I/flutter (19408): 📡 API响应消息: Empty response data
I/flutter (19408): ❌ 用机记录获取失败: Empty response data
I/flutter (19408): ❌ 数据加载失败: Empty response data
I/flutter (19408): CustomToast: Failed to get overlay from context: No Overlay widget found.
```

## 问题分析

### 根本原因

1. **缺少防抖机制**：每次点击日期都立即发起新的API请求，连续点击时会产生多个并发请求
2. **Context问题**：Toast显示使用`Get.context`而不是`pageContext`，在某些时机可能找不到正确的Overlay
3. **重复请求**：相同日期被重复选择时也会发起请求

### 具体问题

- **210状态码**：可能是由于请求太频繁或数据为空导致
- **Toast显示失败**：`Get.context`可能在某些时刻不可用或没有正确的Overlay ancestor
- **性能问题**：多个并发请求浪费资源并可能导致数据混乱

## 解决方案

### 1. 添加防抖机制

在`UsageReportController`中添加防抖Timer：

```dart
// 防抖Timer
Timer? _debounceTimer;
```

在`changeDate`方法中实现防抖逻辑（300ms延迟）：

```dart
// 取消之前的防抖Timer
_debounceTimer?.cancel();

// 使用防抖加载数据，避免连续点击时多次请求
_debounceTimer = Timer(const Duration(milliseconds: 300), () {
  debugPrint('📊 防抖Timer触发，开始加载数据');
  loadData();
});
```

### 2. 避免相同日期重复请求

在`changeDate`方法开始处添加日期检查：

```dart
// 如果选择的是相同日期，直接返回
final newDateStr = DateFormat('yyyy-MM-dd').format(date);
final currentDateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);

if (newDateStr == currentDateStr) {
  debugPrint('📊 相同日期，跳过切换: $newDateStr');
  return;
}
```

### 3. 使用正确的Context显示Toast

创建`_showToastSafely`方法，优先使用`pageContext`：

```dart
/// 安全地显示Toast
void _showToastSafely(String message) {
  try {
    // 优先使用pageContext（已在页面中保存）
    CustomToast.show(pageContext, message);
  } catch (e) {
    debugPrint('⚠️ 使用pageContext显示Toast失败，尝试其他方式: $e');
    // fallback到Get.context
    try {
      if (Get.context != null) {
        CustomToast.show(Get.context!, message);
      } else {
        // 最终fallback：使用OKToastUtil
        OKToastUtil.show(message);
      }
    } catch (e2) {
      debugPrint('⚠️ 所有Toast显示方式都失败: $e2');
      // 最后使用print输出
      print('Toast消息: $message');
    }
  }
}
```

在`loadData`中使用这个方法：

```dart
} else {
  debugPrint('❌ 数据加载失败: ${result.msg}');
  // 使用pageContext而不是Get.context，确保有正确的Overlay
  _showToastSafely(result.msg ?? '数据加载失败');
}
```

### 4. 清理资源

在`onClose`方法中清理防抖Timer：

```dart
@override
void onClose() {
  hideTooltip();
  _debounceTimer?.cancel();  // ✅ 清理防抖Timer
  pageController.dispose();
  tabScrollController.dispose();
  debugPrint('📊 UsageReportController 销毁');
  super.onClose();
}
```

## 修改文件

- `lib/pages/usage_report/usage_report_controller.dart`
  - 添加`dart:async`导入
  - 添加`_debounceTimer`字段
  - 修改`changeDate`方法（添加防抖和相同日期检查）
  - 修改`loadData`方法（使用`_showToastSafely`）
  - 添加`_showToastSafely`方法
  - 修改`onClose`方法（清理Timer）

## 效果

修复后的效果：

1. ✅ **防止多次请求**：连续点击日期时，只有最后一次点击（300ms后）才会触发API请求
2. ✅ **Toast正常显示**：使用正确的Context，确保Toast能正常显示错误信息
3. ✅ **避免不必要的请求**：相同日期不会重复请求
4. ✅ **更好的用户体验**：减少不必要的网络请求和错误提示
5. ✅ **资源及时清理**：页面销毁时正确清理Timer资源

## 测试建议

1. **快速连续点击不同日期**：验证只有最后选择的日期会发起请求
2. **点击相同日期**：验证不会发起重复请求
3. **网络异常时点击日期**：验证Toast能正常显示错误信息
4. **快速进入/退出页面**：验证没有内存泄漏

## 注意事项

- 防抖延迟设置为300ms，这是一个合理的值。如需调整，可修改`Timer(const Duration(milliseconds: 300), ...)`
- `pageContext`在`UsageReportPage`的`build`方法中设置：`controller.pageContext = context`
- Toast显示有多层fallback机制，确保在各种情况下都能给用户反馈

## 相关文件

- `lib/pages/usage_report/usage_report_controller.dart` - Controller层修复
- `lib/pages/usage_report/usage_report_page.dart` - 页面已正确设置pageContext
- `lib/widgets/custom_toast_widget.dart` - Toast组件（已有完善的fallback机制）
- `lib/network/public/usage_record_api.dart` - API层（无需修改）

## 参考

- Flutter防抖（Debounce）模式
- GetX状态管理最佳实践
- Flutter Overlay使用注意事项

