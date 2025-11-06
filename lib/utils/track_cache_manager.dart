import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kissu_app/model/location_model/location_model.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/network/tools/logging/log_manager.dart';

/// 轨迹数据缓存管理器
/// 专门缓存今天之前的历史轨迹数据，提高加载速度
class TrackCacheManager {
  static const String _cachePrefix = 'track_cache_';
  static const String _metaPrefix = 'track_meta_';
  static const int _maxCacheAgeDays = 30; // 缓存保留30天
  static const int _maxCacheSize = 50; // 最多缓存50个条目
  
  static TrackCacheManager? _instance;
  static TrackCacheManager get instance => _instance ??= TrackCacheManager._();
  
  TrackCacheManager._();
  
  /// 生成缓存键
  /// 格式: track_cache_userId_date_isOneself_bindStatus
  String _generateCacheKey(String date, int isOneself) {
    final userId = UserManager.userId ?? 'unknown';
    final bindStatus = _getBindStatus();
    return '${_cachePrefix}${userId}_${date}_${isOneself}_$bindStatus';
  }
  
  /// 生成元数据键
  String _generateMetaKey(String date, int isOneself) {
    final userId = UserManager.userId ?? 'unknown';
    final bindStatus = _getBindStatus();
    return '${_metaPrefix}${userId}_${date}_${isOneself}_$bindStatus';
  }
  
  /// 获取当前绑定状态用于缓存键
  String _getBindStatus() {
    final user = UserManager.currentUser;
    if (user != null) {
      final bindStatus = user.bindStatus.toString(); //0从未绑定，1绑定中，2已解绑
      return bindStatus;
    }
    return 'unknown';
  }
  
  /// 检查是否应该缓存该日期的数据
  /// 规则：只缓存今天之前的数据
  bool _shouldCacheDate(String date) {
    try {
      final targetDate = DateTime.parse(date);
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final targetDateOnly = DateTime(targetDate.year, targetDate.month, targetDate.day);
      
      // 只缓存今天之前的数据
      final shouldCache = targetDateOnly.isBefore(todayDate);
      logger.debug('📅 缓存检查: $date ${shouldCache ? "应该缓存" : "不应缓存"}', tag: 'TrackCacheManager');
      return shouldCache;
    } catch (e) {
      logger.error('❌ 日期解析失败: $date, $e', tag: 'TrackCacheManager', error: e);
      return false;
    }
  }
  
  /// 获取缓存的轨迹数据
  Future<LocationResponse?> getCachedTrackData(String date, int isOneself) async {
    // 检查是否应该使用缓存
    if (!_shouldCacheDate(date)) {
      logger.debug('🚫 $date 是今天或未来日期，不使用缓存', tag: 'TrackCacheManager');
      return null;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _generateCacheKey(date, isOneself);
      final metaKey = _generateMetaKey(date, isOneself);
      
      final cachedData = prefs.getString(cacheKey);
      final metaData = prefs.getString(metaKey);
      
      if (cachedData == null || metaData == null) {
        logger.debug('💾 无缓存数据: $date, isOneself=$isOneself', tag: 'TrackCacheManager');
        return null;
      }
      
      // 检查缓存元数据
      final meta = jsonDecode(metaData);
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(meta['timestamp']);
      final now = DateTime.now();
      
      // 检查缓存是否过期（超过30天）
      if (now.difference(cacheTime).inDays > _maxCacheAgeDays) {
        logger.debug('⏰ 缓存已过期: $date, 缓存时间: $cacheTime', tag: 'TrackCacheManager');
        await _removeCacheData(date, isOneself);
        return null;
      }
      
      // 解析缓存数据
      final jsonData = jsonDecode(cachedData);
      final locationResponse = LocationResponse.fromJson(jsonData);
      
      logger.debug('✅ 使用缓存数据: $date, isOneself=$isOneself, 缓存时间: $cacheTime', tag: 'TrackCacheManager');
      return locationResponse;
      
    } catch (e) {
      logger.error('❌ 获取缓存数据失败: $e', tag: 'TrackCacheManager', error: e);
      await _removeCacheData(date, isOneself); // 清除损坏的缓存
      return null;
    }
  }
  
