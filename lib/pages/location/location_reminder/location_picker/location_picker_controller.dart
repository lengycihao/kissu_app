import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:kissu_app/pages/location/location_reminder/location_reminder_controller.dart';
import 'package:kissu_app/services/amap_geocode_service.dart';
import 'package:kissu_app/services/simple_location_service.dart';
import 'package:kissu_app/utils/debug_util.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/pages/location/location_reminder/location_picker/custom_location_info_window.dart';

/// 地图选点Controller
class LocationPickerController extends GetxController {
  // 地图控制器
  AMapController? mapController;
  
  // 逆地理编码服务
  final _geocodeService = AMapGeocodeService();
  
  // 初始位置参数
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialLocationName;
  
  // 当前选中的位置
  final Rx<LatLng?> selectedLocation = Rx<LatLng?>(null);
  
  // 当前位置的地址信息
  final selectedAddress = '请在地图上选择位置'.obs;
  
  // 地址加载状态
  final isLoadingAddress = false.obs;
  
  // 选中的图标类型 (1-5: 公司/家/娱乐/健身房/商场)
  final selectedIcon = 2.obs; // 默认为"家"

  // 选中的提醒类型（到达/离开）
  final selectedBottomAway = true.obs;
  
  // 地图类型 (1: 经典地图, 2: 卫星地图)
  final mapType = 1.obs;
  
  // 备注文本
  final noteText = ''.obs;
  
  // 围栏半径（米）- 默认100米
  final geofenceRadius = 100.0.obs;
  
  // 地图标记
  final markers = <Marker>{}.obs;
  
  // 地图圆形覆盖物（电子围栏）
  final circles = <Circle>{}.obs;
  
  // 可选的图标列表
  final List<LocationIconData> availableIcons = [
    LocationIconData(id: 1, type: 'company', label: '公司', asset: 'assets/location/kissu3_gongsi.webp',selectedAsset: 'assets/location/kissu3_gongsi_sel.webp'),
    LocationIconData(id: 2, type: 'home', label: '家', asset: 'assets/location/kissu3_jia.webp',selectedAsset: 'assets/location/kissu3_jia_sel.webp'),
    LocationIconData(id: 3, type: 'restaurant', label: '娱乐', asset: 'assets/location/kissu3_yule.webp',selectedAsset: 'assets/location/kissu3_yule_sel.webp'),
    LocationIconData(id: 4, type: 'gym', label: '健身房', asset: 'assets/location/kissu3_jianshen.webp',selectedAsset: 'assets/location/kissu3_jianshen_sel.webp'),
    LocationIconData(id: 5, type: 'shop', label: '商场', asset: 'assets/location/kissu3_shangchang.webp',selectedAsset: 'assets/location/kissu3_shangchang_sel.webp'),
  ];
  
  // 文本输入控制器
  final TextEditingController noteController = TextEditingController();
  
  LocationPickerController({
    this.initialLatitude,
    this.initialLongitude,
    this.initialLocationName,
  });
  
  @override
  void onInit() {
    super.onInit();
    
    // 监听备注文本变化
    noteController.addListener(() {
      noteText.value = noteController.text;
    });
    
    // 如果有初始位置，设置初始标记
    _initializeLocation();
  }
  
  /// 初始化位置
  void _initializeLocation() {
    if (initialLatitude != null && initialLongitude != null) {
      final position = LatLng(initialLatitude!, initialLongitude!);
      selectedLocation.value = position;
      
      // 如果有初始位置名称，使用它；否则获取地址
      if (initialLocationName != null && initialLocationName!.isNotEmpty) {
        selectedAddress.value = initialLocationName!;
        _updateMarker(position, initialLocationName!);
        _updateGeofenceCircle(position); // 添加围栏圆形
      } else {
        _updateMarker(position, '正在获取地址...');
        _updateGeofenceCircle(position); // 添加围栏圆形
        _getAddressFromLocation(position);
      }
      
      DebugUtil.info('🗺️ 初始位置已设置: $position');
    } else {
      // 🆕 没有初始位置时，不设置任何标记
      DebugUtil.info('🗺️ 无初始位置，等待用户选择');
    }
  }
  
