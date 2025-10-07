import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:kissu_app/pages/location/location_reminder/location_reminder_controller.dart';
import 'package:kissu_app/widgets/safe_amap_widget.dart';

/// 围栏详情页面（只读模式）
/// 显示单个位置提醒的详细信息和地图
class GeofenceDetailPage extends StatefulWidget {
  final LocationReminder reminder;

  const GeofenceDetailPage({super.key, required this.reminder});

  @override
  State<GeofenceDetailPage> createState() => _GeofenceDetailPageState();
}

class _GeofenceDetailPageState extends State<GeofenceDetailPage> {
  final _markers = <Marker>{}.obs;
  final _circles = <Circle>{}.obs;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  /// 初始化地图数据
  void _initializeMap() async {
    await _addGeofenceToMap(widget.reminder);
  }

  /// 添加围栏到地图
  Future<void> _addGeofenceToMap(LocationReminder reminder) async {
    // 添加标记（使用自定义图标）
    final icon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      _getIconPath(reminder.icon),
    );

    final marker = Marker(
      position: LatLng(reminder.latitude, reminder.longitude),
      icon: icon,
    );

    // 根据提醒类型选择颜色：到达=蓝色，离开=粉色
    final strokeColor = reminder.type == ReminderType.arrive
        ? const Color(0x994D9FFF) // 60%透明度蓝色边框
        : const Color(0xFFFF88AA); // 粉色边框
    final fillColor = reminder.type == ReminderType.arrive
        ? const Color(0x334D9FFF) // 20%透明度蓝色填充
        : const Color(0x66FFD5E1); // 粉色填充
    
    // 添加圆形围栏
    final circle = Circle(
      center: LatLng(reminder.latitude, reminder.longitude),
      radius: reminder.radius,
      strokeWidth: 2,
      strokeColor: strokeColor,
      fillColor: fillColor,
      visible: true,
    );

    _markers.add(marker);
    _circles.add(circle);
  }

  /// 获取图标路径
  String _getIconPath(int iconId) {
    switch (iconId) {
      case 1: // 公司
        return 'assets/location/kissu3_gongsi_sel.webp';
      case 2: // 家
        return 'assets/location/kissu3_jia_sel.webp';
      case 3: // 娱乐
        return 'assets/location/kissu3_yule_sel.webp';
      case 4: // 健身房
        return 'assets/location/kissu3_jianshen_sel.webp';
      case 5: // 商场
        return 'assets/location/kissu3_shangchang_sel.webp';
      default:
        return 'assets/3.0/kissu3_map_marker_icon.webp';
    }
  }

  /// 获取位置名称
  String _getLocationName(int iconId) {
    switch (iconId) {
      case 1:
        return 'TA的公司';
      case 2:
        return 'TA的家';
      case 3:
        return 'TA的娱乐';
      case 4:
        return 'TA的健身房';
      case 5:
        return 'TA的商场';
      default:
        return '未知地点';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 地图
          Obx(() {
            return SafeAMapWidget(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  widget.reminder.latitude - 0.001, // 向上偏移视角
                  widget.reminder.longitude,
                ),
                zoom: _calculateZoomByRadius(widget.reminder.radius),
              ),
              onMapCreated: (controller) {
                // 地图创建完成，无需交互
              },
              markers: _markers.toSet(),
              circles: _circles.toSet(),
              myLocationStyleOptions: MyLocationStyleOptions(
                false, // 不显示当前位置
              ),
            );
          }),

          // 顶部导航栏
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              decoration: BoxDecoration(
                color: Colors.transparent,
                
              ),
              child: Container(
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
                    
                  ],
                ),
              ),
            ),
          ),

          // 底部信息卡片
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 拖动条
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 16),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // 内容
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 标题行
                        Row(
                          children: [
                            // 图标
                            Image.asset(
                              _getIconPath(widget.reminder.icon),
                              width: 32,
                              height: 32,
                            ),
                            const SizedBox(width: 12),
                            // 名称和类型
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getLocationName(widget.reminder.icon),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              widget.reminder.type ==
                                                  ReminderType.arrive
                                              ? const Color(0xFFE3F2FD)
                                              : const Color(0xFFFFF3E0),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          widget.reminder.type ==
                                                  ReminderType.arrive
                                              ? '到达提醒'
                                              : '离开提醒',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color:
                                                widget.reminder.type ==
                                                    ReminderType.arrive
                                                ? const Color(0xFF1976D2)
                                                : const Color(0xFFF57C00),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        widget.reminder.isActive
                                            ? Icons.check_circle
                                            : Icons.pause_circle,
                                        size: 16,
                                        color: widget.reminder.isActive
                                            ? const Color(0xFF4CAF50)
                                            : const Color(0xFF999999),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.reminder.isActive
                                            ? '已激活'
                                            : '已暂停',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: widget.reminder.isActive
                                              ? const Color(0xFF4CAF50)
                                              : const Color(0xFF999999),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // 地址信息
                        _buildInfoRow(
                          Icons.location_on_outlined,
                          '地址',
                          widget.reminder.address,
                        ),

                        const SizedBox(height: 16),

                        // 围栏半径
                        _buildInfoRow(
                          Icons.radio_button_unchecked,
                          '围栏半径',
                          '${widget.reminder.radius.toInt()} 米',
                        ),

                        const SizedBox(height: 16),

                        // 坐标信息
                        _buildInfoRow(
                          Icons.pin_drop_outlined,
                          '坐标',
                          '${widget.reminder.latitude.toStringAsFixed(6)}, ${widget.reminder.longitude.toStringAsFixed(6)}',
                        ),

                        // 备注（如果有）
                        if (widget.reminder.note.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.note_outlined,
                            '备注',
                            widget.reminder.note,
                          ),
                        ],

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF4D9FFF)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF333333),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 根据半径计算缩放级别
  double _calculateZoomByRadius(double radius) {
    if (radius <= 50) return 18.0;
    if (radius <= 100) return 18.0;
    if (radius <= 200) return 16.5;
    if (radius <= 500) return 15.5;
    if (radius <= 1000) return 14.5;
    return 13.0;
  }
}
