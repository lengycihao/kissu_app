import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'usage_settings_controller.dart';

class UsageSettingsPage extends StatelessWidget {
  const UsageSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UsageSettingsController());
    
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(child: _buildMainContent(controller)),
        ],
      ),
    );
  }

  // 背景图
  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/phone_history/kissu3_phone_history_bg.webp'),
          fit: BoxFit.fill,
        ),
      ),
    );
  }

  // 主内容
  Widget _buildMainContent(UsageSettingsController controller) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1.通知提示设置
                // _buildSectionTitle('1.通知提示设置'),
                // const SizedBox(height: 16),
                // _buildNotificationTypeSection(controller),
                
                // const SizedBox(height: 32),
                
                // 2.手机状态消息
                _buildSectionTitle('手机状态消息'),
                const SizedBox(height: 16),
                _buildPhoneStatusSection(controller),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 构建头部
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
                '用机设置',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24), // 占位，保持标题居中
        ],
      ),
    );
  }

  /// 构建章节标题
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF333333),
      ),
    );
  }



  /// 构建手机状态消息区域
  Widget _buildPhoneStatusSection(UsageSettingsController controller) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 16, bottom: 30),
      // decoration: BoxDecoration(
      //   color: Colors.white,
      //   borderRadius: BorderRadius.circular(9),
         
      // ),
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF87D1),
            ),
          );
        }

        if (controller.notificationList.isEmpty) {
          return const Center(
            child: Text(
              '暂无通知设置',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),
          );
        }

        // 动态构建两列布局
        final items = controller.notificationList;
        final leftItems = <Widget>[];
        final rightItems = <Widget>[];

        for (int i = 0; i < items.length; i++) {
          final item = items[i];
          final switchWidget = _buildDynamicSwitchItem(
            item.title,
            item.checked,
            () => controller.toggleNotification(i),
          );

          if (i % 2 == 0) {
            leftItems.add(switchWidget);
          } else {
            rightItems.add(switchWidget);
          }
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: leftItems,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                children: rightItems,
              ),
            ),
          ],
        );
      }),
    );
  }


  /// 构建动态开关选项
  Widget _buildDynamicSwitchItem(
    String title,
    bool isChecked,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isChecked ? const Color(0xFFFF9AD8) : Colors.transparent,
                border: Border.all(
                  color: const Color(0xFFFF9AD8),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isChecked
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF666666),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
