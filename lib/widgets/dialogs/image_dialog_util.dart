import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/network_image_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kissu_app/pages/common/image_crop_page.dart';
import 'package:kissu_app/utils/screen_adaptation.dart';
import 'package:kissu_app/widgets/dialogs/simple_image_source_dialog.dart';
import 'package:kissu_app/widgets/dialogs/permission_request_dialog.dart';
import 'package:kissu_app/services/permission_service.dart';
import 'package:kissu_app/network/public/file_upload_api.dart';
import 'package:kissu_app/network/public/photo_wall_api.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/widgets/dialogs/location_state_delete_dialog.dart';

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
  /// [onUploadSuccess] 上传成功后的回调函数
  /// [currentPhotoWallUrl] 当前照片墙的网络图片URL
  static void showImageDialog({
    required BuildContext context,
    required String imagePath,
    double maxWidthRatio = 0.9,
    double maxHeightRatio = 0.8,
    bool barrierDismissible = true,
    bool showCloseButton = true,
    double borderRadius = 12,
    Color? backgroundColor,
    VoidCallback? onUploadSuccess,
    String? currentPhotoWallUrl,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return _AvatarUploadDialog(
          imagePath: imagePath,
          barrierDismissible: barrierDismissible,
          showCloseButton: showCloseButton,
          onUploadSuccess: onUploadSuccess,
          currentPhotoWallUrl: currentPhotoWallUrl,
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
  final VoidCallback? onUploadSuccess;
  final String? currentPhotoWallUrl;

  const _AvatarUploadDialog({
    required this.imagePath,
    required this.barrierDismissible,
    required this.showCloseButton,
    this.onUploadSuccess,
    this.currentPhotoWallUrl,
  });

  @override
  _AvatarUploadDialogState createState() => _AvatarUploadDialogState();
}

class _AvatarUploadDialogState extends State<_AvatarUploadDialog> {
  final PermissionService _permissionService = PermissionService();
  final FileUploadApi _fileUploadApi = FileUploadApi();
  final PhotoWallApi _photoWallApi = PhotoWallApi();
  
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
      logError('选择照片失败: $e', tag: 'ImageDialog', error: e);
      CustomToast.show(context, '选择照片失败');
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
        // 不设置imageQuality和maxWidth/maxHeight，保持原始图片质量
        // 压缩将在裁剪后上传时进行
      );

      if (pickedFile != null) {
        // 直接进入图片裁剪页面（会预加载图片，裁剪页面有自己的loading）
        await _navigateToCropPage(pickedFile.path);
      }
    } catch (e) {
      CustomToast.show(context, '选择图片失败: $e');
    }
  }

  /// 导航到图片裁剪页面
  Future<void> _navigateToCropPage(String imagePath) async {
    try {
      await Get.to(
        () => ImageCropPage(
          imagePath: imagePath,
          onCropComplete: _onCropComplete,
          customCropFrameAsset: 'assets/3.0/kissu3_crop_icon.webp',
          // 不预加载，让裁剪页面自己加载并显示loading
        ),
        transition: Transition.rightToLeft,
        fullscreenDialog: true,
      );
    } catch (e) {
      logError('导航到裁剪页面失败: $e', tag: 'ImageDialog', error: e);
      CustomToast.show(context, '打开裁剪页面失败');
    }
  }

  /// 裁剪完成回调
  void _onCropComplete(String croppedImagePath) {
    setState(() {
      _selectedImageFile = File(croppedImagePath);
    });
  }

  /// 上传头像（照片墙）
  Future<void> _uploadAvatar() async {
    if (_selectedImageFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // 第一步：上传图片文件，获取URL
      final uploadResult = await _fileUploadApi.uploadFile(_selectedImageFile!);

      if (!uploadResult.isSuccess || uploadResult.data == null) {
        setState(() {
          _isUploading = false;
        });
        CustomToast.show(context, uploadResult.msg ?? '图片上传失败');
        return;
      }
      
      // 获取上传后的图片URL
      final photoWallUrl = uploadResult.data!;
      logDebug('📸 图片上传成功，URL: $photoWallUrl', tag: 'ImageDialog');
      
      // 第二步：调用保存照片墙接口
      final saveResult = await _photoWallApi.savePhotoWall(photoWallUrl);
      
      setState(() {
        _isUploading = false;
      });
      
      if (saveResult.isSuccess) {
        CustomToast.show(context, '照片墙保存成功');
        
        // 保存成功后关闭弹窗
        Navigator.of(context).pop();
        
        // 执行回调函数（刷新首页数据）
        if (widget.onUploadSuccess != null) {
          widget.onUploadSuccess!();
        }
      } else {
        CustomToast.show(context, saveResult.msg ?? '照片墙保存失败');
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      logError('照片墙保存失败: $e', tag: 'ImageDialog', error: e);
      CustomToast.show(context, '操作失败: $e');
    }
  }

  /// 预览图片
  void _previewImage() {
    // 如果有选中的本地图片，预览本地图片
    if (_selectedImageFile != null) {
      _showImagePreview(
        context,
        isLocal: true,
        localFile: _selectedImageFile,
      );
      return;
    }
    
    // 如果有网络图片URL，预览网络图片
    if (widget.currentPhotoWallUrl != null && 
        widget.currentPhotoWallUrl!.isNotEmpty && 
        widget.currentPhotoWallUrl!.startsWith('http')) {
      _showImagePreview(
        context,
        isLocal: false,
        networkUrl: widget.currentPhotoWallUrl,
      );
      return;
    }
    
    // 如果是默认头像，不预览
  }

  /// 显示图片预览对话框
  void _showImagePreview(
    BuildContext context, {
    required bool isLocal,
    File? localFile,
    String? networkUrl,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.zero,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                children: [
                  // 图片内容
                  Center(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: isLocal
                          ? Image.file(
                              localFile!,
                              fit: BoxFit.contain,
                            )
                          : NetworkImageHelper.loadImage(
                              imageUrl: networkUrl!,
                              fit: BoxFit.contain,
                              errorWidget: Center(
                                child: Text(
                                  '图片加载失败',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  // 关闭按钮
                  Positioned(
                    top: 40,
                    right: 20,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 获取头像显示组件
  Widget _buildAvatarDisplay() {
    // 如果有选中的本地图片，优先显示本地图片
    if (_selectedImageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(
          _selectedImageFile!,
          fit: BoxFit.cover,
          width: 100,
          height: 100,
        ),
      );
    }
    
    // 如果有网络图片URL，显示网络图片
    if (widget.currentPhotoWallUrl != null && 
        widget.currentPhotoWallUrl!.isNotEmpty && 
        widget.currentPhotoWallUrl!.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: NetworkImageHelper.loadImage(
          imageUrl: widget.currentPhotoWallUrl!,
          fit: BoxFit.cover,
          width: 100,
          height: 100,
          errorWidget: Image.asset(
            "assets/3.0/kissu3_love_avater.webp",
            fit: BoxFit.cover,
            width: 100,
            height: 100,
          ),
        ),
      );
    }
    
    // 否则显示默认头像
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
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
          // 背景遮罩（是否可点击关闭由 barrierDismissible 控制）
          GestureDetector(
            onTap: widget.barrierDismissible ? () => Navigator.of(context).pop() : null,
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
                  // 使用Container包装Stack，确保超出部分可点击
                  Container(
                    width: 160, // 扩大容器宽度以容纳超出的按钮
                    height: 140, // 扩大容器高度以容纳超出的按钮
                    child: Stack(
                      clipBehavior: Clip.none, // 允许子元素超出容器
                      alignment: Alignment.center,
                      children: [
                        // 头像容器
                        GestureDetector(
                          onTap: _previewImage,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Color(0xffFBCDFF),
                                width: 3,
                              ),
                            ),
                            child: _buildAvatarDisplay(),
                          ),
                        ),
                      // 上传按钮（右下角，超出容器右边20px，下边8px）
                      Positioned(
                        right: 0, // 扩大点击区域，超出右边30px
                        bottom: 0, // 扩大点击区域，超出下边18px
                        child: GestureDetector(
                          onTap: _isUploading ? null : _pickAvatar,
                          // 扩大点击区域：添加10px的padding，让点击区域从46x24变为66x44
                          child: Container(
                            padding: EdgeInsets.all(10),
                            color: Colors.transparent,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.asset(
                                  "assets/3.0/kissu3_upload_logo.webp",
                                  width: 46,
                                  height: 24,
                                ),
                                // 上传文字
                                Text(
                                  "上传",
                                  style: TextStyle(
                                    color: Color(0xFFFF78E2),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )],
                    ),
                  ),
                  // SizedBox(height: 20),
                  // 上传中的加载指示器 - 显示在按钮上方
                  if (_isUploading)
                    Container(
                      height: 50,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF87E1)),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "上传中...",
                            style: TextStyle(
                              color: Color(0xFFFF87E1),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                   
                  GestureDetector(
                    onTap: _isUploading ? null : () async {
                      if (_selectedImageFile == null) {
                        CustomToast.show(context, '请先选择照片');
                        return;
                      }
                      await _uploadAvatar();
                    },
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
                        _isUploading ? "上传中..." : "保存照片",
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
                  SizedBox(height: 10),
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
                onTap: _handleCloseTap,
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

  /// 处理右上角关闭按钮点击
  Future<void> _handleCloseTap() async {
    // 如果没有选中过新的本地照片，直接关闭弹窗
    if (_selectedImageFile == null) {
      Navigator.of(context).pop();
      return;
    }

    // 已经有裁剪后的本地图片但未保存，弹出挽留弹窗
    await LocationStateDeleteDialog.show(
      context: context,
      title: '照片暂未保存，是否直接退出？',
      barrierDismissible: true,
      // 左边按钮（取消按钮区域）："退出" -> 关闭照片墙弹窗
      onCancel: () {
        Navigator.of(context).pop();
      },
      // 右边按钮（确认按钮区域）："继续编辑" -> 仅关闭挽留弹窗（内部已处理 pop），不做额外处理
      onConfirm: () {},
      // 照片墙使用自定义按钮图片
      cancelAsset: 'assets/location/kissu3_dialog_cancel.webp',
      confirmAsset: 'assets/location/kissu3_dialog_sure.webp',
    );
  }
}
