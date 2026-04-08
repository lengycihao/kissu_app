import 'package:kissu_app/pages/splash/splash_page.dart';
import 'package:kissu_app/pages/home/home_binding.dart';
import 'package:kissu_app/pages/home/home_page.dart';
import 'package:kissu_app/pages/location/location_v2_binding.dart';
import 'package:kissu_app/pages/location/location_v2_page.dart';
import 'package:kissu_app/pages/login/info_setting/info_setting_binding.dart';
import 'package:kissu_app/pages/login/info_setting/info_setting_page.dart';
import 'package:kissu_app/pages/qr/qr_scan_page.dart';
import 'package:kissu_app/pages/login/login_page.dart';
 import 'package:kissu_app/pages/vip/vip_binding.dart';
import 'package:kissu_app/pages/vip/vip_page.dart';
import 'package:kissu_app/pages/vip/forever_vip_page.dart';
import 'package:kissu_app/pages/vip/forever_vip_controller.dart';
import 'package:kissu_app/pages/mine/sub_pages/system_permission_binding.dart';
import 'package:kissu_app/pages/mine/sub_pages/system_permission_controller.dart';
import 'package:kissu_app/pages/mine/sub_pages/system_permission_page.dart';
import 'package:kissu_app/pages/mine/sub_pages/system_permission_guide_page.dart';
import 'package:kissu_app/pages/permission_setting_page.dart';
import 'package:kissu_app/pages/agreement/agreement_webview_page.dart';
import 'package:kissu_app/pages/mine/love_info/avatar_preview_page.dart';
import 'package:kissu_app/pages/mine/sub_pages/feed_back_page.dart';
import 'package:kissu_app/pages/location/location_state_page.dart';
import 'package:kissu_app/pages/location/location_state_binding.dart';
import 'package:kissu_app/pages/location/location_reminder/location_reminder_page.dart';
import 'package:kissu_app/pages/location/location_reminder/location_reminder_binding.dart';
import 'package:kissu_app/pages/anti_spy/anti_spy_page.dart';
import 'package:kissu_app/pages/anti_spy/anti_spy_binding.dart';
import 'package:kissu_app/pages/message_list/message_list_page.dart';
import 'package:kissu_app/pages/message_list/message_list_binding.dart';
import 'package:kissu_app/pages/message_detail/message_detail_page.dart';
import 'package:kissu_app/pages/message_detail/message_detail_binding.dart';
import 'package:kissu_app/pages/interaction_message/interaction_message_page.dart';
import 'package:kissu_app/pages/interaction_message/interaction_message_binding.dart';
import 'package:kissu_app/pages/track/track_page.dart';
import 'package:kissu_app/pages/track/track_binding.dart';
import 'package:kissu_app/pages/app_icon_selector/app_icon_selector_page.dart';
import 'package:kissu_app/pages/app_icon_selector/app_icon_selector_binding.dart';
import 'package:kissu_app/pages/mine/device_usage/device_usage_page.dart';
import 'package:kissu_app/pages/mine/device_usage/device_usage_binding.dart';
import 'package:kissu_app/pages/mine/device_usage/app_usage_detail_page.dart';
import 'package:kissu_app/pages/mine/device_usage/app_usage_detail_binding.dart';
import 'package:kissu_app/pages/mine/app_usage/app_usage_page.dart';
import 'package:kissu_app/pages/mine/app_usage/app_usage_binding.dart';
import 'package:kissu_app/pages/mine/notification_settings/notification_settings_page.dart';
import 'package:kissu_app/pages/mine/notification_settings/notification_settings_binding.dart';
import 'package:kissu_app/pages/chat/chat_page.dart';
import 'package:kissu_app/pages/chat/chat_binding.dart';
import 'package:kissu_app/pages/chat/chat_settings_page.dart';
import 'package:kissu_app/pages/chat/chat_settings_binding.dart';
import 'package:kissu_app/pages/chat/chat_background_page.dart';
import 'package:kissu_app/pages/chat/chat_background_binding.dart';
import 'package:kissu_app/pages/chat/chat_bubble_page.dart';
import 'package:kissu_app/pages/chat/chat_bubble_binding.dart';
import 'package:kissu_app/pages/chat/chat_theme_page.dart';
import 'package:kissu_app/pages/chat/chat_theme_binding.dart';
import 'package:kissu_app/pages/chat/im_notification_settings/im_notification_settings_page.dart';
import 'package:kissu_app/pages/chat/im_notification_settings/im_notification_settings_binding.dart';
import 'package:kissu_app/pages/check_in_188/check_in_188_page.dart';
import 'package:kissu_app/pages/check_in_188/check_in_188_binding.dart';
import 'package:kissu_app/pages/check_in_188/check_in_188_progress_page.dart';
import 'package:kissu_app/pages/check_in_188/check_in_188_progress_binding.dart';
import 'package:kissu_app/pages/check_in_188/views/check_in_188_recovery_card_page.dart';
import 'package:kissu_app/pages/check_in_188/views/check_in_188_recovery_card_binding.dart';
import 'package:kissu_app/pages/check_in_188/views/check_in_188_card_log_page.dart';
import 'package:kissu_app/pages/check_in_188/views/check_in_188_card_log_binding.dart';
import 'package:kissu_app/pages/check_in_188/views/check_in_188_activity_page.dart';
import 'package:kissu_app/pages/check_in_188/views/check_in_188_activity_binding.dart';
import 'package:kissu_app/pages/mine/lock_screen/lock_screen_page.dart';
import 'package:kissu_app/pages/mine/lock_screen/lock_screen_binding.dart';
import 'package:kissu_app/pages/mine/lock_screen/lock_screen_question_page.dart';
import 'package:kissu_app/pages/widget_center/widget_center_page.dart';
import 'package:kissu_app/pages/widget_center/widget_center_binding.dart';
import 'package:kissu_app/pages/widget_center/widget_add_guide_page.dart';
import 'package:kissu_app/pages/guess_game_v2/game_home_page.dart';
import 'package:kissu_app/pages/guess_game_v2/bindings/game_home_binding.dart';
import 'package:kissu_app/pages/guess_game_v2/topic_selection_page.dart';
import 'package:kissu_app/pages/guess_game_v2/bindings/topic_selection_binding.dart';
import 'package:kissu_app/pages/guess_game_v2/game_play_page.dart';
import 'package:kissu_app/pages/guess_game_v2/bindings/game_play_binding.dart';
import 'package:kissu_app/pages/guess_game_v2/game_success_page.dart';
import 'package:kissu_app/pages/guess_game_v2/game_failed_page.dart';
import 'package:kissu_app/pages/guess_game_v2/game_penalty_photo_page.dart';
import 'package:kissu_app/pages/guess_game_v2/game_penalty_audio_page.dart';
import 'package:kissu_app/pages/guess_game_v2/game_penalty_wait_page.dart';
import 'package:kissu_app/pages/guess_game_v2/game_penalty_record_page.dart';
import 'package:kissu_app/pages/guess_game_v2/game_penalty_select_page.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:get/get.dart';

