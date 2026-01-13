import 'analytics_manager.dart';
import 'analytics_events.dart';
import 'analytics_params.dart';

/// 埋点辅助类
/// 提供便捷的埋点方法，封装常用的埋点场景
class AnalyticsHelper {
  AnalyticsHelper._();

  // ==================== 用户协议页面 ====================

  /// 记录用户协议操作
  /// [agree] true=同意, false=不同意
  static void trackAgreementOperation({required bool agree}) {
    AnalyticsManager.instance.trackClick(
      pageId: UserAgreementEvents.pageId,
      eventId: UserAgreementEvents.operation,
      params: {
        AnalyticsParams.operation: agree ? YesNoValue.yes : YesNoValue.no,
      },
    );
  }

  // ==================== 登录页面 ====================

  /// 记录手机号输入事件
  /// [hasInput] 是否有输入内容
  static void trackPhoneInput({required bool hasInput}) {
    AnalyticsManager.instance.trackClick(
      pageId: LoginEvents.pageId,
      eventId: LoginEvents.phoneInput,
      params: {
        AnalyticsParams.isInput: hasInput ? YesNoValue.yes : YesNoValue.no,
      },
    );
  }

  /// 记录验证码输入事件
  /// [hasInput] 是否有输入内容
  static void trackCodeInput({required bool hasInput}) {
    AnalyticsManager.instance.trackClick(
      pageId: LoginEvents.pageId,
      eventId: LoginEvents.codeInput,
      params: {
        AnalyticsParams.isInput: hasInput ? YesNoValue.yes : YesNoValue.no,
      },
    );
  }

  /// 记录获取验证码点击事件
  /// [success] 发送是否成功
  static void trackGetVerificationCode({required bool success}) {
    AnalyticsManager.instance.trackClick(
      pageId: LoginEvents.pageId,
      eventId: LoginEvents.getCode,
      params: {
        AnalyticsParams.sendStatus: success ? SendStatusValue.success : SendStatusValue.failed,
      },
    );
  }

  /// 记录登录按钮点击事件
  /// [success] 登录是否成功
  static void trackLoginButton({required bool success}) {
    AnalyticsManager.instance.trackClick(
      pageId: LoginEvents.pageId,
      eventId: LoginEvents.loginButton,
      params: {
        AnalyticsParams.loginStatus: success ? LoginStatusValue.success : LoginStatusValue.failed,
      },
    );
  }

  // ==================== 个人信息页面 ====================

  /// 记录性别选择
  static void trackGenderSelect({required String gender}) {
    AnalyticsManager.instance.trackClick(
      pageId: LoginInfoEvents.pageId,
      eventId: LoginInfoEvents.gender,
      params: {
        AnalyticsParams.sex: gender,
      },
    );
  }

  /// 记录生日选择
  static void trackBirthdaySelect({required String date}) {
    AnalyticsManager.instance.trackClick(
      pageId: LoginInfoEvents.pageId,
      eventId: LoginInfoEvents.selectBirthday,
      params: {
        AnalyticsParams.selectDate: date,
      },
    );
  }

  /// 记录确认按钮点击
  static void trackLoginInfoSure({
    required bool changeAvatar,
    required bool changeNickname,
  }) {
    AnalyticsManager.instance.trackClick(
      pageId: LoginInfoEvents.pageId,
      eventId: LoginInfoEvents.sureBtn,
      params: {
        AnalyticsParams.changeAvatar: changeAvatar ? YesNoValue.yes : YesNoValue.no,
        AnalyticsParams.changeNickname: changeNickname ? YesNoValue.yes : YesNoValue.no,
      },
    );
  }

  // ==================== 绑定页面 ====================

  /// 记录绑定输入
  static void trackBindInput() {
    AnalyticsManager.instance.trackClick(
      pageId: BindEvents.pageId,
      eventId: BindEvents.input,
    );
  }

  /// 记录确认绑定
  static void trackBindSure({required bool success}) {
    AnalyticsManager.instance.trackClick(
      pageId: BindEvents.pageId,
      eventId: BindEvents.sure,
      params: {
        AnalyticsParams.bindStatus: success ? BindStatusValue.bound : BindStatusValue.notBound,
      },
    );
  }

  /// 记录取消绑定
  static void trackBindCancel() {
    AnalyticsManager.instance.trackClick(
      pageId: BindEvents.pageId,
      eventId: BindEvents.cancel,
    );
  }

