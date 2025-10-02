import 'package:flutter/material.dart';

/// 底部弹窗组件
class BottomDialogWidget extends StatelessWidget {
  final VoidCallback? onClose;
  final Widget? child;

  const BottomDialogWidget({
    Key? key,
    this.onClose,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部拖拽指示器
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // 关闭按钮
          if (onClose != null)
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.close,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ),
              ),
            ),
          
          // 内容区域
          if (child != null) child!,
        ],
      ),
    );
  }

  /// 显示底部弹窗
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    VoidCallback? onClose,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BottomDialogWidget(
        onClose: onClose,
        child: child,
      ),
    );
  }
}