  @override
  void onClose() {
    // 清理自定义InfoWindow
    CustomLocationInfoWindowManager.dispose();
    noteController.dispose();
    super.onClose();
  }
  
  /// 地图创建完成回调
  void onMapCreated(AMapController controller) {
    mapController = controller;
    DebugUtil.info('🗺️ 地图选点页面地图创建完成');
  }
  
  /// 地图相机位置改变回调
  void onCameraMove(CameraPosition position) {
    CustomLocationInfoWindowManager.updateCameraPosition(position);
  }
  
  /// 切换地图类型
  void switchMapType(int type) {
    mapType.value = type;
    DebugUtil.info('🗺️ 切换地图类型: ${type == 2 ? "卫星地图" : "经典地图"}');
    // 注意：高德地图在地图选择器中会自动根据 mapType 切换
  }
  
  /// 初始相机位置
  CameraPosition get initialCameraPosition {
    // 优先级：1. 传入的初始位置 > 2. 当前位置 > 3. 默认杭州
    if (initialLatitude != null && initialLongitude != null) {
      return CameraPosition(
        target: LatLng(initialLatitude!, initialLongitude!),
        zoom: 17.5, // 提高缩放级别，让100米围栏显示得更清晰
      );
    }
    
    // 尝试获取当前位置
    try {
      final locationService = Get.find<SimpleLocationService>();
      final currentLoc = locationService.currentLocation.value;
      if (currentLoc != null) {
        final lat = double.tryParse(currentLoc.latitude);
        final lng = double.tryParse(currentLoc.longitude);
        if (lat != null && lng != null) {
          DebugUtil.info('🗺️ 使用当前位置作为初始相机位置: ($lat, $lng)');
          return CameraPosition(
            target: LatLng(lat, lng),
            zoom: 17.5,
          );
        }
      }
    } catch (e) {
      DebugUtil.error('获取当前位置失败: $e');
    }
    
    // 默认杭州
    return const CameraPosition(
      target: LatLng(30.2741, 120.2206),
      zoom: 17.5,
    );
  }
  
  /// 地图点击事件
  void onMapTap(LatLng position, BuildContext context) {
    DebugUtil.info('🗺️ 地图点击: $position');
    selectedLocation.value = position;
    
    // 先更新地图标记（暂不显示地址）
    _updateMarker(position, '正在获取地址...', context: context);
    
    // 更新围栏圆形
    _updateGeofenceCircle(position);
    
    // 🔧 不移动相机，保持当前视角
    // _moveCameraToPosition(position);
    
    // 获取地址信息并更新marker（不带POI名称）
    _getAddressFromLocation(position, context: context, poiName: null);
  }
  
  /// POI点击事件
  void onPoiTap(AMapPoi poi, BuildContext context) {
    DebugUtil.info('🗺️ POI点击: {name=${poi.name}, id=${poi.id}, latLng=${poi.latLng}}');
    
    // 从POI获取位置信息
    if (poi.latLng != null) {
      final position = poi.latLng!;
      
      selectedLocation.value = position;
      
      // 先更新地图标记
      _updateMarker(position, '正在获取地址...', context: context);
      
      // 更新围栏圆形
      _updateGeofenceCircle(position);
      
      // 🔧 不移动相机，保持当前视角
      // _moveCameraToPosition(position);
      
      // 获取地址信息并拼接POI名称
      _getAddressFromLocation(position, context: context, poiName: poi.name);
    } else {
      DebugUtil.warning('⚠️ POI没有位置信息');
    }
  }
  
