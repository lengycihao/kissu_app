import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoBackground extends StatefulWidget {
  final String videoPath;
  final String placeholderImagePath;
  final double? width;
  final double? height;

  const VideoBackground({
    super.key,
    required this.videoPath,
    required this.placeholderImagePath,
    this.width,
    this.height,
  });

  @override
  State<VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<VideoBackground> {
  VideoPlayerController? _controller;
  bool _isVideoInitialized = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset(widget.videoPath);
      
      await _controller!.initialize();
      
      if (!_isDisposed) {
        // 设置无声播放
        await _controller!.setVolume(0.0);
        
        // 设置循环播放
        await _controller!.setLooping(true);
        
        // 开始播放
        await _controller!.play();
        
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('视频初始化失败: $e');
      // 如果视频加载失败，保持显示图片
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double videoWidth = widget.width ?? 1500;
    final double videoHeight = widget.height ?? screenSize.height;

    return SizedBox(
      width: videoWidth,
      height: videoHeight,
      child: Stack(
        children: [
          // 占位图片 - 始终显示，作为背景
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              alignment: Alignment.centerRight, // 默认显示中间偏右位置
              child: Image.asset(
                widget.placeholderImagePath,
                width: videoWidth,
                height: videoHeight,
              ),
            ),
          ),
          
          // 视频层 - 在图片上方，初始化后显示
          if (_isVideoInitialized && _controller != null)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                alignment: Alignment.centerRight, // 默认显示中间偏右位置
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
