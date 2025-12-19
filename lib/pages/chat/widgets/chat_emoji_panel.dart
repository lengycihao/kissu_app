import 'package:flutter/material.dart';

/// 表情面板组件
class ChatEmojiPanel extends StatelessWidget {
  final Function(String)? onEmojiSelected;

  const ChatEmojiPanel({
    super.key,
    this.onEmojiSelected,
  });

  static const List<String> _systemEmojis = [
    '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂',
    '🙂', '🙃', '😉', '😊', '😇', '🥰', '😍', '🤩',
    '😘', '😗', '😚', '😙', '😋', '😛', '😜', '🤪',
    '😝', '🤑', '🤗', '🤭', '🤫', '🤔', '🤐', '🤨',
    '😐', '😑', '😶', '😏', '😒', '🙄', '😬', '🤥',
    '😌', '😔', '😪', '🤤', '😴', '😷', '🤒', '🤕',
    '🤢', '🤮', '🤧', '🥵', '🥶', '🥴', '😵', '🤯',
    '🤠', '🥳', '😎', '🤓', '🧐', '😕', '😟', '🙁',
    '😮', '😯', '😲', '😳', '🥺', '😦', '😧', '😨',
    '😰', '😥', '😢', '😭', '😱', '😖', '😣', '😞',
    '😓', '😩', '😫', '🥱', '😤', '😡', '😠', '🤬',
    '👍', '👎', '👌', '✌️', '🤞', '🤟', '🤘', '🤙',
    '👏', '🙌', '👐', '🤲', '🤝', '🙏', '💪', '🦾',
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍',
    '💔', '❣️', '💕', '💞', '💓', '💗', '💖', '💘',
    '💝', '💟', '☮️', '✝️', '☪️', '🕉️', '☸️', '✡️',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        // border: Border(
        //   top: BorderSide(color: Colors.grey[200]!, width: 0.5),
        // ),
      ),
      child: SafeArea(
        top: false, // 顶部不使用SafeArea，避免上方空白
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: GridView.builder(
            padding: EdgeInsets.zero, // 移除顶部padding
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: _systemEmojis.length,
            itemBuilder: (context, index) {
              return _EmojiItem(
                emoji: _systemEmojis[index],
                onTap: onEmojiSelected,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EmojiItem extends StatelessWidget {
  final String emoji;
  final Function(String)? onTap;

  const _EmojiItem({
    required this.emoji,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap?.call(emoji),
      child: Container(
         
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 22),
          ),
        ),
      ),
    );
  }
}

