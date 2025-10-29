import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'debug_util.dart';

/// 友盟统计埋点工具类
/// 
/// 提供便捷的友盟统计功能，包括：
/// - 页面访问统计
/// - 事件统计
/// - 自定义事件和参数
/// - 用户属性设置
/// 
/// 使用示例：
/// ```dart
/// // 页面访问统计
/// UmengAnalytics.pageStart('HomePage');
/// UmengAnalytics.pageEnd('HomePage');
/// 
/// // 事件统计
/// UmengAnalytics.logEvent('button_click');
/// 
/// // 带参数的事件统计
/// UmengAnalytics.logEventWithParams('purchase', {'product_id': '123', 'amount': '99.9'});
/// 
/// // 设置用户ID
/// UmengAnalytics.setUserId('user_12345');
/// ```
class UmengAnalytics {
  static const MethodChannel _channel = MethodChannel('umeng_analytics');
  
  /// 是否已初始化
  static bool _isInitialized = false;
  
  /// 虚拟用户ID的缓存key
  static const String _virtualUserIdKey = 'umeng_virtual_user_id';
  
  /// 虚拟用户ID实例（缓存）
  static String? _cachedVirtualUserId;
  
  /// 事件计时器映射表：记录所有进行中的事件
  /// key: 事件ID, value: 开始时间
  static final Map<String, DateTime> _eventTimers = {};
  
  /// 事件计时最大时长（毫秒），超过此时长会自动结束并警告
  /// 默认 30 分钟，防止忘记调用 eventEnd 导致内存泄漏
  static const int _maxEventDurationMs = 30 * 60 * 1000;
  
  /// 初始化友盟统计
  /// 
  /// [appKey] 友盟AppKey，如果不传则使用项目配置的key
  /// [channel] 渠道标识，默认为'Umeng'
  /// [logEnabled] 是否开启日志，默认为false
  static Future<void> init({
    String? appKey,
    String? channel,
    bool logEnabled = false,
  }) async {
    try {
      await _channel.invokeMethod('umeng_init', {
        'appKey': appKey ?? '6879fbe579267e0210b67be9',
        'channel': channel ?? 'Umeng',
        'logEnabled': logEnabled,
      });
      _isInitialized = true;
      DebugUtil.success('友盟统计初始化成功');
    } catch (e) {
      DebugUtil.error('友盟统计初始化失败: $e');
    }
  }
  
  /// 设置是否开启Session统计
  /// 
  /// [enabled] 是否开启，默认为true
  static Future<void> setSessionContinueMillis({bool enabled = true}) async {
    try {
      await _channel.invokeMethod('umeng_setSessionContinue', {
        'enabled': enabled,
      });
    } catch (e) {
      DebugUtil.error('设置Session统计失败: $e');
    }
  }
  
  /// 页面访问开始
  /// 
  /// [pageName] 页面名称，建议使用英文或拼音
  /// 
  /// 注意：必须与pageEnd成对使用
  static Future<void> pageStart(String pageName) async {
    if (!_isInitialized) {
      DebugUtil.warning('友盟统计未初始化，请先调用init()');
      return;
    }
    
    try {
      await _channel.invokeMethod('umeng_pageStart', {
        'pageName': pageName,
      });
      DebugUtil.info('友盟统计-页面开始: $pageName');
    } catch (e) {
      DebugUtil.error('友盟统计页面开始失败: $e');
    }
  }
  
  /// 页面访问结束
  /// 
  /// [pageName] 页面名称，必须与pageStart中的名称一致
  static Future<void> pageEnd(String pageName) async {
    if (!_isInitialized) {
      DebugUtil.warning('友盟统计未初始化，请先调用init()');
      return;
    }
    
    try {
      await _channel.invokeMethod('umeng_pageEnd', {
        'pageName': pageName,
      });
      DebugUtil.info('友盟统计-页面结束: $pageName');
    } catch (e) {
      DebugUtil.error('友盟统计页面结束失败: $e');
    }
  }
  
  /// 记录事件
  /// 
  /// [eventId] 事件ID，建议使用英文或拼音，如：'button_click'
  static Future<void> logEvent(String eventId) async {
    if (!_isInitialized) {
      DebugUtil.warning('友盟统计未初始化，请先调用init()');
      return;
    }
    
    try {
      await _channel.invokeMethod('umeng_logEvent', {
        'eventId': eventId,
      });
      DebugUtil.info('友盟统计-事件: $eventId');
    } catch (e) {
      DebugUtil.error('友盟统计事件失败: $e');
    }
  }
  
