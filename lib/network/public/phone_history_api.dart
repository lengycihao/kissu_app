import 'package:intl/intl.dart';
import 'package:kissu_app/model/phone_history_model/phone_history_model.dart';
import 'package:kissu_app/model/system_info_model.dart';
import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/utils/user_manager.dart';

class PhoneHistoryApi {
  // 简单的内存缓存，避免相同请求的重复网络调用
  static final Map<String, MapEntry<DateTime, PhoneHistoryModel>> _cache = {};
  static const Duration _cacheTimeout = Duration(minutes: 5);
  /// 获取敏感记录
  Future<HttpResultN<PhoneHistoryModel>> getSensitiveRecord({
    int page = 1,
    int pageSize = 10,
    String? date,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    
    if (date != null && date.isNotEmpty) {
      params['date'] = date;
    }
    
    // 生成缓存key，包含用户ID以避免不同用户间的缓存冲突
    final userId = UserManager.userId ?? 'anonymous';
    final cacheKey = '${userId}_${page}_${pageSize}_${date ?? 'today'}';
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isToday = (date == null || date.isEmpty) ? true : (date == today);
    
    // 检查缓存（当天的数据不使用缓存，总是获取最新）
    if (_cache.containsKey(cacheKey) && !isToday) {
      final cacheEntry = _cache[cacheKey]!;
      final isExpired = DateTime.now().difference(cacheEntry.key) > _cacheTimeout;
      
      if (!isExpired && page == 1) {
        // 只对第一页进行缓存，避免分页数据不一致
        return HttpResultN<PhoneHistoryModel>(
          isSuccess: true,
          code: 200,
          msg: 'success',
          data: cacheEntry.value,
        );
      } else if (isExpired) {
        _cache.remove(cacheKey);
      }
    }
    
    final result = await HttpManagerN.instance.executeGet(
      '/get/sensitive/record',
      queryParam: params,
      paramEncrypt: false,
    );

    if (result.isSuccess) {
      final model = PhoneHistoryModel.fromJson(result.getDataJson());
      
      // 缓存第一页数据（非当天数据）
      if (page == 1 && !isToday) {
        _cache[cacheKey] = MapEntry(DateTime.now(), model);
        
        // 清理过期缓存，避免内存泄漏
        _cleanExpiredCache();
      }
      
      return result.convert(data: model);
    } else {
      return result.convert();
    }
  }
  
  /// 清理过期缓存
  void _cleanExpiredCache() {
    final now = DateTime.now();
    _cache.removeWhere((key, value) => 
      now.difference(value.key) > _cacheTimeout
    );
  }
  
  /// 清空所有缓存
  static void clearCache() {
    _cache.clear();
  }
  
  /// 清空特定用户的缓存
  static void clearUserCache(String userId) {
    _cache.removeWhere((key, value) => key.startsWith('${userId}_'));
  }
  
  /// 清空当前用户的缓存
  static void clearCurrentUserCache() {
    final userId = UserManager.userId;
    if (userId != null) {
      clearUserCache(userId);
    }
  }

  /// 获取系统信息设置
  Future<HttpResultN<SystemInfoModel>> getSystemInfo() async {
    final result = await HttpManagerN.instance.executeGet(
      '/set/system/info',
      paramEncrypt: false,
    );

    if (result.isSuccess) {
      final model = SystemInfoModel.fromJson(result.getDataJson());
      return result.convert(data: model);
    } else {
      return result.convert();
    }
  }

  /// 设置系统开关
  Future<HttpResultN<dynamic>> setSystemSwitch({
    required String isPushKissuMsg,
    required String isPushSystemMsg,
    required String isPushPhoneStatusMsg,
    required String isPushLocationMsg,
  }) async {
    final params = {
      'is_push_kissu_msg': isPushKissuMsg,
      'is_push_system_msg': isPushSystemMsg,
      'is_push_phone_status_msg': isPushPhoneStatusMsg,
      'is_push_location_msg': isPushLocationMsg,
    };

    final result = await HttpManagerN.instance.executePost(
      '/set/system/switch',
      jsonParam: params,
      paramEncrypt: false,
    );

    return result;
  }
}