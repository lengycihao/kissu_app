import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:kissu_app/network/tools/logging/log_manager.dart';
 
class LoggingInterceptor extends Interceptor {
  final bool logHeaders;
  final bool logRequestBody;
  final bool logResponseBody;
  final int maxBodyLength;
  final Set<String> sensitiveHeaders;
  final Set<String> sensitiveFields;
  final String tag;

  LoggingInterceptor({
    this.logHeaders = false, // Simplified - headers usually not needed
    this.logRequestBody = true,
    this.logResponseBody = true,
    this.maxBodyLength = 500, // Shorter for cleaner logs
    Set<String>? sensitiveHeaders,
    Set<String>? sensitiveFields,
    this.tag = 'HTTP',
  }) : sensitiveHeaders = sensitiveHeaders ?? _defaultSensitiveHeaders,
       sensitiveFields = sensitiveFields ?? _defaultSensitiveFields;

  static const Set<String> _defaultSensitiveHeaders = {
    'authorization',
    'cookie',
    'set-cookie',
    'x-api-key',
    'x-auth-token',
    'bearer',
    'token',
  };

  static const Set<String> _defaultSensitiveFields = {
    'password',
    'token',
    'secret',
    'key',
    'credential',
    'auth',
    'private',
    'sensitive',
    'passphrase',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final startTime = DateTime.now();
    options.extra['request_start_time'] = startTime;

    // Simple request log
    logger.debug('${options.method} ${options.uri}', tag: tag);

    if (logHeaders && options.headers.isNotEmpty) {
      final sanitizedHeaders = _sanitizeHeaders(options.headers);
      logger.debug('Headers: $sanitizedHeaders', tag: tag);
    }

    if (logRequestBody && options.data != null) {
      final bodyInfo = _getBodyInfo(options.data);
      if (bodyInfo.isNotEmpty) {
        logger.debug('Request: $bodyInfo', tag: tag);
      }
    }

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final endTime = DateTime.now();
    final startTime =
        response.requestOptions.extra['request_start_time'] as DateTime?;
    final duration = startTime != null ? endTime.difference(startTime) : null;

    // Simple success log
    final durationText = duration != null
        ? ' (${duration.inMilliseconds}ms)'
        : '';
    logger.info(
      '${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}$durationText',
      tag: tag,
    );

    if (logResponseBody && response.data != null) {
      final bodyInfo = _getBodyInfo(response.data);
      if (bodyInfo.isNotEmpty) {
        logger.debug('Response: $bodyInfo', tag: tag);
      }
    }

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final endTime = DateTime.now();
    final startTime =
        err.requestOptions.extra['request_start_time'] as DateTime?;
    final duration = startTime != null ? endTime.difference(startTime) : null;

    // Simple error log with more context
    final durationText = duration != null
        ? ' (${duration.inMilliseconds}ms)'
        : '';
    final statusCode = err.response?.statusCode ?? 'NO_RESPONSE';

    logger.error(
      '$statusCode ${err.requestOptions.method} ${err.requestOptions.uri}$durationText',
      tag: tag,
      error: err,
      extra: {
        'type': err.type.toString(),
        'message': err.message,
        'statusCode': statusCode,
      },
    );

    if (logResponseBody && err.response?.data != null) {
      final bodyInfo = _getBodyInfo(err.response!.data);
      if (bodyInfo.isNotEmpty) {
        logger.debug('Error Response: $bodyInfo', tag: tag);
      }
    }

    super.onError(err, handler);
  }

  Map<String, String> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = <String, String>{};
    headers.forEach((key, value) {
      sanitized[key] = _sanitizeHeaderValue(key, value);
    });
    return sanitized;
  }

  String _getBodyInfo(dynamic data) {
    try {
      if (data is FormData) {
        return _getFormDataInfo(data);
      }

      final bodyString = _formatBody(data);
      return _sanitizeBody(bodyString);
    } catch (e) {
      return '[Body parsing error: $e]';
    }
  }

  String _getFormDataInfo(FormData formData) {
    final parts = <String>[];

    // Add field count
    if (formData.fields.isNotEmpty) {
      parts.add('${formData.fields.length} fields');
    }

    // Add file count and sizes
    if (formData.files.isNotEmpty) {
      final fileCount = formData.files.length;
      final totalSize = formData.files.fold<int>(
        0,
        (sum, file) => sum + file.value.length,
      );
      parts.add('$fileCount files (${_formatBytes(totalSize)})');
    }

    return parts.isEmpty ? 'FormData (empty)' : 'FormData: ${parts.join(', ')}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String _formatBody(dynamic data) {
    try {
      if (data is String) {
        return data.length > maxBodyLength
            ? '${data.substring(0, maxBodyLength)}... (truncated)'
            : data;
      }

      final jsonString = JsonEncoder.withIndent('  ').convert(data);
      return jsonString.length > maxBodyLength
          ? '${jsonString.substring(0, maxBodyLength)}... (truncated)'
          : jsonString;
    } catch (e) {
      final dataString = data.toString();
      return dataString.length > maxBodyLength
          ? '${dataString.substring(0, maxBodyLength)}... (truncated)'
          : dataString;
    }
  }

  String _sanitizeHeaderValue(String key, dynamic value) {
    if (_isSensitiveHeader(key)) {
      return '***HIDDEN***';
    }
    return value.toString();
  }

  String _sanitizeBody(String body) {
    try {
      final decoded = json.decode(body) as Map<String, dynamic>;
      final sanitized = _sanitizeMap(decoded);
      return JsonEncoder.withIndent('  ').convert(sanitized);
    } catch (e) {
      // Not JSON, perform simple string sanitization
      return _sanitizeString(body);
    }
  }

  Map<String, dynamic> _sanitizeMap(Map<String, dynamic> map) {
    final sanitized = <String, dynamic>{};

    map.forEach((key, value) {
      if (_isSensitiveField(key)) {
        sanitized[key] = '***HIDDEN***';
      } else if (value is Map<String, dynamic>) {
        sanitized[key] = _sanitizeMap(value);
      } else if (value is List) {
        sanitized[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _sanitizeMap(item);
          }
          return item;
        }).toList();
      } else {
        sanitized[key] = value;
      }
    });

    return sanitized;
  }

  String _sanitizeString(String input) {
    String result = input;

    for (final field in sensitiveFields) {
      final pattern = RegExp('"$field"\\s*:\\s*"[^"]*"', caseSensitive: false);
      result = result.replaceAll(pattern, '"$field": "***HIDDEN***"');
    }

    return result;
  }

  bool _isSensitiveHeader(String key) {
    return sensitiveHeaders.any(
      (header) => key.toLowerCase().contains(header.toLowerCase()),
    );
  }

  bool _isSensitiveField(String key) {
    return sensitiveFields.any(
      (field) => key.toLowerCase().contains(field.toLowerCase()),
    );
  }

  static LoggingInterceptor create({
    bool logHeaders = false,
    bool logRequestBody = true,
    bool logResponseBody = true,
    int maxBodyLength = 500,
    Set<String>? sensitiveHeaders,
    Set<String>? sensitiveFields,
    String tag = 'HTTP',
  }) {
    return LoggingInterceptor(
      logHeaders: logHeaders,
      logRequestBody: logRequestBody,
      logResponseBody: logResponseBody,
      maxBodyLength: maxBodyLength,
      sensitiveHeaders: sensitiveHeaders,
      sensitiveFields: sensitiveFields,
      tag: tag,
    );
  }

  // Remove unused updateSettings method since interceptors are immutable
}
