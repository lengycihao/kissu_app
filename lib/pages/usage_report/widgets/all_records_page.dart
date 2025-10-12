import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/models/usage_record_api_model.dart';
import 'package:kissu_app/pages/usage_report/usage_report_controller.dart';
import 'package:kissu_app/pages/usage_report/common/generic_record_item.dart';

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
              padding: const EdgeInsets.only(top: 12, bottom: 80),
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

  /// 构建记录项（使用通用组件）
  Widget _buildRecordItem(RecordItem record) {
    return GenericRecordItemWidget(record: record);
  }

  /// 下拉刷新
  Future<void> _onRefresh(UsageReportController controller) async {
    await controller.loadData();
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

  /// 构建返回顶部按钮
  Widget _buildBackToTopButton() {
    return Positioned(
      right: 16,
      bottom: 100,
      child: GestureDetector(
        onTap: _scrollToTop,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
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
    );
  }
}
