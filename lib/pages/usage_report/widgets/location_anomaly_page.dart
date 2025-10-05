import 'package:flutter/material.dart';
import 'package:kissu_app/models/location_anomaly_model.dart';
import 'location_anomaly_card.dart';
import 'location_anomaly_detail_page.dart';

/// 定位/足迹异常页面
class LocationAnomalyPage extends StatefulWidget {
  const LocationAnomalyPage({super.key});

  @override
  State<LocationAnomalyPage> createState() => _LocationAnomalyPageState();
}

class _LocationAnomalyPageState extends State<LocationAnomalyPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

  // 分页相关
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  List<LocationAnomalyModel> _records = [];

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

  /// 下拉刷新
  Future<void> _onRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    // 模拟网络请求
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _currentPage = 1;
      _records = _getMockData();
      _hasMoreData = true;
      _isRefreshing = false;
    });
  }

  /// 加载更多
  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    // 模拟网络请求
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _currentPage++;
      // 模拟最多3页
      if (_currentPage >= 3) {
        _hasMoreData = false;
      } else {
        _records.addAll(_getMockData());
      }
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_records.isEmpty && !_isRefreshing) {
      return _buildEmptyState();
    }

    return Stack(
      children: [
        // 列表内容（优化性能配置）
        RefreshIndicator(
          onRefresh: _onRefresh,
          color: const Color(0xFFFF6B9D),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 12, bottom: 80),
            itemCount: _records.length + (_hasMoreData ? 1 : 0),
            // 性能优化配置
            addAutomaticKeepAlives: true, // 保持列表项状态，避免重复构建地图
            addRepaintBoundaries: true, // 隔离重绘边界，提升滚动性能
            cacheExtent: 200, // 缓存可见区域外200px的内容
            itemBuilder: (context, index) {
              if (index == _records.length) {
                return _buildLoadMoreWidget();
              }
              return LocationAnomalyCard(
                key: ValueKey(_records[index].id), // 添加key保持状态
                record: _records[index],
                onTap: () => _onCardTap(_records[index]),
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

  /// 加载更多提示
  Widget _buildLoadMoreWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: _isLoadingMore
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B9D)),
              ),
            )
          : const Text(
              '已加载全部',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF999999),
              ),
            ),
    );
  }

  /// 卡片点击
  void _onCardTap(LocationAnomalyModel record) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LocationAnomalyDetailPage(record: record),
      ),
    );
  }

  /// 获取模拟数据
  List<LocationAnomalyModel> _getMockData() {
    return [
      // 停留点类型
      LocationAnomalyModel(
        id: '1',
        locationName: '浙江杭州上城区解放路',
        latitude: 31.239668,
        longitude: 121.499809,
        timeRange: '14:30-17:12',
        type: LocationAnomalyType.stay,
        avatarUrl: 'https://via.placeholder.com/100',
      ),
      // 疑似异常点 - 速度异常
      LocationAnomalyModel(
        id: '2',
        locationName: '上海市静安区南京西路1000号',
        latitude: 31.228416,
        longitude: 121.448468,
        timeRange: '10:15-11:45',
        type: LocationAnomalyType.exception,
        exceptionSubType: ExceptionSubType.speed,
        avatarUrl: 'https://via.placeholder.com/100',
      ),
      // 疑似异常点 - 停留时长异常
      LocationAnomalyModel(
        id: '3',
        locationName: '上海市徐汇区衡山路8号',
        latitude: 31.210344,
        longitude: 121.437356,
        timeRange: '18:20-19:50',
        type: LocationAnomalyType.exception,
        exceptionSubType: ExceptionSubType.stayDuration,
        avatarUrl: 'https://via.placeholder.com/100',
      ),
      // 停留点类型
      LocationAnomalyModel(
        id: '4',
        locationName: '北京市朝阳区建国门外大街',
        latitude: 31.221461,
        longitude: 121.418965,
        timeRange: '15:00-16:30',
        type: LocationAnomalyType.stay,
        avatarUrl: 'https://via.placeholder.com/100',
      ),
      // 疑似更改手机定位
      LocationAnomalyModel(
        id: '5',
        locationName: '疑似更改手机定位',
        latitude: 31.271591,
        longitude: 121.480237,
        timeRange: '12:00-13:00',
        type: LocationAnomalyType.yishi,
        avatarUrl: 'https://via.placeholder.com/100',
      ),
    ];
  }
}

