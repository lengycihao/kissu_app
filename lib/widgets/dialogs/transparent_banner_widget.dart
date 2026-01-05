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

     
    // Banner区域 - 使用card_swiper插件实现复杂轮播
    // 图片比例 282*234，间距40px已在custom_bottom_dialog.dart中通过Positioned处理
    return SizedBox(
      height: widget.height,
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
        viewportFraction: 0.75, // 当前图片占75%宽度
        scale: 0.85, // 侧边图片缩放85%
        loop: true, // 无限循环
        fade: 0.7,
      ),
    );
  }

  // 构建单个图片组件
  Widget _buildImageCard(String imagePath, {bool isMain = false}) {
    return Container(
      // width: isMain ? 380 : 105.6, // 主图234px，侧图105.6px
      // height: isMain ? 195 : 156,   // 主图195px，侧图156px
      // margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
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
          borderRadius: BorderRadius.circular(26),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
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
