import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/widgets/selector/date_selector.dart';
import 'usage_report_controller.dart';
import 'widgets/sensitive_record_page.dart';
import 'widgets/unlock_record_detail_page.dart';
import 'widgets/screen_time_detail_page.dart';
import 'widgets/location_anomaly_page.dart';
import 'widgets/all_records_page.dart';

class UsageReportPage extends GetView<UsageReportController> {
  const UsageReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(child: _buildMainContent()),
          // 底部白色渐变蒙版
          Positioned(
            bottom: 90, // 底部信息栏高度
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xffF2F2F7),
                      Color(0xffF2F2F7).withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 背景图
  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            'assets/phone_history/kissu3_phone_history_bg.webp',
          ),
          fit: BoxFit.fill,
        ),
      ),
    );
  }

  // 主内容
  Widget _buildMainContent() {
    return Stack(
      children: [
        Column(
          children: [
            _buildHeader(),
            _buildDateSelector(),
            const SizedBox(height: 16),
            _buildTabBarWithFilter(),
            Expanded(child: _buildPageView()),
            // 底部信息栏
            _buildBottomInfo(),
          ],
        ),
        if (!controller.isUserBound())
          Positioned(
            top: 190, //
            left: 0,
            right: 0,
            bottom: 90,
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xffffffff),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 320,

                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(
                                'assets/kissu3_history_unbind_bg.webp',
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            controller.handleBindButtonClick();
                          },
                          child: Container(
                            margin: EdgeInsets.only(left: 72,top: 20),
                            width: 135,
                            height: 35,
                            decoration: BoxDecoration(
                              color: Color(0xFFFF408D),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '立即绑定',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 104,
                      height: 160,

                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(
                            'assets/kissu3_history_unbind_heart.webp',
                          ),
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
  }

  // 构建标签栏和筛选按钮
  Widget _buildTabBarWithFilter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildTabBar()),
          const SizedBox(width: 8),
          _buildFilterButton(),
        ],
      ),
    );
  }

  // 构建标签栏
  Widget _buildTabBar() {
    return Container(
      height: 42,
      // padding: EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFB6E3), width: 1),
      ),
      clipBehavior: Clip.antiAlias, // 裁剪超出圆角边界的内容
      child: Stack(
        children: [
          // 标签列表
          Obx(() {
            final tabs = controller.visibleTabs;
            final selectedIndex =
                controller.selectedTabIndex.value; // 在 Obx 内部获取
            return ListView(
              controller: controller.tabScrollController, // 添加滚动控制器
              scrollDirection: Axis.horizontal,
              children: [
                const SizedBox(width: 2), // 左侧占位
                ...List.generate(tabs.length, (index) {
                  final isSelected = selectedIndex == index;
                  return GestureDetector(
                    key: controller.tabKeys[index], // 添加 GlobalKey
                    onTap: () => controller.changeTab(index),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 3,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFF9AD8)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        tabs[index],
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF333333),
                          fontWeight: isSelected
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        softWrap: false,
                      ),
                    ),
                  );
                }),
                // const SizedBox(width: 47), // 右侧占位（31px渐变蒙版 + 16px间距）
              ],
            );
          }),
          // 右侧渐变蒙版
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                width: 31,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.white.withOpacity(0),
                      Colors.white.withOpacity(1),
                    ],
                    stops: const [0.0, 1.0],
                  ),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(22),
                    bottomRight: Radius.circular(22),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建筛选按钮
  Widget _buildFilterButton() {
    return GestureDetector(
      onTap: () => controller.toggleFilterDrawer(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFFB6E3), width: 1),
        ),
        alignment: Alignment.center,
        child: Image.asset(
          'assets/phone_history/kissu3_history_seting_more.webp',
          width: 16,
          height: 16,
        ),
      ),
    );
  }

  // 构建 PageView
  Widget _buildPageView() {
    return Stack(
      children: [
        // 未绑定状态的背景图
        GestureDetector(
          onTap: () {
            // 点击页面时隐藏筛选抽屉
            controller.hideFilterDrawer();
          },
          onPanDown: (_) {
            // 开始滑动时隐藏筛选抽屉
            controller.hideFilterDrawer();
          },
          child: Obx(() {
            final tabs = controller.visibleTabs;
            return PageView.builder(
              controller: controller.pageController,
              itemCount: tabs.length,
              onPageChanged: controller.onPageChanged,
              itemBuilder: (context, index) {
                return _buildTabContent(tabs[index]);
              },
            );
          }),
        ),
        // 筛选抽屉
        Obx(() {
          if (!controller.isFilterDrawerVisible.value) {
            return const SizedBox.shrink();
          }
          return _buildFilterDrawer();
        }),
      ],
    );
  }

  // 构建标签内容
  Widget _buildTabContent(String tabName) {
    // 获取标签的基础名称（去除数量信息）
    final baseTabName = _getBaseTabName(tabName);

    switch (baseTabName) {
      case '全部记录':
        return const AllRecordsPage();
      case '敏感记录':
        return const SensitiveRecordPage();
      case '解锁记录':
        return const UnlockRecordDetailPage();
      case '屏幕使用时长':
        return const ScreenTimeDetailPage();
      case '定位/足迹异常':
        return const LocationAnomalyPage();
      default:
        return _buildPlaceholderPage(tabName);
    }
  }

  /// 获取标签的基础名称（去除数量信息）
  String _getBaseTabName(String tabName) {
    // 移除括号中的数量信息，例如 "敏感记录(12)" -> "敏感记录"
    final regex = RegExp(r'\(\d+\)$');
    return tabName.replaceAll(regex, '');
  }

  // 占位页面
  Widget _buildPlaceholderPage(String title) {
    return Center(
      child: Text(
        '$title内容开发中...',
        style: const TextStyle(fontSize: 16, color: Color(0xFF999999)),
      ),
    );
  }

  // 构建筛选抽屉
  Widget _buildFilterDrawer() {
    return Positioned(
      top: 0,
      right: 16,
      child: GestureDetector(
        onTap: () => controller.toggleFilterDrawer(),
        child: Container(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {}, // 阻止事件冒泡
            child: Container(
              width: 125,
              height: 242,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    'assets/phone_history/kissu3_history_seting_more_bg.webp',
                  ),
                  fit: BoxFit.fill,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFilterItem('敏感记录', 'sensitiveRecord'),
                  _buildFilterItem('解锁记录', 'unlockRecord'),
                  _buildFilterItem('屏幕使用时长', 'screenTime'),
                  _buildFilterItem('定位/足迹异常', 'locationAnomaly'),
                  const Divider(color: Color(0xFFEEEEEE), height: 1),
                  _buildFilterItem('高敏感', 'highSensitive'),
                  _buildFilterItem('中敏感', 'mediumSensitive'),
                  _buildFilterItem('低敏感', 'lowSensitive'),
                  _buildFilterItem('显示数据数值', 'showDataCount'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 构建筛选项
  Widget _buildFilterItem(String label, String filterKey) {
    return Obx(() {
      bool isSelected = false;
      switch (filterKey) {
        case 'sensitiveRecord':
          isSelected = controller.filterSensitiveRecord.value;
          break;
        case 'unlockRecord':
          isSelected = controller.filterUnlockRecord.value;
          break;
        case 'screenTime':
          isSelected = controller.filterScreenTime.value;
          break;
        case 'locationAnomaly':
          isSelected = controller.filterLocationAnomaly.value;
          break;
        case 'highSensitive':
          isSelected = controller.filterHighSensitive.value;
          break;
        case 'mediumSensitive':
          isSelected = controller.filterMediumSensitive.value;
          break;
        case 'lowSensitive':
          isSelected = controller.filterLowSensitive.value;
          break;
        case 'showDataCount':
          isSelected = controller.filterShowDataCount.value;
          break;
      }

      // 根据敏感级别设置不同的选中图标和文字颜色
      String selectedIcon;
      Color textColor;

      switch (filterKey) {
        case 'highSensitive':
          selectedIcon =
              'assets/phone_history/kissu3_history_seting_high_sel.webp';
          textColor = const Color(0xFFFF0000); // 红色
          break;
        case 'mediumSensitive':
          selectedIcon =
              'assets/phone_history/kissu3_history_seting_middle_sel.webp';
          textColor = const Color(0xFFFFA100); // 橙色
          break;
        case 'lowSensitive':
          selectedIcon = 'assets/phone_history/kissu3_history_seting_sel.webp';
          textColor = const Color(0xFF3B86FF); // 蓝色
          break;
        default:
          selectedIcon = 'assets/phone_history/kissu3_history_seting_sel.webp';
          textColor = const Color(0xFF333333); // 蓝色
          break;
      }

      return GestureDetector(
        onTap: () => controller.toggleFilter(filterKey),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 12, color: textColor),
              ),
            ),
            Image.asset(
              isSelected
                  ? selectedIcon
                  : 'assets/phone_history/kissu3_history_seting_unsel.webp',
              width: 12,
              height: 12,
            ),
          ],
        ),
      );
    });
  }

  // 构建顶部标题栏
  Widget _buildHeader() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Image.asset(
              'assets/kissu_mine_back.webp',
              width: 24,
              height: 24,
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                '用机记录',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => controller.showSettingDialog(),
            child: Image.asset(
              'assets/phone_history/kissu_phone_setting.webp',
              width: 24,
              height: 24,
            ),
          ),
        ],
      ),
    );
  }

  // 构建日期选择器
  Widget _buildDateSelector() {
    return DateSelector(
      externalSelectedIndex: controller.selectedDateIndex,
      onSelect: (date) {
        controller.changeDate(date);
      },
    );
  }

  /// 构建底部信息栏
  Widget _buildBottomInfo() {
    return Container(
      height: 90,
      padding: EdgeInsets.only(top: 5),
      decoration: const BoxDecoration(color: Color(0xffF2F2F7)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 距离信息
          _buildDistanceInfo(),
          // 分割线
          SizedBox(width: 15),
          // 设备信息
          Expanded(child: _buildDeviceInfo()), SizedBox(width: 16),
        ],
      ),
    );
  }

  /// 构建距离信息
  Widget _buildDistanceInfo() {
    return InkWell(
      onTap: () {
        controller.handleDistanceButtonClick();
      },
      child: Container(
        width: 60,
        height: 48,
        decoration: BoxDecoration(
          color: Color(0xffFCFCFD),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          border: Border.all(color: Color(0xFFF4E6FF), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/phone_history/kissu3_history_diatance.webp',
              width: 16,
              height: 16,
            ),
            const SizedBox(height: 3),
            const Text(
              '距离',
              style: TextStyle(fontSize: 10, color: Color(0xFF333333)),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建设备信息
  Widget _buildDeviceInfo() {
    return Obx(() {
      final deviceInfo = controller.deviceInfo.value;

      // 获取设备信息，如果没有则显示默认值
      final mobileModel = deviceInfo?.mobileModel ?? '未知';
      final networkName = deviceInfo?.networkName ?? '未知';
      final power = deviceInfo?.power ?? '未知';
      final isWifi = deviceInfo?.isConnectedToWifi ?? false;

      return InkWell(
        onTap: () {
          // TODO: 点击查看设备信息
          debugPrint('点击设备信息');
        },
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xffFCFCFD),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Color(0xFFF4E6FF), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 手机型号
              if (mobileModel.isNotEmpty) ...[
                Image.asset(
                  'assets/phone_history/kissu_phone_type.webp',
                  width: 16,
                  height: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  mobileModel,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF333333),
                  ),
                ),
                const Spacer(),
              ],
              // 网络信息
              Image.asset(
                'assets/phone_history/kissu_phone_wifi.webp',
                width: 16,
                height: 16,
              ),
              const SizedBox(width: 4),
              Text(
                isWifi && networkName.isNotEmpty ? networkName : '移动网络',
                style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
              ),
              const Spacer(),
              // 电量信息
              if (power.isNotEmpty) ...[
                Image.asset(
                  'assets/phone_history/kissu_phone_barry.webp',
                  width: 16,
                  height: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  power,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}
