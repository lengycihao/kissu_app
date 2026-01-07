import 'dart:convert';

/// 埋点事件数据模型
/// 用于封装单个埋点事件的所有信息
class AnalyticsEvent {
  /// 页面ID（用于分组）
  final String pageId;
  
  /// 事件ID
  final String eventId;
  
  /// 事件参数
  final Map<String, dynamic> params;
  
  /// 事件创建时间戳（毫秒）
  final int timestamp;
  
  /// 事件唯一标识（用于去重）
  final String uuid;

  AnalyticsEvent({
    required this.pageId,
    required this.eventId,
    required this.params,
    int? timestamp,
    String? uuid,
  })  : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch,
        uuid = uuid ?? _generateUuid();

  /// 生成简单的UUID
  static String _generateUuid() {
    final now = DateTime.now();
    return '${now.millisecondsSinceEpoch}_${now.microsecond}';
  }

  /// 转换为JSON Map
  Map<String, dynamic> toJson() {
    return {
      'page_id': pageId,
      'event_id': eventId,
      'params': params,
      'timestamp': timestamp,
      'uuid': uuid,
    };
  }

  /// 从JSON Map创建实例
  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      pageId: json['page_id'] as String,
      eventId: json['event_id'] as String,
      params: Map<String, dynamic>.from(json['params'] as Map),
      timestamp: json['timestamp'] as int,
      uuid: json['uuid'] as String,
    );
  }

  /// 转换为JSON字符串
  String toJsonString() => jsonEncode(toJson());

  /// 从JSON字符串创建实例
  factory AnalyticsEvent.fromJsonString(String jsonString) {
    return AnalyticsEvent.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  @override
  String toString() {
    return 'AnalyticsEvent(pageId: $pageId, eventId: $eventId, params: $params)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalyticsEvent && other.uuid == uuid;
  }

  @override
  int get hashCode => uuid.hashCode;
}

/// 页面事件数据模型
/// 专门用于页面浏览事件，自动处理进入时间和停留时长
class PageAnalyticsEvent extends AnalyticsEvent {
  /// 页面进入时间
  final DateTime enterTime;
  
  /// 页面离开时间（可选，离开时设置）
  DateTime? _exitTime;

  PageAnalyticsEvent({
    required super.pageId,
    required super.eventId,
    required super.params,
    DateTime? enterTime,
  }) : enterTime = enterTime ?? DateTime.now();

  /// 设置离开时间
  void setExitTime([DateTime? time]) {
    _exitTime = time ?? DateTime.now();
  }

  /// 获取页面停留时长（格式：mm:ss）
  String get duration {
    final exitTime = _exitTime ?? DateTime.now();
    final diff = exitTime.difference(enterTime);
    final minutes = diff.inMinutes;
    final seconds = diff.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 获取页面停留时长（秒）
  int get durationInSeconds {
    final exitTime = _exitTime ?? DateTime.now();
    return exitTime.difference(enterTime).inSeconds;
  }

  /// 获取格式化的进入时间（格式：年-月-日 时:分:秒）
  String get formattedEnterTime {
    return _formatDateTime(enterTime, separator: '-');
  }

  /// 格式化日期时间
  static String _formatDateTime(DateTime dateTime, {String separator = '-'}) {
    final year = dateTime.year;
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$year$separator$month$separator$day $hour:$minute:$second';
  }
}

/// 批量上报请求模型
class AnalyticsBatchRequest {
  /// 事件列表
  final List<AnalyticsEvent> events;
  
  /// 设备信息
  final Map<String, dynamic>? deviceInfo;
  
  /// 应用版本
  final String? appVersion;

  AnalyticsBatchRequest({
    required this.events,
    this.deviceInfo,
    this.appVersion,
  });

  /// 转换为JSON Map
  Map<String, dynamic> toJson() {
    return {
      'events': events.map((e) => e.toJson()).toList(),
      if (deviceInfo != null) 'device_info': deviceInfo,
      if (appVersion != null) 'app_version': appVersion,
    };
  }
}
