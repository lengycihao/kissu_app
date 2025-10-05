import 'package:flutter/material.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:kissu_app/models/location_anomaly_model.dart';
import 'package:kissu_app/pages/chat/utils/map_marker_util.dart';

/// 定位/足迹异常卡片组件
/// 显示地图预览，包含位置信息和图标标识
class LocationAnomalyCard extends StatefulWidget {
  final LocationAnomalyModel record;
  final VoidCallback? onTap;

  const LocationAnomalyCard({
    super.key,
    required this.record,
    this.onTap,
  });

  @override
  State<LocationAnomalyCard> createState() => _LocationAnomalyCardState();
}

class _LocationAnomalyCardState extends State<LocationAnomalyCard> {
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
        size: 60.0,
        borderWidth: 3.0,
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
    // 特殊处理疑似更改手机定位类型
    if (widget.record.type == LocationAnomalyType.yishi) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildTimeLabel(),
          const SizedBox(height: 8),
          _buildYishiCard(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildTimeLabel(),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: widget.onTap,
          child: Container(
            height: 80, // 固定高度 80px
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildMapPreview(),
          ),
        ),
      ],
    );
  }

  /// 构建时间标签（参考敏感记录的样式）
  Widget _buildTimeLabel() {
    final timeStr = widget.record.timeRange; // 直接使用 timeRange，格式如 "14:30-17:12"
    return Center(
      child: Text(
        timeStr,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF999999),
        ),
      ),
    );
  }

  /// 构建疑似更改手机定位卡片（使用图片）
  Widget _buildYishiCard() {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 80,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/phone_history/kissu3_history_yishi.webp',
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        ),
      ),
    );
  }

  /// 构建地图预览（使用静态快照优化性能）
  Widget _buildMapPreview() {
    // 获取圆形配置
    final circleConfig = widget.record.type.circleConfig;
    final hasCircle = circleConfig.radius > 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // 使用静态地图快照代替动态地图组件，大幅提升滚动性能
              Positioned.fill(
                child: RepaintBoundary(
                  child: _StaticMapSnapshot(
                    latitude: widget.record.latitude,
                    longitude: widget.record.longitude,
                    markerIcon: _markerIcon,
                  ),
                ),
              ),
              // 绘制圆形覆盖层（如果需要）
              if (hasCircle)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CirclePainter(
                      circleConfig: circleConfig,
                      // 标记在地图左侧 1/5 位置
                      center: const Offset(0.12, 0.5),
                    ),
                  ),
                ),
              // 在圆形中心显示类型图标
              if (hasCircle)
                Positioned(
                  left: constraints.maxWidth * 0.12 - 12, // 图标宽度的一半
                  top: 40 - 12, // 图标高度的一半（卡片高度80px的中心）
                  child: Image.asset(
                    'assets/home_list_type_location.webp',
                    width: 24,
                    height: 24,
                  ),
                ),
              // 底部渐变蒙版（从左到右：透明到白色）
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 80,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white,
                        Colors.white,
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),
              // 底部信息文字（位于蒙版之上）
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 80,
                child: _buildInfoSection(),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 构建信息区域
  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12).copyWith(left: 110),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左侧：位置名称和时间
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDescriptionText(),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildTypeLabel(),
                    const Spacer(),
                    const Text("查看", style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                       color: Color(0xFF2289FF),
                    ),),
                    Image.asset(
                      'assets/phone_history/kissu3_arrow_right_blue.webp',
                      width: 12,
                      height: 12,
                    ),
                  ],
                ),
              ],
            ),
          ),
           
        ],
      ),
    );
  }

  /// 构建描述文本（根据类型显示不同内容）
  Widget _buildDescriptionText() {
    // 停留点类型
    if (widget.record.type == LocationAnomalyType.stay) {
      final displayName = _truncateLocationName(widget.record.locationName, 5);
      return Text.rich(
        TextSpan(
          children: [
            const TextSpan(
              text: "对方出现在你标记的",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
            TextSpan(
              text: displayName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4096FF),
              ),
            ),
            const TextSpan(
              text: "过",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      );
    }
    
    // 疑似异常点 - 速度异常
    if (widget.record.type == LocationAnomalyType.exception && 
        widget.record.exceptionSubType == ExceptionSubType.speed) {
          
      return const Text(
        "对方定位速度异常",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF333333),
        ),
      );
    }
    
    // 疑似异常点 - 停留时长异常（默认）
    final displayName = _truncateLocationName(widget.record.locationName, 5);
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(
            text: "对方已在",
            
            style: TextStyle(
              fontSize: 12,
              
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
          TextSpan(
            text: displayName,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFFFF3B00),
            ),
          ),
          const TextSpan(
            text: "停留超过2个小时",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建类型标签
  Widget _buildTypeLabel() {
    // 停留点类型
    if (widget.record.type == LocationAnomalyType.stay) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF3B96FF),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        child: const Text(
          "停留点",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFFFFFDFD),
          ),
        ),
      );
    }
    
    // 疑似异常点（包括速度异常和停留异常）
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFFF6262),
            Color(0xFFFF9B65),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: const Text(
        "疑似异常点",
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFFFFFDFD),
        ),
      ),
    );
  }

  /// 截断位置名称，最多显示指定字数，超出显示...
  String _truncateLocationName(String name, int maxLength) {
    if (name.length <= maxLength) {
      return name;
    }
    return '${name.substring(0, maxLength)}...';
  }
}

/// 静态地图快照组件（优化性能）
/// 使用轻量级实现，避免在列表中创建多个地图实例
class _StaticMapSnapshot extends StatefulWidget {
  final double latitude;
  final double longitude;
  final BitmapDescriptor? markerIcon;

  const _StaticMapSnapshot({
    required this.latitude,
    required this.longitude,
    this.markerIcon,
  });

  @override
  State<_StaticMapSnapshot> createState() => _StaticMapSnapshotState();
}

class _StaticMapSnapshotState extends State<_StaticMapSnapshot> 
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // 保持地图状态，避免重复创建

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用，用于 AutomaticKeepAliveClientMixin
    
    return AMapWidget(
      onMapCreated: (AMapController controller) {
        controller.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(widget.latitude, widget.longitude),
              zoom: 15.0,
            ),
          ),
        );
      },
      initialCameraPosition: CameraPosition(
        target: LatLng(widget.latitude, widget.longitude),
        zoom: 15.0,
      ),
      markers: widget.markerIcon != null
          ? {
              Marker(
                position: LatLng(widget.latitude, widget.longitude),
                icon: widget.markerIcon!,
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
      mapType: MapType.normal,
      logoPosition: LogoPosition.bottomRight,
      zoomGesturesEnabled: false,
      scrollGesturesEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
    );
  }
}

/// 圆形绘制器
class _CirclePainter extends CustomPainter {
  final MapCircleConfig circleConfig;
  final Offset center; // 相对位置（0-1）

  _CirclePainter({
    required this.circleConfig,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 计算实际中心点位置
    final actualCenter = Offset(
      size.width * center.dx,
      size.height * center.dy,
    );

    // 绘制外圈（边框）
    final strokePaint = Paint()
      ..color = circleConfig.strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = circleConfig.strokeWidth;

    canvas.drawCircle(
      actualCenter,
      circleConfig.radius,
      strokePaint,
    );

    // 绘制内圈（填充）
    final fillPaint = Paint()
      ..color = circleConfig.fillColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      actualCenter,
      circleConfig.radius,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
