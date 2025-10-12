import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/models/unlock_record_model.dart';
import 'package:kissu_app/pages/usage_report/usage_report_controller.dart';
import '../common/unlock_record_item.dart';

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
            final data = _controller.unlockRecordData.value;
            
            // 如果没有数据，显示空状态
            if (data == null || data.records.isEmpty) {
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
                  child: _buildTitle(data),
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
                        return _buildRecordItem(data.records[index]);
                      },
                      childCount: data.records.length,
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

  /// 构建标题
  Widget _buildTitle(UnlockRecordDetailModel data) {
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
            const TextSpan(text: '解锁手机次数 '),
            TextSpan(
              text: '${data.unlockCount}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const TextSpan(text: ' 次'),
          ],
        ),
      ),
    );
  }

  /// 构建记录项（使用公共组件）
  Widget _buildRecordItem(UnlockRecordItem record) {
    return UnlockRecordItemWidget(record: record);
  }
}

