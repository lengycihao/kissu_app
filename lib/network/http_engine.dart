import 'dart:convert';
import 'dart:io';
import 'package:dio/io.dart';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/foundation.dart';
import 'package:kissu_app/network/tools/cons/network_constants.dart';
import 'package:kissu_app/network/utils/regex_util.dart';
import 'enum/cache_control.dart';
import 'utils/log_util.dart';

class HttpEngine {
  late Dio dio;
  static String _proxy = "";
  //设置代理
  static void setProxy(String proxy) {
    _proxy = proxy;
  }

  HttpEngine(
    String? baseUrl,
    List<Interceptor>? interceptors, {
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
  }) {
    /// 网络配置
    final options = BaseOptions(
      baseUrl: baseUrl ?? NetworkConstants.baseUrl,
      connectTimeout: connectTimeout ?? const Duration(seconds: 30),
      sendTimeout: sendTimeout ?? const Duration(seconds: 30),
      receiveTimeout: receiveTimeout ?? const Duration(seconds: 30),
      validateStatus: (code) {
        if (code == 200 || code == 401 || code == 422 || code == 429) {
          return true;
        } else {
          return false;
        }
      },
    );

    dio = Dio(options);

    // 设置Dio的转换器
    dio.transformer = BackgroundTransformer(); //Json后台线程处理优化（可选）

    // 设置Dio的拦截器 - 使用传入的拦截器列表
    if (interceptors != null) {
      for (var interceptor in interceptors) {
        dio.interceptors.add(interceptor);
      }
    }
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      SecurityContext securityContext = SecurityContext();
      securityContext.setAlpnProtocols(['TLSv1.3'], true);
      HttpClient httpClient = HttpClient(context: securityContext);
      if (kDebugMode && _proxy.isNotEmpty) {
        httpClient.findProxy = (uri) {
          //proxy all request to localhost:8888
          return "PROXY ${_proxy}";
        };
      }

      httpClient.badCertificateCallback = (cert, host, port) {
        return true; // 返回true强制通过
      };
      return httpClient;
    };
    // 日志打印不全
    // if (kDebugMode) {
    //   dio.interceptors
    //       .add(LogInterceptor(requestBody: true, responseBody: true));
    // }
  }

  /// 网络请求 Post 请求
  Future<Response> executePost({
    required String url,
    Map<String, dynamic>? jsonParams,
    Map<String, dynamic>? formParam,
    Map<String, String>? paths, //文件
    Map<String, Uint8List>? pathStreams, //文件流
    Map<String, String>? headers,
    ProgressCallback? send, // 上传进度监听
    ProgressCallback? receive, // 下载监听
    CancelToken? cancelToken, // 用于取消的 token，可以多个请求绑定一个 token
  }) async {
    String? generateJsonData() {
      if (jsonParams == null) {
        return null;
      } else {
        return jsonEncode(jsonParams);
      }
    }

    Future<FormData?> generateFormData() async {
      if (formParam == null && paths == null && pathStreams == null)
        return null;

      final Map<String, dynamic> map = {};

      //表单参数
      if (formParam != null) {
        map.addAll(formParam);
      }

      //File文件
      if (paths != null && paths.isNotEmpty) {
        for (final entry in paths.entries) {
          final key = entry.key;
          final value = entry.value;

          if (value.isNotEmpty && RegexUtil.isLocalImagePath(value)) {
            // 以文件的方式压缩，获取到流对象
            Uint8List? stream = await FlutterImageCompress.compressWithFile(
              value,
              minWidth: 1000,
              minHeight: 1000,
              quality: 80,
            );

            //传入压缩之后的流对象
            if (stream != null) {
              map[key] = MultipartFile.fromBytes(stream, filename: "file");
            }
          }
        }
      }

      //File文件流
      if (pathStreams != null && pathStreams.isNotEmpty) {
        for (final entry in pathStreams.entries) {
          final key = entry.key;
          final value = entry.value;

          if (value.isNotEmpty) {
            // 以流方式压缩，获取到流对象
            Uint8List stream = await FlutterImageCompress.compressWithList(
              value,
              minWidth: 1000,
              minHeight: 1000,
              quality: 80,
            );

            //传入压缩之后的流对象
            map[key] = MultipartFile.fromBytes(stream, filename: "file_stream");
          }
        }
      }
      return FormData.fromMap(map);
    }

    final data = generateJsonData() ?? await generateFormData();

    return dio.post(
      url,
      data: data,
      options: Options(headers: headers),
      onSendProgress: send,
      onReceiveProgress: receive,
      cancelToken: cancelToken,
    );
  }

  /// 网络请求 Get 请求
  Future<Response> executeGet({
    required String url,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CacheControl? cacheControl,
    Duration? cacheExpiration,
    ProgressCallback? receive, // 请求进度监听
    CancelToken? cancelToken, // 用于取消的 token，可以多个请求绑定一个 token
  }) {
    return dio.get(
      url,
      queryParameters: queryParams,
      options: Options(headers: headers),
      onReceiveProgress: receive,
      cancelToken: cancelToken,
    );
  }

  /// 网络请求 PUT 请求
  Future<Response> executePut({
    required String url,
    Map<String, dynamic>? jsonParams,
    Map<String, dynamic>? formParam,
    Map<String, String>? headers,
    ProgressCallback? send, // 上传进度监听
    ProgressCallback? receive, // 下载监听
    CancelToken? cancelToken, // 用于取消的 token，可以多个请求绑定一个 token
  }) async {
    String? generateJsonData() {
      if (jsonParams == null) {
        return null;
      } else {
        return jsonEncode(jsonParams);
      }
    }

    FormData? generateFormData() {
      if (formParam == null) return null;
      return FormData.fromMap(formParam);
    }

    final data = generateJsonData() ?? generateFormData();

    return dio.put(
      url,
      data: data,
      options: Options(headers: headers),
      onSendProgress: send,
      onReceiveProgress: receive,
      cancelToken: cancelToken,
    );
  }

  /// 网络请求 DELETE 请求
  Future<Response> executeDelete({
    required String url,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? jsonParams,
    Map<String, String>? headers,
    CancelToken? cancelToken, // 用于取消的 token，可以多个请求绑定一个 token
  }) async {
    dynamic data;
    if (jsonParams != null) {
      data = jsonEncode(jsonParams);
    }

    return dio.delete(
      url,
      data: data,
      queryParameters: queryParams,
      options: Options(headers: headers),
      cancelToken: cancelToken,
    );
  }

  /// 网络请求 PATCH 请求
  Future<Response> executePatch({
    required String url,
    Map<String, dynamic>? jsonParams,
    Map<String, dynamic>? formParam,
    Map<String, String>? headers,
    ProgressCallback? send, // 上传进度监听
    ProgressCallback? receive, // 下载监听
    CancelToken? cancelToken, // 用于取消的 token，可以多个请求绑定一个 token
  }) async {
    String? generateJsonData() {
      if (jsonParams == null) {
        return null;
      } else {
        return jsonEncode(jsonParams);
      }
    }

    FormData? generateFormData() {
      if (formParam == null) return null;
      return FormData.fromMap(formParam);
    }

    final data = generateJsonData() ?? generateFormData();

    return dio.patch(
      url,
      data: data,
      options: Options(headers: headers),
      onSendProgress: send,
      onReceiveProgress: receive,
      cancelToken: cancelToken,
    );
  }

  /// Dio 网络下载
  Future<void> downloadFile({
    required String url,
    required String savePath,
    ProgressCallback? receive, // 下载进度监听
    CancelToken? cancelToken, // 用于取消的 token，可以多个请求绑定一个 token
    void Function(bool success, String path)? callback, // 下载完成回调函数
  }) async {
    try {
      await dio.download(
        url,
        savePath,
        onReceiveProgress: receive,
        cancelToken: cancelToken,
      );
      // 下载成功
      callback?.call(true, savePath);
    } on DioException catch (e) {
      Log.e("DioException：$e");
      // 下载失败
      callback?.call(false, savePath);
    }
  }
}
