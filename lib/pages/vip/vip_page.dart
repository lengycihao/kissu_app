import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/models/vip_package_model.dart';
import 'package:kissu_app/models/vip_banner_model.dart';
import 'package:kissu_app/pages/vip/vip_controller.dart';
import 'package:kissu_app/utils/agreement_utils.dart';
import 'package:kissu_app/utils/user_manager.dart';
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
    const double paymentBaseHeight =
        44.0 + 10.0 + 50.0 + 15.0 + 20.0; // 额外增加20px缓冲
    const double paymentExtraBuffer = 20.0;
    final paymentComponentHeight =
        paymentBaseHeight + bottomPadding + paymentExtraBuffer;

    return WillPopScope(
      onWillPop: () async {
        // 拦截物理返回键，显示挽留弹窗
        await controller.onBackTap();
        return false; // 阻止默认返回行为
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFffffff),
        body: Stack(
          children: [
            // 主要内容区域 - 添加底部padding为支付组件留出空间
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                controller.handleScroll(notification);
                return false;
              },
              child: SingleChildScrollView(
                controller: controller.mainScrollController,
                physics: const AlwaysScrollableScrollPhysics(),
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
                            colors: [Color(0xFFFDE0F9), Color(0xFFFFFFFF)],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              const SizedBox(height: 5),
                              Obx(() {
                                final bannerData = controller.bannerData.value;
                                final banners = bannerData?.vipIconBanner ?? [];

                                String displayDesc = '';
                                if (banners.isNotEmpty) {
                                  final currentIndex =
                                      controller.currentIndex.value %
                                      banners.length;
                                  displayDesc =
                                      banners[currentIndex].vipIconBannerDesc;
                                }

                                if (displayDesc.isEmpty) {
                                  displayDesc =
                                      (bannerData?.desc ?? '想TA就立刻知道TA在哪儿')
                                          .trim();
                                }

                                if (displayDesc.isEmpty) {
                                  displayDesc = '想TA就立刻知道TA在哪儿';
                                }

                                return Text(
                                  displayDesc,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                );
                              }),
                              const SizedBox(height: 5),
                              // 顶部轮播图指示条 - 位置在图片按钮组件顶部外15px处
                              _buildTopCarouselIndicators(),
                              // 图片按钮组件 - 与轮播图底部重合，高度102px
                              _buildIconButtons(),
                              // 开通提示图片
                              // Image.asset(
                              //   "assets/kissu_vip_top_tip.webp",
                              //   height: 20,
                              //   fit: BoxFit.fitHeight,
                              // ),

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

                              const SizedBox(height: 30),
                              _buildPriceComponents(),
                              // // 评价轮播图指示条
                              // _buildCommentCarouselIndicators(),
                              const SizedBox(height: 15),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 固定的返回按钮 - 距离顶部55px，距离左边20px
            Positioned(
              left: 20,
              top: 55,
              child: GestureDetector(
                onTap: controller.onBackTap,
                child: Padding(
                  padding: EdgeInsets.all(8.0).copyWith(top: 0),

                  child: Image(
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
      ),
    );
  }

  // 顶部轮播图
  Widget _buildTopCarousel() {
    // 本地静态图片文件列表（作为兜底数据）
    final localImageAssets = [
      'assets/kissu4_vip_banner_location.webp',
      'assets/kissu4_vip_banner_track.webp',
      'assets/kissu4_vip_banner_history.webp',
      'assets/kissu4_vip_banner_mingan.webp',
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
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          imageAssetPath,
          width: double.infinity,
          height: 248,
          fit: BoxFit.fitHeight,
        ),
      ),
    );
  }

  Widget _buildRemoteBannerItem(VipIconBanner banner) {
    final displayUrl = banner.displayContent;
    if (displayUrl.isEmpty) {
      return _buildImageItem('assets/kissu4_vip_banner_location.webp');
    }

    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          displayUrl,
          width: double.infinity,
          height: 248,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/kissu4_vip_banner_location.webp',
              width: double.infinity,
              height: 248,
              fit: BoxFit.fitHeight,
            );
          },
        ),
      ),
    );
  }

  // 图片按钮组件
  Widget _buildIconButtons() {
    final fallbackIcons = [
      {
        'selected': 'assets/kissu_vip_banner_1sel.webp',
        'unselected': 'assets/kissu_vip_banner_1unsel.webp',
      },
      {
        'selected': 'assets/kissu_vip_banner_2sel.webp',
        'unselected': 'assets/kissu_vip_banner_2unsel.webp',
      },
      {
        'selected': 'assets/kissu_vip_banner_3sel.webp',
        'unselected': 'assets/kissu_vip_banner_3unsel.webp',
      },
      {
        'selected': 'assets/kissu_vip_banner_4sel.webp',
        'unselected': 'assets/kissu_vip_banner_4unsel.webp',
      },
    ];

    return Obx(() {
      final banners = controller.bannerData.value?.vipIconBanner ?? [];
      final hasRemoteData = banners.isNotEmpty;
      final itemCount = hasRemoteData ? banners.length : fallbackIcons.length;

      return Container(
        height: 77,
        margin: const EdgeInsets.only(top: 10, bottom: 36),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(itemCount, (index) {
            final isSelected = controller.currentIndex.value == index;
            final double size = 77;
            final iconUrl = hasRemoteData
                ? _resolveIconUrl(banners[index], isSelected)
                : '';
            final fallbackPair = fallbackIcons[index % fallbackIcons.length];

            return GestureDetector(
              onTap: () => controller.selectTab(index),
              child: SizedBox(
                width: size,
                height: size,
                child: hasRemoteData && iconUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          iconUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            final fallback = isSelected
                                ? fallbackPair['selected']!
                                : fallbackPair['unselected']!;
                            return Image.asset(fallback, fit: BoxFit.cover);
                          },
                        ),
                      )
                    : Image.asset(
                        isSelected
                            ? fallbackPair['selected']!
                            : fallbackPair['unselected']!,
                        fit: BoxFit.cover,
                      ),
              ),
            );
          }),
        ),
      );
    });
  }

  String _resolveIconUrl(VipIconBanner banner, bool isSelected) {
    if (isSelected && banner.vipIconSelect.isNotEmpty) {
      return banner.vipIconSelect;
    }
    if (banner.vipIcon.isNotEmpty) {
      return banner.vipIcon;
    }
    if (banner.vipIconSelect.isNotEmpty) {
      return banner.vipIconSelect;
    }
    return '';
  }

  // 开通提示图片
  Widget _buildOpenTipImage() {
    return Image.asset(
      "assets/kissu_vip_top_tip.webp",
      height: 20,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  // 价格组件 - 支持横向滑动，解决对齐问题
  Widget _buildPriceComponents() {
    return Obx(() {
      if (controller.isLoadingPackages.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.vipPackages.isEmpty) {
        return const Center(child: Text('暂无套餐数据'));
      }

      final planList = controller.vipPackages
          .asMap()
          .entries
          .map((entry) => _VipPlanData(entry.value, entry.key))
          .toList();

      final _VipPlanData? lifetimePlan = _extractPlan(
        planList,
        (plan) => plan.package.isForever,
      );

      final List<_VipPlanData> remainingPlans =
          planList.where((plan) => !plan.package.isForever).toList()
            ..sort((a, b) => a.package.vipDays.compareTo(b.package.vipDays));

      final List<_VipPlanData> selectablePlans = List<_VipPlanData>.from(
        remainingPlans,
      );

      _VipPlanData? monthlyPlan = _extractPlan(
        selectablePlans,
        (plan) => plan.package.title.contains('月'),
      );
      _VipPlanData? annualPlan = _extractPlan(
        selectablePlans,
        (plan) => plan.package.title.contains('年'),
      );

      if (monthlyPlan == null && selectablePlans.isNotEmpty) {
        monthlyPlan = selectablePlans.removeAt(0);
      }
      if (annualPlan == null && selectablePlans.isNotEmpty) {
        annualPlan = selectablePlans.removeAt(0);
      }

      final currentSelectedIndex = controller.selectedPriceIndex.value;

      final List<Widget> children = [];

      if (lifetimePlan != null) {
        children.add(
          _buildLifetimePlanCard(lifetimePlan, currentSelectedIndex),
        );
        children.add(const SizedBox(height: 10));
      }

      final List<Widget> rowChildren = [];
      if (monthlyPlan != null) {
        rowChildren.add(
          Expanded(
            child: _buildPeriodPlanCard(
              monthlyPlan,
              currentSelectedIndex,
              isMonthly: true,
            ),
          ),
        );
      }
      if (monthlyPlan != null && annualPlan != null) {
        rowChildren.add(const SizedBox(width: 10));
      }
      if (annualPlan != null) {
        rowChildren.add(
          Expanded(
            child: _buildPeriodPlanCard(
              annualPlan,
              currentSelectedIndex,
              isMonthly: false,
            ),
          ),
        );
      }

      if (rowChildren.isNotEmpty) {
        children.add(Row(children: rowChildren));
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    });
  }

  _VipPlanData? _extractPlan(
    List<_VipPlanData> list,
    bool Function(_VipPlanData) test,
  ) {
    for (var i = 0; i < list.length; i++) {
      if (test(list[i])) {
        return list.removeAt(i);
      }
    }
    return null;
  }

  Widget _buildLifetimePlanCard(_VipPlanData plan, int currentSelectedIndex) {
    final priceParts = _splitPriceParts(plan.package.vipPrice);
    final hasOriginalPrice = _hasOriginalPrice(plan.package.vipOriginalPrice);
    final originalPrice = _formatPriceWithSymbol(plan.package.vipOriginalPrice);
    final isSelected = currentSelectedIndex == plan.index;

    final backgroundAsset = isSelected
        ? "assets/4.0/kissu4_vip_open_bg.webp"
        : "assets/4.0/kissu4_vip_open_bg_sel.webp";

    return GestureDetector(
      onTap: () {
        if (plan.index >= 0) {
          controller.selectPrice(plan.index);
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 105,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(backgroundAsset),
                fit: BoxFit.contain,
              ),
              // border: Border.all(
              //   color: isSelected
              //       ? const Color(0xffFF6885)
              //       : Colors.transparent,
              //   width: 2,
              // ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: priceParts[0],
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xffFF6885),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: priceParts[1],
                            style: const TextStyle(
                              fontSize: 24,
                              color: Color(0xffFF6885),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasOriginalPrice)
                      Text(
                        originalPrice,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0x66000000),
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Color(0x66000000),
                        ),
                      ),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      plan.package.title,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xff000000),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Text(
                      '永久在一起，久久不分离',
                      style: TextStyle(fontSize: 11, color: Color(0x66000000)),
                    ),
                  ],
                ),
                Container(
                  width: 80,
                  height: 26,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/4.0/kissu4_vip_open_bt.webp"),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -15,
            left: 0,
            child: Image.asset(
              "assets/4.0/kissu4_vip_open_bg_tip.webp",
              width: 110,
              height: 34,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: 6,
            right: 5,
            child: Obx(() {
              final desc = controller.lifetimeActivityDesc.value;
              final countdown = controller.lifetimeCountdownText;
              if (desc.isEmpty && countdown.isEmpty) {
                return const SizedBox.shrink();
              }

              final parts = <String>[];
              if (desc.isNotEmpty) {
                parts.add(desc);
              }
              if (countdown.isNotEmpty) {
                parts.add(countdown);
              }
              final displayText = parts.join(' ');

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xffF6F275),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  displayText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xff000000),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodPlanCard(
    _VipPlanData plan,
    int currentSelectedIndex, {
    required bool isMonthly,
  }) {
    final priceParts = _splitPriceParts(plan.package.vipPrice);
    final isSelected = currentSelectedIndex == plan.index;
    final perDayPriceText = plan.package.perDayPriceText;
    final backgroundAsset = isSelected
        ? "assets/4.0/kissu4_vip_open_second_bg_sel.webp"
        : "assets/4.0/kissu4_vip_open_second_bg.webp";

    return GestureDetector(
      onTap: () {
        if (plan.index >= 0) {
          controller.selectPrice(plan.index);
        }
      },
      child: Container(
        height: 113,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(backgroundAsset),
            fit: BoxFit.fill,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (isMonthly)
              Transform.translate(
                offset: const Offset(0, -5),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Image.asset(
                    "assets/4.0/kissu4_vip_open_second_tip.webp",
                    width: 78,
                    height: 19,
                  ),
                ),
              ),
            SizedBox(height: isMonthly ? 5 : 24),
            Text(
              plan.package.title,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xff000000),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: priceParts[0],
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xffFF6885),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: priceParts[1],
                    style: const TextStyle(
                      fontSize: 24,
                      color: Color(0xffFF6885),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Container(width: 80, height: 0.5, color: const Color(0xff22000000)),
            const SizedBox(height: 5),
            if (perDayPriceText.isNotEmpty)
              Text(
                perDayPriceText,
                style: const TextStyle(fontSize: 11, color: Color(0x66000000)),
              ),
          ],
        ),
      ),
    );
  }

  List<String> _splitPriceParts(String? price) {
    final clean = _stripCurrencySymbol(price);
    final display = clean.isEmpty ? '0.00' : clean;
    return ['￥', display];
  }

  bool _hasOriginalPrice(String? price) {
    final clean = _stripCurrencySymbol(price);
    if (clean.isEmpty) return false;
    final value = double.tryParse(clean);
    if (value == null) {
      return true;
    }
    return value > 0;
  }

  String _formatPriceWithSymbol(String? price) {
    final clean = _stripCurrencySymbol(price);
    if (clean.isEmpty) return '';
    return '￥$clean';
  }

  String _stripCurrencySymbol(String? price) {
    final raw = price?.trim() ?? '';
    if (raw.isEmpty) return '';
    return raw.replaceFirst(RegExp(r'^[¥￥]'), '');
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
      case 'huawei': // 华为渠道
      case '3': // 华为渠道代码
      case 'xiaomi': // 小米渠道
      case '2': // 小米渠道代码
      case 'vivo': // VIVO渠道
      case '4': // VIVO渠道代码
      case 'oppo': // OPPO渠道
      case '5': // OPPO渠道代码
        return false; // 这些渠道不显示定位功能提示
      default:
        return true; // 其他渠道显示定位功能提示
    }
  }

  // 用户评价标题
  Widget _buildUserCommonTitle() {
    return Align(
      alignment: AlignmentGeometry.centerLeft,
      child: Text(
        "会员用户五星评价",
        style: TextStyle(
          color: Color(0xff000000),
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'AlimamaShuHeiTi',
        ),
      ),
    );
  }

  // 用户评价轮播图
  Widget _buildCommentCarousel() {
    return Obx(() {
      final List<CommentItem> commentList =
          controller.bannerData.value?.commentList ?? [];
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
  Widget _buildCommentItem(CommentItem comment) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFDCDBD7), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 头像
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: comment.hasAvatar
                    ? Image.network(
                        comment.avatar,
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return SizedBox.shrink();
                        },
                      )
                    : SizedBox.shrink(),
              ),
              const SizedBox(width: 8),
              Text(
                comment.nickname,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              //vip标识
              if (comment.hasVipIcon)
                Image.network(
                  comment.vipIcon,
                  width: 60,
                  height: 18,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(width: 24, height: 24);
                  },
                ),
            ],
          ),
          const SizedBox(height: 4),

          Expanded(
            child: Text(
              comment.content,
              style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          //星星
          if (comment.hasStarImage)
            Image.network(
              comment.starImage,
              width: 100,
              height: 20,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(width: 100, height: 20);
              },
            ),
          const SizedBox(height: 8),
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
                  'assets/4.0/kissu4_wechat.webp',
                  '微信支付',
                  controller.selectedPaymentMethod.value == 0,
                  () => controller.selectPaymentMethod(0),
                ),
                _buildPaymentOption(
                  'assets/4.0/kissu4_zhifubao.webp',
                  '支付宝支付',
                  controller.selectedPaymentMethod.value == 1,
                  () => controller.selectPaymentMethod(1),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 立即开通/继续续费按钮
          Obx(() {
            final periodLabel = controller.getCurrentPeriodLabel();
            final periodText = periodLabel.isNotEmpty ? '/$periodLabel' : '';
            return GestureDetector(
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
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/4.0/kissu4_vip_open_bt_bg.webp"),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(9)),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '￥',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          TextSpan(
                            text: controller.getCurrentPrice(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'AlimamaShuHeiTi',
                              color: Colors.black,
                            ),
                          ),
                          //支付价格提示
                          TextSpan(
                            text: periodText,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      UserManager.isVip ? "立即续费" : "立即开通",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'AlimamaShuHeiTi',
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

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
                    width: 13,
                    height: 13,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => AgreementUtils.toVipAgreement(),
                  child: RichText(
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
                            color: Color(0xFF63A9EA), // 高亮蓝色
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              // 上报服务协议点击埋点
                              await controller.onServiceAgreementTap();
                              AgreementUtils.toVipAgreement();
                            },
                        ),
                      ],
                    ),
                  ),
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
            Image(
              image: AssetImage(iconPath),
              width: 18,
              height: 18,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            // 支付方式图标
            Container(
              width: 13,
              height: 13,
              child: Image.asset(
                isSelected
                    ? 'assets/kissu_vip_agree.webp'
                    : 'assets/kissu_select_circle.webp',
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
            ),
          ],
        ),
      ),
    );
  }

  // 顶部轮播图指示条
  Widget _buildTopCarouselIndicators() {
    return Obx(() {
      final remoteCount =
          controller.bannerData.value?.vipIconBanner.length ?? 0;
      final itemCount = remoteCount > 0 ? remoteCount : 4;

      if (itemCount <= 1) {
        return const SizedBox();
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
                  ? Color(0xffFF89D9)
                  : Color(0xFFFECFE9),
            ),
          ),
        ),
      );
    });
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

class _VipPlanData {
  final VipPackageModel package;
  final int index;

  _VipPlanData(this.package, this.index);
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
