import 'package:intl/intl.dart';
import 'package:kissu_app/model/location_model/location_model.dart';
import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/utils/track_cache_manager.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';

class TrackApi {
  static const String _baseUrl = '/get/trace';
  
  /// 获取位置数据
  /// [date] 日期格式：2025-08-25
  /// [isOneself] 1查看自己 0查看另一半
  /// [useCache] 是否使用缓存，默认true
  static Future<HttpResultN<LocationResponse>> getTrack({
    String? date,
    required int isOneself,
    bool useCache = true,
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
      
      // 尝试从缓存获取数据（仅对历史日期）
      if (useCache) {
        final cachedData = await TrackCacheManager.instance.getCachedTrackData(targetDate, isOneself);
        if (cachedData != null) {
          logDebug('✅ TrackApi: 使用缓存数据: $targetDate, isOneself=$isOneself', tag: 'TrackApi');
          return HttpResultN<LocationResponse>(
            isSuccess: true,
            code: 0,
            data: cachedData,
          );
        }
      }
      
      // 缓存未命中，从API获取数据
      logDebug('🔄 TrackApi: 缓存未命中，请求API数据: $targetDate, isOneself=$isOneself', tag: 'TrackApi');

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
          logDebug('🔍 Track API 返回数据结构: ${jsonData.keys.toList()}', tag: 'TrackApi');
          
          final locationResponse = LocationResponse.fromJson(jsonData);
          
          // 缓存历史数据（今天之前的数据）
          if (useCache) {
            await TrackCacheManager.instance.cacheTrackData(targetDate, isOneself, locationResponse);
          }
          
          logInfo('✅ TrackApi: 获取到最新数据${useCache ? "，已缓存历史数据" : ""}', tag: 'TrackApi');
          
          return HttpResultN<LocationResponse>(
            isSuccess: true,
            code: result.code,
            data: locationResponse,
          );

          
        } catch (e) {
          logError('🚨 Track API 数据解析失败: $e', tag: 'TrackApi', error: e);
          logDebug('📝 原始数据类型: ${result.dataJson.runtimeType}', tag: 'TrackApi');
          if (result.dataJson is Map) {
            logDebug('📝 数据字段: ${(result.dataJson as Map).keys.toList()}', tag: 'TrackApi');
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

  /// 清除所有轨迹缓存
  static Future<void> clearAllCache() async {
    await TrackCacheManager.instance.clearAllCache();
  }
  
  /// 获取缓存统计信息
  static Future<Map<String, dynamic>> getCacheStats() async {
    return await TrackCacheManager.instance.getCacheStats();
  }
  
  /// 强制刷新（不使用缓存）
  static Future<HttpResultN<LocationResponse>> forceRefresh({
    String? date,
    required int isOneself,
  }) async {
    return await getTrack(
      date: date,
      isOneself: isOneself,
      useCache: false,
    );
  }
}
