import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/home/home_controller.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/widgets/banner_widget.dart';
import 'package:kissu_app/widgets/video_background.dart';

class KissuHomePage extends GetView<HomeController> {
  const KissuHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 视频背景
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: VideoBackground(
              videoPath: "assets/home4k.mp4",
              placeholderImagePath: "assets/kissu_home_bg.webp",
              width: 1500,
              height: MediaQuery.of(context).size.height,
            ),
          ),

          // 底部按钮栏（你已有的）
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFF6D4128), width: 1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(4, (index) {
                  return InkWell(
                    onTap: () => controller.onButtonTap(index),
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          controller.getTopIconPath(index),
                          width: 42,
                          height: 42,
                        ),
                        const SizedBox(height: 4),
                        Image.asset(
                          controller.getBottomIconPath(index),
                          width: index == 2 ? 42 : 24,
                          height: 14,
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),

          // 头像显示区域 - 根据绑定状态显示不同内容
          Obx(
            () => Positioned(
              top: 85, // 与下面按钮保持20px间距
              right: 30,
              child: Column(
                children: [
                  // 未绑定状态 - 显示加号按钮
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 第一个加号按钮
                      Transform.translate(
                        offset: const Offset(33, 0),
                        child: Transform.rotate(
                          angle: 30 * 3.1415926535 / 180, // 逆时针30度
                          child: controller.userAvatar.value.startsWith('http')
                              ? Image.network(
                                  controller.userAvatar.value,
                                  width: 38,
                                  height: 38,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      "assets/kissu_icon.webp",
                                      width: 38,
                                      height: 38,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                              : Image.asset(
                                  controller.userAvatar.value,
                                  width: 38,
                                  height: 38,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      // 减少重叠的间距，例如 -6
                      Transform.translate(
                        offset: const Offset(-38, 0),
                        child: Transform.rotate(
                          angle: -30 * 3.1415926535 / 180, // 顺时针30度
                          child: controller.isBound.value
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: Image.network(
                                    controller.partnerAvatar.value,
                                    width: 38,
                                    height: 38,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        "assets/kissu_icon.webp",
                                        width: 38,
                                        height: 38,
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                                )
                              : GestureDetector(
                                  onTap: () {
                                    ///TODO 跳转分享页--1
                                    Get.toNamed(KissuRoutePath.share);
                                  },
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Image.asset(
                                        "assets/kissu_home_add_avair.webp",
                                        width: 24,
                                        height: 24,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),

                  controller.isBound.value
                      ? Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Color(0xffFFECEA)),
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                          ),
                          child: Text(
                            "在一起${UserManager.currentUser?.loverInfo?.loveDays}天",
                            style: TextStyle(
                              color: Color(0xff666666),
                              fontSize: 12,
                            ),
                          ),
                        )
                      : Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Color(0xffFFECEA)),
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                          ),
                          child: Text(
                            "绑定另一半",
                            style: TextStyle(
                              color: Color(0xff666666),
                              fontSize: 12,
                            ),
                          ),
                        ),

                  const SizedBox(height: 35), // 与下方两个按钮间距
                  // 下面已有的两个按钮
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          controller.onNotificationTap();
                        },
                        child: Image.asset(
                          "assets/kissu_home_notiicon.png",
                          width: 50,
                          height: 50,
                        ),
                      ),
                      // const SizedBox(height: 15),
                      // GestureDetector(
                      //   onTap: () {
                      //     controller.onMoneyTap();
                      //   },
                      //   child: Image.asset(
                      //     "assets/kissu_home_moneyicon.png",
                      //     width: 60,
                      //     height: 50,
                      //   ),
                      // ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Banner - 只在未绑定时显示
          Obx(
            () => !controller.isBound.value
                ? Positioned(
                    bottom: 90 + 18, // 90 是已有底部按钮栏高度，18 是间距
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          controller.onUnbindTipTap();
                        },
                        child: SizedBox(
                          width: 303,
                          height: 81,
                          child: BannerWidget(
                            imagePaths: const [
                              "assets/kissu_home_bottom_map_vip_unbing.webp",
                              "assets/kissu_home_banner_bg2.webp",
                            ],
                            animationDuration: const Duration(seconds: 2),
                            switchDuration: const Duration(seconds: 3),
                            scaleFactor: 1.05,
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // 轮播图
          Positioned(
            bottom: 90 + 15, // 90 是已有底部按钮栏高度，18 是间距，20 是指示器高度
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 81,
                  child: Swiper(
                    itemBuilder: (BuildContext context, int index) {
                      return Center(
                        child: Container(
                          width: 303,
                          height: 81,
                           decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(
                                index == 0
                                    ? "assets/kissu_home_bottom_map_vip_unbing.webp"
                                    : "assets/home_banner_bg3.webp",
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: index == 0
                              ? null
                              : Stack(
                                children: [
                                  Positioned(
                                    left: 16,bottom: 8,
                                    child: Container(
                                       width: 31,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: AssetImage(
                                            "assets/kissu_home_header_bg.webp",
                                          ),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Transform.translate(
                                        offset: Offset(0, -2),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadiusGeometry.circular(
                                                15,
                                              ),
                                          child: Image.network(
                                            controller.userAvatar.value,
                                            width: 28,
                                            height: 28,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Image.asset(
                                                    "assets/kissu_icon.webp",
                                                    width: 28,
                                                    height: 28,
                                                    fit: BoxFit.cover,
                                                  );
                                                },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                        ),
                      );
                    },
                    autoplay: false,
                    loop: false,
                    itemCount: 2,
                    viewportFraction: 1,
                    // 移除内置的pagination
                    onIndexChanged: (index) {
                      controller.currentSwiperIndex.value = index;
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // 外置的指示器
                Obx(
                  () => _buildCustomIndicator(
                    controller.currentSwiperIndex.value,
                    2,
                  ),
                ),
              ],
            ),
          ),

          // Obx(
          //   () => controller.isBound.value
          //       ? Positioned(
          //           bottom: 90 + 18, // 90 是已有底部按钮栏高度，18 是间距
          //           left: 0,
          //           right: 0,
          //           child: Center(
          //             child: SizedBox(
          //               width: 303,
          //               height: 81,
          //               child: Stack(
          //                 children: [
          //                   // Banner背景
          //                   BannerWidget(
          //                     imagePaths: const [
          //                       "assets/kissu_home_bottom_map_vip_unbing.webp",
          //                       "assets/kissu_home_banner_bg2.webp",
          //                     ],
          //                     animationDuration: const Duration(seconds: 2),
          //                     switchDuration: const Duration(seconds: 3),
          //                     scaleFactor: 1.05,
          //                   ),
          //                   // 头像显示层
          //                   Container(
          //                     padding: const EdgeInsets.only(
          //                       left: 20,
          //                       right: 40,
          //                     ),
          //                     child: Row(
          //                       mainAxisAlignment:
          //                           MainAxisAlignment.spaceBetween,
          //                       children: [
          //                         // 自己头像背景
          //                         Container(
          //                           decoration: const BoxDecoration(
          //                             image: DecorationImage(
          //                               image: AssetImage(
          //                                 "assets/kissu_home_header_bg.webp",
          //                               ),
          //                               fit: BoxFit.contain,
          //                             ),
          //                           ),

          //                           width: 45,
          //                           height: 58,
          //                           padding: EdgeInsets.only(
          //                             left: 2,
          //                             right: 2,
          //                             bottom: 4,
          //                           ),
          //                           child: ClipRRect(
          //                             borderRadius: BorderRadius.circular(20),
          //                             child: Obx(
          //                               () => Container(
          //                                 padding: EdgeInsets.all(2), // 边框厚度
          //                                 decoration: BoxDecoration(
          //                                   color: Colors.white, // 背景色（边框颜色）
          //                                   shape: BoxShape
          //                                       .circle, // 圆形边框（如果头像是圆的）
          //                                   // border: Border.all(color: Colors.white, width: 2), // 方形边框写法
          //                                 ),
          //                                 child: ClipOval(
          //                                   child:
          //                                       controller.userAvatar.value
          //                                           .startsWith('http')
          //                                       ? Image.network(
          //                                           controller.userAvatar.value,

          //                                           fit: BoxFit.contain,
          //                                           errorBuilder:
          //                                               (
          //                                                 context,
          //                                                 error,
          //                                                 stackTrace,
          //                                               ) {
          //                                                 return Image.asset(
          //                                                   "assets/kissu_icon.webp",
          //                                                   width: 26,
          //                                                   height: 26,
          //                                                   fit: BoxFit.contain,
          //                                                 );
          //                                               },
          //                                         )
          //                                       : Image.asset(
          //                                           controller.userAvatar.value,

          //                                           fit: BoxFit.contain,
          //                                         ),
          //                                 ),
          //                               ),
          //                             ),
          //                           ),
          //                         ),
          //                         // 伴侣头像背景
          //                         Container(
          //                           decoration: const BoxDecoration(
          //                             image: DecorationImage(
          //                               image: AssetImage(
          //                                 "assets/kissu_home_header_bg.webp",
          //                               ),
          //                               fit: BoxFit.contain,
          //                             ),
          //                           ),

          //                           width: 45,
          //                           height: 58,
          //                           padding: EdgeInsets.only(
          //                             left: 2,
          //                             right: 2,
          //                             bottom: 4,
          //                           ),
          //                           child: ClipRRect(
          //                             borderRadius: BorderRadius.circular(20),
          //                             child: Obx(
          //                               () => Container(
          //                                 padding: EdgeInsets.all(2), // 边框厚度
          //                                 decoration: BoxDecoration(
          //                                   color: Colors.white, // 背景色（边框颜色）
          //                                   shape: BoxShape
          //                                       .circle, // 圆形边框（如果头像是圆的）
          //                                   // border: Border.all(color: Colors.white, width: 2), // 方形边框写法
          //                                 ),
          //                                 child: ClipOval(
          //                                   child:
          //                                       controller.partnerAvatar.value
          //                                           .startsWith('http')
          //                                       ? Image.network(
          //                                           controller
          //                                               .partnerAvatar
          //                                               .value,

          //                                           fit: BoxFit.contain,
          //                                           errorBuilder:
          //                                               (
          //                                                 context,
          //                                                 error,
          //                                                 stackTrace,
          //                                               ) {
          //                                                 return Image.asset(
          //                                                   "assets/kissu_icon.webp",
          //                                                   width: 26,
          //                                                   height: 26,
          //                                                   fit: BoxFit.contain,
          //                                                 );
          //                                               },
          //                                         )
          //                                       : Image.asset(
          //                                           controller
          //                                               .partnerAvatar
          //                                               .value,

          //                                           fit: BoxFit.contain,
          //                                         ),
          //                                 ),
          //                               ),
          //                             ),
          //                           ),
          //                         ),
          //                       ],
          //                     ),
          //                   ),
          //                 ],
          //               ),
          //             ),
          //           ),
          //         )
          //       : const SizedBox.shrink(),
          // ),
        ],
      ),
    );
  }

  /// 构建自定义指示器
  Widget _buildCustomIndicator(int currentIndex, int itemCount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(itemCount, (index) {
        bool isActive = index == currentIndex;
        return Container(
          width: isActive ? 20.0 : 6.0, // 选中时宽度为20，未选中为6
          height: isActive ? 4.0 : 6.0, // 选中时高度为4，未选中为6
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            color: isActive ? Colors.black : Colors.black,
            borderRadius: BorderRadius.circular(isActive ? 3.0 : 4.0),
          ),
        );
      }),
    );
  }
}

// Expanded(
//   flex: 1,
//   child: Obx(() {
//     return AMapWidget(
//       apiKey: const AMapApiKey( // 这里要换成你自己的高德 key
//         androidKey: "your-android-key",
//         iosKey: "your-ios-key",
//       ),
//       markers: {
//         // 实时位置
//         Marker(
//           position: controller.person1Location.value,
//           infoWindow: const InfoWindow(title: "人1"),
//         ),
//         Marker(
//           position: controller.person2Location.value,
//           infoWindow: const InfoWindow(title: "人2"),
//         ),
//         // 停留点
//         ...controller.stayPoints.map((p) => Marker(
//               position: p,
//               infoWindow: const InfoWindow(title: "停留点"),
//               icon: BitmapDescriptor.defaultMarkerWithHue(
//                 BitmapDescriptor.hueBlue,
//               ),
//             )),
//       },
//       polylines: {
//         // 人1轨迹
//         Polyline(
//           points: controller.person1Track,
//           color: Colors.red,
//           width: 5,
//         ),
//         // 人2轨迹
//         Polyline(
//           points: controller.person2Track,
//           color: Colors.green,
//           width: 5,
//         ),
//       },
//     );   }),
// ),
