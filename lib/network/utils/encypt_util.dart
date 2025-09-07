import 'dart:convert';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

class EncryptUtil {
  static String encodeMd5(String data) {
    var content = const Utf8Encoder().convert(data);
    var digest = md5.convert(content);
    return hex.encode(digest.bytes);
  }

  static String xorCode(String res, String key) {
    List<String> keyList = key.split(',');
    List<int> codeUnits = res.codeUnits;
    List<int> codes = [];
    for (int i = 0, length = codeUnits.length; i < length; i++) {
      int code = codeUnits[i] ^ int.parse(keyList[i % keyList.length]);
      codes.add(code);
    }
    return String.fromCharCodes(codes);
  }

  static String xorBase64Encode(String res, String key) {
    String encode = xorCode(res, key);
    encode = encodeBase64(encode);
    return encode;
  }

  static String xorBase64Decode(String res, String key) {
    String encode = decodeBase64(res);
    encode = xorCode(encode, key);
    return encode;
  }

  static String encodeBase64(String data) {
    var content = utf8.encode(data);
    var digest = base64Encode(content);
    return digest;
  }

  static String decodeBase64(String data) {
    List<int> bytes = base64Decode(data);
    String result = utf8.decode(bytes);
    return result;
  }

  static String zipEncode(String str) {
    List<int> stringBytes = utf8.encode(str);
    List<int> gzipBytes = gzip.encode(stringBytes);
    String compressedString = base64UrlEncode(gzipBytes);
    String encodedString = Uri.encodeComponent(compressedString);
    return encodedString;
  }

  static String zipDecode(String str) {
    String decodedString = Uri.decodeComponent(str);
    List<int> stringBytes = base64Url.decode(decodedString);
    List<int> gzipBytes = gzip.decode(stringBytes);
    String compressedString = utf8.decode(gzipBytes);
    return compressedString;
  }
}