  /// 更新地图标记
  /// [position] 标记位置
  /// [address] 地址信息，显示在自定义InfoWindow中
  /// [context] BuildContext，用于显示自定义InfoWindow
  Future<void> _updateMarker(LatLng position, String address, {BuildContext? context}) async {
    try {
      // 加载自定义图标
      final icon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/3.0/kissu3_map_marker_icon.webp',
      );
      
      final marker = Marker(
        position: position,
        icon: icon,
        infoWindowEnable: true,
        infoWindow: InfoWindow(
          title: address.split('\n').first, // 位置名称
          snippet: address.contains('\n') ? address.split('\n').skip(1).join('\n') : '', // 详细地址
        ),
        customInfoWindowBuilder: (context) {
          // 返回自定义 InfoWindow Widget
          return Container(
            width: 220,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address.split('\n').first,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                if (address.contains('\n')) ...[
                  SizedBox(height: 4),
                  Text(
                    address.split('\n').skip(1).join('\n'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
      
      // 清空并添加新标记，触发响应式更新
      markers.clear();
      markers.add(marker);
      markers.refresh(); // 强制刷新
      
      DebugUtil.success('🗺️ 地图标记已更新: $position');
      DebugUtil.info('📍 地址信息: $address');
    } catch (e) {
      DebugUtil.error('🗺️ 更新标记失败: $e');
    }
  }
  
  /// 从位置获取地址（调用高德地图逆地理编码API）
  /// [position] 位置坐标
  /// [context] BuildContext，用于显示自定义InfoWindow
  /// [poiName] POI名称，如果有则拼接到地址前面
  Future<void> _getAddressFromLocation(LatLng position, {BuildContext? context, String? poiName}) async {
    try {
      isLoadingAddress.value = true;
      selectedAddress.value = '正在获取地址...';
      
      // 调用逆地理编码服务
      final result = await _geocodeService.getAddressFromLocation(
        longitude: position.longitude,
        latitude: position.latitude,
      );
      
      if (result['success'] == true) {
        // 使用详细地址
        String detailAddress = _geocodeService.buildDetailAddress(result);
        
        // 如果有POI名称，拼接到地址前面
        if (poiName != null && poiName.isNotEmpty) {
          selectedAddress.value = '$poiName - $detailAddress';
          DebugUtil.success('✅ 地址获取成功（带POI）: ${selectedAddress.value}');
        } else {
          selectedAddress.value = detailAddress;
          DebugUtil.success('✅ 地址获取成功: ${selectedAddress.value}');
        }
        
        // 更新marker，显示获取到的地址
        _updateMarker(position, selectedAddress.value, context: context);
      } else {
        selectedAddress.value = '无法获取地址信息';
        DebugUtil.error('❌ 地址获取失败: ${result['error']}');
        
        // 更新marker，显示错误信息
        _updateMarker(position, '无法获取地址信息', context: context);
      }
    } catch (e) {
      selectedAddress.value = '地址获取失败';
      DebugUtil.error('❌ 获取地址异常: $e');
      
      // 更新marker，显示错误信息
      _updateMarker(position, '地址获取失败', context: context);
    } finally {
      isLoadingAddress.value = false;
    }
  }
  
  /// 选择图标类型
  void selectIcon(int iconId) {
    selectedIcon.value = iconId;
    final iconData = availableIcons.firstWhere(
      (icon) => icon.id == iconId,
      orElse: () => availableIcons[1],
    );
    DebugUtil.info('🎨 选中图标: ${iconData.label} (ID: $iconId)');
  }
  
  /// 更新围栏半径
  void updateGeofenceRadius(double radius) {
    geofenceRadius.value = radius;
    DebugUtil.info('📏 更新围栏半径: ${radius}米');
    
    // 如果已经选择了位置，更新圆形覆盖物
    if (selectedLocation.value != null) {
      _updateGeofenceCircle(selectedLocation.value!);
    }
  }
  
  /// 更新电子围栏圆形覆盖物
  void _updateGeofenceCircle(LatLng position) {
    // 根据触发条件选择颜色：到达=蓝色，离开=粉色
    final bool isArrival = selectedBottomAway.value; // true=到达, false=离开
    final strokeColor = isArrival 
        ? const Color(0x994D9FFF) // 蓝色边框 (60%透明度)
        : const Color(0xFFFF88AA); // 粉色边框
    final fillColor = isArrival
        ? const Color(0x334D9FFF) // 蓝色填充 (20%透明度)
        : const Color(0x66FFD5E1); // 粉色填充 #FFD5E1 带透明度
    
    final circle = Circle(
      center: position,
      radius: geofenceRadius.value,
      strokeWidth: 2,
      strokeColor: strokeColor,
      fillColor: fillColor,
      visible: true,
    );
    
    circles.clear();
    circles.add(circle);
    circles.refresh();
    
    DebugUtil.success('🔵 围栏圆形已更新: 中心=$position, 半径=${geofenceRadius.value}米');
  }
  
  /// 移动相机到指定位置，并向上偏移避免底部面板遮挡
  // void _moveCameraToPosition(LatLng position) {
  //   if (mapController != null) {
  //     // 🔧 底部面板约占45%屏幕高度，标记点需要显示在屏幕上方25-30%位置
  //     // 在缩放级别17.5下，屏幕高度约显示0.0063度纬度
  //     // 标记点默认在屏幕中心（50%），需要上移到25%
  //     // 向上偏移 = 屏幕高度 × (50% - 25%) = 0.0063 × 0.25 = 0.0016度
  //     // 实际测试需要更大偏移量以避免被面板完全遮挡，使用 0.005 度
  //     final offsetLatitude = position.latitude + 0.005;
  //     final offsetPosition = LatLng(offsetLatitude, position.longitude);
      
  //     DebugUtil.info('📷 相机移动: 原位置=$position, 偏移后=$offsetPosition, 偏移量=0.005度');
      
  //     // 使用动画移动相机，更平滑
  //     mapController!.moveCamera(
  //       CameraUpdate.newLatLng(offsetPosition),
  //       animated: true,
  //       duration: 300, // 动画时长300ms
  //     );
  //   }
  // }
  
  /// 保存位置
  Future<LocationReminder?> saveLocation() async {
    if (selectedLocation.value == null) {
      OKToastUtil.show('请先在地图上选择一个位置');
      return null;
    }
    
    try {
      // 创建位置提醒对象（不再截取本地地图快照）
      final reminder = LocationReminder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: noteText.value.isNotEmpty ? noteText.value : _getDefaultName(),
        address: selectedAddress.value,
        icon: selectedIcon.value,
        note: noteText.value,
        latitude: selectedLocation.value!.latitude,
        longitude: selectedLocation.value!.longitude,
        mapSnapshot: null, // 不再使用本地快照，改用静态地图URL
        radius: geofenceRadius.value,
        type: selectedBottomAway.value ? ReminderType.arrive : ReminderType.leave,
        mapType: mapType.value, // 保存用户选择的地图类型
      );
      
      DebugUtil.success('✅ 位置提醒创建成功: 类型=${reminder.type}, 半径=${reminder.radius}米, 地图类型=${reminder.mapType}');
      return reminder;
    } catch (e) {
      DebugUtil.error('❌ 保存位置失败: $e');
      OKToastUtil.showError('保存位置失败，请重试');
      return null;
    }
  }
  
  /// 获取默认名称（根据图标类型）
  String _getDefaultName() {
    final iconData = availableIcons.firstWhere(
      (icon) => icon.id == selectedIcon.value,
      orElse: () => availableIcons[1], // 默认返回"家"
    );
    return '我的${iconData.label}';
  }
}

/// 位置图标数据
class LocationIconData {
  final int id; // 图标ID (1-5)
  final String type; // 图标类型标识
  final String label; // 显示标签
  final String asset; // 未选中图标资源
  final String selectedAsset; // 选中图标资源
  
  LocationIconData({
    required this.id,
    required this.type,
    required this.label,
    required this.asset,
    required this.selectedAsset,
  });
}

