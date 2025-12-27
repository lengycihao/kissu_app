import 'package:flutter/material.dart';
import '../../../widgets/location_map_snapshot.dart';
import 'package:kissu_app/pages/location/location_reminder/location_reminder_controller.dart';

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
         ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              // 使用静态地图快照替换实时地图，避免每条消息导致地图重建闪烁
              // 请求更高分辨率的地图图片（3倍），然后缩小显示以保持文字清晰度
              Transform.scale(
                scale: 1, // 将3倍大小的图片缩小回原始尺寸
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: widget.width * 2,
                  height: widget.height * 2,
                  child: LocationMapSnapshot(
                    longitude: widget.longitude,
                    latitude: widget.latitude,
                    radius: 50,
                    iconId: 1,
                     reminderType: ReminderType.leave,
                    size: '${(widget.width * 2).toInt()}*${(widget.height * 2).toInt()}',
                    height: widget.height * 2, // 请求3倍高度的图片
                    isSatellite: false,
                  ),
                ),
              ),
              // 半透明遮罩，提示用户可以点击
              // Positioned.fill(
              //   child: Container(
              //     decoration: BoxDecoration(
              //       color: Colors.black.withValues(alpha: 0.1),
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //   ),
              // ),
               
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
