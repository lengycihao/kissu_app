import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';

/// 媒体选择工具类
class MediaPickerUtil {
  static final ImagePicker _picker = ImagePicker();

  /// 从相册选择图片
  static Future<File?> pickImageFromGallery({
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      // 请求相册权限
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        Get.snackbar(
          '权限提示',
          '请在设置中允许访问相册',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black87,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
        return null;
      }

      // 选择图片
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('选择图片失败: $e');
      Get.snackbar(
        '错误',
        '选择图片失败，请重试',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return null;
    }
  }

  /// 使用相机拍照
  static Future<File?> takePhoto({
    int imageQuality = 85,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    try {
      // 请求相机权限
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        Get.snackbar(
          '权限提示',
          '请在设置中允许访问相机',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black87,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
        return null;
      }

      // 拍照
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
        preferredCameraDevice: preferredCameraDevice,
      );

      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      debugPrint('拍照失败: $e');
      Get.snackbar(
        '错误',
        '拍照失败，请重试',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return null;
    }
  }

  /// 选择视频
  static Future<File?> pickVideo({
    ImageSource source = ImageSource.gallery,
    Duration? maxDuration,
  }) async {
    try {
      // 请求权限
      final Permission permission = source == ImageSource.camera
          ? Permission.camera
          : Permission.photos;
      final status = await permission.request();
      if (!status.isGranted) {
        Get.snackbar(
          '权限提示',
          '请在设置中允许访问${source == ImageSource.camera ? "相机" : "相册"}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black87,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
        return null;
      }

      // 选择视频
      final XFile? video = await _picker.pickVideo(
        source: source,
        maxDuration: maxDuration,
      );

      if (video != null) {
        return File(video.path);
      }
      return null;
    } catch (e) {
      debugPrint('选择视频失败: $e');
      Get.snackbar(
        '错误',
        '选择视频失败，请重试',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return null;
    }
  }

  /// 显示图片来源选择对话框
  static Future<File?> showImageSourceDialog({
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    final result = await Get.dialog<ImageSource>(
      AlertDialog(
        title: const Text('选择图片来源'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xff8B7FFF)),
              title: const Text('从相册选择'),
              onTap: () => Get.back(result: ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xff6BA5FF)),
              title: const Text('拍照'),
              onTap: () => Get.back(result: ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (result == null) return null;

    if (result == ImageSource.gallery) {
      return await pickImageFromGallery(
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
    } else {
      return await takePhoto(imageQuality: imageQuality);
    }
  }
}

