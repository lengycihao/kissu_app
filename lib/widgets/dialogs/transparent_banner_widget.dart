import 'package:flutter/material.dart';
import 'package:card_swiper/card_swiper.dart';

/// 透明背景的Banner组件
class TransparentBannerWidget extends StatefulWidget {
  final List<String> imagePaths;
  final double height;
  final Duration autoPlayInterval;
  final bool autoPlay;

  const TransparentBannerWidget({
    Key? key,
    required this.imagePaths,
    this.height = 230,
    this.autoPlayInterval = const Duration(seconds: 3),
    this.autoPlay = true,
  }) : super(key: key);

  @override
  State<TransparentBannerWidget> createState() => _TransparentBannerWidgetState();
}

class _TransparentBannerWidgetState extends State<TransparentBannerWidget> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.imagePaths.isEmpty) {
      return const SizedBox.shrink();
    }

    if (widget.imagePaths.length == 1) {
      // 只有一张图片时，只显示完整图片
      return Column(
        children: [
          Container(
            height: 175,
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: Center(
              child: _buildImageCard(widget.imagePaths[0], isMain: true),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        // Banner区域 - 使用card_swiper插件实现复杂轮播
        Container(
          height: 175,
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Swiper(
            itemBuilder: (context, index) {
              return _buildCarouselItem(index);
            },
            itemCount: widget.imagePaths.length,
            autoplay: widget.autoPlay,
            autoplayDelay: widget.autoPlayInterval.inMilliseconds,
            onIndexChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            // 关键配置：实现一屏显示三张图片的效果
            viewportFraction: 0.6, // 当前图片占80%宽度，两侧各留10%
            scale: 0.8, // 侧边图片缩放80%
            loop: true, // 无限循环
          ),
        ),
        const SizedBox(height: 10),
        // 指示器 - 完全放在轮播图外面
        if (widget.imagePaths.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.imagePaths.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width:_currentIndex == index ? 14 : 8,
                height:_currentIndex == index ? 14 : 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _currentIndex ? const Color(0xFFFF5787) : const Color(0xffffb4c4),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // 构建单个图片组件
  Widget _buildImageCard(String imagePath, {bool isMain = false}) {
    return Container(
      width: isMain ? 220 : 105.6, // 主图220px，侧图105.6px
      height: isMain ? 195 : 156,   // 主图195px，侧图156px
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFFFE8F0), // 浅粉色背景
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
            width: double.infinity,
          ),
        ),
      ),
    );
  }

  // 构建轮播图项目
  Widget _buildCarouselItem(int index) {
    return Center(
      child: _buildImageCard(widget.imagePaths[index], isMain: true),
    );
  }

}
