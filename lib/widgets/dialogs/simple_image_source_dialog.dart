import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// 简单图片来源选择对话框（仅包含相册、相机、取消）
class SimpleImageSourceDialog {
  /// 显示图片来源选择对话框
  /// 返回用户选择的图片来源，如果用户取消则返回null
  static Future<ImageSource?> show(BuildContext context) async {
    return await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 15),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/3.0/kissu3_avater_viewbg.webp'),
              fit: BoxFit.fill,
            ),
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
                  '更换头像',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 30),
                
                // 相册选择
                _buildImageSourceOption(
                  context,
                  icon: Icons.photo_library_outlined,
                  title: '相册选择',
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
                SizedBox(height: 10),
                
                // 相机拍照
                _buildImageSourceOption(
                  context,
                  icon: Icons.camera_alt_outlined,
                  title: '相机拍照',
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),

                const SizedBox(height: 20),

                // 取消按钮
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xffFFD4D0), width: 1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        margin: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xffFFD4D0), width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFEA39C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFFEA39C), size: 18),
            ),
            SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

