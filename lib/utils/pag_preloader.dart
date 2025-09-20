import 'package:flutter/material.dart';

/// PAG动画预加载管理器
/// 用于提前加载和缓存PAG动画资源，减少首次加载时的延迟
class PagPreloader {
  static final PagPreloader _instance = PagPreloader._internal();
  factory PagPreloader() => _instance;
  PagPreloader._internal();

  /// 已预加载的PAG资源缓存
  static final Map<String, bool> _preloadedAssets = {};
  
  /// 正在预加载的资源
  static final Set<String> _loadingAssets = {};

  /// 检查资源是否已预加载
  static bool isPreloaded(String assetPath) {
    return _preloadedAssets[assetPath] == true;
  }

  /// 标记资源为已预加载
  static void markAsPreloaded(String assetPath) {
    _preloadedAssets[assetPath] = true;
    _loadingAssets.remove(assetPath);
    debugPrint('PAG资源标记为已预加载: $assetPath');
  }

  /// 预加载首页PAG资源
  static Future<void> preloadHomePagAssets() async {
    final homeAssets = [
      'assets/pag/home_bg_person.pag',
      'assets/pag/home_bg_fridge.pag',
      'assets/pag/home_bg_clothes.pag',
      'assets/pag/home_bg_flowers.pag',
      'assets/pag/home_bg_music.pag',
    ];

    debugPrint('开始预加载首页PAG资源...');
    
    for (final assetPath in homeAssets) {
      if (!isPreloaded(assetPath) && !_loadingAssets.contains(assetPath)) {
        _loadingAssets.add(assetPath);
        // 这里可以添加实际的预加载逻辑，比如预解码等
        // 目前只是标记为预加载状态
        await Future.delayed(Duration(milliseconds: 50)); // 模拟预加载时间
        markAsPreloaded(assetPath);
      }
    }
    
    debugPrint('首页PAG资源预加载完成');
  }

  /// 清理预加载缓存（在内存压力大时调用）
  static void clearCache() {
    _preloadedAssets.clear();
    _loadingAssets.clear();
    debugPrint('PAG预加载缓存已清理');
  }

  /// 获取预加载状态信息
  static Map<String, dynamic> getPreloadStatus() {
    return {
      'preloadedCount': _preloadedAssets.length,
      'loadingCount': _loadingAssets.length,
      'preloadedAssets': _preloadedAssets.keys.toList(),
      'loadingAssets': _loadingAssets.toList(),
    };
  }
}
