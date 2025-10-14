import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/models/unlock_record_model.dart';
import 'package:kissu_app/models/usage_record_api_model.dart';
import 'package:kissu_app/pages/usage_report/usage_report_controller.dart';
import '../common/unlock_record_item.dart';
import '../common/type19_unlock_record_item.dart';
import '../common/generic_record_item.dart';

/// 解锁记录详情页面
class UnlockRecordDetailPage extends StatefulWidget {
  const UnlockRecordDetailPage({super.key});

  @override
  State<UnlockRecordDetailPage> createState() =>
      _UnlockRecordDetailPageState();
}

class _UnlockRecordDetailPageState extends State<UnlockRecordDetailPage> {
  final ScrollController _scrollController = ScrollController();
  final UsageReportController _controller = Get.find<UsageReportController>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Obx(() {
            final controller = Get.find<UsageReportController>();
            
            // 检查是否所有敏感度筛选都未选中
            final hasNoSensitiveLevelSelected = !controller.filterHighSensitive.value && 
                                               !controller.filterMediumSensitive.value && 
                                               !controller.filterLowSensitive.value;
            
            if (hasNoSensitiveLevelSelected) {
              return _buildNoSensitiveLevelSelectedState();
            }
            
            // 获取所有解锁相关的记录（14、15、19类型）
            final allUnlockRecords = _getAllUnlockRecords();
            final unlockCount = _getUnlockCount();
            
            // 如果没有数据，显示空状态
            if (allUnlockRecords.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_open, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      '暂无解锁记录',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }
            
            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                // 标题
                SliverToBoxAdapter(
                  child: _buildTitleWithCount(unlockCount),
                ),
                // 图表部分作为header（图表数据暂时为空，接口还没做好）
                // SliverToBoxAdapter(
                //   child: _buildChartsSection(data),
                // ),
                // 记录列表
                SliverPadding(
                  padding: const EdgeInsets.only(top: 12, bottom: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildMixedRecordItem(allUnlockRecords[index]);
                      },
                      childCount: allUnlockRecords.length,
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }


  /// 获取所有解锁相关的记录（14、15、19类型）
  List<dynamic> _getAllUnlockRecords() {
    final allRecords = <dynamic>[];
    
    // 从全部记录中获取14、15类型的RecordItem
    final allRecordData = _controller.allRecordData.value;
    if (allRecordData != null) {
      final unlockRelatedRecords = allRecordData.data.where((record) => 
        record.eventType == 14 || record.eventType == 15 || record.eventType == 19
      ).toList();
      
      // 按时间排序（最新的在前）
      unlockRelatedRecords.sort((a, b) => b.createTime.compareTo(a.createTime));
      allRecords.addAll(unlockRelatedRecords);
    }
    
    return allRecords;
  }
  
  /// 获取解锁次数
  int _getUnlockCount() {
    final unlockData = _controller.unlockRecordData.value;
    return unlockData?.unlockCount ?? 0;
  }
  
  /// 构建标题（带解锁次数）
  Widget _buildTitleWithCount(int unlockCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20).copyWith(bottom: 5),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF333333),
            height: 1.5,
          ),
          children: [
            const TextSpan(text: '解锁手机次数 ', style: TextStyle(fontSize: 14, color: Color(0xFF333333))),
            TextSpan(
              text: '$unlockCount',
              style: const TextStyle(
                fontSize: 16,color: Color(0xFF333333),
                fontWeight: FontWeight.w600,
              ),
            ),
            const TextSpan(text: ' 次', style: TextStyle(fontSize: 14, color: Color(0xFF333333))),
          ],
        ),
      ),
    );
  }
  
  /// 构建混合记录项（根据类型选择不同组件）
  Widget _buildMixedRecordItem(dynamic record) {
    if (record is RecordItem) {
      // 14、15类型使用GenericRecordItemWidget（参考其他类型的样式）
      if (record.eventType == 14 || record.eventType == 15) {
        return GenericRecordItemWidget(
          record: record,
          showTimeLabel: false, // 解锁记录页面不显示时间标签
          onVipStatusChanged: () {
            // 解锁记录页面需要刷新混合记录数据
            // 这里可以通过回调通知父页面刷新
          },
        );
      }
      
      // 19类型转换为UnlockRecordItem并使用Type19组件
      if (record.eventType == 19) {
        final unlockRecord = _convertToUnlockRecord(record);
        return Type19UnlockRecordItemWidget(
          record: unlockRecord,
          showTimeLabel: false, // 解锁记录页面不显示时间标签
          onVipStatusChanged: () {
            // 解锁记录页面需要刷新混合记录数据
            // 这里可以通过回调通知父页面刷新
          },
        );
      }
    }
    
    // 兜底：如果是UnlockRecordItem，使用原来的逻辑
    if (record is UnlockRecordItem) {
      return _buildRecordItem(record);
    }
    
    return const SizedBox.shrink();
  }
  
  /// 将RecordItem转换为UnlockRecordItem（用于19类型）
  UnlockRecordItem _convertToUnlockRecord(RecordItem record) {
    // 解析时间
    final time = DateTime.tryParse(record.createTime) ?? DateTime.now();
    
    // 解析ext字段中的数据
    final unlockTimeStr = record.ext['unlock_time'] as String?;
    final lockTimeStr = record.ext['lock_time'] as String?;
    final moveDistanceStr = record.ext['move_distance'] as String?;
    final stayNumberStr = record.ext['stay_number'] as String?;
    
    // 解析解锁时间和锁定时间
    DateTime? unlockTime;
    DateTime? lockTime;
    
    if (unlockTimeStr != null) {
      // 如果ext中的时间是HH:mm格式，需要结合当前日期
      if (unlockTimeStr.contains(':') && !unlockTimeStr.contains('-')) {
        final timeParts = unlockTimeStr.split(':');
        if (timeParts.length == 2) {
          final hour = int.tryParse(timeParts[0]) ?? 0;
          final minute = int.tryParse(timeParts[1]) ?? 0;
          unlockTime = DateTime(time.year, time.month, time.day, hour, minute);
        }
      } else {
        unlockTime = DateTime.tryParse(unlockTimeStr);
      }
    }
    
    if (lockTimeStr != null) {
      // 如果ext中的时间是HH:mm格式，需要结合当前日期
      if (lockTimeStr.contains(':') && !lockTimeStr.contains('-')) {
        final timeParts = lockTimeStr.split(':');
        if (timeParts.length == 2) {
          final hour = int.tryParse(timeParts[0]) ?? 0;
          final minute = int.tryParse(timeParts[1]) ?? 0;
          lockTime = DateTime(time.year, time.month, time.day, hour, minute);
        }
      } else {
        lockTime = DateTime.tryParse(lockTimeStr);
      }
    }
    
    // 解析移动距离（去除单位"m"或"米"）
    double? moveDistance;
    if (moveDistanceStr != null) {
      final distanceNum = moveDistanceStr.replaceAll(RegExp(r'[^\d.]'), '');
      moveDistance = double.tryParse(distanceNum);
    }
    
    // 解析停留点数量
    final stayNumber = stayNumberStr != null ? int.tryParse(stayNumberStr) : null;
    
    return UnlockRecordItem(
      time: unlockTime ?? time,
      action: UnlockActionType.unlock,
      endTime: lockTime,
      movementDistance: moveDistance,
      stayPointCount: stayNumber,
      icon: record.icon,
      eventType: record.eventType,
    );
  }

  /// 构建记录项（根据eventType选择组件）
  Widget _buildRecordItem(UnlockRecordItem record) {
    // 类型19（解锁记录）使用专门的类型19组件
    if (record.eventType == 19) {
      return Type19UnlockRecordItemWidget(
        record: record,
        showTimeLabel: true, // 解锁记录页面显示时间标签
      );
    }
    
    // 其他类型使用普通解锁记录组件
    return UnlockRecordItemWidget(record: record);
  }

  /// 构建未选择敏感度筛选的状态
  Widget _buildNoSensitiveLevelSelectedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/phone_history/kissu_phone_list_empty.webp', width: 128, height: 128),
          const SizedBox(height: 16),
          const Text(
            '请选择敏感度筛选条件',
            style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 8),
          const Text(
            '在右上角筛选中选择高敏感、中敏感或低敏感',
            style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC)),
          ),
        ],
      ),
    );
  }
}

