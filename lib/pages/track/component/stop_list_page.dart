import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/track/stay_point.dart';
import 'package:kissu_app/pages/track/track_controller.dart';

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
      onTap: () {
        try {
          final controller = Get.find<TrackController>();
          controller.moveToStopPoint(record.latitude, record.longitude);
        } catch (e) {
          print('无法找到轨迹控制器: $e');
        }
      },
      child: Container(
        child: IntrinsicHeight(
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左边时间部分 - 对齐
            Container(
              width: 45, // 给时间一个固定宽度，确保对齐
              child: Text(
                record.leftTime,
                style: TextStyle(fontSize: 12, color: Color(0xff333333)),
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
                      bottom: -16, // 延伸到margin区域
                      child: Container(width: 1, color: Color(0xffFF88AA)),
                    ),
                  // 圆点
                  Positioned(
                    left: 1,
                    top: 0,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Color(0xFFFF88AA), // 统一圆点颜色
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
            SizedBox(width: 20),
            // 内容部分
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.locationName,
                    style: TextStyle(fontSize: 12, color: Color(0xff333333)),
                  ),
                  const SizedBox(height: 4),

                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xffFFEDF2), Color(0xffFFF8FA)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: record.time.trim().isEmpty
                        ? // 当时间为空时，图标和文字居中显示
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/kissu_track_location.webp',
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
                                'assets/kissu_track_location.webp',
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: 12),
                              // 仅当 stayDuration 非空时显示
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (record.stayDuration.isNotEmpty) ...[
                                      Text(
                                        record.stayDuration,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xffFF4177),
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
