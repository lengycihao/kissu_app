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

  // ==================== 业务埋点方法 ====================
  
  /// 登录按钮点击事件
  /// 
  /// 参数说明：
  /// - [isSuccess] 是否登录成功（根据后台返回的状态判断）
  /// - [userId] 用户ID（登录成功后的真实用户ID，可选）
  static Future<void> trackLoginButton({
    required bool isSuccess,
    String? userId,
  }) async {
    try {
      // 获取虚拟用户ID
      final virtualUserId = await getOrCreateVirtualUserId();

      // 获取当前时间，格式：年/月/日 时:分:秒
      final now = DateTime.now();
      final clickTime = '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} '
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      // 构建事件参数
      final params = <String, String>{
        'device_id': virtualUserId,           // 虚拟用户ID
        'click_time': clickTime,              // 点击时间
        'is_success': isSuccess ? '是' : '否', // 是否登录成功
      };

      // 如果登录成功且提供了用户ID，则添加用户ID参数
      if (userId != null && userId.isNotEmpty) {
        params['user_id'] = userId;
      }

      // 发送点击事件
      await logEventWithParams('login_button', params);
      
      DebugUtil.info('友盟统计: 登录按钮点击事件已发送 - 是否成功: ${isSuccess ? "是" : "否"}, 用户ID: ${userId ?? "未提供"}');
    } catch (e) {
      DebugUtil.error('友盟统计: 发送登录按钮点击事件失败 - $e');
    }
  }
}

