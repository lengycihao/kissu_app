import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/utils/oaid_util.dart';
import 'analytics_event_model.dart';
import 'analytics_params.dart';

/// 埋点管理器
/// 负责事件收集、缓存、批量上报等核心功能
class AnalyticsManager extends GetxService {
  static AnalyticsManager get instance => Get.find<AnalyticsManager>();

  /// 缓存的事件列表
  final List<AnalyticsEvent> _eventQueue = [];

  /// 本地持久化key
  static const String _cacheKey = 'analytics_event_cache';

  /// 批量上报阈值（达到此数量触发上报）
  static const int _batchThreshold = 10;

  /// 定时上报间隔（秒）
  static const int _reportIntervalSeconds = 60;

  /// 上报定时器
  Timer? _reportTimer;

  /// 是否正在上报
  bool _isReporting = false;

  /// 虚拟用户ID缓存
  String? _mockUserId;

  /// 是否已初始化
  bool _isInitialized = false;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onClose() {
    _reportTimer?.cancel();
    _flushToLocal();
    super.onClose();
  }

  /// 初始化
  Future<void> _initialize() async {
    if (_isInitialized) return;

    // 从本地恢复缓存的事件
    await _restoreFromLocal();

    // 获取虚拟用户ID
    await _initMockUserId();

    // 启动定时上报
    _startReportTimer();

    _isInitialized = true;
    debugPrint('📊 AnalyticsManager 初始化完成');
  }

  /// 初始化虚拟用户ID
  Future<void> _initMockUserId() async {
    try {
      _mockUserId = await OaidUtil.instance.getOaid();
    } catch (e) {
      debugPrint('❌ 获取虚拟用户ID失败: $e');
    }
  }

  /// 启动定时上报
  void _startReportTimer() {
    _reportTimer?.cancel();
    _reportTimer = Timer.periodic(
      const Duration(seconds: _reportIntervalSeconds),
      (_) => _flushEvents(),
    );
  }

  /// 记录事件
  /// 
  /// [pageId] 页面ID
  /// [eventId] 事件ID
  /// [params] 自定义参数（会自动合并公共参数）
  void trackEvent({
    required String pageId,
    required String eventId,
    Map<String, dynamic>? params,
  }) {
    final mergedParams = _buildParams(params);
    final event = AnalyticsEvent(
      pageId: pageId,
      eventId: eventId,
      params: mergedParams,
    );

    _eventQueue.add(event);
    debugPrint('📊 记录事件: $eventId, 队列长度: ${_eventQueue.length}');

    // 达到阈值触发上报
    if (_eventQueue.length >= _batchThreshold) {
      _flushEvents();
    }
  }

  /// 记录页面浏览事件
  /// 
  /// [pageId] 页面ID
  /// [eventId] 事件ID
  /// [enterTime] 进入时间
  /// [duration] 停留时长（格式：mm:ss）
  /// [sourcePage] 来源页
  /// [exitType] 离开方式
  /// [params] 其他自定义参数
  void trackPageView({
    required String pageId,
    required String eventId,
    required String enterTime,
    required String duration,
    String? sourcePage,
    String? exitType,
    Map<String, dynamic>? params,
  }) {
    final pageParams = <String, dynamic>{
      AnalyticsParams.pageEnterTime: enterTime,
      AnalyticsParams.pageDuration: duration,
      if (sourcePage != null) AnalyticsParams.sourcePage: sourcePage,
      if (exitType != null) AnalyticsParams.exitType: exitType,
      ...?params,
    };

    trackEvent(
      pageId: pageId,
      eventId: eventId,
      params: pageParams,
    );
  }

  /// 记录点击事件
  /// 
  /// [pageId] 页面ID
  /// [eventId] 事件ID
  /// [btnName] 按钮名称（可选）
  /// [params] 其他自定义参数
  void trackClick({
    required String pageId,
    required String eventId,
    String? btnName,
    Map<String, dynamic>? params,
  }) {
    final clickParams = <String, dynamic>{
      AnalyticsParams.clickTime: _formatClickTime(DateTime.now()),
      if (btnName != null) AnalyticsParams.btnName: btnName,
      ...?params,
    };

    trackEvent(
      pageId: pageId,
      eventId: eventId,
      params: clickParams,
    );
  }

  /// 构建完整参数（合并公共参数）
  Map<String, dynamic> _buildParams(Map<String, dynamic>? customParams) {
    final params = <String, dynamic>{};

    // 添加虚拟用户ID
    if (_mockUserId != null) {
      params[AnalyticsParams.mockUserId] = _mockUserId;
    }

    // 添加用户ID
    final userId = UserManager.userId;
    if (userId != null) {
      params[AnalyticsParams.userId] = userId;
    }

    // 添加会员状态
    params[AnalyticsParams.vipStatus] = _getVipStatus();

    // 添加绑定状态
    params[AnalyticsParams.bindStatus] = _getBindStatus();

    // 添加绑定次数
    params[AnalyticsParams.bindNum] = _getBindNum();

    // 添加188活动参与状态
    params[AnalyticsParams.action188] = _getAction188Status();

    // 合并自定义参数（自定义参数优先级更高）
    if (customParams != null) {
      params.addAll(customParams);
    }

    return params;
  }

