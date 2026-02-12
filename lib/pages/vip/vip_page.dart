import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/network_image_helper.dart';
import 'package:kissu_app/models/vip_banner_model.dart';
import 'package:kissu_app/pages/vip/vip_controller.dart';
import 'package:kissu_app/network/interceptor/business_header_interceptor.dart';
import 'components/vip_payment_component.dart';
import 'components/vip_price_section.dart';
import 'components/vip_top_feature_section.dart';
import 'components/vip_comment_section.dart';

class VipPage extends StatefulWidget {
  const VipPage({super.key});

  @override
  State<VipPage> createState() => _VipPageState();
}

class _VipPageState extends State<VipPage> with WidgetsBindingObserver {
  late VipController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<VipController>();
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
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      controller.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      controller.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听页面可见性变化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupPageVisibilityListener();
    });

    // 计算底部支付组件的实际高度
    // 包括：支付方式选项(~44) + 间距(10) + 按钮(50) + 间距(15) + 协议文字(~20) + 顶部padding(10) + 底部padding(25) + 底部安全区域
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const double paymentBaseHeight =
        44.0 + 10.0 + 50.0 + 15.0 + 20.0; // 额外增加20px缓冲
    const double paymentExtraBuffer = 20.0;
    final paymentComponentHeight =
        paymentBaseHeight + bottomPadding + paymentExtraBuffer;

    return PopScope(
      canPop: false, // 统一由 onBackTap 控制返回行为
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // 拦截物理返回键，显示挽留弹窗
        await controller.onBackTap();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFffffff),
        body: Stack(
          children: [
            // 主要内容区域 - 添加底部padding为支付组件留出空间
            SingleChildScrollView(
                controller: controller.mainScrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: paymentComponentHeight,
                  ), // 动态计算底部padding
                  child: Column(
                    children: [
                      // 顶部轮播图 - 紧贴屏幕顶部，全宽度
                      _buildTopCarousel(),

                      // 其他内容使用padding，从图片按钮下方开始应用渐变背景
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x80FDE0F9), Color(0xFFFFFFFF)],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              // 顶部说明 + 指示条 + 图标按钮
                              VipTopFeatureSection(controller: controller),

                              // 价格组件（首屏位置）
                              VipPriceSection(controller: controller),

                              // const SizedBox(height: 15),
                              // const Align(
                              //   alignment: Alignment.centerLeft,
                              //   child: Text(
                              //     '会员到期自动续费，可以随时取消',
                              //     style: TextStyle(
                              //       fontSize: 12,
                              //       color: Color(0xFFABABAB),
                              //     ),
                              //   ),
                              // ),
                              const SizedBox(height: 15),

                              // 第二个开通提示图片
                              _buildOpenTipImage(),

                              const SizedBox(height: 15),

                              // 信息背景图片
                              _buildInfoBackground(),

                              const SizedBox(height: 20),

                              // 提示文字
                              _buildHintText(),

                              const SizedBox(height: 20),

                              // 用户评价 + 底部再次展示套餐
                              VipCommentSection(controller: controller),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
           

            // 固定的返回按钮
            Positioned(
              left: 5,
              top: MediaQuery.of(context).padding.top,
              child: GestureDetector(
                onTap: controller.onBackTap,
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/images/kissu_mine_back.webp',
                    width: 22,
                    height: 22,
                  ),
                ),
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: const VipPaymentComponent(),
            ),
          ],
        ),
      ),
    );
  }

  // 顶部轮播图
  Widget _buildTopCarousel() {
    // 本地静态图片文件列表（作为兜底数据）
    final localImageAssets = [
      'assets/images/kissu4_vip_banner_location.webp',
      'assets/images/kissu4_vip_banner_track.webp',
      'assets/images/kissu4_vip_banner_history.webp',
      'assets/images/kissu4_vip_banner_mingan.webp',
    ];

    return Obx(() {
      final banners = controller.bannerData.value?.vipIconBanner ?? [];
      final hasRemoteData = banners.isNotEmpty;
      final itemCount = hasRemoteData
          ? banners.length
          : localImageAssets.length;

      return SizedBox(
        height: 248,
        child: PageView.builder(
          controller: controller.pageController,
          onPageChanged: controller.onPageChanged,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (hasRemoteData) {
              return _buildRemoteBannerItem(banners[index]);
            }
            return _buildImageItem(localImageAssets[index]);
          },
        ),
      );
    });
  }

  // 静态图片项
  Widget _buildImageItem(String imageAssetPath) {
    return Image.asset(
      imageAssetPath,
      width: double.infinity,
      height: 248,
      fit: BoxFit.fitHeight,
    );
  }

  Widget _buildRemoteBannerItem(VipIconBanner banner) {
    final displayUrl = banner.displayContent;
    if (displayUrl.isEmpty) {
      return _buildImageItem('assets/kissu4_vip_banner_location.webp');
    }

    return NetworkImageHelper.loadImage(
      imageUrl: displayUrl,
      width: double.infinity,
      height: 248,
      fit: BoxFit.cover,
      errorWidget: Image.asset(
        'assets/images/kissu4_vip_banner_location.webp',
        width: double.infinity,
        height: 248,
        fit: BoxFit.fitHeight,
      ),
    );
  }

  // 开通提示图片
  Widget _buildOpenTipImage() {
    return Image.asset(
      'assets/images/kissu_vip_top_tip.webp',
      height: 20,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  // 信息背景图片
  Widget _buildInfoBackground() {
    return Image.asset(
      'assets/images/kissu_vip_info_bg.webp',
      width: double.infinity,
      fit: BoxFit.fitWidth,
    );
  }

  // 提示文字
  Widget _buildHintText() {
    final currentChannel = BusinessHeaderInterceptor.getCurrentChannel();
    final shouldShowLocationHint = _shouldShowLocationHint(currentChannel);

    if (!shouldShowLocationHint) {
      return const SizedBox.shrink();
    }

    return const Align(
      alignment: Alignment.centerLeft,
      child: Text(
        '定位功能为会员功能，需双方下载安装并授权后使用',
        style: TextStyle(fontSize: 12, color: Color(0xFFABABAB)),
      ),
    );
  }

  /// 判断是否需要显示定位功能提示
  /// 根据渠道判断，某些渠道（如华为、小米等）可能不显示定位相关功能
  bool _shouldShowLocationHint(String? channel) {
    if (channel == null) return true; // 默认显示

    // 根据渠道判断是否显示定位提示
    // 这里可以根据具体需求调整哪些渠道不显示定位功能
    switch (channel.toLowerCase()) {
      case 'kissu_huawei': // 华为渠道
      case '3': // 华为渠道代码
      case 'kissu_xiaomi': // 小米渠道
      case '2': // 小米渠道代码
      case 'kissu_vivo': // VIVO渠道
      case '4': // VIVO渠道代码
      case 'kissu_oppo': // OPPO渠道
      case '5': // OPPO渠道代码
        return false; // 这些渠道不显示定位功能提示
      default:
        return true; // 其他渠道显示定位功能提示
    }
  }

  // 评价轮播图指示条
  // ignore: unused_element
  Widget _buildCommentCarouselIndicators() {
    return Obx(() {
      final commentList = controller.bannerData.value?.commentList ?? [];
      if (commentList.isEmpty) {
        return const SizedBox();
      }

      final itemCount = commentList.length;
      if (itemCount <= 1) {
        return const SizedBox(); // 只有一个项目时不显示指示条
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          itemCount,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: controller.commentCurrentIndex.value == index
                  ? const Color(0xFFFF408D)
                  : const Color(0xFFE0E0E0),
            ),
          ),
        ),
      );
    });
  }

  /// 设置页面可见性监听
  void _setupPageVisibilityListener() {
    WidgetsBinding.instance.addObserver(_PageVisibilityObserver(controller));
  }
}

/// 页面可见性观察者
class _PageVisibilityObserver extends WidgetsBindingObserver {
  final VipController controller;

  _PageVisibilityObserver(this.controller);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        controller.pauseAutoCarousel(); // 暂停自动轮播
        break;
      case AppLifecycleState.resumed:
        controller.resumeAutoCarousel(); // 恢复自动轮播
        break;
      case AppLifecycleState.detached:
        controller.pauseAutoCarousel(); // 暂停自动轮播
        break;
      case AppLifecycleState.hidden:
        controller.pauseAutoCarousel(); // 暂停自动轮播
        break;
    }
  }
}
