import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/vip/vip_controller.dart';
import 'package:kissu_app/utils/agreement_utils.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/widgets/delayed_pag_widget.dart';
import 'package:kissu_app/network/interceptor/business_header_interceptor.dart';

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
          // 主要内容区域 - 添加底部padding为支付组件留出空间
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 150), // 为底部固定支付组件留出空间
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
      // 如果没有网络数据，显示本地PAG动画轮播
      final bannerList = controller.bannerData.value?.vipIconBanner ?? [];
      
      // 本地PAG动画文件列表
      final localPagAssets = [
        'assets/pag/kissu_vip_top1.pag',
        'assets/pag/kissu_vip_top2.pag',
        'assets/pag/kissu_vip_top3.pag',
        'assets/pag/kissu_vip_top4.pag',
      ];

      // 如果有网络数据则使用网络数据，否则使用本地PAG动画
      final itemCount = bannerList.isNotEmpty ? bannerList.length : localPagAssets.length;
      
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
            // 如果有网络数据，优先使用网络数据
            if (bannerList.isNotEmpty) {
              final item = bannerList[index];
              if (item.vipIconBanner.isNotEmpty) {
                return _buildImageItem(item.vipIconBanner);
              }
            }
            
            // 使用本地PAG动画
            if (index < localPagAssets.length) {
              return _buildPagAnimationItem(localPagAssets[index], index);
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text('暂无内容')),
            );
          },
        ),
      );
    });
  }

  // PAG动画项
  Widget _buildPagAnimationItem(String pagAssetPath, int index) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DelayedPagWidget(
          assetPath: pagAssetPath,
          width: double.infinity,
          height: 337,
          delay: Duration(milliseconds: 500 * index), // 每个动画延迟500ms
          autoPlay: true,
          repeat: true,
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
      
      // 只有当有网络数据时才显示图标按钮
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
        alignment: Alignment.bottomRight,
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
            Transform.translate(
              offset: const Offset(5, 10), // 向下移动20px
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
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      padding:   EdgeInsets.only(left: 20, right: 20, bottom: 25),
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
                  '${UserManager.isVip ? "继续续费" : "立即开通"} ${controller.getCurrentPrice()}',
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
         
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
