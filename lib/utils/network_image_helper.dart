import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 网络图片加载辅助类
/// 统一使用 CachedNetworkImage 替代 Image.network，避免重复加载和日志噪音
class NetworkImageHelper {
  /// 加载网络图片（带缓存）
  /// 
  /// [imageUrl] 图片URL
  /// [width] 宽度
  /// [height] 高度
  /// [fit] 填充方式
  /// [placeholder] 占位图路径（本地资源）
  /// [errorWidget] 错误时显示的widget（如果不提供，使用placeholder）
  static Widget loadImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    String? placeholder,
    Widget? errorWidget,
  }) {
    // 如果URL为空，直接显示占位图
    if (imageUrl.isEmpty) {
      if (placeholder != null) {
        return Image.asset(
          placeholder,
          width: width,
          height: height,
          fit: fit,
        );
      }
      return SizedBox(width: width, height: height);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      // 优化：减少淡入动画时间，提升加载体验
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 100),
      // 加载中显示占位图
      placeholder: placeholder != null
          ? (context, url) => Image.asset(
                placeholder,
                width: width,
                height: height,
                fit: fit,
              )
          : null,
      // 加载失败显示错误widget或占位图
      errorWidget: (context, url, error) {
        if (errorWidget != null) {
          return errorWidget;
        }
        if (placeholder != null) {
          return Image.asset(
            placeholder,
            width: width,
            height: height,
            fit: fit,
          );
        }
        return Icon(
          Icons.broken_image,
          size: width != null && height != null ? (width < height ? width : height) : 24,
          color: Colors.grey,
        );
      },
      // 优化：内存缓存使用2倍分辨率（防止Infinity或NaN）
      memCacheWidth: width != null && width.isFinite ? (width * 2).toInt() : null,
      memCacheHeight: height != null && height.isFinite ? (height * 2).toInt() : null,
      // 优化：磁盘缓存限制大小，减少存储占用
      maxWidthDiskCache: width != null && width.isFinite ? (width * 3).toInt() : null,
      maxHeightDiskCache: height != null && height.isFinite ? (height * 3).toInt() : null,
    );
  }

  /// 加载圆形头像
  static Widget loadAvatar({
    required String imageUrl,
    required double size,
    String? placeholder,
    Widget? errorWidget,
  }) {
    return ClipOval(
      child: loadImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: placeholder,
        errorWidget: errorWidget,
      ),
    );
  }

  /// 加载圆角图片
  static Widget loadRoundedImage({
    required String imageUrl,
    double? width,
    double? height,
    required double borderRadius,
    BoxFit fit = BoxFit.cover,
    String? placeholder,
    Widget? errorWidget,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: loadImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: placeholder,
        errorWidget: errorWidget,
      ),
    );
  }
}
