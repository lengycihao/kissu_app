import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:kissu_app/pages/location/location_reminder/location_reminder_controller.dart';
import 'package:kissu_app/services/amap_geocode_service.dart';
import 'package:kissu_app/utils/debug_util.dart';

/// 地图选点Controller
class LocationPickerController extends GetxController {
  // 地图控制器
  AMapController? mapController;
  
  // 逆地理编码服务
  final _geocodeService = AMapGeocodeService();
  
  // 当前选中的位置
  final Rx<LatLng?> selectedLocation = Rx<LatLng?>(null);
  
  // 当前位置的地址信息
  final selectedAddress = '请在地图上选择位置'.obs;
  
  // 地址加载状态
  final isLoadingAddress = false.obs;
  
  // 选中的图标类型
  final selectedIcon = 'home'.obs;

    // 选中的图标类型
  final selectedBottomAway = true.obs;
  
  // 备注文本
  final noteText = ''.obs;
  
  // 地图标记
  final markers = <Marker>{}.obs;
  
  // 可选的图标列表
  final List<LocationIconData> availableIcons = [
    LocationIconData(type: 'home', label: '家', asset: 'assets/location/kissu3_jia.webp',selectedAsset: 'assets/location/kissu3_jia_sel.webp'),
    LocationIconData(type: 'company', label: '公司', asset: 'assets/location/kissu3_gongsi.webp',selectedAsset: 'assets/location/kissu3_gongsi_sel.webp'),
    LocationIconData(type: 'gym', label: '健身房', asset: 'assets/location/kissu3_jianshen.webp',selectedAsset: 'assets/location/kissu3_jianshen_sel.webp'),
    LocationIconData(type: 'restaurant', label: '娱乐', asset: 'assets/location/kissu3_yule.webp',selectedAsset: 'assets/location/kissu3_yule_sel.webp'),
    LocationIconData(type: 'shop', label: '商店', asset: 'assets/location/kissu3_shangchang.webp',selectedAsset: 'assets/location/kissu3_shangchang_sel.webp'),
  ];
  
  // 文本输入控制器
  final TextEditingController noteController = TextEditingController();
  
  @override
  void onInit() {
    super.onInit();
    
    // 监听备注文本变化
    noteController.addListener(() {
      noteText.value = noteController.text;
    });
  }
  
  @override
  void onClose() {
    noteController.dispose();
    super.onClose();
  }
  
  /// 地图创建完成回调
  void onMapCreated(AMapController controller) {
    mapController = controller;
    DebugUtil.info('🗺️ 地图选点页面地图创建完成');
  }
  
  /// 初始相机位置（默认杭州）
  CameraPosition get initialCameraPosition {
    return const CameraPosition(
      target: LatLng(30.2741, 120.2206),
      zoom: 16.0,
    );
  }
  
  /// 地图点击事件
  void onMapTap(LatLng position) {
    DebugUtil.info('🗺️ 地图点击: $position');
    selectedLocation.value = position;
    
    // 更新地图标记
    _updateMarker(position);
    
    // 获取地址信息（这里简化处理，实际应该调用逆地理编码API）
    _getAddressFromLocation(position);
  }
  
  /// 更新地图标记
  void _updateMarker(LatLng position) {
    try {
      final marker = Marker(
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
      
      // 清空并添加新标记，触发响应式更新
      markers.clear();
      markers.add(marker);
      markers.refresh(); // 强制刷新
      
      DebugUtil.success('🗺️ 地图标记已更新: $position');
      DebugUtil.info('🗺️ 标记数量: ${markers.length}');
    } catch (e) {
      DebugUtil.error('🗺️ 更新标记失败: $e');
    }
  }
  
  /// 从位置获取地址（调用高德地图逆地理编码API）
  Future<void> _getAddressFromLocation(LatLng position) async {
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
        selectedAddress.value = _geocodeService.buildDetailAddress(result);
        DebugUtil.success('✅ 地址获取成功: ${selectedAddress.value}');
      } else {
        selectedAddress.value = '无法获取地址信息';
        DebugUtil.error('❌ 地址获取失败: ${result['error']}');
      }
    } catch (e) {
      selectedAddress.value = '地址获取失败';
      DebugUtil.error('❌ 获取地址异常: $e');
    } finally {
      isLoadingAddress.value = false;
    }
  }
  
  /// 选择图标类型
  void selectIcon(String iconType) {
    selectedIcon.value = iconType;
    DebugUtil.info('🎨 选中图标类型: $iconType');
  }
  
  /// 保存位置
  Future<LocationReminder?> saveLocation() async {
    if (selectedLocation.value == null) {
      Get.snackbar(
        '提示',
        '请先在地图上选择一个位置',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.white,
        colorText: const Color(0xFF333333),
      );
      return null;
    }
    
    try {
      // 截取地图快照
      Uint8List? mapSnapshot;
      if (mapController != null) {
        DebugUtil.info('📸 开始截取地图快照...');
        mapSnapshot = await mapController!.takeSnapshot();
        if (mapSnapshot != null) {
          DebugUtil.success('📸 地图快照截取成功，大小: ${mapSnapshot.length} bytes');
        } else {
          DebugUtil.warning('📸 地图快照截取失败，返回null');
        }
      }
      
      // 创建位置提醒对象
      final reminder = LocationReminder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: noteText.value.isNotEmpty ? noteText.value : _getDefaultName(),
        address: selectedAddress.value,
        icon: selectedIcon.value,
        note: noteText.value,
        latitude: selectedLocation.value!.latitude,
        longitude: selectedLocation.value!.longitude,
        mapSnapshot: mapSnapshot,
      );
      
      DebugUtil.success('✅ 位置提醒创建成功');
      return reminder;
    } catch (e) {
      DebugUtil.error('❌ 保存位置失败: $e');
      Get.snackbar(
        '错误',
        '保存位置失败，请重试',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.white,
        colorText: const Color(0xFF333333),
      );
      return null;
    }
  }
  
  /// 获取默认名称（根据图标类型）
  String _getDefaultName() {
    final iconData = availableIcons.firstWhere(
      (icon) => icon.type == selectedIcon.value,
      orElse: () => availableIcons[0],
    );
    return '我的${iconData.label}';
  }
}

/// 位置图标数据
class LocationIconData {
  final String type;
  final String label;
  final String asset;
  final String selectedAsset;
  
  LocationIconData({
    required this.type,
    required this.label,
    required this.asset,
    required this.selectedAsset,
  });
}

