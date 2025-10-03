import 'package:flutter/material.dart';

/// 输入栏状态
enum InputBarMode {
  normal,  // 正常模式(显示文字输入)
  voice,   // 语音模式(显示语音按钮)
}

/// 聊天输入栏组件
class ChatInputBar extends StatefulWidget {
  final Function(String)? onSendText;
  final VoidCallback? onVoicePressed;
  final VoidCallback? onVoiceReleased;
  final VoidCallback? onVoiceCancelled;
  final Function(bool)? onVoiceCancelStateChanged;
  final VoidCallback? onEmojiTap;
  final VoidCallback? onExtensionTap;
  final bool showEmojiPanel;
  final bool showExtensionPanel;
  final FocusNode? focusNode;
  final bool isRecording; // 新增：外部录音状态

  const ChatInputBar({
    super.key,
    this.onSendText,
    this.onVoicePressed,
    this.onVoiceReleased,
    this.onVoiceCancelled,
    this.onVoiceCancelStateChanged,
    this.onEmojiTap,
    this.onExtensionTap,
    this.showEmojiPanel = false,
    this.showExtensionPanel = false,
    this.focusNode,
    this.isRecording = false, // 默认值
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _textController = TextEditingController();
  InputBarMode _mode = InputBarMode.normal;
  bool _hasText = false;
  bool _isCanceling = false;
  Offset? _pressStartPosition;
  bool _isPressing = false; // 本地按压状态

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {
        _hasText = _textController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _mode = _mode == InputBarMode.normal
          ? InputBarMode.voice
          : InputBarMode.normal;
    });
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 0.5),
        ),
        boxShadow: [], // 明确设置为空数组，确保没有阴影
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 语音/键盘切换按钮
              _buildVoiceToggleButton(),
              const SizedBox(width: 8),

              // 输入框或语音按钮
              Expanded(
                child: _mode == InputBarMode.normal
                    ? _buildTextInput()
                    : _buildVoiceButton(),
              ),
              const SizedBox(width: 8),

              // 表情按钮
              _buildEmojiButton(),
              const SizedBox(width: 8),

              // 发送按钮或扩展功能按钮
              _hasText ? _buildSendButton() : _buildExtensionButton(),
            ],
          ),
        ),
      ),
    );
  }

  // 语音/键盘切换按钮
  Widget _buildVoiceToggleButton() {
    return GestureDetector(
      onTap: _toggleMode,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Image.asset(
          'assets/chat/kissu3_chat_audio_icon.webp',
          width: 20,
          height: 20,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  // 文字输入框
  Widget _buildTextInput() {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 36,
        maxHeight: 100,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextField(
        controller: _textController,
        focusNode: widget.focusNode,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => _sendMessage(),
        style: const TextStyle(fontSize: 15, color: Colors.black87),
        decoration: const InputDecoration(
          hintText: '说点什么...',
          hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  // 语音按钮
  Widget _buildVoiceButton() {
    // 使用外部录音状态判断是否真正在录音
    final bool isActuallyRecording = widget.isRecording;
    
    return GestureDetector(
      // 使用 onPanDown 实现即时响应
      onPanDown: (details) {
        setState(() {
          _isPressing = true;
          _isCanceling = false;
          _pressStartPosition = details.globalPosition;
        });
        widget.onVoicePressed?.call();
      },
      onPanUpdate: (details) {
        if (!_isPressing || _pressStartPosition == null) return;
        
        // 计算手指移动距离
        final dy = _pressStartPosition!.dy - details.globalPosition.dy;
        final shouldCancel = dy > 80; // 上滑超过80像素进入取消状态
        
        if (shouldCancel != _isCanceling) {
          setState(() => _isCanceling = shouldCancel);
          widget.onVoiceCancelStateChanged?.call(shouldCancel);
        }
      },
      onPanEnd: (_) {
        if (!_isPressing) return;
        
        final wasCanceling = _isCanceling;
        setState(() {
          _isPressing = false;
          _isCanceling = false;
          _pressStartPosition = null;
        });
        
        // 只有真正在录音时才调用释放/取消回调
        if (isActuallyRecording) {
          if (wasCanceling) {
            widget.onVoiceCancelled?.call();
          } else {
            widget.onVoiceReleased?.call();
          }
        }
      },
      onPanCancel: () {
        if (!_isPressing) return;
        
        setState(() {
          _isPressing = false;
          _isCanceling = false;
          _pressStartPosition = null;
        });
        
        // 只有真正在录音时才调用取消回调
        if (isActuallyRecording) {
          widget.onVoiceCancelled?.call();
        }
      },
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: isActuallyRecording
              ? (_isCanceling 
                  ? Colors.red.withOpacity(0.1)
                  : const Color(0xffBA92FD).withOpacity(0.2))
              : (_isPressing 
                  ? Colors.grey[200]  // 按下但未开始录音（如权限请求中）
                  : Colors.grey[100]),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: Text(
            isActuallyRecording 
                ? (_isCanceling ? '松开取消' : '松开发送') 
                : '按住说话',
            style: TextStyle(
              color: isActuallyRecording
                  ? (_isCanceling ? Colors.red : const Color(0xffBA92FD))
                  : Colors.grey[700],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // 表情按钮
  Widget _buildEmojiButton() {
    return GestureDetector(
      onTap: widget.onEmojiTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: widget.showEmojiPanel
              ? const Color(0xffBA92FD).withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Image.asset(
          widget.showEmojiPanel 
              ? 'assets/chat/kissu3_chat_emoji_close.webp'
              : 'assets/chat/kissu3_chat_emoji_open.webp',
          width: 22,
          height: 22,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  // 扩展功能按钮
  Widget _buildExtensionButton() {
    return GestureDetector(
      onTap: widget.onExtensionTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: widget.showExtensionPanel
              ? const Color(0xffBA92FD).withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Image.asset(
          widget.showExtensionPanel
              ? 'assets/chat/kissu3_send_more_close.webp'
              : 'assets/chat/kissu3_send_more_open.webp',
          width: 22,
          height: 22,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  // 发送按钮
  Widget _buildSendButton() {
    return GestureDetector(
      onTap: _sendMessage,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xffBA92FD), Color(0xff9D7FEA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Image.asset(
          'assets/chat/kissu3_chat_send.webp',
          width: 18,
          height: 18,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

