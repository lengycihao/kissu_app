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
      // 放宽 ALPN/协议配置，避免部分设备在二次启动后因握手协商失败导致 unknown/handshake 错误
      // 允许常见 TLS 版本，交由系统协商最佳协议
      try {
        securityContext.setAlpnProtocols(['h2', 'http/1.1'], true);
      } catch (_) {
        // 某些 ROM 不支持设置 ALPN，忽略即可
      }
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

          if (value.isNotEmpty) {
            try {
              final file = File(value);
              if (!await file.exists()) {
                continue; // 文件不存在，跳过
              }
              
              // 获取文件扩展名
              final fileName = file.path.split(Platform.pathSeparator).last;
              final isImage = RegexUtil.isLocalImagePath(value);
              
              if (isImage) {
                // 图片文件：根据大小决定是否压缩
                final fileSize = await file.length();
                
                // 🔧 优化：对于小文件（< 500KB）或应用图标（512x512），不压缩或使用高质量
                // 应用图标通常是 512x512 的 PNG，文件大小通常在 50-200KB 之间
                if (fileSize < 500 * 1024) {
                  // 小文件直接上传，不压缩，保持原始质量
                  final bytes = await file.readAsBytes();
                  map[key] = MultipartFile.fromBytes(bytes, filename: fileName);
                } else {
                  // 大文件才压缩
                  Uint8List? stream = await FlutterImageCompress.compressWithFile(
                    value,
                    minWidth: 1000,
                    minHeight: 1000,
                    quality: 80,
                  );

                  //传入压缩之后的流对象
                  if (stream != null) {
                    map[key] = MultipartFile.fromBytes(stream, filename: fileName);
                  }
                }
              } else {
                // 非图片文件：直接上传，不压缩
                final bytes = await file.readAsBytes();
                map[key] = MultipartFile.fromBytes(bytes, filename: fileName);
              }
            } catch (e) {
              // 如果是图片且读取失败，尝试压缩
              if (RegexUtil.isLocalImagePath(value)) {
                Uint8List? stream = await FlutterImageCompress.compressWithFile(
                  value,
                  minWidth: 1000,
                  minHeight: 1000,
                  quality: 80,
                );

                if (stream != null) {
                  final fileName = value.split(Platform.pathSeparator).last;
                  map[key] = MultipartFile.fromBytes(stream, filename: fileName);
                }
              }
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
            // 🔧 优化：对于小文件（< 500KB，通常是应用图标），不压缩，保持原始质量
            if (value.length < 500 * 1024) {
              // 小文件直接上传，不压缩
              map[key] = MultipartFile.fromBytes(value, filename: "file.png");
            } else {
              // 大文件才压缩
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