class KissuRoute {
  static final routes = [
    GetPage(
      name: KissuRoutePath.splash,
      page: () => const SplashPage(),
      transition: Transition.fadeIn,
    ),
    // GetPage(
    //   name: KissuRoutePath.home,
    //   page: () =>  KissuHomePage(),
    //   binding: HomeBinding(),
    // ),
    GetPage(name: KissuRoutePath.login, page: () => LoginPage()),
    GetPage(
      name: KissuRoutePath.home,
      page: () => KissuHomePage(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 500),
    ),
    GetPage(
      name: KissuRoutePath.infoSetting,
      page: () => InfoSettingPage(),
      binding: InfoSettingBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.location,
      page: () => LocationV2Page(),
      binding: LocationV2Binding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.vip,
      page: () => const VipPage(),
      binding: VipBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.foreverVip,
      page: () => const ForeverVipPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ForeverVipController>(() => ForeverVipController());
      }),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.qrScanPage,
      page: () => const QrScanPage(),
      transition: Transition.downToUp,
    ),
    GetPage(
      name: KissuRoutePath.systemPermission,
      page: () => const SystemPermissionPage(),
      binding: SystemPermissionBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.systemPermissionPreventSleepGuide,
      page: () => const SystemPermissionGuidePage(
        guideType: SystemPermissionGuideType.preventSleep,
        title: '防止程序休眠',
      ),
      binding: SystemPermissionBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.systemPermissionLockGuide,
      page: () => const SystemPermissionGuidePage(
        guideType: SystemPermissionGuideType.lockInBackground,
        title: '锁定程序后台',
      ),
      binding: SystemPermissionBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.systemPermissionBackgroundGuide,
      page: () => const SystemPermissionGuidePage(
        guideType: SystemPermissionGuideType.allowBackgroundRun,
        title: '重启后恢复运行',
      ),
      binding: SystemPermissionBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.systemPermissionLocationGuide,
      page: () => const SystemPermissionGuidePage(
        guideType: SystemPermissionGuideType.location,
        title: '开启实时定位',
      ),
      binding: SystemPermissionBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.systemPermissionNotificationGuide,
      page: () => const SystemPermissionGuidePage(
        guideType: SystemPermissionGuideType.notification,
        title: '开启通知提醒',
      ),
      binding: SystemPermissionBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.systemPermissionAppUsageGuide,
      page: () => const SystemPermissionGuidePage(
        guideType: SystemPermissionGuideType.appUsage,
        title: '允许获取应用使用权限',
      ),
      binding: SystemPermissionBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.systemPermissionBatteryGuide,
      page: () => const SystemPermissionGuidePage(
        guideType: SystemPermissionGuideType.battery,
        title: '电池权限设置',
      ),
      binding: SystemPermissionBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.systemPermissionOverlayGuide,
      page: () => const SystemPermissionGuidePage(
        guideType: SystemPermissionGuideType.overlayWindow,
        title: '悬浮窗权限设置',
      ),
      binding: SystemPermissionBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.permissionSetting,
      page: () => const PermissionSettingPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.agreementWebView,
      page: () => const AgreementWebViewPage(
        title: '',
        url: '',
      ),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.avatarPreview,
      page: () => const AvatarPreviewPage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: KissuRoutePath.feedback,
      page: () => const FeedbackPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.locationState,
      page: () => LocationStatePage(),
      binding: LocationStateBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.locationReminder,
      page: () => LocationReminderPage(),
      binding: LocationReminderBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.antiSpy,
      page: () => const AntiSpyPage(),
      binding: AntiSpyBinding(),
      transition: Transition.rightToLeft,
    ),
    // GetPage(
    //   name: KissuRoutePath.usageSettings,
    //   page: () => const UsageSettingsPage(),
    //   transition: Transition.rightToLeft,
    // ),
    GetPage(
      name: KissuRoutePath.messageList,
      page: () => const MessageListPage(),
      binding: MessageListBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.messageDetail,
      page: () => const MessageDetailPage(),
      binding: MessageDetailBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.interactionMessage,
      page: () => const InteractionMessagePage(),
      binding: InteractionMessageBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.track,
      page: () => const TrackPage(),
      binding: TrackBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.appIconSelector,
      page: () => const AppIconSelectorPage(),
      binding: AppIconSelectorBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.deviceUsage,
      page: () => const DeviceUsagePage(),
      binding: DeviceUsageBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.appUsageDetail,
      page: () => const AppUsageDetailPage(),
      binding: AppUsageDetailBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.appUsage,
      page: () => const AppUsagePage(),
      binding: AppUsageBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.notificationSettings,
      page: () => const NotificationSettingsPage(),
      binding: NotificationSettingsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.chat,
      page: () => ChatPage(),
      binding: ChatBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.chatSettings,
      page: () => const ChatSettingsPage(),
      binding: ChatSettingsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.chatBackground,
      page: () => const ChatBackgroundPage(),
      binding: ChatBackgroundBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.chatBubble,
      page: () => const ChatBubblePage(),
      binding: ChatBubbleBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.chatTheme,
      page: () => const ChatThemePage(),
      binding: ChatThemeBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.imNotificationSettings,
      page: () => const ImNotificationSettingsPage(),
      binding: ImNotificationSettingsBinding(),
      transition: Transition.rightToLeft,
    ),
    // GetPage(
    //   name: KissuRoutePath.locationExample,
    //   page: () => const LocationExamplePage(),
    //   transition: Transition.rightToLeft,
    // ),
     
    // GetPage(
    //   name: KissuRoutePath.testLocationNow,
    //   page: () => TestLocationNowPage(),
    //   transition: Transition.rightToLeft,
    // ),
    // GetPage(
    //   name: KissuRoutePath.quickLocationTest,
    //   page: () => QuickLocationTest(),
    //   transition: Transition.rightToLeft,
    // ),
     
    // GetPage(
    //   name: KissuRoutePath.simpleMarkerTest,
    //   page: () => const SimpleMarkerTestPage(),
    //   transition: Transition.rightToLeft,
    // ),
    
    // GetPage(name: BBRoutePath.aboutUs, page: () => const AboutUsPage()),
    // GetPage(
    //   name: BBRoutePath.webView,
    //   page: () => const WebViewPage(),
    //   transition: Transition.cupertino, // 配置过渡动画
    //   binding: WebViewBinding(),
    // ),
    GetPage(
      name: KissuRoutePath.checkIn188,
      page: () => const CheckIn188Page(),
      binding: CheckIn188Binding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.checkIn188Progress,
      page: () => const CheckIn188ProgressPage(),
      binding: CheckIn188ProgressBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.checkIn188RecoveryCard,
      page: () => const CheckIn188RecoveryCardPage(),
      binding: CheckIn188RecoveryCardBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.checkIn188CardLog,
      page: () => const CheckIn188CardLogPage(),
      binding: CheckIn188CardLogBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.checkIn188Activity,
      page: () => const CheckIn188ActivityPage(),
      binding: CheckIn188ActivityBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.lockScreen,
      page: () => const LockScreenPage(),
      binding: LockScreenBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.lockScreenQuestion,
      page: () => const LockScreenQuestionPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.widgetCenter,
      page: () => const WidgetCenterPage(),
      binding: WidgetCenterBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.widgetAddGuide,
      page: () => const WidgetAddGuidePage(),
      transition: Transition.rightToLeft,
    ),
   
    // ===== 你说我猜 V2 =====
    GetPage(
      name: KissuRoutePath.guessGameV2Home,
      page: () => const GameHomePage(),
      binding: GameHomeBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.guessGameV2TopicSelection,
      page: () => const TopicSelectionPage(),
      binding: TopicSelectionBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.guessGameV2Play,
      page: () => const GamePlayPage(),
      binding: GamePlayBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.guessGameV2Success,
      page: () => const GameSuccessPage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: KissuRoutePath.guessGameV2Failed,
      page: () => const GameFailedPage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: KissuRoutePath.guessGameV2PenaltyPhoto,
      page: () => const GamePenaltyPhotoPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.guessGameV2PenaltyAudio,
      page: () => const GamePenaltyAudioPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.guessGameV2PenaltyWait,
      page: () => const GamePenaltyWaitPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.guessGameV2PenaltyRecord,
      page: () => const GamePenaltyRecordPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.guessGameV2PenaltySelect,
      page: () => const GamePenaltySelectPage(),
      transition: Transition.rightToLeft,
    ),
  ];
}

// // 路由列表
// class KissuRoute {
//   static final List<GetPage> routes = [
//     GetPage(
//       name: KissuRoutePath.home,
//       page: () => KissuHomePage(),
//       transition: Transition.fadeIn, // 可选：页面切换动画
//     ),
//     GetPage(
//       name: KissuRoutePath.login,
//       page: () => KissuLoginPage(),
//       transition: Transition.rightToLeft,
//     ),
//     GetPage(
//       name: KissuRoutePath.profile,
//       page: () => KissuProfilePage(),
//       transition: Transition.rightToLeft,
//     ),
//   ];
// }
