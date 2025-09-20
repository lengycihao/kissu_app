import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/network/public/auth_service.dart';

import 'interceptor/http_header_key.dart';
import 'enum/cache_control.dart';
import 'enum/http_method.dart';
import 'http_engine.dart';
import 'interceptor/cache_control_interceptor.dart';
import 'interceptor/encypt_interceptor.dart';
import 'interceptor/logging_interceptor.dart';
import 'interceptor/network_debounce_interceptor.dart';
import 'interceptor/business_header_interceptor.dart';
import 'interceptor/api_response_interceptor.dart';

class HttpManagerN {
  HttpManagerN._();

  static final HttpManagerN _instance = HttpManagerN._();

  static HttpManagerN get instance => _instance;

  late HttpEngine _httpEngine;
  bool _isInitialized = false;

  /// Initialize HTTP manager with enhanced interceptors
  init(
    String? baseUrl, {
    List<Interceptor>? interceptors,
    AuthService? authService, // 新增 AuthService 参数
    String? encryptionKey,
    String? encryptionIv,
    bool enableCache = true,
    bool enableEncryption = false,
    bool enableDebounce = true,
    bool enableApiInterceptor = true,
    bool enableBusinessHeaders = true, // 新增业务请求头开关
    bool enableResponseProcessor = true, // 新增响应处理开关
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
  }) {
    final enhancedInterceptors = <Interceptor>[];

    // 添加业务请求头拦截器（需要最先执行，确保所有请求都有正确的请求头）
    if (enableBusinessHeaders && authService != null) {
      enhancedInterceptors.add(BusinessHeaderInterceptor(authService));
    }

    if (enableDebounce) {
      enhancedInterceptors.add(NetworkDebounceInterceptor());
    }

    if (enableCache) {
      enhancedInterceptors.add(CacheControlInterceptor());
    }

    if (enableEncryption) {
      enhancedInterceptors.add(
        EncryptInterceptor.create(aesKey: encryptionKey, aesIv: encryptionIv),
      );
    }

    // Add response processor for unified error handling and format conversion
    if (enableResponseProcessor) {
      enhancedInterceptors.add(ApiResponseInterceptor());
    }

    // Add custom interceptors last
    if (interceptors != null) {
      enhancedInterceptors.addAll(interceptors);
    }

    // Add logging interceptor (logging is controlled by the logging system itself)
    enhancedInterceptors.add(
      LoggingInterceptor.create(
        logHeaders: true, // 启用 header 日志来查看 sign 字段
        logRequestBody: true,
        logResponseBody: true,
        maxBodyLength: 500,
        tag: 'HTTP',
      ),
    );

    _httpEngine = HttpEngine(
      baseUrl,
      enhancedInterceptors,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      sendTimeout: sendTimeout,
    );
    _isInitialized = true;
  }

  /// Enhanced file download with progress tracking
  Future<HttpResultN<String>> downloadFile(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    _ensureInitialized();

    try {
      final options = Options(headers: headers);
      await _httpEngine.dio.download(
        urlPath,
        savePath,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );

      return HttpResultN<String>(
        isSuccess: true,
        code: 200,
        msg: 'Download completed',
      );
    } on DioException catch (e) {
      return HttpResultN<String>(
        isSuccess: false,
        code: e.response?.statusCode ?? -1,
        msg: _handleDioException(e),
      );
    } catch (error) {
      return HttpResultN<String>(
        isSuccess: false,
        code: -1,
        msg: error.toString(),
      );
    }
  }

