import 'package:flutter/material.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
// no-op: location preview widgets not required here
import 'package:kissu_app/pages/location/services/marker_builder.dart';

/// 全屏位置详情页（与之前聊天页中的私有 _LocationDetailPage 功能等价）
class LocationDetailPage extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String locationName;
  final String? avatarUrl;
  final bool isMyself;

  const LocationDetailPage({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    this.avatarUrl,
    required this.isMyself,
  });

  @override
  State<LocationDetailPage> createState() => _LocationDetailPageState();
}

class _LocationDetailPageState extends State<LocationDetailPage> {
  BitmapDescriptor? _pedestalIcon;
  BitmapDescriptor? _avatarIcon;
  Offset? _avatarAnchor;
  final MarkerBuilder _markerBuilder = MarkerBuilder();
  Set<Marker> _markers = {};
  bool _iconsCreated = false;

  @override
  void initState() {
    super.initState();
    _createMarkerIcons();
  }

  Future<void> _createMarkerIcons() async {
    try {
      final String baseAsset = widget.isMyself
          ? 'assets/images/kissu_location_run.webp'
          : 'assets/3.0/kissu3_location_she.webp';

      // 创建底座（尺寸与定位页一致）
      final pedestal = await _markerBuilder.createPedestalMarker(
        pedestalAsset: baseAsset,
        size: widget.isMyself ? 800.0 : 40.0,
      );

      // 创建头像 marker（不包含底座）
      final avatarData = await _markerBuilder.createAvatarMarker(
        widget.avatarUrl ?? '',
        defaultAsset: 'assets/3.0/kissu3_love_avater.webp',
        baseAsset: baseAsset,
        useLargePedestal: widget.isMyself,
        skipPedestal: true,
      );

      final avatarDescriptor = avatarData['descriptor'] as BitmapDescriptor?;
      final avatarAnchor = avatarData['anchor'] as Offset?;

      final Set<Marker> markers = {};

      if (pedestal != null) {
        final pedestalMarker = Marker(
          position: LatLng(widget.latitude, widget.longitude),
          icon: pedestal,
          anchor: const Offset(0.5, 0.5),
          zIndex: 1.0,
          clickable: false,
        );
        pedestalMarker.setIdForCopy('detail_pedestal');
        markers.add(pedestalMarker);
      }

      if (avatarDescriptor != null) {
        final avatarMarker = Marker(
          position: LatLng(widget.latitude, widget.longitude),
          icon: avatarDescriptor,
          anchor: avatarAnchor ?? const Offset(0.5, 1.0),
          zIndex: 2.0,
        );
        avatarMarker.setIdForCopy('detail_avatar');
        markers.add(avatarMarker);
      }

      if (mounted) {
        setState(() {
          _pedestalIcon = pedestal;
          _avatarIcon = avatarDescriptor;
          _avatarAnchor = avatarAnchor;
          _markers = markers;
          _iconsCreated = true;
        });
      }
    } catch (e) {
      debugPrint('创建详情页标记图标失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AMapWidget(
            onMapCreated: (AMapController controller) {
              controller.moveCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: LatLng(widget.latitude, widget.longitude),
                    zoom: 16.0,
                  ),
                ),
              );
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.latitude, widget.longitude),
              zoom: 16.0,
            ),
            markers: _markers.isNotEmpty
                ? _markers
                : {
                    Marker(
                      position: LatLng(widget.latitude, widget.longitude),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                    ),
                  },
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
          ),
          // 顶部右侧关闭按钮（替代顶部返回按钮）
         
          // 底部位置信息卡片（白色背景，圆角，左侧图标、标题、位置文案，右上角有关闭按钮）
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Stack(
              children: [
                Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [Color(0xffFFF1FD), Color(0xffF6F6F6)],
                  begin: Alignment.topCenter,
                  end: AlignmentGeometry.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF000000).withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: 20,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // 左侧图标
                              Image.asset(
                                'assets/4.0/kissu_location_logo.webp',
                                width: 28,
                                height: 28,
                                fit: BoxFit.contain,
                              ),
                              Expanded(
                                child: Text(
                                  widget.isMyself ? '当前我的位置' : '当前Ta的位置',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF333333),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [const SizedBox(width: 8),
                              // 小圆点
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 6, right: 8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF8AD3),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              // 位置文本（最多两行）
                              Expanded(
                                child: Text(
                                  widget.locationName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xff333333),
                                  ),
                                  maxLines: 5,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
                    Positioned(
            top: 0,
            right: 2,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  // color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  
                ),
                child: const Center(
                  child: Icon(Icons.close, size: 16, color: Color(0xFF666666)),
                ),
              ),
            ),
          ),
      
              ],
            )
          ),
        ],
      ),
    );
  }
}
