import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../utils/umeng_analytics_util.dart';
import '../utils/user_manager.dart';

/// 统一的埋点服务类
/// 
/// 集中管理所有页面的埋点方法，提供统一的接口和实现
/// 
/// 使用示例：
/// ```dart
/// // 首页埋点
/// await TrackingService.trackPartnerAvatarClick();
/// await TrackingService.trackMessageCenterClick();
/// ```
class TrackingService {
  TrackingService._(); // 私有构造函数，防止实例化

  // ==================== 通用工具方法 ====================

  /// 获取格式化的当前时间
  /// 格式：年/月/日 时:分:秒
  /// 示例：2025/10/25 14:30:45
  static String _getFormattedTime() {
    final now = DateTime.now();
    return '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  /// 构建基础埋点参数（device_id + click_time + user_id）
  /// 
  /// 返回包含以下参数的Map：
  /// - device_id: 虚拟用户ID（必填）
  /// - click_time: 点击时间（必填）
  /// - user_id: 用户ID（可选，仅在已登录时包含）
  static Future<Map<String, String>> _buildBaseParams() async {
    // 获取虚拟用户ID
    final deviceId = await UmengAnalytics.getOrCreateVirtualUserId();
    
    // 获取用户ID（如果已登录）
    final user = UserManager.currentUser;
    final userId = user?.id?.toString() ?? '';
    
    // 获取当前时间
    final clickTime = _getFormattedTime();
    
    // 构建参数
    final params = <String, String>{
      'device_id': deviceId,
      'click_time': clickTime,
    };
    
    // 如果有用户ID，添加到参数中
    if (userId.isNotEmpty) {
      params['user_id'] = userId;
    }
    
    return params;
  }

  /// 上报埋点事件的通用方法
  /// 
  /// [eventId] 事件ID
  /// [params] 事件参数
  /// [eventName] 事件名称（用于日志输出）
  static Future<void> _trackEvent(
    String eventId,
    Map<String, String> params,
    String eventName,
  ) async {
    try {
      await UmengAnalytics.logEventWithParams(eventId, params);
      
      final deviceId = params['device_id'] ?? '';
      final userId = params['user_id'] ?? '';
      final clickTime = params['click_time'] ?? '';
      
      debugPrint('✅ $eventName埋点上报成功: device_id=$deviceId, user_id=$userId, click_time=$clickTime');
    } catch (e) {
      debugPrint('❌ $eventName埋点：上报数据失败 - $e');
    }
  }

  // ==================== 首页埋点 ====================

  /// 埋点：点击另一半头像（绑定伴侣头像）
  /// 
  /// 事件ID: bind_partner_avatar
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - click_time: 点击时间
  static Future<void> trackPartnerAvatarClick() async {
    final params = await _buildBaseParams();
    await _trackEvent('bind_partner_avatar', params, '另一半头像点击');
  }

  /// 埋点：点击消息中心按钮
  /// 
  /// 事件ID: message_center_button
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - click_time: 点击时间
  static Future<void> trackMessageCenterClick() async {
    final params = await _buildBaseParams();
    await _trackEvent('message_center_button', params, '消息中心按钮点击');
  }

  /// 埋点：活动按钮点击事件
  /// 
  /// 事件ID: receive_red_packet_button
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - click_time: 点击时间
  /// 
  /// 触发场景：用户点击首页活动按钮时
  static Future<void> trackActivityButtonClick() async {
    final params = await _buildBaseParams();
    await _trackEvent('receive_red_packet_button', params, '活动按钮点击');
  }

  /// 埋点：首页页面 - 浏览事件
  /// 
  /// 事件ID: home_page
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - stay_duration: 页面停留时长（如：2s）
  /// - scroll_times: 页面滑动次数（如：3次）
  /// 
  /// [stayDuration] 页面停留时长
  /// [scrollTimes] 页面滑动次数
  /// 
  /// 触发场景：用户退出首页时
  static Future<void> trackHomePageView({
    required String stayDuration,
    required int scrollTimes,
  }) async {
    try {
      final params = await _buildBaseParams();
      params.remove('click_time'); // 浏览事件不需要点击时间
      params['stay_duration'] = stayDuration;
      params['scroll_times'] = '${scrollTimes}次';
      await _trackEvent('home_page', params, '首页页面-浏览事件');
    } catch (e) {
      debugPrint('❌ 首页页面浏览埋点：上报数据失败 - $e');
    }
  }

  // ==================== 登录页埋点 ====================

  /// 埋点：登录按钮点击事件
  /// 
  /// 事件ID: login_button
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - click_time: 点击时间
  /// - is_success: 是否登录成功（"是"/"否"）
  /// - user_id: 用户ID（登录成功时）
  /// 
  /// [isSuccess] 是否登录成功（根据后台返回的状态判断）
  /// [userId] 用户ID（登录成功后的真实用户ID，可选）
  static Future<void> trackLoginButton({
    required bool isSuccess,
    String? userId,
  }) async {
    try {
      // 获取虚拟用户ID
      final deviceId = await UmengAnalytics.getOrCreateVirtualUserId();
      
      // 获取当前时间
      final clickTime = _getFormattedTime();
      
      // 构建事件参数
      final params = <String, String>{
        'device_id': deviceId,
        'click_time': clickTime,
        'is_success': isSuccess ? '是' : '否',
      };
      
      // 如果登录成功且提供了用户ID，则添加用户ID参数
      if (userId != null && userId.isNotEmpty) {
        params['user_id'] = userId;
      }
      
      // 发送埋点事件
      await _trackEvent('login_button', params, '登录按钮点击');
    } catch (e) {
      debugPrint('❌ 登录按钮点击埋点：上报数据失败 - $e');
    }
  }

  /// 埋点：协议操作事件
  /// 
  /// 事件ID: user_agreement_operation
  /// 
  /// 用于统计用户在登录页面对隐私协议的操作行为
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - is_agree: 是否同意（"1"=同意，"0"=不同意）
  /// 
  /// [isAgree] 操作协议类型：true=同意，false=不同意/取消勾选
  /// 
  /// 使用场景：
  /// 1. 勾选协议复选框时：isAgree = true
  /// 2. 取消勾选协议复选框时：isAgree = false
  /// 3. 未勾选协议时弹窗点击同意：isAgree = true
  static Future<void> trackAgreementOperation({
    required bool isAgree,
  }) async {
    try {
      // 获取虚拟用户ID
      final deviceId = await UmengAnalytics.getOrCreateVirtualUserId();
      
      // 构建事件参数
      final params = <String, String>{
        'device_id': deviceId,
        'is_agree': isAgree ? '1' : '0',
      };
      
      // 发送埋点事件
      await _trackEvent('user_agreement_operation', params, '协议操作');
    } catch (e) {
      debugPrint('❌ 协议操作埋点：上报数据失败 - $e');
    }
  }

  // ==================== 首页 Banner/岛视图埋点 ====================

  /// 埋点：屏视图 Banner 点击事件
  /// 
  /// 事件ID: home_banner
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - is_drag: 是否手动滑动（"1"=是，"0"=否）
  /// - click_time: 点击时间
  /// - click_type: 点击类型（定位、足迹、绑定、会员）
  /// - is_vip: 是否会员（是会员、不是会员）
  /// - is_bind: 是否绑定（是绑定、未绑定）
  /// 
  /// [isDrag] 是否是手动滑动到的 banner（true=用户手动滑动，false=自动播放）
  /// [clickType] 点击类型：定位、足迹、绑定、会员
  /// [isVip] 是否是会员
  /// [isBind] 是否已绑定伴侣
  static Future<void> trackHomeBannerClick({
    required bool isDrag,
    required String clickType,
    required bool isVip,
    required bool isBind,
  }) async {
    try {
      // 获取基础参数（device_id + user_id + click_time）
      final params = await _buildBaseParams();
      
      // 添加 banner 特有参数
      params['is_drag'] = isDrag ? '1' : '0';
      params['click_type'] = clickType;
      params['is_vip'] = isVip ? '是会员' : '不是会员';
      params['is_bind'] = isBind ? '是绑定' : '未绑定';
      
      // 发送埋点事件
      await _trackEvent('home_banner', params, '屏视图Banner点击');
    } catch (e) {
      debugPrint('❌ 屏视图Banner点击埋点：上报数据失败 - $e');
    }
  }

  /// 埋点：岛视图按钮点击事件
  /// 
  /// 事件ID: home_island
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - click_time: 点击时间
  /// - is_vip: 是否会员（是会员、不是会员）
  /// - is_bind: 是否绑定（是绑定、未绑定）
  /// - click_type: 点击类型（定位、足迹、绑定、会员）
  /// 
  /// [clickType] 点击类型：定位、足迹、绑定、会员
  /// [isVip] 是否是会员
  /// [isBind] 是否已绑定伴侣
  static Future<void> trackHomeIslandClick({
    required String clickType,
    required bool isVip,
    required bool isBind,
  }) async {
    try {
      // 获取基础参数（device_id + user_id + click_time）
      final params = await _buildBaseParams();
      
      // 添加岛视图特有参数
      params['click_type'] = clickType;
      params['is_vip'] = isVip ? '是会员' : '不是会员';
      params['is_bind'] = isBind ? '是绑定' : '未绑定';
      
      // 发送埋点事件
      await _trackEvent('home_island', params, '岛视图按钮点击');
    } catch (e) {
      debugPrint('❌ 岛视图按钮点击埋点：上报数据失败 - $e');
    }
  }

  // ==================== 底部导航埋点 ====================

  /// 埋点：底部导航点击事件
  /// 
  /// 事件ID: bottom_navigation
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - click_time: 点击时间
  /// - bottom_name: 底部导航名称（定位、足迹、用机记录、我的）
  /// 
  /// [bottomName] 底部导航名称：定位、足迹、用机记录、我的
  static Future<void> trackBottomNavigationClick({
    required String bottomName,
  }) async {
    try {
      // 获取基础参数（device_id + user_id + click_time）
      final params = await _buildBaseParams();
      
      // 添加底部导航特有参数
      params['bottom_name'] = bottomName;
      
      // 发送埋点事件
      await _trackEvent('bottom_navigation', params, '底部导航点击');
    } catch (e) {
      debugPrint('❌ 底部导航点击埋点：上报数据失败 - $e');
    }
  }

  // ==================== 充值弹窗埋点 ====================

  /// 埋点：充值弹窗 - 关闭按钮点击
  /// 
  /// 事件ID: home_vip_alert
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - vip_alert_close: 关闭按钮（包括右上角关闭按钮和点击屏幕关闭）
  static Future<void> trackVipAlertClose() async {
    try {
      // 获取基础参数（device_id + user_id）
      final params = await _buildBaseParams();
      
      // 移除 click_time，因为 API 文档中没有这个参数
      params.remove('click_time');
      
      // 添加关闭按钮参数
      params['vip_alert_close'] = 'vip_alert_close';
      
      // 发送埋点事件
      await _trackEvent('home_vip_alert', params, '充值弹窗-关闭');
    } catch (e) {
      debugPrint('❌ 充值弹窗关闭埋点：上报数据失败 - $e');
    }
  }

  /// 埋点：充值弹窗 - 立即查看按钮点击
  /// 
  /// 事件ID: home_vip_alert
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - vip_alert_open: 立即查看按钮
  static Future<void> trackVipAlertOpen() async {
    try {
      // 获取基础参数（device_id + user_id）
      final params = await _buildBaseParams();
      
      // 移除 click_time，因为 API 文档中没有这个参数
      params.remove('click_time');
      
      // 添加立即查看按钮参数
      params['vip_alert_open'] = 'vip_alert_open';
      
      // 发送埋点事件
      await _trackEvent('home_vip_alert', params, '充值弹窗-立即查看');
    } catch (e) {
      debugPrint('❌ 充值弹窗立即查看埋点：上报数据失败 - $e');
    }
  }

  // ==================== 我的页埋点 ====================
  // TODO: 添加我的页相关埋点方法

  // ==================== 位置页埋点 ====================
  
  /// 埋点：定位页 - 开通会员按钮点击
  /// 
  /// 事件ID: open_membership_button
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - click_time: 点击时间
  static Future<void> trackOpenMembershipButton() async {
    final params = await _buildBaseParams();
    await _trackEvent('open_membership_button', params, '定位页-开通会员按钮点击');
  }

  /// 埋点：定位页 - 滑动操作
  /// 
  /// 事件ID: swipe_operation
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - is_vip: 是否会员（已充值、未充值）
  /// - scroll_status: 滑动状态（已上滑、已下滑）
  /// - click_time: 点击时间
  /// 
  /// [isVip] 是否是会员
  /// [scrollStatus] 滑动状态：已上滑、已下滑
  static Future<void> trackSwipeOperation({
    required bool isVip,
    required String scrollStatus,
  }) async {
    try {
      // 获取基础参数（device_id + user_id + click_time）
      final params = await _buildBaseParams();
      
      // 添加滑动操作特有参数
      params['is_vip'] = isVip ? '已充值' : '未充值';
      params['scroll_status'] = scrollStatus;
      
      // 发送埋点事件
      await _trackEvent('swipe_operation', params, '定位页-滑动操作');
    } catch (e) {
      debugPrint('❌ 定位页滑动操作埋点：上报数据失败 - $e');
    }
  }

  /// 埋点：定位页 - 页面浏览时长（开始计时）
  /// 
  /// 事件ID: location_page
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - enter_time: 进入时间
  /// - is_bind: 是否绑定（已绑定、未绑定）
  /// - is_vip: 是否会员（已充值、未充值）
  /// - has_location: 定位权限（开启、关闭）
  /// 
  /// [isBindPartner] 是否绑定伴侣
  /// [isVip] 是否是会员
  /// [hasLocation] 是否有定位权限
  static Future<void> trackLocationPageBegin({
    required bool isBindPartner,
    required bool isVip,
    required bool hasLocation,
  }) async {
    try {
      // 获取基础参数（device_id + user_id）
      final user = UserManager.currentUser;
      final deviceId = user?.deviceId ?? '';
      final enterTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      
      final params = <String, String>{
        'device_id': deviceId,
        'user_id': user?.id?.toString() ?? '',
        'enter_time': enterTime,
        'is_bind': isBindPartner ? '已绑定' : '未绑定',
        'is_vip': isVip ? '已充值' : '未充值',
        'has_location': hasLocation ? '开启' : '关闭',
      };
      
      // 开始事件计时
      await UmengAnalytics.eventBegin('location_page', params: params);
      debugPrint('📊 定位页-页面浏览：开始计时');
    } catch (e) {
      debugPrint('❌ 定位页页面浏览埋点（开始）：上报数据失败 - $e');
    }
  }

  /// 埋点：定位页 - 页面浏览时长（结束计时）
  /// 
  /// 事件ID: location_page
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - enter_time: 进入时间
  /// - is_bind: 是否绑定（已绑定、未绑定）
  /// - is_vip: 是否会员（已充值、未充值）
  /// - has_location: 定位权限（开启、关闭）
  /// 
  /// [isBindPartner] 是否绑定伴侣
  /// [isVip] 是否是会员
  /// [hasLocation] 是否有定位权限
  static Future<void> trackLocationPageEnd({
    required bool isBindPartner,
    required bool isVip,
    required bool hasLocation,
  }) async {
    try {
      // 获取基础参数（device_id + user_id）
      final user = UserManager.currentUser;
      final deviceId = user?.deviceId ?? '';
      final enterTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      
      final params = <String, String>{
        'device_id': deviceId,
        'user_id': user?.id?.toString() ?? '',
        'enter_time': enterTime,
        'is_bind': isBindPartner ? '已绑定' : '未绑定',
        'is_vip': isVip ? '已充值' : '未充值',
        'has_location': hasLocation ? '开启' : '关闭',
      };
      
      // 结束事件计时
      await UmengAnalytics.eventEnd('location_page', params: params);
      debugPrint('📊 定位页-页面浏览：结束计时');
    } catch (e) {
      debugPrint('❌ 定位页页面浏览埋点（结束）：上报数据失败 - $e');
    }
  }

  /// 埋点：定位页 - 地图模式切换
  /// 
  /// 事件ID: map_mode_switch
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - map_mode: 地图模式（经典模式、卫星模式）
  /// - click_time: 点击时间
  /// 
  /// [mapType] 地图类型：1=经典模式，2=卫星模式
  static Future<void> trackMapModeSwitch({
    required int mapType,
  }) async {
    try {
      // 获取基础参数（device_id + user_id + click_time）
      final params = await _buildBaseParams();
      
      // 添加地图模式特有参数
      params['map_mode'] = mapType == 1 ? '经典模式' : '卫星模式';
      
      // 发送埋点事件
      await _trackEvent('map_mode_switch', params, '定位页-地图模式切换');
    } catch (e) {
      debugPrint('❌ 定位页地图模式切换埋点：上报数据失败 - $e');
    }
  }

  /// 埋点：定位页 - 刷新地图按钮点击
  /// 
  /// 事件ID: refresh_map_button
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - click_time: 点击时间
  static Future<void> trackRefreshMapButton() async {
    final params = await _buildBaseParams();
    await _trackEvent('refresh_map_button', params, '定位页-刷新地图按钮点击');
  }

  /// 埋点：定位页 - 立即去绑定按钮点击
  /// 
  /// 事件ID: bind_now_button
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - click_time: 点击时间
  static Future<void> trackBindNowButton() async {
    final params = await _buildBaseParams();
    await _trackEvent('bind_now_button', params, '定位页-立即去绑定按钮点击');
  }

  /// 埋点：定位页 - 开启自己定位按钮点击
  /// 
  /// 事件ID: enable_own_location_button
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - click_time: 点击时间
  /// - location_status: 定位状态（开启/关闭）
  static Future<void> trackEnableOwnLocation({required bool isEnabled}) async {
    final params = await _buildBaseParams();
    params['location_status'] = isEnabled ? '开启' : '关闭';
    await _trackEvent('enable_own_location_button', params, '定位页-开启自己定位按钮点击');
  }

  /// 埋点：定位页 - 对方开启定位状态提示点击
  /// 
  /// 事件ID: partner_location_status_prompt
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - click_time: 点击时间
  static Future<void> trackPartnerLocationStatusPrompt() async {
    final params = await _buildBaseParams();
    await _trackEvent('partner_location_status_prompt', params, '定位页-对方开启定位状态提示点击');
  }

  /// 埋点：定位页 - 人物切换按钮点击（顶部头像切换）
  /// 
  /// 事件ID: character_switch_button
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - click_time: 点击时间
  /// - switch_status: 切换状态（切换成TA或自己）
  static Future<void> trackCharacterSwitch({required bool isMyself}) async {
    final params = await _buildBaseParams();
    params['switch_status'] = isMyself ? '自己' : 'TA';
    await _trackEvent('character_switch_button', params, '定位页-人物切换按钮点击');
  }

  /// 埋点：定位页 - 离线提示"查看原因"点击
  /// 
  /// 事件ID: location_offline_reason
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - click_time: 点击时间
  static Future<void> trackLocationOfflineReason() async {
    final params = await _buildBaseParams();
    await _trackEvent('location_offline_reason', params, '定位页-离线提示查看原因点击');
  }

  /// 埋点：定位页 - 当前状态按钮点击（地图右侧第一个按钮）
  /// 
  /// 事件ID: location_current_state
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - click_time: 点击时间
  static Future<void> trackCurrentStateButton() async {
    final params = await _buildBaseParams();
    await _trackEvent('location_current_state', params, '定位页-当前状态按钮点击');
  }

  /// 埋点：定位页 - 位置提醒按钮点击（地图右侧第三个按钮）
  /// 
  /// 事件ID: location_location_knock
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - click_time: 点击时间
  static Future<void> trackLocationReminderButton() async {
    final params = await _buildBaseParams();
    await _trackEvent('location_location_knock', params, '定位页-位置提醒按钮点击');
  }

  /// 埋点：定位页 - Ta的足迹按钮点击（地图右侧第二个按钮）
  /// 
  /// 事件ID: location_her_track
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - click_time: 点击时间
  static Future<void> trackHerTrackButton() async {
    final params = await _buildBaseParams();
    await _trackEvent('location_her_track', params, '定位页-Ta的足迹按钮点击');
  }

  // ==================== 状态页面埋点 ====================

  /// 埋点：状态页面 - 浏览事件
  /// 
  /// 事件ID: state_current_page
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - is_bind: 用户情侣绑定状态（已绑定/未绑定）
  /// - is_vip: 用户充值状态（已充值/未充值）
  /// - stay_duration: 页面停留时长（如：2s）
  /// - scroll_times: 页面滑动次数（如：3次）
  static Future<void> trackStatePageView({
    required bool isBind,
    required bool isVip,
    required String stayDuration,
    required int scrollTimes,
  }) async {
    final params = await _buildBaseParams();
    params['is_bind'] = isBind ? '已绑定' : '未绑定';
    params['is_vip'] = isVip ? '已充值' : '未充值';
    params['stay_duration'] = stayDuration;
    params['scroll_times'] = '${scrollTimes}次';
    await _trackEvent('state_current_page', params, '状态页面-浏览事件');
  }

  /// 埋点：状态页面 - 设置完成（点击保存弹窗的确认按钮）
  /// 
  /// 事件ID: state_setting_complet
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - state_info: 状态类型（如：亲亲、开心、玩游戏）
  /// - state_duration: 状态有效期（如：1小时、2小时、3小时）
  /// - click_time: 确定时间
  static Future<void> trackStateSettingComplete({
    required String stateInfo,
    required int stateDurationHours,
  }) async {
    final params = await _buildBaseParams();
    params['state_info'] = stateInfo;
    params['state_duration'] = '${stateDurationHours}小时';
    await _trackEvent('state_setting_complet', params, '状态页面-设置完成');
  }

  /// 埋点：状态页面 - 删除状态
  /// 
  /// 事件ID: state_delete
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - click_time: 点击删除时间
  static Future<void> trackStateDelete() async {
    final params = await _buildBaseParams();
    await _trackEvent('state_delete', params, '状态页面-删除状态');
  }

  // ==================== 足迹页埋点 ====================
  
  /// 埋点：足迹页 - 页面浏览
  /// 
  /// 事件ID: footprint_page
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - stay_duration: 页面停留时长（如：45s）
  /// - is_bind: 用户情侣绑定状态（已绑定/未绑定）
  /// - is_vip: 用户充值状态（已充值/未充值）
  /// - can_location: 位置权限（已开启/未开启）
  /// 
  /// [stayDuration] 停留时长
  /// [isBind] 是否绑定情侣
  /// [isVip] 是否是会员
  /// [canLocation] 是否有位置权限
  static Future<void> trackFootprintPageView({
    required String stayDuration,
    required bool isBind,
    required bool isVip,
    required bool canLocation,
  }) async {
    final params = await _buildBaseParams();
    params['stay_duration'] = stayDuration;
    params['is_bind'] = isBind ? '已绑定' : '未绑定';
    params['is_vip'] = isVip ? '已充值' : '未充值';
    params['can_location'] = canLocation ? '已开启' : '未开启';
    
    await _trackEvent('footprint_page', params, '足迹页面-页面浏览');
  }
  
  /// 埋点：足迹页 - 滑动状态
  /// 
  /// 事件ID: footprint_page_swipe_state
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 操作时间
  /// - click_state: 滑动状态（小屏/中屏/大屏）
  /// 
  /// [clickState] 滑动状态：小屏、中屏、大屏
  static Future<void> trackFootprintPageSwipeState({
    required String clickState,
  }) async {
    final params = await _buildBaseParams();
    params['click_state'] = clickState;
    
    await _trackEvent('footprint_page_swipe_state', params, '足迹页面-滑动状态');
  }
  
  /// 埋点：足迹页 - 停留点点击
  /// 
  /// 事件ID: footprint_stay_button
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 操作时间
  static Future<void> trackFootprintStayButton() async {
    final params = await _buildBaseParams();
    await _trackEvent('footprint_stay_button', params, '足迹页面-停留点点击');
  }
  
  /// 埋点：足迹页 - 停留位置关闭按钮
  /// 
  /// 事件ID: footprint_stay_close_button
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 操作时间
  static Future<void> trackFootprintStayCloseButton() async {
    final params = await _buildBaseParams();
    await _trackEvent('footprint_stay_close_button', params, '足迹页面-停留位置关闭按钮');
  }

  // ==================== 位置提醒列表页埋点 ====================
  
  /// 埋点：位置提醒列表 - 页面浏览
  /// 
  /// 事件ID: location_knock_list
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - stay_duration: 页面停留时长（如：2s）
  /// - scroll_times: 页面滑动次数（如：3次）
  static Future<void> trackLocationKnockListPageView({
    required String stayDuration,
    required int scrollTimes,
  }) async {
    final params = await _buildBaseParams();
    params['stay_duration'] = stayDuration;
    params['scroll_times'] = '${scrollTimes}次';
    await _trackEvent('location_knock_list', params, '位置提醒列表-页面浏览');
  }

  /// 埋点：位置提醒列表 - 添加地点位置
  /// 
  /// 事件ID: location_knock_add
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - click_time: 点击时间
  static Future<void> trackLocationKnockAdd() async {
    final params = await _buildBaseParams();
    await _trackEvent('location_knock_add', params, '位置提醒列表-添加地点位置');
  }

  /// 埋点：位置提醒列表 - 删除操作
  /// 
  /// 事件ID: location_knock_delete
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - click_time: 点击时间
  static Future<void> trackLocationKnockDelete() async {
    final params = await _buildBaseParams();
    await _trackEvent('location_knock_delete', params, '位置提醒列表-删除操作');
  }

  // ==================== 添加地点页面埋点 ====================

  /// 埋点：添加地点页面 - 页面浏览
  /// 
  /// 事件ID: location_knock_address_add
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - stay_duration: 页面停留时长（如：2s）
  /// - click_time: 进入时间
  static Future<void> trackLocationKnockAddressAddPageView({
    required String stayDuration,
  }) async {
    final params = await _buildBaseParams();
    params['stay_duration'] = stayDuration;
    await _trackEvent('location_knock_address_add', params, '添加地点页面-页面浏览');
  }

  /// 埋点：添加地点页面 - 保存操作
  /// 
  /// 事件ID: location_knock_address_save
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - click_time: 点击时间
  static Future<void> trackLocationKnockAddressSave() async {
    final params = await _buildBaseParams();
    await _trackEvent('location_knock_address_save', params, '添加地点页面-保存操作');
  }

  // ==================== 轨迹页埋点 ====================

  /// 埋点：足迹页 - 立即去绑定按钮
  /// 
  /// 事件ID: footprint_bind_now_button
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 操作时间
  static Future<void> trackFootprintBindNowButton() async {
    final params = await _buildBaseParams();
    await _trackEvent('footprint_bind_now_button', params, '足迹页面-立即去绑定按钮');
  }

  /// 埋点：足迹页 - 开通会员按钮
  /// 
  /// 事件ID: footprint_open_membership_button
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 操作时间
  static Future<void> trackFootprintOpenMembershipButton() async {
    final params = await _buildBaseParams();
    await _trackEvent('footprint_open_membership_button', params, '足迹页面-开通会员按钮');
  }

  /// 埋点：足迹页 - 日期按钮
  /// 
  /// 事件ID: date_button
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  /// - is_bind: 用户情侣绑定状态（已绑定/未绑定）
  static Future<void> trackDateButton(bool isBind) async {
    final params = await _buildBaseParams();
    params['is_bind'] = isBind ? '已绑定' : '未绑定';
    await _trackEvent('date_button', params, '足迹页面-日期按钮');
  }

  /// 埋点：足迹页 - 轨迹回放按钮
  /// 
  /// 事件ID: foot_moving
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  static Future<void> trackFootMoving() async {
    final params = await _buildBaseParams();
    await _trackEvent('foot_moving', params, '足迹页面-轨迹回放按钮');
  }

  // ==================== 用机记录页面埋点 ====================

  /// 埋点：用机记录页面 - 页面浏览
  /// 
  /// 事件ID: device_usage_record
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - stay_duration: 页面停留时长（如：2s）
  /// - is_bind: 用户情侣绑定状态（已绑定/未绑定）
  /// - is_vip: 用户充值状态（已充值/未充值）
  /// - click_time: 进入页面时间
  static Future<void> trackDeviceUsageRecordPageView({
    required String stayDuration,
    required bool isBind,
    required bool isVip,
  }) async {
    final params = await _buildBaseParams();
    params['stay_duration'] = stayDuration;
    params['is_bind'] = isBind ? '已绑定' : '未绑定';
    params['is_vip'] = isVip ? '已充值' : '未充值';
    await _trackEvent('device_usage_record', params, '用机记录页面-页面浏览');
  }

  /// 埋点：用机记录页面 - 立即绑定按钮
  /// 
  /// 事件ID: bind_immediately
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  static Future<void> trackBindImmediately() async {
    final params = await _buildBaseParams();
    await _trackEvent('bind_immediately', params, '用机记录页面-立即绑定按钮');
  }

  // ==================== 会员可见相关埋点 ====================

  /// 埋点：会员可见按钮点击
  /// 
  /// 事件ID: membership_only
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  /// 
  /// 触发场景：
  /// - 用机记录页面各标签下的"会员可查看"按钮点击
  /// - 屏幕使用时长详情页的"开通会员"毛玻璃遮罩点击
  /// - 解锁记录项的毛玻璃遮罩点击
  static Future<void> trackMembershipOnly() async {
    final params = await _buildBaseParams();
    await _trackEvent('membership_only', params, '会员可见按钮');
  }

  // ==================== 绑定页面埋点 ====================

  /// 埋点：绑定页面 - 浏览事件
  /// 
  /// 事件ID: bind_page
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID（通过用户设备号生成）
  /// - user_id: 用户ID（已登录时）
  /// - stay_duration: 页面停留时长（如：2s）
  /// - previous_name: 上一个页面名称
  /// - previous_id: 上一个页面id
  /// 
  /// [stayDuration] 停留时长（格式：如"2s"）
  /// [previousName] 上一个页面名称
  /// [previousId] 上一个页面ID
  static Future<void> trackBindPageView({
    required String stayDuration,
    required String previousName,
    required String previousId,
  }) async {
    try {
      // 获取基础参数（device_id + user_id + click_time）
      final params = await _buildBaseParams();
      
      // 移除 click_time，因为浏览事件不需要点击时间
      params.remove('click_time');
      
      // 添加绑定页面特有参数
      params['stay_duration'] = stayDuration;
      params['previous_name'] = previousName;
      params['previous_id'] = previousId;
      
      // 发送埋点事件
      await _trackEvent('bind_page', params, '绑定页面-浏览事件');
    } catch (e) {
      debugPrint('❌ 绑定页面浏览埋点：上报数据失败 - $e');
    }
  }

  /// 埋点：绑定按钮 - 点击事件
  /// 
  /// 事件ID: bind_code_button
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - click_time: 点击时间
  /// 
  /// 触发场景：用户在输入框输入匹配码后点击确认绑定按钮
  static Future<void> trackBindCodeButton() async {
    final params = await _buildBaseParams();
    await _trackEvent('bind_code_button', params, '绑定按钮点击');
  }

  /// 埋点：微信邀请 - 点击事件
  /// 
  /// 事件ID: wechat_invite
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - click_time: 点击时间
  /// 
  /// 触发场景：用户点击微信分享按钮
  static Future<void> trackWechatInvite() async {
    final params = await _buildBaseParams();
    await _trackEvent('wechat_invite', params, '微信邀请点击');
  }

  /// 埋点：QQ邀请 - 点击事件
  /// 
  /// 事件ID: qq_invite
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - click_time: 点击时间
  /// 
  /// 触发场景：用户点击QQ分享按钮
  static Future<void> trackQQInvite() async {
    final params = await _buildBaseParams();
    await _trackEvent('qq_invite', params, 'QQ邀请点击');
  }

  /// 埋点：扫码按钮 - 点击事件
  /// 
  /// 事件ID: scan_to_bind
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID（已登录时）
  /// - click_time: 点击时间
  /// 
  /// 触发场景：用户点击扫描二维码按钮
  static Future<void> trackScanToBind() async {
    final params = await _buildBaseParams();
    await _trackEvent('scan_to_bind', params, '扫码按钮点击');
  }

  // ==================== 我的页面埋点 ====================

  /// 埋点：我的页面 - 浏览事件
  /// 
  /// 事件ID: my_page
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID（通过用户设备号生成）
  /// - user_id: 用户ID（已登录时）
  /// - stay_duration: 页面停留时长（如：2s）
  /// - can_scroll: 页面是否滑动（是/否）
  /// - scroll_times: 页面滑动次数（如：3次）
  /// 
  /// [stayDuration] 停留时长（格式：如"2s"）
  /// [canScroll] 页面是否滑动
  /// [scrollTimes] 页面滑动次数
  static Future<void> trackMyPageView({
    required String stayDuration,
    required bool canScroll,
    required int scrollTimes,
  }) async {
    try {
      // 获取基础参数（device_id + user_id + click_time）
      final params = await _buildBaseParams();
      
      // 移除 click_time，因为浏览事件不需要点击时间
      params.remove('click_time');
      
      // 添加我的页面特有参数
      params['stay_duration'] = stayDuration;
      params['can_scroll'] = canScroll ? '是' : '否';
      params['scroll_times'] = '${scrollTimes}次';
      
      // 发送埋点事件
      await _trackEvent('my_page', params, '我的页面-浏览事件');
    } catch (e) {
      debugPrint('❌ 我的页面浏览埋点：上报数据失败 - $e');
    }
  }

  // ==================== 恋爱信息页面埋点 ====================

  /// 埋点：个人信息_性别 - 点击事件
  /// 
  /// 事件ID: my_personal_info_gender
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  /// - gender: 性别状态（男/女）
  /// 
  /// [gender] 性别状态：男 或 女
  /// 
  /// 触发场景：用户在恋爱信息页面选择性别时
  static Future<void> trackPersonalInfoGender({
    required String gender,
  }) async {
    final params = await _buildBaseParams();
    params['gender'] = gender;
    await _trackEvent('my_personal_info_gender', params, '个人信息-性别点击');
  }

  /// 埋点：个人信息_头像 - 点击事件
  /// 
  /// 事件ID: my_personal_info_avatar
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  /// - is_avatar: 头像是否更换（是/否）
  /// 
  /// [isAvatarChanged] 头像是否更换
  /// 
  /// 触发场景：用户在恋爱信息页面更换头像时
  static Future<void> trackPersonalInfoAvatar({
    required bool isAvatarChanged,
  }) async {
    final params = await _buildBaseParams();
    params['is_avatar'] = isAvatarChanged ? '是' : '否';
    await _trackEvent('my_personal_info_avatar', params, '个人信息-头像点击');
  }

  /// 埋点：个人信息_年龄 - 点击事件
  /// 
  /// 事件ID: my_personal_info_birth
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  /// - birth: 年龄日期（显示具体年龄日期）
  /// 
  /// [birth] 年龄日期（格式：yyyy-MM-dd）
  /// 
  /// 触发场景：用户在恋爱信息页面选择生日时
  static Future<void> trackPersonalInfoBirth({
    required String birth,
  }) async {
    final params = await _buildBaseParams();
    params['birth'] = birth;
    await _trackEvent('my_personal_info_birth', params, '个人信息-年龄点击');
  }

  // ==================== 我的页面点击事件埋点 ====================

  /// 埋点：我的页面-返回 - 点击事件
  /// 
  /// 事件ID: my_leave_event
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  /// 
  /// 触发场景：用户点击我的页面的返回按钮
  static Future<void> trackMyLeaveEvent() async {
    final params = await _buildBaseParams();
    await _trackEvent('my_leave_event', params, '我的页面-返回点击');
  }

  /// 埋点：恋爱信息入口点击 - 点击事件
  /// 
  /// 事件ID: edit_info_page
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  /// 
  /// 触发场景：用户点击恋爱信息入口（头像、标签等）
  static Future<void> trackEditInfoPage() async {
    final params = await _buildBaseParams();
    await _trackEvent('edit_info_page', params, '恋爱信息入口点击');
  }

  /// 埋点：绑定页面 - 点击事件
  /// 
  /// 事件ID: my_bind_page
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  /// 
  /// 触发场景：用户在我的页面点击绑定相关入口
  static Future<void> trackMyBindPage() async {
    final params = await _buildBaseParams();
    await _trackEvent('my_bind_page', params, '绑定页面点击');
  }

  /// 埋点：开通会员 - 点击事件
  /// 
  /// 事件ID: my_open_membership
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  /// - vip_page_type: 会员页面类型（会员页面、终身会员页面）
  /// 
  /// [vipPageType] 会员页面类型
  /// 
  /// 触发场景：用户点击会员相关按钮
  static Future<void> trackMyOpenMembership({
    required String vipPageType,
  }) async {
    final params = await _buildBaseParams();
    params['vip_page_type'] = vipPageType;
    await _trackEvent('my_open_membership', params, '开通会员点击');
  }

  /// 埋点：意见与反馈 - 点击事件
  /// 
  /// 事件ID: feedback
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  /// 
  /// 触发场景：用户点击意见与反馈菜单
  static Future<void> trackFeedback() async {
    final params = await _buildBaseParams();
    await _trackEvent('feedback', params, '意见与反馈点击');
  }

  /// 埋点：联系我们 - 点击事件
  /// 
  /// 事件ID: contact_customer_service
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  /// 
  /// 触发场景：用户点击联系我们菜单
  static Future<void> trackContactCustomerService() async {
    final params = await _buildBaseParams();
    await _trackEvent('contact_customer_service', params, '联系我们点击');
  }

  /// 埋点：关于我们 - 点击事件
  /// 
  /// 事件ID: about_us
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  /// 
  /// 触发场景：用户点击关于我们菜单
  static Future<void> trackAboutUs() async {
    final params = await _buildBaseParams();
    await _trackEvent('about_us', params, '关于我们点击');
  }

  /// 埋点：首页视图 - 点击事件
  /// 
  /// 事件ID: home_view
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  /// 
  /// 触发场景：用户点击首页视图菜单
  static Future<void> trackHomeView() async {
    final params = await _buildBaseParams();
    await _trackEvent('home_view', params, '首页视图点击');
  }

  /// 埋点：系统权限 - 点击事件
  /// 
  /// 事件ID: system_permissions
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  /// 
  /// 触发场景：用户点击系统权限菜单
  static Future<void> trackSystemPermissions() async {
    final params = await _buildBaseParams();
    await _trackEvent('system_permissions', params, '系统权限点击');
  }

  /// 埋点：常见问题 - 点击事件
  /// 
  /// 事件ID: faq
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  /// 
  /// 触发场景：用户点击常见问题菜单
  static Future<void> trackFaq() async {
    final params = await _buildBaseParams();
    await _trackEvent('faq', params, '常见问题点击');
  }

  /// 埋点：账号及隐私安全 - 点击事件
  /// 
  /// 事件ID: account_privacy_security
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  /// 
  /// 触发场景：用户点击账号及隐私安全菜单
  static Future<void> trackAccountPrivacySecurity() async {
    final params = await _buildBaseParams();
    await _trackEvent('account_privacy_security', params, '账号及隐私安全点击');
  }

  /// 埋点：分享App - 点击事件
  /// 
  /// 事件ID: my_share
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  /// 
  /// 触发场景：用户点击分享APP菜单
  static Future<void> trackMyShare() async {
    final params = await _buildBaseParams();
    await _trackEvent('my_share', params, '分享App点击');
  }

  /// 埋点：防偷拍检查 - 点击事件
  /// 
  /// 事件ID: safe_check
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  /// 
  /// 触发场景：用户点击防偷拍检查菜单
  static Future<void> trackSafeCheck() async {
    final params = await _buildBaseParams();
    await _trackEvent('safe_check', params, '防偷拍检查点击');
  }

  // ==================== 消息中心/互动消息页面埋点 ====================

  /// 埋点：接收绑定按钮 - 点击事件
  /// 
  /// 事件ID: accept_bind_button
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  /// - other_id: 绑定情侣id
  /// 
  /// [otherId] 绑定情侣的用户ID
  /// 
  /// 触发场景：用户在消息中心点击"同意绑定"按钮
  static Future<void> trackAcceptBindButton({
    required String otherId,
  }) async {
    final params = await _buildBaseParams();
    params['other_id'] = otherId;
    await _trackEvent('accept_bind_button', params, '接收绑定按钮点击');
  }

  /// 埋点：拒绝绑定按钮 - 点击事件
  /// 
  /// 事件ID: reject_bind_button
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  /// 
  /// 触发场景：用户在消息中心点击"拒绝绑定"按钮
  static Future<void> trackRejectBindButton() async {
    final params = await _buildBaseParams();
    await _trackEvent('reject_bind_button', params, '拒绝绑定按钮点击');
  }

  /// 埋点：互动消息页面 - 浏览事件
  /// 
  /// 事件ID: message_center_page
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - stay_duration: 页面停留时长
  /// - can_scroll: 页面是否滑动
  /// - is_bind: 情侣绑定状态（已绑定、未绑定）
  /// 
  /// [stayDuration] 页面停留时长（如：2s）
  /// [canScroll] 页面是否滑动
  /// [isBind] 情侣绑定状态
  /// 
  /// 触发场景：用户退出消息中心页面时
  static Future<void> trackMessageCenterPageView({
    required String stayDuration,
    required bool canScroll,
    required String isBind,
  }) async {
    try {
      final params = await _buildBaseParams();
      params.remove('click_time'); // 浏览事件不需要点击时间
      params['stay_duration'] = stayDuration;
      params['can_scroll'] = canScroll ? '是' : '否';
      params['is_bind'] = isBind;
      await _trackEvent('message_center_page', params, '互动消息页面-浏览事件');
    } catch (e) {
      debugPrint('❌ 互动消息页面浏览埋点：上报数据失败 - $e');
    }
  }

  /// 埋点：19元弹窗 - 支付事件
  /// 
  /// 事件ID: vip_sale
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  /// - vip_price: 会员金额（如：12.80）
  /// - vip_name: 会员名称（如：双人月度会员）
  /// - pay_type: 支付方式（如：支付宝）
  /// - is_renew: 是否是续费（是续费、不是续费）
  /// - previous_name: 上个页面名称
  /// - pay_result: 支付结果（如：支付成功、支付取消、点击支付）
  /// 
  /// [vipPrice] 会员金额
  /// [vipName] 会员名称
  /// [payType] 支付方式
  /// [isRenew] 是否是续费
  /// [previousName] 上个页面名称
  /// [payResult] 支付结果（支付成功、支付取消、点击支付等）
  /// 
  /// 触发场景：从19元弹窗进行支付操作时（包括支付成功、取消等所有支付结果）
  static Future<void> trackVipSale({
    required String vipPrice,
    required String vipName,
    required String payType,
    required String isRenew,
    required String previousName,
    required String payResult,
  }) async {
    final params = await _buildBaseParams();
    params['vip_price'] = vipPrice;
    params['vip_name'] = vipName;
    params['pay_type'] = payType;
    params['is_renew'] = isRenew;
    params['previous_name'] = previousName;
    params['pay_result'] = payResult;
    await _trackEvent('vip_sale', params, '19元弹窗支付');
  }

  // ==================== 会员页面埋点 ====================

  /// 埋点：会员页面 - 浏览事件
  /// 
  /// 事件ID: membership_page
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - stay_duration: 页面停留时长（如：2s）
  /// - can_scroll: 页面是否滑动（是/否）
  /// - scroll_times: 页面滑动次数（如：3次）
  /// - previous_name: 上个页面名称
  /// - is_vip: 是否开通会员（开通/未开通）
  /// - previous_id: 上个页面id
  /// 
  /// [stayDuration] 页面停留时长
  /// [canScroll] 页面是否滑动
  /// [scrollTimes] 页面滑动次数
  /// [previousName] 上个页面名称
  /// [isVip] 是否开通会员
  /// [previousId] 上个页面id
  /// 
  /// 触发场景：用户退出会员页面时
  static Future<void> trackMembershipPageView({
    required String stayDuration,
    required bool canScroll,
    required int scrollTimes,
    required String previousName,
    required String isVip,
    required String previousId,
  }) async {
    try {
      final params = await _buildBaseParams();
      params.remove('click_time'); // 浏览事件不需要点击时间
      params['stay_duration'] = stayDuration;
      params['can_scroll'] = canScroll ? '是' : '否';
      params['scroll_times'] = '${scrollTimes}次';
      params['previous_name'] = previousName;
      params['is_vip'] = isVip;
      params['previous_id'] = previousId;
      await _trackEvent('membership_page', params, '会员页面-浏览事件');
    } catch (e) {
      debugPrint('❌ 会员页面浏览埋点：上报数据失败 - $e');
    }
  }

  /// 埋点：会员页面返回 - 点击事件
  /// 
  /// 事件ID: membership_leave
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  /// 
  /// 触发场景：用户点击会员页面返回按钮
  static Future<void> trackMembershipLeave() async {
    final params = await _buildBaseParams();
    await _trackEvent('membership_leave', params, '会员页面返回点击');
  }

  /// 埋点：会员服务协议 - 点击事件
  /// 
  /// 事件ID: membership_service_agreement
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  /// 
  /// 触发场景：用户点击会员服务协议
  static Future<void> trackMembershipServiceAgreement() async {
    final params = await _buildBaseParams();
    await _trackEvent('membership_service_agreement', params, '会员服务协议点击');
  }

  /// 埋点：开通会员 - 支付事件
  /// 
  /// 事件ID: membership_open
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  /// - vip_price: 会员金额（如：12.80）
  /// - vip_name: 会员名称（如：双人月度会员）
  /// - pay_type: 支付方式（如：支付宝）
  /// - is_renew: 是否是续费（是续费/不是续费）
  /// - previous_name: 上个页面名称
  /// - pay_result: 支付结果（如：支付成功、支付取消、点击支付）
  /// 
  /// [vipPrice] 会员金额
  /// [vipName] 会员名称
  /// [payType] 支付方式（支付宝/微信）
  /// [isRenew] 是否是续费
  /// [previousName] 上个页面名称
  /// [payResult] 支付结果（支付成功、支付取消、点击支付等）
  /// 
  /// 触发场景：用户进行会员支付操作时（包括支付成功、取消等所有支付结果）
  static Future<void> trackMembershipOpen({
    required String vipPrice,
    required String vipName,
    required String payType,
    required String isRenew,
    required String previousName,
    required String payResult,
  }) async {
    final params = await _buildBaseParams();
    params['vip_price'] = vipPrice;
    params['vip_name'] = vipName;
    params['pay_type'] = payType;
    params['is_renew'] = isRenew;
    params['previous_name'] = previousName;
    params['pay_result'] = payResult;
    await _trackEvent('membership_open', params, '开通会员点击');
  }

  // ==================== 3.5版本新增埋点 ====================

  /// 埋点：定位-立刻去绑定
  /// 
  /// 事件ID: location3.5_tobind
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  /// 
  /// 触发场景：
  /// 1. 定位页面蒙版上的绑定按钮点击
  /// 2. 定位页面添加位置提醒时未绑定的绑定按钮点击
  static Future<void> trackLocationToBind() async {
    final params = await _buildBaseParams();
    await _trackEvent('location3.5_tobind', params, '定位-立刻去绑定');
  }

  /// 埋点：定位-立刻开通会员
  /// 
  /// 事件ID: location3.5_tovip
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  /// 
  /// 触发场景：定位页面蒙版上的会员按钮点击
  static Future<void> trackLocationToVip() async {
    final params = await _buildBaseParams();
    await _trackEvent('location3.5_tovip', params, '定位-立刻开通会员');
  }

  /// 埋点：足迹-立刻去绑定
  /// 
  /// 事件ID: track3.5_tobind
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  /// 
  /// 触发场景：足迹页面蒙版上的绑定按钮点击
  static Future<void> trackTrackToBind() async {
    final params = await _buildBaseParams();
    await _trackEvent('track3.5_tobind', params, '足迹-立刻去绑定');
  }

  /// 埋点：足迹-立刻开通会员
  /// 
  /// 事件ID: track3.5_tovip
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  /// 
  /// 触发场景：足迹页面蒙版上的会员按钮点击
  static Future<void> trackTrackToVip() async {
    final params = await _buildBaseParams();
    await _trackEvent('track3.5_tovip', params, '足迹-立刻开通会员');
  }

  /// 埋点：用机记录-立刻去绑定
  /// 
  /// 事件ID: history3.5_tobind
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  /// 
  /// 触发场景：用机记录页面蒙版上的绑定按钮点击
  static Future<void> trackHistoryToBind() async {
    final params = await _buildBaseParams();
    await _trackEvent('history3.5_tobind', params, '用机记录-立刻去绑定');
  }

  /// 埋点：用机记录-立刻开通会员
  /// 
  /// 事件ID: history3.5_vip
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  /// 
  /// 触发场景：用机记录页面蒙版上的会员按钮点击
  static Future<void> trackHistoryToVip() async {
    final params = await _buildBaseParams();
    await _trackEvent('history3.5_vip', params, '用机记录-立刻开通会员');
  }

  /// 埋点：绑定页面挽回弹窗
  /// 
  /// 事件ID: home3.5_tobind_reback
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID
  /// - user_id: 用户ID
  /// - click_time: 点击时间
  /// - button_name: 点击按钮名称（"再想想"或"立即绑定"）
  /// 
  /// [buttonName] 按钮名称：再想想 或 立即绑定
  /// 
  /// 触发场景：用户在绑定弹窗关闭时的挽回弹窗中点击按钮
  static Future<void> trackBindingReback({
    required String buttonName,
  }) async {
    final params = await _buildBaseParams();
    params['button_name'] = buttonName;
    await _trackEvent('home3.5_tobind_reback', params, '绑定页面挽回弹窗');
  }

  /// 埋点：会员挽留弹窗 - 点击事件
  /// 
  /// 事件ID: vipretention_popup
  /// 
  /// 参数：
  /// - device_id: 虚拟用户ID（通过用户设备号生成）
  /// - user_id: 用户ID
  /// - button_name: 点击按钮名称（"全部解锁"或"下次再说"）
  /// - click_time: 点击时间（格式：年/月/日 时:分:秒）
  /// - vip_price: 会员金额（如：12.80）
  /// - vip_name: 会员名称（如：双人月度会员）
  /// - pay_type: 支付方式（如：支付宝、微信）
  /// - is_renew: 是否是续费（是续费、不是续费）
  /// - previous_name: 上个页面名称
  /// - pay_result: 支付结果（如：支付成功、支付取消、点击支付、下次再说）
  /// 
  /// [buttonName] 按钮名称：全部解锁 或 下次再说
  /// [vipPrice] 会员金额
  /// [vipName] 会员名称
  /// [payType] 支付方式
  /// [isRenew] 是否是续费
  /// [previousName] 上个页面名称
  /// [payResult] 支付结果
  /// 
  /// 触发场景：用户在会员页面返回时弹出的挽留弹窗中点击按钮
  static Future<void> trackVipRetentionPopup({
    required String buttonName,
    required String vipPrice,
    required String vipName,
    required String payType,
    required String isRenew,
    required String previousName,
    required String payResult,
  }) async {
    final params = await _buildBaseParams();
    params['button_name'] = buttonName;
    params['vip_price'] = vipPrice;
    params['vip_name'] = vipName;
    params['pay_type'] = payType;
    params['is_renew'] = isRenew;
    params['previous_name'] = previousName;
    params['pay_result'] = payResult;
    await _trackEvent('vipretention_popup', params, '会员挽留弹窗');
  }
}

