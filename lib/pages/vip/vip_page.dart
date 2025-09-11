import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/vip/vip_controller.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

class VipPage extends GetView<VipController> {
  const VipPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 监听页面可见性变化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupPageVisibilityListener();
    });
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF4),
      body: Stack(
        children: [
          // 主要内容区域
          SingleChildScrollView(
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
                  offset: const Offset(0, -20), // 向上移动20px实现重合
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

                      const SizedBox(height: 15),

                      // 价格组件
                      _buildPriceComponents(),

                      const SizedBox(height: 15),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '会员到期自动续费，可以随时取消',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFABABAB),
                          ),
                        ),
                      ),
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

                // 支付组件 - 全宽度，无左右间隔
                _buildPaymentComponent(),
              ],
            ),
          ),

          // 固定的返回按钮 - 距离顶部55px，距离左边20px
          Positioned(
            left: 20,
            top: 55,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // 顶部轮播图
  Widget _buildTopCarousel() {
    return Obx(() {
      final bannerList = controller.bannerData.value?.vipIconBanner ?? [];
      if (bannerList.isEmpty) {
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
          itemCount: bannerList.length,
          itemBuilder: (context, index) {
            final item = bannerList[index];

            if (item.hasVideo) {
              final chewieController = controller.getChewieController(index);
              // 如果 Chewie 控制器初始化失败，显示图片占位符
              if (chewieController == null) {
                return _buildVideoPlaceholder(item.vipIconVideo);
              }
              return _buildChewieVideoItem(chewieController, index);
            } else if (item.vipIconBanner.isNotEmpty) {
              return _buildImageItem(item.vipIconBanner);
            } else {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('暂无内容')),
              );
            }
          },
        ),
      );
    });
  }

  // Chewie 视频播放器组件
  Widget _buildChewieVideoItem(ChewieController chewieController, int index) {
    return SizedBox(
      width: double.infinity, // 确保全宽度
      height: 235, // 固定高度 235px
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ValueListenableBuilder(
          valueListenable: chewieController.videoPlayerController,
          builder: (context, VideoPlayerValue value, child) {
            // 检查是否有错误
            if (value.hasError) {
              return _buildVideoErrorFallback(index);
            }
            
            // 确保视频已初始化且有尺寸信息
            if (!value.isInitialized || value.size == Size.zero) {
              return Container(
                color: Colors.white,
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.grey,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              );
            }
            
            return FittedBox(
              fit: BoxFit.cover, // 确保视频内容填充整个容器而不失真
              child: SizedBox(
                width: value.size.width,
                height: value.size.height,
                child: Chewie(controller: chewieController),
              ),
            );
          },
        ),
      ),
    );
  }

  // 视频错误时的备用显示
  Widget _buildVideoErrorFallback(int index) {
    // 获取对应的banner数据，显示静态图片作为备用
    final banners = controller.bannerData.value?.vipIconBanner ?? [];
    if (index < banners.length) {
      final banner = banners[index];
      return Container(
        width: double.infinity,
        height: 235,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[100],
        ),
        child: Stack(
          children: [
            // 显示静态图片作为备用
            if (banner.vipIconBanner.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  banner.vipIconBanner,
                  width: double.infinity,
                  height: 235,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey[600],
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '图片加载失败',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            
            // 显示错误提示
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '视频加载失败',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // 如果没有banner数据，显示默认错误界面
    return Container(
      width: double.infinity,
      height: 235,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[100],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              color: Colors.grey[600],
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              '视频暂时无法播放',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 视频占位符（当视频加载失败时）
  Widget _buildVideoPlaceholder(String videoUrl) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black87,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.black87],
                ),
              ),
            ),
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_library_outlined,
                    size: 60,
                    color: Colors.white70,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '视频加载失败',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  // 图片项
  Widget _buildImageItem(String imageUrl) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Center(child: Text('图片加载失败')),
            );
          },
        ),
      ),
    );
  }

  // 图片按钮组件
  Widget _buildIconButtons() {
    return Obx(() {
      final bannerList = controller.bannerData.value?.vipIconBanner ?? [];
      if (bannerList.isEmpty) {
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
        padding: EdgeInsets.only(top: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            bannerList.length,
            (index) => GestureDetector(
              onTap: () => controller.selectTab(index),
              child: SizedBox(
                width: 70,
                // height: 78,
                child: Image.network(
                  controller.currentIndex.value == index
                      ? bannerList[index].vipIconSelect
                      : bannerList[index].vipIcon,
                  fit: BoxFit.fitWidth,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    );
                  },
                ),
              ),
            ),
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

  // 价格组件 - 支持横向滑动
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
        
        // 如果套餐数量超过可显示数量，使用横向滑动
        if (totalItems > maxVisibleItems) {
          return Container(
            height: 130, // 增加高度以容纳底部标签，从115改为130
            child: Stack(
              children: [
                ListView.separated(
                  controller: controller.priceScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: sideMargin),
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
            height: 130, // 为Row布局也增加相同的高度
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
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

  // 单个价格组件
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
      height: size.height + (showBottomLabel ? 10 : 0), // 为底部标签增加额外空间
      child: Stack(
        clipBehavior: Clip.none, // 允许子组件超出边界
        children: [
          // 主价格卡片
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: size.width,
              height: size.height,
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
                    decoration:  BoxDecoration(
                      color: isSelected ?Color(0xFFFF0A6C):Color(0xffFF77AD),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
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
          // 底部标签 - 确保在最上层显示
          if (showBottomLabel)
            Positioned(
              right: -8, // 调整右侧位置，让标签部分突出
              bottom: 20, // 位于价格卡片底部边缘下方
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                decoration: const BoxDecoration(
                  color: Color(0xff046AE4),
                  borderRadius: BorderRadius.all(Radius.circular(15)),
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
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'App内部分功能需双方付费场景下使用',
        style: TextStyle(fontSize: 12, color: Color(0xFFABABAB)),
      ),
    );
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
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
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

          const SizedBox(height: 20),

          // 立即开通按钮
          Obx(
            () => GestureDetector(
              onTap: controller.agreementChecked.value
                  ? controller.purchaseVip
                  : null,
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
                  '立即开通 ${controller.getCurrentPrice()}',
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
            () => GestureDetector(
              onTap: controller.toggleAgreement,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    controller.agreementChecked.value
                        ? "assets/kissu_vip_agree.webp"
                        : "assets/kissu_vip_unagree.webp",
                    width: 16,
                    height: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '会员服务协议',
                    style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
                  ),
                ],
              ),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
         
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 支付方式图标
            Container(
              width: 20,
              height: 20,
              child: Image.asset(
                isSelected ? 'assets/kissu_vip_agree.webp' : 'assets/kissu_vip_unagree.webp',
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
        controller.pauseAllVideos();
        controller.pauseAutoCarousel(); // 暂停自动轮播
        break;
      case AppLifecycleState.resumed:
        controller.playCurrentVideo();
        controller.resumeAutoCarousel(); // 恢复自动轮播
        break;
      case AppLifecycleState.detached:
        controller.pauseAllVideos();
        controller.pauseAutoCarousel(); // 暂停自动轮播
        break;
      case AppLifecycleState.hidden:
        controller.pauseAllVideos();
        controller.pauseAutoCarousel(); // 暂停自动轮播
        break;
    }
  }
}
