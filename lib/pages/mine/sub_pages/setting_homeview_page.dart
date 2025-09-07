import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingHomeController extends GetxController {
  // 当前选择的模式 0 = pst, 1 = dst
  var selectedIndex = 0.obs;

  void select(int index) {
    selectedIndex.value = index;
  }

  String get centerImage {
    if (selectedIndex.value == 0) {
      return "assets/kissu_setting_home_center_dst.webp";
    } else {
      return "assets/kissu_setting_home_center_pst.webp";
    }
  }

  String get leftButtonImage {
    return selectedIndex.value == 0
        ? "assets/kissu_setting_home_pst.webp"
        : "assets/kissu_setting_home_pstu.webp";
  }

  String get rightButtonImage {
    return selectedIndex.value == 1
        ? "assets/kissu_setting_home_dst.webp"
        : "assets/kissu_setting_home_dstu.webp";
  }

  void onBackTap() {
    Get.back();
  }
}

class SettingHomePage extends StatelessWidget {
  const SettingHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SettingHomeController());

    return Scaffold(
      body: Stack(
        children: [
          // 背景图
          Positioned.fill(
            child: Image.asset(
              "assets/kissu_setting_home_bg.webp",
              fit: BoxFit.cover,
            ),
          ),

          // 页面内容
          Column(
            children: [
              // 顶部导航
              Padding(
                padding: EdgeInsets.only(left: 16, right: 16, top: 56),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: controller.onBackTap,
                      child: Image.asset(
                        "assets/kissu_mine_back.webp",
                        width: 22,
                        height: 22,
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          "首页视图",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 22), // 占位保持居中
                  ],
                ),
              ),

              // 中间图片
              Expanded(
                child: Center(
                  child: Obx(
                    () => Image.asset(
                      controller.centerImage,
                      width: 180,
                      height: 364,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              // 底部两个按钮
              Padding(
                padding: const EdgeInsets.only(bottom: 65),
                child: Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => controller.select(0),
                        child: Image.asset(
                          controller.leftButtonImage,
                          width: 124,
                          height: 184,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 36),
                      GestureDetector(
                        onTap: () => controller.select(1),
                        child: Image.asset(
                          controller.rightButtonImage,
                          width: 124,
                          height: 184,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
