import 'package:flutter/material.dart';

/// 权限请求说明弹窗（与定位权限弹窗样式一致）
class PermissionRequestDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback? onAllow;
  final VoidCallback? onCancel;

  const PermissionRequestDialog({
    super.key,
    required this.title,
    required this.content,
    this.onAllow,
    this.onCancel,
  });

  /// 显示相机权限请求弹窗
  static Future<bool?> showCameraPermissionDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PermissionRequestDialog(
        title: '开启相机权限',
        content: '为向你提供拍摄头像等功能，Kissu需要获取你的相机权限',
      ),
    );
  }

  /// 显示相册权限请求弹窗
  static Future<bool?> showPhotosPermissionDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PermissionRequestDialog(
        title: '开启存储权限',
        content: '为向你提供选择头像、发送图片等功能，Kissu需要获取你的存储权限',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: SizedBox(
          width: 270,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 主弹窗容器
              Container(
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage(
                      'assets/dialog/kissu4_dialog_small_bg.webp',
                    ),
                    fit: BoxFit.fill,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // 内容区域
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 25, 24, 24),
                      child: Column(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xff333333),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            content,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xff333333),
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          // 继续按钮
                          GestureDetector(
                            onTap:
                                onAllow ??
                                () => Navigator.of(context).pop(true),
                            child: Container(
                              width: 106,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9AD9),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Center(
                                child: Text(
                                  '继续',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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
                    color: const Color(0xFF999999),
                    borderRadius: BorderRadius.circular(16),
                    image: const DecorationImage(
                      image: AssetImage(
                        'assets/images/kissu_location_close.webp',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
