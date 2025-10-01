// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:dio/dio.dart';
// import 'package:kissu_app/services/permission_service.dart';
// import 'package:kissu_app/widgets/dialogs/permission_request_dialog.dart';

// class ImageHandler {
//   final ImagePicker _imagePicker = ImagePicker();
//   final PermissionService _permissionService = PermissionService();

//   // 显示选择来源弹窗
//   void showImageSourceDialog(
//     BuildContext context, {
//     required Function(List<File>) onSelected,
//     required int maxImages,
//     required List<File> currentImages,
//   }) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder: (context) => _buildBottomSheet(
//         context,
//         onSelected: onSelected,
//         maxImages: maxImages,
//         currentImages: currentImages,
//       ),
//     );
//   }

//   // 构建底部弹窗内容
//   Widget _buildBottomSheet(
//     BuildContext context, {
//     required Function(List<File>) onSelected,
//     required int maxImages,
//     required List<File> currentImages,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 20),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Text(
//             "选择图片来源",
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//           ),
//           const SizedBox(height: 24),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               // 相机选项
//               _buildOptionItem(
//                 icon: Icons.camera_alt,
//                 label: "相机",
//                   onTap: () async {
//                     Navigator.pop(context);
//                     await _handleCameraSelection(context, onSelected);
//                   },
//               ),

//               // 相册选项
//               _buildOptionItem(
//                 icon: Icons.photo_library,
//                 label: "相册",
//                   onTap: () async {
//                     Navigator.pop(context);
//                     await _handleGallerySelection(context, onSelected, maxImages, currentImages);
//                   },
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   // 构建选项按钮
//   Widget _buildOptionItem({
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(8),
//       child: Column(
//         children: [
//           Container(
//             width: 64,
//             height: 64,
//             decoration: BoxDecoration(
//               color: Colors.grey[100],
//               borderRadius: BorderRadius.circular(32),
//             ),
//             child: Icon(icon, size: 28, color: Colors.blue),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             label,
//             style: const TextStyle(fontSize: 16, color: Colors.black87),
//           ),
//         ],
//       ),
//     );
//   }

//   /// 处理相机选择 - 使用自定义弹窗提示权限申请
//   Future<void> _handleCameraSelection(BuildContext context, Function(List<File>) onSelected) async {
//     try {
//       // 检查是否已有相机权限
//       final hasPermission = await _permissionService.checkPermissionStatus(PermissionType.camera);
      
//       if (!hasPermission) {
//         // 显示自定义权限提示弹窗
//         if (!context.mounted) return;
//         final shouldContinue = await PermissionRequestDialog.showCameraPermissionDialog(context);
//         if (shouldContinue != true) return;
        
//         // 申请相机权限
//         final granted = await _permissionService.requestCameraPermission();
//         if (!granted) {
//           if (!context.mounted) return;
//           _showEnhancedPermissionDeniedDialog(context, "相机", PermissionType.camera);
//           return;
//         }
//       }
      
//       // 权限已获得，进行图片拍摄
//       if (!context.mounted) return;
//       final image = await _getImageFromCamera(context);
//       if (image != null) {
//         onSelected([image]);
//       }
//     } catch (e) {
//       if (context.mounted) {
//         _showMessage(context, '相机功能异常: $e');
//       }
//     }
//   }

//   /// 处理相册选择 - 使用自定义弹窗提示权限申请
//   Future<void> _handleGallerySelection(
//     BuildContext context, 
//     Function(List<File>) onSelected, 
//     int maxImages, 
//     List<File> currentImages
//   ) async {
//     try {
//       // 检查是否已有相册权限
//       final hasPermission = await _permissionService.checkPermissionStatus(PermissionType.photos);
//       print("相册权限检查结果: $hasPermission");
      
//       // 检查权限是否被永久拒绝
//       final isPermanentlyDenied = await _permissionService.isPermissionPermanentlyDenied(PermissionType.photos);
//       print("相册权限是否被永久拒绝: $isPermanentlyDenied");
      
//       if (!hasPermission) {
//         // 如果权限被永久拒绝，直接提示跳转设置
//         if (isPermanentlyDenied) {
//           if (!context.mounted) return;
//           print("权限被永久拒绝，显示设置提示");
//           _showEnhancedPermissionDeniedDialog(context, "相册", PermissionType.photos);
//           return;
//         }
//         // 显示自定义权限提示弹窗
//         if (!context.mounted) {
//           print("Context 不可用，无法显示权限弹窗");
//           return;
//         }
//         print("显示相册权限说明弹窗");
//         final shouldContinue = await PermissionRequestDialog.showPhotosPermissionDialog(context);
//         print("用户选择继续: $shouldContinue");
//         if (shouldContinue != true) {
//           print("用户取消了权限申请");
//           return;
//         }
        