  /// 记录返回弹窗点击
  /// [btnStatus] 0=再想想, 1=立马绑定
  static void trackBindRebackDialog({required int btnStatus}) {
    AnalyticsManager.instance.trackClick(
      pageId: BindEvents.pageId,
      eventId: BindEvents.rebackDialog,
      params: {
        AnalyticsParams.btnStatus: btnStatus,
      },
    );
  }

  // ==================== 首页 ====================

  /// 记录底部导航点击
  static void trackBottomNavigation({required String navigationName}) {
    AnalyticsManager.instance.trackClick(
      pageId: HomeEvents.pageId,
      eventId: HomeEvents.bottomNavigation,
      params: {
        AnalyticsParams.navigationName: navigationName,
      },
    );
  }

  /// 记录绑定伴侣头像点击
  static void trackBindPartnerAvatar() {
    AnalyticsManager.instance.trackClick(
      pageId: HomeEvents.pageId,
      eventId: HomeEvents.bindPartnerAvatar,
    );
  }

  /// 记录VIP活动点击
  static void trackVipAction() {
    AnalyticsManager.instance.trackClick(
      pageId: HomeEvents.pageId,
      eventId: HomeEvents.vipAction,
    );
  }

  /// 记录VIP充值弹窗点击
  /// [btnStatus] 1=进入, 0=关闭
  static void trackVipRechargeDialog({required int btnStatus}) {
    AnalyticsManager.instance.trackClick(
      pageId: HomeEvents.pageId,
      eventId: HomeEvents.vipRechargeDialog,
      params: {
        AnalyticsParams.btnStatus: btnStatus,
      },
    );
  }

  /// 记录续费提醒弹窗点击
  /// [btnStatus] 1=进入, 0=关闭
  static void trackRenewalReminderDialog({required int btnStatus}) {
    AnalyticsManager.instance.trackClick(
      pageId: HomeEvents.pageId,
      eventId: HomeEvents.renewalReminderDialog,
      params: {
        AnalyticsParams.btnStatus: btnStatus,
      },
    );
  }

  /// 记录到期提示弹窗点击
  /// [btnStatus] 1=进入, 0=关闭
  static void trackExpiryTipDialog({required int btnStatus}) {
    AnalyticsManager.instance.trackClick(
      pageId: HomeEvents.pageId,
      eventId: HomeEvents.expiryTipDialog,
      params: {
        AnalyticsParams.btnStatus: btnStatus,
      },
    );
  }

  /// 记录一起便便按钮点击
  static void trackPoopTogether() {
    AnalyticsManager.instance.trackClick(
      pageId: HomeEvents.pageId,
      eventId: HomeEvents.poopTogether,
    );
  }

  // ==================== 定位页面 ====================

  /// 记录返回按钮点击
  static void trackLocationBack() {
    AnalyticsManager.instance.trackClick(
      pageId: LocationEvents.pageId,
      eventId: LocationEvents.back,
    );
  }

  /// 记录当前状态点击
  static void trackLocationCurrentState({required bool hasSet}) {
    AnalyticsManager.instance.trackClick(
      pageId: LocationEvents.pageId,
      eventId: LocationEvents.currentState,
      params: {
        AnalyticsParams.setStatus: hasSet ? YesNoValue.yes : YesNoValue.no,
      },
    );
  }

  /// 记录Ta的轨迹点击
  static void trackLocationHerTrack() {
    AnalyticsManager.instance.trackClick(
      pageId: LocationEvents.pageId,
      eventId: LocationEvents.herTrack,
    );
  }

  /// 记录敲一敲点击
  static void trackLocationKnock() {
    AnalyticsManager.instance.trackClick(
      pageId: LocationEvents.pageId,
      eventId: LocationEvents.locationKnock,
    );
  }

  /// 记录去绑定点击
  static void trackLocationToBind({required String btnName}) {
    AnalyticsManager.instance.trackClick(
      pageId: LocationEvents.pageId,
      eventId: LocationEvents.toBind,
      params: {
        AnalyticsParams.btnName: btnName,
      },
    );
  }

  // ==================== 足迹页面 ====================

  /// 记录头像切换
  static void trackTrackAvatarChange({required String avatarName}) {
    AnalyticsManager.instance.trackClick(
      pageId: TrackEvents.pageId,
      eventId: TrackEvents.avatarChange,
      params: {
        AnalyticsParams.avatarName: avatarName,
      },
    );
  }

