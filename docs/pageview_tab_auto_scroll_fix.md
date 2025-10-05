# PageView 与标签栏联动滚动优化

## 问题描述

在"用机记录"页面中，当用户横向滑动 PageView 切换标签时，如果切换到的标签不在可视屏幕上，标签栏不会自动滚动到可视区域，导致用户无法看到当前选中的标签。

### 问题场景
1. 标签栏有多个标签（全部记录、敏感记录、解锁记录、屏幕使用时长、定位/足迹异常）
2. 当标签过多时，标签栏会横向滚动
3. 用户横向滑动 PageView 切换到右侧的标签（如"定位/足迹异常"）
4. **问题**：标签栏没有自动滚动，用户看不到选中的标签

## 解决方案

### 1. 添加标签栏滚动控制器

**文件：** `lib/pages/usage_report/usage_report_controller.dart`

```dart
// 标签栏滚动控制器
late ScrollController tabScrollController;

// 标签的 GlobalKey 列表，用于获取每个标签的位置和大小
final Map<int, GlobalKey> tabKeys = {};

@override
void onInit() {
  super.onInit();
  pageController = PageController(initialPage: 0);
  tabScrollController = ScrollController(); // 初始化标签栏滚动控制器
  debugPrint('📊 UsageReportController 初始化');
}

@override
void onClose() {
  pageController.dispose();
  tabScrollController.dispose(); // 释放滚动控制器
  debugPrint('📊 UsageReportController 销毁');
  super.onClose();
}
```

### 2. 自动生成标签的 GlobalKey

在 `visibleTabs` getter 中自动为每个标签生成 `GlobalKey`，用于后续获取标签的实际位置和大小：

```dart
List<String> get visibleTabs {
  final tabs = <String>['全部记录'];
  if (filterSensitiveRecord.value) tabs.add('敏感记录');
  if (filterUnlockRecord.value) tabs.add('解锁记录');
  if (filterScreenTime.value) tabs.add('屏幕使用时长');
  if (filterLocationAnomaly.value) tabs.add('定位/足迹异常');
  
  // 确保每个标签都有对应的 GlobalKey
  for (int i = 0; i < tabs.length; i++) {
    if (!tabKeys.containsKey(i)) {
      tabKeys[i] = GlobalKey();
    }
  }
  // 清理多余的 key
  tabKeys.removeWhere((key, value) => key >= tabs.length);
  
  return tabs;
}
```

### 3. 实现自动滚动逻辑

**核心功能：** `_scrollTabToVisible(int index)`

当标签切换时，自动滚动标签栏使目标标签可见：

```dart
/// 滚动标签到可视区域
void _scrollTabToVisible(int index) {
  if (!tabScrollController.hasClients) return;
  
  // 延迟执行，确保标签已渲染
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!tabScrollController.hasClients) return;
    
    // 尝试获取标签的实际位置和大小
    final tabKey = tabKeys[index];
    if (tabKey?.currentContext != null) {
      final RenderBox renderBox = tabKey!.currentContext!.findRenderObject() as RenderBox;
      final tabPosition = renderBox.localToGlobal(Offset.zero);
      final tabWidth = renderBox.size.width;
      
      // 获取标签栏的位置
      final scrollViewWidth = tabScrollController.position.viewportDimension;
      final currentOffset = tabScrollController.offset;
      final maxOffset = tabScrollController.position.maxScrollExtent;
      
      // 计算标签在滚动视图中的相对位置
      double? scrollTo;
      
      // 简化计算：获取标签左边缘相对于 ListView 起始位置的距离
      final tabLeftInScroll = currentOffset + (tabPosition.dx - 16); // 减去左侧 margin
      final tabRightInScroll = tabLeftInScroll + tabWidth;
      
      // 右侧占位宽度（渐变蒙版 + 间距）
      const rightPadding = 47.0;
      // 左侧留白
      const leftPadding = 20.0;
      
      if (tabLeftInScroll < currentOffset + leftPadding) {
        // 标签在左侧不可见区域，滚动使其显示在左侧
        scrollTo = (tabLeftInScroll - leftPadding).clamp(0.0, maxOffset);
      } else if (tabRightInScroll > currentOffset + scrollViewWidth - rightPadding) {
        // 标签在右侧不可见区域，滚动使其显示在右侧
        scrollTo = (tabRightInScroll - scrollViewWidth + rightPadding).clamp(0.0, maxOffset);
      }
      
      if (scrollTo != null) {
        tabScrollController.animateTo(
          scrollTo,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        debugPrint('📊 滚动标签栏到: $scrollTo (标签索引: $index, 标签宽度: $tabWidth)');
      }
    } else {
      // 如果无法获取实际位置，使用估算方法
      _scrollTabToVisibleByEstimate(index);
    }
  });
}

/// 使用估算方法滚动标签到可视区域（备用方案）
void _scrollTabToVisibleByEstimate(int index) {
  if (!tabScrollController.hasClients) return;
  
  final averageTabWidth = 90.0; // 平均宽度估算值
  final scrollViewWidth = tabScrollController.position.viewportDimension;
  
  final targetOffset = index * averageTabWidth;
  final currentOffset = tabScrollController.offset;
  final maxOffset = tabScrollController.position.maxScrollExtent;
  
  double? scrollTo;
  
  if (targetOffset < currentOffset) {
    scrollTo = (targetOffset - 20).clamp(0.0, maxOffset);
  } else if (targetOffset + averageTabWidth > currentOffset + scrollViewWidth - 47) {
    scrollTo = (targetOffset + averageTabWidth - scrollViewWidth + 67).clamp(0.0, maxOffset);
  }
  
  if (scrollTo != null) {
    tabScrollController.animateTo(
      scrollTo,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    debugPrint('📊 滚动标签栏到(估算): $scrollTo (标签索引: $index)');
  }
}
```

