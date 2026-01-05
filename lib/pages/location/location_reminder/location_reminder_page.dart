import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/location/location_reminder/location_reminder_controller.dart';
import 'package:kissu_app/pages/location/location_reminder/location_picker/location_picker_page.dart';
import 'package:kissu_app/widgets/location_map_snapshot.dart';
import 'package:kissu_app/widgets/dialogs/delete_location_reminder_dialog.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/utils/agreement_utils.dart'; 
import 'package:kissu_app/models/city_model.dart';
// import 'package:kissu_app/utils/debug_util.dart';
import 'package:kissu_app/widgets/common_back_button.dart';

/// 位置提醒页面
/// 
/// 性能优化：
/// - 使用 GetView 替代 StatelessWidget + Get.put
/// - 使用 Get.lazyPut 管理 Controller 生命周期
/// - 添加 ListView 缓存配置
/// - 使用 ValueKey 优化 Widget 复用
class LocationReminderPage extends GetView<LocationReminderController> {
  const LocationReminderPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 Get.lazyPut 确保 Controller 只创建一次，并在页面销毁时自动清理
    Get.lazyPut<LocationReminderController>(
      () => LocationReminderController(),
      fenix: false,
    );

    // 读取来自定位页面传入的参数，判断是否需要提示另一半开启定位权限
    final args = Get.arguments;
    final bool partnerLocationOpen =
        (args is Map && args['partnerLocationOpen'] is bool)
            ? args['partnerLocationOpen'] as bool
            : true;
    final bool fromAddLocationEntry =
        (args is Map && args['fromAddLocationEntry'] is bool)
            ? args['fromAddLocationEntry'] as bool
            : false;

    // 仅在从“添加地点”入口进入时才触发另一半权限弹窗（控制器内部避免重复弹出）
    if (fromAddLocationEntry) {
      Future.microtask(() {
        try {
          final ctrl = Get.find<LocationReminderController>();
          ctrl.showPartnerPermissionIfNeeded(partnerLocationOpen);
        } catch (_) {}
      });
    }
    return Scaffold(
      backgroundColor: const Color(0xFFf6f6f6),
      body: Stack(
        children: [
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
                // 自定义顶部导航栏（与推送设置保持一致）
                Container(
                  height: 44,
                  child: Stack(
                    children: [
                      // 返回按钮
                      Positioned(
                        left: 6,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: CommonBackButton(
                            onTap: () => Get.back(),
                            assetPath: 'assets/images/kissu_mine_back.webp',
                            iconSize: 24,
                          ),
                        ),
                      ),
                      // 居中标题
                      const Center(
                        child: Text(
                          '位置提醒',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                      // 右侧使用须知入口
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () => AgreementUtils.toLocationNotice(),
                          child: Container(
                            margin: const EdgeInsets.only(right: 16),
                            alignment: Alignment.center,
                            child: const Text(
                              '使用须知',
                              style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 内容区域（保持原 ListView 逻辑）
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Obx(() {
                      // 当达到20个时，不显示添加按钮
                      final showAddButton = controller.reminders.length < 20;
                      return NotificationListener<ScrollNotification>(
                        onNotification: (scrollNotification) {
                          // 监听滑动更新事件
                          if (scrollNotification is ScrollUpdateNotification) {
                            controller.incrementScrollCount();
                          }
                          return false;
                        },
                        child: ListView.builder(
                          // 添加缓存extent，提升性能
                          cacheExtent: 500, // 缓存屏幕外500像素的内容
                          itemCount: controller.reminders.length + (showAddButton ? 1 : 0),
                          itemBuilder: (context, index) {
                            // 最后一个item是"添加地点"按钮
                            if (showAddButton && index == controller.reminders.length) {
                              return _buildAddLocationItem(context);
                            }

                            // 显示已保存的位置提醒
                            final reminder = controller.reminders[index];
                            // 使用 key 来优化 Widget 复用
                            return _buildLocationItem(context, reminder, index);
                          },
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建位置提醒item
  Widget _buildLocationItem(
    BuildContext context,
    LocationReminder reminder,
    int index,
  ) {
    // 使用 ValueKey 提高 Widget 复用效率
    return GestureDetector(
      key: ValueKey(reminder.id),
      onTap: () async {
        // 跳转到位置选择页面（编辑模式）
        final result = await Get.to(
          () => LocationPickerPage(editingReminder: reminder),
          transition: Transition.rightToLeft,
        );
        
        // 如果返回了更新后的数据，更新列表
        if (result != null && result is LocationReminder) {
          controller.updateReminder(result);
        }
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
              // 备注内容
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        reminder.note,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF333333),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // const SizedBox(width: 8),
                    // Text(
                    //   reminder.type == ReminderType.arrive ? "到达" : "离开",
                    //   style: TextStyle(
                    //     fontSize: 11,
                    //     color: reminder.type == ReminderType.arrive
                    //         ? const Color(0xFF1976D2)
                    //         : const Color(0xFFF57C00),
                    //   ),
                    // ),
                  ],
                ),
              ),
              // 删除按钮
              GestureDetector(
                onTap: () {
                  _showDeleteDialog(context, reminder.id);
                },
                child: Image.asset(
                  'assets/setting/kissu_navbar_delete.webp',
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
        // 获取从定位页面传入的城市信息
        final arguments = Get.arguments as Map<String, dynamic>?;
        final partnerCity = arguments?['partnerCity'] as CityModel?;
        
        // 🔧 新建位置提醒时不传入初始位置，让用户在地图上自由选择
        // 只在编辑已有提醒时才传入位置
        final result = await Get.to(
          () => LocationPickerPage(
            initialCity: partnerCity, // 传递另一半的城市信息
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
              borderRadius: BorderRadius.circular(12), 
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon
                    Image(
                      image: AssetImage(
                        'assets/images/home_list_type_location.webp',
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
                          color: const Color(0x44000000),
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
        assetPath = 'assets/location/kissu3_shangchang_list.webp';
        break;
      case 2: // 家
        assetPath = 'assets/location/kissu3_jia_list.webp';
        break;
      case 3: // 娱乐
        assetPath = 'assets/location/kissu3_gongsi_list.webp';
        break;
      case 4: // 健身房
        assetPath = 'assets/location/kissu3_jianshen_list.webp';
        break;
      case 5: // 商场
        assetPath = 'assets/location/kissu3_zidingyi_list.webp';
        break;
      default:
        assetPath = 'assets/location/kissu3_zidingyi_list.webp'; // 默认使用家的图标
    }

    return Image.asset(
      assetPath,
      width: 15,
      height: 15,
      fit: BoxFit.contain,
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
  void _showDeleteDialog(BuildContext context, String reminderId) async {
    await DeleteLocationReminderDialogUtil.show(
      onConfirm: () async {
         
        
        // 执行原来的删除方法
        final success = await controller.removeReminder(reminderId);
        if (success) {
          OKToastUtil.show('删除成功');
        } else {
          OKToastUtil.showError('删除失败，请重试');
        }
      },
      onCancel: () {
        // 弹窗消失，不需要额外操作
      },
    );
  }
}
