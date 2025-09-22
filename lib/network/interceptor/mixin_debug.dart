import 'package:dio/dio.dart';

mixin InterceptorDebugPrint on Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // debugPrint('$runtimeType onRequest');
    super.onRequest(options, handler);
  }
}
