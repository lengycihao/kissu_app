import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/utils/oaid_util.dart';
import 'package:kissu_app/network/public/analytics_api.dart';
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
  static const int _reportIntervalSeconds = 5;

  /// 上报定时器
  Timer? _reportTimer;

  /// 是否正在上报
  bool _isReporting = false;

  /// 虚拟用户ID缓存
  String? _mockUserId;

  /// 是否已初始化
  bool _isInitialized = false;

  /// 本地测试模式（开启后将埋点写入log.txt而不是上报到服务器）
  static const bool _localTestMode = false;

  /// 埋点上传 API
  final _analyticsApi = AnalyticsApi();

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

    // 🔒 隐私合规：不在初始化时获取OAID，等待用户同意隐私政策后再获取
    // await _initMockUserId(); // 移除：OAID获取延迟到用户同意隐私政策后

    // 启动定时上报
    _startReportTimer();

    _isInitialized = true;
    debugPrint('📊 AnalyticsManager 初始化完成（OAID将在隐私政策同意后获取）');
  }

  /// 初始化虚拟用户ID（在用户同意隐私政策后调用）
  /// 🔒 隐私合规：只有在用户同意隐私政策后才获取OAID
  Future<void> initMockUserIdAfterPrivacyAgreed() async {
    debugPrint('📊 开始初始化虚拟用户ID...');
    if (_mockUserId != null) {
      debugPrint('📊 虚拟用户ID已存在: $_mockUserId，跳过获取');
      return;
    }
    try {
      _mockUserId = await OaidUtil.instance.getOaid();
      if (_mockUserId != null) {
        debugPrint('📊 虚拟用户ID获取成功: $_mockUserId');
      } else {
        debugPrint('⚠️ 虚拟用户ID获取返回null');
      }
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
  /// [sourceEvent] 来源事件（触发当前页面/弹窗的事件ID）
  /// [exitType] 离开方式
  /// [params] 其他自定义参数
  void trackPageView({
    required String pageId,
    required String eventId,
    required int enterTime,
    required int duration,
    String? sourcePage,
    String? sourceEvent,
    int? exitType,
    Map<String, dynamic>? params,
  }) {
    final pageParams = <String, dynamic>{
      AnalyticsParams.pageEnterTime: enterTime,
      AnalyticsParams.pageDuration: duration,
      if (sourcePage != null) AnalyticsParams.sourcePage: sourcePage,
      if (sourceEvent != null) AnalyticsParams.sourceEvent: sourceEvent,
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
    int? btnName,
    Map<String, dynamic>? params,
  }) {
    final clickParams = <String, dynamic>{
      AnalyticsParams.clickTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
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
    debugPrint('📊 构建埋点参数，当前虚拟用户ID: $_mockUserId');
    if (_mockUserId != null) {
      params[AnalyticsParams.mockUserId] = _mockUserId;
    }

    // 添加用户ID
    // final userId = UserManager.userId;
    // if (userId != null) {
    //   params[AnalyticsParams.userId] = userId;
    // }

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

  /// 获取会员状态
  int _getVipStatus() {
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

  /// 获取绑定状态
  int _getBindStatus() {
    if (!UserManager.isLoggedIn) return BindStatusValue.notBound;
    
    final user = UserManager.currentUser;
    if (user == null) return BindStatusValue.notBound;
    
    // bindStatus 是 String? 类型，需要转换为 int 进行比较
    // 0 = 未绑定, 1 = 已绑定, 2 = 已解绑
    final bindStatusStr = user.bindStatus?.toString() ?? '0';
    
    switch (bindStatusStr) {
      case '1':
        return BindStatusValue.bound;
      case '2':
        return BindStatusValue.unbound;
      default:
        return BindStatusValue.notBound;
    }
  }

  /// 获取绑定次数
  int _getBindNum() {
    if (!UserManager.isLoggedIn) return 0;
    final user = UserManager.currentUser;
    return user?.bindNum ?? 0;
  }

  /// 获取188活动参与状态
  int _getAction188Status() {
    if (!UserManager.isLoggedIn) return Action188Value.notParticipated;
    final user = UserManager.currentUser;
    final isCheckIn = user?.isCheckIn ?? 0;
    // isCheckIn: 1已参与 0未参与
    return isCheckIn == 1 ? Action188Value.participated : Action188Value.notParticipated;
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
  Future<bool> _reportEvents(List<AnalyticsEvent> events) async {
    try {
      // 本地测试模式：写入log.txt文件
      if (_localTestMode) {
        final request = AnalyticsBatchRequest(
          events: events,
          appVersion: await _getAppVersion(),
        );
        return await _writeToLogFile(request);
      }

      // 将事件转换为后端需要的格式
      final pointData = events.map((e) => e.toUploadJson()).toList();

      debugPrint('📊 上报数据: ${jsonEncode({'point_data': pointData})}');

      // 调用埋点上传接口
      final result = await _analyticsApi.uploadPoint(pointData: pointData);

      if (result.isSuccess) {
        debugPrint('✅ 埋点上报成功');
        return true;
      } else {
        debugPrint('❌ 埋点上报失败: ${result.msg}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ 埋点上报异常: $e');
      return false;
    }
  }

  /// 将埋点数据写入log.txt文件（本地测试用）
  Future<bool> _writeToLogFile(AnalyticsBatchRequest request) async {
    try {
      // 尝试多个位置，优先使用外部存储
      File? logFile;
      String? location;
      
      // 1. 尝试外部存储（Download目录）
      try {
        final downloadDir = await getExternalStorageDirectory();
        if (downloadDir != null) {
          logFile = File('${downloadDir.path}/analytics_log.txt');
          location = '外部存储';
        }
      } catch (e) {
        debugPrint('⚠️ 无法访问外部存储: $e');
      }
      
      // 2. 如果外部存储失败，使用应用文档目录
      if (logFile == null) {
        final directory = await getApplicationDocumentsDirectory();
        logFile = File('${directory.path}/analytics_log.txt');
        location = '应用文档目录';
      }
      
      // 确保文件存在
      if (!await logFile.exists()) {
        await logFile.create(recursive: true);
      }
      
      // 格式化输出内容
      final timestamp = DateTime.now().toIso8601String();
      final separator = '=' * 80;
      final buffer = StringBuffer();
      
      buffer.writeln('\n$separator');
      buffer.writeln('📊 埋点上报时间: $timestamp');
      buffer.writeln('📦 事件数量: ${request.events.length}');
      buffer.writeln('📱 应用版本: ${request.appVersion ?? "未知"}');
      buffer.writeln('📁 存储位置: $location');
      buffer.writeln('📂 文件路径: ${logFile.path}');
      buffer.writeln(separator);
      
      // 逐个输出事件详情
      for (var i = 0; i < request.events.length; i++) {
        final event = request.events[i];
        buffer.writeln('\n【事件 ${i + 1}】');
        buffer.writeln('  页面ID: ${event.pageId}');
        buffer.writeln('  事件ID: ${event.eventId}');
        buffer.writeln('  时间戳: ${event.timestamp}');
        buffer.writeln('  参数:');
        
        // 格式化输出参数
        event.params.forEach((key, value) {
          buffer.writeln('    - $key: $value');
        });
      }
      
      buffer.writeln('\n$separator\n');
      
      // 追加写入文件
      await logFile.writeAsString(
        buffer.toString(),
        mode: FileMode.append,
        flush: true,
      );
      
      debugPrint('✅ 埋点数据已写入 ($location): ${logFile.path}');
      
      // 如果是外部存储，提供ADB命令
      if (location == '外部存储') {
        debugPrint('� ADB查看命令: adb shell cat "${logFile.path}"');
        debugPrint('💻 ADB拉取命令: adb pull "${logFile.path}" ./analytics_log.txt');
      }
      
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ 写入日志文件失败: $e');
      debugPrint('StackTrace: $stackTrace');
      return false;
    }
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

  /// 立即上报单个事件（不进事件池，直接上报）
  /// 用于需要立即上报的场景，如更换logo后app会被杀掉
  Future<void> trackEventImmediately({
    required String pageId,
    required String eventId,
    Map<String, dynamic>? params,
  }) async {
    final mergedParams = _buildParams(params);
    final event = AnalyticsEvent(
      pageId: pageId,
      eventId: eventId,
      params: mergedParams,
    );

    debugPrint('📊 立即上报事件: $eventId');

    // 本地测试模式：写入日志文件
    if (_localTestMode) {
      final request = AnalyticsBatchRequest(
        events: [event],
        appVersion: await _getAppVersion(),
      );
      await _writeToLogFile(request);
      return;
    }

    // 直接上报单个事件
    try {
      final pointData = [event.toUploadJson()];
      final result = await _analyticsApi.uploadPoint(pointData: pointData);
      
      if (result.isSuccess) {
        debugPrint('📊 事件立即上报成功: $eventId');
      } else {
        debugPrint('📊 事件立即上报失败: $eventId，已保存到队列');
        _eventQueue.add(event);
      }
    } catch (e) {
      debugPrint('❌ 事件立即上报异常: $e，已保存到队列');
      _eventQueue.add(event);
    }
  }

  /// 获取当前队列中的事件数量
  int get pendingEventCount => _eventQueue.length;

  /// 清空所有事件（谨慎使用）
  void clearAllEvents() {
    _eventQueue.clear();
    debugPrint('📊 已清空所有待上报事件');
  }

  /// 获取日志文件内容（用于应用内查看）
  Future<String> getLogContent() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logFile = File('${directory.path}/analytics_log.txt');
      
      if (await logFile.exists()) {
        return await logFile.readAsString();
      } else {
        return '暂无埋点日志文件';
      }
    } catch (e) {
      return '读取日志文件失败: $e';
    }
  }

  /// 清空日志文件
  Future<void> clearLogFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logFile = File('${directory.path}/analytics_log.txt');
      
      if (await logFile.exists()) {
        await logFile.writeAsString('');
        debugPrint('✅ 日志文件已清空');
      }
    } catch (e) {
      debugPrint('❌ 清空日志文件失败: $e');
    }
  }
}
