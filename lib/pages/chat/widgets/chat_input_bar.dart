import 'package:flutter/material.dart';

/// 聊天输入栏组件（语音功能已移除）
class ChatInputBar extends StatefulWidget {
  final Function(String)? onSendText;
  final VoidCallback? onTyping;
  final VoidCallback? onEmojiTap;
  final VoidCallback? onAlbumTap;
  final VoidCallback? onCameraTap;
  final VoidCallback? onLocationTap;
  final bool showEmojiPanel;
  final FocusNode? focusNode;
  final Color? themeButtonColor; // 主题按钮颜色

  const ChatInputBar({
    super.key,
    this.onSendText,
    this.onTyping,
    this.onEmojiTap,
    this.onAlbumTap,
    this.onCameraTap,
    this.onLocationTap,
    this.showEmojiPanel = false,
    this.focusNode,
    this.themeButtonColor,
  });

  @override
  State<ChatInputBar> createState() => ChatInputBarState();
}

class ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _textController = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {
        _hasText = _textController.text.trim().isNotEmpty;
      });
      if (widget.onTyping != null && _textController.text.isNotEmpty) {
        widget.onTyping!();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// 插入表情到输入框（供外部调用）
  void insertEmoji(String emoji) {
    final text = _textController.text;
    final selection = _textController.selection;
    
    // 处理边界情况：如果光标位置无效，则插入到文本末尾
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;
    
    // 确保 start 和 end 都在有效范围内
    final safeStart = start.clamp(0, text.length);
    final safeEnd = end.clamp(0, text.length);
    
    // 在光标位置插入表情
    final newText = text.replaceRange(
      safeStart,
      safeEnd,
      emoji,
    );
    
    // 计算新的光标位置
    final newOffset = safeStart + emoji.length;
    
    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newOffset,
      ),
    );
    
    // 不自动请求焦点，避免弹出键盘
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty && widget.onSendText != null) {
      widget.onSendText!(text);
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xffffffff), // 纯白色背景
          boxShadow: [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 10,
              offset: Offset(0, -2),
            )
          ]
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _buildTextInput()),
                    const SizedBox(width: 12),
                    _buildSendButton(),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFunctionRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 文字输入框
  Widget _buildTextInput() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xffF2F2F2),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: TextField(
        controller: _textController,
        focusNode: widget.focusNode,
        minLines: 1,
        maxLines: 4, // 最多展示4行，超过后内部滚动
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => _sendMessage(),
        
        style: const TextStyle(fontSize: 15, color: Colors.black87),
        decoration: const InputDecoration(
          hintText: '发送消息给Ta',
          hintStyle: TextStyle(color: Color(0xff333333), fontSize: 12),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  // 发送按钮
  Widget _buildSendButton() {
    // 获取主题按钮颜色，如果没有则使用默认颜色
    final buttonColor = widget.themeButtonColor ?? const Color(0xffFF90CA);
    final disabledColor = buttonColor.withOpacity(0.8);
    
    return GestureDetector(
      onTap: _sendMessage,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: BoxDecoration(
          color: _hasText ? buttonColor : disabledColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Text(
          '发送',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildFunctionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildFunctionIcon(
          asset: 'assets/chat/kissu3_chat_emoji_open.webp',
          onTap: widget.onEmojiTap,
          isChangeColor: true,
          isActive: widget.showEmojiPanel,
        ),
        _buildFunctionIcon(
          asset: 'assets/chat/kissu3_chat_picture.webp',
          onTap: widget.onAlbumTap,
        ),
        _buildFunctionIcon(
          asset: 'assets/chat/kissu3_chat_camera.webp',
          onTap: widget.onCameraTap,
        ),
        _buildFunctionIcon(
          asset: 'assets/chat/kissu3_chat_location.webp',
          onTap: widget.onLocationTap,
        ),
      ],
    );
  }

  Widget _buildFunctionIcon({
    required String asset,
    VoidCallback? onTap,
    bool isChangeColor = false,
    bool isActive = false,
  }) {
    // 获取主题按钮颜色，如果没有则使用默认颜色
    final buttonColor = widget.themeButtonColor ?? const Color(0xffFF90CA);
    // 选中时使用主题颜色的浅色版本（透明度0.15）
    final activeColor = buttonColor;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        color: Colors.white,
        child: Center(
          child: Image.asset(
            asset,
            width: 24,
            color: isChangeColor&&isActive ?activeColor:null,
            height: 24,
             fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

