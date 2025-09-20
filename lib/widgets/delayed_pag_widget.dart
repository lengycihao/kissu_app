import 'package:flutter/material.dart';
import 'package:kissu_app/widgets/pag_animation_widget.dart';
import 'package:kissu_app/utils/pag_preloader.dart';

class DelayedPagWidget extends StatefulWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final Duration delay;
  final bool autoPlay;
  final bool repeat;

  const DelayedPagWidget({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    required this.delay,
    this.autoPlay = true,
    this.repeat = true,
  });

  @override
  State<DelayedPagWidget> createState() => _DelayedPagWidgetState();
}

class _DelayedPagWidgetState extends State<DelayedPagWidget> with AutomaticKeepAliveClientMixin {
  bool _shouldLoad = false;
  bool _isVisible = true;
  bool _hasStartedLoading = false; // 添加标志防止重复加载
  bool _wasEverLoaded = false; // 记录是否曾经加载过

  @override
  bool get wantKeepAlive => false; // 禁用状态保持，减少内存占用

  @override
  void initState() {
    super.initState();
    _startDelayedLoading();
  }

  void _startDelayedLoading() {
    if (_hasStartedLoading) return; // 防止重复启动
    
    _hasStartedLoading = true;
    
    // 检查是否已通过预加载管理器预加载过此资源
    if (PagPreloader.isPreloaded(widget.assetPath)) {
      // 如果已预加载，立即显示，无需延迟
      debugPrint('PAG资源已预加载，立即显示: ${widget.assetPath}');
      if (mounted) {
        setState(() {
          _shouldLoad = true;
          _wasEverLoaded = true;
        });
      }
      return;
    }
    
    // 延迟加载动画，并且只在页面可见时加载
    Future.delayed(widget.delay, () {
      if (mounted && _isVisible && !_shouldLoad) {
        setState(() {
          _shouldLoad = true;
          _wasEverLoaded = true;
        });
        // 标记为已预加载
        PagPreloader.markAsPreloaded(widget.assetPath);
        debugPrint('PAG延迟加载完成: ${widget.assetPath}');
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 检查页面可见性，但要避免不必要的状态更新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final route = ModalRoute.of(context);
        final isVisible = route?.isCurrent ?? true;
        
        // 如果已经加载过，则不再受可见性影响，保持显示状态
        if (_wasEverLoaded) {
          debugPrint('PAG组件已加载过，保持显示状态: ${widget.assetPath}');
          if (!_shouldLoad) {
            setState(() {
              _shouldLoad = true;
              _isVisible = true;
            });
          }
          return;
        }
        
        // 只在可见性真正改变且未曾加载过时才更新状态
        if (_isVisible != isVisible && !_wasEverLoaded) {
          debugPrint('延迟PAG组件可见性变化: ${widget.assetPath} -> $isVisible');
          
          setState(() {
            _isVisible = isVisible;
          });
          
          // 只在首次变为可见且未开始加载时启动加载
          if (isVisible && !_hasStartedLoading) {
            _startDelayedLoading();
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用以支持AutomaticKeepAliveClientMixin
    
    // 如果曾经加载过，则始终显示，不再受可见性影响
    if (_wasEverLoaded && _shouldLoad) {
      return PagAnimationWidget(
        assetPath: widget.assetPath,
        width: widget.width,
        height: widget.height,
        autoPlay: widget.autoPlay,
        repeat: widget.repeat,
      );
    }
    
    // 首次加载时的逻辑
    if (!_shouldLoad || (!_isVisible && !_wasEverLoaded)) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
      );
    }

    return PagAnimationWidget(
      assetPath: widget.assetPath,
      width: widget.width,
      height: widget.height,
      autoPlay: widget.autoPlay,
      repeat: widget.repeat,
    );
  }
}
