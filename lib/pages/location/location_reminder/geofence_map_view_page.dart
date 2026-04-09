import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:kissu_app/pages/location/location_reminder/location_reminder_controller.dart';
import 'package:kissu_app/services/simple_location_service.dart';
import 'package:kissu_app/widgets/safe_amap_widget.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';

/// 围栏地图视图页面
/// 显示所有位置提醒的围栏范围
class GeofenceMapViewPage extends StatefulWidget {
  final LocationReminder? focusReminder; // 聚焦的围栏
  
  const GeofenceMapViewPage({
    super.key,
    this.focusReminder,
  });

  @override
  State<GeofenceMapViewPage> createState() => _GeofenceMapViewPageState();
}

class _GeofenceMapViewPageState extends State<GeofenceMapViewPage>
    with WidgetsBindingObserver {
  AMapController? _mapController;
  final _markers = <Marker>{}.obs;
  final _circles = <Circle>{}.obs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeMap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused) {
      // 应用进入后台，暂停地图更新（释放资源）
      // logDebug('🗺️ GeofenceMapViewPage: 应用进入后台，暂停地图更新', tag: 'GeofenceMapView');
    } else if (state == AppLifecycleState.resumed) {
      // 应用恢复前台，恢复地图更新
      // logDebug('🗺️ GeofenceMapViewPage: 应用恢复前台，恢复地图更新', tag: 'GeofenceMapView');
    }
  }

  /// 初始化地图数据
  void _initializeMap() async {
    final controller = Get.find<LocationReminderController>();
    final reminders = controller.reminders;

    // 加载所有围栏
    for (final reminder in reminders) {
      await _addGeofenceToMap(reminder);
    }

    // 如果有聚焦的围栏，移动相机到该位置
    if (widget.focusReminder != null) {
      _focusOnReminder(widget.focusReminder!);
    }
  }

  /// 添加围栏到地图
  Future<void> _addGeofenceToMap(LocationReminder reminder) async {
    // 添加标记
    final icon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/3.0/kissu3_map_marker_icon.webp',
    );

    final marker = Marker(
      position: LatLng(reminder.latitude, reminder.longitude),
      icon: icon,
      infoWindow: InfoWindow(
        title: reminder.name,
        snippet: '${reminder.type == ReminderType.arrive ? "到达" : "离开"}提醒 · ${reminder.radius.toInt()}米',
      ),
    );

    // 添加圆形围栏
    final circle = Circle(
      center: LatLng(reminder.latitude, reminder.longitude),
      radius: reminder.radius,
      strokeWidth: 2,
      strokeColor: reminder.isActive
          ? const Color(0xFFFF88AA) // 激活状态：粉色边框
          : const Color(0xFFCCCCCC), // 暂停状态：灰色边框
      fillColor: reminder.isActive
          ? const Color(0x66FFD5E1) // 激活状态：粉色填充 #FFD5E1 带透明度
          : const Color(0x33CCCCCC), // 暂停状态：灰色填充
      visible: true,
    );

    _markers.add(marker);
    _circles.add(circle);
  }

  /// 聚焦到指定围栏
  void _focusOnReminder(LocationReminder reminder) {
    if (_mapController != null) {
      _mapController!.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(reminder.latitude, reminder.longitude),
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(44 + MediaQuery.of(context).padding.top),
        child: Container(
          height: 44 + MediaQuery.of(context).padding.top,
          color: Colors.white,
          child: Stack(
            children: [
              // 返回按钮
              Positioned(
                left: 5,
                top: MediaQuery.of(context).padding.top,
                bottom: 0,
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: Image.asset(
                      "assets/images/kissu_mine_back.webp",
                      width: 22,
                      height: 22,
                    ),
                  ),
                ),
              ),
              // 标题 - 绝对居中
              Positioned(
                left: 0,
                right: 0,
                top: MediaQuery.of(context).padding.top,
                bottom: 0,
                child: Center(
                  child: Text(
                    '围栏地图',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
              ),
              // 右侧定位按钮
              Positioned(
                right: 5,
                top: MediaQuery.of(context).padding.top,
                bottom: 0,
                child: GestureDetector(
                  onTap: _moveToCurrentLocation,
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.my_location,
                      size: 24,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Obx(() {
        return SafeAMapWidget(
          initialCameraPosition: _getInitialCameraPosition(),
          onMapCreated: (controller) {
            _mapController = controller;
          },
          markers: _markers.toSet(),
          circles: _circles.toSet(),
          myLocationStyleOptions: MyLocationStyleOptions(
            true,
            circleStrokeColor: const Color(0xFFFF88AA),
            circleFillColor: const Color(0x33FF88AA),
          ),
        );
      }),
      floatingActionButton: _buildLegend(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  /// 获取初始相机位置
  CameraPosition _getInitialCameraPosition() {
    // 如果有聚焦的围栏，使用围栏位置
    if (widget.focusReminder != null) {
      return CameraPosition(
        target: LatLng(
          widget.focusReminder!.latitude,
          widget.focusReminder!.longitude,
        ),
        zoom: 15.0,
      );
    }

    // 否则使用当前位置
    final locationService = Get.find<SimpleLocationService>();
    final currentLoc = locationService.currentLocation.value;
    if (currentLoc != null) {
      final lat = double.tryParse(currentLoc.latitude);
      final lng = double.tryParse(currentLoc.longitude);
      if (lat != null && lng != null) {
        return CameraPosition(
          target: LatLng(lat, lng),
          zoom: 13.0,
        );
      }
    }

    // 默认位置（天安门）
    return const CameraPosition(
      target: LatLng(39.9042, 116.4074), // 天安门坐标
      zoom: 13.0,
    );
  }

  /// 移动到当前位置
  void _moveToCurrentLocation() {
    final locationService = Get.find<SimpleLocationService>();
    final currentLoc = locationService.currentLocation.value;
    
    if (currentLoc != null && _mapController != null) {
      final lat = double.tryParse(currentLoc.latitude);
      final lng = double.tryParse(currentLoc.longitude);
      
      if (lat != null && lng != null) {
        _mapController!.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(lat, lng),
              zoom: 15.0,
            ),
          ),
        );
      }
    }
  }

  /// 构建图例
  Widget _buildLegend() {
    final controller = Get.find<LocationReminderController>();
    final activeCount = controller.reminders.where((r) => r.isActive).length;
    final totalCount = controller.reminders.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0x334D9FFF),
                  border: Border.all(color: const Color(0xFF4D9FFF), width: 2),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '激活中',
                style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0x33CCCCCC),
                  border: Border.all(color: const Color(0xFFCCCCCC), width: 2),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '已暂停',
                style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '共 $totalCount 个围栏，$activeCount 个激活',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF999999),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

