import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/usage_report/usage_report_controller.dart';
import '../common/generic_record_item.dart';

/// 敏感记录页面内容
class SensitiveRecordPage extends StatefulWidget {
  const SensitiveRecordPage({super.key});

  @override
  State<SensitiveRecordPage> createState() => _SensitiveRecordPageState();
}

class _SensitiveRecordPageState extends State<SensitiveRecordPage> {
  final ScrollController _scrollController = ScrollController();
  final UsageReportController _controller = Get.find<UsageReportController>();
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
    return Obx(() {
      // 检查是否所有敏感度筛选都未选中
      final hasNoSensitiveLevelSelected = !_controller.filterHighSensitive.value && 
                                         !_controller.filterMediumSensitive.value && 
                                         !_controller.filterLowSensitive.value;
      
      if (hasNoSensitiveLevelSelected) {
        return _buildNoSensitiveLevelSelectedState();
      }
      
      final data = _controller.sensitiveRecordData.value;
      final records = data?.data ?? [];

      if (records.isEmpty) {
        return _buildEmptyState();
      }

      return Stack(
        children: [
          // 列表内容（带下拉刷新）
          RefreshIndicator(
            onRefresh: _onRefresh,
            color: const Color(0xFFFF6B9D),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 12, bottom: 20),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                final params = _getRecordParams(record.eventType);
                
    return GenericRecordItemWidget(
      record: record,
      showTimeLabel: true, // 显示时间标签
      showSensitiveLevel: true, // 显示敏感等级标签
      onVipStatusChanged: () => _controller.loadData(), // VIP状态变化时刷新数据
      backgroundGradientColors: params['colors'],
      backgroundWidth: params['width'],
      backgroundText: params['text'],
      backgroundImage: params['backgroundImage'],
    );
              },
            ),
          ),
          // 返回顶部按钮
          if (_showBackToTop) _buildBackToTopButton(),
        ],
      );
    });
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/phone_history/kissu_phone_list_empty.webp', width: 128, height: 128),
          const SizedBox(height: 16),
          const Text(
            '暂无敏感记录',
            style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
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
      bottom: 10,
      right: 16,
      child: GestureDetector(
        onTap: _scrollToTop,
        child: Image.asset(
          'assets/phone_history/kissu3_history_totop_icon.webp',
          width: 48,
          height: 48,
        ),
      ),
    );
  }

  /// 下拉刷新
  Future<void> _onRefresh() async {
    await _controller.loadData();
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
          'text': '疑似定位异常',
          'backgroundImage': null,
        };
      case 20:
        return {
          'colors': [const Color(0xFFFF6262), const Color(0xFFFF9B65)],
          'width': 105.0,
          'text': '疑似异常点',
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
}
