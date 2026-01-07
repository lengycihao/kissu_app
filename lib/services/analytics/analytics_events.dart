/// 埋点事件ID常量定义
/// 按页面分组，便于维护和查找
/// 
/// 命名规则：
/// - 页面事件：{pageName}Page
/// - 操作事件：{pageName}{ActionName}
library;

/// 用户协议页面事件
class UserAgreementEvents {
  static const String pageId = 'user_agreement_event';
  
  /// 页面浏览事件
  static const String page = 'user_agreement_page';
  
  /// 协议操作事件（同意/不同意）
  static const String operation = 'user_agreement_operation';
}

/// 登录页面事件
class LoginEvents {
  static const String pageId = 'login_event';
  
  /// 页面浏览事件
  static const String page = 'login_page';
  
  /// 手机号输入事件
  static const String phoneInput = 'login_phone_input';
  
  /// 验证码输入事件
  static const String codeInput = 'login_code_input';
  
  /// 获取验证码事件
  static const String getVerificationCode = 'login_get_verification_code';
  
  /// 登录按钮点击事件
  static const String button = 'login_button';
}

/// 个人信息页面事件
class LoginInfoEvents {
  static const String pageId = 'login_info_event';
  
  /// 页面浏览事件
  static const String page = 'login_info_page';
  
  /// 性别选择事件
  static const String gender = 'login_info_gender';
  
  /// 生日选择事件
  static const String selectBirthday = 'login_info_select_birthday';
  
  /// 确认按钮事件
  static const String sureBtn = 'login_info_sure_btn';
}

/// 绑定页面事件
class BindEvents {
  static const String pageId = 'bind_event';
  
  /// 页面浏览事件
  static const String page = 'bind_page';
  
  /// 输入事件
  static const String input = 'bind_input';
  
  /// 确认绑定事件
  static const String sure = 'bind_sure';
  
  /// 取消绑定事件
  static const String cancel = 'bind_cancel';
  
  /// 返回弹窗事件
  static const String rebackDialog = 'bind_reback_dialog';
}

/// 首页事件
class HomeEvents {
  static const String pageId = 'home_event';
  
  /// 页面浏览事件
  static const String page = 'home_page';
  
  /// 底部导航点击事件
  static const String bottomNavigation = 'home_bottom_navigation';
  
  /// 绑定伴侣头像点击事件
  static const String bindPartnerAvatar = 'home_bind_partner_avatar';
  
  /// VIP活动点击事件
  static const String vipAction = 'home_vip_action';
  
  /// 一起拉屎点击事件
  static const String poopTogether = 'home_poop_together';
  
  /// VIP充值弹窗事件
  static const String vipRechargeDialog = 'home_vip_recharge_dialog';
  
  /// 续费提醒弹窗事件
  static const String renewalReminderDialog = 'home_renewal_reminder_dialog';
  
  /// 到期提示弹窗事件
  static const String expiryTipDialog = 'home_expiry_tip_dialog';
}

/// 定位页面事件
class LocationEvents {
  static const String pageId = 'location_event';
  
  /// 页面浏览事件
  static const String page = 'location_page';
  
  /// 返回按钮事件
  static const String back = 'location_back';
  
  /// 当前状态点击事件
  static const String currentState = 'location_current_state';
  
  /// Ta的轨迹点击事件
  static const String herTrack = 'location_her_track';
  
  /// 敲一敲点击事件
  static const String locationKnock = 'location_location_knock';
  
  /// 去绑定点击事件
  static const String toBind = 'location_tobind';
}

/// 足迹页面事件
class TrackEvents {
  static const String pageId = 'track_event';
  
  /// 页面浏览事件
  static const String page = 'track_page';
  
  /// 头像切换事件
  static const String avatarChange = 'track_avatar_change';
  
  /// 返回按钮事件
  static const String back = 'track_back';
  
  /// 历史回放事件
  static const String historyReplay = 'track_history_replay';
  
