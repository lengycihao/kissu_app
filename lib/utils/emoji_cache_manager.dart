import 'dart:convert';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kissu_app/utils/debug_util.dart';

/// 表情数据缓存管理器
/// 缓存表情分类数据和当前状态，提高加载速度
class EmojiCacheManager {
  static const String _emojiDataKey = 'emoji_categories_data';
  static const String _emojiMetaKey = 'emoji_categories_meta';
  static const String _currentStatusKey = 'current_status_data';
  static const String _currentStatusMetaKey = 'current_status_meta';
  static const int _maxCacheAgeHours = 24; // 缓存保留24小时
  
  static EmojiCacheManager? _instance;
  static EmojiCacheManager get instance => _instance ??= EmojiCacheManager._();
  
  EmojiCacheManager._();
  
  /// 缓存表情分类数据
  Future<void> cacheEmojiCategories(List<EmojiCategory> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 序列化数据
      final jsonData = jsonEncode(categories.map((category) => category.toJson()).toList());
      
      // 创建元数据
      final meta = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'dataSize': jsonData.length,
        'categoryCount': categories.length,
      };
      
      // 保存数据和元数据
      await prefs.setString(_emojiDataKey, jsonData);
      await prefs.setString(_emojiMetaKey, jsonEncode(meta));
      
      logDebug('💾 缓存表情分类数据成功，共 ${categories.length} 个分类');
    } catch (e) {
      logError('❌ 缓存表情分类数据失败: $e');
    }
  }
  
  /// 获取缓存的表情分类数据
  Future<List<EmojiCategory>?> getCachedEmojiCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final cachedData = prefs.getString(_emojiDataKey);
      final metaData = prefs.getString(_emojiMetaKey);
      
      if (cachedData == null || metaData == null) {
        logDebug('💾 无缓存的表情分类数据');
        return null;
      }
      
      // 检查缓存元数据
      final meta = jsonDecode(metaData);
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(meta['timestamp']);
      final now = DateTime.now();
      
      // 检查缓存是否过期（超过24小时）
      if (now.difference(cacheTime).inHours > _maxCacheAgeHours) {
        logDebug('⏰ 表情分类缓存已过期，缓存时间: $cacheTime');
        await _clearEmojiCache();
        return null;
      }
      
      // 解析缓存数据
      final jsonData = jsonDecode(cachedData);
      final categories = (jsonData as List)
          .map((item) => EmojiCategory.fromJson(item))
          .toList();
      
      logDebug('✅ 使用缓存的表情分类数据，共 ${categories.length} 个分类，缓存时间: $cacheTime');
      return categories;
      
    } catch (e) {
      logError('❌ 获取缓存表情分类数据失败: $e');
      await _clearEmojiCache(); // 清除损坏的缓存
      return null;
    }
  }
  
  /// 缓存当前状态数据
  Future<void> cacheCurrentStatus(CurrentStatusData statusData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 序列化数据
      final jsonData = jsonEncode(statusData.toJson());
      
      // 创建元数据
      final meta = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'dataSize': jsonData.length,
      };
      
      // 保存数据和元数据
      await prefs.setString(_currentStatusKey, jsonData);
      await prefs.setString(_currentStatusMetaKey, jsonEncode(meta));
      
      logDebug('💾 缓存当前状态数据成功');
    } catch (e) {
      logError('❌ 缓存当前状态数据失败: $e');
    }
  }
  
  /// 获取缓存的当前状态数据
  Future<CurrentStatusData?> getCachedCurrentStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final cachedData = prefs.getString(_currentStatusKey);
      final metaData = prefs.getString(_currentStatusMetaKey);
      
      if (cachedData == null || metaData == null) {
        logDebug('💾 无缓存的当前状态数据');
        return null;
      }
      
      // 检查缓存元数据
      final meta = jsonDecode(metaData);
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(meta['timestamp']);
      final now = DateTime.now();
      
      // 检查缓存是否过期（超过24小时）
      if (now.difference(cacheTime).inHours > _maxCacheAgeHours) {
        logDebug('⏰ 当前状态缓存已过期，缓存时间: $cacheTime');
        await _clearCurrentStatusCache();
        return null;
      }
      
      // 解析缓存数据
      final jsonData = jsonDecode(cachedData);
      final statusData = CurrentStatusData.fromJson(jsonData);
      
      logDebug('✅ 使用缓存的当前状态数据，缓存时间: $cacheTime');
      return statusData;
      
    } catch (e) {
      logError('❌ 获取缓存当前状态数据失败: $e');
      await _clearCurrentStatusCache(); // 清除损坏的缓存
      return null;
    }
  }
  
  /// 清除表情分类缓存
  Future<void> _clearEmojiCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_emojiDataKey);
      await prefs.remove(_emojiMetaKey);
      logDebug('🗑️ 清除表情分类缓存');
    } catch (e) {
      logError('❌ 清除表情分类缓存失败: $e');
    }
  }
  
  /// 清除当前状态缓存
  Future<void> _clearCurrentStatusCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentStatusKey);
      await prefs.remove(_currentStatusMetaKey);
      logDebug('🗑️ 清除当前状态缓存');
    } catch (e) {
      logError('❌ 清除当前状态缓存失败: $e');
    }
  }
  
  /// 清除所有缓存
  Future<void> clearAllCache() async {
    await _clearEmojiCache();
    await _clearCurrentStatusCache();
    logDebug('🗑️ 清除所有表情相关缓存');
  }
  
  /// 获取缓存统计信息
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      int emojiDataSize = 0;
      int statusDataSize = 0;
      bool emojiCacheValid = false;
      bool statusCacheValid = false;
      final now = DateTime.now();
      
      // 检查表情分类缓存
      final emojiMetaData = prefs.getString(_emojiMetaKey);
      if (emojiMetaData != null) {
        try {
          final meta = jsonDecode(emojiMetaData);
          final cacheTime = DateTime.fromMillisecondsSinceEpoch(meta['timestamp']);
          if (now.difference(cacheTime).inHours <= _maxCacheAgeHours) {
            emojiCacheValid = true;
            emojiDataSize = meta['dataSize'] ?? 0;
          }
        } catch (e) {
          // 忽略解析错误
        }
      }
      
      // 检查当前状态缓存
      final statusMetaData = prefs.getString(_currentStatusMetaKey);
      if (statusMetaData != null) {
        try {
          final meta = jsonDecode(statusMetaData);
          final cacheTime = DateTime.fromMillisecondsSinceEpoch(meta['timestamp']);
          if (now.difference(cacheTime).inHours <= _maxCacheAgeHours) {
            statusCacheValid = true;
            statusDataSize = meta['dataSize'] ?? 0;
          }
        } catch (e) {
          // 忽略解析错误
        }
      }
      
      return {
        'emojiCacheValid': emojiCacheValid,
        'statusCacheValid': statusCacheValid,
        'emojiDataSize': emojiDataSize,
        'statusDataSize': statusDataSize,
        'totalSize': emojiDataSize + statusDataSize,
        'totalSizeKB': ((emojiDataSize + statusDataSize) / 1024).toStringAsFixed(2),
        'maxCacheAgeHours': _maxCacheAgeHours,
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }
}

