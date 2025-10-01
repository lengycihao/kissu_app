import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// 图片来源选择对话框工具类
class ImageSourceDialog {
  /// 显示图片来源选择对话框
  /// 返回用户选择的图片来源，如果用户取消则返回null
  static Future<ImageSource?> show(BuildContext context) async {
    return await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 顶部拖拽指示器
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // 标题
                const Text(
                  '选择图片来源',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 20),

                // 选项列表
                _buildImageSourceOption(
                  context,
                  icon: Icons.photo_library_outlined,
                  title: '从相册选择',
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
                Divider(height: 1, color: Colors.grey[200]),
                _buildImageSourceOption(
                  context,
                  icon: Icons.camera_alt_outlined,
                  title: '拍照',
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),

                const SizedBox(height: 10),

                // 取消按钮
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '取消',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建图片来源选项
  static Widget _buildImageSourceOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFFEA39C).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFFFEA39C), size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFF333333),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }
}

