import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoBackgroundWidget extends StatefulWidget {
  final String videoPath;
  final String? placeholderImagePath; // 添加占位符图片路径
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool enableHorizontalScroll;

  const VideoBackgroundWidget({
    super.key,
    required this.videoPath,
    this.placeholderImagePath, // 可选的占位符图片
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.enableHorizontalScroll = false,
  });

  @override
  State<VideoBackgroundWidget> createState() => _VideoBackgroundWidgetState();
}

class _VideoBackgroundWidgetState extends State<VideoBackgroundWidget>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _imageFadeController;
  late Animation<double> _imageFadeAnimation;

  @override
  bool get wantKeepAlive => true; // 保持组件状态

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _imageFadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _imageFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _imageFadeController,
      curve: Curves.easeInOut,
    ));
    
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset(
        widget.videoPath,
        // 添加视频播放配置以减少日志输出
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true, // 允许与其他音频混合
          allowBackgroundPlayback: false, // 不允许后台播放
        ),
      );
      
      await _controller.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        
        // 设置循环播放
        _controller.setLooping(true);
        // 设置音量（背景视频通常静音）
        _controller.setVolume(0.0);
        // 开始播放
        _controller.play();
        // 开始淡入动画
        _fadeController.forward();
        // 开始图片淡出动画
        _imageFadeController.forward();
      }
    } catch (e) {
      debugPrint('❌ 视频初始化失败: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    _imageFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用，因为使用了 AutomaticKeepAliveClientMixin
    
    if (_hasError) {
      // 视频加载失败时显示备用背景
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.play_circle_outline,
            color: Colors.white54,
            size: 64,
          ),
        ),
      );
    }

    // 构建视频组件
    Widget videoWidget = Container();
    if (_isInitialized) {
      videoWidget = SizedBox(
        width: widget.width,
        height: widget.height,
        child: FittedBox(
          fit: widget.fit,
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: VideoPlayer(_controller),
          ),
        ),
      );
      
      // 添加淡入动画效果
      videoWidget = FadeTransition(
        opacity: _fadeAnimation,
        child: videoWidget,
      );
    }

    // 构建图片占位符组件
    Widget imageWidget = Container();
    if (widget.placeholderImagePath != null) {
      imageWidget = SizedBox(
        width: widget.width,
        height: widget.height,
        child: FittedBox(
          fit: widget.fit,
          child: Image.asset(
            widget.placeholderImagePath!,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('占位符图片加载失败: $error');
              return Container(); // 返回空容器而不是fallback
            },
          ),
        ),
      );
      
      // 添加淡出动画效果
      imageWidget = FadeTransition(
        opacity: _imageFadeAnimation,
        child: imageWidget,
      );
    } else if (!_isInitialized) {
      // 没有占位符图片且视频未初始化时显示加载指示器
      imageWidget = _buildFallbackPlaceholder();
    }

    // 使用Stack叠加图片和视频
    Widget stackWidget = Stack(
      children: [
        // 视频在底层
        videoWidget,
        // 图片在上层
        imageWidget,
      ],
    );

    // 如果启用水平滚动，包装在SingleChildScrollView中
    if (widget.enableHorizontalScroll) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: stackWidget,
      );
    }

    return stackWidget;
  }

  // 构建备用占位符（当没有提供占位符图片或图片加载失败时使用）
  Widget _buildFallbackPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1a1a2e),
            Color(0xFF16213e),
            Color(0xFF0f3460),
          ],
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.white54,
          strokeWidth: 2,
        ),
      ),
    );
  }
}
