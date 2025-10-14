import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/widgets/selector/date_selector.dart';
import 'package:kissu_app/widgets/device_info_item.dart';
import 'phone_history_controller.dart';

class PhoneHistoryPage extends GetView<PhoneHistoryController> {
  const PhoneHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    controller.pageContext = context; // ✅ 保存 Scaffold 的 context
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(child: _buildMainContent()),
        ],
      ),
    );
  }

  // 背景图
  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/phone_history/kissu_phone_bg.webp'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // 主内容
  Widget _buildMainContent() {
    return Column(
      children: [
        _buildHeader(),
        _buildDateSelector(),
        Expanded(
          child: _buildPageView(),
        ),
        _buildBottomTip(),
      ],
    );
  }

  // PageView实现页面切换效果
  Widget _buildPageView() {
    return PageView.builder(
      controller: controller.pageController,
      onPageChanged: controller.onPageChanged,
      itemCount: 7, // 最近7天
      itemBuilder: (context, index) {
        return _buildPageContent(index);
      },
    );
  }

  // 构建单个页面内容
  Widget _buildPageContent(int index) {
    return Obx(() {
      // 只有当前页面才显示内容，避免性能问题
      if (index != controller.currentPageIndex.value) {
        return const SizedBox();
      }

      return Column(
        children: [
          // 加载指示器 - 放在页面内容顶部
          _buildDateLoadingIndicator(),
          // 滑动提示
          _buildSwipeHint(),
          // 页面内容
          Expanded(
            child: Obx(() {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildContentByState(),
              );
            }),
          ),
        ],
      );
    });
  }

  // 底部提示
  Widget _buildBottomTip() {
    return Container(
      padding: const EdgeInsets.only(bottom: 20, top: 20),
      child: const Text(
        'Kissu统计也可能存在偏差，仅提供参考哦',
        style: TextStyle(fontSize: 10, color: Color(0xFFD1CDCD)),
      ),
    );
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
                '敏感记录',
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

  // 构建日期切换加载指示器 - 移到页面内容顶部
  Widget _buildDateLoadingIndicator() {
    return Obx(() {
      if (!controller.isDateLoading.value) {
        return const SizedBox.shrink();
      }
      
      return Container(
        height: 50,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B9D)),
              ),
            ),
            SizedBox(width: 8),
            Text(
              '加载中...',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF999999),
              ),
            ),
          ],
        ),
      );
    });
  }

  // 构建滑动提示
  Widget _buildSwipeHint() {
    return Obx(() {
      if (controller.swipeHintText.value.isEmpty) {
        return const SizedBox.shrink();
      }
      
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B9D).withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            controller.swipeHintText.value,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ),
      );
    });
  }

  // 构建未绑定状态背景图片
  Widget _buildUnbindBackground() {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.only(
              left: 12, // 与设备信息栏左边距对齐
              right: 12, // 与设备信息栏右边距对齐
              top: 18, // 与设备信息栏顶部边距对齐
              bottom: 12, // 距离底部文字上方20px + 底部文字高度约40px
            ),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/kissu_history_unbind_bg.webp'),
                fit: BoxFit.fill,
              ),
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
             
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
          onTap: () => controller.showBindingDialog(),
          child: Container(
            width: 110,
            height: 35,
            margin: EdgeInsets.only(bottom: 50), // 底部间距
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0xffFF88AA),
            ),
            alignment: Alignment.center,
            child: const Text(
              "立即绑定",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),)
      ],
    );
  }

  // 根据状态构建内容
  Widget _buildContentByState() {
    // 如果绑定状态未知，显示加载状态
    if (controller.isBinding.value == null) {
      return _buildInitialLoadingState();
    }
    // 根据绑定状态显示对应内容
    return controller.isBinding.value!
        ? _buildUsageList()
        : _buildEmptyStateWithBackground();
  }

  // 构建初始加载状态
  Widget _buildInitialLoadingState() {
    return Stack(
      key: const ValueKey('loading'),
      children: [
        // 使用与未绑定状态相同的背景
        _buildUnbindBackground(),
        // 加载指示器覆盖在背景上
        const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xffFF88AA)),
            strokeWidth: 2.0,
          ),
        ),
      ],
    );
  }

  // 构建未绑定状态（带背景图片和下拉刷新）
  Widget _buildEmptyStateWithBackground() {
    return Stack(
      key: const ValueKey('unbind'),
      children: [
        // 背景图片 - 仅在未绑定时显示
        _buildUnbindBackground(),
        // 原有的空状态内容
        // _buildEmptyState(),
      ],
    );
  }


  // 构建使用记录列表
  Widget _buildUsageList() {
    return Container(
      key: const ValueKey('bind'),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Stack(
        children: [
          // 背景容器
          Column(
            children: [
              // 顶部信息栏
              _buildInfoHeader(),
              // 记录列表（支持左右滑动）
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value && controller.recordList.isEmpty) {
                    return _buildLoadingList();
                  }
                  if (controller.recordList.isEmpty) {
                    return _buildEmptyList();
                  }
                  return _buildRecordsListWithRefresh();
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 构建顶部信息栏
  Widget _buildInfoHeader() {
    return Obx(() {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 20),
            margin: const EdgeInsets.only(bottom: 12, top: 18),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  'assets/track_device_bg.webp',
                ),
                fit: BoxFit.fill,
              ),
            ),
            child: Column(
              children: [
                // 距离和更新时间
                Row(
                  children: [
                    const Text(
                      '当前相距',
                      style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                    ),
                    const SizedBox(width: 8),
                    Obx(() => Text(
                      controller.distance,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6B9D),
                      ),
                    )),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(width: 1, color: const Color(0xffFFEDF2)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Color(0xFF4CAF50),
                          ),
                          const SizedBox(width: 4),
                          Obx(() => Text(
                            controller.updateTime.isEmpty 
                                ? '暂无更新' 
                                : controller.updateTime,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF47493C),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 设备信息行
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Obx(() => DeviceInfoItem(
                          text: controller.deviceModel,
                          iconPath:
                              'assets/phone_history/kissu_phone_type.webp',
                          isDevice: true,
                          onLongPress: controller.showTooltip,
                        )),
                      ),
                      Expanded(
                        child: Obx(() => DeviceInfoItem(
                          text: controller.batteryLevel,
                          iconPath:
                              'assets/phone_history/kissu_phone_barry.webp',
                          isDevice: false,
                          onLongPress: controller.showTooltip,
                        )),
                      ),
                      Expanded(
                        child: Obx(() => DeviceInfoItem(
                          text: controller.networkName,
                          iconPath:
                              'assets/phone_history/kissu_phone_wifi.webp',
                          isDevice: false,
                          onLongPress: controller.showTooltip,
                        )),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 🔽 浮层提示（显示在 InfoHeader 顶部）
          if (controller.tooltipText.value != null)
            Positioned(
              top: -60, // 调整距离
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        controller.tooltipText.value!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF333333),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => controller.hideTooltip(),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }

  // 构建空列表（带背景和下拉刷新） - 背景延伸到合适高度
  Widget _buildEmptyList() {
    return RefreshIndicator(
      onRefresh: controller.onRefresh,
      color: const Color(0xFFFF6B9D),
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/phone_history/kissu_phone_list_bg.webp'),
            fit: BoxFit.fill,
          ),
        ),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: 300, // 给一个固定高度确保可以滑动
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 80),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/phone_history/kissu_phone_list_empty.webp',
                  width: 128,
                  height: 128,
                ),
                const SizedBox(height: 12),
                const Text(
                  '对方目前还没有敏感行为',
                  style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 构建加载状态
  Widget _buildLoadingList() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/phone_history/kissu_phone_list_bg.webp'),
          fit: BoxFit.fill,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B9D)),
        ),
      ),
    );
  }

  // 构建带下拉刷新和上拉加载的记录列表
  Widget _buildRecordsListWithRefresh() {
    return RefreshIndicator(
      onRefresh: controller.onRefresh,
      color: const Color(0xFFFF6B9D),
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/phone_history/kissu_phone_list_bg.webp'),
            fit: BoxFit.fill,
          ),
        ),
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
                controller.hasMoreData.value &&
                !controller.isLoadingMore.value) {
              controller.loadMore();
            }
            return false;
          },
          child: Obx(() => ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            itemCount: controller.recordList.length + (controller.hasMoreData.value ? 1 : 0),
            // 性能优化：添加缓存extent和预估高度
            cacheExtent: 500,
            itemExtent: null, // 让系统自动计算
            itemBuilder: (context, index) {
              if (index == controller.recordList.length) {
                return _buildLoadMoreWidget();
              }
              
              return _buildRecordItem(index);
            },
          )),
        ),
      ),
    );
  }

  // 构建单个记录项（性能优化：避免在itemBuilder中重复创建对象）
  Widget _buildRecordItem(int index) {
    final record = controller.recordList[index];
    final time = record.createTime ?? '';
    final action = record.content ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // 性能优化：最小化尺寸
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 15,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffF6F6F6),
                    borderRadius: BorderRadius.circular(1000),
                  ),
                  child: Text(
                    action,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF333333),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: null, // 允许多行显示
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 构建加载更多组件
  Widget _buildLoadMoreWidget() {
    return Obx(() {
      if (controller.isLoadingMore.value) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B9D)),
                ),
              ),
              SizedBox(width: 8),
              Text(
                '加载中...',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
        );
      }
      
      if (!controller.hasMoreData.value) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: const Text(
            '没有更多数据了',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF999999),
            ),
            textAlign: TextAlign.center,
          ),
        );
      }
      
      return const SizedBox.shrink();
    });
  }
}