  /// 记录返回按钮点击
  static void trackTrackBack() {
    AnalyticsManager.instance.trackClick(
      pageId: TrackEvents.pageId,
      eventId: TrackEvents.back,
    );
  }

  /// 记录历史回放
  static void trackTrackHistoryReplay() {
    AnalyticsManager.instance.trackClick(
      pageId: TrackEvents.pageId,
      eventId: TrackEvents.historyReplay,
    );
  }

  /// 记录去绑定/开通会员按钮点击
  static void trackTrackToBind({required String btnName}) {
    AnalyticsManager.instance.trackClick(
      pageId: TrackEvents.pageId,
      eventId: TrackEvents.toBind,
      params: {
        AnalyticsParams.btnName: btnName,
      },
    );
  }

  // ==================== 聊天页面 ====================

  /// 记录返回按钮点击
  static void trackChatBack() {
    AnalyticsManager.instance.trackClick(
      pageId: ChatEvents.pageId,
      eventId: ChatEvents.back,
    );
  }

  /// 记录聊天设置点击
  static void trackChatSetting() {
    AnalyticsManager.instance.trackClick(
      pageId: ChatEvents.pageId,
      eventId: ChatEvents.setting,
    );
  }

  /// 记录背景选择
  static void trackChatBgBtn({required String bgName}) {
    AnalyticsManager.instance.trackClick(
      pageId: ChatEvents.pageId,
      eventId: ChatEvents.bgBtn,
      params: {
        AnalyticsParams.bgName: bgName,
      },
    );
  }

  /// 记录气泡选择
  static void trackChatBuddleBtn({required String buddleName}) {
    AnalyticsManager.instance.trackClick(
      pageId: ChatEvents.pageId,
      eventId: ChatEvents.buddleBtn,
      params: {
        AnalyticsParams.buddleName: buddleName,
      },
    );
  }

  /// 记录聊天主题选择
  static void trackChatThemeBtn({required String themeName}) {
    AnalyticsManager.instance.trackClick(
      pageId: ChatEvents.pageId,
      eventId: ChatEvents.themeBtn,
      params: {
        AnalyticsParams.themeName: themeName,
      },
    );
  }

  // ==================== 用机记录页面 ====================

  /// 记录权限引导按钮点击
  static void trackPermissionGuideBtn() {
    AnalyticsManager.instance.trackClick(
      pageId: PhoneHistoryEvents.pageId,
      eventId: PhoneHistoryEvents.permissionGuideBtn,
    );
  }

  /// 记录返回按钮点击
  static void trackPhoneHistoryBack() {
    AnalyticsManager.instance.trackClick(
      pageId: PhoneHistoryEvents.pageId,
      eventId: PhoneHistoryEvents.back,
    );
  }

  /// 记录设置按钮点击
  static void trackPhoneHistorySetting() {
    AnalyticsManager.instance.trackClick(
      pageId: PhoneHistoryEvents.pageId,
      eventId: PhoneHistoryEvents.setting,
    );
  }

  /// 记录手机使用模块点击
  static void trackPhoneUseModule({required String btnName}) {
    AnalyticsManager.instance.trackClick(
      pageId: PhoneHistoryEvents.pageId,
      eventId: PhoneHistoryEvents.phoneUseModule,
      params: {
        AnalyticsParams.btnName: btnName,
      },
    );
  }

  /// 记录App使用模块点击
  static void trackAppUseModule({required String btnName}) {
    AnalyticsManager.instance.trackClick(
      pageId: PhoneHistoryEvents.pageId,
      eventId: PhoneHistoryEvents.appUseModule,
      params: {
        AnalyticsParams.btnName: btnName,
      },
    );
  }

  /// 记录敏感操作模块点击
  static void trackSensitiveOperationModule({required String btnName}) {
    AnalyticsManager.instance.trackClick(
      pageId: PhoneHistoryEvents.pageId,
      eventId: PhoneHistoryEvents.sensitiveOperationModule,
      params: {
        AnalyticsParams.btnName: btnName,
      },
    );
  }

  // ==================== 敏感操作记录页面 ====================

  /// 记录敏感操作记录item上的vip按钮点击
  static void trackSensitiveItemVipBtn() {
    AnalyticsManager.instance.trackClick(
      pageId: SensitiveEvents.pageId,
      eventId: SensitiveEvents.itemVipBtn,
    );
  }

  // ==================== 我的页面 ====================