  /// 去绑定点击事件
  static const String toBind = 'track_tobind';
}

/// 聊天页面事件
class ChatEvents {
  static const String pageId = 'chat_event';
  
  /// 页面浏览事件
  static const String page = 'chat_page';
  
  /// 返回按钮事件
  static const String back = 'chat_back';
  
  /// 设置按钮事件
  static const String setting = 'chat_setting';
  
  /// 背景按钮事件
  static const String bgBtn = 'chat_bg_btn';
  
  /// 气泡按钮事件
  static const String buddleBtn = 'chat_buddle_btn';
  
  /// 主题按钮事件
  static const String themeBtn = 'chat_theme_btn';
}

/// 用机记录页面事件
class PhoneHistoryEvents {
  static const String pageId = 'phone_history_event';
  
  /// 页面浏览事件
  static const String page = 'phone_history_page';
  
  /// 权限引导按钮事件
  static const String permissionGuideBtn = 'permission_guide_btn';
  
  /// 返回按钮事件
  static const String back = 'phone_history_back';
  
  /// 设置按钮事件
  static const String setting = 'phone_history_setting';
  
  /// 手机使用模块点击事件
  static const String phoneUseModule = 'ph_phone_use_module';
  
  /// App使用模块点击事件
  static const String appUseModule = 'ph_app_use_module';
  
  /// 敏感操作模块点击事件
  static const String sensitiveOperationModule = 'ph_sensitive_operation_module';
}

/// 手机使用统计页面事件
class PhoneUseEvents {
  static const String pageId = 'phone_use_event';
  
  /// 页面浏览事件
  static const String page = 'phone_use_page';
}

/// App使用统计页面事件
class AppUseEvents {
  static const String pageId = 'app_use_event';
  
  /// 页面浏览事件
  static const String page = 'app_use_page';
}

/// 敏感操作记录页面事件
class SensitiveEvents {
  static const String pageId = 'sensitive_event';
  
  /// 页面浏览事件
  static const String page = 'sensitive_operation_page';
  
  /// 敏感项VIP按钮事件
  static const String itemVipBtn = 'sensitive_item_vip_btn';
}

/// 我的页面事件
class MyPageEvents {
  static const String pageId = 'my_page_event';
  
  /// 页面浏览事件
  static const String page = 'my_page';
  
  /// 返回按钮事件
  static const String back = 'my_page_back';
  
  /// 头像点击事件
  static const String avatar = 'my_page_avatar';
  
  /// VIP按钮事件
  static const String vipBtn = 'my_page_vip_btn';
  
  /// 权限按钮事件
  static const String permissionBtn = 'my_page_permission_btn';
  
  /// 功能模块点击事件
  static const String functionsModule = 'my_page_functions_moudle';
  
  /// 更换Logo页面事件
  static const String changeLogoPage = 'change_logo_page';
  
  /// 更换Logo项点击事件
  static const String changeLogoItemBtn = 'change_logo_item_btn';
  
  /// 分享按钮事件
  static const String shareBtn = 'my_page_share_btn';
  
  /// 分享渠道事件
  static const String shareChannel = 'my_page_share_channel';
  
  /// 分享关闭事件
  static const String shareClose = 'my_page_share_close';
}

/// 会员中心页面事件
class MembershipEvents {
  static const String pageId = 'membership_event';
  
  /// 页面浏览事件
  static const String page = 'membership_page';
  
  /// 会员类型点击事件
  static const String typeClick = 'membership_page_type_click';
  
  /// 支付按钮事件
  static const String payBtn = 'membership_page_pay_btn';
  
  /// 99元支付事件
  static const String pay99 = 'membership_page_99_pay';
  
  /// 返回弹窗事件
  static const String rebackPopup = 'membership_page_reback_popup';
  
  /// 19元弹窗事件
  static const String popup19Dialog = 'popup_19_dialog';
  
  /// 恢复购买事件
  static const String restorePurchases = 'restore_purchases';
}
