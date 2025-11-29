import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/network_image_helper.dart';
import 'package:kissu_app/widgets/selector/date_selector.dart';
import 'package:kissu_app/models/usage_record_api_model.dart';
import 'package:kissu_app/widgets/custom_refresh_header.dart';
import 'package:kissu_app/widgets/skeleton/sensitive_record_skeleton.dart';
import 'usage_report_controller.dart';

class UsageReportPage extends GetView<UsageReportController> {
  const UsageReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 保存context到controller，用于Overlay
    controller.pageContext = context;

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
    return Column(
      children: [
        // 顶部背景图（140高度）
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
        // 剩余部分渐变背景
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.1, 1],
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
            // 记录列表
            Expanded(child: _buildRecordList()),
          ],
        ),
        // 底部筛选按钮（悬浮）
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
        return const SensitiveRecordSkeleton();
      }

      if (records.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 88),
              Image.asset(
                'assets/phone_history/kissu_phone_list_empty.webp',
                width: 120,
                height: 120,
              ),
              SizedBox(height: 12),
              Text(
                '暂无使用数据哦',
                style: TextStyle(fontSize: 12, color: Color(0xFF333333)),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.onRefresh,
        color: Color(0xFFFF6B9D),
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            // 预加载：当滚动到距离底部300px时就开始加载更多
            // 这样用户滚动时不会感觉到等待
            if (scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 300) {
              if (hasMore && !isLoadingMore) {
                controller.loadMoreData();
              }
            }
            return false;
          },
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 15).copyWith(bottom: 80),
            itemCount: records.length + (hasMore ? 1 : 0) + 1, // +1 for refresh time hint
            // 优化：使用iOS弹性滚动效果
            physics: const BouncingScrollPhysics(),
            // 优化：增加缓存范围，提前渲染屏幕外的内容
            cacheExtent: 500,
            itemBuilder: (context, index) {
              // 第一项：刷新时间提示
              if (index == 0) {
                return Obx(() => RefreshTimeHint(
                  lastRefreshTime: controller.lastRefreshTime.value,
                  isPulling: controller.isPullingRefresh.value,
                ));
              }
              
              // 调整索引
              final recordIndex = index - 1;
              
              if (recordIndex == records.length) {
                // 加载更多指示器
                return Container(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: isLoadingMore
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFFF6B9D),
                            ),
                          ),
                        )
                      : SizedBox.shrink(),
                );
              }

              final record = records[recordIndex];
              // 优化：使用独立Widget并添加RepaintBoundary
              return RepaintBoundary(
                child: _RecordItem(
                  record: record,
                  onTap: () => controller.handleRecordItemClick(record),
                  onJumpTap: () => controller.handleJumpPageClick(record.jumpPage),
                ),
              );
            },
          ),
        ),
      );
    });
  }


  // 格式化时间
  static String _formatTime(String createTime) {
    try {
      final dateTime = DateTime.parse(createTime);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return createTime;
    }
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
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xffffffff),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Color(0xffFF9AD9)),
              boxShadow: [
                BoxShadow(
                  color: Color(0xff000000).withOpacity(0.1),
                  offset: Offset(0, 0),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image(
                  image: AssetImage(
                    'assets/phone_history/kissu_phone_selecter.webp',
                  ),
                  width: 14,
                  height: 14,
                ),
                SizedBox(width: 6),
                Text(
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
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Image.asset(
              'assets/images/kissu_mine_back.webp',
              width: 24,
              height: 24,
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                '敏感操作记录',
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
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16),child: DateSelector(
      externalSelectedIndex: controller.selectedDateIndex,
      onSelect: (date) {
        controller.changeDate(date);
      },
    ),);
  }

  /// 构建底部信息栏
  Widget _buildBottomInfo() {
    return Container(
      // height: 65,
      padding: EdgeInsets.symmetric(
        horizontal: 15,
      ).copyWith(bottom: 16, top: 12),
      // decoration: const BoxDecoration(color: Color(0xffF2F2F7)),
      child: _buildDeviceInfo(),
    );
  }

  /// 构建设备信息
  Widget _buildDeviceInfo() {
    // final deviceInfo = controller.deviceInfo.value;

    // 获取设备信息，如果没有则显示默认值
    final distance = '未知';
    final mobileModel =  '未知';
    final networkName =  '未知';
    final power =  '未知';
    final isWifi =  false;

    return Container(
        height: 65,
        padding: const EdgeInsets.symmetric(horizontal: 15),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 距离信息
            _buildDeviceInfoItem(
              icon: 'assets/phone_history/kissu_phone_distance.webp',
              text: distance,
              maxLength: 4,
            ),
            const Spacer(),
            // 手机型号
            if (mobileModel.isNotEmpty) ...[
              _buildDeviceInfoItem(
                icon: 'assets/phone_history/kissu_phone_type.webp',
                text: mobileModel,
                maxLength: 4,
              ),
              const Spacer(),
            ],
            // 网络信息
            _buildDeviceInfoItem(
              icon: 'assets/phone_history/kissu_phone_wifi.webp',
              text: isWifi && networkName.isNotEmpty ? networkName : '移动网络',
              maxLength: 4,
            ),
            const Spacer(),
            // 电量信息
            if (power.isNotEmpty) ...[
              _buildDeviceInfoItem(
                icon: 'assets/phone_history/kissu_phone_barry.webp',
                text: power,
                maxLength: null, // 电量不截断
              ),
            ],
          ],
        ),
      );
  }

  /// 构建设备信息项（带长按显示详情）
  Widget _buildDeviceInfoItem({
    required String icon,
    required String text,
    int? maxLength,
  }) {
    final displayText = maxLength != null && text.length > maxLength
        ? '${text.substring(0, maxLength)}...'
        : text;

    return GestureDetector(
       
      child: Container(
        color: Colors.transparent, // 确保整个区域可以响应手势
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(icon, width: 16, height: 16),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                displayText,
                style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 记录项Widget - 独立Widget减少重建
class _RecordItem extends StatelessWidget {
  final SensitiveRecordItem record;
  final VoidCallback onTap;
  final VoidCallback onJumpTap;

  const _RecordItem({
    required this.record,
    required this.onTap,
    required this.onJumpTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff000000).withOpacity(0.04),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Stack(
          children: [
            record.hasSubContent
                ? _buildDoubleRowItem()
                : _buildSingleRowItem(),
            if (record.needsVip)
              Positioned(
                right: 0,
                top: 0,
                child: Transform.translate(
                  offset: const Offset(16, -16),
                  child: Container(
                    height: 16,
                    width: 56,
                    decoration: const BoxDecoration(
                      color: Color(0xffFFBAE4),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      "VIP查看",
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 单行记录（subContent为空）
  Widget _buildSingleRowItem() {
    return Row(
      children: [
        // 左侧图标
        ClipRRect(
          child: NetworkImageHelper.loadImage(
            imageUrl: record.icon,
            width: 18,
            height: 18,
            fit: BoxFit.cover,
            errorWidget: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
              child: const Icon(Icons.image, size: 18, color: Color(0xFFCCCCCC)),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // 中间文本（带高亮）
        Expanded(child: _buildContentWithHighlight()),
        const SizedBox(width: 8),
        // 时间
        Text(
          UsageReportPage._formatTime(record.createTime),
          style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
        ),
      ],
    );
  }

  // 双行记录（有subContent）
  Widget _buildDoubleRowItem() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 左侧图标
        ClipRRect(
          child: NetworkImageHelper.loadImage(
            imageUrl: record.icon,
            width: 18,
            height: 18,
            fit: BoxFit.cover,
            errorWidget: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.image, size: 16, color: Color(0xFFCCCCCC)),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // 中间文本（两行）
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildContentWithHighlight(),
              if (record.hasSubContent) ...[
                const SizedBox(height: 2),
                Text(
                  record.subContent,
                  style: const TextStyle(fontSize: 11, color: Color(0xcc333333)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        // 时间
        Text(
          UsageReportPage._formatTime(record.createTime),
          style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
        ),
      ],
    );
  }

  // 构建带高亮的内容文本
  Widget _buildContentWithHighlight() {
    return Row(
      children: [
        Text(
          record.content,
          style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
        ),
        if (record.showJumpButton)
          GestureDetector(
            onTap: onJumpTap,
            child: Container(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                children: const [
                  Text(
                    "查看",
                    style: TextStyle(
                      color: Color(0xff009BFE),
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 2),
                  Image(
                    image: AssetImage(
                      'assets/phone_history/kissu3_vip_go.webp',
                    ),
                    color: Color(0xff009bfe),
                    width: 8,
                  )
                ],
              ),
            ),
          ),
      ],
    );
  }
}