  /// 记录带参数的事件
  /// 
  /// [eventId] 事件ID
  /// [params] 事件参数，key和value都必须是String类型
  /// 
  /// 示例：
  /// ```dart
  /// UmengAnalytics.logEventWithParams('purchase', {
  ///   'product_id': '123',
  ///   'product_name': 'VIP会员',
  ///   'amount': '99.9',
  ///   'currency': 'CNY',
  /// });
  /// ```
  static Future<void> logEventWithParams(
    String eventId,
    Map<String, String> params,
  ) async {
    if (!_isInitialized) {
      DebugUtil.warning('友盟统计未初始化，请先调用init()');
      return;
    }
    
    try {
      await _channel.invokeMethod('umeng_logEventWithParams', {
        'eventId': eventId,
        'params': params,
      });
      DebugUtil.info('友盟统计-事件(带参数): $eventId, params: $params');
    } catch (e) {
      DebugUtil.error('友盟统计事件(带参数)失败: $e');
    }
  }
  
  /// 记录带数值的事件（用于统计事件发生次数）
  /// 
  /// [eventId] 事件ID
  /// [value] 数值，表示事件发生的次数或其他数值
  static Future<void> logEventWithValue(
    String eventId,
    int value,
  ) async {
    if (!_isInitialized) {
      DebugUtil.warning('友盟统计未初始化，请先调用init()');
      return;
    }
    
    try {
      await _channel.invokeMethod('umeng_logEventWithValue', {
        'eventId': eventId,
        'value': value,
      });
      DebugUtil.info('友盟统计-事件(带数值): $eventId, value: $value');
    } catch (e) {
      DebugUtil.error('友盟统计事件(带数值)失败: $e');
    }
  }
  
  /// 记录带参数和数值的事件
  /// 
  /// [eventId] 事件ID
  /// [params] 事件参数
  /// [value] 数值
  static Future<void> logEventWithParamsAndValue(
    String eventId,
    Map<String, String> params,
    int value,
  ) async {
    if (!_isInitialized) {
      DebugUtil.warning('友盟统计未初始化，请先调用init()');
      return;
    }
    
    try {
      await _channel.invokeMethod('umeng_logEventWithParamsAndValue', {
        'eventId': eventId,
        'params': params,
        'value': value,
      });
      DebugUtil.info('友盟统计-事件(带参数和数值): $eventId, params: $params, value: $value');
    } catch (e) {
      DebugUtil.error('友盟统计事件(带参数和数值)失败: $e');
    }
  }
  
  /// 设置用户ID
  /// 
  /// [userId] 用户ID，用于关联用户行为
  /// 
  /// 注意：建议在用户登录后立即调用此方法
  static Future<void> setUserId(String userId) async {
    if (!_isInitialized) {
      DebugUtil.warning('友盟统计未初始化，请先调用init()');
      return;
    }
    
    try {
      await _channel.invokeMethod('umeng_setUserId', {
        'userId': userId,
      });
      DebugUtil.info('友盟统计-设置用户ID: $userId');
    } catch (e) {
      DebugUtil.error('友盟统计设置用户ID失败: $e');
    }
  }
  
  /// 清除用户ID
  /// 
  /// 建议在用户退出登录时调用
  static Future<void> clearUserId() async {
    if (!_isInitialized) {
      DebugUtil.warning('友盟统计未初始化，请先调用init()');
      return;
    }
    
    try {
      await _channel.invokeMethod('umeng_clearUserId');
      DebugUtil.info('友盟统计-清除用户ID');
    } catch (e) {
      DebugUtil.error('友盟统计清除用户ID失败: $e');
    }
  }
  
  /// 设置用户属性（通过事件方式记录）
  /// 
  /// ⚠️ 注意：友盟统计 SDK 不直接支持自定义用户属性设置
  /// 此方法实际上会将用户属性作为事件参数上报
  /// 
  /// [properties] 用户属性，key和value都必须是String类型
  /// 
  /// 示例：
  /// ```dart
  /// UmengAnalytics.setUserProfile({
  ///   'gender': 'male',
  ///   'age': '25',
  ///   'city': 'Beijing',
  ///   'vip_level': '3',
  /// });
  /// ```
  static Future<void> setUserProfile(Map<String, String> properties) async {
    if (!_isInitialized) {
      DebugUtil.warning('友盟统计未初始化，请先调用init()');
      return;
    }
    
    try {
      // 友盟不支持直接设置用户属性，通过事件方式记录
      await _channel.invokeMethod('umeng_setUserProfile', {
        'properties': properties,
      });
      DebugUtil.info('友盟统计-记录用户属性(作为事件): $properties');
    } catch (e) {
      DebugUtil.error('友盟统计记录用户属性失败: $e');
    }
  }
  
