import 'package:flutter/material.dart';

/// 设备信息项组件
/// 支持长按显示提示框功能
class DeviceInfoItem extends StatelessWidget {
  final String text;
  final String iconPath;
  final bool isDevice;
  final Function(String, Offset)? onLongPress; // 长按回调，传递文本和位置
  final VoidCallback? onLongPressEnd; // 长按结束回调

  const DeviceInfoItem({
    Key? key,
    required this.text,
    required this.iconPath,
    this.isDevice = false,
    this.onLongPress,
    this.onLongPressEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) {
        if (onLongPress != null) {
          // 传递文本和全局位置给回调
          onLongPress!(text, details.globalPosition + const Offset(0, -40));
        }
      },
      onLongPressEnd: (_) {
        if (onLongPressEnd != null) {
          onLongPressEnd!();
        }
      },
      child: Container(
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(iconPath, width: 22, height: 22),
            const SizedBox(height: 4),
            Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
