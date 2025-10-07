import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/location/location_reminder/location_reminder_controller.dart';
import 'package:kissu_app/pages/location/location_reminder/location_picker/location_picker_page.dart';
import 'package:kissu_app/pages/location/location_reminder/geofence_detail_page.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/widgets/location_map_snapshot.dart';

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
               
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: const Center(
                child: Row(
                  children: [
                    // Icon(Icons.map, size: 18, color: Color(0xFF666666)),
                    // SizedBox(width: 4),
                    Text(
                      '使用须知',
                      style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Obx(() {
          // 当达到20个时，不显示添加按钮
          final showAddButton = controller.reminders.length < 20;
          return ListView.builder(
            itemCount: controller.reminders.length + (showAddButton ? 1 : 0),
            itemBuilder: (context, index) {
              // 最后一个item是"添加地点"按钮
              if (showAddButton && index == controller.reminders.length) {
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
    return GestureDetector(
      onTap: () {
        // 跳转到围栏详情页面（只读模式）
        Get.to(
          () => GeofenceDetailPage(reminder: reminder),
          transition: Transition.rightToLeft,
        );
      },
      child: Container(
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
              // 名称（根据图标类型和性别显示）
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        _getLocationName(reminder.icon),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      reminder.type == ReminderType.arrive ? "到达" : "离开",
                      style: TextStyle(
                        fontSize: 11,
                        color: reminder.type == ReminderType.arrive
                            ? const Color(0xFF1976D2)
                            : const Color(0xFFF57C00),
                      ),
                    ),
                  ],
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
          // 地图快照区域 - 使用自定义地图组件（带图标和围栏圆圈）
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(7)),
            child: LocationMapSnapshot(
              longitude: reminder.longitude,
              latitude: reminder.latitude,
              radius: reminder.radius.toInt(),
              iconId: reminder.icon,
              reminderType: reminder.type,
              isSatellite: reminder.mapType == 2, // 根据保存的地图类型决定
              size: '800*160', // 2倍分辨率，适配高清屏
              height: 80,
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
          // 备注（如果有）
          if (reminder.note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '备注：${reminder.note}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 3),
          // 围栏信息和开关
          // Row(
          //   children: [
          //     // 围栏类型和半径
          //     Container(
          //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          //       decoration: BoxDecoration(
          //         color: reminder.type == ReminderType.arrive
          //             ? const Color(0xFFE3F2FD)
          //             : const Color(0xFFFFF3E0),
          //         borderRadius: BorderRadius.circular(4),
          //       ),
          //       child: Text(
          //         '${reminder.type == ReminderType.arrive ? "到达" : "离开"}提醒 · ${reminder.radius.toInt()}米',
          //         style: TextStyle(
          //           fontSize: 11,
          //           color: reminder.type == ReminderType.arrive
          //               ? const Color(0xFF1976D2)
          //               : const Color(0xFFF57C00),
          //         ),
          //       ),
          //     ),
          //     const Spacer(),
          //     // 激活/暂停开关
          //     GestureDetector(
          //       onTap: () {
          //         controller.toggleReminderActive(reminder.id);
          //       },
          //       child: Container(
          //         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          //         decoration: BoxDecoration(
          //           color: reminder.isActive
          //               ? const Color(0xFF4CAF50)
          //               : const Color(0xFFE0E0E0),
          //           borderRadius: BorderRadius.circular(12),
          //         ),
          //         child: Row(
          //           children: [
          //             Icon(
          //               reminder.isActive ? Icons.check_circle : Icons.pause_circle,
          //               size: 14,
          //               color: reminder.isActive ? Colors.white : const Color(0xFF757575),
          //             ),
          //             const SizedBox(width: 4),
          //             Text(
          //               reminder.isActive ? '已激活' : '已暂停',
          //               style: TextStyle(
          //                 fontSize: 11,
          //                 color: reminder.isActive ? Colors.white : const Color(0xFF757575),
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ),
          //     const SizedBox(width: 8),
            
          //     // 查看地图按钮
          //     GestureDetector(
          //       onTap: () {
          //         Get.to(() => GeofenceMapViewPage(focusReminder: reminder));
          //       },
          //       child: const Icon(
          //         Icons.map_outlined,
          //         size: 20,
          //         color: Color(0xFF4D9FFF),
          //       ),
          //     ),
          //   ],
          // ),
       
        ],
        ),
      ),
    );
  }

  /// 构建"添加地点"item
  Widget _buildAddLocationItem(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // 🔧 新建位置提醒时不传入初始位置，让用户在地图上自由选择
        // 只在编辑已有提醒时才传入位置
        final result = await Get.to(
          () => LocationPickerPage(
            // 不传入任何初始位置参数
          ),
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
                // 使用天安门地图快照作为背景
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        // 天安门地图快照背景
                        LocationMapSnapshot(
                          latitude: 39.90923,  // 天安门纬度
                          longitude: 116.397428,  // 天安门经度
                          radius: 500,  // 500米范围
                          iconId: 1,  // 使用公司图标
                          reminderType: ReminderType.arrive,  // 默认使用到达类型（蓝色）
                        ),
                        // 半透明遮罩层
                        Container(
                          color: const Color(0x66000000),
                        ),
                        // 添加地点文字
                        Center(
                          child: Image.asset(
                            'assets/location/kissu3_add_point.webp',
                            width: 105,
                            height: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 15),
          Text(
            '最多可以添加20个地方',
            style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }

  /// 获取位置图标
  Widget _getLocationIcon(int iconId) {
    String assetPath;
    switch (iconId) {
      case 1: // 公司
        assetPath = 'assets/location/kissu3_gongsi_sel.webp';
        break;
      case 2: // 家
        assetPath = 'assets/location/kissu3_jia_sel.webp';
        break;
      case 3: // 娱乐
        assetPath = 'assets/location/kissu3_yule_sel.webp';
        break;
      case 4: // 健身房
        assetPath = 'assets/location/kissu3_jianshen_sel.webp';
        break;
      case 5: // 商场
        assetPath = 'assets/location/kissu3_shangchang_sel.webp';
        break;
      default:
        assetPath = 'assets/location/kissu3_jia_sel.webp'; // 默认使用家的图标
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

  /// 获取位置名称（根据图标类型和伴侣性别）
  String _getLocationName(int iconId) {
    // 获取伴侣性别，默认为女性（她）
    final user = UserManager.currentUser;
    String pronoun = '她';
    
    if (user != null) {
      // 优先使用 loverInfo
      if (user.loverInfo?.gender != null) {
        pronoun = user.loverInfo!.gender == 1 ? '他' : '她';
      } 
      // 其次使用 halfUserInfo
      else if (user.halfUserInfo?.gender != null) {
        pronoun = user.halfUserInfo!.gender == 1 ? '他' : '她';
      }
    }

    switch (iconId) {
      case 1:
        return '${pronoun}的公司';
      case 2:
        return '${pronoun}的家';
      case 3:
        return '${pronoun}常去的娱乐场所';
      case 4:
        return '${pronoun}常去的健身房';
      case 5:
        return '${pronoun}常去的商场';
      default:
        return '${pronoun}的位置';
    }
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
