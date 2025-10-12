import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/usage_report/usage_report_controller.dart';
import '../common/generic_record_item.dart';

/// 定位/足迹异常页面
class LocationAnomalyPage extends StatefulWidget {
  const LocationAnomalyPage({super.key});

  @override
  State<LocationAnomalyPage> createState() => _LocationAnomalyPageState();
}

class _LocationAnomalyPageState extends State<LocationAnomalyPage> {
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

  /// 下拉刷新
  Future<void> _onRefresh() async {
    await _controller.loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final data = _controller.locationAnomalyData.value;
      final records = data?.data ?? [];

      if (records.isEmpty) {
        return _buildEmptyState();
      }

      return Stack(
        children: [
          // 列表内容
          RefreshIndicator(
            onRefresh: _onRefresh,
            color: const Color(0xFFFF6B9D),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 12, bottom: 80),
              itemCount: records.length,
              itemBuilder: (context, index) {
                return GenericRecordItemWidget(
                  record: records[index],
                  showSensitiveLevel: true,
                );
              },
            ),
          ),
          // 返回顶部按钮
          if (_showBackToTop)
            Positioned(
              right: 16,
              bottom: 10,
              child: GestureDetector(
                onTap: _scrollToTop,
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
                  child: Image.asset(
                    'assets/phone_history/kissu3_history_totop_icon.webp',
                    width: 20,
                    height: 20,
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  /// 空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/phone_history/kissu_phone_list_empty.webp',
            width: 120,
            height: 120,
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无定位/足迹异常记录',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

}

