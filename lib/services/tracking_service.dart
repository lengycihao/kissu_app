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
}

