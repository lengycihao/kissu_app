import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kissu_app/models/screen_time_model.dart';
import 'package:kissu_app/models/unlock_record_model.dart';
import 'package:kissu_app/models/usage_record_api_model.dart';
import 'package:kissu_app/network/public/usage_record_api.dart';
import 'package:kissu_app/services/permission_service.dart';
import 'package:kissu_app/utils/usage_record_converter.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';

class UsageReportController extends GetxController {
  final PermissionService _permissionService = PermissionService();
  final UsageRecordApi _usageRecordApi = UsageRecordApi();
  
  // 选中的日期索引
  final selectedDateIndex = 0.obs;
  
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
  final filterHighSensitive = false.obs; // 高敏感
  final filterMediumSensitive = false.obs; // 中敏感
  final filterLowSensitive = false.obs; // 低敏感
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

  // 动态标签列表（根据筛选状态计算）
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

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: 0);
    tabScrollController = ScrollController();
    debugPrint('📊 UsageReportController 初始化');
    
    // 检查并请求屏幕使用时长权限
    _checkAndRequestPermission();
  }
  
  /// 检查并请求屏幕使用时长权限
  Future<void> _checkAndRequestPermission() async {
    debugPrint('📊 检查屏幕使用时长权限...');
    
    // 检查是否已授权
    final bool isGranted = await _permissionService.isUsageAccessGranted();
    
    if (isGranted) {
      debugPrint('✅ 屏幕使用时长权限已授权');
      // 加载数据
      loadData();
    } else {
      debugPrint('❌ 屏幕使用时长权限未授权，显示引导弹窗');
      // 显示权限引导弹窗
      _showPermissionDialog();
    }
  }
  
  /// 显示权限引导弹窗
  void _showPermissionDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('需要使用统计权限'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '为了给您提供详细的屏幕使用报告，需要授予"使用情况访问权限"。',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                '授权步骤：',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildPermissionStep('1', '点击下方"去授权"按钮'),
              _buildPermissionStep('2', '在列表中找到"Kissu"应用'),
              _buildPermissionStep('3', '点击并开启权限开关'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFB74D), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.info_outline, color: Color(0xFFFF9800), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '如果列表中找不到应用，请尝试向下滚动或使用搜索功能查找"Kissu"',
                        style: TextStyle(fontSize: 12, color: Color(0xFFE65100)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              // 请求权限
              await _requestPermission();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6750A4),
              foregroundColor: Colors.white,
            ),
            child: const Text('去授权'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
  
  /// 构建权限步骤指示
  Widget _buildPermissionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF6750A4),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                text,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 请求权限
  Future<void> _requestPermission() async {
    debugPrint('📊 请求屏幕使用时长权限...');
    
    final bool granted = await _permissionService.requestUsageAccessPermission();
    
    if (granted) {
      debugPrint('✅ 权限授予成功');
      if (Get.context != null) {
        CustomToast.show(Get.context!, '权限授予成功');
      }
      // 加载数据
      loadData();
    } else {
      debugPrint('❌ 权限授予失败');
      if (Get.context != null) {
        CustomToast.show(Get.context!, '未授予权限，部分功能无法使用');
      }
    }
  }

  @override
  void onClose() {
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

  /// 切换筛选项
  void toggleFilter(String filterKey) {
    // 保存当前选中的标签名称
    final currentTabName = selectedTabIndex.value < visibleTabs.length 
        ? visibleTabs[selectedTabIndex.value] 
        : '全部记录';
    
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
    final newIndex = newTabs.indexOf(currentTabName);
    if (newIndex != -1) {
      // 如果当前标签仍然存在，保持选中
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
    
    // TODO: 应用筛选并刷新数据
    loadData();
  }

  /// 切换日期
  void changeDate(DateTime date) {
    selectedDate.value = date;
    
    // 计算日期索引（相对于今天）
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = todayDate.difference(targetDate).inDays;
    
    selectedDateIndex.value = difference;
    
    debugPrint('📊 切换日期: ${DateFormat('yyyy-MM-dd').format(date)}, 索引: $difference');
    
    // TODO: 加载该日期的数据
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
    
    // 3. 存储敏感记录数据
    sensitiveRecordData.value = data.sensitiveRecord;
    debugPrint('🔒 敏感记录数据: ${sensitiveRecordData.value?.data.length}条记录');
    
    // 4. 存储定位异常数据
    locationAnomalyData.value = data.locationStayAbnormalRecord;
    debugPrint('📍 定位异常数据: ${locationAnomalyData.value?.data.length}条记录');
    
    // 5. 存储全部记录数据
    allRecordData.value = data.allRecord;
    debugPrint('📋 全部记录数据: ${allRecordData.value?.data.length}条记录');
    
    // 6. 存储设备信息
    deviceInfo.value = data.halfLocationMobileDevice;
    debugPrint('📱 设备信息: 手机=${deviceInfo.value?.mobileModel}, 网络=${deviceInfo.value?.networkName}, 电量=${deviceInfo.value?.power}');
  }

  /// 显示设置对话框
  void showSettingDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('设置'),
        content: const Text('用机报告设置功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

