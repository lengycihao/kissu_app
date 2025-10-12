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
              padding: const EdgeInsets.only(top: 12, bottom: 80),
              itemCount: records.length,
              itemBuilder: (context, index) {
                return GenericRecordItemWidget(
                  record: records[index],
                  showSensitiveLevel: true, // 显示敏感等级标签
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
          Image.asset('assets/kissu_empty_icon.webp', width: 120, height: 120),
          const SizedBox(height: 16),
          const Text(
            '暂无敏感记录',
            style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
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
}
