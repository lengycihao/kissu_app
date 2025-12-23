import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/track/stay_point.dart';
import 'package:kissu_app/pages/track/track_controller.dart';
import 'package:kissu_app/model/location_model/location_model.dart';

class StopListItem extends StatelessWidget {
  final StopRecord record;
  final int index; // 用于显示连接线等，保留以防需要
  final bool isLast; // 是否是最后一个item

  const StopListItem({
    Key? key,
    required this.record,
    required this.index,
    this.isLast = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        try {
          final controller = Get.find<TrackController>();

          // 创建对应的TrackStopPoint对象用于InfoWindow显示
          final stopPoint = TrackStopPoint(
            lat: record.latitude,
            lng: record.longitude,
            locationName: record.locationName,
            duration: record.stayDuration,
            startTime: record.time.split('~').isNotEmpty
                ? record.time.split('~')[0]
                : '',
            endTime: record.time.split('~').length > 1
                ? record.time.split('~')[1]
                : '',
            serialNumber: record.serialNumber,
          );

          // 使用增强版方法：移动地图、绘制高亮圆圈、显示InfoWindow
          await controller.moveToStopPointWithHighlight(
            context, // 传入正确的BuildContext
            record.latitude,
            record.longitude,
            stopPoint: stopPoint,
          );
        } catch (e) {
          print('无法找到轨迹控制器: $e');
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: isLast ? 0 : 0),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左边时间部分 - 对齐
              Container(
                width: 40, // 给时间一个固定宽度，确保对齐
                child: Text(
                  record.leftTime,
                  style: TextStyle(fontSize: 13, color: Color(0xff333333), fontWeight: FontWeight.w500,),
                ),
              ),
              // 时间轴圆点和连接线
              Container(
                width: 20,
                child: Stack(
                  children: [
                    // 连接线 - 从圆点底部延伸到容器底部
                    if (!isLast)
                      Positioned(
                        left: 9, // 圆点中心位置
                        top: 16, // 圆点底部
                        bottom: 0,
                        child: SizedBox(
                          width: 2,
                          // 使用 CustomPaint 绘制虚线
                          child: CustomPaint(
                            painter: _VerticalDashedLinePainter(
                              color: const Color(0x66000000),
                              dashHeight: 6,
                              gapHeight: 4,
                              strokeWidth: 1,
                            ),
                          ),
                        ),
                      ),
                    // 圆点
                    Positioned(
                      left: 1,
                      top: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Color(0xFF000000),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: Color(0xFFFF97CE),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                         child: Text(
                          record.serialNumber, // 直接显示 serial_number
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 15),
              // 内容部分
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.locationName,
                      style: TextStyle(fontSize: 12, color: Color(0xff333333)),
                    ),
                    const SizedBox(height: 11),

                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                       color: record.status == 'staying' ? Color(0xffFFFFEE)  :Color(0xffFFEDFB) ,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: record.time.trim().isEmpty
                          ? // 当时间为空时，图标和文字居中显示
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/kissu_track_location.webp',
                                  width: 24,
                                  height: 24,
                                ),
                                const SizedBox(width: 12),
                                // 仅显示停留时长文字
                                if (record.stayDuration.isNotEmpty)
                                  Text(
                                    record.stayDuration,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xffFF4177),
                                    ),
                                  ),
                              ],
                            )
                          : // 当时间不为空时，正常布局
                            Row(
                              children: [
                                Image.asset(
                                  record.status == 'staying'
                                      ? 'assets/images/kissu_track_staying.webp'
                                      : 'assets/images/kissu_track_location.webp',
                                  width: 24,
                                  height: 24,
                                  // color: record.status == 'staying'
                                  //     ? Color(0xFFBE9DFF)
                                  //     : Color(0xFFFBAE84),
                                ),
                                const SizedBox(width: 12),
                                // 仅当 stayDuration 非空时显示
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (record.stayDuration.isNotEmpty) ...[
                                        Text(
                                          record.stayDuration,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xff333333),
                                          ),
                                          softWrap: true, // 启用自动换行
                                          maxLines: 2, // 最多显示两行
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                      // 时间部分
                                      Text(
                                        record.time,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xff666666),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 垂直虚线画笔
class _VerticalDashedLinePainter extends CustomPainter {
  final Color color;
  final double dashHeight;
  final double gapHeight;
  final double strokeWidth;

  _VerticalDashedLinePainter({
    required this.color,
    this.dashHeight = 4.0,
    this.gapHeight = 4.0,
    this.strokeWidth = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double y = 0.0;
    final centerX = size.width / 2;
    while (y < size.height) {
      final endY = (y + dashHeight).clamp(0.0, size.height);
      canvas.drawLine(Offset(centerX, y), Offset(centerX, endY), paint);
      y += dashHeight + gapHeight;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
