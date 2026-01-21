import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../track/track_page.dart';
import '../../track/track_binding.dart';
import '../location_v2_controller.dart';
import '../services/location_data_helper.dart';

/// 位置记录列表组件
/// 负责显示和管理位置记录列表
class LocationRecordsListWidget extends StatelessWidget {
  final LocationV2Controller controller;

  const LocationRecordsListWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Stack(
        children: [
          Container(
            margin: EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 15),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
             
            child: Obx(() {
              if (controller.locationRecords.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(top: 90),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/kissu_track_empty.webp',
                        width: 133,
                        height: 96,
                      ),
                      SizedBox(height: 14),
                      Text(
                        '目前还没有停留地点哦～',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xff777777),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return _OptimizedLocationRecordsList(controller: controller);
            }),
          ),
        ],
      ),
    );
  }
}

/// 优化的位置记录列表组件
class _OptimizedLocationRecordsList extends StatelessWidget {
  final LocationV2Controller controller;

  const _OptimizedLocationRecordsList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final records = controller.locationRecords;
      if (records.isEmpty) return Container();

      if (records.length > 10) {
        return _buildLargeList(records);
      } else {
        return _LocationListWithBackground(
          controller: controller,
          records: records,
        );
      }
    });
  }

  Widget _buildLargeList(List<LocationRecord> records) {
    return Column(
      children: [
        Obx(() {
          final recordCount = controller.locationRecords.length;
          return Row(
            children: [
              Text(
                "今日停留$recordCount个地方",
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'AlimamaShuHeiTi',
                  color: Color(0xFF000000),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Image.asset(
                'assets/images/kissu_love_yellow.webp',
                width: 23,
                height: 23,
              ),
            ],
          );
        }),
        SizedBox(height: 16),
        if (records.isNotEmpty)
          ...records.asMap().entries.map((entry) {
            final index = entry.key;
            final record = entry.value;
            final isLast = index == records.length - 1;
            return RepaintBoundary(
              child: _LocationRecordItem(
                record: record,
                index: index,
                isLast: isLast,
                controller: controller,
              ),
            );
          }),
      ],
    );
  }
}

/// 带背景的位置列表组件
class _LocationListWithBackground extends StatelessWidget {
  final LocationV2Controller controller;
  final List<LocationRecord> records;

  const _LocationListWithBackground({
    required this.controller,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    final imageHeight = 140.0;

    return Obx(() {
      return Column(
        children: [
          Row(
            children: [
              Text(
                "今日停留${records.length}个地方",
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'AlimamaShuHeiTi',
                  color: Color(0xFF000000),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Image.asset(
                'assets/images/kissu_love_yellow.webp',
                width: 23,
                height: 23,
              ),
            ],
          ),
          SizedBox(height: 16),
          ...records.asMap().entries.map((entry) {
            final index = entry.key;
            final record = entry.value;
            final isLast = index == records.length - 1;
            return RepaintBoundary(
              child: _LocationRecordItem(
                record: record,
                index: index,
                isLast: isLast,
                controller: controller,
              ),
            );
          }),
          SizedBox(height: imageHeight),
        ],
      );
    });
  }
}

/// 位置记录项组件
class _LocationRecordItem extends StatelessWidget {
  final LocationRecord record;
  final int index;
  final bool isLast;
  final LocationV2Controller controller;

  const _LocationRecordItem({
    required this.record,
    required this.index,
    required this.isLast,
    required this.controller,
  });

  String _formatTimeRange(String? startTime, String? endTime) {
    if (startTime == null || startTime.isEmpty) return '未知时间';
    if (startTime == '当前') return '当前停留';
    if (endTime == null || endTime.isEmpty || endTime == '当前') {
      return '$startTime~当前';
    }
    return '$startTime~$endTime';
  }

  String _getLeftText(LocationRecord record) {
    if (record.status == 'staying') {
      return '停留中';
    } else if (record.status == 'ended') {
      return '停留${record.duration ?? '未知'}';
    } else {
      return '停留${record.duration ?? '未知'}';
    }
  }

  String _getRightText(LocationRecord record) {
    if (record.status == 'staying') {
      return record.duration ?? '未知';
    } else if (record.status == 'ended') {
      return _formatTimeRange(record.startTime, record.endTime);
    } else {
      return _formatTimeRange(record.startTime, record.endTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 埋点：页面离开（进入下一页）
        controller.onNavigateToNextPage?.call();
        
        if (record.latitude != null && record.longitude != null) {
          Get.to(
            () => TrackPage(
              initialLatitude: record.latitude!,
              initialLongitude: record.longitude!,
              initialLocationName: record.locationName,
              initialDuration: record.duration,
              initialStartTime: record.startTime,
              initialEndTime: record.endTime,
              autoShowInfoWindow: true,
              targetUserType: controller.isOneself.value,
            ),
            binding: TrackBinding(),
            transition: Transition.rightToLeft,
          );
        } else {
          // 注意：已经在上面调用过了，不需要重复调用
          Get.to(
            () => TrackPage(),
            binding: TrackBinding(),
            transition: Transition.rightToLeft,
          );
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 0),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      record.startTime ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(width: 6),
                  Image(
                    image: AssetImage(
                      'assets/images/kissu_location_circle.webp',
                    ),
                    color: Color(0xffFF87B2),
                    width: 8,
                    height: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    record.locationName ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF333333),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    decoration: BoxDecoration(
                      color: record.status == 'staying'
                          ? const Color(0xFFFFFFEE)
                          : Color(0xffFFF4FD),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          record.status == 'staying'
                              ? 'assets/images/kissu_track_staying.webp'
                              : 'assets/images/kissu_track_location.webp',
                          width: 24,
                          height: 24,
                          color: record.status == 'staying'
                              ? Color(0xFFBE9DFF)
                              : Color(0xFFFBAE84),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getLeftText(record),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        Spacer(),
                        Text(
                          _getRightText(record),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
