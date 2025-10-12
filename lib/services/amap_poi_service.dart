import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:kissu_app/models/poi_model.dart';

/// 高德地图POI搜索服务
class AMapPoiService {
  // 高德地图 Web 服务 API Key
  static const String _webApiKey = '347b46716d628b9464546b31726ba3fc';

  // 高德地图POI搜索API地址
  static const String _poiSearchUrl =
      'https://restapi.amap.com/v3/place/text';

  final Dio _dio = Dio();

  /// 搜索POI
  ///
  /// [keyword] 搜索关键词
  /// [city] 城市名称或adcode
  /// [page] 当前页码，从1开始
  /// [pageSize] 每页数量，默认20
  /// [location] 中心点坐标（格式：经度,纬度），传递后会返回距离信息
  ///
  /// 返回POI列表
  Future<List<PoiModel>> searchPoi({
    required String keyword,
    required String city,
    int page = 1,
    int pageSize = 20,
    String? location,
  }) async {
    try {
      final queryParams = {
        'key': _webApiKey,
        'keywords': keyword,
        'city': city,
        'offset': pageSize,
        'page': page,
        'extensions': 'all', // 返回详细信息
      };

      // 如果传递了location参数，则添加到查询参数中（用于计算距离）
      // 同时添加 sortrule=distance 来按距离排序，这样API才会返回distance字段
      if (location != null && location.isNotEmpty) {
        // queryParams['location'] = location;
        queryParams['sortrule'] = 'distance'; // 按距离排序，这样会返回distance字段
      }

      debugPrint('🔍 准备发送POI搜索请求: $queryParams');

      final response = await _dio.get(
        _poiSearchUrl,
        queryParameters: queryParams,
      );

      debugPrint('🔍 API响应状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        debugPrint('🔍 API响应数据: status=${data['status']}, info=${data['info']}, count=${data['count']}');
        
        // 检查返回状态
        if (data['status'] == '1' && data['pois'] != null) {
          final List<dynamic> pois = data['pois'];
          debugPrint('🔍 返回POI数量: ${pois.length}');
          
          // 调试：打印第一个POI的完整数据（只看关键字段）
          if (pois.isNotEmpty) {
            final firstPoi = pois[0];
            debugPrint('🔍 第一个POI数据: name=${firstPoi['name']}, distance=${firstPoi['distance']}, location=${firstPoi['location']}');
          }
          
          // 如果传递了location参数，但API没有返回正确的distance，则手动计算
          if (location != null && location.isNotEmpty) {
            final locationParts = location.split(',');
            if (locationParts.length == 2) {
              final userLng = double.tryParse(locationParts[0]);
              final userLat = double.tryParse(locationParts[1]);
              
              if (userLng != null && userLat != null) {
                // 为每个POI计算距离
                for (var poi in pois) {
                  // 检查distance字段是否为空或无效（如空数组、空字符串等）
                  final distanceValue = poi['distance'];
                  if (distanceValue == null || 
                      distanceValue == '' || 
                      distanceValue is List ||
                      (distanceValue is String && distanceValue.isEmpty)) {
                    // 手动计算距离
                    final poiLocation = poi['location'] as String?;
                    if (poiLocation != null && poiLocation.isNotEmpty) {
                      final poiParts = poiLocation.split(',');
                      if (poiParts.length == 2) {
                        final poiLng = double.tryParse(poiParts[0]);
                        final poiLat = double.tryParse(poiParts[1]);
                        
                        if (poiLng != null && poiLat != null) {
                          final distance = _calculateDistance(userLat, userLng, poiLat, poiLng);
                          poi['distance'] = distance.round().toString();
                        }
                      }
                    }
                  }
                }
              }
            }
          }
          
          return pois.map((poi) => PoiModel.fromJson(poi)).toList();
        } else {
          debugPrint('❌ POI搜索失败: ${data['info']}');
          return [];
        }
      } else {
        debugPrint('❌ POI搜索请求失败: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ POI搜索异常: $e');
      return [];
    }
  }

  /// 获取城市列表（从本地JSON文件或API）
  /// 这里暂时返回空，实际应该从/get/region接口获取
  Future<Map<String, dynamic>> getCityList() async {
    // TODO: 实现从后端API获取城市列表
    // 暂时返回空数据
    return {};
  }

  /// 使用Haversine公式计算两个经纬度之间的距离（单位：米）
  /// 
  /// [lat1] 第一个点的纬度
  /// [lng1] 第一个点的经度
  /// [lat2] 第二个点的纬度
  /// [lng2] 第二个点的经度
  /// 
  /// 返回距离（米）
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000; // 地球半径（米）
    
    // 将角度转换为弧度
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// 将角度转换为弧度
  double _toRadians(double degree) {
    return degree * pi / 180;
  }
}