### 4. 在标签切换时调用滚动

在两个场景下调用自动滚动：

#### 场景 1：用户点击标签

```dart
void changeTab(int index) {
  _isProgrammaticPageChange = true;
  selectedTabIndex.value = index;
  pageController.animateToPage(
    index,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
  ).then((_) {
    _isProgrammaticPageChange = false;
  });
  _scrollTabToVisible(index); // 自动滚动标签栏
  debugPrint('📊 切换标签: $index');
}
```

#### 场景 2：用户滑动 PageView

```dart
void onPageChanged(int index) {
  if (!_isProgrammaticPageChange) {
    selectedTabIndex.value = index;
    _scrollTabToVisible(index); // 自动滚动标签栏
    debugPrint('📊 用户滑动到页面: $index');
  }
}
```

### 5. UI 层面绑定 ScrollController 和 GlobalKey

**文件：** `lib/pages/usage_report/usage_report_page.dart`

```dart
Obx(() {
  final tabs = controller.visibleTabs;
  final selectedIndex = controller.selectedTabIndex.value;
  return ListView(
    controller: controller.tabScrollController, // 绑定滚动控制器
    scrollDirection: Axis.horizontal,
    children: [
      const SizedBox(width: 2),
      ...List.generate(tabs.length, (index) {
        final isSelected = selectedIndex == index;
        return GestureDetector(
          key: controller.tabKeys[index], // 绑定 GlobalKey
          onTap: () => controller.changeTab(index),
          child: Container(
            // ... 标签样式
          ),
        );
      }),
      const SizedBox(width: 47),
    ],
  );
}),
```

## 技术细节

### 使用 GlobalKey 获取标签位置

- **优点**：可以获取标签的实际宽度和位置，精确计算
- **原理**：通过 `GlobalKey.currentContext` 获取 `RenderBox`，然后获取 `localToGlobal` 位置和 `size`

### 使用 WidgetsBinding.instance.addPostFrameCallback

- **原因**：确保标签已经渲染完成，再获取其位置和大小
- **时机**：在当前帧渲染完成后的下一帧执行

### 两种计算方法

1. **精确计算**（使用 GlobalKey）
   - 获取标签的实际位置和宽度
   - 精确判断标签是否在可视区域内
   - 优先使用这种方法

2. **估算计算**（备用方案）
   - 当 GlobalKey 无法获取位置时使用
   - 使用平均宽度估算标签位置
   - 确保功能稳定性

### 边界考虑

- **左侧留白**：20px，确保标签不紧贴左边缘
- **右侧占位**：47px（31px 渐变蒙版 + 16px 间距），确保标签不被遮挡
- **边界限制**：使用 `clamp(0.0, maxOffset)` 确保滚动位置在有效范围内

## 效果验证

### 测试步骤

1. 打开"我的-用机记录"页面
2. 确保所有筛选项都打开，标签栏显示 5 个标签
3. **测试场景 1：向右滑动**
   - 从"全部记录"向右滑动到"定位/足迹异常"
   - 观察标签栏是否自动滚动，使"定位/足迹异常"标签可见
4. **测试场景 2：向左滑动**
   - 从"定位/足迹异常"向左滑动到"全部记录"
   - 观察标签栏是否自动滚动，使"全部记录"标签可见
5. **测试场景 3：点击标签**
   - 点击不可见的标签
   - 观察标签栏是否自动滚动到对应位置

### 预期效果

- ✅ 标签切换时，标签栏自动滚动到可视区域
- ✅ 滚动动画流畅（300ms，easeInOut 曲线）
- ✅ 标签显示位置合理（不紧贴边缘，不被遮挡）
- ✅ 适配不同屏幕尺寸

## 相关文件

### 修改的文件
- `lib/pages/usage_report/usage_report_controller.dart` - 添加滚动控制逻辑
- `lib/pages/usage_report/usage_report_page.dart` - 绑定滚动控制器和 GlobalKey

## 技术要点总结

1. **ScrollController 管理**
   - 在 Controller 中创建和管理 `ScrollController`
   - 在 `onClose` 中正确释放资源

2. **GlobalKey 动态管理**
   - 使用 `Map<int, GlobalKey>` 存储标签的 Key
   - 在标签数量变化时自动更新 Key 列表
   - 清理无效的 Key，防止内存泄漏

3. **精确的位置计算**
   - 使用 `RenderBox.localToGlobal` 获取绝对位置
   - 使用 `RenderBox.size` 获取实际大小
   - 考虑滚动偏移量和可视区域宽度

4. **备用方案**
   - 当 GlobalKey 无法获取位置时使用估算方法
   - 确保功能在各种情况下都能正常工作

5. **用户体验优化**
   - 使用动画过渡（300ms）
   - 考虑边距和遮挡区域
   - 避免过度滚动

## 更新日志

**2025-10-04**
- 实现标签栏自动滚动功能
- 使用 GlobalKey 精确获取标签位置
- 添加备用估算方法确保稳定性
- 优化用户体验，考虑边界和动画

