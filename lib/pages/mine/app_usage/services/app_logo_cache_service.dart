import 'dart:convert';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kissu_app/network/tools/logging/log_manager.dart';

/// App Logo缓存服务
/// 用于缓存已上传的app logo URL，避免重复上传
class AppLogoCacheService {
  static const _tag = 'AppLogoCacheService';
  static const _cacheKey = 'app_logo_cache';
  
  // 单例
  static final AppLogoCacheService _instance = AppLogoCacheService._internal();
  factory AppLogoCacheService() => _instance;
  AppLogoCacheService._internal();
  
  // 内存缓存（包名 -> logo URL）
  Map<String, String> _cache = {};
  bool _isLoaded = false;
  
  /// 初始化缓存（从SharedPreferences加载）
  Future<void> initialize() async {
    if (_isLoaded) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_cacheKey);
      
      if (json != null && json.isNotEmpty) {
        final Map<String, dynamic> map = jsonDecode(json);
        // 过滤掉空字符串的缓存项
        _cache = <String, String>{};
        map.forEach((key, value) {
          final url = value as String;
          if (url.isNotEmpty) {
            _cache[key] = url;
          } else {
            logWarning('发现空的logo缓存，已过滤: $key', tag: _tag);
          }
        });
        logDebug('已加载logo缓存: ${_cache.length}个应用', tag: _tag);
      } else {
        _cache = {};
        logDebug('logo缓存为空', tag: _tag);
      }
      
      _isLoaded = true;
    } catch (e) {
      logError('加载logo缓存失败: $e', tag: _tag, error: e);
      _cache = {};
      _isLoaded = true;
    }
  }
  
  /// 获取缓存的logo URL
  /// [packageName] 应用包名
  /// 返回缓存的URL，如果不存在或为空则返回null
  String? getCachedLogoUrl(String packageName) {
    // 如果缓存未加载，返回null（避免在初始化完成前使用）
    if (!_isLoaded) {
      logWarning('缓存未初始化，无法获取logo: $packageName', tag: _tag);
      return null;
    }
    
    final url = _cache[packageName];
    // 如果URL为空字符串，也返回null（避免使用无效的缓存）
    if (url == null || url.isEmpty) {
      return null;
    }
    
    return url;
  }
  
  /// 缓存logo URL
  /// [packageName] 应用包名
  /// [logoUrl] logo的URL
  Future<void> cacheLogoUrl(String packageName, String logoUrl) async {
    try {
      // 确保URL不为空才缓存
      if (logoUrl.isEmpty) {
        logWarning('尝试缓存空的logo URL: $packageName', tag: _tag);
        return;
      }
      
      _cache[packageName] = logoUrl;
      await _saveCache();
      logDebug('已缓存logo: $packageName -> $logoUrl', tag: _tag);
    } catch (e) {
      logError('缓存logo失败: $e', tag: _tag, error: e);
    }
  }
  
  /// 保存缓存到SharedPreferences
  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_cache);
      await prefs.setString(_cacheKey, json);
    } catch (e) {
      logError('保存logo缓存失败: $e', tag: _tag, error: e);
    }
  }
  
  /// 清除所有缓存
  Future<void> clearCache() async {
    try {
      _cache.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      logDebug('已清除所有logo缓存', tag: _tag);
    } catch (e) {
      logError('清除logo缓存失败: $e', tag: _tag, error: e);
    }
  }
  
  /// 获取缓存数量
  int get cacheCount => _cache.length;
}

