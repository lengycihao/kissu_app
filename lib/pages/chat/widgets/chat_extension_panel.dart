import 'package:flutter/material.dart';

/// 扩展功能类型
enum ExtensionType {
  album,    // 相册
  camera,   // 相机
  location, // 位置
}

/// 扩展功能项配置
class ExtensionItem {
  final ExtensionType type;
  final IconData icon;
  final String label;
  final Color color;

  ExtensionItem({
    required this.type,
    required this.icon,
    required this.label,
    required this.color,
  });
}

/// 聊天扩展功能面板
class ChatExtensionPanel extends StatelessWidget {
  final Function(ExtensionType)? onItemTap;

  const ChatExtensionPanel({
    super.key,
    this.onItemTap,
  });

  // 扩展功能列表
  static final List<ExtensionItem> _extensionItems = [
    ExtensionItem(
      type: ExtensionType.album,
      icon: Icons.photo_library, // 临时占位，下面会替换为图片
      label: '照片',
      color: const Color(0xff8B7FFF),
    ),
    ExtensionItem(
      type: ExtensionType.camera,
      icon: Icons.camera_alt, // 临时占位，下面会替换为图片
      label: '拍照',
      color: const Color(0xff6BA5FF),
    ),
    ExtensionItem(
      type: ExtensionType.location,
      icon: Icons.location_on, // 临时占位，下面会替换为图片
      label: '位置',
      color: const Color(0xff4CAF50),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200, // 减少高度
      decoration: BoxDecoration(
        color: const Color(0xffFFFCF5),
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(16), // 减少padding
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 改为3列，减少每行项目数
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.8, // 调整宽高比
          ),
          itemCount: _extensionItems.length,
          itemBuilder: (context, index) {
            final item = _extensionItems[index];
            return _buildExtensionItem(item);
          },
        ),
      ),
    );
  }

  Widget _buildExtensionItem(ExtensionItem item) {
    // 根据类型选择对应的图标
    String iconPath;
    switch (item.type) {
      case ExtensionType.album:
        iconPath = 'assets/chat/kissu3_chat_picture.webp';
        break;
      case ExtensionType.camera:
        iconPath = 'assets/chat/kissu3_chat_camera.webp';
        break;
      case ExtensionType.location:
        iconPath = 'assets/chat/kissu3_chat_location.webp';
        break;
    }

    return GestureDetector(
      onTap: () => onItemTap?.call(item.type),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Image.asset(
              iconPath,
              width: 35,
              height: 35,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

