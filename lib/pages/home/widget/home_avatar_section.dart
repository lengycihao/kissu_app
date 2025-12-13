import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/network_image_helper.dart';
import 'package:kissu_app/pages/home/home_controller.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog_controller.dart';
import 'package:kissu_app/widgets/no_placeholder_image.dart';
import 'package:kissu_app/services/tracking_service.dart';

/// 首页右上角头像模块
/// 包含：双头像、状态文本、通知图标、活动图标
class HomeAvatarSection extends StatelessWidget {
  final HomeController controller;

  const HomeAvatarSection({Key? key, required this.controller})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Positioned(
        top: 55, // 与下面按钮保持20px间距
        right: 25,
        child: Column(
          children: [
            // 未绑定状态 - 显示加号按钮
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 第一个头像按钮
                Transform.translate(
                  offset: const Offset(45, 0),
                  child: Transform.rotate(
                    angle: 30 * 3.1415926535 / 180, // 逆时针30度
                    child: GestureDetector(
                      onTap: () {
                        if (controller.isBound.value) {
                          // 已绑定状态下点击头像跳转到恋爱信息页
                          controller.navigateToLoveInfoPage();
                        } else {
                          // 未绑定状态下显示绑定弹窗
                          CustomBottomDialog.show(
                            context: context,
                            caller: BindingDialogCaller.home,
                          );
                        }
                      },
                      // 🚀 优化：统一使用 NoPlaceholderImage，它现在能自动识别网络和本地图片
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: NoPlaceholderImage(
                          imageUrl: controller.userAvatar.value,
                          defaultAssetPath:
                              "assets/3.0/kissu3_love_avater.webp",
                          width: 38,
                          height: 38,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ),
                // 减少重叠的间距，例如 -6
                Transform.translate(
                  offset: const Offset(-30, 0),
                  child: Transform.rotate(
                    angle: -30 * 3.1415926535 / 180, // 顺时针30度
                    child: controller.isBound.value
                        ? GestureDetector(
                            onTap: () {
                              // 埋点：点击另一半头像（已绑定状态）
                              TrackingService.trackPartnerAvatarClick();
                              // 已绑定状态下点击头像跳转到恋爱信息页
                              controller.navigateToLoveInfoPage();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                              ),
                              child: NoPlaceholderImage(
                                imageUrl: controller.partnerAvatar.value,
                                defaultAssetPath:
                                    "assets/3.0/kissu3_love_avater.webp",
                                width: 38,
                                height: 38,
                                fit: BoxFit.cover,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTap: () {
                              // 埋点：点击另一半头像（未绑定状态）
                              TrackingService.trackPartnerAvatarClick();
                              // 显示绑定弹窗
                              CustomBottomDialog.show(
                                context: context,
                                caller: BindingDialogCaller.home,
                              );
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
                                  "assets/images/kissu_home_add_avair.webp",
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
                ? Transform.translate(
                    offset: Offset(9, 0),
                    child: GestureDetector(
                      onTap: () {
                        // 已绑定状态下点击"在一起X天"跳转到恋爱信息页
                        controller.navigateToLoveInfoPage();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xff5CC0FF),
                          border: Border.all(
                            color: Color(0xffffffff),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        child: Obx(
                          () => Text(
                            "在一起${controller.loveDays.value}天",
                            style: TextStyle(
                              color: Color(0xffffffff),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : Transform.translate(
                    offset: Offset(9, 0),
                    child: GestureDetector(
                      onTap: () {
                        // 未绑定状态下点击"绑定另一半"显示绑定弹窗
                        CustomBottomDialog.show(
                          context: context,
                          caller: BindingDialogCaller.home,
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xff5CC0FF),
                          border: Border.all(color: Color(0xffffffff)),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        child: Text(
                          "绑定另一半",
                          style: TextStyle(
                            color: Color(0xffffffff),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),

            const SizedBox(height: 15), // 与下方两个按钮间距
            // 通知图标和活动图标
            Transform.translate(
              offset: const Offset(19, 0),
              child: Column(
                children: [
                  // 福利会员图标
                  // SizedBox(
                  //   width: 56,
                  //   height: 56,
                  //   child: Stack(
                  //     clipBehavior: Clip.none,
                  //     children: [
                  //       // 通知图标（固定位置）
                  //       GestureDetector(
                  //         onTap: () {
                  //           controller.onNotificationTap();
                  //         },
                  //         child: Image.asset(
                  //           "assets/images/kissu_home_vip_icon.webp",
                  //           width: 56,
                  //           height: 56,
                  //         ),
                  //       ),
                  //       // 红点角标
                  //       Obx(() {
                  //         if (controller.isRedDot.value) {
                  //           return Positioned(
                  //             right: 0,
                  //             top: 0,
                  //             child: Container(
                  //               width: 12,
                  //               height: 12,
                  //               decoration: BoxDecoration(
                  //                 color: const Color(0xffFF6B6B),
                  //                 shape: BoxShape.circle,
                  //                 border: Border.all(
                  //                   color: Colors.white,
                  //                   width: 1,
                  //                 ),
                  //               ),
                  //             ),
                  //           );
                  //         }
                  //         return const SizedBox.shrink();
                  //       }),
                  //     ],
                  //   ),
                  // ),
                  // SizedBox(height: 5),
                
                  // 通知图标（带红点）+ 抽屉式提示
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // 左侧抽屉式提示条（从图标左侧展开）
                        Positioned(
                          right: 20, // 从图标左侧开始
                          top: 0,
                          child: Obx(() {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              width: controller.isRedDot.value ? 110 : 0,
                              height: 36,
                              child: controller.isRedDot.value
                                  ? Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(18),
                                          bottomLeft: Radius.circular(18),
                                        ),
                                      ),
                                      alignment: Alignment.centerLeft,
                                      padding: EdgeInsets.only(
                                        left: 12,
                                        right: 8,
                                      ),
                                      child: Text(
                                        "有未读消息哦~",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    )
                                  : SizedBox.shrink(),
                            );
                          }),
                        ),
                        // 通知图标（固定位置）
                        GestureDetector(
                          onTap: () {
                            controller.onNotificationTap();
                          },
                          child: Image.asset(
                            "assets/images/kissu_home_notiicon.webp",
                            width: 56,
                            height: 56,
                          ),
                        ),
                        // 红点角标
                        Obx(() {
                          if (controller.isRedDot.value) {
                            return Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: const Color(0xffFF6B6B),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                      ],
                    ),
                  ),

                  // 活动图标
                  Obx(() {
                    if (controller.isActivity.value &&
                        controller.activityIcon.value.isNotEmpty) {
                      return Column(
                        children: [
                          const SizedBox(height: 5), // 间距30px
                          GestureDetector(
                            onTap: () async {
                              // 埋点：活动按钮点击
                              await TrackingService.trackActivityButtonClick();

                              controller.navigateToH5(
                                controller.activityLink.value,
                              );
                            },
                            child: NetworkImageHelper.loadImage(
                              imageUrl: controller.activityIcon.value,
                              width: 50,
                              height: 50,
                              fit: BoxFit.contain,
                              errorWidget: const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  }),
            //  SizedBox(height: 5),  SizedBox(
            //         width: 56,
            //         height: 56,
            //         child: Stack(
            //           clipBehavior: Clip.none,
            //           children: [
            //             // 通知图标（固定位置）
            //             GestureDetector(
            //               onTap: () {
            //                 controller.onNotificationTap();
            //               },
            //               child: Image.asset(
            //                 "assets/images/kissu_home_lashi_icon.webp",
            //                 width: 56,
            //                 height: 56,
            //               ),
            //             ),
            //             // 红点角标
            //             Obx(() {
            //               if (controller.isRedDot.value) {
            //                 return Positioned(
            //                   right: 0,
            //                   top: 0,
            //                   child: Container(
            //                     width: 12,
            //                     height: 12,
            //                     decoration: BoxDecoration(
            //                       color: const Color(0xffFF6B6B),
            //                       shape: BoxShape.circle,
            //                       border: Border.all(
            //                         color: Colors.white,
            //                         width: 1,
            //                       ),
            //                     ),
            //                   ),
            //                 );
            //               }
            //               return const SizedBox.shrink();
            //             }),
            //           ],
            //         ),
            //       ),
                 
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
