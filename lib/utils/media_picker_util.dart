import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:kissu_app/services/permission_service.dart';

/// 媒体选择工具类
class MediaPickerUtil {
  static final ImagePicker _picker = ImagePicker();
  static final PermissionService _permissionService = PermissionService();

  /// 从相册选择图片
  /// 
  /// [imageQuality] 图片质量 (0-100)
  /// [maxWidth] 最大宽度
  /// [maxHeight] 最大高度
  /// 
  /// 返回选中的图片文件，如果用户取消则返回 null
  static Future<File?> pickImageFromGallery({
    int imageQuality = 85,
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      // 检查权限
      final hasPermission = await _permissionService.isPhotosPermissionGranted();
      if (!hasPermission) {
        // 请求权限
        final granted = await _permissionService.requestPhotosPermission();
        if (!granted) {
          debugPrint('相册权限未授予');
          return null;
        }
      }

      // 选择图片
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
      );

      if (pickedFile == null) {
        return null;
      }

      // 如果需要压缩
      if (maxWidth != null || maxHeight != null || imageQuality < 100) {
        return await _compressImage(
          File(pickedFile.path),
          quality: imageQuality,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        );
      }

      return File(pickedFile.path);
    } catch (e) {
      debugPrint('从相册选择图片失败: $e');
      return null;
    }
  }

  /// 拍照
  /// 
  /// [imageQuality] 图片质量 (0-100)
  /// 
  /// 返回拍摄的图片文件，如果用户取消则返回 null
  static Future<File?> takePhoto({
    int imageQuality = 85,
  }) async {
    try {
      // 检查权限
      final hasPermission = await _permissionService.isCameraPermissionGranted();
      if (!hasPermission) {
        // 请求权限
        final granted = await _permissionService.requestCameraPermission();
        if (!granted) {
          debugPrint('相机权限未授予');
          return null;
        }
      }

      // 拍照
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
      );

      if (pickedFile == null) {
        return null;
      }

      // 如果需要压缩
      if (imageQuality < 100) {
        return await _compressImage(
          File(pickedFile.path),
          quality: imageQuality,
        );
      }

      return File(pickedFile.path);
    } catch (e) {
      debugPrint('拍照失败: $e');
      return null;
    }
  }

  /// 压缩图片
  /// 
  /// [file] 原始图片文件
  /// [quality] 压缩质量 (0-100)
  /// [maxWidth] 最大宽度
  /// [maxHeight] 最大高度
  /// 
  /// 返回压缩后的图片文件
  static Future<File> _compressImage(
    File file, {
    int quality = 85,
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      // 获取文件路径
      final filePath = file.absolute.path;
      
      // 生成压缩后的文件路径
      final lastIndex = filePath.lastIndexOf(RegExp(r'\.'));
      final splitted = filePath.substring(0, lastIndex);
      final outPath = '${splitted}_compressed.jpg';

      // 压缩图片
      XFile? compressedFile;
      if (maxWidth != null || maxHeight != null) {
        compressedFile = await FlutterImageCompress.compressAndGetFile(
          filePath,
          outPath,
          quality: quality,
          minWidth: maxWidth != null ? (maxWidth ~/ 2) : 1920,
          minHeight: maxHeight != null ? (maxHeight ~/ 2) : 1920,
        );
      } else {
        compressedFile = await FlutterImageCompress.compressAndGetFile(
          filePath,
          outPath,
          quality: quality,
        );
      }

      if (compressedFile == null) {
        debugPrint('图片压缩失败，返回原文件');
        return file;
      }

      return File(compressedFile.path);
    } catch (e) {
      debugPrint('图片压缩失败: $e，返回原文件');
      return file;
    }
  }
}

