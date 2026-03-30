import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';

/// 游戏事件弹窗（3秒自动消失或点击消失）
class GameEventDialog extends StatefulWidget {
  final String imagePath;
  final double width;
  final double height;
  final bool alignTop; // 是否顶部对齐

  const GameEventDialog({
    super.key,
    required this.imagePath,
    required this.width,
    required this.height,
    this.alignTop = false,
  });

  @override
  State<GameEventDialog> createState() => _GameEventDialogState();
}

class _GameEventDialogState extends State<GameEventDialog> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 3秒后自动关闭
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Material(
        color: Colors.transparent,
        child: Container(
          color: Colors.black.withValues(alpha: 0.65),
          alignment: widget.alignTop ? Alignment.topCenter : Alignment.center,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              margin: widget.alignTop ? const EdgeInsets.only(top: 0) : null,
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(widget.imagePath),
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 游戏事件类型
enum GameEventType {
  addTimes,     // 对方使用特权：答题次数+1
  addTimesSelf, // 自己使用特权：答题次数+1
  skip,         // 对方使用特权：跳过
  skipSelf,     // 自己使用特权：跳过
  wrong,        // 回答错误
  right,        // 回答正确
  success,      // 游戏成功
  failed,       // 游戏失败
}

/// 获取事件对应的弹窗参数
_GameEventParams _getEventParams(GameEventType type) {
  switch (type) {
    case GameEventType.addTimes:
      return _GameEventParams('assets/say_guess/kissu_say_guess_addtimes.webp', 290, 290, false);
    case GameEventType.addTimesSelf:
      return _GameEventParams('assets/say_guess/kissu_say_guess_addtimes_self.webp', 290, 290, false);
    case GameEventType.skip:
      return _GameEventParams('assets/say_guess/kissu_say_guess_skip.webp', 290, 290, false);
    case GameEventType.skipSelf:
      return _GameEventParams('assets/say_guess/kissu_say_guess_skip_self.webp', 290, 290, false);
    case GameEventType.wrong:
      return _GameEventParams('assets/say_guess/kissu_say_guess_wrong.webp', 290, 290, false);
    case GameEventType.right:
      return _GameEventParams('assets/say_guess/kissu_say_guess_right.webp', 290, 290, false);
    case GameEventType.success:
      return _GameEventParams('assets/say_guess/kissu_say_guess_sucess.webp', 375, 459, true);
    case GameEventType.failed:
      return _GameEventParams('assets/say_guess/kissu_say_guess_failed.webp', 375, 459, true);
  }
}

class _GameEventParams {
  final String imagePath;
  final double width;
  final double height;
  final bool alignTop;
  const _GameEventParams(this.imagePath, this.width, this.height, this.alignTop);
}

/// 使用 Get.dialog 显示弹窗（不需要 BuildContext，可在 controller 调用）
Future<void> showGameEventDialogGet(GameEventType type) async {
  final p = _getEventParams(type);
  await Get.dialog(
    GameEventDialog(
      imagePath: p.imagePath,
      width: p.width,
      height: p.height,
      alignTop: p.alignTop,
    ),
    barrierColor: Colors.transparent,
    barrierDismissible: true,
  );
  // 弹窗关闭后强制失焦，防止 chat 输入框重新获焦唤起键盘
  FocusManager.instance.primaryFocus?.unfocus();
}

/// 显示游戏事件弹窗（需要 BuildContext 版本，保留兼容）
Future<void> showGameEventDialog(BuildContext context, GameEventType type) {
  final p = _getEventParams(type);
  return showDialog(
    context: context,
    barrierColor: Colors.transparent,
    builder: (context) => GameEventDialog(
      imagePath: p.imagePath,
      width: p.width,
      height: p.height,
      alignTop: p.alignTop,
    ),
  );
}
