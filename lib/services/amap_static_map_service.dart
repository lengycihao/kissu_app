import 'package:kissu_app/utils/debug_util.dart';

/// 高德地图静态地图服务
/// 用于生成静态地图图片URL
class AMapStaticMapService {
  // 高德地图 Web 服务 API Key
  static const String _webApiKey = '347b46716d628b9464546b31726ba3fc';
  
  // 高德地图静态图 API 地址
  static const String _staticMapApiUrl = 'https://restapi.amap.com/v3/staticmap';
  
  /// 生成静态地图URL
  /// 
  /// [longitude] 经度
  /// [latitude] 纬度
  /// [zoom] 缩放级别，默认15（1-17，数值越大越详细）
  /// [size] 图片尺寸，格式"宽*高"，默认"400*200"
  /// [showMarker] 是否显示标记，默认false（因为我们使用自定义图标叠加）
  /// [markerLabel] 标记标签，默认A
  /// [markerSize] 标记大小，small/mid/large，默认mid
  /// [isSatellite] 是否为卫星地图，默认false
  /// 
  /// 返回值：静态地图图片URL
  static String getStaticMapUrl({
    required double longitude,
    required double latitude,
    int zoom = 15,
    String size = '400*200',
    bool showMarker = false,
    String markerLabel = 'A',
    String markerSize = 'mid',
    bool isSatellite = false,
  }) {
    try {
       
      // 构建URL参数（注意：高德API不需要对部分参数进行URL编码）
      final params = {
        'location': '$longitude,$latitude',
        'zoom': '$zoom',
        'size': size,
        'key': _webApiKey,
      };
      
      // 只有当 showMarker 为 true 时才添加 markers 参数
      if (showMarker) {
        params['markers'] = '$markerSize,,$markerLabel:$longitude,$latitude';
      }
      
      // 如果是卫星地图，添加 traffic=0（不显示路况）
      // 高德地图的卫星图通过 style 参数控制，但静态图API可能不支持
      // 作为替代，我们可以使用不同的底图样式参数
      String trafficParam = isSatellite ? '&traffic=0' : '';
      
      // 构建完整URL
      final urlBuffer = StringBuffer('$_staticMapApiUrl?')
        ..write('location=${params['location']}&')
        ..write('zoom=${params['zoom']}&')
        ..write('size=${params['size']}&');
      
      // 只有显示标记时才添加 markers 参数
      if (showMarker) {
        urlBuffer.write('markers=${params['markers']}&');
      }
      
      urlBuffer
        ..write('key=${params['key']}')
        ..write(trafficParam);
      
      final url = urlBuffer.toString();
      
       return url;
    } catch (e) {
      DebugUtil.error('❌ 生成静态地图URL失败: $e');
      return '';
    }
  }
  
  /// 生成带圆形围栏的静态地图URL
  /// 
  /// [longitude] 经度
  /// [latitude] 纬度
  /// [radius] 围栏半径（米）
  /// [zoom] 缩放级别，默认15
  /// [size] 图片尺寸，格式"宽*高"，默认"400*200"
  /// [isSatellite] 是否为卫星地图，默认false
  /// 
  /// 注意：高德静态地图API不直接支持圆形绘制，这里只显示中心标记
  static String getStaticMapUrlWithCircle({
    required double longitude,
    required double latitude,
    required int radius,
    int zoom = 15,
    String size = '400*200',
    bool isSatellite = false,
  }) {
    // 根据半径自动调整缩放级别
    final adjustedZoom = calculateZoomByRadius(radius);
    
    return getStaticMapUrl(
      longitude: longitude,
      latitude: latitude,
      zoom: adjustedZoom,
      size: size,
      markerLabel: 'A',
      markerSize: 'mid',
      isSatellite: isSatellite,
    );
  }
  
  /// 根据半径计算合适的缩放级别（公开方法）
  static int calculateZoomByRadius(int radius) {
    if (radius <= 50) return 16;  // 缩小1级
    if (radius <= 100) return 15; // 缩小1级
    if (radius <= 200) return 14; // 缩小1级
    if (radius <= 500) return 13; // 缩小1级
    if (radius <= 1000) return 12; // 缩小1级
    if (radius <= 2000) return 11; // 缩小1级
    return 10; // 缩小1级
  }
}
