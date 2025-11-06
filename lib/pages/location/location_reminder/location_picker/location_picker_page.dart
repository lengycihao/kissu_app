import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/location/location_reminder/location_picker/location_picker_controller.dart';
import 'package:kissu_app/pages/location/location_reminder/location_reminder_controller.dart';
import 'package:kissu_app/utils/debug_util.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/widgets/safe_amap_widget.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:kissu_app/models/poi_model.dart';
import 'package:kissu_app/models/city_model.dart';
import 'package:kissu_app/pages/location/poi_search/poi_search_page.dart';
import 'package:kissu_app/pages/location/poi_search/poi_search_controller.dart';
import 'package:kissu_app/pages/location/city_list/city_list_page.dart';
import 'package:kissu_app/services/tracking_service.dart';

/// 地图选点页面
class LocationPickerPage extends StatelessWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialLocationName;
  final LocationReminder? editingReminder; // 编辑模式：传入已有的提醒对象

  LocationPickerPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialLocationName,
    this.editingReminder,
  });

  LocationPickerController get controller => Get.put(
        LocationPickerController(
          initialLatitude: initialLatitude,
          initialLongitude: initialLongitude,
          initialLocationName: initialLocationName,
          editingReminder: editingReminder,
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

          // 地图logo - 悬浮在地图上，位置在底部面板左上角
          _buildMapLogo(context),
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

  /// 构建顶部工具栏（自定义导航栏）
  Widget _buildTopBar(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 19).copyWith(top: MediaQuery.of(context).padding.top+19),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Row(
          children: [
            // 返回按钮
            GestureDetector(
              onTap: () => Get.back(),
              child:   Padding(
                padding: EdgeInsets.all(8),
                child: Image.asset(
                  'assets/location/kissu3_back.webp',
                  width: 20,
                  height: 20,
                ),
              ),
            ),

 
            // 搜索框
            Expanded(
              child: GestureDetector(
                onTap: () => _goToPoiSearch(context),
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFffffff),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Color(0xFFFFBBB5),width: 1),
                  ),
                  child: Row(
                    children: [
                      
                      const SizedBox(width: 16),
                      Text(
                        '请输入',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

 
            // 城市定位按钮
            Obx(() {
              final currentCity = controller.currentCity.value;
              final hasCity = currentCity.isNotEmpty;
              
              return GestureDetector(
                onTap: () => _goToCityList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image(
                        image: AssetImage('assets/location/kissu3_location_pink.webp'),
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasCity ? currentCity.replaceAll('市', '') : '选择城市',
                        style: TextStyle(
                          fontSize: 13,
                          color: hasCity ? Colors.black : const Color(0xFFFF408D), // 无城市时用粉色提示
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      );
  }

  /// 跳转到POI搜索页面
  void _goToPoiSearch(BuildContext context) async {
    final result = await Get.to(
      () => const PoiSearchPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<PoiSearchController>(
          () => PoiSearchController(
            initialCity: controller.currentCityModel.value,
          ),
        );
      }),
      transition: Transition.rightToLeft,
    );
    
    if (result != null) {
      // 新的返回数据结构：Map包含 poi, city, cityChanged
      if (result is Map) {
        final poi = result['poi'] as PoiModel?;
        final city = result['city'] as CityModel?;
        final cityChanged = result['cityChanged'] as bool? ?? false;
        
        // 如果选择了POI，更新位置并添加围栏
        if (poi != null) {
          controller.updateLocationFromPoi(poi, context: context);
        }
        
        // 如果城市发生变化，同步城市信息
        if (cityChanged && city != null) {
          controller.updateCurrentCity(city);
        }
      }
      // 兼容旧的返回方式（直接返回PoiModel）
      else if (result is PoiModel) {
        controller.updateLocationFromPoi(result, context: context);
      }
    }
  }

  /// 跳转到城市列表页面
  void _goToCityList() async {
    final result = await Get.to(
      () => const CityListPage(),
      transition: Transition.rightToLeft,
    );
    if (result != null && result is CityModel) {
      // 更新当前城市
      controller.updateCurrentCity(result);
    }
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
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 使用说明
                  const Text(
                    '目前有效提醒范围100m',
                    style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                  ),
                  const SizedBox(height: 20),

                  // 图标选择
                  _buildIconSelector(),

                  const SizedBox(height: 20),

                  // 备注输入
                  TextField(
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
                      // 字符计数器放在输入框内右侧
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Obx(() => Text(
                          '${controller.noteText.value.length}/10',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF999999),
                          ),
                        )),
                      ),
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 0,
                        minHeight: 0,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF333333),
                    ),
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
                                  '到达地点提醒',
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
                                  '离开地点提醒',
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
                  // const SizedBox(height: 20),
                  
                  // // 地图类型切换
                  // _buildMapTypeSelector(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              // 判断是否可以保存：必须选择了位置且输入了备注
              final canSave = controller.selectedLocation.value != null && 
                              controller.noteText.value.trim().isNotEmpty;
              
              return GestureDetector(
                onTap: () async {
                  if (!canSave) {
                    // 检查具体缺少什么并给出相应提示
                    if (controller.selectedLocation.value == null) {
                      OKToastUtil.show('请在地图上添加要提醒的位置');
                      return;
                    }
                    if (controller.noteText.value.trim().isEmpty) {
                      OKToastUtil.show('请添加备注');
                      return;
                    }
                  }
                  
                  // 上报保存操作埋点
                  try {
                    await TrackingService.trackLocationKnockAddressSave();
                    DebugUtil.info('✅ 添加地点页面-保存操作埋点上报成功');
                  } catch (e) {
                    DebugUtil.error('❌ 添加地点页面-保存操作埋点上报失败: $e');
                  }
                  
                  final reminder = await controller.saveLocation();
                  if (reminder != null) {
                    Get.back(result: reminder);
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 42,
                  decoration: BoxDecoration(
                    color: canSave ? Color(0xFFFF408D) : Color(0xFFFF9DC4),
                    borderRadius: BorderRadius.circular(21),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '保存',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
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
                  width: 52,
                  height: 52,
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

  /// 构建地图logo - 悬浮在底部面板左上角
  Widget _buildMapLogo(BuildContext context) {
    return Positioned(
      bottom: 370, // 根据底部面板的高度计算，让logo在面板上方
      left: 14,
      child: Image.asset(
        'assets/map_logo.webp',
        width: 68,
        height: 22,
      ),
    );
  }
}

 