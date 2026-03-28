import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:kissu_app/widgets/custom_refresh_header.dart';
import 'package:kissu_app/widgets/selector/date_selector.dart';

import 'usage_report_controller.dart';
import 'widgets/usage_record_item.dart';

class UsageReportPage extends StatefulWidget {
  const UsageReportPage({super.key});

  @override
  State<UsageReportPage> createState() => _UsageReportPageState();
}

class _UsageReportPageState extends State<UsageReportPage> with WidgetsBindingObserver {
  late UsageReportController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<UsageReportController>();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // 切换到后台
      controller.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      // 从后台返回
      controller.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    controller.pageContext = context;

    return Scaffold(
      body: Listener(
        // 点击页面任意位置时，主动关闭设备信息 tip
        onPointerDown: (_) => controller.clearSelectedDeviceInfo(),
        child: Stack(
          children: [
            _buildBackground(),
            SafeArea(child: _buildMainContent()),
          ],
        ),
      ),
    );
  }

  // 背景图
  Widget _buildBackground() {
    return Column(
      children: [
        Container(
          height: 140,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                'assets/phone_history/kissu3_phone_history_bg.webp',
              ),
              fit: BoxFit.fill,
              alignment: Alignment.topCenter,
            ),
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.1, 1],
                colors: [Colors.white, Color(0xFFF6F6F6), Color(0xFFF6F6F6)],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 主内容
  Widget _buildMainContent() {
    return Stack(
      children: [
        Column(
          children: [
            _buildHeader(),
            _buildBottomInfo(),
            _buildDateSelector(),
            const SizedBox(height: 16),
            Expanded(child: _buildRecordList()),
          ],
        ),
        _buildFloatingFilterButton(),
      ],
    );
  }

  // 构建记录列表
  Widget _buildRecordList() {
    return Obx(() {
      final records = controller.sensitiveRecordList;
      final isLoading = controller.isLoading.value;
      final isLoadingMore = controller.isLoadingMore.value;
      final hasMore = controller.hasMore.value;

      if (isLoading && records.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6B9D)),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.onRefresh,
        color: const Color(0xFFFF6B9D),
        child: records.isEmpty
            ? Builder(
                builder: (context) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 200,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 150),
                        Image.asset(
                          'assets/phone_history/kissu_phone_list_empty.webp',
                          width: 120,
                          height: 120,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '暂无使用数据哦',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (scrollInfo.metrics.pixels >=
                      scrollInfo.metrics.maxScrollExtent - 300) {
                    if (hasMore && !isLoadingMore) {
                      controller.loadMoreData();
                    }
                  }
                  return false;
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                  ).copyWith(bottom: 80),
                  // +1 for refresh time hint
                  itemCount: records.length + (hasMore ? 1 : 0) + 1,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  cacheExtent: 500,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Obx(
                        () => RefreshTimeHint(
                          lastRefreshTime: controller.lastRefreshTime.value,
                          isPulling: controller.isPullingRefresh.value,
                        ),
                      );
                    }

                    final recordIndex = index - 1;

                    if (recordIndex == records.length) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        child: isLoadingMore
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFFF6B9D),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      );
                    }

                    final record = records[recordIndex];
                    return RepaintBoundary(
                      child: UsageRecordItem(
                        record: record,
                        onTap: () => controller.handleRecordItemClick(record),
                        onJumpTap: () =>
                            controller.handleJumpPageClick(record.jumpPage),
                      ),
                    );
                  },
                ),
              ),
      );
    });
  }

  // 构建底部悬浮筛选按钮
  Widget _buildFloatingFilterButton() {
    return Positioned(
      bottom: 60,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: () => controller.showFilterDialog(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xffffffff),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xffFF9AD9)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff000000).withOpacity(0.1),
                  offset: const Offset(0, 0),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Image(
                  image: AssetImage(
                    'assets/phone_history/kissu_phone_selecter.webp',
                  ),
                  width: 14,
                  height: 14,
                ),
                const SizedBox(width: 6),
                const Text(
                  '筛选',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF000000),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // 构建顶部标题栏
  Widget _buildHeader() {
    return SizedBox(
      height: 44,
      child: Stack(
        children: [
          // 返回按钮
          Positioned(
            left: 5,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/images/kissu_mine_back.webp',
                  width: 22,
                  height: 22,
                ),
              ),
            ),
          ),
          // 标题 - 绝对居中
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                '敏感操作记录',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建日期选择器
  Widget _buildDateSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DateSelector(
        externalSelectedIndex: controller.selectedDateIndex,
        onSelect: controller.changeDate,
      ),
    );
  }

  /// 构建底部信息栏
  Widget _buildBottomInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
      ).copyWith(bottom: 16, top: 12),
      child: _buildDeviceInfo(),
    );
  }

  /// 构建设备信息
  Widget _buildDeviceInfo() {
    return Obx(() {
      // 获取设备信息，如果没有则显示默认值
      final deviceData = controller.halfUserData.value;
      final distance = deviceData?.distance ?? '未知';
      final mobileModel = deviceData?.mobileModel ?? '未知';
      final networkName = deviceData?.networkName ?? '未知';
      final power = deviceData?.power ?? '未知';
      final selectedType = controller.selectedDeviceInfoType.value;

      return Container(
        height: 65,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xffffffff),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff000000).withOpacity(0.06),
              offset: const Offset(0, 0),
              blurRadius: 8,
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 底部四个设备信息项
            _buildNormalDeviceInfo(
              distance: distance,
              mobileModel: mobileModel,
              networkName: networkName,
              power: power,
            ),
            // 顶部悬浮黑色气泡样式详情（根据选中项浮在对应图标正上方）
            if (selectedType != null)
              _buildDeviceInfoTooltip(
                type: selectedType,
                distance: distance,
                mobileModel: mobileModel,
                networkName: networkName,
                power: power,
              ),
          ],
        ),
      );
    });
  }

  /// 构建正常状态的设备信息（4个模块并排）
  Widget _buildNormalDeviceInfo({
    required String distance,
    required String mobileModel,
    required String networkName,
    required String power,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 距离信息
        Expanded(
          child: _buildDeviceInfoItem(
            icon: 'assets/phone_history/kissu_phone_distance.webp',
            text: distance,
            maxLength: 6,
            type: 'distance',
          ),
        ),
        const SizedBox(width: 8),
        // 手机型号
        Expanded(
          child: _buildDeviceInfoItem(
            icon: 'assets/phone_history/kissu_phone_type.webp',
            text: mobileModel,
            maxLength: 6,
            type: 'mobileModel',
          ),
        ),
        const SizedBox(width: 8),
        
        // 网络信息
        Expanded(
          child: _buildDeviceInfoItem(
            icon: 'assets/phone_history/kissu_phone_wifi.webp',
            text: networkName.isNotEmpty && networkName != '未知'
                ? networkName
                : '未知',
            maxLength: 8,
            type: 'network',
          ),
        ),
        const SizedBox(width: 8),
        // 电量信息
        Expanded(
          child: _buildDeviceInfoItem(
            icon: 'assets/phone_history/kissu_phone_barry.webp',
            text: power,
            maxLength: null,
            type: 'power',
          ),
        ),
      ],
    );
  }

  /// 构建设备信息悬浮气泡（黑色背景 + 小三角），浮在对应图标正上方
  /// 使用与底部完全相同的 Row 结构，确保精确对齐
  Widget _buildDeviceInfoTooltip({
    required String type,
    required String distance,
    required String mobileModel,
    required String networkName,
    required String power,
  }) {
    String content;
    switch (type) {
      case 'distance':
        content = distance;
        break;
      case 'mobileModel':
        content = mobileModel;
        break;
      case 'network':
        content =
            networkName.isNotEmpty && networkName != '未知' ? networkName : '未知';
        break;
      case 'power':
        content = power;
        break;
      default:
        content = '';
        break;
    }

    if (content.isEmpty) {
      return const SizedBox.shrink();
    }

    // 使用与 _buildNormalDeviceInfo 完全相同的 Row 结构，保证对齐
    Widget buildBubble(String bubbleType, String bubbleText) {
      if (bubbleType != type || bubbleText.isEmpty) {
        return const SizedBox.shrink();
      }
      // 在这一列内部居中，气泡的三角正对下面图标的中心
      // 使用 Align 而不是 Center，允许气泡宽度超出列宽
      return Align(
        alignment: Alignment.center,
        child: _DeviceInfoTooltipBubble(text: bubbleText),
      );
    }

    return Positioned(
      top: -40,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: buildBubble('distance', distance)),
            const SizedBox(width: 8),
            Expanded(child: buildBubble('mobileModel', mobileModel)),
            const SizedBox(width: 8),
            Expanded(
              child: buildBubble(
                'network',
                networkName.isNotEmpty && networkName != '未知'
                    ? networkName
                    : '未知',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: buildBubble('power', power)),
          ],
        ),
      ),
    );
  }

  /// 构建设备信息项（带点击展开功能）
  Widget _buildDeviceInfoItem({
    required String icon,
    required String text,
    int? maxLength,
    required String type,
  }) {
    final displayText = maxLength != null && text.length > maxLength
        ? '${text.substring(0, maxLength)}...'
        : text;

    return Obx(() {
      final selectedType = controller.selectedDeviceInfoType.value;
      final isSelected = selectedType == type;

      return GestureDetector(
        onTap: () => controller.toggleDeviceInfo(type),
        child: Container(
          color: Colors.transparent,
          // padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            // mainAxisSize: MainAxisSize.spaceBetween,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: 'device_info_icon_$type',
                child: Image.asset(icon, width: 22, height: 22),
              ),
               Flexible(
                child: Hero(
                  tag: 'device_info_content_$type',
                  child: Material(
                    color: Colors.transparent,
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF333333),
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// 单个设备信息的悬浮提示气泡
class _DeviceInfoTooltipBubble extends StatelessWidget {
  final String text;

  const _DeviceInfoTooltipBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return UnconstrainedBox(
      constrainedAxis: Axis.vertical,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
              ),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
            ),
          ),
          CustomPaint(
            size: const Size(12, 6),
            painter: _TooltipArrowPainter(),
          ),
        ],
      ),
    );
  }
}

/// 气泡底部的小三角形
class _TooltipArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
