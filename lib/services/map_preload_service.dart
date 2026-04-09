import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'dart:ui' as ui;

import 'package:kissu_app/network/tools/logging/log_manager.dart';

/// 地图资源预加载服务
/// 用于在应用启动时预加载地图相关资源，提升地图页面打开速度
class MapPreloadService {
  static final MapPreloadService _instance = MapPreloadService._();
  static MapPreloadService get instance => _instance;

  MapPreloadService._();

  bool _isPreloaded = false;
  bool _isPreloading = false;

  /// Marker缓存（全局级别，跨页面复用）
  final Map<String, BitmapDescriptor> _markerCache = {};

  /// 图片缓存（ui.Image对象）
  final Map<String, ui.Image> _imageCache = {};

  /// 是否已预加载
  bool get isPreloaded => _isPreloaded;

  /// 在应用启动时调用此方法预加载地图资源
  Future<void> preloadMapResources() async {
    if (_isPreloaded || _isPreloading) {
      logger.debug('🗺️ 地图资源已预加载或正在预加载中，跳过');
      return;
    }

    _isPreloading = true;
    final startTime = DateTime.now();

    try {
      logger.debug('🚀 开始预加载地图资源...');

      // 并行预加载所有常用图片资源
      await Future.wait([
        _preloadAssetImage('assets/3.0/kissu3_location_she.webp'),
        _preloadAssetImage('assets/3.0/kissu3_emoij_bg.webp'),
        _preloadAssetImage('assets/3.0/kissu3_love_avater.webp'),
        _preloadAssetImage('assets/images/kissu_location_start.webp'),
        _preloadAssetImage('assets/images/kissu_location_circle.webp'),
        _preloadAssetImage('assets/images/kissu_love_yellow.webp'),
      ]);

      _isPreloaded = true;
      final duration = DateTime.now().difference(startTime);
      logger.debug('✅ 地图资源预加载完成，耗时: ${duration.inMilliseconds}ms');
    } catch (e) {
      logger.error('❌ 地图资源预加载失败: $e');
    } finally {
      _isPreloading = false;
    }
  }

  /// 预加载本地图片资源并解码为ui.Image
  Future<void> _preloadAssetImage(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      _imageCache[assetPath] = frame.image;
      logger.debug('  ✓ 预加载图片: $assetPath');
    } catch (e) {
      logger.error('  ✗ 预加载图片失败 $assetPath: $e');
    }
  }

  /// 获取预加载的图片
  ui.Image? getPreloadedImage(String assetPath) {
    return _imageCache[assetPath];
  }

  /// 缓存Marker（用于跨页面复用）
  void cacheMarker(String key, BitmapDescriptor marker) {
    _markerCache[key] = marker;
    logger.debug('💾 缓存Marker: $key (总缓存数: ${_markerCache.length})');
  }

  /// 获取缓存的Marker
  BitmapDescriptor? getCachedMarker(String key) {
    final marker = _markerCache[key];
    if (marker != null) {
      logger.debug('🎯 命中Marker缓存: $key');
    }
    return marker;
  }

  /// 生成Marker缓存key
  static String generateMarkerCacheKey({
    required String avatarUrl,
    String? faceUrl,
  }) {
    return 'marker_${avatarUrl.hashCode}_${faceUrl?.hashCode ?? 'null'}';
  }

  /// 清空缓存（用于内存管理）
  void clearCache() {
    _markerCache.clear();
    _imageCache.clear();
    _isPreloaded = false;
    logger.debug('🗑️ 已清空地图资源缓存');
  }

  /// 获取缓存统计信息
  Map<String, int> getCacheStats() {
    return {
      'markerCount': _markerCache.length,
      'imageCount': _imageCache.length,
    };
  }
}

