import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart' as gg;
import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/network/public/auth_service.dart';
import 'package:get_it/get_it.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';

/// API响应拦截器
/// 处理统一的响应格式和错误处理
class ApiResponseInterceptor extends Interceptor {

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    try {
      // 处理401未授权
      if (response.statusCode == 401) {
        _showMessage('登录已过期，请重新登录');
        _handleUnauthorized();
        return;
      }

      // 转换响应为统一格式
      final processedResponse = _processApiResponse(response);
      
      // 检查业务层面的错误码处理
      if (!processedResponse.isSuccess) {
        // 检查各种错误码并给出相应处理
        switch (processedResponse.code) {
          case 43000:
            // token失效或账号异常 - 跳到登录页
            print('检测到code 43000，token失效或账号异常，需要重新登录');
            final message = processedResponse.msg ?? 'token失效或账号异常，请重新登录';
            _showMessage(message);
            _handleUnauthorized();
            return;
            
          case 41000:
            // header公共参数缺失
            print('检测到code 41000，header公共参数缺失');
            final message = processedResponse.msg ?? 'header公共参数缺失';
            _showMessage(message);
            break;
            
          case 51000:
            // 签名错误
            print('检测到code 51000，签名错误');
            final message = processedResponse.msg ?? '签名错误';
            _showMessage(message);
            break;
            
          case 1:
            // 接口处理失败 - 一般业务错误，不需要特殊处理，让上层业务处理
            print('检测到code 1，接口处理失败: ${processedResponse.msg}');
            break;
            
          default:
            // 检查是否是其他常见的token过期错误码
            final tokenExpiredCodes = [401, 1001, 1002, 10001, 403];
            if (tokenExpiredCodes.contains(processedResponse.code)) {
              print('检测到业务层面token过期，错误码: ${processedResponse.code}');
              final message = processedResponse.msg ?? '登录已过期，请重新登录';
              _showMessage(message);
              _handleUnauthorized();
              return;
            }
            
            // 检查错误消息中是否包含token过期关键词
            final msg = processedResponse.msg?.toLowerCase() ?? '';
            final tokenExpiredKeywords = ['token', 'unauthorized', '未授权', '登录失效', '登录过期'];
            if (tokenExpiredKeywords.any((keyword) => msg.contains(keyword))) {
              print('检测到错误消息中包含token过期关键词: ${processedResponse.msg}');
              final message = processedResponse.msg ?? '登录已过期，请重新登录';
              _showMessage(message);
              _handleUnauthorized();
              return;
            }
            break;
        }
      }
      
      response.data = processedResponse;
      super.onResponse(response, handler);
    } catch (e) {
      // 处理失败时创建错误响应
      final errorResult = HttpResultN(
        isSuccess: false,
        code: -1,
        msg: 'Response processing failed: ${e.toString()}',
      );
      response.data = errorResult;
      super.onResponse(response, handler);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 处理401错误
    if (err.response?.statusCode == 401) {
      _showMessage('登录已过期，请重新登录');
      _handleUnauthorized();
      return;
    }

    // 将网络错误转换为统一格式
    final errorResult = _handleDioError(err);
    final errorResponse = Response(
      statusCode: err.response?.statusCode ?? -1,
      statusMessage: err.response?.statusMessage ?? 'Network Error',
      data: errorResult,
      requestOptions: err.requestOptions,
    );

    // 转换错误为成功响应，让上层统一处理
    handler.resolve(errorResponse);
  }

  /// 处理未授权错误
  void _handleUnauthorized() async {
    print('检测到token过期，清除用户数据并跳转到登录页');
    
    try {
      // 通过AuthService清除所有用户数据
      final authService = GetIt.instance<AuthService>();
      await authService.logout();
      print('用户数据已清除');
    } catch (e) {
      print('清除用户信息失败: $e');
      // 备用清除方式
      try {
        const storage = FlutterSecureStorage();
        await storage.delete(key: 'current_user');
      } catch (fallbackError) {
        print('备用清除方式也失败: $fallbackError');
      }
    }
    
    // 跳转到登录页
    try {
      gg.Get.offAllNamed(KissuRoutePath.login);
    } catch (e) {
      print('导航到登录页失败: $e');
    }
  }

  /// 处理API响应
  HttpResultN _processApiResponse(Response response) {
    // 检查HTTP状态码
    if (!_isHttpStatusValid(response.statusCode)) {
      return HttpResultN(
        isSuccess: false,
        code: response.statusCode ?? -1,
        msg: _getHttpStatusMessage(response.statusCode),
      );
    }

    // 解析响应数据
    Map<String, dynamic> jsonMap;
    try {
      jsonMap = _parseResponseData(response.data);
    } catch (e) {
      return HttpResultN(
        isSuccess: false,
        code: -1,
        msg: 'Failed to parse response: ${e.toString()}',
      );
    }

    // 提取API字段
    final apiCode = _extractValue(jsonMap, ['code', 'status', 'statusCode']);
    final message = _extractValue(jsonMap, ['message', 'msg', 'description']);
    final data = jsonMap['data'];

    // 判断API是否成功
    final isApiSuccess = _isApiSuccess(apiCode);

    if (isApiSuccess) {
      return _createSuccessResult(data, apiCode, message);
    } else {
      return HttpResultN(
        isSuccess: false,
        code: apiCode ?? -1,
        msg: message ?? 'Request failed',
      );
    }
  }

