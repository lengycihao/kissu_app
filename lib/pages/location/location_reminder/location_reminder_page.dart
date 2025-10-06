import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/location/location_reminder/location_reminder_controller.dart';
import 'package:kissu_app/pages/location/location_reminder/location_picker/location_picker_page.dart';

/// 位置提醒页面
class LocationReminderPage extends StatelessWidget {
  LocationReminderPage({super.key});

  final controller = Get.put(LocationReminderController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            margin: const EdgeInsets.only(left: 16),
            child: Center(
              child: Image.asset(
                'assets/kissu_mine_back.webp',
                width: 24,
                height: 24,
              ),
            ),
          ),
        ),
        title: const Text(
          '位置提醒',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              // TODO: 显示使用须知弹窗
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: const Center(
                child: Text(
                  '使用须知',
                  style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Obx(() {
          return ListView.builder(
            itemCount: controller.reminders.length + 1, // +1 for add button
            itemBuilder: (context, index) {
              // 最后一个item是"添加地点"按钮
              if (index == controller.reminders.length) {
                return _buildAddLocationItem(context);
              }

              // 显示已保存的位置提醒
              final reminder = controller.reminders[index];
              return _buildLocationItem(context, reminder, index);
            },
          );
        }),
      ),
    );
  }

  /// 构建位置提醒item
  Widget _buildLocationItem(
    BuildContext context,
    LocationReminder reminder,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon
              _getLocationIcon(reminder.icon),
              const SizedBox(width: 8),
              // 名称
              Expanded(
                child: Text(
                  reminder.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 删除按钮
              GestureDetector(
                onTap: () {
                  _showDeleteDialog(context, reminder.id);
                },
                child: Image.asset(
                  'assets/location/kissu3_delete_icon.webp',
                  width: 20,
                  height: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          // 地图快照区域
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(7)),
            child: Container(
              height: 80,
              width: double.infinity,
              color: const Color(0xFFF5F5F5),
              child: reminder.mapSnapshot != null
                  ? Image.memory(reminder.mapSnapshot!, fit: BoxFit.cover)
                  : const Center(
                      child: Icon(
                        Icons.map,
                        size: 48,
                        color: Color(0xFFCCCCCC),
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 8),
          // 地址
          Text(
            reminder.address,
            style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 构建"添加地点"item
  Widget _buildAddLocationItem(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // 跳转到地图选点页面
        final result = await Get.to(
          () => LocationPickerPage(),
          transition: Transition.rightToLeft,
        );

        // 如果返回了位置数据，添加到列表
        if (result != null && result is LocationReminder) {
          controller.addReminder(result);
        }
      },
      child: Column(
        children: [
          Container(
            height: 125,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFffffff),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD4D0), width: 1),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Icon
                      Image(
                        image: AssetImage(
                          'assets/home_list_type_location.webp',
                        ),
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 8),
                      // 名称
                      Expanded(
                        child: Text(
                          '添加地点',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Container(
                    height: 78,
                    decoration: BoxDecoration(
                      color: const Color(0x33000000),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/location/kissu3_add_point.webp',
                        width: 105,
                        height: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 15),
          Text(
            '最多可以添加2个地方',
            style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }

  /// 获取位置图标
  Widget _getLocationIcon(String iconType) {
    String assetPath;
    switch (iconType) {
      case 'gym':
        assetPath = 'assets/location/icon_gym.webp';
        break;
      case 'company':
        assetPath = 'assets/location/icon_company.webp';
        break;
      case 'home':
        assetPath = 'assets/location/icon_home.webp';
        break;
      case 'restaurant':
        assetPath = 'assets/location/icon_restaurant.webp';
        break;
      case 'shop':
        assetPath = 'assets/location/icon_shop.webp';
        break;
      default:
        assetPath = 'assets/location/icon_location.webp';
    }

    return Image.asset(
      assetPath,
      width: 24,
      height: 24,
      errorBuilder: (context, error, stackTrace) {
        // 如果图标加载失败，显示默认图标
        return const Icon(
          Icons.location_on,
          size: 24,
          color: Color(0xFFFF88AA),
        );
      },
    );
  }

  /// 显示删除确认对话框
  void _showDeleteDialog(BuildContext context, String reminderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '删除提醒',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          '确定要删除这个位置提醒吗？',
          style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              '取消',
              style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
            ),
          ),
          TextButton(
            onPressed: () {
              controller.removeReminder(reminderId);
              Get.back();
            },
            child: const Text(
              '删除',
              style: TextStyle(fontSize: 16, color: Color(0xFFFF4177)),
            ),
          ),
        ],
      ),
    );
  }
}
