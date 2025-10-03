import 'package:flutter/material.dart';
import 'dart:async';

/// 语音录制状态
enum VoiceRecordState {
  idle,       // 空闲
  recording,  // 录制中
  canceling,  // 取消状态（手指滑出按钮区域）
}

/// 语音录制浮层组件
class ChatVoiceRecorder extends StatefulWidget {
  final bool isRecording;
  final bool isCanceling;
  final VoidCallback? onCancel;

  const ChatVoiceRecorder({
    super.key,
    required this.isRecording,
    this.isCanceling = false,
    this.onCancel,
  });

  @override
  State<ChatVoiceRecorder> createState() => _ChatVoiceRecorderState();
}

class _ChatVoiceRecorderState extends State<ChatVoiceRecorder>
    with SingleTickerProviderStateMixin {
  int _recordDuration = 0;
  Timer? _timer;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(ChatVoiceRecorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _startRecording();
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _stopRecording();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _recordDuration = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordDuration++;
      });

      // 最长录音60秒
      if (_recordDuration >= 60) {
        _stopRecording();
      }
    });
  }

  void _stopRecording() {
    _timer?.cancel();
    setState(() {
      _recordDuration = 0;
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isRecording) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: Center(
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 麦克风动画图标
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_animationController.value * 0.2),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: widget.isCanceling
                              ? Colors.red.withOpacity(0.8)
                              : const Color(0xffBA92FD),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isCanceling ? Icons.cancel : Icons.mic,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // 录音时长
                Text(
                  _formatDuration(_recordDuration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                // 提示文字
                Text(
                  widget.isCanceling ? '松开取消发送' : '松开发送，上滑取消',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),

                // // 音量波形指示器（模拟）
                // if (!widget.isCanceling) ...[
                //   const SizedBox(height: 16),
                //   _buildVolumeIndicator(),
                // ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

