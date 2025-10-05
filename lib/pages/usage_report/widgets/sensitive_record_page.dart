import 'package:flutter/material.dart';
import 'package:kissu_app/models/sensitive_record_model.dart';
import 'sensitive_record_item.dart';

/// 敏感记录页面内容
class SensitiveRecordPage extends StatefulWidget {
  const SensitiveRecordPage({super.key});

  @override
  State<SensitiveRecordPage> createState() => _SensitiveRecordPageState();
}

class _SensitiveRecordPageState extends State<SensitiveRecordPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false; // 是否显示返回顶部按钮
  bool _showUnreadTip = true; // 是否显示未读提示（当数据满一屏时）
  int _unreadCount = 10; // 未读数量

  // 分页相关
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  List<SensitiveRecordModel> _records = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // 初始化加载数据
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
    // 滚动超过一屏时显示返回顶部按钮
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
        // 列表内容（带下拉刷新）
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
              return SensitiveRecordItem(
                record: _records[index],
                onViewTap: () => _onViewTap(_records[index]),
              );
            },
          ),
        ),
        // 未读提示（满屏时显示）
        if (_showUnreadTip && _records.length > 5) _buildUnreadTip(),
        // 返回顶部按钮
        if (_showBackToTop) _buildBackToTopButton(),
      ],
    );
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


  /// 构建未读提示
  Widget _buildUnreadTip() {
    return Positioned(
      bottom: 5,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: () {
            // TODO: 点击查看未读记录
            setState(() {
              _showUnreadTip = false;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_unreadCount条敏感记录未查看',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFFF2958),
                  ),
                ),
                const SizedBox(width: 4),
                Image.asset(
                  'assets/phone_history/kissu3_history_list_more.webp',
                  width: 12,
                  height: 12,
                ),
              ],
            ),
          ),
        ),
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

  /// 构建加载更多Widget
  Widget _buildLoadMoreWidget() {
    if (!_hasMoreData) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            '没有更多数据了',
            style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
          ),
        ),
      );
    }

    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B9D)),
          ),
        ),
      ),
    );
  }

  /// 下拉刷新
  Future<void> _onRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _currentPage = 1;
      _hasMoreData = true;
    });

    // 模拟网络请求
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _records = _getMockData();
      _isRefreshing = false;
      _unreadCount = 10;
      _showUnreadTip = true;
    });
  }

  /// 上拉加载更多
  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    // 模拟网络请求
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _currentPage++;
      // 模拟加载更多数据
      final moreData = _getMoreMockData(_currentPage);
      if (moreData.isEmpty) {
        _hasMoreData = false;
      } else {
        _records.addAll(moreData);
      }
      _isLoadingMore = false;
    });
  }

  /// 点击查看
  void _onViewTap(SensitiveRecordModel record) {
    // TODO: 跳转到详情页
    debugPrint('点击查看: ${record.type}');
  }

  /// 获取模拟数据（第一页）
  List<SensitiveRecordModel> _getMockData() {
    final now = DateTime.now();
    return [
      SensitiveRecordModel.location(
        time: now.subtract(const Duration(hours: 0, minutes: 30)),
        duration: '2小时',
      ),
      SensitiveRecordModel.track(
        time: now.subtract(const Duration(hours: 1, minutes: 9)),
        pointCount: 3,
      ),
      SensitiveRecordModel.wifi(
        time: now.subtract(const Duration(hours: 2, minutes: 0)),
        actionType: WifiActionType.changed,
        wifiName: '家里的WiFi',
      ),
      SensitiveRecordModel.wifi(
        time: now.subtract(const Duration(hours: 2, minutes: 30)),
        actionType: WifiActionType.opened,
      ),
      SensitiveRecordModel.battery(
        time: now.subtract(const Duration(hours: 3, minutes: 0)),
        batteryLevel: 28,
        isCharging: true,
      ),
      SensitiveRecordModel.device(
        time: now.subtract(const Duration(hours: 3, minutes: 30)),
        deviceModel: 'vivo',
      ),
      SensitiveRecordModel.location(
        time: now.subtract(const Duration(hours: 4)),
        duration: '1.5小时',
      ),
      SensitiveRecordModel.track(
        time: now.subtract(const Duration(hours: 5)),
        pointCount: 5,
      ),
      SensitiveRecordModel.wifi(
        time: now.subtract(const Duration(hours: 6)),
        actionType: WifiActionType.closed,
      ),
      SensitiveRecordModel.battery(
        time: now.subtract(const Duration(hours: 7)),
        batteryLevel: 15,
        isCharging: false,
      ),
      SensitiveRecordModel.device(
        time: now.subtract(const Duration(hours: 8)),
        deviceModel: 'OPPO',
      ),
      SensitiveRecordModel.location(
        time: now.subtract(const Duration(hours: 9)),
        duration: '3小时',
      ),
      SensitiveRecordModel.track(
        time: now.subtract(const Duration(hours: 10)),
        pointCount: 8,
      ),
      SensitiveRecordModel.wifi(
        time: now.subtract(const Duration(hours: 11)),
        actionType: WifiActionType.changed,
        wifiName: '公司WiFi',
      ),
      SensitiveRecordModel.battery(
        time: now.subtract(const Duration(hours: 12)),
        batteryLevel: 85,
        isCharging: true,
      ),
    ];
  }

  /// 获取更多模拟数据（分页）
  List<SensitiveRecordModel> _getMoreMockData(int page) {
    // 模拟最多3页数据
    if (page > 3) return [];

    final now = DateTime.now();
    final baseHours = page * 12; // 每页间隔12小时

    return [
      SensitiveRecordModel.location(
        time: now.subtract(Duration(hours: baseHours + 1)),
        duration: '${page}小时',
      ),
      SensitiveRecordModel.track(
        time: now.subtract(Duration(hours: baseHours + 2)),
        pointCount: page * 2,
      ),
      SensitiveRecordModel.wifi(
        time: now.subtract(Duration(hours: baseHours + 3)),
        actionType: WifiActionType.changed,
        wifiName: 'WiFi-$page',
      ),
      SensitiveRecordModel.battery(
        time: now.subtract(Duration(hours: baseHours + 4)),
        batteryLevel: 50 + page * 10,
        isCharging: page % 2 == 0,
      ),
      SensitiveRecordModel.device(
        time: now.subtract(Duration(hours: baseHours + 5)),
        deviceModel: page % 2 == 0 ? 'iPhone' : 'Samsung',
      ),
      SensitiveRecordModel.location(
        time: now.subtract(Duration(hours: baseHours + 6)),
        duration: '${page + 1}小时',
      ),
      SensitiveRecordModel.track(
        time: now.subtract(Duration(hours: baseHours + 7)),
        pointCount: page * 3,
      ),
      SensitiveRecordModel.wifi(
        time: now.subtract(Duration(hours: baseHours + 8)),
        actionType: page % 2 == 0
            ? WifiActionType.opened
            : WifiActionType.closed,
      ),
      SensitiveRecordModel.battery(
        time: now.subtract(Duration(hours: baseHours + 9)),
        batteryLevel: 20 + page * 15,
        isCharging: page % 2 == 1,
      ),
      SensitiveRecordModel.device(
        time: now.subtract(Duration(hours: baseHours + 10)),
        deviceModel: 'Xiaomi',
      ),
    ];
  }
}
