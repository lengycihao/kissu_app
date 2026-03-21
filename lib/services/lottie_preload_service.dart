import 'package:flutter/material.dart';
import 'package:kissu_app/network/tools/logging/log_manager.dart';
import 'package:lottie/lottie.dart';

/// Lottie动画预加载服务
/// 在应用启动时预加载VIP页面的Lottie动画，提升页面打开速度
class LottiePreloadService {
  static final LottiePreloadService _instance = LottiePreloadService._internal();
  factory LottiePreloadService() => _instance;
  LottiePreloadService._internal();

  // VIP页面的Lottie动画资源列表
  static const List<String> _vipLottieAssets = [
    'assets/json/location.json',
    'assets/json/track.json',
    'assets/json/history.json',
    'assets/json/mingan.json',
  ];

  // 缓存预加载的LottieComposition
  final Map<String, LottieComposition> _cachedCompositions = {};
  
  // 预加载完成标志
  bool _isPreloaded = false;
  bool get isPreloaded => _isPreloaded;

  /// 预加载VIP页面的Lottie动画
  /// 应该在应用启动时调用，例如在main.dart的runApp之前
  Future<void> preloadVipLottieAnimations() async {
    if (_isPreloaded) {
      logger.debug('🎬 Lottie动画已预加载，跳过');
      return;
    }

    logger.debug('🎬 开始预加载VIP页面Lottie动画...');
    final startTime = DateTime.now();

    try {
      // 并行加载所有动画
      await Future.wait(
        _vipLottieAssets.map((assetPath) => _preloadSingleLottie(assetPath)),
      );

      _isPreloaded = true;
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      logger.debug('🎬 Lottie动画预加载完成，耗时: ${duration}ms');
    } catch (e) {
      logger.error('❌ Lottie动画预加载失败: $e');
    }
  }

  /// 预加载单个Lottie动画
  Future<void> _preloadSingleLottie(String assetPath) async {
    try {
      // 使用AssetLottie加载并缓存动画
      final composition = await AssetLottie(assetPath).load();
      _cachedCompositions[assetPath] = composition;
      logger.debug('✅ 预加载成功: $assetPath');
    } catch (e) {
      logger.error('❌ 预加载失败: $assetPath - $e');
    }
  }

  /// 获取预加载的LottieComposition
  /// 如果未预加载，返回null，Lottie会自动加载
  LottieComposition? getPreloadedComposition(String assetPath) {
    return _cachedCompositions[assetPath];
  }

  /// 清除缓存
  void clearCache() {
    _cachedCompositions.clear();
    _isPreloaded = false;
    logger.debug('🗑️ Lottie缓存已清除');
  }
}

