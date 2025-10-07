import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/location/location_reminder/location_picker/location_picker_controller.dart';
import 'package:kissu_app/pages/location/location_reminder/location_reminder_controller.dart';
import 'package:kissu_app/utils/debug_util.dart';
import 'package:kissu_app/widgets/safe_amap_widget.dart';
import 'package:kissu_app/widgets/location_map_snapshot.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';

/// 地图选点页面
class LocationPickerPage extends StatelessWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialLocationName;

  LocationPickerPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialLocationName,
  });

  LocationPickerController get controller => Get.put(
        LocationPickerController(
          initialLatitude: initialLatitude,
          initialLongitude: initialLongitude,
          initialLocationName: initialLocationName,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 地图区域
          _buildMapView(),

          // 顶部工具栏
          _buildTopBar(context),

          // 底部信息面板
          _buildBottomPanel(context),
        ],
      ),
    );
  }

  /// 构建地图视图
  Widget _buildMapView() {
    return Obx(() {
      // 触发响应式更新
      final markerSet = controller.markers.toSet();
      final circleSet = controller.circles.toSet();
      DebugUtil.info('🗺️ 地图Widget重建 - 标记数量: ${markerSet.length}, 圆形数量: ${circleSet.length}');

      return Builder(
        builder: (context) {
          return SafeAMapWidget(
            initialCameraPosition: controller.initialCameraPosition,
            onMapCreated: controller.onMapCreated,
            onCameraMove: controller.onCameraMove,
            onTap: (position) => controller.onMapTap(position, context),
            onPoiTouched: (poi) => controller.onPoiTap(poi, context),
            markers: markerSet,
            circles: circleSet, // 添加圆形覆盖物
            myLocationStyleOptions: MyLocationStyleOptions(false), // 禁用定位蓝点
            compassEnabled: false,
            scaleEnabled: false,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
          );
        },
      );
    });
  }

  /// 构建顶部工具栏
  Widget _buildTopBar(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 返回按钮
            GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  /// 构建底部信息面板
  Widget _buildBottomPanel(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          gradient: LinearGradient(
            colors: [Color(0xFFFFE4F1), Color(0xFFFBFDFF), Color(0xFFFFF4DB)],
            stops: [0.0, 0.5, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 拖动指示器
            // Center(
            //   child: Container(
            //     margin: const EdgeInsets.only(top: 12, bottom: 16),
            //     width: 40,
            //     height: 4,
            //     decoration: BoxDecoration(
            //       color: const Color(0xFFE5E5E5),
            //       borderRadius: BorderRadius.circular(2),
            //     ),
            //   ),
            // ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    width: 40,
                    height: 20,
                    alignment: Alignment.center,
                    child: Text(
                      '取消',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final reminder = await controller.saveLocation();
                    if (reminder != null) {
                      Get.back(result: reminder);
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 20,
                    alignment: Alignment.center,
                    child: Text(
                      '保存',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFFF88AA),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 使用说明
                  const Text(
                    '1、轻点地图界面，即可选择你需要设置提醒的位置',
                    style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '2、点击建筑物可显示名称，地址信息显示在地图标记上',
                    style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                  ),
                  const SizedBox(height: 20),

                  // 图标选择
                  _buildIconSelector(),

                  const SizedBox(height: 20),

                  // 备注输入
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller.noteController,
                              maxLength: 10,
                              decoration: InputDecoration(
                                hintText: '请输入备注',
                                hintStyle: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF999999),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFffffff),
                                // 普通状态边框
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFFFCCC8),
                                    width: 2,
                                  ),
                                ),
                                // 聚焦状态边框
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFFFCCC8),
                                    width: 2,
                                  ),
                                ),
                                // 禁用状态边框（可选）
                                disabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFFFCCC8),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                counterText: '',
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 字符计数器
                          Obx(() => Text(
                            '${controller.noteText.value.length}/10',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF999999),
                            ),
                          )),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Obx(() {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 25),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              controller.selectedBottomAway.value = true;
                              // 更新圆圈颜色
                              if (controller.selectedLocation.value != null) {
                                controller.updateGeofenceRadius(controller.geofenceRadius.value);
                              }
                            },
                            child: Padding(padding: EdgeInsets.symmetric(vertical: 10,horizontal: 10),child:Row(
                              children: [
                                Image(
                                  image: AssetImage(
                                    controller.selectedBottomAway.value
                                        ? 'assets/kissu_login_privite_sel.webp'
                                        : 'assets/kissu_login_privite_unsel.webp',
                                  ),
                                  width: 14,
                                  height: 14,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '到达位置提醒',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ],
                            )),
                          ),
                          GestureDetector(
                            onTap: () {
                              controller.selectedBottomAway.value = false;
                              // 更新圆圈颜色
                              if (controller.selectedLocation.value != null) {
                                controller.updateGeofenceRadius(controller.geofenceRadius.value);
                              }
                            },
                            child: Row(
                              children: [
                                Image(
                                  image: AssetImage(
                                    controller.selectedBottomAway.value
                                        ? 'assets/kissu_login_privite_unsel.webp'
                                        : 'assets/kissu_login_privite_sel.webp',
                                  ),
                                  width: 14,
                                  height: 14,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '离开位置提醒',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  
                  // 地图类型切换
                  _buildMapTypeSelector(),
                ],
              ),
            ),
            const SizedBox(height: 35),
          ],
        ),
      ),
    );
  }

  /// 构建图标选择器
  Widget _buildIconSelector() {
    return Obx(() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: controller.availableIcons.map((iconData) {
          final isSelected = controller.selectedIcon.value == iconData.id;
          return GestureDetector(
            onTap: () => controller.selectIcon(iconData.id),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                        isSelected ? iconData.selectedAsset : iconData.asset,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }
  
  /// 构建地图类型切换器
  Widget _buildMapTypeSelector() {
    return Obx(() {
      // 获取当前选中的位置，如果没有则使用默认位置
      final location = controller.selectedLocation.value;
      final latitude = location?.latitude ?? 39.90923;  // 默认天安门
      final longitude = location?.longitude ?? 116.397428;
      final radius = controller.geofenceRadius.value;
      final reminderType = controller.selectedBottomAway.value 
          ? ReminderType.arrive 
          : ReminderType.leave;
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '地图类型',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // 经典地图
              Expanded(
                child: GestureDetector(
                  onTap: () => controller.switchMapType(1),
                  child: _MapTypeOption(
                    latitude: latitude,
                    longitude: longitude,
                    radius: radius,
                    reminderType: reminderType,
                    iconId: controller.selectedIcon.value,
                    label: '经典地图',
                    isSelected: controller.mapType.value == 1,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // 卫星地图
              Expanded(
                child: GestureDetector(
                  onTap: () => controller.switchMapType(2),
                  child: _MapTypeOption(
                    latitude: latitude,
                    longitude: longitude,
                    radius: radius,
                    reminderType: reminderType,
                    iconId: controller.selectedIcon.value,
                    label: '卫星地图',
                    isSelected: controller.mapType.value == 2,
                    isSatellite: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}

/// 地图类型选项组件
class _MapTypeOption extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double radius;
  final ReminderType reminderType;
  final int iconId;
  final String label;
  final bool isSelected;
  final bool isSatellite;

  const _MapTypeOption({
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.reminderType,
    required this.iconId,
    required this.label,
    required this.isSelected,
    this.isSatellite = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 地图预览图（使用地图快照）
        Container(
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFFD1E4)
                  : const Color(0xFFE0E0E0),
              width: isSelected ? 3 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LocationMapSnapshot(
              latitude: latitude,
              longitude: longitude,
              radius: radius.round(),
              iconId: iconId,
              reminderType: reminderType,
              isSatellite: isSatellite,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 地图类型标签
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected 
                ? const Color(0xFFFF88AA)
                : const Color(0xFF999999),
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
