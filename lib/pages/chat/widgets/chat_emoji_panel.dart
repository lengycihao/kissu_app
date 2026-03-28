import 'package:flutter/material.dart';

/// 表情面板组件
class ChatEmojiPanel extends StatelessWidget {
  final Function(String)? onEmojiSelected;
  final VoidCallback? onDelete;

  const ChatEmojiPanel({
    super.key,
    this.onEmojiSelected,
    this.onDelete,
  });

  static const List<String> _systemEmojis = [
    '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂',
    '🙂', '🙃', '😉', '😊', '😇', '🥰', '😍', '🤩',
    '😘', '😗', '😚', '❤️', '😋', '💣', '💩', '🔪',
    '😝', '🤑', '🤗', '🤭', '🤫', '🤔', '🤐', '🤨',
    '😐', '😑', '😶', '😏', '😒', '🙄', '😬', '🤥',
    '😌', '😔', '😪', '🤤', '😴', '😷', '🤒', '🤕',
    '🤢', '🤮', '🤧', '🥵', '🥶', '😓', '😩', '😫',
    '🤠', '🥳', '😎', '🤓', '🧐', '😕', '😟', '🙁',
    '😮', '😯', '😲', '😳', '🥺', '😦', '😧', '😨',
    '😰', '😥', '😢', '😭', '😱', '😖', '😣', '😞',
    '🥱', '😤', '😡', '😠', '🤬','👍', '👎', '👌',
    '✌️', '🤞', '🤟', '🤘', '🤙','💘','🤲', '🤝', 
    '👏', '🤲', '🤝', '🙏', '💪',
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
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: GridView.builder(
                padding: EdgeInsets.zero.copyWith(bottom: 40), // 移除顶部padding
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
            // 删除按钮 - 右下角
            Positioned(
              right: 16,
              bottom: 12,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 50,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/chat/kissu_chat_reback.png',
                      width: 22,
                      height: 22,
                    ),
                  ),
                ),
              ),
            ),
          ],
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

