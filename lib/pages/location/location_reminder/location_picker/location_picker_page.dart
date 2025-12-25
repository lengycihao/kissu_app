import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      resizeToAvoidBottomInset: false,
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
      DebugUtil.info(
        '🗺️ 地图Widget重建 - 标记数量: ${markerSet.length}, 圆形数量: ${circleSet.length}',
      );

      // 将地图限制在距屏幕底部 300px 处，保留上方工具栏和下方面板空间
      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        bottom: 250, // 地图底部距离底部 300px
        child: Builder(builder: (context) {
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
        }),
      );
    });
  }

  /// 构建顶部工具栏（使用图片背景，标题为“添加地点”）
  Widget _buildTopBar(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(left: 6, right: 6, top: topPadding, bottom: 12),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/setting/kissu_navbar_bg.webp'),
          fit: BoxFit.cover,
        ),
      ),
      child: SizedBox(
        height: 44,
        child: Stack(
          children: [
            Positioned(
              left: 6,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      'assets/location/kissu3_back.webp',
                      width: 20,
                      color: Color(0xff333333),
                      height: 20,
                    ),
                  ),
                ),
              ),
            ),
            const Center(
              child: Text(
                '添加地点',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            // 城市定位按钮（恢复到右侧）
            Positioned(
              right: 6,
              top: 0,
              bottom: 0,
              child: Obx(() {
                final currentCity = controller.currentCity.value;
                final hasCity = currentCity.isNotEmpty;
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: GestureDetector(
                    onTap: () => _goToCityList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image(
                            image: AssetImage(
                              'assets/location/kissu3_location_pink.webp',
                            ),
                            width: 16,
                            color: Color(0xff777777),
                            height: 16,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              hasCity ? currentCity.replaceAll('市', '') : '选择城市',
                              style: TextStyle(
                                fontSize: 13,
                                color: hasCity
                                    ? Colors.black
                                    : const Color(0xFFFF408D),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
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

  /// 跳转到城市列表页面（恢复，供右侧按钮使用）
  void _goToCityList() async {
    final result = await Get.to(
      () => const CityListPage(),
      transition: Transition.rightToLeft,
    );
    if (result != null && result is CityModel) {
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
            // 搜索框（从顶部移动到下半屏，并放在“目前有效提醒范围100m”之上）
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: GestureDetector(
                onTap: () => _goToPoiSearch(context),
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(0xFFE8E8E8), width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 11).copyWith(right: 8),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/kissu_search_icon.webp',
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          controller.initialLocationName ?? '请输入要添加的地点',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 右侧搜索按钮
                      GestureDetector(
                        onTap: () => _goToPoiSearch(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFA9E0),
                            borderRadius: BorderRadius.circular(20),
                           ),
                          child: const Text(
                            '搜索',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFFffffff),
                             ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Container(
              padding: EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 图标选择
                  _buildIconSelector(context),

                  // const SizedBox(height: 10),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '操作须知',
                  style: TextStyle(
                    fontSize: 14,
                    height:2,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '1、请在输入框填写需提醒的地点名称',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF777777),
                    height:1.7,
                  ),
                ),
                Text(
                  '2、目前有效提醒范围100m',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF777777),
                    height: 1.7,
                  ),
                ),
                Text(
                  '3、当对方进出该范围，你会收到通知',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF777777),
                    height: 1.7,
                  ),
                ),
                const SizedBox(height:30),
              ],
            ),
            Obx(() {
              // 判断是否可以保存：必须选择了位置且输入了备注
              final canSave =
                  controller.selectedLocation.value != null &&
                  controller.noteText.value.trim().isNotEmpty;

              return GestureDetector(
                onTap: () async {
                  if (!canSave) {
                    // 检查具体缺少什么并给出相应提示
                    if (controller.selectedLocation.value == null) {
                      OKToastUtil.show('请在地图上添加要提醒的位置');
                      return;
                    }
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
                    color: Color(0xFFFFA9E0),
                    borderRadius: BorderRadius.circular(21),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '保存',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
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
  Widget _buildIconSelector(BuildContext context) {
    return Obx(() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: controller.availableIcons.map((iconData) {
          final isSelected = controller.selectedIcon.value == iconData.id;
          return GestureDetector(
            onTap: () {
              // 当选择"自定义地点"时，弹出自定义输入弹窗；否则直接选择图标
              if (iconData.id == 5) { // 使用id判断而不是label，避免文字变化影响
                _showCustomLocationDialog(context);
              } else {
                controller.selectIcon(iconData.id);
              }
            },
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
                SizedBox(height: 4),
                // 当选择自定义地点且有自定义文字时，显示自定义文字；否则显示原始标签
                Text(
                  (iconData.id == 5 && controller.customLocationText.value.isNotEmpty)
                      ? controller.customLocationText.value
                      : iconData.label,
                  style: TextStyle(fontSize: 12, color: Color(0xFF333333)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }

  /// 显示“自定义地点”输入弹窗
  Future<void> _showCustomLocationDialog(BuildContext context) async {
    final TextEditingController _customController = TextEditingController();

    await Get.dialog(
      Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 270,
            height: 205,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage('assets/dialog/kissu_toast_bg.webp'),
                fit: BoxFit.fill,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '自定义地点',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Color(0xffF3F3F3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _customController,
                    textAlign: TextAlign.center,
                    maxLength: 10, // 限制输入文字数量为10
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(10), // 限制输入长度
                    ],
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '请输入地点名称～',
                      contentPadding: EdgeInsets.only(bottom: 5),
                      hintStyle: TextStyle(color: Color(0xFF777777),fontSize: 12),
                      counterText: '', // 隐藏字符计数器
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    final text = _customController.text.trim();
                    if (text.isEmpty) {
                      // 使用已有的OKToast工具给出提示（文件已导入OKToastUtil）
                      // 如果没有导入，可以替换为 Get.snackbar
                      try {
                        OKToastUtil.show('请输入地点名称');
                      } catch (_) {
                        Get.snackbar('提示', '请输入地点名称', snackPosition: SnackPosition.BOTTOM);
                      }
                      return;
                    }

                    // 将自定义名称写入备注输入框，并选中自定义图标
                    controller.noteController.text = text;
                    controller.noteText.value = text;
                    controller.customLocationText.value = text; // 设置自定义地点显示文字
                    controller.selectIcon(5);
                    Get.back();
                  },
                  child: Container(
                    width: 106,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA9E0),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '确定',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                       ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  /// 构建地图logo - 悬浮在底部面板左上角
  Widget _buildMapLogo(BuildContext context) {
    return Positioned(
      bottom: 370, // 根据底部面板的高度计算，让logo在面板上方
      left: 14,
      child: Image.asset('assets/images/map_logo.webp', width: 68, height: 22),
    );
  }
}
