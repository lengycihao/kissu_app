import 'dart:io';
import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/network/http_managerN.dart';

class FileUploadApi {
  /// 上传文件
  /// [file] 要上传的文件
  /// 返回文件URL
  Future<HttpResultN<String>> uploadFile(File file) async {
    try {
      final result = await HttpManagerN.instance.executePost(
        '/file/upload',
        paths: {'file': file.path},
        paramEncrypt: false,
      );

      if (result.isSuccess) {
        final data = result.getDataJson();
        return HttpResultN<String>(
          isSuccess: true,
          code: result.code,
          msg: result.msg,
          data: data['file_url'],
        );
      } else {
        return HttpResultN<String>(
          isSuccess: false,
          code: result.code,
          msg: result.msg ?? '上传失败',
        );
      }
    } catch (e) {
      return HttpResultN<String>(isSuccess: false, code: -1, msg: '上传失败: $e');
    }
  }
}
