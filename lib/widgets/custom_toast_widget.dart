import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';

class CustomToastWidget extends StatefulWidget {
  final String message;
  final Duration duration;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final double maxWidth;
  final EdgeInsets padding;

  const CustomToastWidget({
    super.key,
    required this.message,
    this.duration = const Duration(seconds: 2),
    this.backgroundColor = const Color(0xFF000000), // 黑色背景
    this.textColor = const Color(0xFFFFFFFF), // 白色文字
    this.fontSize = 11.0,
    this.maxWidth = 275.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
  });

  @override
  State<CustomToastWidget> createState() => _CustomToastWidgetState();
}

class _CustomToastWidgetState extends State<CustomToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // 开始显示动画
    _animationController.forward();

    // 自动隐藏
    Future.delayed(widget.duration, () {
      if (mounted) {
        _hide();
      }
    });
  }

  void _hide() async {
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: widget.maxWidth,
            ),
            padding: widget.padding,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              widget.message,
              style: TextStyle(
                color: widget.textColor,
                fontSize: widget.fontSize,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class CustomToast {
  static OverlayEntry? _overlayEntry;

  /// 安全地移除现有的Toast
  static void _removeExistingToast() {
    if (_overlayEntry != null) {
      try {
        _overlayEntry!.remove();
      } catch (e) {
        logWarning('CustomToast: Error removing existing toast: $e', tag: 'CustomToast', error: e);
      } finally {
        _overlayEntry = null;
      }
    }
  }
  
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    Color backgroundColor = const Color(0xFF000000), // 黑色背景
    Color textColor = const Color(0xFFFFFFFF), // 白色文字
    double fontSize = 13.0,
    double maxWidth = 275.0,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
  }) {
    // 检查context是否有效
    if (!context.mounted) {
      logWarning('CustomToast: Context is not mounted, skipping toast display', tag: 'CustomToast');
      return;
    }

    // 如果已经有Toast在显示，先移除
    _removeExistingToast();
    
    try {
      // 尝试多种方式获取Overlay
      OverlayState? overlay;
      
      // 方式1: 尝试获取当前context的overlay
      try {
        overlay = Overlay.of(context);
      } catch (e) {
        logWarning('CustomToast: Failed to get overlay from context: $e', tag: 'CustomToast', error: e);
      }
      
      // 方式2: 尝试获取根overlay
      if (overlay == null) {
        try {
          overlay = Overlay.of(context, rootOverlay: true);
        } catch (e) {
          logWarning('CustomToast: Failed to get root overlay: $e', tag: 'CustomToast', error: e);
        }
      }
      
      // 方式3: 使用Navigator的overlay
      if (overlay == null) {
        try {
          final navigatorState = Navigator.of(context);
          overlay = navigatorState.overlay;
        } catch (e) {
          logWarning('CustomToast: Failed to get Navigator overlay: $e', tag: 'CustomToast', error: e);
        }
      }
      
      // 方式4: 使用GetX的overlay
      if (overlay == null) {
        try {
          overlay = Get.overlayContext?.findAncestorStateOfType<OverlayState>();
        } catch (e) {
          logWarning('CustomToast: Failed to get GetX overlay: $e', tag: 'CustomToast', error: e);
        }
      }
      
      if (overlay == null) {
        logWarning('CustomToast: No overlay available, using fallback SnackBar', tag: 'CustomToast');
        // 使用SnackBar作为fallback
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              duration: duration,
              backgroundColor: backgroundColor,
            ),
          );
        } catch (e) {
          logError('CustomToast: SnackBar also failed: $e', tag: 'CustomToast', error: e);
          // 最后的fallback：使用Get.snackbar
          try {
            Get.snackbar(
              '提示',
              message,
              snackPosition: SnackPosition.TOP,
              backgroundColor: backgroundColor,
              colorText: textColor,
              duration: duration,
            );
          } catch (e2) {
            logError('CustomToast: All fallback methods failed: $e2', tag: 'CustomToast', error: e2);
          }
        }
        return;
      }
      
      // 创建OverlayEntry
      _overlayEntry = OverlayEntry(
        builder: (context) => _ToastOverlay(
          message: message,
          duration: duration,
          backgroundColor: backgroundColor,
          textColor: textColor,
          fontSize: fontSize,
          maxWidth: maxWidth,
          padding: padding,
          onDismiss: () {
            _removeExistingToast();
          },
        ),
      );
      
      // 插入Overlay
      overlay.insert(_overlayEntry!);
      
    } catch (e) {
      logError('CustomToast: Error showing toast: $e', tag: 'CustomToast', error: e);
      _overlayEntry = null;
      
      // 最后的fallback
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: duration,
            backgroundColor: backgroundColor,
          ),
        );
      } catch (e2) {
        logError('CustomToast: Even SnackBar failed: $e2', tag: 'CustomToast', error: e2);
        // 使用Get.snackbar作为最终fallback
        try {
          Get.snackbar(
            '提示',
            message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: backgroundColor,
            colorText: textColor,
            duration: duration,
          );
        } catch (e3) {
          logError('CustomToast: All fallback methods failed: $e3', tag: 'CustomToast', error: e3);
        }
      }
    }
  }
}

class _ToastOverlay extends StatefulWidget {
  final String message;
  final Duration duration;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final double maxWidth;
  final EdgeInsets padding;
  final VoidCallback onDismiss;

  const _ToastOverlay({
    Key? key,
    required this.message,
    required this.duration,
    required this.backgroundColor,
    required this.textColor,
    required this.fontSize,
    required this.maxWidth,
    required this.padding,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // 开始显示动画
    _animationController.forward();

    // 自动隐藏
    Future.delayed(widget.duration, () {
      if (mounted) {
        _hide();
      }
    });
  }

  void _hide() async {
    await _animationController.reverse();
    if (mounted) {
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: widget.maxWidth,
              ),
              padding: widget.padding,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                widget.message,
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: widget.fontSize,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
