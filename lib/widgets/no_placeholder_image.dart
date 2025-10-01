import 'package:flutter/material.dart';

/// 无占位图的网络图片组件
/// 在加载过程中显示默认图片而不是占位图
class NoPlaceholderImage extends StatelessWidget {
  final String imageUrl;
  final String defaultAssetPath;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const NoPlaceholderImage({
    super.key,
    required this.imageUrl,
    required this.defaultAssetPath,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    // 计算缓存尺寸，避免Infinity导致的错误
    int? cacheWidth;
    int? cacheHeight;
    
    if (width != double.infinity && width.isFinite) {
      cacheWidth = (width * MediaQuery.of(context).devicePixelRatio).round();
    }
    
    if (height != double.infinity && height.isFinite) {
      cacheHeight = (height * MediaQuery.of(context).devicePixelRatio).round();
    }
    
    Widget imageWidget = Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      // 优化缓存策略，减少内存占用
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          defaultAssetPath,
          width: width,
          height: height,
          fit: fit,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        // 加载过程中显示默认图片
        return Image.asset(
          defaultAssetPath,
          width: width,
          height: height,
          fit: fit,
        );
      },
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