  /// 手动触发数据上报
  /// 
  /// 友盟SDK会自动在合适的时机上报数据，一般不需要手动调用
  static Future<void> flush() async {
    if (!_isInitialized) {
      DebugUtil.warning('友盟统计未初始化，请先调用init()');
      return;
    }
    
    try {
      await _channel.invokeMethod('umeng_flush');
      DebugUtil.info('友盟统计-手动上报数据');
    } catch (e) {
      DebugUtil.error('友盟统计手动上报数据失败: $e');
    }
  }
  
  /// 设置是否在后台运行时继续统计
  /// 
  /// [enabled] 是否开启后台统计，默认为false
  static Future<void> setScenarioType({bool enabled = false}) async {
    try {
      await _channel.invokeMethod('umeng_setScenarioType', {
        'enabled': enabled,
      });
    } catch (e) {
      DebugUtil.error('友盟统计设置后台统计失败: $e');
    }
  }
  
  /// 生成或获取虚拟用户ID
  /// 
  /// 虚拟用户ID用于在用户未登录或未授权的情况下进行用户行为统计
  /// 
  /// 特点：
  /// - 首次调用时会生成一个UUID格式的虚拟ID并持久化存储
  /// - 后续调用会返回已存储的虚拟ID
  /// - 应用卸载重装后会生成新的虚拟ID
  /// - 用户登录后建议使用真实用户ID（调用setUserId）
  /// 
  /// 使用场景：
  /// ```dart
  /// // 1. 应用启动时或隐私政策同意后初始化友盟
  /// await UmengAnalytics.init();
  /// 
  /// // 2. 获取虚拟用户ID并设置给友盟
  /// String virtualUserId = await UmengAnalytics.getOrCreateVirtualUserId();
  /// await UmengAnalytics.setUserId(virtualUserId);
  /// 
  /// // 3. 用户登录后，切换为真实用户ID
  /// await UmengAnalytics.setUserId('real_user_12345');
  /// 
  /// // 4. 用户退出登录后，恢复为虚拟用户ID
  /// String virtualUserId = await UmengAnalytics.getOrCreateVirtualUserId();
  /// await UmengAnalytics.setUserId(virtualUserId);
  /// ```
  /// 
  /// 返回值：虚拟用户ID（UUID格式，如：550e8400-e29b-41d4-a716-446655440000）
  static Future<String> getOrCreateVirtualUserId() async {
    try {
      // 如果内存中已有缓存，直接返回
      if (_cachedVirtualUserId != null && _cachedVirtualUserId!.isNotEmpty) {
        return _cachedVirtualUserId!;
      }
      
      // 从本地存储读取
      final prefs = await SharedPreferences.getInstance();
      String? storedId = prefs.getString(_virtualUserIdKey);
      
      // 如果本地存储中有，使用已存储的ID
      if (storedId != null && storedId.isNotEmpty) {
        _cachedVirtualUserId = storedId;
        DebugUtil.info('友盟统计-获取已存在的虚拟用户ID: $storedId');
        return storedId;
      }
      
      // 生成新的虚拟用户ID（UUID格式）
      const uuid = Uuid();
      String newVirtualId = uuid.v4();
      
      // 持久化存储
      await prefs.setString(_virtualUserIdKey, newVirtualId);
      
      // 缓存到内存
      _cachedVirtualUserId = newVirtualId;
      
      DebugUtil.success('友盟统计-生成新的虚拟用户ID: $newVirtualId');
      return newVirtualId;
      
    } catch (e) {
      DebugUtil.error('友盟统计生成虚拟用户ID失败: $e');
      // 失败时返回一个临时的UUID（不持久化）
      const uuid = Uuid();
      return uuid.v4();
    }
  }
  
