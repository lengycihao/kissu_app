import 'package:flutter/material.dart';

class BannerWidget extends StatefulWidget {
  final List<String> imagePaths;
  final Duration animationDuration;
  final Duration switchDuration;
  final double scaleFactor;

  const BannerWidget({
    super.key,
    required this.imagePaths,
    this.animationDuration = const Duration(seconds: 2),
    this.switchDuration = const Duration(seconds: 3),
    this.scaleFactor = 1.02, // 减小缩放幅度
  });

  @override
  State<BannerWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends State<BannerWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _transitionController;
  late Animation<Offset> _currentSlideAnimation;
  late Animation<Offset> _nextSlideAnimation;
  late Animation<double> _currentScaleAnimation;
  late Animation<double> _nextScaleAnimation;

  int _currentIndex = 0;
  int _nextIndex = 1;

  @override
  void initState() {
    super.initState();

    // 缩放动画控制器
    _scaleController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    // 过渡动画控制器
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // 当前图片滑动动画（向左）
    _currentSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.5, 0.0), // 增加滑动距离，让图片完全离开屏幕
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeInOut,
    ));

    // 下一张图片滑动动画（从右边进入）
    _nextSlideAnimation = Tween<Offset>(
      begin: const Offset(1.5, 0.0), // 从更远的右边开始进入
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeInOut,
    ));

    // 当前图片缩放动画（由大到小）
    _currentScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeInOut,
    ));

    // 下一张图片缩放动画（由小到大）
    _nextScaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeInOut,
    ));

    // 开始缩放动画
    _scaleController.repeat(reverse: true);

    // 开始自动切换
    _startAutoSwitch();
  }

  void _startAutoSwitch() {
    Future.delayed(widget.switchDuration, () {
      if (mounted) {
        _transitionController.forward().then((_) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % widget.imagePaths.length;
            _nextIndex = (_currentIndex + 1) % widget.imagePaths.length;
          });
          _transitionController.reset();
          _startAutoSwitch();
        });
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleController, _transitionController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Stack(
            children: [
              // 当前图片
              SlideTransition(
                position: _currentSlideAnimation,
                child: Transform.scale(
                  scale: _currentScaleAnimation.value,
                  child: Image.asset(
                    widget.imagePaths[_currentIndex],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // 下一张图片
              SlideTransition(
                position: _nextSlideAnimation,
                child: Transform.scale(
                  scale: _nextScaleAnimation.value,
                  child: Image.asset(
                    widget.imagePaths[_nextIndex],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}