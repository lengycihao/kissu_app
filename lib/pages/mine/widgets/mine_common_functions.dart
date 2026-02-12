import 'package:flutter/material.dart';
import '../mine_controller.dart';

/// 我的页面-常用功能模块
class MineCommonFunctions extends StatefulWidget {
  final List<CommonFunctionItem> items;

  const MineCommonFunctions({super.key, required this.items});

  @override
  State<MineCommonFunctions> createState() => _MineCommonFunctionsState();
}

class _MineCommonFunctionsState extends State<MineCommonFunctions>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.only(bottom: 16, top: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部标题
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 28),
              child: Text(
                "常用功能",
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xcc000000),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // 功能图标网格（两排，每排4个）
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Column(
                children: [
                  // 第一排
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(4, (index) {
                      if (index < widget.items.length) {
                        return _AnimatedFunctionItem(
                          item: widget.items[index],
                          delay: index * 60,
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ),
                  const SizedBox(height: 23),
                  // 第二排
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(4, (index) {
                      final itemIndex = index + 4;
                      if (itemIndex < widget.items.length) {
                        return _AnimatedFunctionItem(
                          item: widget.items[itemIndex],
                          delay: itemIndex * 60,
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 带动画的功能项
class _AnimatedFunctionItem extends StatefulWidget {
  final CommonFunctionItem item;
  final int delay;

  const _AnimatedFunctionItem({required this.item, required this.delay});

  @override
  State<_AnimatedFunctionItem> createState() => _AnimatedFunctionItemState();
}

class _AnimatedFunctionItemState extends State<_AnimatedFunctionItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // 延迟启动动画
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTap: widget.item.onTap,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              SizedBox(
                width: 80,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      widget.item.icon,
                      width: 44,
                      height: 44,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Color(0xFFE8E8E8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.image_not_supported,
                            size: 44,
                            color: Color(0xFF999999),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.item.title,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xff000000),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ///新logo标志位
              if (widget.item.subIcon != null)
                Transform.translate(
                  offset: Offset(30, -10),
                  child: Image(
                    image: AssetImage(widget.item.subIcon!),
                    width: 28,
                    height: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
