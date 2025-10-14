import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/models/usage_record_api_model.dart';
import 'package:kissu_app/pages/usage_report/usage_report_controller.dart';
import 'package:kissu_app/pages/usage_report/common/generic_record_item.dart';
import 'package:kissu_app/pages/usage_report/common/type19_unlock_record_item.dart';
import 'package:kissu_app/models/unlock_record_model.dart';

/// 全部记录页面 - 混合展示所有类型的记录
class AllRecordsPage extends StatefulWidget {
  const AllRecordsPage({super.key});

  @override
  State<AllRecordsPage> createState() => _AllRecordsPageState();
}

class _AllRecordsPageState extends State<AllRecordsPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 监听滚动
  void _onScroll() {
    if (_scrollController.offset > 300 && !_showBackToTop) {
      setState(() {
        _showBackToTop = true;
      });
    } else if (_scrollController.offset <= 300 && _showBackToTop) {
      setState(() {
        _showBackToTop = false;
      });
    }
  }

  /// 返回顶部
  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UsageReportController>();
    
    return Obx(() {
      // 检查是否所有敏感度筛选都未选中
      final hasNoSensitiveLevelSelected = !controller.filterHighSensitive.value && 
                                         !controller.filterMediumSensitive.value && 
                                         !controller.filterLowSensitive.value;
      
      if (hasNoSensitiveLevelSelected) {
        return _buildNoSensitiveLevelSelectedState();
      }
      
      final allRecord = controller.allRecordData.value;
      final isLoading = controller.isLoading.value;
      
      // 加载中
      if (isLoading && allRecord == null) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B9D)),
          ),
        );
      }
      
      // 空状态
      if (allRecord == null || allRecord.data.isEmpty) {
        return _buildEmptyState();
      }
      
      // 有数据
      return Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => _onRefresh(controller),
            color: const Color(0xFFFF6B9D),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 12, bottom: 20),
              itemCount: allRecord.data.length,
              itemBuilder: (context, index) {
                return _buildRecordItem(allRecord.data[index]);
              },
            ),
          ),
          // 返回顶部按钮
          if (_showBackToTop) _buildBackToTopButton(),
        ],
      );
    });
  }

  /// 构建记录项（根据类型使用不同组件）
  Widget _buildRecordItem(RecordItem record) {
    // 类型19（解锁记录）使用专门的类型19组件
    if (record.eventType == 19) {
      final unlockRecord = _convertToUnlockRecord(record);
      return Type19UnlockRecordItemWidget(
        record: unlockRecord,
        showTimeLabel: true,
        onVipStatusChanged: () => Get.find<UsageReportController>().loadData(), // VIP状态变化时刷新数据
      );
    }
    
    // 其他类型使用通用组件
    final params = _getRecordParams(record.eventType);
    
    return GenericRecordItemWidget(
      record: record,
      showTimeLabel: true, // 显示时间标签
      onVipStatusChanged: () => Get.find<UsageReportController>().loadData(), // VIP状态变化时刷新数据
      backgroundGradientColors: params['colors'],
      backgroundWidth: params['width'],
      backgroundText: params['text'],
      backgroundImage: params['backgroundImage'],
    );
  }

  /// 将RecordItem转换为UnlockRecordItem
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
      unlockTime = DateTime.tryParse(unlockTimeStr);
    }
    if (lockTimeStr != null) {
      lockTime = DateTime.tryParse(lockTimeStr);
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
      endTime: lockTime ?? time, // 确保有endTime，这样isPeriodRecord为true
      movementDistance: moveDistance,
      stayPointCount: stayNumber,
      icon: record.icon,
    );
  }

  /// 下拉刷新
  Future<void> _onRefresh(UsageReportController controller) async {
    await controller.loadData();
  }

  /// 根据eventType获取记录参数
  Map<String, dynamic> _getRecordParams(int eventType) {
    switch (eventType) {
      case 17:
        return {
          'colors': [const Color(0xFF3B96FF), const Color(0xFF718DFF)],
          'width': 70.0,
          'text': '标记点',
          'backgroundImage': null,
        };
      case 18:
        return {
          'colors': [const Color(0xFF3B96FF), const Color(0xFF718DFF)],
          'width': 70.0,
          'text': '标记点',
          'backgroundImage': 'assets/phone_history/kissu3_history_blue_map.webp',
        };
      case 9:
        return {
          'colors': [const Color(0xFFFF6262), const Color(0xFFFF9B65)],
          'width': 88.0,
          'text': '疑似异常点',
          'backgroundImage': null,
        };
      case 20:
        return {
          'colors': [const Color(0xFFFF6262), const Color(0xFFFF9B65)],
          'width': 105.0,
          'text': '疑似定位异常',
          'backgroundImage': null,
        };
      default:
        return {
          'colors': null,
          'width': null,
          'text': null,
          'backgroundImage': null,
        };
    }
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无记录',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
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

  /// 构建返回顶部按钮
  Widget _buildBackToTopButton() {
    return Positioned(
      right: 16,
      bottom: 100,
      child: GestureDetector(
        onTap: _scrollToTop,
        child: Image.asset(
          'assets/phone_history/kissu3_history_totop_icon.webp',
          width: 44,
          height: 44,
        ),
      ),
    );
  }
}
