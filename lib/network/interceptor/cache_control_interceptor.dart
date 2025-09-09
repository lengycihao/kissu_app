import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:kissu_app/network/interceptor/http_header_key.dart';
import 'package:kissu_app/network/enum/cache_control.dart';
import 'package:kissu_app/network/utils/file_cache_util.dart';

import 'mixin_debug.dart';

class CacheControlInterceptor extends Interceptor {
  // Memory cache for frequently accessed data
  static final Map<String, _CacheEntry> _memoryCache = {};
  static const int _maxMemoryCacheSize = 50;
  static const Duration _defaultMemoryCacheDuration = Duration(minutes: 5);
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final headers = options.headers;
    final cacheControlName = headers[HttpHeaderKey.cacheControl] as String?;

    if (cacheControlName == null || cacheControlName.isEmpty) {
      handler.next(options);
      return;
    }

    final cacheKey = _generateCacheKey(options);
    final cacheControl = _parseCacheControl(cacheControlName);

    switch (cacheControl) {
      case CacheControl.onlyCache:
        await _handleOnlyCacheRequest(cacheKey, options, handler);
        break;
      case CacheControl.cacheFirstOrNetworkPut:
        await _handleCacheFirstRequest(cacheKey, options, handler);
        break;
      case CacheControl.onlyNetworkPutCache:
        await _handleNetworkFirstRequest(cacheKey, options, handler);
        break;
      default:
        handler.next(options);
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.statusCode == 200) {
      _handleSuccessfulResponse(response);
    }
    super.onResponse(response, handler);
  }

  @override
  Future onError(DioException err, ErrorInterceptorHandler handler) async {
    // Try to serve from cache if network fails and cache is available
    final headers = err.requestOptions.headers;
    final cacheControlName = headers[HttpHeaderKey.cacheControl] as String?;

    if (cacheControlName == CacheControl.cacheFirstOrNetworkPut.name) {
      final cacheKey = _generateCacheKey(err.requestOptions);
      final cachedData = await _getCachedData(cacheKey);

      if (cachedData != null) {
        handler.resolve(
          Response(
            statusCode: 200,
            data: cachedData,
            statusMessage: 'Served from cache due to network error',
            requestOptions: err.requestOptions,
          ),
        );
        return;
      }
    }

    super.onError(err, handler);
  }

  String _generateCacheKey(RequestOptions options) {
    final uri = options.uri.toString();
    final method = options.method;
    final params = options.queryParameters;
    final data = options.data;

    final keyComponents = [method, uri];

    if (params.isNotEmpty) {
      final sortedParams = Map.fromEntries(
        params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );
      keyComponents.add(json.encode(sortedParams));
    }

    if (data != null && data is Map) {
      try {
        keyComponents.add(json.encode(data));
      } catch (e) {
        keyComponents.add(data.toString());
      }
    }

    return keyComponents.join(':');
  }

  CacheControl? _parseCacheControl(String cacheControlName) {
    for (final control in CacheControl.values) {
      if (control.name == cacheControlName) {
        return control;
      }
    }
    return null;
  }

  Future<void> _handleOnlyCacheRequest(
    String cacheKey,
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final cachedData = await _getCachedData(cacheKey);

    handler.resolve(
      Response(
        statusCode: 200,
        data: cachedData,
        statusMessage: cachedData != null ? 'Cache hit' : 'Cache miss',
        requestOptions: options,
      ),
    );
  }

  Future<void> _handleCacheFirstRequest(
    String cacheKey,
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final cachedData = await _getCachedData(cacheKey);

    if (cachedData != null) {
      handler.resolve(
        Response(
          statusCode: 200,
          data: cachedData,
          statusMessage: 'Served from cache',
          requestOptions: options,
        ),
      );
    } else {
      options.headers[HttpHeaderKey.YYCacheKey] = cacheKey;
      handler.next(options);
    }
  }

  Future<void> _handleNetworkFirstRequest(
    String cacheKey,
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers[HttpHeaderKey.YYCacheKey] = cacheKey;
    handler.next(options);
  }

  Future<dynamic> _getCachedData(String cacheKey) async {
    // Check memory cache first
    final memoryEntry = _memoryCache[cacheKey];
    if (memoryEntry != null && !memoryEntry.isExpired) {
      return memoryEntry.data;
    }

    // Remove expired memory cache entry
    if (memoryEntry != null && memoryEntry.isExpired) {
      _memoryCache.remove(cacheKey);
    }

    // Check file cache
    final fileData = await FileCacheUtil.instance.getJsonByKey(cacheKey);

    // Cache in memory for faster access next time
    if (fileData != null) {
      _putMemoryCache(cacheKey, fileData, _defaultMemoryCacheDuration);
    }

    return fileData;
  }

  void _handleSuccessfulResponse(Response response) {
    final requestHeaders = response.requestOptions.headers;
    final cacheKey = requestHeaders[HttpHeaderKey.YYCacheKey] as String?;
    final cacheExpiration =
        requestHeaders[HttpHeaderKey.cacheExpiration] as String?;

    if (cacheKey != null && response.data != null) {
      Duration? duration;
      if (cacheExpiration != null) {
        try {
          duration = Duration(milliseconds: int.parse(cacheExpiration));
        } catch (e) {
          duration = null;
        }
      }

      // Save to both memory and file cache
      _putMemoryCache(
        cacheKey,
        response.data,
        duration ?? _defaultMemoryCacheDuration,
      );

      if (response.data is Map<String, dynamic>) {
        FileCacheUtil.instance.putJsonByKey(
          cacheKey,
          response.data as Map<String, dynamic>,
          expiration: duration,
        );
      }
    }
  }

  void _putMemoryCache(String key, dynamic data, Duration duration) {
    // Ensure memory cache doesn't exceed max size
    if (_memoryCache.length >= _maxMemoryCacheSize) {
      _cleanOldestMemoryCache();
    }

    _memoryCache[key] = _CacheEntry(
      data: data,
      expiresAt: DateTime.now().add(duration),
    );
  }

  void _cleanOldestMemoryCache() {
    if (_memoryCache.isEmpty) return;

    // Remove expired entries first
    final now = DateTime.now();
    _memoryCache.removeWhere((key, entry) => entry.expiresAt.isBefore(now));

    // If still over limit, remove oldest entries
    if (_memoryCache.length >= _maxMemoryCacheSize) {
      final sortedEntries = _memoryCache.entries.toList()
        ..sort((a, b) => a.value.expiresAt.compareTo(b.value.expiresAt));

      final toRemove = sortedEntries.take(
        _memoryCache.length - _maxMemoryCacheSize + 1,
      );
      for (final entry in toRemove) {
        _memoryCache.remove(entry.key);
      }
    }
  }

  static void clearMemoryCache() {
    _memoryCache.clear();
  }

  static void clearCacheByPattern(String pattern) {
    final regex = RegExp(pattern);
    _memoryCache.removeWhere((key, value) => regex.hasMatch(key));
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime expiresAt;

  _CacheEntry({required this.data, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
