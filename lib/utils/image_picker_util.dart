import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';

class ImageHandler {
  final ImagePicker _imagePicker = ImagePicker();
  
  // 显示选择来源弹窗
  void showImageSourceDialog(
    BuildContext context, {
    required Function(List<File>) onSelected,
    required int maxImages,
    required List<File> currentImages,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildBottomSheet(
        context,
        onSelected: onSelected,
        maxImages: maxImages,
        currentImages: currentImages,
      ),
    );
  }
  
  // 构建底部弹窗内容
  Widget _buildBottomSheet(
    BuildContext context, {
    required Function(List<File>) onSelected,
    required int maxImages,
    required List<File> currentImages,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "选择图片来源",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 相机选项
              _buildOptionItem(
                icon: Icons.camera_alt,
                label: "相机",
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _getImageFromCamera(context);
                  if (image != null) {
                    onSelected([image]);
                  }
                },
              ),
              
              // 相册选项
              _buildOptionItem(
                icon: Icons.photo_library,
                label: "相册",
                onTap: () async {
                  // Navigator.pop(context);
                  final remaining = maxImages - currentImages.length;
                  // if (remaining <= 0) {
                  //   _showMessage(context, "最多只能选择$maxImages张图片");
                  //   return;
                  // }
                  
                  final images = await _getImagesFromGallery(context, remaining);
                  if (images.isNotEmpty) {
                    onSelected(images);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // 构建选项按钮
  Widget _buildOptionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(icon, size: 28, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
  
  // 从相机获取图片
  Future<File?> _getImageFromCamera(BuildContext context) async {
    try {
      // 检查相机权限
      if (!await _checkPermission(Permission.camera, "相机", context)) {
        return null;
      }
      
      // 调用相机
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      _showMessage(context, "相机调用失败: ${e.toString()}");
    }
    return null;
  }
  
  // 从相册获取图片
  Future<List<File>> _getImagesFromGallery(
    BuildContext context, 
    int maxSelectable,
  ) async {
    try {
      // 检查相册权限
      if (!await _checkPermission(_getGalleryPermission(), "相册", context)) {
        return [];
      }
      Navigator.pop(context);
      // 调用相册选择多张图片
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 80,
      );
      
      // 处理选择数量限制
      if (images.length > maxSelectable) {
        if (context.mounted) {
          _showMessage(context, 
          "已为您保留前$maxSelectable张图片（最多可选择$maxSelectable张）"
        );
        }
        return images
            .sublist(0, maxSelectable)
            .map((xfile) => File(xfile.path))
            .toList();
      }
      
      return images.map((xfile) => File(xfile.path)).toList();
    } catch (e) {
      if (context.mounted) {
        _showMessage(context, "相册调用失败: ${e.toString()}");
        
      }
      return [];
    }
  }
  
  // 根据平台获取相册权限
  Permission _getGalleryPermission() {
    if (Platform.isAndroid) {
      return Permission.photos;
    } else if (Platform.isIOS) {
      return Permission.photos;
    }
    return Permission.storage;
  }
  
  // 检查并请求权限
  Future<bool> _checkPermission(
    Permission permission, 
    String permissionName,
    BuildContext context,
  ) async {
    // 检查权限状态
    final status = await permission.status;
    
    if (status.isGranted) {
      return true;
    }
    
    // 请求权限
    final result = await permission.request();
    
    if (result.isGranted) {
      return true;
    } else {
      _showPermissionDeniedDialog(context, permissionName);
      return false;
    }
  }
  
  // 显示权限被拒绝对话框
  void _showPermissionDeniedDialog(BuildContext context, String permissionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("权限不足"),
        content: Text("需要$permissionName权限才能继续，请在设置中开启。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("确定"),
          ),
        ],
      ),
    );
  }
  
  // 显示提示消息
  void _showMessage(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("确定"),
          ),
        ],
      ),
    );
  }
  
  // 上传图片到服务器
  Future<String> uploadImages(
    String url,
    List<File> images, {
    Function(double progress)? onProgress,
    Map<String, String>? extraData,
  }) async {
    if (images.isEmpty) {
      return "请先选择图片";
    }
    
    try {
      final dio = Dio();
      final formData = FormData();
      
      // 添加图片文件
      for (int i = 0; i < images.length; i++) {
        final file = await MultipartFile.fromFile(
          images[i].path,
          filename: 'image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
        );
        formData.files.add(MapEntry('images[]', file));
      }
      
      // 添加额外数据
      if (extraData != null) {
        extraData.forEach((key, value) {
          formData.fields.add(MapEntry(key, value));
        });
      }
      
      // 执行上传
      final response = await dio.post(
        url,
        data: formData,
        onSendProgress: (int sent, int total) {
          if (total > 0 && onProgress != null) {
            onProgress(sent / total);
          }
        },
      );
      
      if (response.statusCode == 200) {
        return "上传成功";
      } else {
        return "上传失败: 状态码 ${response.statusCode}";
      }
    } catch (e) {
      return "上传失败: ${e.toString()}";
    }
  }
}
    