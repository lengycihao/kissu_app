/// 埋点事件ID常量定义
/// 按页面分组，便于维护和查找
/// 
/// 命名规则：
/// - 页面事件：{pageName}Page
/// - 操作事件：{pageName}{ActionName}
library;

/// 用户协议页面事件
class UserAgreementEvents {
  static const String pageId = 'user_agreement_page';
  
  /// 页面浏览事件
  static const String page = 'user_agreement_popout_event';
  
  /// 协议操作事件（同意/不同意）
  static const String operation = 'user_agreement_operation_event';
}

/// 登录页面事件
class LoginEvents {
  static const String pageId = 'login_page';
  
  /// 页面浏览事件
  static const String page = 'login_page_event';
  
  /// 手机号输入事件
  static const String phoneInput = 'login_page_phone_input_event';
  
  /// 验证码输入事件
  static const String codeInput = 'login_page_code_input_event';
  
  /// 获取验证码事件
  static const String getCode = 'login_page_get_code_event';
  
  /// 登录按钮点击事件
  static const String loginButton = 'login_page_button_event';
}

/// 个人信息页面事件
class LoginInfoEvents {
  static const String pageId = 'perfect_user_info_page';
  
  /// 页面浏览事件
  static const String page = 'login_info_page_event';
  
  /// 性别选择事件
  static const String gender = 'login_info_page_gender_event';
  
  /// 生日选择事件
  static const String selectBirthday = 'login_info_page_birthday_event';
  
  /// 确认按钮事件
  static const String sureBtn = 'login_info_page_button_event';
}

/// 绑定页面事件
class BindEvents {
  static const String pageId = 'bind_page';
  
  /// 页面浏览事件
  static const String page = 'bind_page_event';
  
  /// 输入匹配码事件
  static const String input = 'bind_page_friend_code_input_event';
  
  /// 确认按钮事件
  static const String sure = 'bind_page_sure_button_event';
  
  /// 取消按钮事件
  static const String cancel = 'bind_page_cancel_event';
  
  /// 返回弹窗事件
  static const String rebackDialog = 'bind_page_reback_dialog_event';
}

/// 首页事件
class HomeEvents {
  static const String pageId = 'home_page';
  
  /// 页面浏览事件
  static const String page = 'home_page_event';
  
  /// 底部导航点击事件
  static const String bottomNavigation = 'home_page_bottom_navigation_event';
  
  /// 绑定伴侣头像点击事件
  static const String bindPartnerAvatar = 'home_page_bind_partner_avatar_event';
  
  /// VIP活动点击事件
  static const String vipAction = 'home_page_vip_action_event';
  
  /// 一起拉屎点击事件
  static const String poopTogether = 'home_page_poop_together_event';

    ///新增 365活动
  static const String seedingEvent = 'home_page_seeding_event';
  
  /// VIP充值弹窗事件
  static const String vipRechargeDialog = 'home_page_vip_recharge_dialog_event';
  
  /// 续费提醒弹窗事件
  static const String renewalReminderDialog = 'home_page_renewal_reminder_dialog_event';
  
  /// 到期提示弹窗事件
  static const String expiryTipDialog = 'home_page_vip_expire_dialog_event';
}

/// 定位页面事件
class LocationEvents {
  static const String pageId = 'location_page';
  
  /// 页面浏览事件
  static const String page = 'location_page_event';
  
  /// 返回按钮事件
  static const String back = 'location_page_back_event';
  
  /// 当前状态点击事件
  static const String currentState = 'location_page_mood_event';
  
  /// Ta的轨迹点击事件
  static const String herTrack = 'location_page_track_event';
  
  /// 位置提醒点击事件
  static const String locationKnock = 'location_page_remind_event';
  
  /// 去绑定点击事件
  static const String toBind = 'location_page_vip_bind_event';
}

/// 足迹页面事件
class TrackEvents {
  static const String pageId = 'track_page';
  
  /// 页面浏览事件
  static const String page = 'track_page_event';
  
  /// 头像切换事件
  static const String avatarChange = 'track_page_change_avatar_event';
  
  /// 返回按钮事件
  static const String back = 'track_page_back_event';
  
  /// 历史回放事件
  static const String historyReplay = 'track_page_history_video_replay_event';
  
  /// 去绑定点击事件
  static const String toBind = 'track_page_vip_bind_event';
}

