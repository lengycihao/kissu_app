import 'package:flutter/material.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';

/// 内存管理工具类
/// 用于统一管理应用的内存使用和资源清理
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  /// 清理所有缓存资源
  static void clearAllCaches() {
    try {
      // 清理图片缓存
      _clearImageCache();
      
      logDebug('🧹 内存管理器：所有缓存已清理');
    } catch (e) {
      logError('❌ 清理缓存时出错: $e');
    }
  }

  /// 清理图片缓存
  static void _clearImageCache() {
    try {
      // 获取图片缓存实例
      final imageCache = PaintingBinding.instance.imageCache;
      
      // 清理缓存
      imageCache.clear();
      imageCache.clearLiveImages();
      
      logDebug('🧹 图片缓存已清理');
    } catch (e) {
      logError('❌ 清理图片缓存时出错: $e');
    }
  }

  /// 获取当前内存使用情况
  static void printMemoryUsage() {
    try {
      final imageCache = PaintingBinding.instance.imageCache;
      logDebug('📊 内存使用情况:');
      logDebug('  - 图片缓存数量: ${imageCache.currentSize}');
      logDebug('  - 图片缓存大小限制: ${imageCache.maximumSize}');
      logDebug('  - 图片缓存大小: ${imageCache.currentSizeBytes}');
      logDebug('  - 图片缓存大小限制: ${imageCache.maximumSizeBytes}');
    } catch (e) {
      logError('❌ 获取内存使用情况时出错: $e');
    }
  }

  /// 设置图片缓存限制
  static void setImageCacheLimits({
    int? maxSize,
    int? maxSizeBytes,
  }) {
    try {
      final imageCache = PaintingBinding.instance.imageCache;
      
      if (maxSize != null) {
        imageCache.maximumSize = maxSize;
        logDebug('📊 图片缓存数量限制设置为: $maxSize');
      }
      
      if (maxSizeBytes != null) {
        imageCache.maximumSizeBytes = maxSizeBytes;
        logDebug('📊 图片缓存大小限制设置为: $maxSizeBytes bytes');
      }
    } catch (e) {
      logError('❌ 设置图片缓存限制时出错: $e');
    }
  }

  /// 在应用启动时初始化内存管理
  static void initialize() {
    // 设置合理的图片缓存限制
    setImageCacheLimits(
      maxSize: 100, // 最多缓存100张图片
      maxSizeBytes: 50 * 1024 * 1024, // 最多缓存50MB
    );
    
    logDebug('🚀 内存管理器初始化完成');
  }
}
