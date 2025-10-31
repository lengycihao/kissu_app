import 'package:flutter/material.dart';

/// 情侣关系动画叠加层
/// 用于显示绑定/解绑关系时的GIF动画
class RelationshipAnimationOverlay extends StatefulWidget {
  /// GIF资源路径
  final String gifPath;
  
  /// 动画播放时长
  final Duration duration;
  
  /// 动画完成后的回调
  final VoidCallback? onAnimationComplete;

  const RelationshipAnimationOverlay({
    super.key,
    required this.gifPath,
    this.duration = const Duration(seconds: 3),
    this.onAnimationComplete,
  });

  @override
  State<RelationshipAnimationOverlay> createState() => _RelationshipAnimationOverlayState();
}

class _RelationshipAnimationOverlayState extends State<RelationshipAnimationOverlay> 
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // 创建淡入淡出动画控制器
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    
    // 开始淡入动画
    _fadeController.forward();
    
    // GIF播放时长，根据传入的duration自动关闭
    // 注意：GIF会自动循环播放，我们通过定时器控制显示时长
    Future.delayed(widget.duration, () {
      if (mounted) {
        _fadeController.reverse().then((_) {
          widget.onAnimationComplete?.call();
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 获取屏幕宽度，动画尺寸为屏幕宽度的80%
    final screenWidth = MediaQuery.of(context).size.width;
    final animationSize = screenWidth * 0.8;
    
    return Material(
      color: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SizedBox.expand(
          child: Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Image.asset(
                widget.gifPath,
                width: animationSize,
                height: animationSize,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