  /// 记录返回按钮点击
  static void trackMyPageBack() {
    AnalyticsManager.instance.trackClick(
      pageId: MyPageEvents.pageId,
      eventId: MyPageEvents.back,
    );
  }

  /// 记录头像点击
  static void trackMyPageAvatar() {
    AnalyticsManager.instance.trackClick(
      pageId: MyPageEvents.pageId,
      eventId: MyPageEvents.avatar,
    );
  }

  /// 记录VIP按钮点击
  static void trackMyPageVipBtn({required String btnName}) {
    AnalyticsManager.instance.trackClick(
      pageId: MyPageEvents.pageId,
      eventId: MyPageEvents.vipBtn,
      params: {
        AnalyticsParams.btnName: btnName,
      },
    );
  }

  /// 记录权限按钮点击
  static void trackMyPagePermissionBtn() {
    AnalyticsManager.instance.trackClick(
      pageId: MyPageEvents.pageId,
      eventId: MyPageEvents.permissionBtn,
    );
  }

  /// 记录功能模块点击
  static void trackMyPageFunctionsModule({required String btnName}) {
    AnalyticsManager.instance.trackClick(
      pageId: MyPageEvents.pageId,
      eventId: MyPageEvents.functionsModule,
      params: {
        AnalyticsParams.btnName: btnName,
      },
    );
  }

  /// 记录更换Logo项点击
  static void trackChangeLogoItemBtn({required String logoName}) {
    AnalyticsManager.instance.trackClick(
      pageId: MyPageEvents.pageId,
      eventId: MyPageEvents.changeLogoItemBtn,
      params: {
        AnalyticsParams.logoName: logoName,
      },
    );
  }

  /// 记录分享APP按钮点击
  static void trackMyPageShareBtn() {
    AnalyticsManager.instance.trackClick(
      pageId: MyPageEvents.pageId,
      eventId: MyPageEvents.shareBtn,
    );
  }

  /// 记录分享渠道点击
  static void trackMyPageShareChannel({
    required int channelName,
    required int shareStatus,
  }) {
    AnalyticsManager.instance.trackClick(
      pageId: MyPageEvents.pageId,
      eventId: MyPageEvents.shareChannel,
      params: {
        AnalyticsParams.shareChannelName: channelName,
        AnalyticsParams.shareStatus: shareStatus,
      },
    );
  }

  /// 记录分享弹窗关闭
  static void trackMyPageShareClose() {
    AnalyticsManager.instance.trackClick(
      pageId: MyPageEvents.pageId,
      eventId: MyPageEvents.shareClose,
    );
  }

  // ==================== 会员中心 ====================

  /// 记录会员类型点击
  static void trackMembershipTypeClick({required int clickStatus}) {
    AnalyticsManager.instance.trackClick(
      pageId: MembershipEvents.pageId,
      eventId: MembershipEvents.typeClick,
      params: {
        AnalyticsParams.clickStatus: clickStatus,
      },
    );
  }

  /// 记录支付按钮点击
  static void trackMembershipPayBtn({
    required String memberType,
    required String payType,
    required int payStatus,
    required String btnName,
    required String payDuration,
  }) {
    AnalyticsManager.instance.trackClick(
      pageId: MembershipEvents.pageId,
      eventId: MembershipEvents.payBtn,
      params: {
        AnalyticsParams.memberType: memberType,
        AnalyticsParams.payType: payType,
        AnalyticsParams.payStatus: payStatus,
        AnalyticsParams.btnName: btnName,
        AnalyticsParams.payDuration: payDuration,
      },
    );
  }

  /// 记录返回弹窗点击
  static void trackMembershipRebackPopup({required int btnName}) {
    AnalyticsManager.instance.trackClick(
      pageId: MembershipEvents.pageId,
      eventId: MembershipEvents.rebackPopup,
      params: {
        AnalyticsParams.btnName: btnName,
      },
    );
  }

  /// 记录19元弹窗点击
  static void trackPopup19Dialog({required int btnName}) {
    AnalyticsManager.instance.trackClick(
      pageId: MembershipEvents.pageId,
      eventId: MembershipEvents.popup19Dialog,
      params: {
        AnalyticsParams.btnName: btnName,
      },
    );
  }

  /// 记录恢复购买点击
  static void trackRestorePurchases() {
    AnalyticsManager.instance.trackClick(
      pageId: MembershipEvents.pageId,
      eventId: MembershipEvents.restorePurchases,
    );
  }
}
