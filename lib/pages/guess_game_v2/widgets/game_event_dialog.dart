import 'package:flutter/material.dart';
import 'dart:async';

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
          color: Colors.black.withValues(alpha: 0.3),
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
  addTimes,    // 增加答题次数
  skip,        // 跳过题目
  wrong,       // 回答错误
  right,       // 回答正确
  success,     // 游戏成功
  failed,      // 游戏失败
}

/// 显示游戏事件弹窗
void showGameEventDialog(BuildContext context, GameEventType type) {
  String imagePath;
  double width;
  double height;
  bool alignTop;

  switch (type) {
    case GameEventType.addTimes:
      imagePath = 'assets/say_guess/kissu_say_guess_addtimes.webp';
      width = 290;
      height = 290;
      alignTop = false;
      break;
    case GameEventType.skip:
      imagePath = 'assets/say_guess/kissu_say_guess_skip.webp';
      width = 290;
      height = 290;
      alignTop = false;
      break;
    case GameEventType.wrong:
      imagePath = 'assets/say_guess/kissu_say_guess_wrong.webp';
      width = 290;
      height = 290;
      alignTop = false;
      break;
    case GameEventType.right:
      imagePath = 'assets/say_guess/kissu_say_guess_right.webp';
      width = 290;
      height = 290;
      alignTop = false;
      break;
    case GameEventType.success:
      imagePath = 'assets/say_guess/kissu_say_guess_sucess.webp';
      width = 375;
      height = 459;
      alignTop = true;
      break;
    case GameEventType.failed:
      imagePath = 'assets/say_guess/kissu_say_guess_failed.webp';
      width = 375;
      height = 459;
      alignTop = true;
      break;
  }

  showDialog(
    context: context,
    barrierColor: Colors.transparent,
    builder: (context) => GameEventDialog(
      imagePath: imagePath,
      width: width,
      height: height,
      alignTop: alignTop,
    ),
  );
}
