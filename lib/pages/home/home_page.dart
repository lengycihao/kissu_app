import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/home/home_controller.dart';

class KissuHomePage extends GetView<HomeController> {
  const KissuHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景图
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Image.asset(
              "assets/kissu_home_bg.webp",
              width: 1500,
              height: 812,
              fit: BoxFit.cover,
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

          // 右上固定按钮
          Positioned(
            top: 90, // 与下面按钮保持20px间距
            right: 30,
            child: Column(
              children: [
                // 新增图片+按钮组合，水平排列
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 图片
                    Transform.rotate(
                      angle: -30 * 3.1415926535 / 180, // 逆时针30度
                      child: Container(
                        width: 36,
                        height: 36,
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
                    // 减少重叠的间距，例如 -6
                    Transform.translate(
                      offset: const Offset(-6, 0),
                      child: Transform.rotate(
                        angle: 30 * 3.1415926535 / 180, // 顺时针30度
                        child: GestureDetector(
                          onTap: () {
                            // controller.onAddAvaireTap();
                          },
                          child: Container(
                            width: 36,
                            height: 36,
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
                const SizedBox(height: 20), // 与下方两个按钮间距
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
                    const SizedBox(height: 15),
                    GestureDetector(
                      onTap: () {
                        controller.onMoneyTap();
                      },
                      child: Image.asset(
                        "assets/kissu_home_moneyicon.png",
                        width: 60,
                        height: 50,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 90 + 18, // 90 是已有底部按钮栏高度，18 是间距
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                "assets/kissu_home_bottom_map_vip_unbing.webp",
                width: 303,
                height: 81,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
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