  /// Enhanced POST request with new features
  Future<HttpResultN> executePost(
    String url, {
    HttpMethod method = HttpMethod.POST,
    Map<String, String>? headers,
    Map<String, dynamic>? jsonParam,
    Map<String, dynamic>? formParam,
    Map<String, String>? paths, // File path
    Map<String, Uint8List>? pathStreams, // File stream
    CacheControl? cacheControl,
    Duration? cacheExpiration, // Cache expired duration
    ProgressCallback? send, // Upload progress
    ProgressCallback? receive, // Download progress
    CancelToken? cancelToken,
    bool paramEncrypt = false, // 默认改为false，避免不必要的加密
    bool bodyEncrypt = false, // 新增body加密选项
    bool networkDebounce = true,
    bool isShowLoadingDialog = false, // If show global loading dialog
  }) {
    return _preExecuteRequest(
      url,
      method,
      headers,
      jsonParam,
      formParam,
      null,
      paths,
      pathStreams,
      cacheControl,
      cacheExpiration,
      send,
      receive,
      cancelToken,
      paramEncrypt,
      bodyEncrypt,
      networkDebounce,
      isShowLoadingDialog,
    );
  }

  /// Enhanced GET request with new features
  Future<HttpResultN> executeGet(
    String url, {
    HttpMethod method = HttpMethod.GET,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParam,
    CacheControl? cacheControl,
    Duration? cacheExpiration, // Cache expired duration
    ProgressCallback? receive, // Download progress
    CancelToken? cancelToken,
    bool paramEncrypt = false, // 默认改为false
    bool networkDebounce = true,
    bool isShowLoadingDialog = false, // If show global loading dialog
  }) {
    return _preExecuteRequest(
      url,
      method,
      headers,
      null,
      null,
      queryParam,
      null,
      null,
      cacheControl,
      cacheExpiration,
      null,
      receive,
      cancelToken,
      paramEncrypt,
      false, // GET请求不需要body加密
      networkDebounce,
      isShowLoadingDialog,
    );
  }

