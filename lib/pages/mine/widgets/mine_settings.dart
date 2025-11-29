import 'package:flutter/material.dart';
import '../mine_controller.dart';

/// 我的页面-应用设置模块
class MineSettings extends StatefulWidget {
  final List<SettingItem> items;

  const MineSettings({
    super.key,
    required this.items,
  });

  @override
  State<MineSettings> createState() => _MineSettingsState();
}

class _MineSettingsState extends State<MineSettings>
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
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    // 延迟启动，在常用功能之后
    Future.delayed(const Duration(milliseconds: 500), () {
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
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.only(bottom: 16),
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
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.items.length,
          separatorBuilder: (_, __) => const SizedBox.shrink(),
          itemBuilder: (_, index) {
            return _AnimatedSettingItem(
              item: widget.items[index],
              index: index,
              isLast: index == widget.items.length - 1,
            );
          },
        ),
      ),
    );
  }
}

/// 带动画的设置项
class _AnimatedSettingItem extends StatefulWidget {
  final SettingItem item;
  final int index;
  final bool isLast;

  const _AnimatedSettingItem({
    required this.item,
    required this.index,
    required this.isLast,
  });

  @override
  State<_AnimatedSettingItem> createState() => _AnimatedSettingItemState();
}

class _AnimatedSettingItemState extends State<_AnimatedSettingItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // 延迟启动动画，每个项目延迟80ms
    Future.delayed(Duration(milliseconds: 500 + (widget.index * 80)), () {
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
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_slideAnimation.value, 0),
            child: child,
          );
        },
        child: GestureDetector(
          onTap: widget.item.onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 19,
              vertical: 12,
            ).copyWith(bottom: widget.isLast ? 0 : 12),
            child: Row(
              children: [
                Image.asset(widget.item.icon, width: 20, height: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.item.title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF000000),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Image.asset(
                  "assets/4.0/kissu4_arrow_right.webp",
                  width: 16,
                  height: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

