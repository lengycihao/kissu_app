import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/mine/app_usage/models/app_usage_record.dart';
import 'package:kissu_app/pages/mine/app_usage/models/app_usage_stat_data.dart';
import 'package:kissu_app/pages/mine/app_usage/models/hourly_app_record_data.dart';
import 'package:kissu_app/utils/network_image_helper.dart';
import 'package:kissu_app/widgets/common_back_button.dart';
import 'package:kissu_app/widgets/selector/date_selector.dart';
import 'app_usage_controller.dart';

/// App使用统计页面
class AppUsagePage extends StatefulWidget {
  const AppUsagePage({super.key});

  @override
  State<AppUsagePage> createState() => _AppUsagePageState();
}

class _AppUsagePageState extends State<AppUsagePage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AppUsageController());

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Stack(
        children: [
          // 背景渐变层（顶部25%白色，25%到100%白色到#F6F6F6渐变）
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.05, 1.0],
                  colors: [Colors.white, Colors.white, const Color(0xFFF6F6F6)],
                ),
              ),
            ),
          ),
          // 背景图片（与顶部对齐）
          Positioned.fill(
            child: Image.asset(
              "assets/4.0/kissu4_new_use_bg.webp",
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // 顶部导航栏
                _buildTopBar(controller),
                // 可滚动内容区域（带下拉刷新）
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => controller.onRefresh(),
                    color: const Color(0xFFFF839E),
                    child: CustomScrollView(
                      controller: _scrollController,
                      key: const PageStorageKey('appUsageScrollView'),
                      // iOS风格弹性滚动
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        // 顶部padding
                         SliverPadding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ).copyWith(bottom: 0),
                        ),

                        // 权限提示（只在没权限时显示）
                        // 日期选择器
                        SliverToBoxAdapter(
                          child: DateSelector(
                            externalSelectedIndex: controller.selectedDateIndex,
                            onSelect: (date) {
                              controller.selectDate(date);
                            },
                          ),
                        ),
                        // Ta当前授权过的App
                        Obx(() {
                          final apps = controller.halfAuthorizedApps;
                          if (apps.isEmpty) {
                            return const SliverToBoxAdapter(
                              child: SizedBox.shrink(),
                            );
                          }
                          return SliverToBoxAdapter(
                            child: _buildHalfAuthorizedApps(controller),
                          );
                        }),

                        const SliverToBoxAdapter(
                          child: SizedBox(height: 14),
                        ),

                        // 最近使用App模块
                        SliverToBoxAdapter(
                          child: _buildRecentlyUsedApps(controller),
                        ),

                        const SliverToBoxAdapter(
                          child: SizedBox(height: 16),
                        ),

                        // 使用记录模块 - 吸顶标题栏
                        _buildUsageRecordsStickyHeader(controller),

                        // 使用记录模块 - 内容区域
                        SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                            margin: EdgeInsets.symmetric(horizontal: 16),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: Obx(() {
                              final showTimeline = controller.showTimeline.value;
                              return showTimeline
                                  ? _buildTimelineView(controller)
                                  : _buildStatisticsView(controller);
                            }),
                          ),
                        ),

                        const SliverToBoxAdapter(
                          child: SizedBox(height: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 顶部导航栏
  Widget _buildTopBar(AppUsageController controller) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          // 返回按钮（统一封装，点击区域更大且更灵敏）
          CommonBackButton(
            onTap: () => Get.back(),
            assetPath: "assets/4.0/kissu4_back.webp",
            iconSize: 22,
          ),
          // 标题
          const Expanded(
            child: Center(
              child: Text(
                "App使用统计",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),
          SizedBox(width: 45,)
          // // 测试页面入口按钮
          // GestureDetector(
          //   onTap: () => Get.toNamed(KissuRoutePath.dialogShowcase),
          //   child: Container(
          //     padding: const EdgeInsets.all(8),
          //     child: const Icon(
          //       Icons.science_outlined,
          //       size: 24,
          //       color: Color(0xFFFF839E),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }


  /// Ta当前授权过的App模块
  Widget _buildHalfAuthorizedApps(AppUsageController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Image.asset(
                    'assets/4.0/kissu4_app_use_late_tip.webp',
                    width: 130,
                    height: 16,
                    fit: BoxFit.fitWidth,
                  ),
                  const Text(
                    'Ta当前授权过的App',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'AlimamaShuHeiTi',
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Transform.translate(
                offset: const Offset(-2, -5),
                child: Image.asset(
                  'assets/4.0/kissu4_app_use_tip.webp',
                  width: 13,
                  height: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            child: Stack(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: controller.halfAuthorizedApps
                        .map(
                          (app) => Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x11000000),
                                  blurRadius: 4,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: NetworkImageHelper.loadImage(
                                imageUrl: app.appLogo,
                                width: 42,
                                height: 42,
                                fit: BoxFit.cover,
                                errorWidget: Image.asset(
                                  'assets/images/kissu4_logo.png',
                                  width: 42,
                                  height: 42,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 24,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.white.withOpacity(0),
                            Colors.white,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 最近使用App模块
  Widget _buildRecentlyUsedApps(AppUsageController controller) {
    return Obx(() {
      final apps = controller.recentlyUsedApps;

      // 空数据状态
      if (apps.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(14),
          margin: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      Image.asset(
                        'assets/4.0/kissu4_app_use_late_tip.webp',
                        width: 76,
                        height: 16,
                        fit: BoxFit.fitWidth,
                      ),
                      const Text(
                        '最近使用App',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'AlimamaShuHeiTi',
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Transform.translate(
                    offset: Offset(-2, -5),
                    child: Image.asset(
                      'assets/4.0/kissu4_app_use_tip.webp',
                      width: 13,
                      height: 17,
                    ),
                  ),
                  const Spacer(),
                  Obx(() {
                    final showCount = controller.showUsageCount.value;
                    return _buildSegmentedControl(
                      options: ['次数', '分钟'],
                      selectedIndex: showCount ? 0 : 1,
                      onSelected: (index) {
                        controller.showUsageCount.value = index == 0;
                      },
                    );
                  }),
                ],
              ),
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/4.0/kissu4_use_app_empty.webp',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '暂无使用数据哦',
                      style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      }

      final showAll = controller.showAllRecentApps.value;
      final hasMore = apps.length > 5;
      final displayApps = (showAll || !hasMore) ? apps : apps.take(5).toList();

      return Container(
        padding: const EdgeInsets.all(16).copyWith(bottom: 10),
        margin: EdgeInsets.symmetric(horizontal: 16),
         decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    Image.asset(
                      'assets/4.0/kissu4_app_use_late_tip.webp',
                      width: 76,
                      height: 16,
                      fit: BoxFit.fitWidth,
                    ),
                    const Text(
                      '最近使用App',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'AlimamaShuHeiTi',
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 4),
                Transform.translate(
                  offset: Offset(-2, -5),
                  child: Image.asset(
                    'assets/4.0/kissu4_app_use_tip.webp',
                    width: 13,
                    height: 17,
                  ),
                ),
                const Spacer(),
                Obx(() {
                  final showCount = controller.showUsageCount.value;
                  return _buildSegmentedControl(
                    options: ['次数', '分钟'],
                    selectedIndex: showCount ? 0 : 1,
                    onSelected: (index) {
                      controller.showUsageCount.value = index == 0;
                    },
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),

            // App列表
            Stack(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  // 添加缓存区域提升性能
                  cacheExtent: 200,
                  itemCount: displayApps.length,
                  itemBuilder: (context, index) {
                    final app = displayApps[index];
                    // 使用RepaintBoundary隔离重绘
                    return RepaintBoundary(
                      child: _buildRecentAppItem(app, controller),
                    );
                  },
                ),

                // 渐变蒙版（当有更多内容且未展开时）
                if (hasMore && !showAll)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white.withOpacity(0), Colors.white],
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // 查看全部/收起按钮（少于5个时用SizedBox占位保持高度）
            SizedBox(
              height: 30,
              child: hasMore
                  ? Center(
                      child: GestureDetector(
                        onTap: () => controller.toggleShowAllRecentApps(),
                        child: Container(
                          margin: const EdgeInsets.only(top: 8),

                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                showAll ? '收起' : '查看全部',
                                style: TextStyle(
                                  color: Color(0xff000000).withOpacity(0.6),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Image.asset(
                                showAll
                                    ? 'assets/4.0/kissu4_app_use_more.webp'
                                    : 'assets/4.0/kissu4_app_use_more.webp',
                                width: 14,
                                height: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      );
    });
  }

  /// 最近使用App项
  Widget _buildRecentAppItem(
    AppUsageStatData app,
    AppUsageController controller,
  ) {
    return Obx(() {
      final showCount = controller.showUsageCount.value;
      // 次数标签：显示 open_app_number
      // 分钟标签：显示 minutes
      final value = showCount ? app.openAppNumber : app.minutes;
      final unit = showCount ? '次' : '分钟';

      // 进度条计算：
      // 次数标签：open_app_number / total_open_app_number
      // 分钟标签：use_app_duration / total_use_app_duration
      final progress = showCount
          ? (controller.totalOpenAppNumber.value > 0
                ? app.openAppNumber / controller.totalOpenAppNumber.value
                : 0.0)
          : (controller.totalUseAppDuration.value > 0
                ? app.useAppDuration / controller.totalUseAppDuration.value
                : 0.0);

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            // App图标（从网络URL加载，失败或空时用占位图）
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: app.appLogo.isNotEmpty
                  ? NetworkImageHelper.loadImage(
                      imageUrl: app.appLogo,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorWidget: Image.asset(
                        'assets/images/kissu4_logo.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      'assets/images/kissu4_logo.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
            ),

            const SizedBox(width: 12),

            // App名称和进度条
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        app.appName,
                        style: const TextStyle(
                          fontSize: 12,
                          // fontWeight: FontWeight.w500,
                          color: Color(0xFF333333),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // 使用次数/时长
                      Text(
                        '$value$unit',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF5CB7F0),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: const Color(0xFFD6EFFF),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF7DCDFF),
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  /// 分段控制器（根据UI图实现）
  Widget _buildSegmentedControl({
    required List<String> options,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFE0E0E0), // 浅灰色边框
          width: 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(options.length, (index) {
          final isSelected = index == selectedIndex;
          final isFirst = index == 0;
          final isLast = index == options.length - 1;

          return GestureDetector(
            onTap: () => onSelected(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: isFirst ? const Radius.circular(20) : Radius.zero,
                  bottomLeft: isFirst ? const Radius.circular(20) : Radius.zero,
                  topRight: isLast ? const Radius.circular(20) : Radius.zero,
                  bottomRight: isLast ? const Radius.circular(20) : Radius.zero,
                ),
              ),
              child: Text(
                options[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF777777),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// 使用记录模块 - 吸顶标题栏
  Widget _buildUsageRecordsStickyHeader(AppUsageController controller) {
    return Obx(() {
      final showTimeline = controller.showTimeline.value;
      return SliverPersistentHeader(
        key: const ValueKey('usageRecordsHeader'), // 使用稳定的key保持状态
        pinned: true,
        delegate: _UsageRecordsHeaderDelegate(
          controller: controller,
          showTimeline: showTimeline,
          scrollController: _scrollController,
          onSegmentedControlChanged: (index) {
            final isTimeline = index == 1;
            
            // 如果切换的是当前视图，直接返回
            if (controller.showTimeline.value == isTimeline) {
              return;
            }
            
            // 如果正在加载数据，不允许切换
            if (isTimeline && controller.isLoadingTimelineData.value) {
              return;
            }
            if (!isTimeline && controller.isLoadingStatisticsData.value) {
              return;
            }
            
            // 保存当前滚动位置
            final scrollCtrl = _scrollController;
            final currentScrollOffset = scrollCtrl.hasClients 
                ? scrollCtrl.offset 
                : 0.0;
            
            // 先切换视图状态
            controller.showTimeline.value = isTimeline;
            
            // 然后加载数据
            if (isTimeline) {
              // 切换到时间轴视图时，重置选中状态为第一个App
              controller.resetTimelineSelection();
              controller.loadTimelineData();
            } else {
              controller.loadStatisticsData();
            }
            
            // 延迟恢复滚动位置，确保布局完成后再恢复
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (scrollCtrl.hasClients && currentScrollOffset > 0) {
                // 使用 jumpTo 立即恢复位置，避免动画
                scrollCtrl.jumpTo(currentScrollOffset);
              }
            });
          },
        ),
      );
    });
  }


  /// 统计视图（从00:00到当前时间或24:00）
  Widget _buildStatisticsView(AppUsageController controller) {
    return Obx(() {
      // 加载状态
      if (controller.isLoadingStatisticsData.value) {
        return const SizedBox(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFFFF839E)),
          ),
        );
      }

      // 使用API返回的数据
      final hourlyRecords = controller.hourlyAppRecords;

      // 构建时间段数据
      final widgets = <Widget>[];

      // 创建一个Map，方便查找每个小时的数据
      // hour_key = 17 表示 17:00-18:00 的数据，应该显示在 17:00
      final hourDataMap = <int, HourlyAppRecordGroup>{};
      for (final record in hourlyRecords) {
        hourDataMap[record.hourKey] = record;
      }

      // 获取所有有数据的小时，并排序（从大到小）
      final hoursWithData = hourDataMap.keys.toList()
        ..sort((a, b) => b.compareTo(a));

      // 显示顺序：从上到下 = 从新到旧 = 从大到小
      // hour_key=18 表示 18:00-19:00 的数据，应该显示在18:00和19:00之间
      // hour_key=22 表示 22:00-23:00 的数据，应该显示在22:00和23:00之间
      // 每个时间段显示：结束点 → 数据 → 开始点
      // 例如：23:59 → 23:00 → [22:00数据] → 22:00 → 19:00 → [18:00数据] → 18:00 → 00:00
      if (hoursWithData.isNotEmpty) {
        // 0. 最上面添加23:59标签
        widgets.add(_buildTimePoint23_59());

        // 1. 遍历所有有数据的小时，从大到小
        // 对于每个有数据的小时（hour_key）：
        // - hour_key表示 hour:00-(hour+1):00 的数据
        // - 先显示(hour+1):00结束点（小圆点），但如果下一个小时也有数据，则跳过（避免重复）
        // - 再显示数据（大圆点）
        // - 最后显示hour:00开始点（小圆点）
        for (int i = 0; i < hoursWithData.length; i++) {
          final hour = hoursWithData[i];
          final hourData = hourDataMap[hour]!;
          
          // 显示(hour+1):00结束点（小圆点）
          // 但如果下一个小时也有数据（即hour+1也在hoursWithData中），则跳过（避免重复显示）
          final endHour = hour + 1;
          // 结束点应该始终显示（除非超过maxHour或下一个小时也有数据）
          // 注意：即使endHour > maxHour，如果是历史日期，也应该显示（但这里maxHour已经是23了）
          if (endHour <= 23) { // 使用固定的23，因为结束点最多到24:00（即23+1）
            // 检查endHour是否也在hoursWithData中（即下一个小时也有数据）
            // 如果下一个小时也有数据，那么endHour会作为下一个小时的开始点显示，这里就不显示了
            bool nextHourHasData = hourDataMap.containsKey(endHour);
            
            // 如果下一个小时没有数据，才显示结束点
            if (!nextHourHasData) {
              widgets.add(
                _buildTimePoint(
                  '${endHour.toString().padLeft(2, '0')}:00',
                  isLast: false,
                ),
              );
            }
          }
          
          // 显示数据（大圆点）
          widgets.add(_buildAppListRowFromApi(hourData.recordList, hour));
          
          // 显示hour:00开始点（小圆点）
          widgets.add(
            _buildTimePoint(hourData.hourKeyFormatted, isLast: false),
          );
        }

        // 2. 最后添加起始点 00:00（最下面）
        // 注意：如果最小数据小时是0，00:00已经在循环中显示了，这里不需要重复添加
        final minDataHour = hoursWithData[hoursWithData.length - 1];
        if (minDataHour > 0) {
          widgets.add(_buildTimePoint('00:00', isLast: true));
        }
      } else {
        // 没有数据，显示空状态（已经在下面处理）
      }

      // 空数据状态
      if (hourlyRecords.isEmpty) {
        return   SizedBox(
          height: 200,
          child: Center(
            child:  Column(
                  children: [
                    Image.asset(
                      'assets/4.0/kissu4_use_app_empty.webp',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '暂无使用数据哦',
                      style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
                    ),
                  ],
                ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      );
    });
  }

  /// 构建23:59时间点（最上面，使用特殊颜色）
  Widget _buildTimePoint23_59() {
    return SizedBox(
      height: 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 46,
            child: Text(
              '23:59',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xdd333333),
                height: 1,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          // 统一10px宽度，小圆点居中，虚线从中心位置绘制
          SizedBox(
            width: 10,
            child: Column(
              children: [
                // 小圆点居中（使用指定颜色）
                Center(
                  child: Image(
                    image: AssetImage(
                      'assets/phone_history/kissu4_phone_history_circle.png',
                     
                    ),
                     width: 10,
                      height: 10,
                      fit: BoxFit.contain,
                      color: Color(0xff7ACCFF),
                  ),
                ),
                // 虚线（向下连接，从中心位置）
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: CustomPaint(
                      painter: DashedLinePainter(),
                      size: const Size(1, double.infinity),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建时间点（带小圆点）
  Widget _buildTimePoint(String time, {bool isLast = false}) {
    // 00:00 是起点，不应该有向下的虚线
    final shouldShowDashedLine = !isLast && time != '00:00';
    
    return SizedBox(
      height: 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 46,
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xdd333333),
                height: 1,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          // 统一20px宽度，小圆点居中，虚线从中心（10px）位置绘制
          SizedBox(
            width: 10,
            child: Column(
              children: [
                // 小圆点居中
                Center(
                  child: Image.asset(
                   time == '00:00' ? 'assets/phone_history/kissu4_phone_history_circle.png': 'assets/4.0/kissu4_app_use_point.webp',
                    width: 10,
                    height: 10,
                    fit: BoxFit.contain,
                    color: time == '00:00' ? const Color(0xff7ACCFF) : null,
                  ),
                ),
                // 虚线（向下连接，从中心位置）
                // 00:00 是起点，不应该有向下的虚线
                if (shouldShowDashedLine)
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: CustomPaint(
                        painter: DashedLinePainter(),
                        size: const Size(1, double.infinity),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建App列表行（带大圆点）- 使用API数据
  Widget _buildAppListRowFromApi(List<HourlyAppRecord> records, int hour) {
    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧空白（对齐时间）
          const SizedBox(width: 49),

          // 大圆点和虚线（20px宽度，虚线从中心位置）
          SizedBox(
            width: 20,
            child: Column(
              children: [
                // 大圆点图片（20x20，正好填满容器）
                Align(
                  alignment: Alignment.center,
                  child: CustomPaint(
                    painter: DashedLinePainter(),
                    size: const Size(1, 15),
                  ),
                ),
                Image.asset(
                  'assets/4.0/kissu4_app_use_time.webp',
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                ),
                // 虚线（向下连接，从中心位置）
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: CustomPaint(
                      painter: DashedLinePainter(),
                      size: const Size(1, double.infinity),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // App列表（横向滑动）
          Expanded(
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xffF9F9F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    // iOS风格弹性滚动
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: records.map((record) {
                        return Container(
                          padding: const EdgeInsets.only(left: 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 使用app_logo（网络图片），失败或空时用占位图
                              record.appLogo.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: NetworkImageHelper.loadImage(
                                        imageUrl: record.appLogo,
                                        width: 28,
                                        height: 28,
                                        fit: BoxFit.cover,
                                        errorWidget: Image.asset(
                                          'assets/images/kissu4_logo.png',
                                          width: 28,
                                          height: 28,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                  : Image.asset(
                                      'assets/images/kissu4_logo.png',
                                      width: 28,
                                      height: 28,
                                      fit: BoxFit.cover,
                                    ),
                              const SizedBox(height: 6),
                              // 使用use_app_duration_minutes字段
                              Text(
                                record.useAppDurationMinutes,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xbb333333),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                // 右侧渐变蒙版
                if (records.length > 4)
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    width: 20,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Colors.white.withOpacity(0), Colors.white],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 时间轴视图
  Widget _buildTimelineView(AppUsageController controller) {
    return Obx(() {
      // 加载状态
      if (controller.isLoadingTimelineData.value) {
        return const SizedBox(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFFFF839E)),
          ),
        );
      }

      // 直接访问 RxList，GetX 会自动处理响应式更新
      final latelyApps = controller.latelyUseAppData;
      final recordDetails = controller.appOpenRecordDetail;

      // 调试信息：打印数据长度
      debugPrint(
        '时间轴视图数据: latelyApps=${latelyApps.length}, recordDetails=${recordDetails.length}',
      );

      // 空数据状态
      if (latelyApps.isEmpty && recordDetails.isEmpty) {
        return SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/4.0/kissu4_use_app_empty.webp',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 12),
                const Text(
                  '暂无使用记录',
                  style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 最上面添加23:59时间点
          _buildTimelineTimePoint23_59(),

          // 时间轴详细记录
          ...recordDetails.asMap().entries.map((entry) {
            final detail = entry.value;

            return SizedBox(
              height: 60,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 时间
                  SizedBox(
                    width:54,
                    child: Text(
                      detail.openTime,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xdd333333),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 圆点和虚线
                  SizedBox(
                    width: 10,
                    child: Column(
                      children: [
                        // 小圆点（使用图片，保持原色）
                        Image.asset(
                          'assets/4.0/kissu4_app_use_point.webp',
                          width: 10,
                          height: 10,
                          fit: BoxFit.contain,
                        ),
                        // 虚线连接（从中心位置）
                        Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: CustomPaint(
                              painter: DashedLinePainter(),
                              size: const Size(1, double.infinity),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // App图标
                  detail.appLogo.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                        child: NetworkImageHelper.loadImage(
                          imageUrl: detail.appLogo,
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                          errorWidget: Image.asset(
                            'assets/images/kissu4_logo.png',
                            width: 24,
                            height: 24,
                            fit: BoxFit.cover,
                          ),
                        ),
                        )
                      : Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Image.asset(
                          'assets/images/kissu4_logo.png',
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                        ),
                      ),

                  const SizedBox(width: 8),

                  Flexible(
                    child: Text(
                      '打开了"${detail.appName}"',
                      style: TextStyle(
                        fontSize: _getFontSizeForAppName(detail.appName),
                        color: const Color(0xbb333333),
                      ),
                      maxLines: _getMaxLinesForAppName(detail.appName),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // 时长
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE0F0),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Text(
                      detail.useDurationText,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // 底部00:00（带虚线连接，和统计标签下的23:59保持一致）
          SizedBox(
            height: 40,
            // width: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 54,
                  child: Text(
                    '00:00',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xdd333333),
                      height: 1,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 10,
                  child: Column(
                    children: [
                      // 如果有记录，显示虚线连接到上面（只显示到小圆点上方，不向下延伸）
                      // if (recordDetails.isNotEmpty)
                      //   SizedBox(
                      //     height: 15, // 固定高度，只显示到小圆点上方
                      //     child: Align(
                      //       alignment: Alignment.center,
                      //       child: CustomPaint(
                      //         painter: DashedLinePainter(),
                      //         size: const Size(1, double.infinity),
                      //       ),
                      //     ),
                      //   ),
                      // 小圆点（使用图片，和统计标签下的23:59保持一致）
                      Center(
                        child: Image(
                          image: AssetImage(
                            'assets/phone_history/kissu4_phone_history_circle.png',
                          ),
                          width: 10,
                          height: 10,
                          fit: BoxFit.contain,
                          color: const Color(0xff7ACCFF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  /// 构建时间轴视图的23:59时间点
  Widget _buildTimelineTimePoint23_59() {
    return SizedBox(
      height: 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 54,
            child: Text(
              '23:59',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xdd333333),
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          // 统一10px宽度，小圆点居中，虚线从中心位置绘制
          SizedBox(
            width: 10,
            child: Column(
              children: [
                // 小圆点居中（使用图片，颜色#FFE1F4）
                Center(
                  child: Image(
                    image: AssetImage(
                      'assets/phone_history/kissu4_phone_history_circle.png',
                    ),
                    width: 10,
                    height: 10,
                    fit: BoxFit.contain,
                    color: const Color(0xFFFFE1F4),
                  ),
                ),
                // 虚线（向下连接，从中心位置）
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: CustomPaint(
                      painter: DashedLinePainter(),
                      size: const Size(1, double.infinity),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 计算App名称的总长度单位
  /// - 中文字符：1个字符 = 1个长度单位
  /// - 英文/其他字符：2个字符 = 1个长度单位
  double _calculateAppNameLength(String appName) {
    int chineseCharCount = 0;
    int otherCharCount = 0;
    
    for (int i = 0; i < appName.length; i++) {
      final char = appName[i];
      final rune = char.runes.first;
      // 判断是否为中文字符（Unicode范围：\u4e00-\u9fff）
      if (rune >= 0x4e00 && rune <= 0x9fff) {
        chineseCharCount++;
      } else {
        otherCharCount++;
      }
    }
    
    // 中文字符：1个 = 1单位，其他字符：2个 = 1单位
    return chineseCharCount + (otherCharCount / 2.0);
  }

  /// 根据App名称的总长度单位返回对应的字体大小
  /// - 长度单位 >= 7：10pt
  /// - 长度单位 == 6：11pt
  /// - 长度单位 == 5：11pt
  /// - 长度单位 <= 4：13pt（默认）
  double _getFontSizeForAppName(String appName) {
    final length = _calculateAppNameLength(appName);
    
    if (length >= 7) {
      return 10.0;
    } else if (length == 6) {
      return 11.0;
    } else if (length >= 5) {
      return 11.0;
    } else {
      return 13.0; // 默认字体大小
    }
  }

  /// 根据App名称的总长度单位返回最大行数
  /// - 长度单位 > 6：返回2（允许换行）
  /// - 长度单位 <= 6：返回1（单行显示）
  int _getMaxLinesForAppName(String appName) {
    final length = _calculateAppNameLength(appName);
    return length > 6 ? 2 : 1;
  }
  
}

/// 虚线画笔
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 1;

    const dashHeight = 4.0;
    const dashSpace = 4.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 会话和App的组合
class SessionWithApp {
  final AppUsageRecord record;
  final AppUsageSession session;

  SessionWithApp({required this.record, required this.session});
}

/// 使用记录模块吸顶标题栏的Delegate
class _UsageRecordsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final AppUsageController controller;
  final bool showTimeline;
  final ValueChanged<int> onSegmentedControlChanged;
  final ScrollController? scrollController;

  _UsageRecordsHeaderDelegate({
    required this.controller,
    required this.showTimeline,
    required this.onSegmentedControlChanged,
    this.scrollController,
  });

  double get _baseHeight => 60.0; // 标题行高度（包含padding）
  double get _timelineExtraHeight => showTimeline ? 65.0 : 0.0; // 横向列表(54) + 间距(12+16)

  @override
  double get minExtent => _baseHeight + _timelineExtraHeight; // 最小高度（吸顶时的高度）

  @override
  double get maxExtent => _baseHeight + _timelineExtraHeight; // 最大高度（正常显示时的高度）

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // 吸顶时添加白色背景和圆角
    return Container(
      height: _baseHeight + _timelineExtraHeight,

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Image.asset(
                    'assets/4.0/kissu4_app_use_late_tip.webp',
                    width: 70,
                    height: 16,
                    fit: BoxFit.fitWidth,
                  ),
                  const Text(
                    '使用记录',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'AlimamaShuHeiTi',
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Transform.translate(
                offset: const Offset(-8, -5),
                child: Image.asset(
                  'assets/4.0/kissu4_app_use_tip.webp',
                  width: 13,
                  height: 17,
                ),
              ),
              const Spacer(),
              _buildSegmentedControl(
                options: const ['统计', '时间轴'],
                selectedIndex: showTimeline ? 1 : 0,
                onSelected: onSegmentedControlChanged,
              ),
            ],
          ),
          if (showTimeline) ...[
            const SizedBox(height: 12),
            _buildTimelineAppSelector(controller),
            const SizedBox(height: 0), // 移除底部留白
          ],
        ],
      ),
    );
  }

  /// 分段控制器（从AppUsagePage复制）
  Widget _buildSegmentedControl({
    required List<String> options,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(options.length, (index) {
          final isSelected = index == selectedIndex;
          final isFirst = index == 0;
          final isLast = index == options.length - 1;

          return GestureDetector(
            onTap: () => onSelected(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: isFirst ? const Radius.circular(20) : Radius.zero,
                  bottomLeft: isFirst ? const Radius.circular(20) : Radius.zero,
                  topRight: isLast ? const Radius.circular(20) : Radius.zero,
                  bottomRight: isLast ? const Radius.circular(20) : Radius.zero,
                ),
              ),
              child: Text(
                options[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF777777),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTimelineAppSelector(AppUsageController controller) {
    return Obx(() {
      final latelyApps = controller.latelyUseAppData;
      return SizedBox(
        height: 44, // 减少高度：44(图标) + 10(上下间距)
        child: Stack(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: latelyApps.map((app) {
                  final isSelected =
                      controller.selectedAppForTimeline.value == app.appPkg;
                  return GestureDetector(
                    onTap: () => controller.selectAppForTimeline(app.appPkg),
                    child: Container(
                      margin: const EdgeInsets.only(right: 2),
                      width: 44,
                      height: 44,
                     
                      alignment: Alignment.center,
                      child: AnimatedScale(
                        scale: isSelected ? 1.3 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: app.appLogo.isNotEmpty
                            ? Container(

                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xffdddddd),
                                      blurRadius: 2,
                                      offset: const Offset(1, 1),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: NetworkImageHelper.loadImage(
                                    imageUrl: app.appLogo,
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.cover,
                                    errorWidget: Image.asset(
                                      'assets/images/kissu4_logo.png',
                                      width: 30,
                                      height: 30,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Image.asset(
                                  'assets/images/kissu4_logo.png',
                                  width: 30,
                                  height: 30,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (latelyApps.length > 5)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 40,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Colors.white.withOpacity(0), Colors.white],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  @override
  bool shouldRebuild(covariant _UsageRecordsHeaderDelegate oldDelegate) {
    return showTimeline != oldDelegate.showTimeline;
  }
}

