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
  static String generateSignature({
    required RequestOptions options,
    String secretKey = 'TYXHTRrGeP8xy095q0iY', // 正确的签名密钥
  }) {
    // 构建签名字符串
    final signString = _buildSignString(options, secretKey);

    // 生成 MD5 签名并转为大写
    return _generateMD5(signString).toUpperCase();
  }

  /// 构建签名字符串
  /// 按照指定规则：合并header和参数，按ASCII排序，拼接key
  static String _buildSignString(
    RequestOptions options,
    String secretKey,
  ) {
    // 收集所有参数（header + query + body）
    final allParams = <String, dynamic>{};
    
    // 1. 添加 header 参数（排除一些系统header）
    final headers = options.headers;
    headers.forEach((key, value) {
      // 只包含业务相关的header，排除系统header
      if (_isBusinessHeader(key)) {
        allParams[key] = value?.toString() ?? '';
      }
    });
    
    // 2. 添加查询参数
    final queryParams = options.queryParameters;
    queryParams.forEach((key, value) {
      allParams[key] = value?.toString() ?? '';
    });
    
    // 3. 添加请求体参数
    if (options.data != null && options.data is Map) {
      final bodyParams = options.data as Map<String, dynamic>;
      bodyParams.forEach((key, value) {
        allParams[key] = value?.toString() ?? '';
      });
    }
    
    // 4. 按键名ASCII升序排序
    final sortedKeys = allParams.keys.toList()..sort();
    
    // 5. 拼接参数：value1value2value3...（只拼接值，不拼接键）
    final buffer = StringBuffer();
    for (final key in sortedKeys) {
      final value = allParams[key];
      buffer.write(value);
    }
    
    // 6. 拼接签名key
    buffer.write(secretKey);
    
    return buffer.toString();
  }
  
  /// 判断是否为业务相关的header
  static bool _isBusinessHeader(String key) {
    // 包含的业务header
    const businessHeaders = {
      'channel',
      'version', 
      'deviceid',
      'pkg',
      'token',
      'userid',
    };
    
    // 排除的系统header
    const systemHeaders = {
      'content-type',
      'content-length',
      'user-agent',
      'accept',
      'accept-encoding',
      'connection',
      'host',
      'timestamp',
      'nonce',
      'sign', // 排除sign本身
    };
    
    final lowerKey = key.toLowerCase();
    
    // 如果是明确的业务header，包含
    if (businessHeaders.contains(lowerKey)) {
      return true;
    }
    
    // 如果是系统header，排除
    if (systemHeaders.contains(lowerKey)) {
      return false;
    }
    
    // 其他情况默认包含
    return true;
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
    return digest.toString(); // 保持原始格式，在外层转换大写
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
    String secretKey = 'TYXHTRrGeP8xy095q0iY',
  }) {
    final expectedSignature = generateSignature(
      options: options,
      secretKey: secretKey,
    );

    return signature.toUpperCase() == expectedSignature.toUpperCase();
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
  
  /// 测试签名生成（用于验证算法正确性）
  /// 使用提供的示例数据进行测试
  static String testSignatureGeneration() {
    // 创建模拟的 RequestOptions
    final options = RequestOptions(
      path: '/api/login',
      method: 'POST',
      headers: {
        'channel': 'kissu_ios',
        'version': '1.0.0',
        'deviceid': '22101317C',
        'pkg': 'com.xxx.yyy',
      },
      data: {
        'captcha': '632021',
        'phone': '15267477179',
      },
    );
    
    // 生成签名
    final signature = generateSignature(options: options);
    
    // 输出调试信息
    print('=== 签名生成测试 ===');
    print('Header参数: ${options.headers}');
    print('Body参数: ${options.data}');
    
    // 手动构建签名字符串用于验证
    final allParams = <String, String>{
      'captcha': '632021',
      'channel': 'kissu_ios',
      'deviceid': '22101317C',
      'phone': '15267477179',
      'pkg': 'com.xxx.yyy',
      'version': '1.0.0',
    };
    
    final sortedKeys = allParams.keys.toList()..sort();
    final signString = sortedKeys.map((key) => allParams[key]).join('') + 'TYXHTRrGeP8xy095q0iY';
    
    print('排序后的参数: $sortedKeys');
    print('拼接字符串: $signString');
    print('生成的签名: $signature');
    print('==================');
    
    return signature;
  }
}
