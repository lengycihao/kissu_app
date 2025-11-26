import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/home/home_controller.dart';
import 'package:kissu_app/widgets/dialogs/image_dialog_util.dart';
import 'package:kissu_app/widgets/no_placeholder_image.dart';
import 'package:kissu_app/services/view_mode_service.dart';
import 'package:kissu_app/pages/track/track_page.dart';
import 'package:kissu_app/pages/track/track_binding.dart';
import 'package:kissu_app/utils/screen_adaptation.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/widgets/guide_overlay_widget.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog_controller.dart';
import 'package:kissu_app/widgets/kissu_banner_builder.dart';
import 'package:kissu_app/widgets/island_view_button.dart';
import 'package:kissu_app/utils/vip_navigation_helper.dart';
import 'package:kissu_app/services/tracking_service.dart';
import 'package:kissu_app/pages/home/widget/home_avatar_section.dart';
import 'package:lottie/lottie.dart';

class KissuHomePage extends StatefulWidget {
  const KissuHomePage({super.key});

  @override
  State<KissuHomePage> createState() => _KissuHomePageState();
}

class _KissuHomePageState extends State<KissuHomePage>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
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

    // 应用生命周期变化时不需要特殊处理
    // 用户信息刷新已通过静态变量控制在app启动时只执行一次
    if (state == AppLifecycleState.resumed) {
      final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;
      if (isCurrentRoute) {
        debugPrint('🏠 应用回到前台且首页可见，但不需要刷新用户信息（已通过静态变量控制）');
      } else {
        debugPrint('🏠 应用回到前台但首页不可见');
      }
    }
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
              width: ScreenAdaptation.getDynamicContainerSize()
                  .width, // 使用动态宽度以支持滑动
              height: ScreenAdaptation.getAdaptedContainerSize().height,
              child: Stack(
                children: [
                  // 背景图片
                  Positioned.fill(
                    child: Image.asset(
                      "assets/images/kissu_home_bg.webp",
                      width: 1125, // 固定宽度1500px
                      height: ScreenAdaptation.getDynamicBackgroundSize()
                          .height, // 使用动态高度
                      fit: BoxFit.contain, // 改回cover以保持原有显示效果
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

                  // Lottie 动画层 - home_light.json
                  Positioned(
                    left: ScreenAdaptation.scaleXByDynamicWidth(
                      71,
                    ), // 基于动态背景宽度缩放X坐标
                    top: ScreenAdaptation.scaleY(0), // Y坐标基于高度缩放
                    child: Lottie.asset(
                      'assets/json/home_light.json',
                      width: ScreenAdaptation.scaleXByDynamicWidth(
                        265,
                      ), // 基于动态背景宽度缩放宽度
                      height: ScreenAdaptation.scaleSizeByHeight(
                        164,
                      ), // 基于高度比例缩放高度
                      fit: BoxFit.contain,
                      repeat: true,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('❌ home_light.json 加载失败: $error');
                        return SizedBox.shrink();
                      },
                    ),
                  ),
                  // 静态图片 - kissu4_home_light.webp
                  Positioned(
                    left: ScreenAdaptation.scaleXByDynamicWidth(
                      332,
                    ), // 基于动态背景宽度缩放X坐标
                    top: ScreenAdaptation.scaleY(0), // Y坐标基于高度缩放
                    child: Image.asset(
                      'assets/home/kissu4_home_light.webp',
                      width: ScreenAdaptation.scaleXByDynamicWidth(
                        111,
                      ), // 基于动态背景宽度缩放宽度
                      height: ScreenAdaptation.scaleSizeByHeight(
                        164,
                      ), // 基于高度比例缩放高度
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('❌ home_light.png 加载失败: $error');
                        return SizedBox.shrink();
                      },
                    ),
                  ),
                  // 静态图片 - kissu_home_person.webp
                  Positioned(
                    left: ScreenAdaptation.scaleXByDynamicWidth(
                      429,
                    ), // 基于动态背景宽度缩放X坐标
                    top: ScreenAdaptation.scaleY(280), // Y坐标基于高度缩放
                    child: Image.asset(
                      'assets/home/kissu_home_person.webp',
                      width: ScreenAdaptation.scaleXByDynamicWidth(
                        305,
                      ), // 基于动态背景宽度缩放宽度
                      height: ScreenAdaptation.scaleSizeByHeight(
                        320,
                      ), // 基于高度比例缩放高度
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('❌ home_light.png 加载失败: $error');
                        return SizedBox.shrink();
                      },
                    ),
                  ),
                   // 静态图片 - kissu_home_person.webp
                  Positioned(
                    left: ScreenAdaptation.scaleXByDynamicWidth(
                      620,
                    ), // 基于动态背景宽度缩放X坐标
                    top: ScreenAdaptation.scaleY(44), // Y坐标基于高度缩放
                    child: Image.asset(
                      'assets/home/kissu_home_window.webp',
                      width: ScreenAdaptation.scaleXByDynamicWidth(
                        422,
                      ), // 基于动态背景宽度缩放宽度
                      height: ScreenAdaptation.scaleSizeByHeight(
                        370,
                      ), // 基于高度比例缩放高度
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('❌ home_light.png 加载失败: $error');
                        return SizedBox.shrink();
                      },
                    ),
                  ),
                  // Lottie 动画层 - home_audio.json
                  Positioned(
                    left: ScreenAdaptation.scaleXByDynamicWidth(
                      499,
                    ), // 基于动态背景宽度缩放X坐标
                    top: ScreenAdaptation.scaleY(147), // Y坐标基于高度缩放
                    child: Lottie.asset(
                      'assets/json/home_audio.json',
                      width: ScreenAdaptation.scaleXByDynamicWidth(
                        78,
                      ), // 基于动态背景宽度缩放宽度
                      height: ScreenAdaptation.scaleSizeByHeight(
                        84,
                      ), // 基于高度比例缩放高度
                      fit: BoxFit.contain,
                      repeat: true,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('❌ home_audio.json 加载失败: $error');
                        return SizedBox.shrink();
                      },
                    ),
                  ),

                  // Lottie 动画层 - home_dog.json
                  Positioned(
                    left: ScreenAdaptation.scaleXByDynamicWidth(
                      74,
                    ), // 基于动态背景宽度缩放X坐标
                    top: ScreenAdaptation.scaleY(521), // Y坐标基于高度缩放
                    child: Lottie.asset(
                      'assets/json/home_dog.json',
                      width: ScreenAdaptation.scaleXByDynamicWidth(
                        216,
                      ), // 基于动态背景宽度缩放宽度
                      height: ScreenAdaptation.scaleSizeByHeight(
                        130,
                      ), // 基于高度比例缩放高度
                      fit: BoxFit.contain,
                      repeat: true,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('❌ home_dog.json 加载失败: $error');
                        return SizedBox.shrink();
                      },
                    ),
                  ),

                  // 照片墙容器
                  Positioned(
                    left: ScreenAdaptation.scaleXByDynamicWidth(
                      532,
                    ), // 基于动态背景宽度缩放X坐标
                    top: ScreenAdaptation.scaleY(66), // Y坐标基于高度缩放
                    child: GestureDetector(
                      onTap: () {
                        // 点击事件处理
                        _onRedContainerTap();
                      },
                      child: Obx(
                        () => ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: ScreenAdaptation.scaleXByDynamicWidth(
                              80,
                            ), // 基于高度比例缩放宽度
                            height: ScreenAdaptation.scaleSizeByHeight(
                              78,
                            ), // 基于高度比例缩放高度
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(
                                  "assets/images/kissu_home_avair_bg.webp",
                                ),
                                fit: BoxFit.fill,
                              ),
                            ),
                            padding: EdgeInsets.only(
                              left: 17,
                              right: 15,
                              top: 18,
                              bottom: 16,
                            ),
                            child: SizedBox(
                              width: ScreenAdaptation.scaleXByDynamicWidth(48),
                              height: ScreenAdaptation.scaleSizeByHeight(44),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child:
                                    controller.photoWallUrl.value.startsWith(
                                      'http',
                                    )
                                    ? NoPlaceholderImage(
                                        imageUrl: controller.photoWallUrl.value,
                                        defaultAssetPath:
                                            "assets/images/kissu_icon.webp",
                                        width:
                                            ScreenAdaptation.scaleXByDynamicWidth(
                                              48,
                                            ),
                                        height:
                                            ScreenAdaptation.scaleSizeByHeight(
                                              44,
                                            ),
                                        fit: BoxFit.cover,
                                      )
                                    : Image.asset(
                                        controller.photoWallUrl.value,
                                        width:
                                            ScreenAdaptation.scaleXByDynamicWidth(
                                              48,
                                            ),
                                        height:
                                            ScreenAdaptation.scaleSizeByHeight(
                                              44,
                                            ),
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                          ),
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
                        // const SizedBox(height: 4),
                        Image.asset(
                          controller.getBottomIconPath(index),
                          width: index == 2 ? 48 : 24,
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
          HomeAvatarSection(controller: controller),

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
          Obx(
            () => GuideOverlayWidget(
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
            ),
          ),
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
          child: Listener(
            onPointerDown: (_) {
              // 用户触摸了 banner，标记为手动滑动
              controller.isBannerManuallyDragged.value = true;
            },
            child: Swiper(
              itemBuilder: (BuildContext context, int index) {
                return Center(
                  child: GestureDetector(
                    onTap: () async {
                      // 前两张 banner 点击显示绑定弹窗，天气 banner 不需要点击事件
                      if (index < 2) {
                        // 获取点击类型
                        final clickType = index == 0 ? '定位' : '足迹';

                        // 上报埋点：屏视图 Banner 点击
                        await TrackingService.trackHomeBannerClick(
                          isDrag: controller.isBannerManuallyDragged.value,
                          clickType: clickType,
                          isVip: UserManager.isVip,
                          isBind: false, // 未绑定状态
                        );

                        CustomBottomDialog.show(
                          context: context,
                          caller: BindingDialogCaller.home,
                        );
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
                          travelTool: controller.travelTool.value,
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
                // 索引变化后，重置手动滑动标记为 false（自动播放）
                // 如果是手动滑动，会在 onTap 之前被 GestureDetector 的 onPanDown 捕获
                Future.delayed(const Duration(milliseconds: 100), () {
                  controller.isBannerManuallyDragged.value = false;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 外置的指示器
        Obx(
          () => _buildCustomIndicator(
            controller.currentSwiperIndex.value,
            3,
          ), // 3 个点
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
          child: Listener(
            onPointerDown: (_) {
              // 用户触摸了 banner，标记为手动滑动
              controller.isBannerManuallyDragged.value = true;
            },
            child: Swiper(
              itemBuilder: (BuildContext context, int index) {
                return Center(
                  child: GestureDetector(
                    onTap: () async {
                      // 前两张 banner 点击跳转到对应页面，天气 banner 不需要点击事件
                      if (index == 0) {
                        // 获取点击类型
                        final clickType = '定位';

                        // 上报埋点：屏视图 Banner 点击
                        await TrackingService.trackHomeBannerClick(
                          isDrag: controller.isBannerManuallyDragged.value,
                          clickType: clickType,
                          isVip: UserManager.isVip,
                          isBind: true, // 已绑定状态
                        );

                        // 定位banner - 添加会员检查
                        VipNavigationHelper.navigateToLocationWithVipCheck();
                      } else if (index == 1) {
                        // 获取点击类型
                        final clickType = '足迹';

                        // 上报埋点：屏视图 Banner 点击
                        await TrackingService.trackHomeBannerClick(
                          isDrag: controller.isBannerManuallyDragged.value,
                          clickType: clickType,
                          isVip: UserManager.isVip,
                          isBind: true, // 已绑定状态
                        );

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
                          travelTool: controller.travelTool.value,
                          width: 302,
                          height: 83,
                        );
                      } else if (index == 1) {
                        return KissuBannerBuilder.buildFootprintBannerWidget(
                          isBound: true,
                          isVip: isVip,
                          userAvatarUrl: userAvatarUrl,
                          partnerAvatarUrl: partnerAvatarUrl,
                          footprintCount:
                              controller.stayCount.value, // 显示实际的足迹数量
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
                // 索引变化后，重置手动滑动标记为 false（自动播放）
                // 如果是手动滑动，会在 onTap 之前被 GestureDetector 的 onPanDown 捕获
                Future.delayed(const Duration(milliseconds: 100), () {
                  controller.isBannerManuallyDragged.value = false;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 外置的指示器
        Obx(
          () => _buildCustomIndicator(
            controller.currentSwiperIndex.value,
            3,
          ), // 3 个点
        ),
      ],
    );
  }

  //照片墙
  void _onRedContainerTap() {
    ImageDialogUtil.showImageDialog(
      context: context,
      imagePath: "assets/3.0/kissu3_picture_wall.webp",
      barrierDismissible: false,
      currentPhotoWallUrl: controller.photoWallUrl.value, // 传入当前照片墙的URL
      onUploadSuccess: () {
        // 上传成功后刷新首页数据
        controller.loadIndexData();
      },
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

  const _AnimatedIslandView({Key? key, required this.controller})
    : super(key: key);

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
            final weatherText =
                controller.currentTemp.value != null &&
                    controller.weather.value != null
                ? '${controller.currentTemp.value}°${controller.weather.value}'
                : '';

            return Column(
              children: [
                // 足迹按钮
                IslandViewButton(
                  iconAsset: "assets/images/home_list_type_foot.webp",
                  title: "TA的足迹",
                  value: stayCountText,
                  valueColor: Color(0xffFF6591),
                  onTap: () async {
                    // 上报埋点：岛视图按钮点击
                    await TrackingService.trackHomeIslandClick(
                      clickType: '足迹',
                      isVip: UserManager.isVip,
                      isBind: controller.isBound.value,
                    );

                    Get.to(() => TrackPage(), binding: TrackBinding());
                  },
                ),
                SizedBox(height: 4),
                // 定位按钮
                IslandViewButton(
                  iconAsset: "assets/images/home_list_type_location.webp",
                  title: "我们相距",
                  value: distanceText,
                  valueColor: Color(0xff6D5DFF),
                  onTap: () async {
                    // 上报埋点：岛视图按钮点击
                    await TrackingService.trackHomeIslandClick(
                      clickType: '定位',
                      isVip: UserManager.isVip,
                      isBind: controller.isBound.value,
                    );

                    // 距离按钮 - 添加会员检查
                    VipNavigationHelper.navigateToLocationWithVipCheck();
                  },
                ),
                SizedBox(height: 4),
                // 天气按钮（无点击事件，不显示箭头）
                IslandViewButton(
                  iconUrl: controller.weatherIconUrl.value,
                  iconAsset:
                      "assets/images/home_list_type_location.webp", // 备用图标
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
