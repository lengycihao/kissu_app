import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kissu_app/models/screen_time_model.dart';
import 'package:kissu_app/models/unlock_record_model.dart';
import 'package:kissu_app/models/usage_record_api_model.dart';
import 'package:kissu_app/model/system_info_model.dart';
import 'package:kissu_app/network/public/usage_record_api.dart';
import 'package:kissu_app/network/public/phone_history_api.dart';
import 'package:kissu_app/utils/usage_record_converter.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/utils/vip_navigation_helper.dart';

class UsageReportController extends GetxController {
  final UsageRecordApi _usageRecordApi = UsageRecordApi();
  final PhoneHistoryApi _phoneHistoryApi = PhoneHistoryApi();
  
  // 选中的日期索引 (6对应今天，在DateSelector的recentDates数组中)
  final selectedDateIndex = 6.obs;
  
  // 当前选中的日期
  final selectedDate = DateTime.now().obs;

  // 当前选中的标签索引
  final selectedTabIndex = 0.obs;

  // PageView 控制器
  late PageController pageController;

  // 标签栏滚动控制器
  late ScrollController tabScrollController;

  // 标签的 GlobalKey 列表，用于获取每个标签的位置和大小
  final Map<int, GlobalKey> tabKeys = {};

  // 是否正在程序切换页面（用于区分用户滑动和程序切换）
  bool _isProgrammaticPageChange = false;

  // 筛选抽屉显示状态
  final isFilterDrawerVisible = false.obs;

  // 筛选项状态
  final filterSensitiveRecord = true.obs; // 敏感记录（默认选中）
  final filterUnlockRecord = true.obs; // 解锁记录（默认选中）
  final filterScreenTime = true.obs; // 屏幕使用时长（默认选中）
  final filterLocationAnomaly = true.obs; // 定位/足迹异常（默认选中）
  final filterHighSensitive = true.obs; // 高敏感（默认选中）
  final filterMediumSensitive = true.obs; // 中敏感（默认选中）
  final filterLowSensitive = true.obs; // 低敏感（默认选中）
  final filterShowDataCount = false.obs; // 显示数据数值

  // API数据存储
  final Rx<UsageRecordApiResponse?> apiData = Rx<UsageRecordApiResponse?>(null);
  final isLoading = false.obs;
  
  // 转换后的UI数据
  Rx<ScreenTimeDetailModel?> screenTimeData = Rx<ScreenTimeDetailModel?>(null);
  Rx<UnlockRecordDetailModel?> unlockRecordData = Rx<UnlockRecordDetailModel?>(null);
  Rx<RecordSection?> sensitiveRecordData = Rx<RecordSection?>(null);
  Rx<RecordSection?> locationAnomalyData = Rx<RecordSection?>(null);
  Rx<RecordSection?> allRecordData = Rx<RecordSection?>(null);
  Rx<HalfLocationMobileDevice?> deviceInfo = Rx<HalfLocationMobileDevice?>(null);

  // 系统设置相关
  final systemInfo = Rxn<SystemInfoModel>();
  final isSystemInfoLoading = false.obs;
  final isSystemSwitchLoading = false.obs;

  // 用户绑定状态（响应式）
  final isUserBound = false.obs;

  // Tooltip相关
  OverlayEntry? _overlayEntry;

  // 页面Context（用于Overlay）
  late BuildContext pageContext;

  // 动态标签列表（根据筛选状态计算）
  List<String> get visibleTabs {
    final tabs = <String>[];
    
    // 获取各类数据的数量
    final allRecordCount = allRecordData.value?.data.length ?? 0;
    final sensitiveRecordCount = sensitiveRecordData.value?.data.length ?? 0;
    final unlockRecordCount = unlockRecordData.value?.records.length ?? 0;
    final screenTimeCount = screenTimeData.value?.records.length ?? 0;
    final locationAnomalyCount = locationAnomalyData.value?.data.length ?? 0;
    
    // 根据是否显示数据数值来决定标签文本
    if (filterShowDataCount.value) {
      // 显示数据数值
      tabs.add('全部记录($allRecordCount)');
      if (filterSensitiveRecord.value) tabs.add('敏感记录($sensitiveRecordCount)');
      if (filterUnlockRecord.value) tabs.add('解锁记录($unlockRecordCount)');
      if (filterScreenTime.value) tabs.add('屏幕使用时长($screenTimeCount)');
      if (filterLocationAnomaly.value) tabs.add('定位/足迹异常($locationAnomalyCount)');
    } else {
      // 不显示数据数值
      tabs.add('全部记录');
      if (filterSensitiveRecord.value) tabs.add('敏感记录');
      if (filterUnlockRecord.value) tabs.add('解锁记录');
      if (filterScreenTime.value) tabs.add('屏幕使用时长');
      if (filterLocationAnomaly.value) tabs.add('定位/足迹异常');
    }
    
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

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: 0);
    tabScrollController = ScrollController();
    debugPrint('📊 UsageReportController 初始化');
    
