import 'package:flutter/material.dart';

/// 权限请求说明弹窗
class PermissionRequestDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback? onContinue;
  final VoidCallback? onCancel;

  const PermissionRequestDialog({
    super.key,
    required this.title,
    required this.content,
    this.onContinue,
    this.onCancel,
  });

  /// 显示相机权限请求弹窗
  static Future<bool?> showCameraPermissionDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PermissionRequestDialog(
        title: '开启相机权限',
        content: '我们需要访问您的相机，用于拍摄头像等场景',
        onContinue: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  /// 显示相册权限请求弹窗
  static Future<bool?> showPhotosPermissionDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PermissionRequestDialog(
        title: '开启相册权限',
        content: '我们需要访问您的相册，用于上传头像等场景',
        onContinue: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 主弹窗容器
          Container(
            width: 269,
            height: 183,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/kissu_permission_bg.webp'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题区域
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                // 内容区域
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Text(
                    content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF333333),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // 继续按钮区域
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF408D), // 新的按钮颜色
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        '继续',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 关闭按钮 - 放在弹窗下方16px处
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onCancel ?? () => Navigator.of(context).pop(false),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF999999), // 灰色背景
                borderRadius: BorderRadius.circular(16), // 圆角
                image: const DecorationImage(
                  image: AssetImage('assets/kissu_location_close.webp'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