  /// 清除虚拟用户ID
  /// 
  /// 清除本地存储和内存缓存中的虚拟用户ID
  /// 下次调用getOrCreateVirtualUserId时会生成新的ID
  /// 
  /// 使用场景：
  /// - 用户主动清除数据
  /// - 需要重置用户统计数据
  static Future<void> clearVirtualUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_virtualUserIdKey);
      _cachedVirtualUserId = null;
      DebugUtil.info('友盟统计-清除虚拟用户ID');
    } catch (e) {
      DebugUtil.error('友盟统计清除虚拟用户ID失败: $e');
    }
  }
  
  /// 获取当前虚拟用户ID（不创建新ID）
  /// 
  /// 如果虚拟用户ID不存在，返回null
  /// 如果需要确保获取ID，请使用getOrCreateVirtualUserId
  /// 
  /// 返回值：虚拟用户ID或null
  static Future<String?> getVirtualUserId() async {
    try {
      // 如果内存中已有缓存，直接返回
      if (_cachedVirtualUserId != null && _cachedVirtualUserId!.isNotEmpty) {
        return _cachedVirtualUserId;
      }
      
      // 从本地存储读取
      final prefs = await SharedPreferences.getInstance();
      String? storedId = prefs.getString(_virtualUserIdKey);
      
      if (storedId != null && storedId.isNotEmpty) {
        _cachedVirtualUserId = storedId;
        return storedId;
      }
      
      return null;
    } catch (e) {
      DebugUtil.error('友盟统计获取虚拟用户ID失败: $e');
      return null;
    }
  }

  // ==================== 事件计时方法（带安全销毁机制） ====================
  
  /// 开始计时事件
  /// 
  /// 用于记录事件的开始时间，配合 [eventEnd] 使用可自动计算事件时长
  /// 
  /// ⚠️ 安全机制：
  /// - 同一事件ID只能有一个计时器，重复调用会覆盖之前的计时器并警告
  /// - 自动检测超时事件（默认30分钟），超时会自动结束并警告
  /// - 建议在页面销毁时调用 [endAllEvents] 清理所有未结束的事件
  /// 
  /// [eventId] 事件ID，建议使用英文或拼音
  /// [params] 可选参数，会在 eventEnd 时一起上报
  /// 
  /// 使用示例：
  /// ```dart
  /// // 1. 基础用法
  /// await UmengAnalytics.eventBegin('video_play');
  /// // ... 用户观看视频 ...
  /// await UmengAnalytics.eventEnd('video_play');
  /// 
  /// // 2. 带参数
  /// await UmengAnalytics.eventBegin('video_play', params: {'video_id': '123'});
  /// await UmengAnalytics.eventEnd('video_play', params: {'video_id': '123'});
  /// 
  /// // 3. 在页面销毁时清理（防止内存泄漏）
  /// @override
  /// void onClose() {
  ///   UmengAnalytics.endAllEvents(); // 自动结束所有未结束的事件
  ///   super.onClose();
  /// }
  /// ```
  static Future<void> eventBegin(String eventId, {Map<String, String>? params}) async {
    if (!_isInitialized) {
      DebugUtil.warning('友盟统计未初始化，请先调用init()');
      return;
    }
    
    // 检查是否已存在相同事件ID的计时器
    if (_eventTimers.containsKey(eventId)) {
      DebugUtil.warning('友盟统计-事件计时警告: 事件 "$eventId" 已经在计时中，将覆盖之前的计时器');
      // 先结束之前的事件
      await eventEnd(eventId, params: params, isAutoEnd: true);
    }
    
    try {
      // 记录开始时间（只在 Dart 层面记录，不调用原生方法）
      _eventTimers[eventId] = DateTime.now();
      
      DebugUtil.info('友盟统计-事件计时开始: $eventId${params != null ? ", params: $params" : ""}');
    } catch (e) {
      // 失败时清理本地记录
      _eventTimers.remove(eventId);
      DebugUtil.error('友盟统计事件计时开始失败: $e');
    }
  }
  
  /// 结束计时事件
  /// 
  /// 结束由 [eventBegin] 开始的事件计时，自动计算并上报时长
  /// 
  /// [eventId] 事件ID，必须与 eventBegin 中的 ID 一致
  /// [params] 可选参数，会覆盖 eventBegin 时的参数
  /// [isAutoEnd] 内部参数，标记是否为自动结束（用于日志区分）
  /// 
  /// 注意：
  /// - 如果事件未开始就调用 eventEnd，会记录警告但不会报错
  /// - 建议在 finally 块中调用 eventEnd 确保一定会执行
  static Future<void> eventEnd(String eventId, {Map<String, String>? params, bool isAutoEnd = false}) async {
    if (!_isInitialized) {
      DebugUtil.warning('友盟统计未初始化，请先调用init()');
      return;
    }
    
    // 检查事件是否已开始
    final startTime = _eventTimers[eventId];
    if (startTime == null) {
      DebugUtil.warning('友盟统计-事件计时警告: 事件 "$eventId" 未开始计时就调用了 eventEnd');
      return;
    }
    
    try {
      // 计算时长
      final duration = DateTime.now().difference(startTime);
      final durationMs = duration.inMilliseconds;
      
      // 检查是否超时
      if (durationMs > _maxEventDurationMs) {
        DebugUtil.warning(
          '友盟统计-事件计时警告: 事件 "$eventId" 计时时长过长 (${duration.inMinutes}分钟)，'
          '可能忘记调用 eventEnd，建议检查代码'
        );
      }
      
      // 清理本地记录
      _eventTimers.remove(eventId);
      
      // 使用普通的 logEventWithParams 方法上报，附带时长参数
      final eventParams = <String, String>{
        'duration_ms': durationMs.toString(),
        'duration_seconds': duration.inSeconds.toString(),
        if (params != null) ...params,
      };
      
      await logEventWithParams(eventId, eventParams);
      
      final logPrefix = isAutoEnd ? '友盟统计-事件计时自动结束' : '友盟统计-事件计时结束';
      DebugUtil.info('$logPrefix: $eventId, 时长: ${duration.inSeconds}秒${params != null ? ", params: $params" : ""}');
    } catch (e) {
      // 即使失败也清理本地记录，防止内存泄漏
      _eventTimers.remove(eventId);
      DebugUtil.error('友盟统计事件计时结束失败: $e');
    }
  }
  
  /// 结束所有进行中的事件
  /// 
  /// 自动结束所有通过 [eventBegin] 开始但未调用 [eventEnd] 的事件
  /// 
  /// ⚠️ 强烈建议在以下场景调用此方法：
  /// - 页面/组件销毁时（onClose、dispose）
  /// - 应用进入后台时
  /// - 用户退出登录时
  /// 
  /// 使用示例：
  /// ```dart
  /// @override
  /// void onClose() {
  ///   UmengAnalytics.endAllEvents();
  ///   super.onClose();
  /// }
  /// 
  /// @override
  /// void dispose() {
  ///   UmengAnalytics.endAllEvents();
  ///   super.dispose();
  /// }
  /// ```
  static Future<void> endAllEvents() async {
    if (_eventTimers.isEmpty) {
      return;
    }
    
    final eventIds = _eventTimers.keys.toList();
    DebugUtil.info('友盟统计-批量结束未完成的事件: ${eventIds.join(", ")} (共${eventIds.length}个)');
    
    // 逐个结束所有事件
    for (final eventId in eventIds) {
      await eventEnd(eventId, isAutoEnd: true);
    }
  }
  
  /// 获取当前进行中的事件列表
  /// 
  /// 用于调试，查看哪些事件还在计时中
  /// 
  /// 返回：事件ID列表
  static List<String> getActiveEvents() {
    return _eventTimers.keys.toList();
  }
  
  /// 检查指定事件是否正在计时
  /// 
  /// [eventId] 事件ID
  /// 
  /// 返回：true 表示正在计时，false 表示未计时
  static bool isEventActive(String eventId) {
    return _eventTimers.containsKey(eventId);
  }
  
  /// 清理超时的事件（内部方法）
  /// 
  /// 自动检测并结束所有超过最大时长的事件
  /// 可以在应用生命周期的某些节点定期调用此方法
  static Future<void> cleanupTimeoutEvents() async {
    final now = DateTime.now();
    final timeoutEvents = <String>[];
    
    // 查找所有超时的事件
    _eventTimers.forEach((eventId, startTime) {
      final duration = now.difference(startTime);
      if (duration.inMilliseconds > _maxEventDurationMs) {
        timeoutEvents.add(eventId);
      }
    });
    
    // 结束超时事件
    if (timeoutEvents.isNotEmpty) {
      DebugUtil.warning('友盟统计-发现${timeoutEvents.length}个超时事件，自动结束: ${timeoutEvents.join(", ")}');
      for (final eventId in timeoutEvents) {
        await eventEnd(eventId, isAutoEnd: true);
      }
    }
  }
}

