import 'package:flutter/material.dart';

/// 社交风格的气泡菜单：复制 / 删除
class MessageActionBubble extends StatelessWidget {
  const MessageActionBubble({
    super.key,
    required this.canCopy,
    required this.canDelete,
    this.onCopy,
    this.onDelete,
  });

  final bool canCopy;
  final bool canDelete;
  final VoidCallback? onCopy;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    if (canCopy) {
      items.add(_buildItem('复制', Icons.copy_rounded, onCopy));
    }
    if (canDelete) {
      items.add(_buildItem('删除', Icons.delete_outline_rounded, onDelete,
          danger: true));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Container(
                width: 0.5,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: Colors.white.withOpacity(0.2),
              ),
            items[i],
          ],
        ],
      ),
    );
  }

  Widget _buildItem(
    String text,
    IconData icon,
    VoidCallback? onTap, {
    bool danger = false,
  }) {
    final color =
        danger ? const Color(0xFFFF6B6B) : const Color(0xFFFFFFFF);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 3),
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