    // 初始化用户绑定状态
    _updateUserBindStatus();
    
    // 默认加载当天数据
    loadData();
    
    // // 检查并请求屏幕使用时长权限
    // _checkAndRequestPermission();
  }
  
  /// 检查并请求屏幕使用时长权限
  // Future<void> _checkAndRequestPermission() async {
  //   debugPrint('📊 检查屏幕使用时长权限...');
    
  //   // 检查是否已授权
  //   final bool isGranted = await _permissionService.isUsageAccessGranted();
    
  //   if (isGranted) {
  //     debugPrint('✅ 屏幕使用时长权限已授权');
  //     // 加载数据
  //     loadData();
  //   } else {
  //     debugPrint('❌ 屏幕使用时长权限未授权，显示引导弹窗');
  //     // 显示权限引导弹窗
  //     _showPermissionDialog();
  //   }
  // }
  
  // /// 显示权限引导弹窗
  // void _showPermissionDialog() {
  //   Get.dialog(
  //     AlertDialog(
  //       title: const Text('需要使用统计权限'),
  //       content: SingleChildScrollView(
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             const Text(
  //               '为了给您提供详细的屏幕使用报告，需要授予"使用情况访问权限"。',
  //               style: TextStyle(fontSize: 14),
  //             ),
  //             const SizedBox(height: 16),
  //             const Text(
  //               '授权步骤：',
  //               style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
  //             ),
  //             const SizedBox(height: 8),
  //             _buildPermissionStep('1', '点击下方"去授权"按钮'),
  //             _buildPermissionStep('2', '在列表中找到"Kissu"应用'),
  //             _buildPermissionStep('3', '点击并开启权限开关'),
  //             const SizedBox(height: 12),
  //             Container(
  //               padding: const EdgeInsets.all(10),
  //               decoration: BoxDecoration(
  //                 color: const Color(0xFFFFF8E1),
  //                 borderRadius: BorderRadius.circular(8),
  //                 border: Border.all(color: const Color(0xFFFFB74D), width: 1),
  //               ),
  //               child: Row(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: const [
  //                   Icon(Icons.info_outline, color: Color(0xFFFF9800), size: 18),
  //                   SizedBox(width: 8),
  //                   Expanded(
  //                     child: Text(
  //                       '如果列表中找不到应用，请尝试向下滚动或使用搜索功能查找"Kissu"',
  //                       style: TextStyle(fontSize: 12, color: Color(0xFFE65100)),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Get.back(),
  //           child: const Text('取消'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () async {
  //             Get.back();
  //             // 请求权限
  //             await _requestPermission();
  //           },
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: const Color(0xFF6750A4),
  //             foregroundColor: Colors.white,
  //           ),
  //           child: const Text('去授权'),
  //         ),
  //       ],
  //     ),
  //     barrierDismissible: false,
  //   );
  // }
  
  // /// 构建权限步骤指示
  // Widget _buildPermissionStep(String number, String text) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 6),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Container(
  //           width: 22,
  //           height: 22,
  //           alignment: Alignment.center,
  //           decoration: BoxDecoration(
  //             color: const Color(0xFF6750A4),
  //             borderRadius: BorderRadius.circular(11),
  //           ),
  //           child: Text(
  //             number,
  //             style: const TextStyle(
  //               color: Colors.white,
  //               fontSize: 12,
  //               fontWeight: FontWeight.bold,
  //             ),
  //           ),
  //         ),
  //         const SizedBox(width: 10),
  //         Expanded(
  //           child: Padding(
  //             padding: const EdgeInsets.only(top: 3),
  //             child: Text(
  //               text,
  //               style: const TextStyle(fontSize: 13),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  
  // /// 请求权限
  // Future<void> _requestPermission() async {
  //   debugPrint('📊 请求屏幕使用时长权限...');
    
  //   final bool granted = await _permissionService.requestUsageAccessPermission();
    
  //   if (granted) {
  //     debugPrint('✅ 权限授予成功');
  //     if (Get.context != null) {
  //       CustomToast.show(Get.context!, '权限授予成功');
  //     }
  //     // 加载数据
  //     loadData();
  //   } else {
  //     debugPrint('❌ 权限授予失败');
  //     if (Get.context != null) {
  //       CustomToast.show(Get.context!, '未授予权限，部分功能无法使用');
  //     }
  //   }
  // }

  @override
  void onClose() {
    hideTooltip();
    pageController.dispose();
    tabScrollController.dispose();
    debugPrint('📊 UsageReportController 销毁');
    super.onClose();
  }

  /// 切换标签
  void changeTab(int index) {
    _isProgrammaticPageChange = true;
    selectedTabIndex.value = index;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ).then((_) {
      // 动画完成后重置标志位
      _isProgrammaticPageChange = false;
    });
    _scrollTabToVisible(index);
    debugPrint('📊 切换标签: $index');
  }

  /// PageView 页面变化回调（仅在用户手动滑动时更新选中状态）
  void onPageChanged(int index) {
    if (!_isProgrammaticPageChange) {
      selectedTabIndex.value = index;
      _scrollTabToVisible(index);
      debugPrint('📊 用户滑动到页面: $index');
      
      // 页面切换时隐藏筛选抽屉
      hideFilterDrawer();
    }
  }

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
        // tabPosition.dx 是标签相对于屏幕的位置
        // 我们需要计算标签在 ListView 中的位置
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

  /// 切换筛选抽屉显示状态
  void toggleFilterDrawer() {
    isFilterDrawerVisible.value = !isFilterDrawerVisible.value;
    debugPrint('📊 筛选抽屉: ${isFilterDrawerVisible.value ? "显示" : "隐藏"}');
  }

  /// 隐藏筛选抽屉
  void hideFilterDrawer() {
    if (isFilterDrawerVisible.value) {
      isFilterDrawerVisible.value = false;
      debugPrint('📊 筛选抽屉: 隐藏');
    }
  }

  /// 检查上面四个标签筛选项是否可以被取消选择
  bool canToggleTopTabFilter(String filterKey) {
    // 计算当前选中的上面四个标签数量
    int selectedCount = 0;
    if (filterSensitiveRecord.value) selectedCount++;
    if (filterUnlockRecord.value) selectedCount++;
    if (filterScreenTime.value) selectedCount++;
    if (filterLocationAnomaly.value) selectedCount++;
    
    // 获取当前筛选项的状态
    bool currentValue = false;
    switch (filterKey) {
      case 'sensitiveRecord':
        currentValue = filterSensitiveRecord.value;
        break;
      case 'unlockRecord':
        currentValue = filterUnlockRecord.value;
        break;
      case 'screenTime':
        currentValue = filterScreenTime.value;
        break;
      case 'locationAnomaly':
        currentValue = filterLocationAnomaly.value;
        break;
    }
    
    // 如果当前是选中状态且只剩2个选中项，不允许取消
    return !(currentValue && selectedCount <= 2);
  }

  /// 获取标签的基础名称（去除数量信息）
  String _getBaseTabName(String tabName) {
    // 移除括号中的数量信息，例如 "敏感记录(12)" -> "敏感记录"
    final regex = RegExp(r'\(\d+\)$');
    return tabName.replaceAll(regex, '');
  }

  /// 切换筛选项
  void toggleFilter(String filterKey) {
    // 保存当前选中的标签基础名称
    final currentTabName = selectedTabIndex.value < visibleTabs.length 
        ? _getBaseTabName(visibleTabs[selectedTabIndex.value])
        : '全部记录';
    
    // 检查是否为上面四个标签之一
    final isTopTabFilter = ['sensitiveRecord', 'unlockRecord', 'screenTime', 'locationAnomaly'].contains(filterKey);
    
    if (isTopTabFilter) {
      // 计算当前选中的上面四个标签数量
      int selectedCount = 0;
      if (filterSensitiveRecord.value) selectedCount++;
      if (filterUnlockRecord.value) selectedCount++;
      if (filterScreenTime.value) selectedCount++;
      if (filterLocationAnomaly.value) selectedCount++;
      
      // 如果当前要取消选择的项目是选中状态，且选中数量只有2个，则不允许取消
      bool currentValue = false;
      switch (filterKey) {
        case 'sensitiveRecord':
          currentValue = filterSensitiveRecord.value;
          break;
        case 'unlockRecord':
          currentValue = filterUnlockRecord.value;
          break;
        case 'screenTime':
          currentValue = filterScreenTime.value;
          break;
        case 'locationAnomaly':
          currentValue = filterLocationAnomaly.value;
          break;
      }
      
      // 如果当前是选中状态且只剩2个选中项，不允许取消
      if (currentValue && selectedCount <= 2) {
        debugPrint('📊 筛选限制: 上面四个标签至少需要选中两个');
        return;
      }
    }
    
    switch (filterKey) {
      case 'sensitiveRecord':
        filterSensitiveRecord.value = !filterSensitiveRecord.value;
        break;
      case 'unlockRecord':
        filterUnlockRecord.value = !filterUnlockRecord.value;
        break;
      case 'screenTime':
        filterScreenTime.value = !filterScreenTime.value;
        break;
      case 'locationAnomaly':
        filterLocationAnomaly.value = !filterLocationAnomaly.value;
        break;
      case 'highSensitive':
        filterHighSensitive.value = !filterHighSensitive.value;
        break;
      case 'mediumSensitive':
        filterMediumSensitive.value = !filterMediumSensitive.value;
        break;
      case 'lowSensitive':
        filterLowSensitive.value = !filterLowSensitive.value;
        break;
      case 'showDataCount':
        filterShowDataCount.value = !filterShowDataCount.value;
        break;
    }
    
    // 筛选变化后，尝试保持当前选中的标签
    final newTabs = visibleTabs;
    int newIndex = -1;
    
    // 根据基础名称查找匹配的标签
    for (int i = 0; i < newTabs.length; i++) {
      if (_getBaseTabName(newTabs[i]) == currentTabName) {
        newIndex = i;
        break;
      }
    }
    
    if (newIndex != -1) {
      // 如果找到匹配的标签，保持选中
      selectedTabIndex.value = newIndex;
      // 同步 PageController
      if (pageController.hasClients && pageController.page?.toInt() != newIndex) {
        pageController.jumpToPage(newIndex);
      }
    } else {
      // 否则选中第一个标签
      selectedTabIndex.value = 0;
      // 同步 PageController
      if (pageController.hasClients && pageController.page?.toInt() != 0) {
        pageController.jumpToPage(0);
      }
    }
    
    debugPrint('📊 切换筛选项: $filterKey, 可见标签: $newTabs, 选中索引: ${selectedTabIndex.value}');
    
    // 应用本地筛选，不重新请求接口
    _applyLocalFiltering();
  }

  /// 切换日期
  void changeDate(DateTime date) {
    selectedDate.value = date;
    
    // 切换日期时，自动切换到第一个标签页和内容页
    _isProgrammaticPageChange = true;
    selectedTabIndex.value = 0;
    
    // 同时重置标签栏滚动位置到起始位置
    if (tabScrollController.hasClients) {
      tabScrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    
    pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ).then((_) {
      // 动画完成后重置标志位
      _isProgrammaticPageChange = false;
    });
    
    debugPrint('📊 切换日期: ${DateFormat('yyyy-MM-dd').format(date)}，重置标签页、内容页和标签栏滚动位置到第一个');
    
    // 加载该日期的数据
    loadData();
  }

  /// 加载数据
  Future<void> loadData() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);
    debugPrint('📊 加载数据: $dateStr');
    
    try {
      isLoading.value = true;
      
      // 调用API
      final result = await _usageRecordApi.getSensitiveRecord(date: selectedDate.value);
      
      if (result.isSuccess && result.data != null) {
        debugPrint('✅ 数据加载成功');
        apiData.value = result.data;
        
        // 转换数据
        _convertApiDataToUIModels();
      } else {
        debugPrint('❌ 数据加载失败: ${result.msg}');
        if (Get.context != null) {
          CustomToast.show(Get.context!, result.msg ?? '数据加载失败');
        }
      }
    } catch (e) {
      debugPrint('💥 数据加载异常: $e');
      if (Get.context != null) {
        CustomToast.show(Get.context!, '数据加载异常: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 将API数据转换为UI模型
  void _convertApiDataToUIModels() {
    if (apiData.value == null) return;
    
    final data = apiData.value!;
    
    // 1. 转换屏幕使用时长数据
    screenTimeData.value = UsageRecordConverter.convertToScreenTimeModel(
      data.mobileScreenUsageDurationRecord,
      selectedDate.value,
    );
    debugPrint('📱 屏幕使用时长数据转换完成: ${screenTimeData.value?.records.length}条记录');
    
    // 2. 转换解锁记录数据
    unlockRecordData.value = UsageRecordConverter.convertToUnlockRecordModel(
      data.unlockMobileRecord,
      selectedDate.value,
    );
    debugPrint('🔓 解锁记录数据转换完成: ${unlockRecordData.value?.records.length}条记录');
    
    // 3. 存储敏感记录数据（先存储原始数据，后续通过本地筛选）
    sensitiveRecordData.value = _applySensitiveLevelFilter(data.sensitiveRecord);
    debugPrint('🔒 敏感记录数据: ${sensitiveRecordData.value?.data.length}条记录');
    
    // 4. 存储定位异常数据（先存储原始数据，后续通过本地筛选）
    locationAnomalyData.value = _applySensitiveLevelFilter(data.locationStayAbnormalRecord);
    debugPrint('📍 定位异常数据: ${locationAnomalyData.value?.data.length}条记录');
    
    // 5. 存储全部记录数据（先存储原始数据，后续通过本地筛选）
    allRecordData.value = _applySensitiveLevelFilter(data.allRecord);
    debugPrint('📋 全部记录数据: ${allRecordData.value?.data.length}条记录');
    
    // 6. 存储设备信息
    deviceInfo.value = data.halfLocationMobileDevice;
    debugPrint('📱 设备信息: 手机=${deviceInfo.value?.mobileModel}, 网络=${deviceInfo.value?.networkName}, 电量=${deviceInfo.value?.power}');
  }

  /// 应用本地筛选（不重新请求接口）
  void _applyLocalFiltering() {
    if (apiData.value == null) {
      debugPrint('⚠️ 本地筛选: API数据为空，无法进行筛选');
      return;
    }
    
    debugPrint('🔄 本地筛选: 重新应用敏感度筛选到已获取的数据');
    
    final data = apiData.value!;
    
    // 重新应用敏感度筛选到各个数据源
    sensitiveRecordData.value = _applySensitiveLevelFilter(data.sensitiveRecord);
    locationAnomalyData.value = _applySensitiveLevelFilter(data.locationStayAbnormalRecord);
    allRecordData.value = _applySensitiveLevelFilter(data.allRecord);
    
    debugPrint('✅ 本地筛选完成: 敏感记录=${sensitiveRecordData.value?.data.length}条, 定位异常=${locationAnomalyData.value?.data.length}条, 全部记录=${allRecordData.value?.data.length}条');
  }

  /// 应用敏感度筛选
  RecordSection? _applySensitiveLevelFilter(RecordSection? originalData) {
    if (originalData == null) return null;
    
    // 如果没有选中任何敏感度筛选，返回空数据（0条记录）
    if (!filterHighSensitive.value && !filterMediumSensitive.value && !filterLowSensitive.value) {
      debugPrint('🔍 敏感度筛选: 未选中任何筛选条件，返回空数据 (0条)');
      return RecordSection(
        number: 0,
        data: [],
      );
    }
    
    debugPrint('🔍 敏感度筛选: 高敏感=${filterHighSensitive.value}, 中敏感=${filterMediumSensitive.value}, 低敏感=${filterLowSensitive.value}');
    
    // 根据选中的敏感度筛选数据
    final filteredData = originalData.data.where((record) {
      final sensitiveLevel = record.sensitiveLevel;
      
      // 高敏感 (1)
      if (filterHighSensitive.value && sensitiveLevel == 1) {
        return true;
      }
      
      // 中敏感 (2)
      if (filterMediumSensitive.value && sensitiveLevel == 2) {
        return true;
      }
      
      // 低敏感 (3)
      if (filterLowSensitive.value && sensitiveLevel == 3) {
        return true;
      }
      
      return false;
    }).toList();
    
    debugPrint('🔍 敏感度筛选结果: 原始${originalData.data.length}条 -> 筛选后${filteredData.length}条');
    
    // 返回筛选后的数据
    return RecordSection(
      number: filteredData.length,
      data: filteredData,
    );
  }

  /// 显示设置对话框
  void showSettingDialog() async {
    // 跳转到用机设置页面
    Get.toNamed(KissuRoutePath.usageSettings);
  }

  /// 获取系统信息设置
  Future<void> loadSystemInfo() async {
    isSystemInfoLoading.value = true;
    try {
      final result = await _phoneHistoryApi.getSystemInfo();
      if (result.isSuccess && result.data != null) {
        systemInfo.value = result.data!;
      } else {
        OKToastUtil.show('获取系统设置失败: ${result.msg}');
      }
    } catch (e) {
      OKToastUtil.show('获取系统设置异常: $e');
    } finally {
      isSystemInfoLoading.value = false;
    }
  }


  /// 更新用户绑定状态
  void _updateUserBindStatus() {
    final user = UserManager.currentUser;
    bool bound = false;
    if (user?.bindStatus != null) {
      if (user!.bindStatus is int) {
        bound = user.bindStatus == 1;
      } else if (user.bindStatus is String) {
        bound = user.bindStatus == "1";
      }
    }
    isUserBound.value = bound;
    debugPrint('📊 用户绑定状态更新: $bound');
  }

  /// 检查用户是否已绑定（保持向后兼容）
  bool isUserBoundSync() {
    return isUserBound.value;
  }

  /// 处理距离按钮点击事件
  void handleDistanceButtonClick() {
    if (isUserBound.value) {
      // 已绑定，跳转到定位页面（添加会员检查）
      debugPrint('📍 用户已绑定，跳转到定位页面（检查会员状态）');
      VipNavigationHelper.navigateToLocationWithVipCheck();
    } else {
      // 未绑定，显示绑定弹窗
      debugPrint('💑 用户未绑定，显示绑定弹窗');
      showBindingDialog();
    }
  }

  /// 处理绑定按钮点击事件
  void handleBindButtonClick() {
    debugPrint('💑 立即绑定按钮被点击');
    showBindingDialog();
  }

  /// 显示绑定弹窗
  void showBindingDialog() {
    final currentContext = Get.context;
    if (currentContext != null) {
      CustomBottomDialog.show(
        context: currentContext,
        onClose: () {
          debugPrint('💑 绑定弹窗已关闭');
        },
      ).then((result) {
        // 绑定弹窗关闭后，更新绑定状态并检查是否需要刷新页面
        _updateUserBindStatus();
        if (isUserBound.value) {
          debugPrint('💑 用户已绑定，刷新页面数据');
          loadData();
        }
      });
    } else {
      debugPrint('❌ 无法获取Context，跳过显示绑定弹窗');
    }
  }

  /// 获取设备详细信息
  String _getDeviceDetailInfo(String componentText) {
    final device = deviceInfo.value;
    if (device == null) return componentText;

    final mobileModel = device.mobileModel;
    final power = device.power;
    final networkName = device.networkName;
    final isWifi = device.isWifi == '1';

    if (componentText.contains(mobileModel) || componentText == mobileModel) {
      return "设备型号：$mobileModel";
    } else if (componentText.contains(power) || componentText == power) {
      return "当前电量：$power";
    } else if (componentText.contains(networkName) || componentText == networkName || componentText == '移动网络') {
      // 处理 WiFi 和移动网络两种情况
      if (isWifi && networkName.isNotEmpty) {
        return "网络名称：$networkName";
      } else {
        return "网络类型：移动网络";
      }
    }
    return componentText;
  }

  /// 显示设备信息详情tip
  void showTooltip(String text, Offset position) {
    hideTooltip();

    final detailText = _getDeviceDetailInfo(text);
    final screenSize = MediaQuery.of(pageContext).size;
    const padding = 12.0;
    final maxWidth = screenSize.width * 0.75;
    final estimatedHeight = 120.0;

    double left = position.dx;
    double top = position.dy;

    if (left + maxWidth + padding > screenSize.width) {
      left = screenSize.width - maxWidth - padding;
    }

    if (top + estimatedHeight + padding > screenSize.height) {
      top = screenSize.height - estimatedHeight - padding;
    }

    _overlayEntry = OverlayEntry(
      builder: (_) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: hideTooltip,
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              child: Material(
                color: Colors.transparent,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        detailText,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF333333),
                          height: 1.4,
                        ),
                      ),
                    ),
                    Positioned(
                      top: -8,
                      right: -8,
                      child: GestureDetector(
                        onTap: hideTooltip,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.grey,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(pageContext, rootOverlay: true).insert(_overlayEntry!);
  }

  /// 隐藏设备信息详情tip
  void hideTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}


