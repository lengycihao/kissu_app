import 'package:get/get_navigation/src/routes/get_route.dart';
 import 'package:kissu_app/pages/home/home_binding.dart';
import 'package:kissu_app/pages/home/home_page.dart';
import 'package:kissu_app/pages/login/login_page.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:get/get.dart';
 

class KissuRoute {
  static final routes = [
    GetPage(
      name: KissuRoutePath.home,
      page: () =>  KissuHomePage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: KissuRoutePath.login,
      page: () =>  LoginPage(),
     ),
     GetPage(
      name: KissuRoutePath.home,
      page: () =>  KissuHomePage(),
      binding: HomeBinding(),
      transition: Transition.downToUp,
    ),
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