  /// 获取会员状态文本
  String _getVipStatus() {
    if (!UserManager.isLoggedIn) return VipStatusValue.notPaid;
    
    if (UserManager.isVip) {
      return VipStatusValue.active;
    }
    
    // 检查是否曾经是会员（已过期）
    final vipEndDate = UserManager.vipEndDate;
    if (vipEndDate != null && vipEndDate.isNotEmpty) {
      try {
        final endDate = DateTime.parse(vipEndDate);
        if (endDate.isBefore(DateTime.now())) {
          return VipStatusValue.expired;
        }
      } catch (_) {}
    }
    
    return VipStatusValue.notPaid;
  }

  /// 获取绑定状态文本
  String _getBindStatus() {
    if (!UserManager.isLoggedIn) return BindStatusValue.notBound;
    
    final user = UserManager.currentUser;
    if (user == null) return BindStatusValue.notBound;
    
    final bindStatus = user.bindStatus;
    switch (bindStatus) {
      case 1:
        return BindStatusValue.bound;
      case 2:
        return BindStatusValue.unbound;
      default:
        return BindStatusValue.notBound;
    }
  }

  /// 获取绑定次数
  int _getBindNum() {
    if (!UserManager.isLoggedIn) return 0;
    // LoginModel中没有bindNum字段，暂时返回0
    // TODO: 根据实际业务逻辑获取绑定次数
    return 0;
  }

  /// 获取188活动参与状态
  String _getAction188Status() {
    // TODO: 根据实际业务逻辑获取188活动参与状态
    return Action188Value.notParticipated;
  }

  /// 格式化点击时间（格式：年/月/日 时:分:秒）
  String _formatClickTime(DateTime dateTime) {
    final year = dateTime.year;
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$year/$month/$day $hour:$minute:$second';
  }

  /// 触发事件上报
  Future<void> _flushEvents() async {
    if (_isReporting || _eventQueue.isEmpty) return;

    _isReporting = true;
    debugPrint('📊 开始上报事件，数量: ${_eventQueue.length}');

    try {
      // 取出待上报的事件
      final eventsToReport = List<AnalyticsEvent>.from(_eventQueue);
      
      // 调用上报接口
      final success = await _reportEvents(eventsToReport);
      
      if (success) {
        // 上报成功，清除已上报的事件
        _eventQueue.removeWhere((e) => eventsToReport.contains(e));
        debugPrint('📊 事件上报成功，剩余: ${_eventQueue.length}');
      } else {
        // 上报失败，保存到本地
        await _flushToLocal();
        debugPrint('📊 事件上报失败，已保存到本地');
      }
    } catch (e) {
      debugPrint('❌ 事件上报异常: $e');
      await _flushToLocal();
    } finally {
      _isReporting = false;
    }
  }

  /// 上报事件到服务器
  /// 
  /// TODO: 接口出来后实现具体的上报逻辑
  Future<bool> _reportEvents(List<AnalyticsEvent> events) async {
    // 构建请求数据
    final request = AnalyticsBatchRequest(
      events: events,
      appVersion: await _getAppVersion(),
    );

    debugPrint('📊 上报数据: ${jsonEncode(request.toJson())}');

    // TODO: 调用实际的上报接口
    // final response = await HttpManagerN.post(
    //   url: '/api/analytics/report',
    //   jsonParams: request.toJson(),
    // );
    // return response.isSuccess;

    // 暂时返回true，模拟上报成功
    return true;
  }

  /// 获取应用版本
  Future<String?> _getAppVersion() async {
    // TODO: 从AppInfoService获取版本号
    return null;
  }

  /// 保存事件到本地
  Future<void> _flushToLocal() async {
    if (_eventQueue.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _eventQueue.map((e) => e.toJsonString()).toList();
      await prefs.setStringList(_cacheKey, jsonList);
      debugPrint('📊 已保存 ${_eventQueue.length} 个事件到本地');
    } catch (e) {
      debugPrint('❌ 保存事件到本地失败: $e');
    }
  }

  /// 从本地恢复事件
  Future<void> _restoreFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_cacheKey);
      
      if (jsonList != null && jsonList.isNotEmpty) {
        for (final jsonString in jsonList) {
          try {
            final event = AnalyticsEvent.fromJsonString(jsonString);
            _eventQueue.add(event);
          } catch (e) {
            debugPrint('❌ 解析缓存事件失败: $e');
          }
        }
        
        // 清除本地缓存
        await prefs.remove(_cacheKey);
        debugPrint('📊 从本地恢复 ${_eventQueue.length} 个事件');
      }
    } catch (e) {
      debugPrint('❌ 从本地恢复事件失败: $e');
    }
  }

  /// 强制立即上报所有事件
  Future<void> forceFlush() async {
    await _flushEvents();
  }

  /// 获取当前队列中的事件数量
  int get pendingEventCount => _eventQueue.length;

  /// 清空所有事件（谨慎使用）
  void clearAllEvents() {
    _eventQueue.clear();
    debugPrint('📊 已清空所有待上报事件');
  }
}
