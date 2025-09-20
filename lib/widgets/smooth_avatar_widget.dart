import 'dart:async';
import 'package:flutter/material.dart';

/// 平滑加载头像组件
/// 特点：延迟500ms后再显示伴侣头像，避免显示占位图
class SmoothAvatarWidget extends StatefulWidget {
  final String? avatarUrl;
  final String defaultAsset;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final BoxFit fit;
  final VoidCallback? onTap;
  final VoidCallback? onImageLoaded;

  const SmoothAvatarWidget({
    super.key,
    this.avatarUrl,
    required this.defaultAsset,
    required this.width,
    required this.height,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.fit = BoxFit.cover,
    this.onTap,
    this.onImageLoaded,
  });

  @override
  State<SmoothAvatarWidget> createState() => _SmoothAvatarWidgetState();
}

class _SmoothAvatarWidgetState extends State<SmoothAvatarWidget> {
  bool _shouldShowPartnerAvatar = false;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _startDelayTimer();
  }

  @override
  void didUpdateWidget(SmoothAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果头像URL发生变化，重新启动延迟计时器
    if (oldWidget.avatarUrl != widget.avatarUrl) {
      _startDelayTimer();
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    super.dispose();
  }

  /// 启动延迟计时器
  void _startDelayTimer() {
    // 重置状态
    setState(() {
      _shouldShowPartnerAvatar = false;
    });

    // 取消之前的计时器
    _delayTimer?.cancel();

    // 检查是否有有效的网络URL
    final avatarUrl = widget.avatarUrl;
    if (avatarUrl == null || avatarUrl.isEmpty || !avatarUrl.startsWith('http')) {
      return;
    }

    // 设置500ms延迟后开始尝试显示伴侣头像
    _delayTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _shouldShowPartnerAvatar = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(10),
          border: widget.border,
          boxShadow: widget.boxShadow,
        ),
        child: ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(9),
          child: _buildImage(),
        ),
      ),
    );
  }

  Widget _buildImage() {
    // 如果没有有效的网络URL，显示透明占位
    if (widget.avatarUrl == null || 
        widget.avatarUrl!.isEmpty || 
        !widget.avatarUrl!.startsWith('http')) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.transparent,
      );
    }
    
    // 如果延迟时间未到，显示透明占位
    if (!_shouldShowPartnerAvatar) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.transparent,
      );
    }
    
    // 延迟时间到了，显示网络头像
    return Image.network(
      widget.avatarUrl!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      // 如果网络图片加载失败，显示透明占位
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: widget.width,
          height: widget.height,
          color: Colors.transparent,
        );
      },
      // 加载过程中显示透明占位
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          // 图片加载完成，显示图片
          // 调用回调通知图片已加载
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onImageLoaded?.call();
          });
          return child;
        }
        // 加载中显示透明占位
        return Container(
          width: widget.width,
          height: widget.height,
          color: Colors.transparent,
        );
      },
    );
  }

}