  /// Enhanced PUT request
  Future<HttpResultN> executePut(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? jsonParam,
    Map<String, dynamic>? formParam,
    ProgressCallback? send,
    ProgressCallback? receive,
    CancelToken? cancelToken,
    bool paramEncrypt = false,
    bool bodyEncrypt = false,
    bool networkDebounce = true,
    bool isShowLoadingDialog = false,
  }) {
    return _preExecuteRequest(
      url,
      HttpMethod.PUT,
      headers,
      jsonParam,
      formParam,
      null,
      null,
      null,
      null,
      null,
      send,
      receive,
      cancelToken,
      paramEncrypt,
      bodyEncrypt,
      networkDebounce,
      isShowLoadingDialog,
    );
  }

  /// Enhanced DELETE request
  Future<HttpResultN> executeDelete(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParam,
    Map<String, dynamic>? jsonParam,
    CancelToken? cancelToken,
    bool paramEncrypt = false,
    bool networkDebounce = true,
    bool isShowLoadingDialog = false,
  }) {
    return _preExecuteRequest(
      url,
      HttpMethod.DELETE,
      headers,
      jsonParam,
      null,
      queryParam,
      null,
      null,
      null,
      null,
      null,
      null,
      cancelToken,
      paramEncrypt,
      false,
      networkDebounce,
      isShowLoadingDialog,
    );
  }

  /// Enhanced PATCH request
  Future<HttpResultN> executePatch(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? jsonParam,
    Map<String, dynamic>? formParam,
    ProgressCallback? send,
    ProgressCallback? receive,
    CancelToken? cancelToken,
    bool paramEncrypt = false,
    bool bodyEncrypt = false,
    bool networkDebounce = true,
    bool isShowLoadingDialog = false,
  }) {
    return _preExecuteRequest(
      url,
      HttpMethod.PATCH,
      headers,
      jsonParam,
      formParam,
      null,
      null,
      null,
      null,
      null,
      send,
      receive,
      cancelToken,
      paramEncrypt,
      bodyEncrypt,
      networkDebounce,
      isShowLoadingDialog,
    );
  }

  /// Create FormData from files for upload
  FormData createFormData({
    Map<String, dynamic>? fields,
    Map<String, String>? filePaths,
    Map<String, Uint8List>? fileStreams,
  }) {
    final formData = FormData();

    // Add fields
    if (fields != null) {
      fields.forEach((key, value) {
        formData.fields.add(MapEntry(key, value.toString()));
      });
    }

    // Add file paths
    if (filePaths != null) {
      filePaths.forEach((key, path) {
        formData.files.add(MapEntry(key, MultipartFile.fromFileSync(path)));
      });
    }

    // Add file streams
    if (fileStreams != null) {
      fileStreams.forEach((key, bytes) {
        formData.files.add(
          MapEntry(key, MultipartFile.fromBytes(bytes, filename: '$key.bin')),
        );
      });
    }

    return formData;
  }

  /// Upload files with enhanced progress tracking
  Future<HttpResultN> uploadFiles(
    String url, {
    Map<String, dynamic>? fields,
    Map<String, String>? filePaths,
    Map<String, Uint8List>? fileStreams,
    Map<String, String>? headers,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
    bool networkDebounce = false, // 上传通常不需要防抖
    bool isShowLoadingDialog = true, // 上传通常需要显示进度
  }) {
    final formData = createFormData(
      fields: fields,
      filePaths: filePaths,
      fileStreams: fileStreams,
    );

    return executePost(
      url,
      formParam: {'formData': formData}, // 这里需要特殊处理
      headers: headers,
      send: onSendProgress,
      cancelToken: cancelToken,
      networkDebounce: networkDebounce,
      isShowLoadingDialog: isShowLoadingDialog,
    );
  }

  Future<HttpResultN> _preExecuteRequest(
    String url,
    HttpMethod method,
    Map<String, String>? headers,
    Map<String, dynamic>? jsonParam,
    Map<String, dynamic>? formParam,
    Map<String, dynamic>? queryParam,
    Map<String, String>? paths,
    Map<String, Uint8List>? pathStreams,
    CacheControl? cacheControl,
    Duration? cacheExpiration,
    ProgressCallback? send,
    ProgressCallback? receive,
    CancelToken? cancelToken,
    bool paramEncrypt,
    bool bodyEncrypt,
    bool networkDebounce,
    bool isShowLoadingDialog,
  ) async {
    _ensureInitialized();

    if (headers == null || headers.isEmpty) {
      headers = <String, String>{};
    }

    // Enhanced header configuration
    if (networkDebounce) {
      headers[HttpHeaderKey.networkDebounce] = "true";
    }

    if (isShowLoadingDialog) {
      headers[HttpHeaderKey.showLoadingDialog] = "true";
    }

    if (paramEncrypt) {
      headers[HttpHeaderKey.paramEncrypt] = "true";
    }

    if (bodyEncrypt) {
      headers[HttpHeaderKey.bodyEncrypt] = "true";
      headers[HttpHeaderKey.responseDecrypt] = "true";
    }

    // Cache headers for all methods (not just POST)
    if (cacheControl != null) {
      headers[HttpHeaderKey.cacheControl] = cacheControl.name;

      if (cacheExpiration != null) {
        headers[HttpHeaderKey.cacheExpiration] = cacheExpiration.inMilliseconds
            .toString();
      }
    }

    return _executeRequest(
      url,
      method,
      headers,
      jsonParam,
      formParam,
      queryParam,
      paths,
      pathStreams,
      cacheControl,
      cacheExpiration,
      send,
      receive,
      cancelToken,
    );
  }

  /// Simplified request execution - business logic moved to ApiInterceptor
  Future<HttpResultN> _executeRequest(
    String url,
    HttpMethod method,
    Map<String, String>? headers,
    Map<String, dynamic>? jsonParam,
    Map<String, dynamic>? formParam,
    Map<String, dynamic>? queryParam,
    Map<String, String>? paths,
    Map<String, Uint8List>? pathStreams,
    CacheControl? cacheControl,
    Duration? cacheExpiration,
    ProgressCallback? send,
    ProgressCallback? receive,
    CancelToken? cancelToken,
  ) async {
    try {
      Response response;

      Future<Response> executeGenerateRequest() async {
        switch (method) {
          case HttpMethod.POST:
            return _httpEngine.executePost(
              url: url,
              jsonParams: jsonParam,
              formParam: formParam,
              paths: paths,
              pathStreams: pathStreams,
              headers: headers,
              send: send,
              receive: receive,
              cancelToken: cancelToken,
            );
          case HttpMethod.PUT:
            return _httpEngine.executePut(
              url: url,
              jsonParams: jsonParam,
              formParam: formParam,
              headers: headers,
              send: send,
              receive: receive,
              cancelToken: cancelToken,
            );
          case HttpMethod.DELETE:
            return _httpEngine.executeDelete(
              url: url,
              queryParams: queryParam,
              jsonParams: jsonParam,
              headers: headers,
              cancelToken: cancelToken,
            );
          case HttpMethod.PATCH:
            return _httpEngine.executePatch(
              url: url,
              jsonParams: jsonParam,
              formParam: formParam,
              headers: headers,
              send: send,
              receive: receive,
              cancelToken: cancelToken,
            );
          case HttpMethod.GET:
            return _httpEngine.executeGet(
              url: url,
              queryParams: queryParam,
              headers: headers,
              cacheControl: cacheControl,
              cacheExpiration: cacheExpiration,
              receive: receive,
              cancelToken: cancelToken,
            );
        }
      }

      // Enhanced timing measurement
      if (!kReleaseMode) {
        final startTime = DateTime.now();
        response = await executeGenerateRequest();
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime).inMilliseconds;

        final statusEmoji = response.statusCode == 200 ? '✅' : '❌';
        debugPrint(
          '$statusEmoji Request ${method.name} $url - ${duration}ms - Status: ${response.statusCode}',
        );
      } else {
        response = await executeGenerateRequest();
      }

      // ApiInterceptor has already processed the response
      // response.data should now contain a HttpResultN object
      if (response.data is HttpResultN) {
        return response.data as HttpResultN;
      } else {
        // Fallback in case ApiInterceptor is disabled

        return HttpResultN(
          isSuccess: true,
          code: response.statusCode ?? 200,
          msg: 'Success',
          dataJson: response.data["data"],
        );
      }
    } catch (e) {
      // This should not happen with ApiInterceptor enabled, but provide fallback

      return HttpResultN(
        isSuccess: false,
        code: -1,
        msg: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  String _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout';
      case DioExceptionType.sendTimeout:
        return 'Send timeout';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout';
      case DioExceptionType.badResponse:
        return 'Bad response: ${e.response?.statusCode}';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.connectionError:
        return 'Connection error';
      case DioExceptionType.badCertificate:
        return 'Bad certificate';
      case DioExceptionType.unknown:
        return 'Unknown error: ${e.message}';
    }
  }

  /// Utility methods for enhanced functionality

  /// Update base URL at runtime
  void updateBaseUrl(String newBaseUrl) {
    _ensureInitialized();
    _httpEngine.dio.options.baseUrl = newBaseUrl;
  }

  /// Add interceptor at runtime
  void addInterceptor(Interceptor interceptor) {
    _ensureInitialized();
    _httpEngine.dio.interceptors.add(interceptor);
  }

  /// Remove interceptor
  void removeInterceptor(Interceptor interceptor) {
    _ensureInitialized();
    _httpEngine.dio.interceptors.remove(interceptor);
  }

  /// Clear all caches
  void clearCache() {
    CacheControlInterceptor.clearMemoryCache();
  }

  /// Clear network debounce cache
  void clearDebounceCache() {
    NetworkDebounceInterceptor.clearAllCache();
  }

  /// Cancel all pending requests
  void cancelAllRequests([String? reason]) {
    _ensureInitialized();
    // This would require maintaining a list of active cancel tokens
    // For now, we'll clear the debounce cache which cancels pending requests
    NetworkDebounceInterceptor.clearAllCache();
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('HttpManagerN not initialized. Call init() first.');
    }
  }
}
