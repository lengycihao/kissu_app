import 'package:dio/dio.dart';
import 'package:kissu_app/utils/debug_util.dart';

/// 高德地图逆地理编码服务
/// 用于将经纬度坐标转换为地址信息
class AMapGeocodeService {
  // ⚠️ 重要：高德地图 Web 服务需要专门的 Web 服务 API Key
  // 
  // 这里需要使用 **Web服务类型** 的Key，不能使用 Android/iOS SDK Key！
  // 
  // 申请步骤：
  // 1. 访问高德开放平台：https://console.amap.com/dev/key/app
  // 2. 创建应用或选择现有应用
  // 3. 添加 Key，服务类型选择：Web服务
  // 4. 将新Key替换下面的值
  // 
  // 当前使用的Key (38edb925a25f22e3aae2f86ce7f2ff3b) 是Android SDK Key，
  // 会返回 USERKEY_PLAT_NOMATCH 错误
  // 
  // TODO: 请替换为正确的 Web 服务 Key
  static const String _webApiKey = '38edb925a25f22e3aae2f86ce7f2ff3b';
  
  // 高德地图逆地理编码 API 地址
  static const String _regeoApiUrl = 'https://restapi.amap.com/v3/geocode/regeo';
  
  final Dio _dio = Dio();
  
  /// 逆地理编码：根据经纬度获取地址信息
  /// 
  /// [longitude] 经度
  /// [latitude] 纬度
  /// [radius] 搜索半径，默认1000米
  /// [extensions] 返回结果控制，base(默认)返回基本地址信息；all返回详细地址信息
  /// 
  /// 返回值：
  /// - success: 是否成功
  /// - address: 完整的格式化地址
  /// - province: 省份
  /// - city: 城市
  /// - district: 区县
  /// - street: 街道
  /// - streetNumber: 门牌号
  /// - adcode: 区域编码
  Future<Map<String, dynamic>> getAddressFromLocation({
    required double longitude,
    required double latitude,
    int radius = 1000,
    String extensions = 'all',
  }) async {
    try {
      DebugUtil.info('🗺️ 开始逆地理编码: ($latitude, $longitude)');
      
      // 构建请求参数
      final params = {
        'key': _webApiKey,
        'location': '$longitude,$latitude', // 注意：高德API要求格式为 "经度,纬度"
        'radius': radius.toString(),
        'extensions': extensions,
        'batch': 'false',
        'roadlevel': '1',
      };
      
      // 发起请求
      final response = await _dio.get(
        _regeoApiUrl,
        queryParameters: params,
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
      
      // 检查响应
      if (response.statusCode != 200) {
        DebugUtil.error('❌ 逆地理编码请求失败: HTTP ${response.statusCode}');
        return {
          'success': false,
          'error': '网络请求失败',
        };
      }
      
      final data = response.data;
      
      // 检查高德API返回状态
      if (data['status'] != '1') {
        DebugUtil.error('❌ 高德API错误: ${data['info']}');
        return {
          'success': false,
          'error': data['info'] ?? '未知错误',
        };
      }
      
      // 解析地址信息
      final regeocode = data['regeocode'];
      if (regeocode == null) {
        return {
          'success': false,
          'error': '无法获取地址信息',
        };
      }
      
      final addressComponent = regeocode['addressComponent'];
      final formattedAddress = regeocode['formatted_address'];
      
      DebugUtil.success('✅ 逆地理编码成功: $formattedAddress');
      
      return {
        'success': true,
        'address': formattedAddress ?? '',
        'province': addressComponent?['province'] ?? '',
        'city': addressComponent?['city'] ?? '',
        'district': addressComponent?['district'] ?? '',
        'township': addressComponent?['township'] ?? '',
        'street': addressComponent?['streetNumber']?['street'] ?? '',
        'streetNumber': addressComponent?['streetNumber']?['number'] ?? '',
        'adcode': addressComponent?['adcode'] ?? '',
        'citycode': addressComponent?['citycode'] ?? '',
        'building': addressComponent?['building']?['name'] ?? '',
        'neighborhood': addressComponent?['neighborhood']?['name'] ?? '',
      };
      
    } catch (e) {
      DebugUtil.error('❌ 逆地理编码异常: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// 构建简短地址（用于显示）
  /// 例如："浙江省杭州市上城区远洋东街39号"
  String buildShortAddress(Map<String, dynamic> result) {
    if (result['success'] != true) {
      return '无法获取地址';
    }
    
    final province = result['province'] ?? '';
    final city = result['city'] ?? '';
    final district = result['district'] ?? '';
    final street = result['street'] ?? '';
    final streetNumber = result['streetNumber'] ?? '';
    
    // 组合地址，去除重复部分
    String address = '';
    if (province.isNotEmpty && !city.contains(province)) {
      address += province;
    }
    if (city.isNotEmpty) {
      address += city;
    }
    if (district.isNotEmpty) {
      address += district;
    }
    if (street.isNotEmpty) {
      address += street;
    }
    if (streetNumber.isNotEmpty) {
      address += streetNumber;
    }
    
    return address.isEmpty ? result['address'] ?? '位置信息' : address;
  }
  
  /// 构建详细地址（包含建筑物、小区等信息）
  String buildDetailAddress(Map<String, dynamic> result) {
    if (result['success'] != true) {
      return '无法获取地址';
    }
    
    return result['address'] ?? '位置信息';
  }
}

