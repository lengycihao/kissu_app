import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart' as gg;
import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/network/public/auth_service.dart';
import 'package:get_it/get_it.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';

/// API响应拦截器
/// 处理统一的响应格式和错误处理
class ApiResponseInterceptor extends Interceptor {
  // 防重复弹窗机制
  static bool _isHandlingUnauthorized = false;
  static DateTime? _lastUnauthorizedTime;
  
  /// 重置token失效处理状态（应用启动时调用）
  static void resetUnauthorizedState() {
    _isHandlingUnauthorized = false;
    _lastUnauthorizedTime = null;
    print('token失效处理状态已重置');
  }
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    try {
      // 🔍 打印原始响应body数据（用于调试）
      // print('🔍 原始响应URL: ${response.requestOptions.uri}');
      // print('🔍 原始响应状态码: ${response.statusCode}');
      // print('🔍 原始响应Headers: ${response.headers}');
      // print('🔍 原始响应Body: ${response.data}');
      // print('🔍 原始响应Body类型: ${response.data.runtimeType}');
      
      // 移除HTTP状态码401的特殊处理，只通过业务错误码43000来判断token失效

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
            _handleTokenExpired(message);
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
            // 其他错误码不做特殊处理，让上层业务处理
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
    // 将网络错误转换为统一格式，不再处理401等HTTP状态码的特殊逻辑
    // 只有业务层面的43000错误码才会触发退出登录
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

  /// 处理token失效（防重复弹窗）
  void _handleTokenExpired(String message) {
    final now = DateTime.now();
    
    print('⚠️ Token失效处理开始: $message');
    print('📊 当前处理状态: _isHandlingUnauthorized=$_isHandlingUnauthorized');
    print('⏰ 上次处理时间: $_lastUnauthorizedTime');
    
    // 检查是否正在处理中
    if (_isHandlingUnauthorized) {
      print('⏸️ 正在处理token失效，跳过重复处理');
      return;
    }
    
    // 检查距离上次处理是否太近（10秒内不重复处理，防止并发请求重复触发）
    if (_lastUnauthorizedTime != null && 
        now.difference(_lastUnauthorizedTime!) < const Duration(seconds: 10)) {
      final timeDiff = now.difference(_lastUnauthorizedTime!).inSeconds;
      print('⏸️ 距离上次token失效处理太近（${timeDiff}秒），跳过重复处理');
      return;
    }
    
    // 标记正在处理并记录时间
    _isHandlingUnauthorized = true;
    _lastUnauthorizedTime = now;
    
    print('🚀 开始执行token失效处理流程...');
    
    // 显示消息
    _showMessage(message);
    
    // 处理未授权
    _handleUnauthorized();
  }

  /// 处理未授权错误
  void _handleUnauthorized() async {
    print('🔐 检测到token过期，开始清除用户数据并跳转到登录页');

    try {
      // 直接清除本地用户数据，不调用退出登录API（因为token已失效）
      final authService = GetIt.instance<AuthService>();
      await authService.clearLocalUserData();
      print('✅ 本地用户数据已清除');
    } catch (e) {
      print('❌ 清除用户信息失败: $e');
      // 备用清除方式 - 直接删除存储的用户数据
      try {
        const storage = FlutterSecureStorage();
        await storage.delete(key: 'current_user');
        print('✅ 备用清除方式成功');
      } catch (fallbackError) {
        print('❌ 备用清除方式也失败: $fallbackError');
      }
    }

    // 跳转到登录页
    try {
      print('🔄 准备跳转到登录页...');
      
      // 检查Get路由是否已经初始化
      if (gg.Get.isRegistered<gg.GetMaterialController>()) {
        gg.Get.offAllNamed(KissuRoutePath.login);
        print('✅ 已成功跳转到登录页');
      } else {
        print('⚠️ Get路由尚未初始化，延迟跳转...');
        // 延迟跳转，等待Get路由初始化完成
        Future.delayed(const Duration(milliseconds: 500), () {
          try {
            gg.Get.offAllNamed(KissuRoutePath.login);
            print('✅ 延迟跳转到登录页成功');
          } catch (delayedError) {
            print('❌ 延迟跳转也失败: $delayedError');
            _tryFallbackNavigation();
          }
        });
      }
    } catch (e) {
      print('❌ 导航到登录页失败: $e');
      _tryFallbackNavigation();
    }
    
    // 延迟重置处理状态，确保跳转完成
    Future.delayed(const Duration(seconds: 2), () {
      _isHandlingUnauthorized = false;
      print('🔄 token失效处理状态已重置');
    });
  }

  /// 尝试备用跳转方式
  void _tryFallbackNavigation() {
    print('🔧 尝试备用跳转方式...');
    
    // 尝试多种跳转方式
    final fallbackRoutes = ['/login', KissuRoutePath.login];
    
    for (final route in fallbackRoutes) {
      try {
        gg.Get.offAllNamed(route);
        print('✅ 备用跳转方式成功: $route');
        return;
      } catch (e) {
        print('❌ 备用跳转失败 ($route): $e');
      }
    }
    
    print('🚨 所有跳转方式都失败了，将在应用下次启动时重定向到登录页');
  }

  /// 处理API响应
  HttpResultN _processApiResponse(Response response) {
    // 检查HTTP状态码
    if (!_isHttpStatusValid(response.statusCode)) {
      // 对于500错误，检查是否返回了HTML错误页面
      if (response.statusCode == 500) {
        String errorMsg = '服务器内部错误';
        if (response.data is String && response.data.toString().contains('<!DOCTYPE html>')) {
          errorMsg = '服务器发生错误，请稍后重试';
          print('🚨 服务器返回HTML错误页面，状态码: ${response.statusCode}');
        }
        return HttpResultN(
          isSuccess: false,
          code: response.statusCode ?? -1,
          msg: errorMsg,
        );
      }
      
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
      // 检查是否是HTML错误页面（通常是服务器500错误）
      if (response.data is String && response.data.toString().contains('<!DOCTYPE html>')) {
        return HttpResultN(
          isSuccess: false,
          code: response.statusCode ?? 500,
          msg: '服务器发生错误~',
        );
      }
      
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
  HttpResultN _createSuccessResult(
    dynamic data,
    dynamic code,
    String? message,
  ) {
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
      try {
        // 添加详细的JSON解析错误处理
        if (data.isEmpty) {
          throw FormatException('Empty JSON string');
        }
        
        // 检查JSON字符串是否包含常见的格式问题
        final trimmedData = data.trim();
        if (!trimmedData.startsWith('{') && !trimmedData.startsWith('[')) {
          throw FormatException('Invalid JSON format: does not start with { or [');
        }
        
        // 尝试解析JSON
        final result = json.decode(trimmedData);
        if (result is Map<String, dynamic>) {
          return result;
        } else {
          throw FormatException('JSON decoded to ${result.runtimeType}, expected Map<String, dynamic>');
        }
      } catch (e) {
        // 记录详细的错误信息和原始数据
        print('🚨 JSON解析失败:');
        print('📝 原始数据长度: ${data.length}');
        print('📝 原始数据前100字符: ${data.length > 100 ? data.substring(0, 100) + '...' : data}');
        print('📝 错误详情: $e');
        
        // 尝试修复常见的JSON问题
        try {
          final fixedData = _tryFixJsonString(data);
          if (fixedData != data) {
            print('🔧 尝试修复JSON后重新解析...');
            final result = json.decode(fixedData);
            if (result is Map<String, dynamic>) {
              return result;
            }
          }
        } catch (fixError) {
          print('🚫 JSON修复也失败了: $fixError');
        }
        
        throw FormatException(
          'Failed to parse JSON response: $e. Data preview: ${data.length > 50 ? data.substring(0, 50) + '...' : data}',
        );
      }
    } else {
      throw FormatException(
        'Unsupported response data type: ${data.runtimeType}',
      );
    }
  }
  
  /// 尝试修复常见的JSON字符串问题
  String _tryFixJsonString(String jsonString) {
    String fixed = jsonString.trim();
    
    // 修复常见的转义问题
    fixed = fixed.replaceAll('\\"', '"');
    fixed = fixed.replaceAll('\\n', '\n');
    fixed = fixed.replaceAll('\\r', '\r');
    fixed = fixed.replaceAll('\\t', '\t');
    
    // 移除可能的BOM标记
    if (fixed.startsWith('\uFEFF')) {
      fixed = fixed.substring(1);
    }
    
    // 修复可能的编码问题
    if (fixed.contains('\\u')) {
      try {
        fixed = fixed.replaceAllMapped(
          RegExp(r'\\u([0-9a-fA-F]{4})'),
          (match) => String.fromCharCode(int.parse(match.group(1)!, radix: 16)),
        );
      } catch (e) {
        print('修复Unicode转义失败: $e');
      }
    }
    
    return fixed;
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
      case 400:
        return 'Bad Request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not Found';
      case 500:
        return 'Internal Server Error';
      case 502:
        return 'Bad Gateway';
      case 503:
        return 'Service Unavailable';
      default:
        return 'HTTP Error: $statusCode';
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
          msg:
              'HTTP ${e.response!.statusCode}: ${e.response!.statusMessage ?? 'Unknown error'}',
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
      case DioExceptionType.connectionTimeout:
        return -1001;
      case DioExceptionType.sendTimeout:
        return -1002;
      case DioExceptionType.receiveTimeout:
        return -1003;
      case DioExceptionType.cancel:
        return -1004;
      case DioExceptionType.connectionError:
        return -1005;
      case DioExceptionType.badCertificate:
        return -1006;
      case DioExceptionType.badResponse:
        return -1007;
      case DioExceptionType.unknown:
        return -1000;
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
        // 🔍 详细记录 unknown 错误信息，帮助定位问题
        // 使用 debugPrint 确保在 Release 版本中也能输出关键错误信息
        debugPrint('🔍 [Unknown Network Error] 详细信息:');
        debugPrint('  📍 请求地址: ${e.requestOptions.uri}');
        debugPrint('  📡 请求方法: ${e.requestOptions.method}');
        debugPrint('  📋 请求头: ${e.requestOptions.headers}');
        debugPrint('  💬 错误消息: ${e.message}');
        debugPrint('  🔧 错误类型: ${e.error?.runtimeType}');
        debugPrint('  📊 错误对象: ${e.error}');
        
        // 如果有响应，记录响应状态
        if (e.response != null) {
          debugPrint('  📥 响应状态码: ${e.response?.statusCode}');
          debugPrint('  📥 响应消息: ${e.response?.statusMessage}');
        }
        
        // 记录堆栈跟踪（仅关键部分）
        final stackLines = e.stackTrace.toString().split('\n').take(5).join('\n');
        debugPrint('  📋 堆栈跟踪（前5行）:\n$stackLines');
        
        // 根据错误消息内容返回更友好的提示
        final errorMsg = e.message?.toLowerCase() ?? '';
        final errorObj = e.error?.toString().toLowerCase() ?? '';
        
        if (errorMsg.contains('connection') || errorMsg.contains('connect') || 
            errorObj.contains('connection') || errorObj.contains('connect')) {
          return '网络连接异常，请检查网络状态';
        } else if (errorMsg.contains('timeout') || errorObj.contains('timeout')) {
          return '网络请求超时，请稍后重试';
        } else if (errorMsg.contains('certificate') || errorMsg.contains('ssl') ||
                   errorObj.contains('certificate') || errorObj.contains('ssl') ||
                   errorObj.contains('handshake')) {
          return '网络安全验证失败，请稍后重试';
        } else if (errorMsg.contains('socket') || errorObj.contains('socket')) {
          return '网络连接中断，请检查网络后重试';
        } else if (errorMsg.contains('host') || errorObj.contains('host')) {
          return '无法连接到服务器，请检查网络';
        } else if (errorMsg.contains('refused') || errorObj.contains('refused')) {
          return '服务器拒绝连接，请稍后重试';
        } else if (errorMsg.contains('reset') || errorObj.contains('reset')) {
          return '网络连接被重置，请重试';
        }
        
        // 返回更友好的通用错误消息，包含部分原始错误信息便于调试
        final shortError = e.message != null && e.message!.length > 50 
            ? '${e.message!.substring(0, 50)}...' 
            : e.message ?? '未知错误';
        debugPrint('  ⚠️ 返回给用户的错误消息: 网络请求异常');
        debugPrint('  🔍 实际错误: $shortError');
        return '$shortError网络请求异常，请检查网络后重试';
    }
  }

  /// 显示消息提示
  void _showMessage(String message) {
    try {
      CustomToast.show(
        gg.Get.context!,
        message,
      );
    } catch (e) {
      debugPrint('显示消息失败: $e, 消息内容: $message');
    }
  }
}
