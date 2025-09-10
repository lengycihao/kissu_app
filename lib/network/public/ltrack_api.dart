import 'package:intl/intl.dart';
import 'package:kissu_app/model/location_model/location_model.dart';
import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/utils/user_manager.dart';

class TrackApi {
  static const String _baseUrl = '/get/trace';
  
  // 缓存存储
  static final Map<String, LocationResponse> _cache = {};

  /// 获取位置数据
  /// [date] 日期格式：2025-08-25
  /// [isOneself] 1查看自己 0查看另一半
  static Future<HttpResultN<LocationResponse>> getTrack({
    String? date,
    required int isOneself,
  }) async {
    try {
      final userId = UserManager.userId;
      if (userId == null || userId.isEmpty) {
        return HttpResultN<LocationResponse>(
          isSuccess: false,
          code: -1,
          msg: '用户未登录',
        );
      }

      // 如果没有指定日期，使用今天的日期
      final targetDate = date ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // 生成缓存key，包含用户ID
      final cacheKey = '${userId}_${targetDate}_$isOneself';
      
      // 检查缓存
      if (_cache.containsKey(cacheKey)) {
        return HttpResultN<LocationResponse>(
          isSuccess: true,
          code: 200,
          data: _cache[cacheKey]!,
        );
      }

      final params = {
        'date': targetDate,
        'is_oneself': isOneself.toString(),
      };

      final result = await HttpManagerN.instance.executeGet(
        _baseUrl,
        queryParam: params,
      );
      
      if (result.isSuccess && result.dataJson != null) {
        try {
          // 添加数据验证
          final jsonData = result.dataJson;
          if (jsonData is! Map<String, dynamic>) {
            throw FormatException('API返回的数据不是有效的JSON对象: ${jsonData.runtimeType}');
          }
          
          // 检查必要字段
          print('🔍 Track API 返回数据结构: ${jsonData.keys.toList()}');
          
          final locationResponse = LocationResponse.fromJson(jsonData);
          
          // 缓存结果
          _cache[cacheKey] = locationResponse;
          
          return HttpResultN<LocationResponse>(
            isSuccess: true,
            code: result.code,
            data: locationResponse,
          );
        } catch (e) {
          print('🚨 Track API 数据解析失败: $e');
          print('📝 原始数据类型: ${result.dataJson.runtimeType}');
          if (result.dataJson is Map) {
            print('📝 数据字段: ${(result.dataJson as Map).keys.toList()}');
          }
          
          return HttpResultN<LocationResponse>(
            isSuccess: false,
            code: -1,
            msg: '数据解析失败: $e',
          );
        }
      } else {
        return HttpResultN<LocationResponse>(
          isSuccess: false,
          code: result.code,
          msg: result.msg ?? '获取位置数据失败',
        );
      }
    } catch (e) {
      return HttpResultN<LocationResponse>(
        isSuccess: false,
        code: -1,
        msg: '获取位置数据失败: $e',
      );
    }
  }

  /// 清空指定用户的缓存
  static void clearUserCache(String userId) {
    final keysToRemove = _cache.keys.where((key) => key.startsWith('${userId}_')).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }

  /// 清空当前用户的缓存
  static void clearCurrentUserCache() {
    final userId = UserManager.userId;
    if (userId != null && userId.isNotEmpty) {
      clearUserCache(userId);
    }
  }

  /// 清空所有缓存
  static void clearAllCache() {
    _cache.clear();
  }
}
