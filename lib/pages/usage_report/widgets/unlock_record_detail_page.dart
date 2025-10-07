import 'package:flutter/material.dart';
import 'package:kissu_app/models/screen_time_model.dart';
import 'package:kissu_app/models/unlock_record_model.dart';
import 'simple_curve_chart.dart';
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
  late UnlockRecordDetailModel _data;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 加载数据
  void _loadData() {
    _data = _getMockData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600), // 参考敏感记录页居中显示
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 标题
              SliverToBoxAdapter(
                child: _buildTitle(),
              ),
              // 图表部分作为header
              SliverToBoxAdapter(
                child: _buildChartsSection(),
              ),
              // 记录列表
              SliverPadding(
                padding: const EdgeInsets.only(top: 12, bottom: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildRecordItem(_data.records[index]);
                    },
                    childCount: _data.records.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建标题
  Widget _buildTitle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20).copyWith(bottom: 5),
      // color: Colors.white,
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
              text: '${_data.unlockCount}',
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

  /// 构建图表区域
  Widget _buildChartsSection() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: SimpleCurveChart(
              iconPath: 'assets/phone_history/kissu3_history_time_more.webp',
              title: '解锁次数最多时段',
              timePeriod: '23-2',
              count: 24,
              data: _data.hourlyData,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: SimpleCurveChart(
              iconPath: 'assets/phone_history/kissu3_history_yichang.webp',
              title: '23点后异常时段',
              timePeriod: '23-2',
              count: 24,
              data: _data.weeklyData,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建记录项（使用公共组件）
  Widget _buildRecordItem(UnlockRecordItem record) {
    return UnlockRecordItemWidget(record: record);
  }

  /// 获取模拟数据
  UnlockRecordDetailModel _getMockData() {
    // 按小时统计数据（23-2时段，4个数据点）
    final hourlyData = [
      ChartDataPoint(label: '23', value: 8),   // 23点
      ChartDataPoint(label: '0', value: 12),   // 0点
      ChartDataPoint(label: '1', value: 18),   // 1点
      ChartDataPoint(label: '2', value: 10),   // 2点
    ];

    // 按星期统计数据（23-2时段异常数据，4个数据点）
    final weeklyData = [
      ChartDataPoint(label: '23', value: 5),   // 23点
      ChartDataPoint(label: '0', value: 15),   // 0点
      ChartDataPoint(label: '1', value: 22),   // 1点
      ChartDataPoint(label: '2', value: 8),    // 2点
    ];

    // 解锁记录列表
    final now = DateTime.now();
    final records = [
      // 样式1：单个锁定事件
      UnlockRecordItem(
        time: DateTime(now.year, now.month, now.day, 16, 0),
        action: UnlockActionType.lock,
      ),
      // 样式2：时段记录（解锁->锁定）
      UnlockRecordItem(
        time: DateTime(now.year, now.month, now.day, 17, 0),
        action: UnlockActionType.unlock,
        endTime: DateTime(now.year, now.month, now.day, 18, 0),
        movementDistance: 800,
        stayPointCount: 3,
      ),
      // 样式1：单个解锁事件
      UnlockRecordItem(
        time: DateTime(now.year, now.month, now.day, 15, 30),
        action: UnlockActionType.unlock,
      ),
      // 样式1：23:45解锁（无异常标签）
      UnlockRecordItem(
        time: DateTime(now.year, now.month, now.day - 1, 23, 45),
        action: UnlockActionType.unlock,
      ),
      // 样式2：时段记录（跨天）
      UnlockRecordItem(
        time: DateTime(now.year, now.month, now.day, 0, 10),
        action: UnlockActionType.unlock,
        endTime: DateTime(now.year, now.month, now.day, 1, 15),
        movementDistance: 1200,
        stayPointCount: 1,
      ),
      // 样式1：单个锁定事件
      UnlockRecordItem(
        time: DateTime(now.year, now.month, now.day - 1, 23, 55),
        action: UnlockActionType.lock,
      ),
      UnlockRecordItem(
        time: now.subtract(const Duration(hours: 4, minutes: 15)),
        action: UnlockActionType.lock,
      ),
      UnlockRecordItem(
        time: now.subtract(const Duration(hours: 5, minutes: 0)),
        action: UnlockActionType.unlock,
        movementDistance: 350,
      ),
      UnlockRecordItem(
        time: now.subtract(const Duration(hours: 5, minutes: 10)),
        action: UnlockActionType.lock,
        stayPointCount: 1,
      ),
    ];

    return UnlockRecordDetailModel(
      unlockCount: 66,
      hourlyData: hourlyData,
      weeklyData: weeklyData,
      records: records,
    );
  }
}

