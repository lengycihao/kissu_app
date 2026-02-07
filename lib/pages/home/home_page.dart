import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/home/home_controller.dart';
import 'package:kissu_app/widgets/no_placeholder_image.dart';
import 'package:kissu_app/utils/screen_adaptation.dart';
import 'package:kissu_app/widgets/guide_overlay_widget.dart';
import 'package:kissu_app/pages/home/widget/home_avatar_section.dart';
import 'package:kissu_app/widgets/dialogs/image_dialog_util.dart';
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
    // 应用生命周期变化时不需要特殊处理
    // 埋点逻辑已统一在 HomeController 中处理，避免重复上报
    if (state == AppLifecycleState.resumed) {
      final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;
      if (isCurrentRoute) {
        debugPrint('🏠 应用回到前台且首页可见');
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
            physics: const BouncingScrollPhysics(),
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
                      fit: BoxFit.cover, // 填充全屏，避免底部留白
                    ),
                  ),

                   
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
                        // 点击照片墙打开编辑弹窗
                        ImageDialogUtil.showImageDialog(
                          context: context,
                          imagePath: 'assets/3.0/kissu3_photo_viewbg.webp',
                          currentPhotoWallUrl: controller.photoWallUrl.value.startsWith('http')
                              ? controller.photoWallUrl.value
                              : null,
                          onUploadSuccess: () {
                            // 上传成功后刷新首页数据
                            controller.loadIndexData();
                          },
                        );
                      },
                      child: Obx(
                        () => ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Container(
                            width: ScreenAdaptation.scaleXByDynamicWidth(
                              52,
                            ), // 基于高度比例缩放宽度
                            height: ScreenAdaptation.scaleSizeByHeight(
                              52,
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
                              left: 5,
                              right: 5,
                              top: 5,
                              bottom: 5,
                            ),
                            child: SizedBox(
                              width: ScreenAdaptation.scaleXByDynamicWidth(42),
                              height: ScreenAdaptation.scaleSizeByHeight(42),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
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

          // 种草浮动按钮 - 在导航栏上方
          Obx(() {
            
            if (!controller.showSeedingButton.value || controller.seedingIcon.value.isEmpty) {
              return const SizedBox.shrink();
            }
            
            return Positioned(
              bottom: 30 + 64 + 40, // 导航栏高度64 + 底部间距30 + 按钮与导航栏间距15
              right: 20,
              child: GestureDetector(
                onTap: controller.openSeedingLink,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 按钮主体 - 显示图标
                    Container(
                      width: 60,
                      height: 60,
                      
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: NoPlaceholderImage(
                          imageUrl: controller.seedingIcon.value,
                          defaultAssetPath: "assets/images/kissu_icon.webp",
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // 关闭按钮 - 右上角
                    Positioned(
                      right: -4,
                      top: -8,
                      child: GestureDetector(
                        onTap: () {
                          controller.closeSeedingButton();
                        },
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Color(0xff666666),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Color(0xff666666),
                            weight: 4,
                            size: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // 底部按钮栏（自定义悬浮tabbar）
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Obx(() {
              final unread = controller.chatUnreadCount.value;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0x9effffff),
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(35),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(5, (index) {
                    final showBadge = index == 2 && unread > 0;
                    return Expanded(
                      child: InkWell(
                        onTap: () => controller.onButtonTap(index),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Image.asset(
                                  controller.getTopIconPath(index),
                                  width: 34,
                                  height: 34,
                                ),
                                if (showBadge)
                                  Positioned(
                                    right: -2,
                                    top: -2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 1),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF4D67),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        unread > 99 ? '99+' : unread.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              controller.getTabTitle(index),
                              style: const TextStyle(
                                color: Color(0xFF4C342A),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
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

          // 底部组件已移除，保持界面简洁
          Positioned(
            bottom: 70 + 30 + 15, // 保留原位置占位（可选）
            left: 0,
            right: 0,
            child: const SizedBox.shrink(),
          ),

          // 引导层覆盖层
          Obx(
            () => GuideOverlayWidget(
              isVisible: controller.showGuideOverlay.value,
              guideType: controller.currentGuideType.value, 
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

 

  // Banner-related helpers removed
}

// Animated island view removed as part of bottom module cleanup
