import 'package:kissu_app/pages/splash/splash_page.dart';
import 'package:kissu_app/pages/home/home_binding.dart';
import 'package:kissu_app/pages/home/home_page.dart';
import 'package:kissu_app/pages/location/location_binding.dart';
import 'package:kissu_app/pages/location/location_page.dart';
import 'package:kissu_app/pages/login/info_setting/info_setting_binding.dart';
import 'package:kissu_app/pages/login/info_setting/info_setting_page.dart';
import 'package:kissu_app/pages/login/info_setting/share_page.dart';
import 'package:kissu_app/pages/qr/qr_scan_page.dart';
import 'package:kissu_app/pages/login/login_page.dart';
 import 'package:kissu_app/pages/vip/vip_binding.dart';
import 'package:kissu_app/pages/vip/vip_page.dart';
import 'package:kissu_app/pages/vip/forever_vip_page.dart';
import 'package:kissu_app/pages/vip/forever_vip_controller.dart';
import 'package:kissu_app/pages/mine/sub_pages/system_permission_page.dart';
import 'package:kissu_app/pages/mine/sub_pages/system_permission_binding.dart';
import 'package:kissu_app/pages/permission_setting_page.dart';
import 'package:kissu_app/pages/agreement/agreement_webview_page.dart';
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
      transition: Transition.downToUp,
    ),
    GetPage(
      name: KissuRoutePath.infoSetting,
      page: () => InfoSettingPage(),
      binding: InfoSettingBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: KissuRoutePath.location,
      page: () => LocationPage(),
      binding: LocationBinding(),
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
      name: KissuRoutePath.share,
      page: () => const SharePage(),
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
