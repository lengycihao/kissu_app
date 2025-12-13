import 'package:flutter/material.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import '../utils/map_marker_util.dart';

/// 位置预览组件
/// 用于在聊天消息中显示小地图预览
class LocationPreviewWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String locationName;
  final double width;
  final double height;
  final VoidCallback? onTap;
  final String? avatarUrl; // 发送者头像 URL

  const LocationPreviewWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    this.width = 150,
    this.height = 100,
    this.onTap,
    this.avatarUrl,
  });

  @override
  State<LocationPreviewWidget> createState() => _LocationPreviewWidgetState();
}

class _LocationPreviewWidgetState extends State<LocationPreviewWidget> {
  BitmapDescriptor? _markerIcon;

  @override
  void initState() {
    super.initState();
    _createMarkerIcon();
  }

  /// 创建自定义标记图标（圆形头像）
  Future<void> _createMarkerIcon() async {
    try {
      final icon = await MapMarkerUtil.createCircleAvatarMarker(
        widget.avatarUrl,
        size: 60.0, // 标记大小
        borderWidth: 3.0, // 边框宽度
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // 地图组件
              AMapWidget(
                onMapCreated: (AMapController controller) {
                  // 地图创建完成后的回调
                  controller.moveCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: LatLng(widget.latitude, widget.longitude),
                        zoom: 15.0, // 适中的缩放级别
                      ),
                    ),
                  );
                },
                initialCameraPosition: CameraPosition(
                  target: LatLng(widget.latitude, widget.longitude),
                  zoom: 15.0,
                ),
                markers: _markerIcon != null
                    ? {
                        Marker(
                          position: LatLng(widget.latitude, widget.longitude),
                          icon: _markerIcon!,
                        ),
                      }
                    : {
                        Marker(
                          position: LatLng(widget.latitude, widget.longitude),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed,
                          ),
                        ),
                      },
                // 禁用用户交互，因为这只是预览
                onTap: (LatLng position) {
                  widget.onTap?.call();
                },
                // 设置地图样式为简化版本
                mapType: MapType.normal,
                // 禁用缩放和拖拽
                zoomGesturesEnabled: false,
                scrollGesturesEnabled: false,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
              ),
              // 半透明遮罩，提示用户可以点击
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              // 位置图标
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 简化的位置预览组件（当无法加载地图时使用）
class SimpleLocationPreviewWidget extends StatelessWidget {
  final String locationName;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const SimpleLocationPreviewWidget({
    super.key,
    required this.locationName,
    this.width = 150,
    this.height = 100,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_on,
              color: Colors.red,
              size: 32,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                locationName,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
