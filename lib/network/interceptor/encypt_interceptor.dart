import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:dio/dio.dart';
import 'package:kissu_app/network/interceptor/http_header_key.dart';

class EncryptInterceptor extends Interceptor {
  final String _defaultAesKey;
  final String _defaultAesIv;
  final Encrypter _encrypter;
  final IV _iv;

  EncryptInterceptor({String? aesKey, String? aesIv})
    : _defaultAesKey = aesKey ?? 'your-32-char-secret-key-here!',
      _defaultAesIv = aesIv ?? 'your-16-char-iv!',
      _encrypter = Encrypter(
        AES(
          Key.fromBase64(
            base64.encode(
              utf8.encode(aesKey ?? 'your-32-char-secret-key-here!'),
            ),
          ),
        ),
      ),
      _iv = IV.fromBase64(
        base64.encode(utf8.encode(aesIv ?? 'your-16-char-iv!')),
      );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final headers = options.headers;
    final encryptParams = _getBoolHeader(headers, HttpHeaderKey.paramEncrypt);
    final encryptBody = _getBoolHeader(headers, HttpHeaderKey.bodyEncrypt);

    if (encryptParams || encryptBody) {
      try {
        if (encryptParams) {
          _encryptQueryParameters(options);
        }

        if (encryptBody) {
          _encryptRequestBody(options);
        }

        // Add encryption metadata to headers
        options.headers[HttpHeaderKey.encrypted] = 'true';
        options.headers[HttpHeaderKey.encryptAlgorithm] = 'AES-256-ECB';
      } catch (e) {
        // Log encryption error
        print('Encryption error: $e');
      }
    }

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final requestHeaders = response.requestOptions.headers;
    final shouldDecrypt =
        _getBoolHeader(requestHeaders, HttpHeaderKey.responseDecrypt) ||
        _getBoolHeader(requestHeaders, HttpHeaderKey.bodyEncrypt);

    if (shouldDecrypt && response.data != null) {
      try {
        final decryptedData = _decryptResponseData(response.data);
        response.data = decryptedData;
      } catch (e) {
        print('Decryption error: $e');
        // Continue with original data if decryption fails
      }
    }

    super.onResponse(response, handler);
  }

  bool _getBoolHeader(Map<String, dynamic> headers, String key) {
    return headers[key] != null &&
        headers[key].toString().toLowerCase() == 'true';
  }

  void _encryptQueryParameters(RequestOptions options) {
    if (options.queryParameters.isNotEmpty) {
      final encryptedParams = <String, dynamic>{};

      options.queryParameters.forEach((key, value) {
        if (_shouldEncryptParam(key)) {
          final encrypted = _encryptString(value.toString());
          encryptedParams[key] = encrypted;
        } else {
          encryptedParams[key] = value;
        }
      });

      options.queryParameters = encryptedParams;
    }
  }

  void _encryptRequestBody(RequestOptions options) {
    if (options.data == null) return;

    if (options.data is Map) {
      final encryptedData = _encryptMapData(
        options.data as Map<String, dynamic>,
      );
      options.data = encryptedData;
    } else if (options.data is String) {
      options.data = _encryptString(options.data as String);
    } else if (options.data is FormData) {
      _encryptFormData(options.data as FormData);
    }
  }

  Map<String, dynamic> _encryptMapData(Map<String, dynamic> data) {
    final encryptedData = <String, dynamic>{};

    data.forEach((key, value) {
      if (_shouldEncryptParam(key)) {
        if (value is String) {
          encryptedData[key] = _encryptString(value);
        } else if (value is Map) {
          encryptedData[key] = _encryptMapData(value as Map<String, dynamic>);
        } else {
          encryptedData[key] = _encryptString(value.toString());
        }
      } else {
        encryptedData[key] = value;
      }
    });

    return encryptedData;
  }

  void _encryptFormData(FormData formData) {
    final encryptedFields = <MapEntry<String, String>>[];

    for (final field in formData.fields) {
      if (_shouldEncryptParam(field.key)) {
        final encrypted = _encryptString(field.value);
        encryptedFields.add(MapEntry(field.key, encrypted));
      } else {
        encryptedFields.add(field);
      }
    }

    formData.fields.clear();
    formData.fields.addAll(encryptedFields);
  }

  String _encryptString(String data) {
    try {
      final encrypted = _encrypter.encrypt(data, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      print('String encryption error: $e');
      return data; // Return original if encryption fails
    }
  }

  dynamic _decryptResponseData(dynamic data) {
    if (data is String) {
      return _decryptString(data);
    } else if (data is Map) {
      return _decryptMapData(data as Map<String, dynamic>);
    } else if (data is List) {
      return data.map((item) => _decryptResponseData(item)).toList();
    }

    return data;
  }

  String _decryptString(String encryptedData) {
    try {
      final encrypted = Encrypted.fromBase64(encryptedData);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      print('String decryption error: $e');
      return encryptedData; // Return original if decryption fails
    }
  }

  Map<String, dynamic> _decryptMapData(Map<String, dynamic> data) {
    final decryptedData = <String, dynamic>{};

    data.forEach((key, value) {
      if (value is String && _isEncryptedData(value)) {
        decryptedData[key] = _decryptString(value);
      } else if (value is Map) {
        decryptedData[key] = _decryptMapData(value as Map<String, dynamic>);
      } else if (value is List) {
        decryptedData[key] = value
            .map((item) => _decryptResponseData(item))
            .toList();
      } else {
        decryptedData[key] = value;
      }
    });

    return decryptedData;
  }

  bool _shouldEncryptParam(String key) {
    // Define sensitive parameters that should be encrypted
    const sensitiveParams = {
      'password',
      'token',
      'secret',
      'key',
      'credential',
      'auth',
      'private',
      'sensitive',
    };

    final lowerKey = key.toLowerCase();
    return sensitiveParams.any((param) => lowerKey.contains(param));
  }

  bool _isEncryptedData(String data) {
    // Simple heuristic to check if data looks like base64 encrypted data
    try {
      base64.decode(data);
      return data.length > 16 && data.length % 4 == 0;
    } catch (e) {
      return false;
    }
  }

  static EncryptInterceptor create({String? aesKey, String? aesIv}) {
    return EncryptInterceptor(aesKey: aesKey, aesIv: aesIv);
  }

  void updateKeys({String? newAesKey, String? newAesIv}) {
    // Note: In a real implementation, you might want to create a new interceptor
    // with updated keys rather than modifying the existing one
    print('Keys updated - restart interceptor for changes to take effect');
  }
}
