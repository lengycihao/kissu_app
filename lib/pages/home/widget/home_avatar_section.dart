import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/source_page_utils.dart';
import 'package:lottie/lottie.dart';
import 'package:kissu_app/utils/network_image_helper.dart';
import 'package:kissu_app/pages/home/home_controller.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog.dart';
 import 'package:kissu_app/widgets/no_placeholder_image.dart'; 
import 'package:kissu_app/network/public/auth_service.dart';
import 'package:kissu_app/network/public/service_locator.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/services/analytics/analytics_helper.dart';
import 'package:kissu_app/services/analytics/analytics_events.dart';

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
                    angle: 0, // 逆时针30度
                    child: GestureDetector(
                      onTap: () {
                        // 埋点：右上角头像点击
                        AnalyticsHelper.trackBindPartnerAvatar();
                        
                        if (controller.isBound.value) {
                          // navigateToLoveInfoPage内部会调用埋点
                          controller.navigateToLoveInfoPage();
                        } else {
                          // 未绑定状态下显示绑定弹窗
                          CustomBottomDialog.show(
                            context: context,
                            caller: SourcePageUtilsCaller.home,
                            sourceEvent: HomeEvents.bindPartnerAvatar,
                          );
                        }
                      },
                      // 🚀 优化：统一使用 NoPlaceholderImage，它现在能自动识别网络和本地图片
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: NoPlaceholderImage(
                          imageUrl: controller.userAvatar.value,
                          defaultAssetPath:
                              "assets/3.0/kissu3_love_avater.webp",
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ),
              
               // 减少重叠的间距，例如 -6
                Transform.translate(
                  offset: const Offset(-30, 0),
                  child: Transform.rotate(
                    angle: 0, // 顺时针30度
                    child: controller.isBound.value
                        ? GestureDetector(
                            onTap: () {
                              // 埋点：右上角头像点击
                              AnalyticsHelper.trackBindPartnerAvatar();
                              
                              // navigateToLoveInfoPage内部会调用埋点
                              controller.navigateToLoveInfoPage();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                              ),
                              child: NoPlaceholderImage(
                                imageUrl: controller.partnerAvatar.value,
                                defaultAssetPath:
                                    "assets/3.0/kissu3_love_avater.webp",
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTap: () {
                               
                              // 显示绑定弹窗
                              CustomBottomDialog.show(
                                context: context,
                                caller: SourcePageUtilsCaller.home,
                                sourceEvent: HomeEvents.bindPartnerAvatar,
                              );
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
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
                    offset: Offset(9, -5),
                    child: GestureDetector(
                      onTap: () {
                        // 已绑定状态下点击"在一起X天"跳转到恋爱信息页
                        controller.navigateToLoveInfoPage();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xffFFD9F1),
                          gradient: LinearGradient(colors: [
                            Color(0xffFFB3FF),
                            Color(0xffFF9EFF)
                          ],begin: Alignment.topLeft,end: Alignment.bottomRight),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xff000000).withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 1),
                            ),
                          ],
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        child: Obx(
                          () => Text(
                            "相爱${controller.loveDays.value}天",
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
                    offset: Offset(9, -5),
                    child: GestureDetector(
                      onTap: () {
                        // 未绑定状态下点击"绑定另一半"显示绑定弹窗
                        CustomBottomDialog.show(
                          context: context,
                          caller: SourcePageUtilsCaller.home,
                          sourceEvent: HomeEvents.bindPartnerAvatar,
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xffFFD9F1),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xff000000).withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 1),
                            ),
                          ],
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        child: Text(
                          "绑定另一半",
                          style: TextStyle(
                            color: Color(0xffFF92D7),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),

            const SizedBox(height: 5), // 与下方两个按钮间距
             Transform.translate(
              offset: const Offset(19, 0),
              child: Column(
                
                children: [
                  // 福利会员图标 - 非终身会员时展示，点击跳转到会员页面 

                  
                  Obx(() {
                    if (controller.isForeverVip.value) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: [
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  // 埋点：会员福利按钮点击
                                  AnalyticsHelper.trackVipAction();
                                  
                                  // 🔥 未绑定时先弹出绑定弹窗
                                  if (!controller.isBound.value) {
                                    CustomBottomDialog.show(
                                      context: context,
                                      caller: SourcePageUtilsCaller.home,
                                      sourceEvent: HomeEvents.vipAction,
                                    );
                                    return;
                                  }
                                  
                                  // 埋点：首页离开（进入下一页）
                                  controller.trackHomePageExitFromWidget();
                                  
                                  // 已绑定：跳转到会员页面
                                  await Get.toNamed(KissuRoutePath.vip,arguments: {'source_page': SourcePageUtilsCaller.home, 'source_event': HomeEvents.vipAction});
                                  
                                  // 从会员页面返回后，重置埋点状态
                                  controller.onPageResumed();
                                },
                                child: Image.asset(
                                  "assets/gif/home_vip.gif",
                                  width: 44,
                                  height: 44,
                                ),
                              ),
                            
                            ],
                          ),

                        ),
                        Text("会员福利", style: TextStyle(
                          color: Color(0xff333333),
                          fontSize: 12,
                          fontFamily: "LiuHuanKaTongShouShu",
                        ),),
                        const SizedBox(height: 5),
                      ],
                    );
                  }),

                  // 活动图标
                  Obx(() {
                    if (controller.isActivity.value &&
                        controller.activityIcon.value.isNotEmpty) {
                      return Column(
                        children: [
                          const SizedBox(height: 5), // 间距30px
                          GestureDetector(
                            onTap: () async {
                              // 埋点：VIP活动点击
                              AnalyticsHelper.trackVipAction();
                              
                              // navigateToH5内部会调用埋点，这里不需要重复调用
                              await controller.navigateToH5(
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
               
                  SizedBox(height: 6),
                  // 拉屎图标 - 根据 crap_status 控制显示
                  Obx(() {
                    // 只有当 crap_status 为 "1" 时才显示
                    if (controller.crapStatus.value != '1') {
                      return const SizedBox.shrink();
                    }

                    return SizedBox(
                      width: 48,
                      height: 64,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // 拉屎图标（固定位置）
                          GestureDetector(
                            onTap: () async {
                              // 埋点：一起便便按钮点击
                              AnalyticsHelper.trackPoopTogether();
                              
                              // 未绑定时先弹出绑定弹窗
                              if (!controller.isBound.value) {
                                CustomBottomDialog.show(
                                  context: context,
                                  caller: SourcePageUtilsCaller.home,
                                  sourceEvent: HomeEvents.poopTogether,
                                );
                                return;
                              }

                              // 已绑定：使用接口返回的 crap_link，然后拼接 token
                              String baseUrl = controller.crapLink.value;
                              if (baseUrl.isEmpty) {
                                // 如果接口没有返回链接，使用默认链接
                                baseUrl =
                                    'http://devweb.ikissu.cn/share/couplesdeFecating.html';
                              }

                              String url = baseUrl;

                              try {
                                final authService = getIt<AuthService>();
                                final token = authService.userToken;
                                if (token != null && token.isNotEmpty) {
                                  final encodedToken = Uri.encodeComponent(
                                    token,
                                  );
                                  // 判断链接是否已经包含参数
                                  final separator = baseUrl.contains('?')
                                      ? '&'
                                      : '?';
                                  url =
                                      '$baseUrl${separator}token=$encodedToken';
                                }
                              } catch (_) {
                                // 获取 token 失败时，使用不带 token 的链接
                                url = baseUrl;
                              }

                              // navigateToH5内部会调用埋点，这里不需要重复调用
                              await controller.navigateToH5(
                                url,
                                showAppBar: false,
                                title: '',
                                backgroundColor: Colors.white,
                                showLoadingIndicator: false, // 拉屎H5不显示加载动画
                              );
                            },
                            child: Column(
                              children: [
                                Image.asset(
                              "assets/gif/kissu_home_lashi_icon.gif",
                              width: 44,
                              height: 44,
                            ),
                            Text("拉了么", style: TextStyle(
                              color: Color(0xff333333),
                              fontSize: 12,
                              fontFamily: "LiuHuanKaTongShouShu",
                            ),),
                              ],
                            )
                          ),
                          // // 红点角标
                          // Obx(() {
                          //   if (controller.isRedDot.value) {
                          //     return Positioned(
                          //       right: 0,
                          //       top: 0,
                          //       child: Container(
                          //         width: 12,
                          //         height: 12,
                          //         decoration: BoxDecoration(
                          //           color: const Color(0xffFF6B6B),
                          //           shape: BoxShape.circle,
                          //           border: Border.all(
                          //             color: Colors.white,
                          //             width: 1,
                          //           ),
                          //         ),
                          //       ),
                          //     );
                          //   }
                          //   return const SizedBox.shrink();
                          // }),
                        ],
                      ),
                    );
                  }),
                  
                  SizedBox(height: 6),
                  // 188打卡入口
                  // GestureDetector(
                  //   onTap: () {
                  //     // 埋点：首页离开（进入下一页）
                  //     controller.trackHomePageExitFromWidget();
                  //     Get.toNamed(KissuRoutePath.checkIn188);
                  //   },
                  //   child: Column(
                  //     children: [
                  //       Image.asset(
                  //         "assets/188/kissu_188_notice_icon.webp",
                  //         width: 44,
                  //         height: 44,
                  //       ),
                  //       Text(
                  //         "188打卡",
                  //         style: TextStyle(
                  //           color: Color(0xff333333),
                  //           fontSize: 12,
                  //           fontFamily: "LiuHuanKaTongShouShu",
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
              
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
