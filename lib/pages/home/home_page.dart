import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/home/home_controller.dart';
import 'package:kissu_app/widgets/no_placeholder_image.dart';
import 'package:kissu_app/widgets/delayed_pag_widget.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/services/view_mode_service.dart';
import 'package:kissu_app/pages/mine/love_info/love_info_page.dart';
import 'package:kissu_app/pages/location/location_page.dart';
import 'package:kissu_app/pages/location/location_binding.dart';
import 'package:kissu_app/pages/track/track_page.dart';
import 'package:kissu_app/pages/track/track_binding.dart';
import 'package:kissu_app/utils/screen_adaptation.dart';


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
                      "assets/kissu_home_bg.png",
                      width: ScreenAdaptation.getDynamicBackgroundSize().width, // 使用动态宽度
                      height: ScreenAdaptation.getDynamicBackgroundSize().height, // 使用动态高度
                      fit: BoxFit.cover, // 改回cover以保持原有显示效果
                    ),
                  ),
                  
                  // PAG动画层 - home_bg_person.pag (优化延迟时间)
                  Positioned(
                    left: ScreenAdaptation.scaleXByDynamicWidth(395), // 基于动态背景宽度缩放X坐标
                    top: ScreenAdaptation.scaleY(293), // Y坐标基于高度缩放
                    child: DelayedPagWidget(
                      assetPath: 'assets/pag/home_bg_person.pag',
                      width: ScreenAdaptation.scaleSizeByHeight(350), // 基于高度比例缩放大小
                      height: ScreenAdaptation.scaleSizeByHeight(380), // 基于高度比例缩放大小
                      delay: Duration(milliseconds: 200), // 减少延迟时间
                      autoPlay: true,
                      repeat: true,
                    ),
                  ),
                  
                  // PAG动画层 - home_bg_fridge.pag (优化延迟时间)
                  Positioned(
                    left: ScreenAdaptation.scaleXByDynamicWidth(22), // 基于动态背景宽度缩放X坐标
                    top: ScreenAdaptation.scaleY(139), // Y坐标基于高度缩放
                    child: DelayedPagWidget(
                      assetPath: 'assets/pag/home_bg_fridge.pag',
                      width: ScreenAdaptation.scaleSizeByHeight(174), // 基于高度比例缩放大小
                      height: ScreenAdaptation.scaleSizeByHeight(364), // 基于高度比例缩放大小
                      delay: Duration(milliseconds: 400), // 减少延迟时间
                    ),
                  ),
                  
                  // PAG动画层 - home_bg_clothes.pag (优化延迟时间)
                  Positioned(
                    left: ScreenAdaptation.scaleXByDynamicWidth(1228), // 基于动态背景宽度缩放X坐标
                    top: ScreenAdaptation.scaleY(68), // Y坐标基于高度缩放
                    child: DelayedPagWidget(
                      assetPath: 'assets/pag/home_bg_clothes.pag',
                      width: ScreenAdaptation.scaleSizeByHeight(272), // 基于高度比例缩放大小
                      height: ScreenAdaptation.scaleSizeByHeight(174), // 基于高度比例缩放大小
                      delay: Duration(milliseconds: 600), // 减少延迟时间
                    ),
                  ),
                  
                  // PAG动画层 - home_bg_flowers.pag (优化延迟时间)
                  Positioned(
                    left: ScreenAdaptation.scaleXByDynamicWidth(675), // 基于动态背景宽度缩放X坐标
                    top: ScreenAdaptation.scaleY(268), // Y坐标基于高度缩放
                    child: DelayedPagWidget(
                      assetPath: 'assets/pag/home_bg_flowers.pag',
                      width: ScreenAdaptation.scaleSizeByHeight(232), // 基于高度比例缩放大小
                      height: ScreenAdaptation.scaleSizeByHeight(119), // 基于高度比例缩放大小
                      delay: Duration(milliseconds: 800), // 减少延迟时间
                    ),
                  ),
                  
                  // PAG动画层 - home_bg_music.pag (优化延迟时间)
                  Positioned(
                    left: ScreenAdaptation.scaleXByDynamicWidth(352), // 基于动态背景宽度缩放X坐标
                    top: ScreenAdaptation.scaleY(260), // Y坐标基于高度缩放
                    child: DelayedPagWidget(
                      assetPath: 'assets/pag/home_bg_music.pag',
                      width: ScreenAdaptation.scaleSizeByHeight(130), // 基于高度比例缩放大小
                      height: ScreenAdaptation.scaleSizeByHeight(108), // 基于高度比例缩放大小
                      delay: Duration(milliseconds: 1000), // 减少延迟时间
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
              top: 55, // 与下面按钮保持20px间距
              right: 25,
              child: Column(
                children: [
                  // 未绑定状态 - 显示加号按钮
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 第一个加号按钮
                      Transform.translate(
                        offset: const Offset(45, 0),
                        child: Transform.rotate(
                          angle: 30 * 3.1415926535 / 180, // 逆时针30度
                          child: controller.userAvatar.value.startsWith('http')
                              ? NoPlaceholderImage(
                                    imageUrl: controller.userAvatar.value,
                                    defaultAssetPath: "assets/kissu_icon.webp",
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
                                    defaultAssetPath: "assets/kissu_icon.webp",
                                    width: 38,
                                    height: 38,
                                    fit: BoxFit.cover,
                                    borderRadius: BorderRadius.circular(5),
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
        ],
      ),
    );
  }

  //屏视图
  Widget _buildBanner() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 81,
          child: Swiper(
            itemBuilder: (BuildContext context, int index) {
              return Center(
                child: GestureDetector(
                  onTap: () {
                     Get.toNamed(KissuRoutePath.share);
                  },
                  child: Container(
                    width: 303,
                    height: 81,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                          index == 0
                              ? "assets/home_banner_bg3.webp"
                              : "assets/kissu_home_bind_last.webp",
                              
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: index == 1
                        ? Stack(
                            children: [
                              Positioned(
                                left: 16,
                                bottom: 8,
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
                                      borderRadius: BorderRadiusGeometry.circular(15),
                                      child: NoPlaceholderImage(
                                        imageUrl: controller.userAvatar.value,
                                        defaultAssetPath: "assets/kissu_icon.webp",
                                        width: 28,
                                        height: 28,
                                        fit: BoxFit.cover,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Stack(
                            children: [
                              Positioned(
                                left: 16,
                                bottom: 8,
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
                                      borderRadius: BorderRadiusGeometry.circular(
                                        15,
                                      ),
                                      child: NoPlaceholderImage(
                                        imageUrl: controller.userAvatar.value,
                                        defaultAssetPath: "assets/kissu_icon.webp",
                                        width: 28,
                                        height: 28,
                                        fit: BoxFit.cover,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              );
            },
            autoplay: true,
            loop: true,
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
          () => _buildCustomIndicator(controller.currentSwiperIndex.value, 2),
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
                            ? "assets/home_banner_bg_bing.webp"
                            : "assets/kissu_home_bind_last.webp",
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: index == 0
                      ? GestureDetector(
                          onTap: () {
                            Get.toNamed(KissuRoutePath.location);
                          },
                          child: Stack(
                            children: [
                              Center(
                                child: Container(
                                  width: 55,
                                  height: 18,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(
                                      color: Color(0xffFF88AA),
                                      width: 1,
                                    ),
                                  ),
                                  child: Obx(
                                    () => Text(
                                      controller.distance.value,
                                      style: TextStyle(
                                        color: Color(0xff000000),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 26,
                                bottom: 8,
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
                                          BorderRadiusGeometry.circular(15),
                                      child: NoPlaceholderImage(
                                        imageUrl: controller.partnerAvatar.value,
                                        defaultAssetPath: "assets/kissu_icon.webp",
                                        width: 28,
                                        height: 28,
                                        fit: BoxFit.cover,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 16,
                                bottom: 8,
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
                                          BorderRadiusGeometry.circular(15),
                                      child: NoPlaceholderImage(
                                        imageUrl: controller.userAvatar.value,
                                        defaultAssetPath: "assets/kissu_icon.webp",
                                        width: 28,
                                        height: 28,
                                        fit: BoxFit.cover,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : GestureDetector(
                          onTap: () {
                            Get.toNamed(KissuRoutePath.location);
                          },
                          child: Stack(
                            children: [
                              // Center(
                              //   child: Container(
                              //     width: 55,
                              //     height: 18,
                              //     alignment: Alignment.center,
                              //     decoration: BoxDecoration(
                              //       color: Colors.white,
                              //       borderRadius: BorderRadius.circular(9),
                              //       border: Border.all(
                              //         color: Color(0xffFF88AA),
                              //         width: 1,
                              //       ),
                              //     ),
                              //     child: Obx(
                              //       () => Text(
                              //         controller.distance.value,
                              //         style: TextStyle(
                              //           color: Color(0xff000000),
                              //           fontSize: 12,
                              //         ),
                              //       ),
                              //     ),
                              //   ),
                              // ),
                              Positioned(
                                left: 16,
                                bottom: 8,
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
                                      borderRadius: BorderRadiusGeometry.circular(
                                        15,
                                      ),
                                      child: NoPlaceholderImage(
                                        imageUrl: controller.userAvatar.value,
                                        defaultAssetPath: "assets/kissu_icon.webp",
                                        width: 28,
                                        height: 28,
                                        fit: BoxFit.cover,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              );
            },
            autoplay: true,
            loop: true,
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
          () => _buildCustomIndicator(controller.currentSwiperIndex.value, 2),
        ),
      ],
    );
  }

  /// 岛视图
  Widget _bottomListView() {
    return _AnimatedIslandView();
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
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  // 点击足迹记录，跳转到足迹页面
                  Get.to(() => TrackPage(), binding: TrackBinding());
                },
                child: Container(
                  width: 178,
                  height: 36,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/home_list_bg.webp"),
                      fit: BoxFit.fill,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Image(
                        image: AssetImage("assets/home_list_type_foot.webp"),
                        width: 20,
                        height: 20,
                      ),
                      Text(
                        "TA的足迹记录",
                        style: TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 12,
                        ),
                      ),
                      Image(
                        image: AssetImage("assets/kissu_mine_arrow.webp"),
                        width: 16,
                        height: 16,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  // 点击定位，跳转到定位页面
                  Get.to(() => LocationPage(), binding: LocationBinding());
                },
                child: Container(
                  width: 178,
                  height: 36,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/home_list_bg.webp"),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Image(
                        image: AssetImage(
                          "assets/home_list_type_location.webp",
                        ),
                        width: 20,
                        height: 20,
                      ),
                      Text(
                        "今天我们的定位",
                        style: TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 12,
                        ),
                      ),
                      Image(
                        image: AssetImage("assets/kissu_mine_arrow.webp"),
                        width: 16,
                        height: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
