import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/mine/app_usage/models/app_usage_record.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'app_usage_controller.dart';

/// App使用统计页面
class AppUsagePage extends StatelessWidget {
  const AppUsagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AppUsageController());
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF333333), size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'App使用统计',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          // 测试页面入口
          IconButton(
            icon: const Icon(Icons.science_outlined, color: Color(0xFFFF839E), size: 24),
            onPressed: () => Get.toNamed(KissuRoutePath.dialogShowcase),
            tooltip: '测试弹窗页面',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 权限提示（只在没权限时显示）
            Obx(() {
              final hasPermission = controller.hasUsagePermission.value;
              if (!hasPermission) return _buildPermissionBanner(controller);
              return const SizedBox();
            }),
            
            // 日期选择器（最近7天）
            _buildDateSelector(controller),
            
            const SizedBox(height: 16),
            
            // 最近使用App模块
            _buildRecentlyUsedApps(controller),
            
            const SizedBox(height: 16),
            
            // 使用记录模块
            _buildUsageRecords(controller),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  /// 权限提示横幅
  Widget _buildPermissionBanner(AppUsageController controller) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFFFF839E),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '目前必要权限还未开启，会造成数据显示错误',
              style: TextStyle(
                color: const Color(0xFFFF839E),
                fontSize: 13,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => controller.openUsageSettings(),
            child: Row(
              children: const [
                Text(
                  '去开启',
                  style: TextStyle(
                    color: Color(0xFFFF839E),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFFFF839E),
                  size: 12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// 日期选择器（最近7天）
  Widget _buildDateSelector(AppUsageController controller) {
    return Obx(() {
      final selectedDate = controller.selectedDate.value;
      final showPicker = controller.showDatePicker.value;
      final isToday = _isToday(selectedDate);
      
      return Column(
        children: [
          // 日期按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: GestureDetector(
              onTap: () => controller.toggleDatePicker(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isToday 
                          ? '${selectedDate.month}月${selectedDate.day}日 今天'
                          : '${selectedDate.month}月${selectedDate.day}日',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      showPicker ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // 日期选择面板
          if (showPicker) _buildDatePickerPanel(controller),
        ],
      );
    });
  }
  
  /// 日期选择面板（最近7天）
  Widget _buildDatePickerPanel(AppUsageController controller) {
    final now = DateTime.now();
    final dates = List.generate(7, (index) => now.subtract(Duration(days: 6 - index)));
    
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() {
        final selectedDate = controller.selectedDate.value;
        
        return Row(
          children: List.generate(dates.length, (index) {
            final date = dates[index];
            final isSelected = _isSameDay(date, selectedDate);
            final dateText = _getDateText(date);
            
            return Expanded(
              child: GestureDetector(
                onTap: () => controller.selectDate(date),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFF839E) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dateText,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? Colors.white : const Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }
  
  /// 获取日期文本（周几）
  String _getDateText(DateTime date) {
    const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return weekdays[date.weekday % 7];
  }
  
  /// 判断是否同一天
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }
  
  /// 最近使用App模块
  Widget _buildRecentlyUsedApps(AppUsageController controller) {
    return Obx(() {
      final apps = controller.recentlyUsedApps;
      
      // 空数据状态
      if (apps.isEmpty) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '最近使用App',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.auto_awesome, size: 16, color: Colors.amber),
                  const Spacer(),
                  Obx(() {
                    final showCount = controller.showUsageCount.value;
                    return Row(
                      children: [
                        _buildTabButton('次数', showCount, () => controller.showUsageCount.value = true),
                        const SizedBox(width: 8),
                        _buildTabButton('分钟', !showCount, () => controller.showUsageCount.value = false),
                      ],
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
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF999999),
                      ),
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
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '最近使用App',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.auto_awesome, size: 16, color: Colors.amber),
                const Spacer(),
                Obx(() {
                  final showCount = controller.showUsageCount.value;
                  return Row(
                    children: [
                      _buildTabButton('次数', showCount, () => controller.showUsageCount.value = true),
                      const SizedBox(width: 8),
                      _buildTabButton('分钟', !showCount, () => controller.showUsageCount.value = false),
                    ],
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
                  itemCount: displayApps.length,
                  itemBuilder: (context, index) {
                    final app = displayApps[index];
                    return _buildRecentAppItem(app, controller);
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
                          colors: [
                            Colors.white.withOpacity(0),
                            Colors.white,
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            // 查看全部/收起按钮（少于5个时用SizedBox占位保持高度）
            SizedBox(
              height: 40,
              child: hasMore
                  ? Center(
                      child: GestureDetector(
                        onTap: () => controller.toggleShowAllRecentApps(),
                        child: Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                showAll ? '收起' : '查看全部',
                                style: const TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                showAll ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: const Color(0xFF666666),
                                size: 16,
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
  Widget _buildRecentAppItem(AppUsageRecord app, AppUsageController controller) {
    return Obx(() {
      final showCount = controller.showUsageCount.value;
      final value = showCount ? app.sessionCount : (app.totalDuration / 60000).round();
      final unit = showCount ? '次' : '分钟';
      final maxValue = showCount ? controller.maxSessionCount : controller.maxDuration;
      final progress = maxValue > 0 ? value / maxValue : 0.0;
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            // App图标
            if (app.icon != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  app.icon!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF839E).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.apps, color: Color(0xFFFF839E), size: 24),
              ),
            
            const SizedBox(width: 12),
            
            // App名称和进度条
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.appName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: const Color(0xFFE0E0E0),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF64B5F6)),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            // 使用次数/时长
            Text(
              '$value$unit',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
      );
    });
  }
  
  /// 标签按钮
  Widget _buildTabButton(String text, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF999999),
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  
  /// 使用记录模块
  Widget _buildUsageRecords(AppUsageController controller) {
    return Obx(() {
      final records = controller.usageRecords;
      
      // 空数据状态
      if (records.isEmpty) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '使用记录',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.auto_awesome, size: 16, color: Colors.amber),
                  const Spacer(),
                  Obx(() {
                    final showTimeline = controller.showTimeline.value;
                    return Row(
                      children: [
                        _buildTabButton('统计', !showTimeline, () => controller.showTimeline.value = false),
                        const SizedBox(width: 8),
                        _buildTabButton('时间轴', showTimeline, () => controller.showTimeline.value = true),
                      ],
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
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      }
      
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '使用记录',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.auto_awesome, size: 16, color: Colors.amber),
                const Spacer(),
                Obx(() {
                  final showTimeline = controller.showTimeline.value;
                  return Row(
                    children: [
                      _buildTabButton('统计', !showTimeline, () => controller.showTimeline.value = false),
                      const SizedBox(width: 8),
                      _buildTabButton('时间轴', showTimeline, () => controller.showTimeline.value = true),
                    ],
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),
            
            // 内容区域
            Obx(() {
              final showTimeline = controller.showTimeline.value;
              return showTimeline 
                  ? _buildTimelineView(controller)
                  : _buildStatisticsView(controller);
            }),
          ],
        ),
      );
    });
  }
  
  /// 统计视图（从00:00到当前时间或24:00）
  Widget _buildStatisticsView(AppUsageController controller) {
    final records = controller.usageRecords;
    final selectedDate = controller.selectedDate.value;
    final isToday = _isToday(selectedDate);
    
    // 如果是今天，显示到当前小时；如果是历史日期，显示完整24小时
    final maxHour = isToday ? DateTime.now().hour : 23;
    
    // 构建时间段数据
    final widgets = <Widget>[];
    
    for (int hour = maxHour; hour >= 0; hour--) {
      // 检查这个时间段是否有使用记录
      final appsInSlot = <AppUsageRecord>[];
      for (final record in records) {
        if (record.hourlyRecords.any((h) => h.hour == hour)) {
          appsInSlot.add(record);
        }
      }
      
      // 如果有使用记录，显示：时间点 -> 大圆点+App列表 -> (下一个时间点的小圆点会在下一轮显示)
      if (appsInSlot.isNotEmpty) {
        // 显示当前时间点（小圆点）
        widgets.add(_buildTimePoint('${hour.toString().padLeft(2, '0')}:00'));
        // 显示大圆点+App列表
        widgets.add(_buildAppListRow(appsInSlot, hour));
      } else {
        // 没有使用记录，只显示时间点（小圆点）
        widgets.add(_buildTimePoint('${hour.toString().padLeft(2, '0')}:00', isLast: hour == 0));
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
  
  /// 构建时间点（带小圆点）
  Widget _buildTimePoint(String time, {bool isLast = false}) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              time,
              style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          // 统一20px宽度，小圆点居中，虚线从中心（10px）位置绘制
          SizedBox(
            width: 20,
            child: Column(
              children: [
                // 小圆点居中
                Center(
                  child: Image.asset(
                    'assets/4.0/kissu4_app_use_point.webp',
                    width: 10,
                    height: 10,
                    fit: BoxFit.contain,
                  ),
                ),
                // 虚线（向下连接，从中心位置）
                if (!isLast)
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
  
  /// 构建App列表行（带大圆点）
  Widget _buildAppListRow(List<AppUsageRecord> apps, int hour) {
    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧空白（对齐时间）
          const SizedBox(width: 68),
          
          // 大圆点和虚线（20px宽度，虚线从中心位置）
          SizedBox(
            width: 20,
            child: Column(
              children: [
                // 大圆点图片（20x20，正好填满容器）
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: Row(
                    children: apps.map((record) {
                      final hourlyRecord = record.hourlyRecords.firstWhere((h) => h.hour == hour);
                      final duration = hourlyRecord.totalDuration;
                      final minutes = (duration / 60000).round();
                      
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (record.icon != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  record.icon!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF839E).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.apps, color: Color(0xFFFF839E), size: 28),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              '${minutes}分钟',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                // 右侧渐变蒙版
                if (apps.length > 4)
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
  
  /// 时间轴视图
  Widget _buildTimelineView(AppUsageController controller) {
    final records = controller.usageRecords;
    
    // 获取所有会话记录
    final allSessions = <SessionWithApp>[];
    for (final record in records) {
      for (final hourly in record.hourlyRecords) {
        for (final session in hourly.sessions) {
          allSessions.add(SessionWithApp(record: record, session: session));
        }
      }
    }
    allSessions.sort((a, b) => b.session.openTime.compareTo(a.session.openTime));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 顶部App图标列表
        SizedBox(
          height: 70,
          child: Stack(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: Row(
                  children: records.map((record) {
                    final isSelected = controller.selectedAppForTimeline.value == record.packageName;
                    return GestureDetector(
                      onTap: () => controller.selectAppForTimeline(record.packageName),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 56, // 固定宽度，避免布局变化
                        height: 56, // 固定高度，避免布局变化
                        alignment: Alignment.center,
                        child: AnimatedScale(
                          scale: isSelected ? 1.27 : 1.0, // 44 * 1.27 ≈ 56
                          duration: const Duration(milliseconds: 200),
                          child: record.icon != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    record.icon!,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF839E).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.apps,
                                    color: Color(0xFFFF839E),
                                    size: 24,
                                  ),
                                ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              // 右侧渐变蒙版
              if (records.length > 5)
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
        
        const SizedBox(height: 16),
        
        // 时间轴详细记录
        ...allSessions.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final time = DateTime.fromMillisecondsSinceEpoch(item.session.openTime);
          final duration = item.session.duration;
          final durationText = _formatDuration(duration);
          final isLast = index == allSessions.length - 1;
          
          return SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 时间
                SizedBox(
                  width: 48,
                  child: Text(
                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                // 圆点和虚线
                SizedBox(
                  width: 10,
                  child: Column(
                    children: [
                      // 小圆点
                      Image.asset(
                        'assets/4.0/kissu4_app_use_point.webp',
                        width: 10,
                        height: 10,
                        fit: BoxFit.contain,
                      ),
                      // 虚线连接（从中心位置）
                      if (!isLast)
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
                if (item.record.icon != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.memory(
                      item.record.icon!,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF839E).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.apps, color: Color(0xFFFF839E), size: 20),
                  ),
                
                const SizedBox(width: 8),
                
                // 文字信息
                Expanded(
                  child: Text(
                    '打开了"${item.record.appName}"',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF333333),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // 时长
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE0F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    durationText,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFFF839E),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        
        // 底部00:00
        SizedBox(
          height: 30,
          child: Row(
            children: [
              const SizedBox(
                width: 48,
                child: Text(
                  '00:00',
                  style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 10,
                child: Image.asset(
                  'assets/4.0/kissu4_app_use_point.webp',
                  width: 10,
                  height: 10,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// 判断是否是今天
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
  
  /// 格式化时长
  String _formatDuration(int millis) {
    final duration = Duration(milliseconds: millis);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}小时${minutes}分钟';
    } else if (minutes > 0) {
      return '${minutes}分钟';
    } else {
      return '小于1分钟';
    }
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
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
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
