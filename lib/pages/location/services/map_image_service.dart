import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:kissu_app/services/map_preload_service.dart';

/// 地图图片加载和缓存服务
/// 
/// 负责处理地图相关的图片加载和缓存，包括：
/// - 网络图片加载
/// - 本地资源图片加载
/// - 图片缓存管理
class MapImageService {
  MapImageService._();
  
  static final MapImageService instance = MapImageService._();
  
  final Map<String, ui.Image> _imageCache = {};

  /// 从网络加载图片
  Future<ui.Image?> loadImageFromNetwork(String url) async {
    if (_imageCache.containsKey(url)) {
      return _imageCache[url];
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final image = frame.image;
        _imageCache[url] = image;
        return image;
      }
    } catch (e) {
      print('Load image from network error: $e');
    }
    return null;
  }

  /// 从本地资源加载图片
  Future<ui.Image?> loadImageFromAsset(String assetPath) async {
    // 优化1：先从本地缓存查找
    if (_imageCache.containsKey(assetPath)) {
      return _imageCache[assetPath];
    }

    // 优化2：尝试从全局预加载服务获取
    final preloadedImage = MapPreloadService.instance.getPreloadedImage(assetPath);
    if (preloadedImage != null) {
      _imageCache[assetPath] = preloadedImage;
      return preloadedImage;
    }

    // 优化3：如果都没有，才进行加载
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final image = frame.image;
      _imageCache[assetPath] = image;
      return image;
    } catch (e) {
      print('Load image from asset error: $assetPath, $e');
      return null;
    }
  }

  /// 清除图片缓存
  void clearCache() {
    _imageCache.clear();
  }

  /// 获取缓存大小
  int get cacheSize => _imageCache.length;
}

