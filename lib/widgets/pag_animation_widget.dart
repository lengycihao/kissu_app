import 'package:flutter/material.dart';
import 'package:pag/pag.dart';

class PagAnimationWidget extends StatefulWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final bool autoPlay;
  final bool repeat;
  final VoidCallback? onAnimationFinished;
  final Widget Function(BuildContext context)? defaultBuilder;

  const PagAnimationWidget({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.autoPlay = true,
    this.repeat = true,
    this.onAnimationFinished,
    this.defaultBuilder,
  });

  @override
  State<PagAnimationWidget> createState() => _PagAnimationWidgetState();
}

class _PagAnimationWidgetState extends State<PagAnimationWidget> with AutomaticKeepAliveClientMixin {
  bool _isVisible = true;
  bool _isLoaded = false;
  bool _isPaused = false;
  static final Map<String, bool> _loadedAssets = {}; // 静态缓存已加载的资源

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    // 检查是否已经加载过该资源
    if (_loadedAssets[widget.assetPath] == true) {
      // 如果已加载过，立即显示
      _isLoaded = true;
    } else {
      // 首次加载时使用延迟
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _isLoaded = true;
            _loadedAssets[widget.assetPath] = true; // 标记为已加载
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用以支持AutomaticKeepAliveClientMixin
    
    return RepaintBoundary(
      child: Container(
        width: widget.width,
        height: widget.height,
        child: _isVisible && _isLoaded && !_isPaused ? PAGView.asset(
          widget.assetPath,
          width: widget.width,
          height: widget.height,
          repeatCount: widget.repeat ? PAGView.REPEAT_COUNT_LOOP : PAGView.REPEAT_COUNT_DEFAULT,
          autoPlay: widget.autoPlay,
          onAnimationEnd: widget.onAnimationFinished,
          defaultBuilder: widget.defaultBuilder ?? (context) {
            return Container(
              width: widget.width,
              height: widget.height,
            );
          },
        ) : Container(
          width: widget.width,
          height: widget.height,
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 当页面不可见时暂停动画，但避免频繁的状态更新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final route = ModalRoute.of(context);
        final isVisible = route?.isCurrent ?? true;
        
        // 只在可见性真正改变时才更新状态
        if (_isVisible != isVisible) {
          debugPrint('PAG动画可见性变化: ${widget.assetPath} -> $isVisible');
          setState(() {
            _isVisible = isVisible;
            _isPaused = !isVisible;
          });
        }
      }
    });
  }

  // 添加暂停/恢复方法
  void pauseAnimation() {
    if (mounted) {
      setState(() {
        _isPaused = true;
      });
    }
  }

  void resumeAnimation() {
    if (mounted) {
      setState(() {
        _isPaused = false;
      });
    }
  }
}
