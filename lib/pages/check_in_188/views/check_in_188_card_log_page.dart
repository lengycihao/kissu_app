import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'check_in_188_card_log_controller.dart';

/// 补签卡日志页面
class CheckIn188CardLogPage extends GetView<CheckIn188CardLogController> {
  const CheckIn188CardLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffEFEFEF),
      body: Stack(
        
        children: [
          // 背景渐变
         // 背景图
          Positioned.fill(
            child: Image.asset(
              "assets/4.0/kissu4_new_use_bg.webp",
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),
          // 内容区域
          Column(
            children: [
              // 导航栏
              _buildNavBar(),
              // Tab切换
              _buildTabBar(),
              // 内容列表
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollUpdateNotification) {
                      controller.updateNavBarOpacity(notification.metrics.pixels);
                    }
                    return false;
                  },
                  child: Obx(() {
                    if (controller.currentTabIndex.value == 0) {
                      return _buildObtainRecordList();
                    } else {
                      return _buildUseRecordList();
                    }
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建导航栏
  Widget _buildNavBar() {
    return Obx(() {
      final opacity = controller.navBarOpacity.value;
      return Container(
        padding: EdgeInsets.only(top: Get.mediaQuery.padding.top),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE8EB).withOpacity(opacity),
        ),
        child: SizedBox(
          height: 44,
          child: Stack(
            children: [
              // 返回按钮
              Positioned(
                left: 0,
                child: GestureDetector(
                  onTap: controller.goBack,
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: const Icon(Icons.chevron_left, size: 28),
                  ),
                ),
              ),
              // 标题
              const Center(
                child: Text(
                  '补签卡日志',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// 构建Tab栏
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      height: 34,
      
      child: Obx(() {
        final currentIndex = controller.currentTabIndex.value;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
           GestureDetector(
                onTap: () => controller.switchTab(0),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: currentIndex == 0 ? Colors.black : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  width: 85,
                  child: Text(
                    '获得记录',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: currentIndex == 0 ? Colors.white : const Color(0xFF666666),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 20,),
            GestureDetector(
                onTap: () => controller.switchTab(1),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: currentIndex == 1 ? Colors.black : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),width: 85,
                  child: Text(
                    '补卡记录',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: currentIndex == 1 ? Colors.white : const Color(0xFF666666),
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  /// 构建获得记录列表
  Widget _buildObtainRecordList() {
    return Obx(() {
      if (controller.obtainRecords.isEmpty) {
        return const Center(
          child: Text(
            '暂无获得记录',
            style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.obtainRecords.length,
        itemBuilder: (context, index) {
          final record = controller.obtainRecords[index];
          return _buildObtainRecordItem(record);
        },
      );
    });
  }

  /// 构建获得记录项
  Widget _buildObtainRecordItem(CardObtainRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12).copyWith(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和时间
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                record.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF000000),
                ),
              ),
              Text(
                record.time,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 补签卡图片和数量
          Row(
            children: [
              Image.asset(
                'assets/188/kissu_188_recovery_card.webp',
                width: 50,
                height: 66,
              ),
              const SizedBox(width: 12),
              Text(
                '×${record.count}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 活动说明
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE9EBFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              record.description,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF777777),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建补卡记录列表
  Widget _buildUseRecordList() {
    return Obx(() {
      if (controller.useRecords.isEmpty) {
        return const Center(
          child: Text(
            '暂无补卡记录',
            style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: controller.useRecords.length,
        itemBuilder: (context, index) {
          final record = controller.useRecords[index];
          return _buildUseRecordItem(record);
        },
      );
    });
  }

  /// 构建补卡记录项
  Widget _buildUseRecordItem(CardUseRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14).copyWith(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 补签日期和时间
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    '补签日期：',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  Text(
                    record.date,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF000000),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '${record.userName} ',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFaaaaaa),
                    ),
                  ),
                  Text(
                    record.time,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFaaaaaa),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 补签卡图片和数量
          Row(
            children: [
              Image.asset(
                'assets/188/kissu_188_recovery_card.webp',
                width: 50,
                height: 66,
              ),
              const SizedBox(width: 12),
              Text(
                '×${record.count}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
