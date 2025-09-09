import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

/// 签名工具类
/// 提供请求签名相关的功能
class SignatureUtils {
  /// 生成请求签名
  ///
  /// [options] 请求配置
  /// [secretKey] 签名密钥
  /// [timestamp] 时间戳
  static String generateSignature({
    required RequestOptions options,
    String secretKey = 'your_secret_key', // 替换为实际的密钥
    int? timestamp,
  }) {
    timestamp ??= DateTime.now().millisecondsSinceEpoch;

    // 构建签名字符串
    final signString = _buildSignString(options, timestamp, secretKey);

    // 生成 MD5 签名
    return _generateMD5(signString);
  }

  /// 构建签名字符串
  static String _buildSignString(
    RequestOptions options,
    int timestamp,
    String secretKey,
  ) {
    final method = options.method.toUpperCase();
    final path = options.path;

    // 获取查询参数
    final queryParams = options.queryParameters;
    final sortedQueryString = _buildSortedQueryString(queryParams);

    // 获取请求体参数
    String bodyString = '';
    if (options.data != null) {
      if (options.data is Map) {
        bodyString = _buildSortedQueryString(
          options.data as Map<String, dynamic>,
        );
      } else if (options.data is String) {
        bodyString = options.data as String;
      }
    }

    // 构建最终的签名字符串
    // 格式：METHOD|PATH|QUERY|BODY|TIMESTAMP|SECRET_KEY
    final parts = [
      method,
      path,
      sortedQueryString,
      bodyString,
      timestamp.toString(),
      secretKey,
    ];

    return parts.join('|');
  }

  /// 构建排序后的查询字符串
  static String _buildSortedQueryString(Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) {
      return '';
    }

    // 按照 key 排序
    final sortedKeys = params.keys.toList()..sort();

    final parts = <String>[];
    for (final key in sortedKeys) {
      final value = params[key];
      if (value != null) {
        parts.add('$key=$value');
      }
    }

    return parts.join('&');
  }

  /// 生成 MD5 哈希
  static String _generateMD5(String input) {
    final bytes = utf8.encode(input);
    final digest = md5.convert(bytes);
    return digest.toString().toLowerCase();
  }

  /// 生成 SHA256 哈希（备选方案）
  static String generateSHA256(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString().toLowerCase();
  }

  /// 验证签名（用于服务端验证，客户端通常不需要）
  static bool verifySignature({
    required String signature,
    required RequestOptions options,
    String secretKey = 'your_secret_key',
    int? timestamp,
  }) {
    final expectedSignature = generateSignature(
      options: options,
      secretKey: secretKey,
      timestamp: timestamp,
    );

    return signature.toLowerCase() == expectedSignature.toLowerCase();
  }

  /// 为请求添加时间戳（防重放攻击）
  static void addTimestamp(RequestOptions options) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    options.headers['timestamp'] = timestamp.toString();
  }

  /// 为请求添加随机数（增强安全性）
  static void addNonce(RequestOptions options) {
    final nonce = _generateNonce();
    options.headers['nonce'] = nonce;
  }

  /// 生成随机数
  static String _generateNonce() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return (timestamp + random).toString();
  }
}
