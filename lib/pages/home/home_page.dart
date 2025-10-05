import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/home/home_controller.dart';
import 'package:kissu_app/widgets/no_placeholder_image.dart';
// import 'package:kissu_app/widgets/delayed_pag_widget.dart'; // 注释掉PAG动画相关导入
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/services/view_mode_service.dart';
import 'package:kissu_app/pages/mine/love_info/love_info_page.dart';
import 'package:kissu_app/pages/location/location_page.dart';
import 'package:kissu_app/pages/location/location_binding.dart';
import 'package:kissu_app/pages/track/track_page.dart';
import 'package:kissu_app/pages/track/track_binding.dart';
import 'package:kissu_app/utils/screen_adaptation.dart';
import 'package:kissu_app/widgets/dialogs/image_dialog_util.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/widgets/guide_overlay_widget.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog.dart';
import 'package:kissu_app/widgets/kissu_banner_builder.dart';
import 'package:kissu_app/widgets/island_view_button.dart';


class KissuHomePage extends StatefulWidget {
  const KissuHomePage({super.key});

  @override
  State<KissuHomePage> createState() => _KissuHomePageState();
}

class _KissuHomePageState extends State<KissuHomePage> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  late HomeController controller;

  @override
  bool get wantKeepAlive => false; // 禁用页面状态保持，减少内存占用

  @override
  void initState() {
    super.initState();
    controller = Get.find<HomeController>();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // 当应用从后台回到前台时刷新用户信息
    // 但只有当页面当前可见时才刷新，避免不必要的UI更新
    if (state == AppLifecycleState.resumed) {
      final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;
      if (isCurrentRoute) {
        debugPrint('🏠 应用回到前台且首页可见，刷新用户信息');
        controller.refreshUserInfoFromServer();
      } else {
        debugPrint('🏠 应用回到前台但首页不可见，跳过刷新');
      }
    }
  }

  /// 红色容器点击事件处理
  void _onRedContainerTap() {
    debugPrint('🔴 红色容器被点击了');
    ImageDialogUtil.showImageDialog(
      context: context,
      imagePath: 'assets/3.0/kissu3_picture_wall.webp',
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用以支持AutomaticKeepAliveClientMixin
    
    return Scaffold(
      body: Stack(
        children: [
          // 背景图片的可滑动容器
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: controller.scrollController,
            child: SizedBox(
              width: ScreenAdaptation.getDynamicContainerSize().width, // 使用动态宽度以支持滑动
              height: ScreenAdaptation.getAdaptedContainerSize().height,
              child: Stack(
                children: [
                  // 背景图片
                  Positioned.fill(
                    child: Image.asset(
                      "assets/kissu_home_bg.webp",
                      width: 1500, // 固定宽度1500px
                      height: ScreenAdaptation.getDynamicBackgroundSize().height, // 使用动态高度
                      fit: BoxFit.cover, // 改回cover以保持原有显示效果
                    ),
                  ),
                  
                  // PAG动画层 - home_bg_person.pag (已注释)
                  // Positioned(
                  //   left: ScreenAdaptation.scaleXByDynamicWidth(395), // 基于动态背景宽度缩放X坐标
                  //   top: ScreenAdaptation.scaleY(293), // Y坐标基于高度缩放
                  //   child: DelayedPagWidget(
                  //     assetPath: 'assets/pag/home_bg_person.pag',
                  //     width: ScreenAdaptation.scaleSizeByHeight(350), // 基于高度比例缩放大小
                  //     height: ScreenAdaptation.scaleSizeByHeight(380), // 基于高度比例缩放大小
                  //     delay: Duration(milliseconds: 200), // 减少延迟时间
                  //     autoPlay: true,
                  //     repeat: true,
                  //   ),
                  // ),
                  
                  // PAG动画层 - home_bg_fridge.pag (已注释)
                  // Positioned(
                  //   left: ScreenAdaptation.scaleXByDynamicWidth(22), // 基于动态背景宽度缩放X坐标
                  //   top: ScreenAdaptation.scaleY(139), // Y坐标基于高度缩放
                  //   child: DelayedPagWidget(
                  //     assetPath: 'assets/pag/home_bg_fridge.pag',
                  //     width: ScreenAdaptation.scaleSizeByHeight(174), // 基于高度比例缩放大小
                  //     height: ScreenAdaptation.scaleSizeByHeight(364), // 基于高度比例缩放大小
                  //     delay: Duration(milliseconds: 400), // 减少延迟时间
                  //   ),
                  // ),
                  
                  // PAG动画层 - home_bg_clothes.pag (已注释)
                  // Positioned(
                  //   left: ScreenAdaptation.scaleXByDynamicWidth(1228), // 基于动态背景宽度缩放X坐标
                  //   top: ScreenAdaptation.scaleY(68), // Y坐标基于高度缩放
                  //   child: DelayedPagWidget(
                  //     assetPath: 'assets/pag/home_bg_clothes.pag',
                  //     width: ScreenAdaptation.scaleSizeByHeight(272), // 基于高度比例缩放大小
                  //     height: ScreenAdaptation.scaleSizeByHeight(174), // 基于高度比例缩放大小
                  //     delay: Duration(milliseconds: 600), // 减少延迟时间
                  //   ),
                  // ),
                  
                  // PAG动画层 - home_bg_flowers.pag (已注释)
                  // Positioned(
                  //   left: ScreenAdaptation.scaleXByDynamicWidth(675), // 基于动态背景宽度缩放X坐标
                  //   top: ScreenAdaptation.scaleY(268), // Y坐标基于高度缩放
                  //   child: DelayedPagWidget(
                  //     assetPath: 'assets/pag/home_bg_flowers.pag',
                  //     width: ScreenAdaptation.scaleSizeByHeight(232), // 基于高度比例缩放大小
                  //     height: ScreenAdaptation.scaleSizeByHeight(119), // 基于高度比例缩放大小
                  //     delay: Duration(milliseconds: 800), // 减少延迟时间
                  //   ),
                  // ),
                  
                  // PAG动画层 - home_bg_music.pag (已注释)
                  // Positioned(
                  //   left: ScreenAdaptation.scaleXByDynamicWidth(352), // 基于动态背景宽度缩放X坐标
                  //   top: ScreenAdaptation.scaleY(260), // Y坐标基于高度缩放
                  //   child: DelayedPagWidget(
                  //     assetPath: 'assets/pag/home_bg_music.pag',
                  //     width: ScreenAdaptation.scaleSizeByHeight(130), // 基于高度比例缩放大小
                  //     height: ScreenAdaptation.scaleSizeByHeight(108), // 基于高度比例缩放大小
                  //     delay: Duration(milliseconds: 1000), // 减少延迟时间
                  //   ),
                  // ),
                  
                  // 新增的红色容器
                  Positioned(
                    left: 500, // 基于动态背景宽度缩放X坐标
                    top: ScreenAdaptation.scaleY(88), // Y坐标基于高度缩放
                    child: GestureDetector(
                      onTap: () {
                        // 点击事件处理
                        _onRedContainerTap();
                      },
                      child: Container(
                        width: ScreenAdaptation.scaleSizeByHeight(60), // 基于高度比例缩放宽度
                        height: ScreenAdaptation.scaleSizeByHeight(54), // 基于高度比例缩放高度
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  
                ],
              ),
            ),
          ),

          // 底部按钮栏（你已有的）
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFFFD4D0), width: 1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(6, (index) {
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
                        // const SizedBox(height: 4),
                        Image.asset(
                          controller.getBottomIconPath(index),
                          width: index == 3 ? 48 : 24,
                          height: 14,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),


          // 🧪 测试按钮 - 触发截屏反馈按钮显示
          // // 调试按钮 - 显示VIP开通弹窗
          // Positioned(
          //   top: 100,
          //   left: 25,
          //   child: GestureDetector(
          //     onTap: () {
          //       controller.showVipPurchaseDialog();
          //     },
          //     child: Container(
          //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          //       decoration: BoxDecoration(
          //         color: Colors.pink.withOpacity(0.8),
          //         borderRadius: BorderRadius.circular(20),
          //       ),
          //       child: const Text(
          //         '测试VIP弹窗',
          //         style: TextStyle(
          //           color: Colors.white,
          //           fontSize: 12,
          //           fontWeight: FontWeight.bold,
          //         ),
          //       ),
          //     ),
          //   ),
          // ),

          // 头像显示区域 - 根据绑定状态显示不同内容
          Obx(
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
                                Get.to(() => const LoveInfoPage());
                              } else {
                                // 未绑定状态下显示绑定弹窗
                                CustomBottomDialog.show(context: context);
                              }
                            },
                            child: controller.userAvatar.value.startsWith('http')
                                ? NoPlaceholderImage(
                                      imageUrl: controller.userAvatar.value,
                                      defaultAssetPath: "assets/kissu3_love_avater.webp",
                                      width: 38,
                                      height: 38,
                                      fit: BoxFit.cover,
                                      borderRadius: BorderRadius.circular(5),
                                    )
                                : Image.asset(
                                    controller.userAvatar.value,
                                    width: 38,
                                    height: 38,
                                    fit: BoxFit.cover,
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
                                    // 已绑定状态下点击头像跳转到恋爱信息页
                                    Get.to(() => const LoveInfoPage());
                                  },
                                  child: NoPlaceholderImage(
                                    imageUrl: controller.partnerAvatar.value,
                                    defaultAssetPath: "assets/kissu3_love_avater.webp",
                                    width: 38,
                                    height: 38,
                                    fit: BoxFit.cover,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                )
                              : GestureDetector(
                                  onTap: () {
                                    // 显示绑定弹窗
                                    CustomBottomDialog.show(context: context);
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
                      ? Transform.translate(
                          offset: Offset(9, 0),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Color(0xffFFECEA)),
                              borderRadius: BorderRadius.all(
                                Radius.circular(15),
                              ),
                            ),
                            child: Obx(() => Text(
                              "在一起${controller.loveDays.value}天",
                              style: TextStyle(
                                color: Color(0xff666666),
                                fontSize: 12,
                              ),
                            )),
                          ),
                        )
                      : Transform.translate(
                          offset: Offset(9, 0),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Color(0xffFFECEA)),
                              borderRadius: BorderRadius.all(
                                Radius.circular(15),
                              ),
                            ),
                            child: Text(
                              "绑定另一半",
                              style: TextStyle(
                                color: Color(0xff666666),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),

                  const SizedBox(height: 15), // 与下方两个按钮间距
                  // 通知图标和活动图标
                  Transform.translate(
                    offset: const Offset(9, 0),
                    child: Column(
                      children: [
                        // 通知图标（带红点）
                        Stack(
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
                            // 红点角标
                            Obx(() {
                              if (controller.redDotCount.value > 0) {
                                return Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xffFF6B6B),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1,
                                      ),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Text(
                                      controller.redDotCount.value > 99
                                          ? '99+'
                                          : controller.redDotCount.value
                                                .toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            }),
                          ],
                        ),
                        // 活动图标
                        Obx(() {
                          if (controller.isActivity.value &&
                              controller.activityIcon.value.isNotEmpty) {
                            return Column(
                              children: [
                                const SizedBox(height: 20), // 间距30px
                                GestureDetector(
                                  onTap: () {
                                    controller.navigateToH5(
                                      controller.activityLink.value,
                                    );
                                  },
                                  child: Image.network(
                                    controller.activityIcon.value,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const SizedBox.shrink();
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Banner - 只在未绑定时显示

          // 底部组件（根据首页视图内部按钮可切换child）
          Positioned(
            bottom: 90 + 15, // 90 是已有底部按钮栏高度，18 是间距，20 是指示器高度
            left: 0,
            right: 0,
            child: Obx(() {
              final viewModeService = Get.find<ViewModeService>();
              if (viewModeService.isScreenView) {
                // 屏视图：根据绑定状态显示不同的Banner
                return controller.isBound.value
                    ? _buildBannerBind()
                    : _buildBanner();
              } else {
                // 岛视图
                return _bottomListView();
              }
            }),
          ),

          // 引导层覆盖层
          Obx(() => GuideOverlayWidget(
            isVisible: controller.showGuideOverlay.value,
            guideType: controller.currentGuideType.value, // 根据当前状态显示对应引导图
            onDismiss: () {
              if (controller.currentGuideType.value == GuideType.swipe) {
                // 引导图1关闭，执行其他逻辑
                controller.onGuide1Dismissed();
              } else {
                // 引导图2关闭，执行后续逻辑
                controller.onGuide2Dismissed();
              }
            },
            dismissible: true, // 允许点击背景关闭
          )),
        ],
      ),
    );
  }

  //屏视图 - 未绑定状态
  Widget _buildBanner() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 83,
          child: Swiper(
            itemBuilder: (BuildContext context, int index) {
              return Center(
                child: GestureDetector(
                  onTap: () {
                    // 前两张 banner 点击显示绑定弹窗，天气 banner 不需要点击事件
                    if (index < 2) {
                      CustomBottomDialog.show(context: context);
                    }
                  },
                  child: Obx(() {
                    // 获取当前用户的 VIP 状态
                    final isVip = UserManager.isVip;
                    final userAvatarUrl = controller.userAvatar.value;
                    
                    // index == 0: 定位 banner
                    // index == 1: 足迹 banner
                    // index == 2: 天气 banner
                    if (index == 0) {
                      return KissuBannerBuilder.buildLocationBannerWidget(
                        isBound: false,
                        isVip: isVip,
                        userAvatarUrl: userAvatarUrl,
                        width: 302,
                        height: 83,
                      );
                    } else if (index == 1) {
                      return KissuBannerBuilder.buildFootprintBannerWidget(
                        isBound: false,
                        isVip: isVip,
                        userAvatarUrl: userAvatarUrl,
                        width: 302,
                        height: 83,
                      );
                    } else {
                      // 天气 banner
                      return KissuBannerBuilder.buildWeatherBannerWidget(
                        weatherIconUrl: controller.weatherIconUrl.value,
                        weather: controller.weather.value,
                        minTemp: controller.minTemp.value,
                        maxTemp: controller.maxTemp.value,
                        currentTemp: controller.currentTemp.value,
                        isLoading: controller.isWeatherLoading.value,
                        width: 302,
                        height: 83,
                      );
                    }
                  }),
                ),
              );
            },
            autoplay: true,
            loop: true,
            itemCount: 3, // 3 张 banner
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
          () => _buildCustomIndicator(controller.currentSwiperIndex.value, 3), // 3 个点
        ),
      ],
    );
  }

  //已绑定屏视图
  Widget _buildBannerBind() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 83,
          child: Swiper(
            itemBuilder: (BuildContext context, int index) {
              return Center(
                child: GestureDetector(
                  onTap: () {
                    // 前两张 banner 点击跳转到对应页面，天气 banner 不需要点击事件
                    if (index == 0) {
                      Get.toNamed(KissuRoutePath.location);
                    } else if (index == 1) {
                      Get.to(() => TrackPage(), binding: TrackBinding());
                    }
                  },
                  child: Obx(() {
                    // 获取当前用户的 VIP 状态
                    final isVip = UserManager.isVip;
                    final userAvatarUrl = controller.userAvatar.value;
                    final partnerAvatarUrl = controller.partnerAvatar.value;
                    
                    // index == 0: 定位 banner
                    // index == 1: 足迹 banner
                    // index == 2: 天气 banner
                    if (index == 0) {
                      return KissuBannerBuilder.buildLocationBannerWidget(
                        isBound: true,
                        isVip: isVip,
                        userAvatarUrl: userAvatarUrl,
                        partnerAvatarUrl: partnerAvatarUrl,
                        distance: controller.distance.value,
                        width: 302,
                        height: 83,
                      );
                    } else if (index == 1) {
                      return KissuBannerBuilder.buildFootprintBannerWidget(
                        isBound: true,
                        isVip: isVip,
                        userAvatarUrl: userAvatarUrl,
                        partnerAvatarUrl: partnerAvatarUrl,
                        footprintCount: 0, // TODO: 添加实际的足迹数量
                        width: 302,
                        height: 83,
                      );
                    } else {
                      // 天气 banner
                      return KissuBannerBuilder.buildWeatherBannerWidget(
                        weatherIconUrl: controller.weatherIconUrl.value,
                        weather: controller.weather.value,
                        minTemp: controller.minTemp.value,
                        maxTemp: controller.maxTemp.value,
                        currentTemp: controller.currentTemp.value,
                        isLoading: controller.isWeatherLoading.value,
                        width: 302,
                        height: 83,
                      );
                    }
                  }),
                ),
              );
            },
            autoplay: true,
            loop: true,
            itemCount: 3, // 3 张 banner
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
          () => _buildCustomIndicator(controller.currentSwiperIndex.value, 3), // 3 个点
        ),
      ],
    );
  }

  /// 岛视图
  Widget _bottomListView() {
    return _AnimatedIslandView(controller: controller);
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

/// 带动画的岛视图组件
class _AnimatedIslandView extends StatefulWidget {
  final HomeController controller;

  const _AnimatedIslandView({Key? key, required this.controller}) : super(key: key);

  @override
  _AnimatedIslandViewState createState() => _AnimatedIslandViewState();
}

class _AnimatedIslandViewState extends State<_AnimatedIslandView>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 创建缩放动画控制器
    _scaleController = AnimationController(
      duration: const Duration(seconds: 2), // 2秒一个周期
      vsync: this,
    );

    // 创建缩放动画：从0.95到1.05，然后回到0.95
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // 开始循环动画
    _startAnimation();
  }

  void _startAnimation() {
    _scaleController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Obx(() {
            final controller = widget.controller;
            final isVip = UserManager.isVip;
            final isBound = controller.isBound.value;
            
            // 根据VIP和绑定状态决定是否显示真实数据
            final shouldMaskData = isBound && !isVip;
            
            // 停留点显示文本
            final stayCountText = shouldMaskData 
                ? '* 个停留点' 
                : '${controller.stayCount.value}个停留点';
            
            // 距离显示文本
            final distanceText = shouldMaskData 
                ? '* KM' 
                : controller.distance.value;
            
            // 天气显示文本（天气始终显示真实数据）
            final weatherText = controller.currentTemp.value != null && controller.weather.value != null
                ? '${controller.currentTemp.value}°${controller.weather.value}'
                : '加载中...';
            
            return Column(
              children: [
                // 足迹按钮
                IslandViewButton(
                  iconAsset: "assets/home_list_type_foot.webp",
                  title: "TA的足迹",
                  value: stayCountText,
                  valueColor: Color(0xffFF6591),
                  onTap: () {
                    Get.to(() => TrackPage(), binding: TrackBinding());
                  },
                ),
                SizedBox(height: 4),
                // 定位按钮
                IslandViewButton(
                  iconAsset: "assets/home_list_type_location.webp",
                  title: "我们相距",
                  value: distanceText,
                  valueColor: Color(0xff3580FF),
                  onTap: () {
                    Get.to(() => LocationPage(), binding: LocationBinding());
                  },
                ),
                SizedBox(height: 4),
                // 天气按钮（无点击事件，不显示箭头）
                IslandViewButton(
                  iconAsset: "assets/home_list_type_location.webp",
                  title: "TA的天气",
                  value: weatherText,
                  valueColor: Color(0xff3580FF),
                  showArrow: false,
                ),
              ],
            );
          }),
        );
      },
    );
  }
}
