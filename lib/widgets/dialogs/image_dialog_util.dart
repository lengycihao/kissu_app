import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kissu_app/utils/screen_adaptation.dart';
import 'package:kissu_app/widgets/dialogs/simple_image_source_dialog.dart';
import 'package:kissu_app/widgets/dialogs/permission_request_dialog.dart';
import 'package:kissu_app/services/permission_service.dart';
import 'package:kissu_app/network/public/file_upload_api.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';

/// 图片弹窗工具类
class ImageDialogUtil {
  /// 显示图片弹窗
  ///
  /// [context] 上下文
  /// [imagePath] 图片路径
  /// [maxWidthRatio] 最大宽度比例，默认0.9
  /// [maxHeightRatio] 最大高度比例，默认0.8
  /// [barrierDismissible] 点击外部是否可关闭，默认true
  /// [showCloseButton] 是否显示关闭按钮，默认true
  /// [borderRadius] 圆角半径，默认12
  /// [backgroundColor] 背景颜色，已移除背景色
  static void showImageDialog({
    required BuildContext context,
    required String imagePath,
    double maxWidthRatio = 0.9,
    double maxHeightRatio = 0.8,
    bool barrierDismissible = true,
    bool showCloseButton = true,
    double borderRadius = 12,
    Color? backgroundColor,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return _AvatarUploadDialog(
          imagePath: imagePath,
          barrierDismissible: barrierDismissible,
          showCloseButton: showCloseButton,
        );
      },
    );
  }
}

/// 头像上传弹窗组件
class _AvatarUploadDialog extends StatefulWidget {
  final String imagePath;
  final bool barrierDismissible;
  final bool showCloseButton;

  const _AvatarUploadDialog({
    required this.imagePath,
    required this.barrierDismissible,
    required this.showCloseButton,
  });

  @override
  _AvatarUploadDialogState createState() => _AvatarUploadDialogState();
}

class _AvatarUploadDialogState extends State<_AvatarUploadDialog> {
  final PermissionService _permissionService = PermissionService();
  final FileUploadApi _fileUploadApi = FileUploadApi();
  
  File? _selectedImageFile; // 选中的本地图片文件
  bool _isUploading = false; // 是否正在上传

  /// 选择头像
  Future<void> _pickAvatar() async {
    try {
      // 检查是否已有相册和相机权限
      final hasPhotoPermission = await _permissionService.checkPermissionStatus(PermissionType.photos);
      final hasCameraPermission = await _permissionService.checkPermissionStatus(PermissionType.camera);
      
      // 如果两个权限都有，直接显示选择来源对话框
      if (hasPhotoPermission && hasCameraPermission) {
        final imageSource = await SimpleImageSourceDialog.show(context);
        if (imageSource == null) return;
        
        await _pickImageFromSource(imageSource);
        return;
      }
      
      // 如果没有权限，先显示权限说明弹窗
      final shouldContinue = await PermissionRequestDialog.showPhotosPermissionDialog(context);
      if (shouldContinue != true) return;
      
      // 申请权限
      bool photoPermissionGranted = hasPhotoPermission;
      bool cameraPermissionGranted = hasCameraPermission;
      
      if (!hasPhotoPermission) {
        photoPermissionGranted = await _permissionService.requestPhotosPermission();
      }
      
      if (!hasCameraPermission) {
        cameraPermissionGranted = await _permissionService.requestCameraPermission();
      }
      
      // 如果至少有一个权限被授予，显示选择来源对话框
      if (photoPermissionGranted || cameraPermissionGranted) {
        final imageSource = await SimpleImageSourceDialog.show(context);
        if (imageSource == null) return;
        
        await _pickImageFromSource(imageSource);
      } else {
        CustomToast.show(context, '权限未授予，无法选择图片');
      }
    } catch (e) {
      print('选择头像失败: $e');
      CustomToast.show(context, '选择头像失败');
    }
  }

  /// 从指定来源选择图片
  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      // 再次检查权限状态（防止用户在选择来源时权限被撤销）
      bool hasPermission = false;
      if (source == ImageSource.camera) {
        hasPermission = await _permissionService.checkPermissionStatus(PermissionType.camera);
      } else {
        hasPermission = await _permissionService.checkPermissionStatus(PermissionType.photos);
      }

      if (!hasPermission) {
        CustomToast.show(context, '权限未授予，无法选择图片');
        return;
      }

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
        });
        
        // 选择完图片后自动上传
        await _uploadAvatar();
      }
    } catch (e) {
      CustomToast.show(context, '选择图片失败: $e');
    }
  }

  /// 上传头像
  Future<void> _uploadAvatar() async {
    if (_selectedImageFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final result = await _fileUploadApi.uploadFile(_selectedImageFile!);

      if (result.isSuccess && result.data != null) {
        setState(() {
          _isUploading = false;
        });
        
        CustomToast.show(context, '头像上传成功');
        
        // TODO: 这里预留后续调用更新用户头像的接口
        // 上传成功后的URL: result.data
        // await _updateUserAvatar(result.data!);
      } else {
        setState(() {
          _isUploading = false;
        });
        CustomToast.show(context, result.msg ?? '头像上传失败');
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      print('上传头像失败: $e');
      CustomToast.show(context, '头像上传失败');
    }
  }

  /// 获取头像显示组件
  Widget _buildAvatarDisplay() {
    // 如果有选中的本地图片，优先显示本地图片
    if (_selectedImageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          _selectedImageFile!,
          fit: BoxFit.cover,
          width: 100,
          height: 100,
        ),
      );
    }
    
    // 否则显示默认头像
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        "assets/3.0/kissu3_love_avater.webp",
        fit: BoxFit.cover,
        width: 100,
        height: 100,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(13).copyWith(
        top: ScreenAdaptation.screenHeight / 2 - 190,
        bottom: ScreenAdaptation.screenHeight / 2 - 190,
      ),
      child: Stack(
        children: [
          // 背景遮罩
          GestureDetector(
            onTap: widget.barrierDismissible
                ? () => Navigator.of(context).pop()
                : null,
            child: Container(color: Colors.transparent),
          ),
          // 图片内容
          Center(
            child: Container(
              width: 334,
              height: 350,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(widget.imagePath),
                  fit: BoxFit.contain,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Color(0xffFBCDFF),
                            width: 3,
                          ),
                        ),
                        child: _buildAvatarDisplay(),
                      ),
                      // 上传中的加载指示器
                      if (_isUploading)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 33),
                  GestureDetector(
                    onTap: _isUploading ? null : _pickAvatar,
                    child: Container(
                      height: 42,
                      width: 290,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isUploading
                              ? [const Color.fromARGB(255, 223, 220, 220), Color.fromARGB(255, 223, 220, 220)]
                              : [Color(0xFFCE92FF), Color(0xFFFF87E1)],
                        ),
                        borderRadius: BorderRadius.circular(21),
                      ),
                      child: Text(
                        _isUploading ? "上传中..." : "上传头像",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 23),
                  Text(
                    "*更多可自定义内容不断内测中...",
                    style: TextStyle(
                      color: Color(0xff999999),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 关闭按钮
          if (widget.showCloseButton)
            Positioned(
              top: 10,
              right: 3,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
