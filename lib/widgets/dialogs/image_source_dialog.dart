import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// 图片来源选择结果
class ImageSourceResult {
  /// 系统头像路径（如果选择了系统头像）
  final String? systemAvatarPath;
  
  /// 图片来源（如果选择了相册或相机）
  final ImageSource? imageSource;
  
  ImageSourceResult({this.systemAvatarPath, this.imageSource});
}

/// 图片来源选择对话框工具类
class ImageSourceDialog {
  /// 显示图片来源选择对话框
  /// 返回用户选择的图片来源或系统头像，如果用户取消则返回null
  static Future<ImageSourceResult?> show(BuildContext context) async {
    return await showModalBottomSheet<ImageSourceResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return _ImageSourceDialogContent();
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

/// 对话框内容（有状态组件，用于管理选中状态）
class _ImageSourceDialogContent extends StatefulWidget {
  @override
  _ImageSourceDialogContentState createState() => _ImageSourceDialogContentState();
}

class _ImageSourceDialogContentState extends State<_ImageSourceDialogContent> {
  // 系统头像列表
  final List<String> _systemAvatars = [
    'assets/3.0/kissu3_love_avater.webp',
    'assets/3.0/kissu3_boy_avater.webp',
    'assets/3.0/kissu3_girl_avater.webp',
  ];
  
  // 默认不选中任何头像
  int? _selectedAvatarIndex;
  
  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 20),
            
            // 系统头像选择
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_systemAvatars.length, (index) {
                final isSelected = _selectedAvatarIndex == index;
                return GestureDetector(
                  onTap: () {
                    // 点击头像后立即返回选中的头像
                    Navigator.of(context).pop(
                      ImageSourceResult(systemAvatarPath: _systemAvatars[index]),
                    );
                  },
                  child: Stack(
                    children: [
                      // 头像图片带边框
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(37),
                          border: Border.all(
                            color: isSelected 
                              ? Color(0xFFFF89AB) 
                              : Color(0xFFFFD4D0),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(36),
                          child: Image.asset(
                            _systemAvatars[index],
                            fit: BoxFit.fill,
                            width: 72,
                            height: 72,
                          ),
                        ),
                      ),
                      // 只在选中时显示右下角的选中标志
                      if (isSelected)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Image.asset(
                            'assets/3.0/kissu3_avater_sel.webp',
                            width: 24,
                            height: 24,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 30),
            
            // 相册选择
            ImageSourceDialog._buildImageSourceOption(
              context,
              icon: Icons.photo_library_outlined,
              title: '相册选择',
              onTap: () => Navigator.of(context).pop(
                ImageSourceResult(imageSource: ImageSource.gallery),
              ),
            ),
            SizedBox(height: 10),
            
            // 相机拍照
            ImageSourceDialog._buildImageSourceOption(
              context,
              icon: Icons.camera_alt_outlined,
              title: '相机拍照',
              onTap: () => Navigator.of(context).pop(
                ImageSourceResult(imageSource: ImageSource.camera),
              ),
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
  }
}
