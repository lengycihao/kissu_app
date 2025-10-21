import 'package:flutter/services.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';

/// 地图自定义样式加载工具类
class MapStyleLoader {
  static CustomStyleOptions? _cachedCustomStyle;

  /// 获取自定义地图样式
  /// 如果已经缓存则直接返回，否则加载资源文件
  static Future<CustomStyleOptions> getCustomMapStyle() async {
    if (_cachedCustomStyle != null) {
      return _cachedCustomStyle!;
    }

    try {
      // 加载 style.data 文件
      final styleDataBytes = await rootBundle.load('assets/map/style.data');
      final styleData = styleDataBytes.buffer.asUint8List();

      // 加载 style_extra.data 文件  
      final styleExtraDataBytes = await rootBundle.load('assets/map/style_extra.data');
      final styleExtraData = styleExtraDataBytes.buffer.asUint8List();

      // 创建自定义样式配置
      _cachedCustomStyle = CustomStyleOptions(
        true, // 启用自定义样式
        styleData: styleData,
        styleExtraData: styleExtraData,
      );

      print('✅ 地图自定义样式加载成功');
      print('   style.data 大小: ${styleData.length} bytes');
      print('   style_extra.data 大小: ${styleExtraData.length} bytes');

      return _cachedCustomStyle!;
    } catch (e) {
      print('❌ 地图自定义样式加载失败: $e');
      
      // 加载失败时返回禁用状态
      _cachedCustomStyle = CustomStyleOptions(false);
      return _cachedCustomStyle!;
    }
  }

  /// 清除缓存的样式（用于重新加载）
  static void clearCache() {
    _cachedCustomStyle = null;
  }

  /// 预加载地图样式（建议在应用启动时调用）
  static Future<void> preloadMapStyle() async {
    try {
      await getCustomMapStyle();
      print('✅ 地图样式预加载完成');
    } catch (e) {
      print('❌ 地图样式预加载失败: $e');
    }
  }
}
