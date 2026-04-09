import 'package:flutter/material.dart';

/// 更多菜单选项类型
enum MoreMenuType {
  editRemark,      // 修改备注
  changeBackground, // 更换背景
}

/// 更多菜单项配置
class MoreMenuItem {
  final MoreMenuType type;
  final String iconAsset;
  final String label;

  MoreMenuItem({
    required this.type,
    required this.iconAsset,
    required this.label,
  });
}

/// 聊天更多菜单组件（抽屉式）
class ChatMoreMenu extends StatelessWidget {
  final Function(MoreMenuType)? onItemTap;

  const ChatMoreMenu({
    super.key,
    this.onItemTap,
  });

  // 菜单项列表
  static final List<MoreMenuItem> _menuItems = [
    MoreMenuItem(
      type: MoreMenuType.editRemark,
      iconAsset: 'assets/chat/kissu3_chat_remark.webp',
      label: '修改备注',
    ),
    MoreMenuItem(
      type: MoreMenuType.changeBackground,
      iconAsset: 'assets/chat/kissu3_chat_picture.webp',
      label: '更换背景',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 71,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/chat/kissu3_chat_more_bg.webp'),
          fit: BoxFit.fill,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _menuItems.map((item) {
          return _buildMenuItem(item);
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItem(MoreMenuItem item) {
    return GestureDetector(
      onTap: () => onItemTap?.call(item.type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5) ,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              item.iconAsset,
              width: 13,
              height: 13,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 3),
            Text(
              item.label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xff6D383E),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示更多菜单（Overlay方式，显示在按钮下方）
  static void show(
    BuildContext context, {
    required Offset position,
    Function(MoreMenuType)? onItemTap,
  }) {
    // print('🎯 ChatMoreMenu.show 被调用, position: $position');
    final overlay = Overlay.of(context);
    // print('🎯 Overlay: $overlay');
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final rightPosition = screenWidth - position.dx;
        // print('🎯 屏幕宽度: $screenWidth, right位置: $rightPosition, top: ${position.dy}');
        
        return Stack(
          children: [
            // 点击外部区域关闭
            GestureDetector(
              onTap: () {
                // print('🎯 点击外部，关闭菜单');
                overlayEntry?.remove();
              },
              child: Container(
                color: Colors.transparent,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            // 菜单内容
            Positioned(
              right: rightPosition, // 从右边定位
              top: position.dy,
              child: Material(
                color: Colors.transparent,
                child: ChatMoreMenu(
                  onItemTap: (type) {
                    // print('🎯 菜单项被点击: $type');
                    overlayEntry?.remove();
                    onItemTap?.call(type);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(overlayEntry);
  }
}