/// 表情分类数据模型（支持序列化）
class EmojiCategory {
  final String name;
  final int classId;
  final List<EmojiItem> emojis;
  
  EmojiCategory({
    required this.name,
    required this.classId,
    required this.emojis,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'classId': classId,
      'emojis': emojis.map((emoji) => emoji.toJson()).toList(),
    };
  }
  
  factory EmojiCategory.fromJson(Map<String, dynamic> json) {
    return EmojiCategory(
      name: json['name'] ?? '',
      classId: json['classId'] ?? 0,
      emojis: (json['emojis'] as List?)
          ?.map((item) => EmojiItem.fromJson(item))
          .toList() ?? [],
    );
  }
}

/// 表情项数据模型（支持序列化）
class EmojiItem {
  final int id;
  final String emoji; // 图片URL
  final String name;
  
  EmojiItem({
    required this.id,
    required this.emoji,
    required this.name,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'emoji': emoji,
      'name': name,
    };
  }
  
  factory EmojiItem.fromJson(Map<String, dynamic> json) {
    return EmojiItem(
      id: json['id'] ?? 0,
      emoji: json['emoji'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

/// 当前状态数据模型（支持序列化）
class CurrentStatusData {
  final bool hasStatus;
  final int currentStatusId;
  final String currentStatusText;
  final String currentStatusEmoji;
  final DateTime? statusExpireTime;
  final int selectedExpireHours;
  final int topExpireHours;
  
  CurrentStatusData({
    required this.hasStatus,
    required this.currentStatusId,
    required this.currentStatusText,
    required this.currentStatusEmoji,
    this.statusExpireTime,
    required this.selectedExpireHours,
    required this.topExpireHours,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'hasStatus': hasStatus,
      'currentStatusId': currentStatusId,
      'currentStatusText': currentStatusText,
      'currentStatusEmoji': currentStatusEmoji,
      'statusExpireTime': statusExpireTime?.millisecondsSinceEpoch,
      'selectedExpireHours': selectedExpireHours,
      'topExpireHours': topExpireHours,
    };
  }
  
  factory CurrentStatusData.fromJson(Map<String, dynamic> json) {
    return CurrentStatusData(
      hasStatus: json['hasStatus'] ?? false,
      currentStatusId: json['currentStatusId'] ?? 0,
      currentStatusText: json['currentStatusText'] ?? '',
      currentStatusEmoji: json['currentStatusEmoji'] ?? '',
      statusExpireTime: json['statusExpireTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['statusExpireTime'])
          : null,
      selectedExpireHours: json['selectedExpireHours'] ?? 1,
      topExpireHours: json['topExpireHours'] ?? 1,
    );
  }
}
