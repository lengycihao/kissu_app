import 'package:flutter/material.dart';

/// 智能图片组件
/// 
/// 特性：
/// - 自动识别网络图片和本地资源
/// - 加载过程中显示默认图片而不是占位图
/// - 优化的缓存策略
/// - 加载失败时显示默认图片
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
    // 🚀 优化1：如果imageUrl为空或是本地资源，直接显示默认图片
    if (imageUrl.isEmpty || !_isNetworkUrl(imageUrl)) {
      Widget localImage = Image.asset(
        imageUrl.isEmpty ? defaultAssetPath : imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          // 如果加载本地图片也失败，使用默认图片
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
          child: localImage,
        );
      }
      return localImage;
    }
    
    // 🚀 优化2：计算缓存尺寸，避免Infinity导致的错误
    int? cacheWidth;
    int? cacheHeight;
    
    if (width != double.infinity && width.isFinite) {
      cacheWidth = (width * MediaQuery.of(context).devicePixelRatio).round();
    }
    
    if (height != double.infinity && height.isFinite) {
      cacheHeight = (height * MediaQuery.of(context).devicePixelRatio).round();
    }
    
    // 🚀 优化3：网络图片加载，带缓存和错误处理
    Widget imageWidget = Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      // 优化缓存策略，减少内存占用
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('⚠️ 图片加载失败: $imageUrl, 错误: $error');
        return Image.asset(
          defaultAssetPath,
          width: width,
          height: height,
          fit: fit,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        // 🚀 优化4：加载过程中显示默认图片（立即显示，不留空白）
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

  /// 判断是否是网络URL
  bool _isNetworkUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }
}
