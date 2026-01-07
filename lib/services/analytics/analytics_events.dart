/// 埋点事件ID常量定义
/// 按页面分组，便于维护和查找
/// 
/// 命名规则：
/// - 页面事件：{pageName}Page
/// - 操作事件：{pageName}{ActionName}
library;

/// 用户协议页面事件
class UserAgreementEvents {
  static const String pageId = 'user_agreement_event_id';
  
  /// 页面浏览事件
  static const String page = 'user_agreement_page_event';
  
  /// 协议操作事件（同意/不同意）
  static const String operation = 'user_agreement_operation_event';
}

/// 登录页面事件
class LoginEvents {
  static const String pageId = 'login_event_id';
  
  /// 页面浏览事件
  static const String page = 'login_page_event';
  
  /// 手机号输入事件
  static const String phoneInput = 'login_phone_input_event';
  
  /// 验证码输入事件
  static const String codeInput = 'login_code_input_event';
  
  /// 获取验证码事件
  static const String getVerificationCode = 'login_get_verification_code_event';
  
  /// 登录按钮点击事件
  static const String button = 'login_button_event';
}

/// 个人信息页面事件
class LoginInfoEvents {
  static const String pageId = 'login_info_event_id';
  
  /// 页面浏览事件
  static const String page = 'login_info_page_event';
  
  /// 性别选择事件
  static const String gender = 'login_info_gender_event';
  
  /// 生日选择事件
  static const String selectBirthday = 'login_info_select_birthday_event';
  
  /// 确认按钮事件
  static const String sureBtn = 'login_info_sure_btn_event';
}

/// 绑定页面事件
class BindEvents {
  static const String pageId = 'bind_event_id';
  
  /// 页面浏览事件
  static const String page = 'bind_page_event';
  
  /// 输入匹配码事件
  static const String input = 'bind_input_event';
  
  /// 确认按钮事件
  static const String sure = 'bind_sure_event';
  
  /// 取消按钮事件
  static const String cancel = 'bind_cancel_event';
  
  /// 返回弹窗事件
  static const String rebackDialog = 'bind_reback_dialog_event';
}

/// 首页事件
class HomeEvents {
  static const String pageId = 'home_event_id';
  
  /// 页面浏览事件
  static const String page = 'home_page_event';
  
  /// 底部导航点击事件
  static const String bottomNavigation = 'home_bottom_navigation_event';
  
  /// 绑定伴侣头像点击事件
  static const String bindPartnerAvatar = 'home_bind_partner_avatar_event';
  
  /// VIP活动点击事件
  static const String vipAction = 'home_vip_action_event';
  
  /// 一起拉屎点击事件
  static const String poopTogether = 'home_poop_together_event';
  
  /// VIP充值弹窗事件
  static const String vipRechargeDialog = 'home_vip_recharge_dialog_event';
  
  /// 续费提醒弹窗事件
  static const String renewalReminderDialog = 'home_renewal_reminder_dialog_event';
  
  /// 到期提示弹窗事件
  static const String expiryTipDialog = 'home_expiry_tip_dialog_event';
}

/// 定位页面事件
class LocationEvents {
  static const String pageId = 'location_event_id';
  
  /// 页面浏览事件
  static const String page = 'location_page_event';
  
  /// 返回按钮事件
  static const String back = 'location_back_event';
  
  /// 当前状态点击事件
  static const String currentState = 'location_current_state_event';
  
  /// Ta的轨迹点击事件
  static const String herTrack = 'location_her_track_event';
  
  /// 敲一敲点击事件
  static const String locationKnock = 'location_location_knock_event';
  
  /// 去绑定点击事件
  static const String toBind = 'location_tobind_event';
}

/// 足迹页面事件
class TrackEvents {
  static const String pageId = 'track_event_id';
  
  /// 页面浏览事件
  static const String page = 'track_page_event';
  
  /// 头像切换事件
  static const String avatarChange = 'track_avatar_change_event';
  
  /// 返回按钮事件
  static const String back = 'track_back_event';
  
  /// 历史回放事件
  static const String historyReplay = 'track_history_replay_event';
  
  /// 去绑定点击事件
  static const String toBind = 'track_tobind_event';
}

/// 聊天页面事件
class ChatEvents {
  static const String pageId = 'chat_event_id';
  