  /// 缓存轨迹数据
  Future<void> cacheTrackData(String date, int isOneself, LocationResponse data) async {
    // 检查是否应该缓存
    if (!_shouldCacheDate(date)) {
      logger.debug('🚫 $date 是今天或未来日期，不进行缓存', tag: 'TrackCacheManager');
      return;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _generateCacheKey(date, isOneself);
      final metaKey = _generateMetaKey(date, isOneself);
      
      // 序列化数据
      final jsonData = jsonEncode(data.toJson());
      
      // 创建元数据
      final meta = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'date': date,
        'isOneself': isOneself,
        'dataSize': jsonData.length,
      };
      
      // 保存数据和元数据
      await prefs.setString(cacheKey, jsonData);
      await prefs.setString(metaKey, jsonEncode(meta));
      
      logger.debug('💾 缓存数据成功: $date, isOneself=$isOneself, 大小: ${jsonData.length} bytes', tag: 'TrackCacheManager');
      
      // 清理旧缓存
      await _cleanupOldCache();
      
    } catch (e) {
      logger.error('❌ 缓存数据失败: $e', tag: 'TrackCacheManager', error: e);
    }
  }
  
  /// 移除特定的缓存数据
  Future<void> _removeCacheData(String date, int isOneself) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _generateCacheKey(date, isOneself);
      final metaKey = _generateMetaKey(date, isOneself);
      
      await prefs.remove(cacheKey);
      await prefs.remove(metaKey);
      
      logger.debug('🗑️ 移除缓存数据: $date, isOneself=$isOneself', tag: 'TrackCacheManager');
    } catch (e) {
      logger.error('❌ 移除缓存数据失败: $e', tag: 'TrackCacheManager', error: e);
    }
  }
  
  /// 清理旧缓存
  /// 1. 移除过期缓存（超过30天）
  /// 2. 如果缓存条目过多，移除最旧的
  Future<void> _cleanupOldCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      // 找到所有缓存元数据键
      final metaKeys = keys.where((key) => key.startsWith(_metaPrefix)).toList();
      
      final List<Map<String, dynamic>> cacheEntries = [];
      final now = DateTime.now();
      
      // 收集缓存信息并移除过期缓存
      for (final metaKey in metaKeys) {
        try {
          final metaDataString = prefs.getString(metaKey);
          if (metaDataString == null) continue;
          
          final meta = jsonDecode(metaDataString);
          final cacheTime = DateTime.fromMillisecondsSinceEpoch(meta['timestamp']);
          
          // 移除过期缓存
          if (now.difference(cacheTime).inDays > _maxCacheAgeDays) {
            final date = meta['date'];
            final isOneself = meta['isOneself'];
            await _removeCacheData(date, isOneself);
            logger.debug('🗑️ 移除过期缓存: $date, isOneself=$isOneself', tag: 'TrackCacheManager');
            continue;
          }
          
          // 收集有效缓存信息
          cacheEntries.add({
            'metaKey': metaKey,
            'timestamp': meta['timestamp'],
            'date': meta['date'],
            'isOneself': meta['isOneself'],
          });
        } catch (e) {
          logger.error('❌ 处理缓存元数据失败: $metaKey, $e', tag: 'TrackCacheManager', error: e);
          await prefs.remove(metaKey);
        }
      }
      
      // 如果缓存条目过多，移除最旧的
      if (cacheEntries.length > _maxCacheSize) {
        // 按时间戳排序，最旧的在前
        cacheEntries.sort((a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));
        
        final toRemove = cacheEntries.take(cacheEntries.length - _maxCacheSize);
        for (final entry in toRemove) {
          await _removeCacheData(entry['date'], entry['isOneself']);
          logger.debug('🗑️ 移除旧缓存: ${entry['date']}, isOneself=${entry['isOneself']}', tag: 'TrackCacheManager');
        }
      }
      
      logger.debug('🧹 缓存清理完成，当前缓存条目数: ${cacheEntries.length > _maxCacheSize ? _maxCacheSize : cacheEntries.length}', tag: 'TrackCacheManager');
      
    } catch (e) {
      logger.error('❌ 清理缓存失败: $e', tag: 'TrackCacheManager', error: e);
    }
  }
  
  /// 清除所有缓存
  Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      final cacheKeys = keys.where((key) => 
        key.startsWith(_cachePrefix) || key.startsWith(_metaPrefix)
      ).toList();
      
      for (final key in cacheKeys) {
        await prefs.remove(key);
      }
      
      logger.info('🗑️ 清除所有轨迹缓存完成，移除 ${cacheKeys.length} 个条目', tag: 'TrackCacheManager');
    } catch (e) {
      logger.error('❌ 清除所有缓存失败: $e', tag: 'TrackCacheManager', error: e);
    }
  }
  
  /// 获取缓存统计信息
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      final metaKeys = keys.where((key) => key.startsWith(_metaPrefix)).toList();
      
      int totalSize = 0;
      int validCacheCount = 0;
      int expiredCacheCount = 0;
      final now = DateTime.now();
      
      for (final metaKey in metaKeys) {
        try {
          final metaDataString = prefs.getString(metaKey);
          if (metaDataString == null) continue;
          
          final meta = jsonDecode(metaDataString);
          final cacheTime = DateTime.fromMillisecondsSinceEpoch(meta['timestamp']);
          
          if (now.difference(cacheTime).inDays > _maxCacheAgeDays) {
            expiredCacheCount++;
          } else {
            validCacheCount++;
            totalSize += (meta['dataSize'] as int?) ?? 0;
          }
        } catch (e) {
          expiredCacheCount++;
        }
      }
      
      return {
        'validCacheCount': validCacheCount,
        'expiredCacheCount': expiredCacheCount,
        'totalSize': totalSize,
        'totalSizeKB': (totalSize / 1024).toStringAsFixed(2),
        'maxCacheSize': _maxCacheSize,
        'maxCacheAgeDays': _maxCacheAgeDays,
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }
  
  /// 预热缓存（为常用日期预加载数据）
  Future<void> preloadCommonDates() async {
    // 这个方法可以在应用启动时调用，预加载最近几天的数据
    // 目前暂时留空，可以根据使用模式来优化
    logger.debug('🔥 预热缓存功能暂未实现', tag: 'TrackCacheManager');
  }
}
