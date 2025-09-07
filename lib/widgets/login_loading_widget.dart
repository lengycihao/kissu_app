import 'package:flutter/material.dart';

/// 登录加载动画组件
class LoginLoadingWidget extends StatefulWidget {
  final bool isLoading;
  final Widget child;
  final String? loadingText;

  const LoginLoadingWidget({
    super.key,
    required this.isLoading,
    required this.child,
    this.loadingText = '登录中...',
  });

  @override
  State<LoginLoadingWidget> createState() => _LoginLoadingWidgetState();
}

class _LoginLoadingWidgetState extends State<LoginLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(LoginLoadingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _controller.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 原始内容
        widget.child,

        // 加载遮罩
        if (widget.isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  width: 160, // 固定宽度
                  height: 120, // 固定高度
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 旋转的爱心动画
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _animation.value * 2 * 3.14159,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF7C98),
                                    Color(0xFFFFB6C1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // 加载文本 - 使用固定容器确保高度一致
                      Container(
                        height: 20, // 固定文本区域高度
                        alignment: Alignment.center,
                        child: Text(
                          widget.loadingText ?? '登录中...',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF333333),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // 跳动的小圆点
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (index) {
                          return AnimatedBuilder(
                            animation: _animation,
                            builder: (context, child) {
                              final delay = index * 0.2;
                              final value = (_animation.value - delay).clamp(
                                0.0,
                                1.0,
                              );
                              final scale =
                                  0.5 +
                                  0.5 *
                                      (1 - (value - 0.5).abs() * 2).clamp(
                                        0.0,
                                        1.0,
                                      );

                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFFF7C98,
                                      ).withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