  /// 页面浏览事件
  static const String page = 'chat_page_event';
  
  /// 返回按钮事件
  static const String back = 'chat_back_event';
  
  /// 设置按钮事件
  static const String setting = 'chat_setting_event';
  
  /// 背景按钮事件
  static const String bgBtn = 'chat_bg_btn_event';
  
  /// 气泡按钮事件
  static const String buddleBtn = 'chat_buddle_btn_event';
  
  /// 主题按钮事件
  static const String themeBtn = 'chat_theme_btn_event';
}

/// 用机记录页面事件
class PhoneHistoryEvents {
  static const String pageId = 'phone_history_event_id';
  
  /// 页面浏览事件
  static const String page = 'phone_history_page_event';
  
  /// 权限引导按钮事件
  static const String permissionGuideBtn = 'permission_guide_btn_event';
  
  /// 返回按钮事件
  static const String back = 'phone_history_back_event';
  
  /// 设置按钮事件
  static const String setting = 'phone_history_setting_event';
  
  /// 手机使用模块点击事件
  static const String phoneUseModule = 'ph_phone_use_module_event';
  
  /// App使用模块点击事件
  static const String appUseModule = 'ph_app_use_module_event';
  
  /// 敏感操作模块点击事件
  static const String sensitiveOperationModule = 'ph_sensitive_operation_module_event';
}

/// 手机使用统计页面事件
class PhoneUseEvents {
  static const String pageId = 'phone_use_event_id';
  
  /// 页面浏览事件
  static const String page = 'phone_use_page_event';
}

/// App使用统计页面事件
class AppUseEvents {
  static const String pageId = 'app_use_event_id';
  
  /// 页面浏览事件
  static const String page = 'app_use_page_event';
}

/// 敏感操作记录页面事件
class SensitiveEvents {
  static const String pageId = 'sensitive_event_id';
  
  /// 页面浏览事件
  static const String page = 'sensitive_operation_page_event';
  
  /// 敏感项VIP按钮事件
  static const String itemVipBtn = 'sensitive_item_vip_btn_event';
}

/// 更换app图标页面事件
class ChangeLogoEvents {
  static const String pageId = 'my_page_event_id';
  
  /// 页面浏览事件
  static const String page = 'change_logo_page_event';
  
  /// 图标点击事件
  static const String itemBtn = 'change_logo_item_btn_event';
}

/// 我的页面事件
class MyPageEvents {
  static const String pageId = 'my_page_event_id';
  
  /// 页面浏览事件
  static const String page = 'my_page_event';
  
  /// 返回按钮事件
  static const String back = 'my_page_back_event';
  
  /// 头像点击事件
  static const String avatar = 'my_page_avatar_event';
  
  /// VIP按钮事件
  static const String vipBtn = 'my_page_vip_btn_event';
  
  /// 权限按钮事件
  static const String permissionBtn = 'my_page_permission_btn_event';
  
  /// 功能模块点击事件
  static const String functionsModule = 'my_page_functions_moudle_event';
  
  /// 更换Logo页面事件
  static const String changeLogoPage = 'change_logo_page_event';
  
  /// 更换Logo项点击事件
  static const String changeLogoItemBtn = 'change_logo_item_btn_event';
  
  /// 分享按钮事件
  static const String shareBtn = 'my_page_share_btn_event';
  
  /// 分享渠道事件
  static const String shareChannel = 'my_page_share_channel_event';
  
  /// 分享关闭事件
  static const String shareClose = 'my_page_share_close_event';
}

/// 会员中心页面事件
class MembershipEvents {
  static const String pageId = 'membership_event_id';
  
  /// 页面浏览事件
  static const String page = 'membership_page_event';
  
  /// 会员类型点击事件
  static const String typeClick = 'membership_page_type_click_event';
  
  /// 支付按钮事件
  static const String payBtn = 'membership_page_pay_btn_event';
  
  /// 99元支付事件
  static const String pay99 = 'membership_page_99_pay_event';
  
  /// 返回弹窗事件
  static const String rebackPopup = 'membership_page_reback_popup_event';
  
  /// 19元弹窗事件
  static const String popup19Dialog = 'popup_19_dialog_event';
  
  /// 恢复购买事件
  static const String restorePurchases = 'restore_purchases_event';
}