//         // 申请相册权限
//         print("开始申请相册权限");
//         try {
//           final granted = await _permissionService.requestPhotosPermission();
//           print("相册权限申请结果: $granted");
//           if (!granted) {
//             if (!context.mounted) return;
//             print("权限被拒绝，显示权限被拒绝弹窗");
//             _showEnhancedPermissionDeniedDialog(context, "相册", PermissionType.photos);
//             return;
//           }
//           print("相册权限申请成功，继续选择图片");
//         } catch (e) {
//           print("申请相册权限时发生异常: $e");
//           if (context.mounted) {
//             _showMessage(context, '权限申请失败: $e');
//           }
//           return;
//         }
//       }
      
//       // 权限已获得，进行图片选择
//       final remaining = maxImages - currentImages.length;
//       if (remaining <= 0) {
//         if (!context.mounted) return;
//         _showMessage(context, "最多只能选择$maxImages张图片");
//         return;
//       }
      
//       if (!context.mounted) return;
//       final images = await _getImagesFromGallery(context, remaining);
//       if (images.isNotEmpty) {
//         onSelected(images);
//       }
//     } catch (e) {
//       if (context.mounted) {
//         _showMessage(context, '相册功能异常: $e');
//       }
//     }
//   }

//   // 从相机获取图片（内部方法，权限已检查）
//   Future<File?> _getImageFromCamera(BuildContext context) async {
//     try {
//       // 调用相机
//       final XFile? image = await _imagePicker.pickImage(
//         source: ImageSource.camera,
//         imageQuality: 80,
//       );

//       if (image != null) {
//         return File(image.path);
//       }
//     } catch (e) {
//       if (context.mounted) {
//         _showMessage(context, "相机调用失败: ${e.toString()}");
//       }
//     }
//     return null;
//   }

//   // 从相册获取图片
//   Future<List<File>> _getImagesFromGallery(
//     BuildContext context,
//     int maxSelectable,
//   ) async {
//     try {
//       // 调用相册选择多张图片
//       final List<XFile> images = await _imagePicker.pickMultiImage(
//         imageQuality: 80,
//       );

//       // 处理选择数量限制
//       if (images.length > maxSelectable) {
//         if (context.mounted) {
//           _showMessage(
//             context,
//             "已为您保留前$maxSelectable张图片（最多可选择$maxSelectable张）",
//           );
//         }
//         return images
//             .sublist(0, maxSelectable)
//             .map((xfile) => File(xfile.path))
//             .toList();
//       }

//       return images.map((xfile) => File(xfile.path)).toList();
//     } catch (e) {
//       if (context.mounted) {
//         _showMessage(context, "相册调用失败: ${e.toString()}");
//       }
//       return [];
//     }
//   }

//   // 注意：旧的权限检查方法已移除，现在使用统一的 PermissionService
//   // 如果其他地方还在使用 _checkPermission，请更新为使用 PermissionService

//   // 显示增强的权限被拒绝对话框（支持跳转设置）
//   void _showEnhancedPermissionDeniedDialog(
//     BuildContext context,
//     String permissionName,
//     PermissionType permissionType,
//   ) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("权限不足"),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("需要$permissionName权限才能继续使用此功能。"),
//             const SizedBox(height: 8),
//             Text(
//               _permissionService.getPermissionDescription(permissionType),
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.grey[600],
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("取消"),
//           ),
//           TextButton(
//             onPressed: () async {
//               Navigator.pop(context);
//               await _permissionService.openPermissionSettings(permissionType);
//             },
//             child: const Text("去设置"),
//           ),
//         ],
//       ),
//     );
//   }

//   // 旧的权限对话框方法已移除，现在统一使用 _showEnhancedPermissionDeniedDialog

//   // 显示提示消息
//   void _showMessage(BuildContext context, String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("确定"),
//           ),
//         ],
//       ),
//     );
//   }

//   // 上传图片到服务器
//   Future<String> uploadImages(
//     String url,
//     List<File> images, {
//     Function(double progress)? onProgress,
//     Map<String, String>? extraData,
//   }) async {
//     if (images.isEmpty) {
//       return "请先选择图片";
//     }

//     try {
//       final dio = Dio();
//       final formData = FormData();

//       // 添加图片文件
//       for (int i = 0; i < images.length; i++) {
//         final file = await MultipartFile.fromFile(
//           images[i].path,
//           filename: 'image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
//         );
//         formData.files.add(MapEntry('images[]', file));
//       }

//       // 添加额外数据
//       if (extraData != null) {
//         extraData.forEach((key, value) {
//           formData.fields.add(MapEntry(key, value));
//         });
//       }

//       // 执行上传
//       final response = await dio.post(
//         url,
//         data: formData,
//         onSendProgress: (int sent, int total) {
//           if (total > 0 && onProgress != null) {
//             onProgress(sent / total);
//           }
//         },
//       );

//       if (response.statusCode == 200) {
//         return "上传成功";
//       } else {
//         return "上传失败: 状态码 ${response.statusCode}";
//       }
//     } catch (e) {
//       return "上传失败: ${e.toString()}";
//     }
//   }
// }
