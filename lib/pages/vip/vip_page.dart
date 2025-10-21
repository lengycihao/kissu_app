import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/vip/vip_controller.dart';
import 'package:kissu_app/utils/agreement_utils.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:lottie/lottie.dart'; // Lottie 动画库
import 'package:kissu_app/network/interceptor/business_header_interceptor.dart';

class VipPage extends GetView<VipController> {
  const VipPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 监听页面可见性变化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupPageVisibilityListener();
    });
    
    // 计算底部支付组件的实际高度
    // 包括：支付方式选项(~44) + 间距(10) + 按钮(50) + 间距(15) + 协议文字(~20) + 顶部padding(10) + 底部padding(25) + 底部安全区域
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final paymentComponentHeight = 44 + 10 + 50 + 15 + 20 + 10 + 25 + bottomPadding + 20; // 额外增加20px缓冲
    
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF4),
      body: Stack(
        children: [
          // 主要内容区域 - 添加底部padding为支付组件留出空间
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(bottom: paymentComponentHeight), // 动态计算底部padding
              child: Column(
                children: [
                  // 顶部轮播图 - 紧贴屏幕顶部，全宽度
                  _buildTopCarousel(),

                  // 顶部轮播图指示条 - 位置在图片按钮组件顶部外15px处
                  Transform.translate(
                    offset: const Offset(0, -35), // 向上移动35px，在图片按钮组件顶部外15px处
                    child: _buildTopCarouselIndicators(),
                  ),

                  // 图片按钮组件 - 与轮播图底部重合，高度102px
                  Transform.translate(
                    offset: const Offset(0, -30), // 向上移动20px实现重合
                    child: _buildIconButtons(),
                  ),

                  // 其他内容使用padding
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // 开通提示图片
                        Image.asset(
                          "assets/kissu_vip_top_tip.webp",
                          height: 20,
                          fit: BoxFit.fitHeight,
                        ),

                        // const SizedBox(height: 15),

                        // 价格组件
                        _buildPriceComponents(),

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

                        // 用户评价标题
                        _buildUserCommonTitle(),

                        const SizedBox(height: 15),

                        // 用户评价轮播图
                        _buildCommentCarousel(),

                        const SizedBox(height: 15),

                        // 评价轮播图指示条
                        _buildCommentCarouselIndicators(),

                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 固定的返回按钮 - 距离顶部55px，距离左边20px
          Positioned(
            left: 20,
            top: 55,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Padding(
                padding: EdgeInsets.all(8.0).copyWith(top: 0),
               
                 
                child:  Image(
                image: AssetImage('assets/kissu_mine_back.webp'),
                width: 22,
                height: 22,
                fit: BoxFit.cover,
              ),
              ),
            ),
          ),

          // 固定在底部的支付组件
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildPaymentComponent(),
          ),
        ],
      ),
    );
  }


  // 顶部轮播图
  Widget _buildTopCarousel() {
    return Obx(() {
      // 如果没有网络数据，显示本地Lottie动画轮播
      final bannerList = controller.bannerData.value?.vipIconBanner ?? [];
      
      // 本地Lottie动画文件列表
      final localLottieAssets = [
        'assets/json/location.json',
        'assets/json/track.json',
        'assets/json/history.json',
        'assets/json/mingan.json',
      ];

      // 如果有网络数据则使用网络数据，否则使用本地Lottie动画
      final itemCount = bannerList.isNotEmpty ? bannerList.length : localLottieAssets.length;
      
      if (itemCount == 0) {
        return Container(
          height: 337,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }

      return SizedBox(
        height: 337,
        child: PageView.builder(
          controller: controller.pageController,
          onPageChanged: controller.onPageChanged,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            return _buildLottieAnimationItem(localLottieAssets[index]);

           
          },
        ),
      );
    });
  }

  // Lottie动画项 - 使用预加载的动画实现秒开
  Widget _buildLottieAnimationItem(String lottieAssetPath) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Lottie.asset(
          lottieAssetPath,
          width: double.infinity,
          height: 337,
          fit: BoxFit.cover,
          repeat: true,
          animate: true,
          frameRate: FrameRate.max,
          addRepaintBoundary: true,
          options: LottieOptions(
            enableMergePaths: true,
          ),
        ),
      ),
    );
  }

   

  // 图片按钮组件
  Widget _buildIconButtons() {
    return Obx(() {
      final bannerList = controller.bannerData.value?.vipIconBanner ?? [];
      
      // 本地Lottie动画列表（对应location.json, track.json, history.json, mingan.json）
      final localLottieAssets = [
        'assets/json/location.json',
        'assets/json/track.json',
        'assets/json/history.json',
        'assets/json/mingan.json',
      ];
      
      // 如果有网络数据则使用网络数据，否则使用本地Lottie动画
      final itemCount = bannerList.isNotEmpty ? bannerList.length : localLottieAssets.length;
      
      if (itemCount == 0) {
        return const SizedBox();
      }

      return Container(
        height: 102,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/kissu_banner_bg.webp"),
            fit: BoxFit.cover,
          ),
        ),
        padding: EdgeInsets.only(top: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            itemCount,
            (index) {
              // 根据索引确定图片资源
              String imagePath;
              final isSelected = controller.currentIndex.value == index;
              
              switch (index) {
                case 0:
                  imagePath = isSelected 
                      ? 'assets/kissu_vip_banner_1sel.webp' 
                      : 'assets/kissu_vip_banner_1unsel.webp';
                  break;
                case 1:
                  imagePath = isSelected 
                      ? 'assets/kissu_vip_banner_2sel.webp' 
                      : 'assets/kissu_vip_banner_2unsel.webp';
                  break;
                case 2:
                  imagePath = isSelected 
                      ? 'assets/kissu_vip_banner_3sel.webp' 
                      : 'assets/kissu_vip_banner_3unsel.webp';
                  break;
                case 3:
                  imagePath = isSelected 
                      ? 'assets/kissu_vip_banner_4sel.webp' 
                      : 'assets/kissu_vip_banner_4unsel.webp';
                  break;
                default:
                  imagePath = 'assets/kissu_vip_banner_1unsel.webp';
              }
              
              return GestureDetector(
                onTap: () => controller.selectTab(index),
                child: SizedBox(
                  width: 70,
                  height: 78,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
  }


  // 开通提示图片
  Widget _buildOpenTipImage() {
    return Image.asset(
      "assets/kissu_vip_open_tip.webp",
      height: 20,
      fit: BoxFit.contain,
    );
  }

  // 价格组件 - 支持横向滑动，解决对齐问题
  Widget _buildPriceComponents() {
    return Obx(
      () {
        if (controller.isLoadingPackages.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        if (controller.vipPackages.isEmpty) {
          return const Center(
            child: Text('暂无套餐数据'),
          );
        }
        
        // 在Obx内部先获取当前选中索引，确保响应式更新
        final currentSelectedIndex = controller.selectedPriceIndex.value;
        
        // 获取屏幕宽度
        final screenWidth = Get.width;
        final itemWidth = 100.0;
        final itemSpacing = 10.0;
        final sideMargin = 15.0; // 两侧留白
        
        // 计算可显示的套餐数量
        final availableWidth = screenWidth - (sideMargin * 2);
        final maxVisibleItems = ((availableWidth + itemSpacing) / (itemWidth + itemSpacing)).floor();
        final totalItems = controller.vipPackages.length;
        
        // 🔥 统一容器高度：100px卡片 + 35px标签空间，确保所有套餐对齐
        const unifiedHeight = 115.0;
        
        // 如果套餐数量超过可显示数量，使用横向滑动
        if (totalItems > maxVisibleItems) {
          return Container(
            height: unifiedHeight,
            child: Stack(
              children: [
                ListView.separated(
                  controller: controller.priceScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: sideMargin),
                  clipBehavior: Clip.none, // 允许子组件超出ListView边界
                  itemCount: totalItems,
                  separatorBuilder: (context, index) => SizedBox(width: itemSpacing),
                  itemBuilder: (context, index) {
                    final package = controller.vipPackages[index];
                    final isLast = index == totalItems - 1;
                    
                    return _buildPriceItem(
                      title: package.durationText,
                      price1: package.priceText,
                      price2: package.originalPriceText,
                      size: const Size(100, 100),
                      background: "assets/kissu_vip_year_bg.webp",
                      isSelected: currentSelectedIndex == index,
                      onTap: () => controller.selectPrice(index),
                      showBottomLabel: isLast, // 最后一个显示底部标签
                      bottomLabel: '80%选择',
                    );
                  },
                ),
                // 左侧渐变指示器
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          const Color(0xFFFFFDF4).withValues(alpha: 0.8),
                          const Color(0xFFFFFDF4).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // 右侧渐变指示器
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          const Color(0xFFFFFDF4).withValues(alpha: 0.8),
                          const Color(0xFFFFFDF4).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // 套餐数量较少时，使用居中的Row布局
          return Container(
            height: unifiedHeight, // 使用统一高度
            alignment: Alignment.topCenter, // 顶部对齐
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start, // 🔥 关键：顶部对齐
              children: controller.vipPackages.asMap().entries.map((entry) {
                final index = entry.key;
                final package = entry.value;
                final isLast = index == controller.vipPackages.length - 1;
                
                return Row(
                  children: [
                    _buildPriceItem(
                      title: package.durationText,
                      price1: package.priceText,
                      price2: package.originalPriceText,
                      size: const Size(100, 100),
                      background: "assets/kissu_vip_year_bg.webp",
                      isSelected: currentSelectedIndex == index,
                      onTap: () => controller.selectPrice(index),
                      showBottomLabel: isLast, // 最后一个显示底部标签
                      bottomLabel: '80%选择',
                    ),
                    if (index < controller.vipPackages.length - 1)
                      SizedBox(width: itemSpacing),
                  ],
                );
              }).toList(),
            ),
          );
        }
      },
    );
  }

  // 单个价格组件 - 重新设计确保完美对齐
  Widget _buildPriceItem({
    required String title,
    required String price1,
    required String price2,
    required String background,
    Size size = const Size(100, 100),
    required bool isSelected,
    required VoidCallback onTap,
    bool showBottomLabel = false,
    String bottomLabel = '',
  }) {
    return SizedBox(
      width: size.width,
      height: 115, // 🔥 固定统一高度：100px卡片 + 35px标签空间
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 主价格卡片 - 固定在顶部
          Positioned(
            top: 0,
            left: 0,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: size.width,
                height: size.height, // 卡片本身保持100px高度
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: isSelected ? const Color(0xFFFF950A) : const Color(0xFFFFF3B8),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: size.width - 10,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFF0A6C) : const Color(0xffFF77AD),
                        borderRadius: const BorderRadius.all(Radius.circular(10)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      price1,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Color(0xFF5E3603),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      price2,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 底部标签 - 固定位置，不影响卡片对齐
          if (showBottomLabel)
            Positioned(
              bottom: 5, // 固定在底部
              right: -5, // 稍微向右偏移
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: const BoxDecoration(
                  color: Color(0xff046AE4),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Text(
                  bottomLabel,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 信息背景图片
  Widget _buildInfoBackground() {
    return Image.asset(
      "assets/kissu_vip_info_bg.webp",
      width: double.infinity,
      fit: BoxFit.fitWidth,
    );
  }

  // 提示文字
  Widget _buildHintText() {
    // 检查当前渠道是否需要显示定位功能提示
    final currentChannel = BusinessHeaderInterceptor.getCurrentChannel();
    final shouldShowLocationHint = _shouldShowLocationHint(currentChannel);
    
    if (!shouldShowLocationHint) {
      // 如果不需要显示定位提示，返回空的容器
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
      case 'huawei':    // 华为渠道
      case '3':         // 华为渠道代码
      case 'xiaomi':    // 小米渠道  
      case '2':         // 小米渠道代码
      case 'vivo':      // VIVO渠道
      case '4':         // VIVO渠道代码
      case 'oppo':      // OPPO渠道
      case '5':         // OPPO渠道代码
        return false;   // 这些渠道不显示定位功能提示
      default:
        return true;    // 其他渠道显示定位功能提示
    }
  }

  // 用户评价标题
  Widget _buildUserCommonTitle() {
    return Image.asset(
      "assets/kissu_vip_user_common.webp",
      height: 22,
      fit: BoxFit.contain,
    );
  }

  // 用户评价轮播图
  Widget _buildCommentCarousel() {
    return Obx(() {
      final commentList = controller.bannerData.value?.commentList ?? [];
      if (commentList.isEmpty) {
        return const SizedBox();
      }

      return SizedBox(
        height: 115,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            controller.onCommentScroll();
            return false;
          },
          child: ListView.builder(
            controller: controller.commentScrollController,
            scrollDirection: Axis.horizontal,
            itemCount: commentList.length,
            itemBuilder: (context, index) {
              final comment = commentList[index];
              return Container(
                width: 266, // 固定item宽度266px
                margin: EdgeInsets.only(
                  left: index == 0 ? 0 : 13, // 第一个item左边距0px，其他item左边距13px
                ),
                child: _buildCommentItem(comment),
              );
            },
          ),
        ),
      );
    });
  }

  // 单个评价项
  Widget _buildCommentItem(dynamic comment) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comment.nickname,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              ...List.generate(
                5,
                (index) =>
                    const Icon(Icons.star, size: 11, color: Color(0xFFFF408D)),
              ),
              const SizedBox(width: 8),
              Text(
                comment.date,
                style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              comment.content,
              style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // 支付组件
  Widget _buildPaymentComponent() {
    // 获取底部安全区域高度
    final bottomPadding = MediaQuery.of(Get.context!).padding.bottom;
    // 计算实际底部内边距：基础25px + 底部安全区域高度
    final actualBottomPadding = 25.0 + bottomPadding;
    
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: actualBottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 支付方式选择
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPaymentOption(
                  'assets/kissu_vip_alipay.webp',
                  '支付宝支付',
                  controller.selectedPaymentMethod.value == 0,
                  () => controller.selectPaymentMethod(0),
                ),
                _buildPaymentOption(
                  'assets/kissu_vip_wechat.webp',
                  '微信支付',
                  controller.selectedPaymentMethod.value == 1,
                  () => controller.selectPaymentMethod(1),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 立即开通/继续续费按钮
          Obx(
            () => GestureDetector(
              onTap: () {
                if (!controller.agreementChecked.value) {
                  // 如果未勾选协议，显示提示并返回
                  controller.showAgreementWarning();
                  return;
                }
                // 已勾选协议，执行购买
                controller.purchaseVip();
              },
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/kissu_pay_btn_bg.webp"),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(9)),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${UserManager.isVip ? "立即续费" : "立即开通"} ${controller.getCurrentPrice()}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),

          // 服务协议勾选
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: controller.toggleAgreement,
                  child: Image.asset(
                    controller.agreementChecked.value
                        ? "assets/kissu_vip_agree.webp"
                        : "assets/kissu_select_circle.webp",
                    width: 16,
                    height: 16,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => AgreementUtils.toVipAgreement(),
                  child:  RichText(
  text: TextSpan(
    children: [
      TextSpan(
        text: '阅读并同意',
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF666666),
        ),
      ),
      TextSpan(
        text: '《会员服务协议》',
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFFFF839E), // 高亮蓝色
         ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            AgreementUtils.toVipAgreement();
          },
      ),
    ],
  ),
)

                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 支付方式选项
  Widget _buildPaymentOption(
    String iconPath,
    String title,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
         
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 支付方式图标
            Container(
              width: 20,
              height: 20,
              child: Image.asset(
                isSelected ? 'assets/kissu_vip_agree.webp' : 'assets/kissu_select_circle.webp',
                width: 20,
                height: 20,
                fit: BoxFit.contain,
               ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 顶部轮播图指示条
  Widget _buildTopCarouselIndicators() {
    return Obx(() {
      final bannerList = controller.bannerData.value?.vipIconBanner ?? [];
      if (bannerList.isEmpty) {
        return const SizedBox();
      }

      final itemCount = bannerList.length;
      if (itemCount <= 1) {
        return const SizedBox(); // 只有一个项目时不显示指示条
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          itemCount,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: controller.currentIndex.value == index
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    });
  }

  // 评价轮播图指示条
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
