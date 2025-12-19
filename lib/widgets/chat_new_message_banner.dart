import 'dart:async';

import 'package:flutter/material.dart';

/// 全局聊天新消息 Banner（顶部黑色卡片，带进出场动画）
class ChatNewMessageBanner extends StatefulWidget {
  final String avatarUrl;
  final String nickname;
  final String messagePreview;
  final VoidCallback? onTapNavigate; // 点击时：关闭并跳转
  final VoidCallback? onAutoDismiss; // 自动消失时：只关闭

  const ChatNewMessageBanner({
    super.key,
    required this.avatarUrl,
    required this.nickname,
    required this.messagePreview,
    this.onTapNavigate,
    this.onAutoDismiss,
  });

  @override
  State<ChatNewMessageBanner> createState() => _ChatNewMessageBannerState();
}

class _ChatNewMessageBannerState extends State<ChatNewMessageBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _autoTimer;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    // 进场动画
    _controller.forward();

    // 2s 后触发自动消失动画
    _autoTimer = Timer(const Duration(seconds: 2), () {
      _startClose(fromTap: false);
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startClose({required bool fromTap}) {
    if (_isClosing) return;
    _isClosing = true;
    _autoTimer?.cancel();

    _controller.reverse().whenComplete(() {
      if (!mounted) return;
      if (fromTap) {
        widget.onTapNavigate?.call();
      } else {
        widget.onAutoDismiss?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPadding + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _startClose(fromTap: true),
            child: _buildCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: _buildAvatar(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.nickname,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.messagePreview,
                  style: const TextStyle(
                    color: Color(0xccffffff),
                    fontWeight: FontWeight.w400,
                    decoration: TextDecoration.none,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final avatarUrl = widget.avatarUrl;

    if (avatarUrl.isEmpty) {
      return Container(
        width: 34,
        height: 34,
        color: Colors.white24,
        child: const Icon(Icons.person, color: Colors.white, size: 20),
      );
    }

    if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
      return Image.network(
        avatarUrl,
        width: 34,
        height: 34,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 34,
          height: 34,
          color: Colors.white24,
          child: const Icon(Icons.person, color: Colors.white, size: 20),
        ),
      );
    }

    return Image.asset(
      avatarUrl,
      width: 34,
      height: 34,
      fit: BoxFit.cover,
    );
  }
}