  /// 检查HTTP状态码是否有效
  bool _isHttpStatusValid(int? statusCode) {
    return statusCode != null && statusCode >= 200 && statusCode < 300;
  }

  /// 检查API业务状态码是否表示成功
  bool _isApiSuccess(dynamic code) {
    if (code == null) return true; // 没有状态码默认成功
    if (code is int) return code == 200 || code == 0;
    if (code is String) return code == '200' || code == '0';
    return false;
  }

  /// 创建成功结果
  HttpResultN _createSuccessResult(dynamic data, dynamic code, String? message) {
    if (data is List) {
      return HttpResultN(
        isSuccess: true,
        code: _parseIntCode(code),
        msg: message ?? 'Success',
        listJson: data,
      );
    } else {
      return HttpResultN(
        isSuccess: true,
        code: _parseIntCode(code),
        msg: message ?? 'Success',
        dataJson: data,
      );
    }
  }

  /// 解析响应数据
  Map<String, dynamic> _parseResponseData(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is String) {
      return json.decode(data) as Map<String, dynamic>;
    } else {
      throw FormatException('Unsupported response data type: ${data.runtimeType}');
    }
  }

  /// 提取字段值
  dynamic _extractValue(Map<String, dynamic> jsonMap, List<String> keys) {
    for (final key in keys) {
      if (jsonMap.containsKey(key)) {
        return jsonMap[key];
      }
    }
    return null;
  }

  /// 解析整数状态码
  int _parseIntCode(dynamic code) {
    if (code is int) return code;
    if (code is String) return int.tryParse(code) ?? 200;
    return 200;
  }

  /// 获取HTTP状态码错误消息
  String _getHttpStatusMessage(int? statusCode) {
    switch (statusCode) {
      case 400: return 'Bad Request';
      case 401: return 'Unauthorized';
      case 403: return 'Forbidden';
      case 404: return 'Not Found';
      case 500: return 'Internal Server Error';
      case 502: return 'Bad Gateway';
      case 503: return 'Service Unavailable';
      default: return 'HTTP Error: $statusCode';
    }
  }

  /// 处理Dio错误
  HttpResultN _handleDioError(DioException e) {
    if (e.response != null) {
      try {
        final jsonMap = _parseResponseData(e.response!.data);
        final message = _extractValue(jsonMap, ['message', 'msg', 'error']);
        
        return HttpResultN(
          isSuccess: false,
          code: e.response!.statusCode ?? -1,
          msg: message?.toString() ?? 'Server Error',
        );
      } catch (_) {
        return HttpResultN(
          isSuccess: false,
          code: e.response!.statusCode ?? -1,
          msg: 'HTTP ${e.response!.statusCode}: ${e.response!.statusMessage ?? 'Unknown error'}',
        );
      }
    }

    // 网络层错误
    return HttpResultN(
      isSuccess: false,
      code: _getDioErrorCode(e.type),
      msg: _getDioErrorMessage(e),
    );
  }

  /// 获取Dio错误码
  int _getDioErrorCode(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout: return -1001;
      case DioExceptionType.sendTimeout: return -1002;
      case DioExceptionType.receiveTimeout: return -1003;
      case DioExceptionType.cancel: return -1004;
      case DioExceptionType.connectionError: return -1005;
      case DioExceptionType.badCertificate: return -1006;
      case DioExceptionType.badResponse: return -1007;
      case DioExceptionType.unknown: return -1000;
    }
  }

  /// 获取Dio错误消息
  String _getDioErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout - Please check your network';
      case DioExceptionType.sendTimeout:
        return 'Send timeout - Request took too long';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout - Server response took too long';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.connectionError:
        return 'Network connection error - Please check your internet';
      case DioExceptionType.badCertificate:
        return 'SSL certificate error - Secure connection failed';
      case DioExceptionType.badResponse:
        return 'Bad response format from server';
      case DioExceptionType.unknown:
        return e.message ?? 'Unknown network error occurred';
    }
  }

  /// 显示消息提示
  void _showMessage(String message, {bool isError = true}) {
    try {
      gg.Get.snackbar(
        isError ? '错误' : '提示',
        message,
        backgroundColor: isError 
            ? gg.Get.theme.colorScheme.error.withOpacity(0.1)
            : gg.Get.theme.colorScheme.primary.withOpacity(0.1),
        colorText: isError 
            ? gg.Get.theme.colorScheme.error
            : gg.Get.theme.colorScheme.primary,
        snackPosition: gg.SnackPosition.TOP,
        duration: Duration(seconds: isError ? 4 : 3), // 错误消息显示更久
        margin: EdgeInsets.all(16),
        borderRadius: 8,
        icon: Icon(
          isError ? Icons.warning_amber_rounded : Icons.info_outline,
          color: isError 
              ? gg.Get.theme.colorScheme.error
              : gg.Get.theme.colorScheme.primary,
        ),
      );
    } catch (e) {
      print('显示消息失败: $e, 消息内容: $message');
    }
  }
}