/// 聊天页面事件
class ChatEvents {
  static const String pageId = 'chat_page';
  
  /// 页面浏览事件
  static const String page = 'chat_page_event';
  
  /// 返回按钮事件
  static const String back = 'chat_page_back_event';
  
  /// 设置按钮事件
  static const String setting = 'chat_page_setting_event';
  
  /// 背景按钮事件
  static const String bgBtn = 'chat_page_bg_btn_event';
  
  /// 气泡按钮事件
  static const String buddleBtn = 'chat_page_buddle_btn_event';
  
  /// 主题按钮事件
  static const String themeBtn = 'chat_page_theme_btn_event';
}

/// 用机记录页面事件
class PhoneHistoryEvents {
  static const String pageId = 'mobile_use_page';
  
  /// 页面浏览事件
  static const String page = 'mobile_use_page_event';
  
  /// 权限引导按钮事件
  static const String permissionGuideBtn = 'mobile_use_page_permission_guide_btn_event';
  
  /// 返回按钮事件
  static const String back = 'mobile_use_page_back_event';
  
  /// 设置按钮事件
  static const String setting = 'mobile_use_page_setting_event';
  
  /// 手机使用模块点击事件
  static const String phoneUseModule = 'mobile_use_page_module_event';
  
  /// App使用模块点击事件
  static const String appUseModule = 'mobile_use_page_app_use_module_event';
  
  /// 敏感操作模块点击事件
  static const String sensitiveOperationModule = 'mobile_use_page_sensitive_operation_module_event';
}

/// 手机使用统计页面事件
class PhoneUseEvents {
  static const String pageId = 'mobile_use_stat_page';
  
  /// 页面浏览事件
  static const String page = 'mobile_use_stat_page_event';
}

/// App使用统计页面事件
class AppUseEvents {
  static const String pageId = 'app_use_stat_page';
  
  /// 页面浏览事件
  static const String page = 'app_use_stat_page_event';
}

/// 敏感操作记录页面事件
class SensitiveEvents {
  static const String pageId = 'sensitive_page';
  
  /// 页面浏览事件
  static const String page = 'sensitive_page_event';
  
  /// 敏感项VIP按钮事件
  static const String itemVipBtn = 'sensitive_page_event_item_vip_btn_event';
}

/// 更换app图标页面事件
class ChangeLogoEvents {
  static const String pageId = 'my_page';
  
  /// 页面浏览事件
  static const String page = 'my_page_change_logo_page_event';
  
  /// 图标点击事件
  static const String itemBtn = 'my_page_change_logo_item_btn_event';
}

/// 我的页面事件
class MyPageEvents {
  static const String pageId = 'my_page';
  
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
  static const String changeLogoPage = 'my_page_change_logo_page_event';
  
  /// 更换Logo项点击事件
  static const String changeLogoItemBtn = 'my_page_change_logo_item_btn_event';
  
  /// 分享按钮事件
  static const String shareBtn = 'my_page_share_btn_event';
  
  /// 分享渠道事件
  static const String shareChannel = 'my_page_share_channel_event';
  
  /// 分享关闭事件
  static const String shareClose = 'my_page_share_close_event';
  
  /// 解除关系item点击事件（设置页面）
  static const String unbind = 'my_page_unbind_event';
  
  /// 解除关系页面确认按钮事件
  static const String unbindBtn = 'my_page_unbind_btn_event';
  
  /// 解除关系弹窗按钮事件
  static const String unbindStatement = 'my_page_unbind_statement_event';
}

/// 会员中心页面事件
class MembershipEvents {
  static const String pageId = 'vip_page';
  
  /// 页面浏览事件
  static const String page = 'vip_page_event';
  
  /// 会员类型点击事件
  static const String typeClick = 'vip_page_type_click_event';
  
  /// 支付按钮事件
  static const String payBtn = 'vip_page_pay_btn_event';
  
  /// 99元支付事件
  static const String pay99 = 'vip_page_99_pay_event';
  
  /// 返回弹窗事件
  static const String rebackPopup = 'vip_page_reback_popup_event';
  
  /// 19元弹窗事件
  static const String popup19Dialog = 'vip_page_19_dialog_event';
  
  /// 恢复购买事件
  static const String restorePurchases = 'vip_page_restore_purchases_event';
}
