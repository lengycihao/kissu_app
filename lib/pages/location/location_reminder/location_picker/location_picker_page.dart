import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/location/location_reminder/location_picker/location_picker_controller.dart';
import 'package:kissu_app/utils/debug_util.dart';
import 'package:kissu_app/widgets/safe_amap_widget.dart';

/// 地图选点页面
class LocationPickerPage extends StatelessWidget {
  LocationPickerPage({super.key});

  final controller = Get.put(LocationPickerController());

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
      DebugUtil.info('🗺️ 地图Widget重建 - 标记数量: ${markerSet.length}');

      return SafeAMapWidget(
        initialCameraPosition: controller.initialCameraPosition,
        onMapCreated: controller.onMapCreated,
        onTap: controller.onMapTap,
        onLongPress: controller.onMapTap, // 同时支持长按选点
        markers: markerSet,
        compassEnabled: false,
        scaleEnabled: false,
        zoomGesturesEnabled: true,
        scrollGesturesEnabled: true,
        rotateGesturesEnabled: true,
        tiltGesturesEnabled: true,
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
            // 完成按钮
            GestureDetector(
              onTap: () async {
                final reminder = await controller.saveLocation();
                if (reminder != null) {
                  Get.back(result: reminder);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF88AA),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF88AA).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  '完成',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
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
                Container(
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
                Container(
                  width: 40,
                  height: 20,
                  alignment: Alignment.center,
                  child: Text(
                    '保存',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
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
                  // 地址信息
                  const Text(
                    '1、轻拖地图界面，即可自由选择你需要设置提醒的位置',
                    style: TextStyle(fontSize: 12, color: Color(0xFF333333)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '2、按住「范围」按钮，左右滑块，可设置有效范围',
                    style: TextStyle(fontSize: 12, color: Color(0xFF333333)),
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
                            onTap: () =>
                                controller.selectedBottomAway.value = true,
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
                            onTap: () =>
                                controller.selectedBottomAway.value = false,
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
                  // SizedBox(height: 10),
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
          final isSelected = controller.selectedIcon.value == iconData.type;
          return GestureDetector(
            onTap: () => controller.selectIcon(iconData.type),
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
}
