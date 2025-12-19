import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/models/vip_banner_model.dart';
import 'package:kissu_app/pages/vip/vip_controller.dart';
import 'package:kissu_app/utils/network_image_helper.dart';

/// 顶部文案 + 指示条 + 图标按钮区域（不包含价格和支付，仅展示功能卖点）
class VipTopFeatureSection extends StatelessWidget {
  const VipTopFeatureSection({
    super.key,
    required this.controller,
  });

  final VipController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 5),
        _buildDescText(),
        const SizedBox(height: 5),
        _buildTopCarouselIndicators(),
        _buildIconButtons(),
      ],
    );
  }

  Widget _buildDescText() {
    return Obx(() {
      final bannerData = controller.bannerData.value;
      final banners = bannerData?.vipIconBanner ?? [];

      String displayDesc = '';
      if (banners.isNotEmpty) {
        final currentIndex = controller.currentIndex.value % banners.length;
        displayDesc = banners[currentIndex].vipIconBannerDesc;
      }

      if (displayDesc.isEmpty) {
        displayDesc =
            (bannerData?.desc ?? '想TA就立刻知道TA在哪儿').trim();
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
    });
  }

  /// 顶部轮播图指示条
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
                  ? const Color(0xffFF89D9)
                  : const Color(0xFFFECFE9),
            ),
          ),
        ),
      );
    });
  }

  /// 图片按钮组件 - 与轮播图底部重合，高度102px
  Widget _buildIconButtons() {
    final fallbackIcons = [
      {
        'selected': 'assets/images/kissu_vip_banner_1sel.webp',
        'unselected': 'assets/images/kissu_vip_banner_1unsel.webp',
      },
      {
        'selected': 'assets/images/kissu_vip_banner_2sel.webp',
        'unselected': 'assets/images/kissu_vip_banner_2unsel.webp',
      },
      {
        'selected': 'assets/images/kissu_vip_banner_3sel.webp',
        'unselected': 'assets/images/kissu_vip_banner_3unsel.webp',
      },
      {
        'selected': 'assets/images/kissu_vip_banner_4sel.webp',
        'unselected': 'assets/images/kissu_vip_banner_4unsel.webp',
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
                        child: NetworkImageHelper.loadImage(
                          imageUrl: iconUrl,
                          fit: BoxFit.cover,
                          errorWidget: Image.asset(
                            isSelected
                                ? fallbackPair['selected']!
                                : fallbackPair['unselected']!,
                            fit: BoxFit.cover,
                          ),
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


