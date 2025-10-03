import 'package:flutter/material.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import '../utils/map_marker_util.dart';

/// 位置信息数据模型
class LocationInfo {
  final String name;
  final String? address;
  final double latitude;
  final double longitude;
  final bool isCurrentLocation;

  LocationInfo({
    required this.name,
    this.address,
    required this.latitude,
    required this.longitude,
    this.isCurrentLocation = false,
  });
}

/// 位置选择页面
class LocationPickerPage extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialLocationName;
  final String? avatarUrl;

  const LocationPickerPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialLocationName,
    this.avatarUrl,
  });

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  BitmapDescriptor? _markerIcon;
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;
  
  // 模拟的附近位置列表（实际应从高德地图 POI 搜索获取）
  late List<LocationInfo> _nearbyLocations;

  @override
  void initState() {
    super.initState();
    _createMarkerIcon();
    _initializeLocations();
  }

  void _initializeLocations() {
    final lat = widget.initialLatitude ?? 39.9042;
    final lng = widget.initialLongitude ?? 116.4074;
    
    _nearbyLocations = [
      LocationInfo(
        name: widget.initialLocationName ?? '当前位置',
        address: '我的位置',
        latitude: lat,
        longitude: lng,
        isCurrentLocation: true,
      ),
      // 模拟附近的位置（实际应从高德地图 API 获取）
      LocationInfo(
        name: '附近地点 1',
        address: '示例地址 1',
        latitude: lat + 0.001,
        longitude: lng + 0.001,
      ),
      LocationInfo(
        name: '附近地点 2',
        address: '示例地址 2',
        latitude: lat - 0.001,
        longitude: lng + 0.001,
      ),
      LocationInfo(
        name: '附近地点 3',
        address: '示例地址 3',
        latitude: lat + 0.001,
        longitude: lng - 0.001,
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 创建自定义标记图标
  Future<void> _createMarkerIcon() async {
    try {
      final icon = await MapMarkerUtil.createCircleAvatarMarker(
        widget.avatarUrl,
        size: 80.0,
        borderWidth: 4.0,
      );
      if (mounted) {
        setState(() {
          _markerIcon = icon;
        });
      }
    } catch (e) {
      debugPrint('创建标记图标失败: $e');
    }
  }

  void _onConfirm() {
    final selectedLocation = _nearbyLocations[_selectedIndex];
    Navigator.of(context).pop(selectedLocation);
  }

  @override
  Widget build(BuildContext context) {
    final selectedLocation = _nearbyLocations[_selectedIndex];
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 全屏地图
          AMapWidget(
            onMapCreated: (AMapController controller) {
              controller.moveCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: LatLng(selectedLocation.latitude, selectedLocation.longitude),
                    zoom: 16.0,
                  ),
                ),
              );
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(selectedLocation.latitude, selectedLocation.longitude),
              zoom: 16.0,
            ),
            markers: _markerIcon != null
                ? {
                    Marker(
                      position: LatLng(selectedLocation.latitude, selectedLocation.longitude),
                      icon: _markerIcon!,
                    ),
                  }
                : {
                    Marker(
                      position: LatLng(selectedLocation.latitude, selectedLocation.longitude),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                    ),
                  },
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
          ),

          // 返回按钮 - 左上角
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Image.asset(
                'assets/kissu_mine_back.webp',
                width: 22,
                height: 22,
              ),
            ),
          ),

          // 底部功能区域
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  
                  // 1. 搜索框
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFF9DC4),
                          width: 2,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: '搜索地点',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFFFF9DC4),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (value) {
                          // TODO: 实现搜索功能
                          debugPrint('搜索: $value');
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 2. 附近地址列表 - 可滚动区域
                  Flexible(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _nearbyLocations.length,
                        itemBuilder: (context, index) {
                          final location = _nearbyLocations[index];
                          final isSelected = _selectedIndex == index;
                          
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedIndex = index;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? const Color(0xFFFFF5F9) 
                                    : Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    location.isCurrentLocation 
                                        ? Icons.my_location 
                                        : Icons.location_on_outlined,
                                    color: location.isCurrentLocation
                                        ? const Color(0xFFFF9DC4)
                                        : Colors.grey[600],
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          location.name,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: location.isCurrentLocation
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            color: const Color(0xFF333333),
                                          ),
                                        ),
                                        if (location.address != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            location.address!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFFFF72C6),
                                      size: 24,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. 确认按钮 - 固定在底部
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      0,
                      20,
                      20 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _onConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9DC4),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          '确定',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
}

