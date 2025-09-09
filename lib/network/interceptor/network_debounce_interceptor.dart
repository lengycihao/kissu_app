import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:kissu_app/network/interceptor/http_header_key.dart';
import 'package:kissu_app/network/tools/cons/network_constants.dart';

import 'mixin_debug.dart';

class NetworkDebounceInterceptor extends Interceptor {
  static final Map<String, CancelToken> _cancelTokenMap = {};
  static final Map<String, String> _requestCacheMap = {};
  static final Map<String, DateTime> _requestTimeMap = {};
  static final Map<String, Completer<Response>> _pendingRequests = {};

  static const Duration _debounceDelay = Duration(milliseconds: 300);
  static const Duration _cacheExpiry = Duration(minutes: 5);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final url = options.uri.toString();
    final method = options.method;
    final headers = options.headers;
    final isShowLoadingDialog = _getBoolHeader(
      headers,
      HttpHeaderKey.showLoadingDialog,
    );
    final enableDebounce = _getBoolHeader(
      headers,
      HttpHeaderKey.networkDebounce,
    );

    if (enableDebounce) {
      final parameters = _extractParameters(method, options);
      _handleDebounceRequest(
        url,
        method,
        parameters,
        options,
        handler,
        isShowLoadingDialog,
      );
    } else {
      if (isShowLoadingDialog) {
        // Show loading dialog if needed
      }
      super.onRequest(options, handler);
    }
  }

  bool _getBoolHeader(Map<String, dynamic> headers, String key) {
    return headers[key] != null &&
        headers[key].toString().toLowerCase() == 'true';
  }

  Map<String, dynamic>? _extractParameters(
    String method,
    RequestOptions options,
  ) {
    switch (method.toUpperCase()) {
      case 'GET':
        return options.queryParameters;
      case 'POST':
      case 'PUT':
      case 'PATCH':
        if (options.data is Map) {
          return Map<String, dynamic>.from(options.data);
        } else if (options.data is FormData) {
          return _extractFormDataParams(options.data as FormData);
        } else if (options.data is String) {
          try {
            return json.decode(options.data);
          } catch (e) {
            return {'body': options.data};
          }
        }
        break;
      case 'DELETE':
        return options.queryParameters.isNotEmpty
            ? options.queryParameters
            : null;
    }
    return null;
  }

  Map<String, dynamic> _extractFormDataParams(FormData formData) {
    final Map<String, dynamic> params = {};

    for (var field in formData.fields) {
      params[field.key] = field.value;
    }

    for (var file in formData.files) {
      params['${file.key}_file_size'] = file.value.length;
      params['${file.key}_file_name'] = file.value.filename ?? 'unnamed';
    }

    return params;
  }

  void _handleDebounceRequest(
    String url,
    String method,
    Map<String, dynamic>? parameters,
    RequestOptions options,
    RequestInterceptorHandler handler,
    bool isShowLoadingDialog,
  ) async {
    final requestKey = _generateRequestKey(method, url, parameters);
    final now = DateTime.now();

    // Clean expired cache entries
    _cleanExpiredCache();

    // Check for identical pending request
    if (_pendingRequests.containsKey(requestKey)) {
      try {
        final response = await _pendingRequests[requestKey]!.future;
        handler.resolve(response);
        return;
      } catch (e) {
        // If pending request failed, continue with new request
        _pendingRequests.remove(requestKey);
      }
    }

    // Check for recent identical request
    final lastRequestTime = _requestTimeMap[requestKey];
    if (lastRequestTime != null &&
        now.difference(lastRequestTime) < _debounceDelay) {
      // Too soon, reject the request
      handler.resolve(
        Response(
          statusCode: HttpStatusCode.repeat,
          statusMessage: 'Request debounced - too frequent',
          requestOptions: options,
        ),
      );
      return;
    }

    // Cancel any existing request with same key
    final existingToken = _cancelTokenMap[requestKey];
    if (existingToken != null && !existingToken.isCancelled) {
      existingToken.cancel('Superseded by new request');
    }

    // Set up new request
    final cancelToken = CancelToken();
    _cancelTokenMap[requestKey] = cancelToken;
    _requestTimeMap[requestKey] = now;
    options.cancelToken = cancelToken;

    // Create completer for request deduplication
    final completer = Completer<Response>();
    _pendingRequests[requestKey] = completer;

    if (isShowLoadingDialog) {
      // Show loading dialog if needed
    }

    // Continue with the request
    super.onRequest(options, handler);
  }

  String _generateRequestKey(
    String method,
    String url,
    Map<String, dynamic>? params,
  ) {
    final sortedParams = _sortAndSerializeParams(params);
    return '$method:$url:$sortedParams';
  }

  String _sortAndSerializeParams(Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) {
      return '';
    }

    final sortedKeys = params.keys.toList()..sort();
    final sortedParams = <String, dynamic>{};

    for (final key in sortedKeys) {
      sortedParams[key] = params[key];
    }

    try {
      return json.encode(sortedParams);
    } catch (e) {
      return sortedParams.toString();
    }
  }

  void _cleanExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    _requestTimeMap.forEach((key, time) {
      if (now.difference(time) > _cacheExpiry) {
        expiredKeys.add(key);
      }
    });

    for (final key in expiredKeys) {
      _requestTimeMap.remove(key);
      _requestCacheMap.remove(key);
      _cancelTokenMap.remove(key);
      _pendingRequests.remove(key);
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _handleRequestCompletion(response.requestOptions, response);
    super.onResponse(response, handler);
  }

  @override
  Future onError(DioException err, ErrorInterceptorHandler handler) async {
    _handleRequestCompletion(err.requestOptions, null, err);
    super.onError(err, handler);
  }

  void _handleRequestCompletion(
    RequestOptions requestOptions, [
    Response? response,
    DioException? error,
  ]) {
    final headers = requestOptions.headers;
    final isShowLoadingDialog = _getBoolHeader(
      headers,
      HttpHeaderKey.showLoadingDialog,
    );
    final enableDebounce = _getBoolHeader(
      headers,
      HttpHeaderKey.networkDebounce,
    );

    if (enableDebounce) {
      final url = requestOptions.uri.toString();
      final method = requestOptions.method;
      final parameters = _extractParameters(method, requestOptions);
      final requestKey = _generateRequestKey(method, url, parameters);

      // Complete pending request
      final completer = _pendingRequests.remove(requestKey);
      if (completer != null && !completer.isCompleted) {
        if (response != null) {
          completer.complete(response);
        } else if (error != null) {
          completer.completeError(error);
        }
      }

      // Clean up cancel token
      _cancelTokenMap.remove(requestKey);
    }

    if (isShowLoadingDialog) {
      // Dismiss loading dialog if needed
    }
  }

  static void clearAllCache() {
    _cancelTokenMap.clear();
    _requestCacheMap.clear();
    _requestTimeMap.clear();
    _pendingRequests.clear();
  }
}
