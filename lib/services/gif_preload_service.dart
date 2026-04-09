import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:kissu_app/network/tools/logging/log_manager.dart';

/// GIF预加载服务
/// 
/// 用于在首页等位置提前预加载GIF帧数据到原生层缓存
/// 后续在地图页面使用时可以直接从缓存读取，无需重新解码
class GifPreloadService {
  static const MethodChannel _channel = MethodChannel('com.amap.flutter.map.gif_preload');
  
  /// 预加载GIF到缓存
  /// 
  /// [assetPath] GIF文件的asset路径（如: assets/gif/ceshi.gif）
  /// [width] GIF显示宽度（像素）
  /// [height] GIF显示高度（像素）
  static Future<bool> preloadGif({
    required String assetPath,
    required int width,
    required int height,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'preloadGif',
        {
          'assetPath': assetPath,
          'width': width,
          'height': height,
        },
      );
      logger.debug('✅ GIF预加载请求已发送: $assetPath, ${width}x$height');
      return result ?? false;
    } catch (e) {
      logger.error('❌ GIF预加载失败: $e');
      return false;
    }
  }
  
  /// 预加载定位页面使用的GIF
  /// 
  /// 在首页初始化时调用，提前加载定位页面需要的GIF动画
  static Future<void> preloadLocationGifs(double devicePixelRatio) async {
    // 计算实际像素尺寸
    final gifSizeW = (498 / 2 * devicePixelRatio).toInt();
    final gifSizeH = (633 / 2 * devicePixelRatio).toInt();
    
    // 预加载定位页面的GIF
    await preloadGif(
      assetPath: 'assets/gif/ceshi.gif',
      width: gifSizeW,
      height: gifSizeH,
    );
  }
}
