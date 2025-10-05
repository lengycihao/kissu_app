import 'package:flutter/material.dart';
import 'package:kissu_app/models/sensitive_record_model.dart';
import 'package:kissu_app/models/location_anomaly_model.dart';
import 'package:kissu_app/models/unlock_record_model.dart';
import 'package:kissu_app/models/screen_time_model.dart';
import 'sensitive_record_item.dart';
import 'location_anomaly_card.dart';
import '../common/unlock_record_item.dart';
import '../common/screen_time_item.dart';

/// 全部记录页面 - 混合展示所有类型的记录
class AllRecordsPage extends StatefulWidget {
  const AllRecordsPage({super.key});

  @override
  State<AllRecordsPage> createState() => _AllRecordsPageState();
}

class _AllRecordsPageState extends State<AllRecordsPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;
  
  // 分页相关
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  List<AllRecordItem> _records = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 初始化加载数据
  void _loadInitialData() {
    _records = _getMockData();
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

    // 上拉加载更多
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMore();
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
    if (_records.isEmpty && !_isRefreshing) {
      return _buildEmptyState();
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _onRefresh,
          color: const Color(0xFFFF6B9D),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 12, bottom: 80),
            itemCount: _records.length + (_hasMoreData ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _records.length) {
                return _buildLoadMoreWidget();
              }
              return _buildRecordItem(_records[index]);
            },
          ),
        ),
        // 返回顶部按钮
        if (_showBackToTop) _buildBackToTopButton(),
      ],
    );
  }

  /// 构建记录项（根据类型显示不同的组件）
  Widget _buildRecordItem(AllRecordItem item) {
    switch (item.type) {
      case RecordType.sensitiveRecord:
        return SensitiveRecordItem(
          record: item.sensitiveRecord!,
          onViewTap: () => _onSensitiveRecordTap(item.sensitiveRecord!),
        );
      
      case RecordType.locationAnomaly:
        return LocationAnomalyCard(
          record: item.locationAnomaly!,
          onTap: () => _onLocationAnomalyTap(item.locationAnomaly!),
        );
      
      case RecordType.unlockRecord:
        return UnlockRecordItemWidget(
          record: item.unlockRecord!,
          showTimeLabel: true, // 在全部记录页面显示时间标签
        );
      
      case RecordType.screenTime:
        return ScreenTimeItemWidget(
          record: item.screenTime!,
          showTimeLabel: true, // 在全部记录页面显示时间标签
        );
    }
  }


  /// 下拉刷新
  Future<void> _onRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isRefreshing = false;
      // 重新加载数据
      _records = _getMockData();
      _hasMoreData = true;
    });
  }

  /// 加载更多
  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoadingMore = false;
      // 模拟没有更多数据
      _hasMoreData = false;
    });
  }

  /// 构建加载更多组件
  Widget _buildLoadMoreWidget() {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B9D)),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
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

  /// 点击敏感记录
  void _onSensitiveRecordTap(SensitiveRecordModel record) {
    debugPrint('查看敏感记录详情: ${record.type}');
  }

  /// 点击定位异常
  void _onLocationAnomalyTap(LocationAnomalyModel record) {
    debugPrint('查看定位异常详情');
  }

  /// 获取模拟数据 - 展示所有类型的记录
  List<AllRecordItem> _getMockData() {
    final now = DateTime.now();
    
    return [
      // ===== 敏感记录类型（5种） =====
      
      // 1. 敏感记录 - 定位类型
      AllRecordItem(
        type: RecordType.sensitiveRecord,
        time: DateTime(now.year, now.month, now.day, 16, 30),
        sensitiveRecord: SensitiveRecordModel.location(
          time: DateTime(now.year, now.month, now.day, 16, 30),
          duration: '2小时',
        ),
      ),
      
      // 2. 敏感记录 - 轨迹类型
      AllRecordItem(
        type: RecordType.sensitiveRecord,
        time: DateTime(now.year, now.month, now.day, 15, 45),
        sensitiveRecord: SensitiveRecordModel.track(
          time: DateTime(now.year, now.month, now.day, 15, 45),
          pointCount: 5,
        ),
      ),
      
      // 3. 敏感记录 - WiFi类型
      AllRecordItem(
        type: RecordType.sensitiveRecord,
        time: DateTime(now.year, now.month, now.day, 15, 15),
        sensitiveRecord: SensitiveRecordModel.wifi(
          time: DateTime(now.year, now.month, now.day, 15, 15),
          actionType: WifiActionType.changed,
          wifiName: 'Home-WiFi',
        ),
      ),
      
      // 4. 敏感记录 - 电量类型
      AllRecordItem(
        type: RecordType.sensitiveRecord,
        time: DateTime(now.year, now.month, now.day, 14, 50),
        sensitiveRecord: SensitiveRecordModel.battery(
          time: DateTime(now.year, now.month, now.day, 14, 50),
          batteryLevel: 15,
          isCharging: true,
        ),
      ),
      
      // 5. 敏感记录 - 设备类型
      AllRecordItem(
        type: RecordType.sensitiveRecord,
        time: DateTime(now.year, now.month, now.day, 14, 20),
        sensitiveRecord: SensitiveRecordModel.device(
          time: DateTime(now.year, now.month, now.day, 14, 20),
          deviceModel: 'iPhone 14 Pro',
        ),
      ),
      
      // ===== 定位/足迹异常类型（2种） =====
      
      // 6. 定位异常 - 停留点
      AllRecordItem(
        type: RecordType.locationAnomaly,
        time: DateTime(now.year, now.month, now.day, 14, 0),
        locationAnomaly: LocationAnomalyModel(
          id: 'loc_001',
          type: LocationAnomalyType.stay,
          locationName: '北京市朝阳区建外SOHO',
          timeRange: '14:00-15:30',
          latitude: 39.9042,
          longitude: 116.4074,
          avatarUrl: 'https://via.placeholder.com/40',
        ),
      ),
      
      // 7. 定位异常 - 疑似更改手机定位
      AllRecordItem(
        type: RecordType.locationAnomaly,
        time: DateTime(now.year, now.month, now.day, 13, 30),
        locationAnomaly: LocationAnomalyModel(
          id: 'loc_002',
          type: LocationAnomalyType.yishi,
          locationName: '',
          timeRange: '13:30',
          latitude: 0,
          longitude: 0,
          avatarUrl: 'https://via.placeholder.com/40',
        ),
      ),
      
      // ===== 解锁记录类型（2种） =====
      
      // 8. 解锁记录 - 单个解锁操作
      AllRecordItem(
        type: RecordType.unlockRecord,
        time: DateTime(now.year, now.month, now.day, 13, 15),
        unlockRecord: UnlockRecordItem(
          time: DateTime(now.year, now.month, now.day, 13, 15),
          action: UnlockActionType.unlock,
          movementDistance: 1200,
          stayPointCount: 3,
        ),
      ),
      
      // 9. 解锁记录 - 时段记录（解锁->锁定）
      AllRecordItem(
        type: RecordType.unlockRecord,
        time: DateTime(now.year, now.month, now.day, 10, 30),
        unlockRecord: UnlockRecordItem(
          time: DateTime(now.year, now.month, now.day, 10, 30),
          action: UnlockActionType.unlock,
          endTime: DateTime(now.year, now.month, now.day, 11, 45),
          movementDistance: 800,
          stayPointCount: 2,
        ),
      ),
      
      // ===== 屏幕使用时长类型（1种） =====
      
      // 10. 屏幕使用时长 - 正常记录
      AllRecordItem(
        type: RecordType.screenTime,
        time: DateTime(now.year, now.month, now.day, 9, 0),
        screenTime: ScreenTimeRecordItem(
          startTime: DateTime(now.year, now.month, now.day, 9, 0),
          endTime: DateTime(now.year, now.month, now.day, 11, 0),
          durationMinutes: 120,
        ),
      ),
    ];
  }
}

/// 记录类型枚举
enum RecordType {
  sensitiveRecord, // 敏感记录
  locationAnomaly, // 定位/足迹异常
  unlockRecord, // 解锁记录
  screenTime, // 屏幕使用时长
}

/// 全部记录项的统一模型（用于混合展示）
class AllRecordItem {
  final RecordType type;
  final DateTime time; // 用于排序
  final SensitiveRecordModel? sensitiveRecord;
  final LocationAnomalyModel? locationAnomaly;
  final UnlockRecordItem? unlockRecord;
  final ScreenTimeRecordItem? screenTime;

  AllRecordItem({
    required this.type,
    required this.time,
    this.sensitiveRecord,
    this.locationAnomaly,
    this.unlockRecord,
    this.screenTime,
  });
}
/// 虚线绘制器

