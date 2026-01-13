import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:photo_manager/photo_manager.dart';

/// 图片保存工具类
class ImageSaverUtil {
  /// 保存assets图片到相册
  /// [assetPath] assets路径，如 'assets/setting/kissu_fuli_dialog.webp'
  static Future<bool> saveAssetImageToGallery(String assetPath) async {
    try {
      // 读取assets图片
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();

      // 确保文件扩展名是 .jpg
      final String fileName = assetPath.split('/').last;
      final String finalFileName = fileName.endsWith('.webp') 
          ? fileName.replaceAll('.webp', '.jpg') 
          : fileName;

      // 使用 photo_manager 直接保存到相册
      final AssetEntity? asset = await PhotoManager.editor.saveImage(
        bytes,
        filename: finalFileName,
      );

      if (asset != null) {
        OKToastUtil.show('保存成功');
        return true;
      } else {
        OKToastUtil.showError('保存失败，请检查权限');
        return false;
      }
    } catch (e) {
      logError('保存图片失败: $e');
      OKToastUtil.showError('保存图片失败: $e');
      return false;
    }
  }
}

