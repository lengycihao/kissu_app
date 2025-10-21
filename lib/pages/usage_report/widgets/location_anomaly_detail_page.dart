import 'package:flutter/material.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:kissu_app/models/location_anomaly_model.dart';
import 'package:kissu_app/pages/usage_report/widgets/map_marker_util.dart';
import 'package:kissu_app/widgets/safe_amap_widget.dart'; 

/// 定位/足迹异常详情页面
/// 显示全屏地图
class LocationAnomalyDetailPage extends StatefulWidget {
  final LocationAnomalyModel record;

  const LocationAnomalyDetailPage({
    super.key,
    required this.record,
  });

  @override
  State<LocationAnomalyDetailPage> createState() => _LocationAnomalyDetailPageState();
}

class _LocationAnomalyDetailPageState extends State<LocationAnomalyDetailPage> {
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
        widget.record.avatarUrl,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 全屏地图
          SafeAMapWidget(
            onMapCreated: (AMapController controller) {
              controller.moveCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: LatLng(widget.record.latitude, widget.record.longitude),
                    zoom: 16.0,
                  ),
                ),
              );
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.record.latitude, widget.record.longitude),
              zoom: 16.0,
            ),
            markers: _markerIcon != null
                ? {
                    Marker(
                      position: LatLng(widget.record.latitude, widget.record.longitude),
                      icon: _markerIcon!,
                    ),
                  }
                : {
                    Marker(
                      position: LatLng(widget.record.latitude, widget.record.longitude),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                    ),
                  },
            mapType: MapType.normal,
          ),

          // 顶部返回按钮
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),

          // 底部位置信息模块
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 126,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/chat/kissu3_map_preview_bg.webp'),
                  fit: BoxFit.fill,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 30),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
                  child: Row(
                    children: [
                      // 左侧类型图标
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(
                          widget.record.type.iconPath,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 中间位置信息
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.record.locationName,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF333333),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  widget.record.type.title,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF999999),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.record.timeRange,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF999999),
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
            ),
          ),
        ],
      ),
    );
  }
}

