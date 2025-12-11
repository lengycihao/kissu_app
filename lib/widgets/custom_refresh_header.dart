import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 刷新时间提示组件（显示1秒后淡出）
class RefreshTimeHint extends StatefulWidget {
  final DateTime? lastRefreshTime;
  final bool isPulling; // 是否正在下拉
  
  const RefreshTimeHint({
    Key? key,
    this.lastRefreshTime,
    this.isPulling = false,
  }) : super(key: key);

  @override
  State<RefreshTimeHint> createState() => _RefreshTimeHintState();
}

class _RefreshTimeHintState extends State<RefreshTimeHint> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _heightAnimation;
  DateTime? _displayTime;
  bool _shouldShow = false;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _heightAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    if (widget.lastRefreshTime != null) {
      _displayTime = widget.lastRefreshTime;
      _shouldShow = true;
      _startHideTimer();
    }
  }
  
  @override
  void didUpdateWidget(RefreshTimeHint oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 如果开始下拉，立即显示占位空间
    if (widget.isPulling && !oldWidget.isPulling) {
      setState(() {
        _shouldShow = true;
      });
      _controller.reset();
      _controller.value = 0;
    }
    
    // 如果刷新完成（有新的时间），更新显示并重新开始隐藏计时
    if (widget.lastRefreshTime != oldWidget.lastRefreshTime && 
        widget.lastRefreshTime != null) {
      _displayTime = widget.lastRefreshTime;
      setState(() {
        _shouldShow = true;
      });
      _controller.reset();
      _controller.value = 0;
      _startHideTimer();
    }
  }
  
  void _startHideTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _controller.forward().then((_) {
          if (mounted) {
            setState(() {
              _shouldShow = false;
            });
          }
        });
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 如果不应该显示，返回空
    if (!_shouldShow) {
      return const SizedBox.shrink();
    }
    
    // 如果正在下拉但还没有时间，显示占位
    if (widget.isPulling && _displayTime == null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        child: const SizedBox(height: 16), // 占位空间
      );
    }
    
    // 如果没有时间，不显示
    if (_displayTime == null) {
      return const SizedBox.shrink();
    }
    
    final formatter = DateFormat('HH:mm');
    final timeText = '更新于${formatter.format(_displayTime!)}';
    
    return SizeTransition(
      sizeFactor: _heightAnimation,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
           alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image(image: AssetImage('assets/phone_history/kissu4_list_complet.png'),width: 16,color: Color(0xFF333333),),
              SizedBox(width: 4,),
              Text(
            timeText,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF333333),
            ),
          )
            ],
          ),
        ),
      ),
    );
  }
}

/// 自定义下拉刷新包装器（不显示任何loading）
class CustomPullToRefresh extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  
  const CustomPullToRefresh({
    Key? key,
    required this.child,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<CustomPullToRefresh> createState() => _CustomPullToRefreshState();
}

class _CustomPullToRefreshState extends State<CustomPullToRefresh> {
  bool _isRefreshing = false;
  bool _hasTriggered = false; // 标记是否已触发过刷新
  
  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // 检测下拉到顶部并继续下拉
        if (notification is ScrollUpdateNotification) {
          if (notification.metrics.pixels < -100 && !_isRefreshing && !_hasTriggered) {
            // 下拉超过100像素，触发刷新
            _hasTriggered = true;
            _triggerRefresh();
          }
        } else if (notification is ScrollEndNotification) {
          // 滚动结束，重置触发标记
          _hasTriggered = false;
        }
        return false;
      },
      child: widget.child,
    );
  }
  
  Future<void> _triggerRefresh() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }
}
